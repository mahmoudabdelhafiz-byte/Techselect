<?php
require_once __DIR__.'/Db.php';

final class TosResearchAuthority
{
    public static function render(string $path,array $config): bool
    {
        if(!in_array($path,['/research/terminal-operating-systems','/research/terminal-operating-systems/','/research/tos-capability-taxonomy','/research/tos-capability-taxonomy/'],true))return false;
        $pdo=Db::pdo();
        if(str_contains($path,'tos-capability-taxonomy'))self::renderTaxonomy($pdo,$config);
        else self::renderHub($pdo,$config);
        return true;
    }

    private static function h($v): string
    {
        return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');
    }

    private static function category(PDO $pdo): array
    {
        $st=$pdo->prepare("SELECT id,name,description FROM categories WHERE slug='terminal-operating-systems' AND is_active=1 LIMIT 1");
        $st->execute();$category=$st->fetch(PDO::FETCH_ASSOC);
        if(!$category){http_response_code(404);echo '<!doctype html><html><body><h1>Terminal Operating Systems research dataset is not available.</h1></body></html>';exit;}
        return $category;
    }

    private static function renderHub(PDO $pdo,array $config): void
    {
        $category=self::category($pdo);
        $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor,
         COUNT(DISTINCT pc.id) capability_rows,
         COUNT(DISTINCT CASE WHEN pc.support_status='supported' THEN pc.id END) supported_count,
         COUNT(DISTINCT CASE WHEN pc.support_status IN('partially_supported','enterprise_only','plan_dependent','custom_configuration','addon','third_party_integration') THEN pc.id END) conditional_count,
         COUNT(DISTINCT CASE WHEN pc.support_status IN('unknown','not_yet_verified') THEN pc.id END) unknown_count,
         COUNT(DISTINCT CASE WHEN pc.support_status='not_supported' THEN pc.id END) unsupported_count,
         COUNT(DISTINCT es.id) evidence_count
         FROM products p
         LEFT JOIN vendors v ON v.id=p.vendor_id
         LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL
         LEFT JOIN evidence_sources es ON es.product_id=p.id
         WHERE p.category_id=? AND p.status='active'
         GROUP BY p.id ORDER BY p.name");
        $q->execute([$category['id']]);$products=$q->fetchAll(PDO::FETCH_ASSOC);

        $q=$pdo->prepare("SELECT m.name,m.slug,COUNT(c.id) capability_count FROM modules m JOIN capabilities c ON c.module_id=m.id AND c.is_active=1 WHERE m.category_id=? AND m.slug<>'mobile-access' GROUP BY m.id,m.name,m.slug ORDER BY m.id");
        $q->execute([$category['id']]);$modules=$q->fetchAll(PDO::FETCH_ASSOC);
        $specialistCount=0;foreach($modules as $m)$specialistCount+=(int)$m['capability_count'];
        $q=$pdo->prepare("SELECT COUNT(*) FROM capabilities c JOIN modules m ON m.id=c.module_id WHERE m.category_id=? AND m.slug='mobile-access' AND c.is_active=1");$q->execute([$category['id']]);$mobileCount=(int)$q->fetchColumn();
        $q=$pdo->prepare("SELECT COUNT(DISTINCT es.id),MAX(es.checked_at) FROM evidence_sources es JOIN products p ON p.id=es.product_id WHERE p.category_id=? AND p.status='active'");$q->execute([$category['id']]);[$sourceCount,$latestEvidence]=$q->fetch(PDO::FETCH_NUM);
        $q=$pdo->prepare("SELECT MAX(last_reviewed_at) FROM products WHERE category_id=? AND status='active'");$q->execute([$category['id']]);$lastReviewed=$q->fetchColumn();

        $base=rtrim($config['site_url'],'/');
        $canonical=$base.'/research/terminal-operating-systems';
        $items=[];foreach($products as $i=>$p)$items[]=['@type'=>'ListItem','position'=>$i+1,'name'=>$p['name'],'url'=>$base.'/software/'.$p['slug']];
        $schema=['@context'=>'https://schema.org','@graph'=>[
          ['@type'=>'CollectionPage','@id'=>$canonical.'#page','url'=>$canonical,'name'=>'Terminal Operating Systems (TOS): Vendor Landscape, Capabilities & Selection Framework','description'=>'TechSelectAI specialist research hub for evidence-based Terminal Operating System selection for container and mixed-cargo terminals.','dateModified'=>$lastReviewed?date('Y-m-d',strtotime($lastReviewed)):date('Y-m-d'),'about'=>[['@type'=>'Thing','name'=>'Terminal Operating System'],['@type'=>'Thing','name'=>'Container terminal operations']],'mainEntity'=>['@type'=>'ItemList','name'=>'Terminal Operating Systems in the TechSelectAI research dataset','numberOfItems'=>count($items),'itemListElement'=>$items]],
          ['@type'=>'BreadcrumbList','itemListElement'=>[
            ['@type'=>'ListItem','position'=>1,'name'=>'Home','item'=>$base.'/'],
            ['@type'=>'ListItem','position'=>2,'name'=>'Research','item'=>$base.'/research/software-evidence-benchmark'],
            ['@type'=>'ListItem','position'=>3,'name'=>'Terminal Operating Systems','item'=>$canonical]
          ]]
        ]];
        ?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Terminal Operating Systems (TOS): Vendor Comparison & Selection Framework | TechSelectAI</title>
<meta name="description" content="Evidence-based Terminal Operating System research covering TOS vendors, 85 specialist capabilities, vessel, yard, gate, rail, automation, integrations, billing, special cargo and resilience.">
<link rel="canonical" href="<?=self::h($canonical)?>"><meta name="robots" content="index,follow,max-snippet:-1,max-image-preview:large">
<meta property="og:type" content="website"><meta property="og:site_name" content="TechSelectAI"><meta property="og:title" content="Terminal Operating Systems (TOS): Vendor Landscape & Selection Framework"><meta property="og:description" content="TechSelectAI specialist TOS research for evidence-based terminal software selection."><meta property="og:url" content="<?=self::h($canonical)?>">
<script type="application/ld+json"><?=json_encode($schema,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)?></script>
<style>:root{--navy:#153b66;--teal:#248d91;--ink:#182334;--muted:#667085;--line:#dfe7ee;--soft:#f5f9fb}*{box-sizing:border-box}body{margin:0;font-family:Inter,Arial,sans-serif;color:var(--ink);background:#fff;line-height:1.62}a{color:#1766a5}header{padding:17px max(22px,5vw);border-bottom:1px solid var(--line);display:flex;justify-content:space-between;align-items:center}header a.brand{font-weight:850;font-size:20px;color:var(--navy);text-decoration:none}nav a{margin-left:18px;text-decoration:none;font-weight:650}.wrap{max-width:1120px;margin:auto;padding:0 24px 60px}.hero{padding:48px 0 28px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.1em;color:var(--teal);font-weight:800}.hero h1{font-size:clamp(37px,5.2vw,62px);line-height:1.04;margin:8px 0 16px;max-width:980px}.lead{font-size:20px;color:#506075;max-width:900px}.stats,.links{display:flex;gap:10px;flex-wrap:wrap;margin-top:20px}.pill{background:#eef7f7;border:1px solid #d5e8e8;border-radius:999px;padding:8px 11px;font-size:13px;font-weight:750}.btn{display:inline-flex;padding:10px 14px;border-radius:10px;text-decoration:none;font-weight:750;border:1px solid #cdd9e2}.btn.primary{background:var(--navy);color:#fff;border-color:var(--navy)}.section{padding-top:38px}.section h2{font-size:29px;margin:0 0 9px}.intro{color:var(--muted);max-width:900px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(245px,1fr));gap:15px}.card{border:1px solid var(--line);border-radius:15px;padding:18px;background:#fff}.card h3{margin:0 0 7px;font-size:18px}.card p{color:var(--muted);margin:6px 0}.metric{font-size:12px;color:#536174;margin-top:10px}.notice{background:#fff9ec;border:1px solid #ecd9aa;border-radius:14px;padding:18px;color:#694b0e}.steps{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:13px}.step{background:var(--soft);border:1px solid var(--line);border-radius:14px;padding:17px}.step b{display:block;color:var(--navy);margin-bottom:5px}.footer-note{margin-top:42px;color:var(--muted);font-size:13px}@media(max-width:700px){nav{display:none}}</style></head><body>
<header><a class="brand" href="/">TechSelectAI</a><nav><a href="/categories/terminal-operating-systems">TOS category</a><a href="/research/tos-capability-taxonomy">TOS taxonomy</a><a href="/methodology">Methodology</a></nav></header>
<main class="wrap"><section class="hero"><div class="eyebrow">Specialist research · Ports, maritime & terminal operations</div><h1>Terminal Operating Systems (TOS): Vendor Landscape, Capabilities & Selection Framework</h1><p class="lead">TechSelectAI maintains a specialist, evidence-based research model for selecting Terminal Operating Systems used in container and mixed-cargo terminal operations. The model focuses on operational requirements—not review popularity—and separates verified product capability evidence from buyer-specific fit scoring.</p>
<div class="stats"><span class="pill"><?=count($products)?> active TOS products</span><span class="pill"><?=$specialistCount?> specialist TOS criteria</span><span class="pill"><?=$mobileCount?> mobile-access criteria tracked separately</span><span class="pill"><?=(int)$sourceCount?> recorded evidence sources</span></div>
<div class="links"><a class="btn primary" href="/categories/terminal-operating-systems">Compare TOS products</a><a class="btn" href="/research/tos-capability-taxonomy">Explore the capability taxonomy</a><a class="btn" href="/methodology">How evidence is evaluated</a></div></section>
<section class="section"><h2>What a modern TOS evaluation needs to cover</h2><p class="intro">A Terminal Operating System decision goes far beyond a generic software feature list. TechSelectAI's specialist model organizes the operational questions buyers commonly need to validate during discovery, shortlist, RFP and reference checks.</p><div class="grid"><?php foreach($modules as $m):?><article class="card"><div class="eyebrow">TOS module</div><h3><?=self::h($m['name'])?></h3><p><?=(int)$m['capability_count']?> buyer-selectable criteria in the current taxonomy.</p></article><?php endforeach;?></div></section>
<section class="section"><h2>Current TOS research dataset</h2><p class="intro">These are the active Terminal Operating Systems currently represented in the TechSelectAI dataset. Counts describe TechSelectAI's research coverage, not product quality or a universal ranking.</p><div class="grid"><?php foreach($products as $p):?><article class="card"><div class="eyebrow"><?=self::h($p['vendor']?:'Vendor')?></div><h3><a href="/software/<?=self::h($p['slug'])?>"><?=self::h($p['name'])?></a></h3><p><?=self::h($p['short_description']?:'Evidence-backed Terminal Operating System profile.')?></p><div class="metric"><?=(int)$p['supported_count']?> supported · <?=(int)$p['conditional_count']?> conditional · <?=(int)$p['unknown_count']?> research pending · <?=(int)$p['unsupported_count']?> explicitly unsupported · <?=(int)$p['evidence_count']?> evidence sources</div></article><?php endforeach;?></div></section>
<section class="section"><h2>How to interpret TechSelectAI TOS evidence</h2><div class="notice"><strong>Not yet verified does not mean not supported.</strong> It means the current TechSelectAI evidence set has not established the exact capability. Vendor RFP responses, project-specific configuration, implementation documentation or terminal references may verify additional capability.</div><div class="steps" style="margin-top:15px"><div class="step"><b>Supported</b>Current evidence establishes the capability for the evaluated product or documented scope.</div><div class="step"><b>Conditional / partial</b>The capability may depend on an edition, add-on, companion module, third-party integration or implementation scope.</div><div class="step"><b>Not yet verified</b>Evidence is incomplete. TechSelectAI does not convert missing evidence into a negative product claim.</div><div class="step"><b>Not supported</b>Used only when evidence establishes that the evaluated product does not support the capability.</div></div></section>
<section class="section"><h2>Designed for TOS procurement and technical evaluation</h2><div class="steps"><div class="step"><b>1. Define terminal requirements</b>Capture vessel, yard, gate, rail, equipment, automation, cargo, integration, billing, resilience and security needs.</div><div class="step"><b>2. Review evidence</b>Separate demonstrated product capability from optional modules, implementation examples and claims that are still unverified.</div><div class="step"><b>3. Build the shortlist</b>Compare products against the buyer's actual must-have criteria rather than a generic market popularity list.</div><div class="step"><b>4. Validate through RFP</b>Use vendor responses, architecture workshops, reference terminals and implementation evidence to close remaining research gaps.</div></div></section>
<section class="section"><h2>Research transparency</h2><p class="intro">TechSelectAI is not claiming that every TOS capability is permanently verified or universally included in every implementation. Optional modules, companion products, integrations and project-specific configurations are kept explicit where the available evidence requires that distinction. Evidence confidence and product fit are separate signals.</p><div class="links"><a class="btn" href="/trust">Trust & independence</a><a class="btn" href="/about-techselectai">About / citation resource</a><a class="btn" href="/research/software-evidence-benchmark">Evidence benchmark</a></div><?php if($latestEvidence):?><p class="footer-note">Latest recorded TOS evidence check in the current dataset: <?=self::h(date('F j, Y',strtotime($latestEvidence)))?>.</p><?php endif;?></section></main></body></html><?php
    }

    private static function renderTaxonomy(PDO $pdo,array $config): void
    {
        $category=self::category($pdo);
        $q=$pdo->prepare("SELECT m.name module_name,m.slug module_slug,c.name capability_name,c.slug capability_slug,c.description FROM modules m JOIN capabilities c ON c.module_id=m.id AND c.is_active=1 WHERE m.category_id=? ORDER BY m.id,c.id");
        $q->execute([$category['id']]);$rows=$q->fetchAll(PDO::FETCH_ASSOC);
        $modules=[];$specialistCount=0;$mobileCount=0;
        foreach($rows as $r){$modules[$r['module_name']][]=$r;if($r['module_slug']==='mobile-access')$mobileCount++;else $specialistCount++;}
        $base=rtrim($config['site_url'],'/');$canonical=$base.'/research/tos-capability-taxonomy';
        $terms=[];foreach($rows as $r){if($r['module_slug']==='mobile-access')continue;$terms[]=['@type'=>'DefinedTerm','name'=>$r['capability_name'],'termCode'=>$r['capability_slug'],'description'=>$r['description'],'inDefinedTermSet'=>$canonical];}
        $schema=['@context'=>'https://schema.org','@graph'=>[
          ['@type'=>'TechArticle','@id'=>$canonical.'#article','url'=>$canonical,'headline'=>'Terminal Operating System Capability Taxonomy','description'=>'TechSelectAI specialist capability taxonomy for evaluating container-terminal and mixed-cargo Terminal Operating Systems.','about'=>['@type'=>'Thing','name'=>'Terminal Operating System']],
          ['@type'=>'DefinedTermSet','@id'=>$canonical,'name'=>'TechSelectAI Terminal Operating System Capability Taxonomy','description'=>'Buyer-selectable operational requirements used by TechSelectAI to structure TOS research and software selection.','hasDefinedTerm'=>$terms],
          ['@type'=>'BreadcrumbList','itemListElement'=>[
            ['@type'=>'ListItem','position'=>1,'name'=>'Home','item'=>$base.'/'],
            ['@type'=>'ListItem','position'=>2,'name'=>'TOS Research','item'=>$base.'/research/terminal-operating-systems'],
            ['@type'=>'ListItem','position'=>3,'name'=>'TOS Capability Taxonomy','item'=>$canonical]
          ]]
        ]];
        ?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Terminal Operating System Capability Taxonomy — <?=$specialistCount?> TOS Requirements | TechSelectAI</title>
<meta name="description" content="Explore TechSelectAI's <?=$specialistCount?>-requirement Terminal Operating System capability taxonomy for vessel, yard, gate, rail, equipment, automation, cargo, integration, billing, resilience and security.">
<link rel="canonical" href="<?=self::h($canonical)?>"><meta name="robots" content="index,follow,max-snippet:-1,max-image-preview:large">
<meta property="og:type" content="article"><meta property="og:site_name" content="TechSelectAI"><meta property="og:title" content="Terminal Operating System Capability Taxonomy"><meta property="og:description" content="A structured TOS requirements framework for container-terminal software evaluation."><meta property="og:url" content="<?=self::h($canonical)?>">
<script type="application/ld+json"><?=json_encode($schema,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE)?></script>
<style>:root{--navy:#153b66;--teal:#248d91;--ink:#182334;--muted:#667085;--line:#dfe7ee;--soft:#f6f9fb}*{box-sizing:border-box}body{margin:0;font-family:Inter,Arial,sans-serif;color:var(--ink);line-height:1.58}a{color:#1766a5}header{padding:17px max(22px,5vw);border-bottom:1px solid var(--line);display:flex;justify-content:space-between}header a{font-weight:750;text-decoration:none}.brand{font-size:20px;color:var(--navy)}.wrap{max-width:1120px;margin:auto;padding:0 24px 60px}.hero{padding:46px 0 26px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.1em;color:var(--teal);font-weight:800}.hero h1{font-size:clamp(36px,5vw,58px);line-height:1.05;margin:8px 0 15px}.lead{font-size:19px;color:#526175;max-width:900px}.note{padding:17px;border:1px solid #d8e8ea;background:#f1f8f8;border-radius:13px;margin-top:18px}.module{padding-top:34px}.module h2{font-size:27px;margin:0 0 7px}.module-intro{color:var(--muted);margin:0 0 14px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(285px,1fr));gap:12px}.cap{border:1px solid var(--line);border-radius:13px;padding:15px;background:#fff}.cap h3{font-size:16px;margin:0 0 6px}.cap p{font-size:13px;color:var(--muted);margin:0}.slug{font-size:11px;color:#718096;margin-top:8px;overflow-wrap:anywhere}.links{display:flex;gap:10px;flex-wrap:wrap;margin-top:20px}.btn{padding:10px 13px;border:1px solid #ccd8e0;border-radius:9px;text-decoration:none;font-weight:750}.footer-note{margin-top:38px;color:var(--muted);font-size:13px}@media(max-width:650px){header span{display:none}}</style></head><body>
<header><a class="brand" href="/">TechSelectAI</a><span><a href="/research/terminal-operating-systems">TOS research hub</a> · <a href="/categories/terminal-operating-systems">Compare products</a></span></header>
<main class="wrap"><section class="hero"><div class="eyebrow">Original specialist framework · Terminal operations</div><h1>Terminal Operating System Capability Taxonomy</h1><p class="lead">TechSelectAI uses a domain-specific TOS requirements model to structure terminal software discovery, evidence research, comparison and buyer requirement capture. The current framework contains <strong><?=$specialistCount?> specialist operational criteria</strong> across nine TOS modules, with <?=$mobileCount?> mobile-access criteria tracked separately.</p><div class="note"><strong>Taxonomy depth is not evidence depth.</strong> A criterion appearing here means it is relevant to TOS evaluation; it does not mean every product supports it. Product support is established separately from evidence and may remain <em>not yet verified</em>.</div><div class="links"><a class="btn" href="/research/terminal-operating-systems">TOS vendor landscape</a><a class="btn" href="/categories/terminal-operating-systems">TOS category comparison</a><a class="btn" href="/methodology">Evaluation methodology</a></div></section>
<?php foreach($modules as $module=>$caps):?><section class="module"><div class="eyebrow"><?=self::h($module==='Mobile Access'?'Cross-category selection criteria':'TOS operational module')?></div><h2><?=self::h($module)?></h2><p class="module-intro"><?=count($caps)?> buyer-selectable criteria.</p><div class="grid"><?php foreach($caps as $cap):?><article class="cap"><h3><a href="/capabilities/<?=self::h($cap['capability_slug'])?>"><?=self::h($cap['capability_name'])?></a></h3><p><?=self::h($cap['description'])?></p><div class="slug"><?=self::h($cap['capability_slug'])?></div></article><?php endforeach;?></div></section><?php endforeach;?>
<p class="footer-note">Use this taxonomy as a requirements framework, not as a claim that every listed capability is standard in every TOS. Critical requirements should be validated through current vendor documentation, RFP responses, solution architecture, reference terminals and implementation evidence.</p></main></body></html><?php
    }
}
