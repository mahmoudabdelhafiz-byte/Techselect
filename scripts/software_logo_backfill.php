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

$summary=['mode'=>$apply?'apply':'dry-run','examined'=>0,'eligible'=>0,'cached'=>0,'skipped'=>0,'failed'=>0];
foreach($products as $product){
    $summary['examined']++;
    $label=$product['name'].' ['.$product['slug'].']';
    try{
        $discovery=SoftwareLogoManager::discover($product);
        $candidates=$discovery['candidates']??[];
        $best=null;
        foreach($candidates as $candidate){
            // Only auto-select assets that the official page itself strongly identifies
            // as a logo/brand image. Lower-confidence icons/social images stay manual.
            if((int)($candidate['score']??0)>=100){$best=$candidate;break;}
        }
        if(!$best){
            $summary['skipped']++;
            echo "SKIP  {$label} — no high-confidence official logo candidate\n";
            continue;
        }
        $summary['eligible']++;
        echo ($apply?'CACHE ':'FOUND ').$label.' — '.$best['url']."\n";
        if(!$apply)continue;

        $cached=SoftwareLogoManager::cache($product,(string)$best['url']);
        $attribution=$product['name'].' logo — official vendor website';
        $pdo->prepare('UPDATE products SET logo_path=?,logo_source_url=?,logo_attribution=?,logo_last_verified_at=NOW() WHERE id=?')
            ->execute([$cached['logo_path'],$cached['source_url'],$attribution,(int)$product['id']]);
        $summary['cached']++;
    }catch(Throwable $e){
        $summary['failed']++;
        echo "FAIL  {$label} — {$e->getMessage()}\n";
    }
}

echo "\n".json_encode($summary,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT)."\n";
if(!$apply)echo "Dry run only. Re-run with --apply after reviewing discovered official assets.\n";
exit($summary['failed']>0?1:0);
