-- Buyer-specific shortlist and contextual decision matrix for #206
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS selection_project_matrix_runs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  scoring_version VARCHAR(64) NOT NULL,
  weights_json JSON NOT NULL,
  input_snapshot JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_matrix_runs_project (project_id, created_at),
  FOREIGN KEY (project_id) REFERENCES selection_projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS selection_project_shortlist (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  matrix_run_id BIGINT UNSIGNED NULL,
  shortlist_state VARCHAR(32) NOT NULL DEFAULT 'researching',
  project_fit_score DECIMAL(5,2) NULL,
  baseline_evaluation_score DECIMAL(5,2) NULL,
  mandatory_gap_count INT NOT NULL DEFAULT 0,
  score_breakdown_json JSON NULL,
  rationale_json JSON NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_project_shortlist (project_id, product_id),
  KEY idx_project_shortlist_state (project_id, shortlist_state),
  FOREIGN KEY (project_id) REFERENCES selection_projects(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY (matrix_run_id) REFERENCES selection_project_matrix_runs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
