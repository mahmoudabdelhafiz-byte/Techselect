-- TechSelectAI AI Business Case Builder foundation
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS business_cases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  consultation_id BIGINT UNSIGNED NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  version INT UNSIGNED NOT NULL DEFAULT 1,
  assumptions_json JSON NULL,
  verified_facts_json JSON NULL,
  generated_output_json JSON NULL,
  model_provider VARCHAR(50) NULL,
  model_name VARCHAR(100) NULL,
  prompt_version VARCHAR(32) NULL,
  generated_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_bc_user_time(user_id,updated_at),
  KEY idx_bc_consultation(consultation_id),
  KEY idx_bc_product(product_id),
  CONSTRAINT fk_bc_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_bc_consultation FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
  CONSTRAINT fk_bc_product FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS business_case_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_case_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(40) NOT NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_bce_case_time(business_case_id,occurred_at),
  KEY idx_bce_type_time(event_type,occurred_at),
  CONSTRAINT fk_bce_case FOREIGN KEY(business_case_id) REFERENCES business_cases(id) ON DELETE CASCADE,
  CONSTRAINT fk_bce_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
