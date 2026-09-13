<?php
$path = __DIR__ . '/../db/mysql/071_expand_identity_catalog_haystack_linq.sql';
if (!is_file($path)) {
    fwrite(STDERR, "Missing migration 071\n");
    exit(1);
}
$sql = file_get_contents($path);
$fail = static function (string $message): void {
    fwrite(STDERR, $message . "\n");
    exit(1);
};

foreach (['haystack', 'linq'] as $slug) {
    if (substr_count($sql, "'{$slug}'") < 4) {
        $fail("Expected repeated product slug {$slug}");
    }
}
if (stripos($sql, 'INSERT INTO categories') !== false || stripos($sql, 'INSERT INTO modules') !== false || stripos($sql, 'INSERT INTO capabilities') !== false) {
    $fail('Migration 071 must reuse the existing identity taxonomy');
}
foreach (['vendor_owned,verification_status,confidence', "'verified','high'", 'not_yet_verified', 'product_capability_evidence', 'last_reviewed_at', 'ON DUPLICATE KEY UPDATE'] as $needle) {
    if (strpos($sql, $needle) === false) {
        $fail("Missing catalog contract marker: {$needle}");
    }
}
if (preg_match('/g2\.com|capterra/i', $sql)) {
    $fail('Third-party review data is not allowed in this evidence-first migration');
}
if (substr_count($sql, "'supported'") < 12) {
    $fail('Expected a meaningful set of verified supported facts');
}
if (strpos($sql, "e.source_url=f.source_url") === false) {
    $fail('Known capability facts must link to exact evidence URLs');
}
if (strpos($sql, "d.slug='public-saas'") === false) {
    $fail('Expected explicit public SaaS deployment facts');
}
if (strpos($sql, 'thehaystackapp.com') === false || strpos($sql, 'linqapp.com') === false) {
    $fail('Expected official Haystack and Linq evidence domains');
}
if (strpos($sql, "'not_supported'") !== false) {
    $fail('Migration 071 must not infer unsupported from missing evidence');
}

$dir = __DIR__ . '/../db/mysql';
foreach (glob($dir . '/*.sql') as $file) {
    if (basename($file) === basename($path)) {
        continue;
    }
    $other = file_get_contents($file);
    foreach (["'haystack'", "'linq'"] as $slugLiteral) {
        if (strpos($other, $slugLiteral) !== false) {
            $fail('Potential duplicate product shell found outside migration 071: ' . basename($file) . ' contains ' . $slugLiteral);
        }
    }
}

echo "Catalog 071 identity expansion contract passed.\n";
