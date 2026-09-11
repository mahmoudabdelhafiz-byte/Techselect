<?php
$root=dirname(__DIR__);
$wrapper=file_get_contents($root.'/customer_outcome_links_page.php');
$ht=file_get_contents($root.'/.htaccess');
$service=file_get_contents($root.'/app/lib/CustomerOutcomes.php');
$errors=[];
$require=function(bool $ok,string $message) use (&$errors){if(!$ok)$errors[]=$message;};

$require(str_contains($wrapper,'CustomerOutcomes::publicList'), 'wrapper must reuse the approved public outcome gate');
$require(str_contains($wrapper,'CustomerOutcomes::publicCustomerLabel'), 'wrapper must preserve anonymization/naming rules');
$require(str_contains($wrapper,"/case-studies/"), 'proof cards must link to canonical case-study pages');
$require(str_contains($wrapper,'customer-outcomes'), 'proof section must expose a stable citation section');
$require(str_contains($wrapper,"array_slice($related,0,3)"), 'contextual proof cards must be bounded');
$require(!str_contains($wrapper,'Fit Score =') && !str_contains($wrapper,'rating_5'), 'customer proof must not calculate recommendation/review scores');
$require(str_contains($wrapper,"catch(Throwable $e)"), 'missing migration must fail open for public rendering');

$require(str_contains($ht,'^software/[a-z0-9-]+/?$ customer_outcome_links_page.php'), 'software route must use proof wrapper');
$require(str_contains($ht,'^categories/[a-z0-9-]+/?$ customer_outcome_links_page.php'), 'category route must use proof wrapper');
$require(str_contains($ht,'^compare/[a-z0-9-]+-vs-[a-z0-9-]+/?$ customer_outcome_links_page.php'), 'comparison route must use proof wrapper');

$require(str_contains($service,"verification_status='verified'"), 'public outcome query must require verified status');
$require(str_contains($service,"publication_status='published'"), 'public outcome query must require published status');
$require(str_contains($service,'approved_by IS NOT NULL'), 'public outcome query must require approval metadata');
$require(str_contains($service,'published_at IS NOT NULL'), 'public outcome query must require publication timestamp');

if($errors){foreach($errors as $e)fwrite(STDERR,"FAIL: $e\n");exit(2);} 
echo "customer outcome contextual links: OK\n";
