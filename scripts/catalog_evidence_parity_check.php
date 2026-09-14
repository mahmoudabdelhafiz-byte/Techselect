<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$class=file_get_contents($root.'/app/lib/CatalogEvidenceParity.php')?:'';
$report=file_get_contents($root.'/scripts/catalog_evidence_parity_report.php')?:'';
$errors=[];
$must=[
    "'capability_verified_pct' => 0.40",
    "'capability_evidenced_pct' => 0.25",
    "'fresh_verified_pct' => 0.15",
    "'mobile_verified_pct' => 0.10",
    "'public_source_diversity_pct' => 0.10",
    "m.slug<>'mobile-access'",
    "support_status NOT IN ('unknown','not_yet_verified')",
    "es.verification_status='verified'",
    "policy_status='permitted'",
    "'identity_blind'=>true",
    "'changes_fit_score'=>false",
    "'unknown_is_not_unsupported'=>true",
    "'category_relative'=>true",
];
foreach($must as $needle)if(strpos($class,$needle)===false)$errors[]="Parity engine missing invariant: {$needle}";
foreach(['cardiq','card iq','barmageyat','ham smart','house product','preferred vendor','score bonus','ranking bonus','boost'] as $needle){
    if(stripos($class,$needle)!==false)$errors[]="Parity engine contains identity/commercial bias token: {$needle}";
}
foreach(['Scoring::','recommendation_rank','recommendation_score','consultation_recommendations'] as $needle){
    if(stripos($class,$needle)!==false)$errors[]="Parity audit must not couple to recommendation scoring/ranking: {$needle}";
}
if(preg_match('/\bUPDATE\s+consultation_recommendations\b/i',$class)||preg_match('/\bINSERT\s+INTO\s+consultation_recommendations\b/i',$class))$errors[]='Parity audit must never write recommendation results.';
foreach(['CatalogEvidenceParity::report','--fail-on-critical','CLI only'] as $needle)if(strpos($report,$needle)===false)$errors[]="Parity report missing: {$needle}";
if($errors){fwrite(STDERR,implode("\n",$errors)."\n");exit(1);}echo "Catalog evidence parity contract passed: identity-blind, category-relative, and independent from Fit Score.\n";
