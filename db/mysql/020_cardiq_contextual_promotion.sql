-- Contextual CardIQ promotion tracking. Separate from recommendation scoring.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS contextual_promotions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  consultation_id BIGINT UNSIGNED NOT NULL,
  visitor_session_id BIGINT UNSIGNED NULL,
  user_id BIGINT UNSIGNED NULL,
  promotion_key VARCHAR(80) NOT NULL,
  trigger_group VARCHAR(80) NOT NULL,
  relevance_score SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  event_type VARCHAR(32) NOT NULL,
  route_path VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_cp_consultation_event (consultation_id,event_type,created_at),
  KEY idx_cp_session_event (visitor_session_id,event_type,created_at),
  KEY idx_cp_user_event (user_id,event_type,created_at),
  KEY idx_cp_promotion_event (promotion_key,event_type,created_at),
  CONSTRAINT fk_cp_consultation FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE,
  CONSTRAINT fk_cp_session FOREIGN KEY (visitor_session_id) REFERENCES visitor_sessions(id) ON DELETE SET NULL,
  CONSTRAINT fk_cp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
