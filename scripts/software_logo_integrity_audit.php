<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/SoftwareLogoManager.php';

if(PHP_SAPI!=='cli'){fwrite(STDERR,"CLI only\n");exit(2);}

$pdo=Db::pdo();$slug=null;$noLive=in_array('--no-live',$argv,true);
foreach($argv as $arg)if(preg_match('/^--slug=([a-z0-9-]+)$/',$arg,$m))$slug=$m[1];
$where="p.status='active'";$params=[];if($slug!==null){$where.=' AND p.slug=?';$params[]=$slug;}
$sql="SELECT p.id,p.name,p.slug,p.website_url,p.logo_path,p.logo_source_url,p.logo_attribution,p.logo_last_verified_at,
             v.id vendor_id,v.name vendor_name,v.website_url vendor_website
      FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id
      WHERE {$where} ORDER BY p.name";
$st=$pdo->prepare($sql);$st->execute($params);$products=$st->fetchAll(PDO::FETCH_ASSOC);

$rows=[];$hashGroups=[];$counts=['products'=>count($products),'ok'=>0,'review'=>0,'missing'=>0,'unavailable'=>0];
foreach($products as $p){
    $issues=[];$assessment=null;
    if(empty($p['logo_path'])){
        $status='missing';$issues[]='missing_logo';$counts['missing']++;
    }elseif(empty($p['website_url'])){
        $status='review';$issues[]='missing_official_website';$counts['review']++;
    }else{
        if($noLive){
            $relative=ltrim((string)$p['logo_path'],'/');
            if(!str_starts_with($relative,'media/software/')||str_contains($relative,'..'))$issues[]='unsafe_logo_path';
            if(!is_file(dirname(__DIR__).'/'.$relative))$issues[]='cached_file_missing';
            if(empty($p['logo_source_url']))$issues[]='missing_source_url';
            $status=$issues?'review':'ok';
        }else{
            $assessment=SoftwareLogoManager::assessStoredLogo($p);$status=$assessment['status'];$issues=$assessment['issues'];
        }
        $counts[$status]=($counts[$status]??0)+1;
    }

    $relative=ltrim((string)($p['logo_path']??''),'/');$absolute=dirname(__DIR__).'/'.$relative;
    $sha=null;if($relative!==''&&is_file($absolute)){$sha=hash_file('sha256',$absolute);if($sha)$hashGroups[$sha][]=['slug'=>$p['slug'],'name'=>$p['name'],'vendor_id'=>$p['vendor_id'],'vendor_name'=>$p['vendor_name'],'logo_path'=>$p['logo_path']];}
    $rows[$p['slug']]=['slug'=>$p['slug'],'name'=>$p['name'],'vendor'=>$p['vendor_name'],'status'=>$status,'issues'=>$issues,'logo_path'=>$p['logo_path'],'logo_source_url'=>$p['logo_source_url'],'logo_last_verified_at'=>$p['logo_last_verified_at'],'sha256'=>$sha,'top_candidates'=>array_slice($assessment['acceptable_candidates']??[],0,3)];
}

$duplicateGroups=[];
foreach($hashGroups as $sha=>$group){
    if(count($group)<2)continue;$vendors=[];foreach($group as $r)$vendors[(string)($r['vendor_id']??'none')]=true;
    if(count($vendors)<2)continue;
    $duplicateGroups[]=['sha256'=>$sha,'products'=>$group];
    foreach($group as $r){$rows[$r['slug']]['issues'][]='same_cached_image_used_by_different_vendors';if($rows[$r['slug']]['status']==='ok'){$rows[$r['slug']]['status']='review';$counts['ok']--; $counts['review']++;}}
}

foreach($rows as $r){
    if($r['status']==='ok')echo "OK      {$r['name']} [{$r['slug']}]\n";
    elseif($r['status']==='missing')echo "MISSING {$r['name']} [{$r['slug']}]\n";
    else echo "REVIEW  {$r['name']} [{$r['slug']}] — ".implode(', ',array_unique($r['issues']))."\n";
}

echo "\n".json_encode(['summary'=>$counts,'duplicate_cross_vendor_images'=>$duplicateGroups,'products'=>array_values($rows)],JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)."\n";
echo "\nAudit is report-only. For a confirmed bad mapping, run: php scripts/software_logo_backfill.php --slug=<slug> --refresh, review the candidate, then repeat with --apply.\n";
exit($counts['review']>0?1:0);
