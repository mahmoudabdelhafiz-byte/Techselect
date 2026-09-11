-- Verified vendor claim + scoped self-service update workflow
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_profile_claims (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vendor_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  verification_method VARCHAR(48) NOT NULL,
  company_email VARCHAR(254) NULL,
  evidence_url TEXT NULL,
  evidence_note TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending_review',
  reviewer_notes TEXT NULL,
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_vendor_claim_pending(vendor_id,user_id),
  KEY idx_vendor_claim_status(status,created_at),
  FOREIGN KEY(vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_memberships (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vendor_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  membership_role VARCHAR(32) NOT NULL DEFAULT 'vendor_editor',
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  source_claim_id BIGINT UNSIGNED NULL,
  verified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at DATETIME NULL,
  UNIQUE KEY uq_vendor_membership(vendor_id,user_id),
  KEY idx_vendor_membership_user(user_id,status),
  FOREIGN KEY(vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(source_claim_id) REFERENCES vendor_profile_claims(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_update_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vendor_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  requested_by_user_id BIGINT UNSIGNED NOT NULL,
  update_type VARCHAR(48) NOT NULL,
  field_key VARCHAR(64) NULL,
  current_value TEXT NULL,
  proposed_value TEXT NULL,
  evidence_url TEXT NULL,
  notes TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending_review',
  reviewer_notes TEXT NULL,
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_vendor_update_queue(status,created_at),
  KEY idx_vendor_update_vendor(vendor_id,status),
  FOREIGN KEY(vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(requested_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vendor_self_service_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity_type VARCHAR(32) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(48) NOT NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  before_json JSON NULL,
  after_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_vendor_ss_history(entity_type,entity_id,created_at),
  FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
