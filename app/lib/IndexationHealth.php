<?php
final class IndexationHealth {
    public const STRATEGIC_TYPES=['software','category','comparison','alternative','use_case','evaluation','research'];
    public const STATES=['unknown','indexed','discovered_not_indexed','crawled_not_indexed','excluded_noindex','redirect','duplicate_canonicalized','not_found','soft_404'];

    public static function expectedUrls(PDO $pdo,string $siteUrl): array {
        $out=[];$siteUrl=rtrim($siteUrl,'/');
        $add=static function(&$out,$path,$type,$priority='standard',$lastmod=null) use($siteUrl){$out[$path]=['path'=>$path,'canonical_url'=>$siteUrl.$path,'page_type'=>$type,'priority_level'=>$priority,'lastmod'=>$lastmod];};
        $add($out,'/','home','strategic');$add($out,'/software','catalog','strategic');$add($out,'/methodology','methodology','strategic');$add($out,'/trust','trust','standard');$add($out,'/case-studies','case_studies','standard');$add($out,'/research/software-evidence-benchmark','research','strategic');
        try{$q=$pdo->query("SELECT slug,updated_at FROM products WHERE status='active' ORDER BY slug");foreach($q as $r)$add($out,'/software/'.$r['slug'],'software','strategic',$r['updated_at']??null);}catch(Throwable $e){}
        try{$q=$pdo->query("SELECT slug FROM categories WHERE is_active=1 ORDER BY slug");foreach($q as $r)$add($out,'/categories/'.$r['slug'],'category','strategic');}catch(Throwable $e){}
        try{$q=$pdo->query("SELECT p1.slug a,p2.slug b FROM products p1 JOIN products p2 ON p2.category_id=p1.category_id AND p2.id>p1.id WHERE p1.status='active' AND p2.status='active'");foreach($q as $r){$pair=[$r['a'],$r['b']];sort($pair,SORT_STRING);$add($out,'/compare/'.implode('-vs-',$pair),'comparison','strategic');}}catch(Throwable $e){}
        try{$q=$pdo->query("SELECT canonical_path,updated_at FROM seo_generated_pages WHERE publication_status='published' AND quality_decision='indexable'");foreach($q as $r)$add($out,$r['canonical_path'],'use_case','strategic',$r['updated_at']??null);}catch(Throwable $e){}
        return array_values($out);
    }

    public static function syncExpected(PDO $pdo,string $siteUrl,array $sitemapEntries=[]): array {
        $expected=self::expectedUrls($pdo,$siteUrl);$present=[];$lastmods=[];
        foreach($sitemapEntries as $entry){
            if(is_string($entry)){$present[$entry]=true;continue;}
            if(!is_array($entry))continue;$p=(string)($entry['path']??'');if($p==='')continue;$present[$p]=true;if(!empty($entry['lastmod']))$lastmods[$p]=self::dateOrNull($entry['lastmod']);
        }
        $issues=0;$strategic=0;
        $up=$pdo->prepare("INSERT INTO indexation_url_health(canonical_url,path,page_type,priority_level,sitemap_expected,sitemap_present,sitemap_lastmod,issue_codes_json,last_checked_at) VALUES(?,?,?,?,1,?,?,?,NOW()) ON DUPLICATE KEY UPDATE canonical_url=VALUES(canonical_url),page_type=VALUES(page_type),priority_level=VALUES(priority_level),sitemap_expected=1,sitemap_present=VALUES(sitemap_present),sitemap_lastmod=VALUES(sitemap_lastmod),issue_codes_json=VALUES(issue_codes_json),last_checked_at=NOW()");
        foreach($expected as $r){
            $isPresent=isset($present[$r['path']])?1:0;$codes=[];$sitemapLastmod=$lastmods[$r['path']]??null;
            if(!$isPresent)$codes[]='missing_from_sitemap';
            if($isPresent&&!empty($r['lastmod'])&&$sitemapLastmod&&strtotime($sitemapLastmod)<strtotime((string)$r['lastmod'])-86400)$codes[]='stale_sitemap_lastmod';
            if($r['priority_level']==='strategic')$strategic++;if($codes)$issues++;
            $up->execute([$r['canonical_url'],$r['path'],$r['page_type'],$r['priority_level'],$isPresent,$sitemapLastmod,json_encode($codes)]);
        }
        return ['known'=>count($expected),'strategic'=>$strategic,'issues'=>$issues];
    }

    public static function importIndexStates(PDO $pdo,array $rows,string $source): int {
        if(!preg_match('/^[a-z0-9_\-]{2,48}$/i',$source))throw new InvalidArgumentException('invalid_source');$count=0;
        $get=$pdo->prepare('SELECT id,index_state FROM indexation_url_health WHERE path=? LIMIT 1');
        $upd=$pdo->prepare('UPDATE indexation_url_health SET index_state=?,index_state_source=?,discovered_at=COALESCE(?,discovered_at),last_crawled_at=COALESCE(?,last_crawled_at),last_indexed_at=COALESCE(?,last_indexed_at),observed_http_status=COALESCE(?,observed_http_status),observed_canonical_url=COALESCE(?,observed_canonical_url),observed_meta_robots=COALESCE(?,observed_meta_robots),robots_allowed=COALESCE(?,robots_allowed),notes=?,updated_at=NOW() WHERE id=?');
        $hist=$pdo->prepare('INSERT INTO indexation_state_history(url_health_id,index_state,source,detail_json) VALUES(?,?,?,?)');
        foreach($rows as $r){
            $path=(string)($r['path']??'');$state=(string)($r['index_state']??'unknown');if($path===''||!in_array($state,self::STATES,true))continue;$get->execute([$path]);$cur=$get->fetch(PDO::FETCH_ASSOC);if(!$cur)continue;
            $http=isset($r['observed_http_status'])&&is_numeric($r['observed_http_status'])?(int)$r['observed_http_status']:null;$canon=trim((string)($r['observed_canonical_url']??''))?:null;$meta=trim((string)($r['observed_meta_robots']??''))?:null;$robots=array_key_exists('robots_allowed',$r)?(!empty($r['robots_allowed'])?1:0):null;$notes=mb_substr(trim((string)($r['notes']??'')),0,2000)?:null;
            $upd->execute([$state,$source,self::dateOrNull($r['discovered_at']??null),self::dateOrNull($r['last_crawled_at']??null),self::dateOrNull($r['last_indexed_at']??null),$http,$canon,$meta,$robots,$notes,(int)$cur['id']]);
            $hist->execute([(int)$cur['id'],$state,$source,json_encode($r,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)]);$count++;
        }
        return $count;
    }

    public static function probeStrategic(PDO $pdo,string $siteUrl,int $limit=75): array {
        $limit=max(1,min(200,$limit));$siteHost=strtolower((string)parse_url($siteUrl,PHP_URL_HOST));if($siteHost==='')throw new InvalidArgumentException('invalid_site_url');
        $robots=self::robotsRules($siteUrl);$q=$pdo->prepare("SELECT id,path,canonical_url FROM indexation_url_health WHERE priority_level='strategic' ORDER BY COALESCE(last_checked_at,'1970-01-01') ASC,id ASC LIMIT ?");$q->bindValue(1,$limit,PDO::PARAM_INT);$q->execute();
        $upd=$pdo->prepare('UPDATE indexation_url_health SET observed_http_status=?,observed_canonical_url=?,observed_meta_robots=?,robots_allowed=?,last_checked_at=NOW(),updated_at=NOW() WHERE id=?');
        $checked=0;$issues=0;$errors=0;
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $row){
            $url=(string)$row['canonical_url'];$host=strtolower((string)parse_url($url,PHP_URL_HOST));if($host!==$siteHost){$errors++;continue;}
            try{$obs=self::probeUrl($url,$siteHost);$allowed=self::robotsAllows((string)$row['path'],$robots);$upd->execute([$obs['status'],$obs['canonical'],$obs['meta_robots'],$allowed?1:0,(int)$row['id']]);$checked++;if($obs['status']>=300||!$allowed||stripos((string)$obs['meta_robots'],'noindex')!==false||($obs['canonical']&&rtrim($obs['canonical'],'/')!==rtrim($url,'/')))$issues++;}catch(Throwable $e){$errors++;}
        }
        return ['checked'=>$checked,'issues'=>$issues,'errors'=>$errors];
    }

    private static function probeUrl(string $url,string $expectedHost):array{
        $ctx=stream_context_create(['http'=>['method'=>'GET','timeout'=>8,'follow_location'=>0,'ignore_errors'=>true,'user_agent'=>'TechSelectAI-IndexationHealth/2.0','header'=>"Accept: text/html\r\n"],'ssl'=>['verify_peer'=>true,'verify_peer_name'=>true]]);
        $html=@file_get_contents($url,false,$ctx,0,524288);$headers=$http_response_header??[];$status=0;
        foreach($headers as $h){if(preg_match('#^HTTP/\S+\s+(\d{3})#i,$h,$m)){$status=(int)$m[1];break;}}
        if($status===0)throw new RuntimeException('probe_failed');
        $canonical=null;$meta=null;$location=null;
        foreach($headers as $h){if(stripos($h,'Location:')===0)$location=trim(substr($h,9));}
        if(is_string($html)&&$html!==''){
            if(preg_match('#<link[^>]+rel=["\']canonical["\'][^>]+href=["\']([^"\']+)["\']#i',$html,$m)||preg_match('#<link[^>]+href=["\']([^"\']+)["\'][^>]+rel=["\']canonical["\']#i',$html,$m))$canonical=self::absoluteUrl($m[1],$url,$expectedHost);
            if(preg_match('#<meta[^>]+name=["\']robots["\'][^>]+content=["\']([^"\']+)["\']#i',$html,$m)||preg_match('#<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']robots["\']#i',$html,$m))$meta=trim($m[1]);
        }
        if($status>=300&&$status<400&&$location)$canonical=self::absoluteUrl($location,$url,$expectedHost);
        return ['status'=>$status,'canonical'=>$canonical,'meta_robots'=>$meta];
    }

    private static function absoluteUrl(string $value,string $base,string $expectedHost):?string{
        $value=trim($value);if($value==='')return null;if(str_starts_with($value,'/')){$scheme=parse_url($base,PHP_URL_SCHEME)?:'https';return $scheme.'://'.$expectedHost.$value;}
        $host=strtolower((string)parse_url($value,PHP_URL_HOST));return $host===$expectedHost?$value:null;
    }

    private static function robotsRules(string $siteUrl):array{
        $url=rtrim($siteUrl,'/').'/robots.txt';$ctx=stream_context_create(['http'=>['timeout'=>6,'follow_location'=>0,'user_agent'=>'TechSelectAI-IndexationHealth/2.0']]);$txt=@file_get_contents($url,false,$ctx);if(!is_string($txt))return [];$rules=[];$active=false;
        foreach(preg_split('/\R/',$txt) as $line){$line=trim(preg_replace('/#.*/','',$line));if($line==='')continue;if(stripos($line,'User-agent:')===0){$active=trim(substr($line,11))==='*';continue;}if($active&&stripos($line,'Disallow:')===0){$v=trim(substr($line,9));if($v!=='')$rules[]=$v;}}
        return $rules;
    }
    private static function robotsAllows(string $path,array $rules):bool{foreach($rules as $r){if($r==='/'||str_starts_with($path,$r))return false;}return true;}

    public static function recordDailySnapshot(PDO $pdo):array{
        $r=$pdo->query("SELECT COUNT(*) total_urls,SUM(priority_level='strategic') strategic_urls,SUM(priority_level='strategic' AND index_state='indexed') indexed_strategic,SUM(priority_level='strategic' AND index_state IN ('discovered_not_indexed','crawled_not_indexed')) stuck_strategic,SUM(priority_level='strategic' AND index_state IN ('excluded_noindex','redirect','duplicate_canonicalized','not_found','soft_404')) technical_exclusions_strategic,SUM(priority_level='strategic' AND sitemap_present=0) missing_sitemap_strategic FROM indexation_url_health")->fetch(PDO::FETCH_ASSOC)?:[];
        $pdo->prepare("INSERT INTO indexation_daily_snapshots(snapshot_date,total_urls,strategic_urls,indexed_strategic,stuck_strategic,technical_exclusions_strategic,missing_sitemap_strategic) VALUES(CURDATE(),?,?,?,?,?,?) ON DUPLICATE KEY UPDATE total_urls=VALUES(total_urls),strategic_urls=VALUES(strategic_urls),indexed_strategic=VALUES(indexed_strategic),stuck_strategic=VALUES(stuck_strategic),technical_exclusions_strategic=VALUES(technical_exclusions_strategic),missing_sitemap_strategic=VALUES(missing_sitemap_strategic)")->execute([(int)($r['total_urls']??0),(int)($r['strategic_urls']??0),(int)($r['indexed_strategic']??0),(int)($r['stuck_strategic']??0),(int)($r['technical_exclusions_strategic']??0),(int)($r['missing_sitemap_strategic']??0)]);
        self::detectAlerts($pdo,$r);return $r;
    }

    private static function detectAlerts(PDO $pdo,array $current):void{
        $prev=$pdo->query("SELECT * FROM indexation_daily_snapshots WHERE snapshot_date<CURDATE() ORDER BY snapshot_date DESC LIMIT 1")->fetch(PDO::FETCH_ASSOC);if(!$prev)return;
        $before=(int)$prev['indexed_strategic'];$now=(int)($current['indexed_strategic']??0);$drop=$before-$now;$pct=$before>0?($drop/$before)*100:0;
        if($before>=5&&$drop>=3&&$pct>=20)self::upsertAlert($pdo,'strategic_index_drop','critical','strategic_index_drop','Strategic indexed URLs dropped by '.$drop.' ('.round($pct,1).'%) since '.$prev['snapshot_date'],['previous'=>$before,'current'=>$now,'previous_date'=>$prev['snapshot_date']]);else self::resolveAlert($pdo,'strategic_index_drop');
        $techBefore=(int)$prev['technical_exclusions_strategic'];$techNow=(int)($current['technical_exclusions_strategic']??0);if($techNow>=$techBefore+3)self::upsertAlert($pdo,'technical_exclusion_spike','warning','technical_exclusion_spike','Strategic technical exclusions increased from '.$techBefore.' to '.$techNow,['previous'=>$techBefore,'current'=>$techNow]);else self::resolveAlert($pdo,'technical_exclusion_spike');
    }
    private static function upsertAlert(PDO $pdo,string $type,string $severity,string $key,string $message,array $detail):void{$pdo->prepare("INSERT INTO indexation_health_alerts(alert_type,severity,alert_key,message,detail_json,status) VALUES(?,?,?,?,?,'open') ON DUPLICATE KEY UPDATE severity=VALUES(severity),message=VALUES(message),detail_json=VALUES(detail_json),status='open',last_seen_at=NOW(),resolved_at=NULL")->execute([$type,$severity,$key,$message,json_encode($detail)]);}
    private static function resolveAlert(PDO $pdo,string $key):void{$pdo->prepare("UPDATE indexation_health_alerts SET status='resolved',resolved_at=NOW() WHERE alert_key=? AND status='open'")->execute([$key]);}

    public static function dashboard(PDO $pdo): array {
        $summary=$pdo->query("SELECT COUNT(*) total,SUM(priority_level='strategic') strategic,SUM(sitemap_present=1) in_sitemap,SUM(index_state='indexed') indexed,SUM(index_state IN ('discovered_not_indexed','crawled_not_indexed')) stuck,SUM(index_state IN ('excluded_noindex','redirect','duplicate_canonicalized','not_found','soft_404')) technical_exclusions FROM indexation_url_health")->fetch(PDO::FETCH_ASSOC)?:[];
        $q=$pdo->query("SELECT id,path,page_type,priority_level,sitemap_present,sitemap_lastmod,observed_http_status,observed_canonical_url,observed_meta_robots,robots_allowed,index_state,index_state_source,discovered_at,last_crawled_at,last_indexed_at,last_checked_at,issue_codes_json,notes,updated_at FROM indexation_url_health ORDER BY FIELD(priority_level,'strategic','standard','low'),FIELD(index_state,'crawled_not_indexed','discovered_not_indexed','excluded_noindex','not_found','soft_404','redirect','duplicate_canonicalized','unknown','indexed'),path LIMIT 1000");$rows=$q->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as &$r){$r['issue_codes']=json_decode($r['issue_codes_json']?:'[]',true)?:[];unset($r['issue_codes_json']);$r['attention']=self::attention($r);}unset($r);
        try{$alerts=$pdo->query("SELECT alert_type,severity,message,status,first_seen_at,last_seen_at FROM indexation_health_alerts WHERE status='open' ORDER BY FIELD(severity,'critical','warning','info'),last_seen_at DESC LIMIT 20")->fetchAll(PDO::FETCH_ASSOC);}catch(Throwable $e){$alerts=[];}
        try{$trend=$pdo->query("SELECT snapshot_date,strategic_urls,indexed_strategic,stuck_strategic,technical_exclusions_strategic,missing_sitemap_strategic FROM indexation_daily_snapshots ORDER BY snapshot_date DESC LIMIT 30")->fetchAll(PDO::FETCH_ASSOC);}catch(Throwable $e){$trend=[];}
        return ['summary'=>$summary,'urls'=>$rows,'alerts'=>$alerts,'trend'=>array_reverse($trend),'generated_at'=>gmdate('c')];
    }

    public static function attention(array $r): array {
        $reasons=[];$ageDays=null;if(!empty($r['discovered_at']))$ageDays=(int)floor((time()-strtotime($r['discovered_at']))/86400);
        if(($r['priority_level']??'')==='strategic'&&in_array($r['index_state']??'',['discovered_not_indexed','crawled_not_indexed'],true)&&$ageDays!==null&&$ageDays>=14)$reasons[]='strategic_url_unindexed_14d';
        foreach(($r['issue_codes']??[]) as $c)$reasons[]=$c;if(empty($r['sitemap_present']))$reasons[]='missing_from_sitemap';if(($r['robots_allowed']??1)===0)$reasons[]='robots_blocked';if(stripos((string)($r['observed_meta_robots']??''),'noindex')!==false)$reasons[]='noindex';if(!empty($r['observed_http_status'])&&(int)$r['observed_http_status']>=400)$reasons[]='http_error';if(!empty($r['observed_http_status'])&&(int)$r['observed_http_status']>=300&&(int)$r['observed_http_status']<400)$reasons[]='redirect';
        $observedCanonical=trim((string)($r['observed_canonical_url']??''));$expected=(string)($r['canonical_url']??'');if($observedCanonical!==''&&$expected!==''&&rtrim($observedCanonical,'/')!==rtrim($expected,'/'))$reasons[]='canonical_mismatch';
        return ['needs_attention'=>(bool)$reasons,'reasons'=>array_values(array_unique($reasons)),'age_days'=>$ageDays];
    }

    private static function dateOrNull($v):?string{if(!$v)return null;$t=strtotime((string)$v);return $t?date('Y-m-d H:i:s',$t):null;}
}
