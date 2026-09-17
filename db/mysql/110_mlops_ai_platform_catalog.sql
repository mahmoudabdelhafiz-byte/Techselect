-- TechSelectAI MLOps & Machine Learning Platform catalog expansion.
-- Adds one canonical category and five evidence-backed current products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('MLOps & Machine Learning Platforms','mlops-machine-learning-platforms','Platforms for developing, tracking, governing, deploying, serving and monitoring machine learning models and reusable ML features across the model lifecycle.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @mlops_cat=(SELECT id FROM categories WHERE slug='mlops-machine-learning-platforms' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@mlops_cat,'Development & Lifecycle','mlops-development-lifecycle','Experiment tracking, reusable pipelines, feature management and governed model lifecycle management.',1),
(@mlops_cat,'Deployment & Production','mlops-deployment-production','Model serving, deployment automation and production model monitoring.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,0,1
FROM modules m JOIN (
 SELECT 'mlops-development-lifecycle' module_slug,'Experiment tracking & evaluation' name,'mlops-experiment-tracking' slug,'Track runs, parameters, metrics, artifacts and model evaluation results.' UNION ALL
 SELECT 'mlops-development-lifecycle','ML pipelines / workflow orchestration','mlops-pipelines','Build repeatable training, validation or deployment workflows as managed ML pipelines.' UNION ALL
 SELECT 'mlops-development-lifecycle','Model registry & lifecycle governance','mlops-model-registry','Register, version, govern, approve and trace machine learning models across lifecycle stages.' UNION ALL
 SELECT 'mlops-development-lifecycle','Feature store / reusable feature management','mlops-feature-store','Create, register, reuse, govern and serve machine learning features consistently for training and inference.' UNION ALL
 SELECT 'mlops-deployment-production','Model deployment & serving','mlops-model-serving','Deploy models to real-time or batch inference endpoints and manage production serving.' UNION ALL
 SELECT 'mlops-deployment-production','Production model monitoring','mlops-model-monitoring','Monitor deployed models, data drift, performance, health or production behavior.'
) x ON x.module_slug=m.slug
WHERE m.category_id=@mlops_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Databricks','databricks','https://www.databricks.com/','Data, analytics, AI and machine learning platform vendor.','active'),
('Amazon Web Services','amazon-web-services','https://aws.amazon.com/','Cloud infrastructure, data and AI services vendor.','active'),
('Domino Data Lab','domino-data-lab','https://domino.ai/','Enterprise AI and MLOps platform vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud, data and AI platform vendor.','active'),
('Dataiku','dataiku','https://www.dataiku.com/','Enterprise AI, analytics and machine learning platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat110_products;
CREATE TEMPORARY TABLE cat110_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat110_products VALUES
('databricks','mlops-machine-learning-platforms','Databricks Machine Learning','databricks-machine-learning','Machine learning platform built around MLflow and Unity Catalog for experiment tracking, feature engineering, governed model registry, deployment and model monitoring.','https://docs.databricks.com/aws/en/machine-learning/'),
('amazon-web-services','mlops-machine-learning-platforms','Amazon SageMaker AI','amazon-sagemaker-ai','Managed machine learning platform for ML pipelines, feature engineering, model registry, deployment automation, inference and production monitoring.','https://docs.aws.amazon.com/sagemaker/latest/dg/whatis.html'),
('domino-data-lab','mlops-machine-learning-platforms','Domino Enterprise MLOps','domino-enterprise-mlops','Enterprise MLOps platform for governed experimentation, pipelines, model registry, deployment and production monitoring across cloud, hybrid and on-premises environments.','https://domino.ai/platform/mlops'),
('microsoft','mlops-machine-learning-platforms','Azure Machine Learning','azure-machine-learning','Cloud machine learning service for experiment tracking, reusable pipelines, registries, feature store, model deployment and production monitoring.','https://azure.microsoft.com/en-us/products/machine-learning'),
('dataiku','mlops-machine-learning-platforms','Dataiku','dataiku-mlops','Enterprise AI and machine learning platform with experiment tracking, model lifecycle, MLOps, feature store, deployment and monitoring capabilities.','https://www.dataiku.com/product/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat110_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat110_sources;
CREATE TEMPORARY TABLE cat110_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat110_sources VALUES
('databricks-machine-learning','https://docs.databricks.com/aws/en/mlflow','MLflow on Databricks','Databricks'),
('databricks-machine-learning','https://docs.databricks.com/aws/en/machine-learning/feature-store','Databricks Feature Store','Databricks'),
('databricks-machine-learning','https://docs.databricks.com/aws/en/machine-learning/concepts/ml-capabilities','Databricks ML capabilities','Databricks'),
('amazon-sagemaker-ai','https://docs.aws.amazon.com/sagemaker/latest/dg/model-registry.html','SageMaker Model Registry','AWS'),
('amazon-sagemaker-ai','https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-feature-processing.html','SageMaker Feature Store','AWS'),
('amazon-sagemaker-ai','https://docs.aws.amazon.com/sagemaker/latest/dg/deploy-model-next-steps.html','SageMaker deployment and MLOps','AWS'),
('domino-enterprise-mlops','https://domino.ai/platform/mlops','Domino MLOps Platform','Domino Data Lab'),
('domino-enterprise-mlops','https://domino.ai/platform/ai-workbench','Domino AI Workbench','Domino Data Lab'),
('azure-machine-learning','https://learn.microsoft.com/en-us/azure/machine-learning/how-to-share-models-pipelines-across-workspaces-with-registries','Azure ML registries and cross-workspace MLOps','Microsoft'),
('azure-machine-learning','https://learn.microsoft.com/en-us/azure/machine-learning/concept-what-is-managed-feature-store','Azure ML managed feature store','Microsoft'),
('azure-machine-learning','https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-managed-online-endpoints','Azure ML managed online endpoints','Microsoft'),
('azure-machine-learning','https://learn.microsoft.com/en-us/azure/machine-learning/how-to-monitor-model-performance','Azure ML model monitoring','Microsoft'),
('dataiku-mlops','https://doc.dataiku.com/dss/latest/mlops/index.html','Dataiku MLOps','Dataiku');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat110_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat110_facts;
CREATE TEMPORARY TABLE cat110_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat110_facts VALUES
('databricks-machine-learning','mlops-experiment-tracking','supported',0.990,'MLflow on Databricks provides experiment tracking, model evaluation, metrics, parameters and artifact management.','https://docs.databricks.com/aws/en/mlflow'),
('databricks-machine-learning','mlops-model-registry','supported',0.990,'Databricks uses MLflow Model Registry with Unity Catalog for governed model versions, lifecycle metadata, access control and lineage.','https://docs.databricks.com/aws/en/machine-learning/concepts/ml-capabilities'),
('databricks-machine-learning','mlops-feature-store','supported',0.990,'Databricks Feature Store centralizes reusable features with governance, lineage and online/offline serving.','https://docs.databricks.com/aws/en/machine-learning/feature-store'),
('databricks-machine-learning','mlops-model-serving','supported',0.990,'Databricks documents real-time serving endpoints and batch inference for registered models.','https://docs.databricks.com/aws/en/machine-learning/concepts/ml-capabilities'),
('databricks-machine-learning','mlops-model-monitoring','supported',0.970,'MLflow on Databricks documents production observability and monitoring; exact monitoring depth can differ between classic ML and agent workloads.','https://docs.databricks.com/aws/en/mlflow'),

('amazon-sagemaker-ai','mlops-pipelines','supported',0.990,'SageMaker AI documents managed MLOps pipelines for repeatable ML workflows and CI/CD automation.','https://docs.aws.amazon.com/sagemaker/latest/dg/deploy-model-next-steps.html'),
('amazon-sagemaker-ai','mlops-model-registry','supported',0.990,'SageMaker Model Registry supports model cataloging, versions, metadata, approvals, lineage, deployment and CI/CD.','https://docs.aws.amazon.com/sagemaker/latest/dg/model-registry.html'),
('amazon-sagemaker-ai','mlops-feature-store','supported',0.990,'SageMaker Feature Store supports managed feature processing, online/offline stores and pipeline-based feature engineering.','https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-feature-processing.html'),
('amazon-sagemaker-ai','mlops-model-serving','supported',0.990,'SageMaker AI supports managed production inference and deployment guardrails for model endpoints.','https://docs.aws.amazon.com/sagemaker/latest/dg/deploy-model-next-steps.html'),

('domino-enterprise-mlops','mlops-experiment-tracking','supported',0.990,'Domino documents organized experiment tracking, comparison and reproducibility across AI and ML development work.','https://domino.ai/platform/ai-workbench'),
('domino-enterprise-mlops','mlops-pipelines','supported',0.990,'Domino documents visual automation and monitoring of data and model pipelines with Domino Flows.','https://domino.ai/platform/ai-workbench'),
('domino-enterprise-mlops','mlops-model-registry','supported',0.990,'Domino documents a governed model registry with lineage, model cards, stakeholder review and approval workflows.','https://domino.ai/platform/mlops'),
('domino-enterprise-mlops','mlops-model-serving','supported',0.990,'Domino documents batch and real-time model deployment across Domino, CI/CD, cloud and hybrid targets.','https://domino.ai/platform/mlops'),
('domino-enterprise-mlops','mlops-model-monitoring','supported',0.990,'Domino documents monitoring for accuracy, drift, endpoint health and model quality with alerts and remediation workflows.','https://domino.ai/platform/mlops'),

('azure-machine-learning','mlops-model-registry','supported',0.990,'Azure Machine Learning registries share models, components and environments across workspaces with lineage preserved.','https://learn.microsoft.com/en-us/azure/machine-learning/how-to-share-models-pipelines-across-workspaces-with-registries'),
('azure-machine-learning','mlops-feature-store','supported',0.990,'Azure Machine Learning managed feature store supports feature discovery, versioning, materialization, retrieval, serving and monitoring.','https://learn.microsoft.com/en-us/azure/machine-learning/concept-what-is-managed-feature-store'),
('azure-machine-learning','mlops-model-serving','supported',0.990,'Azure Machine Learning supports managed online and batch endpoints for model inference.','https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-managed-online-endpoints'),
('azure-machine-learning','mlops-model-monitoring','supported',0.990,'Azure Machine Learning supports scheduled model monitoring for production performance and drift scenarios.','https://learn.microsoft.com/en-us/azure/machine-learning/how-to-monitor-model-performance'),

('dataiku-mlops','mlops-experiment-tracking','supported',0.990,'Dataiku MLOps includes experiment tracking, model comparison and lifecycle traceability.','https://doc.dataiku.com/dss/latest/mlops/index.html'),
('dataiku-mlops','mlops-pipelines','supported',0.970,'Dataiku documents CI/CD project deployment and test scenarios for productionizing ML workflows; orchestration differs from dedicated cloud pipeline services.','https://doc.dataiku.com/dss/latest/mlops/index.html'),
('dataiku-mlops','mlops-model-registry','supported',0.990,'Dataiku documents model version evaluation, comparison, import and lifecycle management capabilities.','https://doc.dataiku.com/dss/latest/mlops/index.html'),
('dataiku-mlops','mlops-feature-store','supported',0.990,'Dataiku MLOps explicitly includes a Feature Store for curated reusable features.','https://doc.dataiku.com/dss/latest/mlops/index.html'),
('dataiku-mlops','mlops-model-serving','supported',0.990,'Dataiku documents versioned real-time REST API scoring and model deployment to production.','https://doc.dataiku.com/dss/latest/mlops/index.html'),
('dataiku-mlops','mlops-model-monitoring','supported',0.990,'Dataiku documents drift analysis and unified monitoring of projects, endpoints and model health.','https://doc.dataiku.com/dss/latest/mlops/index.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat110_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat110_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat110_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment and mobile administration are intentionally not inferred in this first batch.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('databricks-machine-learning','amazon-sagemaker-ai','domino-enterprise-mlops','azure-machine-learning','dataiku-mlops')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
