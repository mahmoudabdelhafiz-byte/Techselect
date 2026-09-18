<?php
declare(strict_types=1);

$root=dirname(__DIR__);
$migration=$root.'/db/mysql/136_ot_ics_cybersecurity_asset_visibility_catalog.sql';
$sql=@file_get_contents($migration);
$errors=[];

if($sql===false){fwrite(STDERR,"Missing migration 136\n");exit(1);}

$category='ot-ics-cybersecurity-asset-visibility';
$products=['nozomi-networks-platform','claroty-ctd','dragos-platform','tenable-one-ot-exposure','microsoft-defender-for-iot'];

if(strpos($sql,"'{$category}'")===false)$errors[]="Missing category {$category}";
foreach($products as $slug){if(substr_count($sql,"'{$slug}'")<3)$errors[]="Product {$slug} is not carried through migration";}

foreach(array_merge([$category],$products) as $slug){
  foreach(glob($root.'/db/mysql/*.sql')?:[] as $file){
    if(realpath($file)===realpath($migration))continue;
    if(strpos((string)@file_get_contents($file),"'{$slug}'")!==false)$errors[]="Duplicate catalog shell {$slug} in ".basename($file);
  }
}

foreach([
 'not_yet_verified','product_capability_evidence','vendor_documentation','product_deployments','product_mobile_access',
 'otsec-passive-discovery','otsec-active-enrichment','otsec-topology-mapping','otsec-vulnerability-exposure',
 'otsec-engineering-change-monitoring','otsec-threat-anomaly-detection','otsec-segmentation-policy',
 'otsec-threat-intelligence','otsec-soc-integration','otsec-distributed-deployment','Unknown != Unsupported'
] as $needle){if(strpos($sql,$needle)===false)$errors[]="Missing OT-security invariant: {$needle}";}

$allowed=[
 'nozominetworks.com','www.nozominetworks.com','technicaldocs.nozominetworks.com',
 'claroty.com','www.claroty.com','web-assets.claroty.com',
 'dragos.com','www.dragos.com',
 'tenable.com','www.tenable.com','docs.tenable.com',
 'microsoft.com','www.microsoft.com','learn.microsoft.com'
];
preg_match_all('#https://[^\s\'\"]+#',$sql,$m);
foreach(array_unique($m[0]??[]) as $url){
  $url=rtrim($url,');,');
  $host=strtolower((string)parse_url($url,PHP_URL_HOST));
  if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved evidence host: {$host}";
}

foreach(['g2.com','capterra','fit_score','overall_score','recommendation_rank'] as $bad){
  if(stripos($sql,$bad)!==false)$errors[]="Prohibited catalog coupling/source: {$bad}";
}

foreach([
 "'nozomi-networks-platform','otsec-active-enrichment','partially_supported',0.990",
 "'nozomi-networks-platform','otsec-segmentation-policy','partially_supported',0.980",
 "'nozomi-networks-platform','otsec-threat-intelligence','partially_supported',0.990",
 "'claroty-ctd','otsec-segmentation-policy','partially_supported',0.990",
 "'dragos-platform','otsec-engineering-change-monitoring','partially_supported',0.960",
 "'tenable-one-ot-exposure','otsec-threat-intelligence','partially_supported',0.970",
 "'microsoft-defender-for-iot','otsec-active-enrichment','partially_supported',0.980",
 "'microsoft-defender-for-iot','otsec-segmentation-policy','partially_supported',0.960",
 "'microsoft-defender-for-iot','otsec-threat-intelligence','partially_supported',0.970"
] as $req){if(strpos($sql,$req)===false)$errors[]="Required scope boundary missing: {$req}";}

foreach([
 'add-on capability rather than assumed in every Nozomi platform deployment',
 'actual enforcement depends on external firewalls/NAC',
 'distinct subscription/add-on',
 'policy enforcement is performed through firewall/NAC integrations rather than assumed as native inline enforcement',
 'universal code-diff/configuration-control function for every controller family is not inferred',
 'separate OT adversary-intelligence workbench equivalent to dedicated CTI products is not inferred',
 'active-discovery depth varies by device and deployment',
 'native firewall/NAC segmentation enforcement is not inferred',
 'not treated as a standalone OT threat-intelligence product'
] as $phrase){if(strpos($sql,$phrase)===false)$errors[]="Missing OT-security limitation text: {$phrase}";}

if(strpos($sql,"WHERE p.slug IN('nozomi-networks-platform','dragos-platform','tenable-one-ot-exposure')")===false)$errors[]='SaaS deployment set changed';
if(strpos($sql,"WHERE p.slug IN('nozomi-networks-platform','claroty-ctd','dragos-platform','tenable-one-ot-exposure')")===false)$errors[]='On-prem deployment set changed';
if(strpos($sql,"Defender for IoT combines Azure services with locally managed/cloud-connected/air-gapped OT sensors")===false)$errors[]='Microsoft hybrid deployment boundary missing';

if(strpos($sql,"SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000")===false)$errors[]='Mobile defaults must remain unknown';

if($errors){fwrite(STDERR,"OT/ICS cybersecurity catalog check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "OT/ICS cybersecurity catalog contract passed: 1 canonical category, 5 current products, first-party evidence, OT-specific scope boundaries, conservative deployment/mobile handling and ranking neutrality.\n";
