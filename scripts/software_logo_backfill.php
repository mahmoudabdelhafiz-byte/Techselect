<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/SoftwareLogoManager.php';

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, "CLI only\n");
    exit(2);
}

$apply=in_array('--apply',$argv,true);
$refresh=in_array('--refresh',$argv,true);
$limit=200;$slug=null;
foreach($argv as $arg){
    if(preg_match('/^--limit=(\d+)$/',$arg,$m))$limit=max(1,min(1000,(int)$m[1]));
    if(preg_match('/^--slug=([a-z0-9-]+)$/',$arg,$m))$slug=$m[1];
}

$pdo=Db::pdo();
$where="p.status='active' AND p.website_url IS NOT NULL AND p.website_url<>''";
$params=[];
if(!$refresh)$where.=" AND (p.logo_path IS NULL OR p.logo_path='')";
if($slug!==null){$where.=" AND p.slug=?";$params[]=$slug;}
$sql="SELECT p.id,p.name,p.slug,p.website_url,p.logo_path,p.logo_source_url,p.logo_attribution,p.logo_last_verified_at,
             v.name vendor_name,v.website_url vendor_website
      FROM products p
      LEFT JOIN vendors v ON v.id=p.vendor_id
      WHERE {$where}
      ORDER BY p.name
      LIMIT ".(int)$limit;
$st=$pdo->prepare($sql);$st->execute($params);$products=$st->fetchAll(PDO::FETCH_ASSOC);

$summary=['mode'=>$apply?'apply':'dry-run','refresh'=>$refresh,'slug'=>$slug,'examined'=>0,'eligible'=>0,'cached'=>0,'skipped'=>0,'failed'=>0,'candidate_failures'=>0];
foreach($products as $product){
    $summary['examined']++;
    $label=$product['name'].' ['.$product['slug'].']';
    try{
        $candidates=SoftwareLogoManager::acceptableCandidates($product);
        if(!$candidates){
            $summary['skipped']++;
            echo "SKIP  {$label} — no acceptable identity-aware first-party logo/icon candidate\n";
            continue;
        }
        $summary['eligible']++;
        if(!$apply){
            $best=$candidates[0];
            echo "FOUND {$label} — ".$best['url'].' [score '.(int)($best['score']??0).', kind '.($best['kind']??'unknown').", identity ".(!empty($best['identity_match'])?'yes':'no')."]\n";
            continue;
        }

        $cached=null;$lastError=null;
        foreach($candidates as $candidate){
            echo "TRY   {$label} — ".$candidate['url'].' [score '.(int)($candidate['score']??0)."]\n";
            try{
                $cached=SoftwareLogoManager::cache($product,(string)$candidate['url']);
                break;
            }catch(Throwable $candidateError){
                $summary['candidate_failures']++;
                $lastError=$candidateError;
                echo "RETRY {$label} — {$candidateError->getMessage()}\n";
            }
        }
        if(!$cached)throw $lastError?:new RuntimeException('all_logo_candidates_failed');

        $attribution=$product['name'].' logo/icon — official vendor website';
        $pdo->prepare('UPDATE products SET logo_path=?,logo_source_url=?,logo_attribution=?,logo_last_verified_at=NOW() WHERE id=?')
            ->execute([$cached['logo_path'],$cached['source_url'],$attribution,(int)$product['id']]);
        $summary['cached']++;
        echo "CACHE {$label} — {$cached['logo_path']}\n";
    }catch(Throwable $e){
        $summary['failed']++;
        echo "FAIL  {$label} — {$e->getMessage()}\n";
    }
}

echo "\n".json_encode($summary,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT)."\n";
if(!$apply)echo "Dry run only. Review discovered official assets, then re-run with --apply. Use --slug=<slug> --refresh to safely replace one existing mapping.\n";
exit($summary['failed']>0?1:0);
