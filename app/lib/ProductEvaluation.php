<?php
final class ProductEvaluation {
  public const DIMENSIONS = [
    'usability' => 'Usability',
    'implementation_complexity' => 'Implementation complexity',
    'integration_depth' => 'Integration depth',
    'administration_overhead' => 'Administration overhead',
    'value' => 'Value',
    'support_community' => 'Support & community',
    'security_compliance' => 'Security & compliance',
    'enterprise_suitability' => 'Enterprise suitability',
    'smb_suitability' => 'SMB suitability',
    'product_maturity' => 'Product maturity',
  ];
  public const STALE_AFTER_DAYS = 180;

  public static function publishedForProduct(PDO $pdo,int $productId): ?array {
    $q=$pdo->prepare("SELECT pe.id,pe.overall_score,pe.confidence_score,pe.best_for,pe.limitations,pe.summary,pe.evidence_count,pe.evaluated_at,pe.published_at,em.version methodology_version,em.name methodology_name FROM product_evaluations pe JOIN evaluation_methodologies em ON em.id=pe.methodology_id WHERE pe.product_id=? AND pe.status='published' AND em.status='published' ORDER BY pe.published_at DESC,pe.id DESC LIMIT 1");
    $q->execute([$productId]);
    $evaluation=$q->fetch(PDO::FETCH_ASSOC);
    if(!$evaluation)return null;

    $q=$pdo->prepare("SELECT dimension_key,score,confidence_score,rationale,evidence_count FROM product_evaluation_dimensions WHERE evaluation_id=? ORDER BY id");
    $q->execute([(int)$evaluation['id']]);
    $dimensions=[];
    foreach($q->fetchAll(PDO::FETCH_ASSOC) as $row){
      $key=(string)$row['dimension_key'];
      $dimensions[$key]=[
        'key'=>$key,
        'label'=>self::DIMENSIONS[$key]??ucwords(str_replace('_',' ',$key)),
        'score'=>$row['score']===null?null:(float)$row['score'],
        'confidence'=>(float)$row['confidence_score'],
        'rationale'=>$row['rationale'],
        'evidence_count'=>(int)$row['evidence_count'],
      ];
    }
    $evaluation['overall_score']=$evaluation['overall_score']===null?null:(float)$evaluation['overall_score'];
    $evaluation['confidence_score']=(float)$evaluation['confidence_score'];
    $evaluation['evidence_count']=(int)$evaluation['evidence_count'];
    $evaluation['dimensions']=$dimensions;
    $evaluation['transparency']=self::transparencyForEvaluation($pdo,(int)$evaluation['id'],$evaluation);
    return $evaluation;
  }

  public static function transparencyForEvaluation(PDO $pdo,int $evaluationId,array $evaluation=[]): array {
    $sql="SELECT es.source_type,es.verification_status,es.checked_at,COUNT(*) link_count FROM product_evaluation_dimensions d JOIN product_evaluation_evidence pee ON pee.evaluation_dimension_id=d.id JOIN evidence_sources es ON es.id=pee.evidence_source_id WHERE d.evaluation_id=? GROUP BY es.source_type,es.verification_status,es.checked_at";
    $st=$pdo->prepare($sql);$st->execute([$evaluationId]);
    $sourceMix=[];$statusCounts=[];$oldest=null;$newest=null;$problemCount=0;$linked=0;
    foreach($st->fetchAll(PDO::FETCH_ASSOC) as $r){
      $type=(string)($r['source_type']?:'unknown');$count=(int)$r['link_count'];$linked+=$count;
      $sourceMix[$type]=($sourceMix[$type]??0)+$count;
      $status=(string)($r['verification_status']?:'unverified');$statusCounts[$status]=($statusCounts[$status]??0)+$count;
      if(in_array($status,['outdated','broken','disputed','superseded','placeholder','unverified'],true))$problemCount+=$count;
      $checked=$r['checked_at']??null;if($checked){if($oldest===null||$checked<$oldest)$oldest=$checked;if($newest===null||$checked>$newest)$newest=$checked;}
    }
    arsort($sourceMix);
    $basis=$evaluation['evaluated_at']??$evaluation['published_at']??null;
    $ageDays=$basis?max(0,(int)floor((time()-strtotime((string)$basis))/86400)):null;
    $staleByAge=$ageDays!==null&&$ageDays>self::STALE_AFTER_DAYS;
    $stale=$staleByAge||$problemCount>0;
    $reasons=[];
    if($staleByAge)$reasons[]='Evaluation is older than '.self::STALE_AFTER_DAYS.' days.';
    if($problemCount>0)$reasons[]=$problemCount.' linked evidence item'.($problemCount===1?' has':'s have').' a non-current verification state.';
    return [
      'source_mix'=>$sourceMix,
      'verification_status_counts'=>$statusCounts,
      'linked_evidence_count'=>$linked,
      'oldest_checked_at'=>$oldest,
      'newest_checked_at'=>$newest,
      'age_days'=>$ageDays,
      'stale'=>$stale,
      'stale_reasons'=>$reasons,
      'provenance_labels'=>[
        'official_or_vendor'=>'Vendor/official factual source',
        'verified_fact'=>'TechSelectAI-verified factual evidence',
        'community'=>'Community-derived insight',
        'analysis'=>'TechSelectAI analysis',
        'estimate'=>'Estimate / inference',
      ],
    ];
  }

  public static function weightedScore(array $dimensionScores,array $weights): ?float {
    $sum=0.0;$used=0.0;
    foreach($weights as $key=>$weight){
      if(!array_key_exists($key,$dimensionScores) || $dimensionScores[$key]===null || $dimensionScores[$key]==='')continue;
      $w=max(0.0,(float)$weight);
      $score=max(0.0,min(10.0,(float)$dimensionScores[$key]));
      $sum+=$score*$w;$used+=$w;
    }
    return $used>0?round($sum/$used,2):null;
  }

  public static function confidenceLabel(float $confidence): string {
    if($confidence>=0.85)return 'High';
    if($confidence>=0.65)return 'Moderate';
    if($confidence>=0.40)return 'Limited';
    return 'Insufficient';
  }
}
