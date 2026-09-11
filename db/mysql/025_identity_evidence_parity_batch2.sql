-- TechSelectAI identity evidence parity batch 2
-- Issue #146: strengthen Mobilo directory/offboarding evidence and Popl admin/offboarding evidence.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards' LIMIT 1);

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
  SELECT 'mobilo' product_slug,'https://www.mobilocard.com/support-articles/microsoft-azure-integration' url,'Mobilo Microsoft Azure Integration' title,'Mobilo' publisher UNION ALL
  SELECT 'mobilo','https://www.mobilocard.com/support-articles/removing-users-from-the-app-as-an-administrator','Mobilo Removing Users as an Administrator','Mobilo' UNION ALL
  SELECT 'popl','https://support.popl.co/en/articles/8597830-remove-or-delete-a-member','Popl Remove or Delete a Member','Popl' UNION ALL
  SELECT 'popl','https://docs.popl.co/introduction/integrations/syncing-members-from-azure-active-directory-entra-id','Popl Syncing Members from Microsoft Entra ID','Popl'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(
  SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url
);

DROP TEMPORARY TABLE IF EXISTS parity25_facts;
CREATE TEMPORARY TABLE parity25_facts(
  product_slug VARCHAR(190),
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);

INSERT INTO parity25_facts VALUES
('mobilo','entra-id-integration','supported',0.980,'Mobilo documents a Microsoft Azure Active Directory integration that syncs directory groups, adds new users, updates existing users and identifies removed users for deletion.','https://www.mobilocard.com/support-articles/microsoft-azure-integration'),
('mobilo','automated-deprovisioning','supported',0.930,'During Azure synchronization Mobilo identifies users removed from the synced directory/security group and presents them for deletion; completing deletion removes the Mobilo account and deactivates the card. This is directory-assisted deprovisioning with an admin review/action step, not evidence of unattended SCIM deprovisioning.','https://www.mobilocard.com/support-articles/microsoft-azure-integration'),
('mobilo','manual-offboarding-control','supported',0.980,'Mobilo administrators can deactivate/delete departing users, deactivate cards, or release/reassign cards from the admin interface.','https://www.mobilocard.com/support-articles/removing-users-from-the-app-as-an-administrator'),
('popl','manual-offboarding-control','supported',0.980,'Popl team admins can remove members from a managed team or permanently delete member accounts.','https://support.popl.co/en/articles/8597830-remove-or-delete-a-member'),
('popl','automated-deprovisioning','supported',0.990,'Popl documents an Entra ID synchronization option that removes members when they are removed from synced Active Directory groups, with an optional permanent-delete toggle.','https://docs.popl.co/introduction/integrations/syncing-members-from-azure-active-directory-entra-id');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM parity25_facts f
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
FROM parity25_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE slug IN('mobilo','popl');

DROP TEMPORARY TABLE IF EXISTS parity25_facts;
COMMIT;
