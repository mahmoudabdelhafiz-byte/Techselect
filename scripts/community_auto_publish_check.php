<?php
/** Static contract for conditional Community Intelligence publication. */
$root=dirname(__DIR__);
$policy=file_get_contents($root.'/app/lib/CommunityIntelligenceAutoPublisher.php')?:'';
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
if($errors){fwrite(STDERR,"Community auto-publication contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Community auto-publication contract passed.\n";
