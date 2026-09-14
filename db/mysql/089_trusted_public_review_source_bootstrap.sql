-- TechSelectAI trusted zero-touch public-review source bootstrap policy.
-- Automatically permits only collector-backed public sources with known hosts while
-- keeping G2/Capterra blocked and unknown sources restricted.
SET NAMES utf8mb4;
START TRANSACTION;

-- Reclassify only records that were automatically permitted by migration 088.
-- Explicitly reviewed/admin-approved records are left unchanged unless prohibited.
UPDATE public_review_connectors
SET policy_status='restricted',
    policy_checked_at=NOW(),
    policy_notes='Restricted automatically: connector is not one of TechSelectAI trusted machine-collected public sources.',
    next_run_at=NULL
WHERE policy_status='permitted'
  AND policy_notes='Permitted automatically by TechSelectAI machine source policy.'
  AND NOT (
    (connector_type='stackexchange_api' AND LOWER(base_url) REGEXP '^https://api\\.stackexchange\\.com/') OR
    (connector_type='rss_atom' AND source_type='reddit' AND LOWER(base_url) REGEXP '^https://(www\\.|old\\.)?reddit\\.com/') OR
    (connector_type='hackernews_algolia_api' AND LOWER(base_url) REGEXP '^https://hn\\.algolia\\.com/') OR
    (connector_type='apple_app_store_reviews' AND LOWER(base_url) REGEXP '^https://itunes\\.apple\\.com/') OR
    (connector_type='google_play_developer_api' AND LOWER(base_url) REGEXP '^https://androidpublisher\\.googleapis\\.com/')
  );

UPDATE public_review_sources
SET access_policy='restricted',
    access_policy_checked_at=NOW(),
    access_policy_notes='Restricted automatically: source is not from a TechSelectAI trusted machine-collected public source.'
WHERE access_policy='permitted'
  AND (
    access_policy_notes='Permitted automatically by TechSelectAI machine source policy.' OR
    access_policy_notes LIKE 'Inherited from explicitly permitted connector #%'
  )
  AND NOT (
    (source_type='reddit' AND LOWER(source_url) REGEXP '^https://([^/]+\\.)?reddit\\.com/') OR
    (source_type='public_forum' AND (LOWER(source_url) REGEXP '^https://([^/]+\\.)?stackoverflow\\.com/' OR LOWER(source_url) REGEXP '^https://([^/]+\\.)?stackexchange\\.com/')) OR
    (source_type='other_public' AND LOWER(source_url) REGEXP '^https://news\\.ycombinator\\.com/') OR
    (source_type='app_store' AND (LOWER(source_url) REGEXP '^https://play\\.google\\.com/' OR LOWER(source_url) REGEXP '^https://apps\\.apple\\.com/' OR LOWER(source_url) REGEXP '^https://itunes\\.apple\\.com/'))
  );

-- G2 and Capterra remain hard-blocked regardless of any previous status.
UPDATE public_review_connectors
SET policy_status='blocked',policy_checked_at=NOW(),policy_notes='Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.',status='inactive',next_run_at=NULL
WHERE source_type IN ('g2','capterra')
   OR LOWER(base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
   OR LOWER(base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)';

UPDATE public_review_sources
SET access_policy='blocked',access_policy_checked_at=NOW(),access_policy_notes='Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.',status='inactive'
WHERE source_type IN ('g2','capterra')
   OR LOWER(source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
   OR LOWER(source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)';

COMMIT;

DROP TRIGGER IF EXISTS trg_public_review_connector_auto_policy_bi;
CREATE TRIGGER trg_public_review_connector_auto_policy_bi
BEFORE INSERT ON public_review_connectors
FOR EACH ROW
SET NEW.policy_status = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)' THEN 'blocked'
      WHEN (NEW.connector_type='stackexchange_api' AND LOWER(NEW.base_url) REGEXP '^https://api\\.stackexchange\\.com/')
        OR (NEW.connector_type='rss_atom' AND NEW.source_type='reddit' AND LOWER(NEW.base_url) REGEXP '^https://(www\\.|old\\.)?reddit\\.com/')
        OR (NEW.connector_type='hackernews_algolia_api' AND LOWER(NEW.base_url) REGEXP '^https://hn\\.algolia\\.com/')
        OR (NEW.connector_type='apple_app_store_reviews' AND LOWER(NEW.base_url) REGEXP '^https://itunes\\.apple\\.com/')
        OR (NEW.connector_type='google_play_developer_api' AND LOWER(NEW.base_url) REGEXP '^https://androidpublisher\\.googleapis\\.com/') THEN 'permitted'
      ELSE 'restricted' END,
    NEW.policy_checked_at = NOW(),
    NEW.policy_notes = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.'
      WHEN (NEW.connector_type='stackexchange_api' AND LOWER(NEW.base_url) REGEXP '^https://api\\.stackexchange\\.com/')
        OR (NEW.connector_type='rss_atom' AND NEW.source_type='reddit' AND LOWER(NEW.base_url) REGEXP '^https://(www\\.|old\\.)?reddit\\.com/')
        OR (NEW.connector_type='hackernews_algolia_api' AND LOWER(NEW.base_url) REGEXP '^https://hn\\.algolia\\.com/')
        OR (NEW.connector_type='apple_app_store_reviews' AND LOWER(NEW.base_url) REGEXP '^https://itunes\\.apple\\.com/')
        OR (NEW.connector_type='google_play_developer_api' AND LOWER(NEW.base_url) REGEXP '^https://androidpublisher\\.googleapis\\.com/')
      THEN COALESCE(NEW.policy_notes,'Permitted automatically: trusted machine-collected public source.')
      ELSE 'Restricted automatically: unsupported source requires an explicit policy basis.' END,
    NEW.status = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)' THEN 'inactive'
      ELSE NEW.status END,
    NEW.next_run_at = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.base_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)' THEN NULL
      WHEN (NEW.connector_type='stackexchange_api' AND LOWER(NEW.base_url) REGEXP '^https://api\\.stackexchange\\.com/')
        OR (NEW.connector_type='rss_atom' AND NEW.source_type='reddit' AND LOWER(NEW.base_url) REGEXP '^https://(www\\.|old\\.)?reddit\\.com/')
        OR (NEW.connector_type='hackernews_algolia_api' AND LOWER(NEW.base_url) REGEXP '^https://hn\\.algolia\\.com/')
        OR (NEW.connector_type='apple_app_store_reviews' AND LOWER(NEW.base_url) REGEXP '^https://itunes\\.apple\\.com/')
        OR (NEW.connector_type='google_play_developer_api' AND LOWER(NEW.base_url) REGEXP '^https://androidpublisher\\.googleapis\\.com/')
      THEN CASE WHEN NEW.status='active' THEN COALESCE(NEW.next_run_at,NOW()) ELSE NULL END
      ELSE NULL END;

DROP TRIGGER IF EXISTS trg_public_review_source_auto_policy_bi;
CREATE TRIGGER trg_public_review_source_auto_policy_bi
BEFORE INSERT ON public_review_sources
FOR EACH ROW
SET NEW.access_policy = CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)' THEN 'blocked'
      WHEN (NEW.source_type='reddit' AND LOWER(NEW.source_url) REGEXP '^https://([^/]+\\.)?reddit\\.com/')
        OR (NEW.source_type='public_forum' AND (LOWER(NEW.source_url) REGEXP '^https://([^/]+\\.)?stackoverflow\\.com/' OR LOWER(NEW.source_url) REGEXP '^https://([^/]+\\.)?stackexchange\\.com/'))
        OR (NEW.source_type='other_public' AND LOWER(NEW.source_url) REGEXP '^https://news\\.ycombinator\\.com/')
        OR (NEW.source_type='app_store' AND (LOWER(NEW.source_url) REGEXP '^https://play\\.google\\.com/' OR LOWER(NEW.source_url) REGEXP '^https://apps\\.apple\\.com/' OR LOWER(NEW.source_url) REGEXP '^https://itunes\\.apple\\.com/')) THEN 'permitted'
      ELSE 'restricted' END,
    NEW.access_policy_checked_at=NOW(),
    NEW.access_policy_notes=CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)'
      THEN 'Blocked automatically by TechSelectAI policy: G2 and Capterra are excluded.'
      WHEN (NEW.source_type='reddit' AND LOWER(NEW.source_url) REGEXP '^https://([^/]+\\.)?reddit\\.com/')
        OR (NEW.source_type='public_forum' AND (LOWER(NEW.source_url) REGEXP '^https://([^/]+\\.)?stackoverflow\\.com/' OR LOWER(NEW.source_url) REGEXP '^https://([^/]+\\.)?stackexchange\\.com/'))
        OR (NEW.source_type='other_public' AND LOWER(NEW.source_url) REGEXP '^https://news\\.ycombinator\\.com/')
        OR (NEW.source_type='app_store' AND (LOWER(NEW.source_url) REGEXP '^https://play\\.google\\.com/' OR LOWER(NEW.source_url) REGEXP '^https://apps\\.apple\\.com/' OR LOWER(NEW.source_url) REGEXP '^https://itunes\\.apple\\.com/'))
      THEN COALESCE(NEW.access_policy_notes,'Permitted automatically: trusted machine-collected public source.')
      ELSE 'Restricted automatically: unsupported source requires an explicit policy basis.' END,
    NEW.status=CASE
      WHEN NEW.source_type IN ('g2','capterra')
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)g2\\.com([/:?#]|$)'
        OR LOWER(NEW.source_url) REGEXP '(^|//|\\.)capterra\\.com([/:?#]|$)' THEN 'inactive'
      ELSE NEW.status END;
