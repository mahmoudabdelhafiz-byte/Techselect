-- TechSelectAI strategic category expansion evidence completion.
-- Adds two first-party evidence sources referenced by 081 and backfills their capability links.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation',x.url,x.title,x.publisher,1,'verified','high',NOW()
FROM products p JOIN (
 SELECT 'workato' product_slug,'https://docs.workato.com/en/api-mgmt/api-endpoints' url,'Workato API Endpoints' title,'Workato' publisher UNION ALL
 SELECT 'snaplogic','https://www.snaplogic.com/resources/data-sheets/snaplogic-api-management','SnapLogic API Management Data Sheet','SnapLogic'
) x ON x.product_slug=p.slug
WHERE NOT EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id AND e.source_url=x.url);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,x.note
FROM (
 SELECT 'workato' product_slug,'integration-workflow-orchestration' capability_slug,'https://docs.workato.com/en/api-mgmt/api-endpoints' source_url,'Workato API recipes orchestrate multi-system workflow logic exposed through managed endpoints.' note UNION ALL
 SELECT 'snaplogic','api-monitoring-analytics','https://www.snaplogic.com/resources/data-sheets/snaplogic-api-management','SnapLogic documents low-code API monitoring and dynamic dashboards.'
) x
JOIN products p ON p.slug=x.product_slug
JOIN capabilities c ON c.slug=x.capability_slug
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url=x.source_url;

COMMIT;