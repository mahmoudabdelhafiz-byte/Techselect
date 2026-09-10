-- TechSelectAI first-party verified software reviews foundation
-- Keeps user reviews separate from recommendation fit scoring and Public Review Intelligence.
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS software_reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  overall_rating TINYINT UNSIGNED NOT NULL,
  ease_of_use_rating TINYINT UNSIGNED NULL,
  implementation_rating TINYINT UNSIGNED NULL,
  administration_rating TINYINT UNSIGNED NULL,
  support_rating TINYINT UNSIGNED NULL,
  value_for_money_rating TINYINT UNSIGNED NULL,
  feature_depth_rating TINYINT UNSIGNED NULL,
  integration_quality_rating TINYINT UNSIGNED NULL,
  reliability_rating TINYINT UNSIGNED NULL,
  would_recommend TINYINT(1) NULL,
  would_choose_again TINYINT(1) NULL,
  pros TEXT NULL,
  cons TEXT NULL,
  improvements TEXT NULL,
  reviewer_role VARCHAR(120) NULL,
  reviewer_industry VARCHAR(120) NULL,
  reviewer_country VARCHAR(80) NULL,
  company_size_band VARCHAR(50) NULL,
  usage_duration_band VARCHAR(50) NULL,
  deployment_model VARCHAR(80) NULL,
  implementation_duration_band VARCHAR(50) NULL,
  budget_outcome_band VARCHAR(50) NULL,
  implementation_difficulty VARCHAR(32) NULL,
  migration_complexity VARCHAR(32) NULL,
  public_identity_mode VARCHAR(32) NOT NULL DEFAULT 'anonymous_verified',
  moderation_status VARCHAR(32) NOT NULL DEFAULT 'pending',
  moderation_notes TEXT NULL,
  submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  moderated_at DATETIME NULL,
  published_at DATETIME NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review_user_product(user_id,product_id),
  KEY idx_review_product_status(product_id,moderation_status,published_at),
  KEY idx_review_user(user_id),
  CONSTRAINT chk_review_overall CHECK (overall_rating BETWEEN 1 AND 5),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS software_review_verifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  review_id BIGINT UNSIGNED NOT NULL,
  verification_level VARCHAR(40) NOT NULL,
  verification_status VARCHAR(24) NOT NULL DEFAULT 'pending',
  verification_reference_hash BINARY(32) NULL,
  verified_at DATETIME NULL,
  expires_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review_verification(review_id,verification_level),
  KEY idx_review_verification_status(verification_status,verification_level),
  FOREIGN KEY(review_id) REFERENCES software_reviews(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS software_review_risk_flags (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  review_id BIGINT UNSIGNED NOT NULL,
  flag_type VARCHAR(50) NOT NULL,
  severity VARCHAR(16) NOT NULL DEFAULT 'medium',
  status VARCHAR(24) NOT NULL DEFAULT 'open',
  details_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME NULL,
  KEY idx_review_risk(review_id,status),
  KEY idx_review_risk_type(flag_type,status),
  FOREIGN KEY(review_id) REFERENCES software_reviews(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS software_review_rewards (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  review_id BIGINT UNSIGNED NOT NULL,
  reward_type VARCHAR(50) NOT NULL,
  eligibility_status VARCHAR(24) NOT NULL DEFAULT 'pending',
  issuance_status VARCHAR(24) NOT NULL DEFAULT 'not_issued',
  reward_reference_hash BINARY(32) NULL,
  issued_at DATETIME NULL,
  redeemed_at DATETIME NULL,
  expires_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review_reward(review_id),
  KEY idx_review_reward_status(eligibility_status,issuance_status),
  FOREIGN KEY(review_id) REFERENCES software_reviews(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_verified_review_ratings (
  product_id BIGINT UNSIGNED PRIMARY KEY,
  rating_5 DECIMAL(4,2) NULL,
  approved_review_count INT NOT NULL DEFAULT 0,
  weighted_review_count DECIMAL(10,3) NOT NULL DEFAULT 0,
  verification_confidence DECIMAL(4,3) NOT NULL DEFAULT 0,
  methodology_version VARCHAR(32) NOT NULL,
  last_calculated_at DATETIME NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
