-- TechSelectAI Enterprise AI Assistants catalog expansion.
-- Adds one canonical enterprise-assistant category and five evidence-backed products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Enterprise AI Assistants','enterprise-ai-assistants','Enterprise AI assistants and agentic work platforms for secure organizational chat, research, content creation, connected-workplace tasks and governed business workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @eai_cat=(SELECT id FROM categories WHERE slug='enterprise-ai-assistants' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@eai_cat,'Assistant & Work Capabilities','eai-assistant-work','Enterprise chat, research, business-data grounding, connectors and agent/workflow capabilities.',1),
(@eai_cat,'Security, Admin & Governance','eai-security-governance','Identity, administration, privacy, retention, audit and usage-governance capabilities for organizational deployment.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'eai-assistant-work' module_slug,'Enterprise AI chat & reasoning' name,'eai-chat-reasoning' slug,'Provide enterprise users with conversational AI for analysis, writing, reasoning and knowledge work.' description,0 sec UNION ALL
 SELECT 'eai-assistant-work','Web research / cited research' name,'eai-web-research','Research current web information and return source-grounded or cited answers/reports.',0 UNION ALL
 SELECT 'eai-assistant-work','Business data connectors / grounding' name,'eai-business-connectors','Connect approved enterprise applications, files or data sources so answers and work can be grounded in organizational context.',1 UNION ALL
 SELECT 'eai-assistant-work','Custom agents / workflows' name,'eai-agents-workflows','Create, configure or run organization-specific agents, automations or multi-step workflows.',0 UNION ALL
 SELECT 'eai-security-governance','SSO / SCIM / enterprise identity controls' name,'eai-enterprise-identity','Support enterprise identity and lifecycle controls such as SSO, SCIM, domain capture or role-based administration.',1 UNION ALL
 SELECT 'eai-security-governance','Business data not used for model training by default' name,'eai-no-training-default','Provide documented default protection against using enterprise customer prompts/content to train provider models.',1 UNION ALL
 SELECT 'eai-security-governance','Retention / audit / usage governance' name,'eai-retention-audit-governance','Provide retention controls, audit logs, usage analytics, reporting or spend/governance controls for administrators.',1
) x ON x.module_slug=m.slug
WHERE m.category_id=@eai_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('OpenAI','openai','https://openai.com/','Enterprise AI assistant, agent, coding and API platform vendor.','active'),
('Anthropic','anthropic','https://www.anthropic.com/','Enterprise AI assistant, coding and AI platform vendor.','active'),
('Google Cloud','google-cloud','https://cloud.google.com/','Cloud, data, AI and enterprise agent platform vendor.','active'),
('Microsoft','microsoft','https://www.microsoft.com/','Enterprise productivity, cloud and AI software vendor.','active'),
('Perplexity','perplexity','https://www.perplexity.ai/','AI research, answer-engine and enterprise work platform vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat111_products;
CREATE TEMPORARY TABLE cat111_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat111_products VALUES
('openai','enterprise-ai-assistants','ChatGPT Enterprise','chatgpt-enterprise','Managed enterprise ChatGPT workspace with advanced AI capabilities, connected workplace tools, agents/workflows and enterprise-grade security, administration and data controls.','https://openai.com/business/pricing/'),
('anthropic','enterprise-ai-assistants','Claude Enterprise','claude-enterprise','Enterprise Claude offering with Chat, Cowork, Claude Code, enterprise connectors and organization-level identity, governance, retention, audit and administration controls.','https://www.anthropic.com/enterprise'),
('google-cloud','enterprise-ai-assistants','Gemini Enterprise','gemini-enterprise','Enterprise AI and agentic work platform with business-data connectors, secure search and answers, no-code and custom agents, centralized governance and enterprise security controls.','https://cloud.google.com/gemini-enterprise'),
('microsoft','enterprise-ai-assistants','Microsoft 365 Copilot','microsoft-365-copilot','Enterprise AI assistant integrated with Microsoft 365 apps and organizational data, with agents, enterprise data protection and centralized administration.','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise'),
('perplexity','enterprise-ai-assistants','Perplexity Enterprise','perplexity-enterprise','Enterprise research and work platform for cited answers, deep research, connected-tool workflows, document/asset creation and organization-level security and administration.','https://www.perplexity.ai/enterprise');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat111_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat111_sources;
CREATE TEMPORARY TABLE cat111_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat111_sources VALUES
('chatgpt-enterprise','https://openai.com/business/pricing/','OpenAI Business and Enterprise Pricing','OpenAI'),
('chatgpt-enterprise','https://openai.com/business-data/','OpenAI Business Data Privacy','OpenAI'),
('chatgpt-enterprise','https://help.openai.com/en/articles/8265053-what-is-chatgpt-enterprise','What is ChatGPT Enterprise?','OpenAI'),
('claude-enterprise','https://www.anthropic.com/enterprise','Claude Enterprise','Anthropic'),
('claude-enterprise','https://www.anthropic.com/webinars/configuring-claude-guidance-for-enterprise-admins','Configuring Claude for Enterprise Admins','Anthropic'),
('gemini-enterprise','https://cloud.google.com/gemini-enterprise','Gemini Enterprise','Google Cloud'),
('gemini-enterprise','https://cloud.google.com/gemini-enterprise/connectors','Gemini Enterprise Connectors','Google Cloud'),
('gemini-enterprise','https://docs.cloud.google.com/gemini/enterprise/docs/agents-overview','Gemini Enterprise Agents Overview','Google Cloud'),
('microsoft-365-copilot','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise','Microsoft 365 Copilot Enterprise Plans','Microsoft'),
('perplexity-enterprise','https://www.perplexity.ai/enterprise','Perplexity Enterprise','Perplexity'),
('perplexity-enterprise','https://www.perplexity.ai/enterprise/pricing','Perplexity Enterprise Pricing','Perplexity');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat111_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat111_facts;
CREATE TEMPORARY TABLE cat111_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat111_facts VALUES
-- ChatGPT Enterprise
('chatgpt-enterprise','eai-chat-reasoning','supported',0.990,'ChatGPT Enterprise provides managed organizational access to advanced ChatGPT capabilities for enterprise knowledge work.','https://help.openai.com/en/articles/8265053-what-is-chatgpt-enterprise'),
('chatgpt-enterprise','eai-web-research','supported',0.980,'OpenAI business plans include advanced research capabilities; exact usage depends on workspace plan, seat type and contracted usage model.','https://openai.com/business/pricing/'),
('chatgpt-enterprise','eai-business-connectors','supported',0.990,'OpenAI documents connections to Google Workspace, Slack, GitHub, Microsoft 365 and additional plugins/connectors for business plans.','https://openai.com/business/pricing/'),
('chatgpt-enterprise','eai-agents-workflows','supported',0.990,'OpenAI documents ChatGPT Work and workspace agents for customized multi-step business workflows.','https://openai.com/business/pricing/'),
('chatgpt-enterprise','eai-enterprise-identity','supported',0.990,'Enterprise includes SAML SSO plus advanced controls such as SCIM, domain verification and role-based access controls.','https://openai.com/business/pricing/'),
('chatgpt-enterprise','eai-no-training-default','supported',0.990,'OpenAI states organization data from ChatGPT Enterprise is not used to train models by default.','https://openai.com/business-data/'),
('chatgpt-enterprise','eai-retention-audit-governance','supported',0.990,'Enterprise includes custom data retention, user analytics, spend controls and administrative governance capabilities.','https://openai.com/business/pricing/'),

-- Claude Enterprise
('claude-enterprise','eai-chat-reasoning','supported',0.990,'Claude Enterprise provides secure employee access to Claude Chat for reasoning, writing, analysis and business work.','https://www.anthropic.com/enterprise'),
('claude-enterprise','eai-business-connectors','supported',0.990,'Anthropic documents enterprise connectors including Gmail, Google Drive, Slack and other workplace systems.','https://www.anthropic.com/enterprise'),
('claude-enterprise','eai-agents-workflows','supported',0.990,'Claude Enterprise includes Cowork, Claude Code, skills/plugins and connected-task workflows across enterprise tools.','https://www.anthropic.com/enterprise'),
('claude-enterprise','eai-enterprise-identity','supported',0.990,'Claude Enterprise supports SSO/SAML, SCIM, roles, permissions and admin-managed connector/plugin controls.','https://www.anthropic.com/enterprise'),
('claude-enterprise','eai-no-training-default','supported',0.990,'Anthropic states enterprise prompts, data and results are not used to train its models by default.','https://www.anthropic.com/enterprise'),
('claude-enterprise','eai-retention-audit-governance','supported',0.990,'Claude Enterprise documents data retention controls, usage analytics, audit logs, OpenTelemetry monitoring and Compliance API access.','https://www.anthropic.com/enterprise'),

-- Gemini Enterprise
('gemini-enterprise','eai-chat-reasoning','supported',0.990,'Gemini Enterprise provides an enterprise chat interface for search, analysis, content creation and business work.','https://cloud.google.com/gemini-enterprise'),
('gemini-enterprise','eai-web-research','supported',0.980,'Gemini Enterprise includes research agents and enterprise search experiences; specific research features can depend on edition and enabled agents.','https://cloud.google.com/gemini-enterprise'),
('gemini-enterprise','eai-business-connectors','supported',0.990,'Google documents connectors for Google Workspace, Microsoft 365, HubSpot, Jira and additional enterprise sources.','https://cloud.google.com/gemini-enterprise/connectors'),
('gemini-enterprise','eai-agents-workflows','supported',0.990,'Gemini Enterprise supports no-code workflow agents plus organization-managed Google, partner and custom agents.','https://docs.cloud.google.com/gemini/enterprise/docs/agents-overview'),
('gemini-enterprise','eai-enterprise-identity','supported',0.980,'Gemini Enterprise provides centralized access controls, IAM roles and admin governance; exact enterprise controls differ by edition.','https://cloud.google.com/gemini-enterprise'),
('gemini-enterprise','eai-retention-audit-governance','partially_supported',0.950,'Gemini Enterprise provides centralized governance and observability; advanced sovereignty, encryption and compliance controls can be edition-dependent.','https://cloud.google.com/gemini-enterprise'),

-- Microsoft 365 Copilot
('microsoft-365-copilot','eai-chat-reasoning','supported',0.990,'Microsoft 365 Copilot provides enterprise AI chat and assistance across Microsoft 365.','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise'),
('microsoft-365-copilot','eai-web-research','supported',0.980,'Microsoft 365 Copilot Chat includes secure web-grounded AI chat; business-data grounding depends on the licensed Copilot plan.','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise'),
('microsoft-365-copilot','eai-business-connectors','supported',0.990,'Microsoft 365 Copilot grounds answers in organizational Microsoft 365 data and connected services through the Microsoft ecosystem.','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise'),
('microsoft-365-copilot','eai-agents-workflows','supported',0.990,'Microsoft documents creation and use of agents through Copilot Studio with Microsoft 365 Copilot.','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise'),
('microsoft-365-copilot','eai-enterprise-identity','supported',0.990,'Microsoft documents enterprise data protection and IT control for Microsoft 365 Copilot deployments; it requires a qualifying Microsoft 365 subscription.','https://www.microsoft.com/en-us/microsoft-365-copilot/pricing/enterprise'),

-- Perplexity Enterprise
('perplexity-enterprise','eai-chat-reasoning','supported',0.990,'Perplexity Enterprise provides organization-level AI answers, analysis and work capabilities.','https://www.perplexity.ai/enterprise'),
('perplexity-enterprise','eai-web-research','supported',0.990,'Perplexity Enterprise emphasizes current, cited answers, Deep Research and multi-step research workflows.','https://www.perplexity.ai/enterprise/pricing'),
('perplexity-enterprise','eai-business-connectors','supported',0.970,'Perplexity Enterprise documents centrally governed file connectors, connected tools and private organizational knowledge search; connector availability varies by plan.','https://www.perplexity.ai/enterprise/pricing'),
('perplexity-enterprise','eai-agents-workflows','supported',0.980,'Perplexity Enterprise includes Computer for multi-step research, analysis, asset generation and scheduled automations across connected tools.','https://www.perplexity.ai/enterprise/pricing'),
('perplexity-enterprise','eai-enterprise-identity','supported',0.990,'Perplexity Enterprise documents SSO, SCIM, role-based controls, user management and audit logs.','https://www.perplexity.ai/enterprise'),
('perplexity-enterprise','eai-no-training-default','supported',0.990,'Perplexity states Enterprise customer data is not used to train its models.','https://www.perplexity.ai/enterprise'),
('perplexity-enterprise','eai-retention-audit-governance','supported',0.990,'Perplexity Enterprise documents configurable retention, audit logs, usage analytics and admin controls.','https://www.perplexity.ai/enterprise/pricing');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat111_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat111_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat111_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Enterprise assistants are cloud services, but deployment is not promoted here to avoid conflating SaaS access with private/self-hosted deployment options.
-- Mobile support is not inferred from general vendor mobile apps in this first batch.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('chatgpt-enterprise','claude-enterprise','gemini-enterprise','microsoft-365-copilot','perplexity-enterprise')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
