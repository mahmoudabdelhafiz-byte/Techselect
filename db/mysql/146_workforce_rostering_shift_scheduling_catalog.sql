-- TechSelectAI Workforce Rostering & Shift Scheduling specialized catalog foundation.
-- Adds a domain-specific operational rostering category, six initial products and 58 buyer-selectable criteria.
-- Official first-party evidence reviewed Sep 2026. Presence is not an endorsement.
-- ManpowerIQ is a Barmageyat-owned related-party product and is explicitly disclosed; ownership does not affect scoring.
-- Unknown != Unsupported. No Fit Score, recommendation ranking, review weighting, popularity or commercial placement logic is changed.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO categories(name,slug,description,is_active) VALUES
('Workforce Rostering & Shift Scheduling Software','workforce-rostering-shift-scheduling','Specialized workforce rostering, shift scheduling and manpower-planning software for operational, frontline and 24/7 environments, covering demand planning, roster generation, skills and certifications, labor rules, fatigue, operational allocation, approvals, employee self-service, integrations and workforce control.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @rost_cat=(SELECT id FROM categories WHERE slug='workforce-rostering-shift-scheduling' LIMIT 1);

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@rost_cat,'Demand & Staffing Planning','rostering-demand-planning','Forecast workload and translate operational demand into staffing requirements, scenarios and coverage targets.',1),
(@rost_cat,'Roster & Shift Generation','rostering-schedule-generation','Build and optimize rosters, shift patterns and individual assignments using availability, skills and preferences.',1),
(@rost_cat,'Compliance, Fatigue & Fairness','rostering-compliance-fatigue','Apply labor rules, agreements, rest/fatigue limits, overtime controls and fair scheduling policies.',1),
(@rost_cat,'Operational Workforce Allocation','rostering-operational-allocation','Allocate qualified people to departments, locations, work areas, crews, equipment and live operational needs.',1),
(@rost_cat,'Employee Self-Service','rostering-self-service','Employee schedule access, swaps, bids, volunteering, leave requests and availability/preferences.',1),
(@rost_cat,'Approval, Governance & Audit','rostering-governance','Roster approvals, overrides, change control, versioning, auditability and role-based scheduling access.',1),
(@rost_cat,'Integration & Workforce Data','rostering-integration-data','Connect rostering with HR, payroll, attendance, operational systems, APIs and enterprise identity.',1),
(@rost_cat,'Analytics & Operational Control','rostering-analytics-control','Coverage, manpower status, overtime/cost, planned-vs-actual and scheduling alerts.',1),
(@rost_cat,'Platform & Operational Scale','rostering-platform-operations','Support multi-location, continuous 24/7 operations and large operational workforces.',1)
ON DUPLICATE KEY UPDATE name=VALUES(name),description=VALUES(description),is_active=1;

INSERT INTO modules(category_id,name,slug,description,is_active) VALUES
(@rost_cat,'Mobile Access','mobile-access','Buyer-selectable mobile access requirements. Availability is evidence-based; unknown is not unsupported.',1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_active=1;
SET @rost_mobile=(SELECT id FROM modules WHERE category_id=@rost_cat AND slug='mobile-access' LIMIT 1);

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active) VALUES
(@rost_mobile,'Android mobile application','workforce-rostering-shift-scheduling-mobile-android-app','A vendor-supported Android application is available for the software.',0,1),
(@rost_mobile,'iOS mobile application','workforce-rostering-shift-scheduling-mobile-ios-app','A vendor-supported iOS application is available for the software.',0,1),
(@rost_mobile,'Mobile web access','workforce-rostering-shift-scheduling-mobile-web-access','The software provides vendor-supported mobile web or responsive browser access.',0,1)
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO capabilities(module_id,name,slug,description,is_security_related,is_active)
SELECT m.id,x.name,x.slug,x.description,x.sec,1
FROM modules m JOIN (
 SELECT 'rostering-demand-planning' module_slug,'Workforce demand forecasting' name,'rostering-workforce-demand-forecasting' slug,'Forecast workforce demand from historical, operational, production or business-volume signals.' description,0 sec UNION ALL
 SELECT 'rostering-demand-planning' module_slug,'Staffing requirements modeling' name,'rostering-staffing-requirements-modeling' slug,'Translate demand, service targets or operating plans into required headcount by role, skill, time period or work area.' description,0 sec UNION ALL
 SELECT 'rostering-demand-planning' module_slug,'Workload-driven staffing' name,'rostering-workload-driven-staffing' slug,'Calculate staffing needs directly from workload, production, service or task demand.' description,0 sec UNION ALL
 SELECT 'rostering-demand-planning' module_slug,'Staffing scenario planning' name,'rostering-staffing-scenario-planning' slug,'Compare alternative staffing or roster scenarios before publishing the schedule.' description,0 sec UNION ALL
 SELECT 'rostering-demand-planning' module_slug,'Coverage targets & minimum staffing' name,'rostering-coverage-targets' slug,'Define minimum staffing or coverage targets by time, role, location or operating area.' description,0 sec UNION ALL
 SELECT 'rostering-demand-planning' module_slug,'Multi-site capacity planning' name,'rostering-multi-site-capacity-planning' slug,'Plan workforce capacity across multiple sites, departments or operating units.' description,0 sec UNION ALL
 SELECT 'rostering-demand-planning' module_slug,'Operations / production demand integration' name,'rostering-operations-demand-integration' slug,'Use operational, production, order, terminal or service-demand data as an input to manpower planning.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Roster builder' name,'rostering-roster-builder' slug,'Create, edit and publish employee rosters or shift schedules.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Automated / optimized scheduling' name,'rostering-automated-scheduling' slug,'Automatically generate or optimize schedules against demand, rules, costs and workforce constraints.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Recurring shift patterns' name,'rostering-recurring-shift-patterns' slug,'Model repeating shift templates, cycles or recurring work patterns.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Rotating shifts' name,'rostering-rotating-shifts' slug,'Plan rotating shift patterns across teams, crews or employees.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Employee-to-shift assignment' name,'rostering-shift-slot-assignment' slug,'Assign specific employees to rostered shifts or shift slots.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Skills-based assignment' name,'rostering-skills-based-assignment' slug,'Assign employees according to required skills or competencies.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Certification / qualification assignment' name,'rostering-certification-based-assignment' slug,'Use valid certifications, licenses or qualifications as assignment constraints.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Availability-aware scheduling' name,'rostering-availability-aware-scheduling' slug,'Build schedules using employee availability and unavailability.' description,0 sec UNION ALL
 SELECT 'rostering-schedule-generation' module_slug,'Preference-aware scheduling' name,'rostering-preference-aware-scheduling' slug,'Use employee shift, time or location preferences when generating or adjusting schedules.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Labor-law scheduling rules' name,'rostering-labor-law-compliance' slug,'Enforce working-time, wage-hour or other labor-law constraints during scheduling.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Collective bargaining / union rules' name,'rostering-collective-agreement-rules' slug,'Apply collective bargaining agreements, union rules or local labor-contract constraints.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Rest-period rules' name,'rostering-rest-period-rules' slug,'Enforce minimum rest periods between shifts or duties.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Fatigue-risk scheduling controls' name,'rostering-fatigue-risk-rules' slug,'Apply fatigue-related rules or safeguards to scheduling decisions.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Maximum hours & consecutive shifts' name,'rostering-max-hours-consecutive-shifts' slug,'Control maximum hours, consecutive shifts or extended-duty limits.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Overtime thresholds' name,'rostering-overtime-thresholds' slug,'Identify or prevent assignments that cross configured overtime thresholds.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Fair overtime distribution' name,'rostering-fair-overtime-distribution' slug,'Distribute overtime or extra work according to fairness, equalization or configured rotation rules.' description,0 sec UNION ALL
 SELECT 'rostering-compliance-fatigue' module_slug,'Seniority-based scheduling rules' name,'rostering-seniority-rules' slug,'Apply seniority-based bidding, assignment or scheduling logic where required.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Department & location allocation' name,'rostering-department-location-allocation' slug,'Allocate manpower across departments, sites, terminals, facilities or operational locations.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Work-area & role allocation' name,'rostering-work-area-role-allocation' slug,'Allocate people to roles, functions, zones, lines, berths, yards, gates or comparable work areas.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Crew / gang / team assignment' name,'rostering-crew-gang-team-assignment' slug,'Plan crews, gangs or teams as scheduling units or assignment groups.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Equipment / machine qualification' name,'rostering-equipment-machine-qualification' slug,'Restrict assignments according to qualification for equipment, machines or specialized operating positions.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Minimum skill-mix rules' name,'rostering-minimum-skill-mix' slug,'Require a defined mix of skills, roles or qualifications within a shift, crew or work area.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Cross-site labor pools' name,'rostering-cross-site-labor-pools' slug,'Use shared labor pools across sites, departments or operational units.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Absence backfill & replacement' name,'rostering-absence-backfill' slug,'Identify or assign suitable replacements for absence, leave, sickness or no-shows.' description,0 sec UNION ALL
 SELECT 'rostering-operational-allocation' module_slug,'Intraday workforce reassignment' name,'rostering-intraday-reassignment' slug,'Reallocate employees during the operating day as demand, absences or conditions change.' description,0 sec UNION ALL
 SELECT 'rostering-self-service' module_slug,'Employee schedule self-service' name,'rostering-schedule-self-service' slug,'Allow employees to view their published schedules and assignment details.' description,0 sec UNION ALL
 SELECT 'rostering-self-service' module_slug,'Shift swaps / trades' name,'rostering-shift-swaps' slug,'Allow eligible employees to request or execute shift swaps or trades under configured rules.' description,0 sec UNION ALL
 SELECT 'rostering-self-service' module_slug,'Shift bidding' name,'rostering-shift-bidding' slug,'Allow employees to bid for available shifts according to applicable rules.' description,0 sec UNION ALL
 SELECT 'rostering-self-service' module_slug,'Open-shift volunteering / claiming' name,'rostering-open-shift-volunteering' slug,'Allow employees to volunteer for or claim eligible open shifts.' description,0 sec UNION ALL
 SELECT 'rostering-self-service' module_slug,'Leave / time-off requests' name,'rostering-leave-timeoff-requests' slug,'Allow employees to request leave or time off within the workforce scheduling process.' description,0 sec UNION ALL
 SELECT 'rostering-self-service' module_slug,'Availability & preference self-service' name,'rostering-availability-preference-self-service' slug,'Allow employees to submit or update availability and scheduling preferences.' description,0 sec UNION ALL
 SELECT 'rostering-governance' module_slug,'Roster approval workflow' name,'rostering-roster-approval-workflow' slug,'Route rosters or manpower plans through configured approval steps before publication or execution.' description,0 sec UNION ALL
 SELECT 'rostering-governance' module_slug,'Roster change approval' name,'rostering-roster-change-approval' slug,'Require approval for selected schedule changes after an initial roster is created or published.' description,0 sec UNION ALL
 SELECT 'rostering-governance' module_slug,'Manager override with controls' name,'rostering-manager-override' slug,'Allow authorized managers to override automated or rule-based scheduling decisions with traceable controls.' description,0 sec UNION ALL
 SELECT 'rostering-governance' module_slug,'Roster version history' name,'rostering-roster-version-history' slug,'Maintain roster versions or change history across planning and publication cycles.' description,0 sec UNION ALL
 SELECT 'rostering-governance' module_slug,'Scheduling audit trail' name,'rostering-scheduling-audit-trail' slug,'Record scheduling decisions, changes, approvals and relevant user actions for audit or review.' description,0 sec UNION ALL
 SELECT 'rostering-governance' module_slug,'Role-based scheduling access' name,'rostering-role-based-scheduling-access' slug,'Restrict roster planning, approval or administration functions by role or responsibility.' description,1 sec UNION ALL
 SELECT 'rostering-integration-data' module_slug,'HRIS / HCM integration' name,'rostering-hris-integration' slug,'Exchange employee, organization, contract, skill or assignment data with HR/HCM systems.' description,0 sec UNION ALL
 SELECT 'rostering-integration-data' module_slug,'Payroll integration' name,'rostering-payroll-integration' slug,'Exchange approved hours, premiums, overtime or roster-related data with payroll systems.' description,0 sec UNION ALL
 SELECT 'rostering-integration-data' module_slug,'Time & attendance integration' name,'rostering-time-attendance-integration' slug,'Integrate planned rosters with actual attendance or timekeeping data.' description,0 sec UNION ALL
 SELECT 'rostering-integration-data' module_slug,'Operations system integration' name,'rostering-operations-system-integration' slug,'Integrate rostering with operational systems such as ERP, MES, TOS, production, maintenance or service platforms.' description,0 sec UNION ALL
 SELECT 'rostering-integration-data' module_slug,'API / webhook integration' name,'rostering-api-webhook-integration' slug,'Expose or consume supported APIs, webhooks or web services for workforce data and scheduling workflows.' description,0 sec UNION ALL
 SELECT 'rostering-integration-data' module_slug,'Enterprise SSO / identity integration' name,'rostering-enterprise-sso' slug,'Integrate scheduling access with enterprise SSO or identity providers where supported.' description,1 sec UNION ALL
 SELECT 'rostering-analytics-control' module_slug,'Coverage-gap visibility' name,'rostering-coverage-gap-visibility' slug,'Identify understaffed or overstaffed shifts, roles, locations or operating periods.' description,0 sec UNION ALL
 SELECT 'rostering-analytics-control' module_slug,'Manpower status monitoring' name,'rostering-manpower-status-monitoring' slug,'Monitor planned or allocated manpower status across shifts, departments or locations.' description,0 sec UNION ALL
 SELECT 'rostering-analytics-control' module_slug,'Overtime & labor-cost analytics' name,'rostering-overtime-labor-cost-analytics' slug,'Analyze overtime exposure, labor cost or schedule cost implications.' description,0 sec UNION ALL
 SELECT 'rostering-analytics-control' module_slug,'Planned vs actual staffing' name,'rostering-planned-vs-actual-staffing' slug,'Compare rostered staffing or hours with actual attendance, deployment or worked hours.' description,0 sec UNION ALL
 SELECT 'rostering-analytics-control' module_slug,'Staffing alerts & exceptions' name,'rostering-staffing-alerts-exceptions' slug,'Surface staffing gaps, violations, exceptions or schedule risks requiring attention.' description,0 sec UNION ALL
 SELECT 'rostering-platform-operations' module_slug,'Multi-location operations' name,'rostering-multi-location-operations' slug,'Operate workforce scheduling consistently across multiple sites, facilities, branches or terminals.' description,0 sec UNION ALL
 SELECT 'rostering-platform-operations' module_slug,'Continuous 24/7 operations' name,'rostering-continuous-24x7-operations' slug,'Support organizations that require continuous round-the-clock shift coverage and scheduling.' description,0 sec UNION ALL
 SELECT 'rostering-platform-operations' module_slug,'Large-workforce scale' name,'rostering-large-workforce-scale' slug,'Support high employee, shift, location or scheduling volumes appropriate to enterprise operational workforces.' description,0 sec
) x ON x.module_slug=m.slug
WHERE m.category_id=@rost_cat
ON DUPLICATE KEY UPDATE description=VALUES(description),is_security_related=VALUES(is_security_related),is_active=1;

INSERT INTO vendors(name,slug,website_url,description,status) VALUES
('Barmageyat','barmageyat','https://barmageyat.net/','Terminal, logistics and business software developer.','active'),
('UKG','ukg','https://www.ukg.com/','Workforce management, HCM, payroll and scheduling software provider.','active'),
('Quinyx','quinyx','https://www.quinyx.com/','Workforce management software provider focused on frontline planning, scheduling, compliance and workforce operations.','active'),
('ATOSS','atoss','https://www.atoss.com/','Workforce management software provider for workforce planning, scheduling, deployment, time and compliance.','active'),
('Legion Technologies','legion-technologies','https://legion.co/','AI-native workforce management software provider for forecasting, labor optimization, scheduling and frontline workforce operations.','active')
ON DUPLICATE KEY UPDATE name=VALUES(name),website_url=VALUES(website_url),description=VALUES(description),status='active';

DROP TEMPORARY TABLE IF EXISTS cat146_products;
CREATE TEMPORARY TABLE cat146_products(vendor_slug VARCHAR(190),category_slug VARCHAR(190),product_name VARCHAR(190),product_slug VARCHAR(190),description TEXT,product_url TEXT);
INSERT INTO cat146_products VALUES
('barmageyat','workforce-rostering-shift-scheduling','ManpowerIQ','manpoweriq','Smart workforce rostering and manpower planning for planning, allocation, approval and monitoring across departments, shifts and locations.','https://barmageyat.net/'),
('ukg','workforce-rostering-shift-scheduling','UKG Shiftboard','ukg-shiftboard','Workforce scheduling for complex, high-compliance and 24/7 operations including manufacturing and energy environments.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg','workforce-rostering-shift-scheduling','UKG Pro Workforce Management','ukg-pro-workforce-management','Enterprise workforce management combining scheduling, forecasting, time, compliance, analytics and workforce planning.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('quinyx','workforce-rostering-shift-scheduling','Quinyx Workforce Management','quinyx-workforce-management','Frontline workforce management platform covering demand forecasting, scheduling, compliance, time and attendance and workforce analytics.','https://www.quinyx.com/workforce-management'),
('atoss','workforce-rostering-shift-scheduling','ATOSS Workforce Management','atoss-workforce-management','Enterprise workforce management for demand forecasting, scheduling, deployment, time and attendance, compliance and workforce analytics.','https://www.atoss.com/en/atoss-workforce-management'),
('legion-technologies','workforce-rostering-shift-scheduling','Legion WFM','legion-wfm','AI-powered workforce management covering demand forecasting, labor optimization, automated scheduling, compliance and employee self-service.','https://legion.co/products/automated-scheduling/');

INSERT INTO products(vendor_id,category_id,name,slug,short_description,website_url,status,last_reviewed_at)
SELECT v.id,c.id,x.product_name,x.product_slug,x.description,x.product_url,'active',NOW()
FROM cat146_products x JOIN vendors v ON v.slug=x.vendor_slug JOIN categories c ON c.slug=x.category_slug
ON DUPLICATE KEY UPDATE vendor_id=VALUES(vendor_id),category_id=VALUES(category_id),name=VALUES(name),short_description=VALUES(short_description),website_url=VALUES(website_url),status='active',last_reviewed_at=NOW();

-- Reusable relationship disclosures are informational only and never participate in scoring/ranking.
CREATE TABLE IF NOT EXISTS product_relationship_disclosures(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  disclosure_type VARCHAR(50) NOT NULL,
  related_organization VARCHAR(190) NOT NULL,
  label VARCHAR(190) NOT NULL,
  details TEXT NOT NULL,
  source_url TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_relationship(product_id,disclosure_type,related_organization),
  KEY idx_relationship_product(product_id,is_active),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO product_relationship_disclosures(product_id,disclosure_type,related_organization,label,details,source_url,is_active)
SELECT p.id,'operator_ownership','Barmageyat','Related-party product','This product is developed by Barmageyat, which operates TechSelectAI. The relationship does not increase Fit Score, Evidence Confidence or ranking position.','https://techselectai.com/trust',1
FROM products p WHERE p.slug IN('manpoweriq','cardiq')
ON DUPLICATE KEY UPDATE label=VALUES(label),details=VALUES(details),source_url=VALUES(source_url),is_active=1;

DROP TEMPORARY TABLE IF EXISTS cat146_sources;
CREATE TEMPORARY TABLE cat146_sources(product_slug VARCHAR(190),url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat146_sources VALUES
('manpoweriq','https://barmageyat.net/','Barmageyat - ManpowerIQ','Barmageyat'),
('ukg-shiftboard','https://www.ukg.com/products/features/ukg-shiftboard','UKG Shiftboard','UKG'),
('ukg-shiftboard','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features','UKG Shiftboard Features','UKG'),
('ukg-pro-workforce-management','https://www.ukg.com/products/ukg-pro-workforce-management','UKG Pro Workforce Management','UKG'),
('ukg-pro-workforce-management','https://www.ukg.com/products/features/scheduling','UKG Employee Scheduling','UKG'),
('quinyx-workforce-management','https://www.quinyx.com/workforce-management','Quinyx Workforce Management','Quinyx'),
('quinyx-workforce-management','https://www.quinyx.com/workforce-management/scheduling-automation','Quinyx Scheduling Automation','Quinyx'),
('atoss-workforce-management','https://www.atoss.com/en/atoss-workforce-management','ATOSS Workforce Management','ATOSS'),
('atoss-workforce-management','https://www.atoss.com/en/expertise/workforce-scheduling','ATOSS Workforce Scheduling','ATOSS'),
('legion-wfm','https://legion.co/products/automated-scheduling/','Legion Automated Scheduling','Legion Technologies'),
('legion-wfm','https://legion.co/products/labor-optimization/','Legion Labor Optimization','Legion Technologies'),
('legion-wfm','https://legion.co/products/schedule-optimization/','Legion Schedule Optimization','Legion Technologies');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat146_sources s JOIN products p ON p.slug=s.product_slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=s.url);

DROP TEMPORARY TABLE IF EXISTS cat146_facts;
CREATE TEMPORARY TABLE cat146_facts(product_slug VARCHAR(190),capability_slug VARCHAR(190),support_status VARCHAR(40),confidence DECIMAL(4,3),limitations TEXT,source_url TEXT);
INSERT INTO cat146_facts VALUES
('manpoweriq','rostering-roster-builder','supported',0.960,'Barmageyat publicly describes ManpowerIQ as a smart workforce rostering and manpower planning system.','https://barmageyat.net/'),
('manpoweriq','rostering-shift-slot-assignment','partially_supported',0.920,'Public evidence states that ManpowerIQ plans and allocates manpower across shifts, but the exact employee-to-slot assignment workflow is not yet documented in detail.','https://barmageyat.net/'),
('manpoweriq','rostering-department-location-allocation','supported',0.980,'Barmageyat explicitly states that ManpowerIQ allocates manpower across departments and locations.','https://barmageyat.net/'),
('manpoweriq','rostering-roster-approval-workflow','supported',0.980,'Barmageyat explicitly states that ManpowerIQ supports approval within its manpower planning workflow.','https://barmageyat.net/'),
('manpoweriq','rostering-manpower-status-monitoring','supported',0.970,'Barmageyat explicitly states that ManpowerIQ monitors manpower across departments, shifts and locations.','https://barmageyat.net/'),
('manpoweriq','rostering-multi-location-operations','supported',0.960,'Public evidence explicitly describes manpower planning and monitoring across locations.','https://barmageyat.net/'),
('ukg-shiftboard','rostering-automated-scheduling','supported',0.990,'UKG states Shiftboard automates and optimizes complex workforce scheduling requirements.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-shiftboard','rostering-operations-demand-integration','supported',0.980,'UKG Shiftboard aligns workforce plans and schedules with production demand and operational needs.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('ukg-shiftboard','rostering-skills-based-assignment','supported',0.990,'UKG Shiftboard optimizes skill mix and assigns qualified workers to meet coverage needs.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('ukg-shiftboard','rostering-certification-based-assignment','supported',0.990,'UKG documents scheduling against required training and certifications for safe assignments.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-shiftboard','rostering-collective-agreement-rules','supported',0.990,'UKG Shiftboard explicitly supports union and collective bargaining scheduling rules.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-shiftboard','rostering-fatigue-risk-rules','supported',0.990,'UKG Shiftboard explicitly supports fatigue standards and fatigue-related scheduling controls.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-shiftboard','rostering-fair-overtime-distribution','supported',0.980,'UKG documents fair overtime distribution and overtime-cost optimization.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-shiftboard','rostering-absence-backfill','supported',0.970,'UKG Shiftboard automates response to sudden call-offs and staffing disruptions.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-shiftboard','rostering-shift-bidding','supported',0.980,'Employees can bid on shifts under UKG Shiftboard.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('ukg-shiftboard','rostering-continuous-24x7-operations','supported',0.990,'UKG positions Shiftboard specifically for highly regulated 24/7 operations.','https://www.ukg.com/products/features/ukg-shiftboard'),
('ukg-pro-workforce-management','rostering-workforce-demand-forecasting','supported',0.990,'UKG Pro Workforce Management includes AI-guided forecasting and strategic workforce planning.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('ukg-pro-workforce-management','rostering-automated-scheduling','supported',0.990,'UKG Pro Workforce Management uses intelligent AI scheduling to build best-fit schedules.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('ukg-pro-workforce-management','rostering-skills-based-assignment','supported',0.980,'UKG scheduling recommends best-fit employees using skills, availability and compliance.','https://www.ukg.com/products/features/scheduling'),
('ukg-pro-workforce-management','rostering-availability-aware-scheduling','supported',0.980,'UKG scheduling uses employee availability when recommending assignments.','https://www.ukg.com/products/features/scheduling'),
('ukg-pro-workforce-management','rostering-preference-aware-scheduling','supported',0.980,'UKG explicitly balances business needs with employee preferences.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('ukg-pro-workforce-management','rostering-labor-law-compliance','supported',0.990,'UKG Pro Workforce Management includes automated compliance tools across workforce processes.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('ukg-pro-workforce-management','rostering-coverage-gap-visibility','supported',0.970,'UKG provides real-time staffing visibility and workforce control for coverage decisions.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('ukg-pro-workforce-management','rostering-manpower-status-monitoring','supported',0.970,'UKG Pro Workforce Management provides real-time visibility into shifts, locations and teams.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('ukg-pro-workforce-management','rostering-continuous-24x7-operations','supported',0.970,'UKG explicitly describes scheduling for complex 24/7 operations where compliance and safety cannot be compromised.','https://www.ukg.com/products/ukg-pro-workforce-management'),
('quinyx-workforce-management','rostering-workforce-demand-forecasting','supported',0.990,'Quinyx combines demand forecasting with workforce scheduling in its WFM platform.','https://www.quinyx.com/workforce-management'),
('quinyx-workforce-management','rostering-automated-scheduling','supported',0.990,'Quinyx Auto Schedule and Auto Assign automatically optimize schedules.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-skills-based-assignment','supported',0.990,'Quinyx automated scheduling uses employee skills when assigning shifts.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-certification-based-assignment','supported',0.990,'Quinyx explicitly evaluates skills and certifications in automated assignment.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-availability-aware-scheduling','supported',0.990,'Quinyx automation uses employee availability in schedule generation.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-preference-aware-scheduling','supported',0.990,'Quinyx automation incorporates employee preferences into schedule optimization.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-labor-law-compliance','supported',0.990,'Quinyx applies labor-law and compliance rules in scheduling.','https://www.quinyx.com/workforce-management'),
('quinyx-workforce-management','rostering-fatigue-risk-rules','supported',0.970,'Quinyx states its compliance engine can apply fatigue rules alongside labor laws and policies.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-shift-swaps','supported',0.990,'Quinyx supports employee shift swaps and real-time schedule changes.','https://www.quinyx.com/workforce-management/scheduling'),
('quinyx-workforce-management','rostering-open-shift-volunteering','supported',0.980,'Quinyx employees can volunteer for open shifts through the mobile scheduling experience.','https://www.quinyx.com/workforce-management/scheduling-automation'),
('quinyx-workforce-management','rostering-hris-integration','supported',0.980,'Quinyx documents integration with HR and HRIS systems.','https://www.quinyx.com/workforce-management'),
('quinyx-workforce-management','rostering-payroll-integration','supported',0.980,'Quinyx documents integration with payroll systems.','https://www.quinyx.com/workforce-management'),
('atoss-workforce-management','rostering-workforce-demand-forecasting','supported',0.990,'ATOSS Workforce Management explicitly includes workforce forecasting across locations and time periods.','https://www.atoss.com/en/atoss-workforce-management'),
('atoss-workforce-management','rostering-staffing-requirements-modeling','supported',0.980,'ATOSS translates forecast demand into staffing requirements and executable workforce plans.','https://www.atoss.com/en/expertise/workforce-scheduling'),
('atoss-workforce-management','rostering-automated-scheduling','supported',0.990,'ATOSS documents automated, demand-driven workforce scheduling.','https://www.atoss.com/en/atoss-workforce-management'),
('atoss-workforce-management','rostering-skills-based-assignment','supported',0.980,'ATOSS workforce scheduling aligns assignments with skills and operational requirements.','https://www.atoss.com/en/expertise/workforce-scheduling'),
('atoss-workforce-management','rostering-availability-aware-scheduling','supported',0.980,'ATOSS scheduling uses workforce availability as a scheduling constraint.','https://www.atoss.com/en/expertise/workforce-scheduling'),
('atoss-workforce-management','rostering-labor-law-compliance','supported',0.990,'ATOSS enforces labor and regulatory constraints during scheduling.','https://www.atoss.com/en/expertise/workforce-scheduling'),
('atoss-workforce-management','rostering-intraday-reassignment','supported',0.970,'ATOSS documents real-time schedule adjustment and workforce deployment as conditions change.','https://www.atoss.com/en/atoss-workforce-management'),
('atoss-workforce-management','rostering-multi-location-operations','supported',0.970,'ATOSS workforce planning and deployment explicitly operate across locations.','https://www.atoss.com/en/atoss-workforce-management'),
('legion-wfm','rostering-workforce-demand-forecasting','supported',0.990,'Legion generates granular labor demand forecasts by time interval and demand driver.','https://legion.co/products/labor-optimization/'),
('legion-wfm','rostering-workload-driven-staffing','supported',0.990,'Legion labor optimization converts workload and demand into optimized labor plans.','https://legion.co/products/labor-optimization/'),
('legion-wfm','rostering-automated-scheduling','supported',0.990,'Legion automatically generates optimized schedules from labor plans, rules and employee constraints.','https://legion.co/products/automated-scheduling/'),
('legion-wfm','rostering-skills-based-assignment','supported',0.990,'Legion scheduling considers employee skills when selecting the best employee for a shift.','https://legion.co/products/automated-scheduling/'),
('legion-wfm','rostering-preference-aware-scheduling','supported',0.990,'Legion scheduling balances business needs with employee preferences.','https://legion.co/products/schedule-optimization/'),
('legion-wfm','rostering-labor-law-compliance','supported',0.990,'Legion uses compliance templates and business rules to enforce labor laws and policies.','https://legion.co/products/automated-scheduling/'),
('legion-wfm','rostering-overtime-thresholds','supported',0.970,'Legion optimization explicitly works to avoid costly overtime while meeting coverage requirements.','https://legion.co/products/automated-scheduling/'),
('legion-wfm','rostering-shift-swaps','supported',0.990,'Legion supports automated shift swaps with configurable rules.','https://legion.co/products/schedule-optimization/'),
('legion-wfm','rostering-leave-timeoff-requests','supported',0.980,'Legion employee self-service includes time-off requests.','https://legion.co/products/schedule-optimization/'),
('legion-wfm','rostering-overtime-labor-cost-analytics','supported',0.980,'Legion provides real-time visibility into labor costs, schedule quality and forecast variance.','https://legion.co/products/schedule-optimization/'),
('legion-wfm','rostering-coverage-gap-visibility','supported',0.980,'Legion shows gaps between scheduled hours, demand and employee preferences.','https://legion.co/products/labor-optimization/'),
('legion-wfm','rostering-multi-location-operations','supported',0.970,'Legion optimizes workforce schedules across locations and supports multi-location staffing.','https://legion.co/products/automated-scheduling/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT p.id,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat146_facts f JOIN products p ON p.slug=f.product_slug JOIN capabilities c ON c.slug=f.capability_slug
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),limitations=VALUES(limitations),confidence_score=VALUES(confidence_score),last_verified_at=NOW();

-- Every remaining criterion starts unknown rather than unsupported.
INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,confidence_score)
SELECT p.id,cap.id,NULL,'not_yet_verified',0
FROM cat146_products x JOIN products p ON p.slug=x.product_slug
JOIN categories cat ON cat.slug=x.category_slug
JOIN modules m ON m.category_id=cat.id
JOIN capabilities cap ON cap.module_id=m.id
WHERE NOT EXISTS(
  SELECT 1 FROM product_capabilities pc
  WHERE pc.product_id=p.id AND pc.capability_id=cap.id AND pc.edition_id IS NULL
);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party vendor documentation supporting this rostering capability status or scope boundary.'
FROM cat146_facts f
JOIN products p ON p.slug=f.product_slug
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=f.source_url;

-- Do not infer deployment or platform-specific mobile support from generic cloud/mobile wording.
INSERT INTO product_mobile_access(product_id,platform,support_status,scope_status,evidence_type,confidence_score)
SELECT p.id,x.platform,'not_yet_verified','not_yet_verified','not_yet_verified',0.000
FROM products p CROSS JOIN (SELECT 'android' platform UNION ALL SELECT 'ios' UNION ALL SELECT 'mobile_web') x
WHERE p.slug IN('manpoweriq','ukg-shiftboard','ukg-pro-workforce-management','quinyx-workforce-management','atoss-workforce-management','legion-wfm')
ON DUPLICATE KEY UPDATE product_id=VALUES(product_id);

COMMIT;
