<?php
require_once __DIR__.'/EvidenceRefresh.php';
final class EvidenceFactExtractor{
  private const DOMAINS=['capability','integration','deployment','pricing_commercial','compliance','regional_availability','limitation'];

  public static function extract(PDO $pdo,array $config,int $candidateId):array{
    if(empty($config['openai_api_key']))throw new RuntimeException('AI extraction is not configured on this server');
    $st=$pdo->prepare("SELECT c.id,c.status,c.review_notes,es.id evidence_source_id,es.source_url,es.source_title,es.source_type,p.id product_id,p.name product_name,p.slug product_slug,v.name vendor_name FROM evidence_change_candidates c JOIN evidence_sources es ON es.id=c.evidence_source_id JOIN products p ON p.id=es.product_id LEFT JOIN vendors v ON v.id=p.vendor_id WHERE c.id=? LIMIT 1");
    $st->execute([$candidateId]);$c=$st->fetch();if(!$c)throw new RuntimeException('candidate_not_found');if($c['status']!=='needs_fact_extraction')throw new RuntimeException('candidate_not_ready');
    $page=EvidenceRefresh::fetchForReview((string)$c['source_url']);if(trim((string)$page['text'])==='')throw new RuntimeException('source_text_empty');

    $proposal=['type'=>'object','additionalProperties'=>false,'properties'=>[
      'fact_domain'=>['type'=>'string','enum'=>self::DOMAINS],
      'field_key'=>['type'=>'string'],
      'previous_value'=>['type'=>'string'],
      'proposed_value'=>['type'=>'string'],
      'confidence'=>['type'=>'number','minimum'=>0,'maximum'=>1],
      'rationale'=>['type'=>'string'],
      'source_excerpt'=>['type'=>'string']
    ],'required'=>['fact_domain','field_key','previous_value','proposed_value','confidence','rationale','source_excerpt']];
    $schema=['type'=>'object','additionalProperties'=>false,'properties'=>['proposals'=>['type'=>'array','maxItems'=>20,'items'=>$proposal]],'required'=>['proposals']];
    $instructions='You are TechSelectAI Evidence Fact Extraction. Analyze only the supplied reviewed vendor/source text and propose structured fact changes for human review. Never update facts, never rank products, and never infer unsupported claims. Allowed fact domains are capability, integration, deployment, pricing_commercial, compliance, regional_availability, limitation. Use concise stable field_key names. previous_value may be an empty string if the current TechSelectAI value is not supplied; do not guess it. proposed_value must be directly supported by the supplied source. Include a short source_excerpt that directly supports the proposal. Keep not_yet_verified distinct from not_supported. Return no proposal when the source does not clearly support a material structured fact.';
    $input="PRODUCT:\n".json_encode(['id'=>$c['product_id'],'name'=>$c['product_name'],'slug'=>$c['product_slug'],'vendor'=>$c['vendor_name']],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)."\n\nSOURCE:\n".json_encode(['title'=>$c['source_title'],'url'=>$page['final_url'],'type'=>$c['source_type'],'review_notes'=>$c['review_notes']],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)."\n\nREVIEWED_SOURCE_TEXT:\n".$page['text'];
    $payload=['model'=>$config['openai_model']?:'gpt-5','instructions'=>$instructions,'input'=>$input,'text'=>['format'=>['type'=>'json_schema','name'=>'evidence_fact_proposals','strict'=>true,'schema'=>$schema]]];
    $ch=curl_init('https://api.openai.com/v1/responses');curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>45,CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$config['openai_api_key'],'Content-Type: application/json'],CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);
    $raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$err=curl_error($ch);curl_close($ch);if($raw===false||$status<200||$status>=300)throw new RuntimeException('AI evidence extraction failed'.($err?': '.$err:''));
    $data=json_decode($raw,true);$text=$data['output_text']??null;if(!$text&&!empty($data['output']))foreach($data['output'] as $item)foreach(($item['content']??[]) as $content)if(($content['type']??'')==='output_text'){$text=$content['text']??null;break 2;}
    $result=json_decode((string)$text,true);if(!is_array($result)||!isset($result['proposals'])||!is_array($result['proposals']))throw new RuntimeException('invalid_ai_proposal_output');
    $clean=[];foreach($result['proposals'] as $p){$domain=(string)($p['fact_domain']??'');$key=trim((string)($p['field_key']??''));$value=trim((string)($p['proposed_value']??''));$confidence=(float)($p['confidence']??0);if(!in_array($domain,self::DOMAINS,true)||$key===''||$value===''||$confidence<0||$confidence>1)continue;$clean[]=['fact_domain'=>$domain,'field_key'=>mb_substr($key,0,120),'previous_value'=>mb_substr((string)($p['previous_value']??''),0,8000),'proposed_value'=>mb_substr($value,0,8000),'confidence'=>$confidence,'rationale'=>mb_substr((string)($p['rationale']??''),0,8000),'source_excerpt'=>mb_substr((string)($p['source_excerpt']??''),0,2000)];}
    return $clean;
  }
}
