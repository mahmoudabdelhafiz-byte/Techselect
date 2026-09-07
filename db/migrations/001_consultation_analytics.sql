BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('user', 'consultant', 'admin', 'super_admin');
CREATE TYPE user_status AS ENUM ('pending', 'active', 'suspended', 'disabled');
CREATE TYPE consultation_status AS ENUM ('draft', 'in_progress', 'requirements_review', 'analysis', 'completed', 'archived');
CREATE TYPE consultation_source AS ENUM ('ai_chat', 'guided_wizard', 'manual', 'admin');
CREATE TYPE requirement_priority AS ENUM ('must_have', 'important', 'nice_to_have');
CREATE TYPE requirement_source AS ENUM ('wizard', 'ai_extracted', 'user_added', 'consultant_added', 'admin');
CREATE TYPE deployment_preference_type AS ENUM ('required', 'preferred', 'acceptable', 'excluded');
CREATE TYPE country_requirement_type AS ENUM ('headquarters', 'operating_country', 'must_support');
CREATE TYPE message_sender_type AS ENUM ('user', 'assistant', 'system', 'consultant');
CREATE TYPE consultation_message_type AS ENUM ('normal', 'question', 'requirement_summary', 'recommendation', 'warning');
CREATE TYPE recommendation_status AS ENUM ('recommended', 'strong_match', 'possible_match', 'conditional', 'excluded');
CREATE TYPE recommendation_gap_type AS ENUM ('unsupported', 'partial', 'unknown', 'plan_restriction', 'integration_required', 'budget_gap', 'regional_gap', 'deployment_gap');
CREATE TYPE gap_severity AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE analytics_event_type AS ENUM (
  'page_view', 'search_performed', 'category_viewed', 'module_viewed',
  'capability_viewed', 'product_viewed', 'comparison_started',
  'product_added_to_compare', 'comparison_completed', 'consultation_started',
  'consultation_message_sent', 'consultation_requirement_added',
  'consultation_requirement_confirmed', 'consultation_step_completed',
  'consultation_abandoned', 'consultation_completed', 'recommendations_generated',
  'recommendation_viewed', 'recommendation_product_clicked',
  'vendor_website_clicked', 'account_created', 'consultation_saved',
  'report_downloaded', 'vendor_contact_requested',
  'expert_consultation_requested', 'sponsored_impression', 'sponsored_click',
  'affiliate_click'
);

-- Minimal dimensions referenced by consultation and analytics facts.
CREATE TABLE countries (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, code char(2) NOT NULL UNIQUE, name text NOT NULL);
CREATE TABLE industries (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE categories (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE modules (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, category_id bigint REFERENCES categories(id), name text NOT NULL);
CREATE TABLE capabilities (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, module_id bigint REFERENCES modules(id), name text NOT NULL);
CREATE TABLE integrations (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE deployment_models (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE compliance_frameworks (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE languages (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, code varchar(12) NOT NULL UNIQUE, name text NOT NULL);
CREATE TABLE products (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, category_id bigint REFERENCES categories(id), name text NOT NULL);
CREATE TABLE product_editions (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE, name text NOT NULL, UNIQUE (product_id, name));

CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email text NOT NULL,
  password_hash text NOT NULL,
  full_name text NOT NULL,
  company_id bigint,
  role user_role NOT NULL DEFAULT 'user',
  status user_status NOT NULL DEFAULT 'pending',
  email_verified_at timestamptz,
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_email_unique_ci ON users (lower(email));

CREATE TABLE visitor_sessions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_token_hash bytea NOT NULL UNIQUE,
  user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  country_code char(2),
  utm_source text,
  utm_medium text,
  utm_campaign text,
  referrer text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT visitor_session_times_valid CHECK (last_seen_at >= first_seen_at)
);
COMMENT ON COLUMN visitor_sessions.session_token_hash IS 'SHA-256 digest only; never persist the bearer token.';

CREATE TABLE companies (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  company_name text,
  country_id bigint NOT NULL REFERENCES countries(id),
  industry_id bigint NOT NULL REFERENCES industries(id),
  employee_count_min integer CHECK (employee_count_min >= 0),
  employee_count_max integer CHECK (employee_count_max >= 0),
  expected_software_users integer CHECK (expected_software_users >= 0),
  branch_count integer CHECK (branch_count >= 0),
  annual_revenue_range text,
  business_type text,
  current_technology_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT employee_range_valid CHECK (employee_count_min IS NULL OR employee_count_max IS NULL OR employee_count_min <= employee_count_max)
);
ALTER TABLE users ADD CONSTRAINT users_company_fk FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;

CREATE TABLE consultations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_uuid uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  visitor_session_id bigint REFERENCES visitor_sessions(id) ON DELETE SET NULL,
  user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  company_id bigint REFERENCES companies(id) ON DELETE SET NULL,
  title text,
  category_id bigint REFERENCES categories(id) ON DELETE SET NULL,
  business_problem text NOT NULL,
  original_user_request text,
  budget_min numeric(14,2) CHECK (budget_min >= 0),
  budget_max numeric(14,2) CHECK (budget_max >= 0),
  budget_currency char(3),
  budget_period text,
  implementation_timeline text,
  preferred_deployment text,
  status consultation_status NOT NULL DEFAULT 'draft',
  consultation_source consultation_source NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT consultation_owner_present CHECK (visitor_session_id IS NOT NULL OR user_id IS NOT NULL),
  CONSTRAINT consultation_budget_valid CHECK (budget_min IS NULL OR budget_max IS NULL OR budget_min <= budget_max),
  CONSTRAINT consultation_completion_valid CHECK ((status = 'completed' AND completed_at IS NOT NULL) OR status <> 'completed'),
  CONSTRAINT consultation_times_valid CHECK (completed_at IS NULL OR completed_at >= started_at)
);

CREATE TABLE consultation_requirements (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  capability_id bigint REFERENCES capabilities(id) ON DELETE SET NULL,
  requirement_text text NOT NULL,
  normalized_requirement text,
  priority requirement_priority NOT NULL,
  is_mandatory boolean NOT NULL DEFAULT false,
  source requirement_source NOT NULL,
  confidence_score numeric(4,3) CHECK (confidence_score BETWEEN 0 AND 1),
  user_confirmed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT must_have_is_mandatory CHECK (priority <> 'must_have' OR is_mandatory)
);

CREATE TABLE consultation_integrations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  integration_id bigint NOT NULL REFERENCES integrations(id),
  priority requirement_priority NOT NULL,
  is_mandatory boolean NOT NULL DEFAULT false,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (consultation_id, integration_id)
);
CREATE TABLE consultation_deployment_preferences (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  deployment_model_id bigint NOT NULL REFERENCES deployment_models(id),
  preference_type deployment_preference_type NOT NULL,
  priority requirement_priority NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (consultation_id, deployment_model_id)
);
CREATE TABLE consultation_compliance_requirements (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  compliance_id bigint NOT NULL REFERENCES compliance_frameworks(id),
  priority requirement_priority NOT NULL,
  is_mandatory boolean NOT NULL DEFAULT false,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (consultation_id, compliance_id)
);
CREATE TABLE consultation_countries (
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  country_id bigint NOT NULL REFERENCES countries(id),
  requirement_type country_requirement_type NOT NULL,
  PRIMARY KEY (consultation_id, country_id, requirement_type)
);
CREATE TABLE consultation_languages (
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  language_id bigint NOT NULL REFERENCES languages(id),
  priority requirement_priority NOT NULL,
  is_mandatory boolean NOT NULL DEFAULT false,
  PRIMARY KEY (consultation_id, language_id)
);

CREATE TABLE consultation_messages (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  sender_type message_sender_type NOT NULL,
  message_text text NOT NULL,
  message_type consultation_message_type NOT NULL DEFAULT 'normal',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE consultation_recommendations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id),
  edition_id bigint REFERENCES product_editions(id),
  recommendation_rank integer NOT NULL CHECK (recommendation_rank > 0),
  overall_score numeric(5,2) NOT NULL CHECK (overall_score BETWEEN 0 AND 100),
  functional_score numeric(5,2) NOT NULL CHECK (functional_score BETWEEN 0 AND 100),
  mandatory_score numeric(5,2) NOT NULL CHECK (mandatory_score BETWEEN 0 AND 100),
  integration_score numeric(5,2) NOT NULL CHECK (integration_score BETWEEN 0 AND 100),
  deployment_score numeric(5,2) NOT NULL CHECK (deployment_score BETWEEN 0 AND 100),
  budget_score numeric(5,2) NOT NULL CHECK (budget_score BETWEEN 0 AND 100),
  regional_score numeric(5,2) NOT NULL CHECK (regional_score BETWEEN 0 AND 100),
  security_score numeric(5,2) NOT NULL CHECK (security_score BETWEEN 0 AND 100),
  evidence_score numeric(5,2) NOT NULL CHECK (evidence_score BETWEEN 0 AND 100),
  mandatory_gap_count integer NOT NULL DEFAULT 0 CHECK (mandatory_gap_count >= 0),
  important_gap_count integer NOT NULL DEFAULT 0 CHECK (important_gap_count >= 0),
  recommendation_status recommendation_status NOT NULL,
  generated_at timestamptz NOT NULL DEFAULT now(),
  scoring_version text NOT NULL,
  UNIQUE (consultation_id, product_id, edition_id, scoring_version),
  UNIQUE (consultation_id, recommendation_rank, scoring_version),
  CONSTRAINT excluded_mandatory_gap CHECK (mandatory_gap_count = 0 OR recommendation_status IN ('conditional', 'excluded'))
);
CREATE TABLE recommendation_gaps (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  recommendation_id bigint NOT NULL REFERENCES consultation_recommendations(id) ON DELETE CASCADE,
  consultation_requirement_id bigint REFERENCES consultation_requirements(id) ON DELETE SET NULL,
  gap_type recommendation_gap_type NOT NULL,
  severity gap_severity NOT NULL,
  explanation text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE analytics_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  visitor_session_id bigint REFERENCES visitor_sessions(id) ON DELETE SET NULL,
  user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  consultation_id bigint REFERENCES consultations(id) ON DELETE SET NULL,
  event_type analytics_event_type NOT NULL,
  category_id bigint REFERENCES categories(id) ON DELETE SET NULL,
  product_id bigint REFERENCES products(id) ON DELETE SET NULL,
  module_id bigint REFERENCES modules(id) ON DELETE SET NULL,
  capability_id bigint REFERENCES capabilities(id) ON DELETE SET NULL,
  integration_id bigint REFERENCES integrations(id) ON DELETE SET NULL,
  metadata_json jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT analytics_actor_present CHECK (visitor_session_id IS NOT NULL OR user_id IS NOT NULL),
  CONSTRAINT analytics_metadata_object CHECK (metadata_json IS NULL OR jsonb_typeof(metadata_json) = 'object')
);
CREATE TABLE search_logs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  visitor_session_id bigint REFERENCES visitor_sessions(id) ON DELETE SET NULL,
  user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  search_text text NOT NULL,
  normalized_query text NOT NULL,
  detected_category_id bigint REFERENCES categories(id) ON DELETE SET NULL,
  detected_intent text,
  result_count integer NOT NULL CHECK (result_count >= 0),
  selected_product_id bigint REFERENCES products(id) ON DELETE SET NULL,
  selected_category_id bigint REFERENCES categories(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT search_actor_present CHECK (visitor_session_id IS NOT NULL OR user_id IS NOT NULL)
);

CREATE TABLE data_retention_policies (
  record_type text PRIMARY KEY,
  retention_days integer NOT NULL CHECK (retention_days > 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE sensitive_record_access_logs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_user_id bigint NOT NULL REFERENCES users(id),
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  access_reason text NOT NULL,
  accessed_at timestamptz NOT NULL DEFAULT now()
);
REVOKE ALL ON sensitive_record_access_logs FROM PUBLIC;

CREATE INDEX visitor_sessions_user_idx ON visitor_sessions (user_id);
CREATE INDEX consultations_visitor_idx ON consultations (visitor_session_id);
CREATE INDEX consultations_user_idx ON consultations (user_id);
CREATE INDEX consultations_category_status_idx ON consultations (category_id, status);
CREATE INDEX consultations_started_idx ON consultations (started_at);
CREATE INDEX consultation_requirements_consultation_idx ON consultation_requirements (consultation_id);
CREATE INDEX consultation_requirements_capability_idx ON consultation_requirements (capability_id, is_mandatory);
CREATE INDEX consultation_messages_timeline_idx ON consultation_messages (consultation_id, created_at);
CREATE INDEX recommendations_product_idx ON consultation_recommendations (product_id, generated_at);
CREATE INDEX recommendation_gaps_type_idx ON recommendation_gaps (gap_type, severity);
CREATE INDEX analytics_events_created_type_idx ON analytics_events (created_at, event_type);
CREATE INDEX analytics_events_consultation_idx ON analytics_events (consultation_id, created_at);
CREATE INDEX analytics_events_product_idx ON analytics_events (product_id, event_type);
CREATE INDEX search_logs_created_idx ON search_logs (created_at);
CREATE INDEX search_logs_normalized_idx ON search_logs (normalized_query, created_at);

-- Claims an anonymous journey after registration without overwriting an existing owner.
CREATE FUNCTION link_visitor_session_to_user(p_session_token text, p_user_id bigint)
RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE v_session_id bigint;
BEGIN
  SELECT id INTO v_session_id
  FROM visitor_sessions
  WHERE session_token_hash = digest(p_session_token, 'sha256') AND user_id IS NULL
  FOR UPDATE;
  IF v_session_id IS NULL THEN RAISE EXCEPTION 'unclaimed visitor session not found'; END IF;
  UPDATE visitor_sessions SET user_id = p_user_id, last_seen_at = now() WHERE id = v_session_id;
  UPDATE consultations SET user_id = p_user_id, updated_at = now() WHERE visitor_session_id = v_session_id AND user_id IS NULL;
  UPDATE analytics_events SET user_id = p_user_id WHERE visitor_session_id = v_session_id AND user_id IS NULL;
  UPDATE search_logs SET user_id = p_user_id WHERE visitor_session_id = v_session_id AND user_id IS NULL;
  RETURN v_session_id;
END $$;

-- Aggregated operational views deliberately omit names, messages, and raw requests.
CREATE VIEW analytics_overview_daily AS
SELECT date_trunc('day', created_at)::date AS activity_date,
       count(DISTINCT visitor_session_id) AS visitors,
       count(*) FILTER (WHERE event_type = 'search_performed') AS searches,
       count(*) FILTER (WHERE event_type = 'consultation_started') AS consultations_started,
       count(*) FILTER (WHERE event_type = 'consultation_completed') AS consultations_completed,
       round(100.0 * count(*) FILTER (WHERE event_type = 'consultation_completed') /
             NULLIF(count(*) FILTER (WHERE event_type = 'consultation_started'), 0), 2) AS completion_rate,
       count(*) FILTER (WHERE event_type = 'recommendation_viewed') AS recommendation_views,
       count(*) FILTER (WHERE event_type = 'vendor_website_clicked') AS vendor_clicks,
       count(*) FILTER (WHERE event_type = 'account_created') AS new_registered_users
FROM analytics_events GROUP BY 1;

CREATE VIEW search_intelligence_daily AS
SELECT date_trunc('day', created_at)::date AS activity_date, normalized_query,
       count(*) AS search_count,
       count(*) FILTER (WHERE result_count = 0) AS zero_result_count,
       count(*) FILTER (WHERE selected_product_id IS NOT NULL OR selected_category_id IS NOT NULL) AS selection_count
FROM search_logs GROUP BY 1, 2;

CREATE VIEW consultation_funnel_daily AS
SELECT date_trunc('day', created_at)::date AS activity_date, event_type,
       count(*) AS event_count, count(DISTINCT consultation_id) AS consultations,
       count(*) FILTER (WHERE user_id IS NULL) AS anonymous_events,
       count(*) FILTER (WHERE user_id IS NOT NULL) AS registered_events
FROM analytics_events
WHERE event_type IN ('consultation_started', 'consultation_step_completed', 'recommendations_generated',
                     'recommendation_viewed', 'vendor_website_clicked', 'consultation_saved',
                     'consultation_abandoned', 'consultation_completed')
GROUP BY 1, 2;

CREATE VIEW requirement_intelligence AS
SELECT capability_id, priority, is_mandatory, count(*) AS request_count
FROM consultation_requirements GROUP BY capability_id, priority, is_mandatory;

CREATE VIEW product_intelligence AS
SELECT p.id AS product_id, p.name,
       count(DISTINCT r.id) AS recommendation_count,
       round(avg(r.overall_score), 2) AS average_recommendation_score,
       count(DISTINCT r.id) FILTER (WHERE r.recommendation_status = 'excluded') AS exclusion_count,
       count(DISTINCT g.id) AS recorded_gap_count
FROM products p
LEFT JOIN consultation_recommendations r ON r.product_id = p.id
LEFT JOIN recommendation_gaps g ON g.recommendation_id = r.id
GROUP BY p.id, p.name;

COMMIT;
