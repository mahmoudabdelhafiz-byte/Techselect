<?php
require_once __DIR__.'/Scoring.php';

final class ProjectDecisionMatrix {
  private const VERSION='project-fit-v1.0';
  private const DEFAULT_WEIGHTS=[
    'functional'=>35.0,'mandatory'=>20.0,'integration'=>10.0,'security'=>10.0,
    'deployment'=>10.0,'commercial'=>7.0,'regional'=>5.0,'implementation'=>3.0,
  ];
  private const STATES=['researching','shortlisted','rejected','preferred'];

  public static function defaultWeights():array{return self::DEFAULT_WEIGHTS;}
  public static function version():string{return self::VERSION;}
  public static function states():array{return self::STATES;}

  public static function normalizeWeights(array $input,bool $allowOverride):array{
    if(!$allowOverride)return self::DEFAULT_WEIGHTS;
    $out=self::DEFAULT_WEIGHTS;
    foreach($out as $k=>$v){if(array_key_exists($k,$input))$out[$k]=max(0.0,min(100.0,(float)$input[$k]));}
    if(array_sum($out)<=0)$out=self::DEFAULT_WEIGHTS;
    return $out;
  }

  public static function weightedOverall(array $dims,array $weights):float{
    $sum=0.0;$used=0.0;
    foreach($weights as $k=>$w){if($w<=0||!array_key_exists($k,$dims)||$dims[$k]===null)continue;$v=max(0,min(100,(float)$dims[$k]));$sum+=$v*$w;$used+=$w;}
    return $used>0?round($sum/$used,2):0.0;
  }

  public static function generate(PDO $pdo,array $project,array $weights):array{
    $pid=(int)$project['id'];
    $req=$pdo->prepare("SELECT spr.id,spr.capability_id,spr.requirement_text,spr.priority,spr.is_mandatory,mo.category_id FROM selection_project_requirements spr JOIN capabilities cap ON cap.id=spr.capability_id JOIN modules mo ON mo.id=cap.module_id WHERE spr.project_id=? AND spr.user_confirmed=1 AND spr.capability_id IS NOT NULL");
    $req->execute([$pid]);$all=$req->fetchAll();
    if(!$all)throw new RuntimeException('confirmed_capability_requirements_required');
    $categoryIds=array_values(array_unique(array_map('intval',array_column($all,'category_id'))));
    if(count($categoryIds)!==1)throw new RuntimeException('single_primary_category_required');
    $categoryId=$categoryIds[0];$requirements=array_values(array_filter($all,fn($r)=>(int)$r['category_id']===$categoryId));
    $ints=$pdo->prepare("SELECT integration_id,priority,is_mandatory,integration_name FROM selection_project_integrations WHERE project_id=? AND user_confirmed=1");$ints->execute([$pid]);$wantedInts=$ints->fetchAll();
    $pq=$pdo->prepare("SELECT p.id,p.name,p.slug,v.name vendor FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.status='active' AND p.category_id=? ORDER BY p.name");$pq->execute([$categoryId]);$products=$pq->fetchAll();
    if(!$products)throw new RuntimeException('no_active_products_for_category');

    $fact=$pdo->prepare("SELECT support_status,confidence_score FROM product_capabilities WHERE product_id=? AND capability_id=? AND edition_id IS NULL LIMIT 1");
    $intFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_integrations WHERE product_id=? AND integration_id=? LIMIT 1");
    $depId=null;if(!empty($project['deployment_preference'])){$d=$pdo->prepare("SELECT id FROM deployment_models WHERE LOWER(name)=LOWER(?) OR slug=? LIMIT 1");$slug=strtolower(preg_replace('/[^a-z0-9]+/i','-',trim((string)$project['deployment_preference'])));$d->execute([$project['deployment_preference'],$slug]);$depId=$d->fetchColumn()?:null;}
    $depFact=$pdo->prepare("SELECT support_status FROM product_deployments WHERE product_id=? AND deployment_model_id=? LIMIT 1");
    $price=$pdo->prepare("SELECT amount_min,currency FROM product_pricing WHERE product_id=? ORDER BY COALESCE(amount_min,999999999) ASC LIMIT 1");
    $countryCodes=json_decode((string)($project['country_codes_json']??'[]'),true);$country=is_array($countryCodes)&&!empty($countryCodes[0])?strtoupper((string)$countryCodes[0]):null;
    $regional=$pdo->prepare("SELECT pra.availability_status FROM product_regional_availability pra JOIN countries c ON c.id=pra.country_id WHERE pra.product_id=? AND c.code=? LIMIT 1");
    $securityInput=json_decode((string)($project['security_compliance_json']??'[]'),true);$securityText=mb_strtolower(implode(' ',is_array($securityInput)?$securityInput:[]));
    $standards=$pdo->query("SELECT id,name,slug FROM compliance_standards WHERE is_active=1 ORDER BY id")->fetchAll();$requestedStandards=[];
    foreach($standards as $s){$name=mb_strtolower((string)$s['name']);$slug=mb_strtolower(str_replace('-',' ',(string)$s['slug']));if($securityText!==''&&(mb_stripos($securityText,$name)!==false||mb_stripos($securityText,$slug)!==false))$requestedStandards[]=$s;}
    $complianceFact=$pdo->prepare("SELECT support_status,confidence_score FROM product_compliance WHERE product_id=? AND compliance_standard_id=? LIMIT 1");

    $results=[];
    foreach($products as $p){
      $rows=[];$evidence=[];
      foreach($requirements as $r){$fact->execute([$p['id'],$r['capability_id']]);$f=$fact->fetch();$status=$f['support_status']??'not_yet_verified';$priority=$r['is_mandatory']?'must_have':($r['priority']==='important'?'important':'nice_to_have');$rows[]=['requirement_id'=>(int)$r['id'],'text'=>$r['requirement_text'],'priority'=>$priority,'is_mandatory'=>(int)$r['is_mandatory'],'support_status'=>$status];$evidence[]=(float)($f['confidence_score']??0);}
      $dims=['functional'=>Scoring::weighted($rows),'mandatory'=>Scoring::mustHave($rows),'integration'=>null,'security'=>null,'deployment'=>null,'commercial'=>null,'regional'=>null,'implementation'=>null];
      $gaps=Scoring::mandatoryGaps($rows);
      if($wantedInts){$vals=[];foreach($wantedInts as $wi){if(empty($wi['integration_id']))continue;$intFact->execute([$p['id'],$wi['integration_id']]);$f=$intFact->fetch();$vals[]=Scoring::support($f['support_status']??'not_yet_verified')*100;}$dims['integration']=$vals?round(array_sum($vals)/count($vals),2):null;}
      if($depId){$depFact->execute([$p['id'],$depId]);$f=$depFact->fetch();$dims['deployment']=round(Scoring::support($f['support_status']??'not_yet_verified')*100,2);}
      if(!empty($project['budget_max'])){$price->execute([$p['id']]);$pr=$price->fetch();if($pr&&$pr['amount_min']!==null){$ratio=(float)$pr['amount_min']/(float)$project['budget_max'];$dims['commercial']=$ratio<=.8?100:($ratio<=1?90:($ratio<=1.2?65:($ratio<=1.5?35:10)));}else $dims['commercial']=40;}
      if($country){$regional->execute([$p['id'],$country]);$rf=$regional->fetch();$dims['regional']=round(Scoring::regional($rf['availability_status']??'not_yet_verified')*100,2);}
      $complianceRows=[];if($requestedStandards){$vals=[];foreach($requestedStandards as $s){$complianceFact->execute([$p['id'],$s['id']]);$cf=$complianceFact->fetch();$status=$cf['support_status']??'not_yet_verified';$vals[]=Scoring::support($status)*100;$complianceRows[]=['slug'=>$s['slug'],'name'=>$s['name'],'support_status'=>$status];}$dims['security']=round(array_sum($vals)/count($vals),2);}
      $fit=self::weightedOverall($dims,$weights);
      $contrib=[];$usedWeight=0;foreach($weights as $k=>$w){if(($dims[$k]??null)!==null&&$w>0)$usedWeight+=$w;}foreach($weights as $k=>$w){$contrib[$k]=($usedWeight>0&&($dims[$k]??null)!==null)?round(((float)$dims[$k]*$w)/$usedWeight,2):null;}
      $tradeoffs=[];foreach($dims as $k=>$v){if($v!==null&&$v<60)$tradeoffs[]=$k.' fit is weak or insufficiently verified';}
      if($gaps)$tradeoffs[]=$gaps.' mandatory requirement(s) remain unresolved';
      $results[]=['product'=>$p,'project_fit_score'=>$fit,'baseline_evaluation_score'=>null,'baseline_evaluation_status'=>'not_available_in_current_model','mandatory_gap_count'=>$gaps,'dimensions'=>$dims,'contributions'=>$contrib,'tradeoffs'=>$tradeoffs,'requirements'=>$rows,'requested_compliance'=>$complianceRows,'partner_options'=>[],'partner_note'=>'Verified local partner data is not yet available in the current marketplace model.'];
    }
    usort($results,fn($a,$b)=>$a['mandatory_gap_count']<=>$b['mandatory_gap_count'] ?: $b['project_fit_score']<=>$a['project_fit_score'] ?: strcmp($a['product']['name'],$b['product']['name']));
    foreach($results as $i=>&$r)$r['rank']=$i+1;unset($r);
    return ['scoring_version'=>self::VERSION,'category_id'=>$categoryId,'weights'=>$weights,'requested_compliance'=>array_column($requestedStandards,'slug'),'results'=>$results];
  }
}
