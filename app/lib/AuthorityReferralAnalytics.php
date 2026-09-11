<?php
final class AuthorityReferralAnalytics {
  public static function sanitizeAcquisition(array $input):array{
    return [
      'utm_source'=>self::clean($input['utm_source']??null,190),
      'utm_medium'=>self::clean($input['utm_medium']??null,190),
      'utm_campaign'=>self::clean($input['utm_campaign']??null,190),
      'referrer'=>self::sanitizeReferrer($input['referrer']??null),
    ];
  }

  public static function classify(?string $utmSource,?string $utmMedium,?string $referrer,array $authorityDomains=[]):string{
    $source=strtolower(trim((string)$utmSource));$medium=strtolower(trim((string)$utmMedium));$host=strtolower((string)parse_url((string)$referrer,PHP_URL_HOST));$host=preg_replace('/^www\./','',$host??'');
    $hay=$source.' '.$host;
    foreach(['chatgpt','openai','claude','anthropic','perplexity','gemini','copilot'] as $k)if(str_contains($hay,$k))return 'ai';
    foreach(['google.','bing.com','duckduckgo.com','yahoo.','yandex.','baidu.'] as $k)if(str_contains($hay,$k))return 'search';
    foreach(['linkedin','facebook','instagram','twitter','x.com','youtube','tiktok'] as $k)if(str_contains($hay,$k))return 'social';
    if(in_array($medium,['partner','partnership'],true))return 'partner';
    if(in_array($medium,['directory','profile'],true))return 'directory';
    if(in_array($medium,['publication','editorial','guest_article'],true))return 'publication';
    if($host!==''&&isset($authorityDomains[$host])){
      $type=$authorityDomains[$host];
      if(in_array($type,['partner','customer_mention','vendor_mention'],true))return 'partner';
      if(in_array($type,['directory','company_profile'],true))return 'directory';
      if(in_array($type,['industry_publication','thought_leadership'],true))return 'publication';
    }
    return ($source!==''||$host!=='')?'other':'direct';
  }

  public static function summary(PDO $pdo,int $days=30):array{
    $days=max(1,min(365,$days));$domains=[];
    try{foreach($pdo->query("SELECT domain,source_type FROM authority_sources") as $r)$domains[strtolower((string)$r['domain'])]=(string)$r['source_type'];}catch(Throwable $e){}
    $sql="SELECT utm_source,utm_medium,utm_campaign,referrer,COUNT(*) visits FROM visitor_sessions WHERE first_seen_at>=DATE_SUB(NOW(),INTERVAL ".$days." DAY) AND (utm_source IS NOT NULL OR referrer IS NOT NULL) GROUP BY utm_source,utm_medium,utm_campaign,referrer ORDER BY visits DESC LIMIT 250";
    $rows=$pdo->query($sql)->fetchAll()?:[];$categories=[];$sources=[];$total=0;
    foreach($rows as $r){$n=(int)$r['visits'];$total+=$n;$category=self::classify($r['utm_source']??null,$r['utm_medium']??null,$r['referrer']??null,$domains);$categories[$category]=($categories[$category]??0)+$n;$host=strtolower((string)parse_url((string)($r['referrer']??''),PHP_URL_HOST));$host=preg_replace('/^www\./','',$host??'');$label=$host?:((string)($r['utm_source']??'tagged'));$key=$category.'|'.$label;$sources[$key]=($sources[$key]??0)+$n;}
    arsort($categories);arsort($sources);$top=[];foreach(array_slice($sources,0,50,true) as $key=>$visits){[$category,$label]=explode('|',$key,2);$top[]=['category'=>$category,'source'=>$label,'visits'=>$visits];}
    return ['days'=>$days,'external_or_tagged_sessions'=>$total,'by_category'=>$categories,'top_sources'=>$top];
  }

  private static function sanitizeReferrer($value):?string{
    $raw=trim((string)$value);if($raw==='')return null;$u=parse_url($raw);if(!is_array($u)||empty($u['host']))return null;$host=strtolower((string)$u['host']);$host=preg_replace('/^www\./','',$host);if(in_array($host,['techselectai.com'],true))return null;$scheme=in_array(strtolower((string)($u['scheme']??'')),['http','https'],true)?strtolower((string)$u['scheme']):'https';$path=(string)($u['path']??'/');if($path===''||$path[0]!=='/')$path='/';return mb_substr($scheme.'://'.$host.$path,0,1000);
  }
  private static function clean($value,int $max):?string{$v=trim((string)$value);return $v===''?null:mb_substr($v,0,$max);}
}
