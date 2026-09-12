-- Conditional auto-publication policy for Public Review Intelligence.
-- Auto-publication remains separate from Fit Score, Product Evaluation and recommendation ranking.
SET NAMES utf8mb4;
START TRANSACTION;

ALTER TABLE product_public_review_intelligence
  ADD COLUMN IF NOT EXISTS publication_mode VARCHAR(24) NULL AFTER published_at,
  ADD COLUMN IF NOT EXISTS auto_publish_checked_at DATETIME NULL AFTER publication_mode,
  ADD COLUMN IF NOT EXISTS auto_publish_decision_json JSON NULL AFTER auto_publish_checked_at,
  ADD COLUMN IF NOT EXISTS auto_publish_hold_reason VARCHAR(255) NULL AFTER auto_publish_decision_json,
  ADD COLUMN IF NOT EXISTS auto_publish_manual_hold_reason VARCHAR(255) NULL AFTER auto_publish_hold_reason,
  ADD COLUMN IF NOT EXISTS auto_publish_candidate_json JSON NULL AFTER auto_publish_manual_hold_reason,
  ADD COLUMN IF NOT EXISTS previous_published_score DECIMAL(4,2) NULL AFTER auto_publish_candidate_json;

CREATE TABLE IF NOT EXISTS community_intelligence_auto_publish_settings (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  min_usable_sources INT NOT NULL DEFAULT 15,
  min_source_diversity INT NOT NULL DEFAULT 3,
  min_confidence DECIMAL(4,3) NOT NULL DEFAULT 0.750,
  max_single_domain_share DECIMAL(4,3) NOT NULL DEFAULT 0.500,
  min_recent_sources INT NOT NULL DEFAULT 5,
  recent_days INT NOT NULL DEFAULT 365,
  max_score_movement DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  extreme_low_score DECIMAL(4,2) NOT NULL DEFAULT 1.50,
  extreme_high_score DECIMAL(4,2) NOT NULL DEFAULT 4.80,
  max_suspicious_ratio DECIMAL(4,3) NOT NULL DEFAULT 0.350,
  updated_by_user_id BIGINT UNSIGNED NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_ci_auto_publish_singleton CHECK (id=1),
  FOREIGN KEY(updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO community_intelligence_auto_publish_settings(id)
VALUES(1)
ON DUPLICATE KEY UPDATE id=VALUES(id);

CREATE TABLE IF NOT EXISTS community_intelligence_auto_publish_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  analysis_run_id BIGINT UNSIGNED NULL,
  decision VARCHAR(32) NOT NULL,
  prior_published_score DECIMAL(4,2) NULL,
  candidate_score DECIMAL(4,2) NULL,
  gate_results_json JSON NOT NULL,
  policy_snapshot_json JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ci_auto_history_product(product_id,created_at),
  KEY idx_ci_auto_history_decision(decision,created_at),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(analysis_run_id) REFERENCES public_review_analysis_runs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
