-- Fix duplicate product capability facts caused by MariaDB UNIQUE-key NULL semantics.
-- Run after 005_enrich_cardiq_capabilities.sql.
-- Keeps the strongest / most recently verified generic (edition_id IS NULL) fact,
-- preserves evidence links, removes duplicates, and adds a NULL-safe uniqueness key.
SET NAMES utf8mb4;
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS pc_dedupe_map;
CREATE TEMPORARY TABLE pc_dedupe_map(
  row_id BIGINT UNSIGNED PRIMARY KEY,
  keeper_id BIGINT UNSIGNED NOT NULL
);

INSERT INTO pc_dedupe_map(row_id,keeper_id)
SELECT pc.id,
       (
         SELECT pc2.id
         FROM product_capabilities pc2
         WHERE pc2.product_id=pc.product_id
           AND pc2.capability_id=pc.capability_id
           AND pc2.edition_id IS NULL
         ORDER BY
           CASE pc2.support_status
             WHEN 'supported' THEN 100
             WHEN 'enterprise_only' THEN 90
             WHEN 'plan_dependent' THEN 80
             WHEN 'custom_configuration' THEN 70
             WHEN 'partially_supported' THEN 65
             WHEN 'addon' THEN 60
             WHEN 'third_party_integration' THEN 55
             WHEN 'unknown' THEN 40
             WHEN 'not_yet_verified' THEN 40
             WHEN 'not_supported' THEN 10
             ELSE 0
           END DESC,
           COALESCE(pc2.confidence_score,0) DESC,
           COALESCE(pc2.last_verified_at,'1000-01-01') DESC,
           pc2.id DESC
         LIMIT 1
       ) AS keeper_id
FROM product_capabilities pc
WHERE pc.edition_id IS NULL
  AND EXISTS(
    SELECT 1
    FROM product_capabilities x
    WHERE x.product_id=pc.product_id
      AND x.capability_id=pc.capability_id
      AND x.edition_id IS NULL
      AND x.id<>pc.id
  );

-- Preserve all evidence links on the surviving canonical row.
INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT m.keeper_id,e.evidence_source_id,e.is_primary,e.evidence_note
FROM pc_dedupe_map m
JOIN product_capability_evidence e ON e.product_capability_id=m.row_id
WHERE m.row_id<>m.keeper_id;

-- Remove evidence links from duplicate rows before deleting those rows.
DELETE e
FROM product_capability_evidence e
JOIN pc_dedupe_map m ON m.row_id=e.product_capability_id
WHERE m.row_id<>m.keeper_id;

-- Remove duplicate generic capability facts.
DELETE pc
FROM product_capabilities pc
JOIN pc_dedupe_map m ON m.row_id=pc.id
WHERE m.row_id<>m.keeper_id;

DROP TEMPORARY TABLE pc_dedupe_map;
COMMIT;

-- MariaDB treats NULL values as distinct inside ordinary UNIQUE keys.
-- Add a generated scope column so NULL edition_id maps to 0 and becomes unique.
ALTER TABLE product_capabilities
  ADD COLUMN edition_scope BIGINT UNSIGNED AS (IFNULL(edition_id,0)) PERSISTENT;

ALTER TABLE product_capabilities
  ADD UNIQUE KEY uq_product_cap_scope(product_id,capability_id,edition_scope);
