<?php
require_once __DIR__.'/app/lib/Security.php';
require_once __DIR__.'/app/lib/Db.php';
require_once __DIR__.'/app/lib/AdminControlCenter.php';
Security::start();$adminUser=Security::user();
if(!$adminUser){header('Location: /login?next=%2Fadmin',true,302);exit;}
if(!in_array((string)($adminUser['role']??''),['reviewer','data_editor','admin','super_admin'],true)){http_response_code(403);exit('Forbidden');}
$pdo=Db::pdo();$overview=AdminControlCenter::overview($pdo);
function ah($v){return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>Admin Overview | TechSelectAI</title><style>
body{font-family:Inter,system-ui,sans-serif;background:#f5f8fb;color:#172033;margin:0}.wrap{max-width:1220px;margin:auto;padding:30px}.hero{display:flex;justify-content:space-between;gap:20px;align-items:flex-start}.hero h1{margin:0 0 6px}.muted{color:#64748b}.product-grid,.queue-grid,.tools{display:grid;gap:14px}.product-grid{grid-template-columns:repeat(3,1fr);margin:22px 0}.queue-grid{grid-template-columns:repeat(3,1fr)}.tools{grid-template-columns:repeat(4,1fr);margin-top:14px}.card,.tool{background:#fff;border:1px solid #dfe6ee;border-radius:15px;padding:18px;text-decoration:none;color:inherit}.card .n{font-size:30px;font-weight:800;margin-top:8px}.queue-card{display:block}.queue-card:hover,.tool:hover{border-color:#90a9bd;box-shadow:0 4px 18px rgba(15,39,64,.06)}.queue-card h3{margin:0;font-size:15px}.queue-card .n{font-size:26px}.queue-card p{font-size:12px;color:#64748b;line-height:1.45}.section{margin-top:30px}.section h2{margin-bottom:12px}.tool strong{display:block;margin-bottom:5px}.tool span{font-size:12px;color:#64748b;line-height:1.45}.badge{display:inline-flex;padding:6px 9px;border-radius:999px;background:#e8f1f8;color:#173b63;font-size:12px;font-weight:700}@media(max-width:900px){.queue-grid{grid-template-columns:1fr 1fr}.tools{grid-template-columns:1fr 1fr}}@media(max-width:560px){.wrap{padding:18px}.hero{display:block}.product-grid,.queue-grid,.tools{grid-template-columns:1fr}}
</style></head><body><main class="wrap"><section class="hero"><div><span class="badge">Operational control center</span><h1>TechSelectAI Admin</h1><p class="muted">Review what needs attention across software, evidence, evaluations, community intelligence, SEO, vendors and authority.</p></div><a href="/" class="muted">← Public site</a></section>
<section class="product-grid" id="software"><div class="card"><div class="muted">Active software</div><div class="n"><?=ah($overview['products']['active'])?></div></div><div class="card"><div class="muted">Draft software</div><div class="n"><?=ah($overview['products']['draft'])?></div></div><div class="card"><div class="muted">Archived software</div><div class="n"><?=ah($overview['products']['archived'])?></div></div></section>
<section class="section"><h2>Needs attention</h2><div class="queue-grid"><?php foreach($overview['queues'] as $q):?><a class="card queue-card" href="<?=ah($q['href'])?>"><h3><?=ah($q['label'])?></h3><div class="n"><?= $q['value']===null?'—':ah($q['value']) ?></div><p><?=ah($q['hint'])?></p></a><?php endforeach;?></div></section>
<section class="section"><h2>Operational workspaces</h2><div class="tools">
<a class="tool" href="/evidence-inbox"><strong>Evidence Inbox</strong><span>Verify, dispute, refresh and trace evidence impact.</span></a>
<a class="tool" href="/evaluation-control"><strong>AI Evaluations</strong><span>Review proposed scoring changes before publication.</span></a>
<a class="tool" href="/community-intelligence-admin"><strong>Community Intelligence</strong><span>Review permitted-source intelligence and publication state.</span></a>
<a class="tool" href="/pri-source-policy"><strong>PRI Source Policy</strong><span>Manage public-source access policy and analysis eligibility.</span></a>
<a class="tool" href="/review-moderation"><strong>User Reviews</strong><span>Moderate user-submitted reviews and reward eligibility.</span></a>
<a class="tool" href="/taxonomy-queue"><strong>Taxonomy</strong><span>Review category, capability and taxonomy changes.</span></a>
<a class="tool" href="/search-console"><strong>Search Console</strong><span>Measure clicks, impressions, CTR, rankings and SEO opportunities.</span></a>
<a class="tool" href="/indexation-health"><strong>Indexation Health</strong><span>Inspect sitemap coverage, exclusions and strategic URL issues.</span></a>
<a class="tool" href="/seo-quality-gates"><strong>SEO Quality Gates</strong><span>Review blocked/noindex generated pages and duplicate intent.</span></a>
<a class="tool" href="/long-tail-seo"><strong>Long-tail SEO</strong><span>Generate evidence-gated buyer-intent landing pages.</span></a>
<a class="tool" href="/buyer-analytics"><strong>Buyer Analytics</strong><span>Understand buyer intent and product-selection demand.</span></a>
<a class="tool" href="/ai-referrals"><strong>AI Visibility</strong><span>Review AI referral signals now; benchmark module follows in #178.</span></a>
<a class="tool" href="/authority-admin"><strong>Authority & Backlinks</strong><span>Manage citations, outreach prospects and external authority.</span></a>
<a class="tool" href="/software-submission-admin"><strong>Software Submissions</strong><span>Review new product submissions and suggestions.</span></a>
<a class="tool" href="/vendor-self-service-admin"><strong>Vendor Claims</strong><span>Verify vendor profiles and factual update requests.</span></a>
<a class="tool" href="/vendor-relationship-claims-admin"><strong>Partner Claims</strong><span>Review relationship, territory and evidence claims.</span></a>
</div></section></main></body></html>
