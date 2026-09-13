<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$migration = $root . '/db/mysql/076_expand_major_categories_batch3.sql';
if (!is_file($migration)) {
    fwrite(STDERR, "Missing migration: {$migration}\n");
    exit(1);
}
$sql = file_get_contents($migration) ?: '';
$failures = [];
$require = static function (bool $ok, string $message) use (&$failures): void {
    if (!$ok) $failures[] = $message;
};

$require(stripos($sql, 'INSERT INTO categories') === false, '076 must not create categories.');
$require(stripos($sql, 'INSERT INTO modules') === false, '076 must not create modules.');
$require(stripos($sql, 'INSERT INTO capabilities') === false, '076 must not create capabilities.');

$products = [
    'ivanti-neurons-itsm' => 'itsm',
    'adp-workforce-now' => 'hr-hcm',
    'infor-cloudsuite-industrial' => 'erp',
    'adobe-workfront' => 'project-management',
    'sisense' => 'business-intelligence-analytics',
    'eset-protect-enterprise' => 'endpoint-security',
    'veritas-netbackup' => 'backup-disaster-recovery',
];
foreach ($products as $slug => $category) {
    $require(substr_count($sql, "'{$slug}'") >= 2, "Product {$slug} is not consistently referenced.");
    $require(strpos($sql, "'{$category}'") !== false, "Category {$category} is not reused for {$slug}.");
}

$require(strpos($sql, 'ON DUPLICATE KEY UPDATE') !== false, '076 must be idempotent.');
$require(strpos($sql, 'last_reviewed_at') !== false, 'Products must update last_reviewed_at.');
$require(strpos($sql, "'not_yet_verified'") !== false, 'Unknown facts must remain not_yet_verified.');
$require(strpos($sql, 'product_capability_evidence') !== false, 'Known facts must link to evidence.');
$require(strpos($sql, "1,'verified','high'") !== false, 'Evidence must be vendor-owned, verified and high confidence.');
$require(stripos($sql, 'g2.com') === false, 'G2 data must not be ingested.');
$require(stripos($sql, 'capterra') === false, 'Capterra data must not be ingested.');

preg_match_all("/\('(?:[^']|'')+','(?:[^']|'')+','(?:supported|partially_supported)',[0-9.]+,(?:NULL|'(?:[^']|'')*'),'([^']+)'\)/", $sql, $matches);
foreach ($matches[1] ?? [] as $url) {
    $require(substr_count($sql, "'{$url}'") >= 2, "Known fact source is not represented in evidence: {$url}");
}

$officialHosts = ['ivanti.com','docs.ivanti.com','adp.com','infor.com','adobe.com','experienceleague.adobe.com','sisense.com','eset.com','veritas.com','origin-www.veritas.com'];
preg_match_all("/'https:\/\/([^\/']+)[^']*'/", $sql, $urls);
foreach ($urls[1] ?? [] as $host) {
    $host = strtolower($host);
    $ok = false;
    foreach ($officialHosts as $allowed) {
        if ($host === $allowed || str_ends_with($host, '.' . $allowed)) { $ok = true; break; }
    }
    $require($ok, "Unexpected non-first-party host in migration: {$host}");
}

$migrationFiles = glob($root . '/db/mysql/*.sql') ?: [];
foreach (array_keys($products) as $slug) {
    $hits = 0;
    foreach ($migrationFiles as $file) {
        if ($file === $migration) continue;
        $text = file_get_contents($file) ?: '';
        if (strpos($text, "'{$slug}'") !== false) $hits++;
    }
    $require($hits === 0, "Potential duplicate product shell already exists for {$slug}.");
}

$require(strpos($sql, "'public-saas'") !== false, '076 must include verified SaaS deployment facts.');
$require(strpos($sql, "'on-premise'") !== false, '076 must preserve verified on-premise deployment facts where applicable.');
$require(strpos($sql, "SELECT p.id,i.id,'not_yet_verified',0") !== false, 'Integration support must remain unknown when not reviewed.');

if ($failures !== []) {
    foreach ($failures as $failure) fwrite(STDERR, "FAIL: {$failure}\n");
    exit(1);
}

echo "Catalog 076 cross-category contract passed.\n";
