-- Official Google Play Developer API review connector.
-- This uses authenticated Play Console access only; it does not scrape public Play HTML.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO public_review_connectors(
  product_id,connector_type,source_type,source_name,base_url,config_json,
  policy_status,policy_checked_at,policy_notes,status,interval_minutes,next_run_at,created_by_user_id
)
SELECT p.id,
       'google_play_developer_api',
       'app_store',
       'Google Play',
       'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.card_iq.myapp/reviews',
       JSON_OBJECT('package_name','com.card_iq.myapp','translation_language','en','max_items',50),
       'permitted',
       NOW(),
       'Official authenticated Google Play Developer API for the vendor-authorized CardIQ package. Public review-derived signals remain separate from Fit Score and recommendation ranking.',
       'active',
       1440,
       NOW(),
       NULL
FROM products p
WHERE p.slug='cardiq' AND p.status='active'
  AND NOT EXISTS(
    SELECT 1 FROM public_review_connectors c
    WHERE c.product_id=p.id
      AND c.connector_type='google_play_developer_api'
      AND JSON_UNQUOTE(JSON_EXTRACT(c.config_json,'$.package_name'))='com.card_iq.myapp'
  );

COMMIT;
