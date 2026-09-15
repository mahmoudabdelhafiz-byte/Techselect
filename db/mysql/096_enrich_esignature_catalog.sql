-- TechSelectAI E-signature depth pass.
-- Enriches the existing canonical category from migration 061, promotes four researched drafts,
-- and adds OneSpan Sign as a fifth enterprise peer using first-party evidence.
-- Unknown != Unsupported. No Fit Score or recommendation-ranking logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

SET @esign_cat=(SELECT id FROM categories WHERE slug='e-signature' LIMIT 1);

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('OneSpan','onespan','https://www.onespan.com/','Digital agreements, identity verification and electronic signature software vendor.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat96_products;
CREATE TEMPORARY TABLE cat96_products(
  vendor_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT
);
INSERT INTO cat96_products VALUES
('docusign','Docusign eSignature','docusign-esignature','Electronic signature platform for preparing, sending, routing, signing and tracking agreements with reusable templates, audit evidence and business integrations.','https://www.docusign.com/products/electronic-signature'),
('adobe','Adobe Acrobat Sign','adobe-acrobat-sign','Electronic signature solution for preparing, routing, signing, tracking and managing agreements with templates, audit trails and business integrations.','https://www.adobe.com/acrobat/business/sign.html'),
('dropbox','Dropbox Sign','dropbox-sign','Cloud electronic signature service for signature requests, reusable templates, multi-party signing, audit trails and API-driven signing workflows.','https://sign.dropbox.com/'),
('zoho','Zoho Sign','zoho-sign','Electronic signature platform for preparing, routing, signing and tracking documents with templates, audit trails, APIs and business integrations.','https://www.zoho.com/sign/'),
('onespan','OneSpan Sign','onespan-sign','Enterprise electronic signature platform for secure document signing, multi-signer workflows, reusable templates, audit evidence and API-based integrations.','https://www.onespan.com/products/electronic-signature');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,@esign_cat,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat96_products x JOIN vendors v ON v.slug=x.vendor_slug
ON DUPLICATE KEY UPDATE
  vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),
  short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat96_sources;
CREATE TEMPORARY TABLE cat96_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat96_sources VALUES
('docusign-esignature','https://www.docusign.com/products/electronic-signature','Docusign eSignature','Docusign'),
('docusign-esignature','https://www.docusign.com/integrations/esignature-for-google-workspace','Docusign eSignature for Google Workspace','Docusign'),
('adobe-acrobat-sign','https://www.adobe.com/acrobat/business/sign.html','Adobe Acrobat Sign','Adobe'),
('adobe-acrobat-sign','https://helpx.adobe.com/sign/using/audit-reports.html','Adobe Acrobat Sign audit reports','Adobe'),
('dropbox-sign','https://sign.dropbox.com/features/api','Dropbox Sign API features','Dropbox'),
('dropbox-sign','https://help.dropbox.com/security/dropbox-sign-audit-trail-overview','Dropbox Sign audit trail','Dropbox'),
('dropbox-sign','https://help.dropbox.com/create-upload/how-to-create-a-dropbox-sign-template','Dropbox Sign templates','Dropbox'),
('zoho-sign','https://www.zoho.com/sign/features.html','Zoho Sign features','Zoho'),
('zoho-sign','https://www.zoho.com/sign/api/','Zoho Sign API','Zoho'),
('onespan-sign','https://www.onespan.com/products/electronic-signature','OneSpan Sign','OneSpan'),
('onespan-sign','https://docs.onespan.com/docs/retrieving-an-audit-trail','OneSpan Sign audit trail','OneSpan');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat96_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat96_facts;
CREATE TEMPORARY TABLE cat96_facts(
  product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT
);
INSERT INTO cat96_facts VALUES
-- Docusign eSignature
('docusign-esignature','esign-send-request','supported',0.990,'Docusign documents sending agreements for electronic signature as a core eSignature workflow.','https://www.docusign.com/products/electronic-signature'),
('docusign-esignature','esign-routing','supported',0.980,'Docusign supports recipient routing and configurable agreement workflows.','https://www.docusign.com/products/electronic-signature'),
('docusign-esignature','esign-templates','supported',0.990,'Docusign documents reusable templates and workflows.','https://www.docusign.com/integrations/esignature-for-google-workspace'),
('docusign-esignature','esign-audit-tracking','supported',0.990,'Docusign documents comprehensive automated audit trails with timestamps and activity details.','https://www.docusign.com/integrations/esignature-for-google-workspace'),
('docusign-esignature','esign-integrations','supported',0.990,'Docusign documents business application integrations including Google Workspace.','https://www.docusign.com/integrations/esignature-for-google-workspace'),
-- Adobe Acrobat Sign
('adobe-acrobat-sign','esign-send-request','supported',0.990,'Adobe Acrobat Sign documents sending documents for electronic signature.','https://www.adobe.com/acrobat/business/sign.html'),
('adobe-acrobat-sign','esign-routing','supported',0.970,'Adobe documents routing and agreement workflow capabilities in Acrobat Sign.','https://www.adobe.com/acrobat/business/sign.html'),
('adobe-acrobat-sign','esign-templates','supported',0.960,'Adobe documents reusable agreement and form workflows for Acrobat Sign.','https://www.adobe.com/acrobat/business/sign.html'),
('adobe-acrobat-sign','esign-audit-tracking','supported',0.990,'Adobe documents audit reports for agreement activity.','https://helpx.adobe.com/sign/using/audit-reports.html'),
('adobe-acrobat-sign','esign-integrations','supported',0.960,'Adobe documents business workflow and application integrations for Acrobat Sign.','https://www.adobe.com/acrobat/business/sign.html'),
-- Dropbox Sign
('dropbox-sign','esign-send-request','supported',0.990,'Dropbox Sign documents signature request workflows in its API and product features.','https://sign.dropbox.com/features/api'),
('dropbox-sign','esign-routing','supported',0.960,'Dropbox Sign supports multi-party signature request workflows.','https://sign.dropbox.com/features/api'),
('dropbox-sign','esign-templates','supported',0.990,'Dropbox documents reusable Sign templates and template-based requests.','https://help.dropbox.com/create-upload/how-to-create-a-dropbox-sign-template'),
('dropbox-sign','esign-audit-tracking','supported',0.990,'Dropbox documents tamper-evident, timestamped audit trails for signature transactions.','https://help.dropbox.com/security/dropbox-sign-audit-trail-overview'),
('dropbox-sign','esign-integrations','supported',0.990,'Dropbox Sign documents API, SDK, OAuth and embedded signing capabilities.','https://sign.dropbox.com/features/api'),
-- Zoho Sign
('zoho-sign','esign-send-request','supported',0.990,'Zoho Sign documents sending documents and collecting electronic signatures.','https://www.zoho.com/sign/features.html'),
('zoho-sign','esign-routing','supported',0.970,'Zoho Sign documents multi-recipient signing and workflow controls.','https://www.zoho.com/sign/features.html'),
('zoho-sign','esign-templates','supported',0.980,'Zoho Sign documents reusable templates.','https://www.zoho.com/sign/features.html'),
('zoho-sign','esign-audit-tracking','supported',0.980,'Zoho Sign documents audit trails and document tracking.','https://www.zoho.com/sign/features.html'),
('zoho-sign','esign-integrations','supported',0.990,'Zoho Sign publishes APIs and integration capabilities.','https://www.zoho.com/sign/api/'),
-- OneSpan Sign
('onespan-sign','esign-send-request','supported',0.990,'OneSpan Sign is positioned as an enterprise electronic signature platform for document signing workflows.','https://www.onespan.com/products/electronic-signature'),
('onespan-sign','esign-routing','supported',0.970,'OneSpan Sign supports multi-signer and ordered signing workflows.','https://www.onespan.com/products/electronic-signature'),
('onespan-sign','esign-templates','supported',0.950,'OneSpan Sign documents reusable package and template-driven signing workflows.','https://www.onespan.com/products/electronic-signature'),
('onespan-sign','esign-audit-tracking','supported',0.990,'OneSpan documents detailed audit trails including signer, timestamp and signing-order evidence.','https://docs.onespan.com/docs/retrieving-an-audit-trail'),
('onespan-sign','esign-integrations','supported',0.970,'OneSpan Sign provides API-based integration for electronic signature workflows.','https://docs.onespan.com/docs/retrieving-an-audit-trail');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score,limitations,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.confidence,f.limitations,NOW()
FROM cat96_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score),limitations=VALUES(limitations),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat96_products x JOIN products p ON p.slug=x.product_slug
JOIN modules m ON m.category_id=@esign_cat JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party source supporting this capability.'
FROM cat96_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

INSERT INTO product_mobile_access(product_id,platform,support_status,scope,evidence_url,last_verified_at)
SELECT p.id,plat.platform,'not_yet_verified','Mobile access has not yet been verified from product-specific first-party evidence.',NULL,NULL
FROM products p
JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') plat
WHERE p.slug IN('docusign-esignature','adobe-acrobat-sign','dropbox-sign','zoho-sign','onespan-sign')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope=VALUES(scope);

COMMIT;
