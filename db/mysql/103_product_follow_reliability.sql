-- Product Follow reliability hardening.
-- Apply after 100_product_follow_updates.sql and 102_product_community_notifications.sql.
SET NAMES utf8mb4;
START TRANSACTION;

ALTER TABLE product_update_deliveries
  ADD COLUMN IF NOT EXISTS attempt_count INT UNSIGNED NOT NULL DEFAULT 0 AFTER status,
  ADD COLUMN IF NOT EXISTS next_attempt_at DATETIME NULL AFTER attempted_at;

SET @has_retry_idx=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='product_update_deliveries' AND index_name='idx_product_update_delivery_retry');
SET @sql_retry=IF(@has_retry_idx=0,'ALTER TABLE product_update_deliveries ADD INDEX idx_product_update_delivery_retry(status,next_attempt_at,attempt_count,created_at)','SELECT 1');
PREPARE stmt_retry FROM @sql_retry; EXECUTE stmt_retry; DEALLOCATE PREPARE stmt_retry;

-- A product may legitimately move A -> B -> A -> B over time. The former unique
-- (product_id,current_hash) key suppressed the second B event, so keep it indexed
-- for lookup but not unique.
SET @has_hash_uq=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='product_update_events' AND index_name='uq_product_update_hash');
SET @sql_drop_hash=IF(@has_hash_uq>0,'ALTER TABLE product_update_events DROP INDEX uq_product_update_hash','SELECT 1');
PREPARE stmt_drop_hash FROM @sql_drop_hash; EXECUTE stmt_drop_hash; DEALLOCATE PREPARE stmt_drop_hash;

SET @has_hash_idx=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='product_update_events' AND index_name='idx_product_update_hash');
SET @sql_add_hash=IF(@has_hash_idx=0,'ALTER TABLE product_update_events ADD INDEX idx_product_update_hash(product_id,current_hash)','SELECT 1');
PREPARE stmt_add_hash FROM @sql_add_hash; EXECUTE stmt_add_hash; DEALLOCATE PREPARE stmt_add_hash;

COMMIT;
