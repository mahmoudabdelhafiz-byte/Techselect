-- Enrich CardIQ capability coverage from current public documentation.
-- Safe to run after 001-004 on an existing MariaDB V1 installation.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cat_id=(SELECT id FROM categories WHERE slug='corporate-identity-digital-business-cards' LIMIT 1);
SET @cardiq_id=(SELECT id FROM products WHERE slug='cardiq' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@cat_id,'Internal Communications','internal-communications','Employee messaging, administrator announcements and internal communications.',1),
(@cat_id,'Public Company Presence','public-company-presence','Company-controlled public profile, followers and official public announcements.',1),
(@cat_id,'Security & Governance','security-governance','Security alerts, identity governance and administrative security controls.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m
JOIN (
 SELECT 'internal-communications' module_slug,'Employee one-to-one messaging' name,'employee-one-to-one-messaging' slug,'Private messaging between employees in eligible company workspaces, including supported mobile-app flows.' description,0 security UNION ALL
 SELECT 'internal-communications','Administrator employee broadcast','admin-employee-broadcast','Administrator-originated announcements or messages to employees.',0 UNION ALL
 SELECT 'public-company-presence','Public company profile','public-company-profile','Company-controlled public destination for official links, contacts, services, representatives and employee identities.',0 UNION ALL
 SELECT 'public-company-presence','Follow official company updates','company-profile-followers','Signed-in users can follow official company updates from a company profile.',0 UNION ALL
 SELECT 'public-company-presence','Public company announcements / highlights','public-company-announcements','Authorized company administrators can publish official company highlights or announcements to eligible public audiences.',0 UNION ALL
 SELECT 'security-governance','Enterprise security alerts','enterprise-security-alerts','Company security alerts and events surfaced for administrator review.',1 UNION ALL
 SELECT 'enterprise-access','Microsoft Entra OIDC authentication','entra-oidc-authentication','Microsoft Entra OIDC authentication for active pre-mapped CardIQ users where deployed and configured.',1 UNION ALL
 SELECT 'enterprise-access','Microsoft Entra directory synchronization','entra-directory-sync','Scoped Microsoft Entra directory preview, controlled synchronization and lifecycle reconciliation where configured.',1 UNION ALL
 SELECT 'analytics-crm','Signed CRM lead webhooks','crm-lead-webhooks','Signed outbound lead webhooks for CRM or internal sales workflow integration where configured.',1 UNION ALL
 SELECT 'analytics-crm','Company employee directory','employee-directory','Company-scoped directory of active employees for internal discovery and workflow use.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@cat_id
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

-- Current CardIQ public evidence.
INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @cardiq_id,'vendor_documentation',x.url,x.title,'CardIQ',1,'verified','high',NOW()
FROM (
 SELECT 'https://card-iq.net/faq.php' url,'CardIQ FAQ' title UNION ALL
 SELECT 'https://card-iq.net/?lang=en','CardIQ Corporate Digital Identity Control Platform' UNION ALL
 SELECT 'https://card-iq.net/enterprise_identity_integrations.php?lang=en','CardIQ Enterprise Identity Integrations' UNION ALL
 SELECT 'https://card-iq.net/microsoft-entra','CardIQ + Microsoft Entra ID' UNION ALL
 SELECT 'https://card-iq.net/cardiq_developer_documentation.php','CardIQ Developer & API Documentation'
) x
WHERE @cardiq_id IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=@cardiq_id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cardiq_enriched_facts;
CREATE TEMPORARY TABLE cardiq_enriched_facts(
 capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT
);
INSERT INTO cardiq_enriched_facts VALUES
('employee-one-to-one-messaging','supported',0.95,'Available in eligible company workspaces; public documentation describes secure employee messaging.','https://card-iq.net/?lang=en'),
('admin-employee-broadcast','not_yet_verified',0.40,'Capability has been reported by the product owner, but the current public documentation reviewed by TechSelectAI does not yet state the exact all-employees broadcast behavior clearly enough for a verified claim.','https://card-iq.net/faq.php'),
('public-company-profile','supported',0.98,'Company-controlled public identity hub for official company links, contacts, services, locations, representatives and employee identities.','https://card-iq.net/faq.php'),
('company-profile-followers','supported',0.95,'Signed-in users can follow official updates from an official CardIQ company profile.','https://card-iq.net/faq.php'),
('public-company-announcements','supported',0.95,'Authorized company administrators can publish Company Highlights / official announcements to the selected eligible audience.','https://card-iq.net/faq.php'),
('enterprise-security-alerts','supported',0.95,'Enterprise security alerts and notifications are documented as available subject to plan, migration and workspace configuration.','https://card-iq.net/faq.php'),
('crm-integrations','supported',0.92,'CardIQ supports CRM-oriented integration through signed outbound lead webhooks where configured; this does not claim every named CRM has a native connector.','https://card-iq.net/cardiq_developer_documentation.php'),
('crm-lead-webhooks','supported',0.98,'Signed outbound lead_created webhook delivery to an HTTPS receiver is supported where configured.','https://card-iq.net/cardiq_developer_documentation.php'),
('employee-directory','supported',0.93,'Public CardIQ documentation describes an active employee Directory in company workspaces.','https://card-iq.net/faq.php'),
('entra-oidc-authentication','supported',0.96,'Implemented and available where deployed and configured for active pre-mapped CardIQ users; does not imply SAML login or JIT provisioning.','https://card-iq.net/enterprise_identity_integrations.php?lang=en'),
('entra-directory-sync','supported',0.93,'Controlled Microsoft Entra directory preview, synchronization and lifecycle reconciliation are documented where configured, with review and safety controls.','https://card-iq.net/microsoft-entra'),
('entra-id-integration','supported',0.90,'CardIQ has Microsoft Entra OIDC authentication and controlled directory synchronization/reconciliation where configured. This status does not imply SAML login, JIT provisioning or generally available SCIM.','https://card-iq.net/enterprise_identity_integrations.php?lang=en'),
('sso','partially_supported',0.95,'Microsoft Entra OIDC authentication is implemented where configured, but SAML login and enforced SSO are not currently active; generic SSO must not be interpreted as full SAML support.','https://card-iq.net/enterprise_identity_integrations.php?lang=en');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @cardiq_id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cardiq_enriched_facts f JOIN capabilities c ON c.slug=f.capability_slug
WHERE @cardiq_id IS NOT NULL
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Add unknown rows for the other launch products so comparison pages remain explicit rather than silently omitting new capabilities.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p JOIN capabilities c
JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('blinq','hihello') AND m.category_id=@cat_id
AND c.slug IN('employee-one-to-one-messaging','admin-employee-broadcast','public-company-profile','company-profile-followers','public-company-announcements','enterprise-security-alerts','entra-oidc-authentication','entra-directory-sync','crm-lead-webhooks','employee-directory')
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cardiq_enriched_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@cardiq_id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@cardiq_id AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE id=@cardiq_id;
COMMIT;
