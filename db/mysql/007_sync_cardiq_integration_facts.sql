-- Keep product_integrations aligned with the canonical CardIQ facts already verified in capability/evidence data.
-- Safe to run after 004-006.
SET NAMES utf8mb4;
START TRANSACTION;

SET @cardiq_id=(SELECT id FROM products WHERE slug='cardiq' LIMIT 1);

INSERT INTO product_integrations(product_id,integration_id,support_status,confidence_score)
SELECT @cardiq_id,i.id,x.support_status,x.confidence_score
FROM integrations i
JOIN (
  SELECT 'microsoft-entra-id' slug,'supported' support_status,0.900 confidence_score
  UNION ALL SELECT 'crm','supported',0.920
  UNION ALL SELECT 'api','supported',0.950
) x ON x.slug=i.slug
WHERE @cardiq_id IS NOT NULL
ON DUPLICATE KEY UPDATE support_status=VALUES(support_status),confidence_score=VALUES(confidence_score);

-- Microsoft 365 remains not_yet_verified until evidence specifically verifies the integration itself.
UPDATE product_integrations pi
JOIN integrations i ON i.id=pi.integration_id
SET pi.support_status='not_yet_verified',pi.confidence_score=0
WHERE pi.product_id=@cardiq_id AND i.slug='microsoft-365' AND pi.support_status<>'supported';

COMMIT;
