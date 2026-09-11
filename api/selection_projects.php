<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/Entitlements.php';
require_once __DIR__.'/../app/lib/SelectionProjects.php';
$config=require __DIR__.'/../app/config.php';$pdo=Db::pdo();Security::start();$user=Security::user();Entitlements::requireFeature($pdo,$user,'selection_projects');$uid=(int)$user['id'];$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';$method=$_SERVER['REQUEST_METHOD']??'GET';
function sp_out($d,int $s=200){http_response_code($s);header('Content-Type: application/json; charset=utf-8');echo json_encode($d,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function sp_body(){return json_decode(file_get_contents('php://input'),true)?:[];}
function sp_write(PDO $pdo,array $config,string $route):void{Security::sameOrigin($config);Security::rateLimit($pdo,$route,40,300);Security::requireCsrf();}
function sp_error(Throwable $e):void{$m=$e->getMessage();if($m==='not_found')sp_out(['error'=>'not_found'],404);$known=['invalid_budget_range','invalid_consultation','invalid_source','invalid_priority','invalid_child_type','required_field','invalid_money'];sp_out(['error'=>in_array($m,$known,true)?$m:'invalid_request'],422);}

try{
  if($path==='/api/selection-projects'&&$method==='GET')sp_out(['projects'=>SelectionProjects::list($pdo,$uid),'entitlements'=>Entitlements::context($pdo,$user)]);
  if($path==='/api/selection-projects'&&$method==='POST'){
    sp_write($pdo,$config,'selection-project-create');$b=sp_body();$p=SelectionProjects::create($pdo,$uid,$b);Security::audit($pdo,$uid,'SELECTION_PROJECT_CREATE','selection_project',(string)$p['id'],null,['name'=>$p['name']]);sp_out(['project'=>$p],201);
  }
  if(preg_match('#^/api/selection-projects/(\d+)$#',$path,$m)){
    $id=(int)$m[1];if($method==='GET')sp_out(['project'=>SelectionProjects::get($pdo,$uid,$id),'entitlements'=>Entitlements::context($pdo,$user)]);
    if($method==='PUT'||$method==='PATCH'){sp_write($pdo,$config,'selection-project-update');$before=SelectionProjects::get($pdo,$uid,$id);$p=SelectionProjects::update($pdo,$uid,$id,sp_body());Security::audit($pdo,$uid,'SELECTION_PROJECT_UPDATE','selection_project',(string)$id,['version'=>$before['version']],['version'=>$p['version']]);sp_out(['project'=>$p]);}
  }
  if(preg_match('#^/api/selection-projects/(\d+)/requirements$#',$path,$m)&&$method==='POST'){
    sp_write($pdo,$config,'selection-project-requirement');$b=sp_body();if(($b['source']??'user_entered')!=='user_entered')Entitlements::requireFeature($pdo,$user,'advanced_requirements_builder');$id=(int)$m[1];$p=SelectionProjects::addRequirement($pdo,$uid,$id,$b);Security::audit($pdo,$uid,'SELECTION_REQUIREMENT_ADD','selection_project',(string)$id,null,['source'=>$b['source']??'user_entered']);sp_out(['project'=>$p],201);
  }
  if(preg_match('#^/api/selection-projects/(\d+)/integrations$#',$path,$m)&&$method==='POST'){
    sp_write($pdo,$config,'selection-project-integration');$b=sp_body();if(($b['source']??'user_entered')!=='user_entered')Entitlements::requireFeature($pdo,$user,'advanced_requirements_builder');$id=(int)$m[1];$p=SelectionProjects::addIntegration($pdo,$uid,$id,$b);Security::audit($pdo,$uid,'SELECTION_INTEGRATION_ADD','selection_project',(string)$id,null,['source'=>$b['source']??'user_entered']);sp_out(['project'=>$p],201);
  }
  if(preg_match('#^/api/selection-projects/(\d+)/(requirements|integrations)/(\d+)$#',$path,$m)&&$method==='DELETE'){
    sp_write($pdo,$config,'selection-project-child-delete');$id=(int)$m[1];$kind=$m[2]==='requirements'?'requirement':'integration';$p=SelectionProjects::deleteChild($pdo,$uid,$id,$kind,(int)$m[3]);Security::audit($pdo,$uid,'SELECTION_'.strtoupper($kind).'_DELETE','selection_project',(string)$id,null,['child_id'=>(int)$m[3]]);sp_out(['project'=>$p]);
  }
}catch(Throwable $e){sp_error($e);}
sp_out(['error'=>'not_found'],404);
