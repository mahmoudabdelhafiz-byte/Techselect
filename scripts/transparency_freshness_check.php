<?php
$root=dirname(__DIR__);
$helper=file_get_contents($root.'/app/lib/TransparencySignals.php');
$public=file_get_contents($root.'/app/lib/PublicTransparency.php');
$evaluation=file_get_contents($root.'/app/lib/ProductEvaluation.php');
$software=file_get_contents($root.'/software_logo_page.php');
$knowledge=file_get_contents($root.'/knowledge_page.php');
$fail=[];
foreach(['STALE_DAYS = 180','freshness(','evidenceClass(','sourceMixLabel('] as $n)if(strpos($helper,$n)===false)$fail[]='helper missing '.$n;
foreach(['STALE_AFTER_DAYS','transparencyForEvaluation','stale_reasons','source_mix'] as $n)if(strpos($evaluation,$n)===false)$fail[]='evaluation transparency missing '.$n;
foreach(['Source transparency','Community opinion is not presented as vendor-certified fact','verification_states','comparison'] as $n)if(strpos($public,$n)===false)$fail[]='public transparency missing '.$n;
foreach(["review_status","published_at","data-citation-section=\"freshness\"","Community Intelligence","community-derived signal","Source mix:","Evidence period","See methodology"] as $n)if(strpos($software,$n)===false)$fail[]='software transparency missing '.$n;
foreach(['PublicTransparency::build','PublicTransparency::render','PublicTransparency::css'] as $n)if(strpos($knowledge,$n)===false)$fail[]='knowledge-page transparency missing '.$n;
if(strpos($software,"review_status']??'')==='published'")===false)$fail[]='PRI must be gated by reviewer publication status';
$r=TransparencySignalsTest::run();if(!$r)$fail[]='freshness policy failed';
if($fail){fwrite(STDERR,implode("\n",$fail)."\n");exit(1);}echo "transparency_freshness_check: OK\n";

final class TransparencySignalsTest {
  public static function run(): bool {
    require_once __DIR__.'/../app/lib/TransparencySignals.php';
    $now=new DateTimeImmutable('2026-09-11');
    $current=TransparencySignals::freshness('2026-08-01',$now);
    $stale=TransparencySignals::freshness('2026-01-01',$now);
    return !$current['stale'] && $stale['stale'] && TransparencySignals::evidenceClass('reddit')==='Community-derived insight';
  }
}
