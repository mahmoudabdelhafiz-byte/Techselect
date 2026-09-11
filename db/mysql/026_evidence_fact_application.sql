-- Evidence refresh Phase 4: controlled application of human-approved fact proposals.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS evidence_fact_applications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  proposal_id BIGINT UNSIGNED NOT NULL,
  candidate_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  evidence_source_id BIGINT UNSIGNED NOT NULL,
  target_domain VARCHAR(40) NOT NULL,
  target_slug VARCHAR(190) NOT NULL,
  target_field VARCHAR(80) NOT NULL,
  before_value JSON NULL,
  after_value JSON NOT NULL,
  application_notes TEXT NULL,
  applied_by_user_id BIGINT UNSIGNED NOT NULL,
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_evidence_fact_application_proposal(proposal_id),
  KEY idx_evidence_fact_application_product(product_id,applied_at),
  KEY idx_evidence_fact_application_candidate(candidate_id),
  CONSTRAINT fk_efa_proposal FOREIGN KEY(proposal_id) REFERENCES evidence_fact_proposals(id) ON DELETE CASCADE,
  CONSTRAINT fk_efa_candidate FOREIGN KEY(candidate_id) REFERENCES evidence_change_candidates(id) ON DELETE CASCADE,
  CONSTRAINT fk_efa_product FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_efa_source FOREIGN KEY(evidence_source_id) REFERENCES evidence_sources(id) ON DELETE CASCADE,
  CONSTRAINT fk_efa_user FOREIGN KEY(applied_by_user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
