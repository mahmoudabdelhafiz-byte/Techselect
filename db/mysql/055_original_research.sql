-- #179 Original research / authority reports
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS research_reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  slug VARCHAR(190) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  methodology_version VARCHAR(40) NOT NULL DEFAULT 'research-v1.0',
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS research_report_snapshots (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  report_id BIGINT UNSIGNED NOT NULL,
  snapshot_date DATE NOT NULL,
  period_start DATE NULL,
  period_end DATE NULL,
  sample_products INT NOT NULL DEFAULT 0,
  sample_categories INT NOT NULL DEFAULT 0,
  sample_evidence_sources INT NOT NULL DEFAULT 0,
  source_data_max_date DATETIME NULL,
  summary_json JSON NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  generated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  published_at DATETIME NULL,
  UNIQUE KEY uq_research_snapshot(report_id,snapshot_date),
  KEY idx_research_public(report_id,status,published_at),
  CONSTRAINT fk_research_snapshot_report FOREIGN KEY(report_id) REFERENCES research_reports(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS research_report_rows (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  snapshot_id BIGINT UNSIGNED NOT NULL,
  dimension_type VARCHAR(40) NOT NULL,
  dimension_key VARCHAR(190) NOT NULL,
  dimension_label VARCHAR(255) NOT NULL,
  metrics_json JSON NOT NULL,
  sort_order INT NOT NULL DEFAULT 100,
  UNIQUE KEY uq_research_row(snapshot_id,dimension_type,dimension_key),
  KEY idx_research_rows(snapshot_id,dimension_type,sort_order),
  CONSTRAINT fk_research_row_snapshot FOREIGN KEY(snapshot_id) REFERENCES research_report_snapshots(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO research_reports(slug,title,description,methodology_version,status)
VALUES('software-evidence-benchmark','TechSelectAI Software Evidence Coverage Benchmark','Original benchmark of software evidence coverage, verification confidence and freshness across the TechSelectAI catalog.','research-v1.0','active')
ON DUPLICATE KEY UPDATE title=VALUES(title),description=VALUES(description),methodology_version=VALUES(methodology_version),status='active';

COMMIT;