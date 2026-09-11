-- Community Intelligence publication approval workflow
SET NAMES utf8mb4;

ALTER TABLE product_public_review_intelligence
  ADD COLUMN IF NOT EXISTS review_status VARCHAR(32) NOT NULL DEFAULT 'draft' AFTER methodology_version,
  ADD COLUMN IF NOT EXISTS review_notes TEXT NULL AFTER review_status,
  ADD COLUMN IF NOT EXISTS reviewed_at DATETIME NULL AFTER review_notes,
  ADD COLUMN IF NOT EXISTS reviewed_by_user_id BIGINT UNSIGNED NULL AFTER reviewed_at,
  ADD COLUMN IF NOT EXISTS published_at DATETIME NULL AFTER reviewed_by_user_id,
  ADD KEY IF NOT EXISTS idx_pri_review_status(review_status,reviewed_at);

CREATE TABLE IF NOT EXISTS community_intelligence_review_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  intelligence_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(32) NOT NULL,
  notes TEXT NULL,
  snapshot_json JSON NOT NULL,
  reviewed_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ci_history_product(product_id,created_at),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(reviewed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;