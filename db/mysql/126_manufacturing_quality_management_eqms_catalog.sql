-- TechSelectAI Manufacturing Quality Management & eQMS catalog expansion.
-- Adds one canonical manufacturing/eQMS category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Manufacturing Quality Management & eQMS','manufacturing-quality-management-eqms','Electronic quality management software for manufacturing and regulated industries, covering controlled documents, CAPA, nonconformance, audits, supplier quality, inspections, training, risk, compliance controls, analytics and enterprise integration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @qms_cat=(SELECT id FROM categories WHERE slug='manufacturing-quality-management-eqms' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@qms_cat,'Core Quality System Controls','qms-core-controls','Controlled documents and changes, CAPA, nonconformance/deviation, audits and training/competency workflows.',1),
(@qms_cat,'Manufacturing Quality & Enterprise Governance','qms-manufacturing-governance','Supplier quality, inspection/SPC, risk, regulated records, quality analytics and integration with manufacturing/enterprise systems.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'qms-core-controls' module_slug,'Document control & change management' name,'qms-document-change-control' slug,'Control quality documents, revisions, approvals and related quality-system changes with traceability and governed workflows.' description,0 sec UNION ALL
 SELECT 'qms-core-controls','CAPA & corrective/preventive action management','qms-capa','Manage root-cause investigation, corrective/preventive actions, approvals, effectiveness checks, escalation and closed-loop follow-up.',0 UNION ALL
 SELECT 'qms-core-controls','Nonconformance, deviation & quality-event management','qms-nonconformance-deviation','Capture, investigate, disposition and track nonconformances, deviations, incidents or related quality events through resolution.',0 UNION ALL
 SELECT 'qms-core-controls','Audit management','qms-audit-management','Plan, schedule, execute, document and follow up internal, supplier, regulatory or customer quality audits with findings and actions.',0 UNION ALL
 SELECT 'qms-core-controls','Training & competency management','qms-training-competency','Assign, track and evidence employee training, qualifications, competencies, certifications or retraining linked to quality processes and controlled documents.',0 UNION ALL
 SELECT 'qms-manufacturing-governance','Supplier quality & SCAR management','qms-supplier-quality','Qualify and monitor suppliers, conduct supplier audits, manage scorecards, nonconformances and supplier corrective-action requests where supported.',0 UNION ALL
 SELECT 'qms-manufacturing-governance','Inspection, SPC & shop-floor quality control','qms-inspection-spc','Plan and execute inspections, collect quality data, perform statistical/process quality analysis or manage shop-floor quality controls where explicitly documented.',0 UNION ALL
 SELECT 'qms-manufacturing-governance','Risk management & FMEA','qms-risk-fmea','Assess and manage quality risk using risk registers, risk scoring, FMEA or comparable structured risk-analysis methods where supported.',0 UNION ALL
 SELECT 'qms-manufacturing-governance','Electronic signatures, audit trail & regulated records','qms-regulated-records','Support electronic signatures, audit trails, access controls, validation or regulated-record requirements such as 21 CFR Part 11 where explicitly documented.',1 UNION ALL
 SELECT 'qms-manufacturing-governance','Quality analytics, KPIs & management review','qms-quality-analytics','Provide dashboards, trend analysis, quality KPIs, management-review data or other quality intelligence across processes and sites.',0 UNION ALL
 SELECT 'qms-manufacturing-governance','ERP, MES, PLM & API integration','qms-enterprise-integration','Exchange quality, inspection, product, supplier or manufacturing data with ERP, MES, PLM and other enterprise systems through supported APIs or interfaces.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@qms_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('ETQ','etq','https://www.etq.com/','Electronic quality management software vendor and Hexagon company.','active'),
('MasterControl','mastercontrol','https://www.mastercontrol.com/','Quality, manufacturing and regulated-industry software vendor.','active'),
('Siemens','siemens','https://www.siemens.com/','Industrial technology, automation and manufacturing software vendor.','active'),
('Ideagen','ideagen','https://www.ideagen.com/','Quality, compliance, risk and operational software vendor.','active'),
('QT9 Software','qt9-software','https://qt9software.com/','Quality management, ERP and business intelligence software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat126_products;
CREATE TEMPORARY TABLE cat126_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat126_products VALUES
('etq','manufacturing-quality-management-eqms','ETQ Reliance','etq-reliance','Cloud-native enterprise QMS with document control, training, audits, CAPA, nonconformance, supplier quality, risk, analytics and integration capabilities for manufacturing and regulated organizations.','https://www.etq.com/platform/'),
('mastercontrol','manufacturing-quality-management-eqms','MasterControl Quality Excellence','mastercontrol-quality-excellence','Connected cloud QMS for document/change control, training, audits, CAPA, quality events, risk and regulated-quality workflows, with supplier and analytics capabilities available in the wider Quality Excellence portfolio.','https://www.mastercontrol.com/quality/'),
('siemens','manufacturing-quality-management-eqms','Siemens Opcenter X Quality','siemens-opcenter-x-quality','Cloud SaaS quality-management system focused on shop-floor inspection planning and execution, SPC, nonconformance, supplier incoming inspection, quality analytics and connected manufacturing/PLM workflows.','https://www.siemens.com/en-gb/products/opcenter/quality-x-cloud-qms/'),
('ideagen','manufacturing-quality-management-eqms','Ideagen Quality Management','ideagen-quality-management','Connected quality-management platform for document control, CAPA, audits, training, supplier quality, inspections, nonconformance, compliance and quality analytics across regulated and manufacturing organizations.','https://www.ideagen.com/solutions/quality/quality-management'),
('qt9-software','manufacturing-quality-management-eqms','QT9 QMS','qt9-qms','Integrated QMS for document control, CAPA, audits, nonconforming products, supplier quality, training, risk/FMEA, inspections, compliance controls, analytics and ERP-connected manufacturing quality.','https://qt9software.com/qms');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat126_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat126_sources;
CREATE TEMPORARY TABLE cat126_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat126_sources VALUES
('etq-reliance','https://www.etq.com/platform/','ETQ Reliance eQMS Platform','ETQ'),
('etq-reliance','https://www.etq.com/manufacturing/','ETQ Reliance for Manufacturing','ETQ'),
('etq-reliance','https://host.etq.com/nonconformance-handling/','ETQ Reliance Nonconformance Handling','ETQ'),
('etq-reliance','https://www.etq.com/audit-management/','ETQ Reliance Audit Management','ETQ'),
('etq-reliance','https://www.etq.com/app/uploads/2025/04/HEXAGON-ETQ-Reliance_overview-Broch-12P-US-EN-3.25.pdf','ETQ Reliance Overview Brochure','ETQ'),
('mastercontrol-quality-excellence','https://www.mastercontrol.com/quality/','MasterControl Quality Excellence','MasterControl'),
('mastercontrol-quality-excellence','https://www.mastercontrol.com/quality-management-system/','MasterControl Quality Management System','MasterControl'),
('mastercontrol-quality-excellence','https://www.mastercontrol.com/quality/nonconformance/','MasterControl Nonconformance Management','MasterControl'),
('mastercontrol-quality-excellence','https://www.mastercontrol.com/quality/capa-software/management/','MasterControl CAPA Management','MasterControl'),
('mastercontrol-quality-excellence','https://www.mastercontrol.com/quality/audit-management/qms-audit-software-solutions/','MasterControl Audit Management','MasterControl'),
('mastercontrol-quality-excellence','https://www.mastercontrol.com/resource-center/documents/mastercontrol-supplier/','MasterControl Supplier','MasterControl'),
('siemens-opcenter-x-quality','https://www.siemens.com/en-gb/products/opcenter/quality-x-cloud-qms/','Siemens Opcenter X Quality','Siemens'),
('siemens-opcenter-x-quality','https://www.siemens.com/en-gb/products/opcenter/quality-x-cloud-qms/essentials/','Siemens Opcenter X Quality Essentials','Siemens'),
('siemens-opcenter-x-quality','https://blogs.sw.siemens.com/opcenter/whats-new-in-opcenter-x-quality-2601/','Opcenter X Quality 2601','Siemens'),
('siemens-opcenter-x-quality','https://blogs.sw.siemens.com/opcenter/whats-new-opcenter-x-quality-2607/','Opcenter X Quality 2607','Siemens'),
('siemens-opcenter-x-quality','https://blogs.sw.siemens.com/opcenter/whats-new-in-opcenter-x-2501/','Opcenter X Interoperability and Quality','Siemens'),
('ideagen-quality-management','https://www.ideagen.com/solutions/quality/quality-management','Ideagen Quality Management','Ideagen'),
('ideagen-quality-management','https://www.ideagen.com/solutions/quality','Ideagen Quality Solutions','Ideagen'),
('ideagen-quality-management','https://www.ideagen.com/solutions/quality/supplier-quality-management','Ideagen Supplier Quality Management','Ideagen'),
('ideagen-quality-management','https://www.ideagen.com/solutions/quality/training-management','Ideagen Training Management','Ideagen'),
('ideagen-quality-management','https://www.ideagen.com/resources/whitepapers/ideagen-quality-management','Ideagen Quality Management Brochure','Ideagen'),
('qt9-qms','https://qt9software.com/qms','QT9 QMS','QT9 Software'),
('qt9-qms','https://qt9software.com/qms/features','QT9 QMS Features','QT9 Software'),
('qt9-qms','https://qt9software.com/qms/industry/manufacturing','QT9 QMS for Manufacturing','QT9 Software'),
('qt9-qms','https://qt9software.com/qms/capa-software','QT9 CAPA Management','QT9 Software'),
('qt9-qms','https://qt9software.com/qms/audit-management-software','QT9 Audit Management','QT9 Software');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat126_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat126_facts;
CREATE TEMPORARY TABLE cat126_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat126_facts VALUES
-- ETQ Reliance
('etq-reliance','qms-document-change-control','supported',0.990,'ETQ Reliance core applications include document control and change management with controlled workflows and traceability.','https://www.etq.com/platform/'),
('etq-reliance','qms-capa','supported',0.990,'Corrective Action (CAPA) is a core ETQ Reliance quality application with closed-loop workflow support.','https://www.etq.com/platform/'),
('etq-reliance','qms-nonconformance-deviation','supported',0.990,'ETQ Reliance Nonconformance Handling manages inspection findings, nonconformance reporting, deviations and related quality events.','https://host.etq.com/nonconformance-handling/'),
('etq-reliance','qms-audit-management','supported',0.990,'ETQ Reliance Audit Management supports planning, execution, approval, reporting and supplier/internal quality audits.','https://www.etq.com/audit-management/'),
('etq-reliance','qms-training-competency','supported',0.990,'Training Management is a core ETQ Reliance application for tracking employee quality training and certifications.','https://www.etq.com/platform/'),
('etq-reliance','qms-supplier-quality','supported',0.990,'ETQ Reliance includes supplier/material management and supply-chain quality applications including supplier rating and corrective-action workflows.','https://www.etq.com/app/uploads/2025/04/HEXAGON-ETQ-Reliance_overview-Broch-12P-US-EN-3.25.pdf'),
('etq-reliance','qms-inspection-spc','partially_supported',0.970,'ETQ explicitly documents inspection planning/execution and shop-floor quality-data collection, but the reviewed current evidence does not establish a native SPC package equivalent to dedicated SPC products.','https://host.etq.com/nonconformance-handling/'),
('etq-reliance','qms-risk-fmea','partially_supported',0.970,'ETQ Reliance includes risk assessment/enterprise risk capabilities; FMEA exists in the wider application portfolio, so universal FMEA entitlement is not inferred from the core platform page.','https://www.etq.com/platform/'),
('etq-reliance','qms-regulated-records','partially_supported',0.970,'ETQ documents audit trail, access control, security and regulated-industry compliance capabilities; universal electronic-signature scope depends on licensed applications and validation requirements.','https://www.etq.com/app/uploads/2025/04/HEXAGON-ETQ-Reliance_overview-Broch-12P-US-EN-3.25.pdf'),
('etq-reliance','qms-quality-analytics','supported',0.990,'ETQ Reliance includes advanced analytics, reporting, dashboards and quality insights across enterprise QMS data.','https://www.etq.com/platform/'),
('etq-reliance','qms-enterprise-integration','supported',0.980,'ETQ documents Integration/APIs and integration with third-party systems such as ERP for closed-loop manufacturing quality.','https://www.etq.com/app/uploads/2025/04/HEXAGON-ETQ-Reliance_overview-Broch-12P-US-EN-3.25.pdf'),

-- MasterControl Quality Excellence
('mastercontrol-quality-excellence','qms-document-change-control','supported',0.990,'MasterControl Quality Excellence includes document control and change management with revision, approval and traceability workflows.','https://www.mastercontrol.com/quality/'),
('mastercontrol-quality-excellence','qms-capa','supported',0.990,'MasterControl CAPA automates corrective/preventive action from initiation and investigation through approval and closure.','https://www.mastercontrol.com/quality/capa-software/management/'),
('mastercontrol-quality-excellence','qms-nonconformance-deviation','supported',0.990,'MasterControl Quality Event Management covers nonconformance, deviations and connected quality-event workflows that can launch CAPA.','https://www.mastercontrol.com/quality/nonconformance/'),
('mastercontrol-quality-excellence','qms-audit-management','supported',0.990,'MasterControl Audit manages audit planning, scheduling, observations, findings, closure and integration to CAPA/risk/supplier processes.','https://www.mastercontrol.com/quality/audit-management/qms-audit-software-solutions/'),
('mastercontrol-quality-excellence','qms-training-competency','supported',0.990,'MasterControl Quality Excellence includes integrated training management for assignments, exams, competency records and retraining triggers.','https://www.mastercontrol.com/quality/'),
('mastercontrol-quality-excellence','qms-supplier-quality','partially_supported',0.990,'Supplier Excellence provides supplier quality, approved-vendor and supplier-corrective-action capabilities, but it is presented as an add-on rather than assumed core Quality Excellence entitlement.','https://www.mastercontrol.com/resource-center/documents/mastercontrol-supplier/'),
('mastercontrol-quality-excellence','qms-risk-fmea','partially_supported',0.970,'MasterControl includes risk-management capabilities in Quality Excellence, but FMEA-specific functionality is not inferred from the reviewed QMS evidence.','https://www.mastercontrol.com/quality-management-system/'),
('mastercontrol-quality-excellence','qms-regulated-records','supported',0.990,'MasterControl documents 21 CFR Part 11 compliance, electronic approvals/signatures, audit trails and controlled records across Quality Excellence.','https://www.mastercontrol.com/quality/'),
('mastercontrol-quality-excellence','qms-quality-analytics','partially_supported',0.970,'Quality Excellence includes reporting and trend analysis, while the current product navigation presents Data & Analytics as an add-on; universal advanced analytics entitlement is not inferred.','https://www.mastercontrol.com/quality/'),
('mastercontrol-quality-excellence','qms-enterprise-integration','supported',0.980,'MasterControl documents integration of quality-event processes with ERP, LIMS, accounting and HR applications.','https://www.mastercontrol.com/quality/nonconformance/'),

-- Siemens Opcenter X Quality
('siemens-opcenter-x-quality','qms-capa','partially_supported',0.960,'Opcenter X Quality supports corrective actions linked to shop-floor nonconformance workflows, but a full enterprise CAPA lifecycle is not inferred.','https://www.siemens.com/en-gb/products/opcenter/quality-x-cloud-qms/essentials/'),
('siemens-opcenter-x-quality','qms-nonconformance-deviation','supported',0.990,'Opcenter X Quality provides detailed nonconformance management, action assignment and resolution tracking on the shop floor.','https://blogs.sw.siemens.com/opcenter/whats-new-opcenter-x-quality-2607/'),
('siemens-opcenter-x-quality','qms-supplier-quality','supported',0.980,'Siemens documents incoming-goods inspection and supplier-quality control within Opcenter X Quality.','https://www.siemens.com/en-gb/products/opcenter/quality-x-cloud-qms/'),
('siemens-opcenter-x-quality','qms-inspection-spc','supported',0.990,'Opcenter X Quality explicitly supports inspection planning/execution, gage management, SPC, control charts, MSA and shop-floor quality data analysis.','https://blogs.sw.siemens.com/opcenter/whats-new-in-opcenter-x-quality-2601/'),
('siemens-opcenter-x-quality','qms-regulated-records','partially_supported',0.950,'Opcenter X Quality documents authentication, permissions, traceability and standards-aligned quality controls, but the reviewed evidence does not establish broad e-signature/Part 11 parity with enterprise eQMS suites.','https://blogs.sw.siemens.com/opcenter/whats-new-opcenter-x-quality-2607/'),
('siemens-opcenter-x-quality','qms-quality-analytics','supported',0.990,'Opcenter X Quality provides SPC analysis, control charts, Pareto/trend analysis and AI-assisted statistical evaluation for manufacturing quality.','https://blogs.sw.siemens.com/opcenter/whats-new-in-opcenter-x-quality-2601/'),
('siemens-opcenter-x-quality','qms-enterprise-integration','supported',0.990,'Opcenter X provides REST/HTTP, Kafka and OPC UA interoperability and integration with ERP/external systems; Opcenter X Quality also integrates inspection plans with Teamcenter Quality.','https://blogs.sw.siemens.com/opcenter/whats-new-in-opcenter-x-2501/'),

-- Ideagen Quality Management
('ideagen-quality-management','qms-document-change-control','supported',0.990,'Ideagen Quality Management connects controlled documents, revisions, approvals and change-management workflows in one QMS.','https://www.ideagen.com/solutions/quality/quality-management'),
('ideagen-quality-management','qms-capa','supported',0.990,'Ideagen documents automated CAPA workflows with root-cause analysis, corrective actions and effectiveness monitoring.','https://www.ideagen.com/solutions/quality/quality-management'),
('ideagen-quality-management','qms-nonconformance-deviation','supported',0.990,'Ideagen connects nonconformance reporting to CAPA and other quality workflows for closed-loop quality management.','https://www.ideagen.com/solutions/quality/supplier-quality-management'),
('ideagen-quality-management','qms-audit-management','supported',0.990,'Ideagen includes audit management with automated evidence, checklists, findings and linked corrective action.','https://www.ideagen.com/solutions/quality/quality-management'),
('ideagen-quality-management','qms-training-competency','supported',0.990,'Ideagen training management tracks training records, competency, certifications and automated retraining triggers linked to quality workflows.','https://www.ideagen.com/solutions/quality/training-management'),
('ideagen-quality-management','qms-supplier-quality','supported',0.990,'Ideagen supplier quality covers qualification, scorecards, nonconformance, CAPA, audits, supplier communication and risk.','https://www.ideagen.com/solutions/quality/supplier-quality-management'),
('ideagen-quality-management','qms-inspection-spc','supported',0.980,'Ideagen documents inspection management plus supplier-quality scorecards using statistical process control; exact SPC depth should be validated for the selected configuration.','https://www.ideagen.com/solutions/quality/supplier-quality-management'),
('ideagen-quality-management','qms-risk-fmea','partially_supported',0.960,'Ideagen documents risk management throughout the connected QMS, but FMEA-specific scope is not inferred from the reviewed current pages.','https://www.ideagen.com/solutions/quality/quality-management'),
('ideagen-quality-management','qms-regulated-records','partially_supported',0.970,'Ideagen documents support for standards including 21 CFR Part 11 and audit-ready controlled records; exact electronic-signature/validation scope should be confirmed for the selected solution.','https://www.ideagen.com/solutions/quality/quality-management'),
('ideagen-quality-management','qms-quality-analytics','supported',0.990,'Ideagen provides cross-process quality visibility including audit performance, CAPA effectiveness, inspection trends and supplier quality.','https://www.ideagen.com/solutions/quality'),
('ideagen-quality-management','qms-enterprise-integration','supported',0.980,'Ideagen documents ERP and enterprise-tool integration plus API support for connected quality and training data.','https://www.ideagen.com/solutions/quality/training-management'),

-- QT9 QMS
('qt9-qms','qms-document-change-control','supported',0.990,'QT9 includes document control, revision tracking, approvals and change-control modules in the integrated QMS.','https://qt9software.com/qms/features'),
('qt9-qms','qms-capa','supported',0.990,'QT9 CAPA provides root-cause tools, corrective/preventive workflows, approvals, alerts, traceability and effectiveness follow-up.','https://qt9software.com/qms/capa-software'),
('qt9-qms','qms-nonconformance-deviation','supported',0.990,'QT9 includes Nonconforming Products, Quality Events and Deviation Management as integrated QMS modules.','https://qt9software.com/qms/features'),
('qt9-qms','qms-audit-management','supported',0.990,'QT9 Audit Management supports internal, external and supplier audits with scheduling, evidence, findings, CAPA and real-time reporting.','https://qt9software.com/qms/audit-management-software'),
('qt9-qms','qms-training-competency','supported',0.990,'QT9 includes employee training, assignments, skills tracking, tests and training records within the QMS.','https://qt9software.com/qms/features'),
('qt9-qms','qms-supplier-quality','supported',0.990,'QT9 includes supplier evaluations, supplier surveys, supplier portal, supplier audits and supplier corrective-action workflows.','https://qt9software.com/qms/features'),
('qt9-qms','qms-inspection-spc','partially_supported',0.970,'QT9 includes inspections, defect tracking, statistical reports and manufacturing quality dashboards, but dedicated SPC depth is not inferred beyond the reviewed evidence.','https://qt9software.com/qms/industry/manufacturing'),
('qt9-qms','qms-risk-fmea','supported',0.990,'QT9 includes both Risk Management and FMEA modules as standard integrated QMS tools.','https://qt9software.com/qms/features'),
('qt9-qms','qms-regulated-records','supported',0.990,'QT9 documents electronic-signature approvals, audit trail, IQ/OQ/PQ validation and 21 CFR Part 11 compliance controls.','https://qt9software.com/qms/features'),
('qt9-qms','qms-quality-analytics','supported',0.990,'QT9 provides real-time reports, dashboards, charts, statistical reports and manufacturing quality KPIs.','https://qt9software.com/qms/industry/manufacturing'),
('qt9-qms','qms-enterprise-integration','supported',0.980,'QT9 documents ERP integration and a Quality Link ERP data connector for manufacturing quality workflows.','https://qt9software.com/qms/features');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat126_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat126_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat126_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Promote deployment only where the current product-specific evidence is explicit.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('etq-reliance','mastercontrol-quality-excellence','siemens-opcenter-x-quality','qt9-qms')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.990
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug='qt9-qms'
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Do not infer Android/iOS/mobile-web support from generic mobile, browser or cloud claims.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('etq-reliance','mastercontrol-quality-excellence','siemens-opcenter-x-quality','ideagen-quality-management','qt9-qms')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
