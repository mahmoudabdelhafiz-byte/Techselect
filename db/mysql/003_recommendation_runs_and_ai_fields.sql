-- V1 run history + provisional AI extraction fields for MariaDB/MySQL
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS recommendation_runs(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  consultation_id BIGINT UNSIGNED NOT NULL,
  scoring_version VARCHAR(32) NOT NULL,
  input_snapshot JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_run_consultation(consultation_id,created_at),
  FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE consultation_recommendations
  ADD COLUMN IF NOT EXISTS recommendation_run_id BIGINT UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS snapshot_json JSON NULL;

-- The original V1 schema allowed only one product row per consultation/scoring version.
-- Replace that with per-run uniqueness so Refresh Recommendations creates history.
ALTER TABLE consultation_recommendations DROP INDEX uq_rec;
ALTER TABLE consultation_recommendations
  ADD CONSTRAINT fk_rec_run FOREIGN KEY(recommendation_run_id) REFERENCES recommendation_runs(id) ON DELETE CASCADE,
  ADD UNIQUE KEY uq_rec_run(recommendation_run_id,product_id),
  ADD KEY idx_rec_run(recommendation_run_id);

CREATE TABLE IF NOT EXISTS ai_extracted_fields(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  extraction_run_id BIGINT UNSIGNED NOT NULL,
  field_kind VARCHAR(40) NOT NULL,
  field_key VARCHAR(190) NOT NULL,
  normalized_value JSON NOT NULL,
  source_text TEXT,
  confidence_score DECIMAL(4,3),
  requires_confirmation TINYINT(1) NOT NULL DEFAULT 1,
  accepted_at DATETIME NULL,
  rejected_at DATETIME NULL,
  KEY idx_ai_field_run(extraction_run_id,field_kind),
  FOREIGN KEY(extraction_run_id) REFERENCES ai_extraction_runs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS consultation_messages(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  consultation_id BIGINT UNSIGNED NOT NULL,
  sender_type VARCHAR(32) NOT NULL,
  message_text TEXT NOT NULL,
  message_type VARCHAR(32) NOT NULL DEFAULT 'normal',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_message_timeline(consultation_id,created_at),
  FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
