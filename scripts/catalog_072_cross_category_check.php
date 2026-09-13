<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$m72 = $root . '/db/mysql/072_expand_major_categories_batch1.sql';
$m73 = $root . '/db/mysql/073_complete_bitdefender_cross_platform_evidence.sql';

foreach ([$m72, $m73] as $file) {
    if (!is_file($file)) {
        fwrite(STDERR, "Missing catalog migration: {$file}\n");
        exit(1);
    }
}

$sql72 = file_get_contents($m72) ?: '';
$sql73 = file_get_contents($m73) ?: '';
$combined = $sql72 . "\n" . $sql73;

$failures = [];
$require = static function (bool $ok, string $message) use (&$failures): void {
    if (!$ok) {
        $failures[] = $message;
    }
};

// This batch must reuse the existing taxonomy rather than creating parallel structures.
$require(stripos($sql72, 'INSERT INTO categories') === false, '072 must not create categories.');
$require(stripos($sql72, 'INSERT INTO modules') === false, '072 must not create modules.');
$require(stripos($sql72, 'INSERT INTO capabilities') === false, '072 must not create capabilities.');

$products = [
    'haloitsm' => 'itsm',
    'deel-hr' => 'hr-hcm',
    'sage-intacct' => 'erp',
    'basecamp' => 'project-management',
    'domo' => 'business-intelligence-analytics',
    'bitdefender-gravityzone-enterprise' => 'endpoint-security',
    'rubrik-security-cloud' => 'backup-disaster-recovery',
];

foreach ($products as $slug => $category) {
    $require(substr_count($sql72, "'{$slug}'") >= 2, "Product {$slug} is not consistently referenced.");
    $require(strpos($sql72, "'{$category}'") !== false, "Category {$category} is not reused for {$slug}.");
}

$require(strpos($sql72, 'ON DUPLICATE KEY UPDATE') !== false, '072 must remain idempotent.');
$require(strpos($sql72, 'last_reviewed_at') !== false, 'Products must update last_reviewed_at.');
$require(strpos($sql72, "'not_yet_verified'") !== false, 'Unverified facts must remain not_yet_verified.');
$require(strpos($sql72, 'product_capability_evidence') !== false, 'Known facts must be linked to evidence.');
$require(strpos($sql72, "1,'verified','high'") !== false, 'Evidence must be vendor-owned, verified and high confidence.');
$require(stripos($combined, 'g2.com') === false, 'G2 data must not be ingested.');
$require(stripos($combined, 'capterra') === false, 'Capterra data must not be ingested.');

// Every known fact source should be represented in official evidence either in 072 or the focused 073 completion migration.
preg_match_all("/\('(?:[^']|'')+','(?:[^']|'')+','(?:supported|partially_supported)',[0-9.]+,(?:NULL|'(?:[^']|'')*'),'([^']+)'\)/", $sql72, $matches);
foreach ($matches[1] ?? [] as $url) {
    $require(substr_count($combined, "'{$url}'") >= 2, "Known fact source is not represented in evidence: {$url}");
}

$officialHosts = [
    'usehalo.com', 'deel.com', 'developer.deel.com', 'sage.com', 'basecamp.com',
    'domo.com', 'domo-webflow.domo.com', 'bitdefender.com', 'rubrik.com'
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
    $require($ok, "Unexpected non-first-party host in catalog migration: {$host}");
}

$require(strpos($sql73, 'endpoint-cross-platform') !== false, '073 must complete the Bitdefender cross-platform evidence link.');
$require(strpos($sql73, 'gravityzone-platform') !== false, '073 must insert the GravityZone platform source.');

// Guard against duplicate shells elsewhere in the migration history.
$migrationFiles = glob($root . '/db/mysql/*.sql') ?: [];
foreach (array_keys($products) as $slug) {
    $otherHits = 0;
    foreach ($migrationFiles as $file) {
        if (in_array($file, [$m72, $m73], true)) {
            continue;
        }
        $text = file_get_contents($file) ?: '';
        if (strpos($text, "'{$slug}'") !== false) {
            $otherHits++;
        }
    }
    $require($otherHits === 0, "Potential duplicate product shell already exists for {$slug}.");
}

if ($failures !== []) {
    foreach ($failures as $failure) {
        fwrite(STDERR, "FAIL: {$failure}\n");
    }
    exit(1);
}

echo "Cross-category catalog contract passed.\n";
