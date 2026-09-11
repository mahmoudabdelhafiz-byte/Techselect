CREATE TABLE IF NOT EXISTS seo_quality_gate_settings (
  setting_key VARCHAR(80) PRIMARY KEY,
  setting_value VARCHAR(255) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO seo_quality_gate_settings(setting_key,setting_value) VALUES
('min_indexable_body_chars','1400'),('min_noindex_body_chars','800'),('min_indexable_evidence','3'),('min_noindex_evidence','2'),
('min_indexable_sources','2'),('min_internal_links','2'),('min_rationale_chars','250'),('max_freshness_days','180'),
('near_duplicate_threshold','0.82')
ON DUPLICATE KEY UPDATE setting_value=setting_value;

CREATE TABLE IF NOT EXISTS seo_generated_pages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  page_type ENUM('software','comparison','alternatives','category','best_for','use_case','integration','other') NOT NULL,
  slug VARCHAR(220) NOT NULL,
  canonical_path VARCHAR(500) NOT NULL,
  intent_key VARCHAR(255) NOT NULL,
  title VARCHAR(255) NOT NULL,
  h1 VARCHAR(255) NOT NULL,
  meta_description VARCHAR(500) NULL,
  recommendation_text MEDIUMTEXT NULL,
  body_text MEDIUMTEXT NULL,
  evidence_count INT UNSIGNED NOT NULL DEFAULT 0,
  source_count INT UNSIGNED NOT NULL DEFAULT 0,
  evidence_fingerprint CHAR(64) NULL,
  internal_link_count INT UNSIGNED NOT NULL DEFAULT 0,
  last_reviewed_at DATETIME NULL,
  status ENUM('draft','published','archived') NOT NULL DEFAULT 'draft',
  quality_decision ENUM('pending','indexable','published_noindex','not_generated') NOT NULL DEFAULT 'pending',
  quality_score DECIMAL(5,2) NULL,
  gate_reasons_json JSON NULL,
  canonical_target_path VARCHAR(500) NULL,
  last_gate_run_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_seo_generated_page_path(canonical_path),
  KEY idx_seo_generated_page_decision(quality_decision,status),
  KEY idx_seo_generated_page_intent(intent_key),
  KEY idx_seo_generated_page_type(page_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS seo_quality_gate_runs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  page_id BIGINT UNSIGNED NOT NULL,
  decision ENUM('indexable','published_noindex','not_generated') NOT NULL,
  score DECIMAL(5,2) NOT NULL,
  reasons_json JSON NOT NULL,
  canonical_target_path VARCHAR(500) NULL,
  thresholds_json JSON NOT NULL,
  run_by_user_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_seo_gate_run_page FOREIGN KEY(page_id) REFERENCES seo_generated_pages(id) ON DELETE CASCADE,
  CONSTRAINT fk_seo_gate_run_user FOREIGN KEY(run_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
  KEY idx_seo_gate_run_page(page_id,created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;