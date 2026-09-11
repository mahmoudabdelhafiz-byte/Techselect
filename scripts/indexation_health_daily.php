<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/IndexationHealth.php';
$config=require __DIR__.'/../app/config.php';
$pdo=Db::pdo();
try{
    $probe=IndexationHealth::probeStrategic($pdo,(string)$config['site_url'],100);
    $snapshot=IndexationHealth::recordDailySnapshot($pdo);
    echo json_encode(['ok'=>true,'probe'=>$probe,'snapshot'=>$snapshot,'ran_at'=>gmdate('c')],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
    exit(0);
}catch(Throwable $e){
    fwrite(STDERR,json_encode(['ok'=>false,'error'=>$e->getMessage(),'ran_at'=>gmdate('c')],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL);
    exit(1);
}
