-- TechSelectAI canonical country-level product availability facts.
-- Country rows are neutral taxonomy only; this migration does not assert vendor availability.
SET NAMES utf8mb4;

INSERT INTO countries(code,name) VALUES
('EG','Egypt'),
('SA','Saudi Arabia'),
('AE','United Arab Emirates')
ON DUPLICATE KEY UPDATE name=VALUES(name);

CREATE TABLE IF NOT EXISTS product_regional_availability (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  country_id BIGINT UNSIGNED NOT NULL,
  availability_status VARCHAR(40) NOT NULL DEFAULT 'not_yet_verified',
  confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0,
  availability_notes TEXT NULL,
  source_url TEXT NULL,
  last_verified_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_regional_availability(product_id,country_id),
  KEY idx_regional_country_status(country_id,availability_status,product_id),
  CONSTRAINT fk_regional_product FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_regional_country FOREIGN KEY(country_id) REFERENCES countries(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;