<?php

declare(strict_types=1);

if(PHP_SAPI!=='cli'){http_response_code(403);fwrite(STDERR,"CLI only\n");exit(2);} 
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/CatalogEvidenceParity.php';

$report=CatalogEvidenceParity::report(Db::pdo());
$fail=in_array('--fail-on-critical',$argv,true);
echo json_encode($report,JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
if($fail && (int)($report['summary']['critical']??0)>0)exit(1);
