-- Consolidate duplicate Document Management / ECM taxonomy into the existing Document Management category.
-- Preserves the richer evidence added in migration 090 while restoring one canonical category.
-- Unknown != Unsupported. No recommendation or Fit Score logic is modified.
SET NAMES utf8mb4;
START TRANSACTION;

SET @dms_cat=(SELECT id FROM categories WHERE slug='document-management' LIMIT 1);
SET @ecm_cat=(SELECT id FROM categories WHERE slug='document-management-ecm' LIMIT 1);

-- Strengthen the existing canonical category description.
UPDATE categories
SET name='Document Management / ECM',
    description='Document management and enterprise content management platforms for governed content repositories, metadata, search, versioning, workflow, records lifecycle, access controls and enterprise content integrations.',
    is_active=1
WHERE id=@dms_cat;

-- Extend the canonical taxonomy only where migration 090 added a distinct research dimension.
INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,'Enterprise content integrations','dms-enterprise-integrations','Connect governed content with productivity suites, business applications or other content repositories.',0,1
FROM modules m
WHERE m.category_id=@dms_cat AND m.slug='dms-governance'
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

-- Keep the active canonical product rows from migration 090, but place them in the original category.
UPDATE products
SET category_id=@dms_cat,last_reviewed_at=NOW()
WHERE slug IN ('microsoft-sharepoint','opentext-content-management','m-files','box','egnyte');

-- Retire the two older draft aliases introduced by migration 061. Their historical evidence is preserved.
UPDATE products
SET status='inactive',last_reviewed_at=NOW()
WHERE slug IN ('m-files-document-management','box-intelligent-content-management');

-- Map richer ECM capability research into the canonical DMS capability model.
DROP TEMPORARY TABLE IF EXISTS dms91_capability_map;
CREATE TEMPORARY TABLE dms91_capability_map(source_slug VARCHAR(190),target_slug VARCHAR(190));
INSERT INTO dms91_capability_map VALUES
('ecm-document-repository','dms-repository'),
('ecm-search-discovery','dms-metadata-search'),
('ecm-version-control','dms-version-collaboration'),
('ecm-workflow-automation','dms-workflow'),
('ecm-access-governance','dms-governance-controls'),
('ecm-enterprise-integrations','dms-enterprise-integrations');

-- Create missing canonical product/capability rows from verified ECM facts.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,implementation_type,limitations,confidence_score,last_verified_at)
SELECT src.product_id,tgt.id,NULL,src.support_status,src.implementation_type,src.limitations,src.confidence_score,src.last_verified_at
FROM product_capabilities src
JOIN capabilities sc ON sc.id=src.capability_id
JOIN dms91_capability_map mp ON mp.source_slug=sc.slug
JOIN capabilities tgt ON tgt.slug=mp.target_slug
JOIN modules tm ON tm.id=tgt.module_id AND tm.category_id=@dms_cat
JOIN products p ON p.id=src.product_id AND p.slug IN ('microsoft-sharepoint','opentext-content-management','m-files','box','egnyte')
WHERE src.edition_id IS NULL
  AND NOT EXISTS(
      SELECT 1 FROM product_capabilities existing
      WHERE existing.product_id=src.product_id AND existing.capability_id=tgt.id AND existing.edition_id IS NULL
  );

-- Refresh canonical rows with the richer mapped status/confidence where a row already existed.
UPDATE product_capabilities dst
JOIN products p ON p.id=dst.product_id AND p.slug IN ('microsoft-sharepoint','opentext-content-management','m-files','box','egnyte')
JOIN capabilities tc ON tc.id=dst.capability_id
JOIN modules tm ON tm.id=tc.module_id AND tm.category_id=@dms_cat
JOIN dms91_capability_map mp ON mp.target_slug=tc.slug
JOIN capabilities sc ON sc.slug=mp.source_slug
JOIN product_capabilities src ON src.product_id=dst.product_id AND src.capability_id=sc.id AND src.edition_id IS NULL
SET dst.support_status=src.support_status,
    dst.implementation_type=src.implementation_type,
    dst.limitations=src.limitations,
    dst.confidence_score=src.confidence_score,
    dst.last_verified_at=src.last_verified_at
WHERE dst.edition_id IS NULL;

-- Retention evidence also strengthens the combined canonical governance capability.
INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT dst.id,pce.evidence_source_id,0,'Mapped from migration 090 records / retention evidence during taxonomy consolidation.'
FROM products p
JOIN product_capabilities src ON src.product_id=p.id AND src.edition_id IS NULL
JOIN capabilities sc ON sc.id=src.capability_id AND sc.slug='ecm-records-retention'
JOIN product_capability_evidence pce ON pce.product_capability_id=src.id
JOIN capabilities tc ON tc.slug='dms-governance-controls'
JOIN modules tm ON tm.id=tc.module_id AND tm.category_id=@dms_cat
JOIN product_capabilities dst ON dst.product_id=p.id AND dst.capability_id=tc.id AND dst.edition_id IS NULL
WHERE p.slug IN ('microsoft-sharepoint','opentext-content-management','m-files','box','egnyte');

-- Carry primary evidence linkage from every mapped ECM fact to the canonical DMS capability.
INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT dst.id,pce.evidence_source_id,pce.is_primary,'Mapped from migration 090 evidence during taxonomy consolidation.'
FROM products p
JOIN product_capabilities src ON src.product_id=p.id AND src.edition_id IS NULL
JOIN capabilities sc ON sc.id=src.capability_id
JOIN dms91_capability_map mp ON mp.source_slug=sc.slug
JOIN product_capability_evidence pce ON pce.product_capability_id=src.id
JOIN capabilities tc ON tc.slug=mp.target_slug
JOIN modules tm ON tm.id=tc.module_id AND tm.category_id=@dms_cat
JOIN product_capabilities dst ON dst.product_id=p.id AND dst.capability_id=tc.id AND dst.edition_id IS NULL
WHERE p.slug IN ('microsoft-sharepoint','opentext-content-management','m-files','box','egnyte');

-- Every remaining canonical category capability is explicit, never inferred unsupported.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0.000
FROM products p
JOIN modules m ON m.category_id=@dms_cat AND m.is_active=1
JOIN capabilities c ON c.module_id=m.id AND c.is_active=1
WHERE p.slug IN ('microsoft-sharepoint','opentext-content-management','m-files','box','egnyte')
  AND NOT EXISTS(
      SELECT 1 FROM product_capabilities pc
      WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
  );

-- The temporary ECM taxonomy is no longer part of active discovery/evaluation.
UPDATE capabilities c JOIN modules m ON m.id=c.module_id SET c.is_active=0 WHERE m.category_id=@ecm_cat;
UPDATE modules SET is_active=0 WHERE category_id=@ecm_cat;
UPDATE categories SET is_active=0 WHERE id=@ecm_cat;

COMMIT;
