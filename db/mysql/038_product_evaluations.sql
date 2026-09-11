-- TechSelectAI proprietary product evaluation foundation
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS evaluation_methodologies (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  version VARCHAR(32) NOT NULL UNIQUE,
  name VARCHAR(190) NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'draft',
  dimension_weights JSON NOT NULL,
  published_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_eval_method_status(status,published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_evaluations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  methodology_id BIGINT UNSIGNED NOT NULL,
  overall_score DECIMAL(4,2) NULL,
  confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  best_for TEXT NULL,
  limitations TEXT NULL,
  summary TEXT NULL,
  evidence_count INT UNSIGNED NOT NULL DEFAULT 0,
  evaluated_at DATETIME NULL,
  approved_at DATETIME NULL,
  published_at DATETIME NULL,
  approved_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_eval_version(product_id,methodology_id),
  KEY idx_product_eval_public(product_id,status,published_at),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(methodology_id) REFERENCES evaluation_methodologies(id),
  FOREIGN KEY(approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_evaluation_dimensions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  evaluation_id BIGINT UNSIGNED NOT NULL,
  dimension_key VARCHAR(64) NOT NULL,
  score DECIMAL(4,2) NULL,
  confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0,
  rationale TEXT NULL,
  evidence_count INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_eval_dimension(evaluation_id,dimension_key),
  KEY idx_eval_dimension_key(dimension_key,score),
  FOREIGN KEY(evaluation_id) REFERENCES product_evaluations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_evaluation_evidence (
  evaluation_dimension_id BIGINT UNSIGNED NOT NULL,
  evidence_source_id BIGINT UNSIGNED NOT NULL,
  relevance_weight DECIMAL(4,3) NOT NULL DEFAULT 1.000,
  evidence_note TEXT NULL,
  PRIMARY KEY(evaluation_dimension_id,evidence_source_id),
  FOREIGN KEY(evaluation_dimension_id) REFERENCES product_evaluation_dimensions(id) ON DELETE CASCADE,
  FOREIGN KEY(evidence_source_id) REFERENCES evidence_sources(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO evaluation_methodologies(version,name,description,status,dimension_weights,published_at)
VALUES(
  'product-v1.0',
  'TechSelectAI Product Evaluation v1.0',
  'Evidence-backed product-level evaluation kept separate from buyer-specific Fit Score.',
  'published',
  JSON_OBJECT(
    'usability',12,
    'implementation_complexity',10,
    'integration_depth',15,
    'administration_overhead',8,
    'value',10,
    'support_community',10,
    'security_compliance',15,
    'enterprise_suitability',10,
    'smb_suitability',5,
    'product_maturity',5
  ),
  CURRENT_TIMESTAMP
)
ON DUPLICATE KEY UPDATE
  name=VALUES(name),
  description=VALUES(description),
  dimension_weights=VALUES(dimension_weights);
