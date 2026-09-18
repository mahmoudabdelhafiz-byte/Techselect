-- TechSelectAI FinOps & Cloud Cost Management catalog expansion.
-- Adds one canonical FinOps category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('FinOps & Cloud Cost Management','finops-cloud-cost-management','Platforms for allocating, forecasting, optimizing and governing cloud, Kubernetes, SaaS and AI infrastructure spend across engineering, finance and business teams.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @finops_cat=(SELECT id FROM categories WHERE slug='finops-cloud-cost-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@finops_cat,'Visibility, Allocation & Planning','finops-visibility-planning','Cost visibility, allocation, showback/chargeback, budgeting, forecasting and unit economics.',1),
(@finops_cat,'Optimization & Control','finops-optimization-control','Anomaly detection, rightsizing, commitment optimization and Kubernetes cost management.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'finops-visibility-planning' module_slug,'Multi-cloud / multi-source cost visibility' name,'finops-cost-visibility' slug,'Unify cost and usage visibility across multiple cloud, infrastructure, SaaS or AI cost sources.' description,0 sec UNION ALL
 SELECT 'finops-visibility-planning','Cost allocation / showback / chargeback','finops-cost-allocation','Allocate shared and direct costs to teams, products, applications or business units for accountability and showback/chargeback.',0 UNION ALL
 SELECT 'finops-visibility-planning','Budgets & forecasting','finops-budget-forecast','Create budgets, forecasts and forward-looking cloud financial plans.',0 UNION ALL
 SELECT 'finops-visibility-planning','Unit economics / business metrics','finops-unit-economics','Relate infrastructure or AI spend to business metrics such as customer, transaction, product or token-level unit costs.',0 UNION ALL
 SELECT 'finops-optimization-control','Cost anomaly detection','finops-anomaly-detection','Detect unusual or unexpected changes in cloud or infrastructure spend and alert responsible teams.',0 UNION ALL
 SELECT 'finops-optimization-control','Rightsizing / waste optimization','finops-rightsizing-optimization','Identify underused, idle or oversized infrastructure and recommend or automate waste-reduction actions.',0 UNION ALL
 SELECT 'finops-optimization-control','Commitment / rate optimization','finops-commitment-optimization','Analyze or optimize reserved instances, savings plans, committed-use discounts or equivalent rate commitments.',0 UNION ALL
 SELECT 'finops-optimization-control','Kubernetes cost management','finops-kubernetes-cost','Allocate, analyze and optimize Kubernetes or container costs at cluster, namespace, workload or service level.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@finops_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('IBM','ibm','https://www.ibm.com/','Enterprise technology, cloud, data, AI and FinOps software vendor.','active'),
('Broadcom','broadcom','https://www.broadcom.com/','Infrastructure software, cloud operations and enterprise technology vendor.','active'),
('Finout','finout','https://www.finout.io/','FinOps and cloud cost management software vendor.','active'),
('Vantage','vantage','https://www.vantage.sh/','Cloud and AI cost management and optimization software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat112_products;
CREATE TEMPORARY TABLE cat112_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat112_products VALUES
('ibm','finops-cloud-cost-management','IBM Cloudability','ibm-cloudability','Enterprise FinOps platform for multi-cloud and AI spend visibility, allocation, forecasting, anomaly detection, optimization, commitments and unit economics.','https://www.apptio.com/products/cloudability/'),
('broadcom','finops-cloud-cost-management','CloudHealth by Broadcom','cloudhealth-by-broadcom','Enterprise multi-cloud FinOps platform for cost visibility, allocation, governance, anomaly detection, rightsizing, commitment optimization and unit economics.','https://www.broadcom.com/products/software/finops/cloudhealth'),
('finout','finops-cloud-cost-management','Finout','finout-finops','FinOps platform for cloud, Kubernetes, AI and SaaS spend with allocation, budgets, forecasting, anomaly detection, optimization and unit economics.','https://www.finout.io/finops-platform'),
('ibm','finops-cloud-cost-management','IBM Kubecost','ibm-kubecost','Kubernetes-focused FinOps platform for granular cost allocation, visibility, rightsizing, savings recommendations and container infrastructure optimization.','https://www.apptio.com/company/news/press-releases/apptio-unveils-next-generation-finops-solutions-designed-to-redefine-how-cloud-leaders-manage-and-optimize-investments-in-the-ai-era/'),
('vantage','finops-cloud-cost-management','Vantage','vantage-cloud-cost-management','Cloud, SaaS and AI cost management platform for unified reporting, budgets, forecasting, anomaly detection, optimization, commitments and unit-cost analysis.','https://www.vantage.sh/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat112_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat112_sources;
CREATE TEMPORARY TABLE cat112_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat112_sources VALUES
('ibm-cloudability','https://www.apptio.com/products/cloudability/','IBM Cloudability','IBM Apptio'),
('ibm-cloudability','https://www.apptio.com/products/cloudability-family/','IBM Cloudability Family','IBM Apptio'),
('cloudhealth-by-broadcom','https://www.broadcom.com/products/software/finops/cloudhealth','CloudHealth by Broadcom','Broadcom'),
('cloudhealth-by-broadcom','https://community.broadcom.com/blogs/tj-march/2026/01/13/new-cloudhealth-experience-optimize-phase','CloudHealth Optimize Phase','Broadcom'),
('finout-finops','https://www.finout.io/finops-platform','Finout FinOps Platform','Finout'),
('finout-finops','https://www.finout.io/cloud-cost-allocation','Finout Cloud Cost Allocation','Finout'),
('finout-finops','https://www.finout.io/usecase/k8s','Finout Kubernetes Cost Management','Finout'),
('ibm-kubecost','https://www.apptio.com/company/news/press-releases/apptio-unveils-next-generation-finops-solutions-designed-to-redefine-how-cloud-leaders-manage-and-optimize-investments-in-the-ai-era/','IBM Kubecost 3.0','IBM Apptio'),
('vantage-cloud-cost-management','https://www.vantage.sh/','Vantage Cloud Cost Management','Vantage'),
('vantage-cloud-cost-management','https://www.vantage.sh/features/cost-reports','Vantage Cost Reports','Vantage');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat112_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat112_facts;
CREATE TEMPORARY TABLE cat112_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat112_facts VALUES
-- IBM Cloudability
('ibm-cloudability','finops-cost-visibility','supported',0.990,'IBM Cloudability documents unified visibility across multi-cloud, AI and SaaS spend with resource-level analytics.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-cost-allocation','supported',0.990,'Cloudability documents purpose-built mapping and cost-sharing tools for organization-wide cloud and AI cost allocation.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-budget-forecast','supported',0.990,'Cloudability documents forecasting, budgeting and workload planning as core FinOps capabilities.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-unit-economics','supported',0.990,'Cloudability documents unit economics by combining cloud costs with business metrics.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-anomaly-detection','supported',0.990,'Cloudability documents proactive notifications for spend anomalies and budget breaches.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-rightsizing-optimization','supported',0.990,'Cloudability documents rightsizing and optimization recommendations to reduce waste.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-commitment-optimization','supported',0.990,'Cloudability documents commitment-based discount management and savings automation.','https://www.apptio.com/products/cloudability/'),
('ibm-cloudability','finops-kubernetes-cost','partially_supported',0.950,'Advanced container and Kubernetes cost visibility is available through Cloudability Advanced Containers powered by Kubecost, so exact scope depends on package/add-on selection.','https://www.apptio.com/products/cloudability-family/'),

-- CloudHealth
('cloudhealth-by-broadcom','finops-cost-visibility','supported',0.990,'CloudHealth documents granular multi-cloud and AI cost visibility across public cloud, private cloud, AI and SaaS sources.','https://www.broadcom.com/products/software/finops/cloudhealth'),
('cloudhealth-by-broadcom','finops-cost-allocation','supported',0.990,'CloudHealth documents cost allocation across teams, business units and products plus reallocation and governance capabilities.','https://www.broadcom.com/products/software/finops/cloudhealth'),
('cloudhealth-by-broadcom','finops-budget-forecast','supported',0.980,'CloudHealth documents proactive budget management and financial guardrails; forecasting depth should be validated for the selected deployment.','https://www.broadcom.com/products/software/finops/cloudhealth'),
('cloudhealth-by-broadcom','finops-unit-economics','supported',0.990,'CloudHealth documents cloud unit economics aligned to product profitability and business value.','https://www.broadcom.com/products/software/finops/cloudhealth'),
('cloudhealth-by-broadcom','finops-anomaly-detection','supported',0.990,'CloudHealth documents cost anomaly detection and investigation across cloud spend.','https://www.broadcom.com/products/software/finops/cloudhealth'),
('cloudhealth-by-broadcom','finops-rightsizing-optimization','supported',0.990,'CloudHealth documents multi-cloud rightsizing and optimization recommendations.','https://community.broadcom.com/blogs/tj-march/2026/01/13/new-cloudhealth-experience-optimize-phase'),
('cloudhealth-by-broadcom','finops-commitment-optimization','supported',0.990,'CloudHealth documents optimization of spend-based and resource-based commitment discounts.','https://community.broadcom.com/blogs/tj-march/2026/01/13/new-cloudhealth-experience-optimize-phase'),

-- Finout
('finout-finops','finops-cost-visibility','supported',0.990,'Finout documents unified cost visibility across AWS, Azure, GCP, OCI, Kubernetes, AI and SaaS sources.','https://www.finout.io/finops-platform'),
('finout-finops','finops-cost-allocation','supported',0.990,'Finout documents virtual tagging and shared-cost allocation for organization-wide showback and ownership.','https://www.finout.io/cloud-cost-allocation'),
('finout-finops','finops-budget-forecast','supported',0.990,'Finout documents budgets, forecasting and financial planning based on allocated cost data.','https://www.finout.io/finops-platform'),
('finout-finops','finops-unit-economics','supported',0.990,'Finout documents unit economics such as cost per customer, product, feature and AI token.','https://www.finout.io/finops-platform'),
('finout-finops','finops-anomaly-detection','supported',0.990,'Finout documents anomaly detection across connected cost sources with routed alerts and investigation workflows.','https://www.finout.io/finops-platform'),
('finout-finops','finops-rightsizing-optimization','supported',0.990,'Finout documents rightsizing, idle-resource detection and waste recommendations.','https://www.finout.io/usecase/k8s'),
('finout-finops','finops-commitment-optimization','supported',0.980,'Finout CostGuard documents commitment recommendations alongside rightsizing and idle-resource detection; exact automation scope should be validated.','https://www.finout.io/finops-platform'),
('finout-finops','finops-kubernetes-cost','supported',0.990,'Finout documents Kubernetes allocation, shared-cost attribution, anomaly detection and rightsizing at workload level.','https://www.finout.io/usecase/k8s'),

-- IBM Kubecost
('ibm-kubecost','finops-cost-allocation','supported',0.990,'IBM Kubecost 3.0 documents unified Kubernetes resource visibility and granular cost allocation across clusters and workloads.','https://www.apptio.com/company/news/press-releases/apptio-unveils-next-generation-finops-solutions-designed-to-redefine-how-cloud-leaders-manage-and-optimize-investments-in-the-ai-era/'),
('ibm-kubecost','finops-rightsizing-optimization','supported',0.990,'IBM Kubecost 3.0 documents automated container rightsizing, node-group sizing and savings recommendations.','https://www.apptio.com/company/news/press-releases/apptio-unveils-next-generation-finops-solutions-designed-to-redefine-how-cloud-leaders-manage-and-optimize-investments-in-the-ai-era/'),
('ibm-kubecost','finops-kubernetes-cost','supported',0.990,'IBM Kubecost is specifically documented as Kubernetes cost management and optimization for complex container environments.','https://www.apptio.com/company/news/press-releases/apptio-unveils-next-generation-finops-solutions-designed-to-redefine-how-cloud-leaders-manage-and-optimize-investments-in-the-ai-era/'),

-- Vantage
('vantage-cloud-cost-management','finops-cost-visibility','supported',0.990,'Vantage documents unified cost reporting across cloud, SaaS and AI sources.','https://www.vantage.sh/'),
('vantage-cloud-cost-management','finops-cost-allocation','supported',0.980,'Vantage documents virtual tagging and organizational cost reporting for allocating spend across dimensions.','https://www.vantage.sh/'),
('vantage-cloud-cost-management','finops-budget-forecast','supported',0.990,'Vantage Cost Reports include customizable ML-powered forecasting, budgets and scenario modeling.','https://www.vantage.sh/features/cost-reports'),
('vantage-cloud-cost-management','finops-unit-economics','supported',0.990,'Vantage documents Unit Costs as a core FinOps capability.','https://www.vantage.sh/'),
('vantage-cloud-cost-management','finops-anomaly-detection','supported',0.990,'Vantage Cost Reports include anomaly detection and custom cost alerts.','https://www.vantage.sh/features/cost-reports'),
('vantage-cloud-cost-management','finops-rightsizing-optimization','supported',0.990,'Vantage documents cost recommendations, Kubernetes rightsizing and cross-provider recommendations.','https://www.vantage.sh/'),
('vantage-cloud-cost-management','finops-commitment-optimization','supported',0.980,'Vantage documents Autopilot for savings-plan purchases; exact provider and commitment coverage depends on connected environments.','https://www.vantage.sh/'),
('vantage-cloud-cost-management','finops-kubernetes-cost','supported',0.990,'Vantage documents Kubernetes rightsizing as part of its optimization capabilities.','https://www.vantage.sh/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat112_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat112_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat112_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment and mobile administration are not inferred from cloud-delivered access or mobile browsers in this first batch.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('ibm-cloudability','cloudhealth-by-broadcom','finout-finops','ibm-kubecost','vantage-cloud-cost-management')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
