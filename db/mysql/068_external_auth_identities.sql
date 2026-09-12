-- TechSelectAI external authentication identities (Google / Microsoft)
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS external_auth_identities (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  provider VARCHAR(32) NOT NULL,
  provider_subject VARCHAR(191) NOT NULL,
  provider_email VARCHAR(254) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at DATETIME NULL,
  UNIQUE KEY uq_ts_external_identity_provider_subject (provider,provider_subject),
  KEY idx_ts_external_identity_user (user_id),
  CONSTRAINT fk_ts_external_identity_user_068 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
