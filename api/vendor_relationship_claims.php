<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/VendorRelationshipClaim.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();
$method=$_SERVER['REQUEST_METHOD']??'GET';$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
function vrc_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
if($method==='GET'){
  $q=trim((string)($_GET['q']??''));$type=(string)($_GET['type']??'');
  if($type==='vendors'){$st=$pdo->prepare("SELECT id,name,slug,verification_status FROM vendors WHERE status='active' AND name LIKE ? ORDER BY name LIMIT 20");$st->execute(['%'.$q.'%']);vrc_out(['items'=>$st->fetchAll(PDO::FETCH_ASSOC)]);}
  if($type==='products'){$st=$pdo->prepare("SELECT id,name,slug,status FROM products WHERE status='active' AND name LIKE ? ORDER BY name LIMIT 20");$st->execute(['%'.$q.'%']);vrc_out(['items'=>$st->fetchAll(PDO::FETCH_ASSOC)]);}
  vrc_out(['error'=>'invalid_type'],422);
}
if($method==='POST'){
  Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'vendor-relationship-claim',8,300);
  $b=json_decode(file_get_contents('php://input'),true)?:[];
  try{$r=VendorRelationshipClaim::create($pdo,$b);}catch(InvalidArgumentException $e){vrc_out(['error'=>$e->getMessage()],422);}
  Security::audit($pdo,null,'VENDOR_RELATIONSHIP_CLAIM_SUBMIT','vendor_relationship_claim',(string)$r['id'],null,['status'=>$r['status'],'duplicate'=>$r['duplicate']]);
  vrc_out($r,$r['duplicate']?200:201);
}
vrc_out(['error'=>'method_not_allowed'],405);
