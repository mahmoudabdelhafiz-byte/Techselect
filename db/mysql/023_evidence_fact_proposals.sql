-- Evidence refresh Phase 3: AI-extracted fact proposals for human review.
-- Approval in this phase never updates canonical product facts automatically.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS evidence_fact_proposals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidate_id BIGINT UNSIGNED NOT NULL,
  fact_domain VARCHAR(40) NOT NULL,
  field_key VARCHAR(120) NOT NULL,
  previous_value TEXT NULL,
  proposed_value TEXT NOT NULL,
  confidence DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
  rationale TEXT NULL,
  source_excerpt TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'proposed',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by_user_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  reviewed_by_user_id BIGINT UNSIGNED NULL,
  review_notes TEXT NULL,
  KEY idx_fact_proposal_candidate(candidate_id,status),
  KEY idx_fact_proposal_status_time(status,created_at),
  CONSTRAINT fk_fact_proposal_candidate FOREIGN KEY(candidate_id) REFERENCES evidence_change_candidates(id) ON DELETE CASCADE,
  CONSTRAINT fk_fact_proposal_creator FOREIGN KEY(created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_fact_proposal_reviewer FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
