<?php
final class RfpGenerator {
  public static function build(PDO $pdo,array $project,?array $matrix,array $selectedProductIds=[]):array{
    $pid=(int)$project['id'];
    $rq=$pdo->prepare("SELECT requirement_text,priority,is_mandatory,source,user_confirmed FROM selection_project_requirements WHERE project_id=? AND user_confirmed=1 ORDER BY is_mandatory DESC,id");$rq->execute([$pid]);$req=$rq->fetchAll();
    $iq=$pdo->prepare("SELECT integration_name,priority,is_mandatory,source,user_confirmed FROM selection_project_integrations WHERE project_id=? AND user_confirmed=1 ORDER BY is_mandatory DESC,id");$iq->execute([$pid]);$ints=$iq->fetchAll();
    $assumptions=[];foreach($req as $r)if(($r['source']??'')!=='user_entered')$assumptions[]=$r['requirement_text'];
    $criteria=$matrix['weights']??[];
    $sections=[
      'company_project_background'=>trim(($project['industry_text']?'Industry: '.$project['industry_text']."\n":'').($project['company_size_band']?'Company size: '.$project['company_size_band']."\n":'').($project['expected_users']?'Expected users: '.$project['expected_users']:'')),
      'objectives_scope'=>(string)($project['strategic_objectives']??''),
      'functional_requirements'=>array_values(array_map(fn($r)=>['text'=>$r['requirement_text'],'mandatory'=>(bool)$r['is_mandatory'],'priority'=>$r['priority'],'source'=>$r['source']],$req)),
      'technical_integrations'=>array_values(array_map(fn($r)=>['name'=>$r['integration_name'],'mandatory'=>(bool)$r['is_mandatory'],'priority'=>$r['priority'],'source'=>$r['source']],$ints)),
      'security_compliance'=>json_decode((string)($project['security_compliance_json']??'[]'),true)?:[],
      'deployment_requirements'=>(string)($project['deployment_preference']??''),
      'implementation_expectations'=>['capacity'=>$project['implementation_capacity']??null,'timeline'=>$project['implementation_timeline']??null],
      'migration_data_requirements'=>'Vendor should describe migration approach, data mapping, validation, rollback, and cutover assumptions applicable to the proposed solution.',
      'support_sla_requirements'=>(string)($project['support_requirements']??''),
      'training_adoption_expectations'=>'Vendor should describe training, knowledge transfer, administrator enablement, user adoption, and post-go-live support approach.',
      'pricing_response_template'=>['currency'=>$project['budget_currency']??null,'period'=>$project['budget_period']??null,'requested_breakdown'=>['licenses/subscriptions','implementation','integration','migration','training','support','optional/add-ons']],
      'vendor_questionnaire'=>['architecture and hosting model','security/compliance evidence','integration approach','implementation team and timeline','support model and SLA','commercial assumptions and exclusions'],
      'response_instructions'=>'Respond against each requirement as Supported, Partially Supported, Not Supported, Add-on, Third-party Integration, or Requires Custom Configuration, with evidence and assumptions.',
      'evaluation_criteria'=>$criteria,
      'assumptions_requiring_confirmation'=>$assumptions,
      'procurement_boundary'=>'This RFP supports software evaluation only. Bid submission, supplier onboarding, purchasing approvals, PO creation, invoicing, and procurement execution remain outside TechSelectAI.'
    ];
    return ['sections'=>$sections,'source_snapshot'=>['project_id'=>$pid,'project_version'=>(int)$project['version'],'matrix_run_id'=>$matrix['id']??null,'matrix_scoring_version'=>$matrix['scoring_version']??null,'selected_product_ids'=>array_values(array_map('intval',$selectedProductIds))]];
  }
}
