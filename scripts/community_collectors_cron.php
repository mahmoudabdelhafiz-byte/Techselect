<?php
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/CommunitySourceCollectors.php';
$pdo=Db::pdo();$limit=max(1,min(50,(int)(getenv('TECHSELECT_COMMUNITY_COLLECTOR_LIMIT')?:10)));$analyze=in_array(strtolower((string)getenv('TECHSELECT_COMMUNITY_AUTO_ANALYZE')),['1','true','yes'],true);$out=['purged'=>0,'connectors'=>[],'analysis'=>[],'errors'=>[]];
try{$out['purged']=CommunitySourceCollectors::purgeExpiredText($pdo);}catch(Throwable $e){$out['errors'][]=['stage'=>'purge','error'=>$e->getMessage()];}
$products=[];foreach(CommunitySourceCollectors::due($pdo,$limit) as $id){try{$r=CommunitySourceCollectors::run($pdo,(int)$id);$out['connectors'][]=['id'=>(int)$id]+$r;$c=CommunitySourceCollectors::get($pdo,(int)$id);$products[(int)$c['product_id']]=true;}catch(Throwable $e){$out['errors'][]=['connector_id'=>(int)$id,'error'=>$e->getMessage()];}}
if($analyze){foreach(array_keys($products) as $pid){try{$out['analysis'][]=['product_id'=>$pid]+CommunitySourceCollectors::analyzePending($pdo,$pid,25);}catch(Throwable $e){$out['errors'][]=['product_id'=>$pid,'stage'=>'analyze','error'=>$e->getMessage()];}}}
echo json_encode($out,JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
