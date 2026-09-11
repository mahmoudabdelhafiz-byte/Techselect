-- Reusable software-selection project workspace for #205
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS selection_projects (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  consultation_id BIGINT UNSIGNED NULL,
  name VARCHAR(255) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  company_size_band VARCHAR(64) NULL,
  industry_text VARCHAR(190) NULL,
  country_codes_json JSON NULL,
  expected_users INT NULL,
  current_systems_json JSON NULL,
  deployment_preference VARCHAR(100) NULL,
  security_compliance_json JSON NULL,
  budget_min DECIMAL(14,2) NULL,
  budget_max DECIMAL(14,2) NULL,
  budget_currency CHAR(3) NULL,
  budget_period VARCHAR(50) NULL,
  implementation_capacity VARCHAR(100) NULL,
  implementation_timeline VARCHAR(100) NULL,
  support_requirements TEXT NULL,
  strategic_objectives TEXT NULL,
  version INT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_selection_projects_user (user_id, updated_at),
  KEY idx_selection_projects_consultation (consultation_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS selection_project_requirements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT UNSIGNED NOT NULL,
  capability_id BIGINT UNSIGNED NULL,
  requirement_text TEXT NOT NULL,
  normalized_requirement TEXT NULL,
  priority VARCHAR(32) NOT NULL DEFAULT 'preferred',
  is_mandatory TINYINT(1) NOT NULL DEFAULT 0,
  source VARCHAR(32) NOT NULL DEFAULT 'user_entered',
  user_confirmed TINYINT(1) NOT NULL DEFAULT 1,
  confidence_score DECIMAL(4,3) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_selection_req_project (project_id, is_mandatory, priority),
  KEY idx_selection_req_capability (capability_id),
  FOREIGN KEY (project_id) REFERENCES selection_projects(id) ON DELETE CASCADE,
  FOREIGN KEY (capability_id) REFERENCES capabilities(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS selection_project_integrations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id BIGINT UNSIGNED NOT NULL,
  integration_id BIGINT UNSIGNED NULL,
  integration_name VARCHAR(190) NOT NULL,
  priority VARCHAR(32) NOT NULL DEFAULT 'preferred',
  is_mandatory TINYINT(1) NOT NULL DEFAULT 0,
  source VARCHAR(32) NOT NULL DEFAULT 'user_entered',
  user_confirmed TINYINT(1) NOT NULL DEFAULT 1,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_selection_int_project (project_id, is_mandatory, priority),
  FOREIGN KEY (project_id) REFERENCES selection_projects(id) ON DELETE CASCADE,
  FOREIGN KEY (integration_id) REFERENCES integrations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
