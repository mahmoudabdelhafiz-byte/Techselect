<?php
$root=dirname(__DIR__);
$files=['app/lib/UserConsultationHistory.php','api/secure.php','api/account_history.php','account.php','my_consultations.php','resume_consultation.php','.htaccess','robots.txt'];
foreach($files as $file){if(!is_file($root.'/'.$file)){fwrite(STDERR,"Missing {$file}\n");exit(1);}}
$history=file_get_contents($root.'/app/lib/UserConsultationHistory.php');
$secure=file_get_contents($root.'/api/secure.php');
$api=file_get_contents($root.'/api/account_history.php');
$account=file_get_contents($root.'/account.php');
$resume=file_get_contents($root.'/resume_consultation.php');
$ht=file_get_contents($root.'/.htaccess');
$robots=file_get_contents($root.'/robots.txt');
$checks=[
  'authenticated create stores user_id'=>str_contains($history,'visitor_sessions(session_token_hash,user_id)')&&str_contains($history,'visitor_session_id,user_id,business_problem'),
  'anonymous claim uses hashed visitor token'=>str_contains($history,"hash('sha256',$visitorToken,true)")&&str_contains($history,'UPDATE consultations SET user_id=?'),
  'history scoped by user'=>str_contains($history,'WHERE c.user_id=?'),
  'resume scoped by owner'=>str_contains($history,'public_token=? AND user_id=?'),
  'create handled with current session user'=>str_contains($secure,'UserConsultationHistory::create($pdo,Security::user()'),
  'history API requires authentication'=>str_contains($api,"authentication_required"),
  'claim API requires csrf'=>str_contains($api,'Security::requireCsrf()'),
  'login claims active anonymous consultation'=>str_contains($account,'claimActive(d.csrf_token)'),
  'resume bridge restores session storage'=>str_contains($resume,"sessionStorage.setItem('techselectai.activeConsultation.v1'"),
  'private routes wired'=>str_contains($ht,'my-consultations')&&str_contains($ht,'api/account')&&str_contains($ht,'resume-consultation'),
  'private routes blocked from crawling'=>str_contains($robots,'Disallow: /my-consultations')&&str_contains($robots,'Disallow: /resume-consultation/'),
];
$failed=[];foreach($checks as $name=>$ok){echo ($ok?'PASS':'FAIL')." {$name}\n";if(!$ok)$failed[]=$name;}
if($failed){exit(1);}echo "User consultation history checks passed.\n";
