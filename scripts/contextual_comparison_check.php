<?php
$helper=file_get_contents(__DIR__.'/../app/lib/ContextualComparison.php');
$page=file_get_contents(__DIR__.'/../contextual_comparison_page.php');
$ht=file_get_contents(__DIR__.'/../.htaccess');
$fail=[];
foreach(['company_size','implementation_capacity','security_priority','integration_priority','budget_priority','Scoring::overall','Published product evaluation'] as $n)if(strpos($helper,$n)===false)$fail[]='helper missing '.$n;
foreach(['Contextual Fit','Recalculate fit','What could change this recommendation?','Selection Project','data-citation-section="context-fit"'] as $n)if(strpos($page,$n)===false)$fail[]='page missing '.$n;
if(strpos($ht,'contextual_comparison_page.php')===false)$fail[]='comparison route not wired';
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "contextual_comparison_check: OK\n";
