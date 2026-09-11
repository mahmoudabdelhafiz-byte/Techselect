SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS authority_sources (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_name VARCHAR(180) NOT NULL,
  domain VARCHAR(255) NOT NULL,
  source_url VARCHAR(1024) NULL,
  source_type VARCHAR(40) NOT NULL,
  geography_code VARCHAR(10) NULL,
  relevance_score TINYINT UNSIGNED NOT NULL DEFAULT 3,
  authority_tier VARCHAR(20) NOT NULL DEFAULT 'medium',
  owner_user_id BIGINT UNSIGNED NULL,
  outreach_status VARCHAR(30) NOT NULL DEFAULT 'prospect',
  next_action VARCHAR(255) NULL,
  next_action_at DATETIME NULL,
  techselect_asset_path VARCHAR(512) NULL,
  intended_context VARCHAR(500) NULL,
  mention_requires_approval TINYINT(1) NOT NULL DEFAULT 0,
  mention_approved TINYINT(1) NOT NULL DEFAULT 0,
  approval_notes VARCHAR(500) NULL,
  published_url VARCHAR(1024) NULL,
  link_type VARCHAR(30) NULL,
  rel_attribute VARCHAR(80) NULL,
  backlink_status VARCHAR(20) NOT NULL DEFAULT 'not_published',
  first_verified_at DATETIME NULL,
  last_checked_at DATETIME NULL,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  updated_by BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_authority_domain_type (domain,source_type),
  KEY idx_authority_status (outreach_status,backlink_status),
  KEY idx_authority_next_action (next_action_at),
  KEY idx_authority_type (source_type),
  KEY idx_authority_domain (domain),
  CONSTRAINT fk_authority_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_authority_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_authority_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;