<?php

final class PublicReviewAiAnalyzer
{
    public const ANALYZER_VERSION = 'pri-openai-v2';

    public static function analyze(string $content, array $source = []): array
    {
        $apiKey=trim((string)getenv('OPENAI_API_KEY'));
        $model=trim((string)getenv('TECHSELECT_PRI_MODEL'));
        if($apiKey===''||$model==='')throw new RuntimeException('PRI AI analyzer is not configured. Set OPENAI_API_KEY and TECHSELECT_PRI_MODEL on the server.');
        $content=trim($content);if($content==='')throw new InvalidArgumentException('Review content snapshot is required.');
        if(mb_strlen($content)>30000)$content=mb_substr($content,0,30000);

        $list=['type'=>'array','items'=>['type'=>'string'],'maxItems'=>8];
        $schema=['type'=>'object','additionalProperties'=>false,'properties'=>[
            'sentiment_score'=>['type'=>'number','minimum'=>-1,'maximum'=>1],
            'sentiment_label'=>['type'=>'string','enum'=>['positive','negative','neutral','mixed']],
            'public_rating'=>['type'=>['number','null']],
            'public_rating_scale'=>['type'=>['number','null']],
            'topics'=>$list,
            'themes'=>['type'=>'object','additionalProperties'=>false,'properties'=>[
                'strengths'=>$list,'weaknesses'=>$list,'implementation'=>$list,'support'=>$list,'pricing_value'=>$list,
                'integrations'=>$list,'reliability'=>$list,'usability'=>$list,'best_fit'=>$list,'poor_fit'=>$list
            ],'required'=>['strengths','weaknesses','implementation','support','pricing_value','integrations','reliability','usability','best_fit','poor_fit']],
            'reviewer_context'=>['type'=>'object','additionalProperties'=>['type'=>['string','number','boolean','null']]],
            'source_confidence'=>['type'=>'number','minimum'=>0,'maximum'=>1],
            'source_quality'=>['type'=>'number','minimum'=>0,'maximum'=>1],
            'independence_score'=>['type'=>'number','minimum'=>0,'maximum'=>1],
            'specificity_score'=>['type'=>'number','minimum'=>0,'maximum'=>1],
            'duplicate_suspected'=>['type'=>'boolean'],'spam_suspected'=>['type'=>'boolean'],'affiliate_suspected'=>['type'=>'boolean'],
            'vendor_promotion_suspected'=>['type'=>'boolean'],'bot_suspected'=>['type'=>'boolean'],'low_signal_suspected'=>['type'=>'boolean']
        ],'required'=>['sentiment_score','sentiment_label','public_rating','public_rating_scale','topics','themes','reviewer_context','source_confidence','source_quality','independence_score','specificity_score','duplicate_suspected','spam_suspected','affiliate_suspected','vendor_promotion_suspected','bot_suspected','low_signal_suspected']];

        $input="Analyze this permitted public software discussion for TechSelectAI Community Intelligence. Return derived signals only; do not quote/reproduce source text. Extract concise themes for strengths, weaknesses, implementation, support, pricing/value, integrations, reliability, usability, best-fit and poor-fit contexts. Flag likely duplicate/spam/affiliate/vendor-promotional/bot/low-signal content conservatively. Source quality reflects usefulness; independence reflects distance from vendor/commercial influence; specificity reflects concrete product experience.\n\nSource type: ".($source['source_type']??'unknown')."\nSource name: ".($source['source_name']??'')."\n\nContent:\n".$content;
        $payload=['model'=>$model,'input'=>$input,'text'=>['format'=>['type'=>'json_schema','name'=>'public_review_signal_v2','strict'=>true,'schema'=>$schema]]];
        $ch=curl_init('https://api.openai.com/v1/responses');curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>60,CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$apiKey,'Content-Type: application/json'],CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)]);
        $raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);$err=curl_error($ch);curl_close($ch);
        if($raw===false||$status<200||$status>=300)throw new RuntimeException('PRI AI analyzer request failed'.($err?': '.$err:' (HTTP '.$status.')'));
        $json=json_decode($raw,true);if(!is_array($json))throw new RuntimeException('PRI AI analyzer returned invalid JSON.');
        $text=null;foreach(($json['output']??[]) as $item){foreach(($item['content']??[]) as $part){if(($part['type']??'')==='output_text'&&isset($part['text'])){$text=$part['text'];break 2;}}}
        if(!is_string($text)||trim($text)==='')throw new RuntimeException('PRI AI analyzer returned no structured output.');
        $result=json_decode($text,true);if(!is_array($result))throw new RuntimeException('PRI AI analyzer structured output is invalid.');return $result;
    }
}
