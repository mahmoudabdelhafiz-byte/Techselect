-- Product Community discussions, replies, helpful reactions and abuse reports.
-- Community activity is deliberately isolated from evidence, Fit Score and recommendation ranking.
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS product_community_posts(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  parent_id BIGINT UNSIGNED NULL,
  post_type VARCHAR(24) NOT NULL DEFAULT 'discussion',
  body TEXT NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'published',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_product_community_product_status(product_id,status,created_at),
  KEY idx_product_community_parent(parent_id,created_at),
  KEY idx_product_community_user(user_id,created_at),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(parent_id) REFERENCES product_community_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_community_helpful(
  post_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(post_id,user_id),
  KEY idx_product_community_helpful_user(user_id,created_at),
  FOREIGN KEY(post_id) REFERENCES product_community_posts(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_community_reports(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  post_id BIGINT UNSIGNED NOT NULL,
  reporter_user_id BIGINT UNSIGNED NOT NULL,
  reason VARCHAR(32) NOT NULL,
  details VARCHAR(1000) NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'open',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_community_reporter(post_id,reporter_user_id),
  KEY idx_product_community_report_status(status,created_at),
  FOREIGN KEY(post_id) REFERENCES product_community_posts(id) ON DELETE CASCADE,
  FOREIGN KEY(reporter_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
