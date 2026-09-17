-- TechSelectAI security operations catalog expansion: SIEM / Security Analytics + Privileged Access Management (PAM).
-- First-party vendor evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score or recommendation-ranking logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

/* =========================================================
   SIEM / Security Analytics
   ========================================================= */
INSERT INTO categories(name,slug,description,is_active) VALUES
('SIEM / Security Analytics','siem-security-analytics','Security information and event management platforms for security telemetry collection, detection, investigation, case management, response automation and threat intelligence.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @siem_cat=(SELECT id FROM categories WHERE slug='siem-security-analytics' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@siem_cat,'Security Data & Detection','siem-data-detection','Security telemetry ingestion, normalization, correlation and detection engineering.',1),
(@siem_cat,'Investigation & Response','siem-investigation-response','Threat investigation, hunting, case management, response automation and analyst workflows.',1),
(@siem_cat,'Threat Context','siem-threat-context','Threat intelligence and contextual enrichment used to prioritize and investigate security activity.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,1,1
FROM modules m JOIN (
 SELECT 'siem-data-detection' module_slug,'Security telemetry ingestion & normalization' name,'siem-security-data-ingestion' slug,'Collect, parse, normalize or otherwise prepare security telemetry from multiple systems and environments.' description UNION ALL
 SELECT 'siem-data-detection','Detection rules & correlation','siem-detection-correlation','Detect and correlate suspicious activity using rules, analytics, detections or equivalent security logic.' UNION ALL
 SELECT 'siem-investigation-response','Threat investigation & hunting','siem-threat-hunting-investigation','Search, investigate and proactively hunt across security telemetry and related context.' UNION ALL
 SELECT 'siem-investigation-response','Case / incident management','siem-case-management','Group, assign, prioritize and track security incidents, cases, alerts or investigation workflows.' UNION ALL
 SELECT 'siem-investigation-response','SOAR / response automation','siem-soar-automation','Automate or orchestrate security response actions, playbooks or investigation workflows.' UNION ALL
 SELECT 'siem-threat-context','Threat intelligence & enrichment','siem-threat-intelligence','Use threat intelligence or contextual enrichment to improve detection, prioritization or investigation.'
) x ON x.module_slug=m.slug
WHERE m.category_id=@siem_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=1,is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud and security platform vendor.','active'),
('Splunk','splunk','https://www.splunk.com/','Security and observability software vendor.','active'),
('IBM','ibm','https://www.ibm.com/','Enterprise software, cloud, infrastructure and security technology vendor.','active'),
('Google Cloud','google-cloud','https://cloud.google.com/','Cloud infrastructure, data, AI and security platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS sec104_siem_products;
CREATE TEMPORARY TABLE sec104_siem_products(vendor_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO sec104_siem_products VALUES
('microsoft','Microsoft Sentinel','microsoft-sentinel','Cloud-native SIEM for collecting security data across multicloud and multiplatform environments and supporting threat detection, investigation, response and proactive hunting.','https://learn.microsoft.com/en-us/azure/sentinel/overview'),
('splunk','Splunk Enterprise Security','splunk-enterprise-security','Security operations platform combining SIEM-led threat detection, investigation and response with integrated threat intelligence, case management and edition-dependent automation capabilities.','https://www.splunk.com/en_us/products/enterprise-security.html'),
('ibm','IBM QRadar SIEM','ibm-qradar-siem','SIEM platform for centralized security visibility, near-real-time threat detection, investigation, risk prioritization and compliance-oriented security operations.','https://www.ibm.com/products/qradar-siem'),
('google-cloud','Google Security Operations','google-security-operations','Cloud-native security operations platform combining SIEM, SOAR and threat intelligence for telemetry collection, detection, investigation, case management and automated response.','https://cloud.google.com/security/products/security-operations');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@siem_cat,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM sec104_siem_products x JOIN vendors v ON v.slug=x.vendor_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS sec104_siem_sources;
CREATE TEMPORARY TABLE sec104_siem_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO sec104_siem_sources VALUES
('microsoft-sentinel','https://learn.microsoft.com/en-us/azure/sentinel/overview','What is Microsoft Sentinel SIEM?','Microsoft'),
('microsoft-sentinel','https://learn.microsoft.com/en-us/azure/sentinel/sentinel-siem-application-card','Microsoft Sentinel SIEM application card','Microsoft'),
('splunk-enterprise-security','https://www.splunk.com/en_us/products/enterprise-security.html','Splunk Enterprise Security','Splunk'),
('splunk-enterprise-security','https://www.splunk.com/en_us/products/splunk-enterprise-security-features.html','Splunk Enterprise Security Features','Splunk'),
('ibm-qradar-siem','https://www.ibm.com/products/qradar-siem','IBM QRadar SIEM','IBM'),
('ibm-qradar-siem','https://www.ibm.com/docs/en/security-qradar/security-qradar-siem/saas?topic=qradar-siem-cloud-native-saas-overview','QRadar SIEM Cloud-Native SaaS overview','IBM'),
('google-security-operations','https://cloud.google.com/security/products/security-operations','Google Security Operations','Google Cloud'),
('google-security-operations','https://cloud.google.com/security/products/security-information-event-management','Google Security Operations Detect','Google Cloud'),
('google-security-operations','https://cloud.google.com/security/products/security-orchestration-automation-response','Google Security Operations Respond','Google Cloud');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM sec104_siem_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS sec104_siem_facts;
CREATE TEMPORARY TABLE sec104_siem_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO sec104_siem_facts VALUES
-- Microsoft Sentinel
('microsoft-sentinel','siem-security-data-ingestion','supported',0.990,'Microsoft documents collection at scale across multicloud and multiplatform environments; connector and retention specifics should be confirmed for the target architecture.','https://learn.microsoft.com/en-us/azure/sentinel/overview'),
('microsoft-sentinel','siem-detection-correlation','supported',0.990,'Microsoft documents analytics and threat detection capabilities within Sentinel SIEM.','https://learn.microsoft.com/en-us/azure/sentinel/overview'),
('microsoft-sentinel','siem-threat-hunting-investigation','supported',0.990,'Microsoft documents threat investigation and proactive hunting.','https://learn.microsoft.com/en-us/azure/sentinel/overview'),
('microsoft-sentinel','siem-case-management','supported',0.970,'Microsoft Sentinel supports incident-centric investigation and response workflows; exact workflow configuration depends on the deployed Defender/Sentinel experience.','https://learn.microsoft.com/en-us/azure/sentinel/overview'),
('microsoft-sentinel','siem-soar-automation','supported',0.980,'Microsoft documents automation and rapid response; automation design and connected actions require configuration.','https://learn.microsoft.com/en-us/azure/sentinel/sentinel-siem-application-card'),
('microsoft-sentinel','siem-threat-intelligence','supported',0.990,'Microsoft documents built-in threat intelligence as part of detection, investigation and response.','https://learn.microsoft.com/en-us/azure/sentinel/overview'),

-- Splunk Enterprise Security
('splunk-enterprise-security','siem-security-data-ingestion','supported',0.990,'Splunk Enterprise Security documents collection, unification, search and analysis across security data from domains, clouds and devices.','https://www.splunk.com/en_us/products/splunk-enterprise-security-features.html'),
('splunk-enterprise-security','siem-detection-correlation','supported',0.990,'Splunk Enterprise Security documents SIEM detections, Detection Studio, risk-based alerting and security analytics.','https://www.splunk.com/en_us/products/splunk-enterprise-security-features.html'),
('splunk-enterprise-security','siem-threat-hunting-investigation','supported',0.990,'Splunk Enterprise Security is documented as a threat detection, investigation and response platform with analyst investigation workflows.','https://www.splunk.com/en_us/products/enterprise-security.html'),
('splunk-enterprise-security','siem-case-management','supported',0.980,'Splunk documentation describes integrated alert triage, investigation, response and case-management workflows.','https://www.splunk.com/en_us/products/enterprise-security.html'),
('splunk-enterprise-security','siem-soar-automation','partially_supported',0.990,'SOAR is listed as a native capability in the Premier edition; buyers should verify the selected Enterprise Security edition.','https://www.splunk.com/en_us/products/enterprise-security.html'),
('splunk-enterprise-security','siem-threat-intelligence','supported',0.990,'Threat Intelligence is listed in Splunk Enterprise Security editions and is used to enrich and prioritize security activity.','https://www.splunk.com/en_us/products/splunk-enterprise-security-features.html'),

-- IBM QRadar SIEM
('ibm-qradar-siem','siem-security-data-ingestion','supported',0.970,'IBM describes centralized security visibility and ingestion of alerts from multiple sources; source-specific integrations should be confirmed.','https://www.ibm.com/docs/en/security-qradar/security-qradar-siem/saas?topic=qradar-siem-cloud-native-saas-overview'),
('ibm-qradar-siem','siem-detection-correlation','supported',0.990,'IBM documents near-real-time threat detection, Sigma detections, correlation and machine-learning-assisted severity prioritization.','https://www.ibm.com/docs/en/security-qradar/security-qradar-siem/saas?topic=qradar-siem-cloud-native-saas-overview'),
('ibm-qradar-siem','siem-threat-hunting-investigation','supported',0.970,'IBM documents correlated, context-enriched alerts and investigation workflows designed to reduce analyst investigation time.','https://www.ibm.com/docs/en/security-qradar/security-qradar-siem/saas?topic=qradar-siem-cloud-native-saas-overview'),
('ibm-qradar-siem','siem-case-management','supported',0.980,'IBM documents automated triage, case creation, correlated cases, prioritization and recommended analyst tasks.','https://www.ibm.com/products/qradar-siem'),

-- Google Security Operations
('google-security-operations','siem-security-data-ingestion','supported',0.990,'Google SecOps documents large-scale security telemetry ingestion, parsing and pipeline management across on-premises and cloud environments.','https://cloud.google.com/security/products/security-information-event-management'),
('google-security-operations','siem-detection-correlation','supported',0.990,'Google SecOps documents curated detections and custom YARA-L detection authoring.','https://cloud.google.com/security/products/security-operations'),
('google-security-operations','siem-threat-hunting-investigation','supported',0.990,'Google SecOps documents context-rich search, investigation and proactive threat hunting across security telemetry.','https://cloud.google.com/security/products/security-operations'),
('google-security-operations','siem-case-management','supported',0.990,'Google SecOps documents threat-centric case management, alert grouping, prioritization, assignment and collaboration.','https://cloud.google.com/security/products/security-operations'),
('google-security-operations','siem-soar-automation','supported',0.990,'Google SecOps includes SOAR playbooks and orchestration across third-party security tools.','https://cloud.google.com/security/products/security-orchestration-automation-response'),
('google-security-operations','siem-threat-intelligence','supported',0.990,'Google SecOps documents threat-intelligence enrichment and applied threat intelligence as part of its unified SIEM/SOAR experience.','https://cloud.google.com/security/products/security-information-event-management');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM sec104_siem_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM sec104_siem_products x JOIN products p ON p.slug=x.product_slug
JOIN modules m ON m.category_id=@siem_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM sec104_siem_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Security analyst mobile-admin coverage is not inferred from general vendor mobile apps.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('microsoft-sentinel','splunk-enterprise-security','ibm-qradar-siem','google-security-operations')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

/* =========================================================
   Privileged Access Management (PAM)
   ========================================================= */
INSERT INTO categories(name,slug,description,is_active) VALUES
('Privileged Access Management (PAM)','privileged-access-management','Platforms for discovering privileged accounts, protecting privileged credentials and secrets, controlling elevated access, monitoring privileged sessions and maintaining auditable privileged-access workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @pam_cat=(SELECT id FROM categories WHERE slug='privileged-access-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@pam_cat,'Privileged Credentials','pam-credentials','Discovery, vaulting, password management and rotation for privileged accounts and secrets.',1),
(@pam_cat,'Privileged Access & Sessions','pam-access-sessions','Controlled privileged access, just-in-time access and privileged session monitoring or recording.',1),
(@pam_cat,'Governance & Audit','pam-governance-audit','Approval workflows, auditing, reporting and operational accountability for privileged access.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,1,1
FROM modules m JOIN (
 SELECT 'pam-credentials' module_slug,'Privileged account discovery & onboarding' name,'pam-account-discovery' slug,'Discover, identify and onboard privileged accounts, credentials, systems or secrets into managed controls.' description UNION ALL
 SELECT 'pam-credentials','Credential / secrets vaulting','pam-credential-vaulting','Securely store and control privileged credentials, passwords, keys or secrets in a managed vault or equivalent protected repository.' UNION ALL
 SELECT 'pam-credentials','Automated password / credential rotation','pam-password-rotation','Automatically change, rotate or synchronize privileged credentials according to policy.' UNION ALL
 SELECT 'pam-access-sessions','Just-in-time / time-bound privileged access','pam-jit-access','Grant privileged access only when needed or for a defined period, reducing persistent or standing privilege.' UNION ALL
 SELECT 'pam-access-sessions','Privileged session monitoring & recording','pam-session-monitoring','Monitor, proxy, record, review or terminate privileged administrative sessions.' UNION ALL
 SELECT 'pam-governance-audit','Audit trails, approvals & reporting','pam-audit-reporting','Maintain searchable audit records, approval workflows, reporting or compliance evidence for privileged access.'
) x ON x.module_slug=m.slug
WHERE m.category_id=@pam_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=1,is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('CyberArk','cyberark','https://www.cyberark.com/','Identity security and privileged access management software vendor.','active'),
('BeyondTrust','beyondtrust','https://www.beyondtrust.com/','Privileged access and identity security software vendor.','active'),
('Delinea','delinea','https://delinea.com/','Privileged access management and identity security software vendor.','active'),
('One Identity','one-identity','https://www.oneidentity.com/','Identity security, access governance and privileged access management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS sec104_pam_products;
CREATE TEMPORARY TABLE sec104_pam_products(vendor_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO sec104_pam_products VALUES
('cyberark','CyberArk Privileged Access Manager','cyberark-privileged-access-manager','Privileged access management for discovering and protecting privileged accounts and credentials, vaulting and rotating credentials, controlling just-in-time access, and monitoring privileged sessions.','https://www.cyberark.com/try-buy/privileged-access-manager-demo/'),
('beyondtrust','BeyondTrust Password Safe','beyondtrust-password-safe','Privileged access management for discovering privileged assets and accounts, securing and rotating credentials and secrets, granting just-in-time access, monitoring sessions and maintaining audit trails.','https://docs.beyondtrust.com/bips/docs/welcome-to-password-safe'),
('delinea','Delinea Secret Server','delinea-secret-server','Enterprise privileged-access vault for discovery, encrypted credential storage, automated password rotation, privileged session monitoring and audit reporting.','https://delinea.com/products/secret-server'),
('one-identity','One Identity Safeguard for Privileged Passwords','one-identity-safeguard-privileged-passwords','Privileged password management for discovering privileged accounts, protecting credentials in a vault, automating access workflows and providing audit/reporting controls.','https://www.oneidentity.com/products/one-identity-safeguard-for-privileged-passwords/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@pam_cat,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM sec104_pam_products x JOIN vendors v ON v.slug=x.vendor_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS sec104_pam_sources;
CREATE TEMPORARY TABLE sec104_pam_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO sec104_pam_sources VALUES
('cyberark-privileged-access-manager','https://www.cyberark.com/try-buy/privileged-access-manager-demo/','CyberArk Privileged Access Manager demo','CyberArk'),
('cyberark-privileged-access-manager','https://www.cyberark.com/solutions/security-risk-management/unixlinux-security/','CyberArk Privileged Access Management','CyberArk'),
('beyondtrust-password-safe','https://docs.beyondtrust.com/bips/docs/welcome-to-password-safe','Welcome to BeyondTrust Password Safe','BeyondTrust'),
('beyondtrust-password-safe','https://docs.beyondtrust.com/bips/docs/password-safe-user-essentials','Password Safe user essentials','BeyondTrust'),
('delinea-secret-server','https://delinea.com/products/secret-server','Delinea Secret Server','Delinea'),
('delinea-secret-server','https://delinea.com/products/secret-server/features/discovery','Secret Server Discovery','Delinea'),
('delinea-secret-server','https://delinea.com/products/secret-server/features/privileged-session-management','Secret Server Privileged Session Management','Delinea'),
('one-identity-safeguard-privileged-passwords','https://www.oneidentity.com/products/one-identity-safeguard-for-privileged-passwords/','Safeguard for Privileged Passwords','One Identity'),
('one-identity-safeguard-privileged-passwords','https://www.oneidentity.com/one-identity-safeguard/','One Identity Safeguard PAM products','One Identity');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM sec104_pam_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS sec104_pam_facts;
CREATE TEMPORARY TABLE sec104_pam_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO sec104_pam_facts VALUES
-- CyberArk Privileged Access Manager
('cyberark-privileged-access-manager','pam-account-discovery','supported',0.990,'CyberArk documents automated discovery of privileged accounts, credentials, IAM roles and secrets across supported environments.','https://www.cyberark.com/solutions/security-risk-management/unixlinux-security/'),
('cyberark-privileged-access-manager','pam-credential-vaulting','supported',0.990,'CyberArk documents policy-based onboarding into a protected Digital Vault; supported credential types should be confirmed for the target estate.','https://www.cyberark.com/solutions/security-risk-management/unixlinux-security/'),
('cyberark-privileged-access-manager','pam-password-rotation','supported',0.990,'CyberArk documents automated policy-based rotation of managed credentials.','https://www.cyberark.com/solutions/security-risk-management/unixlinux-security/'),
('cyberark-privileged-access-manager','pam-jit-access','supported',0.990,'CyberArk documents just-in-time access and zero-standing-privilege approaches for supported resources.','https://www.cyberark.com/solutions/security-risk-management/unixlinux-security/'),
('cyberark-privileged-access-manager','pam-session-monitoring','supported',0.990,'CyberArk documents session isolation, monitoring and centralized session recordings for privileged access.','https://www.cyberark.com/try-buy/privileged-access-manager-demo/'),
('cyberark-privileged-access-manager','pam-audit-reporting','supported',0.990,'CyberArk documents centralized audit logs and auditor review of privileged sessions.','https://www.cyberark.com/try-buy/privileged-access-manager-demo/'),

-- BeyondTrust Password Safe
('beyondtrust-password-safe','pam-account-discovery','supported',0.990,'BeyondTrust documents scanning, identifying and profiling assets and privileged accounts for automated onboarding.','https://docs.beyondtrust.com/bips/docs/welcome-to-password-safe'),
('beyondtrust-password-safe','pam-credential-vaulting','supported',0.990,'Password Safe stores and protects privileged passwords, SSH keys and secrets with controlled access.','https://docs.beyondtrust.com/bips/docs/password-safe-user-essentials'),
('beyondtrust-password-safe','pam-password-rotation','supported',0.990,'BeyondTrust documents automatic generation and rotation of strong random passwords.','https://docs.beyondtrust.com/bips/docs/password-safe-user-essentials'),
('beyondtrust-password-safe','pam-jit-access','supported',0.990,'BeyondTrust documents just-in-time privileged access for only as long as needed.','https://docs.beyondtrust.com/bips/docs/password-safe-user-essentials'),
('beyondtrust-password-safe','pam-session-monitoring','supported',0.990,'BeyondTrust documents real-time privileged-session monitoring plus pause/end controls and session recording.','https://docs.beyondtrust.com/bips/docs/password-safe-user-essentials'),
('beyondtrust-password-safe','pam-audit-reporting','supported',0.990,'BeyondTrust documents a searchable audit trail for privileged requests and sessions.','https://docs.beyondtrust.com/bips/docs/password-safe-user-essentials'),

-- Delinea Secret Server
('delinea-secret-server','pam-account-discovery','supported',0.990,'Delinea documents continuous and rule-based discovery of privileged accounts, passwords, API keys and credentials.','https://delinea.com/products/secret-server/features/discovery'),
('delinea-secret-server','pam-credential-vaulting','supported',0.990,'Secret Server documents an encrypted enterprise-grade vault for privileged credentials.','https://delinea.com/products/secret-server'),
('delinea-secret-server','pam-password-rotation','supported',0.990,'Secret Server documents automated credential management and password rotation.','https://delinea.com/products/secret-server'),
('delinea-secret-server','pam-session-monitoring','supported',0.990,'Delinea documents RDP/SSH proxying, live session monitoring, recording, control and playback.','https://delinea.com/products/secret-server/features/privileged-session-management'),
('delinea-secret-server','pam-audit-reporting','supported',0.980,'Secret Server documents full audit trails, reporting and session accountability; deployment-specific retention should be confirmed.','https://delinea.com/products/secret-server'),

-- One Identity Safeguard for Privileged Passwords
('one-identity-safeguard-privileged-passwords','pam-account-discovery','supported',0.990,'One Identity documents automatic host, directory and network discovery for privileged accounts.','https://www.oneidentity.com/products/one-identity-safeguard-for-privileged-passwords/'),
('one-identity-safeguard-privileged-passwords','pam-credential-vaulting','supported',0.990,'One Identity documents an enterprise password vault for privileged credentials.','https://www.oneidentity.com/products/one-identity-safeguard-for-privileged-passwords/'),
('one-identity-safeguard-privileged-passwords','pam-password-rotation','supported',0.960,'The Safeguard product family manages privileged passwords and workflows; rotation depth should be validated against the selected Safeguard deployment and policy.','https://www.oneidentity.com/one-identity-safeguard/'),
('one-identity-safeguard-privileged-passwords','pam-audit-reporting','supported',0.990,'One Identity documents Activity Center queries, audit reports and approval workflows.','https://www.oneidentity.com/products/one-identity-safeguard-for-privileged-passwords/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM sec104_pam_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM sec104_pam_products x JOIN products p ON p.slug=x.product_slug
JOIN modules m ON m.category_id=@pam_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM sec104_pam_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- General vendor mobile apps do not prove full privileged-administration scope.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('cyberark-privileged-access-manager','beyondtrust-password-safe','delinea-secret-server','one-identity-safeguard-privileged-passwords')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
