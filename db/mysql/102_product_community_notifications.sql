-- Optional community notifications for product followers.
-- Community popularity/activity remains separate from evidence, Fit Score and ranking.
SET NAMES utf8mb4;
START TRANSACTION;

ALTER TABLE product_follows
  ADD COLUMN IF NOT EXISTS community_notifications TINYINT(1) NOT NULL DEFAULT 0 AFTER last_notified_at;

CREATE TABLE IF NOT EXISTS product_community_notification_deliveries(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  post_id BIGINT UNSIGNED NOT NULL,
  follow_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'pending',
  attempt_count INT UNSIGNED NOT NULL DEFAULT 0,
  attempted_at DATETIME NULL,
  sent_at DATETIME NULL,
  error_message VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_community_notification(post_id,follow_id),
  KEY idx_product_community_notification_status(status,created_at),
  FOREIGN KEY(post_id) REFERENCES product_community_posts(id) ON DELETE CASCADE,
  FOREIGN KEY(follow_id) REFERENCES product_follows(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
