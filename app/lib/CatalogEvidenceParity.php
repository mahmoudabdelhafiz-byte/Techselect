<?php

declare(strict_types=1);

final class CatalogEvidenceParity
{
    private const FRESH_DAYS = 365;
    private const WEIGHTS = [
        'capability_verified_pct' => 0.40,
        'capability_evidenced_pct' => 0.25,
        'fresh_verified_pct' => 0.15,
        'mobile_verified_pct' => 0.10,
        'public_source_diversity_pct' => 0.10,
    ];

    public static function report(PDO $pdo): array
    {
        $hasMobile = self::tableExists($pdo, 'product_mobile_access');
        $hasConnectors = self::tableExists($pdo, 'public_review_connectors');
        $products = $pdo->query("SELECT p.id,p.name,p.slug,p.category_id,c.name category_name,c.slug category_slug FROM products p JOIN categories c ON c.id=p.category_id WHERE p.status='active' AND c.is_active=1 ORDER BY c.name,p.name")->fetchAll(PDO::FETCH_ASSOC);
        $rows=[];
        foreach($products as $p){
            $pid=(int)$p['id'];$cid=(int)$p['category_id'];
            $total=self::scalar($pdo,"SELECT COUNT(*) FROM capabilities cap JOIN modules m ON m.id=cap.module_id WHERE m.category_id=? AND m.is_active=1 AND cap.is_active=1 AND m.slug<>'mobile-access'",[$cid]);
            $known=self::scalar($pdo,"SELECT COUNT(DISTINCT pc.capability_id) FROM product_capabilities pc JOIN capabilities cap ON cap.id=pc.capability_id JOIN modules m ON m.id=cap.module_id WHERE pc.product_id=? AND m.category_id=? AND m.slug<>'mobile-access' AND pc.edition_id IS NULL AND pc.support_status NOT IN ('unknown','not_yet_verified')",[$pid,$cid]);
            $evidenced=self::scalar($pdo,"SELECT COUNT(DISTINCT pc.capability_id) FROM product_capabilities pc JOIN capabilities cap ON cap.id=pc.capability_id JOIN modules m ON m.id=cap.module_id JOIN product_capability_evidence pce ON pce.product_capability_id=pc.id JOIN evidence_sources es ON es.id=pce.evidence_source_id WHERE pc.product_id=? AND m.category_id=? AND m.slug<>'mobile-access' AND pc.edition_id IS NULL AND pc.support_status NOT IN ('unknown','not_yet_verified') AND es.verification_status='verified'",[$pid,$cid]);
            $fresh=self::scalar($pdo,"SELECT COUNT(DISTINCT pc.capability_id) FROM product_capabilities pc JOIN capabilities cap ON cap.id=pc.capability_id JOIN modules m ON m.id=cap.module_id WHERE pc.product_id=? AND m.category_id=? AND m.slug<>'mobile-access' AND pc.edition_id IS NULL AND pc.support_status NOT IN ('unknown','not_yet_verified') AND pc.last_verified_at>=DATE_SUB(NOW(),INTERVAL ".self::FRESH_DAYS." DAY)",[$pid,$cid]);
            $mobileKnown=0;$mobileTotal=3;
            if($hasMobile)$mobileKnown=self::scalar($pdo,"SELECT COUNT(*) FROM product_mobile_access WHERE product_id=? AND support_status NOT IN ('unknown','not_yet_verified') AND evidence_url IS NOT NULL AND evidence_url<>''",[$pid]);
            $sourceTypes=0;
            if($hasConnectors)$sourceTypes=self::scalar($pdo,"SELECT COUNT(DISTINCT source_type) FROM public_review_connectors WHERE product_id=? AND status='active' AND policy_status='permitted'",[$pid]);
            $metrics=[
                'capability_verified_pct'=>self::pct($known,$total),
                'capability_evidenced_pct'=>self::pct($evidenced,$total),
                'fresh_verified_pct'=>self::pct($fresh,$total),
                'mobile_verified_pct'=>self::pct($mobileKnown,$mobileTotal),
                'public_source_diversity_pct'=>round(min(1,$sourceTypes/3)*100,1),
            ];
            $score=0.0;foreach(self::WEIGHTS as $key=>$weight)$score+=$metrics[$key]*$weight;
            $rows[]=[
                'product_id'=>$pid,'product'=>$p['name'],'product_slug'=>$p['slug'],'category'=>$p['category_name'],'category_slug'=>$p['category_slug'],
                'score'=>round($score,1),'metrics'=>$metrics,
                'counts'=>['category_capabilities'=>$total,'verified_capabilities'=>$known,'evidenced_capabilities'=>$evidenced,'fresh_verified_capabilities'=>$fresh,'verified_mobile_platforms'=>$mobileKnown,'permitted_public_source_types'=>$sourceTypes],
            ];
        }
        $byCategory=[];foreach($rows as $i=>$r)$byCategory[$r['category_slug']][]=$i;
        $categorySummary=[];$critical=0;$watch=0;
        foreach($byCategory as $slug=>$indexes){
            $scores=array_map(fn($i)=>(float)$rows[$i]['score'],$indexes);sort($scores);$median=self::median($scores);$max=$scores?max($scores):0;$min=$scores?min($scores):0;$peerCount=count($scores);
            foreach($indexes as $i){
                $score=(float)$rows[$i]['score'];$status='ok';$reasons=[];
                if($peerCount>=3){
                    if($median>=50 && $score<$median*0.60){$status='critical';$reasons[]='composite coverage is below 60% of the category median';}
                    elseif($score<$median*0.80){$status='watch';$reasons[]='composite coverage is below 80% of the category median';}
                    if(($max-$score)>=40 && $score<45){$status='critical';$reasons[]='coverage trails the strongest peer by at least 40 points';}
                }
                if($rows[$i]['metrics']['capability_verified_pct']<35 && $median>=45){$status=$status==='critical'?'critical':'watch';$reasons[]='low verified capability coverage';}
                $rows[$i]['parity_status']=$status;$rows[$i]['parity_reasons']=array_values(array_unique($reasons));$rows[$i]['category_median_score']=round($median,1);$rows[$i]['category_max_score']=round($max,1);
                if($status==='critical')$critical++;elseif($status==='watch')$watch++;
            }
            $categorySummary[$slug]=['products'=>$peerCount,'median_score'=>round($median,1),'min_score'=>round($min,1),'max_score'=>round($max,1),'spread'=>round($max-$min,1)];
        }
        usort($rows,fn($a,$b)=>[$a['category'],$a['score'],$a['product']]<=>[$b['category'],$b['score'],$b['product']]);
        return [
            'methodology'=>'catalog-evidence-parity-v1','fresh_days'=>self::FRESH_DAYS,'weights'=>self::WEIGHTS,
            'principles'=>['identity_blind'=>true,'changes_fit_score'=>false,'unknown_is_not_unsupported'=>true,'category_relative'=>true],
            'summary'=>['products'=>count($rows),'categories'=>count($categorySummary),'critical'=>$critical,'watch'=>$watch,'ok'=>count($rows)-$critical-$watch],
            'categories'=>$categorySummary,'products'=>$rows,'generated_at'=>gmdate('c')
        ];
    }

    private static function tableExists(PDO $pdo,string $table): bool
    {
        $st=$pdo->prepare("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name=?");$st->execute([$table]);return (int)$st->fetchColumn()>0;
    }
    private static function scalar(PDO $pdo,string $sql,array $params=[]): int {$st=$pdo->prepare($sql);$st->execute($params);return (int)$st->fetchColumn();}
    private static function pct(int $n,int $d): float {return $d>0?round(min(1,$n/$d)*100,1):0.0;}
    private static function median(array $values): float {if(!$values)return 0.0;$n=count($values);$m=intdiv($n,2);return $n%2?$values[$m]:(($values[$m-1]+$values[$m])/2);}
}
