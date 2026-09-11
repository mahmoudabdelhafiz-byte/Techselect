<?php
$root=dirname(__DIR__);
$m=file_get_contents($root.'/db/mysql/038_catalog_expansion_batch2.sql');
$g=file_get_contents($root.'/app/lib/CategoryGuard.php');
$s=file_get_contents($root.'/sitemap.php');
$errors=[];
$categories=['endpoint-security','backup-disaster-recovery','business-intelligence-analytics','project-management'];
$products=['microsoft-defender-endpoint','crowdstrike-falcon-endpoint','sentinelone-singularity-endpoint','sophos-endpoint','veeam-data-platform','acronis-cyber-protect','cohesity-data-cloud','commvault-cloud','microsoft-power-bi','tableau','qlik-cloud-analytics','google-looker','asana','monday-work-management','jira','smartsheet'];
foreach($categories as $x){if(strpos($m,$x)===false)$errors[]='missing category '.$x;if(strpos($g,"'{$x}'")===false)$errors[]='missing alias '.$x;}
foreach($products as $x){if(strpos($m,$x)===false)$errors[]='missing product '.$x;}
if(substr_count($m,"'not_yet_verified'")<1)$errors[]='unknown fallback missing';
if(strpos($m,"product_capability_evidence")===false)$errors[]='capability evidence linkage missing';
if(strpos($m,"vendor_documentation")===false)$errors[]='official evidence source insertion missing';
if(strpos($s,"COUNT(*) FROM product_capabilities")===false||strpos($s,"EXISTS(SELECT 1 FROM evidence_sources")===false)$errors[]='sitemap evidence gate missing';
if(strpos($s,"MAX(p.updated_at) last_updated")===false)$errors[]='category sitemap freshness missing';
if($errors){fwrite(STDERR,"FAIL\n - ".implode("\n - ",$errors)."\n");exit(1);}echo "OK catalog expansion batch 2: 4 categories, 16 products, aliases and evidence-gated sitemap checks present.\n";
