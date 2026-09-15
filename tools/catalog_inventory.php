<?php
require_once __DIR__.'/../app/lib/Db.php';
require_once __DIR__.'/../app/lib/CatalogInventory.php';

if (PHP_SAPI !== 'cli') {
  http_response_code(404);
  exit;
}

try {
  $snapshot = CatalogInventory::snapshot(Db::pdo());
  echo json_encode($snapshot, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE).PHP_EOL;
} catch (Throwable $e) {
  fwrite(STDERR, 'Catalog inventory failed: '.$e->getMessage().PHP_EOL);
  exit(1);
}
