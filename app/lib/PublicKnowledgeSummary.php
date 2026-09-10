<?php
final class PublicKnowledgeSummary {
  public static function build(PDO $pdo,string $path,string $siteUrl): ?array {
    if(preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)) return self::software($pdo,$m[1],$siteUrl);
    if(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)/?$#',$path,$m)) return self::comparison($pdo,$m[1],$m[2],$siteUrl);
    return null;
  }

  private static function software(PDO $pdo,string $slug,string $siteUrl): ?array {
    $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active' LIMIT 1");
    $q->execute([$slug]);$p=$q->fetch();if(!$p)return null;
    $q=$pdo->prepare("SELECT support_status,confidence_score,last_verified_at FROM product_capabilities WHERE product_id=? AND edition_id IS NULL");$q->execute([$p['id']]);$caps=$q->fetchAll();
    $counts=['supported'=>0,'conditional'=>0,'unknown'=>0,'not_supported'=>0];$known=[];$fresh=[];
    foreach($caps as $r){$s=$r['support_status'];if($s==='supported')$counts['supported']++;elseif($s==='not_supported')$counts['not_supported']++;elseif(in_array($s,['unknown','not_yet_verified'],true))$counts['unknown']++;else $counts['conditional']++;if(!in_array($s,['unknown','not_yet_verified'],true))$known[]=(float)$r['confidence_score'];if(!empty($r['last_verified_at']))$fresh[]=$r['last_verified_at'];}
    $q=$pdo->prepare("SELECT COUNT(*) FROM product_integrations WHERE product_id=?");$q->execute([$p['id']]);$integrations=(int)$q->fetchColumn();
    $q=$pdo->prepare("SELECT COUNT(*) FROM product_deployments WHERE product_id=?");$q->execute([$p['id']]);$deployments=(int)$q->fetchColumn();
    $avg=$known?(int)round(array_sum($known)/count($known)*100):null;
    $last=self::latest(array_filter(array_merge([$p['last_reviewed_at']??null],$fresh)));
    $summary=$p['name'].' is listed by TechSelectAI in '.($p['category']?:'its recorded software category').'. TechSelectAI currently records '.$counts['supported'].' supported capabilities, '.$counts['conditional'].' conditional capabilities, '.$counts['unknown'].' unknown or not-yet-verified capabilities, and '.$counts['not_supported'].' not-supported capabilities.';
    if($integrations||$deployments)$summary.=' The profile also records '.$integrations.' integrations and '.$deployments.' deployment options.';
    if($avg!==null)$summary.=' Average confidence across known capability facts is '.$avg.'%.';
    if($last)$summary.=' Latest recorded review or verification activity: '.date('M j, Y',strtotime($last)).'.';
    $url=rtrim($siteUrl,'/').'/software/'.$p['slug'];
    $ld=['@context'=>'https://schema.org','@type'=>'TechArticle','headline'=>$p['name'].' factual software profile','description'=>$summary,'url'=>$url,'mainEntity'=>['@type'=>'SoftwareApplication','name'=>$p['name'],'applicationCategory'=>$p['category']?:null,'publisher'=>['@type'=>'Organization','name'=>$p['vendor']?:'Vendor not recorded']], 'dateModified'=>$last?date(DATE_ATOM,strtotime($last)):null];
    return ['html'=>self::section('Factual summary',$summary,$counts,$avg,$last),'jsonld'=>$ld];
  }

  private static function comparison(PDO $pdo,string $slugA,string $slugB,string $siteUrl): ?array {
    $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.last_reviewed_at,c.name category FROM products p LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug IN (?,?) AND p.status='active'");$q->execute([$slugA,$slugB]);$rows=$q->fetchAll();if(count($rows)!==2)return null;
    $by=[];foreach($rows as $r)$by[$r['slug']]=$r;if(!isset($by[$slugA],$by[$slugB]))return null;$a=$by[$slugA];$b=$by[$slugB];
    $stats=[];foreach([$a,$b] as $p){$q=$pdo->prepare("SELECT support_status,confidence_score,last_verified_at FROM product_capabilities WHERE product_id=? AND edition_id IS NULL");$q->execute([$p['id']]);$counts=['supported'=>0,'conditional'=>0,'unknown'=>0,'not_supported'=>0];$known=[];$dates=[];foreach($q->fetchAll() as $r){$s=$r['support_status'];if($s==='supported')$counts['supported']++;elseif($s==='not_supported')$counts['not_supported']++;elseif(in_array($s,['unknown','not_yet_verified'],true))$counts['unknown']++;else $counts['conditional']++;if(!in_array($s,['unknown','not_yet_verified'],true))$known[]=(float)$r['confidence_score'];if(!empty($r['last_verified_at']))$dates[]=$r['last_verified_at'];}$stats[$p['slug']]=['counts'=>$counts,'avg'=>$known?(int)round(array_sum($known)/count($known)*100):null,'last'=>self::latest(array_filter(array_merge([$p['last_reviewed_at']??null],$dates)))];}
    $sa=$stats[$a['slug']];$sb=$stats[$b['slug']];
    $summary='TechSelectAI compares '.$a['name'].' and '.$b['name'].' using recorded product evidence rather than user-specific recommendation scoring. '.$a['name'].' currently has '.$sa['counts']['supported'].' supported, '.$sa['counts']['conditional'].' conditional, '.$sa['counts']['unknown'].' unknown/not-yet-verified, and '.$sa['counts']['not_supported'].' not-supported capabilities. '.$b['name'].' currently has '.$sb['counts']['supported'].' supported, '.$sb['counts']['conditional'].' conditional, '.$sb['counts']['unknown'].' unknown/not-yet-verified, and '.$sb['counts']['not_supported'].' not-supported capabilities.';
    if($sa['avg']!==null||$sb['avg']!==null)$summary.=' Known-fact confidence is '.($sa['avg']!==null?$sa['avg'].'%':'not available').' for '.$a['name'].' and '.($sb['avg']!==null?$sb['avg'].'%':'not available').' for '.$b['name'].'.';
    $last=self::latest(array_filter([$sa['last'],$sb['last']]));if($last)$summary.=' Latest recorded review or verification activity across the comparison: '.date('M j, Y',strtotime($last)).'.';
    $canonical=[$a['slug'],$b['slug']];sort($canonical,SORT_STRING);$url=rtrim($siteUrl,'/').'/compare/'.implode('-vs-',$canonical);
    $ld=['@context'=>'https://schema.org','@type'=>'TechArticle','headline'=>$a['name'].' vs '.$b['name'].' factual comparison','description'=>$summary,'url'=>$url,'about'=>[['@type'=>'SoftwareApplication','name'=>$a['name'],'url'=>rtrim($siteUrl,'/').'/software/'.$a['slug']],['@type'=>'SoftwareApplication','name'=>$b['name'],'url'=>rtrim($siteUrl,'/').'/software/'.$b['slug']]],'dateModified'=>$last?date(DATE_ATOM,strtotime($last)):null];
    return ['html'=>self::section('Comparison summary',$summary,null,null,$last),'jsonld'=>$ld];
  }

  private static function section(string $title,string $summary,?array $counts,?int $avg,?string $last): string {
    $e=static fn($v)=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');
    $chips='';if($counts){foreach([['Supported',$counts['supported']],['Conditional',$counts['conditional']],['Unknown / not yet verified',$counts['unknown']],['Not supported',$counts['not_supported']]] as $c)$chips.='<span class="pk-chip"><strong>'.$e($c[1]).'</strong> '.$e($c[0]).'</span>';if($avg!==null)$chips.='<span class="pk-chip"><strong>'.$avg.'%</strong> known-fact confidence</span>';}
    if($last)$chips.='<span class="pk-chip">Updated <strong>'.$e(date('M j, Y',strtotime($last))).'</strong></span>';
    return '<section class="section pk-summary" id="factual-summary" data-citation-section="factual-summary"><div class="eyebrow">TechSelectAI factual data</div><h2>'.$e($title).'</h2><p class="section-intro">'.$e($summary).'</p>'.($chips?'<div class="pk-chips">'.$chips.'</div>':'').'<p class="pk-note">This summary reflects recorded TechSelectAI evidence only. It is separate from buyer-specific Fit Score, Evidence Confidence, TechSelectAI Verified Reviews and Public Review Intelligence. Unknown means not yet verified, not unsupported.</p></section>';
  }

  private static function latest(array $dates): ?string {if(!$dates)return null;usort($dates,fn($a,$b)=>strtotime($b)<=>strtotime($a));return $dates[0]??null;}
}
