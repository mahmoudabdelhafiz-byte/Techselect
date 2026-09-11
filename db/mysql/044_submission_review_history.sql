-- Reviewer workflow/history for software submissions
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS software_submission_reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  submission_id BIGINT UNSIGNED NOT NULL,
  reviewer_user_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(40) NOT NULL,
  from_status VARCHAR(32) NULL,
  to_status VARCHAR(32) NOT NULL,
  notes TEXT NULL,
  linked_product_id BIGINT UNSIGNED NULL,
  snapshot_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_submission_review_submission(submission_id,created_at),
  FOREIGN KEY(submission_id) REFERENCES software_submissions(id) ON DELETE CASCADE,
  FOREIGN KEY(reviewer_user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY(linked_product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
