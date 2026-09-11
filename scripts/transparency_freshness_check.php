<?php
$helper=file_get_contents(__DIR__.'/../app/lib/TransparencySignals.php');
$page=file_get_contents(__DIR__.'/../software_logo_page.php');
$fail=[];
foreach(['STALE_DAYS = 180','freshness(','evidenceClass(','sourceMixLabel('] as $n)if(strpos($helper,$n)===false)$fail[]='helper missing '.$n;
foreach(["review_status","published_at","data-citation-section=\"freshness\"","Community Intelligence","community-derived signal","Source mix:","Evidence period","See methodology"] as $n)if(strpos($page,$n)===false)$fail[]='public transparency missing '.$n;
if(strpos($page,"review_status']??'')==='published'")===false)$fail[]='PRI must be gated by reviewer publication status';
$r=TransparencySignalsTest::run();
if(!$r)$fail[]='freshness policy failed';
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
