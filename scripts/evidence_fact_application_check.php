<?php
$root=dirname(__DIR__);
$checks=[
 'db/mysql/026_evidence_fact_application.sql'=>['CREATE TABLE IF NOT EXISTS evidence_fact_applications','UNIQUE KEY uq_evidence_fact_application_proposal','before_value JSON','after_value JSON','applied_by_user_id'],
 'app/lib/EvidenceFactApplicator.php'=>['approved_for_application','proposal_already_applied','proposal_domain_mismatch','target_not_found','supported','partially_supported','not_supported','not_yet_verified','product_capability_evidence','evidence_fact_applications','last_reviewed_at','status=\'applied\'','pricing_commercial','product_pricing','ambiguous_pricing_scope','invalid_pricing_scope','source_url','last_verified_at'],
 'api/evidence_refresh_review.php'=>['EvidenceFactApplicator','/apply','evidence-fact-application','Security::requireCsrf','Security::sameOrigin','EVIDENCE_FACT_APPLIED','EVIDENCE_FACT_APPLICATION_FAILED'],
 'evidence_refresh_review.js'=>['Human mapping required before canonical application','data-map-domain','data-map-slug','data-map-field','data-map-value','data-apply-proposal','Pricing / commercial','product-level only','/apply'],
 'evidence_refresh_review.php'=>['explicitly map approved facts before any canonical update','application-map']
];
$failed=[];
foreach($checks as $file=>$needles){$text=@file_get_contents($root.'/'.$file)?:'';foreach($needles as $needle)if(strpos($text,$needle)===false)$failed[]="$file missing $needle";}
$svc=@file_get_contents($root.'/app/lib/EvidenceFactApplicator.php')?:'';
foreach(['compliance','regional_availability'] as $forbidden)if(strpos($svc,"'".$forbidden."'")!==false)$failed[]="Applicator must not enable unsupported domain: $forbidden";
if(strpos($svc,"private const DOMAINS=['capability','integration','deployment','pricing']")===false)$failed[]='Applicator domain allowlist changed unexpectedly';
if(strpos($svc,"['support_status','confidence_score','limitations']")===false)$failed[]='Capability field allowlist missing';
if(strpos($svc,"['support_status','confidence_score']")===false)$failed[]='Integration/deployment field allowlist missing';
if(strpos($svc,"['pricing_model','billing_period','currency','amount_min','amount_max','unit_label','notes']")===false)$failed[]='Pricing field allowlist missing';
if(strpos($svc,"if($slug!=='product')")===false)$failed[]='Pricing must remain product-level only';
if(strpos($svc,"if(count($rows)>1)throw new RuntimeException('ambiguous_pricing_scope')")===false)$failed[]='Pricing application must fail closed on ambiguous product-level rows';
if($failed){fwrite(STDERR,"Evidence fact application checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Evidence fact application checks passed.\n";
