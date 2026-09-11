<?php
require_once __DIR__.'/../app/lib/Db.php';require_once __DIR__.'/../app/lib/Security.php';require_once __DIR__.'/../app/lib/AdminGovernance.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$u=Security::requireRole(['admin','super_admin']);$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function ag_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}function ag_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
if($method!=='GET'){Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'admin-governance-write',30,60);}
if($path==='/api/admin-governance/users'&&$method==='GET'){ag_out(['users'=>AdminGovernance::users($pdo,$_GET),'permissions'=>AdminGovernance::PERMISSIONS,'roles'=>AdminGovernance::ADMIN_ROLES,'statuses'=>AdminGovernance::USER_STATUSES,'csrf_token'=>Security::csrf()]);}
if(preg_match('#^/api/admin-governance/users/(\d+)$#',$path,$m)&&$method==='PATCH'){
 $id=(int)$m[1];$st=$pdo->prepare("SELECT id,email,full_name,role,status,email_verified_at,last_login_at,created_at,updated_at FROM users WHERE id=?");$st->execute([$id]);$old=$st->fetch(PDO::FETCH_ASSOC);if(!$old)ag_out(['error'=>'not_found'],404);$b=ag_body();$role=(string)($b['role']??$old['role']);$status=(string)($b['status']??$old['status']);[$ok,$reason]=AdminGovernance::canChangeUser($pdo,$u,$old,$role,$status);if(!$ok)ag_out(['error'=>$reason],403);
 $pdo->prepare('UPDATE users SET role=?,status=? WHERE id=?')->execute([$role,$status,$id]);$st->execute([$id]);$new=$st->fetch(PDO::FETCH_ASSOC);Security::audit($pdo,(int)$u['id'],'USER_ROLE_STATUS_UPDATE','user',(string)$id,$old,$new);ag_out(['user'=>$new]);
}
if($path==='/api/admin-governance/audit'&&$method==='GET'){ag_out(AdminGovernance::audit($pdo,$_GET)+['csrf_token'=>Security::csrf()]);}
if($path==='/api/admin-governance/audit.csv'&&$method==='GET'){header('Content-Type: text/csv; charset=utf-8');header('Content-Disposition: attachment; filename="techselectai-audit-log.csv"');echo AdminGovernance::auditCsv($pdo,$_GET);exit;}
ag_out(['error'=>'not_found'],404);
