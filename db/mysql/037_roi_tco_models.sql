-- ROI/TCO modeling for #208
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS roi_tco_models (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  project_id BIGINT UNSIGNED NULL,
  product_id BIGINT UNSIGNED NULL,
  business_case_id BIGINT UNSIGNED NULL,
  title VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  horizon_years INT NOT NULL DEFAULT 3,
  assumptions_json JSON NOT NULL,
  verified_pricing_json JSON NULL,
  results_json JSON NOT NULL,
  scenario_json JSON NULL,
  source_snapshot_json JSON NULL,
  version INT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_roi_tco_user (user_id, updated_at),
  KEY idx_roi_tco_project (project_id),
  KEY idx_roi_tco_product (product_id),
  KEY idx_roi_tco_business_case (business_case_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES selection_projects(id) ON DELETE SET NULL,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
  FOREIGN KEY (business_case_id) REFERENCES business_cases(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
