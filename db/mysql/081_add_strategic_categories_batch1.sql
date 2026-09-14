-- TechSelectAI strategic category expansion batch 1
-- Adds Enterprise Architecture & APM, Integration & API Management, and RPA & Intelligent Automation.
-- Seeds recognizable products using official first-party evidence reviewed in Sep 2026.
-- Preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Enterprise Architecture & Application Portfolio Management','enterprise-architecture-apm','Enterprise architecture and application portfolio management platforms for modeling business and technology landscapes, governing application portfolios, rationalization and transformation planning.',1),
('Integration & API Management','integration-api-management','Enterprise integration and API management platforms for application/data integration, orchestration, API lifecycle management, governance, security and monitoring.',1),
('RPA & Intelligent Automation','rpa-intelligent-automation','Robotic process automation and intelligent automation platforms for desktop/web automation, attended and unattended execution, orchestration, governance and human-in-the-loop workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'enterprise-architecture-apm' cat,'Architecture Modeling & Repository' name,'ea-modeling-repository' slug,'Enterprise architecture repository, application inventory, capability mapping, dependencies and target-state design.' description UNION ALL
 SELECT 'enterprise-architecture-apm','Application Portfolio & Governance','ea-portfolio-governance','Application lifecycle, portfolio assessment, rationalization, cost/risk analysis and architecture governance.' UNION ALL
 SELECT 'integration-api-management','Integration & Orchestration','integration-orchestration','Application and data integration, connectors, transformation, workflow orchestration and hybrid runtime.' UNION ALL
 SELECT 'integration-api-management','API Management & Governance','api-management-governance','API design, publishing, gateways, security, lifecycle governance, monitoring and analytics.' UNION ALL
 SELECT 'rpa-intelligent-automation','RPA Execution','rpa-execution','Desktop and web automation with attended, unattended and centrally orchestrated execution.' UNION ALL
 SELECT 'rpa-intelligent-automation','Automation Governance & Intelligence','rpa-governance-intelligence','Workflow orchestration, AI-assisted automation, human interaction and enterprise governance.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'ea-modeling-repository' ms,'Application inventory / repository' name,'ea-application-inventory' slug,'Maintain a governed inventory or repository of enterprise applications.' description,0 sec UNION ALL
 SELECT 'ea-modeling-repository','Business capability mapping','ea-business-capability-mapping','Map applications, technology and initiatives to business capabilities.',0 UNION ALL
 SELECT 'ea-modeling-repository','Dependency & relationship modeling','ea-dependency-modeling','Model dependencies and relationships across applications, technology, processes and business domains.',0 UNION ALL
 SELECT 'ea-modeling-repository','Roadmaps & target-state architecture','ea-roadmaps-target-state','Design future-state architecture and transformation roadmaps.',0 UNION ALL
 SELECT 'ea-portfolio-governance','Application lifecycle management','ea-application-lifecycle','Track lifecycle status, ownership, standards and end-of-life exposure.',0 UNION ALL
 SELECT 'ea-portfolio-governance','Application rationalization','ea-portfolio-rationalization','Identify redundancy, consolidation, modernization and retirement opportunities.',0 UNION ALL
 SELECT 'ea-portfolio-governance','Cost, risk & technical-health assessment','ea-risk-cost-assessment','Assess portfolio cost, business fit, technical health and risk.',1 UNION ALL
 SELECT 'ea-portfolio-governance','Collaboration & architecture governance','ea-collaboration-governance','Support stakeholder collaboration, review and architecture governance workflows.',1 UNION ALL
 SELECT 'integration-orchestration','Application & SaaS connectors','integration-connectors','Connect enterprise applications, SaaS services, databases and other endpoints.',0 UNION ALL
 SELECT 'integration-orchestration','Workflow / integration orchestration','integration-workflow-orchestration','Build and orchestrate integration workflows across systems and services.',0 UNION ALL
 SELECT 'integration-orchestration','Data mapping & transformation','integration-data-transformation','Transform, map and route data between connected systems.',0 UNION ALL
 SELECT 'integration-orchestration','Hybrid / private runtime','integration-hybrid-runtime','Run integrations in cloud, private or hybrid environments.',1 UNION ALL
 SELECT 'api-management-governance','API design & publishing','api-design-publish','Design, expose, publish or productize APIs for consumers.',0 UNION ALL
 SELECT 'api-management-governance','API gateway & security','api-gateway-security','Control API traffic, authentication, authorization, policies and security.',1 UNION ALL
 SELECT 'api-management-governance','API lifecycle & governance','api-lifecycle-governance','Govern APIs across design, release, versioning and retirement.',1 UNION ALL
 SELECT 'api-management-governance','API monitoring & analytics','api-monitoring-analytics','Monitor API traffic, health, usage and operational analytics.',1 UNION ALL
 SELECT 'rpa-execution','Desktop & web UI automation','rpa-desktop-web-automation','Automate tasks across desktop, browser and legacy user interfaces.',0 UNION ALL
 SELECT 'rpa-execution','Attended automation','rpa-attended','Run automations under human supervision or user initiation.',0 UNION ALL
 SELECT 'rpa-execution','Unattended automation','rpa-unattended','Run autonomous automations without human supervision.',0 UNION ALL
 SELECT 'rpa-execution','Central orchestration & scheduling','rpa-orchestration-scheduling','Centrally deploy, schedule, queue and monitor automation execution.',1 UNION ALL
 SELECT 'rpa-governance-intelligence','Process / workflow automation','rpa-process-workflow','Coordinate multi-step business workflows beyond individual UI tasks.',0 UNION ALL
 SELECT 'rpa-governance-intelligence','AI / document automation','rpa-ai-document','Use AI, OCR or document understanding in automated processes.',0 UNION ALL
 SELECT 'rpa-governance-intelligence','Governance, roles & audit','rpa-governance-audit','Apply enterprise access, governance, versioning and audit controls.',1 UNION ALL
 SELECT 'rpa-governance-intelligence','Human-in-the-loop','rpa-human-in-loop','Pause or route automation for human review, approval or exception handling.',0
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SAP','sap','https://www.sap.com/','Enterprise application and technology software vendor.','active'),
('Ardoq','ardoq','https://www.ardoq.com/','Enterprise architecture platform vendor.','active'),
('Bizzdesign','bizzdesign','https://bizzdesign.com/','Enterprise architecture and transformation platform vendor.','active'),
('Orbus Software','orbus-software','https://www.orbussoftware.com/','Enterprise architecture and transformation platform vendor.','active'),
('MuleSoft','mulesoft','https://www.mulesoft.com/','Integration and API management platform vendor.','active'),
('Boomi','boomi','https://boomi.com/','Enterprise integration, automation and API management platform vendor.','active'),
('Workato','workato','https://www.workato.com/','Enterprise automation, integration and API platform vendor.','active'),
('SnapLogic','snaplogic','https://www.snaplogic.com/','Enterprise integration and API management platform vendor.','active'),
('UiPath','uipath','https://www.uipath.com/','Enterprise automation and RPA platform vendor.','active'),
('Automation Anywhere','automation-anywhere','https://www.automationanywhere.com/','Enterprise intelligent automation and RPA vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, cloud and automation platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat81_products;
CREATE TEMPORARY TABLE cat81_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat81_products VALUES
('sap','enterprise-architecture-apm','SAP LeanIX','sap-leanix','Enterprise architecture and application portfolio management platform for application inventory, capability mapping, dependencies, lifecycle, rationalization and transformation planning.','https://www.leanix.net/en/products/application-portfolio-management'),
('ardoq','enterprise-architecture-apm','Ardoq','ardoq','AI-enabled enterprise architecture platform for mapping applications, processes, capabilities and dependencies with application portfolio management, rationalization and roadmapping.','https://www.ardoq.com/platform-overview'),
('bizzdesign','enterprise-architecture-apm','Bizzdesign Horizzon','bizzdesign-horizzon','Enterprise architecture platform for modeling business, application, data and technology landscapes with portfolio assessment, target-state design and transformation governance.','https://bizzdesign.com/transformation-suite'),
('orbus-software','enterprise-architecture-apm','OrbusInfinity','orbusinfinity','Enterprise architecture and application portfolio management platform for governed application catalogs, capability mapping, dependency modeling, lifecycle management and rationalization.','https://www.orbussoftware.com/solutions/use-case/application-portfolio-management'),
('mulesoft','integration-api-management','MuleSoft Anypoint Platform','mulesoft-anypoint-platform','Enterprise integration and API management platform for connecting applications and data, building integrations, exposing APIs and applying API lifecycle controls.','https://www.mulesoft.com/platform/anypoint-platform'),
('boomi','integration-api-management','Boomi Enterprise Platform','boomi-enterprise-platform','Enterprise integration and automation platform for application/data integration, workflow orchestration, API management, governance and hybrid runtime operations.','https://boomi.com/platform/'),
('workato','integration-api-management','Workato','workato','Enterprise integration and automation platform for application workflows, recipes, API publishing, gateway controls, governance and monitoring.','https://www.workato.com/'),
('snaplogic','integration-api-management','SnapLogic','snaplogic','Enterprise integration platform for application and data integration, pipeline orchestration, transformation, API management and governance.','https://www.snaplogic.com/'),
('uipath','rpa-intelligent-automation','UiPath Platform','uipath-platform','Enterprise automation platform combining RPA, attended and unattended robots, orchestration, governance and AI-assisted automation.','https://www.uipath.com/platform/agentic-automation/rpa'),
('automation-anywhere','rpa-intelligent-automation','Automation Anywhere','automation-anywhere','Enterprise automation platform for attended and unattended RPA, centrally managed bot execution and intelligent process automation.','https://www.automationanywhere.com/products/agentic-process-automation-system'),
('microsoft','rpa-intelligent-automation','Microsoft Power Automate','microsoft-power-automate','Low-code workflow and robotic process automation platform for cloud flows, desktop automation, attended and unattended execution.','https://www.microsoft.com/en-us/power-platform/products/power-automate');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat81_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'sap-leanix' product_slug,'https://www.leanix.net/en/products/application-portfolio-management' url,'SAP LeanIX Application Portfolio Management' title,'SAP LeanIX' publisher UNION ALL
 SELECT 'sap-leanix','https://help.sap.com/docs/leanix/ea/erp-transformation-explore','SAP LeanIX Enterprise Architecture Overview','SAP' UNION ALL
 SELECT 'ardoq','https://www.ardoq.com/platform-overview','Ardoq Platform Overview','Ardoq' UNION ALL
 SELECT 'ardoq','https://www.ardoq.com/solutions/application-portfolio-management','Ardoq Application Portfolio Management','Ardoq' UNION ALL
 SELECT 'bizzdesign-horizzon','https://bizzdesign.com/enterprise-architecture-management-eam-software','Bizzdesign Enterprise Architecture Management','Bizzdesign' UNION ALL
 SELECT 'bizzdesign-horizzon','https://bizzdesign.com/application-portfolio-management-apm-software','Bizzdesign Application Portfolio Management','Bizzdesign' UNION ALL
 SELECT 'orbusinfinity','https://www.orbussoftware.com/solutions/use-case/application-architecture','OrbusInfinity Application Architecture','Orbus Software' UNION ALL
 SELECT 'orbusinfinity','https://www.orbussoftware.com/solutions/use-case/application-portfolio-management','OrbusInfinity Application Portfolio Management','Orbus Software' UNION ALL
 SELECT 'mulesoft-anypoint-platform','https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-platform-api/','Anypoint API Platform API','MuleSoft' UNION ALL
 SELECT 'mulesoft-anypoint-platform','https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/pages/Overview/','Anypoint API Manager Overview','MuleSoft' UNION ALL
 SELECT 'boomi-enterprise-platform','https://boomi.com/platform/','Boomi Enterprise Platform','Boomi' UNION ALL
 SELECT 'boomi-enterprise-platform','https://developer.boomi.com/docs/APIs/PlatformAPI/Platform_APIs_Overview','Boomi Enterprise Platform APIs','Boomi' UNION ALL
 SELECT 'workato','https://docs.workato.com/en/features/api-management','Workato API Platform Features','Workato' UNION ALL
 SELECT 'workato','https://docs.workato.com/workato-api','Workato Developer API','Workato' UNION ALL
 SELECT 'snaplogic','https://docs.snaplogic.com/introduction/integration-get-started.html','SnapLogic Integration Getting Started','SnapLogic' UNION ALL
 SELECT 'snaplogic','https://www.snaplogic.com/products/api-management-development','SnapLogic API Management','SnapLogic' UNION ALL
 SELECT 'uipath-platform','https://www.uipath.com/platform/agentic-automation/rpa','UiPath Enterprise RPA','UiPath' UNION ALL
 SELECT 'uipath-platform','https://docs.uipath.com/overview/other/latest/overview/attended-vs-unattended-automation','UiPath Attended vs Unattended Automation','UiPath' UNION ALL
 SELECT 'automation-anywhere','https://www.automationanywhere.com/products/agentic-process-automation-system','Automation Anywhere Agentic Process Automation System','Automation Anywhere' UNION ALL
 SELECT 'automation-anywhere','https://docs.automationanywhere.com/r/cloud-install/cloud-on-prem-install/cloud-prerequisites-control-room/attend-automation-overview','Automation 360 Attended and Unattended Automation','Automation Anywhere' UNION ALL
 SELECT 'microsoft-power-automate','https://learn.microsoft.com/en-us/power-automate/desktop-flows/introduction','Power Automate Desktop Flows','Microsoft' UNION ALL
 SELECT 'microsoft-power-automate','https://learn.microsoft.com/en-us/power-automate/desktop-flows/hosted-rpa-faq','Power Automate Hosted RPA','Microsoft'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat81_facts;
CREATE TEMPORARY TABLE cat81_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat81_facts VALUES
-- SAP LeanIX
('sap-leanix','ea-application-inventory','supported',0.99,'Application Portfolio Management provides a continuously maintained application landscape and inventory.','https://www.leanix.net/en/products/application-portfolio-management'),
('sap-leanix','ea-business-capability-mapping','supported',0.99,'SAP LeanIX maps applications to business capabilities and business context.','https://help.sap.com/docs/leanix/ea/erp-transformation-explore'),
('sap-leanix','ea-dependency-modeling','supported',0.98,'SAP documents application and underlying dependency mapping.','https://help.sap.com/docs/leanix/ea/erp-transformation-explore'),
('sap-leanix','ea-application-lifecycle','supported',0.98,'The platform documents portfolio lifecycle and technical-obsolescence management.','https://help.sap.com/docs/leanix/ea/erp-transformation-explore'),
('sap-leanix','ea-portfolio-rationalization','supported',0.99,'Application portfolio optimization and IT investment rationalization are explicit use cases.','https://www.leanix.net/en/products/application-portfolio-management'),
('sap-leanix','ea-risk-cost-assessment','supported',0.95,'LeanIX documents cost-saving, technical debt and risk-oriented portfolio decisions.','https://help.sap.com/docs/leanix/ea/erp-transformation-explore'),

-- Ardoq
('ardoq','ea-application-inventory','supported',0.99,'Ardoq maintains a connected central repository of applications, processes, capabilities and people.','https://www.ardoq.com/platform-overview'),
('ardoq','ea-business-capability-mapping','supported',0.99,'Applications and resources can be linked to business capabilities.','https://www.ardoq.com/platform-overview'),
('ardoq','ea-dependency-modeling','supported',0.99,'Ardoq explicitly maps dependencies across applications, teams and processes.','https://www.ardoq.com/'),
('ardoq','ea-roadmaps-target-state','supported',0.95,'Ardoq documents strategic planning and actionable roadmaps.','https://www.ardoq.com/solutions/application-portfolio-management'),
('ardoq','ea-application-lifecycle','supported',0.98,'Application lifecycle management is an explicit Ardoq APM guide/use case.','https://www.ardoq.com/solutions/application-portfolio-management'),
('ardoq','ea-portfolio-rationalization','supported',0.99,'Application rationalization and retirement/investment decisions are explicitly supported.','https://www.ardoq.com/solutions/application-portfolio-management'),
('ardoq','ea-risk-cost-assessment','supported',0.98,'Ardoq documents application costs, optimization and business-risk analysis.','https://www.ardoq.com/solutions/application-portfolio-management'),

-- Bizzdesign Horizzon
('bizzdesign-horizzon','ea-application-inventory','supported',0.95,'Bizzdesign APM documents centralized application inventory and portfolio visibility.','https://bizzdesign.com/application-portfolio-management-apm-software'),
('bizzdesign-horizzon','ea-business-capability-mapping','supported',0.99,'Bizzdesign explicitly maps applications to business capabilities and strategy.','https://bizzdesign.com/application-portfolio-management-apm-software'),
('bizzdesign-horizzon','ea-dependency-modeling','supported',0.98,'Enterprise Architecture Management connects strategy, capabilities, applications, data and technology.','https://bizzdesign.com/enterprise-architecture-management-eam-software'),
('bizzdesign-horizzon','ea-roadmaps-target-state','supported',0.98,'Future-state architecture design is an explicit Bizzdesign EAM use case.','https://bizzdesign.com/enterprise-architecture-management-eam-software'),
('bizzdesign-horizzon','ea-portfolio-rationalization','supported',0.99,'Application rationalization is a documented Bizzdesign APM capability.','https://bizzdesign.com/application-portfolio-management-apm-software'),
('bizzdesign-horizzon','ea-risk-cost-assessment','supported',0.99,'Business fit, technical health, cost, value and risk are documented portfolio assessment dimensions.','https://bizzdesign.com/application-portfolio-management-apm-software'),
('bizzdesign-horizzon','ea-collaboration-governance','supported',0.95,'Bizzdesign documents enterprise-wide alignment and shared decision-making.','https://bizzdesign.com/enterprise-architecture-management-eam-software'),

-- OrbusInfinity
('orbusinfinity','ea-application-inventory','supported',0.99,'OrbusInfinity provides a governed application catalog and authoritative application baseline.','https://www.orbussoftware.com/solutions/use-case/application-architecture'),
('orbusinfinity','ea-business-capability-mapping','supported',0.99,'Applications can be mapped to business capabilities.','https://www.orbussoftware.com/solutions/use-case/application-architecture'),
('orbusinfinity','ea-dependency-modeling','supported',0.99,'The platform models integration and dependency relationships.','https://www.orbussoftware.com/solutions/use-case/application-architecture'),
('orbusinfinity','ea-roadmaps-target-state','supported',0.95,'OrbusInfinity supports modeling rationalization and migration options before decisions.','https://www.orbussoftware.com/solutions/use-case/application-portfolio-management'),
('orbusinfinity','ea-application-lifecycle','supported',0.99,'Lifecycle status and end-of-life tracking are explicit APM capabilities.','https://www.orbussoftware.com/solutions/use-case/application-portfolio-management'),
('orbusinfinity','ea-portfolio-rationalization','supported',0.99,'Portfolio rationalization and investment/divestment decisions are documented.','https://www.orbussoftware.com/solutions/use-case/application-portfolio-management'),
('orbusinfinity','ea-risk-cost-assessment','supported',0.98,'Portfolio health, risk and investment data are explicit APM capabilities.','https://www.orbussoftware.com/solutions/use-case/application-portfolio-management'),

-- MuleSoft Anypoint Platform
('mulesoft-anypoint-platform','api-design-publish','supported',0.95,'Anypoint API Platform and API Manager support registering, exposing and managing API instances.','https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/pages/Overview/'),
('mulesoft-anypoint-platform','api-gateway-security','supported',0.95,'API Manager exposes proxy, application registration, access and SLA controls.','https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-platform-api/'),
('mulesoft-anypoint-platform','api-lifecycle-governance','supported',0.92,'The API management surface includes versioned APIs, environments, applications and management controls.','https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/api-manager-api/minor/1.0/pages/Overview/'),

-- Boomi Enterprise Platform
('boomi-enterprise-platform','integration-connectors','supported',0.99,'Boomi documents application connectivity and more than 1,000 enterprise application connections.','https://boomi.com/platform/'),
('boomi-enterprise-platform','integration-workflow-orchestration','supported',0.99,'Integration, automation, event streams and data orchestration are explicit platform capabilities.','https://boomi.com/platform/'),
('boomi-enterprise-platform','integration-data-transformation','supported',0.99,'Boomi documents data transformation and orchestration capabilities.','https://boomi.com/platform/'),
('boomi-enterprise-platform','api-design-publish','supported',0.98,'API Management and API products are explicit Boomi platform capabilities.','https://boomi.com/platform/'),
('boomi-enterprise-platform','api-gateway-security','supported',0.98,'Boomi documents API Security as part of its API Management portfolio.','https://boomi.com/platform/'),
('boomi-enterprise-platform','api-lifecycle-governance','supported',0.98,'API Governance spans quality from design through retirement.','https://boomi.com/platform/'),
('boomi-enterprise-platform','api-monitoring-analytics','supported',0.92,'Platform APIs and runtime execution records support programmatic monitoring; exact analytics depth varies by service.','https://developer.boomi.com/docs/APIs/PlatformAPI/Platform_APIs_Overview'),

-- Workato
('workato','integration-workflow-orchestration','supported',0.99,'Workato recipes orchestrate multi-system workflows and automation.','https://docs.workato.com/en/api-mgmt/api-endpoints'),
('workato','api-design-publish','supported',0.99,'Workato API Platform supports recipe-based endpoints, proxies and API collections.','https://docs.workato.com/en/features/api-management'),
('workato','api-gateway-security','supported',0.99,'API Platform provides gateway, access profiles, security and quota controls.','https://docs.workato.com/en/features/api-management'),
('workato','api-lifecycle-governance','supported',0.98,'Recipe lifecycle management supports release between development, test and production.','https://docs.workato.com/en/features/api-management'),
('workato','api-monitoring-analytics','supported',0.99,'Workato documents API dashboards and request monitoring.','https://docs.workato.com/en/features/api-management'),

-- SnapLogic
('snaplogic','integration-connectors','supported',0.99,'Snap Packs connect pipelines to enterprise applications, data and services.','https://docs.snaplogic.com/introduction/integration-get-started.html'),
('snaplogic','integration-workflow-orchestration','supported',0.99,'SnapLogic pipelines define integration orchestration logic.','https://docs.snaplogic.com/introduction/integration-get-started.html'),
('snaplogic','integration-data-transformation','supported',0.99,'Pipelines provide ingestion, transformation and synchronization.','https://docs.snaplogic.com/introduction/integration-get-started.html'),
('snaplogic','api-design-publish','supported',0.99,'SnapLogic APIM supports designing, implementing and managing APIs and exposing pipelines as APIs.','https://www.snaplogic.com/products/api-management-development'),
('snaplogic','api-gateway-security','supported',0.98,'SnapLogic documents API security policies and governance across the API lifecycle.','https://www.snaplogic.com/products/api-management-development'),
('snaplogic','api-lifecycle-governance','supported',0.98,'APIM 3.0 supports governed services and policies for internal and external consumption.','https://www.snaplogic.com/products/api-management-development'),
('snaplogic','api-monitoring-analytics','supported',0.95,'SnapLogic documents low-code API monitoring and dynamic dashboards.','https://www.snaplogic.com/resources/data-sheets/snaplogic-api-management'),

-- UiPath
('uipath-platform','rpa-desktop-web-automation','supported',0.99,'UiPath provides UI automation across modern, legacy and virtualized applications.','https://www.uipath.com/platform/agentic-automation/rpa'),
('uipath-platform','rpa-attended','supported',0.99,'UiPath explicitly supports attended automations under human supervision.','https://docs.uipath.com/overview/other/latest/overview/attended-vs-unattended-automation'),
('uipath-platform','rpa-unattended','supported',0.99,'UiPath explicitly supports unattended automations without human supervision.','https://docs.uipath.com/overview/other/latest/overview/attended-vs-unattended-automation'),
('uipath-platform','rpa-orchestration-scheduling','supported',0.98,'UiPath documents central management, audit trails and enterprise-scale execution controls.','https://www.uipath.com/platform/agentic-automation/rpa'),
('uipath-platform','rpa-governance-audit','supported',0.99,'Role-based access, approvals, audit trails and version control are documented.','https://www.uipath.com/platform/agentic-automation/rpa'),
('uipath-platform','rpa-human-in-loop','supported',0.95,'UiPath documents human-in-the-loop steps for exceptions and judgment-oriented automation.','https://www.uipath.com/platform/agentic-automation/rpa'),

-- Automation Anywhere
('automation-anywhere','rpa-desktop-web-automation','supported',0.95,'Automation Anywhere positions its platform for enterprise process automation across user and back-office tasks.','https://www.automationanywhere.com/products/agentic-process-automation-system'),
('automation-anywhere','rpa-attended','supported',0.99,'Automation 360 explicitly supports attended automation.','https://docs.automationanywhere.com/r/cloud-install/cloud-on-prem-install/cloud-prerequisites-control-room/attend-automation-overview'),
('automation-anywhere','rpa-unattended','supported',0.99,'Automation 360 explicitly supports unattended automation.','https://docs.automationanywhere.com/r/cloud-install/cloud-on-prem-install/cloud-prerequisites-control-room/attend-automation-overview'),
('automation-anywhere','rpa-orchestration-scheduling','supported',0.98,'Unattended automations are scheduled or triggered from Control Room with queue management.','https://docs.automationanywhere.com/r/cloud-install/cloud-on-prem-install/cloud-prerequisites-control-room/attend-automation-overview'),
('automation-anywhere','rpa-human-in-loop','supported',0.95,'Attended automation supports user input, review, approvals and exception handling.','https://docs.automationanywhere.com/r/cloud-install/cloud-on-prem-install/cloud-prerequisites-control-room/attend-automation-overview'),

-- Microsoft Power Automate
('microsoft-power-automate','rpa-desktop-web-automation','supported',0.99,'Desktop flows automate desktop, web and legacy applications with recorded or configured actions.','https://learn.microsoft.com/en-us/power-automate/desktop-flows/introduction'),
('microsoft-power-automate','rpa-attended','supported',0.95,'Power Automate desktop flows support user-run desktop automation; licensing determines available execution modes.','https://learn.microsoft.com/en-us/power-automate/desktop-flows/introduction'),
('microsoft-power-automate','rpa-unattended','supported',0.98,'Hosted RPA provides scalable unattended automation through hosted machine groups.','https://learn.microsoft.com/en-us/power-automate/desktop-flows/hosted-rpa-faq'),
('microsoft-power-automate','rpa-orchestration-scheduling','supported',0.95,'Hosted machines and cloud-triggered desktop flows provide centrally managed execution and scaling.','https://learn.microsoft.com/en-us/power-automate/desktop-flows/hosted-rpa-faq'),
('microsoft-power-automate','rpa-process-workflow','supported',0.95,'Power Automate connects desktop flows with cloud flows for multi-system business-process automation.','https://learn.microsoft.com/en-us/power-automate/desktop-flows/introduction');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat81_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Explicit unknowns for every unreviewed capability in the new product's own category.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat81_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat81_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Product-specific third-party integration coverage is intentionally not inferred in this batch.
INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('sap-leanix','ardoq','bizzdesign-horizzon','orbusinfinity','mulesoft-anypoint-platform','boomi-enterprise-platform','workato','snaplogic','uipath-platform','automation-anywhere','microsoft-power-automate')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat81_facts;
DROP TEMPORARY TABLE IF EXISTS cat81_products;
COMMIT;