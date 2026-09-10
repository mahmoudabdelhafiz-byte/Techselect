<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Security.php';
require_once __DIR__.'/../app/lib/BuyerIntentAnalytics.php';
Security::start();
$pdo=Db::pdo();
$user=Security::requireRole(['admin','super_admin','data_editor']);
Security::rateLimit($pdo,'buyer_analytics_admin',60,60);
$days=isset($_GET['days'])?(int)$_GET['days']:30;
header('Content-Type: application/json; charset=utf-8');
echo json_encode(BuyerIntentAnalytics::dashboard($pdo,$days),JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
