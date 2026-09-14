<?php
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    fwrite(STDERR, "CLI only\n");
    exit(2);
}

require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/CommunitySourceCollectors.php';
require_once __DIR__.'/../app/lib/PublicReviewConnectorBootstrap.php';

$pdo=Db::pdo();
$summary=['bootstrap_products'=>0,'bootstrap_connectors_created'=>0,'bootstrap_connectors_existing'=>0,'apple_checked'=>0,'apple_matched'=>0,'apple_no_match'=>0,'bootstrap_errors'=>0,'connectors_run'=>0,'connector_errors'=>0,'products_analyzed'=>0,'analysis_errors'=>0,'items_processed'=>0,'purged'=>0];

// Ensure the active software catalog has machine-managed public feedback sources.
// This is idempotent: existing connectors are reused, and Apple catalog discovery is retried conservatively.
try {
    $bootstrap=PublicReviewConnectorBootstrap::ensure($pdo,8);
    $summary['bootstrap_products']=(int)($bootstrap['products_seen']??0);
    $summary['bootstrap_connectors_created']=(int)($bootstrap['connectors_created']??0);
    $summary['bootstrap_connectors_existing']=(int)($bootstrap['connectors_existing']??0);
    $summary['apple_checked']=(int)($bootstrap['apple_checked']??0);
    $summary['apple_matched']=(int)($bootstrap['apple_matched']??0);
    $summary['apple_no_match']=(int)($bootstrap['apple_no_match']??0);
    $summary['bootstrap_errors']=(int)($bootstrap['apple_errors']??0);
} catch (Throwable $e) {
    $summary['bootstrap_errors']++;
    fwrite(STDERR, 'Review source bootstrap failed: '.$e->getMessage().PHP_EOL);
}

// Collect every connector that is due. Machine source policy decides whether it is permitted.
foreach (CommunitySourceCollectors::due($pdo,50) as $connectorId) {
    try {
        CommunitySourceCollectors::run($pdo,(int)$connectorId);
        $summary['connectors_run']++;
    } catch (Throwable $e) {
        $summary['connector_errors']++;
        fwrite(STDERR, 'Connector '.$connectorId.' failed: '.$e->getMessage().PHP_EOL);
    }
}

// Analyze all newly collected permitted-source items. analyzeProduct() performs the
// automatic publication decision; no reviewer/admin approval is required when gates pass.
$products=$pdo->query("SELECT DISTINCT i.product_id FROM public_review_collected_items i JOIN public_review_sources s ON s.id=i.source_id WHERE i.processing_status='pending_analysis' AND i.analysis_text IS NOT NULL AND s.status='active' AND s.access_policy='permitted' ORDER BY i.product_id LIMIT 100")->fetchAll(PDO::FETCH_COLUMN);
foreach ($products as $productId) {
    try {
        $productProcessed=0;
        // Keep each AI analysis request bounded while allowing a normal hourly run to drain backlog.
        for($batch=0;$batch<4;$batch++){
            $result=CommunitySourceCollectors::analyzePending($pdo,(int)$productId,25);
            $processed=(int)($result['processed']??0);
            $summary['items_processed']+=$processed;
            $productProcessed+=$processed;
            if($processed<25)break;
        }
        if($productProcessed>0)$summary['products_analyzed']++;
    } catch (Throwable $e) {
        $summary['analysis_errors']++;
        fwrite(STDERR, 'Product '.$productId.' analysis failed: '.$e->getMessage().PHP_EOL);
    }
}

$summary['purged']=CommunitySourceCollectors::purgeExpiredText($pdo);
$summary['completed_at']=gmdate('c');
echo json_encode($summary,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
