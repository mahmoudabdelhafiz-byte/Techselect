-- TechSelectAI trusted-vendor catalog depth: Endpoint Security / EDR + Backup / Disaster Recovery
-- First-party vendor evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unsupported or unverified capabilities remain not_yet_verified; Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

/* =========================================================
   Endpoint Security / EDR
   ========================================================= */
INSERT INTO categories(name,slug,description,is_active) VALUES
('Endpoint Security / EDR','endpoint-security-edr','Enterprise endpoint protection, endpoint detection and response, ransomware defense, threat hunting and response automation.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @edr_cat=(SELECT id FROM categories WHERE slug='endpoint-security-edr' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@edr_cat,'Endpoint Prevention','endpoint-prevention','Next-generation endpoint prevention, malware and ransomware protection.',1),
(@edr_cat,'Detection & Response','endpoint-detection-response','Endpoint detection, investigation, hunting and response.',1),
(@edr_cat,'Exposure & Operations','endpoint-exposure-operations','Vulnerability/exposure management and operational security controls.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,1,1
FROM modules m JOIN (
 SELECT 'endpoint-prevention' module_slug,'Next-generation endpoint prevention' name,'endpoint-next-gen-prevention' slug,'Behavioral, ML/AI or equivalent endpoint prevention against modern malware and attacks.' description UNION ALL
 SELECT 'endpoint-prevention','Ransomware protection','endpoint-ransomware-protection','Endpoint controls intended to prevent or contain ransomware activity.' UNION ALL
 SELECT 'endpoint-detection-response','Endpoint detection and response (EDR)','endpoint-edr','Detect, investigate and respond to endpoint threats using endpoint telemetry.' UNION ALL
 SELECT 'endpoint-detection-response','Automated investigation / response','endpoint-automated-response','Automated investigation, containment, remediation or response actions.' UNION ALL
 SELECT 'endpoint-detection-response','Threat hunting','endpoint-threat-hunting','Search and investigate endpoint telemetry for suspicious activity and threats.' UNION ALL
 SELECT 'endpoint-exposure-operations','Vulnerability / exposure management','endpoint-vulnerability-management','Identify and prioritize endpoint software, configuration or vulnerability exposure.'
) x ON x.module_slug=m.slug
WHERE m.category_id=@edr_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=1,is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud and security platform vendor.','active'),
('CrowdStrike','crowdstrike','https://www.crowdstrike.com/','Endpoint, cloud and identity security vendor.','active'),
('SentinelOne','sentinelone','https://www.sentinelone.com/','Endpoint, cloud and identity security vendor.','active'),
('Sophos','sophos','https://www.sophos.com/','Cybersecurity and endpoint protection vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@edr_cat,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'microsoft' vendor_slug,'Microsoft Defender for Endpoint' name,'microsoft-defender-for-endpoint' slug,'Enterprise endpoint security for prevention, EDR, automated investigation, hunting and exposure management.' description,'https://www.microsoft.com/en-us/security/business/endpoint-security/microsoft-defender-endpoint' url UNION ALL
 SELECT 'crowdstrike','CrowdStrike Falcon','crowdstrike','Cloud-native endpoint security using Falcon Prevent and Falcon Insight XDR for prevention, detection and response.','https://www.crowdstrike.com/en-us/platform/endpoint-security/' UNION ALL
 SELECT 'sentinelone','SentinelOne Singularity Endpoint','sentinelone','AI-powered endpoint protection and response with autonomous containment and remediation capabilities.','https://www.sentinelone.com/platform/endpoint-protection-platform/' UNION ALL
 SELECT 'sophos','Sophos Endpoint','sophos-endpoint','Endpoint protection with EDR/XDR investigation, threat hunting and ransomware defenses.','https://www.sophos.com/en-us/products/endpoint-security'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'microsoft-defender-for-endpoint' product_slug,'https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint' url,'Microsoft Defender for Endpoint overview' title,'Microsoft' publisher UNION ALL
 SELECT 'microsoft-defender-for-endpoint','https://learn.microsoft.com/en-us/defender-endpoint/','Microsoft Defender for Endpoint documentation','Microsoft' UNION ALL
 SELECT 'crowdstrike','https://www.crowdstrike.com/en-us/platform/endpoint-security/falcon-prevent-ngav/','CrowdStrike Falcon Prevent','CrowdStrike' UNION ALL
 SELECT 'crowdstrike','https://www.crowdstrike.com/en-us/platform/endpoint-security/falcon-insight-xdr/','CrowdStrike Falcon Insight XDR','CrowdStrike' UNION ALL
 SELECT 'sentinelone','https://www.sentinelone.com/platform/endpoint-protection-platform/','SentinelOne Singularity Endpoint','SentinelOne' UNION ALL
 SELECT 'sentinelone','https://www.sentinelone.com/resources/datasheets/singularity-endpoint/','SentinelOne Singularity Endpoint datasheet','SentinelOne' UNION ALL
 SELECT 'sophos-endpoint','https://www.sophos.com/en-us/products/endpoint-security/edr','Sophos Endpoint Detection and Response','Sophos' UNION ALL
 SELECT 'sophos-endpoint','https://www.sophos.com/en-us/products/endpoint-security/threat-hunting','Sophos Endpoint threat hunting','Sophos'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS edr67_facts;
CREATE TEMPORARY TABLE edr67_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO edr67_facts VALUES
('microsoft-defender-for-endpoint','endpoint-next-gen-prevention','supported',0.99,'Plan and platform coverage should be confirmed for the target estate.','https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint'),
('microsoft-defender-for-endpoint','endpoint-ransomware-protection','supported',0.98,'Protection depth depends on enabled Defender controls and policy.','https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint'),
('microsoft-defender-for-endpoint','endpoint-edr','supported',0.99,NULL,'https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint'),
('microsoft-defender-for-endpoint','endpoint-automated-response','supported',0.99,'Automated investigation and response availability depends on plan and configuration.','https://learn.microsoft.com/en-us/defender-endpoint/'),
('microsoft-defender-for-endpoint','endpoint-threat-hunting','supported',0.99,'Advanced hunting is available within the Defender security operations experience.','https://learn.microsoft.com/en-us/defender-endpoint/'),
('microsoft-defender-for-endpoint','endpoint-vulnerability-management','supported',0.98,'Vulnerability-management depth and licensing should be validated for the selected plan.','https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint'),

('crowdstrike','endpoint-next-gen-prevention','supported',0.99,'Falcon Prevent provides next-generation antivirus/prevention; packaging should be confirmed.','https://www.crowdstrike.com/en-us/platform/endpoint-security/falcon-prevent-ngav/'),
('crowdstrike','endpoint-ransomware-protection','supported',0.98,'Falcon Prevent documents ransomware prevention; exact protections vary with enabled modules and policy.','https://www.crowdstrike.com/en-us/platform/endpoint-security/falcon-prevent-ngav/'),
('crowdstrike','endpoint-edr','supported',0.99,'Falcon Insight XDR includes endpoint detection and response capabilities.','https://www.crowdstrike.com/en-us/platform/endpoint-security/falcon-insight-xdr/'),
('crowdstrike','endpoint-automated-response','supported',0.95,'Response automation and containment capabilities depend on licensed Falcon modules and configuration.','https://www.crowdstrike.com/en-us/platform/endpoint-security/falcon-insight-xdr/'),

('sentinelone','endpoint-next-gen-prevention','supported',0.98,'Singularity Endpoint provides endpoint prevention using behavioral/AI techniques; package should be confirmed.','https://www.sentinelone.com/platform/endpoint-protection-platform/'),
('sentinelone','endpoint-ransomware-protection','supported',0.98,'Vendor materials describe ransomware prevention and rollback/remediation capabilities.','https://www.sentinelone.com/platform/endpoint-protection-platform/'),
('sentinelone','endpoint-edr','supported',0.99,'Singularity Endpoint includes autonomous detection and response.','https://www.sentinelone.com/resources/datasheets/singularity-endpoint/'),
('sentinelone','endpoint-automated-response','supported',0.99,'Vendor materials describe autonomous containment, remediation and rollback actions.','https://www.sentinelone.com/platform/endpoint-protection-platform/'),

('sophos-endpoint','endpoint-next-gen-prevention','supported',0.98,'Sophos EDR includes Sophos Endpoint protection; exact package should be confirmed.','https://www.sophos.com/en-us/products/endpoint-security/edr'),
('sophos-endpoint','endpoint-ransomware-protection','supported',0.98,'Sophos documents ransomware defenses within its endpoint protection stack.','https://www.sophos.com/en-us/products/endpoint-security/edr'),
('sophos-endpoint','endpoint-edr','supported',0.99,NULL,'https://www.sophos.com/en-us/products/endpoint-security/edr'),
('sophos-endpoint','endpoint-threat-hunting','supported',0.99,'Sophos documents guided threat hunting across endpoint/server telemetry.','https://www.sophos.com/en-us/products/endpoint-security/threat-hunting');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM edr67_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('microsoft-defender-for-endpoint','crowdstrike','sentinelone','sophos-endpoint')
AND m.category_id=@edr_cat
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM edr67_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

/* =========================================================
   Backup / Disaster Recovery
   ========================================================= */
INSERT INTO categories(name,slug,description,is_active) VALUES
('Backup / Disaster Recovery','backup-disaster-recovery','Enterprise backup, recovery, cyber resilience, immutability and disaster recovery across on-premises, cloud and SaaS workloads.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @bdr_cat=(SELECT id FROM categories WHERE slug='backup-disaster-recovery' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@bdr_cat,'Backup & Workload Protection','backup-workload-protection','Protection of virtual, physical, cloud, database, application and SaaS workloads.',1),
(@bdr_cat,'Recovery & Continuity','backup-recovery-continuity','Rapid recovery, orchestration, failover and disaster recovery.',1),
(@bdr_cat,'Cyber Resilience','backup-cyber-resilience','Immutability, ransomware resilience and clean recovery controls.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.security,1
FROM modules m JOIN (
 SELECT 'backup-workload-protection' module_slug,'Hybrid workload backup' name,'backup-hybrid-workload-protection' slug,'Backup across multiple workload types such as virtual, physical, cloud, database or SaaS environments.' description,0 security UNION ALL
 SELECT 'backup-workload-protection','Multicloud protection','backup-multicloud-protection','Protection or recovery coverage across public-cloud and hybrid environments.',0 UNION ALL
 SELECT 'backup-recovery-continuity','Rapid / instant recovery','backup-rapid-recovery','Fast restore, instant recovery or equivalent accelerated recovery capabilities.',0 UNION ALL
 SELECT 'backup-recovery-continuity','Disaster recovery / failover','backup-disaster-recovery-failover','Orchestrated disaster recovery, replication, failover or cloud recovery capabilities.',1 UNION ALL
 SELECT 'backup-cyber-resilience','Immutable backup protection','backup-immutable-protection','Immutable or tamper-resistant backup protection.',1 UNION ALL
 SELECT 'backup-cyber-resilience','Clean / ransomware-aware recovery','backup-clean-recovery','Controls intended to validate, scan or recover known-good data after cyber incidents.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@bdr_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Veeam','veeam','https://www.veeam.com/','Backup, recovery and data resilience vendor.','active'),
('Commvault','commvault','https://www.commvault.com/','Enterprise data protection and cyber resilience vendor.','active'),
('Cohesity','cohesity','https://www.cohesity.com/','Enterprise data security, backup and recovery vendor.','active'),
('Acronis','acronis','https://www.acronis.com/','Backup, cyber protection and disaster recovery vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@bdr_cat,x.name,x.slug,x.description,x.url,'active',NOW()
FROM vendors v JOIN (
 SELECT 'veeam' vendor_slug,'Veeam Data Platform' name,'veeam' slug,'Enterprise data resilience platform for backup, recovery, immutability, cyber resilience and disaster recovery.' description,'https://www.veeam.com/products/veeam-data-platform.html' url UNION ALL
 SELECT 'commvault','Commvault Cloud','commvault','Enterprise backup, recovery and cyber resilience platform across cloud, on-premises and SaaS workloads.','https://www.commvault.com/platform/backup-and-recovery' UNION ALL
 SELECT 'cohesity','Cohesity DataProtect','cohesity','Enterprise backup and recovery platform with hybrid workload protection, immutable snapshots and rapid recovery.','https://www.cohesity.com/platform/dataprotect/' UNION ALL
 SELECT 'acronis','Acronis Cyber Protect','acronis','Integrated backup, recovery, security and disaster recovery platform for physical, virtual and cloud workloads.','https://www.acronis.com/en/products/cyber-protect/'
) x ON x.vendor_slug=v.slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'veeam' product_slug,'https://www.veeam.com/products/veeam-data-platform.html' url,'Veeam Data Platform' title,'Veeam' publisher UNION ALL
 SELECT 'veeam','https://www.veeam.com/products/veeam-data-platform/backup-recovery.html','Veeam Backup & Recovery','Veeam' UNION ALL
 SELECT 'commvault','https://www.commvault.com/platform/backup-and-recovery','Commvault Backup & Recovery','Commvault' UNION ALL
 SELECT 'commvault','https://www.commvault.com/use-cases/backup-and-recovery','Commvault backup and recovery use case','Commvault' UNION ALL
 SELECT 'cohesity','https://www.cohesity.com/platform/dataprotect/','Cohesity DataProtect','Cohesity' UNION ALL
 SELECT 'cohesity','https://www.cohesity.com/resources/datasheet/cohesity-dataprotect/','Cohesity DataProtect datasheet','Cohesity' UNION ALL
 SELECT 'acronis','https://www.acronis.com/en/products/cyber-protect/','Acronis Cyber Protect','Acronis' UNION ALL
 SELECT 'acronis','https://www.acronis.com/en/products/cyber-protect/components/','Acronis Cyber Protect components','Acronis'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS bdr67_facts;
CREATE TEMPORARY TABLE bdr67_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO bdr67_facts VALUES
('veeam','backup-hybrid-workload-protection','supported',0.99,'Vendor documentation covers virtual, physical, cloud and application workloads; exact workload support should be validated for the selected edition.','https://www.veeam.com/products/veeam-data-platform/backup-recovery.html'),
('veeam','backup-multicloud-protection','supported',0.98,'Public-cloud coverage and features vary by workload and edition.','https://www.veeam.com/products/veeam-data-platform.html'),
('veeam','backup-rapid-recovery','supported',0.99,'Veeam documents instant/accelerated recovery across supported workloads.','https://www.veeam.com/products/veeam-data-platform/backup-recovery.html'),
('veeam','backup-disaster-recovery-failover','supported',0.95,'Orchestrated recovery and DR capabilities vary by Veeam Data Platform edition.','https://www.veeam.com/products/veeam-data-platform.html'),
('veeam','backup-immutable-protection','supported',0.99,NULL,'https://www.veeam.com/products/veeam-data-platform/backup-recovery.html'),
('veeam','backup-clean-recovery','supported',0.98,'Clean-recovery workflows depend on product edition, configuration and security integrations.','https://www.veeam.com/products/veeam-data-platform/backup-recovery.html'),

('commvault','backup-hybrid-workload-protection','supported',0.99,'Commvault documents protection across cloud, on-premises and SaaS workloads.','https://www.commvault.com/platform/backup-and-recovery'),
('commvault','backup-multicloud-protection','supported',0.98,'Cloud coverage should be confirmed for each target workload and subscription.','https://www.commvault.com/platform/backup-and-recovery'),
('commvault','backup-rapid-recovery','supported',0.98,'Commvault positions the platform for rapid recovery; exact RTO depends on architecture and workload.','https://www.commvault.com/use-cases/backup-and-recovery'),
('commvault','backup-clean-recovery','supported',0.95,'Vendor materials describe cyber-resilient recovery; validation should confirm the desired clean-room or recovery workflow.','https://www.commvault.com/use-cases/backup-and-recovery'),

('cohesity','backup-hybrid-workload-protection','supported',0.99,'DataProtect documents protection across virtual, physical, database, cloud and SaaS environments.','https://www.cohesity.com/platform/dataprotect/'),
('cohesity','backup-multicloud-protection','supported',0.98,'Cohesity documents on-premises, cloud and SaaS protection; verify exact target workloads.','https://www.cohesity.com/platform/dataprotect/'),
('cohesity','backup-rapid-recovery','supported',0.99,'Cohesity documents instant mass restore and rapid recovery capabilities.','https://www.cohesity.com/platform/dataprotect/'),
('cohesity','backup-immutable-protection','supported',0.99,'DataProtect documents immutable snapshots and zero-trust controls.','https://www.cohesity.com/platform/dataprotect/'),

('acronis','backup-hybrid-workload-protection','supported',0.99,'Acronis documents physical, virtual and cloud workload backup; exact coverage depends on deployment option/licensing.','https://www.acronis.com/en/products/cyber-protect/'),
('acronis','backup-rapid-recovery','supported',0.98,'Acronis documents rapid recovery capabilities; achievable RTO depends on workload and architecture.','https://www.acronis.com/en/products/cyber-protect/'),
('acronis','backup-disaster-recovery-failover','supported',0.99,'Integrated DR supports replication/failover to Acronis Cloud where enabled.','https://www.acronis.com/en/products/cyber-protect/components/'),
('acronis','backup-immutable-protection','supported',0.98,'Acronis documents immutable backup among Cyber Protect backup features.','https://www.acronis.com/en/products/cyber-protect/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM bdr67_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,c.id,NULL,'not_yet_verified',0
FROM products p CROSS JOIN capabilities c JOIN modules m ON m.id=c.module_id
WHERE p.slug IN('veeam','commvault','cohesity','acronis')
AND m.category_id=@bdr_cat
AND NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM bdr67_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

COMMIT;
