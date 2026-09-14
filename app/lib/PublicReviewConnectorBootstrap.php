<?php
require_once __DIR__.'/AppleAppStoreReviewCollector.php';

final class PublicReviewConnectorBootstrap
{
    private const STACK_BASE='https://api.stackexchange.com/2.3/search/advanced';
    private const HN_BASE='https://hn.algolia.com/api/v1/search_by_date';

    public static function ensure(PDO $pdo,int $appleDiscoveryLimit=8): array
    {
        $summary=['products_seen'=>0,'connectors_created'=>0,'connectors_existing'=>0,'apple_checked'=>0,'apple_matched'=>0,'apple_no_match'=>0,'apple_errors'=>0];
        $rows=$pdo->query("SELECT p.id,p.name,p.slug,COALESCE(v.name,'') vendor_name FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.status='active' ORDER BY p.id")->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as $p){
            $summary['products_seen']++;$query=trim((string)$p['name'].' '.(string)$p['vendor_name']);
            $connectors=[
                ['stackexchange_api','public_forum','Stack Exchange',self::STACK_BASE,['site'=>'stackoverflow','query'=>$query,'tagged'=>'','pagesize'=>25]],
                ['rss_atom','reddit','Reddit public search','https://www.reddit.com/search.rss?q='.rawurlencode('"'.$p['name'].'" '.$p['vendor_name']).'&sort=new&t=year',['max_items'=>25]],
                ['hackernews_algolia_api','other_public','Hacker News',self::HN_BASE,['query'=>$query,'max_items'=>25]],
            ];
            foreach($connectors as [$type,$sourceType,$name,$base,$config]){
                if(self::connectorExists($pdo,(int)$p['id'],$type,$name)){$summary['connectors_existing']++;continue;}
                self::insertConnector($pdo,(int)$p['id'],$type,$sourceType,$name,$base,$config,'active',1440,'Automatic public-source bootstrap. Machine policy and publication quality gates remain mandatory.');$summary['connectors_created']++;
            }
        }
        if($appleDiscoveryLimit>0)self::discoverAppleApps($pdo,$summary,min(20,max(1,$appleDiscoveryLimit)));
        return $summary;
    }

    private static function discoverAppleApps(PDO $pdo,array &$summary,int $limit): void
    {
        $sql="SELECT p.id,p.name,p.slug,COALESCE(v.name,'') vendor_name,c.id connector_id,c.status connector_status,c.updated_at connector_updated,c.config_json connector_config
              FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id
              LEFT JOIN public_review_connectors c ON c.id=(SELECT MAX(x.id) FROM public_review_connectors x WHERE x.product_id=p.id AND x.connector_type='apple_app_store_reviews')
              WHERE p.status='active' AND (
                    c.id IS NULL OR (
                      c.status='inactive' AND JSON_UNQUOTE(JSON_EXTRACT(c.config_json,'$.discovery_status'))='no_match'
                      AND c.updated_at<=DATE_SUB(NOW(),INTERVAL 30 DAY)
                    )
              )
              ORDER BY COALESCE(c.updated_at,'1970-01-01'),p.id LIMIT ".(int)$limit;
        foreach($pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC) as $p){
            $summary['apple_checked']++;
            try{$match=AppleAppStoreReviewCollector::discover((string)$p['name'],(string)$p['vendor_name'],'us');}
            catch(Throwable $e){$summary['apple_errors']++;continue;}
            if($match){
                $summary['apple_matched']++;$appId=(int)$match['app_id'];$base='https://itunes.apple.com/us/rss/customerreviews/id='.$appId.'/sortBy=mostRecent/json';
                $config=['app_id'=>$appId,'country'=>'us','max_items'=>50,'track_name'=>$match['track_name'],'seller_name'=>$match['seller_name'],'match_confidence'=>$match['confidence'],'track_url'=>$match['track_url'],'discovery_status'=>'matched'];
                if(!empty($p['connector_id'])){
                    $st=$pdo->prepare("UPDATE public_review_connectors SET source_type='app_store',source_name='Apple App Store',base_url=?,config_json=?,policy_status='permitted',policy_checked_at=NOW(),policy_notes=?,status='active',interval_minutes=1440,next_run_at=NOW(),last_error=NULL WHERE id=?");
                    $st->execute([$base,json_encode($config,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),'Automatically matched against Apple public catalog with confidence '.$match['confidence'].'.',(int)$p['connector_id']]);
                } else self::insertConnector($pdo,(int)$p['id'],'apple_app_store_reviews','app_store','Apple App Store',$base,$config,'active',1440,'Automatically matched against Apple public catalog with confidence '.$match['confidence'].'.');
            } else {
                $summary['apple_no_match']++;$config=['discovery_status'=>'no_match','last_checked_at'=>gmdate('c')];
                if(!empty($p['connector_id'])){
                    $st=$pdo->prepare("UPDATE public_review_connectors SET source_type='app_store',source_name='Apple App Store discovery',base_url='https://itunes.apple.com/search',config_json=?,policy_status='permitted',policy_checked_at=NOW(),policy_notes='No confident Apple App Store match; automatic discovery retries after 30 days.',status='inactive',interval_minutes=10080,next_run_at=NULL,last_error=NULL WHERE id=?");$st->execute([json_encode($config,JSON_UNESCAPED_SLASHES),(int)$p['connector_id']]);
                } else self::insertConnector($pdo,(int)$p['id'],'apple_app_store_reviews','app_store','Apple App Store discovery','https://itunes.apple.com/search',$config,'inactive',10080,'No confident Apple App Store match; automatic discovery retries after 30 days.');
            }
        }
    }

    private static function connectorExists(PDO $pdo,int $productId,string $type,string $name): bool
    {
        $st=$pdo->prepare("SELECT 1 FROM public_review_connectors WHERE product_id=? AND connector_type=? AND source_name=? LIMIT 1");$st->execute([$productId,$type,$name]);return (bool)$st->fetchColumn();
    }

    private static function insertConnector(PDO $pdo,int $productId,string $type,string $sourceType,string $name,string $base,array $config,string $status,int $interval,string $notes): void
    {
        $st=$pdo->prepare("INSERT INTO public_review_connectors(product_id,connector_type,source_type,source_name,base_url,config_json,policy_status,policy_checked_at,policy_notes,status,interval_minutes,next_run_at,created_by_user_id) VALUES(?,?,?,?,?,?,'permitted',NOW(),?,?,?,CASE WHEN ?='active' THEN NOW() ELSE NULL END,NULL)");
        $st->execute([$productId,$type,$sourceType,$name,$base,json_encode($config,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),$notes,$status,$interval,$status]);
    }
}
