<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$m74 = $root . '/db/mysql/074_expand_major_categories_batch2.sql';
$m75 = $root . '/db/mysql/075_add_bmc_helix_itsm_catalog.sql';
foreach ([$m74, $m75] as $file) {
    if (!is_file($file)) {
        fwrite(STDERR, "Missing catalog migration: {$file}\n");
        exit(1);
    }
}
$sql74 = file_get_contents($m74) ?: '';
$sql75 = file_get_contents($m75) ?: '';
$combined = $sql74 . "\n" . $sql75;
$failures = [];
$require = static function (bool $ok, string $message) use (&$failures): void {
    if (!$ok) {
        $failures[] = $message;
    }
};

foreach ([$sql74, $sql75] as $sql) {
    $require(stripos($sql, 'INSERT INTO categories') === false, 'Batch must not create categories.');
    $require(stripos($sql, 'INSERT INTO modules') === false, 'Batch must not create modules.');
    $require(stripos($sql, 'INSERT INTO capabilities') === false, 'Batch must not create capabilities.');
}

// ManageEngine ServiceDesk Plus already exists from migration 010; 074 may enrich it but must not count it as a new shell.
$require(strpos($sql74, "'manageengine-servicedesk-plus'") !== false, 'Existing ManageEngine product enrichment must remain explicit.');

$newProducts = [
    'ukg-pro' => 'hr-hcm',
    'epicor-kinetic' => 'erp',
    'teamwork-com' => 'project-management',
    'thoughtspot-analytics' => 'business-intelligence-analytics',
    'trend-vision-one-endpoint-security' => 'endpoint-security',
    'druva-data-resilience-cloud' => 'backup-disaster-recovery',
    'bmc-helix-itsm' => 'itsm',
];
foreach ($newProducts as $slug => $category) {
    $require(substr_count($combined, "'{$slug}'") >= 2, "Product {$slug} is not consistently referenced.");
    $require(strpos($combined, "'{$category}'") !== false, "Category {$category} is not reused for {$slug}.");
}

$require(strpos($combined, 'ON DUPLICATE KEY UPDATE') !== false, 'Migrations must remain idempotent.');
$require(strpos($combined, 'last_reviewed_at') !== false, 'Products must update last_reviewed_at.');
$require(strpos($combined, "'not_yet_verified'") !== false, 'Unknown facts must remain not_yet_verified.');
$require(strpos($combined, 'product_capability_evidence') !== false, 'Known facts must link to evidence.');
$require(strpos($combined, "1,'verified','high'") !== false, 'Evidence must be vendor-owned, verified and high confidence.');
$require(stripos($combined, 'g2.com') === false, 'G2 data must not be ingested.');
$require(stripos($combined, 'capterra') === false, 'Capterra data must not be ingested.');

preg_match_all("/\('(?:[^']|'')+','(?:[^']|'')+','(?:supported|partially_supported)',[0-9.]+,(?:NULL|'(?:[^']|'')*'),'([^']+)'\)/", $combined, $matches);
foreach ($matches[1] ?? [] as $url) {
    $require(substr_count($combined, "'{$url}'") >= 2, "Known fact source is not represented in evidence: {$url}");
}

$officialHosts = [
    'manageengine.com', 'ukg.com', 'epicor.com', 'teamwork.com',
    'thoughtspot.com', 'trendmicro.com', 'druva.com', 'bmc.com'
];
preg_match_all("/'https:\/\/([^\/']+)[^']*'/", $combined, $urls);
foreach ($urls[1] ?? [] as $host) {
    $host = strtolower($host);
    $ok = false;
    foreach ($officialHosts as $allowed) {
        if ($host === $allowed || str_ends_with($host, '.' . $allowed)) {
            $ok = true;
            break;
        }
    }
    $require($ok, "Unexpected non-first-party host in migration: {$host}");
}

$migrationFiles = glob($root . '/db/mysql/*.sql') ?: [];
foreach (array_keys($newProducts) as $slug) {
    $hits = 0;
    foreach ($migrationFiles as $file) {
        if (in_array($file, [$m74, $m75], true)) {
            continue;
        }
        $text = file_get_contents($file) ?: '';
        if (strpos($text, "'{$slug}'") !== false) {
            $hits++;
        }
    }
    $require($hits === 0, "Potential duplicate product shell already exists for {$slug}.");
}

$require(strpos($sql75, "'bmc-helix-itsm'") !== false, '075 must add BMC Helix ITSM.');
$require(strpos($sql75, "'public-saas'") !== false, 'BMC OnDemand deployment must be represented.');
$require(strpos($sql75, "'on-premise'") !== false, 'BMC on-premise deployment must be represented.');
$require(strpos($combined, "SELECT p.id,i.id,'not_yet_verified',0") !== false, 'Integration support must remain unknown when not reviewed.');

if ($failures !== []) {
    foreach ($failures as $failure) {
        fwrite(STDERR, "FAIL: {$failure}\n");
    }
    exit(1);
}

echo "Catalog 074/075 cross-category contract passed.\n";
