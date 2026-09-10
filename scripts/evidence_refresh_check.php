<?php
require_once __DIR__.'/../app/lib/EvidenceRefresh.php';
$failed=[];
$assert=function($cond,$msg)use(&$failed){if(!$cond)$failed[]=$msg;};
$assert(EvidenceRefresh::isSafeIp('8.8.8.8'),'public IPv4 should be safe');
$assert(!EvidenceRefresh::isSafeIp('127.0.0.1'),'loopback must be blocked');
$assert(!EvidenceRefresh::isSafeIp('10.0.0.1'),'private IPv4 must be blocked');
$assert(!EvidenceRefresh::isSafeIp('169.254.1.1'),'link-local IPv4 must be blocked');
$a=EvidenceRefresh::fingerprint('<html><style>x</style><body>Hello   world</body></html>','text/html');
$b=EvidenceRefresh::fingerprint('<html><body>Hello world</body><script>alert(1)</script></html>','text/html');
$c=EvidenceRefresh::fingerprint('<html><body>Hello changed world</body></html>','text/html');
$assert(hash_equals($a,$b),'script/style/whitespace-only changes should normalize');
$assert(!hash_equals($a,$c),'material visible text change should alter fingerprint');
$schema=file_get_contents(__DIR__.'/../db/mysql/022_evidence_refresh.sql');
foreach(['evidence_refresh_checks','evidence_change_candidates','pending_review','content_fingerprint'] as $needle)$assert(strpos($schema,$needle)!==false,"migration missing $needle");
$svc=file_get_contents(__DIR__.'/../app/lib/EvidenceRefresh.php');
foreach(['FILTER_FLAG_NO_PRIV_RANGE','FILTER_FLAG_NO_RES_RANGE','CURLOPT_RESOLVE','FOLLOWLOCATION\'=>false','INSERT IGNORE INTO evidence_change_candidates','UPDATE evidence_sources SET checked_at=NOW()'] as $needle)$assert(strpos($svc,$needle)!==false,"service missing $needle");
if($failed){fwrite(STDERR,"Evidence refresh checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Evidence refresh checks passed.\n";
