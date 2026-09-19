-- TechSelectAI Workforce Rostering Depth Program - UKG Shiftboard evidence pass.
-- Reviews UKG Shiftboard against the specialist rostering taxonomy using current first-party UKG material.
-- UKG states Shiftboard is now part of UKG Pro Workforce Management; this pass evaluates the named Shiftboard scheduling capability separately
-- and does not copy broader UKG Pro Workforce Management features unless they are explicitly documented for Shiftboard.
-- Production-plan alignment is not promoted into a generic ERP/MES/API integration claim.
-- UKG Pro WFM employee/time data integration is not promoted into a generic HRIS/payroll connector catalogue.
-- "Any device" employee self-service wording is not promoted into Android/iOS/mobile-web platform support without exact platform evidence.
-- Deployment model, APIs/webhooks, enterprise SSO and large-workforce scale remain not_yet_verified.
-- Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

SET @shiftboard=(SELECT id FROM products WHERE slug='ukg-shiftboard' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS cat148_sources;
CREATE TEMPORARY TABLE cat148_sources(url TEXT,title VARCHAR(255),publisher VARCHAR(190));
INSERT INTO cat148_sources VALUES
('https://www.ukg.com/products/features/ukg-shiftboard','UKG Shiftboard','UKG'),
('https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features','UKG Shiftboard Features','UKG'),
('https://www.ukg.com/learn/resources/product-info/ukg-shiftboard','UKG Shiftboard Product Information','UKG'),
('https://www.ukg.com/glossary/how-ukg-shiftboard-helps-union-compliance','How UKG Shiftboard Helps With Union Compliance','UKG'),
('https://www.ukg.com/sites/default/files/2026-03/UKG-Shiftboard-Product-Profile.pdf','UKG Shiftboard Product Profile','UKG');

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @shiftboard,'vendor_documentation',s.url,s.title,s.publisher,1,'verified','high',NOW()
FROM cat148_sources s
WHERE @shiftboard IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@shiftboard AND e.source_url=s.url
  );

DROP TEMPORARY TABLE IF EXISTS cat148_facts;
CREATE TEMPORARY TABLE cat148_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat148_facts VALUES
('rostering-staffing-requirements-modeling','supported',0.990,'UKG Shiftboard converts production plans into staffing requirements using configurable demand templates.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-workload-driven-staffing','supported',0.990,'UKG Shiftboard aligns workforce plans with production demand and converts production plans into staffing requirements.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-coverage-targets','supported',0.980,'UKG Shiftboard provides visibility into coverage needs and optimizes skill mix to maximize coverage.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-operations-demand-integration','partially_supported',0.970,'UKG Shiftboard aligns schedules directly with production line plans and production demand, but the reviewed public material does not establish a generic external ERP/MES/API connector for those inputs.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-roster-builder','supported',0.990,'UKG Shiftboard automates shift planning and complex workforce schedule creation.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-automated-scheduling','supported',0.990,'UKG Shiftboard explicitly automates and optimizes complex workforce scheduling requirements.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-recurring-shift-patterns','supported',0.980,'UKG Shiftboard supports configurable shift-pattern structures across plants, sites and units.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-shift-slot-assignment','supported',0.990,'UKG Shiftboard identifies the best staffing options and assigns eligible workers to shifts under configured rules.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-skills-based-assignment','supported',0.990,'UKG Shiftboard optimizes skill mix and uses worker skills when filling coverage requirements.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-certification-based-assignment','supported',0.990,'UKG Shiftboard ensures workers have the required training and certifications before assignment.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-availability-aware-scheduling','supported',0.990,'UKG Shiftboard fills shifts from labor pools with varying availability as part of continuous coverage optimization.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-preference-aware-scheduling','supported',0.990,'UKG Shiftboard explicitly accommodates scheduling preferences and gives employees preference controls.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-labor-law-compliance','supported',0.990,'UKG Shiftboard explicitly enforces labor laws, state/local regulations and internal policies during scheduling.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-collective-agreement-rules','supported',0.990,'UKG Shiftboard explicitly applies collective bargaining agreements and union rules in automated scheduling.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-rest-period-rules','supported',0.990,'UKG Shiftboard explicitly supports fatigue rules including required rest periods.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-fatigue-risk-rules','supported',0.990,'UKG Shiftboard explicitly enforces fatigue standards and fatigue-related scheduling guidelines.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-max-hours-consecutive-shifts','supported',0.990,'UKG Shiftboard rules explicitly cover shift lengths and consecutive shifts as fatigue/compliance constraints.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-overtime-thresholds','supported',0.990,'UKG Shiftboard configures overtime detection, counting and tracking and uses overtime impact in staffing decisions.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-fair-overtime-distribution','supported',0.990,'UKG Shiftboard explicitly supports equitable overtime distribution and configurable fairness rules.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-seniority-rules','supported',0.990,'UKG Shiftboard union-compliance tooling explicitly supports seniority-based priority and related job-progression rules.','https://www.ukg.com/glossary/how-ukg-shiftboard-helps-union-compliance'),
('rostering-department-location-allocation','supported',0.980,'UKG Shiftboard adapts scheduling to each plant, site or unit and supports area-specific workflows and policies.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-work-area-role-allocation','supported',0.990,'UKG Shiftboard builds schedules aligned with operational areas, crews and shift-pattern structures.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-crew-gang-team-assignment','supported',0.980,'UKG Shiftboard explicitly supports crew structures as part of operational scheduling configuration.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-minimum-skill-mix','supported',0.990,'UKG Shiftboard optimizes the workforce skill mix to maximize required coverage.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-absence-backfill','supported',0.990,'UKG Shiftboard automates scheduling responses to sudden call-offs and other staffing disruptions.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-intraday-reassignment','supported',0.990,'UKG Shiftboard can reassign underutilized workers to understaffed areas and make proactive adjustments as demand changes.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-schedule-self-service','partially_supported',0.960,'UKG Shiftboard gives employees schedule controls from any device, including bidding, preferences, trades and time-off actions, but the reviewed wording does not explicitly state full published-roster viewing; native app platform support is not inferred.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('rostering-shift-swaps','supported',0.990,'UKG Shiftboard explicitly allows employees to trade schedules.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('rostering-shift-bidding','supported',0.990,'UKG Shiftboard explicitly allows employees to bid on shifts.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('rostering-open-shift-volunteering','supported',0.990,'UKG Shiftboard explicitly gives employees volunteering opportunities for shifts.','https://www.ukg.com/sites/default/files/2026-03/UKG-Shiftboard-Product-Profile.pdf'),
('rostering-leave-timeoff-requests','supported',0.990,'UKG Shiftboard product information states employees can manage time off and marketplace documentation covers time-off approval data.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('rostering-availability-preference-self-service','supported',0.980,'UKG Shiftboard explicitly lets employees set preferences and supports availability-aware scheduling.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('rostering-manager-override','supported',0.990,'UKG Shiftboard tracks exceptions and documents justifications for manual overrides.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-scheduling-audit-trail','supported',0.990,'UKG Shiftboard explicitly provides full-cycle auditing, tracks exceptions and documents manual-override justifications.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-hris-integration','partially_supported',0.980,'UKG Shiftboard explicitly leverages UKG Pro Workforce Management employee data; this proves suite integration but not a generic HRIS connector catalogue.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-payroll-integration','partially_supported',0.940,'UKG Shiftboard integrates with UKG time clocks to support payroll accuracy, but the reviewed material does not establish direct payroll export or a generic payroll-connector catalogue.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-time-attendance-integration','supported',0.990,'UKG Shiftboard explicitly applies UKG time-and-attendance data to scheduling rules and integrates with UKG time clocks.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-coverage-gap-visibility','supported',0.990,'UKG Shiftboard explicitly identifies coverage gaps and shows production and workforce schedules in a centralized view.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-manpower-status-monitoring','supported',0.980,'UKG Shiftboard provides real-time visibility into staffing and production needs to support proactive adjustments.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard'),
('rostering-overtime-labor-cost-analytics','supported',0.990,'UKG Shiftboard optimizes schedules for labor cost, reduces unnecessary overtime and overstaffing, and evaluates overtime cost impact.','https://www.ukg.com/products/features/ukg-shiftboard'),
('rostering-staffing-alerts-exceptions','supported',0.990,'UKG Shiftboard manages exceptions and proactively recommends schedule changes to prevent rule violations or coverage problems.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-multi-location-operations','supported',0.980,'UKG Shiftboard supports configurable scheduling across plants, sites and units with local workflows and policies.','https://marketplace.ukg.com/en-US/apps/426658/ukg-shiftboard/features'),
('rostering-continuous-24x7-operations','supported',0.990,'UKG positions Shiftboard specifically for complex, highly regulated 24/7 operations.','https://www.ukg.com/learn/resources/product-info/ukg-shiftboard');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @shiftboard,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat148_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @shiftboard IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current first-party UKG documentation supporting this Shiftboard capability status and scope boundary.'
FROM cat148_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@shiftboard AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@shiftboard AND e.source_url=f.source_url;

UPDATE products SET last_reviewed_at=NOW() WHERE id=@shiftboard;

COMMIT;
