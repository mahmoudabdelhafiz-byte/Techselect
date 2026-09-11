CREATE TABLE IF NOT EXISTS search_console_imports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  source_label VARCHAR(80) NOT NULL,
  property_uri VARCHAR(255) NULL,
  date_from DATE NOT NULL,
  date_to DATE NOT NULL,
  row_count INT UNSIGNED NOT NULL DEFAULT 0,
  imported_by_user_id BIGINT UNSIGNED NULL,
  imported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sc_import_dates(date_from,date_to),
  INDEX idx_sc_import_source(source_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS search_console_performance (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  import_id BIGINT UNSIGNED NOT NULL,
  metric_date DATE NOT NULL,
  query_text VARCHAR(700) NOT NULL DEFAULT '',
  page_url VARCHAR(1000) NOT NULL DEFAULT '',
  country_code VARCHAR(8) NOT NULL DEFAULT '',
  device_type VARCHAR(32) NOT NULL DEFAULT '',
  search_appearance VARCHAR(120) NOT NULL DEFAULT '',
  clicks DECIMAL(16,4) NOT NULL DEFAULT 0,
  impressions DECIMAL(16,4) NOT NULL DEFAULT 0,
  ctr DECIMAL(12,8) NOT NULL DEFAULT 0,
  position DECIMAL(12,4) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sc_perf_import FOREIGN KEY(import_id) REFERENCES search_console_imports(id) ON DELETE CASCADE,
  INDEX idx_sc_perf_date(metric_date),
  INDEX idx_sc_perf_page_date(page_url(191),metric_date),
  INDEX idx_sc_perf_query_date(query_text(191),metric_date),
  INDEX idx_sc_perf_country(country_code),
  INDEX idx_sc_perf_device(device_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;