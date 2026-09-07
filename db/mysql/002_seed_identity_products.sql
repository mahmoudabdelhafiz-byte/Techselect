-- TechSelectAI V1 curated identity seed for MariaDB/MySQL
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Corporate Identity & Digital Business Cards','corporate-identity-digital-business-cards','Company-controlled digital business cards, employee identity, signatures, meeting identity, lifecycle controls and verification.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards');

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Digital Business Cards','digital-business-cards','Company-managed digital business cards and sharing.',1),
(@cat_id,'Brand & Communication','brand-communication','Email signatures, meeting backgrounds and brand governance.',1),
(@cat_id,'Identity Lifecycle','identity-lifecycle','Provisioning, deprovisioning, offboarding and identity lifecycle controls.',1),
(@cat_id,'Enterprise Access','enterprise-access','SSO, SCIM and enterprise directory integrations.',1),
(@cat_id,'Verification & Trust','verification-trust','Company and employee verification, communication verification and trust controls.',1),
(@cat_id,'Analytics & CRM','analytics-crm','Engagement analytics, lead capture and CRM integrations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m
JOIN (
 SELECT 'digital-business-cards' module_slug,'Company-managed digital business cards' name,'company-managed-digital-business-cards' slug,'Admins can issue and manage company business cards.' description,0 security UNION ALL
 SELECT 'brand-communication','Email signatures','email-signatures','Company-branded employee email signatures.',0 UNION ALL
 SELECT 'brand-communication','Meeting backgrounds','meeting-backgrounds','Company-branded virtual meeting backgrounds.',0 UNION ALL
 SELECT 'brand-communication','Central brand templates','central-brand-templates','Centralized brand/template governance.',0 UNION ALL
 SELECT 'identity-lifecycle','Automated provisioning','automated-provisioning','Automated employee/account provisioning from connected directories or HR systems.',1 UNION ALL
 SELECT 'identity-lifecycle','Automated deprovisioning','automated-deprovisioning','Automated deactivation/removal from a connected source.',1 UNION ALL
 SELECT 'identity-lifecycle','Manual deactivation / offboarding control','manual-offboarding-control','Admin-controlled employee identity deactivation/offboarding.',1 UNION ALL
 SELECT 'enterprise-access','Single sign-on (SSO)','sso','Enterprise single sign-on.',1 UNION ALL
 SELECT 'enterprise-access','SCIM provisioning','scim','SCIM-based lifecycle provisioning.',1 UNION ALL
 SELECT 'enterprise-access','Microsoft Entra ID integration','entra-id-integration','Microsoft Entra ID directory integration.',1 UNION ALL
 SELECT 'verification-trust','Employee identity verification','employee-identity-verification','Recipient-facing confirmation of employee identity/status.',1 UNION ALL
 SELECT 'verification-trust','Company / domain verification','company-domain-verification','Verification of company or company-controlled domain.',1 UNION ALL
 SELECT 'verification-trust','Communication channel verification','communication-channel-verification','Company-scoped verification of approved email, phone, WhatsApp or domain channels.',1 UNION ALL
 SELECT 'analytics-crm','Engagement analytics','engagement-analytics','Card/profile engagement analytics.',0 UNION ALL
 SELECT 'analytics-crm','Lead capture','lead-capture','Capture visitor/contact details as leads.',0 UNION ALL
 SELECT 'analytics-crm','CRM integrations','crm-integrations','Native or supported CRM integrations.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Barmageyat','barmageyat','https://card-iq.net/','Vendor of CardIQ.','active'),
('Blinq','blinq','https://blinq.me/','Digital business card platform vendor.','active'),
('HiHello','hihello','https://www.hihello.com/','Digital business card platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@cat_id,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'barmageyat' vendor_slug,'CardIQ' name,'cardiq' slug,'Corporate digital identity control platform with company-controlled cards, verification and lifecycle controls.' description,'https://card-iq.net/?lang=en' url UNION ALL
 SELECT 'blinq','Blinq','blinq','Digital business card platform for teams and enterprises.','https://blinq.me/enterprise' UNION ALL
 SELECT 'hihello','HiHello','hihello','Digital business card platform with business and enterprise administration.','https://www.hihello.com/enterprise'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- Evidence records. Duplicate URLs are tolerated only once per product by the NOT EXISTS predicate.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'cardiq' product_slug,'https://card-iq.net/?lang=en' url,'CardIQ Corporate Digital Identity Control Platform' title,'CardIQ' publisher UNION ALL
 SELECT 'cardiq','https://card-iq.net/how_cardiq_works.php?lang=en','How CardIQ Works','CardIQ' UNION ALL
 SELECT 'cardiq','https://card-iq.net/evaluate_cardiq_enterprise.php?lang=en','Evaluate CardIQ for Enterprise Identity Control','CardIQ' UNION ALL
 SELECT 'cardiq','https://card-iq.net/trust_architecture.php','CardIQ Trust Architecture','CardIQ' UNION ALL
 SELECT 'blinq','https://blinq.me/enterprise','Blinq Enterprise','Blinq' UNION ALL
 SELECT 'hihello','https://www.hihello.com/enterprise','HiHello Enterprise','HiHello' UNION ALL
 SELECT 'hihello','https://support.hihello.com/hc/en-us/articles/16012981708699-Creating-Cards-With-Microsoft-Entra-ID-Formerly-Known-as-Azure-Active-Directory','HiHello Microsoft Entra ID Integration','HiHello'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

-- Seed explicit supported/unsupported facts. Anything omitted remains not_yet_verified.
DROP TEMPORARY TABLE IF EXISTS seed_facts;
CREATE TEMPORARY TABLE seed_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO seed_facts VALUES
('cardiq','company-managed-digital-business-cards','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','email-signatures','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','meeting-backgrounds','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','central-brand-templates','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','manual-offboarding-control','supported',0.95,NULL,'https://card-iq.net/how_cardiq_works.php?lang=en'),
('cardiq','employee-identity-verification','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','company-domain-verification','supported',0.95,'Domain verification uses a DNS TXT record where enabled.','https://card-iq.net/how_cardiq_works.php?lang=en'),
('cardiq','communication-channel-verification','supported',0.98,'Company-scoped verification only; no reverse lookup and a not-verified result is not a fraud verdict.','https://card-iq.net/trust_architecture.php'),
('cardiq','engagement-analytics','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','lead-capture','supported',0.95,NULL,'https://card-iq.net/?lang=en'),
('cardiq','scim','not_supported',0.99,'Current public enterprise documentation states native SCIM provisioning is not currently supported.','https://card-iq.net/evaluate_cardiq_enterprise.php?lang=en'),
('cardiq','entra-id-integration','not_supported',0.99,'Current public enterprise documentation states native Entra ID provisioning is not currently supported.','https://card-iq.net/evaluate_cardiq_enterprise.php?lang=en'),
('blinq','company-managed-digital-business-cards','supported',0.95,NULL,'https://blinq.me/enterprise'),
('blinq','email-signatures','supported',0.95,NULL,'https://blinq.me/enterprise'),
('blinq','central-brand-templates','supported',0.95,NULL,'https://blinq.me/enterprise'),
('blinq','automated-provisioning','supported',0.95,NULL,'https://blinq.me/enterprise'),
('blinq','automated-deprovisioning','supported',0.95,NULL,'https://blinq.me/enterprise'),
('blinq','sso','supported',0.95,'Enterprise materials describe SAML SSO support.','https://blinq.me/enterprise'),
('blinq','scim','supported',0.95,'Enterprise materials describe SCIM provisioning/deprovisioning.','https://blinq.me/enterprise'),
('blinq','entra-id-integration','supported',0.95,NULL,'https://blinq.me/enterprise'),
('blinq','crm-integrations','supported',0.95,NULL,'https://blinq.me/enterprise'),
('hihello','company-managed-digital-business-cards','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','email-signatures','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','meeting-backgrounds','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','central-brand-templates','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','automated-provisioning','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','automated-deprovisioning','supported',0.95,'Removing employees from connected Entra groups removes them and pauses cards.','https://support.hihello.com/hc/en-us/articles/16012981708699-Creating-Cards-With-Microsoft-Entra-ID-Formerly-Known-as-Azure-Active-Directory'),
('hihello','sso','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','scim','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','entra-id-integration','supported',0.95,NULL,'https://support.hihello.com/hc/en-us/articles/16012981708699-Creating-Cards-With-Microsoft-Entra-ID-Formerly-Known-as-Azure-Active-Directory'),
('hihello','engagement-analytics','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','lead-capture','supported',0.95,NULL,'https://www.hihello.com/enterprise'),
('hihello','crm-integrations','supported',0.95,NULL,'https://www.hihello.com/enterprise');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM seed_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c
JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('cardiq','blinq','hihello') AND m.category_id=@cat_id
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM seed_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

COMMIT;
