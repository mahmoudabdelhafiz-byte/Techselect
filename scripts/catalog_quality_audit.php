<?php
require_once __DIR__.'/../app/lib/Db.php';
$pdo=Db::pdo();

function rows(PDO $pdo,string $sql): array { return $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC); }
function line(string $status,string $message): void { echo str_pad($status,7).' '.$message."\n"; }

echo "TechSelectAI catalog quality audit\n";
echo str_repeat('=',35)."\n\n";

$summary=$pdo->query("SELECT
 (SELECT COUNT(*) FROM categories WHERE is_active=1) categories,
 (SELECT COUNT(*) FROM products WHERE status='active') products,
 (SELECT COUNT(*) FROM capabilities WHERE is_active=1) capabilities,
 (SELECT COUNT(*) FROM evidence_sources WHERE verification_status='verified') verified_evidence")->fetch(PDO::FETCH_ASSOC);
line('INFO',"categories={$summary['categories']} products={$summary['products']} capabilities={$summary['capabilities']} verified_evidence={$summary['verified_evidence']}");
echo "\n";

$checks=[];
$checks['Products with no evidence']="SELECT p.slug FROM products p WHERE p.status='active' AND NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id) ORDER BY p.slug";
$checks['Products with fewer than 3 capability facts']="SELECT p.slug,COUNT(pc.id) fact_count FROM products p LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL WHERE p.status='active' GROUP BY p.id,p.slug HAVING COUNT(pc.id)<3 ORDER BY fact_count,p.slug";
$checks['Products with no deployment facts']="SELECT p.slug FROM products p WHERE p.status='active' AND NOT EXISTS(SELECT 1 FROM product_deployments pd WHERE pd.product_id=p.id) ORDER BY p.slug";
$checks['Products with all capability facts unknown']="SELECT p.slug,COUNT(pc.id) facts,SUM(pc.support_status IN ('unknown','not_yet_verified')) unknown_facts FROM products p JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL WHERE p.status='active' GROUP BY p.id,p.slug HAVING facts>0 AND unknown_facts=facts ORDER BY p.slug";
$checks['Supported facts without evidence links']="SELECT p.slug product_slug,c.slug capability_slug FROM product_capabilities pc JOIN products p ON p.id=pc.product_id JOIN capabilities c ON c.id=pc.capability_id WHERE p.status='active' AND pc.edition_id IS NULL AND pc.support_status NOT IN ('unknown','not_yet_verified','not_supported') AND NOT EXISTS(SELECT 1 FROM product_capability_evidence pce WHERE pce.product_capability_id=pc.id) ORDER BY p.slug,c.slug";
$checks['Duplicate active product slugs']="SELECT slug,COUNT(*) copies FROM products WHERE status='active' GROUP BY slug HAVING COUNT(*)>1 ORDER BY slug";
$checks['Duplicate capability slugs across modules']="SELECT c.slug,COUNT(DISTINCT c.module_id) modules FROM capabilities c WHERE c.is_active=1 GROUP BY c.slug HAVING COUNT(DISTINCT c.module_id)>1 ORDER BY c.slug";
$checks['Stale verified facts over 365 days']="SELECT p.slug product_slug,c.slug capability_slug,pc.last_verified_at FROM product_capabilities pc JOIN products p ON p.id=pc.product_id JOIN capabilities c ON c.id=pc.capability_id WHERE p.status='active' AND pc.edition_id IS NULL AND pc.last_verified_at IS NOT NULL AND pc.last_verified_at < DATE_SUB(NOW(),INTERVAL 365 DAY) ORDER BY pc.last_verified_at";

$warningCount=0;
foreach($checks as $name=>$sql){
  $result=rows($pdo,$sql);
  echo "[$name]\n";
  if(!$result){ line('PASS','none'); echo "\n"; continue; }
  $warningCount+=count($result);
  foreach($result as $r){$parts=[];foreach($r as $k=>$v)$parts[]="$k=$v";line('WARN',implode('  ',$parts));}
  echo "\n";
}

$coverage=rows($pdo,"SELECT c.slug category_slug,
 COUNT(DISTINCT p.id) active_products,
 COUNT(DISTINCT cp.id) capabilities,
 COUNT(DISTINCT CASE WHEN pc.id IS NOT NULL THEN CONCAT(p.id,':',cp.id) END) recorded_fact_pairs,
 COUNT(DISTINCT CASE WHEN pc.support_status NOT IN ('unknown','not_yet_verified') THEN CONCAT(p.id,':',cp.id) END) known_fact_pairs
 FROM categories c
 LEFT JOIN products p ON p.category_id=c.id AND p.status='active'
 LEFT JOIN modules m ON m.category_id=c.id AND m.is_active=1
 LEFT JOIN capabilities cp ON cp.module_id=m.id AND cp.is_active=1
 LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=cp.id AND pc.edition_id IS NULL
 WHERE c.is_active=1
 GROUP BY c.id,c.slug ORDER BY c.slug");

echo "[Category evidence parity]\n";
foreach($coverage as $r){
  $expected=(int)$r['active_products']*(int)$r['capabilities'];
  $recorded=(int)$r['recorded_fact_pairs'];$known=(int)$r['known_fact_pairs'];
  $recordedPct=$expected?round($recorded/$expected*100,1):0;$knownPct=$expected?round($known/$expected*100,1):0;
  $status=$knownPct>=80?'PASS':($knownPct>=60?'INFO':'WARN');
  line($status,"{$r['category_slug']} products={$r['active_products']} capabilities={$r['capabilities']} recorded_matrix={$recordedPct}% known_evidence={$knownPct}%");
}
echo "\n";

$productCoverage=rows($pdo,"SELECT p.slug product_slug,c.slug category_slug,
 COUNT(DISTINCT cp.id) category_capabilities,
 COUNT(DISTINCT CASE WHEN pc.id IS NOT NULL THEN cp.id END) recorded_facts,
 COUNT(DISTINCT CASE WHEN pc.support_status NOT IN ('unknown','not_yet_verified') THEN cp.id END) known_facts,
 SUM(CASE WHEN pc.support_status IN ('unknown','not_yet_verified') THEN 1 ELSE 0 END) explicit_unknown_facts,
 MAX(pc.last_verified_at) last_verified_at
 FROM products p
 JOIN categories c ON c.id=p.category_id
 LEFT JOIN modules m ON m.category_id=c.id AND m.is_active=1
 LEFT JOIN capabilities cp ON cp.module_id=m.id AND cp.is_active=1
 LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=cp.id AND pc.edition_id IS NULL
 WHERE p.status='active'
 GROUP BY p.id,p.slug,c.slug
 ORDER BY c.slug,p.slug");

echo "[Product evidence coverage]\n";
foreach($productCoverage as $r){
  $expected=(int)$r['category_capabilities'];$recorded=(int)$r['recorded_facts'];$known=(int)$r['known_facts'];
  $recordedPct=$expected?round($recorded/$expected*100,1):0;$knownPct=$expected?round($known/$expected*100,1):0;
  $status=$knownPct>=80?'PASS':($knownPct>=60?'INFO':'WARN');
  if($status==='WARN')$warningCount++;
  line($status,"{$r['category_slug']}/{$r['product_slug']} known={$known}/{$expected} ({$knownPct}%) recorded={$recorded}/{$expected} ({$recordedPct}%) explicit_unknown={$r['explicit_unknown_facts']} last_verified=".($r['last_verified_at']?:'never'));
}
echo "\n";

line('INFO','Interpretation: missing product_capability rows are not unsupported; runtime scoring treats them as not_yet_verified.');
line('INFO','Products with low known-evidence coverage can therefore cluster around similar fit scores. Enrich evidence before broad promotion.');
$weights="functional=35 mandatory=20 integration=15 deployment=10 budget=10 regional=5 security=5";
line('INFO',"Runtime Scoring.php weights currently expected: $weights");
line('INFO','Review these against the approved methodology before changing production ranking behavior.');
echo "\n";

if($warningCount===0){line('PASS','No catalog integrity or evidence-parity warnings detected.');exit(0);}
line('WARN',"$warningCount catalog quality/evidence-parity warning(s) detected. Review before production catalog promotion.");
exit(2);
