-- TechSelectAI Public Community Intelligence enrichment
SET NAMES utf8mb4;

ALTER TABLE public_review_signals
  ADD COLUMN IF NOT EXISTS themes_json JSON NULL AFTER topic_json,
  ADD COLUMN IF NOT EXISTS source_quality DECIMAL(4,3) NOT NULL DEFAULT 0.500 AFTER source_confidence,
  ADD COLUMN IF NOT EXISTS independence_score DECIMAL(4,3) NOT NULL DEFAULT 0.500 AFTER source_quality,
  ADD COLUMN IF NOT EXISTS specificity_score DECIMAL(4,3) NOT NULL DEFAULT 0.500 AFTER independence_score,
  ADD COLUMN IF NOT EXISTS affiliate_suspected TINYINT(1) NOT NULL DEFAULT 0 AFTER spam_suspected,
  ADD COLUMN IF NOT EXISTS vendor_promotion_suspected TINYINT(1) NOT NULL DEFAULT 0 AFTER affiliate_suspected,
  ADD COLUMN IF NOT EXISTS bot_suspected TINYINT(1) NOT NULL DEFAULT 0 AFTER vendor_promotion_suspected,
  ADD COLUMN IF NOT EXISTS low_signal_suspected TINYINT(1) NOT NULL DEFAULT 0 AFTER bot_suspected,
  ADD COLUMN IF NOT EXISTS exclusion_reason VARCHAR(190) NULL AFTER low_signal_suspected,
  ADD COLUMN IF NOT EXISTS retrieved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER exclusion_reason;

ALTER TABLE product_public_review_intelligence
  ADD COLUMN IF NOT EXISTS themes_json JSON NULL AFTER concerns_json,
  ADD COLUMN IF NOT EXISTS source_mix_json JSON NULL AFTER themes_json,
  ADD COLUMN IF NOT EXISTS date_range_start DATETIME NULL AFTER source_mix_json,
  ADD COLUMN IF NOT EXISTS date_range_end DATETIME NULL AFTER date_range_start;
