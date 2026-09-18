-- Backfill buyer-selectable Mobile Access criteria for categories created after migration 087.
-- This is intentionally evidence-neutral: it projects existing product_mobile_access facts and never infers support.
-- Safe to rerun; existing reviewed product_mobile_access facts are not modified.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,'Mobile Access','mobile-access',
       'Buyer-selectable mobile access requirements. Availability is evidence-based; unknown is not unsupported.',1
FROM categories c
WHERE c.is_active=1
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,'Android mobile application',CONCAT(cat.slug,'-mobile-android-app'),
       'A vendor-supported Android application is available for the software.',0,1
FROM modules m
JOIN categories cat ON cat.id=m.category_id
WHERE m.slug='mobile-access' AND cat.is_active=1
  AND NOT EXISTS(
    SELECT 1 FROM capabilities c2
    WHERE c2.module_id=m.id AND c2.slug=CONCAT(cat.slug,'-mobile-android-app')
  );

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,'iOS mobile application',CONCAT(cat.slug,'-mobile-ios-app'),
       'A vendor-supported iOS application is available for the software.',0,1
FROM modules m
JOIN categories cat ON cat.id=m.category_id
WHERE m.slug='mobile-access' AND cat.is_active=1
  AND NOT EXISTS(
    SELECT 1 FROM capabilities c2
    WHERE c2.module_id=m.id AND c2.slug=CONCAT(cat.slug,'-mobile-ios-app')
  );

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,'Mobile web access',CONCAT(cat.slug,'-mobile-web-access'),
       'The software provides vendor-supported mobile web or responsive browser access.',0,1
FROM modules m
JOIN categories cat ON cat.id=m.category_id
WHERE m.slug='mobile-access' AND cat.is_active=1
  AND NOT EXISTS(
    SELECT 1 FROM capabilities c2
    WHERE c2.module_id=m.id AND c2.slug=CONCAT(cat.slug,'-mobile-web-access')
  );

-- Refresh already-projected mobile capability facts from the canonical product_mobile_access table.
UPDATE product_capabilities pc
JOIN products p ON p.id=pc.product_id
JOIN categories cat ON cat.id=p.category_id
JOIN capabilities cap ON cap.id=pc.capability_id
JOIN product_mobile_access pma ON pma.product_id=p.id
SET pc.support_status=pma.support_status,
    pc.implementation_type=CASE pma.platform
      WHEN 'android' THEN 'native_android_app'
      WHEN 'ios' THEN 'native_ios_app'
      ELSE 'mobile_web'
    END,
    pc.limitations=CASE
      WHEN pma.support_status='not_yet_verified' THEN 'Mobile availability has not yet been verified from first-party evidence.'
      WHEN pma.scope_status='not_yet_verified' THEN COALESCE(pma.scope_notes,'Application availability is verified; functional scope is not yet verified.')
      ELSE pma.scope_notes
    END,
    pc.confidence_score=pma.confidence_score,
    pc.last_verified_at=pma.last_verified_at
WHERE pc.edition_id IS NULL
  AND cap.slug=CONCAT(cat.slug,'-',CASE pma.platform
    WHEN 'android' THEN 'mobile-android-app'
    WHEN 'ios' THEN 'mobile-ios-app'
    ELSE 'mobile-web-access'
  END);

-- Add missing projections. Explicit not_yet_verified rows remain intentional and neutral.
INSERT INTO product_capabilities(
  product_id,capability_id,edition_id,support_status,implementation_type,limitations,confidence_score,last_verified_at
)
SELECT p.id,cap.id,NULL,pma.support_status,
       CASE pma.platform
         WHEN 'android' THEN 'native_android_app'
         WHEN 'ios' THEN 'native_ios_app'
         ELSE 'mobile_web'
       END,
       CASE
         WHEN pma.support_status='not_yet_verified' THEN 'Mobile availability has not yet been verified from first-party evidence.'
         WHEN pma.scope_status='not_yet_verified' THEN COALESCE(pma.scope_notes,'Application availability is verified; functional scope is not yet verified.')
         ELSE pma.scope_notes
       END,
       pma.confidence_score,pma.last_verified_at
FROM products p
JOIN categories cat ON cat.id=p.category_id
JOIN modules m ON m.category_id=cat.id AND m.slug='mobile-access'
JOIN product_mobile_access pma ON pma.product_id=p.id
JOIN capabilities cap ON cap.module_id=m.id
 AND cap.slug=CONCAT(cat.slug,'-',CASE pma.platform
   WHEN 'android' THEN 'mobile-android-app'
   WHEN 'ios' THEN 'mobile-ios-app'
   ELSE 'mobile-web-access'
 END)
WHERE p.status='active'
  AND NOT EXISTS(
    SELECT 1 FROM product_capabilities pc
    WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL
  );

COMMIT;
