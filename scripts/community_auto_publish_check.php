<?php
/** Static contract for conditional Community Intelligence publication. */
$root=dirname(__DIR__);
$policy=file_get_contents($root.'/app/lib/CommunityIntelligenceAutoPublisher.php')?:'';
$sourcePolicy=file_get_contents($root.'/app/lib/PublicReviewSourcePolicy.php')?:'';
$ingestion=file_get_contents($root.'/app/lib/PublicReviewIngestion.php')?:'';
$migration=file_get_contents($root.'/db/mysql/084_vendor_coverage_public_review_automation.sql')?:'';
$renderer=file_get_contents($root.'/software_logo_page.php')?:'';
$errors=[];
$required=[
  'min_usable_sources','min_source_diversity','min_confidence','max_single_domain_share',
  'min_recent_sources','max_score_movement','max_suspicious_ratio','sensitive_language',
  "publication_mode='auto'",'auto_publish_candidate_json','community_intelligence_auto_publish_history'
];
foreach($required as $needle)if(!str_contains($policy,$needle))$errors[]="missing auto-publication contract: {$needle}";
foreach(['Scoring::','fit_score','recommendation_rank','recommendation_score'] as $needle)if(str_contains($policy,$needle))$errors[]="auto-publication policy must not couple to scoring/ranking: {$needle}";
if(!str_contains($renderer,'does not affect Fit Score, Product Evaluation or recommendation ranking'))$errors[]='public renderer is missing Community Intelligence independence disclosure';
if(!str_contains($renderer,"publication_mode"))$errors[]='public renderer does not distinguish automatic vs manual publication';

// G2 and Capterra are product-policy exclusions, not merely sources awaiting legal review.
foreach(["'g2' => self::row('G2','blocked'","'capterra' => self::row('Capterra','blocked'",'isBlocked','BLOCKED_HOSTS'] as $needle){
  if(!str_contains($sourcePolicy,$needle))$errors[]="source policy is missing hard exclusion: {$needle}";
}
if(!str_contains($ingestion,'PublicReviewSourcePolicy::isBlocked'))$errors[]='ingestion does not enforce the centralized blocked-source policy';
foreach(['community_intelligence_auto_publish_settings(id,enabled)','VALUES(1,1)','access_policy=\'blocked\'','status=\'inactive\'','Re-analysis required after G2/Capterra source exclusion'] as $needle){
  if(!str_contains($migration,$needle))$errors[]="084 review automation migration is missing: {$needle}";
}
foreach(['g2.com','capterra.com'] as $domain)if(!str_contains($migration,$domain))$errors[]="084 does not quarantine {$domain}";

if($errors){fwrite(STDERR,"Community auto-publication contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Community auto-publication contract passed with hard G2/Capterra exclusion.\n";
