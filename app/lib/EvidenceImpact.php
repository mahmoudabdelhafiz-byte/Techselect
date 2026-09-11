<?php
final class EvidenceImpact {
  public static function forEvidence(PDO $pdo,int $evidenceId): array {
    $st=$pdo->prepare("SELECT e.id,e.product_id,p.name product_name,p.slug product_slug,e.source_title,e.source_url,e.source_type,e.verification_status,e.confidence,e.checked_at,e.notes FROM evidence_sources e JOIN products p ON p.id=e.product_id WHERE e.id=? LIMIT 1");
    $st->execute([$evidenceId]);$e=$st->fetch(PDO::FETCH_ASSOC);if(!$e)return [];

    $impact=[
      'software_page'=>['count'=>1,'items'=>[['label'=>$e['product_name'],'url'=>'/software/'.$e['product_slug']]]],
      'capabilities'=>['count'=>0,'items'=>[]],
      'evaluation_dimensions'=>['count'=>0,'items'=>[]],
      'published_evaluations'=>['count'=>0,'items'=>[]],
      'recommendation_runs'=>['count'=>0,'items'=>[]],
      'total'=>1,
    ];

    try{
      $q=$pdo->prepare("SELECT c.name,c.slug,m.slug module_slug,pc.support_status FROM product_capability_evidence pce JOIN product_capabilities pc ON pc.id=pce.product_capability_id JOIN capabilities c ON c.id=pc.capability_id LEFT JOIN modules m ON m.id=c.module_id WHERE pce.evidence_source_id=?");
      $q->execute([$evidenceId]);$rows=$q->fetchAll(PDO::FETCH_ASSOC);$impact['capabilities']=['count'=>count($rows),'items'=>$rows];
    }catch(Throwable $x){}

    try{
      $q=$pdo->prepare("SELECT ped.dimension_key,ped.score,pe.status,em.version methodology_version FROM product_evaluation_evidence pee JOIN product_evaluation_dimensions ped ON ped.id=pee.evaluation_dimension_id JOIN product_evaluations pe ON pe.id=ped.evaluation_id JOIN evaluation_methodologies em ON em.id=pe.methodology_id WHERE pee.evidence_source_id=?");
      $q->execute([$evidenceId]);$rows=$q->fetchAll(PDO::FETCH_ASSOC);$impact['evaluation_dimensions']=['count'=>count($rows),'items'=>$rows];
      $pub=array_values(array_filter($rows,fn($r)=>($r['status']??'')==='published'));
      $impact['published_evaluations']=['count'=>count($pub),'items'=>$pub];
    }catch(Throwable $x){}

    try{
      $q=$pdo->prepare("SELECT COUNT(DISTINCT cr.id) FROM consultation_recommendations cr WHERE cr.product_id=?");$q->execute([(int)$e['product_id']]);$impact['recommendation_runs']['count']=(int)$q->fetchColumn();
    }catch(Throwable $x){}

    $impact['total']=1+$impact['capabilities']['count']+$impact['evaluation_dimensions']['count']+$impact['recommendation_runs']['count'];
    $impact['high_impact']=$impact['published_evaluations']['count']>0 || $impact['total']>=10;
    $impact['material_risk']=$impact['published_evaluations']['count']>0 || $impact['recommendation_runs']['count']>0;
    return $impact;
  }

  public static function staleState(?string $checkedAt,int $days=180): array {
    if(!$checkedAt)return ['stale'=>true,'age_days'=>null,'threshold_days'=>$days];
    $age=max(0,(int)floor((time()-strtotime($checkedAt))/86400));
    return ['stale'=>$age>$days,'age_days'=>$age,'threshold_days'=>$days];
  }
}
