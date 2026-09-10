-- TechSelectAI taxonomy expansion queue for general AI consultant mode
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS taxonomy_expansion_queue (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  topic_key VARCHAR(160) NOT NULL,
  topic_label VARCHAR(180) NOT NULL,
  occurrence_count INT UNSIGNED NOT NULL DEFAULT 1,
  first_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  latest_example_request VARCHAR(1000) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'new',
  priority VARCHAR(16) NOT NULL DEFAULT 'normal',
  admin_notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_taxonomy_topic_key(topic_key),
  KEY idx_taxonomy_queue_status(status, priority, occurrence_count, last_seen_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS taxonomy_expansion_occurrences (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  queue_id BIGINT UNSIGNED NOT NULL,
  consultation_id BIGINT UNSIGNED NULL,
  example_request VARCHAR(1000) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_taxonomy_occurrence_queue(queue_id, created_at),
  KEY idx_taxonomy_occurrence_consultation(consultation_id),
  FOREIGN KEY(queue_id) REFERENCES taxonomy_expansion_queue(id) ON DELETE CASCADE,
  FOREIGN KEY(consultation_id) REFERENCES consultations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
