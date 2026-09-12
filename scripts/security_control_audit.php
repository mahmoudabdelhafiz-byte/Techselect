<?php
/**
 * Static security-control audit for API files.
 *
 * This does not prove authorization correctness; it prevents new mutation-capable
 * endpoints from silently omitting the common transport protections used by
 * TechSelectAI. Exceptions must be explicit and documented here.
 */
$root = dirname(__DIR__);
$files = glob($root.'/api/*.php') ?: [];
$errors = [];
$rows = [];

$exceptions = [
    // Auth endpoints are anonymous/token-based by design. Individual POST routes
    // enforce same-origin + per-route rate limits; CSRF is required only where a
    // logged-in session is being mutated (logout).
    'auth.php' => ['csrf' => 'mixed anonymous/token-based auth routes'],
    // Anonymous conversion analytics accepts sendBeacon events. It must remain
    // same-origin/rate-limited but does not mutate authenticated user state.
    'public_conversion.php' => ['csrf' => 'anonymous analytics beacon'],
];

foreach ($files as $file) {
    $name = basename($file);
    $src = file_get_contents($file) ?: '';
    $mutation = preg_match("/method\s*===?\s*['\"](?:POST|PUT|PATCH|DELETE)['\"]/i", $src)
        || preg_match("/REQUEST_METHOD.*(?:POST|PUT|PATCH|DELETE)/is", $src);
    if (!$mutation) {
        continue;
    }

    $checks = [
        'same_origin' => str_contains($src, 'Security::sameOrigin'),
        'csrf' => str_contains($src, 'Security::requireCsrf'),
        'rate_limit' => str_contains($src, 'Security::rateLimit'),
    ];

    foreach ($checks as $check => $ok) {
        $key = $check === 'same_origin' ? 'origin' : ($check === 'rate_limit' ? 'rate' : 'csrf');
        if (!$ok && empty($exceptions[$name][$key])) {
            $errors[] = $name.' missing '.$check;
        }
    }
    $rows[] = [$name, $checks];
}

foreach ($rows as [$name, $checks]) {
    echo sprintf(
        "%-38s origin=%s csrf=%s rate=%s\n",
        $name,
        $checks['same_origin'] ? 'yes' : (isset($exceptions[$name]['origin']) ? 'exception' : 'NO'),
        $checks['csrf'] ? 'yes' : (isset($exceptions[$name]['csrf']) ? 'exception' : 'NO'),
        $checks['rate_limit'] ? 'yes' : (isset($exceptions[$name]['rate']) ? 'exception' : 'NO')
    );
}

if ($errors) {
    fwrite(STDERR, "\nSecurity-control audit failed:\n- ".implode("\n- ", $errors)."\n");
    exit(1);
}

echo "\nSecurity-control audit passed.\n";
