BEGIN;

CREATE TYPE ai_extraction_status AS ENUM ('pending','accepted','rejected','superseded');
CREATE TYPE ai_question_status AS ENUM ('open','answered','skipped','cancelled');
CREATE TYPE ai_field_kind AS ENUM ('company','category','capability','integration','deployment','compliance','country','language','budget','timeline','free_text');

CREATE TABLE ai_extraction_runs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  source_message_id bigint REFERENCES consultation_messages(id) ON DELETE SET NULL,
  model_provider text,
  model_name text,
  prompt_version text NOT NULL,
  status ai_extraction_status NOT NULL DEFAULT 'pending',
  raw_output jsonb NOT NULL,
  confidence_score numeric(4,3) CHECK (confidence_score BETWEEN 0 AND 1),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by_user_id bigint REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT ai_extraction_raw_output_object CHECK (jsonb_typeof(raw_output)='object')
);
CREATE INDEX ai_extraction_runs_consultation_idx ON ai_extraction_runs(consultation_id, created_at DESC);

CREATE TABLE ai_extracted_fields (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  extraction_run_id bigint NOT NULL REFERENCES ai_extraction_runs(id) ON DELETE CASCADE,
  field_kind ai_field_kind NOT NULL,
  field_key text NOT NULL,
  normalized_value jsonb NOT NULL,
  source_text text,
  confidence_score numeric(4,3) CHECK (confidence_score BETWEEN 0 AND 1),
  requires_confirmation boolean NOT NULL DEFAULT true,
  accepted_at timestamptz,
  rejected_at timestamptz,
  CONSTRAINT ai_extracted_value_not_null CHECK (jsonb_typeof(normalized_value) IS NOT NULL),
  CONSTRAINT ai_extracted_accept_reject_exclusive CHECK (accepted_at IS NULL OR rejected_at IS NULL)
);
CREATE INDEX ai_extracted_fields_run_idx ON ai_extracted_fields(extraction_run_id, field_kind);

CREATE TABLE ai_follow_up_questions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id bigint NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  extraction_run_id bigint REFERENCES ai_extraction_runs(id) ON DELETE SET NULL,
  question_key text NOT NULL,
  question_text text NOT NULL,
  reason text NOT NULL,
  field_kind ai_field_kind NOT NULL,
  priority integer NOT NULL DEFAULT 100,
  status ai_question_status NOT NULL DEFAULT 'open',
  asked_message_id bigint REFERENCES consultation_messages(id) ON DELETE SET NULL,
  answered_message_id bigint REFERENCES consultation_messages(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  answered_at timestamptz,
  UNIQUE (consultation_id, question_key, status)
);
CREATE INDEX ai_follow_up_questions_open_idx ON ai_follow_up_questions(consultation_id, priority, created_at) WHERE status='open';

CREATE TABLE consultation_ai_state (
  consultation_id bigint PRIMARY KEY REFERENCES consultations(id) ON DELETE CASCADE,
  prompt_version text NOT NULL,
  last_extraction_run_id bigint REFERENCES ai_extraction_runs(id) ON DELETE SET NULL,
  readiness_score numeric(5,2) NOT NULL DEFAULT 0 CHECK (readiness_score BETWEEN 0 AND 100),
  ready_for_matching boolean NOT NULL DEFAULT false,
  missing_critical_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  last_ai_action text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ai_state_missing_array CHECK (jsonb_typeof(missing_critical_fields)='array')
);

CREATE OR REPLACE FUNCTION consultation_missing_critical_fields(p_consultation_id bigint)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT jsonb_strip_nulls(jsonb_build_object(
    'category', CASE WHEN c.category_id IS NULL THEN true END,
    'company_country', CASE WHEN co.country_id IS NULL THEN true END,
    'company_size', CASE WHEN co.employee_count_min IS NULL AND co.employee_count_max IS NULL THEN true END,
    'business_problem', CASE WHEN trim(c.business_problem)='' THEN true END,
    'requirements', CASE WHEN NOT EXISTS (SELECT 1 FROM consultation_requirements r WHERE r.consultation_id=c.id) THEN true END
  ))
  FROM consultations c
  LEFT JOIN companies co ON co.id=c.company_id
  WHERE c.id=p_consultation_id;
$$;

CREATE OR REPLACE FUNCTION refresh_consultation_ai_state(p_consultation_id bigint, p_prompt_version text DEFAULT 'v1')
RETURNS consultation_ai_state
LANGUAGE plpgsql
AS $$
DECLARE
  missing jsonb;
  missing_count integer;
  result consultation_ai_state;
BEGIN
  missing := COALESCE(consultation_missing_critical_fields(p_consultation_id),'{}'::jsonb);
  SELECT count(*) INTO missing_count FROM jsonb_each(missing);
  INSERT INTO consultation_ai_state(consultation_id,prompt_version,readiness_score,ready_for_matching,missing_critical_fields,last_ai_action,updated_at)
  VALUES (p_consultation_id,p_prompt_version,GREATEST(0,100-(missing_count*20)),missing_count=0,COALESCE((SELECT jsonb_agg(key) FROM jsonb_each(missing)),'[]'::jsonb),'refresh',now())
  ON CONFLICT (consultation_id) DO UPDATE SET
    prompt_version=EXCLUDED.prompt_version,
    readiness_score=EXCLUDED.readiness_score,
    ready_for_matching=EXCLUDED.ready_for_matching,
    missing_critical_fields=EXCLUDED.missing_critical_fields,
    last_ai_action='refresh',
    updated_at=now()
  RETURNING * INTO result;
  RETURN result;
END;
$$;

COMMENT ON TABLE ai_extraction_runs IS 'Stores structured model output for requirement extraction. Model output is provisional until accepted into canonical consultation tables.';
COMMENT ON TABLE ai_follow_up_questions IS 'Stores only materially useful follow-up questions. The assistant should not ask for fields that can be inferred with high confidence or are not needed for matching.';
COMMENT ON TABLE consultation_ai_state IS 'Readiness gate for matching. AI may explain results but cannot bypass deterministic recommendation logic.';

COMMIT;
