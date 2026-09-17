-- TechSelectAI Expense Management catalog expansion.
-- Adds one canonical expense-management category and five evidence-backed products.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Expense Management','expense-management','Software for capturing, submitting, approving, reimbursing, reconciling and analyzing employee business expenses while enforcing company policy.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @expense_cat=(SELECT id FROM categories WHERE slug='expense-management' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@expense_cat,'Expense Capture & Submission','expense-capture-submission','Receipt capture, expense entry, reporting and employee submission workflows.',1),
(@expense_cat,'Approval, Reimbursement & Finance','expense-approval-finance','Policy controls, approval workflows, reimbursements, accounting integration, analytics and mobile administration.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'expense-capture-submission' module_slug,'Receipt capture & extraction' name,'expense-receipt-capture' slug,'Capture paper or digital receipts and extract or match expense details.' description,0 sec UNION ALL
 SELECT 'expense-capture-submission','Expense / report submission' name,'expense-report-submission','Create, categorize and submit individual expenses or expense reports.',0 UNION ALL
 SELECT 'expense-approval-finance','Policy enforcement & approvals' name,'expense-policy-approvals','Apply expense policies and route expenses through configurable review or approval workflows.',0 UNION ALL
 SELECT 'expense-approval-finance','Employee reimbursements' name,'expense-reimbursements','Process or coordinate repayment of approved out-of-pocket employee expenses.',0 UNION ALL
 SELECT 'expense-approval-finance','Accounting / ERP integration' name,'expense-accounting-integration','Sync expense data, coding, transactions or reimbursements with accounting or ERP systems.',0 UNION ALL
 SELECT 'expense-approval-finance','Reporting & spend visibility' name,'expense-reporting-analytics','Provide expense reporting, dashboards, trend analysis or real-time spend visibility.',0 UNION ALL
 SELECT 'expense-approval-finance','Mobile expense handling' name,'expense-mobile','Capture, submit, review or approve expenses from supported mobile applications.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@expense_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('SAP Concur','sap-concur','https://www.concur.com/','Travel, expense and invoice management software vendor.','active'),
('Expensify','expensify','https://use.expensify.com/','Expense management, reimbursement and spend-management software vendor.','active'),
('Ramp','ramp','https://ramp.com/','Spend management, corporate card and expense automation software vendor.','active'),
('Emburse','emburse','https://www.emburse.com/','Expense, travel and spend-management software vendor.','active'),
('Brex','brex','https://www.brex.com/','Corporate card, spend management and expense software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat107_products;
CREATE TEMPORARY TABLE cat107_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat107_products VALUES
('sap-concur','expense-management','Concur Expense','concur-expense','Expense management platform for receipt capture, expense reporting, policy checks, approvals, reimbursements, accounting integrations, analytics and mobile expense workflows.','https://www.concur.com/products/concur-expense'),
('expensify','expense-management','Expensify','expensify-expense-management','Expense management platform for receipt scanning, report creation, policy checks, approvals, reimbursements, accounting sync and mobile expense handling.','https://use.expensify.com/expense-management'),
('ramp','expense-management','Ramp Expense Management','ramp-expense-management','Expense automation for receipt collection, policy enforcement, expense review, approvals, reimbursements, accounting sync and spend visibility within the broader Ramp spend platform.','https://ramp.com/expense-management'),
('emburse','expense-management','Emburse Expense Professional','emburse-expense-professional','Configurable expense management for receipt capture, automated reports, approvals, reimbursements, policy enforcement, integrations and mobile expense workflows.','https://www.emburse.com/products/professional/expense'),
('brex','expense-management','Brex Expenses','brex-expenses','Expense management within the Brex spend platform, including card expense data, receipt matching/uploads, reimbursements and accounting-oriented integrations.','https://developer.brex.com/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat107_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat107_sources;
CREATE TEMPORARY TABLE cat107_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat107_sources VALUES
('concur-expense','https://www.concur.com/products/concur-expense','Concur Expense','SAP Concur'),
('concur-expense','https://www.concur.com/products/mobile-app','SAP Concur Mobile App','SAP Concur'),
('expensify-expense-management','https://use.expensify.com/expense-management','Expensify Expense Management','Expensify'),
('expensify-expense-management','https://use.expensify.com/expense-reports','Expensify Expense Reports','Expensify'),
('expensify-expense-management','https://use.expensify.com/download','Expensify Mobile App','Expensify'),
('ramp-expense-management','https://ramp.com/expense-management','Ramp Expense Management','Ramp'),
('ramp-expense-management','https://support.ramp.com/expense-management','Ramp Expense Management Help Center','Ramp'),
('emburse-expense-professional','https://www.emburse.com/products/professional/expense','Emburse Expense Professional','Emburse'),
('emburse-expense-professional','https://www.emburse.com/solutions/expense-management','Emburse Expense Management','Emburse'),
('brex-expenses','https://developer.brex.com/','Brex Developer Platform Overview','Brex'),
('brex-expenses','https://www.brex.com/product/integrations/rillet','Brex Rillet Integration','Brex');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat107_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat107_facts;
CREATE TEMPORARY TABLE cat107_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat107_facts VALUES
-- SAP Concur
('concur-expense','expense-receipt-capture','supported',0.990,'Concur Expense documents receipt upload, AI-powered receipt capture and automatic data extraction.','https://www.concur.com/products/concur-expense'),
('concur-expense','expense-report-submission','supported',0.990,'Employees can create, submit and track expense reports across web and mobile workflows.','https://www.concur.com/products/concur-expense'),
('concur-expense','expense-policy-approvals','supported',0.990,'Concur Expense documents real-time policy checks and structured approval workflows.','https://www.concur.com/products/concur-expense'),
('concur-expense','expense-reimbursements','supported',0.990,'Approved expenses can be reimbursed through the expense workflow.','https://www.concur.com/products/concur-expense'),
('concur-expense','expense-accounting-integration','supported',0.990,'SAP Concur documents integrations with ERP, HR and accounting systems.','https://www.concur.com/products/concur-expense'),
('concur-expense','expense-reporting-analytics','supported',0.990,'Concur Expense documents reporting, analytics and spend visibility.','https://www.concur.com/products/concur-expense'),
('concur-expense','expense-mobile','supported',0.990,'The SAP Concur mobile app supports receipt capture, report submission and manager approvals on iOS and Android.','https://www.concur.com/products/mobile-app'),

-- Expensify
('expensify-expense-management','expense-receipt-capture','supported',0.990,'Expensify documents SmartScan receipt capture and automatic transaction matching.','https://use.expensify.com/expense-management'),
('expensify-expense-management','expense-report-submission','supported',0.990,'Expensify supports creating, submitting and automating expense reports.','https://use.expensify.com/expense-reports'),
('expensify-expense-management','expense-policy-approvals','supported',0.990,'Expensify documents realtime policy checks and built-in approval workflows.','https://use.expensify.com/expense-reports'),
('expensify-expense-management','expense-reimbursements','supported',0.990,'Expensify documents employee reimbursements directly from approved expense workflows.','https://use.expensify.com/expense-reports'),
('expensify-expense-management','expense-accounting-integration','supported',0.990,'Expensify documents accounting sync with systems including QuickBooks, Xero, Sage Intacct and NetSuite.','https://use.expensify.com/expense-reports'),
('expensify-expense-management','expense-reporting-analytics','supported',0.980,'Expensify documents spend insights and reporting; exact report depth varies by configuration.','https://use.expensify.com/expense-management'),
('expensify-expense-management','expense-mobile','supported',0.990,'Expensify documents iOS and Android apps for receipt scanning, expense submission and approvals.','https://use.expensify.com/download'),

-- Ramp
('ramp-expense-management','expense-receipt-capture','supported',0.990,'Ramp documents automatic receipt capture/matching and required documentation workflows.','https://ramp.com/expense-management'),
('ramp-expense-management','expense-report-submission','supported',0.980,'Ramp supports individual expense submission and card-linked expense workflows rather than relying solely on traditional batch reports.','https://support.ramp.com/expense-management'),
('ramp-expense-management','expense-policy-approvals','supported',0.990,'Ramp documents policy controls, review workflows, approval rules and automated exception handling.','https://ramp.com/expense-management'),
('ramp-expense-management','expense-reimbursements','supported',0.990,'Ramp documents employee out-of-pocket reimbursement submission, approvals and payouts.','https://ramp.com/expense-management'),
('ramp-expense-management','expense-accounting-integration','supported',0.990,'Ramp documents automated accounting/ERP sync and transaction coding.','https://ramp.com/expense-management'),
('ramp-expense-management','expense-reporting-analytics','supported',0.990,'Ramp documents dashboards, reports and real-time spend visibility.','https://ramp.com/expense-management'),

-- Emburse
('emburse-expense-professional','expense-receipt-capture','supported',0.990,'Emburse documents mobile receipt capture with OCR extraction.','https://www.emburse.com/products/professional/expense'),
('emburse-expense-professional','expense-report-submission','supported',0.990,'Emburse documents automated expense report creation and employee submission workflows.','https://www.emburse.com/products/professional/expense'),
('emburse-expense-professional','expense-policy-approvals','supported',0.990,'Emburse documents configurable approvals and automated policy enforcement.','https://www.emburse.com/solutions/expense-management'),
('emburse-expense-professional','expense-reimbursements','supported',0.990,'Emburse documents streamlined reimbursements and approvals.','https://www.emburse.com/solutions/expense-management'),
('emburse-expense-professional','expense-accounting-integration','supported',0.990,'Emburse documents ERP, finance, accounting and travel-management integrations.','https://www.emburse.com/solutions/expense-management'),
('emburse-expense-professional','expense-reporting-analytics','supported',0.990,'Emburse documents reporting and dashboards for expense analysis.','https://www.emburse.com/solutions/expense-management'),
('emburse-expense-professional','expense-mobile','supported',0.990,'Emburse Expense Professional documents mobile receipt capture and mobile expense handling.','https://www.emburse.com/products/professional/expense'),

-- Brex
('brex-expenses','expense-receipt-capture','supported',0.990,'Brex Expenses API documents receipt matching and receipt uploads for card expenses.','https://developer.brex.com/'),
('brex-expenses','expense-report-submission','partially_supported',0.950,'Brex manages expenses primarily as transaction-centric spend records rather than a traditional report-first workflow.','https://developer.brex.com/'),
('brex-expenses','expense-reimbursements','supported',0.970,'Brex describes reimbursements as part of its unified spend platform; payout availability can depend on market/account configuration.','https://developer.brex.com/'),
('brex-expenses','expense-accounting-integration','supported',0.990,'Brex documents accounting APIs and integrations that sync spend, receipts and reimbursement data.','https://www.brex.com/product/integrations/rillet');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat107_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat107_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat107_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Current official positioning for all five products is cloud-delivered; no on-premise claim is made.
INSERT INTO product_deployments(product_id,deployment_model_id,support_status,confidence_score)
SELECT p.id,d.id,'supported',0.98
FROM products p JOIN deployment_models d ON d.slug='public-saas'
WHERE p.slug IN('concur-expense','expensify-expense-management','ramp-expense-management','emburse-expense-professional','brex-expenses')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Product-specific mobile scope is promoted only where official evidence explicitly covers expense actions.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'supported','supported','vendor_documentation',0.99
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios') x
WHERE p.slug IN('concur-expense','expensify-expense-management','emburse-expense-professional')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('ramp-expense-management','brex-expenses')
   OR (p.slug IN('concur-expense','expensify-expense-management','emburse-expense-professional') AND x.platform='mobile_web')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
