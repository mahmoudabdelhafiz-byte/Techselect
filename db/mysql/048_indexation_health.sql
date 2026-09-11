-- Indexation health monitoring and sitemap coverage snapshots
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS indexation_url_health (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  canonical_url VARCHAR(1024) NOT NULL,
  path VARCHAR(768) NOT NULL,
  page_type VARCHAR(64) NOT NULL,
  priority_level VARCHAR(24) NOT NULL DEFAULT 'standard',
  sitemap_expected TINYINT(1) NOT NULL DEFAULT 1,
  sitemap_present TINYINT(1) NOT NULL DEFAULT 0,
  sitemap_lastmod DATETIME NULL,
  observed_http_status SMALLINT NULL,
  observed_canonical_url VARCHAR(1024) NULL,
  observed_meta_robots VARCHAR(255) NULL,
  robots_allowed TINYINT(1) NULL,
  index_state VARCHAR(48) NOT NULL DEFAULT 'unknown',
  index_state_source VARCHAR(48) NULL,
  discovered_at DATETIME NULL,
  last_crawled_at DATETIME NULL,
  last_indexed_at DATETIME NULL,
  last_checked_at DATETIME NULL,
  issue_codes_json JSON NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_indexation_health_path(path),
  KEY idx_index_state(index_state,priority_level),
  KEY idx_index_checked(last_checked_at),
  KEY idx_sitemap_gap(sitemap_expected,sitemap_present)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS indexation_health_runs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  source VARCHAR(48) NOT NULL DEFAULT 'internal_audit',
  total_known_urls INT UNSIGNED NOT NULL DEFAULT 0,
  sitemap_urls INT UNSIGNED NOT NULL DEFAULT 0,
  strategic_urls INT UNSIGNED NOT NULL DEFAULT 0,
  issue_count INT UNSIGNED NOT NULL DEFAULT 0,
  summary_json JSON NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_index_run_created(created_at),
  FOREIGN KEY(created_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS indexation_state_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  url_health_id BIGINT UNSIGNED NOT NULL,
  index_state VARCHAR(48) NOT NULL,
  source VARCHAR(48) NOT NULL,
  observed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  detail_json JSON NULL,
  KEY idx_index_history_url(url_health_id,observed_at),
  FOREIGN KEY(url_health_id) REFERENCES indexation_url_health(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
