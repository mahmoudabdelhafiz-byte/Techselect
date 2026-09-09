<?php
require_once __DIR__.'/../app/lib/CategoryGuard.php';

$allowed=['crm','hrms','itsm','erp','project-management','corporate-identity-digital-business-cards'];
$cases=[
  ['Looking for CRM','crm'],
  ['Need an IT service management platform','itsm'],
  ['We need an ERP for finance and supply chain','erp'],
  ['Looking for an HRMS for our employees','hrms'],
  ['Need project management software','project-management'],
  ['Need digital business cards for our company','corporate-identity-digital-business-cards'],
  ['Looking for CRM with employee digital identity','crm'],
];
$failed=0;
foreach($cases as [$text,$expected]){
  $actual=CategoryGuard::detectExplicit([], $text, $allowed);
  $ok=$actual===$expected;
  echo ($ok?'PASS':'FAIL')." | {$text} => ".($actual??'null')." (expected {$expected})\n";
  if(!$ok)$failed++;
}

// Earlier user context must keep priority over a later message that merely adds constraints.
$context=[
  ['sender_type'=>'user','message_text'=>'Looking for CRM'],
  ['sender_type'=>'assistant','message_text'=>'Tell me more requirements'],
];
$actual=CategoryGuard::detectExplicit($context,'In KSA with budget 10 USD per user',$allowed);
$ok=$actual==='crm';
echo ($ok?'PASS':'FAIL')." | context category lock => ".($actual??'null')." (expected crm)\n";
if(!$ok)$failed++;

exit($failed?2:0);
