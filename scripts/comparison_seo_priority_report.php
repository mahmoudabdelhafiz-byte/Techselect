<?php
require_once dirname(__DIR__).'/app/lib/Db.php';
require_once dirname(__DIR__).'/app/lib/ComparisonSeoPriority.php';

if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
$days=90;foreach($argv as $arg)if(preg_match('/^--days=(\d+)$/',$arg,$m))$days=(int)$m[1];
$rows=ComparisonSeoPriority::backlog(Db::pdo(),$days);
$out=[];
foreach($rows as $r){
    $out[]=[
        'path'=>$r['path'],'products'=>array_map(static fn($p)=>$p['name'],$r['products']),
        'tier'=>$r['tier'],'protected'=>$r['protected'],'buyer_intent'=>$r['buyer_intent'],
        'publication_ready'=>$r['indexable'],'readiness_score'=>$r['readiness_score'],
        'known_capability_overlap'=>$r['overlap_known_capabilities'],'readiness_gaps'=>$r['readiness_gaps'],
        'gsc'=>$r['gsc'],'priority_score'=>$r['priority_score'],
    ];
}
echo json_encode(['window_days'=>$days,'policy'=>'Curated buyer/search intent plus evidence readiness. Priority is not a product ranking and does not affect Fit Score.','comparisons'=>$out],JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
