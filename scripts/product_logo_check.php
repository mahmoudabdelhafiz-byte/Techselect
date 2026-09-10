<?php
require_once __DIR__.'/../app/lib/Db.php';
$pdo=Db::pdo();
$rows=$pdo->query("SELECT id,name,slug,logo_path,logo_source_url,logo_attribution,logo_last_verified_at FROM products WHERE status='active' ORDER BY name")->fetchAll();
$warnings=[];$configured=0;
foreach($rows as $p){
  $path=trim((string)($p['logo_path']??''));
  if($path==='') continue;
  $configured++;
  if(strpos($path,'/media/software/')!==0) $warnings[]=$p['slug'].': logo_path must be under /media/software/';
  if(empty($p['logo_source_url'])) $warnings[]=$p['slug'].': logo_source_url is required for a configured logo';
  if(empty($p['logo_attribution'])) $warnings[]=$p['slug'].': logo_attribution is required for a configured logo';
  $local=dirname(__DIR__).$path;
  if(!is_file($local)) $warnings[]=$p['slug'].': local logo file not found at '.$path;
}
echo 'Active products: '.count($rows).PHP_EOL;
echo 'Configured product logos: '.$configured.PHP_EOL;
if($warnings){echo 'Warnings: '.count($warnings).PHP_EOL;foreach($warnings as $w)echo '- '.$w.PHP_EOL;exit(2);}echo "Logo metadata checks passed.\n";
