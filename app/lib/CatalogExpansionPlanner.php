<?php
final class CatalogExpansionPlanner {
  private const STRATEGIC_CATEGORIES=['crm','itsm','hrms','endpoint-security-edr','backup-disaster-recovery'];
  private const EVIDENCE_FRESH_DAYS=180;

  public static function dashboard(PDO $pdo,int $days=90):array{
    $days=max(7,min(365,$days));
    $existing=self::existingCategories($pdo,$days);
    $missing=self::taxonomyCandidates($pdo,$days);
    usort($existing,fn($a,$b)=>$b['priority_score']<=>$a['priority_score']);
    usort($missing,fn($a,$b)=>$b['priority_score']<=>$a['priority_score']);
    $strategic=[];
    foreach($existing as $row){
      if(in_array($row['slug'],self::STRATEGIC_CATEGORIES,true))$strategic[]=$row;
    }
    $strategicReady=count(array_filter($strategic,fn($r)=>!empty($r['publication_ready'])));
    return [
      'window_days'=>$days,
      'existing_categories'=>$existing,
      'strategic_categories'=>$strategic,
      'strategic_summary'=>[
        'target_slugs'=>self::STRATEGIC_CATEGORIES,
        'tracked_count'=>count($strategic),
        'publication_ready_count'=>$strategicReady,
        'minimum_ready_before_new_major_subsystem'=>3,
        'gate_satisfied'=>$strategicReady>=3,
      ],
      'new_category_candidates'=>$missing,
      'generated_at'=>gmdate('c'),
      'policy'=>[
        'minimum_active_products'=>4,
        'minimum_ready_products'=>3,
        'minimum_verified_sources'=>4,
        'minimum_known_capability_rows'=>12,
        'minimum_known_capabilities_per_ready_product'=>3,
        'minimum_fresh_verified_sources_per_ready_product'=>1,
        'evidence_fresh_days'=>self::EVIDENCE_FRESH_DAYS,
        'note'=>'Demand priority decides research order only. Publication remains evidence/readiness gated; Unknown != Unsupported. A ready product needs known capability depth plus recent verified evidence.'
      ]
    ];
  }

  private static function existingCategories(PDO $pdo,int $days):array{
    $fresh=self::EVIDENCE_FRESH_DAYS;
    $sql="SELECT c.id,c.name,c.slug,
      COUNT(DISTINCT p.id) active_products,
      COUNT(DISTINCT CASE WHEN p.status='active'
        AND (SELECT COUNT(*) FROM product_capabilities pc2 WHERE pc2.product_id=p.id AND pc2.edition_id IS NULL AND pc2.support_status<>'not_yet_verified')>=3
        AND EXISTS(SELECT 1 FROM evidence_sources es2 WHERE es2.product_id=p.id AND es2.verification_status='verified' AND COALESCE(es2.checked_at,es2.created_at)>=DATE_SUB(NOW(),INTERVAL {$fresh} DAY))
        THEN p.id END) ready_products,
      COUNT(DISTINCT es.id) evidence_sources,
      COUNT(DISTINCT CASE WHEN es.verification_status='verified' THEN es.id END) verified_sources,
      COUNT(DISTINCT CASE WHEN es.verification_status='verified' AND COALESCE(es.checked_at,es.created_at)>=DATE_SUB(NOW(),INTERVAL {$fresh} DAY) THEN es.id END) fresh_verified_sources,
      COUNT(DISTINCT pc.id) capability_rows,
      COUNT(DISTINCT CASE WHEN pc.support_status<>'not_yet_verified' THEN pc.id END) known_capability_rows,
      (SELECT ROUND(AVG(pc3.confidence_score)*100,1)
       FROM product_capabilities pc3 JOIN products p3 ON p3.id=pc3.product_id
       WHERE p3.category_id=c.id AND p3.status='active' AND pc3.edition_id IS NULL AND pc3.support_status<>'not_yet_verified') avg_known_confidence,
      MAX(p.last_reviewed_at) latest_product_review_at,
      MAX(CASE WHEN es.verification_status='verified' THEN COALESCE(es.checked_at,es.created_at) END) latest_verified_evidence_at
      FROM categories c
      LEFT JOIN products p ON p.category_id=c.id AND p.status='active'
      LEFT JOIN evidence_sources es ON es.product_id=p.id
      LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL
      WHERE c.is_active=1 GROUP BY c.id,c.name,c.slug ORDER BY c.name";
    $rows=$pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);$out=[];
    foreach($rows as $r){
      $cid=(int)$r['id'];$buyer=self::scalar($pdo,"SELECT COUNT(*) FROM buyer_intent_events WHERE category_id=? AND occurred_at>=DATE_SUB(NOW(),INTERVAL {$days} DAY)",[$cid]);
      $consult=self::scalar($pdo,"SELECT COUNT(*) FROM consultations WHERE category_id=? AND created_at>=DATE_SUB(NOW(),INTERVAL {$days} DAY)",[$cid]);
      $gsc=self::gscForCategory($pdo,$r['slug'],$r['name'],$days);
      $demand=self::demandScore($buyer+$consult,(float)$gsc['impressions'],0);
      $active=(int)$r['active_products'];$readyProducts=(int)$r['ready_products'];$verified=(int)$r['verified_sources'];$freshVerified=(int)$r['fresh_verified_sources'];$known=(int)$r['known_capability_rows'];
      $ready=$active>=4&&$readyProducts>=3&&$verified>=4&&$freshVerified>=4&&$known>=12;
      $coverage=(int)$r['capability_rows']?round(($known*100)/(int)$r['capability_rows'],1):0;
      $gaps=[];
      if($active<4)$gaps[]='Need '.(4-$active).' more active product'.((4-$active)===1?'':'s');
      if($readyProducts<3)$gaps[]='Need '.(3-$readyProducts).' more product'.((3-$readyProducts)===1?'':'s').' with ≥3 known capability facts and fresh verified evidence';
      if($verified<4)$gaps[]='Need '.(4-$verified).' more verified evidence source'.((4-$verified)===1?'':'s');
      if($freshVerified<4)$gaps[]='Need '.(4-$freshVerified).' more verified source'.((4-$freshVerified)===1?'':'s').' checked within '.$fresh.' days';
      if($known<12)$gaps[]='Need '.(12-$known).' more known capability row'.((12-$known)===1?'':'s');
      $out[]=[...$r,
        'buyer_events'=>$buyer,'consultations'=>$consult,'gsc_impressions'=>$gsc['impressions'],'gsc_clicks'=>$gsc['clicks'],
        'evidence_coverage_pct'=>$coverage,'publication_ready'=>$ready,'readiness_gaps'=>$gaps,
        'strategic_category'=>in_array($r['slug'],self::STRATEGIC_CATEGORIES,true),
        'priority_score'=>$demand,
        'recommended_action'=>$ready?($demand>=45?'expand_products':'maintain'):($demand>=35?'research_evidence_gap':'hold_publication')
      ];
    }
    return $out;
  }

  private static function taxonomyCandidates(PDO $pdo,int $days):array{
    try{$rows=$pdo->query("SELECT topic_key,topic_label,occurrence_count,priority,last_seen_at,latest_example_request,status FROM taxonomy_expansion_queue WHERE status NOT IN ('dismissed','completed') ORDER BY occurrence_count DESC,last_seen_at DESC")->fetchAll(PDO::FETCH_ASSOC);}catch(Throwable $e){return [];}
    $out=[];foreach($rows as $r){
      $slug=self::slug($r['topic_label']);$st=$pdo->prepare("SELECT id,name,slug FROM categories WHERE is_active=1 AND (slug=? OR LOWER(name)=LOWER(?)) LIMIT 1");$st->execute([$slug,$r['topic_label']]);if($st->fetch())continue;
      $gsc=self::gscForTerm($pdo,$r['topic_label'],$days);$boost=match($r['priority']){'urgent'=>25,'high'=>18,'low'=>3,default=>10};
      $score=self::demandScore((int)$r['occurrence_count'],(float)$gsc['impressions'],$boost);
      $out[]=[...$r,'proposed_slug'=>$slug,'gsc_impressions'=>$gsc['impressions'],'gsc_clicks'=>$gsc['clicks'],'priority_score'=>$score,'publication_ready'=>false,'recommended_action'=>$score>=50?'research_new_category':($score>=25?'validate_demand':'watch')];
    }return $out;
  }

  private static function gscForCategory(PDO $pdo,string $slug,string $name,int $days):array{
    try{$st=$pdo->prepare("SELECT COALESCE(SUM(impressions),0) impressions,COALESCE(SUM(clicks),0) clicks FROM search_console_performance WHERE metric_date>=DATE_SUB(CURDATE(),INTERVAL {$days} DAY) AND (page_url LIKE ? OR LOWER(query_text) LIKE ?)");$st->execute(['%/categories/'.$slug.'%','%'.strtolower($name).'%']);$r=$st->fetch(PDO::FETCH_ASSOC)?:[];return ['impressions'=>(float)($r['impressions']??0),'clicks'=>(float)($r['clicks']??0)];}catch(Throwable $e){return ['impressions'=>0,'clicks'=>0];}
  }
  private static function gscForTerm(PDO $pdo,string $term,int $days):array{
    try{$st=$pdo->prepare("SELECT COALESCE(SUM(impressions),0) impressions,COALESCE(SUM(clicks),0) clicks FROM search_console_performance WHERE metric_date>=DATE_SUB(CURDATE(),INTERVAL {$days} DAY) AND LOWER(query_text) LIKE ?");$st->execute(['%'.strtolower($term).'%']);$r=$st->fetch(PDO::FETCH_ASSOC)?:[];return ['impressions'=>(float)($r['impressions']??0),'clicks'=>(float)($r['clicks']??0)];}catch(Throwable $e){return ['impressions'=>0,'clicks'=>0];}
  }
  private static function scalar(PDO $pdo,string $sql,array $args=[]):int{try{$st=$pdo->prepare($sql);$st->execute($args);return (int)$st->fetchColumn();}catch(Throwable $e){return 0;}}
  private static function demandScore(int $events,float $impressions,int $boost):float{return round(min(100,$boost+min(45,$events*4)+min(35,log10(max(1,$impressions)+1)*12)),1);}
  private static function slug(string $s):string{$s=strtolower(trim($s));$s=preg_replace('/[^a-z0-9]+/','-',$s);return trim((string)$s,'-');}
}
