-- TechSelectAI ITAM + UEM catalog expansion.
-- Adds two new canonical enterprise categories and eight evidence-backed products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

/* =========================================================
   IT Asset Management
   ========================================================= */
INSERT INTO categories(name,slug,description,is_active) VALUES
('IT Asset Management (ITAM)','it-asset-management','Software for discovering, inventorying, tracking, governing and optimizing hardware, software, licenses, contracts and related IT assets across their lifecycle.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @itam_cat=(SELECT id FROM categories WHERE slug='it-asset-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@itam_cat,'Asset Discovery & Inventory','itam-discovery-inventory','Discovery, inventory, normalization and visibility across hardware, software and related technology assets.',1),
(@itam_cat,'Lifecycle, Licensing & Governance','itam-lifecycle-governance','Asset lifecycle, software licensing, contracts, procurement context, compliance and CMDB/ITSM integration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'itam-discovery-inventory' module_slug,'Automated asset discovery & inventory' name,'itam-discovery-inventory' slug,'Automatically discover and maintain inventory of hardware, software, cloud or other IT assets.' description,0 sec UNION ALL
 SELECT 'itam-lifecycle-governance','Hardware / asset lifecycle management','itam-asset-lifecycle','Track IT assets through ownership, deployment, use, movement, retirement or disposal lifecycle stages.',0 UNION ALL
 SELECT 'itam-lifecycle-governance','Software license / entitlement management','itam-software-license-management','Track software licenses, entitlements, usage, compliance or optimization opportunities.',0 UNION ALL
 SELECT 'itam-lifecycle-governance','Contracts / purchase / financial context','itam-contract-purchase-management','Manage or connect purchase orders, contracts, costs, warranties, renewals or financial data associated with IT assets.',0 UNION ALL
 SELECT 'itam-lifecycle-governance','CMDB / ITSM integration','itam-cmdb-itsm-integration','Integrate asset data with CMDB, ITSM or service-management workflows and systems.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@itam_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

/* =========================================================
   Unified Endpoint Management
   ========================================================= */
INSERT INTO categories(name,slug,description,is_active) VALUES
('Unified Endpoint Management (UEM)','unified-endpoint-management','Platforms for centrally provisioning, configuring, securing, updating and supporting desktops, laptops, mobile devices and other enterprise endpoints across multiple operating systems.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @uem_cat=(SELECT id FROM categories WHERE slug='unified-endpoint-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@uem_cat,'Device Lifecycle & Configuration','uem-device-lifecycle','Enrollment, provisioning, configuration, policy and application management across endpoint platforms.',1),
(@uem_cat,'Endpoint Operations & Security','uem-operations-security','Patch/update management, compliance, security posture, remote support and operational endpoint administration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'uem-device-lifecycle' module_slug,'Cross-platform endpoint management' name,'uem-cross-platform-management' slug,'Centrally manage multiple endpoint operating systems and device classes from one administrative platform.' description,0 sec UNION ALL
 SELECT 'uem-device-lifecycle','Enrollment & provisioning','uem-enrollment-provisioning','Enroll, onboard or provision enterprise endpoints using manual, automated or zero-touch methods.',0 UNION ALL
 SELECT 'uem-device-lifecycle','Configuration & policy management','uem-configuration-policy','Apply and maintain device configurations, profiles, controls and administrative policies.',1 UNION ALL
 SELECT 'uem-device-lifecycle','Application management & distribution','uem-application-management','Deploy, configure, update, restrict or remove applications across managed endpoints.',0 UNION ALL
 SELECT 'uem-operations-security','Patch / OS update management','uem-patch-update-management','Plan, automate, deploy or govern operating-system, application or endpoint updates and patches.',1 UNION ALL
 SELECT 'uem-operations-security','Compliance & endpoint security controls','uem-compliance-security','Assess or enforce device compliance, security posture and endpoint-security controls through management policy.',1 UNION ALL
 SELECT 'uem-operations-security','Remote support / troubleshooting','uem-remote-support','Remotely view, control, troubleshoot or support managed endpoints.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@uem_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Lansweeper','lansweeper','https://www.lansweeper.com/','Technology asset intelligence and discovery software vendor.','active'),
('Flexera','flexera','https://www.flexera.com/','IT asset management, software asset management, FinOps and technology intelligence vendor.','active'),
('ServiceNow','servicenow','https://www.servicenow.com/','Enterprise workflow, IT service management and IT asset management software vendor.','active'),
('ManageEngine','manageengine','https://www.manageengine.com/','Enterprise IT operations, service management, endpoint and security software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud, security and endpoint-management vendor.','active'),
('Omnissa','omnissa','https://www.omnissa.com/','Digital workspace, virtual desktop and unified endpoint management software vendor.','active'),
('Hexnode','hexnode','https://www.hexnode.com/','Unified endpoint management and endpoint security software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat105_products;
CREATE TEMPORARY TABLE cat105_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat105_products VALUES
('lansweeper','it-asset-management','Lansweeper','lansweeper-it-asset-management','Technology asset intelligence platform focused on automated discovery, inventory and normalization of IT, OT, cloud and other connected technology assets.','https://www.lansweeper.com/product/'),
('flexera','it-asset-management','Flexera One IT Asset Management','flexera-one-itam','IT asset management platform for hybrid technology estates with software-license intelligence, discovery, hardware asset management, entitlement data and audit-readiness workflows.','https://www.flexera.com/products/flexera-one/it-asset-management'),
('servicenow','it-asset-management','ServiceNow IT Asset Management','servicenow-it-asset-management','IT asset management on the ServiceNow AI Platform for hardware, software and cloud asset lifecycle, cost, compliance, inventory and connected CMDB/procurement workflows.','https://www.servicenow.com/products/it-asset-management.html'),
('manageengine','it-asset-management','ManageEngine AssetExplorer','manageengine-assetexplorer','IT asset management with discovery, inventory, software-license management, asset lifecycle, contracts, purchases, reporting and integrated CMDB capabilities.','https://www.manageengine.com/products/asset-explorer/'),
('microsoft','unified-endpoint-management','Microsoft Intune','microsoft-intune','Cloud endpoint management for cross-platform devices, applications and operating systems with policy, compliance, update and endpoint-security administration.','https://www.microsoft.com/en-us/security/business/endpoint-management/microsoft-intune'),
('omnissa','unified-endpoint-management','Omnissa Workspace ONE UEM','omnissa-workspace-one-uem','Cloud-native unified endpoint management for desktops, mobile, rugged, servers and specialty devices across major operating systems from a centralized console.','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/'),
('manageengine','unified-endpoint-management','ManageEngine Endpoint Central','manageengine-endpoint-central','Unified endpoint management and security platform for desktop, server, mobile and other endpoints with patching, configuration, application, inventory and troubleshooting capabilities.','https://www.manageengine.com/products/desktop-central/features.html'),
('hexnode','unified-endpoint-management','Hexnode UEM','hexnode-uem','Cloud-based unified endpoint management for Android, Apple, Windows, Linux, ChromeOS and other device platforms with enrollment, policies, applications, security and remote administration.','https://www.hexnode.com/uem/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat105_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat105_sources;
CREATE TEMPORARY TABLE cat105_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat105_sources VALUES
('lansweeper-it-asset-management','https://www.lansweeper.com/product/','Lansweeper Platform Overview','Lansweeper'),
('lansweeper-it-asset-management','https://www.lansweeper.com/product/features/','Lansweeper Features','Lansweeper'),
('lansweeper-it-asset-management','https://www.lansweeper.com/product/integrations/','Lansweeper Integrations','Lansweeper'),
('flexera-one-itam','https://www.flexera.com/products/flexera-one/it-asset-management','Flexera One IT Asset Management','Flexera'),
('flexera-one-itam','https://www.flexera.com/solutions/it-inventory/it-asset-discovery','Flexera IT Asset Discovery','Flexera'),
('servicenow-it-asset-management','https://www.servicenow.com/products/it-asset-management.html','ServiceNow IT Asset Management','ServiceNow'),
('servicenow-it-asset-management','https://www.servicenow.com/products/it-asset-management/what-is-itam.html','What is IT Asset Management?','ServiceNow'),
('manageengine-assetexplorer','https://www.manageengine.com/productdocument.html','ManageEngine Product Documentation','ManageEngine'),
('manageengine-assetexplorer','https://download.manageengine.com/government/files/asset-explorer-ds.pdf','ManageEngine AssetExplorer Datasheet','ManageEngine'),
('manageengine-assetexplorer','https://www.manageengine.com/blog/general/unveiling-cloud-based-manageengine-assetexplorer-our-enterprise-it-asset-management-platform.html','ManageEngine AssetExplorer Cloud','ManageEngine'),
('microsoft-intune','https://www.microsoft.com/en-us/security/business/endpoint-management/microsoft-intune','Microsoft Intune Core Capabilities','Microsoft'),
('microsoft-intune','https://www.microsoft.com/en-us/security/business/microsoft-intune','Microsoft Intune','Microsoft'),
('omnissa-workspace-one-uem','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/','Omnissa Workspace ONE UEM','Omnissa'),
('omnissa-workspace-one-uem','https://docs.omnissa.com/','Omnissa Product Documentation','Omnissa'),
('manageengine-endpoint-central','https://www.manageengine.com/products/desktop-central/features.html','ManageEngine Endpoint Central Features','ManageEngine'),
('manageengine-endpoint-central','https://www.manageengine.com/products/desktop-central/help/','ManageEngine Endpoint Central Help','ManageEngine'),
('hexnode-uem','https://www.hexnode.com/uem/','Hexnode UEM','Hexnode'),
('hexnode-uem','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/','What is Hexnode UEM?','Hexnode'),
('hexnode-uem','https://www.hexnode.com/mobile-device-management/help/quickstart-for-hexnode-uem/','Hexnode UEM Quickstart','Hexnode');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat105_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat105_facts;
CREATE TEMPORARY TABLE cat105_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat105_facts VALUES
-- Lansweeper
('lansweeper-it-asset-management','itam-discovery-inventory','supported',0.990,'Lansweeper documents automated discovery and centralized inventory across IT, OT, cloud, managed and unmanaged technology assets.','https://www.lansweeper.com/product/'),
('lansweeper-it-asset-management','itam-cmdb-itsm-integration','supported',0.970,'Lansweeper documents integrations that feed continuously updated asset intelligence to CMDB, ITSM and related systems.','https://www.lansweeper.com/product/integrations/'),

-- Flexera One ITAM
('flexera-one-itam','itam-discovery-inventory','supported',0.990,'Flexera documents asset discovery and unified inventory across on-premises, cloud, SaaS and container environments.','https://www.flexera.com/products/flexera-one/it-asset-management'),
('flexera-one-itam','itam-asset-lifecycle','supported',0.970,'Flexera documents hardware asset management and asset lifecycle/risk management across the technology estate.','https://www.flexera.com/products/flexera-one/it-asset-management'),
('flexera-one-itam','itam-software-license-management','supported',0.990,'Flexera documents license-position, use-rights, audit readiness, true-up optimization and automated reclamation capabilities.','https://www.flexera.com/products/flexera-one/it-asset-management'),
('flexera-one-itam','itam-contract-purchase-management','supported',0.990,'Flexera documents AI ingestion of contracts, entitlements, purchase orders, invoices and quotes for structured ITAM records.','https://www.flexera.com/products/flexera-one/it-asset-management'),
('flexera-one-itam','itam-cmdb-itsm-integration','supported',0.980,'Flexera documents ITSM/CMDB data enrichment including ServiceNow integration.','https://www.flexera.com/products/flexera-one/it-asset-management'),

-- ServiceNow ITAM
('servicenow-it-asset-management','itam-discovery-inventory','supported',0.980,'ServiceNow documents real-time visibility across hardware, software and cloud IT assets; discovery method depends on the broader ServiceNow deployment.','https://www.servicenow.com/products/it-asset-management.html'),
('servicenow-it-asset-management','itam-asset-lifecycle','supported',0.990,'ServiceNow documents automation of the full asset lifecycle from planning through end-of-life.','https://www.servicenow.com/products/it-asset-management.html'),
('servicenow-it-asset-management','itam-software-license-management','supported',0.980,'ServiceNow documents software asset and license tracking, usage, compliance and audit-readiness workflows within ITAM.','https://www.servicenow.com/products/it-asset-management.html'),
('servicenow-it-asset-management','itam-contract-purchase-management','supported',0.990,'ServiceNow documents contract, cost, procurement and inventory context connected to ITAM workflows.','https://www.servicenow.com/products/it-asset-management.html'),
('servicenow-it-asset-management','itam-cmdb-itsm-integration','supported',0.990,'ServiceNow documents direct connection of ITAM with catalogs, CMDB, procurement and service workflows on the ServiceNow platform.','https://www.servicenow.com/products/it-asset-management.html'),

-- ManageEngine AssetExplorer
('manageengine-assetexplorer','itam-discovery-inventory','supported',0.990,'ManageEngine documents asset discovery, detailed inventory and hardware/software inventory management.','https://download.manageengine.com/government/files/asset-explorer-ds.pdf'),
('manageengine-assetexplorer','itam-asset-lifecycle','supported',0.990,'ManageEngine documents complete hardware/software asset lifecycle tracking from procurement through disposal.','https://download.manageengine.com/government/files/asset-explorer-ds.pdf'),
('manageengine-assetexplorer','itam-software-license-management','supported',0.990,'ManageEngine documents software asset management, license management and software-license compliance.','https://download.manageengine.com/government/files/asset-explorer-ds.pdf'),
('manageengine-assetexplorer','itam-contract-purchase-management','supported',0.990,'ManageEngine documents purchase-order, contract, financial, warranty and lifecycle management in AssetExplorer.','https://download.manageengine.com/government/files/asset-explorer-ds.pdf'),
('manageengine-assetexplorer','itam-cmdb-itsm-integration','supported',0.990,'ManageEngine identifies AssetExplorer as IT asset management with integrated CMDB and documents CMDB relationship synchronization.','https://www.manageengine.com/productdocument.html'),

-- Microsoft Intune
('microsoft-intune','uem-cross-platform-management','supported',0.990,'Microsoft documents unified management of cross-platform devices, apps and operating systems.','https://www.microsoft.com/en-us/security/business/endpoint-management/microsoft-intune'),
('microsoft-intune','uem-enrollment-provisioning','supported',0.970,'Microsoft documents endpoint management from setup through decommissioning; enrollment methods vary by platform and license.','https://www.microsoft.com/en-us/security/business/microsoft-intune'),
('microsoft-intune','uem-configuration-policy','supported',0.990,'Microsoft documents policy enforcement and centralized endpoint configuration/compliance management.','https://www.microsoft.com/en-us/security/business/endpoint-management/microsoft-intune'),
('microsoft-intune','uem-application-management','supported',0.980,'Microsoft documents management and protection of cloud-connected endpoints and applications across supported platforms.','https://www.microsoft.com/en-us/security/business/microsoft-intune'),
('microsoft-intune','uem-patch-update-management','supported',0.990,'Microsoft documents patching and keeping applications current across platforms.','https://www.microsoft.com/en-us/security/business/endpoint-management/microsoft-intune'),
('microsoft-intune','uem-compliance-security','supported',0.990,'Microsoft documents device compliance, Zero Trust controls and endpoint security-status management.','https://www.microsoft.com/en-us/security/business/microsoft-intune'),

-- Omnissa Workspace ONE UEM
('omnissa-workspace-one-uem','uem-cross-platform-management','supported',0.990,'Omnissa documents centralized management across Windows, macOS, iOS, Android, Linux, ChromeOS, servers, rugged and specialty devices.','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/'),
('omnissa-workspace-one-uem','uem-enrollment-provisioning','supported',0.990,'Omnissa documents deployment and lifecycle management across device ownership models and endpoint platforms.','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/'),
('omnissa-workspace-one-uem','uem-configuration-policy','supported',0.990,'Omnissa documents centralized device configuration, policy and granular management controls.','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/'),
('omnissa-workspace-one-uem','uem-patch-update-management','supported',0.990,'Omnissa documents endpoint updating and automated patch management within UEM.','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/'),
('omnissa-workspace-one-uem','uem-compliance-security','supported',0.990,'Omnissa documents compliance policies, conditional access and device-posture checks.','https://www.omnissa.com/products/workspace-one-unified-endpoint-management/'),

-- ManageEngine Endpoint Central
('manageengine-endpoint-central','uem-cross-platform-management','supported',0.990,'ManageEngine documents endpoint management across desktops, servers, mobile devices and multiple operating systems.','https://www.manageengine.com/products/desktop-central/features.html'),
('manageengine-endpoint-central','uem-enrollment-provisioning','supported',0.980,'Endpoint Central documentation covers device onboarding for Windows, Apple, Android, Knox, Chrome and Linux.','https://www.manageengine.com/products/desktop-central/help/'),
('manageengine-endpoint-central','uem-configuration-policy','supported',0.990,'ManageEngine documents system configurations, profiles, kiosk controls and policy-oriented administration.','https://www.manageengine.com/products/desktop-central/features.html'),
('manageengine-endpoint-central','uem-application-management','supported',0.990,'ManageEngine documents software/application distribution and application management capabilities.','https://www.manageengine.com/products/desktop-central/features.html'),
('manageengine-endpoint-central','uem-patch-update-management','supported',0.990,'ManageEngine documents automated operating-system, application and mobile-app patching and updates.','https://www.manageengine.com/products/desktop-central/features.html'),
('manageengine-endpoint-central','uem-compliance-security','supported',0.990,'ManageEngine documents endpoint compliance, security, vulnerability remediation and audit reporting capabilities.','https://www.manageengine.com/products/desktop-central/features.html'),
('manageengine-endpoint-central','uem-remote-support','supported',0.990,'ManageEngine documents remote access and troubleshooting capabilities.','https://www.manageengine.com/products/desktop-central/features.html'),

-- Hexnode UEM
('hexnode-uem','uem-cross-platform-management','supported',0.990,'Hexnode documents centralized management across Android, Windows, iOS/iPadOS, macOS, Fire OS, tvOS, visionOS, Linux and ChromeOS.','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/'),
('hexnode-uem','uem-enrollment-provisioning','supported',0.990,'Hexnode documents device enrollment and zero-touch onboarding methods across supported platforms.','https://www.hexnode.com/mobile-device-management/help/quickstart-for-hexnode-uem/'),
('hexnode-uem','uem-configuration-policy','supported',0.990,'Hexnode documents groups, policies, device configurations and centralized policy enforcement.','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/'),
('hexnode-uem','uem-application-management','supported',0.990,'Hexnode documents application management and enterprise application distribution.','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/'),
('hexnode-uem','uem-patch-update-management','supported',0.970,'Hexnode documents patch management and operating-system update controls; exact coverage differs by platform and plan.','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/'),
('hexnode-uem','uem-compliance-security','supported',0.990,'Hexnode documents security management, device compliance and security policy enforcement.','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/'),
('hexnode-uem','uem-remote-support','supported',0.990,'Hexnode documents remote control and remote administration actions for supported endpoints.','https://www.hexnode.com/mobile-device-management/help/what-is-hexnode-mdm/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat105_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat105_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat105_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment facts: only explicit, product-specific evidence is promoted.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('flexera-one-itam','servicenow-it-asset-management','microsoft-intune','omnissa-workspace-one-uem','manageengine-endpoint-central','hexnode-uem')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98
FROM products p JOIN deployment_models d ON d.slug='on-premise'
WHERE p.slug IN('flexera-one-itam','manageengine-assetexplorer','manageengine-endpoint-central')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Mobile administration is not inferred from managed-device agents/apps.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN(
'lansweeper-it-asset-management','flexera-one-itam','servicenow-it-asset-management','manageengine-assetexplorer',
'microsoft-intune','omnissa-workspace-one-uem','manageengine-endpoint-central','hexnode-uem'
)
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
