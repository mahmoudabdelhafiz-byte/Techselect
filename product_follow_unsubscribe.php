<?php
require_once __DIR__.'/app/lib/Db.php';
require_once __DIR__.'/app/lib/ProductFollows.php';
$token=strtolower(trim((string)($_GET['token']??'')));
$row=ProductFollows::unsubscribeByToken(Db::pdo(),$token);
http_response_code($row?200:404);
$name=$row?htmlspecialchars((string)$row['product_name'],ENT_QUOTES,'UTF-8'):'this product';
$link=$row?'/software/'.htmlspecialchars((string)$row['product_slug'],ENT_QUOTES,'UTF-8'):'/software';
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,follow"><title><?= $row?'Unfollowed '.$name:'Invalid unsubscribe link' ?> | TechSelectAI</title><style>body{font-family:system-ui,-apple-system,sans-serif;background:#f8fafc;color:#172033;margin:0}.card{max-width:660px;margin:10vh auto;background:#fff;border:1px solid #dfe7ee;border-radius:18px;padding:32px;box-shadow:0 14px 40px rgba(15,23,42,.07)}a{color:#123b67;font-weight:750}p{line-height:1.65;color:#536174}</style></head><body><main class="card"><?php if($row): ?><h1>You’ve unfollowed <?= $name ?></h1><p>You will no longer receive TechSelectAI product-update emails for this product. This does not affect any other products you follow.</p><p><a href="<?= $link ?>">Return to the product page</a></p><?php else: ?><h1>Invalid or expired unsubscribe link</h1><p>This link could not be matched to a product follow.</p><p><a href="/software">Browse software</a></p><?php endif; ?></main></body></html>
