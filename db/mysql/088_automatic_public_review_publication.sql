-- TechSelectAI zero-touch Public Review Intelligence automation
-- Removes routine admin approval from source policy and publication flow while
-- preserving hard source exclusions and existing quality/safety publication gates.
SET NAMES utf8mb4;
START TRANSACTION;

-- Automatic publication must be enabled globally. Quality/safety thresholds remain unchanged.
INSERT INTO community_intelligence_auto_publish_settings(id,enabled)
VALUES(1,1)
ON DUPLICATE KEY UPDATE enabled=1;

-- Existing connectors waiting only for manual policy review become machine-permitted.
-- G2 and Capterra remain hard blocked regardless of source type or URL casing.
UPDATE public_review_connectors
SET policy_status=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'blocked' ELSE 'permitted' END,
    policy_checked_at=NOW(),
    policy_notes=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.'
      ELSE 'Permitted automatically by TechSelectAI machine source policy.' END,
    status=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'inactive' ELSE status END,
    next_run_at=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN NULL ELSE COALESCE(next_run_at,NOW()) END
WHERE policy_status='pending_review';

-- Existing public sources waiting only for routine manual policy review are also resolved automatically.
UPDATE public_review_sources
SET access_policy=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'blocked' ELSE 'permitted' END,
    access_policy_checked_at=NOW(),
    access_policy_notes=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.'
      ELSE 'Permitted automatically by TechSelectAI machine source policy.' END,
    status=CASE
      WHEN source_type IN ('g2','capterra')
        OR LOWER(source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'inactive' ELSE status END
WHERE access_policy='pending_review';

-- Migration 084 used this field as a system re-analysis lock after removing prohibited
-- G2/Capterra data. It must not require a human to clear it. A clean future analysis
-- still has to pass all automatic publication gates before becoming public.
UPDATE product_public_review_intelligence
SET auto_publish_manual_hold_reason=NULL
WHERE auto_publish_manual_hold_reason='Re-analysis required after G2/Capterra source exclusion.';

COMMIT;

-- Enforce the same machine policy for future connectors without an admin approval step.
DROP TRIGGER IF EXISTS trg_public_review_connector_auto_policy_bi;
CREATE TRIGGER trg_public_review_connector_auto_policy_bi
BEFORE INSERT ON public_review_connectors
FOR EACH ROW
SET NEW.policy_status = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'blocked' ELSE 'permitted' END,
    NEW.policy_checked_at = NOW(),
    NEW.policy_notes = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.'
      ELSE 'Permitted automatically by TechSelectAI machine source policy.' END,
    NEW.status = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'inactive' ELSE NEW.status END,
    NEW.next_run_at = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN NULL ELSE COALESCE(NEW.next_run_at,NOW()) END;

-- Enforce the same policy for future source records, including manually discovered sources.
DROP TRIGGER IF EXISTS trg_public_review_source_auto_policy_bi;
CREATE TRIGGER trg_public_review_source_auto_policy_bi
BEFORE INSERT ON public_review_sources
FOR EACH ROW
SET NEW.access_policy = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'blocked' ELSE 'permitted' END,
    NEW.access_policy_checked_at = NOW(),
    NEW.access_policy_notes = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.'
      ELSE COALESCE(NEW.access_policy_notes,'Permitted automatically by TechSelectAI machine source policy.') END,
    NEW.status = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'inactive' ELSE NEW.status END;
