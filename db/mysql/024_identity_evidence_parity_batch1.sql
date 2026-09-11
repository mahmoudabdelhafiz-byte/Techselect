-- TechSelectAI identity evidence parity batch 1
-- Issue #146: enrich explicit competitor facts using official vendor documentation reviewed Sep 2026.
-- This migration intentionally leaves undocumented verification/security capabilities as not_yet_verified.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards' LIMIT 1);

-- Official vendor evidence sources used by this focused parity batch.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
  SELECT 'blinq' product_slug,'https://blinq.me/business' url,'Blinq Business' title,'Blinq' publisher UNION ALL
  SELECT 'blinq','https://blinq.me/solutions/virtual-meeting-backgrounds','Blinq Virtual Meeting Backgrounds','Blinq' UNION ALL
  SELECT 'blinq','https://support.blinq.me/en/articles/78112-campaign-insights','Blinq Campaign Insights','Blinq' UNION ALL
  SELECT 'hihello','https://support.hihello.com/hc/en-us/articles/14732916034587-How-to-Add-or-Remove-a-User-From-Your-Plan','HiHello Add or Remove a User From Your Plan','HiHello' UNION ALL
  SELECT 'hihello','https://www.hihello.com/blog/how-to-set-up-your-hihello-business-account','HiHello Business Account Setup','HiHello' UNION ALL
  SELECT 'uniqode','https://docs.uniqode.com/en/articles/7958550-create-digital-business-cards-for-your-employees-using-microsoft-entra-id-integration','Uniqode Microsoft Entra ID Integration','Uniqode'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(
  SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url
);

DROP TEMPORARY TABLE IF EXISTS parity24_facts;
CREATE TEMPORARY TABLE parity24_facts(
  product_slug VARCHAR(190),
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);

INSERT INTO parity24_facts VALUES
-- Blinq: explicit current Business/Enterprise documentation.
('blinq','meeting-backgrounds','supported',0.980,'Blinq documents branded virtual backgrounds for teams and major conferencing platforms.','https://blinq.me/solutions/virtual-meeting-backgrounds'),
('blinq','manual-offboarding-control','supported',0.920,'Blinq Business documents centralized team administration and an offboard-in-a-click workflow; enterprise directory automation is tracked separately under automated deprovisioning.','https://blinq.me/business'),
('blinq','lead-capture','supported',0.990,'Blinq Business documents universal lead capture with badge/business-card/QR scanning and CRM synchronization.','https://blinq.me/business'),
('blinq','engagement-analytics','supported',0.980,'Blinq Campaign Insights documents card views, field clicks, contact counts and live engagement metrics for Business/Enterprise admins.','https://support.blinq.me/en/articles/78112-campaign-insights'),

-- HiHello: explicit admin-controlled deactivation/offboarding behavior.
('hihello','manual-offboarding-control','supported',0.970,'Admins can remove users from the Business/Enterprise account and pause company cards to deactivate their links/QR codes; removing a user alone does not delete the card, so card pause/delete is a separate admin action.','https://support.hihello.com/hc/en-us/articles/14732916034587-How-to-Add-or-Remove-a-User-From-Your-Plan'),

-- Uniqode: strengthen deprovisioning based on explicit current Entra behavior.
('uniqode','automated-deprovisioning','supported',0.970,'When a user provisioned through Microsoft Entra ID is permanently deleted, Uniqode documents automatic removal of the account/card and seat release. Marking a user inactive does not delete the card, so permanent deletion or manual cleanup is required.','https://docs.uniqode.com/en/articles/7958550-create-digital-business-cards-for-your-employees-using-microsoft-entra-id-integration'),
('uniqode','manual-offboarding-control','supported',0.920,'Uniqode documents that cards can be manually deleted when directory users are inactive or when direct organization users require cleanup.','https://docs.uniqode.com/en/articles/7958550-create-digital-business-cards-for-your-employees-using-microsoft-entra-id-integration');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM parity24_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN modules m ON m.id=c.module_id AND m.category_id=@cat_id
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM parity24_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Refresh product review date only for products touched by this migration.
UPDATE products SET last_reviewed_at=NOW() WHERE slug IN('blinq','hihello','uniqode');

DROP TEMPORARY TABLE IF EXISTS parity24_facts;
COMMIT;
