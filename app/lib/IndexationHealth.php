<?php
final class IndexationHealth {
    public const STRATEGIC_TYPES=['software','category','comparison','alternative','use_case','evaluation','research'];
    public const STATES=['unknown','indexed','discovered_not_indexed','crawled_not_indexed','excluded_noindex','redirect','duplicate_canonicalized','not_found','soft_404'];

    public static function expectedUrls(PDO $pdo,string $siteUrl): array {
        $out=[];$siteUrl=rtrim($siteUrl,'/');
        $add=static function(&$out,$path,$type,$priority='standard',$lastmod=null) use($siteUrl){$out[$path]=['path'=>$path,'canonical_url'=>$siteUrl.$path,'page_type'=>$type,'priority_level'=>$priority,'lastmod'=>$lastmod];};
        $add($out,'/','home','strategic');$add($out,'/software','catalog','strategic');$add($out,'/methodology','methodology','strategic');$add($out,'/trust','trust','standard');$add($out,'/case-studies','case_studies','standard');
        try{$q=$pdo->query("SELECT slug,updated_at FROM products WHERE status='active' ORDER BY slug");foreach($q as $r)$add($out,'/software/'.$r['slug'],'software','strategic',$r['updated_at']??null);}catch(Throwable $e){}
        try{$q=$pdo->query("SELECT slug FROM categories WHERE is_active=1 ORDER BY slug");foreach($q as $r)$add($out,'/categories/'.$r['slug'],'category','strategic');}catch(Throwable $e){}
        try{$q=$pdo->query("SELECT p1.slug a,p2.slug b FROM products p1 JOIN products p2 ON p2.category_id=p1.category_id AND p2.id>p1.id WHERE p1.status='active' AND p2.status='active'");foreach($q as $r){$pair=[$r['a'],$r['b']];sort($pair,SORT_STRING);$add($out,'/compare/'.implode('-vs-',$pair),'comparison','strategic');}}catch(Throwable $e){}
        return array_values($out);
    }

    public static function syncExpected(PDO $pdo,string $siteUrl,array $sitemapPaths=[]): array {
        $expected=self::expectedUrls($pdo,$siteUrl);$present=array_fill_keys($sitemapPaths,true);$issues=0;$strategic=0;
        $up=$pdo->prepare("INSERT INTO indexation_url_health(canonical_url,path,page_type,priority_level,sitemap_expected,sitemap_present,sitemap_lastmod,issue_codes_json,last_checked_at) VALUES(?,?,?,?,1,?,?,?,NOW()) ON DUPLICATE KEY UPDATE canonical_url=VALUES(canonical_url),page_type=VALUES(page_type),priority_level=VALUES(priority_level),sitemap_expected=1,sitemap_present=VALUES(sitemap_present),sitemap_lastmod=VALUES(sitemap_lastmod),issue_codes_json=VALUES(issue_codes_json),last_checked_at=NOW()");
        foreach($expected as $r){$isPresent=isset($present[$r['path']])?1:0;$codes=[];if(!$isPresent)$codes[]='missing_from_sitemap';if($r['priority_level']==='strategic')$strategic++;if($codes)$issues++;$up->execute([$r['canonical_url'],$r['path'],$r['page_type'],$r['priority_level'],$isPresent,$r['lastmod']?date('Y-m-d H:i:s',strtotime($r['lastmod'])):null,json_encode($codes)]);}
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

    public static function dashboard(PDO $pdo): array {
        $summary=$pdo->query("SELECT COUNT(*) total,SUM(priority_level='strategic') strategic,SUM(sitemap_present=1) in_sitemap,SUM(index_state='indexed') indexed,SUM(index_state IN ('discovered_not_indexed','crawled_not_indexed')) stuck,SUM(index_state IN ('excluded_noindex','redirect','duplicate_canonicalized','not_found','soft_404')) technical_exclusions FROM indexation_url_health")->fetch(PDO::FETCH_ASSOC)?:[];
        $q=$pdo->query("SELECT id,path,page_type,priority_level,sitemap_present,sitemap_lastmod,observed_http_status,observed_canonical_url,observed_meta_robots,robots_allowed,index_state,index_state_source,discovered_at,last_crawled_at,last_indexed_at,last_checked_at,issue_codes_json,notes,updated_at FROM indexation_url_health ORDER BY FIELD(priority_level,'strategic','standard','low'),FIELD(index_state,'crawled_not_indexed','discovered_not_indexed','excluded_noindex','not_found','soft_404','redirect','duplicate_canonicalized','unknown','indexed'),path LIMIT 1000");$rows=$q->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as &$r){$r['issue_codes']=json_decode($r['issue_codes_json']?:'[]',true)?:[];unset($r['issue_codes_json']);$r['attention']=self::attention($r);}unset($r);
        return ['summary'=>$summary,'urls'=>$rows,'generated_at'=>gmdate('c')];
    }

    public static function attention(array $r): array {
        $reasons=[];$ageDays=null;if(!empty($r['discovered_at']))$ageDays=(int)floor((time()-strtotime($r['discovered_at']))/86400);
        if(($r['priority_level']??'')==='strategic'&&in_array($r['index_state']??'',['discovered_not_indexed','crawled_not_indexed'],true)&&$ageDays!==null&&$ageDays>=14)$reasons[]='strategic_url_unindexed_14d';
        if(empty($r['sitemap_present']))$reasons[]='missing_from_sitemap';if(($r['robots_allowed']??1)===0)$reasons[]='robots_blocked';if(stripos((string)($r['observed_meta_robots']??''),'noindex')!==false)$reasons[]='noindex';if(!empty($r['observed_http_status'])&&(int)$r['observed_http_status']>=400)$reasons[]='http_error';
        $observedCanonical=trim((string)($r['observed_canonical_url']??''));if($observedCanonical!==''&&!str_ends_with(rtrim($observedCanonical,'/'),rtrim((string)($r['path']??''),'/')))$reasons[]='canonical_mismatch';
        return ['needs_attention'=>(bool)$reasons,'reasons'=>array_values(array_unique($reasons)),'age_days'=>$ageDays];
    }

    private static function dateOrNull($v):?string{if(!$v)return null;$t=strtotime((string)$v);return $t?date('Y-m-d H:i:s',$t):null;}
}
