-- TechSelectAI security-operations portfolio expansion.
-- Adds new peers to the EXISTING SIEM / Security Operations and PAM taxonomies.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @siem_cat=(SELECT id FROM categories WHERE slug='siem-security-operations' LIMIT 1);
SET @pam_cat=(SELECT id FROM categories WHERE slug='privileged-access-management' LIMIT 1);

-- Reuse taxonomy created in migration 059; fail safely by producing no product rows if the canonical taxonomy is absent.
INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Google Cloud','google-cloud','https://cloud.google.com/','Cloud infrastructure, data, AI and security platform vendor.','active'),
('Fortinet','fortinet','https://www.fortinet.com/','Network and cybersecurity platform vendor.','active'),
('Sumo Logic','sumo-logic','https://www.sumologic.com/','Cloud log analytics, observability and security software vendor.','active'),
('Rapid7','rapid7','https://www.rapid7.com/','Cybersecurity analytics, detection and response software vendor.','active'),
('WALLIX','wallix','https://www.wallix.com/','Privileged access and identity-security software vendor.','active'),
('Keeper Security','keeper-security','https://www.keepersecurity.com/','Password, secrets and privileged-access security software vendor.','active'),
('ARCON','arcon','https://arconnet.com/','Identity security, privileged-access and risk-management software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS sec104_products;
CREATE TEMPORARY TABLE sec104_products(
 vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT
);
INSERT INTO sec104_products VALUES
('google-cloud','siem-security-operations','Google Security Operations','google-security-operations','Cloud-native security operations platform combining SIEM, SOAR and threat intelligence for telemetry collection, threat detection, investigation, case management and response automation.','https://cloud.google.com/security/products/security-operations'),
('fortinet','siem-security-operations','FortiSIEM','fortinet-fortisiem','Security information and event management platform for IT/OT event collection, detection analytics, threat investigation, incident management and built-in response automation.','https://www.fortinet.com/products/siem/fortisiem'),
('sumo-logic','siem-security-operations','Sumo Logic Cloud SIEM','sumo-logic-cloud-siem','Cloud SIEM for collecting and normalizing security telemetry, correlating signals and supporting analyst investigation across cloud and on-premises sources.','https://www.sumologic.com/help/docs/cse/'),
('rapid7','siem-security-operations','Rapid7 SIEM (InsightIDR)','rapid7-siem-insightidr','Cloud-native SIEM and XDR platform for security-data collection, detection, investigation, behavioral analytics and automated response.','https://help.rapid7.com/insightidr/index.html'),
('wallix','privileged-access-management','WALLIX Bastion','wallix-bastion','Privileged access management platform combining privileged credential/password management, session control and recording, discovery and just-in-time access controls.','https://www.wallix.com/products/privileged-access-management/'),
('keeper-security','privileged-access-management','KeeperPAM','keeperpam','Cloud-native privileged access management platform combining enterprise password and secrets management, discovery, remote privileged sessions, just-in-time access and automated credential rotation.','https://www.keepersecurity.com/privileged-access-management/'),
('arcon','privileged-access-management','ARCON Privileged Access Management','arcon-pam','Privileged access management platform for privileged-account discovery, credential protection, granular access control, just-in-time access and monitored or recorded privileged sessions.','https://arconnet.com/privileged-access-management/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM sec104_products x
JOIN vendors v ON v.slug=x.vendor_slug
JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS sec104_sources;
CREATE TEMPORARY TABLE sec104_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO sec104_sources VALUES
('google-security-operations','https://cloud.google.com/security/products/security-operations','Google Security Operations','Google Cloud'),
('google-security-operations','https://cloud.google.com/security/products/security-information-event-management','Google Security Operations - Detect','Google Cloud'),
('google-security-operations','https://cloud.google.com/security/products/security-orchestration-automation-response','Google Security Operations - Respond','Google Cloud'),
('fortinet-fortisiem','https://www.fortinet.com/products/siem/fortisiem','FortiSIEM','Fortinet'),
('sumo-logic-cloud-siem','https://www.sumologic.com/help/docs/cse/','Sumo Logic Cloud SIEM','Sumo Logic'),
('sumo-logic-cloud-siem','https://www.sumologic.com/solutions/security','Sumo Logic Security','Sumo Logic'),
('rapid7-siem-insightidr','https://help.rapid7.com/insightidr/index.html','SIEM (InsightIDR) Overview','Rapid7'),
('rapid7-siem-insightidr','https://docs.rapid7.com/insightidr/advanced-quick-start-guide/','SIEM (InsightIDR) Advanced Quick Start Guide','Rapid7'),
('wallix-bastion','https://www.wallix.com/products/privileged-access-management/','WALLIX Privileged Access Management','WALLIX'),
('keeperpam','https://www.keepersecurity.com/privileged-access-management/','Keeper Privileged Access Management','Keeper Security'),
('arcon-pam','https://arconnet.com/privileged-access-management/','ARCON Privileged Access Management','ARCON');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM sec104_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS sec104_facts;
CREATE TEMPORARY TABLE sec104_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO sec104_facts VALUES
-- Google Security Operations
('google-security-operations','siem-data-ingestion','supported',0.990,'Google documents large-scale telemetry ingestion, parsing and data-pipeline management across cloud and on-premises environments.','https://cloud.google.com/security/products/security-information-event-management'),
('google-security-operations','siem-threat-detection','supported',0.990,'Google documents curated detections, custom YARA-L rules and contextual risk scoring.','https://cloud.google.com/security/products/security-information-event-management'),
('google-security-operations','siem-investigation-hunting','supported',0.990,'Google documents context-rich search, threat investigation, case management and proactive hunting.','https://cloud.google.com/security/products/security-operations'),
('google-security-operations','siem-soar','supported',0.990,'Google Security Operations includes SOAR playbooks and orchestration across third-party security tools.','https://cloud.google.com/security/products/security-orchestration-automation-response'),
('google-security-operations','siem-behavior-risk','partially_supported',0.990,'UEBA and a risk dashboard are documented in the Enterprise package; buyers should verify the selected package.','https://cloud.google.com/security/products/security-operations'),

-- FortiSIEM
('fortinet-fortisiem','siem-data-ingestion','supported',0.990,'Fortinet documents enterprise-wide IT/OT event collection and broad third-party integrations.','https://www.fortinet.com/products/siem/fortisiem'),
('fortinet-fortisiem','siem-threat-detection','supported',0.990,'FortiSIEM documents UEBA, correlation rules, machine-learning models and real-time security analytics.','https://www.fortinet.com/products/siem/fortisiem'),
('fortinet-fortisiem','siem-investigation-hunting','supported',0.990,'Fortinet documents analyst investigation, visual threat hunting, risk prioritization and complete incident management.','https://www.fortinet.com/products/siem/fortisiem'),
('fortinet-fortisiem','siem-soar','supported',0.990,'Fortinet documents built-in SOAR automation and playbooks within FortiSIEM.','https://www.fortinet.com/products/siem/fortisiem'),
('fortinet-fortisiem','siem-behavior-risk','supported',0.980,'Fortinet documents UEBA, customizable machine learning and risk prioritization for security events.','https://www.fortinet.com/products/siem/fortisiem'),

-- Sumo Logic Cloud SIEM
('sumo-logic-cloud-siem','siem-data-ingestion','supported',0.990,'Sumo Logic documents collection of log and event data from on-premises and cloud infrastructure and applications.','https://www.sumologic.com/help/docs/cse/'),
('sumo-logic-cloud-siem','siem-threat-detection','supported',0.980,'Cloud SIEM documents correlation and security-event detection; rule and content coverage varies by configured sources.','https://www.sumologic.com/help/docs/cse/'),
('sumo-logic-cloud-siem','siem-investigation-hunting','supported',0.980,'Sumo Logic documents analyst investigation through Cloud SIEM plus searchable security data.','https://www.sumologic.com/help/docs/cse/'),

-- Rapid7 SIEM (InsightIDR)
('rapid7-siem-insightidr','siem-data-ingestion','supported',0.990,'Rapid7 documents SaaS collection and transformation of telemetry from network-security tools, authentication logs and endpoint devices.','https://help.rapid7.com/insightidr/index.html'),
('rapid7-siem-insightidr','siem-threat-detection','supported',0.990,'Rapid7 documents built-in detections, detection rules and incident detection across unified telemetry.','https://help.rapid7.com/insightidr/index.html'),
('rapid7-siem-insightidr','siem-investigation-hunting','supported',0.990,'Rapid7 documents log search, investigations, endpoint forensics and actionable investigation context.','https://help.rapid7.com/insightidr/index.html'),
('rapid7-siem-insightidr','siem-soar','supported',0.960,'Rapid7 documents automated response capabilities and automation workflows; exact workflow depth depends on the purchased SIEM package and connected tools.','https://docs.rapid7.com/insightidr/advanced-quick-start-guide/'),
('rapid7-siem-insightidr','siem-behavior-risk','supported',0.980,'Rapid7 documents user behavior analytics and correlation of users, accounts, authentications, alerts and privileges.','https://help.rapid7.com/insightidr/index.html'),

-- WALLIX Bastion / WALLIX PAM
('wallix-bastion','pam-discovery','supported',0.980,'WALLIX documents discovery and management of privileged credential activity and automatic asset discovery within its PAM solution.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-vault','supported',0.990,'WALLIX Password Manager manages privileged passwords and credential security as part of Bastion/PAM.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-rotation','supported',0.990,'WALLIX documents password-complexity management and rotation.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-session-monitoring','supported',0.990,'WALLIX documents privileged-session access control and audit trails including video, transcript and metadata.','https://www.wallix.com/products/privileged-access-management/'),
('wallix-bastion','pam-jit-access','supported',0.950,'WALLIX documents least-privilege and just-in-time privilege approaches; exact components and licensing should be confirmed.','https://www.wallix.com/products/privileged-access-management/'),

-- KeeperPAM
('keeperpam','pam-discovery','supported',0.990,'Keeper Discovery provides centralized visibility into privileged accounts and IT assets across local, AWS and Azure environments.','https://www.keepersecurity.com/privileged-access-management/'),
('keeperpam','pam-vault','supported',0.990,'KeeperPAM combines enterprise password management and secrets management for privileged access.','https://www.keepersecurity.com/privileged-access-management/'),
('keeperpam','pam-rotation','supported',0.990,'Keeper documents automated password rotation including post-session credential rotation.','https://www.keepersecurity.com/privileged-access-management/'),
('keeperpam','pam-session-monitoring','supported',0.990,'KeeperPAM documents AI-powered privileged-session monitoring and multi-protocol session recording.','https://www.keepersecurity.com/privileged-access-management/'),
('keeperpam','pam-jit-access','supported',0.990,'KeeperPAM documents time-limited access, ephemeral provisioning and just-in-time access without standing privileges.','https://www.keepersecurity.com/privileged-access-management/'),

-- ARCON PAM
('arcon-pam','pam-discovery','supported',0.990,'ARCON documents auto-discovery and onboarding of privileged IDs, devices, systems and cloud resources.','https://arconnet.com/privileged-access-management/'),
('arcon-pam','pam-vault','supported',0.990,'ARCON documents vaulting, randomization and retrieval of credentials, SSH keys and secrets.','https://arconnet.com/privileged-access-management/'),
('arcon-pam','pam-session-monitoring','supported',0.990,'ARCON documents real-time monitoring, termination, recording and audit trails for privileged sessions.','https://arconnet.com/privileged-access-management/'),
('arcon-pam','pam-jit-access','supported',0.990,'ARCON documents standard just-in-time privilege approaches and least-privilege access controls.','https://arconnet.com/privileged-access-management/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM sec104_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Every new product receives an explicit row for every capability in its canonical category.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM sec104_products x JOIN products p ON p.slug=x.product_slug
JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id
JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM sec104_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Conservative deployment facts only where the official product material is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98 FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('google-security-operations','sumo-logic-cloud-siem','rapid7-siem-insightidr','keeperpam','arcon-pam')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98 FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('fortinet-fortisiem','wallix-bastion','arcon-pam')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Mobile access is explicit unknown until product-specific mobile administrative scope is verified.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('google-security-operations','fortinet-fortisiem','sumo-logic-cloud-siem','rapid7-siem-insightidr','wallix-bastion','keeperpam','arcon-pam')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
