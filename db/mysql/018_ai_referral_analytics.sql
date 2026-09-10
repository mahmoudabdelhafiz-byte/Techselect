CREATE TABLE IF NOT EXISTS ai_referral_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_provider VARCHAR(40) NOT NULL,
  referrer_host VARCHAR(255) NOT NULL,
  referrer_path VARCHAR(512) NULL,
  landing_path VARCHAR(512) NOT NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ai_referral_source_time (source_provider, occurred_at),
  KEY idx_ai_referral_landing_time (landing_path(191), occurred_at),
  KEY idx_ai_referral_occurred_at (occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
