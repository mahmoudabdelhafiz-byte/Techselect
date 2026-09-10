-- TechSelectAI product logo metadata
-- Adds controlled, locally hosted logo references and source attribution.
-- Official vendor/product artwork should only be added when its source and permitted use are known.
SET NAMES utf8mb4;

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS logo_path VARCHAR(255) NULL AFTER website_url,
  ADD COLUMN IF NOT EXISTS logo_source_url TEXT NULL AFTER logo_path,
  ADD COLUMN IF NOT EXISTS logo_attribution VARCHAR(255) NULL AFTER logo_source_url,
  ADD COLUMN IF NOT EXISTS logo_last_verified_at DATETIME NULL AFTER logo_attribution;
