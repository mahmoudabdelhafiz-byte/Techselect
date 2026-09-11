-- RFP generator storage for #207
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS rfp_documents (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  matrix_run_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  selected_product_ids_json JSON NULL,
  source_snapshot_json JSON NOT NULL,
  sections_json JSON NOT NULL,
  version INT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_rfp_project (project_id, updated_at),
  KEY idx_rfp_user (user_id, updated_at),
  FOREIGN KEY (project_id) REFERENCES selection_projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (matrix_run_id) REFERENCES project_matrix_runs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
