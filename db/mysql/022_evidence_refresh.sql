-- Evidence refresh Phase 1: source checks and human review candidates.
-- External source changes never update canonical product facts automatically.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS evidence_refresh_checks (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  evidence_source_id BIGINT UNSIGNED NOT NULL,
  source_url_hash BINARY(32) NOT NULL,
  http_status SMALLINT UNSIGNED NULL,
  content_fingerprint BINARY(32) NULL,
  change_state VARCHAR(32) NOT NULL,
  error_code VARCHAR(64) NULL,
  checked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_refresh_source_time(evidence_source_id,checked_at),
  KEY idx_refresh_state_time(change_state,checked_at),
  CONSTRAINT fk_refresh_check_source FOREIGN KEY(evidence_source_id) REFERENCES evidence_sources(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS evidence_change_candidates (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  evidence_source_id BIGINT UNSIGNED NOT NULL,
  previous_fingerprint BINARY(32) NULL,
  current_fingerprint BINARY(32) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending_review',
  detected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  review_notes TEXT NULL,
  UNIQUE KEY uq_pending_candidate(evidence_source_id,current_fingerprint,status),
  KEY idx_candidate_status_time(status,detected_at),
  CONSTRAINT fk_candidate_source FOREIGN KEY(evidence_source_id) REFERENCES evidence_sources(id) ON DELETE CASCADE,
  CONSTRAINT fk_candidate_reviewer FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
