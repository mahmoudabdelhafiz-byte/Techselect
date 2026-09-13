-- Completes evidence linkage for the Bitdefender cross-platform endpoint fact introduced in migration 072.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO evidence_sources(product_id,source_type,source_url,source_title,publisher_name,vendor_owned,verification_status,confidence,checked_at)
SELECT p.id,'vendor_documentation','https://www.bitdefender.com/en-us/business/gravityzone-platform/','Bitdefender GravityZone Platform','Bitdefender',1,'verified','high',NOW()
FROM products p
WHERE p.slug='bitdefender-gravityzone-enterprise'
AND NOT EXISTS(
  SELECT 1 FROM evidence_sources e
  WHERE e.product_id=p.id AND e.source_url='https://www.bitdefender.com/en-us/business/gravityzone-platform/'
);

INSERT IGNORE INTO product_capability_evidence(product_capability_id,evidence_source_id,is_primary,evidence_note)
SELECT pc.id,e.id,1,'Official Bitdefender GravityZone platform documentation confirms endpoint support across Windows, macOS and major Linux distributions.'
FROM products p
JOIN capabilities c ON c.slug='endpoint-cross-platform'
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources e ON e.product_id=p.id AND e.source_url='https://www.bitdefender.com/en-us/business/gravityzone-platform/'
WHERE p.slug='bitdefender-gravityzone-enterprise';

COMMIT;
