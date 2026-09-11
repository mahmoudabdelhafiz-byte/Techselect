<?php
require_once __DIR__.'/PublicReviewIngestion.php';
require_once __DIR__.'/PublicReviewAdminService.php';

final class CommunitySourceCollectors
{
    public const TYPES=['stackexchange_api','rss_atom'];
    private const SOURCE_TYPES=['reddit','public_forum','app_store','vendor_community','independent_blog','public_case_study','other_public'];

    public static function list(PDO $pdo):array
    {
        $sql="SELECT c.*,p.name product,p.slug product_slug,(SELECT COUNT(*) FROM public_review_collected_items i WHERE i.connector_id=c.id AND i.processing_status='pending_analysis') pending_items FROM public_review_connectors c JOIN products p ON p.id=c.product_id ORDER BY c.updated_at DESC,c.id DESC";
        return $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    public static function create(PDO $pdo,array $input,int $uid):array
    {
        $pid=(int)($input['product_id']??0);$type=(string)($input['connector_type']??'');$sourceType=(string)($input['source_type']??'public_forum');
        if($pid<1||!in_array($type,self::TYPES,true)||!in_array($sourceType,self::SOURCE_TYPES,true))throw new InvalidArgumentException('invalid_connector');
        $p=$pdo->prepare("SELECT id,name FROM products WHERE id=? AND status='active'");$p->execute([$pid]);$product=$p->fetch(PDO::FETCH_ASSOC);if(!$product)throw new InvalidArgumentException('active_product_required');
        $name=trim((string)($input['source_name']??''));if($name==='')throw new InvalidArgumentException('source_name_required');
        $base=self::validatePublicUrl((string)($input['base_url']??''));$config=is_array($input['config']??null)?$input['config']:[];
        if($type==='stackexchange_api'){
            if(strtolower((string)parse_url($base,PHP_URL_HOST))!=='api.stackexchange.com')throw new InvalidArgumentException('stackexchange_api_host_required');
            $site=trim((string)($config['site']??'stackoverflow'));if(!preg_match('/^[a-z0-9.-]{2,80}$/i',$site))throw new InvalidArgumentException('invalid_stackexchange_site');
            $config=['site'=>$site,'query'=>mb_substr(trim((string)($config['query']??$product['name'])),0,190),'tagged'=>mb_substr(trim((string)($config['tagged']??'')),0,100),'pagesize'=>max(1,min(50,(int)($config['pagesize']??25)))];
        } else {
            $config=['max_items'=>max(1,min(50,(int)($config['max_items']??25)))];
        }
        $minutes=max(60,min(10080,(int)($input['interval_minutes']??1440)));
        $st=$pdo->prepare("INSERT INTO public_review_connectors(product_id,connector_type,source_type,source_name,base_url,config_json,policy_status,status,interval_minutes,next_run_at,created_by_user_id) VALUES(?,?,?,?,?,?,'pending_review','active',?,NULL,?)");
        $st->execute([$pid,$type,$sourceType,$name,$base,json_encode($config,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),$minutes,$uid]);
        return self::get($pdo,(int)$pdo->lastInsertId());
    }

    public static function get(PDO $pdo,int $id):array
    {
        $st=$pdo->prepare("SELECT c.*,p.name product,p.slug product_slug FROM public_review_connectors c JOIN products p ON p.id=c.product_id WHERE c.id=?");$st->execute([$id]);$c=$st->fetch(PDO::FETCH_ASSOC);if(!$c)throw new RuntimeException('connector_not_found');$c['config']=json_decode($c['config_json']??'{}',true)?:[];unset($c['config_json']);return $c;
    }

    public static function setPolicy(PDO $pdo,int $id,string $policy,?string $notes):array
    {
        if(!in_array($policy,['pending_review','permitted','restricted','blocked'],true))throw new InvalidArgumentException('invalid_policy');
        self::get($pdo,$id);$pdo->prepare("UPDATE public_review_connectors SET policy_status=?,policy_checked_at=NOW(),policy_notes=?,next_run_at=CASE WHEN ?='permitted' THEN NOW() ELSE NULL END WHERE id=?")->execute([$policy,$notes,$policy,$id]);return self::get($pdo,$id);
    }

    public static function run(PDO $pdo,int $id):array
    {
        $c=self::get($pdo,$id);if(($c['status']??'')!=='active')throw new RuntimeException('connector_not_active');if(($c['policy_status']??'')!=='permitted')throw new RuntimeException('connector_policy_not_permitted');
        $run=$pdo->prepare("INSERT INTO public_review_collection_runs(connector_id,product_id,status) VALUES(?,?,'running')");$run->execute([$id,(int)$c['product_id']]);$runId=(int)$pdo->lastInsertId();
        try{
            $result=match($c['connector_type']){'stackexchange_api'=>self::collectStackExchange($c),'rss_atom'=>self::collectFeed($c),default=>throw new RuntimeException('unsupported_connector')};
            $seen=count($result['items']);$new=0;$dup=0;$reject=0;
            foreach($result['items'] as $item){try{$r=self::persistItem($pdo,$c,$runId,$item);if($r==='new')$new++;elseif($r==='duplicate')$dup++;else$reject++;}catch(Throwable $e){$reject++;}}
            $pdo->prepare("UPDATE public_review_collection_runs SET status='completed',items_seen=?,items_new=?,items_duplicate=?,items_rejected=?,response_meta_json=?,completed_at=NOW() WHERE id=?")->execute([$seen,$new,$dup,$reject,json_encode($result['meta']??[],JSON_UNESCAPED_SLASHES),$runId]);
            $pdo->prepare("UPDATE public_review_connectors SET last_run_at=NOW(),next_run_at=DATE_ADD(NOW(),INTERVAL interval_minutes MINUTE),last_error=NULL WHERE id=?")->execute([$id]);
            return ['run_id'=>$runId,'seen'=>$seen,'new'=>$new,'duplicate'=>$dup,'rejected'=>$reject,'meta'=>$result['meta']??[]];
        }catch(Throwable $e){$msg=mb_substr($e->getMessage(),0,500);$pdo->prepare("UPDATE public_review_collection_runs SET status='failed',error_code='collection_failed',error_message=?,completed_at=NOW() WHERE id=?")->execute([$msg,$runId]);$pdo->prepare("UPDATE public_review_connectors SET last_run_at=NOW(),last_error=?,next_run_at=DATE_ADD(NOW(),INTERVAL interval_minutes MINUTE) WHERE id=?")->execute([$msg,$id]);throw $e;}
    }

    public static function analyzePending(PDO $pdo,int $productId,int $limit=25):array
    {
        $limit=max(1,min(25,$limit));$st=$pdo->prepare("SELECT i.id,i.source_id,i.analysis_text FROM public_review_collected_items i JOIN public_review_sources s ON s.id=i.source_id WHERE i.product_id=? AND i.processing_status='pending_analysis' AND i.analysis_text IS NOT NULL AND s.access_policy='permitted' ORDER BY i.retrieved_at ASC LIMIT {$limit}");$st->execute([$productId]);$items=$st->fetchAll(PDO::FETCH_ASSOC);if(!$items)return ['processed'=>0,'message'=>'no_pending_items'];
        $snapshots=[];foreach($items as $i)$snapshots[]=['source_id'=>(int)$i['source_id'],'content'=>(string)$i['analysis_text']];
        $result=PublicReviewAdminService::analyzeProduct($pdo,$productId,$snapshots);$ids=array_map(fn($x)=>(int)$x['id'],$items);$ph=implode(',',array_fill(0,count($ids),'?'));$pdo->prepare("UPDATE public_review_collected_items SET processing_status='analyzed',analyzed_at=NOW(),analysis_text=NULL WHERE id IN({$ph})")->execute($ids);$result['processed']=count($ids);return $result;
    }

    public static function due(PDO $pdo,int $limit=10):array
    {
        $limit=max(1,min(50,$limit));return $pdo->query("SELECT id FROM public_review_connectors WHERE status='active' AND policy_status='permitted' AND (next_run_at IS NULL OR next_run_at<=NOW()) ORDER BY COALESCE(next_run_at,'1970-01-01') LIMIT {$limit}")->fetchAll(PDO::FETCH_COLUMN);
    }

    public static function purgeExpiredText(PDO $pdo):int
    {
        return $pdo->exec("UPDATE public_review_collected_items SET analysis_text=NULL,processing_status=CASE WHEN processing_status='pending_analysis' THEN 'expired_unanalyzed' ELSE processing_status END WHERE analysis_text IS NOT NULL AND purge_after IS NOT NULL AND purge_after<NOW()");
    }

    private static function collectStackExchange(array $c):array
    {
        $cfg=$c['config'];$query=['site'=>$cfg['site']??'stackoverflow','q'=>$cfg['query']??$c['product'],'pagesize'=>$cfg['pagesize']??25,'sort'=>'activity','order'=>'desc','filter'=>'withbody'];if(!empty($cfg['tagged']))$query['tagged']=$cfg['tagged'];$key=trim((string)getenv('TECHSELECT_STACKEXCHANGE_KEY'));if($key!=='')$query['key']=$key;
        $url=rtrim($c['base_url'],'?').'?'.http_build_query($query);$raw=self::httpGet($url,2000000);$data=json_decode($raw['body'],true);if(!is_array($data)||!isset($data['items']))throw new RuntimeException('invalid_stackexchange_response');$items=[];
        foreach($data['items'] as $row){$body=self::normalizeText((string)($row['body']??''));$title=self::normalizeText((string)($row['title']??''));if(mb_strlen($body)<80)continue;$items[]=['external_id'=>(string)($row['question_id']??''),'url'=>(string)($row['link']??''),'title'=>$title,'author'=>(string)($row['owner']['display_name']??''),'published_at'=>isset($row['creation_date'])?date('Y-m-d H:i:s',(int)$row['creation_date']):null,'content'=>$title."\n\n".$body];}
        return ['items'=>$items,'meta'=>['quota_remaining'=>$data['quota_remaining']??null,'backoff'=>$data['backoff']??null,'has_more'=>$data['has_more']??false,'http_status'=>$raw['status']]];
    }

    private static function collectFeed(array $c):array
    {
        $raw=self::httpGet($c['base_url'],2000000);libxml_use_internal_errors(true);$xml=simplexml_load_string($raw['body'],'SimpleXMLElement',LIBXML_NONET|LIBXML_NOCDATA);if(!$xml)throw new RuntimeException('invalid_feed');$limit=(int)($c['config']['max_items']??25);$items=[];
        if(isset($xml->channel->item))foreach($xml->channel->item as $it){if(count($items)>=$limit)break;$link=trim((string)$it->link;$content=(string)($it->description??'');$ns=$it->getNameSpaces(true);if(isset($ns['content'])){$ce=$it->children($ns['content']);if(isset($ce->encoded))$content=(string)$ce->encoded;}$items[]=self::feedItem((string)($it->guid?:$link),$link,(string)$it->title,(string)($it->author??''),(string)($it->pubDate??''),$content);}
        elseif(isset($xml->entry))foreach($xml->entry as $it){if(count($items)>=$limit)break;$link='';foreach($it->link as $ln){$a=$ln->attributes();if((string)($a['rel']??'alternate')==='alternate'||$link==='')$link=(string)$a['href'];}$content=(string)($it->content?:$it->summary);$items[]=self::feedItem((string)($it->id?:$link),$link,(string)$it->title,(string)($it->author->name??''),(string)($it->published?:$it->updated),$content);}
        return ['items'=>array_values(array_filter($items,fn($x)=>mb_strlen($x['content'])>=80)),'meta'=>['http_status'=>$raw['status'],'format'=>isset($xml->channel)?'rss':'atom']];
    }

    private static function feedItem(string $id,string $url,string $title,string $author,string $date,string $content):array
    {
        $published=null;if($date!==''){try{$published=(new DateTimeImmutable($date))->format('Y-m-d H:i:s');}catch(Throwable $e){}}
        $title=self::normalizeText($title);return ['external_id'=>mb_substr($id,0,255),'url'=>$url,'title'=>mb_substr($title,0,500),'author'=>mb_substr(self::normalizeText($author),0,190),'published_at'=>$published,'content'=>$title."\n\n".self::normalizeText($content)];
    }

    private static function persistItem(PDO $pdo,array $c,int $runId,array $item):string
    {
        $url=self::validatePublicUrl((string)($item['url']??''));$content=trim((string)($item['content']??''));if(mb_strlen($content)<80)return 'rejected';$content=mb_substr($content,0,6000);$fp=PublicReviewIngestion::contentFingerprint($content);$uHash=PublicReviewIngestion::urlHash($url);
        $dup=$pdo->prepare("SELECT id FROM public_review_collected_items WHERE product_id=? AND content_fingerprint=? LIMIT 1");$dup->execute([(int)$c['product_id'],$fp]);if($dup->fetchColumn())return 'duplicate';
        $source=$pdo->prepare("SELECT id FROM public_review_sources WHERE product_id=? AND source_url_hash=? LIMIT 1");$source->execute([(int)$c['product_id'],$uHash]);$sourceId=(int)$source->fetchColumn();if(!$sourceId){$ins=$pdo->prepare("INSERT INTO public_review_sources(product_id,source_url,source_url_hash,source_type,source_name,source_published_at,access_policy,access_policy_checked_at,access_policy_notes,content_fingerprint,status) VALUES(?,?,?,?,?,?,'permitted',NOW(),?,?,'active')");$ins->execute([(int)$c['product_id'],$url,$uHash,$c['source_type'],$c['source_name'],$item['published_at']??null,'Inherited from explicitly permitted connector #'.$c['id'],$fp]);$sourceId=(int)$pdo->lastInsertId();}
        $external=mb_substr((string)($item['external_id']??''),0,255);$extHash=$external!==''?hash('sha256',$external,true):null;$ins=$pdo->prepare("INSERT INTO public_review_collected_items(connector_id,collection_run_id,product_id,source_id,external_id,external_id_hash,canonical_url,canonical_url_hash,title,author_label,source_published_at,retrieved_at,content_fingerprint,analysis_text,processing_status,purge_after) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,'pending_analysis',DATE_ADD(NOW(),INTERVAL 7 DAY))");$ins->execute([(int)$c['id'],$runId,(int)$c['product_id'],$sourceId,$external?:null,$extHash,$url,$uHash,mb_substr((string)($item['title']??''),0,500)?:null,mb_substr((string)($item['author']??''),0,190)?:null,$item['published_at']??null,date('Y-m-d H:i:s'),$fp,$content]);return 'new';
    }

    private static function httpGet(string $url,int $maxBytes):array
    {
        self::validatePublicUrl($url);if(!function_exists('curl_init'))throw new RuntimeException('curl_required');$ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_FOLLOWLOCATION=>true,CURLOPT_MAXREDIRS=>3,CURLOPT_CONNECTTIMEOUT=>8,CURLOPT_TIMEOUT=>20,CURLOPT_USERAGENT=>'TechSelectAI-CommunityCollector/1.0',CURLOPT_HTTPHEADER=>['Accept: application/json, application/rss+xml, application/atom+xml, application/xml, text/xml;q=0.9'],CURLOPT_PROTOCOLS=>CURLPROTO_HTTP|CURLPROTO_HTTPS,CURLOPT_REDIR_PROTOCOLS=>CURLPROTO_HTTP|CURLPROTO_HTTPS]);$body=curl_exec($ch);if($body===false){$e=curl_error($ch);curl_close($ch);throw new RuntimeException('http_fetch_failed: '.$e);}if(strlen($body)>$maxBytes){curl_close($ch);throw new RuntimeException('response_too_large');}$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$effective=(string)curl_getinfo($ch,CURLINFO_EFFECTIVE_URL);curl_close($ch);self::validatePublicUrl($effective);if($status<200||$status>=300)throw new RuntimeException('upstream_http_'.$status);return ['body'=>$body,'status'=>$status,'url'=>$effective];
    }

    private static function validatePublicUrl(string $url):string
    {
        $url=trim($url);if(!filter_var($url,FILTER_VALIDATE_URL))throw new InvalidArgumentException('valid_public_url_required');$scheme=strtolower((string)parse_url($url,PHP_URL_SCHEME));if(!in_array($scheme,['http','https'],true))throw new InvalidArgumentException('http_https_only');$host=(string)parse_url($url,PHP_URL_HOST);if($host===''||strtolower($host)==='localhost')throw new InvalidArgumentException('public_host_required');$ips=gethostbynamel($host)?:[];if(!$ips)throw new InvalidArgumentException('unresolvable_host');foreach($ips as $ip)if(!filter_var($ip,FILTER_VALIDATE_IP,FILTER_FLAG_NO_PRIV_RANGE|FILTER_FLAG_NO_RES_RANGE))throw new InvalidArgumentException('private_or_reserved_host_rejected');return $url;
    }
    private static function normalizeText(string $html):string{$s=html_entity_decode(strip_tags($html),ENT_QUOTES|ENT_HTML5,'UTF-8');return trim(preg_replace('/\s+/u',' ',$s)??$s);}
}
