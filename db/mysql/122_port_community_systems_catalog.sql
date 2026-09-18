-- TechSelectAI Port Community Systems catalog expansion.
-- Adds one canonical PCS category and five evidence-backed current platforms.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review score, follower/community popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Port Community Systems (PCS)','port-community-systems','Neutral digital platforms that connect port authorities, customs, terminals, shipping lines, transporters, traders and logistics stakeholders through shared trade, vessel, cargo and regulatory workflows.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @pcs_cat=(SELECT id FROM categories WHERE slug='port-community-systems' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@pcs_cat,'Community & Trade Facilitation','pcs-community-trade','Stakeholder collaboration, single-window submission, maritime/vessel clearance, customs/regulatory workflows and digital trade documentation.',1),
(@pcs_cat,'Port Flow, Connectivity & Intelligence','pcs-flow-connectivity','Cargo visibility, TOS/carrier/inland integration, payments, truck/gate coordination, APIs/EDI and analytics for port-community operations.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'pcs-community-trade' module_slug,'Port-community stakeholder collaboration' name,'pcs-stakeholder-collaboration' slug,'Connect public and private stakeholders such as port authorities, customs, terminals, shipping lines, forwarders, transporters, traders and other logistics actors through shared workflows and data exchange.' description,0 sec UNION ALL
 SELECT 'pcs-community-trade','Single-window / single-submission trade workflows','pcs-single-window' ,'Provide a unified digital entry point or single-submission model for port, trade or logistics information and transactions across participating agencies and stakeholders.',0 UNION ALL
 SELECT 'pcs-community-trade','Vessel call & maritime single-window clearance','pcs-vessel-clearance','Digitize vessel arrival, stay, departure, manifest, booking, port-call or other maritime-clearance information and approvals where supported.',0 UNION ALL
 SELECT 'pcs-community-trade','Customs, authority & regulatory integration','pcs-customs-regulatory','Exchange declarations, authorizations, permits or status with customs, port authorities and other government or regulatory bodies.',0 UNION ALL
 SELECT 'pcs-community-trade','Paperless documents, approvals & e-signatures','pcs-digital-documents','Digitize and exchange trade documents, approvals, licenses, manifests, delivery orders, certificates or signatures through paperless workflows.',0 UNION ALL
 SELECT 'pcs-flow-connectivity','Cargo, container & shipment visibility','pcs-cargo-visibility','Provide tracking, status or visibility for cargo, containers, documents, vessel schedules or shipment milestones across the port community.',0 UNION ALL
 SELECT 'pcs-flow-connectivity','TOS, carrier & inland-system integration','pcs-tos-carrier-inland-integration','Exchange operational data with terminal operating systems, shipping lines, carriers, inland operators, CFS/ICD, rail, road or other connected logistics systems.',0 UNION ALL
 SELECT 'pcs-flow-connectivity','Payments, charges & community billing','pcs-payments-billing','Support digital payment, community charges, invoicing or fee consolidation across port and trade services where documented.',0 UNION ALL
 SELECT 'pcs-flow-connectivity','Truck appointment & gate-flow coordination','pcs-truck-gate-coordination','Coordinate truck arrivals, appointments, landside flow or gate-related processes directly or through an explicitly connected companion service.',0 UNION ALL
 SELECT 'pcs-flow-connectivity','EDI, APIs & system-to-system connectivity','pcs-edi-api-connectivity','Provide EDI, API or other system-to-system interfaces for real-time or automated exchange between the PCS and participant systems.',0 UNION ALL
 SELECT 'pcs-flow-connectivity','Analytics, KPIs & forecasting','pcs-analytics-forecasting','Provide operational dashboards, KPIs, business intelligence, forecasting or decision-support analytics for port and trade processes.',0
) x ON x.module_slug=m.slug
WHERE m.category_id=@pcs_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Kalé Logistics Solutions','kale-logistics','https://www.kalelogistics.com/','Cargo-community, port-community and logistics digital-platform vendor.','active'),
('SOGET','soget','https://www.soget.fr/en/','Port and airport community-system software vendor.','active'),
('Webb Fontaine','webb-fontaine','https://webbfontaine.com/','Trade, customs and port-community digital-platform vendor.','active'),
('Portall Infosystems','portall','https://www.portall.in/','Smart-port, port-community and maritime single-window software provider.','active'),
('Maqta Technologies Group','maqta-technologies','https://www.adportsgroup.com/en/integrated-clusters/digital','Digital trade, port-community and single-window technology provider within AD Ports Group.','active')
ON DUPLICATE KEY UPDATE website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat122_products;
CREATE TEMPORARY TABLE cat122_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat122_products VALUES
('kale-logistics','port-community-systems','Kalé Port Community System','kale-port-community-system','Port Community System connecting ports, shipping lines, terminals, customs, transporters and inland logistics with maritime single-window, vessel-clearance, cargo-release and port-flow digitalization.','https://www.kalelogistics.com/products/port-community-systems'),
('soget','port-community-systems','SOGET S ONE','soget-s-one','Fourth-generation Port & Airport Community System for import, export, transit and transshipment workflows, real-time cargo tracking, authority approvals, permits and system-to-system integration.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('webb-fontaine','port-community-systems','Webb Ports','webb-ports','Port Community System for stakeholder collaboration, vessel and cargo data exchange, customs integration, paperless processing, digital payments, TOS/shipping-line integration and port-performance analytics.','https://webbfontaine.com/our-solutions/webb-ports'),
('portall','port-community-systems','Portall Port Community System','portall-port-community-system','Cloud-based smart-port community platform for single-window trade data exchange, documents, approvals, payments, cargo/vessel visibility, compliance and stakeholder integration.','https://www.portall.in/product/port-community-system'),
('maqta-technologies','port-community-systems','Maqta Port Community System (mPCS)','maqta-port-community-system','Port Community System developed by Maqta Technologies to provide a single digital window connecting port authorities, traders and logistics stakeholders, with current international PCS rollouts beyond Abu Dhabi.','https://www.adportsgroup.com/en/innovation');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat122_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

DROP TEMPORARY TABLE IF EXISTS cat122_sources;
CREATE TEMPORARY TABLE cat122_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat122_sources VALUES
('kale-port-community-system','https://www.kalelogistics.com/products/port-community-systems','Kalé Port Community Systems','Kalé Logistics Solutions'),
('kale-port-community-system','https://www.kalelogistics.com/products/port-community-systems-1','Kalé Maritime Single Window System','Kalé Logistics Solutions'),
('soget-s-one','https://www.soget.fr/en/sone-port-airport-community-system/','S ONE Port & Airport Community System','SOGET'),
('soget-s-one','https://www.soget.fr/port-community-system-s-one/','S ONE Port Community System Interfaces and Services','SOGET'),
('webb-ports','https://webbfontaine.com/our-solutions/webb-ports','Webb Ports Port Community System','Webb Fontaine'),
('webb-ports','https://portfolio.webbfontaine.com/','Webb Fontaine Product Portfolio - Webb Ports','Webb Fontaine'),
('portall-port-community-system','https://www.portall.in/product/port-community-system','Portall Port Community System','Portall Infosystems'),
('portall-port-community-system','https://www.portall.in/','Portall Smart Port Solutions','Portall Infosystems'),
('maqta-port-community-system','https://www.adportsgroup.com/en/innovation','Maqta Port Community System','AD Ports Group'),
('maqta-port-community-system','https://www.adportsgroup.com/en/integrated-clusters/digital','AD Ports Group Digital Cluster - Maqta Technologies','AD Ports Group'),
('maqta-port-community-system','https://wpvip.adportsgroup.com/adportsgroup/news-and-media/2026/06/18/ad-ports-group-launches-maqta-ayla-digital-solutions-in-jordan/','Maqta Ayla Digital Solutions Launch','AD Ports Group'),
('maqta-port-community-system','https://www.adportsgroup.com/en/news-and-media/2026/01/28/ad-ports-group-and-bigbear-ai-announce-partnership','Maqta Technologies Digital Trade Portfolio','AD Ports Group');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat122_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat122_facts;
CREATE TEMPORARY TABLE cat122_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat122_facts VALUES
-- Kalé Port Community System
('kale-port-community-system','pcs-stakeholder-collaboration','supported',0.990,'Kalé documents one ecosystem connecting ports, shipping lines, terminal operators, customs, transporters and inland-logistics stakeholders.','https://www.kalelogistics.com/products/port-community-systems'),
('kale-port-community-system','pcs-single-window','supported',0.990,'Kalé documents unified Maritime Single Window / PCS workflows that replace fragmented agency submissions.','https://www.kalelogistics.com/products/port-community-systems-1'),
('kale-port-community-system','pcs-vessel-clearance','supported',0.990,'Kalé explicitly documents digital vessel-clearance and maritime-single-window processes for vessel arrival, stay and departure.','https://www.kalelogistics.com/products/port-community-systems-1'),
('kale-port-community-system','pcs-customs-regulatory','supported',0.990,'Kalé documents customs and multi-agency regulatory integration across port-community and maritime-single-window workflows.','https://www.kalelogistics.com/products/port-community-systems'),
('kale-port-community-system','pcs-digital-documents','supported',0.980,'Kalé documents replacement of paper-heavy delivery orders, VGM certificates and multi-portal processes with digital port-community workflows.','https://www.kalelogistics.com/products/port-community-systems'),
('kale-port-community-system','pcs-cargo-visibility','supported',0.980,'Kalé positions the PCS as a synchronized ecosystem addressing cargo-flow blind spots and real-time stakeholder visibility.','https://www.kalelogistics.com/products/port-community-systems'),
('kale-port-community-system','pcs-tos-carrier-inland-integration','supported',0.980,'Kalé documents integration across terminal operations, inland CFS, shipping lines and transporters in the same port-community ecosystem.','https://www.kalelogistics.com/products/port-community-systems'),
('kale-port-community-system','pcs-truck-gate-coordination','partially_supported',0.950,'Kalé documents gate-congestion reduction and landside synchronization, but a universal standalone truck-appointment module is not inferred from the reviewed PCS pages.','https://www.kalelogistics.com/products/port-community-systems'),

-- SOGET S ONE
('soget-s-one','pcs-stakeholder-collaboration','supported',0.990,'S ONE connects public and private logistics, port, airport, customs, terminal and government stakeholders on a neutral community platform.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('soget-s-one','pcs-single-window','supported',0.980,'S ONE centralizes community data and digitizes administrative, logistics and commercial transit processes through a unified PCS workflow.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('soget-s-one','pcs-vessel-clearance','supported',0.990,'S ONE explicitly covers manifests, booking, bill of lading, goods movements and port/authority authorizations across transit operations.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('soget-s-one','pcs-customs-regulatory','supported',0.990,'S ONE covers authorizations and permits from customs, port/airport authorities, government agencies and other regulatory organizations.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('soget-s-one','pcs-digital-documents','supported',0.990,'SOGET documents 100% digital administrative, logistics and commercial workflows for cargo transit.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('soget-s-one','pcs-cargo-visibility','supported',0.990,'S ONE provides real-time tracking and tracing of goods and can extend this with IoT-based shipment tracking.','https://www.soget.fr/port-community-system-s-one/'),
('soget-s-one','pcs-edi-api-connectivity','supported',0.990,'SOGET explicitly documents automated operator-system integration through EDI or API interfaces.','https://www.soget.fr/port-community-system-s-one/'),
('soget-s-one','pcs-truck-gate-coordination','partially_supported',0.980,'SOGET offers TAS Truck Appointment System as a complementary S ONE service; it is not treated as universally included in core S ONE.','https://www.soget.fr/en/sone-port-airport-community-system/'),
('soget-s-one','pcs-analytics-forecasting','partially_supported',0.970,'SOGET offers Business Intelligence as an additional service around S ONE rather than assuming it is included in every core PCS deployment.','https://www.soget.fr/en/sone-port-airport-community-system/'),

-- Webb Ports
('webb-ports','pcs-stakeholder-collaboration','supported',0.990,'Webb Ports connects customs, port authorities, shipping lines, handlers, terminals, forwarders and commercial banks on one PCS.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-single-window','supported',0.980,'Webb Ports centralizes stakeholder communication and trade-process data in one system, reducing fragmented submissions and manual channels.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-vessel-clearance','supported',0.990,'Webb Ports accepts vessel-call information, freight manifests, handling-unit details, booking confirmations and transshipment requests.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-customs-regulatory','supported',0.990,'Webb Ports explicitly integrates with customs systems including ASYCUDA for direct PCS-customs data exchange.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-digital-documents','supported',0.990,'Webb Ports is positioned as a fully paperless environment for port trade processing.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-tos-carrier-inland-integration','supported',0.990,'Webb Ports explicitly documents real-time data sharing with TOS platforms and shipping lines/agents.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-payments-billing','supported',0.990,'Webb Ports supports digital payment and unified invoices consolidating carrier, terminal and authority charges.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-edi-api-connectivity','partially_supported',0.970,'Webb Ports explicitly supports electronic data interchange with private systems; a universal public API catalogue is not inferred from the reviewed evidence.','https://webbfontaine.com/our-solutions/webb-ports'),
('webb-ports','pcs-analytics-forecasting','supported',0.980,'Webb Ports documents performance analytics as a core PCS feature; predictive forecasting is not inferred.','https://webbfontaine.com/our-solutions/webb-ports'),

-- Portall PCS
('portall-port-community-system','pcs-stakeholder-collaboration','supported',0.990,'Portall connects service providers, cargo carriers, custodians, ports, terminals, customs-related actors and trade stakeholders in one PCS.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-single-window','supported',0.990,'Portall explicitly defines its PCS as a single-window system for data exchange, document submission, approvals and payments.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-vessel-clearance','supported',0.980,'Portall provides FAL-compatible exchange and current Maritime Single Window deployments for vessel arrival, stay and departure workflows.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-customs-regulatory','supported',0.990,'Portall documents ASYCUDA/FAL/EDIFACT support plus regulatory-compliance and audit-ready digital workflows.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-digital-documents','supported',0.990,'Portall supports digital documents, OCR, e-signatures, approvals and paperless trade processing.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-cargo-visibility','supported',0.990,'Portall documents real-time visibility into cargo movement, vessel schedules and documentation.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-tos-carrier-inland-integration','supported',0.980,'Portall documents comprehensive integrations across terminal operators, shipping lines, road/rail transporters, CFS/ICD, yards and other port-community participants.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-payments-billing','supported',0.990,'Portall explicitly includes payments in its single-window PCS workflow and reports current payment-processing operations.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-edi-api-connectivity','partially_supported',0.970,'Portall explicitly documents FAL, ASYCUDA and EDIFACT exchange; a general-purpose public API catalogue is not inferred.','https://www.portall.in/product/port-community-system'),
('portall-port-community-system','pcs-analytics-forecasting','supported',0.990,'Portall documents AI-powered forecasting and analytics over PCS data.','https://www.portall.in/product/port-community-system'),

-- Maqta Port Community System
('maqta-port-community-system','pcs-stakeholder-collaboration','supported',0.990,'Maqta PCS is documented as a single digital platform facilitating information flow between port authorities, traders and trade/logistics stakeholders.','https://www.adportsgroup.com/en/innovation'),
('maqta-port-community-system','pcs-single-window','supported',0.990,'AD Ports Group explicitly describes mPCS as a single-window port-community solution and Maqta as a provider of national/port single-window technologies.','https://www.adportsgroup.com/en/innovation'),
('maqta-port-community-system','pcs-customs-regulatory','partially_supported',0.960,'Maqta Technologies has customs and national-single-window capabilities in its wider portfolio, but the exact customs feature set bundled in every mPCS deployment is not inferred.','https://www.adportsgroup.com/en/news-and-media/2026/01/28/ad-ports-group-and-bigbear-ai-announce-partnership'),
('maqta-port-community-system','pcs-cargo-visibility','partially_supported',0.950,'AD Ports Group documents real-time shipment status for registered PCS users through the separate Manara application; this is treated as a connected PCS service rather than universal core entitlement.','https://www.adportsgroup.com/en/innovation'),
('maqta-port-community-system','pcs-truck-gate-coordination','partially_supported',0.970,'The 2026 Aqaba rollout completed a truck-management-system phase under the Maqta Ayla port-digitalization program; truck management is not assumed to be universally bundled in core mPCS.','https://wpvip.adportsgroup.com/adportsgroup/news-and-media/2026/06/18/ad-ports-group-launches-maqta-ayla-digital-solutions-in-jordan/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat122_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat122_products x JOIN products p ON p.slug=x.product_slug JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(SELECT 1 FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this capability.'
FROM cat122_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Deployment remains not_yet_verified for all five products in this batch.
-- Cloud-hosted or internationally deployed does not automatically mean public SaaS.
-- Do not infer platform-specific mobile access from generic responsive/mobile or companion-app references.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('kale-port-community-system','soget-s-one','webb-ports','portall-port-community-system','maqta-port-community-system')
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),scope_status=VALUES(scope_status),evidence_type=VALUES(evidence_type),confidence_score=VALUES(confidence_score);

COMMIT;
