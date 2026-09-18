<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$sql=(string)@file_get_contents($root.'/db/mysql/141_tos_market_names_zodiac_master_terminal.sql');
$api=(string)@file_get_contents($root.'/api/index.php');
$page=(string)@file_get_contents($root.'/software_page.php');
$search=(string)@file_get_contents($root.'/frontend/src/softwareCatalogSearch.js');
$legacyAliases=(string)@file_get_contents($root.'/db/mysql/043_software_submissions.sql');
$errors=[];
if($sql==='')$errors[]='Missing migration 141';
foreach(['alias_name VARCHAR(190) NOT NULL','normalized_alias VARCHAR(190) NOT NULL',"source VARCHAR(40) NOT NULL DEFAULT 'admin'"] as $column){
  if(strpos($legacyAliases,$column)===false)$errors[]="Migration 043 canonical alias schema missing: {$column}";
  if(strpos($sql,$column)===false)$errors[]="Migration 141 must reuse migration 043 alias schema: {$column}";
}
foreach(['alias VARCHAR(190) NOT NULL','alias_type VARCHAR(40)','is_active TINYINT'] as $divergent){
  if(strpos($sql,$divergent)!==false)$errors[]="Migration 141 must not redefine product_aliases with divergent column: {$divergent}";
}
foreach([
  "name='Navis N4 TOS'","'CARGOES TOS+ (Zodiac)'","'cargoes-tos-plus-zodiac'",
  "'Navis Mixed Cargo TOS'","'navis-mixed-cargo-tos'",
  'CREATE TABLE IF NOT EXISTS product_aliases',
  "'Kaleris N4 TOS','former_catalog_name'","'Zodiac','legacy_brand'",
  "'Jade Master Terminal','legacy_brand'","'Master Terminal','former_name'","'MTN','former_name'",
  "'not_yet_verified'",'Unknown != Unsupported'
] as $needle) if(strpos($sql,$needle)===false)$errors[]="Missing TOS market-name invariant: {$needle}";
$allowed=['dpworld.com','www.dpworld.com','kaleris.com','www.kaleris.com'];
preg_match_all('#https://[^\s\'\"]+#',$sql,$matches);
foreach(array_unique($matches[0]??[]) as $url){$url=rtrim($url,');,');$host=strtolower((string)parse_url($url,PHP_URL_HOST));if($host===''||!in_array($host,$allowed,true))$errors[]="Unapproved evidence host: {$host}";}
foreach([
  'these named components are not assumed in every OPS configuration',
  'does not enumerate a universal EDI/API catalogue',
  'straddle-carrier support is not inferred from tractor evidence',
  'AGV support is not inferred where it is not stated',
  'does not by itself classify the cloud option as public SaaS',
  'API support is not separately inferred',
  'full reefer, dangerous-goods and OOG control is not inferred'
] as $phrase) if(strpos($sql,$phrase)===false)$errors[]="Missing scope boundary: {$phrase}";
if(strpos($sql,"d.slug='public-saas'")!==false)$errors[]='Do not map generic CARGOES cloud wording to public SaaS';
if(strpos($sql,"ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);")===false)$errors[]='New TOS mobile defaults must be rerun-safe';
foreach(['g2.com','capterra','recommendation_rank','Scoring::','overall_score','fit_score','popularity_score','sponsored_rank'] as $bad) if(stripos($sql,$bad)!==false)$errors[]="Prohibited ranking/source coupling: {$bad}";
foreach([
  [$api,'product_aliases','software API reads product aliases'],
  [$api,'pa.alias_name','software API uses canonical alias_name column'],
  [$api,'source AS alias_type','software detail API maps canonical source metadata'],
  [$api,"'aliases'",'software detail API exposes aliases'],
  [$page,'product_aliases','software page reads product aliases'],
  [$page,'alias_name AS alias','software page uses canonical alias_name column'],
  [$page,'alternateName','software page structured data exposes alternate names'],
  [$search,'p.aliases','catalog autocomplete searches aliases'],
  [$search,'aliasBySlug','catalog card filtering searches aliases']
] as [$hay,$needle,$label]) if(strpos($hay,$needle)===false)$errors[]=$label;
if($errors){fwrite(STDERR,"TOS market-name coverage check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "TOS market-name coverage passed: Navis N4 naming, Zodiac and Mixed Cargo coverage, searchable aliases, first-party evidence boundaries and neutrality.\n";
