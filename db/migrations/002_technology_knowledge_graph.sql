BEGIN;

CREATE TYPE product_status AS ENUM ('draft', 'active', 'deprecated', 'archived');
CREATE TYPE capability_support_status AS ENUM (
  'supported',
  'partially_supported',
  'addon',
  'third_party_integration',
  'enterprise_only',
  'plan_dependent',
  'custom_configuration',
  'not_supported',
  'unknown',
  'not_yet_verified'
);
CREATE TYPE evidence_source_type AS ENUM (
  'vendor_documentation',
  'pricing_page',
  'security_documentation',
  'product_documentation',
  'vendor_submitted',
  'independent_verification',
  'partner_documentation',
  'other'
);
CREATE TYPE evidence_verification_status AS ENUM ('unverified', 'verified', 'stale', 'disputed', 'rejected');
CREATE TYPE confidence_level AS ENUM ('low', 'medium', 'high');
CREATE TYPE pricing_model_type AS ENUM (
  'free', 'freemium', 'per_user', 'per_company', 'usage_based', 'flat_rate',
  'one_time', 'custom_quote', 'open_source', 'unknown'
);
CREATE TYPE billing_period_type AS ENUM ('monthly', 'annual', 'one_time', 'usage', 'custom', 'unknown');
CREATE TYPE relationship_requirement_level AS ENUM ('supported', 'preferred', 'primary');

-- Vendors and richer product identity.
CREATE TABLE vendors (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  website_url text,
  headquarters_country_id bigint REFERENCES countries(id) ON DELETE SET NULL,
  description text,
  status product_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX vendors_name_unique_ci ON vendors (lower(name));

ALTER TABLE categories ADD COLUMN slug text;
ALTER TABLE categories ADD COLUMN description text;
ALTER TABLE categories ADD COLUMN is_active boolean NOT NULL DEFAULT true;
UPDATE categories SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE categories ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX categories_slug_unique ON categories(slug);

ALTER TABLE modules ADD COLUMN slug text;
ALTER TABLE modules ADD COLUMN description text;
ALTER TABLE modules ADD COLUMN is_active boolean NOT NULL DEFAULT true;
UPDATE modules SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE modules ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX modules_category_slug_unique ON modules(category_id, slug);

ALTER TABLE capabilities ADD COLUMN slug text;
ALTER TABLE capabilities ADD COLUMN description text;
ALTER TABLE capabilities ADD COLUMN capability_group text;
ALTER TABLE capabilities ADD COLUMN is_security_related boolean NOT NULL DEFAULT false;
ALTER TABLE capabilities ADD COLUMN is_active boolean NOT NULL DEFAULT true;
UPDATE capabilities SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE capabilities ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX capabilities_module_slug_unique ON capabilities(module_id, slug);

ALTER TABLE integrations ADD COLUMN slug text;
ALTER TABLE integrations ADD COLUMN vendor_name text;
ALTER TABLE integrations ADD COLUMN description text;
UPDATE integrations SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE integrations ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX integrations_slug_unique ON integrations(slug);

ALTER TABLE deployment_models ADD COLUMN slug text;
ALTER TABLE deployment_models ADD COLUMN description text;
UPDATE deployment_models SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE deployment_models ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX deployment_models_slug_unique ON deployment_models(slug);

ALTER TABLE compliance_frameworks ADD COLUMN slug text;
ALTER TABLE compliance_frameworks ADD COLUMN description text;
UPDATE compliance_frameworks SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE compliance_frameworks ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX compliance_frameworks_slug_unique ON compliance_frameworks(slug);

ALTER TABLE industries ADD COLUMN slug text;
UPDATE industries SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE industries ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX industries_slug_unique ON industries(slug);

ALTER TABLE products ADD COLUMN vendor_id bigint REFERENCES vendors(id) ON DELETE SET NULL;
ALTER TABLE products ADD COLUMN slug text;
ALTER TABLE products ADD COLUMN short_description text;
ALTER TABLE products ADD COLUMN website_url text;
ALTER TABLE products ADD COLUMN status product_status NOT NULL DEFAULT 'active';
ALTER TABLE products ADD COLUMN min_company_size integer CHECK (min_company_size IS NULL OR min_company_size >= 0);
ALTER TABLE products ADD COLUMN max_company_size integer CHECK (max_company_size IS NULL OR max_company_size >= 0);
ALTER TABLE products ADD COLUMN is_open_source boolean NOT NULL DEFAULT false;
ALTER TABLE products ADD COLUMN last_reviewed_at timestamptz;
ALTER TABLE products ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE products ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();
UPDATE products SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE products ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX products_slug_unique ON products(slug);
ALTER TABLE products ADD CONSTRAINT product_company_size_valid CHECK (
  min_company_size IS NULL OR max_company_size IS NULL OR min_company_size <= max_company_size
);

-- Preserve products.category_id for backward compatibility while enabling multiple categories.
CREATE TABLE product_categories (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  category_id bigint NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (product_id, category_id)
);
INSERT INTO product_categories (product_id, category_id, is_primary)
SELECT id, category_id, true FROM products WHERE category_id IS NOT NULL
ON CONFLICT DO NOTHING;

CREATE TABLE product_modules (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  module_id bigint NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  is_core boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (product_id, module_id)
);

ALTER TABLE product_editions ADD COLUMN slug text;
ALTER TABLE product_editions ADD COLUMN description text;
ALTER TABLE product_editions ADD COLUMN status product_status NOT NULL DEFAULT 'active';
ALTER TABLE product_editions ADD COLUMN sort_order integer NOT NULL DEFAULT 0;
ALTER TABLE product_editions ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE product_editions ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();
UPDATE product_editions SET slug = lower(regexp_replace(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')) WHERE slug IS NULL;
ALTER TABLE product_editions ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX product_editions_product_slug_unique ON product_editions(product_id, slug);

CREATE TABLE product_pricing (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  edition_id bigint REFERENCES product_editions(id) ON DELETE CASCADE,
  pricing_model pricing_model_type NOT NULL,
  billing_period billing_period_type NOT NULL DEFAULT 'unknown',
  currency char(3),
  amount_min numeric(14,2) CHECK (amount_min IS NULL OR amount_min >= 0),
  amount_max numeric(14,2) CHECK (amount_max IS NULL OR amount_max >= 0),
  unit_label text,
  minimum_users integer CHECK (minimum_users IS NULL OR minimum_users >= 0),
  maximum_users integer CHECK (maximum_users IS NULL OR maximum_users >= 0),
  notes text,
  source_url text,
  valid_from date,
  last_verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT product_pricing_amount_valid CHECK (amount_min IS NULL OR amount_max IS NULL OR amount_min <= amount_max),
  CONSTRAINT product_pricing_users_valid CHECK (minimum_users IS NULL OR maximum_users IS NULL OR minimum_users <= maximum_users)
);
CREATE INDEX product_pricing_product_idx ON product_pricing(product_id, edition_id);

CREATE TABLE product_deployment_models (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  edition_id bigint REFERENCES product_editions(id) ON DELETE CASCADE,
  deployment_model_id bigint NOT NULL REFERENCES deployment_models(id),
  notes text,
  PRIMARY KEY (product_id, deployment_model_id, edition_id)
);

CREATE TABLE product_integrations (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  integration_id bigint NOT NULL REFERENCES integrations(id),
  edition_id bigint REFERENCES product_editions(id) ON DELETE CASCADE,
  support_status capability_support_status NOT NULL DEFAULT 'not_yet_verified',
  notes text,
  last_verified_at timestamptz,
  PRIMARY KEY (product_id, integration_id, edition_id)
);

CREATE TABLE product_countries (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  country_id bigint NOT NULL REFERENCES countries(id),
  relationship_level relationship_requirement_level NOT NULL DEFAULT 'supported',
  notes text,
  PRIMARY KEY (product_id, country_id)
);

CREATE TABLE product_languages (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  language_id bigint NOT NULL REFERENCES languages(id),
  ui_supported boolean NOT NULL DEFAULT false,
  documentation_supported boolean NOT NULL DEFAULT false,
  support_team_supported boolean NOT NULL DEFAULT false,
  notes text,
  PRIMARY KEY (product_id, language_id)
);

CREATE TABLE product_industries (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  industry_id bigint NOT NULL REFERENCES industries(id),
  relationship_level relationship_requirement_level NOT NULL DEFAULT 'supported',
  notes text,
  PRIMARY KEY (product_id, industry_id)
);

CREATE TABLE product_compliance_frameworks (
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  compliance_id bigint NOT NULL REFERENCES compliance_frameworks(id),
  edition_id bigint REFERENCES product_editions(id) ON DELETE CASCADE,
  support_status capability_support_status NOT NULL DEFAULT 'not_yet_verified',
  notes text,
  last_verified_at timestamptz,
  PRIMARY KEY (product_id, compliance_id, edition_id)
);

-- Capability support is a fact that may be product-wide or edition-specific.
CREATE TABLE product_capabilities (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  capability_id bigint NOT NULL REFERENCES capabilities(id),
  edition_id bigint REFERENCES product_editions(id) ON DELETE CASCADE,
  support_status capability_support_status NOT NULL DEFAULT 'not_yet_verified',
  implementation_type text,
  limitations text,
  configuration_notes text,
  confidence_score numeric(4,3) CHECK (confidence_score BETWEEN 0 AND 1),
  last_verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX product_capabilities_product_capability_edition_unique
  ON product_capabilities(product_id, capability_id, COALESCE(edition_id, 0));
CREATE INDEX product_capabilities_lookup_idx
  ON product_capabilities(capability_id, support_status, product_id);
CREATE INDEX product_capabilities_product_idx
  ON product_capabilities(product_id, support_status);

CREATE TABLE evidence_sources (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  source_type evidence_source_type NOT NULL,
  source_url text,
  source_title text NOT NULL,
  publisher_name text,
  vendor_owned boolean NOT NULL DEFAULT false,
  published_at timestamptz,
  checked_at timestamptz NOT NULL DEFAULT now(),
  verification_status evidence_verification_status NOT NULL DEFAULT 'unverified',
  confidence confidence_level NOT NULL DEFAULT 'medium',
  notes text,
  content_fingerprint text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX evidence_sources_product_status_idx ON evidence_sources(product_id, verification_status, checked_at DESC);
CREATE INDEX evidence_sources_checked_at_idx ON evidence_sources(checked_at DESC);

CREATE TABLE product_capability_evidence (
  product_capability_id bigint NOT NULL REFERENCES product_capabilities(id) ON DELETE CASCADE,
  evidence_source_id bigint NOT NULL REFERENCES evidence_sources(id) ON DELETE CASCADE,
  is_primary boolean NOT NULL DEFAULT false,
  evidence_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (product_capability_id, evidence_source_id)
);

CREATE TABLE verification_history (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  product_capability_id bigint REFERENCES product_capabilities(id) ON DELETE SET NULL,
  evidence_source_id bigint REFERENCES evidence_sources(id) ON DELETE SET NULL,
  previous_status capability_support_status,
  new_status capability_support_status,
  verification_status evidence_verification_status NOT NULL,
  confidence confidence_level,
  verified_by_user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  reason text,
  verified_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT verification_history_status_change CHECK (
    product_capability_id IS NULL OR previous_status IS DISTINCT FROM new_status OR reason IS NOT NULL
  )
);
CREATE INDEX verification_history_product_idx ON verification_history(product_id, verified_at DESC);
CREATE INDEX verification_history_capability_idx ON verification_history(product_capability_id, verified_at DESC);

-- Evidence freshness helpers used by matching, admin review and public trust indicators.
CREATE VIEW product_capability_evidence_summary AS
SELECT
  pc.id AS product_capability_id,
  pc.product_id,
  pc.capability_id,
  pc.edition_id,
  pc.support_status,
  pc.confidence_score,
  pc.last_verified_at,
  count(pce.evidence_source_id) AS evidence_count,
  count(*) FILTER (WHERE es.verification_status = 'verified') AS verified_evidence_count,
  max(es.checked_at) AS latest_evidence_check,
  CASE
    WHEN pc.last_verified_at IS NULL THEN 'unverified'
    WHEN pc.last_verified_at < now() - interval '365 days' THEN 'stale'
    WHEN count(*) FILTER (WHERE es.verification_status = 'verified') = 0 THEN 'unverified'
    ELSE 'current'
  END AS freshness_status
FROM product_capabilities pc
LEFT JOIN product_capability_evidence pce ON pce.product_capability_id = pc.id
LEFT JOIN evidence_sources es ON es.id = pce.evidence_source_id
GROUP BY pc.id;

CREATE VIEW product_knowledge_coverage AS
SELECT
  p.id AS product_id,
  p.name AS product_name,
  count(pc.id) AS capability_fact_count,
  count(pc.id) FILTER (WHERE pc.support_status NOT IN ('unknown', 'not_yet_verified')) AS verified_or_explicit_capability_count,
  count(pc.id) FILTER (WHERE pc.last_verified_at >= now() - interval '365 days') AS recently_verified_capability_count,
  CASE
    WHEN count(pc.id) = 0 THEN 0::numeric
    ELSE round(100.0 * count(pc.id) FILTER (WHERE pc.last_verified_at >= now() - interval '365 days') / count(pc.id), 2)
  END AS freshness_coverage_pct
FROM products p
LEFT JOIN product_capabilities pc ON pc.product_id = p.id
GROUP BY p.id, p.name;

COMMIT;
