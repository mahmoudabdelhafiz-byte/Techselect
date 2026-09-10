<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/Scoring.php';
require_once __DIR__.'/../app/lib/CategoryGuard.php';

$pdo=Db::pdo();
$warnings=0;

function check_line(bool $ok,string $label,string $detail=''): void {
  global $warnings;
  echo ($ok?'PASS ':'WARN ').$label.($detail!==''?' — '.$detail:'')."\n";
  if(!$ok)$warnings++;
}

$categories=$pdo->query("SELECT id,slug,name FROM categories WHERE is_active=1 ORDER BY slug")->fetchAll(PDO::FETCH_ASSOC);
$allowed=array_column($categories,'slug');
$bySlug=[];foreach($categories as $c)$bySlug[$c['slug']]=$c;

$cases=[
  'crm'=>[
    'prompt'=>'Looking for CRM software',
    'anchor'=>'crm-lead-management',
    'min_products'=>7,
  ],
  'hr-hcm'=>[
    'prompt'=>'We need an HRMS for our company',
    'anchor'=>'hr-core-employee-records',
    'min_products'=>7,
  ],
  'itsm'=>[
    'prompt'=>'Need an ITSM service desk solution',
    'anchor'=>'itsm-incident-management',
    'min_products'=>6,
  ],
  'erp'=>[
    'prompt'=>'Looking for ERP software',
    'anchor'=>'erp-financial-accounting',
    'min_products'=>6,
  ],
  'project-management'=>[
    'prompt'=>'Need project management software',
    'anchor'=>'pm-task-management',
    'min_products'=>7,
  ],
  'corporate-identity-digital-business-cards'=>[
    'prompt'=>'Need digital business cards for employees',
    'anchor'=>'company-managed-digital-business-cards',
    'min_products'=>6,
  ],
];

echo "TechSelectAI cross-category recommendation validation\n";
echo str_repeat('=',52)."\n\n";

foreach($cases as $slug=>$case){
  echo "[$slug]\n";
  check_line(isset($bySlug[$slug]),'Category exists');
  if(!isset($bySlug[$slug])){echo "\n";continue;}

  $detected=CategoryGuard::detectExplicit([], $case['prompt'], $allowed);
  check_line($detected===$slug,'Explicit category detection','detected='.($detected??'null'));

  $st=$pdo->prepare("SELECT COUNT(*) FROM products WHERE status='active' AND category_id=?");
  $st->execute([$bySlug[$slug]['id']]);
  $count=(int)$st->fetchColumn();
  check_line($count>=$case['min_products'],'Active product coverage','count='.$count.', expected >= '.$case['min_products']);

  $st=$pdo->prepare("SELECT c.id FROM capabilities c JOIN modules m ON m.id=c.module_id WHERE c.slug=? AND c.is_active=1 AND m.category_id=? LIMIT 1");
  $st->execute([$case['anchor'],$bySlug[$slug]['id']]);
  $capId=$st->fetchColumn();
  check_line((bool)$capId,'Anchor capability belongs to category',$case['anchor']);

  if($capId){
    $st=$pdo->prepare("SELECT p.id,p.name,p.slug,COALESCE(pc.support_status,'not_yet_verified') support_status,COALESCE(pc.confidence_score,0) confidence_score FROM products p LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=? AND pc.edition_id IS NULL WHERE p.status='active' AND p.category_id=? ORDER BY p.name");
    $st->execute([$capId,$bySlug[$slug]['id']]);
    $products=$st->fetchAll(PDO::FETCH_ASSOC);
    $known=0;$scored=[];
    foreach($products as $p){
      if(!in_array($p['support_status'],['unknown','not_yet_verified'],true))$known++;
      $rows=[['priority'=>'must_have','is_mandatory'=>1,'support_status'=>$p['support_status']]];
      $functional=Scoring::weighted($rows);
      $mandatory=Scoring::mustHave($rows);
      $scored[]=['name'=>$p['name'],'score'=>Scoring::overall(['functional'=>$functional,'mandatory'=>$mandatory]),'confidence'=>(float)$p['confidence_score']];
    }
    usort($scored,function($a,$b){if($a['score']!==$b['score'])return $b['score']<=>$a['score'];return $b['confidence']<=>$a['confidence'];});
    check_line($known>0,'Anchor has verified product facts','known='.$known.' / '.$count);
    check_line(!empty($scored),'Category-scoped scoring returns candidates',!empty($scored)?'top='.$scored[0]['name'].' '.$scored[0]['score'].'%':'none');
  }
  echo "\n";
}

// Integrity: product capability facts should not cross category boundaries.
$sql="SELECT COUNT(*) FROM product_capabilities pc JOIN products p ON p.id=pc.product_id JOIN capabilities c ON c.id=pc.capability_id JOIN modules m ON m.id=c.module_id WHERE pc.edition_id IS NULL AND p.category_id<>m.category_id";
$crossFacts=(int)$pdo->query($sql)->fetchColumn();
check_line($crossFacts===0,'No cross-category capability facts','count='.$crossFacts);

// Guardrail context locking: once CRM is explicit, a later budget message must not switch it.
$context=[['sender_type'=>'user','message_text'=>'Looking for CRM']];
$detected=CategoryGuard::detectExplicit($context,'In KSA with budget 10 USD per user',$allowed);
check_line($detected==='crm','Context keeps explicit CRM category','detected='.($detected??'null'));

// Mixed request: CRM remains primary when identity is secondary in the same sentence.
$detected=CategoryGuard::detectExplicit([], 'Need CRM with employee identity verification',$allowed);
check_line($detected==='crm','Primary explicit category wins in mixed CRM + identity request','detected='.($detected??'null'));

echo "\n".($warnings===0?'RESULT: CLEAN':'RESULT: '.$warnings.' warning(s)')."\n";
exit($warnings===0?0:2);
