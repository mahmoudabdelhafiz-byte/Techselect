<?php

final class HackerNewsReviewCollector
{
    private const HOST='hn.algolia.com';

    public static function collect(array $connector): array
    {
        $cfg=is_array($connector['config']??null)?$connector['config']:[];
        $query=trim((string)($cfg['query']??$connector['product']??''));if($query==='')throw new RuntimeException('hackernews_query_required');
        $max=max(1,min(50,(int)($cfg['max_items']??25)));
        $url='https://'.self::HOST.'/api/v1/search_by_date?'.http_build_query(['query'=>$query,'tags'=>'(story,comment)','hitsPerPage'=>$max]);
        $data=self::requestJson($url);$items=[];
        foreach((array)($data['hits']??[]) as $hit){
            $id=trim((string)($hit['objectID']??''));if($id==='')continue;
            $title=self::text((string)($hit['title']??$hit['story_title']??''));$comment=self::text((string)($hit['comment_text']??''));$storyText=self::text((string)($hit['story_text']??''));$body=$comment!==''?$comment:$storyText;
            if($title===''&&$body==='')continue;
            $content=trim($title.($body!==''?"\n\n{$body}":''));
            $created=trim((string)($hit['created_at']??''));$published=null;if($created!==''){try{$published=(new DateTimeImmutable($created))->format('Y-m-d H:i:s');}catch(Throwable $e){}}
            $items[]=['external_id'=>$id,'url'=>'https://news.ycombinator.com/item?id='.rawurlencode($id),'title'=>$title?:'Hacker News discussion','author'=>self::text((string)($hit['author']??'')),'published_at'=>$published,'content'=>$content];
            if(count($items)>=$max)break;
        }
        return ['items'=>$items,'meta'=>['provider'=>'hacker_news_algolia','query'=>$query,'hits'=>(int)($data['nbHits']??count($items)),'page'=>(int)($data['page']??0)]];
    }

    private static function requestJson(string $url): array
    {
        $host=strtolower((string)parse_url($url,PHP_URL_HOST));if($host!==self::HOST)throw new RuntimeException('hackernews_host_rejected');if(!function_exists('curl_init'))throw new RuntimeException('curl_required');
        $ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_CONNECTTIMEOUT=>8,CURLOPT_TIMEOUT=>20,CURLOPT_USERAGENT=>'TechSelectAI-CommunityCollector/1.0',CURLOPT_HTTPHEADER=>['Accept: application/json'],CURLOPT_PROTOCOLS=>CURLPROTO_HTTPS]);$body=curl_exec($ch);
        if($body===false){$e=curl_error($ch);curl_close($ch);throw new RuntimeException('hackernews_fetch_failed: '.$e);}if(strlen((string)$body)>3000000){curl_close($ch);throw new RuntimeException('hackernews_response_too_large');}$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);curl_close($ch);if($status<200||$status>=300)throw new RuntimeException('hackernews_http_'.$status);$data=json_decode((string)$body,true);if(!is_array($data))throw new RuntimeException('hackernews_invalid_json');return $data;
    }

    private static function text(string $value): string {$value=html_entity_decode(strip_tags($value),ENT_QUOTES|ENT_HTML5,'UTF-8');return trim(preg_replace('/\s+/u',' ',$value)??$value);}
}
