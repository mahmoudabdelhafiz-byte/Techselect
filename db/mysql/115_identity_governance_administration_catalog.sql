-- TechSelectAI Identity Governance & Administration catalog expansion.
-- Adds one canonical IGA category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Identity Governance & Administration','identity-governance-administration','Software for governing identity lifecycles, access requests, roles and entitlements, access reviews, policy controls, application onboarding and identity risk across enterprise environments.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @iga_cat=(SELECT id FROM categories WHERE slug='identity-governance-administration' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@iga_cat,'Lifecycle & Access','iga-lifecycle-access','Identity lifecycle automation, access requests, roles and entitlements, and application onboarding/connectivity.',1),
(@iga_cat,'Governance, Compliance & Risk','iga-governance-risk','Access reviews, segregation-of-duties controls, identity risk insight, and governance of non-human or external identities.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'iga-lifecycle-access' module_slug,'Identity lifecycle provisioning & deprovisioning' name,'iga-lifecycle-provisioning' slug,'Automate identity onboarding, changes and offboarding, including provisioning and deprovisioning access across connected systems.' description,1 sec UNION ALL
 SELECT 'iga-lifecycle-access','Access requests & approvals','iga-access-requests','Provide self-service or delegated access requests with approval workflows and controlled fulfillment.',1 UNION ALL
 SELECT 'iga-lifecycle-access','Entitlement & role governance','iga-entitlements-roles','Model, assign and govern entitlements, access profiles, roles or similar access bundles and policies.',1 UNION ALL
 SELECT 'iga-lifecycle-access','Application onboarding & connectors','iga-application-onboarding','Onboard applications and systems into governance using connectors, adapters or guided integration workflows.',1 UNION ALL
 SELECT 'iga-governance-risk','Access reviews & certifications','iga-access-reviews','Run periodic, event-driven or targeted access reviews, recertification or attestation campaigns.',1 UNION ALL
 SELECT 'iga-governance-risk','Segregation of duties & policy controls','iga-segregation-duties','Define and evaluate conflicting-access, separation-of-duties or comparable access-governance policies.',1 UNION ALL
 SELECT 'iga-governance-risk','Identity risk analytics & governance insights','iga-risk-analytics','Surface identity, access, policy or entitlement risk through analytics, recommendations, dashboards or governance insights.',1 UNION ALL
 SELECT 'iga-governance-risk','Non-human & external identity governance','iga-nonhuman-external','Govern supported machine, technical, AI-agent, contractor, partner or other non-employee identities through controlled lifecycle and access processes.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@iga_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SailPoint','sailpoint','https://www.sailpoint.com/','Identity security and identity governance software vendor.','active'),
('Saviynt','saviynt','https://saviynt.com/','Identity security, governance and privileged access software vendor.','active'),
('Omada','omada','https://omadaidentity.com/','Identity governance and administration software vendor.','active'),
('One Identity','one-identity','https://www.oneidentity.com/','Identity security, governance and access management software vendor.','active'),
('IBM','ibm','https://www.ibm.com/','Enterprise technology, security, cloud, data and AI software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat115_products;
CREATE TEMPORARY TABLE cat115_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat115_products VALUES
('sailpoint','identity-governance-administration','SailPoint Identity Security Cloud','sailpoint-identity-security-cloud','Cloud identity security and governance platform for lifecycle management, access requests, certifications, role and entitlement governance, application onboarding and identity risk controls.','https://www.sailpoint.com/solutions/identity-security-cloud'),
('saviynt','identity-governance-administration','Saviynt Identity Governance & Administration','saviynt-identity-governance-administration','Identity governance and administration for lifecycle automation, access requests and reviews, identity risk, compliance controls and application onboarding across cloud, hybrid and on-premises environments.','https://saviynt.com/products/identity-governance-and-administration'),
('omada','identity-governance-administration','Omada Identity Cloud','omada-identity-cloud','SaaS identity governance and administration for lifecycle management, access governance, provisioning, access reviews, policy controls, integrations and identity analytics.','https://omadaidentity.com/products/omada-identity-cloud/'),
('one-identity','identity-governance-administration','One Identity Manager','one-identity-manager','Identity governance and administration software for lifecycle provisioning, access requests, attestation, role and entitlement governance, application governance and compliance reporting.','https://www.oneidentity.com/products/identity-manager/'),
('ibm','identity-governance-administration','IBM Verify Identity Governance','ibm-verify-identity-governance','Enterprise identity governance and administration software for lifecycle provisioning, access requests, recertification, separation-of-duties controls, adapters and identity risk analytics.','https://www.ibm.com/products/verify-identity-governance');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat115_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat115_sources;
CREATE TEMPORARY TABLE cat115_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat115_sources VALUES
('sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/help/getting_started/index.html','Getting Started in Identity Security Cloud','SailPoint'),
('sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/help/access/index.html','Access Overview','SailPoint'),
('sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/help/certs/understanding_certifications.html','Understanding Certifications','SailPoint'),
('sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/help/sod/index.html','Separation of Duties Overview','SailPoint'),
('sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/help/ai/app_onboarding/index.html','SailPoint Application Onboarding','SailPoint'),
('sailpoint-identity-security-cloud','https://documentation.sailpoint.com/saas/user-help/requests/index.html','Access Requests Overview','SailPoint'),
('sailpoint-identity-security-cloud','https://www.sailpoint.com/products/identity-security-cloud/atlas/capabilities/lifecycle-management','SailPoint Lifecycle Management','SailPoint'),
('sailpoint-identity-security-cloud','https://www.sailpoint.com/solutions/identity-security-cloud','SailPoint Identity Security Cloud','SailPoint'),
('saviynt-identity-governance-administration','https://saviynt.com/products/identity-governance-and-administration','Saviynt Identity Governance & Administration','Saviynt'),
('omada-identity-cloud','https://omadaidentity.com/products/omada-identity-cloud/','Omada Identity Cloud','Omada'),
('omada-identity-cloud','https://omadaidentity.com/products/functionality/identity-governance/','Omada Identity Governance','Omada'),
('omada-identity-cloud','https://omadaidentity.com/products/functionality/lifecycle-management/','Omada Identity Lifecycle Management','Omada'),
('omada-identity-cloud','https://documentation.omadaidentity.com/docs/process-flow/access-request/','Omada Identity Cloud Access Request','Omada'),
('one-identity-manager','https://www.oneidentity.com/products/identity-manager/','One Identity Manager','One Identity'),
('ibm-verify-identity-governance','https://www.ibm.com/products/verify-identity-governance','IBM Verify Identity Governance','IBM'),
('ibm-verify-identity-governance','https://www.ibm.com/products/verify/identity-governance-lifecycle-management','IBM Verify Identity Governance Lifecycle Management','IBM'),
('ibm-verify-identity-governance','https://www.ibm.com/support/pages/ibm-verify-identity-governance-adapters','IBM Verify Identity Governance Adapters','IBM'),
('ibm-verify-identity-governance','https://www.ibm.com/support/pages/node/7270058','IBM Verify Identity Governance v11.0.2','IBM');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat115_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat115_facts;
CREATE TEMPORARY TABLE cat115_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat115_facts VALUES
-- SailPoint Identity Security Cloud
('sailpoint-identity-security-cloud','iga-lifecycle-provisioning','supported',0.990,'Identity Security Cloud lifecycle states can automate provisioning and deprovisioning; exact source connectivity and fulfillment behavior depend on the configured connectors and subscribed services.','https://documentation.sailpoint.com/saas/help/access/index.html'),
('sailpoint-identity-security-cloud','iga-access-requests','supported',0.990,'SailPoint documents request, approval and fulfillment workflows for access items; some request experiences depend on licensing and enablement.','https://documentation.sailpoint.com/saas/user-help/requests/index.html'),
('sailpoint-identity-security-cloud','iga-entitlements-roles','supported',0.990,'SailPoint documents entitlements, access profiles, roles and lifecycle states as governed access-model objects.','https://documentation.sailpoint.com/saas/help/access/index.html'),
('sailpoint-identity-security-cloud','iga-application-onboarding','supported',0.990,'SailPoint documents enterprise-application discovery, guided source configuration and application onboarding into Identity Security Cloud.','https://documentation.sailpoint.com/saas/help/ai/app_onboarding/index.html'),
('sailpoint-identity-security-cloud','iga-access-reviews','supported',0.990,'SailPoint certification campaigns review roles, access profiles and entitlements and can revoke request-granted access.','https://documentation.sailpoint.com/saas/help/certs/understanding_certifications.html'),
('sailpoint-identity-security-cloud','iga-segregation-duties','supported',0.990,'Identity Security Cloud documents SoD policies, violations, reporting and remediation workflows for human identities.','https://documentation.sailpoint.com/saas/help/sod/index.html'),
('sailpoint-identity-security-cloud','iga-risk-analytics','supported',0.970,'SailPoint documents identity-security insights and governance risk capabilities within Identity Security Cloud; exact analytics depend on subscribed services.','https://www.sailpoint.com/solutions/identity-security-cloud'),
('sailpoint-identity-security-cloud','iga-nonhuman-external','partially_supported',0.950,'Current SailPoint request documentation explicitly supports requests for machine identities in configured scenarios; broader external-identity lifecycle coverage is not inferred here.','https://documentation.sailpoint.com/saas/user-help/requests/index.html'),

-- Saviynt Identity Governance & Administration
('saviynt-identity-governance-administration','iga-lifecycle-provisioning','supported',0.990,'Saviynt documents complete identity lifecycle automation from onboarding through access revocation on departure.','https://saviynt.com/products/identity-governance-and-administration'),
('saviynt-identity-governance-administration','iga-access-requests','supported',0.990,'Saviynt documents streamlined access requests with AI-assisted recommendations and approval guidance.','https://saviynt.com/products/identity-governance-and-administration'),
('saviynt-identity-governance-administration','iga-entitlements-roles','supported',0.970,'Saviynt documents least-privilege access governance across identities, resources and environments; exact role-model implementation depends on configuration.','https://saviynt.com/products/identity-governance-and-administration'),
('saviynt-identity-governance-administration','iga-application-onboarding','supported',0.990,'Saviynt documents hundreds of pre-built application integrations and accelerated application onboarding.','https://saviynt.com/products/identity-governance-and-administration'),
('saviynt-identity-governance-administration','iga-access-reviews','supported',0.990,'Saviynt documents access review and certification workflows with recommendations and automation.','https://saviynt.com/products/identity-governance-and-administration'),
('saviynt-identity-governance-administration','iga-risk-analytics','supported',0.990,'Saviynt documents continuous evaluation of risks and policy anomalies with dynamic compliance analytics and reporting.','https://saviynt.com/products/identity-governance-and-administration'),
('saviynt-identity-governance-administration','iga-nonhuman-external','supported',0.990,'Saviynt explicitly documents governance for internal, external, human, machine and AI identities in the IGA product.','https://saviynt.com/products/identity-governance-and-administration'),

-- Omada Identity Cloud
('omada-identity-cloud','iga-lifecycle-provisioning','supported',0.990,'Omada Identity Cloud documents identity lifecycle management, automated provisioning and deprovisioning as core IGA functionality.','https://omadaidentity.com/products/omada-identity-cloud/'),
('omada-identity-cloud','iga-access-requests','supported',0.990,'Omada Identity Cloud documents access-request workflows for human identities and a dedicated process for non-human technical identities.','https://documentation.omadaidentity.com/docs/process-flow/access-request/'),
('omada-identity-cloud','iga-entitlements-roles','supported',0.980,'Omada documents role and privilege lifecycle governance plus policies that control access assignment.','https://omadaidentity.com/products/functionality/identity-governance/'),
('omada-identity-cloud','iga-application-onboarding','supported',0.990,'Omada Identity Cloud documents an extensive connector library and guided system onboarding for governed applications.','https://omadaidentity.com/products/omada-identity-cloud/'),
('omada-identity-cloud','iga-access-reviews','supported',0.990,'Omada documents certification campaigns and regular access review processes as core identity-governance functions.','https://omadaidentity.com/products/functionality/identity-governance/'),
('omada-identity-cloud','iga-segregation-duties','supported',0.990,'Omada explicitly documents least-privilege and separation-of-duties policies plus SoD governance processes.','https://omadaidentity.com/products/functionality/identity-governance/'),
('omada-identity-cloud','iga-risk-analytics','supported',0.990,'Omada Identity Cloud documents identity analytics, access intelligence, risk visibility and governance recommendations.','https://omadaidentity.com/products/omada-identity-cloud/'),
('omada-identity-cloud','iga-nonhuman-external','partially_supported',0.970,'Omada documents governance and access requests for non-human technical identities; this row does not infer full partner/external-identity lifecycle coverage beyond the documented scope.','https://omadaidentity.com/products/functionality/lifecycle-management/'),

-- One Identity Manager
('one-identity-manager','iga-lifecycle-provisioning','supported',0.990,'One Identity Manager documents automated identity lifecycle and provisioning to on-premises and cloud targets.','https://www.oneidentity.com/products/identity-manager/'),
('one-identity-manager','iga-access-requests','supported',0.990,'One Identity Manager documents self-service entitlement and group-access requests.','https://www.oneidentity.com/products/identity-manager/'),
('one-identity-manager','iga-entitlements-roles','supported',0.990,'One Identity Manager documents role management, entitlement governance and governed assignment visibility.','https://www.oneidentity.com/products/identity-manager/'),
('one-identity-manager','iga-application-onboarding','supported',0.980,'One Identity Manager documents application governance plus integrations/connectors for extending governed coverage.','https://www.oneidentity.com/products/identity-manager/'),
('one-identity-manager','iga-access-reviews','supported',0.990,'One Identity Manager documents attestation and recertification workflows for user, group and entitlement access.','https://www.oneidentity.com/products/identity-manager/'),
('one-identity-manager','iga-risk-analytics','supported',0.970,'One Identity Manager documents governance heatmaps, policy-violation views and identity-threat response workflows; exact analytics depend on the selected modules and configuration.','https://www.oneidentity.com/products/identity-manager/'),

-- IBM Verify Identity Governance
('ibm-verify-identity-governance','iga-lifecycle-provisioning','supported',0.990,'IBM documents automated identity onboarding, offboarding and provisioning across the user lifecycle.','https://www.ibm.com/products/verify/identity-governance-lifecycle-management'),
('ibm-verify-identity-governance','iga-access-requests','supported',0.980,'IBM documents delegated application ownership and user access through an application catalog; exact approval and fulfillment flows depend on configuration.','https://www.ibm.com/products/verify/identity-governance-lifecycle-management'),
('ibm-verify-identity-governance','iga-entitlements-roles','supported',0.980,'IBM Verify Identity Governance documents role-based and activity-based governance of user access and authorization.','https://www.ibm.com/products/verify-identity-governance'),
('ibm-verify-identity-governance','iga-application-onboarding','supported',0.990,'IBM publishes a current adapter inventory for governed application and infrastructure targets across Verify Identity Governance editions.','https://www.ibm.com/support/pages/ibm-verify-identity-governance-adapters'),
('ibm-verify-identity-governance','iga-access-reviews','supported',0.990,'IBM documents recurring certification campaigns and automated recertification for higher-risk applications.','https://www.ibm.com/products/verify/identity-governance-lifecycle-management'),
('ibm-verify-identity-governance','iga-segregation-duties','supported',0.990,'IBM Verify Identity Governance explicitly documents activity-based governance beyond traditional role-based SoD models.','https://www.ibm.com/products/verify-identity-governance'),
('ibm-verify-identity-governance','iga-risk-analytics','supported',0.990,'IBM Verify Identity Governance v11.0.2 documents governance with actionable identity-risk insights.','https://www.ibm.com/support/pages/node/7270058');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat115_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat115_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat115_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment is promoted only where current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('sailpoint-identity-security-cloud','omada-identity-cloud')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='ibm-verify-identity-governance'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer platform-specific mobile access from browser access or vendor-wide apps.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('sailpoint-identity-security-cloud','saviynt-identity-governance-administration','omada-identity-cloud','one-identity-manager','ibm-verify-identity-governance')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
