<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/EvidenceRefresh.php';
$pdo=Db::pdo();
$args=$argv;$sourceId=null;$limit=10;
foreach($args as $a){if(str_starts_with($a,'--source-id='))$sourceId=(int)substr($a,12);if(str_starts_with($a,'--limit='))$limit=max(1,min(50,(int)substr($a,8)));}
$ids=[];
if($sourceId){$ids=[$sourceId];}else{$st=$pdo->prepare("SELECT id FROM evidence_sources WHERE source_url IS NOT NULL AND source_url<>'' ORDER BY checked_at ASC,id ASC LIMIT ?");$st->bindValue(1,$limit,PDO::PARAM_INT);$st->execute();$ids=array_map('intval',$st->fetchAll(PDO::FETCH_COLUMN));}
if(!$ids){echo "No evidence sources selected.\n";exit(0);}foreach($ids as $id){$r=EvidenceRefresh::check($pdo,$id);echo json_encode($r,JSON_UNESCAPED_SLASHES)."\n";}
