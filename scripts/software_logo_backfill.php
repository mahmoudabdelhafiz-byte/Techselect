<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/SoftwareLogoManager.php';

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, "CLI only\n");
    exit(2);
}

$apply=in_array('--apply',$argv,true);
$limit=200;
foreach($argv as $arg){
    if(preg_match('/^--limit=(\d+)$/',$arg,$m))$limit=max(1,min(1000,(int)$m[1]));
}

$pdo=Db::pdo();
$sql="SELECT id,name,slug,website_url,logo_path,logo_source_url,logo_attribution,logo_last_verified_at
      FROM products
      WHERE status='active' AND website_url IS NOT NULL AND website_url<>''
        AND (logo_path IS NULL OR logo_path='')
      ORDER BY name
      LIMIT ".(int)$limit;
$products=$pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);

$summary=['mode'=>$apply?'apply':'dry-run','examined'=>0,'eligible'=>0,'cached'=>0,'skipped'=>0,'failed'=>0,'candidate_failures'=>0];
foreach($products as $product){
    $summary['examined']++;
    $label=$product['name'].' ['.$product['slug'].']';
    try{
        $discovery=SoftwareLogoManager::discover($product);
        $candidates=array_values(array_filter($discovery['candidates']??[],fn($candidate)=>(int)($candidate['score']??0)>=75));
        if(!$candidates){
            $summary['skipped']++;
            echo "SKIP  {$label} — no acceptable first-party logo/icon candidate\n";
            continue;
        }
        $summary['eligible']++;
        if(!$apply){
            $best=$candidates[0];
            echo "FOUND {$label} — ".$best['url'].' [score '.(int)($best['score']??0)."]\n";
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
        if(!$cached){
            throw $lastError?:new RuntimeException('all_logo_candidates_failed');
        }

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
if(!$apply)echo "Dry run only. Re-run with --apply after reviewing discovered official assets.\n";
exit($summary['failed']>0?1:0);
