SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS user_plan_assignments (
  user_id BIGINT UNSIGNED NOT NULL,
  plan_code VARCHAR(40) NOT NULL DEFAULT 'free_registered',
  plan_status VARCHAR(24) NOT NULL DEFAULT 'active',
  starts_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NULL,
  source VARCHAR(40) NOT NULL DEFAULT 'system_default',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  KEY idx_user_plan (plan_code,plan_status,expires_at),
  CONSTRAINT fk_user_plan_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO user_plan_assignments(user_id,plan_code,plan_status,source)
SELECT u.id,'free_registered','active','migration_default'
FROM users u
LEFT JOIN user_plan_assignments p ON p.user_id=u.id
WHERE p.user_id IS NULL;

COMMIT;
