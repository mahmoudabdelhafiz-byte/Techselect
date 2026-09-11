<?php
require_once __DIR__.'/app/lib/Security.php';
require_once __DIR__.'/app/lib/AdminShell.php';
Security::start();$user=Security::user();
if(!$user){$next=urlencode($_SERVER['REQUEST_URI']??'/admin');header('Location: /login?next='.$next,true,302);exit;}
if(!in_array((string)($user['role']??''),['reviewer','data_editor','admin','super_admin'],true)){http_response_code(403);exit('Forbidden');}
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$brandRoutes=['/admin','/admin/','/review-moderation','/review-moderation/','/review-rewards','/review-rewards/','/taxonomy-queue','/taxonomy-queue/','/pri-source-policy','/pri-source-policy/','/buyer-analytics','/buyer-analytics/','/ai-referrals','/ai-referrals/'];
$target=null;
if(in_array($path,$brandRoutes,true))$target='brand_page.php';
else{
 $map=[
  '/software-management'=>'software_management.php','/admin-users'=>'admin_users.php','/admin-audit'=>'admin_audit.php','/ai-visibility'=>'ai_visibility_dashboard.php','/evidence-refresh'=>'evidence_refresh_review.php','/evidence-inbox'=>'evidence_inbox.php','/evaluation-control'=>'evaluation_control.php','/community-intelligence-admin'=>'community_intelligence_admin.php','/community-collectors'=>'community_source_collectors.php','/software-submission-admin'=>'software_submission_admin.php','/vendor-relationship-claims-admin'=>'vendor_relationship_claim_admin.php','/vendor-self-service-admin'=>'vendor_self_service_admin.php','/indexation-health'=>'indexation_health.php','/search-console'=>'search_console_dashboard.php','/seo-quality-gates'=>'seo_quality_gates_admin.php','/long-tail-seo'=>'long_tail_seo_admin.php','/customer-outcomes-admin'=>'customer_outcomes_admin.php','/authority-admin'=>'authority_admin.php'];
 $clean=rtrim($path,'/')?:'/';$target=$map[$clean]??null;
}
if(!$target||!is_file(__DIR__.'/'.$target)){http_response_code(404);exit('Not found');}
ob_start();require __DIR__.'/'.$target;$html=ob_get_clean();
echo AdminShell::decorate($html,$user,$path);
