<?php
require_once dirname(__DIR__).'/app/lib/AdminShell.php';

$sample='<!doctype html><html><head><title>Admin</title></head><body><main class="wrap"><h1>Buyer Intent Analytics</h1></main><script>window.testAdmin=1;</script></body></html>';
$out=AdminShell::decorate($sample,['role'=>'admin'],'/buyer-analytics');
$errors=[];
if(!preg_match('#<body[^>]*class=["\'][^"\']*ts-admin-shell-body#i',$out))$errors[]='body layout class is not applied server-side';
if(!str_contains($out,'box-sizing:border-box;position:fixed'))$errors[]='sidebar is not border-box sized';
if(!str_contains($out,'width:calc(100% - var(--ts-admin-w))!important'))$errors[]='desktop content width does not reserve sidebar space';
if(!str_contains($out,'ts-admin-nav-link active'))$errors[]='buyer analytics navigation is not marked active';
if(preg_match_all('#<script\b([^>]*)>#i',$out,$scripts)){
    foreach($scripts[1] as $attrs){if(!preg_match('/\bnonce=["\'][^"\']+["\']/i',$attrs))$errors[]='an inline admin script is missing its CSP nonce';}
}else{$errors[]='no admin scripts found in decorated output';}
if($errors){fwrite(STDERR,"Admin shell check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "Admin shell layout/CSP contract passed.\n";
