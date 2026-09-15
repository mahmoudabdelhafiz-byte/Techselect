<?php

final class BestCategorySeo {
    private const FRESH_DAYS=365;
    private const MIN_PRODUCTS=4;

    public static function page(PDO $pdo,string $slug):?array {
        $st=$pdo->prepare("SELECT id,name,slug,description FROM categories WHERE slug=? AND is_active=1 LIMIT 1");
        $st->execute([$slug]);$category=$st->fetch(PDO::FETCH_ASSOC);if(!$category)return null;
        $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor,
            (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.edition_id IS NULL AND pc.support_status NOT IN ('unknown','not_yet_verified')) known_capability_count,
            (SELECT COUNT(*) FROM evidence_sources es WHERE es.product_id=p.id AND es.verification_status='verified') verified_evidence_count,
            (SELECT COUNT(*) FROM evidence_sources es WHERE es.product_id=p.id AND es.verification_status='verified' AND COALESCE(es.checked_at,es.created_at)>=DATE_SUB(NOW(),INTERVAL ".self::FRESH_DAYS." DAY)) fresh_verified_evidence_count
            FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.category_id=? AND p.status='active' ORDER BY p.name");
        $q->execute([(int)$category['id']]);$qualified=[];
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $p){
            if((int)$p['known_capability_count']<3||(int)$p['verified_evidence_count']<1||(int)$p['fresh_verified_evidence_count']<1)continue;
            $qualified[]=$p;
        }
        if(count($qualified)<self::MIN_PRODUCTS)return null;
        return ['path'=>'/best/'.$category['slug'].'-software','category'=>$category,'products'=>$qualified,'minimum_products'=>self::MIN_PRODUCTS];
    }

    public static function indexable(PDO $pdo):array {
        $out=[];$rows=$pdo->query("SELECT slug FROM categories WHERE is_active=1 ORDER BY slug");
        foreach($rows as $r){$page=self::page($pdo,(string)$r['slug']);if($page)$out[]=$page;}
        return $out;
    }
}
