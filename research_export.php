<?php
require_once __DIR__.'/app/lib/OriginalResearch.php';
$s=OriginalResearch::latest();if(!$s){http_response_code(404);exit('No published snapshot');}
$path=parse_url($_SERVER['REQUEST_URI']??'',PHP_URL_PATH)?:'';
if(str_ends_with($path,'.csv')){
 header('Content-Type: text/csv; charset=utf-8');header('Content-Disposition: attachment; filename="techselectai-software-evidence-benchmark-'.$s['snapshot_date'].'.csv"');
 $o=fopen('php://output','w');fputcsv($o,['snapshot_date','category','products','capability_rows','known_rows','coverage_pct','avg_known_confidence_pct','evidence_sources','verified_sources','verified_source_share_pct','freshest_at']);
 foreach($s['rows'] as $r){$m=$r['metrics'];fputcsv($o,[$s['snapshot_date'],$r['dimension_label'],$m['products']??0,$m['capability_rows']??0,$m['known_rows']??0,$m['coverage_pct']??0,$m['avg_known_confidence_pct']??'',$m['evidence_sources']??0,$m['verified_sources']??0,$m['verified_source_share_pct']??0,$m['freshest_at']??'']);}fclose($o);exit;
}
if(str_ends_with($path,'.svg')){
 header('Content-Type: image/svg+xml; charset=utf-8');$rows=array_slice($s['rows'],0,8);$w=900;$h=130+count($rows)*42;function sx($v){return htmlspecialchars((string)$v,ENT_XML1|ENT_QUOTES,'UTF-8');}
 echo '<svg xmlns="http://www.w3.org/2000/svg" width="'.$w.'" height="'.$h.'" viewBox="0 0 '.$w.' '.$h.'"><rect width="100%" height="100%" fill="white"/><style>text{font-family:Arial,sans-serif;fill:#172033}.t{font-size:24px;font-weight:700}.s{font-size:13px;fill:#64748b}.l{font-size:14px}.v{font-size:13px;font-weight:700}</style><text x="28" y="38" class="t">TechSelectAI Software Evidence Coverage Benchmark</text><text x="28" y="62" class="s">Snapshot '.sx($s['snapshot_date']).' · Coverage = known capability evidence / recorded capability rows</text>';
 $y=100;foreach($rows as $r){$m=$r['metrics'];$pct=max(0,min(100,(float)($m['coverage_pct']??0)));$bw=500*$pct/100;echo '<text x="28" y="'.($y+15).'" class="l">'.sx($r['dimension_label']).'</text><rect x="260" y="'.$y.'" width="500" height="18" rx="4" fill="#e2e8f0"/><rect x="260" y="'.$y.'" width="'.$bw.'" height="18" rx="4" fill="#319795"/><text x="775" y="'.($y+14).'" class="v">'.sx($pct).'%</text>';$y+=42;}echo '<text x="28" y="'.($h-20).'" class="s">Source: TechSelectAI original catalog/evidence data · techselectai.com/research/software-evidence-benchmark</text></svg>';exit;
}
http_response_code(404);echo 'Not found';