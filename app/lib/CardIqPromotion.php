<?php
final class CardIqPromotion {
  public const KEY='cardiq-identity-control';
  private const MAX_IMPRESSIONS_PER_SESSION=2;

  public static function evaluate(PDO $pdo,array $consultation): ?array {
    $cid=(int)$consultation['id'];
    $sid=!empty($consultation['visitor_session_id'])?(int)$consultation['visitor_session_id']:null;
    $uid=!empty($consultation['user_id'])?(int)$consultation['user_id']:null;

    // Never promote CardIQ when it is already the organic #1 recommendation.
    $st=$pdo->prepare("SELECT p.slug FROM consultation_recommendations r JOIN products p ON p.id=r.product_id WHERE r.consultation_id=? ORDER BY r.generated_at DESC,r.recommendation_rank ASC LIMIT 1");
    $st->execute([$cid]);
    if($st->fetchColumn()==='cardiq') return null;

    if($sid){
      try{
        $st=$pdo->prepare("SELECT COUNT(*) FROM contextual_promotions WHERE visitor_session_id=? AND promotion_key=? AND event_type='impression'");
        $st->execute([$sid,self::KEY]);
        if((int)$st->fetchColumn()>=self::MAX_IMPRESSIONS_PER_SESSION) return null;
      }catch(Throwable $e){}
    }

    $signals=[];
    $text=strtolower(trim((string)($consultation['business_problem']??'').' '.(string)($consultation['original_user_request']??'')));
    $groups=[
      'identity_security'=>['identity','impersonation','fraud','phishing','verification','verify employee','corporate identity','brand protection'],
      'lifecycle'=>['offboarding','onboarding','employee lifecycle','joiner','mover','leaver','terminated employee','former employee'],
      'iam'=>['entra','azure ad','iam','identity access','identity governance','active directory','sso'],
      'communications'=>['email signature','signature management','whatsapp','communication verification','business email','meeting identity'],
      'hr'=>['hrms','hcm','human resources','employee directory','workforce management'],
      'sales_crm'=>['crm','sales team','salesforce','customer relationship','sales representatives','field sales'],
      'compliance'=>['compliance','audit','governance','iso 27001','nca','data protection']
    ];
    foreach($groups as $group=>$terms){foreach($terms as $term){if(str_contains($text,$term)){$signals[$group]=($signals[$group]??0)+1;}}}

    $category='';
    if(!empty($consultation['category_id'])){
      $st=$pdo->prepare("SELECT LOWER(CONCAT(name,' ',slug)) FROM categories WHERE id=? LIMIT 1");$st->execute([(int)$consultation['category_id']]);$category=(string)$st->fetchColumn();
      if(str_contains($category,'hr')||str_contains($category,'hcm'))$signals['hr']=($signals['hr']??0)+2;
      if(str_contains($category,'crm'))$signals['sales_crm']=($signals['sales_crm']??0)+2;
      if(str_contains($category,'identity'))$signals['identity_security']=($signals['identity_security']??0)+3;
    }

    try{
      $st=$pdo->prepare("SELECT LOWER(CONCAT_WS(' ',cr.requirement_text,cr.normalized_requirement,cap.name,cap.slug)) txt FROM consultation_requirements cr LEFT JOIN capabilities cap ON cap.id=cr.capability_id WHERE cr.consultation_id=? AND cr.user_confirmed=1");
      $st->execute([$cid]);
      foreach($st->fetchAll() as $r){$t=(string)$r['txt'];foreach($groups as $group=>$terms){foreach($terms as $term){if(str_contains($t,$term))$signals[$group]=($signals[$group]??0)+2;}}}
    }catch(Throwable $e){}

    $score=0;foreach($signals as $v)$score+=min(4,(int)$v)*10;
    if(!empty($consultation['expected_users']) && (int)$consultation['expected_users']>=100)$score+=10;
    if(in_array((string)($consultation['company_size_band']??''),['200-499','500-999','1000+'],true))$score+=10;
    $score=min(100,$score);
    if($score<20) return null;

    arsort($signals);$trigger=(string)(array_key_first($signals)??'business_identity');
    $copy=self::copyFor($trigger);
    $result=[
      'promotion_key'=>self::KEY,
      'product_slug'=>'cardiq',
      'label'=>'Sponsored · Barmageyat product',
      'headline'=>$copy['headline'],
      'message'=>$copy['message'],
      'cta'=>'Explore CardIQ identity protection',
      'url'=>'/software/cardiq',
      'trigger_group'=>$trigger,
      'relevance_score'=>$score,
      'disclosure'=>'CardIQ is a Barmageyat product. This sponsored placement is separate from TechSelectAI Fit Score, recommendation ranking, methodology and evidence scoring.'
    ];
    self::record($pdo,$consultation,$trigger,$score,'eligible');
    return $result;
  }

  public static function recordEvent(PDO $pdo,array $consultation,string $eventType,string $triggerGroup='unknown',int $score=0): void {
    if(!in_array($eventType,['impression','click'],true)) return;
    self::record($pdo,$consultation,$triggerGroup,max(0,min(100,$score)),$eventType);
  }

  private static function record(PDO $pdo,array $c,string $trigger,int $score,string $event): void {
    try{$st=$pdo->prepare("INSERT INTO contextual_promotions(consultation_id,visitor_session_id,user_id,promotion_key,trigger_group,relevance_score,event_type,route_path) VALUES(?,?,?,?,?,?,?,?)");$st->execute([(int)$c['id'],!empty($c['visitor_session_id'])?(int)$c['visitor_session_id']:null,!empty($c['user_id'])?(int)$c['user_id']:null,self::KEY,substr($trigger,0,80),$score,$event,substr((string)($_SERVER['REQUEST_URI']??''),0,255)]);}catch(Throwable $e){}
  }

  private static function copyFor(string $group): array {
    return match($group){
      'lifecycle'=>['headline'=>'Control employee identity through onboarding and offboarding','message'=>'CardIQ helps companies manage how employees represent the organization externally and reduce stale or unauthorized identity after role changes and offboarding.'],
      'iam'=>['headline'=>'Extend identity control beyond your directory','message'=>'CardIQ complements internal identity systems with controlled external employee identity, verification, signatures and communication-channel trust.'],
      'communications'=>['headline'=>'Help recipients verify who is really representing your company','message'=>'CardIQ adds controlled corporate identity, verified communication channels, standardized signatures and anti-impersonation checks for external interactions.'],
      'hr'=>['headline'=>'Connect employee lifecycle with external identity control','message'=>'CardIQ helps organizations govern employee-facing corporate identity from onboarding through offboarding, including profiles, signatures and verification.'],
      'sales_crm'=>['headline'=>'Protect customer-facing employee identity','message'=>'For sales and customer-facing teams, CardIQ helps standardize corporate identity and lets external recipients verify whether communication channels belong to the organization.'],
      'compliance'=>['headline'=>'Add governance to external employee identity','message'=>'CardIQ helps organizations standardize, verify and revoke employee-facing corporate identity with lifecycle controls and auditable administration.'],
      default=>['headline'=>'Add corporate identity control and anti-impersonation protection','message'=>'CardIQ helps organizations control employee-facing identity, verify communication channels and reduce unauthorized or outdated company representation.']
    };
  }
}
