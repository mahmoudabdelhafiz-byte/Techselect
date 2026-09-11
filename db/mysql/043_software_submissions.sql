-- Public software suggestion / vendor submission workflow
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS product_aliases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  alias_name VARCHAR(190) NOT NULL,
  normalized_alias VARCHAR(190) NOT NULL,
  source VARCHAR(40) NOT NULL DEFAULT 'admin',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_alias(product_id,normalized_alias),
  KEY idx_product_alias_lookup(normalized_alias),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS software_submissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  submission_type VARCHAR(32) NOT NULL,
  product_name VARCHAR(190) NOT NULL,
  normalized_product_name VARCHAR(190) NOT NULL,
  vendor_name VARCHAR(190) NULL,
  official_website TEXT NULL,
  category_id BIGINT UNSIGNED NULL,
  short_description TEXT NULL,
  pricing_url TEXT NULL,
  documentation_url TEXT NULL,
  security_url TEXT NULL,
  integrations_url TEXT NULL,
  deployment_options TEXT NULL,
  submitter_email VARCHAR(254) NULL,
  supporting_notes TEXT NULL,
  reference_asset_url TEXT NULL,
  existing_product_id BIGINT UNSIGNED NULL,
  duplicate_reason VARCHAR(255) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'new',
  reviewer_notes TEXT NULL,
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_product_id BIGINT UNSIGNED NULL,
  ip_hash BINARY(32) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_submission_status(status,created_at),
  KEY idx_submission_name(normalized_product_name),
  FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY(existing_product_id) REFERENCES products(id) ON DELETE SET NULL,
  FOREIGN KEY(created_product_id) REFERENCES products(id) ON DELETE SET NULL,
  FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
