<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();

function sdg_h($v){return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}

$guides=[
 'hrms-arabic-mena'=>[
  'title'=>'HRMS & HCM for Arabic-Speaking and MENA Organizations',
  'description'=>'Evidence-aware HRMS and HCM selection guide for Arabic-speaking and MENA organizations using canonical TechSelectAI product facts.',
  'eyebrow'=>'MENA · HR & HCM decision guide',
  'category'=>'hr-hcm',
  'intro'=>'Organizations in the Middle East often need more than generic HR functionality. Core HR, onboarding, leave, payroll, integrations, SSO, implementation model, Arabic usability and country-specific requirements can all become mandatory. This guide shows the current TechSelectAI HR/HCM catalog evidence without inventing language, payroll or regional support that has not been verified.',
  'factors'=>[
   'Core employee records, onboarding and offboarding',
   'Recruiting, performance and learning requirements',
   'Leave, time and attendance workflows',
   'Payroll requirements by country and legal entity',
   'Arabic user experience and multilingual administration',
   'API, SSO and enterprise integration requirements',
   'Local implementation, support, hosting and data-residency requirements'
  ],
  'notice'=>'TechSelectAI does not currently maintain complete Arabic-language, country-payroll, local support or regulatory coverage for every HR/HCM product. A missing regional or language fact means not yet verified, not unsupported. Those requirements should be confirmed during the buyer consultation and with the vendor or implementation partner.'
 ],
 'itsm-multi-site-enterprise'=>[
  'title'=>'ITSM Software for Multi-Site Enterprise Operations',
  'description'=>'Evidence-aware ITSM selection guide for enterprises operating multiple offices, facilities or operational sites.',
  'eyebrow'=>'Enterprise · Multi-site ITSM decision guide',
  'category'=>'itsm',
  'intro'=>'Multi-site IT operations need more than a ticketing tool. Service consistency, SLA governance, change control, knowledge, asset visibility, automation, reporting, access controls and integration architecture can determine whether an ITSM platform scales across locations. This guide uses current TechSelectAI ITSM facts and does not create a generic winner from incomplete evidence.',
  'factors'=>[
   'Incident and service-request management across locations',
   'Service catalog and SLA governance',
   'Problem and change-management depth',
   'Knowledge management for distributed support teams',
   'Asset management and CMDB requirements',
   'Workflow automation, reporting and management visibility',
   'API, SSO, deployment, support model and implementation capacity'
  ],
  'notice'=>'A multi-site operating model is buyer-specific. TechSelectAI capability evidence does not by itself prove support for a particular site count, country, language, support-hours requirement or operating model. Those constraints must be validated as consultation requirements rather than inferred from product size or brand.'
 ]
];

$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';
$slug='';if(preg_match('#^/guides/([a-z0-9-]+)/?$#',$path,$m))$slug=$m[1];
if(!isset($guides[$slug])){http_response_code(404);echo '<!doctype html><html><body><h1>Guide not found</h1><p><a href="/">Return to TechSelectAI</a></p></body></html>';exit;}
$g=$guides[$slug];

$st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor_name,
 (SELECT COUNT(*) FROM product_capabilities pc JOIN capabilities cp ON cp.id=pc.capability_id JOIN modules m ON m.id=cp.module_id WHERE pc.product_id=p.id AND pc.edition_id IS NULL AND m.category_id=p.category_id) total_facts,
 (SELECT COUNT(*) FROM product_capabilities pc JOIN capabilities cp ON cp.id=pc.capability_id JOIN modules m ON m.id=cp.module_id WHERE pc.product_id=p.id AND pc.edition_id IS NULL AND m.category_id=p.category_id AND pc.support_status<>'not_yet_verified') known_facts,
 (SELECT COUNT(*) FROM product_capabilities pc JOIN capabilities cp ON cp.id=pc.capability_id JOIN modules m ON m.id=cp.module_id WHERE pc.product_id=p.id AND pc.edition_id IS NULL AND m.category_id=p.category_id AND pc.support_status='supported') supported_facts,
 (SELECT ROUND(AVG(pc.confidence_score)*100) FROM product_capabilities pc JOIN capabilities cp ON cp.id=pc.capability_id JOIN modules m ON m.id=cp.module_id WHERE pc.product_id=p.id AND pc.edition_id IS NULL AND m.category_id=p.category_id AND pc.support_status<>'not_yet_verified') known_confidence
 FROM products p JOIN categories cat ON cat.id=p.category_id JOIN vendors v ON v.id=p.vendor_id
 WHERE p.status='active' AND cat.slug=? ORDER BY p.name");
$st->execute([$g['category']]);$rows=$st->fetchAll();
$lastReviewed=null;foreach($rows as $r){$d=$r['last_reviewed_at']??null;if($d&&(!$lastReviewed||strtotime($d)>strtotime($lastReviewed)))$lastReviewed=$d;}

$canonical=rtrim($config['site_url'],'/').'/guides/'.$slug;
$schema=['@context'=>'https://schema.org','@type'=>'Article','headline'=>$g['title'],'description'=>$g['description'],'mainEntityOfPage'=>$canonical,'publisher'=>['@type'=>'Organization','name'=>'TechSelectAI','url'=>rtrim($config['site_url'],'/')]];
if($lastReviewed)$schema['dateModified']=date('Y-m-d',strtotime($lastReviewed));
$breadcrumb=['@context'=>'https://schema.org','@type'=>'BreadcrumbList','itemListElement'=>[
 ['@type'=>'ListItem','position'=>1,'name'=>'TechSelectAI','item'=>rtrim($config['site_url'],'/').'/' ],
 ['@type'=>'ListItem','position'=>2,'name'=>'Decision Guides','item'=>$canonical],
 ['@type'=>'ListItem','position'=>3,'name'=>$g['title'],'item'=>$canonical]
]];
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title><?=sdg_h($g['title'])?> | TechSelectAI</title><meta name="description" content="<?=sdg_h($g['description'])?>"><link rel="canonical" href="<?=sdg_h($canonical)?>"><link rel="icon" href="/favicon.svg" type="image/svg+xml"><meta property="og:title" content="<?=sdg_h($g['title'])?>"><meta property="og:description" content="<?=sdg_h($g['description'])?>"><meta property="og:url" content="<?=sdg_h($canonical)?>"><meta property="og:type" content="article"><script type="application/ld+json"><?=json_encode($schema,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)?></script><script type="application/ld+json"><?=json_encode($breadcrumb,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)?></script><style>
:root{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#172033;background:#f6f8fb}*{box-sizing:border-box}body{margin:0}.wrap{max-width:1160px;margin:auto;padding:0 22px}.nav{display:flex;align-items:center;justify-content:space-between;padding:20px 0}.nav img{height:38px;max-width:230px}.nav a{color:#173b63;text-decoration:none}.hero{padding:56px 0 34px}.eyebrow{font-size:13px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:#237a7b}.hero h1{font-size:clamp(34px,5vw,58px);line-height:1.04;max-width:960px;margin:12px 0 18px}.lead{font-size:19px;line-height:1.65;max-width:900px;color:#475569}.meta,.small{font-size:13px;color:#64748b}.grid{display:grid;grid-template-columns:1.45fr .75fr;gap:24px;align-items:start}.card{background:#fff;border:1px solid #dfe5ec;border-radius:16px;padding:22px;margin-bottom:18px;box-shadow:0 5px 24px rgba(15,23,42,.04)}h2{font-size:26px;margin-top:0}.factors{padding-left:20px;line-height:1.75}.notice{border-left:4px solid #319795;background:#eefafa;padding:16px 18px;border-radius:10px;margin:20px 0}.table-wrap{overflow-x:auto}table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #e5e7eb;padding:12px 10px}th{background:#f8fafc}.cta{background:#173b63;color:#fff;border-radius:18px;padding:26px}.cta a{display:inline-block;margin-top:10px;background:#fff;color:#173b63;font-weight:800;padding:11px 16px;border-radius:10px;text-decoration:none}.links a{display:block;padding:7px 0}.footer{padding:35px 0 50px;color:#64748b;font-size:13px}@media(max-width:820px){.grid{grid-template-columns:1fr}.hero{padding-top:28px}.nav{align-items:flex-start;gap:14px}.nav img{height:32px}}
</style></head><body><div class="wrap"><nav class="nav"><a href="/" aria-label="TechSelectAI home"><img src="/techselectai-logo.svg" alt="TechSelectAI"></a><div><a href="/methodology">Methodology</a> · <a href="/trust">Trust</a> · <a href="/software">Software</a></div></nav><main><section class="hero" id="overview" data-citation-section><div class="eyebrow"><?=sdg_h($g['eyebrow'])?></div><h1><?=sdg_h($g['title'])?></h1><p class="lead"><?=sdg_h($g['intro'])?></p><p class="meta">Evidence-aware decision content · <?=$lastReviewed?'Catalog last reviewed '.sdg_h(date('F Y',strtotime($lastReviewed))):'Review date varies by product'?></p></section><div class="grid"><div><section class="card"><h2>What should drive the decision?</h2><ul class="factors"><?php foreach($g['factors'] as $f):?><li><?=sdg_h($f)?></li><?php endforeach;?></ul><div class="notice"><strong>Evidence boundary:</strong> <?=sdg_h($g['notice'])?></div></section><section class="card" id="catalog-options" data-citation-section><h2>Current catalog evidence</h2><p class="small">Products are shown alphabetically. Evidence coverage is a data-quality indicator, not a product rank or recommendation.</p><div class="table-wrap"><table><thead><tr><th>Product</th><th>Known evidence</th><th>Supported facts</th><th>Avg. known confidence</th></tr></thead><tbody><?php foreach($rows as $r):?><tr><td><a href="/software/<?=sdg_h($r['slug'])?>"><strong><?=sdg_h($r['name'])?></strong></a><br><span class="small"><?=sdg_h($r['vendor_name'])?></span></td><td><?= (int)$r['known_facts'] ?>/<?= (int)$r['total_facts'] ?> criteria</td><td><?= (int)$r['supported_facts'] ?></td><td><?=$r['known_confidence']!==null?(int)$r['known_confidence'].'%':'Not enough evidence'?></td></tr><?php endforeach;?></tbody></table></div></section></div><aside><section class="cta"><h2>Apply this to your company</h2><p>Turn these general decision factors into buyer-specific requirements and a deterministic TechSelectAI Fit Score where catalog evidence is available.</p><a href="/?start=consultation">Get My Recommendations</a></section><section class="card links"><h2>Related evidence</h2><a href="/categories/<?=sdg_h($g['category'])?>">Browse the category</a><a href="/methodology">How Fit Score works</a><a href="/trust">Evidence & ownership disclosure</a></section></aside></div></main><footer class="footer">TechSelectAI decision guides use the same canonical evidence base as product documentation. Unknown evidence is not treated as unsupported.</footer></div></body></html>