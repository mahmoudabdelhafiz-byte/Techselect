<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/CatalogExpansionPlanner.php';
Security::start();Security::requireRole(['reviewer','data_editor','admin','super_admin']);$pdo=Db::pdo();
$days=(int)($_GET['days']??90);header('Content-Type: application/json; charset=utf-8');
try{echo json_encode(CatalogExpansionPlanner::dashboard($pdo,$days),JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);}catch(Throwable $e){http_response_code(400);echo json_encode(['error'=>$e->getMessage()]);}
