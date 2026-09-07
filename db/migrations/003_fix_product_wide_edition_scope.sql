BEGIN;

-- Migration 002 intentionally allows product-wide facts by making edition_id
-- optional. A PRIMARY KEY that includes edition_id implicitly makes it NOT NULL,
-- so replace those keys with NULL-safe unique indexes.

ALTER TABLE product_deployment_models DROP CONSTRAINT product_deployment_models_pkey;
ALTER TABLE product_deployment_models ALTER COLUMN edition_id DROP NOT NULL;
CREATE UNIQUE INDEX product_deployment_models_scope_unique
  ON product_deployment_models(product_id, deployment_model_id, COALESCE(edition_id, 0));

ALTER TABLE product_integrations DROP CONSTRAINT product_integrations_pkey;
ALTER TABLE product_integrations ALTER COLUMN edition_id DROP NOT NULL;
CREATE UNIQUE INDEX product_integrations_scope_unique
  ON product_integrations(product_id, integration_id, COALESCE(edition_id, 0));

ALTER TABLE product_compliance_frameworks DROP CONSTRAINT product_compliance_frameworks_pkey;
ALTER TABLE product_compliance_frameworks ALTER COLUMN edition_id DROP NOT NULL;
CREATE UNIQUE INDEX product_compliance_frameworks_scope_unique
  ON product_compliance_frameworks(product_id, compliance_id, COALESCE(edition_id, 0));

COMMIT;
