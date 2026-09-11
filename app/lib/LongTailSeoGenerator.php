<?php
require_once __DIR__.'/ProgrammaticSeoQualityGate.php';
final class LongTailSeoGenerator {
    public const TEMPLATES=[
        'category_for_industry'=>'Best category for industry',
        'category_for_company_size'=>'Best category for company size',
        'category_for_use_case'=>'Best category for use case',
        'category_with_requirement'=>'Best category with requirement',
        'comparison_for_context'=>'Product vs product for context',
        'alternatives_for_context'=>'Product alternatives for context',
    ];

    public static function create(PDO $pdo,array $input,int $userId): array {
        $template=trim((string)($input['template_key']??''));
        if(!isset(self::TEMPLATES[$template]))throw new InvalidArgumentException('invalid_template');
        $contextLabel=trim((string)($input['context_label']??''));
        $contextValue=self::slug(trim((string)($input['context_value']??$contextLabel)));
        if($contextLabel===''||$contextValue==='')throw new InvalidArgumentException('context_required');
        $contextType=match($template){
            'category_for_industry'=>'industry','category_for_company_size'=>'company_size','category_for_use_case'=>'use_case','category_with_requirement'=>'requirement',default=>'context'};

        $category=null;$primary=null;$secondary=null;$products=[];
        if(str_starts_with($template,'category_')){
            $category=self::category($pdo,(string)($input['category_slug']??''));
            if(!$category)throw new InvalidArgumentException('category_not_found');
            $products=self::evaluatedProductsInCategory($pdo,(int)$category['id'],5);
            if(count($products)<2)throw new RuntimeException('insufficient_evaluated_products');
        }elseif($template==='comparison_for_context'){
            $primary=self::product($pdo,(string)($input['product_a_slug']??''));$secondary=self::product($pdo,(string)($input['product_b_slug']??''));
            if(!$primary||!$secondary||$primary['id']===$secondary['id'])throw new InvalidArgumentException('comparison_products_required');
            $products=self::evaluationsForIds($pdo,[(int)$primary['id'],(int)$secondary['id']]);
            if(count($products)<2)throw new RuntimeException('published_evaluations_required');
            $category=['id'=>$primary['category_id'],'name'=>$primary['category_name'],'slug'=>$primary['category_slug']];
        }else{
            $primary=self::product($pdo,(string)($input['primary_product_slug']??''));if(!$primary)throw new InvalidArgumentException('primary_product_required');
            $category=['id'=>$primary['category_id'],'name'=>$primary['category_name'],'slug'=>$primary['category_slug']];
            $products=self::evaluatedProductsInCategory($pdo,(int)$primary['category_id'],6);
            $products=array_values(array_filter($products,fn($p)=>(int)$p['id']!==(int)$primary['id']));
            $primaryEval=self::evaluationsForIds($pdo,[(int)$primary['id']]);if(!$primaryEval)throw new RuntimeException('primary_product_evaluation_required');
            array_unshift($products,$primaryEval[0]);$products=array_slice($products,0,6);
            if(count($products)<2)throw new RuntimeException('insufficient_alternatives');
        }

        $meta=self::metadata($template,$category,$primary,$secondary,$contextLabel,$contextValue);
        $evidence=self::evidenceStats($pdo,array_map(fn($p)=>(int)$p['id'],$products));
        $payload=self::payload($template,$category,$primary,$secondary,$contextLabel,$products,$evidence);
        $body=self::bodyText($payload);$recommendation=self::recommendationText($payload);
        $fingerprint=hash('sha256',implode(',',array_map(fn($p)=>(int)$p['id'],$products)).'|'.implode(',',array_map('strval',$evidence['ids'])));
        $lastReviewed=self::freshestReview($products);
        $pdo->beginTransaction();
        try{
            $sql="INSERT INTO seo_generated_pages(page_type,slug,canonical_path,intent_key,title,h1,meta_description,recommendation_text,body_text,evidence_count,source_count,evidence_fingerprint,internal_link_count,last_reviewed_at,status,quality_decision) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?, 'draft','pending') ON DUPLICATE KEY UPDATE intent_key=VALUES(intent_key),title=VALUES(title),h1=VALUES(h1),meta_description=VALUES(meta_description),recommendation_text=VALUES(recommendation_text),body_text=VALUES(body_text),evidence_count=VALUES(evidence_count),source_count=VALUES(source_count),evidence_fingerprint=VALUES(evidence_fingerprint),internal_link_count=VALUES(internal_link_count),last_reviewed_at=VALUES(last_reviewed_at),status='draft',quality_decision='pending',canonical_target_path=NULL";
            $st=$pdo->prepare($sql);$st->execute([$meta['page_type'],$meta['slug'],$meta['path'],$meta['intent_key'],$meta['title'],$meta['h1'],$meta['description'],$recommendation,$body,$evidence['count'],$evidence['source_count'], $fingerprint,count($products)+2,$lastReviewed]);
            $q=$pdo->prepare('SELECT id FROM seo_generated_pages WHERE canonical_path=? LIMIT 1');$q->execute([$meta['path']]);$pageId=(int)$q->fetchColumn();
            $lt=$pdo->prepare("INSERT INTO seo_long_tail_pages(page_id,template_key,category_id,primary_product_id,secondary_product_id,context_type,context_label,context_value,product_ids_json,render_payload_json,generated_by_user_id) VALUES(?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE template_key=VALUES(template_key),category_id=VALUES(category_id),primary_product_id=VALUES(primary_product_id),secondary_product_id=VALUES(secondary_product_id),context_type=VALUES(context_type),context_label=VALUES(context_label),context_value=VALUES(context_value),product_ids_json=VALUES(product_ids_json),render_payload_json=VALUES(render_payload_json),generated_by_user_id=VALUES(generated_by_user_id)" );
            $lt->execute([$pageId,$template,$category['id']??null,$primary['id']??null,$secondary['id']??null,$contextType,$contextLabel,$contextValue,json_encode(array_map(fn($p)=>(int)$p['id'],$products)),json_encode($payload,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),$userId]);
            $pdo->commit();
        }catch(Throwable $e){$pdo->rollBack();throw $e;}
        $gate=ProgrammaticSeoQualityGate::run($pdo,$pageId,$userId);
        if(in_array($gate['decision'],['indexable','published_noindex'],true))$pdo->prepare("UPDATE seo_generated_pages SET status='published' WHERE id=?")->execute([$pageId]);
        return ['page_id'=>$pageId,'canonical_path'=>$meta['path'],'quality'=>$gate,'template_key'=>$template];
    }

    public static function publicPage(PDO $pdo,string $slug): ?array {
        $q=$pdo->prepare("SELECT g.*,l.template_key,l.context_type,l.context_label,l.context_value,l.render_payload_json FROM seo_generated_pages g JOIN seo_long_tail_pages l ON l.page_id=g.id WHERE g.slug=? AND g.status='published' AND g.quality_decision IN('indexable','published_noindex') LIMIT 1");$q->execute([$slug]);$r=$q->fetch(PDO::FETCH_ASSOC);if(!$r)return null;$r['payload']=json_decode($r['render_payload_json']?:'{}',true)?:[];return $r;
    }

    private static function category(PDO $pdo,string $slug):?array{$q=$pdo->prepare("SELECT id,name,slug FROM categories WHERE slug=? AND is_active=1 LIMIT 1");$q->execute([$slug]);$r=$q->fetch(PDO::FETCH_ASSOC);return $r?:null;}
    private static function product(PDO $pdo,string $slug):?array{$q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.category_id,c.name category_name,c.slug category_slug FROM products p JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active' LIMIT 1");$q->execute([$slug]);$r=$q->fetch(PDO::FETCH_ASSOC);return $r?:null;}
    private static function evaluatedProductsInCategory(PDO $pdo,int $categoryId,int $limit):array{$q=$pdo->prepare("SELECT p.id,p.name,p.slug,v.name vendor_name,pe.overall_score,pe.confidence_score,pe.best_for,pe.limitations,pe.summary,pe.evidence_count,pe.published_at,em.version methodology_version FROM products p JOIN vendors v ON v.id=p.vendor_id JOIN product_evaluations pe ON pe.product_id=p.id AND pe.status='published' JOIN evaluation_methodologies em ON em.id=pe.methodology_id AND em.status='published' WHERE p.status='active' AND p.category_id=? ORDER BY pe.confidence_score DESC,pe.evidence_count DESC,pe.overall_score DESC,p.name LIMIT ".(int)$limit);$q->execute([$categoryId]);return $q->fetchAll(PDO::FETCH_ASSOC);}
    private static function evaluationsForIds(PDO $pdo,array $ids):array{if(!$ids)return [];$ph=implode(',',array_fill(0,count($ids),'?'));$q=$pdo->prepare("SELECT p.id,p.name,p.slug,v.name vendor_name,pe.overall_score,pe.confidence_score,pe.best_for,pe.limitations,pe.summary,pe.evidence_count,pe.published_at,em.version methodology_version FROM products p JOIN vendors v ON v.id=p.vendor_id JOIN product_evaluations pe ON pe.product_id=p.id AND pe.status='published' JOIN evaluation_methodologies em ON em.id=pe.methodology_id AND em.status='published' WHERE p.status='active' AND p.id IN($ph) ORDER BY FIELD(p.id,".implode(',',array_map('intval',$ids)).")");$q->execute($ids);return $q->fetchAll(PDO::FETCH_ASSOC);}
    private static function evidenceStats(PDO $pdo,array $ids):array{if(!$ids)return ['count'=>0,'source_count'=>0,'ids'=>[]];$ph=implode(',',array_fill(0,count($ids),'?'));$q=$pdo->prepare("SELECT DISTINCT e.id,e.source_type FROM product_evaluations pe JOIN product_evaluation_dimensions d ON d.evaluation_id=pe.id JOIN product_evaluation_evidence pee ON pee.evaluation_dimension_id=d.id JOIN evidence_sources e ON e.id=pee.evidence_source_id WHERE pe.status='published' AND pe.product_id IN($ph)");$q->execute($ids);$rows=$q->fetchAll(PDO::FETCH_ASSOC);return ['count'=>count($rows),'source_count'=>count(array_unique(array_filter(array_column($rows,'source_type')))),'ids'=>array_map('intval',array_column($rows,'id'))];}
    private static function metadata(string $t,array $c,?array $a,?array $b,string $label,string $value):array{
        if($t==='comparison_for_context'){$slug=self::slug($a['slug'].'-vs-'.$b['slug'].'-for-'.$value);$title=$a['name'].' vs '.$b['name'].' for '.$label;$type='comparison';}
        elseif($t==='alternatives_for_context'){$slug=self::slug($a['slug'].'-alternatives-for-'.$value);$title=$a['name'].' Alternatives for '.$label;$type='alternatives';}
        else{$slug=self::slug($c['slug'].'-for-'.$value);$title='Best '.$c['name'].' Software for '.$label;$type='best_for';}
        $h1=$title.': Evidence-Based Selection Guide';$desc='Evidence-backed TechSelectAI guidance for '.$title.', including evaluated options, trade-offs, confidence, methodology and supporting product evidence.';
        return ['slug'=>$slug,'path'=>'/software-selection/'.$slug,'title'=>$title,'h1'=>$h1,'description'=>$desc,'page_type'=>$type,'intent_key'=>self::slug($t.' '.$c['slug'].' '.$value.' '.($a['slug']??'').' '.($b['slug']??''))];
    }
    private static function payload(string $t,array $c,?array $a,?array $b,string $label,array $products,array $evidence):array{return ['template_key'=>$t,'category'=>$c,'primary_product'=>$a,'secondary_product'=>$b,'context_label'=>$label,'products'=>$products,'evidence'=>$evidence,'methodology_note'=>'TechSelectAI product evaluations are evidence-backed product assessments. This page does not convert the context label into a buyer-specific Fit Score; mandatory requirements, budget, geography, integrations and implementation constraints must still be applied in a selection project.'];}
    private static function bodyText(array $p):string{$parts=[];$parts[]='Buyer question: which '.$p['category']['name'].' options deserve consideration for '.$p['context_label'].'? '.$p['methodology_note'];$parts[]='This market scan includes only active products with published TechSelectAI evaluations. Products without sufficient published evaluation evidence are not silently treated as worse; they are simply excluded from this generated decision page until evidence is strong enough.';foreach($p['products'] as $x){$parts[]=$x['name'].' by '.$x['vendor_name'].'. TechSelectAI evaluation '.($x['overall_score']!==null?$x['overall_score'].'/10':'score unavailable').', confidence '.round(((float)$x['confidence_score'])*100).'% and '.$x['evidence_count'].' evaluation evidence links. '.trim((string)$x['summary']).' Best-for evidence: '.trim((string)$x['best_for']).' Limitations and trade-offs: '.trim((string)$x['limitations']).' The product should be validated against the buyer’s mandatory capabilities, deployment, integration, security, regional support and commercial assumptions before a final recommendation.';}$parts[]='How to decide: use the options above as an evidence-backed shortlist input, then confirm mandatory requirements and apply TechSelectAI’s weighted decision matrix. A product-level evaluation is intentionally separate from contextual Fit Score. Local partner availability, pricing and contractual conditions can also change the final decision without changing the independent product evaluation.';$parts[]='Evidence and freshness: this page is generated only from published product evaluations and linked evidence. Its quality gate also checks evidence depth, source diversity, content depth, internal links and freshness. If the underlying evidence becomes stale or the page becomes duplicative, it can be downgraded to noindex until reviewed.';return implode("\n\n",$parts);}
    private static function recommendationText(array $p):string{return 'Do not select a universal winner from this page alone. For '.$p['context_label'].', first eliminate products that fail mandatory requirements, then compare implementation capacity, integrations, security/compliance, deployment, regional delivery and total commercial assumptions. Use the published TechSelectAI evaluations as product evidence and create a saved selection project for buyer-specific weighting. The preferred option should be the product with the strongest fit to confirmed requirements, not simply the highest general evaluation score.';}
    private static function freshestReview(array $products):?string{$dates=array_values(array_filter(array_column($products,'published_at')));if(!$dates)return null;usort($dates,fn($a,$b)=>strtotime($b)<=>strtotime($a));return date('Y-m-d H:i:s',strtotime($dates[0]));}
    private static function slug(string $s):string{$s=mb_strtolower(trim($s));$s=preg_replace('/[^a-z0-9]+/u','-',$s);return trim(preg_replace('/-+/','-',$s),'-');}
}
