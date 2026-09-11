-- TechSelectAI catalog expansion batch 4 for #257
-- Adds SIEM, Identity & Access Management, Privileged Access Management,
-- Warehouse Management Systems, and Low-Code / BPM.
-- Initial facts are deliberately conservative and use official vendor-owned sources.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('SIEM & Security Operations','siem-security-operations','Security information and event management platforms for centralized security telemetry, detection, investigation and response.',1),
('Identity & Access Management','identity-access-management','Workforce identity and access management platforms for authentication, single sign-on, lifecycle management and access control.',1),
('Privileged Access Management','privileged-access-management','Privileged access management platforms for credential vaulting, privileged account control, session monitoring and least-privilege access.',1),
('Warehouse Management Systems','warehouse-management-systems','Warehouse management software for inventory visibility, inbound and outbound execution, warehouse automation and operational control.',1),
('Low-Code & BPM Platforms','low-code-bpm','Enterprise low-code application development and business process platforms for visual development, workflow automation, integration and governed deployment.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'siem-security-operations' cat,'Security Analytics' name,'siem-analytics' slug,'Security data collection, correlation, detection, investigation and hunting.' description UNION ALL
 SELECT 'siem-security-operations','Response & Automation','siem-response','Incident response, orchestration, automation and analyst workflows.' UNION ALL
 SELECT 'identity-access-management','Authentication & Access','iam-authentication-access','SSO, MFA, passwordless and adaptive access controls.' UNION ALL
 SELECT 'identity-access-management','Identity Lifecycle & Directory','iam-lifecycle-directory','Directory, provisioning, deprovisioning and identity lifecycle management.' UNION ALL
 SELECT 'privileged-access-management','Privileged Credentials','pam-credentials','Privileged credential discovery, vaulting, rotation and access control.' UNION ALL
 SELECT 'privileged-access-management','Privileged Sessions & Least Privilege','pam-sessions','Session monitoring, recording, just-in-time access and privileged activity control.' UNION ALL
 SELECT 'warehouse-management-systems','Warehouse Execution','wms-execution','Inbound, inventory, picking, packing, shipping and warehouse task execution.' UNION ALL
 SELECT 'warehouse-management-systems','Warehouse Optimization & Automation','wms-optimization','Slotting, automation integration, labor/resource orchestration and operational visibility.' UNION ALL
 SELECT 'low-code-bpm','Application Development','lowcode-development','Visual application development for web, mobile and enterprise applications.' UNION ALL
 SELECT 'low-code-bpm','Process, Integration & Governance','lowcode-process-governance','Workflow/process automation, integrations, lifecycle governance and deployment controls.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'siem-analytics' ms,'Central security data ingestion' name,'siem-data-ingestion' slug,'Ingest and centralize security telemetry and logs from multiple sources.' description,1 sec UNION ALL
 SELECT 'siem-analytics','Threat detection & correlation','siem-threat-detection','Detect and correlate suspicious activity across security data.',1 UNION ALL
 SELECT 'siem-analytics','Investigation & threat hunting','siem-investigation-hunting','Search, investigate and hunt across security telemetry and incidents.',1 UNION ALL
 SELECT 'siem-response','Security automation / SOAR','siem-soar','Automate security workflows, orchestration or response actions.',1 UNION ALL
 SELECT 'siem-response','Behavior analytics / risk context','siem-behavior-risk','Use entity, behavior, risk or contextual analytics to improve detection and prioritization.',1 UNION ALL
 SELECT 'iam-authentication-access','Single sign-on (SSO)','iam-sso','Centralized single sign-on to applications and resources.',1 UNION ALL
 SELECT 'iam-authentication-access','Multi-factor authentication','iam-mfa','Require multiple authentication factors for access.',1 UNION ALL
 SELECT 'iam-authentication-access','Adaptive / conditional access','iam-conditional-access','Apply contextual, risk-based or conditional access policies.',1 UNION ALL
 SELECT 'iam-lifecycle-directory','Identity lifecycle provisioning','iam-lifecycle-provisioning','Provision, update and deprovision identities and application access.',1 UNION ALL
 SELECT 'iam-lifecycle-directory','Directory / centralized identity store','iam-directory','Central directory or identity store for workforce identities and groups.',1 UNION ALL
 SELECT 'pam-credentials','Privileged credential vault','pam-vault','Securely store and control privileged credentials and secrets.',1 UNION ALL
 SELECT 'pam-credentials','Credential discovery & onboarding','pam-discovery','Discover and onboard privileged accounts or credentials.',1 UNION ALL
 SELECT 'pam-credentials','Password / secret rotation','pam-rotation','Automate rotation or lifecycle management of privileged passwords and secrets.',1 UNION ALL
 SELECT 'pam-sessions','Privileged session monitoring / recording','pam-session-monitoring','Monitor, record or audit privileged sessions.',1 UNION ALL
 SELECT 'pam-sessions','Just-in-time / least-privilege access','pam-jit-access','Provide time-bound, policy-controlled or least-privilege access to sensitive resources.',1 UNION ALL
 SELECT 'wms-execution','Inventory & location visibility','wms-inventory-visibility','Track warehouse inventory, locations and movements with operational visibility.',0 UNION ALL
 SELECT 'wms-execution','Inbound receiving & putaway','wms-inbound','Manage receiving, putaway and inbound warehouse processes.',0 UNION ALL
 SELECT 'wms-execution','Picking, packing & outbound','wms-outbound','Manage picking, packing, shipping and outbound fulfillment.',0 UNION ALL
 SELECT 'wms-optimization','Warehouse automation integration','wms-automation','Integrate or coordinate with warehouse automation and material-handling systems.',0 UNION ALL
 SELECT 'wms-optimization','Warehouse optimization / orchestration','wms-optimization-orchestration','Optimize slotting, labor, resources, tasks or warehouse execution.',0 UNION ALL
 SELECT 'lowcode-development','Visual low-code development','lowcode-visual-development','Build applications with visual or model-driven low-code development tools.',0 UNION ALL
 SELECT 'lowcode-development','Web & mobile application delivery','lowcode-web-mobile','Build and deliver web and mobile applications.',0 UNION ALL
 SELECT 'lowcode-process-governance','Workflow / process automation','lowcode-workflow-automation','Model and automate workflows or business processes.',0 UNION ALL
 SELECT 'lowcode-process-governance','APIs & enterprise integrations','lowcode-integrations','Connect applications, APIs, data and enterprise systems.',0 UNION ALL
 SELECT 'lowcode-process-governance','Application lifecycle governance','lowcode-governance','Govern development, deployment, security or application lifecycle at enterprise scale.',1
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud, identity, security and application-platform vendor.','active'),
('Splunk','splunk','https://www.splunk.com/','Security and observability software vendor.','active'),
('IBM','ibm','https://www.ibm.com/','Enterprise technology, security, data and AI vendor.','active'),
('Elastic','elastic','https://www.elastic.co/','Search, observability and security software vendor.','active'),
('Okta','okta','https://www.okta.com/','Identity and access management vendor.','active'),
('Ping Identity','ping-identity','https://www.pingidentity.com/','Enterprise identity security and access management vendor.','active'),
('JumpCloud','jumpcloud','https://jumpcloud.com/','Cloud directory, identity, access and device management vendor.','active'),
('CyberArk','cyberark','https://www.cyberark.com/','Identity security and privileged access management vendor.','active'),
('BeyondTrust','beyondtrust','https://www.beyondtrust.com/','Identity security and privileged access management vendor.','active'),
('Delinea','delinea','https://delinea.com/','Identity security and privileged access management vendor.','active'),
('ManageEngine','manageengine','https://www.manageengine.com/','Enterprise IT operations, security and privileged access software vendor.','active'),
('SAP','sap','https://www.sap.com/','Enterprise application and supply-chain software vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise application, database, cloud and supply-chain software vendor.','active'),
('Manhattan Associates','manhattan-associates','https://www.manh.com/','Supply-chain commerce and warehouse management software vendor.','active'),
('Blue Yonder','blue-yonder','https://blueyonder.com/','Supply-chain planning, execution and warehouse software vendor.','active'),
('Mendix','mendix','https://www.mendix.com/','Enterprise low-code application development platform vendor.','active'),
('OutSystems','outsystems','https://www.outsystems.com/','Enterprise low-code application development platform vendor.','active'),
('Appian','appian','https://appian.com/','Enterprise process automation and low-code platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat59_products;
CREATE TEMPORARY TABLE cat59_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,source_url TEXT,source_title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat59_products VALUES
('microsoft','siem-security-operations','Microsoft Sentinel','microsoft-sentinel','Cloud-native SIEM for security data collection, detection, investigation and automated response across multi-cloud and multiplatform environments.','https://www.microsoft.com/en-us/security/business/siem-and-xdr/microsoft-sentinel-siem','Microsoft Sentinel SIEM','Microsoft'),
('splunk','siem-security-operations','Splunk Enterprise Security','splunk-enterprise-security','Security operations platform combining SIEM, threat detection, investigation, response, automation and behavior analytics.','https://www.splunk.com/en_us/products/enterprise-security.html','Splunk Enterprise Security','Splunk'),
('ibm','siem-security-operations','IBM QRadar SIEM','ibm-qradar-siem','Enterprise SIEM for centralized security visibility, threat detection, investigation and compliance-oriented security operations.','https://www.ibm.com/products/qradar-siem','IBM QRadar SIEM','IBM'),
('elastic','siem-security-operations','Elastic Security','elastic-security','Unified security platform with SIEM, detection, investigation, threat hunting and response capabilities built on Elasticsearch.','https://www.elastic.co/security/siem','Elastic SIEM','Elastic'),
('microsoft','identity-access-management','Microsoft Entra ID','microsoft-entra-id','Cloud identity and access management for workforce identities, authentication, SSO, conditional access and identity lifecycle administration.','https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id','Microsoft Entra ID','Microsoft'),
('okta','identity-access-management','Okta Workforce Identity','okta-workforce-identity','Workforce identity platform combining SSO, adaptive MFA, lifecycle management, governance and access security.','https://www.okta.com/products/workforce-identity/','Okta Workforce Identity','Okta'),
('ping-identity','identity-access-management','PingOne for Workforce','pingone-for-workforce','Cloud workforce identity solution for centralized authentication, SSO, MFA and adaptive access across enterprise applications.','https://www.pingidentity.com/en/platform/pingone-for-workforce.html','PingOne for Workforce','Ping Identity'),
('jumpcloud','identity-access-management','JumpCloud','jumpcloud-identity-platform','Cloud identity and access platform combining directory, SSO, MFA, lifecycle management and access controls across applications and infrastructure.','https://jumpcloud.com/','JumpCloud Identity and Access Platform','JumpCloud'),
('cyberark','privileged-access-management','CyberArk Privilege Cloud','cyberark-privilege-cloud','SaaS privileged access management for securing, controlling and monitoring privileged credentials and sessions across hybrid environments.','https://www.cyberark.com/resources/all-blog-posts/cyberark-privilege-cloud-version-14-7-release','CyberArk Privilege Cloud 14.7','CyberArk'),
('beyondtrust','privileged-access-management','BeyondTrust Password Safe','beyondtrust-password-safe','Privileged access management for discovering, vaulting, rotating and controlling privileged credentials with monitored sessions and just-in-time access.','https://www.beyondtrust.com/password-management','BeyondTrust Password Safe','BeyondTrust'),
('delinea','privileged-access-management','Delinea Secret Server','delinea-secret-server','Enterprise privileged access management vault for discovering, securing, rotating and auditing privileged credentials and sessions.','https://delinea.com/products/secret-server','Delinea Secret Server','Delinea'),
('manageengine','privileged-access-management','ManageEngine PAM360','manageengine-pam360','Unified privileged access management platform for privileged credentials, access control, remote access, sessions and governance.','https://www.manageengine.com/privileged-access-management/','ManageEngine PAM360','ManageEngine'),
('sap','warehouse-management-systems','SAP Extended Warehouse Management','sap-extended-warehouse-management','Warehouse management system for high-volume warehouse execution, inventory visibility, automation integration and resource optimization.','https://www.sap.com/products/scm/extended-warehouse-management.html','SAP Extended Warehouse Management','SAP'),
('oracle','warehouse-management-systems','Oracle Fusion Cloud Warehouse Management','oracle-fusion-cloud-warehouse-management','Cloud-native warehouse management for complex fulfillment, inventory accuracy, warehouse execution, automation and operational visibility.','https://docs.oracle.com/en/cloud/saas/warehouse-management/26b/index.html','Oracle Warehouse Management','Oracle'),
('manhattan-associates','warehouse-management-systems','Manhattan Active Warehouse Management','manhattan-active-warehouse-management','Cloud-native warehouse management platform unifying distribution, labor, automation and real-time warehouse execution.','https://www.manh.com/solutions/supply-chain-management-software/warehouse-management','Manhattan Warehouse Management','Manhattan Associates'),
('blue-yonder','warehouse-management-systems','Blue Yonder Warehouse Management','blue-yonder-warehouse-management','Warehouse management and execution platform for inbound, inventory, outbound, resource orchestration, slotting and automation.','https://blueyonder.com/solutions/warehouse-management','Blue Yonder Warehouse Management','Blue Yonder'),
('microsoft','low-code-bpm','Microsoft Power Apps','microsoft-power-apps','Enterprise low-code platform for building business applications and modernizing processes using visual development and connectors.','https://learn.microsoft.com/en-us/power-apps/','Power Apps documentation','Microsoft'),
('mendix','low-code-bpm','Mendix','mendix-platform','Enterprise low-code platform for creating, deploying and governing web, mobile and process-oriented applications across cloud and on-premises environments.','https://www.mendix.com/','Mendix Platform','Mendix'),
('outsystems','low-code-bpm','OutSystems','outsystems-platform','Enterprise low-code platform for full-stack web and mobile application development, workflow automation and governed delivery.','https://www.outsystems.com/low-code-platform/application-development','OutSystems Application Development','OutSystems'),
('appian','low-code-bpm','Appian Platform','appian-platform','Enterprise low-code process platform for visual application development, workflow orchestration, data integration and governed deployment.','https://appian.com/products/platform/low-code','Appian Low-Code','Appian');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.source_url,'active',NOW()
FROM cat59_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.source_url,x.source_title,x.publisher,1,'verified','high',NOW()
FROM cat59_products x JOIN products p ON p.slug=x.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.source_url);

DROP TEMPORARY TABLE IF EXISTS cat59_facts;
CREATE TEMPORARY TABLE cat59_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3));

INSERT INTO cat59_facts
SELECT p.product_slug,c.capability_slug,'supported',0.92 FROM
(SELECT 'microsoft-sentinel' product_slug UNION ALL SELECT 'splunk-enterprise-security' UNION ALL SELECT 'ibm-qradar-siem' UNION ALL SELECT 'elastic-security') p
CROSS JOIN
(SELECT 'siem-data-ingestion' capability_slug UNION ALL SELECT 'siem-threat-detection' UNION ALL SELECT 'siem-investigation-hunting') c;
INSERT INTO cat59_facts VALUES
('microsoft-sentinel','siem-soar','supported',0.96),('microsoft-sentinel','siem-behavior-risk','supported',0.94),
('splunk-enterprise-security','siem-soar','supported',0.95),('splunk-enterprise-security','siem-behavior-risk','supported',0.94),
('elastic-security','siem-soar','supported',0.90),('ibm-qradar-siem','siem-behavior-risk','supported',0.88);

INSERT INTO cat59_facts
SELECT p.product_slug,c.capability_slug,'supported',0.94 FROM
(SELECT 'microsoft-entra-id' product_slug UNION ALL SELECT 'okta-workforce-identity' UNION ALL SELECT 'pingone-for-workforce' UNION ALL SELECT 'jumpcloud-identity-platform') p
CROSS JOIN
(SELECT 'iam-sso' capability_slug UNION ALL SELECT 'iam-mfa') c;
INSERT INTO cat59_facts VALUES
('microsoft-entra-id','iam-conditional-access','supported',0.99),('microsoft-entra-id','iam-lifecycle-provisioning','supported',0.97),('microsoft-entra-id','iam-directory','supported',0.98),
('okta-workforce-identity','iam-conditional-access','supported',0.95),('okta-workforce-identity','iam-lifecycle-provisioning','supported',0.97),
('pingone-for-workforce','iam-conditional-access','supported',0.94),('pingone-for-workforce','iam-directory','supported',0.90),
('jumpcloud-identity-platform','iam-conditional-access','supported',0.95),('jumpcloud-identity-platform','iam-lifecycle-provisioning','supported',0.97),('jumpcloud-identity-platform','iam-directory','supported',0.99);

INSERT INTO cat59_facts
SELECT p.product_slug,c.capability_slug,'supported',0.93 FROM
(SELECT 'cyberark-privilege-cloud' product_slug UNION ALL SELECT 'beyondtrust-password-safe' UNION ALL SELECT 'delinea-secret-server' UNION ALL SELECT 'manageengine-pam360') p
CROSS JOIN
(SELECT 'pam-vault' capability_slug UNION ALL SELECT 'pam-session-monitoring') c;
INSERT INTO cat59_facts VALUES
('cyberark-privilege-cloud','pam-discovery','supported',0.93),('cyberark-privilege-cloud','pam-rotation','supported',0.91),('cyberark-privilege-cloud','pam-jit-access','supported',0.90),
('beyondtrust-password-safe','pam-discovery','supported',0.98),('beyondtrust-password-safe','pam-rotation','supported',0.98),('beyondtrust-password-safe','pam-jit-access','supported',0.97),
('delinea-secret-server','pam-discovery','supported',0.98),('delinea-secret-server','pam-rotation','supported',0.98),
('manageengine-pam360','pam-discovery','supported',0.92),('manageengine-pam360','pam-jit-access','supported',0.90);

INSERT INTO cat59_facts
SELECT p.product_slug,c.capability_slug,'supported',0.92 FROM
(SELECT 'sap-extended-warehouse-management' product_slug UNION ALL SELECT 'oracle-fusion-cloud-warehouse-management' UNION ALL SELECT 'manhattan-active-warehouse-management' UNION ALL SELECT 'blue-yonder-warehouse-management') p
CROSS JOIN
(SELECT 'wms-inventory-visibility' capability_slug UNION ALL SELECT 'wms-inbound' UNION ALL SELECT 'wms-outbound') c;
INSERT INTO cat59_facts VALUES
('sap-extended-warehouse-management','wms-automation','supported',0.98),('sap-extended-warehouse-management','wms-optimization-orchestration','supported',0.96),
('oracle-fusion-cloud-warehouse-management','wms-automation','supported',0.97),
('manhattan-active-warehouse-management','wms-automation','supported',0.95),('manhattan-active-warehouse-management','wms-optimization-orchestration','supported',0.96),
('blue-yonder-warehouse-management','wms-automation','supported',0.96),('blue-yonder-warehouse-management','wms-optimization-orchestration','supported',0.98);

INSERT INTO cat59_facts
SELECT p.product_slug,'lowcode-visual-development','supported',0.96 FROM
(SELECT 'microsoft-power-apps' product_slug UNION ALL SELECT 'mendix-platform' UNION ALL SELECT 'outsystems-platform' UNION ALL SELECT 'appian-platform') p;
INSERT INTO cat59_facts VALUES
('microsoft-power-apps','lowcode-web-mobile','supported',0.90),('microsoft-power-apps','lowcode-integrations','supported',0.93),
('mendix-platform','lowcode-web-mobile','supported',0.98),('mendix-platform','lowcode-workflow-automation','supported',0.92),('mendix-platform','lowcode-integrations','supported',0.95),('mendix-platform','lowcode-governance','supported',0.96),
('outsystems-platform','lowcode-web-mobile','supported',0.99),('outsystems-platform','lowcode-workflow-automation','supported',0.96),('outsystems-platform','lowcode-integrations','supported',0.98),('outsystems-platform','lowcode-governance','supported',0.95),
('appian-platform','lowcode-web-mobile','supported',0.94),('appian-platform','lowcode-workflow-automation','supported',0.99),('appian-platform','lowcode-integrations','supported',0.96),('appian-platform','lowcode-governance','supported',0.96);

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,NOW()
FROM cat59_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat59_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Official vendor-owned source; broad category capability only.'
FROM cat59_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN cat59_products x ON x.product_slug=p.slug
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=x.source_url;

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.90 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('microsoft-sentinel','splunk-enterprise-security','elastic-security','microsoft-entra-id','okta-workforce-identity','pingone-for-workforce','jumpcloud-identity-platform','cyberark-privilege-cloud','oracle-fusion-cloud-warehouse-management','manhattan-active-warehouse-management','microsoft-power-apps','mendix-platform','outsystems-platform','appian-platform')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

COMMIT;
