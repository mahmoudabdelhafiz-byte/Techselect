-- Project canonical product_mobile_access evidence into the existing category capability/scoring model.
-- Mobile availability is NOT a default bonus. It affects Fit Score only when a buyer selects
-- one of these capabilities as a consultation requirement.
SET NAMES utf8mb4;
START TRANSACTION;

-- Every active category gets a Mobile Access module. The same concept is category-scoped so
-- CategoryGuard can safely use it without allowing unrelated cross-category capabilities.
INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,'Mobile Access','mobile-access',
       'Buyer-selectable mobile access requirements. Availability is evidence-based; unknown is not unsupported.',1
FROM categories c
WHERE c.is_active=1
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

-- Category-prefixed slugs keep the criteria unambiguous while preserving the existing
-- capability engine and deterministic recommendation methodology.
INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,CONCAT(cat.slug,'-',x.slug_suffix),x.description,0,1
FROM modules m
JOIN categories cat ON cat.id=m.category_id
CROSS JOIN (
  SELECT 'Android mobile application' name,'mobile-android-app' slug_suffix,
         'A vendor-supported Android application is available for the software.' description
  UNION ALL
  SELECT 'iOS mobile application','mobile-ios-app',
         'A vendor-supported iOS application is available for the software.'
  UNION ALL
  SELECT 'Mobile web access','mobile-web-access',
         'The software provides vendor-supported mobile web or responsive browser access.'
) x
WHERE m.slug='mobile-access' AND cat.is_active=1
  AND NOT EXISTS(
    SELECT 1 FROM capabilities c2
    WHERE c2.module_id=m.id AND c2.slug=CONCAT(cat.slug,'-',x.slug_suffix)
  );

-- Refresh any existing projected facts first.
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

-- Add missing projected facts. Explicit not_yet_verified rows are intentional.
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

-- Keep admin mobile validation changes synchronized with the capability facts used by
-- comparison and recommendations. These triggers never infer support; they mirror the
-- canonical product_mobile_access status and confidence only.
DROP TRIGGER IF EXISTS trg_mobile_access_capability_update;
CREATE TRIGGER trg_mobile_access_capability_update
AFTER UPDATE ON product_mobile_access
FOR EACH ROW
UPDATE product_capabilities pc
JOIN products p ON p.id=pc.product_id
JOIN categories cat ON cat.id=p.category_id
JOIN capabilities cap ON cap.id=pc.capability_id
SET pc.support_status=NEW.support_status,
    pc.implementation_type=CASE NEW.platform WHEN 'android' THEN 'native_android_app' WHEN 'ios' THEN 'native_ios_app' ELSE 'mobile_web' END,
    pc.limitations=CASE
      WHEN NEW.support_status='not_yet_verified' THEN 'Mobile availability has not yet been verified from first-party evidence.'
      WHEN NEW.scope_status='not_yet_verified' THEN COALESCE(NEW.scope_notes,'Application availability is verified; functional scope is not yet verified.')
      ELSE NEW.scope_notes
    END,
    pc.confidence_score=NEW.confidence_score,
    pc.last_verified_at=NEW.last_verified_at
WHERE pc.product_id=NEW.product_id AND pc.edition_id IS NULL
  AND cap.slug=CONCAT(cat.slug,'-',CASE NEW.platform WHEN 'android' THEN 'mobile-android-app' WHEN 'ios' THEN 'mobile-ios-app' ELSE 'mobile-web-access' END);

DROP TRIGGER IF EXISTS trg_mobile_access_capability_insert;
CREATE TRIGGER trg_mobile_access_capability_insert
AFTER INSERT ON product_mobile_access
FOR EACH ROW
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,implementation_type,limitations,confidence_score,last_verified_at)
SELECT p.id,cap.id,NULL,NEW.support_status,
       CASE NEW.platform WHEN 'android' THEN 'native_android_app' WHEN 'ios' THEN 'native_ios_app' ELSE 'mobile_web' END,
       CASE
         WHEN NEW.support_status='not_yet_verified' THEN 'Mobile availability has not yet been verified from first-party evidence.'
         WHEN NEW.scope_status='not_yet_verified' THEN COALESCE(NEW.scope_notes,'Application availability is verified; functional scope is not yet verified.')
         ELSE NEW.scope_notes
       END,
       NEW.confidence_score,NEW.last_verified_at
FROM products p
JOIN categories cat ON cat.id=p.category_id
JOIN modules m ON m.category_id=cat.id AND m.slug='mobile-access'
JOIN capabilities cap ON cap.module_id=m.id
 AND cap.slug=CONCAT(cat.slug,'-',CASE NEW.platform WHEN 'android' THEN 'mobile-android-app' WHEN 'ios' THEN 'mobile-ios-app' ELSE 'mobile-web-access' END)
WHERE p.id=NEW.product_id
  AND NOT EXISTS(
    SELECT 1 FROM product_capabilities pc
    WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL
  );