<?php
final class Entitlements {
  public const PUBLIC='public';
  public const REGISTERED='free_registered';
  public const PRO='pro';

  private const TIER_ORDER=[self::PUBLIC=>0,self::REGISTERED=>1,self::PRO=>2];

  private const FEATURES=[
    'software_search'=>self::PUBLIC,
    'public_product_profiles'=>self::PUBLIC,
    'public_evaluations'=>self::PUBLIC,
    'public_comparisons'=>self::PUBLIC,
    'public_methodology'=>self::PUBLIC,
    'public_partner_discovery'=>self::PUBLIC,
    'limited_ai_consultant'=>self::PUBLIC,

    'save_products'=>self::REGISTERED,
    'save_comparisons'=>self::REGISTERED,
    'persistent_shortlist'=>self::REGISTERED,
    'selection_projects'=>self::REGISTERED,
    'requirements_capture'=>self::REGISTERED,
    'saved_partner_options'=>self::REGISTERED,
    'resume_consultations'=>self::REGISTERED,
    'basic_decision_matrix'=>self::REGISTERED,
    'limited_exports'=>self::REGISTERED,
    'project_tracking'=>self::REGISTERED,

    'advanced_requirements_builder'=>self::PRO,
    'contextual_fit_scoring'=>self::PRO,
    'weighted_decision_matrix'=>self::PRO,
    'advanced_shortlist'=>self::PRO,
    'full_business_case'=>self::PRO,
    'roi_tco_model'=>self::PRO,
    'rfp_generator'=>self::PRO,
    'decision_pack'=>self::PRO,
    'rich_exports'=>self::PRO,
  ];

  public static function matrix():array{return self::FEATURES;}

  public static function tier(PDO $pdo,?array $user):string{
    if(!$user||empty($user['id']))return self::PUBLIC;
    $st=$pdo->prepare("SELECT plan_code,plan_status,expires_at FROM user_plan_assignments WHERE user_id=? LIMIT 1");
    $st->execute([(int)$user['id']]);
    $row=$st->fetch();
    if(!$row)return self::REGISTERED;
    if(($row['plan_status']??'')!=='active')return self::REGISTERED;
    if(!empty($row['expires_at'])&&strtotime((string)$row['expires_at'])<time())return self::REGISTERED;
    $code=(string)($row['plan_code']??self::REGISTERED);
    return isset(self::TIER_ORDER[$code])?$code:self::REGISTERED;
  }

  public static function context(PDO $pdo,?array $user):array{
    $tier=self::tier($pdo,$user);
    $features=[];
    foreach(self::FEATURES as $feature=>$required)$features[$feature]=self::tierRank($tier)>=self::tierRank($required);
    return ['tier'=>$tier,'authenticated'=>$user!==null,'features'=>$features];
  }

  public static function has(PDO $pdo,?array $user,string $feature):bool{
    if(!isset(self::FEATURES[$feature]))return false;
    return self::tierRank(self::tier($pdo,$user))>=self::tierRank(self::FEATURES[$feature]);
  }

  public static function requireFeature(PDO $pdo,?array $user,string $feature):void{
    if(!isset(self::FEATURES[$feature]))self::deny('unknown_feature',500,null);
    if(self::has($pdo,$user,$feature))return;
    $required=self::FEATURES[$feature];
    if($required!==self::PUBLIC&&$user===null)self::deny('authentication_required',401,$required);
    self::deny('upgrade_required',403,$required);
  }

  public static function requiredTier(string $feature):?string{return self::FEATURES[$feature]??null;}

  private static function tierRank(string $tier):int{return self::TIER_ORDER[$tier]??0;}
  private static function deny(string $error,int $status,?string $required):void{
    http_response_code($status);header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error'=>$error,'required_tier'=>$required],JSON_UNESCAPED_SLASHES);exit;
  }
}
