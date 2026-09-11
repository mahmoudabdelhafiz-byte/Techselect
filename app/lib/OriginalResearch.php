<?php
require_once __DIR__.'/Db.php';

final class OriginalResearch {
  public const REPORT_SLUG='software-evidence-benchmark';
  public const METHODOLOGY_VERSION='research-v1.0';

  public static function generate(?PDO $pdo=null, bool $publish=true): array {
    $pdo=$pdo?:Db::pdo();
    $report=self::report($pdo);
    if(!$report) throw new RuntimeException('Research report definition missing. Run migration 055.');

    $summary=$pdo->query("SELECT
      COUNT(DISTINCT p.id) sample_products,
      COUNT(DISTINCT p.category_id) sample_categories,
      COUNT(DISTINCT e.id) sample_evidence_sources,
      COUNT(DISTINCT pc.id) capability_rows,
      SUM(CASE WHEN pc.support_status<>'not_yet_verified' THEN 1 ELSE 0 END) known_capability_rows,
      SUM(CASE WHEN e.verification_status='verified' THEN 1 ELSE 0 END) verified_sources,
      MAX(GREATEST(COALESCE(pc.last_verified_at,'1970-01-01'),COALESCE(e.checked_at,'1970-01-01'),COALESCE(p.last_reviewed_at,'1970-01-01'))) source_data_max_date
      FROM products p
      LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL
      LEFT JOIN evidence_sources e ON e.product_id=p.id
      WHERE p.status='active'")->fetch(PDO::FETCH_ASSOC) ?: [];

    $products=(int)($summary['sample_products']??0);
    $cats=(int)($summary['sample_categories']??0);
    $sources=(int)($summary['sample_evidence_sources']??0);
    $capRows=(int)($summary['capability_rows']??0);
    $known=(int)($summary['known_capability_rows']??0);
    $verified=(int)($summary['verified_sources']??0);
    $headline=[
      'capability_evidence_coverage_pct'=>$capRows?round($known*100/$capRows,1):0,
      'verified_source_share_pct'=>$sources?round($verified*100/$sources,1):0,
      'products'=>$products,
      'categories'=>$cats,
      'evidence_sources'=>$sources,
      'capability_rows'=>$capRows
    ];

    $catSql="SELECT c.slug dimension_key,c.name dimension_label,
      COUNT(DISTINCT p.id) products,
      COUNT(DISTINCT pc.id) capability_rows,
      SUM(CASE WHEN pc.support_status<>'not_yet_verified' THEN 1 ELSE 0 END) known_rows,
      ROUND(AVG(CASE WHEN pc.support_status<>'not_yet_verified' THEN pc.confidence_score END)*100,1) avg_known_confidence,
      COUNT(DISTINCT e.id) evidence_sources,
      SUM(CASE WHEN e.verification_status='verified' THEN 1 ELSE 0 END) verified_sources,
      MAX(GREATEST(COALESCE(pc.last_verified_at,'1970-01-01'),COALESCE(e.checked_at,'1970-01-01'),COALESCE(p.last_reviewed_at,'1970-01-01'))) freshest_at
      FROM categories c JOIN products p ON p.category_id=c.id AND p.status='active'
      LEFT JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL
      LEFT JOIN evidence_sources e ON e.product_id=p.id
      WHERE c.is_active=1 GROUP BY c.id,c.slug,c.name ORDER BY c.name";
    $rows=[];
    foreach($pdo->query($catSql,PDO::FETCH_ASSOC) as $r){
      $cr=(int)$r['capability_rows'];$kr=(int)$r['known_rows'];$es=(int)$r['evidence_sources'];$vs=(int)$r['verified_sources'];
      $rows[]=['dimension_type'=>'category','dimension_key'=>$r['dimension_key'],'dimension_label'=>$r['dimension_label'],'metrics'=>[
        'products'=>(int)$r['products'],'capability_rows'=>$cr,'known_rows'=>$kr,
        'coverage_pct'=>$cr?round($kr*100/$cr,1):0,'avg_known_confidence_pct'=>$r['avg_known_confidence']!==null?(float)$r['avg_known_confidence']:null,
        'evidence_sources'=>$es,'verified_sources'=>$vs,'verified_source_share_pct'=>$es?round($vs*100/$es,1):0,'freshest_at'=>$r['freshest_at']
      ]];
    }

    $today=date('Y-m-d');
    $pdo->beginTransaction();
    $st=$pdo->prepare("INSERT INTO research_report_snapshots(report_id,snapshot_date,period_start,period_end,sample_products,sample_categories,sample_evidence_sources,source_data_max_date,summary_json,status,published_at)
      VALUES(?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE sample_products=VALUES(sample_products),sample_categories=VALUES(sample_categories),sample_evidence_sources=VALUES(sample_evidence_sources),source_data_max_date=VALUES(source_data_max_date),summary_json=VALUES(summary_json),status=VALUES(status),published_at=VALUES(published_at),generated_at=CURRENT_TIMESTAMP");
    $status=$publish?'published':'draft';$published=$publish?date('Y-m-d H:i:s'):null;
    $st->execute([$report['id'],$today,null,$today,$products,$cats,$sources,$summary['source_data_max_date']?:null,json_encode($headline,JSON_UNESCAPED_SLASHES),$status,$published]);
    $sid=(int)$pdo->query("SELECT id FROM research_report_snapshots WHERE report_id=".(int)$report['id']." AND snapshot_date=".$pdo->quote($today))->fetchColumn();
    $pdo->prepare("DELETE FROM research_report_rows WHERE snapshot_id=?")->execute([$sid]);
    $ins=$pdo->prepare("INSERT INTO research_report_rows(snapshot_id,dimension_type,dimension_key,dimension_label,metrics_json,sort_order) VALUES(?,?,?,?,?,?)");
    $i=10;foreach($rows as $r){$ins->execute([$sid,$r['dimension_type'],$r['dimension_key'],$r['dimension_label'],json_encode($r['metrics'],JSON_UNESCAPED_SLASHES),$i]);$i+=10;}
    $pdo->commit();
    return self::snapshotById($pdo,$sid);
  }

  public static function latest(?PDO $pdo=null): ?array {$pdo=$pdo?:Db::pdo();$r=self::report($pdo);if(!$r)return null;$st=$pdo->prepare("SELECT id FROM research_report_snapshots WHERE report_id=? AND status='published' ORDER BY snapshot_date DESC,id DESC LIMIT 1");$st->execute([$r['id']]);$id=$st->fetchColumn();return $id?self::snapshotById($pdo,(int)$id):null;}
  private static function report(PDO $pdo): ?array {$st=$pdo->prepare("SELECT * FROM research_reports WHERE slug=? AND status='active' LIMIT 1");$st->execute([self::REPORT_SLUG]);$r=$st->fetch(PDO::FETCH_ASSOC);return $r?:null;}
  private static function snapshotById(PDO $pdo,int $id): array {$st=$pdo->prepare("SELECT s.*,r.slug report_slug,r.title,r.description,r.methodology_version FROM research_report_snapshots s JOIN research_reports r ON r.id=s.report_id WHERE s.id=?");$st->execute([$id]);$s=$st->fetch(PDO::FETCH_ASSOC);$s['summary']=json_decode($s['summary_json']??'{}',true)?:[];$q=$pdo->prepare("SELECT dimension_type,dimension_key,dimension_label,metrics_json FROM research_report_rows WHERE snapshot_id=? ORDER BY sort_order,dimension_label");$q->execute([$id]);$s['rows']=[];foreach($q as $r){$r['metrics']=json_decode($r['metrics_json']??'{}',true)?:[];unset($r['metrics_json']);$s['rows'][]=$r;}unset($s['summary_json']);return $s;}
}
