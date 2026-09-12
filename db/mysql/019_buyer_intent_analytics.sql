-- TechSelectAI buyer intent analytics foundation
-- Stabilized for #264: make the consultations->industries FK safe on re-runs/partial installs.
SET NAMES utf8mb4;

ALTER TABLE consultations
  ADD COLUMN IF NOT EXISTS country_code CHAR(2) NULL AFTER category_id,
  ADD COLUMN IF NOT EXISTS industry_id BIGINT UNSIGNED NULL AFTER country_code,
  ADD COLUMN IF NOT EXISTS company_size_band VARCHAR(50) NULL AFTER industry_id,
  ADD COLUMN IF NOT EXISTS expected_users INT UNSIGNED NULL AFTER company_size_band,
  ADD KEY IF NOT EXISTS idx_consultation_intent_time (created_at, category_id),
  ADD KEY IF NOT EXISTS idx_consultation_country (country_code),
  ADD KEY IF NOT EXISTS idx_consultation_industry (industry_id);

-- InnoDB foreign-key names are schema-wide and ADD CONSTRAINT has no portable
-- IF NOT EXISTS. Detect an existing FK by the actual column relationship, not name.
SET @ts_has_consultation_industry_fk := (
  SELECT COUNT(*)
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'consultations'
    AND COLUMN_NAME = 'industry_id'
    AND REFERENCED_TABLE_NAME = 'industries'
    AND REFERENCED_COLUMN_NAME = 'id'
);
SET @ts_add_consultation_industry_fk := IF(
  @ts_has_consultation_industry_fk > 0,
  'SELECT 1',
  'ALTER TABLE consultations ADD CONSTRAINT fk_ts_consultations_industry_019 FOREIGN KEY (industry_id) REFERENCES industries(id) ON DELETE SET NULL'
);
PREPARE ts_stmt FROM @ts_add_consultation_industry_fk;
EXECUTE ts_stmt;
DEALLOCATE PREPARE ts_stmt;

CREATE TABLE IF NOT EXISTS buyer_intent_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  consultation_id BIGINT UNSIGNED NULL,
  event_type VARCHAR(40) NOT NULL,
  category_id BIGINT UNSIGNED NULL,
  product_id BIGINT UNSIGNED NULL,
  related_product_id BIGINT UNSIGNED NULL,
  route_path VARCHAR(255) NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_bie_time (occurred_at),
  KEY idx_bie_type_time (event_type, occurred_at),
  KEY idx_bie_product_time (product_id, occurred_at),
  KEY idx_bie_category_time (category_id, occurred_at),
  KEY idx_bie_user_time (user_id, occurred_at),
  CONSTRAINT fk_ts_bie_user_019 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_ts_bie_consultation_019 FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
  CONSTRAINT fk_ts_bie_category_019 FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  CONSTRAINT fk_ts_bie_product_019 FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
  CONSTRAINT fk_ts_bie_related_product_019 FOREIGN KEY (related_product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
