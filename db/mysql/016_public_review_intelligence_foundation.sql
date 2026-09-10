-- TechSelectAI Public Review Intelligence foundation
-- Stores permitted public-source metadata and derived AI analysis signals.
-- This data must remain separate from deterministic fit scoring and TechSelectAI verified reviews.
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS public_review_sources (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  source_url TEXT NOT NULL,
  source_url_hash BINARY(32) NOT NULL,
  source_type VARCHAR(50) NOT NULL,
  source_name VARCHAR(190) NULL,
  source_published_at DATETIME NULL,
  access_policy VARCHAR(32) NOT NULL DEFAULT 'pending_review',
  access_policy_checked_at DATETIME NULL,
  access_policy_notes TEXT NULL,
  content_fingerprint BINARY(32) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_public_review_source(product_id,source_url_hash),
  KEY idx_prs_product_status(product_id,status),
  KEY idx_prs_policy(access_policy,status),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS public_review_analysis_runs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  model_provider VARCHAR(50) NULL,
  model_name VARCHAR(100) NULL,
  analysis_version VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  source_count INT NOT NULL DEFAULT 0,
  eligible_source_count INT NOT NULL DEFAULT 0,
  excluded_source_count INT NOT NULL DEFAULT 0,
  started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  error_message TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_prar_product_created(product_id,created_at),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS public_review_signals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  source_id BIGINT UNSIGNED NOT NULL,
  analysis_run_id BIGINT UNSIGNED NOT NULL,
  sentiment_score DECIMAL(5,4) NULL,
  sentiment_label VARCHAR(24) NULL,
  public_rating DECIMAL(4,2) NULL,
  public_rating_scale DECIMAL(4,2) NULL,
  topic_json JSON NULL,
  reviewer_context_json JSON NULL,
  source_confidence DECIMAL(4,3) NOT NULL DEFAULT 0,
  duplicate_suspected TINYINT(1) NOT NULL DEFAULT 0,
  spam_suspected TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_prsignal_source_run(source_id,analysis_run_id),
  KEY idx_prsignal_run(analysis_run_id),
  FOREIGN KEY(source_id) REFERENCES public_review_sources(id) ON DELETE CASCADE,
  FOREIGN KEY(analysis_run_id) REFERENCES public_review_analysis_runs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_public_review_intelligence (
  product_id BIGINT UNSIGNED PRIMARY KEY,
  analysis_run_id BIGINT UNSIGNED NOT NULL,
  score_5 DECIMAL(4,2) NULL,
  positive_sentiment_pct DECIMAL(5,2) NULL,
  confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0,
  confidence_label VARCHAR(24) NOT NULL DEFAULT 'insufficient',
  sources_analyzed INT NOT NULL DEFAULT 0,
  source_type_count INT NOT NULL DEFAULT 0,
  insufficient_data TINYINT(1) NOT NULL DEFAULT 1,
  strengths_json JSON NULL,
  concerns_json JSON NULL,
  methodology_version VARCHAR(32) NOT NULL,
  last_analyzed_at DATETIME NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(analysis_run_id) REFERENCES public_review_analysis_runs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
