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
    return $evaluation;
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
