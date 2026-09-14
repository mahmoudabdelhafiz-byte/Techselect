-- Cross-category mobile access evaluation for TechSelectAI.
-- Unknown is not unsupported: every active product receives explicit not_yet_verified rows.
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS product_mobile_access (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  platform ENUM('android','ios','mobile_web') NOT NULL,
  support_status VARCHAR(40) NOT NULL DEFAULT 'not_yet_verified',
  scope_status ENUM('full','limited','role_specific','not_yet_verified') NOT NULL DEFAULT 'not_yet_verified',
  scope_notes TEXT NULL,
  evidence_url TEXT NULL,
  evidence_type ENUM('official_app_store','vendor_documentation','other_first_party','not_yet_verified') NOT NULL DEFAULT 'not_yet_verified',
  confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0.000,
  last_verified_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(id),
  UNIQUE KEY uq_product_mobile_platform(product_id,platform),
  KEY idx_mobile_platform_status(platform,support_status),
  CONSTRAINT fk_mobile_product FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p
CROSS JOIN (
  SELECT 'android' platform UNION ALL
  SELECT 'ios' UNION ALL
  SELECT 'mobile_web'
) x
WHERE p.status='active'
ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);

-- CardIQ Android app: official Google Play package supplied and already mapped for review ingestion.
UPDATE product_mobile_access pma
JOIN products p ON p.id=pma.product_id
SET pma.support_status='supported',
    pma.evidence_url='https://play.google.com/store/apps/details?id=com.card_iq.myapp&hl=en',
    pma.evidence_type='official_app_store',
    pma.confidence_score=0.990,
    pma.last_verified_at=NOW(),
    pma.scope_status='not_yet_verified',
    pma.scope_notes='Android application existence verified from the official Google Play listing; feature/function scope remains separately unverified.'
WHERE p.slug='cardiq' AND pma.platform='android';

COMMIT;
