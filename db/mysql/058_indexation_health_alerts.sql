-- Indexation health daily snapshots and alerts for #182 / #254
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS indexation_daily_snapshots (
  snapshot_date DATE NOT NULL PRIMARY KEY,
  total_urls INT UNSIGNED NOT NULL DEFAULT 0,
  strategic_urls INT UNSIGNED NOT NULL DEFAULT 0,
  indexed_strategic INT UNSIGNED NOT NULL DEFAULT 0,
  stuck_strategic INT UNSIGNED NOT NULL DEFAULT 0,
  technical_exclusions_strategic INT UNSIGNED NOT NULL DEFAULT 0,
  missing_sitemap_strategic INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS indexation_health_alerts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  alert_type VARCHAR(64) NOT NULL,
  severity VARCHAR(16) NOT NULL DEFAULT 'warning',
  alert_key VARCHAR(190) NOT NULL,
  message VARCHAR(1000) NOT NULL,
  detail_json JSON NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'open',
  first_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME NULL,
  UNIQUE KEY uq_indexation_alert_key(alert_key),
  KEY idx_indexation_alert_status(status,severity,last_seen_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
