-- TechSelectAI vendor coverage + Public Review Intelligence publication policy
-- 1) Synchronize canonical software-owner relationships for every active catalog product.
-- 2) Mark curated canonical vendor identities as verified when an official website is present.
--    This is identity/catalog verification only; it is NOT a quality endorsement and does not affect Fit Score.
-- 3) Keep Community Intelligence auto-publication enabled behind the existing quality/safety gates.
-- 4) Hard-exclude G2 and Capterra from Public Review Intelligence.
SET NAMES utf8mb4;
START TRANSACTION;

-- Migration 042 only backfilled products that existed at that time. Keep the ownership
-- relationship synchronized for every product added since then.
INSERT INTO vendor_product_relationships(
  vendor_id,product_id,relationship_type,status,verification_status,
  evidence_source_url,evidence_note,verified_at
)
SELECT
  p.vendor_id,p.id,'software_owner','approved','verified',
  COALESCE(NULLIF(p.website_url,''),NULLIF(v.website_url,'')),
  'Canonical software owner synchronized from the curated TechSelectAI catalog. Vendor identity verification is not a recommendation or ranking signal.',
  NOW()
FROM products p
JOIN vendors v ON v.id=p.vendor_id
WHERE p.status='active' AND v.status='active' AND p.vendor_id IS NOT NULL
ON DUPLICATE KEY UPDATE
  status='approved',
  verification_status='verified',
  evidence_source_url=COALESCE(VALUES(evidence_source_url),vendor_product_relationships.evidence_source_url),
  evidence_note=VALUES(evidence_note),
  verified_at=COALESCE(vendor_product_relationships.verified_at,VALUES(verified_at));

-- All active canonical vendors in the curated catalog have an explicit official website.
-- verification_status here means the vendor identity/ownership association is verified;
-- it must never be used as a Fit Score bonus, preferred-vendor flag, or endorsement.
UPDATE vendors v
SET v.verification_status='verified',
    v.verified_at=COALESCE(v.verified_at,NOW())
WHERE v.status='active'
  AND NULLIF(TRIM(v.website_url),'') IS NOT NULL
  AND EXISTS(
    SELECT 1 FROM products p
    WHERE p.vendor_id=v.id AND p.status='active'
  );

-- Keep automatic publication on, but do not loosen any quality/safety thresholds.
INSERT INTO community_intelligence_auto_publish_settings(id,enabled)
VALUES(1,1)
ON DUPLICATE KEY UPDATE enabled=1;

-- G2 and Capterra are explicitly excluded from TechSelectAI Public Review Intelligence.
-- Quarantine both explicit source types and URLs that point to those domains.
UPDATE public_review_sources
SET access_policy='blocked',
    access_policy_checked_at=NOW(),
    access_policy_notes='Blocked by TechSelectAI policy: G2 and Capterra are excluded from Public Review Intelligence.',
    status='inactive'
WHERE source_type IN ('g2','capterra')
   OR LOWER(source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
   OR LOWER(source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)';

UPDATE public_review_connectors
SET policy_status='blocked',
    policy_checked_at=NOW(),
    policy_notes='Blocked by TechSelectAI policy: G2 and Capterra are excluded from Public Review Intelligence.',
    status='inactive',
    next_run_at=NULL
WHERE source_type IN ('g2','capterra')
   OR LOWER(base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
   OR LOWER(base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)';

-- If a currently published aggregate was built from an excluded source, remove it from
-- public display until a clean re-analysis is performed. Never silently reuse the score.
UPDATE product_public_review_intelligence pri
JOIN public_review_signals sg ON sg.analysis_run_id=pri.analysis_run_id
JOIN public_review_sources s ON s.id=sg.source_id
SET pri.review_status='needs_review',
    pri.published_at=NULL,
    pri.publication_mode=NULL,
    pri.auto_publish_hold_reason='Re-analysis required after G2/Capterra source exclusion.',
    pri.auto_publish_manual_hold_reason='Re-analysis required after G2/Capterra source exclusion.'
WHERE s.source_type IN ('g2','capterra')
   OR LOWER(s.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
   OR LOWER(s.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)';

COMMIT;
