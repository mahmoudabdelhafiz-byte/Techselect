<?php
require_once __DIR__.'/ProductEvaluation.php';

final class EvaluationProposalService {
  public const GENERATOR_VERSION='eval-proposal-v1';
  public const MIN_EVIDENCE=3;
  public const MIN_CONFIDENCE=0.65;

  public static function queue(PDO $pdo): array {
    $sql="SELECT p.id product_id,p.name,p.slug,pe.id evaluation_id,pe.overall_score,pe.confidence_score,pe.evidence_count,pe.status,pe.evaluated_at,em.version methodology_version,
      (SELECT COUNT(*) FROM public_review_signals prs JOIN public_review_sources prsrc ON prsrc.id=prs.source_id WHERE prsrc.product_id=p.id AND prsrc.access_policy='permitted' AND prsrc.status='active' AND COALESCE(prs.duplicate_suspected,0)=0 AND COALESCE(prs.spam_suspected,0)=0) community_evidence_count,
      (SELECT ep.status FROM evaluation_proposals ep WHERE ep.product_id=p.id ORDER BY ep.id DESC LIMIT 1) proposal_status,
      (SELECT ep.id FROM evaluation_proposals ep WHERE ep.product_id=p.id ORDER BY ep.id DESC LIMIT 1) proposal_id
      FROM products p LEFT JOIN product_evaluations pe ON pe.product_id=p.id LEFT JOIN evaluation_methodologies em ON em.id=pe.methodology_id WHERE p.status='active' ORDER BY p.name";
    try{return $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC)?:[];}catch(Throwable $e){return [];}
  }

  public static function buildInputs(PDO $pdo,int $productId): array {
    $p=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,c.name category,v.name vendor FROM products p LEFT JOIN categories c ON c.id=p.category_id LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.id=? LIMIT 1");$p->execute([$productId]);$product=$p->fetch(PDO::FETCH_ASSOC);if(!$product)throw new RuntimeException('product_not_found');
    $ev=$pdo->prepare("SELECT pe.*,em.version methodology_version,em.dimension_weights FROM product_evaluations pe JOIN evaluation_methodologies em ON em.id=pe.methodology_id WHERE pe.product_id=? ORDER BY pe.id DESC LIMIT 1");$ev->execute([$productId]);$evaluation=$ev->fetch(PDO::FETCH_ASSOC)?:null;
    $dims=[];if($evaluation){$q=$pdo->prepare("SELECT dimension_key,score,confidence_score,rationale,evidence_count FROM product_evaluation_dimensions WHERE evaluation_id=? ORDER BY id");$q->execute([(int)$evaluation['id']]);$dims=$q->fetchAll(PDO::FETCH_ASSOC)?:[];}
    $es=$pdo->prepare("SELECT verification_status,confidence,COUNT(*) n FROM evidence_sources WHERE product_id=? GROUP BY verification_status,confidence");$es->execute([$productId]);$evidence=$es->fetchAll(PDO::FETCH_ASSOC)?:[];
    $pri=null;try{$q=$pdo->prepare("SELECT score_5,positive_sentiment_pct,confidence_score,confidence_label,sources_analyzed,source_type_count,strengths_json,concerns_json,last_analyzed_at FROM product_public_review_intelligence WHERE product_id=? LIMIT 1");$q->execute([$productId]);$pri=$q->fetch(PDO::FETCH_ASSOC)?:null;}catch(Throwable $e){}
    return ['product'=>$product,'current_evaluation'=>$evaluation,'dimensions'=>$dims,'evidence_summary'=>$evidence,'community_intelligence'=>$pri];
  }

  public static function generate(PDO $pdo,array $config,int $productId): array {
    $inputs=self::buildInputs($pdo,$productId);$evaluation=$inputs['current_evaluation'];if(!$evaluation)throw new RuntimeException('evaluation_foundation_required');
    $apiKey=trim((string)getenv('OPENAI_API_KEY'));$model=trim((string)getenv('TECHSELECT_EVAL_MODEL'))?:trim((string)getenv('TECHSELECT_PRI_MODEL'));if($apiKey===''||$model==='')throw new RuntimeException('evaluation_ai_not_configured');
    $schema=['type'=>'object','additionalProperties'=>false,'properties'=>[
      'overall_score'=>['type'=>['number','null'],'minimum'=>0,'maximum'=>10],
      'confidence_score'=>['type'=>'number','minimum'=>0,'maximum'=>1],
      'summary'=>['type'=>'string'],'best_for'=>['type'=>'string'],'limitations'=>['type'=>'string'],
      'material_reasons'=>['type'=>'array','items'=>['type'=>'string'],'maxItems'=>10],
      'dimensions'=>['type'=>'array','items'=>['type'=>'object','additionalProperties'=>false,'properties'=>[
        'dimension_key'=>['type'=>'string'],'score'=>['type'=>['number','null'],'minimum'=>0,'maximum'=>10],
        'confidence_score'=>['type'=>'number','minimum'=>0,'maximum'=>1],'rationale'=>['type'=>'string'],'evidence_count'=>['type'=>'integer','minimum'=>0]
      ],'required'=>['dimension_key','score','confidence_score','rationale','evidence_count']],'maxItems'=>20]
    ],'required'=>['overall_score','confidence_score','summary','best_for','limitations','material_reasons','dimensions']];
    $prompt="You are proposing a TechSelectAI product evaluation for human review. Use only the supplied inputs. Do not invent facts. Keep unknowns explicit. Community intelligence is advisory and must not override verified factual evidence. Return a proposed evaluation, not a publication decision.\n\nINPUTS:\n".json_encode($inputs,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
    $payload=['model'=>$model,'input'=>$prompt,'text'=>['format'=>['type'=>'json_schema','name'=>'evaluation_proposal','strict'=>true,'schema'=>$schema]]];
    $ch=curl_init('https://api.openai.com/v1/responses');curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>60,CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$apiKey,'Content-Type: application/json'],CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)]);$raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);$err=curl_error($ch);curl_close($ch);if($raw===false||$status<200||$status>=300)throw new RuntimeException('evaluation_ai_failed'.($err?': '.$err:''));$json=json_decode($raw,true);$text=null;foreach(($json['output']??[]) as $item){foreach(($item['content']??[]) as $part){if(($part['type']??'')==='output_text'&&isset($part['text'])){$text=$part['text'];break 2;}}}$proposal=json_decode((string)$text,true);if(!is_array($proposal))throw new RuntimeException('evaluation_ai_invalid_output');
    $evidenceCount=(int)($evaluation['evidence_count']??0);$communityCount=(int)($inputs['community_intelligence']['sources_analyzed']??0);$st=$pdo->prepare("INSERT INTO evaluation_proposals(product_id,methodology_id,base_evaluation_id,status,proposed_overall_score,proposed_confidence_score,proposed_summary,proposed_best_for,proposed_limitations,proposed_dimensions_json,material_reasons_json,supporting_inputs_json,evidence_count,community_evidence_count,model_provider,model_name,generator_version) VALUES(?,?,?,'proposed_change',?,?,?,?,?,?,?,?,?,'OpenAI',?,?)");
    $st->execute([$productId,(int)$evaluation['methodology_id'],(int)$evaluation['id'],$proposal['overall_score'],$proposal['confidence_score'],$proposal['summary'],$proposal['best_for'],$proposal['limitations'],json_encode($proposal['dimensions'],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),json_encode($proposal['material_reasons'],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),json_encode($inputs,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),$evidenceCount,$communityCount,$model,self::GENERATOR_VERSION]);
    return self::getProposal($pdo,(int)$pdo->lastInsertId());
  }

  public static function getProposal(PDO $pdo,int $id): array {$q=$pdo->prepare("SELECT ep.*,p.name product_name,p.slug,em.version methodology_version FROM evaluation_proposals ep JOIN products p ON p.id=ep.product_id JOIN evaluation_methodologies em ON em.id=ep.methodology_id WHERE ep.id=?");$q->execute([$id]);$r=$q->fetch(PDO::FETCH_ASSOC);if(!$r)throw new RuntimeException('proposal_not_found');foreach(['proposed_dimensions_json','material_reasons_json','supporting_inputs_json'] as $k)$r[$k]=json_decode($r[$k]??'null',true);return $r;}

  public static function review(PDO $pdo,int $proposalId,string $action,int $userId,string $notes=''): array {
    $proposal=self::getProposal($pdo,$proposalId);if($proposal['status']!=='proposed_change')throw new RuntimeException('proposal_already_reviewed');
    if($action==='reject'||$action==='request_more_evidence'){$status=$action==='reject'?'rejected':'insufficient_evidence';$pdo->prepare("UPDATE evaluation_proposals SET status=?,reviewed_at=NOW(),reviewed_by_user_id=?,review_notes=? WHERE id=?")->execute([$status,$userId,$notes?:null,$proposalId]);return self::getProposal($pdo,$proposalId);}
    if($action!=='approve')throw new InvalidArgumentException('invalid_action');
    if((int)$proposal['evidence_count']<self::MIN_EVIDENCE || (float)$proposal['proposed_confidence_score']<self::MIN_CONFIDENCE)throw new RuntimeException('publication_threshold_not_met');
    $pdo->beginTransaction();try{
      $evalId=(int)$proposal['base_evaluation_id'];$before=ProductEvaluation::publishedForProduct($pdo,(int)$proposal['product_id']);
      $pdo->prepare("UPDATE product_evaluations SET overall_score=?,confidence_score=?,status='published',summary=?,best_for=?,limitations=?,evidence_count=?,evaluated_at=NOW(),approved_at=NOW(),published_at=NOW(),approved_by_user_id=? WHERE id=?")->execute([$proposal['proposed_overall_score'],$proposal['proposed_confidence_score'],$proposal['proposed_summary'],$proposal['proposed_best_for'],$proposal['proposed_limitations'],$proposal['evidence_count'],$userId,$evalId]);
      $pdo->prepare("DELETE FROM product_evaluation_dimensions WHERE evaluation_id=?")->execute([$evalId]);$ins=$pdo->prepare("INSERT INTO product_evaluation_dimensions(evaluation_id,dimension_key,score,confidence_score,rationale,evidence_count) VALUES(?,?,?,?,?,?)");foreach(($proposal['proposed_dimensions_json']??[]) as $d){$ins->execute([$evalId,$d['dimension_key'],$d['score'],$d['confidence_score'],$d['rationale'],$d['evidence_count']]);}
      $rev=$pdo->prepare("SELECT COALESCE(MAX(revision_number),0)+1 FROM product_evaluation_history WHERE product_id=? AND methodology_id=?");$rev->execute([(int)$proposal['product_id'],(int)$proposal['methodology_id']]);$revision=(int)$rev->fetchColumn();
      $pdo->prepare("INSERT INTO product_evaluation_history(product_id,methodology_id,evaluation_id,proposal_id,revision_number,overall_score,confidence_score,status,summary,best_for,limitations,dimensions_json,evidence_count,community_evidence_count,methodology_version,change_reason,action_by_user_id) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")->execute([(int)$proposal['product_id'],(int)$proposal['methodology_id'],$evalId,$proposalId,$revision,$proposal['proposed_overall_score'],$proposal['proposed_confidence_score'],'published',$proposal['proposed_summary'],$proposal['proposed_best_for'],$proposal['proposed_limitations'],json_encode($proposal['proposed_dimensions_json'],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),(int)$proposal['evidence_count'],(int)$proposal['community_evidence_count'],$proposal['methodology_version'],$notes?:implode('; ',$proposal['material_reasons_json']??[]),$userId]);
      $pdo->prepare("UPDATE evaluation_proposals SET status='published',reviewed_at=NOW(),reviewed_by_user_id=?,review_notes=? WHERE id=?")->execute([$userId,$notes?:null,$proposalId]);$pdo->commit();return ['proposal'=>self::getProposal($pdo,$proposalId),'before'=>$before,'after'=>ProductEvaluation::publishedForProduct($pdo,(int)$proposal['product_id'])];
    }catch(Throwable $e){$pdo->rollBack();throw $e;}
  }
}
