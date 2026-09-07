BEGIN;

INSERT INTO deployment_models (name, slug, description)
VALUES
  ('Managed SaaS','managed-saas','Vendor-managed public SaaS deployment.'),
  ('Dedicated Cloud','dedicated-cloud','Dedicated or isolated cloud arrangement subject to vendor scope.'),
  ('Self-Hosted','self-hosted','Customer-controlled hosting or self-hosted deployment.')
ON CONFLICT (slug) DO UPDATE SET description=EXCLUDED.description;

-- Add evidence used by deployment and explicit-gap facts.
INSERT INTO evidence_sources (product_id, source_type, source_url, source_title, publisher_name, vendor_owned, verification_status, confidence, checked_at)
SELECT p.id, 'vendor_documentation', e.url, e.title, e.publisher, true, 'verified', 'high', now()
FROM (VALUES
  ('cardiq','https://card-iq.net/cardiq_deployment_options.php','CardIQ Deployment Options','CardIQ'),
  ('cardiq','https://card-iq.net/evaluate_cardiq_enterprise.php?lang=en','Evaluate CardIQ for Enterprise Identity Control','CardIQ'),
  ('cardiq','https://card-iq.net/trust_architecture.php','CardIQ Trust Architecture','CardIQ'),
  ('blinq','https://blinq.me/solutions/digital-business-card','Blinq Digital Business Card','Blinq')
) AS e(product_slug,url,title,publisher)
JOIN products p ON p.slug=e.product_slug
WHERE NOT EXISTS (
  SELECT 1 FROM evidence_sources es WHERE es.product_id=p.id AND es.source_url=e.url
);

-- Product-wide deployment facts. Enterprise-scoped availability is preserved in notes.
INSERT INTO product_deployment_models (product_id, deployment_model_id, notes)
SELECT p.id, dm.id, x.notes
FROM (VALUES
  ('cardiq','managed-saas','Available as the standard managed service.'),
  ('cardiq','dedicated-cloud','Available only where offered and contracted through enterprise scoping.'),
  ('cardiq','self-hosted','Available only where offered and contracted through enterprise scoping.'),
  ('blinq','managed-saas','Vendor-managed cloud service based on current enterprise materials.'),
  ('hihello','managed-saas','Vendor-managed cloud service based on current enterprise materials.')
) AS x(product_slug,deployment_slug,notes)
JOIN products p ON p.slug=x.product_slug
JOIN deployment_models dm ON dm.slug=x.deployment_slug
WHERE NOT EXISTS (
  SELECT 1 FROM product_deployment_models pdm
  WHERE pdm.product_id=p.id AND pdm.deployment_model_id=dm.id AND pdm.edition_id IS NULL
);

-- CardIQ current enterprise documentation explicitly says native SCIM and native
-- Entra provisioning are not currently supported. Store these as explicit gaps,
-- not as unknowns, so recommendations remain candid and explainable.
UPDATE product_capabilities pc
SET support_status='not_supported',
    confidence_score=0.99,
    last_verified_at=now(),
    limitations='Current public enterprise documentation states native provisioning is not currently supported.',
    updated_at=now()
FROM products p, capabilities c
WHERE pc.product_id=p.id
  AND pc.capability_id=c.id
  AND pc.edition_id IS NULL
  AND p.slug='cardiq'
  AND c.slug IN ('scim','entra-id-integration');

-- CardIQ Verification Hub communication-channel verification is a current,
-- company-scoped public capability with explicit privacy boundaries.
UPDATE product_capabilities pc
SET support_status='supported',
    confidence_score=0.98,
    last_verified_at=now(),
    limitations='Company-scoped verification only; no reverse lookup and a not-verified result is not a fraud verdict.',
    updated_at=now()
FROM products p, capabilities c
WHERE pc.product_id=p.id
  AND pc.capability_id=c.id
  AND pc.edition_id IS NULL
  AND p.slug='cardiq'
  AND c.slug='communication-channel-verification';

INSERT INTO product_capability_evidence (product_capability_id, evidence_source_id, is_primary, evidence_note)
SELECT pc.id, es.id, true,
       CASE c.slug
         WHEN 'scim' THEN 'Current enterprise evaluation documentation states native SCIM provisioning is not currently supported.'
         WHEN 'entra-id-integration' THEN 'Current enterprise evaluation documentation states native Entra ID provisioning is not currently supported.'
         WHEN 'communication-channel-verification' THEN 'Trust architecture documents company-scoped checks for approved email, phone, WhatsApp, landline and trusted-domain records.'
       END
FROM products p
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.edition_id IS NULL
JOIN capabilities c ON c.id=pc.capability_id
JOIN evidence_sources es ON es.product_id=p.id
  AND es.source_url = CASE
    WHEN c.slug IN ('scim','entra-id-integration') THEN 'https://card-iq.net/evaluate_cardiq_enterprise.php?lang=en'
    WHEN c.slug='communication-channel-verification' THEN 'https://card-iq.net/trust_architecture.php'
  END
WHERE p.slug='cardiq'
  AND c.slug IN ('scim','entra-id-integration','communication-channel-verification')
ON CONFLICT (product_capability_id, evidence_source_id)
DO UPDATE SET is_primary=true, evidence_note=EXCLUDED.evidence_note;

-- Backfill the Blinq meeting-background source referenced by migration 003.
INSERT INTO product_capability_evidence (product_capability_id, evidence_source_id, is_primary)
SELECT pc.id, es.id, true
FROM products p
JOIN capabilities c ON c.slug='meeting-backgrounds'
JOIN product_capabilities pc ON pc.product_id=p.id AND pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN evidence_sources es ON es.product_id=p.id AND es.source_url='https://blinq.me/solutions/digital-business-card'
WHERE p.slug='blinq'
ON CONFLICT (product_capability_id, evidence_source_id) DO UPDATE SET is_primary=true;

COMMIT;
