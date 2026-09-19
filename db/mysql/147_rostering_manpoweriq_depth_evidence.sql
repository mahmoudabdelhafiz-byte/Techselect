-- TechSelectAI Workforce Rostering Depth Program - ManpowerIQ evidence pass.
-- Reviews ManpowerIQ against the specialist rostering taxonomy using current public Barmageyat documentation.
-- ManpowerIQ is a Barmageyat-owned related-party product; this evidence pass changes product facts only, never scoring or ranking.
-- Operational-demand wording is not promoted into an external TOS/ERP/MES/API integration claim.
-- Leave management is not promoted into employee self-service leave requests without explicit request-flow evidence.
-- Approval history is partial evidence for auditability, not proof of a complete schedule-change audit trail.
-- Deployment, SSO, payroll, attendance, API/webhook and platform-specific mobile support remain not_yet_verified.
-- Unknown != Unsupported.
SET NAMES utf8mb4;
START TRANSACTION;

SET @manpoweriq=(SELECT id FROM products WHERE slug='manpoweriq' LIMIT 1);

UPDATE products
SET website_url='https://barmageyat.net/manpower-iq/',
    short_description='Operational workforce rostering and manpower planning for ports, terminals, logistics, warehouses, industrial facilities and shift-based businesses, with rule-based allocation, skills and certification controls, approvals, overtime equalization, cross-pooling and workforce monitoring.',
    last_reviewed_at=NOW()
WHERE id=@manpoweriq;

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT @manpoweriq,'vendor_documentation','https://barmageyat.net/manpower-iq/','ManpowerIQ Workforce Rostering System','Barmageyat',1,'verified','high',NOW()
WHERE @manpoweriq IS NOT NULL
  AND NOT EXISTS(
    SELECT 1 FROM evidence_sources e
    WHERE e.product_id=@manpoweriq AND e.source_url='https://barmageyat.net/manpower-iq/'
  );

DROP TEMPORARY TABLE IF EXISTS cat147_facts;
CREATE TEMPORARY TABLE cat147_facts(
  capability_slug VARCHAR(190),
  support_status VARCHAR(40),
  confidence DECIMAL(4,3),
  limitations TEXT,
  source_url TEXT
);
INSERT INTO cat147_facts VALUES
('rostering-workload-driven-staffing','partially_supported',0.960,'ManpowerIQ generates rosters using operational demand as an input, but the public material does not establish quantitative workload-to-headcount calculations or an external demand feed.','https://barmageyat.net/manpower-iq/'),
('rostering-roster-builder','supported',0.990,'Barmageyat explicitly documents roster planning and roster publishing as part of the ManpowerIQ workforce-planning cycle.','https://barmageyat.net/manpower-iq/'),
('rostering-automated-scheduling','supported',0.990,'ManpowerIQ explicitly includes Automatic Allocation and Intelligent Rostering that generates manpower rosters using availability, department requirements, skills, shift rules and operational demand.','https://barmageyat.net/manpower-iq/'),
('rostering-recurring-shift-patterns','supported',0.990,'ManpowerIQ explicitly supports day, night, office, training, Ramadan, weekend and custom shift patterns.','https://barmageyat.net/manpower-iq/'),
('rostering-shift-slot-assignment','supported',0.980,'Automatic allocation and intelligent rostering assign manpower into configured shifts according to workforce constraints.','https://barmageyat.net/manpower-iq/'),
('rostering-skills-based-assignment','supported',0.990,'ManpowerIQ explicitly assigns employees only to positions for which they have the required skills.','https://barmageyat.net/manpower-iq/'),
('rostering-certification-based-assignment','supported',0.990,'ManpowerIQ explicitly uses certifications, licenses and training status to determine qualified employee assignments.','https://barmageyat.net/manpower-iq/'),
('rostering-availability-aware-scheduling','supported',0.990,'ManpowerIQ Intelligent Rostering explicitly generates rosters using employee availability.','https://barmageyat.net/manpower-iq/'),
('rostering-fair-overtime-distribution','supported',0.990,'ManpowerIQ explicitly tracks overtime and distributes it fairly across employees to reduce imbalance.','https://barmageyat.net/manpower-iq/'),
('rostering-department-location-allocation','supported',0.990,'ManpowerIQ explicitly plans and allocates manpower across departments and locations.','https://barmageyat.net/manpower-iq/'),
('rostering-work-area-role-allocation','supported',0.980,'ManpowerIQ explicitly supports rotation and allocation across operational areas, terminal zones, equipment types and departments.','https://barmageyat.net/manpower-iq/'),
('rostering-equipment-machine-qualification','supported',0.990,'ManpowerIQ restricts employee assignment according to skills, certifications, licenses and training status and supports allocation across equipment types.','https://barmageyat.net/manpower-iq/'),
('rostering-cross-site-labor-pools','supported',0.990,'ManpowerIQ Cross-Pooling explicitly allows qualified manpower to support other departments or locations during peak operations according to business rules.','https://barmageyat.net/manpower-iq/'),
('rostering-roster-approval-workflow','supported',0.990,'ManpowerIQ explicitly supports department-based approvals, manager approvals, delegation and escalation.','https://barmageyat.net/manpower-iq/'),
('rostering-scheduling-audit-trail','partially_supported',0.960,'ManpowerIQ explicitly documents approval history, but the public material does not establish a complete audit trail for every schedule edit, override and publication event.','https://barmageyat.net/manpower-iq/'),
('rostering-coverage-gap-visibility','partially_supported',0.970,'ManpowerIQ documents leave impact on roster coverage and improved operational visibility, but explicit automated understaffing/overstaffing gap detection is not separately described.','https://barmageyat.net/manpower-iq/'),
('rostering-manpower-status-monitoring','supported',0.990,'ManpowerIQ explicitly monitors manpower across departments, shifts and locations and provides dashboards and reports.','https://barmageyat.net/manpower-iq/'),
('rostering-overtime-labor-cost-analytics','partially_supported',0.970,'ManpowerIQ tracks overtime and is designed to improve overtime cost control, but broader labor-cost modeling and analytics are not separately documented.','https://barmageyat.net/manpower-iq/'),
('rostering-shift-dashboard','supported',0.980,'ManpowerIQ explicitly provides dashboards and reports for workforce-planning visibility.','https://barmageyat.net/manpower-iq/'),
('rostering-multi-location-operations','supported',0.990,'ManpowerIQ explicitly supports workforce planning, allocation and monitoring across locations.','https://barmageyat.net/manpower-iq/'),
('rostering-operations-demand-integration','partially_supported',0.950,'Operational demand is explicitly used by Intelligent Rostering, but the public material does not establish an external TOS, ERP, MES or API integration that supplies that demand.','https://barmageyat.net/manpower-iq/');

INSERT INTO product_capabilities(product_id,capability_id,edition_id,support_status,limitations,confidence_score,last_verified_at)
SELECT @manpoweriq,c.id,NULL,f.support_status,f.limitations,f.confidence,NOW()
FROM cat147_facts f
JOIN capabilities c ON c.slug=f.capability_slug
WHERE @manpoweriq IS NOT NULL
ON DUPLICATE KEY UPDATE
  support_status=VALUES(support_status),
  limitations=VALUES(limitations),
  confidence_score=VALUES(confidence_score),
  last_verified_at=NOW();

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Current public Barmageyat documentation supporting this ManpowerIQ capability status and scope boundary.'
FROM cat147_facts f
JOIN capabilities c ON c.slug=f.capability_slug
JOIN product_capabilities pc ON pc.product_id=@manpoweriq AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=@manpoweriq AND e.source_url=f.source_url;

-- Preserve the explicit related-party disclosure and refresh its source to the public trust statement.
UPDATE product_relationship_disclosures
SET label='Related-party product',
    details='ManpowerIQ is developed by Barmageyat, which operates TechSelectAI. The relationship does not increase Fit Score, Evidence Confidence or ranking position.',
    source_url='https://techselectai.com/trust',
    is_active=1
WHERE product_id=@manpoweriq AND disclosure_type='operator_ownership' AND related_organization='Barmageyat';

COMMIT;
