-- Vendor/company profiles and multi-software commercial relationships
SET NAMES utf8mb4;

ALTER TABLE vendors
  ADD COLUMN IF NOT EXISTS legal_name VARCHAR(255) NULL AFTER name,
  ADD COLUMN IF NOT EXISTS headquarters_country_code CHAR(2) NULL AFTER website_url,
  ADD COLUMN IF NOT EXISTS company_type VARCHAR(64) NULL AFTER headquarters_country_code,
  ADD COLUMN IF NOT EXISTS verification_status VARCHAR(32) NOT NULL DEFAULT 'unverified' AFTER description,
  ADD COLUMN IF NOT EXISTS verified_at DATETIME NULL AFTER verification_status,
  ADD COLUMN IF NOT EXISTS verified_by_user_id BIGINT UNSIGNED NULL AFTER verified_at;

CREATE TABLE IF NOT EXISTS vendor_product_relationships (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vendor_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  relationship_type VARCHAR(48) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending_review',
  verification_status VARCHAR(32) NOT NULL DEFAULT 'unverified',
  valid_from DATE NULL,
  valid_until DATE NULL,
  evidence_source_url TEXT NULL,
  evidence_note TEXT NULL,
  verified_at DATETIME NULL,
  verified_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_vendor_product_relationship(vendor_id,product_id,relationship_type),
  KEY idx_vpr_product(product_id,status,verification_status),
  KEY idx_vpr_vendor(vendor_id,status,verification_status),
  FOREIGN KEY(vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(verified_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_relationship_territories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  relationship_id BIGINT UNSIGNED NOT NULL,
  territory_type VARCHAR(32) NOT NULL,
  territory_code VARCHAR(64) NOT NULL,
  territory_name VARCHAR(190) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_vrt_scope(relationship_id,territory_type,territory_code),
  KEY idx_vrt_lookup(territory_type,territory_code),
  FOREIGN KEY(relationship_id) REFERENCES vendor_product_relationships(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Existing product.vendor_id remains the canonical ownership link. Seed an explicit
-- software_owner relationship so ownership and representation can be queried uniformly.
INSERT INTO vendor_product_relationships(vendor_id,product_id,relationship_type,status,verification_status,evidence_note)
SELECT p.vendor_id,p.id,'software_owner','approved','verified','Migrated from canonical products.vendor_id ownership relationship.'
FROM products p
WHERE p.vendor_id IS NOT NULL
ON DUPLICATE KEY UPDATE status=VALUES(status),verification_status=VALUES(verification_status),evidence_note=VALUES(evidence_note);
