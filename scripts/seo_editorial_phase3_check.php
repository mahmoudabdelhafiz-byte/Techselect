<?php
$root=dirname(__DIR__);
$checks=[];
function ck($name,$ok){global $checks;$checks[]=['name'=>$name,'ok'=>(bool)$ok];}
function txt($p){return file_get_contents($p)?:'';}
$page=txt($root.'/editorial_decision_guide.php');
$ht=txt($root.'/.htaccess');
$sitemap=txt($root.'/sitemap.php');
$llms=txt($root.'/llms.txt');

foreach(['crm-egypt-b2b','erp-uae-enterprise','project-management-construction-mena'] as $slug){
 ck('guide config '.$slug,str_contains($page,"'{$slug}'"));
 ck('route '.$slug,str_contains($ht,$slug));
 ck('sitemap '.$slug,str_contains($sitemap,'/guides/'.$slug));
 ck('llms '.$slug,str_contains($llms,'/guides/'.$slug));
}
ck('canonical catalog query',str_contains($page,'product_capabilities')&&str_contains($page,'evidence'));
ck('alphabetical order',str_contains($page,'ORDER BY p.name'));
ck('unknown not unsupported',str_contains($page,'not yet verified, not unsupported')||str_contains($page,'Unknown evidence is not treated as unsupported'));
ck('evidence boundary',str_contains($page,'Evidence boundary:'));
ck('consultation CTA',str_contains($page,'/?start=consultation'));
ck('no universal winner claim',str_contains($page,'does not')&&str_contains($page,'universal winner'));
ck('construction scope boundary',str_contains($page,'not a complete construction-management software category'));

$failed=array_values(array_filter($checks,fn($x)=>!$x['ok']));
foreach($checks as $c)echo ($c['ok']?'PASS ':'FAIL ').$c['name'].PHP_EOL;
if($failed){fwrite(STDERR,count($failed).' check(s) failed'.PHP_EOL);exit(1);}echo 'All editorial phase 3 checks passed'.PHP_EOL;