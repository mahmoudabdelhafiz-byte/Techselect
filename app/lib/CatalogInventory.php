<?php
final class CatalogInventory {
  public static function snapshot(PDO $pdo): array {
    $scalar = static function (string $sql) use ($pdo): int {
      $value = $pdo->query($sql)->fetchColumn();
      return (int)$value;
    };

    $categoryCounts = [
      'active' => $scalar("SELECT COUNT(*) FROM categories WHERE is_active=1"),
      'inactive' => $scalar("SELECT COUNT(*) FROM categories WHERE is_active=0"),
      'total' => $scalar("SELECT COUNT(*) FROM categories"),
    ];

    $productStatusRows = $pdo->query("SELECT status,COUNT(*) AS total FROM products GROUP BY status ORDER BY status")->fetchAll(PDO::FETCH_ASSOC);
    $productByStatus = [];
    foreach ($productStatusRows as $row) {
      $productByStatus[(string)$row['status']] = (int)$row['total'];
    }

    $vendorStatusRows = $pdo->query("SELECT status,COUNT(*) AS total FROM vendors GROUP BY status ORDER BY status")->fetchAll(PDO::FETCH_ASSOC);
    $vendorByStatus = [];
    foreach ($vendorStatusRows as $row) {
      $vendorByStatus[(string)$row['status']] = (int)$row['total'];
    }

    $categoryRows = $pdo->query(
      "SELECT c.id,c.name,c.slug,c.is_active,\n".
      "       SUM(CASE WHEN p.status='active' THEN 1 ELSE 0 END) AS active_products,\n".
      "       SUM(CASE WHEN p.status='draft' THEN 1 ELSE 0 END) AS draft_products,\n".
      "       SUM(CASE WHEN p.status='inactive' THEN 1 ELSE 0 END) AS inactive_products,\n".
      "       COUNT(p.id) AS total_products\n".
      "FROM categories c\n".
      "LEFT JOIN products p ON p.category_id=c.id\n".
      "GROUP BY c.id,c.name,c.slug,c.is_active\n".
      "ORDER BY c.is_active DESC,c.name"
    )->fetchAll(PDO::FETCH_ASSOC);

    foreach ($categoryRows as &$row) {
      $row['id'] = (int)$row['id'];
      $row['is_active'] = (bool)$row['is_active'];
      $row['active_products'] = (int)$row['active_products'];
      $row['draft_products'] = (int)$row['draft_products'];
      $row['inactive_products'] = (int)$row['inactive_products'];
      $row['total_products'] = (int)$row['total_products'];
    }
    unset($row);

    return [
      'generated_at_utc' => gmdate('c'),
      'categories' => $categoryCounts,
      'products' => [
        'total' => array_sum($productByStatus),
        'by_status' => $productByStatus,
      ],
      'vendors' => [
        'total' => array_sum($vendorByStatus),
        'by_status' => $vendorByStatus,
      ],
      'category_breakdown' => $categoryRows,
    ];
  }
}
