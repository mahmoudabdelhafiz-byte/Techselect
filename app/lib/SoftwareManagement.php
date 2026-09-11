<?php
final class SoftwareManagement {
    public static function list(PDO $pdo,array $filters=[]): array {
        $where=['1=1'];$args=[];
        if(($q=trim((string)($filters['q']??'')))!==''){$where[]='(p.name LIKE ? OR p.slug LIKE ? OR v.name LIKE ?)';$like='%'.$q.'%';array_push($args,$like,$like,$like);}
        if(!empty($filters['status'])){$where[]='p.status=?';$args[]=$filters['status'];}
        if(!empty($filters['vendor_id'])){$where[]='p.vendor_id=?';$args[]=(int)$filters['vendor_id'];}
        if(!empty($filters['category_id'])){$where[]='p.category_id=?';$args[]=(int)$filters['category_id'];}
        $sql="SELECT p.id,p.name,p.slug,p.short_description,p.website_url,p.status,p.last_reviewed_at,p.updated_at,p.vendor_id,p.category_id,v.name vendor,c.name category,
        (SELECT COUNT(*) FROM evidence_sources e WHERE e.product_id=p.id) evidence_count,
        (SELECT COUNT(*) FROM evidence_sources e WHERE e.product_id=p.id AND e.verification_status IN('outdated','broken','disputed','placeholder','unverified')) evidence_issues,
        (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.edition_id IS NULL) capability_count,
        (SELECT COUNT(*) FROM product_pricing pp WHERE pp.product_id=p.id) pricing_count,
        (SELECT COUNT(*) FROM product_evaluations pe WHERE pe.product_id=p.id AND pe.status='published') evaluation_count,
        (SELECT MAX(pe.evaluated_at) FROM product_evaluations pe WHERE pe.product_id=p.id AND pe.status='published') evaluation_at
        FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE ".implode(' AND ',$where)." ORDER BY p.name LIMIT 1000";
        $st=$pdo->prepare($sql);$st->execute($args);$rows=$st->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as &$r)$r['readiness']=self::readiness($pdo,(int)$r['id'],$r);unset($r);
        return $rows;
    }
    public static function detail(PDO $pdo,int $id): ?array {
        $q=$pdo->prepare("SELECT p.*,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.id=? LIMIT 1");$q->execute([$id]);$p=$q->fetch(PDO::FETCH_ASSOC);if(!$p)return null;
        $p['readiness']=self::readiness($pdo,$id,$p);
        $p['capabilities']=self::rows($pdo,"SELECT pc.id,c.name,c.slug,pc.support_status,pc.implementation_type,pc.limitations,pc.confidence_score,pc.last_verified_at FROM product_capabilities pc JOIN capabilities c ON c.id=pc.capability_id WHERE pc.product_id=? AND pc.edition_id IS NULL ORDER BY c.name",[$id]);
        $p['pricing']=self::rows($pdo,"SELECT pp.*,pe.name edition_name FROM product_pricing pp LEFT JOIN product_editions pe ON pe.id=pp.edition_id WHERE pp.product_id=? ORDER BY pp.id",[$id]);
        $p['integrations']=self::tryRows($pdo,"SELECT i.name,i.slug,pi.support_status,pi.confidence_score,pi.last_verified_at FROM product_integrations pi JOIN integrations i ON i.id=pi.integration_id WHERE pi.product_id=? ORDER BY i.name",[$id]);
        $p['deployments']=self::tryRows($pdo,"SELECT d.name,d.slug,pd.support_status,pd.confidence_score,pd.last_verified_at FROM product_deployments pd JOIN deployment_models d ON d.id=pd.deployment_model_id WHERE pd.product_id=? ORDER BY d.name",[$id]);
        $p['evidence']=self::rows($pdo,"SELECT id,source_title,source_type,source_url,verification_status,confidence,checked_at FROM evidence_sources WHERE product_id=? ORDER BY checked_at DESC,id DESC",[$id]);
        $p['community']=self::tryRows($pdo,"SELECT * FROM community_intelligence WHERE product_id=? ORDER BY id DESC LIMIT 10",[$id]);
        $p['evaluations']=self::tryRows($pdo,"SELECT pe.id,pe.overall_score,pe.confidence_score,pe.status,pe.best_for,pe.limitations,pe.summary,pe.evidence_count,pe.evaluated_at,pe.published_at,em.version methodology_version FROM product_evaluations pe JOIN evaluation_methodologies em ON em.id=pe.methodology_id WHERE pe.product_id=? ORDER BY pe.id DESC",[$id]);
        $p['aliases']=self::tryRows($pdo,"SELECT id,alias,created_at FROM product_aliases WHERE product_id=? ORDER BY alias",[$id]);
        $p['history']=self::tryRows($pdo,"SELECT id,actor_user_id,action,before_json,after_json,created_at FROM audit_logs WHERE entity_type='product' AND entity_id=? ORDER BY created_at DESC LIMIT 100",[(string)$id]);
        return $p;
    }
    public static function readiness(PDO $pdo,int $id,array $product=[]): array {
        if(!$product){$q=$pdo->prepare('SELECT * FROM products WHERE id=?');$q->execute([$id]);$product=$q->fetch(PDO::FETCH_ASSOC)?:[];}
        $checks=[];
        $checks['vendor_category']=['ok'=>!empty($product['vendor_id'])&&!empty($product['category_id']),'label'=>'Vendor and category assigned'];
        $checks['official_website']=['ok'=>filter_var((string)($product['website_url']??''),FILTER_VALIDATE_URL)!==false,'label'=>'Official website present'];
        $e=(int)self::scalar($pdo,'SELECT COUNT(*) FROM evidence_sources WHERE product_id=?',[$id]);
        $bad=(int)self::scalar($pdo,"SELECT COUNT(*) FROM evidence_sources WHERE product_id=? AND verification_status IN('broken','disputed','outdated')",[$id]);
        $checks['evidence']=['ok'=>$e>=3,'label'=>'At least 3 evidence sources','value'=>$e];
        $checks['evidence_health']=['ok'=>$bad===0,'label'=>'No critical broken/outdated/disputed evidence','value'=>$bad];
        $checks['capabilities']=['ok'=>(int)self::scalar($pdo,'SELECT COUNT(*) FROM product_capabilities WHERE product_id=? AND edition_id IS NULL',[$id])>=3,'label'=>'Capability coverage'];
        $checks['pricing']=['ok'=>(int)self::scalar($pdo,'SELECT COUNT(*) FROM product_pricing WHERE product_id=?',[$id])>0,'label'=>'Pricing evidence'];
        $checks['deployment']=['ok'=>(int)self::tryScalar($pdo,'SELECT COUNT(*) FROM product_deployments WHERE product_id=?',[$id])>0,'label'=>'Deployment coverage'];
        $checks['integrations']=['ok'=>(int)self::tryScalar($pdo,'SELECT COUNT(*) FROM product_integrations WHERE product_id=?',[$id])>0,'label'=>'Integration coverage'];
        $checks['community']=['ok'=>(int)self::tryScalar($pdo,"SELECT COUNT(*) FROM community_intelligence WHERE product_id=? AND publication_status='published'",[$id])>0,'label'=>'Published community intelligence'];
        $evalAt=self::tryScalar($pdo,"SELECT MAX(evaluated_at) FROM product_evaluations WHERE product_id=? AND status='published'",[$id]);
        $checks['evaluation']=['ok'=>!empty($evalAt)&&strtotime((string)$evalAt)>=strtotime('-180 days'),'label'=>'Fresh published TechSelectAI evaluation','value'=>$evalAt];
        $checks['seo']=['ok'=>$e>=3&&!empty($product['slug'])&&!empty($product['short_description']),'label'=>'Public SEO/indexability basics'];
        $passed=count(array_filter($checks,fn($x)=>$x['ok']));$score=(int)round($passed/max(1,count($checks))*100);
        return ['score'=>$score,'passed'=>$passed,'total'=>count($checks),'ready'=>$score>=80&&!$bad,'checks'=>$checks];
    }
    public static function referenceData(PDO $pdo): array {return ['vendors'=>self::rows($pdo,"SELECT id,name FROM vendors WHERE status='active' ORDER BY name"),'categories'=>self::rows($pdo,"SELECT id,name FROM categories WHERE is_active=1 ORDER BY name")];}
    private static function rows(PDO $pdo,string $sql,array $args=[]):array{$q=$pdo->prepare($sql);$q->execute($args);return $q->fetchAll(PDO::FETCH_ASSOC);}
    private static function tryRows(PDO $pdo,string $sql,array $args=[]):array{try{return self::rows($pdo,$sql,$args);}catch(Throwable $e){return [];}}
    private static function scalar(PDO $pdo,string $sql,array $args=[]){$q=$pdo->prepare($sql);$q->execute($args);return $q->fetchColumn();}
    private static function tryScalar(PDO $pdo,string $sql,array $args=[]){try{return self::scalar($pdo,$sql,$args);}catch(Throwable $e){return 0;}}
}
