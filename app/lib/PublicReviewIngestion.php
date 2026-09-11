<?php

require_once __DIR__.'/PublicReviewIntelligence.php';

final class PublicReviewIngestion
{
    public const ANALYSIS_VERSION='pri-analysis-v2';

    public static function validateSource(array $source):void
    {
        if(($source['status']??'active')!=='active')throw new RuntimeException('Source is not active.');
        if(($source['access_policy']??'pending_review')!=='permitted')throw new RuntimeException('Source is not permitted for Public Review Intelligence analysis.');
        $host=strtolower((string)parse_url((string)($source['source_url']??''),PHP_URL_HOST));
        if($host!==''&&(str_contains($host,'g2.com')||str_contains($host,'capterra.com')))throw new RuntimeException('G2/Capterra ingestion is disabled unless explicit licensed access is configured.');
    }

    public static function normalizeDerivedSignal(array $raw):array
    {
        if(!isset($raw['sentiment_score'])||!is_numeric($raw['sentiment_score']))throw new InvalidArgumentException('Missing or invalid sentiment_score.');
        $sentiment=max(-1.0,min(1.0,(float)$raw['sentiment_score']));
        $label=$raw['sentiment_label']??($sentiment>0.15?'positive':($sentiment<-0.15?'negative':'mixed'));
        if(!in_array($label,['positive','negative','neutral','mixed'],true))$label='mixed';
        $rating=null;$scale=null;
        if(isset($raw['public_rating'])&&is_numeric($raw['public_rating'])){$rating=(float)$raw['public_rating'];$scale=isset($raw['public_rating_scale'])&&is_numeric($raw['public_rating_scale'])?(float)$raw['public_rating_scale']:5.0;if($scale<=0||$rating<0||$rating>$scale)throw new InvalidArgumentException('Invalid public rating/scale.');}
        $themes=[];foreach(['strengths','weaknesses','implementation','support','pricing_value','integrations','reliability','usability','best_fit','poor_fit'] as $k)$themes[$k]=self::normalizeStringList($raw['themes'][$k]??[]);
        $flags=[];foreach(['duplicate_suspected','spam_suspected','affiliate_suspected','vendor_promotion_suspected','bot_suspected','low_signal_suspected'] as $f)$flags[$f]=!empty($raw[$f]);
        $exclude=[];foreach($flags as $k=>$v)if($v)$exclude[]=str_replace('_suspected','',$k);
        return [
            'sentiment_score'=>$sentiment,'sentiment_label'=>$label,'public_rating'=>$rating,'public_rating_scale'=>$scale,
            'topics'=>self::normalizeStringList($raw['topics']??[]),'themes'=>$themes,
            'reviewer_context'=>is_array($raw['reviewer_context']??null)?$raw['reviewer_context']:[],
            'source_confidence'=>self::unit($raw['source_confidence']??0.5),'source_quality'=>self::unit($raw['source_quality']??0.5),
            'independence_score'=>self::unit($raw['independence_score']??0.5),'specificity_score'=>self::unit($raw['specificity_score']??0.5),
        ]+$flags+['exclusion_reason'=>$exclude?implode(',',$exclude):null];
    }

    public static function isEligibleSignal(array $signal):bool
    {
        foreach(['duplicate_suspected','spam_suspected','affiliate_suspected','vendor_promotion_suspected','bot_suspected','low_signal_suspected'] as $f)if(!empty($signal[$f]))return false;
        return (float)($signal['source_confidence']??0)>=0.35&&(float)($signal['specificity_score']??0)>=0.30;
    }

    public static function analyzePermittedSources(array $sources,callable $analyzer,?DateTimeImmutable $now=null):array
    {
        $rows=[];$excluded=0;foreach($sources as $source){try{self::validateSource($source);}catch(Throwable $e){$excluded++;continue;}$derived=self::normalizeDerivedSignal($analyzer($source));if(!self::isEligibleSignal($derived)){$excluded++;continue;}$rows[]=array_merge($source,$derived);}
        return ['analysis_version'=>self::ANALYSIS_VERSION,'source_count'=>count($sources),'eligible_source_count'=>count($rows),'excluded_source_count'=>$excluded,'signals'=>$rows,'intelligence'=>PublicReviewIntelligence::calculate($rows,$now)];
    }

    public static function contentFingerprint(string $content):string{$normalized=mb_strtolower(trim(preg_replace('/\s+/u',' ',$content)));return hash('sha256',$normalized,true);}
    public static function urlHash(string $url):string{return hash('sha256',trim($url),true);}
    private static function unit($v):float{return is_numeric($v)?max(0.0,min(1.0,(float)$v)):0.5;}
    private static function normalizeStringList($value):array{if(!is_array($value))return [];$out=[];foreach($value as $item){if(!is_string($item))continue;$item=trim($item);if($item===''||mb_strlen($item)>120)continue;$out[$item]=true;}return array_slice(array_keys($out),0,20);}
}
