SET NAMES utf8mb4;

ALTER TABLE audit_logs
  ADD COLUMN IF NOT EXISTS outcome VARCHAR(32) NOT NULL DEFAULT 'success' AFTER entity_id;

ALTER TABLE audit_logs
  ADD INDEX IF NOT EXISTS idx_audit_actor_created(actor_user_id,created_at),
  ADD INDEX IF NOT EXISTS idx_audit_action_created(action,created_at),
  ADD INDEX IF NOT EXISTS idx_audit_entity_created(entity_type,entity_id,created_at),
  ADD INDEX IF NOT EXISTS idx_audit_outcome_created(outcome,created_at);
