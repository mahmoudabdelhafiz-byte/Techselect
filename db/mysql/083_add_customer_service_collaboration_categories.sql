-- TechSelectAI strategic category expansion batch 2
-- Adds Customer Service & Contact Center and Collaboration & Communication.
-- Seeds major products using official first-party evidence reviewed in Sep 2026.
-- Preserves Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Customer Service & Contact Center','customer-service-contact-center','Customer service and contact-center platforms for case management, omnichannel engagement, routing, knowledge, agent operations, workforce optimization and service analytics.',1),
('Collaboration & Communication','collaboration-communication','Enterprise collaboration and communication platforms for messaging, channels, meetings, calling, file/content collaboration, search and extensibility.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active)
SELECT c.id,x.name,x.slug,x.description,1 FROM categories c JOIN (
 SELECT 'customer-service-contact-center' cat,'Customer Service Operations' name,'customer-service-operations' slug,'Case/ticket management, omnichannel routing, knowledge and self-service.' description UNION ALL
 SELECT 'customer-service-contact-center','Contact Center Intelligence & Workforce','contact-center-intelligence','Voice/contact-center operations, workforce optimization, analytics and AI-assisted service.' UNION ALL
 SELECT 'collaboration-communication','Messaging & Team Collaboration','collaboration-messaging' ,'Team messaging, channels/spaces, content sharing, external collaboration and enterprise search.' UNION ALL
 SELECT 'collaboration-communication','Meetings, Calling & Extensibility','collaboration-meetings-calling','Video meetings, enterprise calling, events and application integrations.'
) x ON x.cat=c.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1 FROM modules m JOIN (
 SELECT 'customer-service-operations' ms,'Case / ticket management' name,'cs-case-ticket-management' slug,'Track, prioritize and resolve customer service cases or tickets.' description,0 sec UNION ALL
 SELECT 'customer-service-operations','Omnichannel engagement & routing','cs-omnichannel-routing','Handle and route work across digital and voice channels.',0 UNION ALL
 SELECT 'customer-service-operations','Knowledge management','cs-knowledge-management','Create and use knowledge articles for agents and customers.',0 UNION ALL
 SELECT 'customer-service-operations','Customer self-service','cs-self-service','Provide portals, bots or other self-service experiences.',0 UNION ALL
 SELECT 'contact-center-intelligence','Voice / contact-center operations','cs-voice-contact-center','Support voice interactions and contact-center agent operations.',0 UNION ALL
 SELECT 'contact-center-intelligence','Workforce engagement / optimization','cs-workforce-optimization','Forecast, schedule, evaluate or optimize contact-center workforce performance.',0 UNION ALL
 SELECT 'contact-center-intelligence','Service analytics & dashboards','cs-service-analytics','Provide operational service/contact-center dashboards, KPIs and analytics.',0 UNION ALL
 SELECT 'contact-center-intelligence','AI-assisted service & automation','cs-ai-service-automation','Use AI or automation to assist agents, route work or resolve customer requests.',0 UNION ALL
 SELECT 'collaboration-messaging','Team chat / messaging','collab-team-messaging','Provide persistent direct and group messaging.',0 UNION ALL
 SELECT 'collaboration-messaging','Channels / team spaces','collab-channels-spaces','Organize work into persistent channels, spaces or team work areas.',0 UNION ALL
 SELECT 'collaboration-messaging','File & content collaboration','collab-file-content','Share, co-edit or collaborate on files and business content.',0 UNION ALL
 SELECT 'collaboration-messaging','Enterprise search','collab-enterprise-search','Search conversations, content or connected applications.',0 UNION ALL
 SELECT 'collaboration-meetings-calling','Video meetings & screen sharing','collab-video-meetings','Host video/audio meetings with screen or content sharing.',0 UNION ALL
 SELECT 'collaboration-meetings-calling','Enterprise calling / telephony','collab-enterprise-calling','Provide business calling, telephony or PSTN connectivity.',0 UNION ALL
 SELECT 'collaboration-meetings-calling','Webinars / events','collab-webinars-events','Run webinars, town halls or larger virtual events.',0 UNION ALL
 SELECT 'collaboration-meetings-calling','Apps, connectors & integrations','collab-app-integrations','Extend collaboration through first- or third-party apps and integrations.',0
) x ON x.ms=m.slug
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Salesforce','salesforce','https://www.salesforce.com/','CRM, customer service and enterprise application software vendor.','active'),
('Freshworks','freshworks','https://www.freshworks.com/','Customer service, IT service and CRM software vendor.','active'),
('Genesys','genesys','https://www.genesys.com/','Cloud contact-center and customer-experience platform vendor.','active'),
('NiCE','nice','https://www.nice.com/','Customer-experience and contact-center software vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise software, productivity, collaboration and cloud vendor.','active'),
('Slack','slack','https://slack.com/','Enterprise team messaging and collaboration software vendor.','active'),
('Zoom','zoom','https://www.zoom.com/','Video communications, collaboration and productivity software vendor.','active'),
('Google','google','https://www.google.com/','Cloud productivity, collaboration and communications software vendor.','active'),
('Cisco','cisco','https://www.cisco.com/','Networking, security and collaboration technology vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat83_products;
CREATE TEMPORARY TABLE cat83_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat83_products VALUES
('salesforce','customer-service-contact-center','Salesforce Service Cloud','salesforce-service-cloud','Customer service platform for case management, omnichannel engagement, knowledge, automation and service analytics.','https://www.salesforce.com/service/cloud/'),
('freshworks','customer-service-contact-center','Freshdesk','freshdesk','Customer support platform for ticketing, omnichannel service, knowledge, automation and support analytics.','https://www.freshworks.com/freshdesk/'),
('genesys','customer-service-contact-center','Genesys Cloud CX','genesys-cloud-cx','Cloud contact-center platform for omnichannel engagement, routing, workforce engagement, analytics and AI-powered experience orchestration.','https://www.genesys.com/cloud-services/genesys-cloud-cx'),
('nice','customer-service-contact-center','NiCE CXone Mpower','nice-cxone-mpower','Enterprise cloud contact-center platform unifying omnichannel routing, workforce optimization, analytics, automation and AI.','https://www.nice.com/products/cxone'),
('microsoft','customer-service-contact-center','Dynamics 365 Customer Service','dynamics-365-customer-service','Cloud customer-service platform for cases, knowledge, omnichannel engagement, unified routing, analytics and AI-assisted service.','https://www.microsoft.com/en-us/dynamics-365/products/customer-service'),
('microsoft','collaboration-communication','Microsoft Teams','microsoft-teams','Enterprise collaboration platform for chat, channels, meetings, calling, file sharing, apps and events.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('slack','collaboration-communication','Slack','slack','Enterprise messaging and collaboration platform for channels, direct messaging, huddles, search, workflow and connected applications.','https://slack.com/'),
('zoom','collaboration-communication','Zoom Workplace','zoom-workplace','Collaboration suite combining meetings, team chat, phone, whiteboard, docs and AI-assisted productivity.','https://www.zoom.com/en/products/collaboration-tools/'),
('google','collaboration-communication','Google Workspace','google-workspace','Cloud productivity and collaboration suite with Gmail, Drive, Meet, Chat, Calendar, Docs and related business tools.','https://workspace.google.com/'),
('cisco','collaboration-communication','Webex Suite','webex-suite','Enterprise collaboration suite for meetings, messaging, calling, whiteboarding, events and integrations.','https://www.webex.com/suite.html');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat83_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'salesforce-service-cloud' product_slug,'https://www.salesforce.com/service/cloud/' url,'Salesforce Service Cloud' title,'Salesforce' publisher UNION ALL
 SELECT 'salesforce-service-cloud','https://help.salesforce.com/s/articleView?id=service_cloud.htm&language=en_US&type=0','Agentforce Service Documentation','Salesforce' UNION ALL
 SELECT 'freshdesk','https://www.freshworks.com/freshdesk/new-features/','Freshdesk Product Updates and Omnichannel Features','Freshworks' UNION ALL
 SELECT 'genesys-cloud-cx','https://www.genesys.com/capabilities/genesys-cloud-associate','Genesys Cloud Associate Capabilities','Genesys' UNION ALL
 SELECT 'genesys-cloud-cx','https://www.genesys.com/capabilities/wem-workforce-engagement-management','Genesys Workforce Engagement Management','Genesys' UNION ALL
 SELECT 'nice-cxone-mpower','https://www.nice.com/solutions/enterprise','NiCE CXone Enterprise Contact Center','NiCE' UNION ALL
 SELECT 'dynamics-365-customer-service','https://learn.microsoft.com/en-us/dynamics365/customer-service/implement/overview','Dynamics 365 Customer Service Overview','Microsoft' UNION ALL
 SELECT 'dynamics-365-customer-service','https://learn.microsoft.com/en-us/dynamics365/customer-service/administer/overview-unified-routing','Dynamics 365 Unified Routing','Microsoft' UNION ALL
 SELECT 'dynamics-365-customer-service','https://learn.microsoft.com/en-us/dynamics365/customer-service/administer/analytics_overview','Dynamics 365 Customer Service Analytics','Microsoft' UNION ALL
 SELECT 'microsoft-teams','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software','Microsoft Teams','Microsoft' UNION ALL
 SELECT 'microsoft-teams','https://learn.microsoft.com/en-us/office365/servicedescriptions/teams-service-description','Microsoft Teams Service Description','Microsoft' UNION ALL
 SELECT 'slack','https://slack.com/features/enterprise-search','Slack Enterprise Search','Slack' UNION ALL
 SELECT 'slack','https://slack.com/help/articles/39044407124755-Set-up-and-manage-Slack-enterprise-search','Slack Enterprise Search Administration','Slack' UNION ALL
 SELECT 'zoom-workplace','https://news.zoom.com/zoom-workplace-simplicity-ui-updates/','Zoom Workplace Collaboration Experience','Zoom' UNION ALL
 SELECT 'google-workspace','https://workspace.google.com/','Google Workspace','Google' UNION ALL
 SELECT 'google-workspace','https://workspace.google.com/resources/what-is-workspace/','What is Google Workspace','Google' UNION ALL
 SELECT 'webex-suite','https://www.webex.com/suite/messaging.html','Webex Messaging','Cisco Webex'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

DROP TEMPORARY TABLE IF EXISTS cat83_facts;
CREATE TEMPORARY TABLE cat83_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat83_facts VALUES
('salesforce-service-cloud','cs-case-ticket-management','supported',0.99,'Service Cloud explicitly provides case management.','https://www.salesforce.com/service/cloud/'),
('salesforce-service-cloud','cs-omnichannel-routing','supported',0.99,'Omni-Channel routes service work across channels.','https://help.salesforce.com/s/articleView?id=service_cloud.htm&language=en_US&type=0'),
('salesforce-service-cloud','cs-knowledge-management','supported',0.99,'Knowledge base capabilities are part of the service platform.','https://help.salesforce.com/s/articleView?id=service_cloud.htm&language=en_US&type=0'),
('salesforce-service-cloud','cs-ai-service-automation','supported',0.98,'Agentforce and service automation provide AI-assisted workflows.','https://www.salesforce.com/service/cloud/'),
('salesforce-service-cloud','cs-service-analytics','supported',0.98,'Service metrics, reporting and visualizations are documented.','https://help.salesforce.com/s/articleView?id=service_cloud.htm&language=en_US&type=0'),
('freshdesk','cs-case-ticket-management','supported',0.99,'Freshdesk is built around customer support ticket management.','https://www.freshworks.com/freshdesk/new-features/'),
('freshdesk','cs-omnichannel-routing','supported',0.97,'Freshdesk Omnichannel combines ticket, chat and phone service operations.','https://www.freshworks.com/freshdesk/new-features/'),
('freshdesk','cs-knowledge-management','supported',0.98,'Knowledge base and knowledge analytics are documented Freshdesk capabilities.','https://www.freshworks.com/freshdesk/new-features/'),
('freshdesk','cs-service-analytics','supported',0.98,'Omnichannel dashboards and knowledge analytics are documented.','https://www.freshworks.com/freshdesk/new-features/'),
('genesys-cloud-cx','cs-omnichannel-routing','supported',0.99,'Genesys documents omnichannel engagement and orchestration.','https://www.genesys.com/capabilities/genesys-cloud-associate'),
('genesys-cloud-cx','cs-voice-contact-center','supported',0.99,'Genesys Cloud is an enterprise contact-center platform spanning customer interaction channels.','https://www.genesys.com/capabilities/genesys-cloud-associate'),
('genesys-cloud-cx','cs-workforce-optimization','supported',0.99,'Workforce engagement management includes performance, quality and workforce capabilities.','https://www.genesys.com/capabilities/wem-workforce-engagement-management'),
('genesys-cloud-cx','cs-service-analytics','supported',0.99,'Genesys documents analytics workspaces and real-time contact-center metrics.','https://www.genesys.com/capabilities/wem-workforce-engagement-management'),
('genesys-cloud-cx','cs-ai-service-automation','supported',0.98,'AI-powered experience orchestration and automation are explicit platform capabilities.','https://www.genesys.com/capabilities/genesys-cloud-associate'),
('nice-cxone-mpower','cs-omnichannel-routing','supported',0.99,'CXone unifies omnichannel routing on one cloud platform.','https://www.nice.com/solutions/enterprise'),
('nice-cxone-mpower','cs-workforce-optimization','supported',0.99,'Workforce optimization is an explicit CXone capability.','https://www.nice.com/solutions/enterprise'),
('nice-cxone-mpower','cs-service-analytics','supported',0.99,'CXone includes analytics for enterprise contact-center operations.','https://www.nice.com/solutions/enterprise'),
('nice-cxone-mpower','cs-ai-service-automation','supported',0.99,'CXone includes integrated AI and automation.','https://www.nice.com/solutions/enterprise'),
('dynamics-365-customer-service','cs-case-ticket-management','supported',0.99,'Dynamics 365 Customer Service tracks customer issues through cases.','https://learn.microsoft.com/en-us/dynamics365/customer-service/implement/overview'),
('dynamics-365-customer-service','cs-knowledge-management','supported',0.99,'Knowledge-base sharing is a documented core capability.','https://learn.microsoft.com/en-us/dynamics365/customer-service/implement/overview'),
('dynamics-365-customer-service','cs-omnichannel-routing','supported',0.99,'Unified routing directs work across customer-service channels.','https://learn.microsoft.com/en-us/dynamics365/customer-service/administer/overview-unified-routing'),
('dynamics-365-customer-service','cs-service-analytics','supported',0.99,'Historical and real-time service analytics dashboards are documented.','https://learn.microsoft.com/en-us/dynamics365/customer-service/administer/analytics_overview'),
('dynamics-365-customer-service','cs-ai-service-automation','supported',0.97,'AI-driven embedded insights and service assistance are documented.','https://learn.microsoft.com/en-us/dynamics365/customer-service/implement/overview'),
('microsoft-teams','collab-team-messaging','supported',0.99,'Teams provides persistent chat and group messaging.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('microsoft-teams','collab-channels-spaces','supported',0.99,'Standard, private and shared channels are documented.','https://learn.microsoft.com/en-us/office365/servicedescriptions/teams-service-description'),
('microsoft-teams','collab-file-content','supported',0.99,'Teams brings conversations and shared content into the same workspace.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('microsoft-teams','collab-video-meetings','supported',0.99,'Meetings with audio, video and screen sharing are core Teams capabilities.','https://learn.microsoft.com/en-us/office365/servicedescriptions/teams-service-description'),
('microsoft-teams','collab-enterprise-calling','supported',0.99,'Teams supports enterprise calling and Teams Phone.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('microsoft-teams','collab-webinars-events','supported',0.98,'Teams supports professional events and webinars at scale.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('microsoft-teams','collab-app-integrations','supported',0.99,'Teams supports first- and third-party apps.','https://www.microsoft.com/en-us/microsoft-teams/group-chat-software'),
('slack','collab-team-messaging','supported',0.99,'Slack is built around enterprise team messaging.','https://slack.com/features/enterprise-search'),
('slack','collab-enterprise-search','supported',0.99,'Enterprise Search searches Slack and connected application content.','https://slack.com/features/enterprise-search'),
('slack','collab-app-integrations','supported',0.99,'Slack enterprise search and connected-app functionality document third-party application integration.','https://slack.com/help/articles/39044407124755-Set-up-and-manage-Slack-enterprise-search'),
('zoom-workplace','collab-team-messaging','supported',0.98,'Zoom Workplace includes Zoom Team Chat.','https://news.zoom.com/zoom-workplace-simplicity-ui-updates/'),
('zoom-workplace','collab-video-meetings','supported',0.99,'Zoom Workplace includes Zoom Meetings as a core product.','https://news.zoom.com/zoom-workplace-simplicity-ui-updates/'),
('zoom-workplace','collab-file-content','partially_supported',0.90,'Zoom Workplace includes collaborative products such as Whiteboard and Docs; exact content-management depth varies by component.','https://news.zoom.com/zoom-workplace-simplicity-ui-updates/'),
('google-workspace','collab-team-messaging','supported',0.99,'Google Chat is included in Workspace.','https://workspace.google.com/'),
('google-workspace','collab-file-content','supported',0.99,'Drive plus collaborative Docs, Sheets and related tools are core Workspace capabilities.','https://workspace.google.com/'),
('google-workspace','collab-video-meetings','supported',0.99,'Google Meet is included for video meetings.','https://workspace.google.com/'),
('google-workspace','collab-app-integrations','supported',0.95,'Workspace combines Gmail, Drive, Meet, Chat, Calendar and Docs in an integrated productivity suite.','https://workspace.google.com/resources/what-is-workspace/'),
('webex-suite','collab-team-messaging','supported',0.99,'Webex Messaging provides persistent team messaging and workspaces.','https://www.webex.com/suite/messaging.html'),
('webex-suite','collab-file-content','supported',0.98,'Webex Messaging supports file sharing, document co-editing and meeting artifacts.','https://www.webex.com/suite/messaging.html'),
('webex-suite','collab-video-meetings','supported',0.99,'Webex Suite messaging page links meetings as part of the collaboration portfolio.','https://www.webex.com/suite/messaging.html'),
('webex-suite','collab-enterprise-calling','supported',0.99,'Calling is an explicit part of the Webex collaboration portfolio.','https://www.webex.com/suite/messaging.html'),
('webex-suite','collab-app-integrations','supported',0.99,'Webex documents integrations with more than 100 applications.','https://www.webex.com/suite/messaging.html');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat83_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat83_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,f.limitations
FROM cat83_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT p.id,i.id,'not_yet_verified',0 FROM products p JOIN integrations i
WHERE p.slug IN('salesforce-service-cloud','freshdesk','genesys-cloud-cx','nice-cxone-mpower','dynamics-365-customer-service','microsoft-teams','slack','zoom-workplace','google-workspace','webex-suite')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

DROP TEMPORARY TABLE IF EXISTS cat83_facts;
DROP TEMPORARY TABLE IF EXISTS cat83_products;
COMMIT;
