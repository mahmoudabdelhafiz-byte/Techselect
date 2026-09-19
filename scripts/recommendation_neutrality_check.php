<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$recommendPath = $root . '/api/recommend.php';
$scoringPath = $root . '/app/lib/Scoring.php';
$promotionPath = $root . '/api/promotion.php';
$mainPath = $root . '/frontend/src/main.jsx';

$files = [$recommendPath, $scoringPath, $promotionPath, $mainPath];
foreach ($files as $file) {
    if (!is_file($file)) {
        fwrite(STDERR, "Missing neutrality dependency: {$file}\n");
        exit(1);
    }
}

$recommend = file_get_contents($recommendPath) ?: '';
$scoring = file_get_contents($scoringPath) ?: '';
$promotion = file_get_contents($promotionPath) ?: '';
$main = file_get_contents($mainPath) ?: '';
$failures = [];
$require = static function (bool $ok, string $message) use (&$failures): void {
    if (!$ok) $failures[] = $message;
};

// The scoring/ranking path must never know which products are related-party / Barmageyat-owned.
foreach (['cardiq', 'card iq', 'manpoweriq', 'manpower iq', 'barmageyat', 'CardIqPromotion', 'product_relationship_disclosures', 'related_party'] as $needle) {
    $require(stripos($recommend, $needle) === false, "Recommendation engine contains product/owner-specific token: {$needle}");
    $require(stripos($scoring, $needle) === false, "Scoring engine contains product/owner-specific token: {$needle}");
}

// No commercial-placement concepts belong in organic scoring or ranking.
foreach (['sponsor', 'promotion', 'preferred vendor', 'preferred_vendor', 'house product', 'score bonus', 'ranking bonus', 'boost'] as $needle) {
    $require(stripos($recommend, $needle) === false, "Recommendation engine contains placement/bias concept: {$needle}");
    $require(stripos($scoring, $needle) === false, "Scoring engine contains placement/bias concept: {$needle}");
}

// Ranking may use result metrics only, never product/vendor identity.
if (preg_match('/usort\(\$results,function\(\$a,\$b\)\{(.+?)\}\);/s', $recommend, $m)) {
    $sortBody = $m[1];
    foreach (['product', 'slug', 'name', 'vendor'] as $needle) {
        $require(stripos($sortBody, $needle) === false, "Ranking comparator references identity field: {$needle}");
    }
    foreach (['mandatory_gaps', 'mandatory', 'overall', 'evidence'] as $metric) {
        $require(strpos($sortBody, "['{$metric}']") !== false, "Expected neutral ranking metric missing: {$metric}");
    }
} else {
    $require(false, 'Could not locate recommendation ranking comparator.');
}

// The former consultation promotion endpoint stays backward compatible but must return no product placement.
$require(strpos($promotion, "['promotion'=>null,'retired'=>true]") !== false, 'Promotion endpoint must return no consultation promotion.');
$require(stripos($promotion, 'CardIqPromotion') === false, 'Promotion endpoint must not call the CardIQ promotion service.');
$require(strpos($main, "./consultationPromotion.js") === false, 'Frontend must not load product-specific consultation promotion UI.');

// Preserve methodology fundamentals: unknown is conservative, not unsupported.
$require(strpos($scoring, "'unknown'=>0.40") !== false, 'Unknown support must remain conservative rather than unsupported.');
$require(strpos($scoring, "'not_yet_verified'=>0.40") !== false, 'Not-yet-verified support must remain conservative rather than unsupported.');
$require(strpos($scoring, "'not_supported'=>0.00") !== false, 'Explicit not-supported facts must remain zero fit.');

if ($failures !== []) {
    foreach ($failures as $failure) fwrite(STDERR, "FAIL: {$failure}\n");
    exit(1);
}

echo "Recommendation neutrality contract passed: no related-party/house-product scoring or ranking path and no product-specific consultation promotion.\n";
