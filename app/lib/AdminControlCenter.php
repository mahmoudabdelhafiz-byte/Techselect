<?php
final class AdminControlCenter {
    public static function overview(PDO $pdo): array {
        $out=['products'=>['active'=>0,'draft'=>0,'archived'=>0],'queues'=>[],'generated_at'=>gmdate('c')];
        try{$rows=$pdo->query("SELECT status,COUNT(*) c FROM products GROUP BY status")->fetchAll(PDO::FETCH_ASSOC);foreach($rows as $r){$k=(string)$r['status'];if(array_key_exists($k,$out['products']))$out['products'][$k]=(int)$r['c'];}}catch(Throwable $e){}
        $out['queues']=[
            self::metric($pdo,'Products needing review',"SELECT COUNT(*) FROM products WHERE status IN ('draft','active') AND (last_reviewed_at IS NULL OR last_reviewed_at < DATE_SUB(NOW(),INTERVAL 180 DAY))",'/software-management','Review stale or never-reviewed products.'),
            self::metric($pdo,'Taxonomy demand backlog',"SELECT COUNT(*) FROM taxonomy_expansion_queue WHERE status NOT IN ('dismissed','completed')",'/catalog-expansion','Prioritize expansion demand against evidence readiness.'),
            self::metric($pdo,'Evidence attention',"SELECT COUNT(*) FROM evidence_sources WHERE verification_status IN ('unverified','outdated','broken','disputed','placeholder')",'/evidence-inbox','Verify, refresh or retire weak evidence.'),
            self::metric($pdo,'PRI source policy',"SELECT COUNT(*) FROM public_review_sources WHERE access_policy='pending_review'",'/pri-source-policy','Review public-source access policy before analysis.'),
            self::metric($pdo,'Reviews awaiting moderation',"SELECT COUNT(*) FROM user_reviews WHERE status IN ('pending','under_review')",'/review-moderation','Moderate user reviews waiting for a decision.'),
            self::metric($pdo,'Products missing evaluation',"SELECT COUNT(*) FROM products p WHERE p.status='active' AND NOT EXISTS(SELECT 1 FROM product_evaluations pe WHERE pe.product_id=p.id AND pe.status='published')",'/evaluation-control','Generate and review evidence-backed evaluations.'),
            self::metric($pdo,'Stale evaluations',"SELECT COUNT(*) FROM product_evaluations WHERE status='published' AND (evaluated_at IS NULL OR evaluated_at < DATE_SUB(NOW(),INTERVAL 180 DAY))",'/evaluation-control','Re-evaluate stale published analysis.'),
            self::metric($pdo,'SEO/indexing alerts',"SELECT COUNT(*) FROM indexation_url_health WHERE priority_level='strategic' AND (sitemap_present=0 OR index_state IN ('discovered_not_indexed','crawled_not_indexed','excluded_noindex','not_found','soft_404'))",'/indexation-health','Inspect strategic pages with sitemap/indexing problems.'),
            self::metric($pdo,'SEO quality failures',"SELECT COUNT(*) FROM seo_generated_pages WHERE quality_decision IN ('published_noindex','not_generated')",'/seo-quality-gates','See generated pages blocked from indexation.'),
            self::metric($pdo,'Community intelligence review',"SELECT COUNT(*) FROM community_intelligence WHERE publication_status IN ('draft','pending_review')",'/community-intelligence-admin','Review unpublished community intelligence.'),
            self::metric($pdo,'Vendor claims waiting',"SELECT COUNT(*) FROM vendor_profile_claims WHERE status='pending_review'",'/vendor-self-service-admin','Verify company/vendor profile claims.'),
            self::metric($pdo,'Relationship claims waiting',"SELECT COUNT(*) FROM vendor_relationship_claims WHERE status='pending'",'/vendor-relationship-claims-admin','Review reseller/implementation territory claims.'),
        ];return $out;
    }
    public static function navigation(string $role): array {
        $all=[
            ['key'=>'overview','label'=>'Overview','href'=>'/admin','roles'=>['reviewer','data_editor','admin','super_admin']],
            ['key'=>'software','label'=>'Software','href'=>'/software-management','roles'=>['reviewer','data_editor','admin','super_admin']],
            ['key'=>'catalog_expansion','label'=>'Catalog Expansion','href'=>'/catalog-expansion','roles'=>['reviewer','data_editor','admin','super_admin']],
            ['key'=>'evidence','label'=>'Evidence','href'=>'/evidence-inbox','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'evaluations','label'=>'AI Evaluations','href'=>'/evaluation-control','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'community','label'=>'Community Intelligence','href'=>'/community-intelligence-admin','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'reviews','label'=>'User Reviews','href'=>'/review-moderation','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'taxonomy','label'=>'Taxonomy','href'=>'/taxonomy-queue','roles'=>['reviewer','data_editor','admin','super_admin']],
            ['key'=>'seo','label'=>'SEO & Indexing','href'=>'/search-console','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'ai_visibility','label'=>'AI Visibility','href'=>'/ai-visibility','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'buyers','label'=>'Buyer Analytics','href'=>'/buyer-analytics','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'authority','label'=>'Authority & Backlinks','href'=>'/authority-admin','roles'=>['reviewer','admin','super_admin']],
            ['key'=>'advertising','label'=>'Advertising','href'=>'/admin_advertising.php','roles'=>['admin','super_admin']],
            ['key'=>'users','label'=>'Users & Roles','href'=>'/admin-users','roles'=>['admin','super_admin']],
            ['key'=>'audit','label'=>'Audit Log','href'=>'/admin-audit','roles'=>['admin','super_admin']],
            ['key'=>'health','label'=>'System Health','href'=>'/health','roles'=>['admin','super_admin']],
        ];return array_values(array_filter($all,fn($x)=>in_array($role,$x['roles'],true)));
    }
    private static function metric(PDO $pdo,string $label,string $sql,string $href,string $hint): array {try{$value=(int)$pdo->query($sql)->fetchColumn();}catch(Throwable $e){$value=null;}return ['label'=>$label,'value'=>$value,'href'=>$href,'hint'=>$hint];}
}
