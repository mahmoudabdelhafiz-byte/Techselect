<?php

final class AlternativeSeo
{
    private const FRESH_DAYS = 365;

    public static function pageForProduct(PDO $pdo, string $slug, int $limit=8): ?array
    {
        $st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.category_id,p.short_description,p.last_reviewed_at,c.name category,c.slug category_slug,v.name vendor FROM products p LEFT JOIN categories c ON c.id=p.category_id LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.slug=? AND p.status='active' AND c.is_active=1 LIMIT 1");
        $st->execute([$slug]);$base=$st->fetch(PDO::FETCH_ASSOC)?:null;if(!$base)return null;
        if(!self::eligibleProduct($pdo,(int)$base['id']))return null;

        $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.category_id=? AND p.id<>? AND p.status='active' ORDER BY p.name");
        $q->execute([(int)$base['category_id'],(int)$base['id']]);
        $alts=[];
        foreach($q->fetchAll(PDO::FETCH_ASSOC)?:[] as $candidate){
            if(!self::eligibleProduct($pdo,(int)$candidate['id']))continue;
            $overlap=self::overlap($pdo,(int)$base['id'],(int)$candidate['id']);
            if($overlap<3)continue;
            $candidate['overlap_known_capabilities']=$overlap;
            $candidate['path']=ComparisonSeoPriority::path($base['slug'],$candidate['slug']);
            $alts[]=$candidate;
        }
        usort($alts,static function($a,$b){$d=((int)$b['overlap_known_capabilities'])<=>((int)$a['overlap_known_capabilities']);return $d!==0?$d:strcmp($a['name'],$b['name']);});
        $alts=array_slice($alts,0,max(3,min(12,$limit)));
        if(count($alts)<3)return null;
        return ['product'=>$base,'alternatives'=>$alts,'path'=>'/alternatives/'.$base['slug'],'indexable'=>true];
    }

    public static function indexable(PDO $pdo): array
    {
        $out=[];
        try{$rows=$pdo->query("SELECT slug FROM products WHERE status='active' ORDER BY slug")->fetchAll(PDO::FETCH_COLUMN)?:[];}catch(Throwable $e){return [];}
        foreach($rows as $slug){$page=self::pageForProduct($pdo,(string)$slug);if($page)$out[]=$page;}
        return $out;
    }

    private static function eligibleProduct(PDO $pdo,int $id):bool
    {
        $known=self::scalar($pdo,"SELECT COUNT(*) FROM product_capabilities WHERE product_id=? AND edition_id IS NULL AND support_status NOT IN ('unknown','not_yet_verified')",[$id]);
        $evidence=self::scalar($pdo,"SELECT COUNT(*) FROM evidence_sources WHERE product_id=? AND verification_status='verified'",[$id]);
        $fresh=self::scalar($pdo,"SELECT COUNT(*) FROM evidence_sources WHERE product_id=? AND verification_status='verified' AND COALESCE(checked_at,created_at)>=DATE_SUB(NOW(),INTERVAL ".self::FRESH_DAYS." DAY)",[$id]);
        return $known>=3&&$evidence>=1&&$fresh>=1;
    }

    private static function overlap(PDO $pdo,int $a,int $b):int
    {
        return self::scalar($pdo,"SELECT COUNT(DISTINCT x.capability_id) FROM product_capabilities x JOIN product_capabilities y ON y.capability_id=x.capability_id AND y.product_id=? AND y.edition_id IS NULL AND y.support_status NOT IN ('unknown','not_yet_verified') WHERE x.product_id=? AND x.edition_id IS NULL AND x.support_status NOT IN ('unknown','not_yet_verified')",[$b,$a]);
    }

    private static function scalar(PDO $pdo,string $sql,array $args):int
    {
        try{$st=$pdo->prepare($sql);$st->execute($args);return (int)$st->fetchColumn();}catch(Throwable $e){return 0;}
    }
}
