<?php
final class BuyerIntentAnalytics {
  public static function recordPublicEvent(PDO $pdo,string $eventType,array $data=[]): void {
    if(!in_array($eventType,['product_view','comparison_view'],true)) return;
    try {
      $userId=null;
      if(class_exists('Security')){$u=Security::user();if($u)$userId=(int)$u['id'];}
      $st=$pdo->prepare("INSERT INTO buyer_intent_events(user_id,consultation_id,event_type,category_id,product_id,related_product_id,route_path) VALUES(?,?,?,?,?,?,?)");
      $st->execute([$userId,isset($data['consultation_id'])?(int)$data['consultation_id']:null,$eventType,isset($data['category_id'])?(int)$data['category_id']:null,isset($data['product_id'])?(int)$data['product_id']:null,isset($data['related_product_id'])?(int)$data['related_product_id']:null,isset($data['route_path'])?substr((string)$data['route_path'],0,255):null]);
    } catch(Throwable $e) {}
  }

  public static function dashboard(PDO $pdo,int $days=30): array {
    $days=max(1,min(365,$days));$since=date('Y-m-d H:i:s',time()-$days*86400);
    $scalar=function(string $sql,array $params=[]) use($pdo){$st=$pdo->prepare($sql);$st->execute($params);return $st->fetchColumn();};
    $rows=function(string $sql,array $params=[]) use($pdo){$st=$pdo->prepare($sql);$st->execute($params);return $st->fetchAll()?:[];};
    $overview=[
      'consultations'=>(int)$scalar("SELECT COUNT(*) FROM consultations WHERE created_at>=?",[$since]),
      'completed'=>(int)$scalar("SELECT COUNT(*) FROM consultations WHERE created_at>=? AND completed_at IS NOT NULL",[$since]),
      'signed_in_consultations'=>(int)$scalar("SELECT COUNT(*) FROM consultations WHERE created_at>=? AND user_id IS NOT NULL",[$since]),
      'unique_signed_in_buyers'=>(int)$scalar("SELECT COUNT(DISTINCT user_id) FROM consultations WHERE created_at>=? AND user_id IS NOT NULL",[$since]),
      'repeat_buyers'=>(int)$scalar("SELECT COUNT(*) FROM (SELECT user_id FROM consultations WHERE created_at>=? AND user_id IS NOT NULL GROUP BY user_id HAVING COUNT(*)>1) x",[$since]),
      'recommendation_runs'=>(int)$scalar("SELECT COUNT(DISTINCT consultation_id) FROM consultation_recommendations WHERE generated_at>=?",[$since])
    ];
    $overview['completion_rate']=$overview['consultations']?round($overview['completed']/$overview['consultations']*100,1):0;
    $categories=$rows("SELECT COALESCE(cat.name,'Unconfirmed') label,COUNT(*) consultations,COUNT(DISTINCT c.user_id) signed_in_buyers FROM consultations c LEFT JOIN categories cat ON cat.id=c.category_id WHERE c.created_at>=? GROUP BY cat.id,cat.name ORDER BY consultations DESC,label LIMIT 15",[$since]);
    $requirements=$rows("SELECT COALESCE(cap.name,cr.normalized_requirement,LEFT(cr.requirement_text,120)) label,COUNT(*) demand_count,SUM(cr.is_mandatory=1) must_have_count FROM consultation_requirements cr LEFT JOIN capabilities cap ON cap.id=cr.capability_id JOIN consultations c ON c.id=cr.consultation_id WHERE c.created_at>=? AND cr.user_confirmed=1 GROUP BY cap.id,cap.name,cr.normalized_requirement,LEFT(cr.requirement_text,120) ORDER BY demand_count DESC,must_have_count DESC LIMIT 20",[$since]);
    $products=$rows("SELECT p.name,p.slug,COUNT(*) recommendation_count,ROUND(AVG(r.overall_score),1) avg_fit,SUM(r.recommendation_rank=1) top_rank_count FROM consultation_recommendations r JOIN products p ON p.id=r.product_id WHERE r.generated_at>=? GROUP BY p.id,p.name,p.slug ORDER BY recommendation_count DESC,top_rank_count DESC LIMIT 20",[$since]);
    $countries=[];$industries=[];$companySizes=[];
    try{$countries=$rows("SELECT COALESCE(c.country_code,vs.country_code,'Unknown') label,COUNT(*) consultations FROM consultations c LEFT JOIN visitor_sessions vs ON vs.id=c.visitor_session_id WHERE c.created_at>=? GROUP BY label ORDER BY consultations DESC LIMIT 15",[$since]);}catch(Throwable $e){}
    try{$industries=$rows("SELECT COALESCE(i.name,'Unknown') label,COUNT(*) consultations FROM consultations c LEFT JOIN industries i ON i.id=c.industry_id WHERE c.created_at>=? GROUP BY i.id,i.name ORDER BY consultations DESC LIMIT 15",[$since]);}catch(Throwable $e){}
    try{$companySizes=$rows("SELECT COALESCE(company_size_band,'Unknown') label,COUNT(*) consultations FROM consultations WHERE created_at>=? GROUP BY company_size_band ORDER BY consultations DESC LIMIT 15",[$since]);}catch(Throwable $e){}
    $views=[];$comparisons=[];
    try{$views=$rows("SELECT p.name,p.slug,COUNT(*) view_count FROM buyer_intent_events e JOIN products p ON p.id=e.product_id WHERE e.occurred_at>=? AND e.event_type='product_view' GROUP BY p.id,p.name,p.slug ORDER BY view_count DESC LIMIT 20",[$since]);$comparisons=$rows("SELECT p1.name product_a,p1.slug slug_a,p2.name product_b,p2.slug slug_b,COUNT(*) comparison_count FROM buyer_intent_events e JOIN products p1 ON p1.id=e.product_id JOIN products p2 ON p2.id=e.related_product_id WHERE e.occurred_at>=? AND e.event_type='comparison_view' GROUP BY p1.id,p1.name,p1.slug,p2.id,p2.name,p2.slug ORDER BY comparison_count DESC LIMIT 20",[$since]);}catch(Throwable $e){}
    $unmapped=[];try{$unmapped=$rows("SELECT normalized_topic label,demand_count,last_seen_at,status,priority FROM taxonomy_expansion_queue ORDER BY demand_count DESC,last_seen_at DESC LIMIT 20");}catch(Throwable $e){}

    $promotion=['available'=>false,'eligible'=>0,'impressions'=>0,'clicks'=>0,'ctr'=>0,'unique_consultations'=>0,'unique_sessions'=>0,'signed_in_impressions'=>0,'anonymous_impressions'=>0,'by_trigger'=>[],'by_category'=>[]];
    try{
      $promotion['eligible']=(int)$scalar("SELECT COUNT(*) FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND event_type='eligible' AND created_at>=?",[$since]);
      $promotion['impressions']=(int)$scalar("SELECT COUNT(*) FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND event_type='impression' AND created_at>=?",[$since]);
      $promotion['clicks']=(int)$scalar("SELECT COUNT(*) FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND event_type='click' AND created_at>=?",[$since]);
      $promotion['ctr']=$promotion['impressions']?round($promotion['clicks']/$promotion['impressions']*100,1):0;
      $promotion['unique_consultations']=(int)$scalar("SELECT COUNT(DISTINCT consultation_id) FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND event_type='impression' AND created_at>=?",[$since]);
      $promotion['unique_sessions']=(int)$scalar("SELECT COUNT(DISTINCT visitor_session_id) FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND event_type='impression' AND visitor_session_id IS NOT NULL AND created_at>=?",[$since]);
      $promotion['signed_in_impressions']=(int)$scalar("SELECT COUNT(*) FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND event_type='impression' AND user_id IS NOT NULL AND created_at>=?",[$since]);
      $promotion['anonymous_impressions']=$promotion['impressions']-$promotion['signed_in_impressions'];
      $promotion['by_trigger']=$rows("SELECT trigger_group label,SUM(event_type='impression') impressions,SUM(event_type='click') clicks,ROUND(CASE WHEN SUM(event_type='impression')>0 THEN SUM(event_type='click')/SUM(event_type='impression')*100 ELSE 0 END,1) ctr FROM contextual_promotions WHERE promotion_key='cardiq-identity-control' AND created_at>=? AND event_type IN ('impression','click') GROUP BY trigger_group ORDER BY impressions DESC,clicks DESC LIMIT 12",[$since]);
      $promotion['by_category']=$rows("SELECT COALESCE(cat.name,'Unconfirmed') label,SUM(cp.event_type='impression') impressions,SUM(cp.event_type='click') clicks,ROUND(CASE WHEN SUM(cp.event_type='impression')>0 THEN SUM(cp.event_type='click')/SUM(cp.event_type='impression')*100 ELSE 0 END,1) ctr FROM contextual_promotions cp JOIN consultations c ON c.id=cp.consultation_id LEFT JOIN categories cat ON cat.id=c.category_id WHERE cp.promotion_key='cardiq-identity-control' AND cp.created_at>=? AND cp.event_type IN ('impression','click') GROUP BY cat.id,cat.name ORDER BY impressions DESC,clicks DESC LIMIT 12",[$since]);
      $promotion['available']=true;
    }catch(Throwable $e){}
    return compact('days','overview','categories','requirements','products','countries','industries','companySizes','views','comparisons','unmapped','promotion');
  }
}
