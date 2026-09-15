<?php

/**
 * Evidence-gated regional category search pages.
 *
 * These pages expose recorded country availability facts only. They do not infer local
 * availability, compliance, residency, language support, partner coverage or product fit.
 * They never change Fit Score, recommendation ranking or sponsorship treatment.
 */
final class RegionalCategorySeo
{
    private const FRESH_DAYS=365;
    private const MIN_PRODUCTS=3;
    private const MIN_CONFIDENCE=0.600;
    private const INDEXABLE_STATUSES=['available','limited_availability'];

    private const COUNTRY_SLUGS=[
        'saudi-arabia'=>'SA',
        'egypt'=>'EG',
        'united-arab-emirates'=>'AE',
    ];

    public static function page(PDO $pdo,string $countrySlug,string $categorySlug):?array
    {
        $countryCode=self::COUNTRY_SLUGS[$countrySlug]??null;if(!$countryCode)return null;
        $st=$pdo->prepare("SELECT id,code,name FROM countries WHERE code=? LIMIT 1");$st->execute([$countryCode]);$country=$st->fetch(PDO::FETCH_ASSOC);if(!$country)return null;
        $st=$pdo->prepare("SELECT id,name,slug,description FROM categories WHERE slug=? AND is_active=1 LIMIT 1");$st->execute([$categorySlug]);$category=$st->fetch(PDO::FETCH_ASSOC);if(!$category)return null;

        $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor,
            pra.availability_status,pra.confidence_score regional_confidence,pra.availability_notes,pra.source_url,pra.last_verified_at regional_last_verified_at,
            (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.edition_id IS NULL AND pc.support_status NOT IN ('unknown','not_yet_verified')) known_capability_count,
            (SELECT COUNT(*) FROM evidence_sources es WHERE es.product_id=p.id AND es.verification_status='verified') verified_evidence_count,
            (SELECT COUNT(*) FROM evidence_sources es WHERE es.product_id=p.id AND es.verification_status='verified' AND COALESCE(es.checked_at,es.created_at)>=DATE_SUB(NOW(),INTERVAL ".self::FRESH_DAYS." DAY)) fresh_verified_evidence_count
            FROM products p
            JOIN product_regional_availability pra ON pra.product_id=p.id AND pra.country_id=?
            LEFT JOIN vendors v ON v.id=p.vendor_id
            WHERE p.category_id=? AND p.status='active'
              AND pra.availability_status IN ('available','limited_availability')
              AND pra.source_url IS NOT NULL AND pra.source_url<>''
              AND pra.last_verified_at IS NOT NULL AND pra.last_verified_at>=DATE_SUB(NOW(),INTERVAL ".self::FRESH_DAYS." DAY)
              AND pra.confidence_score>=?
            ORDER BY p.name");
        $q->execute([(int)$country['id'],(int)$category['id'],self::MIN_CONFIDENCE]);$products=[];
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $p){
            if((int)$p['known_capability_count']<3||(int)$p['verified_evidence_count']<1||(int)$p['fresh_verified_evidence_count']<1)continue;
            $products[]=$p;
        }
        if(count($products)<self::MIN_PRODUCTS)return null;
        $latest=null;foreach($products as $p){$d=$p['regional_last_verified_at']??null;if($d&&($latest===null||$d>$latest))$latest=$d;}
        return [
            'path'=>'/regional/'.$countrySlug.'/'.$category['slug'],
            'country'=>$country,
            'country_slug'=>$countrySlug,
            'category'=>$category,
            'products'=>$products,
            'minimum_products'=>self::MIN_PRODUCTS,
            'latest_regional_verification'=>$latest,
        ];
    }

    public static function indexable(PDO $pdo):array
    {
        $out=[];$cats=$pdo->query("SELECT slug FROM categories WHERE is_active=1 ORDER BY slug")->fetchAll(PDO::FETCH_COLUMN);
        foreach(array_keys(self::COUNTRY_SLUGS) as $countrySlug){
            foreach($cats as $categorySlug){$page=self::page($pdo,$countrySlug,(string)$categorySlug);if($page)$out[]=$page;}
        }
        return $out;
    }

    public static function linksForCategory(PDO $pdo,string $categorySlug):array
    {
        $out=[];foreach(array_keys(self::COUNTRY_SLUGS) as $countrySlug){$page=self::page($pdo,$countrySlug,$categorySlug);if($page)$out[]=$page;}return $out;
    }
}
