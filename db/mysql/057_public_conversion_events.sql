-- Public conversion measurement for #13.
-- Measures contextual public-page CTA exposure/clicks without affecting scoring or rankings.
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS public_conversion_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  event_type ENUM('cta_impression','cta_click') NOT NULL,
  source_path VARCHAR(500) NOT NULL,
  source_type ENUM('software','category','capability','integration','comparison','other') NOT NULL DEFAULT 'other',
  context_key VARCHAR(255) NULL,
  cta_id VARCHAR(80) NOT NULL DEFAULT 'selection_journey',
  destination_path VARCHAR(700) NULL,
  session_hash BINARY(32) NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_public_conversion_time(occurred_at),
  INDEX idx_public_conversion_source(source_type,occurred_at),
  INDEX idx_public_conversion_cta(cta_id,event_type,occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
