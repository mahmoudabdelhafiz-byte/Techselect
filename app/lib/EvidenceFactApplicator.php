<?php
final class EvidenceFactApplicator{
  private const SUPPORT_STATUSES=['supported','partially_supported','not_supported','not_yet_verified'];
  private const DOMAINS=['capability','integration','deployment','pricing'];

  public static function apply(PDO $pdo,int $proposalId,array $mapping,int $actorUserId):array{
    $domain=trim((string)($mapping['target_domain']??''));
    $slug=trim((string)($mapping['target_slug']??''));
    $field=trim((string)($mapping['target_field']??''));
    $value=$mapping['target_value']??null;
    $notes=trim((string)($mapping['application_notes']??''));
    if(!in_array($domain,self::DOMAINS,true))throw new InvalidArgumentException('invalid_target_domain');
    if($domain==='pricing'){
      if($slug!=='product')throw new InvalidArgumentException('invalid_pricing_scope');
      $allowedFields=['pricing_model','billing_period','currency','amount_min','amount_max','unit_label','notes'];
    }else{
      if(!preg_match('/^[a-z0-9][a-z0-9-]{0,189}$/',$slug))throw new InvalidArgumentException('invalid_target_slug');
      $allowedFields=$domain==='capability'?['support_status','confidence_score','limitations']:['support_status','confidence_score'];
    }
    if(!in_array($field,$allowedFields,true))throw new InvalidArgumentException('invalid_target_field');
    if(mb_strlen($notes)>4000)throw new InvalidArgumentException('application_notes_too_long');
    $normalized=self::normalizeValue($domain,$field,$value);

    $pdo->beginTransaction();
    try{
      $st=$pdo->prepare("SELECT p.id,p.status,p.fact_domain,p.candidate_id,c.evidence_source_id,es.product_id,es.source_url FROM evidence_fact_proposals p JOIN evidence_change_candidates c ON c.id=p.candidate_id JOIN evidence_sources es ON es.id=c.evidence_source_id WHERE p.id=? FOR UPDATE");
      $st->execute([$proposalId]);$proposal=$st->fetch();
      if(!$proposal)throw new RuntimeException('proposal_not_found');
      if($proposal['status']!=='approved_for_application')throw new RuntimeException('proposal_not_approved');
      if(!self::domainCompatible((string)$proposal['fact_domain'],$domain,$field))throw new RuntimeException('proposal_domain_mismatch');
      $dup=$pdo->prepare('SELECT id FROM evidence_fact_applications WHERE proposal_id=? LIMIT 1');$dup->execute([$proposalId]);if($dup->fetchColumn())throw new RuntimeException('proposal_already_applied');
      $productId=(int)$proposal['product_id'];$sourceId=(int)$proposal['evidence_source_id'];$before=[];$after=[];$targetId=null;

      if($domain==='capability'){
        $s=$pdo->prepare('SELECT id FROM capabilities WHERE slug=? AND is_active=1 LIMIT 1');$s->execute([$slug]);$targetId=$s->fetchColumn();if(!$targetId)throw new RuntimeException('target_not_found');
        $q=$pdo->prepare('SELECT id,support_status,confidence_score,limitations FROM product_capabilities WHERE product_id=? AND capability_id=? AND edition_id IS NULL ORDER BY id LIMIT 1 FOR UPDATE');$q->execute([$productId,(int)$targetId]);$row=$q->fetch();
        if(!$row){$pdo->prepare("INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,last_verified_at) VALUES(?,?,NULL,'not_yet_verified',0,NOW())")->execute([$productId,(int)$targetId]);$row=['id'=>(int)$pdo->lastInsertId(),'support_status'=>'not_yet_verified','confidence_score'=>'0','limitations'=>null];}
        $before=['support_status'=>$row['support_status'],'confidence_score'=>(float)$row['confidence_score'],'limitations'=>$row['limitations']];
        if($field==='support_status')$pdo->prepare('UPDATE product_capabilities SET support_status=?,last_verified_at=NOW() WHERE id=?')->execute([$normalized,(int)$row['id']]);
        elseif($field==='confidence_score')$pdo->prepare('UPDATE product_capabilities SET confidence_score=?,last_verified_at=NOW() WHERE id=?')->execute([$normalized,(int)$row['id']]);
        else $pdo->prepare('UPDATE product_capabilities SET limitations=?,last_verified_at=NOW() WHERE id=?')->execute([$normalized,(int)$row['id']]);
        $pdo->prepare('INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note) VALUES(?,?,1,?)')->execute([(int)$row['id'],$sourceId,$notes!==''?$notes:null]);
        $q=$pdo->prepare('SELECT support_status,confidence_score,limitations FROM product_capabilities WHERE id=?');$q->execute([(int)$row['id']]);$r=$q->fetch();$after=['support_status'=>$r['support_status'],'confidence_score'=>(float)$r['confidence_score'],'limitations'=>$r['limitations']];
      }elseif($domain==='integration'){
        $s=$pdo->prepare('SELECT id FROM integrations WHERE slug=? LIMIT 1');$s->execute([$slug]);$targetId=$s->fetchColumn();if(!$targetId)throw new RuntimeException('target_not_found');
        $q=$pdo->prepare('SELECT support_status,confidence_score FROM product_integrations WHERE product_id=? AND integration_id=? FOR UPDATE');$q->execute([$productId,(int)$targetId]);$row=$q->fetch();$before=$row?['support_status'=>$row['support_status'],'confidence_score'=>(float)$row['confidence_score']]:['support_status'=>'not_yet_verified','confidence_score'=>0.0];
        $pdo->prepare("INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score) VALUES(?,?,'not_yet_verified',0) ON DUPLICATE KEY UPDATE product_id=VALUES(product_id)")->execute([$productId,(int)$targetId]);
        if($field==='support_status')$pdo->prepare('UPDATE product_integrations SET support_status=? WHERE product_id=? AND integration_id=?')->execute([$normalized,$productId,(int)$targetId]);else $pdo->prepare('UPDATE product_integrations SET confidence_score=? WHERE product_id=? AND integration_id=?')->execute([$normalized,$productId,(int)$targetId]);
        $q=$pdo->prepare('SELECT support_status,confidence_score FROM product_integrations WHERE product_id=? AND integration_id=?');$q->execute([$productId,(int)$targetId]);$r=$q->fetch();$after=['support_status'=>$r['support_status'],'confidence_score'=>(float)$r['confidence_score']];
      }elseif($domain==='deployment'){
        $s=$pdo->prepare('SELECT id FROM deployment_models WHERE slug=? LIMIT 1');$s->execute([$slug]);$targetId=$s->fetchColumn();if(!$targetId)throw new RuntimeException('target_not_found');
        $q=$pdo->prepare('SELECT support_status,confidence_score FROM product_deployments WHERE product_id=? AND deployment_model_id=? FOR UPDATE');$q->execute([$productId,(int)$targetId]);$row=$q->fetch();$before=$row?['support_status'=>$row['support_status'],'confidence_score'=>(float)$row['confidence_score']]:['support_status'=>'not_yet_verified','confidence_score'=>0.0];
        $pdo->prepare("INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score) VALUES(?,?,'not_yet_verified',0) ON DUPLICATE KEY UPDATE product_id=VALUES(product_id)")->execute([$productId,(int)$targetId]);
        if($field==='support_status')$pdo->prepare('UPDATE product_deployments SET support_status=? WHERE product_id=? AND deployment_model_id=?')->execute([$normalized,$productId,(int)$targetId]);else $pdo->prepare('UPDATE product_deployments SET confidence_score=? WHERE product_id=? AND deployment_model_id=?')->execute([$normalized,$productId,(int)$targetId]);
        $q=$pdo->prepare('SELECT support_status,confidence_score FROM product_deployments WHERE product_id=? AND deployment_model_id=?');$q->execute([$productId,(int)$targetId]);$r=$q->fetch();$after=['support_status'=>$r['support_status'],'confidence_score'=>(float)$r['confidence_score']];
      }else{
        $q=$pdo->prepare('SELECT id,pricing_model,billing_period,currency,amount_min,amount_max,unit_label,notes,source_url,last_verified_at FROM product_pricing WHERE product_id=? AND edition_id IS NULL ORDER BY id FOR UPDATE');
        $q->execute([$productId]);$rows=$q->fetchAll();
        if(count($rows)>1)throw new RuntimeException('ambiguous_pricing_scope');
        if(!$rows){
          $pdo->prepare("INSERT INTO product_pricing(product_id,edition_id,pricing_model,billing_period,source_url,last_verified_at) VALUES(?,NULL,'unknown','unknown',?,NOW())")->execute([$productId,$proposal['source_url']?:null]);
          $row=['id'=>(int)$pdo->lastInsertId(),'pricing_model'=>'unknown','billing_period'=>'unknown','currency'=>null,'amount_min'=>null,'amount_max'=>null,'unit_label'=>null,'notes'=>null,'source_url'=>$proposal['source_url']?:null,'last_verified_at'=>null];
        }else{$row=$rows[0];}
        $targetId=(int)$row['id'];
        $before=self::pricingSnapshot($row);
        $sql="UPDATE product_pricing SET {$field}=?,source_url=?,last_verified_at=NOW() WHERE id=?";
        $pdo->prepare($sql)->execute([$normalized,$proposal['source_url']?:null,$targetId]);
        $q=$pdo->prepare('SELECT id,pricing_model,billing_period,currency,amount_min,amount_max,unit_label,notes,source_url,last_verified_at FROM product_pricing WHERE id=?');$q->execute([$targetId]);$after=self::pricingSnapshot($q->fetch());
      }

      $ins=$pdo->prepare('INSERT INTO evidence_fact_applications(proposal_id,candidate_id,product_id,evidence_source_id,target_domain,target_slug,target_field,before_value,after_value,application_notes,applied_by_user_id) VALUES(?,?,?,?,?,?,?,?,?,?,?)');
      $ins->execute([$proposalId,(int)$proposal['candidate_id'],$productId,$sourceId,$domain,$slug,$field,json_encode($before,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),json_encode($after,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),$notes!==''?$notes:null,$actorUserId]);
      $pdo->prepare("UPDATE evidence_fact_proposals SET status='applied' WHERE id=? AND status='approved_for_application'")->execute([$proposalId]);
      $pdo->prepare('UPDATE products SET last_reviewed_at=NOW() WHERE id=?')->execute([$productId]);
      $pdo->commit();
      return ['proposal_id'=>$proposalId,'candidate_id'=>(int)$proposal['candidate_id'],'product_id'=>$productId,'evidence_source_id'=>$sourceId,'target_domain'=>$domain,'target_slug'=>$slug,'target_field'=>$field,'target_id'=>$targetId,'before'=>$before,'after'=>$after];
    }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
  }

  private static function normalizeValue(string $domain,string $field,mixed $value):mixed{
    if($domain==='pricing'){
      if(in_array($field,['amount_min','amount_max'],true)){
        if($value===null||trim((string)$value)==='')return null;
        if(!is_numeric($value)||(float)$value<0)throw new InvalidArgumentException('invalid_pricing_amount');
        return round((float)$value,2);
      }
      $v=trim((string)$value);
      if($field==='currency'){
        if($v==='')return null;
        $v=strtoupper($v);if(!preg_match('/^[A-Z]{3}$/',$v))throw new InvalidArgumentException('invalid_currency');return $v;
      }
      $limit=$field==='notes'?8000:($field==='unit_label'?100:40);
      if(mb_strlen($v)>$limit)throw new InvalidArgumentException('pricing_value_too_long');
      return $v!==''?$v:null;
    }
    if($field==='support_status'){$v=trim((string)$value);if(!in_array($v,self::SUPPORT_STATUSES,true))throw new InvalidArgumentException('invalid_support_status');return $v;}
    if($field==='confidence_score'){if(!is_numeric($value))throw new InvalidArgumentException('invalid_confidence_score');$v=(float)$value;if($v<0||$v>1)throw new InvalidArgumentException('invalid_confidence_score');return round($v,3);}
    $v=trim((string)$value);if(mb_strlen($v)>8000)throw new InvalidArgumentException('limitations_too_long');return $v!==''?$v:null;
  }

  private static function pricingSnapshot(array $row):array{
    return ['pricing_model'=>$row['pricing_model'],'billing_period'=>$row['billing_period'],'currency'=>$row['currency'],'amount_min'=>$row['amount_min']===null?null:(float)$row['amount_min'],'amount_max'=>$row['amount_max']===null?null:(float)$row['amount_max'],'unit_label'=>$row['unit_label'],'notes'=>$row['notes'],'source_url'=>$row['source_url'],'last_verified_at'=>$row['last_verified_at']];
  }

  private static function domainCompatible(string $proposalDomain,string $targetDomain,string $field):bool{
    if($proposalDomain==='pricing_commercial'&&$targetDomain==='pricing')return true;
    if($proposalDomain===$targetDomain)return true;
    return $proposalDomain==='limitation'&&$targetDomain==='capability'&&$field==='limitations';
  }
}
