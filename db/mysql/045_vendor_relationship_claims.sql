-- Existing-software portfolio relationship claims and verification history
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_relationship_claims (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vendor_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  relationship_type VARCHAR(48) NOT NULL,
  territories_json JSON NOT NULL,
  territory_fingerprint CHAR(64) NOT NULL,
  evidence_type VARCHAR(48) NOT NULL,
  evidence_url TEXT NULL,
  evidence_reference VARCHAR(255) NULL,
  evidence_note TEXT NULL,
  submitter_email VARCHAR(254) NOT NULL,
  valid_from DATE NULL,
  valid_until DATE NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  reviewer_notes TEXT NULL,
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  relationship_id BIGINT UNSIGNED NULL,
  ip_hash BINARY(32) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_vrc_queue(status,created_at),
  KEY idx_vrc_vendor_product(vendor_id,product_id,relationship_type),
  KEY idx_vrc_fingerprint(territory_fingerprint),
  FOREIGN KEY(vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY(relationship_id) REFERENCES vendor_product_relationships(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_relationship_claim_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  claim_id BIGINT UNSIGNED NOT NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  action VARCHAR(48) NOT NULL,
  from_status VARCHAR(32) NULL,
  to_status VARCHAR(32) NOT NULL,
  note TEXT NULL,
  snapshot_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_vrch_claim(claim_id,created_at),
  FOREIGN KEY(claim_id) REFERENCES vendor_relationship_claims(id) ON DELETE CASCADE,
  FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
