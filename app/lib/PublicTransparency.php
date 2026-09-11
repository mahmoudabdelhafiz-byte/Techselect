<?php
require_once __DIR__.'/ProductEvaluation.php';

final class PublicTransparency {
  public static function build(PDO $pdo,string $path): ?array {
    if(preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)) return self::software($pdo,$m[1]);
    if(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)/?$#',$path,$m)) return self::comparison($pdo,$m[1],$m[2]);
    return null;
  }

  private static function software(PDO $pdo,string $slug): ?array {
    $st=$pdo->prepare("SELECT id,name,last_reviewed_at FROM products WHERE slug=? AND status='active' LIMIT 1");$st->execute([$slug]);$p=$st->fetch(PDO::FETCH_ASSOC);if(!$p)return null;
    $ev=null;try{$ev=ProductEvaluation::publishedForProduct($pdo,(int)$p['id']);}catch(Throwable $e){}
    $sources=self::productEvidenceSummary($pdo,(int)$p['id']);
    $last=self::latestDate([$p['last_reviewed_at']??null,$sources['latest_checked_at']??null,$ev['evaluated_at']??null,$ev['published_at']??null]);
    $stale=$ev['transparency']['stale']??false;
    $staleReasons=$ev['transparency']['stale_reasons']??[];
    return ['type'=>'software','title'=>$p['name'],'last_reviewed'=>$last,'evaluation'=>$ev,'evidence'=>$sources,'stale'=>$stale,'stale_reasons'=>$staleReasons];
  }

  private static function comparison(PDO $pdo,string $a,string $b): ?array {
    $st=$pdo->prepare("SELECT id,name,slug,last_reviewed_at FROM products WHERE slug IN (?,?) AND status='active'");$st->execute([$a,$b]);$rows=$st->fetchAll(PDO::FETCH_ASSOC);if(count($rows)<2)return null;
    $items=[];foreach($rows as $p){$ev=null;try{$ev=ProductEvaluation::publishedForProduct($pdo,(int)$p['id']);}catch(Throwable $e){}$src=self::productEvidenceSummary($pdo,(int)$p['id']);$items[]=['name'=>$p['name'],'slug'=>$p['slug'],'last_reviewed'=>self::latestDate([$p['last_reviewed_at']??null,$src['latest_checked_at']??null,$ev['evaluated_at']??null,$ev['published_at']??null]),'evidence'=>$src,'evaluation'=>$ev];}
    return ['type'=>'comparison','items'=>$items];
  }

  private static function productEvidenceSummary(PDO $pdo,int $productId): array {
    $st=$pdo->prepare("SELECT source_type,verification_status,COUNT(*) n,MAX(checked_at) latest_checked FROM evidence_sources WHERE product_id=? GROUP BY source_type,verification_status");$st->execute([$productId]);
    $mix=[];$states=[];$count=0;$latest=null;
    foreach($st->fetchAll(PDO::FETCH_ASSOC) as $r){$n=(int)$r['n'];$count+=$n;$type=(string)($r['source_type']?:'unknown');$mix[$type]=($mix[$type]??0)+$n;$state=(string)($r['verification_status']?:'unverified');$states[$state]=($states[$state]??0)+$n;if(!empty($r['latest_checked'])&&($latest===null||$r['latest_checked']>$latest))$latest=$r['latest_checked'];}
    arsort($mix);return ['count'=>$count,'source_mix'=>$mix,'verification_states'=>$states,'latest_checked_at'=>$latest];
  }

  private static function latestDate(array $dates): ?string {$valid=array_values(array_filter($dates));if(!$valid)return null;usort($valid,fn($x,$y)=>strtotime((string)$y)<=>strtotime((string)$x));return $valid[0];}

  public static function render(array $data): string {
    $e=static fn($v)=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');
    if(($data['type']??'')==='comparison'){
      $cards='';foreach($data['items'] as $item){$mix=self::mixLabel($item['evidence']['source_mix']??[]);$cards.='<article class="ts-trust-card"><strong>'.$e($item['name']).'</strong><div>'.($item['last_reviewed']?'Last reviewed '.date('M j, Y',strtotime($item['last_reviewed'])):'Review date unavailable').'</div><div>'.(int)($item['evidence']['count']??0).' evidence sources'.($mix?' · '.$e($mix):'').'</div>'.(!empty($item['evaluation']['methodology_version'])?'<div>Evaluation methodology '.$e($item['evaluation']['methodology_version']).'</div>':'').'</article>';}
      return '<section class="ts-transparency" id="source-transparency" data-citation-section="source-transparency"><div class="eyebrow">Source transparency</div><h2>Freshness & methodology</h2><p>Comparison facts, TechSelectAI analysis, community-derived insights and estimates are kept as separate evidence types. Missing evidence is not treated as proof of non-support.</p><div class="ts-trust-grid">'.$cards.'</div><p class="ts-trust-note"><a href="/methodology">Review TechSelectAI methodology →</a></p></section>';
    }
    $mix=self::mixLabel($data['evidence']['source_mix']??[]);$ev=$data['evaluation']??null;$warning='';if(!empty($data['stale'])){$reason=implode(' ',array_map($e,$data['stale_reasons']??[]));$warning='<div class="ts-stale"><strong>Freshness warning:</strong> '.$reason.' This evaluation should be reviewed before being treated as current.</div>';}
    return '<section class="ts-transparency" id="source-transparency" data-citation-section="source-transparency"><div class="eyebrow">Source transparency</div><h2>How current is this page?</h2>'.$warning.'<div class="ts-trust-grid"><article class="ts-trust-card"><strong>Last reviewed</strong><div>'.(!empty($data['last_reviewed'])?date('M j, Y',strtotime($data['last_reviewed'])):'Not available').'</div></article><article class="ts-trust-card"><strong>Evidence coverage</strong><div>'.(int)($data['evidence']['count']??0).' recorded sources</div><div>'.$e($mix?:'Source mix not yet available').'</div></article><article class="ts-trust-card"><strong>TechSelectAI evaluation</strong><div>'.($ev&&!empty($ev['methodology_version'])?'Methodology '.$e($ev['methodology_version']):'No published product evaluation').'</div><div>'.($ev?$e(ProductEvaluation::confidenceLabel((float)$ev['confidence_score'])).' confidence':'').'</div></article></div><p class="ts-trust-note"><strong>Labels:</strong> vendor/official factual sources, independently verified facts, community-derived insights, TechSelectAI analysis and estimates are distinct signals. Community opinion is not presented as vendor-certified fact. <a href="/methodology">See methodology →</a></p></section>';
  }

  private static function mixLabel(array $mix): string {$parts=[];foreach(array_slice($mix,0,4,true) as $k=>$v)$parts[]=$k.': '.(int)$v;return implode(' · ',$parts);}

  public static function css(): string {return '<style id="techselectai-transparency-style">.ts-transparency{margin:28px 0;padding:22px;border:1px solid #d8e5ec;border-radius:16px;background:#fbfdfe}.ts-transparency h2{margin:5px 0 8px;color:#123b67}.ts-transparency p{color:#536174;line-height:1.6}.ts-trust-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px;margin-top:16px}.ts-trust-card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:14px;color:#536174;font-size:13px;line-height:1.55}.ts-trust-card strong{display:block;color:#123b67;font-size:14px;margin-bottom:5px}.ts-trust-note{font-size:12px;margin:14px 0 0}.ts-stale{margin:12px 0;padding:11px 13px;border-radius:10px;background:#fff7ed;border:1px solid #fed7aa;color:#9a3412;font-size:13px;line-height:1.5}</style>';}
}
