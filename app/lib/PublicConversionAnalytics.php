<?php
final class PublicConversionAnalytics {
  public static function record(PDO $pdo,array $b):void{
    $event=(string)($b['event_type']??'');if(!in_array($event,['cta_impression','cta_click'],true))throw new InvalidArgumentException('invalid_event_type');
    $source=self::path($b['source_path']??'');$destination=self::path($b['destination_path']??'');
    if($source==='')throw new InvalidArgumentException('source_path_required');
    $type=self::sourceType($source);$context=self::contextKey($source);$cta=preg_replace('/[^a-z0-9_-]/','',strtolower((string)($b['cta_id']??'selection_journey')))?:'selection_journey';
    $sessionHash=null;if(session_status()===PHP_SESSION_ACTIVE && session_id()!=='')$sessionHash=hash('sha256',session_id(),true);
    $st=$pdo->prepare("INSERT INTO public_conversion_events(event_type,source_path,source_type,context_key,cta_id,destination_path,session_hash) VALUES(?,?,?,?,?,?,?)");
    $st->execute([$event,$source,$type,$context,$cta,$destination!==''?$destination:null,$sessionHash]);
  }

  public static function dashboard(PDO $pdo,int $days=30):array{
    $days=max(1,min(365,$days));$where="occurred_at>=DATE_SUB(NOW(),INTERVAL {$days} DAY)";
    $summary=$pdo->query("SELECT SUM(event_type='cta_impression') impressions,SUM(event_type='cta_click') clicks,COUNT(DISTINCT CASE WHEN event_type='cta_click' THEN session_hash END) unique_click_sessions FROM public_conversion_events WHERE {$where}")->fetch(PDO::FETCH_ASSOC)?:[];
    $im=(int)($summary['impressions']??0);$cl=(int)($summary['clicks']??0);
    $bySource=$pdo->query("SELECT source_type,COUNT(DISTINCT source_path) pages,SUM(event_type='cta_impression') impressions,SUM(event_type='cta_click') clicks FROM public_conversion_events WHERE {$where} GROUP BY source_type ORDER BY clicks DESC,impressions DESC")->fetchAll(PDO::FETCH_ASSOC);
    foreach($bySource as &$r){$r['impressions']=(int)$r['impressions'];$r['clicks']=(int)$r['clicks'];$r['pages']=(int)$r['pages'];$r['ctr']=$r['impressions']?round($r['clicks']*100/$r['impressions'],2):0;}unset($r);
    $top=$pdo->query("SELECT source_path,context_key,SUM(event_type='cta_impression') impressions,SUM(event_type='cta_click') clicks FROM public_conversion_events WHERE {$where} GROUP BY source_path,context_key HAVING impressions>0 ORDER BY clicks DESC,impressions DESC LIMIT 20")->fetchAll(PDO::FETCH_ASSOC);
    foreach($top as &$r){$r['impressions']=(int)$r['impressions'];$r['clicks']=(int)$r['clicks'];$r['ctr']=$r['impressions']?round($r['clicks']*100/$r['impressions'],2):0;}unset($r);
    return ['available'=>true,'impressions'=>$im,'clicks'=>$cl,'ctr'=>$im?round($cl*100/$im,2):0,'unique_click_sessions'=>(int)($summary['unique_click_sessions']??0),'by_source'=>$bySource,'top_pages'=>$top];
  }

  private static function sourceType(string $p):string{return preg_match('#^/software/#',$p)?'software':(preg_match('#^/categories/#',$p)?'category':(preg_match('#^/capabilities/#',$p)?'capability':(preg_match('#^/integrations/#',$p)?'integration':(preg_match('#^/compare/#',$p)?'comparison':'other'))));}
  private static function contextKey(string $p):?string{if(preg_match('#^/(?:software|categories|capabilities|integrations)/([a-z0-9-]+)/?$#',$p,$m))return $m[1];if(preg_match('#^/compare/([a-z0-9-]+-vs-[a-z0-9-]+)/?$#',$p,$m))return $m[1];return null;}
  private static function path($v):string{$v=trim((string)$v);if($v==='')return '';$p=parse_url($v,PHP_URL_PATH);if(!is_string($p)||$p===''||!str_starts_with($p,'/'))return '';return mb_substr($p,0,700);}
}
