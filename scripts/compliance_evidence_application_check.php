<?php
$root=dirname(__DIR__);$errors=[];$req=function($ok,$m)use(&$errors){if(!$ok)$errors[]=$m;};
$m=@file_get_contents($root.'/db/mysql/028_compliance_facts.sql')?:'';
$s=@file_get_contents($root.'/app/lib/EvidenceFactApplicator.php')?:'';
$j=@file_get_contents($root.'/evidence_refresh_review.js')?:'';
$req(str_contains($m,'CREATE TABLE IF NOT EXISTS compliance_standards'),'missing compliance_standards');
$req(str_contains($m,'CREATE TABLE IF NOT EXISTS product_compliance'),'missing product_compliance');
$req(str_contains($m,"DEFAULT 'not_yet_verified'"),'compliance default must be not_yet_verified');
$req(str_contains($m,'UNIQUE KEY uq_product_compliance(product_id, compliance_standard_id)'),'product/standard mapping must be unique');
foreach(['iso-27001','soc-2','gdpr','hipaa','pci-dss','saudi-nca-ecc','sama-cybersecurity-framework'] as $slug)$req(str_contains($m,"'{$slug}'"),'missing neutral taxonomy '.$slug);
$req(str_contains($s,"'compliance'"),'applicator must enable compliance domain');
$req(str_contains($s,"['support_status','confidence_score','scope_notes']"),'compliance field allowlist missing');
$req(str_contains($s,'FROM compliance_standards WHERE slug=? AND is_active=1'),'compliance slug must resolve canonically');
$req(str_contains($s,'product_compliance'),'product compliance application missing');
$req(str_contains($s,"proposal['source_url']?:null"),'source URL must come from evidence source');
$req(str_contains($j,'Compliance'),'review UI must expose compliance');
$req(str_contains($j,'Scope / qualification notes'),'review UI must expose scoped compliance notes');
$req(!str_contains($s,"'regional_availability'"),'regional availability must remain disabled');
if($errors){fwrite(STDERR,"Compliance evidence checks failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Compliance evidence checks passed.\n";