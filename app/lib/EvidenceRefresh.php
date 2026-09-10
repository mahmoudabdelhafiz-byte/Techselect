<?php
final class EvidenceRefresh{
  private const MAX_BYTES=2097152;
  private const MAX_REDIRECTS=3;

  public static function fingerprint(string $body,string $contentType=''):string{
    $text=$body;
    if(stripos($contentType,'html')!==false || stripos($body,'<html')!==false){
      $text=preg_replace('#<script\b[^>]*>.*?</script>#is',' ',$text)??$text;
      $text=preg_replace('#<style\b[^>]*>.*?</style>#is',' ',$text)??$text;
      $text=strip_tags($text);
      $text=html_entity_decode($text,ENT_QUOTES|ENT_HTML5,'UTF-8');
    }
    $text=preg_replace('/\s+/u',' ',trim($text))??trim($text);
    return hash('sha256',$text,true);
  }

  public static function isSafeIp(string $ip):bool{
    return filter_var($ip,FILTER_VALIDATE_IP,FILTER_FLAG_NO_PRIV_RANGE|FILTER_FLAG_NO_RES_RANGE)!==false;
  }

  public static function validateUrl(string $url):array{
    if(!filter_var($url,FILTER_VALIDATE_URL))throw new RuntimeException('invalid_url');
    $p=parse_url($url);$scheme=strtolower((string)($p['scheme']??''));
    if(!in_array($scheme,['http','https'],true))throw new RuntimeException('unsupported_scheme');
    if(isset($p['user'])||isset($p['pass']))throw new RuntimeException('credentials_not_allowed');
    $host=strtolower(rtrim((string)($p['host']??''),'.'));if($host==='')throw new RuntimeException('missing_host');
    if($host==='localhost'||str_ends_with($host,'.localhost'))throw new RuntimeException('unsafe_host');
    $ips=gethostbynamel($host)?:[];if(!$ips)throw new RuntimeException('dns_failed');
    foreach($ips as $ip)if(!self::isSafeIp($ip))throw new RuntimeException('unsafe_ip');
    return ['url'=>$url,'scheme'=>$scheme,'host'=>$host,'port'=>(int)($p['port']??($scheme==='https'?443:80)),'ip'=>$ips[0]];
  }

  private static function fetch(string $url):array{
    $current=$url;
    for($hop=0;$hop<=self::MAX_REDIRECTS;$hop++){
      $safe=self::validateUrl($current);$body='';$headers=[];
      $ch=curl_init($current);if(!$ch)throw new RuntimeException('curl_init_failed');
      curl_setopt_array($ch,[CURLOPT_FOLLOWLOCATION=>false,CURLOPT_RETURNTRANSFER=>false,CURLOPT_CONNECTTIMEOUT=>8,CURLOPT_TIMEOUT=>20,CURLOPT_USERAGENT=>'TechSelectAI-EvidenceRefresh/1.0',CURLOPT_SSL_VERIFYPEER=>true,CURLOPT_SSL_VERIFYHOST=>2,CURLOPT_RESOLVE=>[$safe['host'].':'.$safe['port'].':'.$safe['ip']],CURLOPT_HEADERFUNCTION=>static function($ch,$line)use(&$headers){$len=strlen($line);$parts=explode(':',$line,2);if(count($parts)===2)$headers[strtolower(trim($parts[0]))]=trim($parts[1]);return $len;},CURLOPT_WRITEFUNCTION=>static function($ch,$chunk)use(&$body){$remaining=self::MAX_BYTES-strlen($body);if($remaining<=0)return 0;$take=substr($chunk,0,$remaining);$body.=$take;return strlen($chunk)===strlen($take)?strlen($chunk):0;}]);
      $ok=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$ctype=(string)curl_getinfo($ch,CURLINFO_CONTENT_TYPE);$err=curl_error($ch);curl_close($ch);
      if($ok===false && strlen($body)<self::MAX_BYTES)throw new RuntimeException($err!==''?'http_error':'fetch_failed');
      if(in_array($status,[301,302,303,307,308],true)){
        $loc=$headers['location']??'';if($loc==='')throw new RuntimeException('redirect_without_location');
        if(!preg_match('#^https?://#i',$loc)){
          $base=$safe['scheme'].'://'.$safe['host'].(($safe['scheme']==='https'&&$safe['port']===443)||($safe['scheme']==='http'&&$safe['port']===80)?'':':'.$safe['port']);
          $loc=$base.'/'.ltrim($loc,'/');
        }
        $current=$loc;continue;
      }
      if($status<200||$status>=300)throw new RuntimeException('http_status_'.$status);
      return ['status'=>$status,'content_type'=>$ctype,'body'=>$body,'final_url'=>$current];
    }
    throw new RuntimeException('too_many_redirects');
  }

  public static function check(PDO $pdo,int $sourceId):array{
    $st=$pdo->prepare('SELECT id,source_url FROM evidence_sources WHERE id=? LIMIT 1');$st->execute([$sourceId]);$source=$st->fetch();
    if(!$source)throw new RuntimeException('source_not_found');
    $url=trim((string)$source['source_url']);if($url==='')throw new RuntimeException('source_url_missing');
    $urlHash=hash('sha256',$url,true);
    try{
      $f=self::fetch($url);$fp=self::fingerprint($f['body'],$f['content_type']);
      $prev=$pdo->prepare("SELECT content_fingerprint FROM evidence_refresh_checks WHERE evidence_source_id=? AND content_fingerprint IS NOT NULL AND change_state IN ('initial','unchanged','changed') ORDER BY id DESC LIMIT 1");$prev->execute([$sourceId]);$old=$prev->fetchColumn();
      $state=$old===false?'initial':(hash_equals((string)$old,$fp)?'unchanged':'changed');
      $pdo->beginTransaction();
      $pdo->prepare('INSERT INTO evidence_refresh_checks(evidence_source_id,source_url_hash,http_status,content_fingerprint,change_state) VALUES(?,?,?,?,?)')->execute([$sourceId,$urlHash,$f['status'],$fp,$state]);
      if($state==='changed')$pdo->prepare("INSERT IGNORE INTO evidence_change_candidates(evidence_source_id,previous_fingerprint,current_fingerprint,status) VALUES(?,?,?,'pending_review')")->execute([$sourceId,$old,$fp]);
      $pdo->prepare('UPDATE evidence_sources SET checked_at=NOW() WHERE id=?')->execute([$sourceId]);$pdo->commit();
      return ['source_id'=>$sourceId,'state'=>$state,'http_status'=>$f['status'],'candidate_created'=>$state==='changed'];
    }catch(Throwable $e){
      $code=substr(preg_replace('/[^a-z0-9_\-\.]/i','_',strtolower($e->getMessage()))??'refresh_failed',0,64);
      try{$pdo->prepare("INSERT INTO evidence_refresh_checks(evidence_source_id,source_url_hash,change_state,error_code) VALUES(?,?,'error',?)")->execute([$sourceId,$urlHash,$code]);}catch(Throwable $ignored){}
      return ['source_id'=>$sourceId,'state'=>'error','error'=>$code];
    }
  }
}
