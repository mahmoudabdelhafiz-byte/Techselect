<?php
require_once __DIR__.'/app/lib/Db.php';
require_once __DIR__.'/app/lib/ProductFollows.php';
$pdo=Db::pdo();
$method=$_SERVER['REQUEST_METHOD']??'GET';
$token=strtolower(trim((string)(($method==='POST'?($_POST['token']??''):($_GET['token']??'')))));
$row=ProductFollows::unsubscribeTarget($pdo,$token);
$confirmed=false;
if($method==='POST' && $row){
    $row=ProductFollows::unsubscribeByToken($pdo,$token);
    $confirmed=$row!==null;
}
http_response_code($row?200:404);
$name=$row?htmlspecialchars((string)$row['product_name'],ENT_QUOTES,'UTF-8'):'this product';
$link=$row?'/software/'.rawurlencode((string)$row['product_slug']):'/software';
$safeToken=htmlspecialchars($token,ENT_QUOTES,'UTF-8');
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,follow"><title><?= $confirmed?'Unfollowed '.$name:($row?'Confirm unfollow':'Invalid unsubscribe link') ?> | TechSelectAI</title><style>body{font-family:system-ui,-apple-system,sans-serif;background:#f8fafc;color:#172033;margin:0}.card{max-width:660px;margin:10vh auto;background:#fff;border:1px solid #dfe7ee;border-radius:18px;padding:32px;box-shadow:0 14px 40px rgba(15,23,42,.07)}a{color:#123b67;font-weight:750}p{line-height:1.65;color:#536174}.actions{display:flex;gap:12px;align-items:center;flex-wrap:wrap}.btn{appearance:none;border:0;border-radius:10px;padding:11px 16px;background:#123b67;color:#fff;font:inherit;font-weight:750;cursor:pointer}.secondary{color:#123b67;text-decoration:none}</style></head><body><main class="card"><?php if($confirmed): ?><h1>You’ve unfollowed <?= $name ?></h1><p>You will no longer receive TechSelectAI product-update emails for this product. This does not affect any other products you follow.</p><p><a href="<?= htmlspecialchars($link,ENT_QUOTES,'UTF-8') ?>">Return to the product page</a></p><?php elseif($row): ?><h1>Unfollow <?= $name ?>?</h1><p>This confirmation protects your subscription from email-security scanners and link preview tools that may open links automatically.</p><div class="actions"><form method="post" action="/product_follow_unsubscribe.php"><input type="hidden" name="token" value="<?= $safeToken ?>"><button class="btn" type="submit">Confirm unfollow</button></form><a class="secondary" href="<?= htmlspecialchars($link,ENT_QUOTES,'UTF-8') ?>">Keep following</a></div><?php else: ?><h1>Invalid or expired unsubscribe link</h1><p>This link could not be matched to a product follow.</p><p><a href="/software">Browse software</a></p><?php endif; ?></main></body></html>
