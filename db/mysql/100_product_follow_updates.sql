-- Product follow and semantic update notifications.
-- Follow state and notification delivery are separate from recommendation/Fit Score logic.
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS product_follows(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'active',
  unsubscribe_token CHAR(64) NOT NULL,
  followed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_notified_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_follow(user_id,product_id),
  UNIQUE KEY uq_product_follow_token(unsubscribe_token),
  KEY idx_product_follow_product_status(product_id,status),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_follow_snapshots(
  product_id BIGINT UNSIGNED PRIMARY KEY,
  semantic_hash CHAR(64) NOT NULL,
  snapshot_json LONGTEXT NOT NULL,
  checked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_update_events(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  previous_hash CHAR(64) NOT NULL,
  current_hash CHAR(64) NOT NULL,
  change_summary TEXT NOT NULL,
  detected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_update_hash(product_id,current_hash),
  KEY idx_product_update_detected(product_id,detected_at),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_update_deliveries(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  event_id BIGINT UNSIGNED NOT NULL,
  follow_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'pending',
  attempted_at DATETIME NULL,
  sent_at DATETIME NULL,
  error_message VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_update_delivery(event_id,follow_id),
  KEY idx_product_update_delivery_status(status,created_at),
  FOREIGN KEY(event_id) REFERENCES product_update_events(id) ON DELETE CASCADE,
  FOREIGN KEY(follow_id) REFERENCES product_follows(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
