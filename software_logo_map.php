<?php
require_once __DIR__.'/app/lib/Db.php';
$pdo=Db::pdo();
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: public, max-age=300');
$q=$pdo->query("SELECT slug,name,logo_path,logo_last_verified_at FROM products WHERE status='active' ORDER BY name");
$products=[];
foreach($q->fetchAll(PDO::FETCH_ASSOC) as $row){
    $path=trim((string)($row['logo_path']??''));
    $safe=$path!==''&&str_starts_with($path,'media/software/')&&strpos($path,'..')===false;
    $products[]=[
        'slug'=>(string)$row['slug'],
        'name'=>(string)$row['name'],
        'logo_path'=>$safe?'/'.ltrim($path,'/'):null,
        'logo_last_verified_at'=>$row['logo_last_verified_at']??null,
    ];
}
echo json_encode(['products'=>$products],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
