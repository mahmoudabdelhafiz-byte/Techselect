<?php
final class TransparencySignals {
    public const STALE_DAYS = 180;

    public static function freshness(?string $date, ?DateTimeImmutable $now=null): array {
        if(!$date)return ['label'=>'Unknown','stale'=>true,'age_days'=>null];
        $now=$now?:new DateTimeImmutable('now');
        try{$at=new DateTimeImmutable($date);}catch(Throwable $e){return ['label'=>'Unknown','stale'=>true,'age_days'=>null];}
        $days=(int)$at->diff($now)->format('%r%a');
        $days=max(0,$days);
        return ['label'=>$days>self::STALE_DAYS?'Review due':'Current','stale'=>$days>self::STALE_DAYS,'age_days'=>$days];
    }

    public static function evidenceClass(string $sourceType): string {
        $t=strtolower(trim($sourceType));
        if(in_array($t,['official_vendor','vendor_documentation','vendor','official'],true))return 'Vendor-provided fact';
        if(in_array($t,['public_forum','reddit','app_store','vendor_community','independent_blog','other_public'],true))return 'Community-derived insight';
        if(in_array($t,['estimate','assumption'],true))return 'Estimate / assumption';
        return 'Independent / reviewed evidence';
    }

    public static function sourceMixLabel(array $mix): string {
        if(!$mix)return 'Source mix not recorded';
        $parts=[];
        foreach($mix as $type=>$count){if((int)$count>0)$parts[]=str_replace('_',' ',(string)$type).' '.(int)$count;}
        return $parts?implode(' · ',$parts):'Source mix not recorded';
    }
}
