<?php

final class GooglePlayReviewCollector
{
    private const SCOPE='https://www.googleapis.com/auth/androidpublisher';
    private const TOKEN_URL='https://oauth2.googleapis.com/token';
    private static ?array $tokenCache=null;

    public static function collect(array $connector): array
    {
        $cfg=is_array($connector['config']??null)?$connector['config']:[];
        $package=trim((string)($cfg['package_name']??''));
        if(!preg_match('/^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+$/',$package))throw new RuntimeException('google_play_invalid_package_name');
        $max=max(1,min(100,(int)($cfg['max_items']??50)));
        $language=trim((string)($cfg['translation_language']??'en'));
        if(!preg_match('/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{2,8})?$/',$language))$language='en';
        $base='https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'.rawurlencode($package).'/reviews';
        $listing='https://play.google.com/store/apps/details?id='.rawurlencode($package);
        $accessToken=self::accessToken();
        $items=[];$pageToken=null;$pages=0;
        do{
            $query=['maxResults'=>min(100,$max-count($items)),'translationLanguage'=>$language];
            if($pageToken)$query['token']=$pageToken;
            $res=self::requestJson($base.'?'.http_build_query($query),$accessToken);
            foreach(($res['data']['reviews']??[]) as $review){
                $item=self::reviewItem($review,$listing);
                if($item!==null)$items[]=$item;
                if(count($items)>=$max)break;
            }
            $pageToken=(string)($res['data']['tokenPagination']['nextPageToken']??'');$pages++;
        }while($pageToken!==''&&count($items)<$max&&$pages<5);
        return ['items'=>$items,'meta'=>['provider'=>'google_play_developer_api','package_name'=>$package,'pages'=>$pages,'http_status'=>200,'note'=>'Google Play Developer API reviews endpoint; availability is controlled by Google and Play Console authorization.']];
    }

    private static function reviewItem(array $review,string $listing): ?array
    {
        $reviewId=trim((string)($review['reviewId']??''));if($reviewId==='')return null;
        $user=null;
        foreach((array)($review['comments']??[]) as $comment){if(isset($comment['userComment'])&&is_array($comment['userComment']))$user=$comment['userComment'];}
        if(!$user)return null;
        $text=self::normalize((string)($user['text']??''));$rating=(int)($user['starRating']??0);
        if($rating<1||$rating>5)$rating=0;
        if($text===''&&$rating===0)return null;
        $content=($rating?"Google Play rating: {$rating}/5":"Google Play review").($text!==''?"\n\n{$text}":'');
        $seconds=(int)($user['lastModified']['seconds']??0);$published=$seconds>0?gmdate('Y-m-d H:i:s',$seconds):null;
        // reviewId is used only as an opaque attribution key; the public URL still resolves to the app listing.
        $url=$listing.'&reviewId='.rawurlencode($reviewId);
        return ['external_id'=>$reviewId,'url'=>$url,'title'=>'Google Play user review','author'=>self::normalize((string)($review['authorName']??'')),'published_at'=>$published,'content'=>$content];
    }

    private static function accessToken(): string
    {
        if(self::$tokenCache&&((int)self::$tokenCache['expires_at'])>time()+60)return (string)self::$tokenCache['token'];
        $file=trim((string)getenv('TECHSELECT_GOOGLE_PLAY_SERVICE_ACCOUNT_FILE'));
        if($file==='')throw new RuntimeException('google_play_service_account_file_required');
        if(!is_file($file)||!is_readable($file))throw new RuntimeException('google_play_service_account_file_unreadable');
        $cred=json_decode((string)file_get_contents($file),true);
        if(!is_array($cred))throw new RuntimeException('google_play_service_account_json_invalid');
        $email=trim((string)($cred['client_email']??''));$privateKey=(string)($cred['private_key']??'');$tokenUri=trim((string)($cred['token_uri']??self::TOKEN_URL));
        if($email===''||$privateKey==='')throw new RuntimeException('google_play_service_account_credentials_incomplete');
        if($tokenUri!==self::TOKEN_URL)throw new RuntimeException('google_play_unexpected_token_uri');
        $now=time();$header=self::b64(json_encode(['alg'=>'RS256','typ'=>'JWT'],JSON_UNESCAPED_SLASHES));
        $claims=self::b64(json_encode(['iss'=>$email,'scope'=>self::SCOPE,'aud'=>$tokenUri,'iat'=>$now,'exp'=>$now+3600],JSON_UNESCAPED_SLASHES));
        $input=$header.'.'.$claims;$signature='';
        if(!openssl_sign($input,$signature,$privateKey,OPENSSL_ALGO_SHA256))throw new RuntimeException('google_play_jwt_sign_failed');
        $jwt=$input.'.'.self::b64($signature);
        if(!function_exists('curl_init'))throw new RuntimeException('curl_required');
        $ch=curl_init($tokenUri);curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>http_build_query(['grant_type'=>'urn:ietf:params:oauth:grant-type:jwt-bearer','assertion'=>$jwt]),CURLOPT_CONNECTTIMEOUT=>8,CURLOPT_TIMEOUT=>20,CURLOPT_HTTPHEADER=>['Accept: application/json','Content-Type: application/x-www-form-urlencoded'],CURLOPT_PROTOCOLS=>CURLPROTO_HTTPS]);
        $body=curl_exec($ch);if($body===false){$e=curl_error($ch);curl_close($ch);throw new RuntimeException('google_play_token_fetch_failed: '.$e);} $status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);curl_close($ch);
        $data=json_decode((string)$body,true);if($status<200||$status>=300||!is_array($data)||empty($data['access_token']))throw new RuntimeException('google_play_token_rejected');
        self::$tokenCache=['token'=>(string)$data['access_token'],'expires_at'=>$now+max(300,(int)($data['expires_in']??3600))];return (string)self::$tokenCache['token'];
    }

    private static function requestJson(string $url,string $token): array
    {
        if(!function_exists('curl_init'))throw new RuntimeException('curl_required');
        $host=strtolower((string)parse_url($url,PHP_URL_HOST));if($host!=='androidpublisher.googleapis.com')throw new RuntimeException('google_play_api_host_rejected');
        $ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_CONNECTTIMEOUT=>8,CURLOPT_TIMEOUT=>20,CURLOPT_USERAGENT=>'TechSelectAI-CommunityCollector/1.0',CURLOPT_HTTPHEADER=>['Accept: application/json','Authorization: Bearer '.$token],CURLOPT_PROTOCOLS=>CURLPROTO_HTTPS]);
        $body=curl_exec($ch);if($body===false){$e=curl_error($ch);curl_close($ch);throw new RuntimeException('google_play_reviews_fetch_failed: '.$e);}if(strlen((string)$body)>4000000){curl_close($ch);throw new RuntimeException('google_play_response_too_large');}$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);curl_close($ch);
        $data=json_decode((string)$body,true);if($status<200||$status>=300)throw new RuntimeException('google_play_reviews_http_'.$status);if(!is_array($data))throw new RuntimeException('google_play_invalid_json');return ['data'=>$data,'status'=>$status];
    }

    private static function b64(string $raw): string {return rtrim(strtr(base64_encode($raw),'+/','-_'),'=');}
    private static function normalize(string $text): string {$s=html_entity_decode(strip_tags($text),ENT_QUOTES|ENT_HTML5,'UTF-8');return trim(preg_replace('/\s+/u',' ',$s)??$s);}
}
