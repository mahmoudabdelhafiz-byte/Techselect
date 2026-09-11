-- #139 External authority outreach campaign execution
SET NAMES utf8mb4;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS authority_campaigns (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  asset_path VARCHAR(512) NOT NULL,
  objective VARCHAR(500) NOT NULL,
  target_audience VARCHAR(500) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  starts_at DATETIME NULL,
  ends_at DATETIME NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_authority_campaign_status(status,starts_at),
  CONSTRAINT fk_authority_campaign_created_by FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS authority_campaign_targets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  campaign_id BIGINT UNSIGNED NOT NULL,
  authority_source_id BIGINT UNSIGNED NOT NULL,
  priority_score DECIMAL(5,2) NOT NULL DEFAULT 0,
  angle VARCHAR(500) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'queued',
  next_action_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_authority_campaign_target(campaign_id,authority_source_id),
  KEY idx_authority_campaign_target_queue(campaign_id,status,priority_score),
  CONSTRAINT fk_authority_campaign_target_campaign FOREIGN KEY(campaign_id) REFERENCES authority_campaigns(id) ON DELETE CASCADE,
  CONSTRAINT fk_authority_campaign_target_source FOREIGN KEY(authority_source_id) REFERENCES authority_sources(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS authority_outreach_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  campaign_target_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(32) NOT NULL,
  channel VARCHAR(32) NULL,
  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subject VARCHAR(255) NULL,
  notes TEXT NULL,
  external_reference VARCHAR(512) NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_authority_outreach_event_target(campaign_target_id,occurred_at),
  CONSTRAINT fk_authority_outreach_event_target FOREIGN KEY(campaign_target_id) REFERENCES authority_campaign_targets(id) ON DELETE CASCADE,
  CONSTRAINT fk_authority_outreach_event_actor FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
