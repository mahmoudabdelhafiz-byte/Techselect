<?php
$root=dirname(__DIR__);$errors=[];
$auth=file_get_contents($root.'/api/auth.php')?:'';
$lib=file_get_contents($root.'/app/lib/ExternalAuth.php')?:'';
$ui=file_get_contents($root.'/account.php')?:'';
$migration=file_get_contents($root.'/db/mysql/068_external_auth_identities.sql')?:'';
$env=file_get_contents($root.'/.env.shared.example')?:'';
foreach(['google','microsoft'] as $p){if(!str_contains($auth,"provider={$p}")&&!str_contains($lib,"provider={$p}")){} }
if(!str_contains($lib,"code_challenge_method'=>'S256'"))$errors[]='PKCE S256 is missing';
if(!str_contains($lib,"\$_SESSION['external_auth']"))$errors[]='OAuth state is not session-bound';
if(!str_contains($lib,'hash_equals'))$errors[]='OAuth state/provider comparison is not timing-safe';
if(!str_contains($lib,'accounts.google.com/o/oauth2/v2/auth')||!str_contains($lib,'oauth2.googleapis.com/token'))$errors[]='Google OAuth endpoints missing';
if(!str_contains($lib,'login.microsoftonline.com')||!str_contains($lib,'graph.microsoft.com/v1.0/me'))$errors[]='Microsoft OAuth/Graph endpoints missing';
if(!str_contains($migration,'UNIQUE KEY uq_ts_external_identity_provider_subject'))$errors[]='external identity uniqueness constraint missing';
if(!str_contains($auth,"LOGIN_EXTERNAL"))$errors[]='external login audit event missing';
if(!str_contains($ui,'Continue with Google')||!str_contains($ui,'Continue with Microsoft'))$errors[]='provider buttons missing from account UI';
if(str_contains($ui,'GOOGLE_OAUTH_CLIENT_SECRET')||str_contains($ui,'MICROSOFT_OAUTH_CLIENT_SECRET'))$errors[]='OAuth secrets leaked to account UI';
foreach(['GOOGLE_OAUTH_CLIENT_ID','GOOGLE_OAUTH_CLIENT_SECRET','MICROSOFT_OAUTH_CLIENT_ID','MICROSOFT_OAUTH_CLIENT_SECRET'] as $k)if(!str_contains($env,$k))$errors[]="$k missing from environment example";
if($errors){fwrite(STDERR,"External auth contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "External auth contract passed.\n";
