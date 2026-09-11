<?php
$root=dirname(__DIR__);
$checks=[];
function must(string $file,string $needle,string $label){global $checks;$text=@file_get_contents($file);$ok=$text!==false&&str_contains($text,$needle);$checks[]=[$label,$ok];if(!$ok)fwrite(STDERR,"FAIL: {$label}\n");}
function mustNot(string $file,string $needle,string $label){global $checks;$text=@file_get_contents($file);$ok=$text!==false&&!str_contains($text,$needle);$checks[]=[$label,$ok];if(!$ok)fwrite(STDERR,"FAIL: {$label}\n");}

must($root.'/db/mysql/027_customer_outcomes.sql',"verification_status ENUM('draft','in_review','verified','rejected')",'verification lifecycle exists');
must($root.'/db/mysql/027_customer_outcomes.sql',"publication_status ENUM('draft','published','archived')",'publication lifecycle exists');
mustNot($root.'/db/mysql/027_customer_outcomes.sql','INSERT INTO customer_outcomes','migration contains no fabricated seed outcome');
must($root.'/app/lib/CustomerOutcomes.php',"verification_status='verified' AND co.publication_status='published'",'public list requires verified + published');
must($root.'/app/lib/CustomerOutcomes.php','approved_by IS NOT NULL AND co.approved_at IS NOT NULL AND co.published_at IS NOT NULL','public list requires explicit approval metadata');
must($root.'/app/lib/CustomerOutcomes.php',"if(\$publication==='published'&&\$verification!=='verified')",'server blocks publishing unverified record');
must($root.'/app/lib/CustomerOutcomes.php','customer_name_approval_required_for_logo','logo approval requires customer-name approval');
must($root.'/case_studies.php','We prefer an empty proof section to fabricated social proof.','public empty state rejects fake proof');
must($root.'/case_study.php','It is not a TechSelectAI Fit Score, Verified Review, Public Review Intelligence score, or vendor marketing claim.','case study is separated from scoring/reviews');
must($root.'/api/customer_outcomes.php',"Security::requireRole(['reviewer','admin','super_admin'])",'admin API role gate');
must($root.'/api/customer_outcomes.php','Security::requireCsrf()','admin writes require CSRF');
must($root.'/.htaccess','RewriteRule ^case-studies/[a-z0-9-]+/?$ case_study.php','public detail route exists');
must($root.'/.htaccess','RewriteRule ^api/customer-outcomes(?:/.*)?$ api/customer_outcomes.php','admin API route exists');
must($root.'/sitemap.php',"verification_status='verified' AND publication_status='published'",'sitemap includes approved public outcomes only');
must($root.'/llms.txt','Customer outcomes are published only after verification and explicit publication approval.','AI discovery documents proof policy');

$failed=array_filter($checks,fn($r)=>!$r[1]);
if($failed){fwrite(STDERR,count($failed)." customer outcome checks failed\n");exit(1);}echo count($checks)." customer outcome checks passed\n";
