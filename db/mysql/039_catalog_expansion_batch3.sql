-- TechSelectAI catalog expansion batch 3 for #96 / #228
-- Adds AI Platforms, Healthcare/EHR Systems, Retail POS, and CAD/Engineering.
-- Initial facts are deliberately conservative and use official vendor-owned sources.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('AI Platforms','ai-platforms','Enterprise platforms for building, deploying, evaluating and governing AI applications, models and agents.',1),
('Healthcare & EHR Systems','healthcare-ehr','Electronic health record and healthcare information systems for clinical documentation, workflows, patient information and care operations.',1),
('Retail POS','retail-pos','Point-of-sale and retail operations software for in-store transactions, inventory, customers and omnichannel commerce.',1),
('CAD & Engineering','cad-engineering','Computer-aided design and engineering software for 2D/3D design, product development, modeling and technical workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'ai-platforms' cat,'Models & AI Development' name,'ai-model-development' slug,'Foundation models, model customization, AI application development and experimentation.' description UNION ALL
 SELECT 'ai-platforms','Agents & Governance','ai-agents-governance','Agent development, evaluation, monitoring, access control and enterprise AI governance.' UNION ALL
 SELECT 'healthcare-ehr','Clinical Records & Workflows','ehr-clinical' ,'Clinical documentation, patient records, orders, results and care workflows.' UNION ALL
 SELECT 'healthcare-ehr','Operations & Interoperability','ehr-operations','Scheduling, medication workflows, interoperability and healthcare operations.' UNION ALL
 SELECT 'retail-pos','Transactions & Inventory','pos-transactions','Checkout, payment, return and retail inventory operations.' UNION ALL
 SELECT 'retail-pos','Omnichannel & Store Management','pos-omnichannel','Customer, omnichannel, multi-store and centralized retail operations.' UNION ALL
 SELECT 'cad-engineering','Design & Modeling','cad-design','2D drafting, 3D modeling, parametric design and engineering geometry.' UNION ALL
 SELECT 'cad-engineering','Engineering Workflow','cad-workflow','Assemblies, collaboration, automation and downstream engineering workflows.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'ai-model-development' ms,'Foundation / generative model access' name,'ai-foundation-models' slug,'Access to managed foundation, generative or large language models.' description,0 sec UNION ALL
 SELECT 'ai-model-development','Model customization / fine-tuning','ai-model-customization','Model customization, tuning, adaptation or managed training capabilities.',0 UNION ALL
 SELECT 'ai-model-development','AI application development tools','ai-app-development','Tools, SDKs, APIs or managed environments for building AI applications.',0 UNION ALL
 SELECT 'ai-agents-governance','Agent development / orchestration','ai-agent-development','Build, orchestrate or operate AI agents and agentic workflows.',0 UNION ALL
 SELECT 'ai-agents-governance','Evaluation / monitoring','ai-evaluation-monitoring','Evaluate, trace, monitor or observe AI application/model behavior.',0 UNION ALL
 SELECT 'ai-agents-governance','Enterprise governance / access control','ai-governance-access','Enterprise controls such as policy, permissions, governance or controlled deployment.',1 UNION ALL
 SELECT 'ehr-clinical','Electronic patient record / charting','ehr-patient-record','Electronic storage, review and documentation of patient clinical information.',1 UNION ALL
 SELECT 'ehr-clinical','Clinical orders / results','ehr-orders-results','Clinical orders, results or related clinician workflows.',1 UNION ALL
 SELECT 'ehr-clinical','Clinical documentation','ehr-clinical-documentation','Structured or narrative clinical documentation for care delivery.',1 UNION ALL
 SELECT 'ehr-operations','Scheduling / patient workflow','ehr-scheduling','Scheduling, visit or patient workflow support.',0 UNION ALL
 SELECT 'ehr-operations','Medication workflow','ehr-medication-workflow','Medication ordering, administration or medication-related workflow support.',1 UNION ALL
 SELECT 'ehr-operations','Interoperability / data exchange','ehr-interoperability','Exchange or interoperability of healthcare/patient information with other systems.',1 UNION ALL
 SELECT 'pos-transactions','Point-of-sale transactions','pos-transactions-core','Process in-person retail sales and day-to-day POS transactions.',0 UNION ALL
 SELECT 'pos-transactions','Payments / tender handling','pos-payments','Accept or process payment/tender methods through the POS workflow.',1 UNION ALL
 SELECT 'pos-transactions','Returns / exchanges','pos-returns','Process returns, refunds or exchanges in retail workflows.',0 UNION ALL
 SELECT 'pos-transactions','Retail inventory visibility','pos-inventory','Track or synchronize inventory for retail operations.',0 UNION ALL
 SELECT 'pos-omnichannel','Omnichannel commerce','pos-omnichannel-commerce','Connect in-store sales with online or other commerce channels.',0 UNION ALL
 SELECT 'pos-omnichannel','Central / multi-store management','pos-multistore-management','Centralized configuration, reporting or operations across stores/locations.',0 UNION ALL
 SELECT 'cad-design','2D drafting / documentation','cad-2d-drafting','Create and edit technical drawings, drafting geometry or design documentation.',0 UNION ALL
 SELECT 'cad-design','3D modeling','cad-3d-modeling','Create and modify three-dimensional engineering or product models.',0 UNION ALL
 SELECT 'cad-design','Parametric / feature-based design','cad-parametric-design','Parametric, feature-based or associative engineering design workflows.',0 UNION ALL
 SELECT 'cad-workflow','Assemblies / product structures','cad-assemblies','Manage multi-part assemblies or product structures in engineering design.',0 UNION ALL
 SELECT 'cad-workflow','Design collaboration / sharing','cad-collaboration','Share, collaborate on or manage design data across users or teams.',0 UNION ALL
 SELECT 'cad-workflow','Automation / extensibility','cad-automation-extensibility','APIs, scripting, automation or extensibility for design workflows.',0
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud and AI platform vendor.','active'),
('Google Cloud','google-cloud','https://cloud.google.com/','Cloud computing, data and AI platform vendor.','active'),
('Amazon Web Services','aws','https://aws.amazon.com/','Cloud infrastructure and managed technology services vendor.','active'),
('IBM','ibm','https://www.ibm.com/','Enterprise technology, software and AI vendor.','active'),
('Epic Systems','epic-systems','https://www.epic.com/','Healthcare software and electronic health record vendor.','active'),
('Oracle','oracle','https://www.oracle.com/','Enterprise application, database, cloud and healthcare technology vendor.','active'),
('InterSystems','intersystems','https://www.intersystems.com/','Healthcare data platform and health information systems vendor.','active'),
('MEDITECH','meditech','https://ehr.meditech.com/','Electronic health record and healthcare technology vendor.','active'),
('Shopify','shopify','https://www.shopify.com/','Commerce and retail technology vendor.','active'),
('Lightspeed','lightspeed','https://www.lightspeedhq.com/','Retail and hospitality commerce technology vendor.','active'),
('Block','block','https://block.xyz/','Commerce, payments and financial technology company.','active'),
('Autodesk','autodesk','https://www.autodesk.com/','Design, engineering and construction software vendor.','active'),
('Dassault Systemes','dassault-systemes','https://www.3ds.com/','Engineering, product design and lifecycle software vendor.','active'),
('Siemens','siemens','https://www.siemens.com/','Industrial technology and engineering software vendor.','active'),
('PTC','ptc','https://www.ptc.com/','Engineering, product lifecycle and industrial software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat39_products;
CREATE TEMPORARY TABLE cat39_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,source_url TEXT,source_title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat39_products VALUES
('microsoft','ai-platforms','Microsoft Foundry','microsoft-foundry','Enterprise AI platform for building, grounding, evaluating, governing and operating AI applications and agents.','https://azure.microsoft.com/en-us/products/ai-foundry','Microsoft Foundry','Microsoft'),
('google-cloud','ai-platforms','Google Cloud Vertex AI','google-vertex-ai','Google Cloud AI platform for building and deploying generative AI and machine learning applications.','https://cloud.google.com/vertex-ai','Vertex AI','Google Cloud'),
('aws','ai-platforms','Amazon Bedrock','amazon-bedrock','AWS managed service for building generative AI applications with foundation models and enterprise controls.','https://aws.amazon.com/bedrock/','Amazon Bedrock','AWS'),
('ibm','ai-platforms','IBM watsonx.ai','ibm-watsonx-ai','IBM enterprise AI studio for building and deploying generative AI and machine learning solutions.','https://www.ibm.com/products/watsonx-ai','IBM watsonx.ai','IBM'),
('epic-systems','healthcare-ehr','Epic','epic-ehr','Enterprise electronic health record and healthcare software platform for clinical and operational workflows.','https://www.epic.com/software/','Epic Software','Epic'),
('oracle','healthcare-ehr','Oracle Health EHR','oracle-health-ehr','Enterprise healthcare information system for patient records, clinical documentation and care workflows.','https://www.oracle.com/health/clinical-suite/electronic-health-record/','Oracle Health EHR','Oracle'),
('intersystems','healthcare-ehr','InterSystems TrakCare','intersystems-trakcare','Unified healthcare information system and electronic medical record platform for connected care delivery.','https://www.intersystems.com/products/trakcare/','InterSystems TrakCare','InterSystems'),
('meditech','healthcare-ehr','MEDITECH Expanse','meditech-expanse','Cloud-native electronic health record platform supporting clinical, operational and financial healthcare workflows.','https://ehr.meditech.com/ehr-solutions/meditech-expanse','MEDITECH Expanse','MEDITECH'),
('oracle','retail-pos','Oracle Retail Xstore Point of Service','oracle-retail-xstore','Enterprise retail point-of-sale application for store transactions and day-to-day store operations.','https://docs.oracle.com/en/industries/retail/retail-xstore-point-of-service/25.0/','Oracle Retail Xstore Point of Service','Oracle'),
('shopify','retail-pos','Shopify POS','shopify-pos','Retail POS system connecting in-store selling with Shopify commerce, inventory, customers and payments.','https://www.shopify.com/pos','Shopify POS','Shopify'),
('lightspeed','retail-pos','Lightspeed Retail','lightspeed-retail-pos','Cloud retail POS and commerce platform for transactions, inventory, customer and store operations.','https://www.lightspeedhq.com/pos/retail/','Lightspeed Retail POS','Lightspeed'),
('block','retail-pos','Square for Retail','square-for-retail','Retail point-of-sale software for checkout, inventory, customer and store management workflows.','https://squareup.com/us/en/point-of-sale/retail','Square for Retail','Square'),
('autodesk','cad-engineering','Autodesk AutoCAD','autodesk-autocad','CAD software for precision 2D drafting, documentation and 3D modeling across design and engineering disciplines.','https://www.autodesk.com/products/autocad/overview','AutoCAD','Autodesk'),
('dassault-systemes','cad-engineering','SOLIDWORKS','solidworks','3D CAD and product development software for mechanical design, engineering and collaboration.','https://www.solidworks.com/','SOLIDWORKS','Dassault Systemes'),
('siemens','cad-engineering','Siemens NX CAD','siemens-nx-cad','Mechanical product design and engineering CAD solution for complex 3D product development and digital workflows.','https://www.siemens.com/en-gb/technology/computer-aided-design-cad/','NX CAD','Siemens'),
('ptc','cad-engineering','PTC Creo','ptc-creo','Parametric 3D CAD platform for product design, engineering, simulation and manufacturing-oriented workflows.','https://www.ptc.com/en/products/creo','Creo','PTC');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.source_url,'active',NOW()
FROM cat39_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.source_url,x.source_title,x.publisher,1,'verified','high',NOW()
FROM cat39_products x JOIN products p ON p.slug=x.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.source_url);

DROP TEMPORARY TABLE IF EXISTS cat39_facts;
CREATE TEMPORARY TABLE cat39_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),source_url TEXT);
INSERT INTO cat39_facts VALUES
('microsoft-foundry','ai-foundation-models','supported',0.98,'https://azure.microsoft.com/en-us/products/ai-foundry'),
('microsoft-foundry','ai-app-development','supported',0.98,'https://azure.microsoft.com/en-us/products/ai-foundry'),
('microsoft-foundry','ai-agent-development','supported',0.98,'https://azure.microsoft.com/en-us/products/ai-foundry'),
('microsoft-foundry','ai-evaluation-monitoring','supported',0.95,'https://azure.microsoft.com/en-us/products/ai-foundry'),
('google-vertex-ai','ai-foundation-models','supported',0.98,'https://cloud.google.com/vertex-ai'),
('google-vertex-ai','ai-model-customization','supported',0.95,'https://cloud.google.com/vertex-ai'),
('google-vertex-ai','ai-app-development','supported',0.98,'https://cloud.google.com/vertex-ai'),
('amazon-bedrock','ai-foundation-models','supported',0.99,'https://aws.amazon.com/bedrock/'),
('amazon-bedrock','ai-app-development','supported',0.98,'https://aws.amazon.com/bedrock/'),
('amazon-bedrock','ai-agent-development','supported',0.95,'https://aws.amazon.com/bedrock/'),
('ibm-watsonx-ai','ai-foundation-models','supported',0.95,'https://www.ibm.com/products/watsonx-ai'),
('ibm-watsonx-ai','ai-model-customization','supported',0.95,'https://www.ibm.com/products/watsonx-ai'),
('ibm-watsonx-ai','ai-app-development','supported',0.95,'https://www.ibm.com/products/watsonx-ai'),

('epic-ehr','ehr-patient-record','supported',0.97,'https://www.epic.com/software/'),
('epic-ehr','ehr-clinical-documentation','supported',0.95,'https://www.epic.com/software/'),
('epic-ehr','ehr-scheduling','supported',0.90,'https://www.epic.com/software/'),
('oracle-health-ehr','ehr-patient-record','supported',0.99,'https://www.oracle.com/health/clinical-suite/electronic-health-record/'),
('oracle-health-ehr','ehr-clinical-documentation','supported',0.98,'https://www.oracle.com/health/clinical-suite/electronic-health-record/'),
('oracle-health-ehr','ehr-orders-results','supported',0.95,'https://www.oracle.com/health/clinical-suite/electronic-health-record/'),
('intersystems-trakcare','ehr-patient-record','supported',0.95,'https://www.intersystems.com/products/trakcare/'),
('intersystems-trakcare','ehr-clinical-documentation','supported',0.93,'https://www.intersystems.com/products/trakcare/'),
('intersystems-trakcare','ehr-interoperability','supported',0.95,'https://www.intersystems.com/products/trakcare/'),
('meditech-expanse','ehr-patient-record','supported',0.98,'https://ehr.meditech.com/ehr-solutions/meditech-expanse'),
('meditech-expanse','ehr-clinical-documentation','supported',0.95,'https://ehr.meditech.com/ehr-solutions/meditech-expanse'),
('meditech-expanse','ehr-scheduling','supported',0.90,'https://ehr.meditech.com/ehr-solutions/meditech-expanse'),

('oracle-retail-xstore','pos-transactions-core','supported',0.99,'https://docs.oracle.com/en/industries/retail/retail-xstore-point-of-service/25.0/'),
('oracle-retail-xstore','pos-payments','supported',0.98,'https://docs.oracle.com/en/industries/retail/retail-xstore-point-of-service/25.0/'),
('oracle-retail-xstore','pos-returns','supported',0.98,'https://docs.oracle.com/en/industries/retail/retail-xstore-point-of-service/25.0/'),
('shopify-pos','pos-transactions-core','supported',0.99,'https://www.shopify.com/pos'),
('shopify-pos','pos-payments','supported',0.98,'https://www.shopify.com/pos'),
('shopify-pos','pos-inventory','supported',0.98,'https://www.shopify.com/pos'),
('shopify-pos','pos-omnichannel-commerce','supported',0.98,'https://www.shopify.com/pos'),
('lightspeed-retail-pos','pos-transactions-core','supported',0.98,'https://www.lightspeedhq.com/pos/retail/'),
('lightspeed-retail-pos','pos-inventory','supported',0.95,'https://www.lightspeedhq.com/pos/retail/'),
('lightspeed-retail-pos','pos-multistore-management','supported',0.90,'https://www.lightspeedhq.com/pos/retail/'),
('square-for-retail','pos-transactions-core','supported',0.98,'https://squareup.com/us/en/point-of-sale/retail'),
('square-for-retail','pos-inventory','supported',0.95,'https://squareup.com/us/en/point-of-sale/retail'),
('square-for-retail','pos-returns','supported',0.90,'https://squareup.com/us/en/point-of-sale/retail'),

('autodesk-autocad','cad-2d-drafting','supported',0.99,'https://www.autodesk.com/products/autocad/overview'),
('autodesk-autocad','cad-3d-modeling','supported',0.98,'https://www.autodesk.com/products/autocad/overview'),
('autodesk-autocad','cad-automation-extensibility','supported',0.95,'https://www.autodesk.com/products/autocad/overview'),
('solidworks','cad-3d-modeling','supported',0.99,'https://www.solidworks.com/'),
('solidworks','cad-parametric-design','supported',0.98,'https://www.solidworks.com/'),
('solidworks','cad-assemblies','supported',0.95,'https://www.solidworks.com/'),
('siemens-nx-cad','cad-3d-modeling','supported',0.99,'https://www.siemens.com/en-gb/technology/computer-aided-design-cad/'),
('siemens-nx-cad','cad-parametric-design','supported',0.98,'https://www.siemens.com/en-gb/technology/computer-aided-design-cad/'),
('siemens-nx-cad','cad-assemblies','supported',0.95,'https://www.siemens.com/en-gb/technology/computer-aided-design-cad/'),
('ptc-creo','cad-3d-modeling','supported',0.99,'https://www.ptc.com/en/products/creo'),
('ptc-creo','cad-parametric-design','supported',0.99,'https://www.ptc.com/en/products/creo'),
('ptc-creo','cad-assemblies','supported',0.95,'https://www.ptc.com/en/products/creo');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,NOW()
FROM cat39_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat39_products x JOIN products p ON p.slug=x.product_slug
JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id
JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Initial catalog-expansion fact from official vendor product documentation.'
FROM cat39_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

COMMIT;
