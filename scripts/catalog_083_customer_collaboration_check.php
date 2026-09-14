<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$migration = $root . '/db/mysql/083_add_customer_service_collaboration_categories.sql';
if (!is_file($migration)) {
    fwrite(STDERR, "Missing migration: {$migration}\n");
    exit(1);
}
$sql = file_get_contents($migration) ?: '';
$failures = [];
$require = static function (bool $ok, string $message) use (&$failures): void {
    if (!$ok) $failures[] = $message;
};

$categories = ['customer-service-contact-center','collaboration-communication'];
foreach ($categories as $slug) {
    $require(substr_count($sql, "'{$slug}'") >= 2, "Category {$slug} is not consistently defined/reused.");
}

$modules = ['customer-service-operations','contact-center-intelligence','collaboration-messaging','collaboration-meetings-calling'];
foreach ($modules as $slug) $require(strpos($sql, "'{$slug}'") !== false, "Missing module {$slug}.");

$capabilities = [
    'cs-case-ticket-management','cs-omnichannel-routing','cs-knowledge-management','cs-self-service',
    'cs-voice-contact-center','cs-workforce-optimization','cs-service-analytics','cs-ai-service-automation',
    'collab-team-messaging','collab-channels-spaces','collab-file-content','collab-enterprise-search',
    'collab-video-meetings','collab-enterprise-calling','collab-webinars-events','collab-app-integrations',
];
foreach ($capabilities as $slug) $require(strpos($sql, "'{$slug}'") !== false, "Missing capability {$slug}.");

$products = [
    'salesforce-service-cloud','freshdesk','genesys-cloud-cx','nice-cxone-mpower','dynamics-365-customer-service',
    'microsoft-teams','slack','zoom-workplace','google-workspace','webex-suite',
];
foreach ($products as $slug) {
    $require(substr_count($sql, "'{$slug}'") >= 2, "Product {$slug} is not consistently referenced.");
}

$require(strpos($sql, 'ON DUPLICATE KEY UPDATE') !== false, '083 must be idempotent.');
$require(strpos($sql, 'last_reviewed_at') !== false, 'Products must update last_reviewed_at.');
$require(strpos($sql, "'not_yet_verified'") !== false, 'Unreviewed facts must remain not_yet_verified.');
$require(strpos($sql, 'product_capability_evidence') !== false, 'Known facts must link to evidence.');
$require(strpos($sql, "1,'verified','high'") !== false, 'Evidence must be vendor-owned, verified and high confidence.');
$require(stripos($sql, 'g2.com') === false, 'G2 data must not be ingested.');
$require(stripos($sql, 'capterra') === false, 'Capterra data must not be ingested.');
$require(stripos($sql, 'preferred_vendor') === false, 'Catalog migration must not add preferred-vendor logic.');
$require(stripos($sql, 'fit_score') === false, 'Catalog migration must not alter Fit Score.');

preg_match_all("/\\('(?:[^']|'')+','(?:[^']|'')+','(?:supported|partially_supported)',[0-9.]+,(?:NULL|'(?:[^']|'')*'),'([^']+)'\\)/", $sql, $matches);
foreach ($matches[1] ?? [] as $url) {
    $require(substr_count($sql, "'{$url}'") >= 2, "Known fact source is not represented in evidence: {$url}");
}

$officialHosts = [
    'salesforce.com','help.salesforce.com','freshworks.com','genesys.com','nice.com','microsoft.com','learn.microsoft.com',
    'slack.com','zoom.com','news.zoom.com','workspace.google.com','webex.com','cisco.com','google.com'
];
preg_match_all("/'https:\\/\\/([^\\/']+)[^']*'/", $sql, $urls);
foreach ($urls[1] ?? [] as $host) {
    $host = strtolower($host);
    $ok = false;
    foreach ($officialHosts as $allowed) {
        if ($host === $allowed || str_ends_with($host, '.' . $allowed)) { $ok = true; break; }
    }
    $require($ok, "Unexpected non-first-party host in migration: {$host}");
}

$migrationFiles = glob($root . '/db/mysql/*.sql') ?: [];
foreach ($products as $slug) {
    $hits = 0;
    foreach ($migrationFiles as $file) {
        if ($file === $migration) continue;
        $text = file_get_contents($file) ?: '';
        if (strpos($text, "'{$slug}'") !== false) $hits++;
    }
    $require($hits === 0, "Potential duplicate product shell already exists for {$slug}.");
}

$require(strpos($sql, "SELECT p.id,i.id,'not_yet_verified',0") !== false, 'Integration support must remain unknown when not reviewed.');
$require(substr_count($sql, 'INSERT INTO categories') === 1, '083 should create/update categories in one controlled block.');
$require(substr_count($sql, 'INSERT INTO modules') === 1, '083 should create/update modules in one controlled block.');
$require(substr_count($sql, 'INSERT INTO capabilities') === 1, '083 should create/update capabilities in one controlled block.');

if ($failures !== []) {
    foreach ($failures as $failure) fwrite(STDERR, "FAIL: {$failure}\n");
    exit(1);
}

echo "Catalog 083 customer-service/collaboration contract passed.\n";
