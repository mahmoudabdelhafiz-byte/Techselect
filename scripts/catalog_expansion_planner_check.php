<?php
$root=dirname(__DIR__);$fail=[];
function need($cond,$msg){global $fail;if(!$cond)$fail[]=$msg;}
function text($path){global $root;$p=$root.'/'.$path;need(is_file($p),'Missing '.$path);return is_file($p)?file_get_contents($p):'';}
$svc=text('app/lib/CatalogExpansionPlanner.php');
$api=text('api/catalog_expansion.php');
$ui=text('catalog_expansion.php');
$ht=text('.htaccess');
$shell=text('admin_shell_page.php');
$nav=text('app/lib/AdminControlCenter.php');
$docs=text('docs/catalog_expansion_planner.md');
$b2=text('db/mysql/038_catalog_expansion_batch2.sql');
$b3=text('db/mysql/039_catalog_expansion_batch3.sql');
need(str_contains($svc,'taxonomy_expansion_queue'),'Planner must use taxonomy demand.');
need(str_contains($svc,'buyer_intent_events'),'Planner must use buyer-intent events.');
need(str_contains($svc,'consultations'),'Planner must use consultations.');
need(str_contains($svc,'search_console_performance'),'Planner must use Search Console signals when available.');
need(str_contains($svc,"minimum_active_products'=>4")&&str_contains($svc,"minimum_ready_products'=>3")&&str_contains($svc,"minimum_verified_sources'=>4")&&str_contains($svc,"minimum_known_capability_rows'=>12"),'Readiness thresholds changed unexpectedly.');
need(str_contains($svc,"support_status<>'not_yet_verified'")&&str_contains($svc,'Unknown != Unsupported'),'Unknown-evidence boundary missing.');
need(str_contains($svc,'COUNT(DISTINCT CASE WHEN pc.support_status'),'Known capability count must remain distinct across joined evidence rows.');
need(!preg_match('/INSERT\s+INTO\s+(products|categories|product_capabilities)/i',$svc),'Planner must not auto-create catalog facts.');
need(str_contains($api,"requireRole(['reviewer','data_editor','admin','super_admin'])"),'Planner API role gate missing.');
need(str_contains($ui,'Demand never overrides evidence readiness'),'UI must disclose demand/readiness separation.');
need(str_contains($ht,'catalog-expansion')&&str_contains($ht,'api/catalog-expansion'),'Routes missing.');
need(str_contains($shell,"'/catalog-expansion'=>'catalog_expansion.php'"),'Admin shell target missing.');
need(str_contains($nav,"'key'=>'catalog_expansion'")&&str_contains($nav,"'href'=>'/catalog-expansion'"),'Admin navigation missing.');
need(str_contains($docs,'038_catalog_expansion_batch2.sql')&&str_contains($docs,'039_catalog_expansion_batch3.sql'),'Documentation must acknowledge existing catalog batches.');
need(str_contains($b2,"'Endpoint Security'")&&str_contains($b2,"'Backup & Disaster Recovery'")&&str_contains($b2,"'Business Intelligence & Analytics'"),'Existing batch 2 coverage not found.');
need(str_contains($b3,"'AI Platforms'")&&str_contains($b3,"'Healthcare & EHR Systems'")&&str_contains($b3,"'Retail POS'")&&str_contains($b3,"'CAD & Engineering'"),'Existing batch 3 coverage not found.');
if($fail){fwrite(STDERR,"Catalog expansion planner contract failed:\n- ".implode("\n- ",$fail)."\n");exit(1);}echo "Catalog expansion planner contract OK\n";
