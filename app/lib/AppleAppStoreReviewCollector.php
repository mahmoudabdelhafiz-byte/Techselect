<?php

final class AppleAppStoreReviewCollector
{
    private const SEARCH_HOST='itunes.apple.com';
    private const APP_HOST='apps.apple.com';

    public static function discover(string $productName,string $vendorName,string $country='us'): ?array
    {
        $productName=trim($productName);$vendorName=trim($vendorName);$country=strtolower(trim($country));
        if($productName==='')return null;
        if(!preg_match('/^[a-z]{2}$/',$country))$country='us';
        $query=['term'=>trim($productName.' '.$vendorName),'country'=>$country,'media'=>'software','entity'=>'software','limit'=>10];
        $res=self::requestJson('https://'.self::SEARCH_HOST.'/search?'.http_build_query($query));
        $best=null;$bestScore=0.0;
        foreach((array)($res['results']??[]) as $row){
            $track=trim((string)($row['trackName']??''));$seller=trim((string)($row['sellerName']??$row['artistName']??''));$id=(int)($row['trackId']??0);
            if($track===''||$id<1)continue;
            $nameScore=self::nameScore($productName,$track,$vendorName,$seller);$vendorScore=self::vendorScore($vendorName,$seller);
            $score=round(($nameScore*0.78)+($vendorScore*0.22),4);
            if($nameScore<0.70||$score<0.78||$score<=$bestScore)continue;
            $bestScore=$score;$best=['app_id'=>$id,'track_name'=>$track,'seller_name'=>$seller,'track_url'=>(string)($row['trackViewUrl']??('https://'.self::APP_HOST.'/'.$country.'/app/id'.$id)),'confidence'=>$score,'country'=>$country];
        }
        return $best;
    }

    public static function collect(array $connector): array
    {
        $cfg=is_array($connector['config']??null)?$connector['config']:[];
        $appId=(int)($cfg['app_id']??0);$country=strtolower(trim((string)($cfg['country']??'us')));$max=max(1,min(100,(int)($cfg['max_items']??50)));
        if($appId<1)throw new RuntimeException('apple_app_store_app_id_required');
        if(!preg_match('/^[a-z]{2}$/',$country))$country='us';
        $items=[];$pages=0;$maxPages=min(2,(int)ceil($max/50));
        for($page=1;$page<=$maxPages&&count($items)<$max;$page++){
            $url='https://'.self::SEARCH_HOST.'/'.$country.'/rss/customerreviews/page='.$page.'/id='.$appId.'/sortBy=mostRecent/json';
            $data=self::requestJson($url);$pages++;
            foreach((array)($data['feed']['entry']??[]) as $entry){
                if(!isset($entry['im:rating']['label']))continue;
                $reviewId=trim((string)($entry['id']['label']??''));if($reviewId==='')$reviewId=hash('sha256',json_encode($entry,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
                $rating=(int)($entry['im:rating']['label']??0);$title=self::text((string)($entry['title']['label']??'Apple App Store review'));$body=self::text((string)($entry['content']['label']??''));
                if($body===''&&$rating<1)continue;
                $content=($rating>=1&&$rating<=5?"Apple App Store rating: {$rating}/5":"Apple App Store review").($title!==''?"\nTitle: {$title}":'').($body!==''?"\n\n{$body}":'');
                $date=trim((string)($entry['updated']['label']??''));$published=null;if($date!==''){try{$published=(new DateTimeImmutable($date))->format('Y-m-d H:i:s');}catch(Throwable $e){}}
                $author=self::text((string)($entry['author']['name']['label']??''));
                $publicUrl='https://'.self::APP_HOST.'/'.$country.'/app/id'.$appId.'?see-all=reviews&reviewId='.rawurlencode($reviewId);
                $items[]=['external_id'=>mb_substr($reviewId,0,255),'url'=>$publicUrl,'title'=>$title?:'Apple App Store user review','author'=>$author,'published_at'=>$published,'content'=>$content];
                if(count($items)>=$max)break;
            }
            if(empty($data['feed']['entry']))break;
        }
        return ['items'=>$items,'meta'=>['provider'=>'apple_app_store_public_rss','app_id'=>$appId,'country'=>$country,'pages'=>$pages,'note'=>'Public Apple customer-review RSS feed; review text is retained only temporarily for analysis.']];
    }

    private static function requestJson(string $url): array
    {
        $host=strtolower((string)parse_url($url,PHP_URL_HOST));if($host!==self::SEARCH_HOST)throw new RuntimeException('apple_app_store_host_rejected');
        if(!function_exists('curl_init'))throw new RuntimeException('curl_required');
        $ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_CONNECTTIMEOUT=>8,CURLOPT_TIMEOUT=>20,CURLOPT_USERAGENT=>'TechSelectAI-CommunityCollector/1.0',CURLOPT_HTTPHEADER=>['Accept: application/json'],CURLOPT_PROTOCOLS=>CURLPROTO_HTTPS]);
        $body=curl_exec($ch);if($body===false){$e=curl_error($ch);curl_close($ch);throw new RuntimeException('apple_app_store_fetch_failed: '.$e);}if(strlen((string)$body)>4000000){curl_close($ch);throw new RuntimeException('apple_app_store_response_too_large');}$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);curl_close($ch);
        if($status<200||$status>=300)throw new RuntimeException('apple_app_store_http_'.$status);$data=json_decode((string)$body,true);if(!is_array($data))throw new RuntimeException('apple_app_store_invalid_json');return $data;
    }

    private static function nameScore(string $product,string $track,string $vendor,string $seller): float
    {
        $p=self::norm($product);$t=self::norm($track);if($p===''||$t==='')return 0.0;if($p===$t)return 1.0;
        $vendorScore=self::vendorScore($vendor,$seller);
        if((str_starts_with($t,$p.' ')||str_contains($t,' '.$p.' ')||str_ends_with($t,' '.$p))&&(mb_strlen($p)>=5||$vendorScore>=0.80))return 0.90;
        if((str_contains($t,$p)||str_contains($p,$t))&&min(mb_strlen($p),mb_strlen($t))>=5)return 0.86;
        $pa=array_values(array_unique(array_filter(explode(' ',$p),fn($x)=>mb_strlen($x)>1)));$ta=array_values(array_unique(array_filter(explode(' ',$t),fn($x)=>mb_strlen($x)>1)));if(!$pa||!$ta)return 0.0;
        $intersection=count(array_intersect($pa,$ta));$union=count(array_unique(array_merge($pa,$ta)));return $union?min(0.85,$intersection/$union):0.0;
    }

    private static function vendorScore(string $vendor,string $seller): float
    {
        $v=self::norm($vendor);$s=self::norm($seller);if($v===''||$s==='')return 0.45;if($v===$s)return 1.0;if(str_contains($s,$v)||str_contains($v,$s))return 0.95;
        $va=array_values(array_filter(explode(' ',$v),fn($x)=>mb_strlen($x)>2&&!in_array($x,['inc','ltd','llc','corp','corporation','company','technologies','technology','software'],true)));$sa=array_values(array_filter(explode(' ',$s),fn($x)=>mb_strlen($x)>2));if(!$va)return 0.45;$hit=count(array_intersect($va,$sa));return min(1.0,$hit/max(1,count($va)));
    }

    private static function norm(string $value): string
    {
        $value=mb_strtolower(html_entity_decode($value,ENT_QUOTES|ENT_HTML5,'UTF-8'));$value=str_replace('&',' and ',$value);$value=preg_replace('/[^a-z0-9]+/u',' ',$value)??$value;return trim(preg_replace('/\s+/u',' ',$value)??$value);
    }
    private static function text(string $value): string {$value=html_entity_decode(strip_tags($value),ENT_QUOTES|ENT_HTML5,'UTF-8');return trim(preg_replace('/\s+/u',' ',$value)??$value);}
}
