-- Management-ready Software Decision Pack snapshots
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS decision_packs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  selection_project_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  narrative_json JSON NULL,
  snapshot_json JSON NULL,
  methodology_version VARCHAR(64) NULL,
  generated_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_decision_pack_project_user(selection_project_id,user_id),
  KEY idx_decision_pack_user(user_id,updated_at),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(selection_project_id) REFERENCES selection_projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
