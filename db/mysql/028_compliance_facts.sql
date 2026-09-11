-- TechSelectAI canonical compliance taxonomy and product facts.
-- Taxonomy rows are neutral concepts only; this migration does not assert vendor compliance claims.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS compliance_standards (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  slug VARCHAR(190) NOT NULL UNIQUE,
  standard_type VARCHAR(40) NOT NULL DEFAULT 'standard',
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS product_compliance (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  compliance_standard_id BIGINT UNSIGNED NOT NULL,
  support_status VARCHAR(40) NOT NULL DEFAULT 'not_yet_verified',
  confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0,
  scope_notes TEXT NULL,
  source_url TEXT NULL,
  last_verified_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_compliance(product_id, compliance_standard_id),
  KEY idx_product_compliance_standard(compliance_standard_id, support_status, product_id),
  CONSTRAINT fk_product_compliance_product FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  CONSTRAINT fk_product_compliance_standard FOREIGN KEY(compliance_standard_id) REFERENCES compliance_standards(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO compliance_standards(name,slug,standard_type,description) VALUES
('ISO/IEC 27001','iso-27001','certification','Information security management system standard.'),
('SOC 2','soc-2','attestation','Service organization controls attestation framework.'),
('GDPR','gdpr','regulation','European Union General Data Protection Regulation.'),
('HIPAA','hipaa','regulation','United States health information privacy and security requirements.'),
('PCI DSS','pci-dss','standard','Payment Card Industry Data Security Standard.'),
('Saudi NCA Essential Cybersecurity Controls','saudi-nca-ecc','framework','Saudi National Cybersecurity Authority Essential Cybersecurity Controls.'),
('SAMA Cyber Security Framework','sama-cybersecurity-framework','framework','Saudi Central Bank Cyber Security Framework.')
ON DUPLICATE KEY UPDATE name=VALUES(name),standard_type=VALUES(standard_type),description=VALUES(description),is_active=1;
