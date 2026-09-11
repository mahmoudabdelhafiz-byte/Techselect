<?php
require_once __DIR__.'/../app/lib/Db.php';

$pdo=Db::pdo();
$categorySlug='corporate-identity-digital-business-cards';
$tracked=['cardiq','blinq','hihello','popl','uniqode','mobilo'];

function parityLine(string $status,string $message): void { echo str_pad($status,7).' '.$message."\n"; }
function parityFail(string $message): void { parityLine('FAIL',$message); $GLOBALS['parityFailures']++; }
$GLOBALS['parityFailures']=0;

$cat=$pdo->prepare("SELECT id FROM categories WHERE slug=? AND is_active=1 LIMIT 1");
$cat->execute([$categorySlug]);
$categoryId=(int)$cat->fetchColumn();
if(!$categoryId){ parityFail("active category missing: $categorySlug"); exit(1); }

$capCountQ=$pdo->prepare("SELECT COUNT(*) FROM capabilities c JOIN modules m ON m.id=c.module_id WHERE m.category_id=? AND c.is_active=1 AND m.is_active=1");
$capCountQ->execute([$categoryId]);
$capabilityCount=(int)$capCountQ->fetchColumn();
if($capabilityCount<1){ parityFail('identity category has no active capabilities'); exit(1); }

parityLine('INFO',"identity capabilities=$capabilityCount");

$productQ=$pdo->prepare("SELECT id,name,slug FROM products WHERE category_id=? AND status='active' AND slug IN (?,?,?,?,?,?) ORDER BY slug");
$productQ->execute(array_merge([$categoryId],$tracked));
$products=$productQ->fetchAll(PDO::FETCH_ASSOC);
$found=array_column($products,'slug');
foreach($tracked as $slug){ if(!in_array($slug,$found,true)) parityFail("tracked active product missing: $slug"); }

$coverageQ=$pdo->prepare("SELECT
 COUNT(pc.id) recorded_rows,
 SUM(CASE WHEN pc.support_status NOT IN ('unknown','not_yet_verified') THEN 1 ELSE 0 END) known_rows,
 SUM(CASE WHEN pc.support_status IN ('unknown','not_yet_verified') OR pc.id IS NULL THEN 1 ELSE 0 END) unknown_rows,
 SUM(CASE WHEN pc.id IS NOT NULL AND pc.support_status NOT IN ('unknown','not_yet_verified') AND EXISTS(
   SELECT 1 FROM product_capability_evidence pce WHERE pce.product_capability_id=pc.id
 ) THEN 1 ELSE 0 END) known_with_evidence
 FROM capabilities c
 JOIN modules m ON m.id=c.module_id
 LEFT JOIN product_capabilities pc ON pc.capability_id=c.id AND pc.product_id=? AND pc.edition_id IS NULL
 WHERE m.category_id=? AND c.is_active=1 AND m.is_active=1");

$coverage=[];
foreach($products as $p){
  $coverageQ->execute([(int)$p['id'],$categoryId]);
  $r=$coverageQ->fetch(PDO::FETCH_ASSOC)?:[];
  $known=(int)($r['known_rows']??0);
  $unknown=(int)($r['unknown_rows']??0);
  $withEvidence=(int)($r['known_with_evidence']??0);
  $pct=$capabilityCount?round($known/$capabilityCount*100,1):0;
  $coverage[$p['slug']]=$pct;
  parityLine('INFO',sprintf('%-8s known=%d/%d (%0.1f%%) unknown=%d evidence_linked_known=%d',$p['slug'],$known,$capabilityCount,$pct,$unknown,$withEvidence));
  if($known>0 && $withEvidence<$known){ parityFail("{$p['slug']} has explicit known capability facts without evidence links"); }
}

// Facts introduced by migration 024 must remain explicit and evidence-linked.
$expected=[
 ['blinq','meeting-backgrounds','supported'],
 ['blinq','manual-offboarding-control','supported'],
 ['blinq','lead-capture','supported'],
 ['blinq','engagement-analytics','supported'],
 ['hihello','manual-offboarding-control','supported'],
 ['uniqode','automated-deprovisioning','supported'],
 ['uniqode','manual-offboarding-control','supported'],
];
$factQ=$pdo->prepare("SELECT pc.support_status,COUNT(pce.id) evidence_links
 FROM products p JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL
 JOIN capabilities c ON c.id=pc.capability_id
 LEFT JOIN product_capability_evidence pce ON pce.product_capability_id=pc.id
 WHERE p.slug=? AND c.slug=? GROUP BY pc.id,pc.support_status LIMIT 1");
foreach($expected as [$product,$capability,$status]){
  $factQ->execute([$product,$capability]);
  $r=$factQ->fetch(PDO::FETCH_ASSOC);
  if(!$r){ parityFail("missing expected fact: $product / $capability"); continue; }
  if((string)$r['support_status']!==$status){ parityFail("unexpected status for $product / $capability: {$r['support_status']}"); }
  if((int)$r['evidence_links']<1){ parityFail("missing evidence link for $product / $capability"); }
}

// Guard against a future bulk change that makes all competitors look artificially identical.
$competitorCoverage=[];
foreach(['blinq','hihello','popl','uniqode','mobilo'] as $slug){ if(isset($coverage[$slug])) $competitorCoverage[$slug]=$coverage[$slug]; }
if(count($competitorCoverage)>=3 && count(array_unique(array_values($competitorCoverage),SORT_REGULAR))===1){
  parityFail('all tracked competitors have identical known-fact coverage; investigate placeholder-style bulk seeding');
}

if($GLOBALS['parityFailures']){
  parityLine('FAIL',$GLOBALS['parityFailures'].' evidence parity regression(s) detected.');
  exit(1);
}
parityLine('PASS','Identity evidence parity checks passed. Unknown remains distinct from unsupported.');
