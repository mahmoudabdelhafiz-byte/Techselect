<?php
final class AiFactualSummary {
  public static function build(PDO $pdo,string $path,string $siteUrl): ?array {
    $path=parse_url($path,PHP_URL_PATH)?:'/';
    if(preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)) return self::software($pdo,$m[1],$siteUrl);
    if(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)/?$#',$path,$m)) return self::comparison($pdo,$m[1],$m[2],$siteUrl);
    return null;
  }

  private static function software(PDO $pdo,string $slug,string $siteUrl): ?array {
    $st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.short_description,p.last_reviewed_at,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active' LIMIT 1");
    $st->execute([$slug]);$p=$st->fetch();if(!$p)return null;
    $q=$pdo->prepare("SELECT support_status,COUNT(*) n FROM product_capabilities WHERE product_id=? AND edition_id IS NULL GROUP BY support_status");$q->execute([$p['id']]);
    $counts=[];foreach($q->fetchAll() as $r)$counts[$r['support_status']]=(int)$r['n'];
    $supported=(int)($counts['supported']??0);
    $unknown=(int)($counts['unknown']??0)+(int)($counts['not_yet_verified']??0);
    $notSupported=(int)($counts['not_supported']??0);
    $total=array_sum($counts);
    $conditional=max(0,$total-$supported-$unknown-$notSupported);
    $q=$pdo->prepare("SELECT COUNT(*) FROM product_integrations WHERE product_id=?");$q->execute([$p['id']]);$integrations=(int)$q->fetchColumn();
    $q=$pdo->prepare("SELECT COUNT(*) FROM product_deployments WHERE product_id=?");$q->execute([$p['id']]);$deployments=(int)$q->fetchColumn();
    $q=$pdo->prepare("SELECT COUNT(*) FROM evidence_sources WHERE product_id=?");$q->execute([$p['id']]);$evidence=(int)$q->fetchColumn();
    $reviewed=$p['last_reviewed_at']?date('M j, Y',strtotime((string)$p['last_reviewed_at'])):null;
    $summary=$p['name'].' is tracked by TechSelectAI as '.($p['category']?:'business software').($p['vendor']?' from '.$p['vendor']:'').'. The current factual profile records '.$total.' capabilities: '.$supported.' supported, '.$conditional.' conditional, '.$unknown.' not yet verified, and '.$notSupported.' not supported. It also tracks '.$integrations.' integrations, '.$deployments.' deployment option'.($deployments===1?'':'s').' and '.$evidence.' evidence source'.($evidence===1?'':'s').'.'.($reviewed?' Last reviewed '.$reviewed.'.':'');
    $canonical=rtrim($siteUrl,'/').'/software/'.$p['slug'];
    $ld=['@context'=>'https://schema.org','@type'=>'WebPage','name'=>$p['name'].' factual software profile','url'=>$canonical,'description'=>$summary,'dateModified'=>$p['last_reviewed_at']?:null,'about'=>['@type'=>'SoftwareApplication','name'=>$p['name'],'applicationCategory'=>$p['category']?:null,'publisher'=>$p['vendor']?['@type'=>'Organization','name'=>$p['vendor']]:null,'url'=>$canonical],'isPartOf'=>['@type'=>'WebSite','name'=>'TechSelectAI','url'=>rtrim($siteUrl,'/').'/']];
    $ld=self::stripNulls($ld);
    return ['summary'=>$summary,'html'=>self::box('Factual summary',$summary,'This summary uses recorded TechSelectAI product facts only. Unknown or not yet verified does not mean unsupported.'),'jsonld'=>$ld];
  }

  private static function comparison(PDO $pdo,string $slugA,string $slugB,string $siteUrl): ?array {
    $slugs=[$slugA,$slugB];sort($slugs,SORT_STRING);
    $st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.last_reviewed_at,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug IN (?,?) AND p.status='active'");
    $st->execute($slugs);$rows=$st->fetchAll();if(count($rows)!==2)return null;
    usort($rows,fn($a,$b)=>array_search($a['slug'],$slugs,true)<=>array_search($b['slug'],$slugs,true));
    $parts=[];$entities=[];$latest=null;
    foreach($rows as $p){
      $q=$pdo->prepare("SELECT support_status,COUNT(*) n FROM product_capabilities WHERE product_id=? AND edition_id IS NULL GROUP BY support_status");$q->execute([$p['id']]);$c=[];foreach($q->fetchAll() as $r)$c[$r['support_status']]=(int)$r['n'];
      $supported=(int)($c['supported']??0);$unknown=(int)($c['unknown']??0)+(int)($c['not_yet_verified']??0);$notSupported=(int)($c['not_supported']??0);$total=array_sum($c);$conditional=max(0,$total-$supported-$unknown-$notSupported);
      $parts[]=$p['name'].' has '.$supported.' supported, '.$conditional.' conditional, '.$unknown.' not yet verified, and '.$notSupported.' not-supported capability records';
      $entities[]=['@type'=>'SoftwareApplication','name'=>$p['name'],'applicationCategory'=>$p['category']?:null,'publisher'=>$p['vendor']?['@type'=>'Organization','name'=>$p['vendor']]:null,'url'=>rtrim($siteUrl,'/').'/software/'.$p['slug']];
      if($p['last_reviewed_at'] && (!$latest || strtotime($p['last_reviewed_at'])>strtotime($latest)))$latest=$p['last_reviewed_at'];
    }
    $summary='TechSelectAI compares '.$rows[0]['name'].' and '.$rows[1]['name'].' using recorded product facts rather than a generic winner label. '.$parts[0].'; '.$parts[1].'. Buyer-specific fit still depends on requirements such as integrations, deployment, security, region and budget.';
    $canonical=rtrim($siteUrl,'/').'/compare/'.implode('-vs-',$slugs);
    $ld=self::stripNulls(['@context'=>'https://schema.org','@type'=>'WebPage','name'=>$rows[0]['name'].' vs '.$rows[1]['name'],'url'=>$canonical,'description'=>$summary,'dateModified'=>$latest?:null,'about'=>$entities,'isPartOf'=>['@type'=>'WebSite','name'=>'TechSelectAI','url'=>rtrim($siteUrl,'/').'/']]);
    return ['summary'=>$summary,'html'=>self::box('Comparison summary',$summary,'This neutral summary uses recorded TechSelectAI facts. It is not a buyer-specific Fit Score and does not include sponsored preference.'),'jsonld'=>$ld];
  }

  private static function box(string $title,string $summary,string $note): string {
    $e=static fn($v)=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');
    return '<section class="ts-factual-summary" id="factual-summary" data-citation-section="factual-summary"><div class="eyebrow">TechSelectAI factual data</div><h2>'.$e($title).'</h2><p>'.$e($summary).'</p><small>'.$e($note).'</small></section>';
  }

  private static function stripNulls(array $value): array {
    foreach($value as $k=>$v){if($v===null||$v===''){unset($value[$k]);continue;}if(is_array($v))$value[$k]=self::stripNulls($v);}return $value;
  }
}
