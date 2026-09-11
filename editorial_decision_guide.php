<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();

function edg_h($v){return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}

$guides=[
 'crm-egypt-b2b'=>[
  'title'=>'CRM Software for Egyptian B2B Companies: A Decision Guide',
  'description'=>'Evidence-aware CRM selection guidance for B2B organizations in Egypt using canonical TechSelectAI product facts and explicit local-evidence boundaries.',
  'eyebrow'=>'Egypt · B2B CRM decision guide',
  'category'=>'crm',
  'intro'=>'Egyptian B2B organizations choosing CRM software usually need to balance sales-process fit, integrations, reporting, implementation capacity, security, deployment and commercial practicality. This guide uses the current TechSelectAI CRM evidence base. It does not assume that a globally capable CRM automatically has the right Egyptian pricing, local partner coverage, Arabic experience or support model.',
  'question'=>'Which CRM products should an Egyptian B2B organization investigate first, and what must still be validated locally?',
  'factors'=>[
   'Lead, account, opportunity and pipeline requirements',
   'Sales workflow automation, forecasting and management reporting',
   'Email, productivity, ERP and other required integrations',
   'SSO, API, access controls and enterprise security requirements',
   'Implementation complexity and internal change-management capacity',
   'Egypt-specific pricing, invoicing, partner and support arrangements',
   'Arabic user experience or bilingual operating requirements when relevant'
  ],
  'notice'=>'TechSelectAI does not currently maintain complete Egypt-specific pricing, partner, Arabic-language or support coverage for every CRM product. Missing local evidence means not yet verified, not unsupported. Validate those items as explicit requirements during evaluation and with the vendor or local implementation partner.'
 ],
 'erp-uae-enterprise'=>[
  'title'=>'ERP Software for UAE Mid-Market and Enterprise Organizations',
  'description'=>'Evidence-aware ERP selection guide for UAE organizations comparing finance, procurement, supply chain, manufacturing and enterprise requirements.',
  'eyebrow'=>'UAE · ERP decision guide',
  'category'=>'erp',
  'intro'=>'ERP selection in the UAE is rarely just a finance-software decision. Organizations may need procurement, inventory, supply chain, manufacturing, project operations, analytics, integrations, SSO, implementation governance and country-specific commercial or regulatory fit. This guide uses current TechSelectAI ERP evidence without declaring a universal winner.',
  'question'=>'How should a UAE organization narrow the ERP market without confusing global feature coverage with local fit?',
  'factors'=>[
   'Financial accounting, AP/AR, budgeting and reporting scope',
   'Procurement, inventory, warehouse and supply-chain requirements',
   'Manufacturing or project-oriented operations where applicable',
   'Workflow automation, dashboards, API and SSO requirements',
   'Migration complexity and integration with the existing application estate',
   'Implementation-partner capability and long-term operating model',
   'UAE-specific commercial, tax, hosting, support and contractual requirements'
  ],
  'notice'=>'The catalog evidence below describes recorded product capabilities, not UAE regulatory certification or guaranteed local availability. VAT, localization, Arabic, hosting, partner capacity, pricing and contractual requirements must be validated for the buyer’s exact legal entities and implementation scope.'
 ],
 'project-management-construction-mena'=>[
  'title'=>'Project Management Software for Construction and Engineering Teams in MENA',
  'description'=>'Evidence-aware project and work-management selection guide for construction and engineering teams operating across MENA.',
  'eyebrow'=>'MENA · Construction & engineering work-management guide',
  'category'=>'project-management',
  'intro'=>'Construction and engineering organizations often need schedules, dependencies, milestones, portfolio visibility, resource planning, workflow intake, reporting and cross-company collaboration. Generic work-management tools can support parts of that operating model, but the right answer depends on whether the buyer also needs specialist construction controls, document management, cost control or field workflows that are outside the current TechSelectAI project-management category.',
  'question'=>'When is a general project-management platform enough for a MENA construction or engineering organization, and when should specialist construction software be evaluated instead?',
  'factors'=>[
   'Task, timeline, milestone and dependency management',
   'Portfolio visibility across multiple projects or sites',
   'Resource and workload planning',
   'Forms, work intake, approvals and workflow automation',
   'Dashboards, reporting and executive portfolio visibility',
   'API, SSO and integration with ERP, document or collaboration systems',
   'Need for specialist construction capabilities such as cost control, BIM, field inspection or contract administration'
  ],
  'notice'=>'TechSelectAI’s current project-management category is not a complete construction-management software category. Product evidence here should not be interpreted as proof of BIM, quantity surveying, field inspection, project cost control or contract-administration support unless those capabilities are separately verified.'
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
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title><?=edg_h($g['title'])?> | TechSelectAI</title><meta name="description" content="<?=edg_h($g['description'])?>"><link rel="canonical" href="<?=edg_h($canonical)?>"><link rel="icon" href="/favicon.svg" type="image/svg+xml"><meta property="og:title" content="<?=edg_h($g['title'])?>"><meta property="og:description" content="<?=edg_h($g['description'])?>"><meta property="og:url" content="<?=edg_h($canonical)?>"><meta property="og:type" content="article"><script type="application/ld+json"><?=json_encode($schema,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)?></script><script type="application/ld+json"><?=json_encode($breadcrumb,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)?></script><style>
:root{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#172033;background:#f6f8fb}*{box-sizing:border-box}body{margin:0}.wrap{max-width:1160px;margin:auto;padding:0 22px}.nav{display:flex;align-items:center;justify-content:space-between;padding:20px 0}.nav img{height:38px;max-width:230px}.nav a{color:#173b63;text-decoration:none}.hero{padding:56px 0 34px}.eyebrow{font-size:13px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:#237a7b}.hero h1{font-size:clamp(34px,5vw,58px);line-height:1.04;max-width:960px;margin:12px 0 18px}.lead{font-size:19px;line-height:1.65;max-width:900px;color:#475569}.question{font-size:17px;font-weight:700;color:#173b63;background:#edf6fb;border-radius:12px;padding:15px 17px}.meta,.small{font-size:13px;color:#64748b}.grid{display:grid;grid-template-columns:1.45fr .75fr;gap:24px;align-items:start}.card{background:#fff;border:1px solid #dfe5ec;border-radius:16px;padding:22px;margin-bottom:18px;box-shadow:0 5px 24px rgba(15,23,42,.04)}h2{font-size:26px;margin-top:0}.factors{padding-left:20px;line-height:1.75}.notice{border-left:4px solid #319795;background:#eefafa;padding:16px 18px;border-radius:10px;margin:20px 0}.table-wrap{overflow-x:auto}table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #e5e7eb;padding:12px 10px}th{background:#f8fafc}.cta{background:#173b63;color:#fff;border-radius:18px;padding:26px}.cta a{display:inline-block;margin-top:10px;background:#fff;color:#173b63;font-weight:800;padding:11px 16px;border-radius:10px;text-decoration:none}.links a{display:block;padding:7px 0}.footer{padding:35px 0 50px;color:#64748b;font-size:13px}@media(max-width:820px){.grid{grid-template-columns:1fr}.hero{padding-top:28px}.nav{align-items:flex-start;gap:14px}.nav img{height:32px}}
</style></head><body><div class="wrap"><nav class="nav"><a href="/" aria-label="TechSelectAI home"><img src="/techselectai-logo.svg" alt="TechSelectAI"></a><div><a href="/methodology">Methodology</a> · <a href="/trust">Trust</a> · <a href="/software">Software</a></div></nav><main><section class="hero" id="overview" data-citation-section><div class="eyebrow"><?=edg_h($g['eyebrow'])?></div><h1><?=edg_h($g['title'])?></h1><p class="lead"><?=edg_h($g['intro'])?></p><p class="question"><?=edg_h($g['question'])?></p><p class="meta">Evidence-aware decision content · <?=$lastReviewed?'Catalog last reviewed '.edg_h(date('F Y',strtotime($lastReviewed))):'Review date varies by product'?></p></section><div class="grid"><div><section class="card"><h2>What should drive the decision?</h2><ul class="factors"><?php foreach($g['factors'] as $f):?><li><?=edg_h($f)?></li><?php endforeach;?></ul><div class="notice"><strong>Evidence boundary:</strong> <?=edg_h($g['notice'])?></div></section><section class="card" id="catalog-options" data-citation-section><h2>Current catalog evidence</h2><p class="small">Products are shown alphabetically. Evidence coverage is a data-quality indicator, not a product rank, market-share claim or recommendation.</p><div class="table-wrap"><table><thead><tr><th>Product</th><th>Known evidence</th><th>Supported facts</th><th>Avg. known confidence</th></tr></thead><tbody><?php foreach($rows as $r):?><tr><td><a href="/software/<?=edg_h($r['slug'])?>"><strong><?=edg_h($r['name'])?></strong></a><br><span class="small"><?=edg_h($r['vendor_name'])?></span></td><td><?= (int)$r['known_facts'] ?>/<?= (int)$r['total_facts'] ?> criteria</td><td><?= (int)$r['supported_facts'] ?></td><td><?=$r['known_confidence']!==null?(int)$r['known_confidence'].'%':'Not enough evidence'?></td></tr><?php endforeach;?></tbody></table></div></section></div><aside><section class="cta"><h2>Apply this to your company</h2><p>Turn these general decision factors into mandatory requirements and a buyer-specific TechSelectAI Fit Score where catalog evidence is available.</p><a href="/?start=consultation">Start My Software Evaluation</a></section><section class="card links"><h2>Related evidence</h2><a href="/categories/<?=edg_h($g['category'])?>">Browse the category</a><a href="/methodology">How Fit Score works</a><a href="/trust">Evidence & ownership disclosure</a></section></aside></div></main><footer class="footer">TechSelectAI decision guides use the same canonical evidence base as product documentation. Unknown evidence is not treated as unsupported.</footer></div></body></html>