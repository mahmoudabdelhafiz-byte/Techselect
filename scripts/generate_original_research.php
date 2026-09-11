<?php
require_once __DIR__.'/../app/lib/OriginalResearch.php';
if(PHP_SAPI!=='cli'){http_response_code(403);exit("CLI only\n");}
$publish=!in_array('--draft',$argv,true);
$s=OriginalResearch::generate(null,$publish);
echo json_encode(['snapshot_id'=>$s['id'],'snapshot_date'=>$s['snapshot_date'],'status'=>$s['status'],'sample_products'=>$s['sample_products'],'sample_categories'=>$s['sample_categories'],'sample_evidence_sources'=>$s['sample_evidence_sources']],JSON_PRETTY_PRINT).PHP_EOL;
