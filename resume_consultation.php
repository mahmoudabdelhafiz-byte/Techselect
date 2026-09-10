<?php
require_once __DIR__.'/app/lib/Db.php';
require_once __DIR__.'/app/lib/Security.php';
require_once __DIR__.'/app/lib/UserConsultationHistory.php';
Security::start();
$user=Security::user();
if(!$user){header('Location: /login?next='.rawurlencode($_SERVER['REQUEST_URI']??'/my-consultations'));exit;}
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
if(!preg_match('#^/resume-consultation/([a-f0-9]{48})/?$#',$path,$m)){http_response_code(404);exit('Not found');}
$payload=UserConsultationHistory::resumeForUser(Db::pdo(),(int)$user['id'],$m[1]);
if(!$payload){http_response_code(404);exit('Consultation not found');}
$nonce=bin2hex(random_bytes(16));
header("Content-Security-Policy: default-src 'self'; script-src 'nonce-{$nonce}'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; frame-ancestors 'none'",true);
$json=json_encode($payload,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_HEX_TAG|JSON_HEX_AMP|JSON_HEX_APOS|JSON_HEX_QUOT);
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Resume Consultation | TechSelectAI</title><meta name="robots" content="noindex,nofollow"><style>body{font-family:Inter,Arial,sans-serif;background:#f7f9fc;color:#172033;margin:0}.box{max-width:620px;margin:12vh auto;padding:24px;background:#fff;border:1px solid #e2e8f0;border-radius:16px}</style></head><body><div class="box"><h1>Resuming your consultation…</h1><p>Your saved search, conversation and latest recommendations are being restored.</p></div><script nonce="<?=htmlspecialchars($nonce,ENT_QUOTES,'UTF-8')?>">try{sessionStorage.setItem('techselectai.activeConsultation.v1',JSON.stringify(<?=$json?>));location.replace('/');}catch(e){location.replace('/');}</script></body></html>
