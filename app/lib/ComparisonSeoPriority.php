<?php

/**
 * Curated comparison SEO priorities.
 *
 * This layer controls research/indexing priority only. It must never change Fit Score,
 * recommendation ranking, Product Evaluation, sponsorship treatment, or canonical facts.
 */
final class ComparisonSeoPriority
{
    private const FRESH_DAYS=365;

    /**
     * Explicit buyer-intent backlog. Missing products are ignored rather than creating thin pages.
     * base_priority is editorial/search-intent priority, not a product ranking.
     */
    private const PAIRS=[
        ['cardiq','blinq',100,'Corporate identity & digital business cards','Enterprise card administration, lifecycle controls and external identity trust','protected'],
        ['cardiq','hihello',94,'Corporate identity & digital business cards','Enterprise digital cards, identity administration and lifecycle controls','priority'],
        ['cardiq','popl',90,'Corporate identity & digital business cards','Team digital cards, lead capture and enterprise administration','priority'],
        ['cardiq','mobilo',88,'Corporate identity & digital business cards','Enterprise digital cards, lead capture and identity governance','priority'],
        ['salesforce','dynamics-365-sales',96,'CRM','Enterprise CRM selection for sales organizations','priority'],
        ['power-bi','tableau',95,'Analytics & BI','Enterprise analytics, dashboards and self-service BI','priority'],
        ['power-bi','qlik',86,'Analytics & BI','Enterprise analytics and governed self-service BI','candidate'],
        ['power-bi','looker',84,'Analytics & BI','Cloud analytics and semantic-model driven BI','candidate'],
        ['crowdstrike','microsoft-defender-for-endpoint',96,'Endpoint Security / EDR','Enterprise endpoint protection and EDR','priority'],
        ['crowdstrike','sentinelone',94,'Endpoint Security / EDR','Enterprise endpoint protection and EDR','priority'],
        ['veeam','commvault',94,'Backup / DR','Enterprise backup, recovery and cyber resilience','priority'],
        ['veeam','cohesity',90,'Backup / DR','Enterprise backup, recovery and data resilience','priority'],
        ['veeam','acronis',82,'Backup / DR','Backup and cyber-protection selection','candidate'],
        ['asana','monday-com',91,'Project Management','Work management and cross-functional project delivery','priority'],
        ['asana','jira',88,'Project Management','Work management versus issue-centric project delivery','candidate'],
        ['asana','smartsheet',84,'Project Management','Work management, planning and portfolio visibility','candidate'],
        ['microsoft-foundry','vertex-ai',88,'AI Platforms','Enterprise AI platform and model application development','candidate'],
        ['microsoft-foundry','amazon-bedrock',88,'AI Platforms','Enterprise generative-AI platform selection','candidate'],
        ['microsoft-foundry','ibm-watsonx-ai',80,'AI Platforms','Enterprise AI governance and application platform selection','candidate'],
        ['autocad','solidworks',85,'CAD / Engineering','Engineering design workflow and CAD platform selection','candidate'],
        ['autocad','creo',78,'CAD / Engineering','Engineering design and product-development CAD selection','candidate'],
        ['autocad','nx',78,'CAD / Engineering','Engineering design and product-development CAD selection','candidate'],
    ];

    public static function canonicalPair(string $a,string $b):array
    {
        $pair=[strtolower(trim($a)),strtolower(trim($b))];sort($pair,SORT_STRING);return $pair;
    }

    public static function path(string $a,string $b):string
    {
        return '/compare/'.implode('-vs-',self::canonicalPair($a,$b));
    }

    public static function isProtected(string $a,string $b):bool
    {
        $key=implode('|',self::canonicalPair($a,$b));
        return $key==='blinq|cardiq';
    }

    public static function backlog(PDO $pdo,int $days=90):array
    {
        $days=max(7,min(365,$days));$out=[];
        foreach(self::PAIRS as [$left,$right,$base,$category,$intent,$tier]){
            $row=self::assess($pdo,$left,$right,$days);
            if(!$row)continue;
            $row['editorial_category']=$category;$row['buyer_intent']=$intent;$row['tier']=$tier;$row['base_priority']=$base;
            $gsc=self::gsc($pdo,$row['path'],$row['products'][0]['name'],$row['products'][1]['name'],$days);
            $row['gsc']=$gsc;
            $searchBoost=min(20.0,log10(max(1.0,(float)$gsc['impressions'])+1)*7.0);
            $depthBoost=$row['indexable']?10.0:min(8.0,$row['readiness_score']/12.5);
            $row['priority_score']=round(min(130,$base+$searchBoost+$depthBoost),1);
            $out[]=$row;
        }
        usort($out,static fn($a,$b)=>$b['priority_score']<=>$a['priority_score']);
        return $out;
    }

    public static function indexablePairs(PDO $pdo,int $days=90):array
    {
        return array_values(array_filter(self::backlog($pdo,$days),static fn($r)=>!empty($r['indexable'])));
    }

    public static function linksForProduct(PDO $pdo,string $slug,int $limit=4):array
    {
        $rows=array_values(array_filter(self::indexablePairs($pdo),static function($r)use($slug){foreach($r['products'] as $p)if($p['slug']===$slug)return true;return false;}));
        return array_slice($rows,0,max(1,min(8,$limit)));
    }

    public static function linksForCategory(PDO $pdo,string $categorySlug,int $limit=6):array
    {
        $rows=array_values(array_filter(self::indexablePairs($pdo),static fn($r)=>($r['category_slug']??'')===$categorySlug));
        return array_slice($rows,0,max(1,min(10,$limit)));
    }

    public static function find(PDO $pdo,string $a,string $b):?array
    {
        $wanted=self::path($a,$b);
        foreach(self::backlog($pdo) as $row)if($row['path']===$wanted)return $row;
        return null;
    }

    private static function assess(PDO $pdo,string $left,string $right,int $days):?array
    {
        $pair=self::canonicalPair($left,$right);
        $st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.category_id,p.last_reviewed_at,c.name category,c.slug category_slug FROM products p LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug IN (?,?) AND p.status='active'");
        $st->execute($pair);$products=$st->fetchAll(PDO::FETCH_ASSOC);if(count($products)!==2)return null;
        usort($products,static fn($a,$b)=>array_search($a['slug'],$pair,true)<=>array_search($b['slug'],$pair,true));
        $gaps=[];$score=0;
        foreach($products as &$p){
            $id=(int)$p['id'];
            $p['known_capability_count']=self::scalar($pdo,"SELECT COUNT(*) FROM product_capabilities WHERE product_id=? AND edition_id IS NULL AND support_status NOT IN ('unknown','not_yet_verified')",[$id]);
            $p['verified_evidence_count']=self::scalar($pdo,"SELECT COUNT(*) FROM evidence_sources WHERE product_id=? AND verification_status='verified'",[$id]);
            $p['fresh_verified_evidence_count']=self::scalar($pdo,"SELECT COUNT(*) FROM evidence_sources WHERE product_id=? AND verification_status='verified' AND COALESCE(checked_at,created_at)>=DATE_SUB(NOW(),INTERVAL ".self::FRESH_DAYS." DAY)",[$id]);
            if($p['known_capability_count']<3)$gaps[]=$p['name'].': fewer than 3 known capability facts';else $score+=25;
            if($p['verified_evidence_count']<1)$gaps[]=$p['name'].': no verified evidence source';else $score+=15;
            if($p['fresh_verified_evidence_count']<1)$gaps[]=$p['name'].': no verified source checked within '.self::FRESH_DAYS.' days';else $score+=10;
        }unset($p);
        $sameCategory=((int)$products[0]['category_id']>0&&(int)$products[0]['category_id']===(int)$products[1]['category_id']);
        if(!$sameCategory)$gaps[]='Products are not currently mapped to the same category';else $score+=10;
        $overlap=self::scalar($pdo,"SELECT COUNT(DISTINCT a.capability_id) FROM product_capabilities a JOIN product_capabilities b ON b.capability_id=a.capability_id AND b.product_id=? AND b.edition_id IS NULL AND b.support_status NOT IN ('unknown','not_yet_verified') WHERE a.product_id=? AND a.edition_id IS NULL AND a.support_status NOT IN ('unknown','not_yet_verified')",[(int)$products[1]['id'],(int)$products[0]['id']]);
        if($overlap<3)$gaps[]='Fewer than 3 mutually known capability facts';else $score+=20;
        $indexable=$sameCategory&&$overlap>=3;
        foreach($products as $p)$indexable=$indexable&&$p['known_capability_count']>=3&&$p['verified_evidence_count']>=1&&$p['fresh_verified_evidence_count']>=1;
        return ['path'=>self::path($left,$right),'products'=>$products,'category_slug'=>$sameCategory?$products[0]['category_slug']:null,'category'=>$sameCategory?$products[0]['category']:null,'overlap_known_capabilities'=>$overlap,'readiness_score'=>$score,'indexable'=>$indexable,'readiness_gaps'=>$gaps,'protected'=>self::isProtected($left,$right)];
    }

    private static function gsc(PDO $pdo,string $path,string $nameA,string $nameB,int $days):array
    {
        try{
            $st=$pdo->prepare("SELECT COALESCE(SUM(impressions),0) impressions,COALESCE(SUM(clicks),0) clicks,CASE WHEN SUM(impressions)>0 THEN SUM(position_sum)/SUM(impressions) ELSE NULL END avg_position FROM search_console_performance WHERE metric_date>=DATE_SUB(CURDATE(),INTERVAL {$days} DAY) AND (page_url LIKE ? OR (LOWER(query_text) LIKE ? AND LOWER(query_text) LIKE ?))");
            $st->execute(['%'.$path.'%','%'.strtolower($nameA).'%','%'.strtolower($nameB).'%']);$r=$st->fetch(PDO::FETCH_ASSOC)?:[];
            return ['impressions'=>(float)($r['impressions']??0),'clicks'=>(float)($r['clicks']??0),'avg_position'=>isset($r['avg_position'])?(float)$r['avg_position']:null,'window_days'=>$days];
        }catch(Throwable $e){return ['impressions'=>0,'clicks'=>0,'avg_position'=>null,'window_days'=>$days];}
    }

    private static function scalar(PDO $pdo,string $sql,array $args):int
    {
        try{$st=$pdo->prepare($sql);$st->execute($args);return (int)$st->fetchColumn();}catch(Throwable $e){return 0;}
    }
}
