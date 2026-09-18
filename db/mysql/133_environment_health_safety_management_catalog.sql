-- TechSelectAI Environment, Health & Safety (EHS) Management catalog expansion.
-- Adds one canonical enterprise EHS category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Environment, Health & Safety (EHS) Management Platforms','environment-health-safety-management','Enterprise EHS software for incident and near-miss management, audits and inspections, operational risk, permit/control-of-work, occupational health, industrial hygiene, environmental compliance, corrective actions, analytics and multi-site governance.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @ehs_cat=(SELECT id FROM categories WHERE slug='environment-health-safety-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@ehs_cat,'Safety, Risk & Operational Control','ehs-safety-risk','Incident management, audits and inspections, risk assessment, job-safety analysis and permit/control-of-work processes.',1),
(@ehs_cat,'Worker Health, Environment & EHS Governance','ehs-health-environment-governance','Occupational health, industrial hygiene, environmental/regulatory compliance, corrective actions, analytics and enterprise EHS governance.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'ehs-safety-risk' module_slug,'Incident, injury & near-miss management' name,'ehs-incident-nearmiss' slug,'Capture, investigate and analyze incidents, injuries, illnesses, near misses and observations, including root-cause and follow-up workflows.' description,0 sec UNION ALL
 SELECT 'ehs-safety-risk','Audits & inspections','ehs-audits-inspections','Plan, execute and track EHS audits, field inspections, findings and follow-up actions using standardized or configurable checklists.' description,0 UNION ALL
 SELECT 'ehs-safety-risk','Hazard, risk, JSA/JHA & assessment management','ehs-risk-assessment','Identify hazards, conduct job/task/process risk assessments, apply controls and maintain risk registers or equivalent safety-risk workflows.' description,0 UNION ALL
 SELECT 'ehs-safety-risk','Permit to work & control of work','ehs-permit-control-work','Digitize permits, work authorizations or control-of-work processes and coordinate operational risk controls for hazardous work where explicitly supported.' description,0 UNION ALL
 SELECT 'ehs-health-environment-governance','Occupational health & worker case management','ehs-occupational-health','Manage occupational-health cases, medical surveillance, claims, work restrictions or employee health records where explicitly documented.' description,0 UNION ALL
 SELECT 'ehs-health-environment-governance','Industrial hygiene & exposure management','ehs-industrial-hygiene','Assess and track worker exposure to chemical, physical or biological agents, including sampling, monitoring and exposure-control workflows.' description,0 UNION ALL
 SELECT 'ehs-health-environment-governance','Environmental compliance & operational permits','ehs-environmental-compliance','Manage air, water, waste, chemicals, environmental permits, reporting and other environmental-compliance obligations where supported.' description,0 UNION ALL
 SELECT 'ehs-health-environment-governance','Regulatory obligations, CAPA & action tracking','ehs-regulatory-actions','Track regulatory obligations, corrective/preventive actions, remediation tasks, due dates, evidence and closeout across EHS workflows.' description,0 UNION ALL
 SELECT 'ehs-health-environment-governance','EHS analytics, dashboards & KPIs','ehs-analytics-kpis','Provide safety/environmental dashboards, leading and lagging indicators, trends, executive reporting and configurable EHS analytics.' description,0 UNION ALL
 SELECT 'ehs-health-environment-governance','Enterprise multi-site governance & integration','ehs-enterprise-integration-scale','Standardize EHS processes across sites and integrate with HR, ERP, IoT, content, business or other enterprise systems through supported APIs/interfaces.' description,0
) x ON x.module_slug=m.slug
WHERE m.category_id=@ehs_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Intelex','intelex','https://www.intelex.com/','Enterprise EHS, quality, ESG and operational-risk software vendor.','active'),
('Cority','cority','https://www.cority.com/','Enterprise EHS, occupational health, environmental and sustainability software vendor.','active'),
('Sphera','sphera','https://sphera.com/','EHS, sustainability, operational risk and product-stewardship software vendor.','active'),
('Wolters Kluwer','wolters-kluwer','https://www.wolterskluwer.com/','Enterprise information and software provider and owner of Enablon.','active'),
('Benchmark Gensuite','benchmark-gensuite','https://benchmarkgensuite.com/','Enterprise EHS, sustainability, quality and operational-risk software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat133_products;
CREATE TEMPORARY TABLE cat133_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat133_products VALUES
('intelex','environment-health-safety-management','Intelex EHS Platform','intelex-ehs-platform','Enterprise EHS platform with modular applications for incidents, audits, inspections, operational risk, permit to work, occupational health, industrial hygiene, environmental compliance, analytics, mobile/offline workflows and enterprise integration.','https://www.intelex.com/ehs-platform/'),
('cority','environment-health-safety-management','CorityOne','corityone','Converged enterprise EHS+ SaaS platform spanning safety, occupational health, industrial hygiene, environmental management, compliance, quality, analytics and multi-site operations.','https://www.cority.com/corityone/'),
('sphera','environment-health-safety-management','SpheraCloud EHS','spheracloud-ehs','SaaS-based enterprise EHS and operational-intelligence platform for incident management, risk assessment, audits, actions, environmental compliance, analytics and globally scaled safety programs.','https://sphera.com/spheracloud-platform/'),
('wolters-kluwer','environment-health-safety-management','Enablon Vision Platform','enablon-vision-platform','Integrated SaaS-enabled enterprise risk platform combining EHSQ, sustainability, operational risk, process safety, control of work, analytics, mobile workflows and enterprise integration.','https://www.wolterskluwer.com/en/solutions/enablon/vision-platform'),
('benchmark-gensuite','environment-health-safety-management','Benchmark Gensuite EHS','benchmark-gensuite-ehs','Unified enterprise EHS suite for incidents, CAPA, audits/inspections, regulatory obligations, environmental compliance, risk, analytics and global mobile-enabled EHS governance.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat133_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat133_sources;
CREATE TEMPORARY TABLE cat133_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat133_sources VALUES
('intelex-ehs-platform','https://www.intelex.com/ehs-platform/','Intelex EHS Platform','Intelex'),
('intelex-ehs-platform','https://www.intelex.com/products/health-safety/','Intelex Health and Safety Management','Intelex'),
('intelex-ehs-platform','https://www.intelex.com/products/health-safety/applications/','Intelex Health and Safety Applications','Intelex'),
('intelex-ehs-platform','https://www.intelex.com/products/applications/incident-management-software/','Intelex Incident Management','Intelex'),
('intelex-ehs-platform','https://www.intelex.com/products/applications/inspection-management-software/','Intelex Inspections Management','Intelex'),
('intelex-ehs-platform','https://www.intelex.com/products/environment/','Intelex Environmental Management','Intelex'),
('intelex-ehs-platform','https://www.intelex.com/risk-management/ehs-compliance-risk','Intelex EHS Compliance and Risk','Intelex'),
('corityone','https://www.cority.com/corityone/','CorityOne Platform','Cority'),
('corityone','https://www.cority.com/safety-cloud/','Cority Safety Cloud','Cority'),
('corityone','https://www.cority.com/corityone/incident-management-software/','Cority Incident Management','Cority'),
('corityone','https://www.cority.com/corityone/compliance-management-software/','Cority Compliance Management','Cority'),
('corityone','https://www.cority.com/health-cloud/occupational-health-solutions/','Cority Occupational Health','Cority'),
('corityone','https://www.cority.com/corityone/risk-management-software/','Cority Risk Management','Cority'),
('corityone','https://www.cority.com/technology-vision/','Cority Technology Vision','Cority'),
('spheracloud-ehs','https://sphera.com/spheracloud-platform/','SpheraCloud Platform','Sphera'),
('spheracloud-ehs','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/','SpheraCloud Health and Safety Management','Sphera'),
('spheracloud-ehs','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/incident-management-software/','Sphera Incident Management','Sphera'),
('spheracloud-ehs','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/audits-software/','Sphera Audits Software','Sphera'),
('spheracloud-ehs','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/risk-assessment-software/','Sphera Risk Assessment','Sphera'),
('spheracloud-ehs','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/actions-software/','Sphera Actions Software','Sphera'),
('spheracloud-ehs','https://sphera.com/solutions/environment-health-safety-sustainability/','Sphera EHS and Sustainability','Sphera'),
('enablon-vision-platform','https://www.wolterskluwer.com/en/solutions/enablon/vision-platform','Enablon Vision Platform','Wolters Kluwer'),
('enablon-vision-platform','https://www.wolterskluwer.com/en/solutions/enablon/ehsq-sustainability','Enablon EHS Software','Wolters Kluwer'),
('enablon-vision-platform','https://www.wolterskluwer.com/en/solutions/enablon/health-safety-software','Enablon Health and Safety','Wolters Kluwer'),
('enablon-vision-platform','https://www.wolterskluwer.com/en/solutions/enablon/environmental-management-software','Enablon Environmental Management','Wolters Kluwer'),
('enablon-vision-platform','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software','Enablon Control of Work','Wolters Kluwer'),
('benchmark-gensuite-ehs','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/','Benchmark Gensuite EHS Software','Benchmark Gensuite'),
('benchmark-gensuite-ehs','https://benchmarkgensuite.com/app/audit-management-software/','Benchmark Gensuite Audit Management','Benchmark Gensuite'),
('benchmark-gensuite-ehs','https://benchmarkgensuite.com/app/regulatory-audit-software/','Benchmark Gensuite Regulatory Auditing','Benchmark Gensuite'),
('benchmark-gensuite-ehs','https://benchmarkgensuite.com/app/mobile/','Benchmark Gensuite Mobile','Benchmark Gensuite');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat133_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat133_facts;
CREATE TEMPORARY TABLE cat133_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat133_facts VALUES
-- Intelex EHS Platform
('intelex-ehs-platform','ehs-incident-nearmiss','supported',0.990,'Intelex supports incident/injury/illness/near-miss reporting, investigation, root-cause analysis and corrective actions through its EHS applications.','https://www.intelex.com/products/applications/incident-management-software/'),
('intelex-ehs-platform','ehs-audits-inspections','supported',0.990,'Intelex provides configurable audit and inspection management with field/mobile and offline workflows.','https://www.intelex.com/products/applications/inspection-management-software/'),
('intelex-ehs-platform','ehs-risk-assessment','supported',0.990,'Intelex Health and Safety includes Job Safety Analysis, Process Hazard Analysis and risk-management applications.','https://www.intelex.com/products/health-safety/'),
('intelex-ehs-platform','ehs-permit-control-work','supported',0.990,'Permit to Work is an explicit Intelex Health and Safety application; entitlement depends on the licensed application bundle.','https://www.intelex.com/products/health-safety/applications/'),
('intelex-ehs-platform','ehs-occupational-health','supported',0.990,'Intelex explicitly provides Occupational Health and worker case/claims management applications.','https://www.intelex.com/products/health-safety/'),
('intelex-ehs-platform','ehs-industrial-hygiene','supported',0.990,'Intelex Health and Safety explicitly includes Industrial Hygiene Management and exposure assessment.','https://www.intelex.com/products/health-safety/'),
('intelex-ehs-platform','ehs-environmental-compliance','supported',0.990,'Intelex Environmental Management covers environmental compliance programs, air/water/waste and related reporting.','https://www.intelex.com/products/environment/'),
('intelex-ehs-platform','ehs-regulatory-actions','supported',0.980,'Intelex combines compliance/risk workflows, root-cause analysis and corrective-action functions; individual regulatory-content applications may require separate licensing.','https://www.intelex.com/risk-management/ehs-compliance-risk'),
('intelex-ehs-platform','ehs-analytics-kpis','supported',0.990,'Business Intelligence & Analytics is a core Intelex Platform capability supporting EHS dashboards and reporting.','https://www.intelex.com/ehs-platform/'),
('intelex-ehs-platform','ehs-enterprise-integration-scale','supported',0.990,'Intelex is designed as a scalable enterprise EHS platform and includes API access/integration capabilities; application scope depends on licensed modules.','https://www.intelex.com/ehs-platform/'),

-- CorityOne
('corityone','ehs-incident-nearmiss','supported',0.990,'CorityOne Safety covers incident, injury and near-miss management with investigation and corrective-action workflows.','https://www.cority.com/corityone/incident-management-software/'),
('corityone','ehs-audits-inspections','supported',0.990,'CorityOne provides inspections, audits and field safety workflows across its Safety Cloud.','https://www.cority.com/safety-cloud/'),
('corityone','ehs-risk-assessment','supported',0.990,'CorityOne Risk Management supports enterprise and operational risk assessment and control workflows.','https://www.cority.com/corityone/risk-management-software/'),
('corityone','ehs-permit-control-work','supported',0.980,'Permit-to-work is supported within Cority safety/process workflows, but exact packaging should be validated for the selected CorityOne configuration.','https://www.cority.com/safety-cloud/'),
('corityone','ehs-occupational-health','supported',0.990,'Cority Occupational Health supports employee health, case management, surveillance and related worker-health workflows.','https://www.cority.com/health-cloud/occupational-health-solutions/'),
('corityone','ehs-industrial-hygiene','supported',0.990,'CorityOne Health includes industrial-hygiene and exposure-management functionality as part of the broader EHS+ platform.','https://www.cority.com/corityone/'),
('corityone','ehs-environmental-compliance','supported',0.990,'CorityOne converges environmental management and compliance with safety, health, quality and ESG workflows.','https://www.cority.com/corityone/'),
('corityone','ehs-regulatory-actions','supported',0.990,'Cority Compliance Management centralizes obligations, regulatory tasks and actions with evidence and workflow tracking.','https://www.cority.com/corityone/compliance-management-software/'),
('corityone','ehs-analytics-kpis','supported',0.990,'CorityOne includes platform analytics and enterprise EHS performance reporting.','https://www.cority.com/corityone/'),
('corityone','ehs-enterprise-integration-scale','supported',0.990,'CorityOne is positioned as a secure scalable SaaS platform for global organizations with RESTful integration capabilities.','https://www.cority.com/technology-vision/'),

-- SpheraCloud EHS
('spheracloud-ehs','ehs-incident-nearmiss','supported',0.990,'SpheraCloud Incident Management supports incident, near-miss and observation reporting, investigation, root cause and corrective action.','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/incident-management-software/'),
('spheracloud-ehs','ehs-audits-inspections','supported',0.990,'Sphera Audits centralizes planning, scheduling, inspections, findings and corrective/preventive actions with mobile/offline execution.','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/audits-software/'),
('spheracloud-ehs','ehs-risk-assessment','supported',0.990,'Sphera Risk Assessment provides enterprise-wide job-based hazard/risk assessment and control workflows.','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/risk-assessment-software/'),
('spheracloud-ehs','ehs-permit-control-work','partially_supported',0.970,'Sphera offers Control of Work/operational-risk capabilities in its broader portfolio, but permit-to-work is not inferred as universally included in the Health and Safety suite.','https://sphera.com/solutions/environment-health-safety-sustainability/'),
('spheracloud-ehs','ehs-environmental-compliance','supported',0.990,'SpheraCloud Environmental Accounting and Operational Compliance cover air, water, waste and environmental reporting/compliance.','https://sphera.com/solutions/environment-health-safety-sustainability/'),
('spheracloud-ehs','ehs-regulatory-actions','supported',0.990,'Sphera Actions supports corrective/preventive actions, remediation, assignments, alerts and multi-site action closeout.','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/actions-software/'),
('spheracloud-ehs','ehs-analytics-kpis','supported',0.990,'SpheraCloud Health and Safety provides real-time reporting, trends, risk insights and analytics across organizational levels.','https://sphera.com/solutions/environment-health-safety-sustainability/health-and-safety-management-software/'),
('spheracloud-ehs','ehs-enterprise-integration-scale','supported',0.990,'SpheraCloud is a SaaS-based mobile platform designed from single-site deployments through global enterprise rollouts.','https://sphera.com/spheracloud-platform/'),

-- Enablon Vision Platform
('enablon-vision-platform','ehs-incident-nearmiss','supported',0.990,'Enablon EHS supports incident management, investigations, root-cause workflows and safety observations within the integrated platform.','https://www.wolterskluwer.com/en/solutions/enablon/health-safety-software'),
('enablon-vision-platform','ehs-audits-inspections','supported',0.990,'Enablon EHS includes audit and inspection management within the integrated Vision Platform.','https://www.wolterskluwer.com/en/solutions/enablon/ehsq-sustainability'),
('enablon-vision-platform','ehs-risk-assessment','supported',0.990,'Enablon provides integrated EHS and operational-risk workflows including job hazard analysis and risk/control management.','https://www.wolterskluwer.com/en/solutions/enablon/health-safety-software'),
('enablon-vision-platform','ehs-permit-control-work','partially_supported',0.990,'Enablon provides dedicated Control of Work and permit-to-work applications in the broader Vision portfolio rather than assuming universal base EHS entitlement.','https://www.wolterskluwer.com/en/solutions/enablon/control-of-work-software'),
('enablon-vision-platform','ehs-occupational-health','supported',0.990,'Enablon Health & Safety explicitly includes occupational-health workflows within the EHS suite.','https://www.wolterskluwer.com/en/solutions/enablon/health-safety-software'),
('enablon-vision-platform','ehs-industrial-hygiene','supported',0.990,'Enablon Health & Safety explicitly includes industrial-hygiene management.','https://www.wolterskluwer.com/en/solutions/enablon/health-safety-software'),
('enablon-vision-platform','ehs-environmental-compliance','supported',0.990,'Enablon Environmental Management supports air, water, waste, chemicals, permits and environmental reporting.','https://www.wolterskluwer.com/en/solutions/enablon/environmental-management-software'),
('enablon-vision-platform','ehs-regulatory-actions','supported',0.990,'Enablon combines regulatory compliance with CAPA/action-plan management and cross-workflow corrective actions.','https://www.wolterskluwer.com/en/solutions/enablon/ehsq-sustainability'),
('enablon-vision-platform','ehs-analytics-kpis','supported',0.990,'Vision Platform provides embedded analytics and enterprise-wide EHS/ESG risk insight; Open Insights is an additional cloud-native analytics layer.','https://www.wolterskluwer.com/en/solutions/enablon/vision-platform'),
('enablon-vision-platform','ehs-enterprise-integration-scale','supported',0.990,'Vision Platform is enterprise-class, SaaS-enabled, API-ready and designed for connected enterprise EHS/ORM operations.','https://www.wolterskluwer.com/en/solutions/enablon/vision-platform'),

-- Benchmark Gensuite EHS
('benchmark-gensuite-ehs','ehs-incident-nearmiss','supported',0.990,'Benchmark Gensuite EHS includes incident management, structured root-cause analysis, near-miss/safety concern reporting and CAPA workflows.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/'),
('benchmark-gensuite-ehs','ehs-audits-inspections','supported',0.990,'Benchmark Gensuite supports audit lifecycle management, inspections, findings and corrective actions with mobile field execution.','https://benchmarkgensuite.com/app/audit-management-software/'),
('benchmark-gensuite-ehs','ehs-risk-assessment','supported',0.980,'Benchmark Gensuite positions risk assessment and operational risk within its connected EHS suite, though exact module packaging should be validated.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/'),
('benchmark-gensuite-ehs','ehs-environmental-compliance','supported',0.990,'Benchmark Gensuite EHS covers air, water, waste, permit tracking, sustainability data and environmental regulatory reporting.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/'),
('benchmark-gensuite-ehs','ehs-regulatory-actions','supported',0.990,'The suite includes CAPA and obligation management for corrective actions, regulatory tasks, deadlines and documentation across sites.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/'),
('benchmark-gensuite-ehs','ehs-analytics-kpis','supported',0.990,'Benchmark Gensuite provides real-time EHS dashboards, enterprise visibility and analytics across sites and roles.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/'),
('benchmark-gensuite-ehs','ehs-enterprise-integration-scale','supported',0.990,'Benchmark Gensuite explicitly supports standardized global workflows and deployment across large multi-site operations.','https://benchmarkgensuite.com/solutions/environmental-health-safety-software/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat133_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat133_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat133_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where the commercial SaaS model is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('corityone','spheracloud-ehs','enablon-vision-platform')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Intelex is web-based and Benchmark is cloud-based in vendor material, but those phrases are not converted automatically into this catalog's public-SaaS classification.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('intelex-ehs-platform','corityone','spheracloud-ehs','enablon-vision-platform','benchmark-gensuite-ehs')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

-- Enablon and Benchmark explicitly document native iOS and Android mobile support.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'supported','supported','vendor_documentation',0.990
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios') x
WHERE p.slug IN('enablon-vision-platform','benchmark-gensuite-ehs')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
