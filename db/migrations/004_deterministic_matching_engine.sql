BEGIN;

CREATE TABLE scoring_profiles (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  version text NOT NULL UNIQUE,
  is_active boolean NOT NULL DEFAULT false,
  functional_weight numeric(5,2) NOT NULL DEFAULT 35,
  mandatory_weight numeric(5,2) NOT NULL DEFAULT 20,
  integration_weight numeric(5,2) NOT NULL DEFAULT 15,
  deployment_weight numeric(5,2) NOT NULL DEFAULT 10,
  budget_weight numeric(5,2) NOT NULL DEFAULT 10,
  regional_weight numeric(5,2) NOT NULL DEFAULT 5,
  security_weight numeric(5,2) NOT NULL DEFAULT 5,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT scoring_weights_total CHECK (
    functional_weight + mandatory_weight + integration_weight + deployment_weight +
    budget_weight + regional_weight + security_weight = 100
  )
);

INSERT INTO scoring_profiles (version, is_active)
VALUES ('v1', true)
ON CONFLICT (version) DO UPDATE SET is_active=true;

CREATE OR REPLACE FUNCTION capability_support_points(p_status capability_support_status)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_status
    WHEN 'supported' THEN 1.00
    WHEN 'enterprise_only' THEN 0.90
    WHEN 'plan_dependent' THEN 0.80
    WHEN 'custom_configuration' THEN 0.70
    WHEN 'partially_supported' THEN 0.65
    WHEN 'addon' THEN 0.60
    WHEN 'third_party_integration' THEN 0.55
    WHEN 'unknown' THEN 0.40
    WHEN 'not_yet_verified' THEN 0.40
    WHEN 'not_supported' THEN 0.00
    ELSE 0.40
  END;
$$;

CREATE OR REPLACE FUNCTION requirement_priority_weight(p_priority requirement_priority)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_priority
    WHEN 'must_have' THEN 5.0
    WHEN 'important' THEN 3.0
    WHEN 'nice_to_have' THEN 1.0
    ELSE 1.0
  END;
$$;

CREATE OR REPLACE FUNCTION preview_consultation_scores(
  p_consultation_id bigint,
  p_scoring_version text DEFAULT 'v1'
)
RETURNS TABLE (
  product_id bigint,
  product_name text,
  overall_score numeric,
  functional_score numeric,
  mandatory_score numeric,
  integration_score numeric,
  deployment_score numeric,
  budget_score numeric,
  regional_score numeric,
  security_score numeric,
  evidence_score numeric,
  mandatory_gap_count integer,
  important_gap_count integer,
  recommendation_status recommendation_status
)
LANGUAGE sql
STABLE
AS $$
WITH profile AS (
  SELECT * FROM scoring_profiles WHERE version=p_scoring_version
), consultation_ctx AS (
  SELECT c.* FROM consultations c WHERE c.id=p_consultation_id
), candidates AS (
  SELECT DISTINCT p.id, p.name
  FROM products p
  CROSS JOIN consultation_ctx cc
  LEFT JOIN product_categories pc ON pc.product_id=p.id
  WHERE p.status='active'
    AND (cc.category_id IS NULL OR p.category_id=cc.category_id OR pc.category_id=cc.category_id)
), requirement_rows AS (
  SELECT
    cand.id AS product_id,
    cr.id AS requirement_id,
    cr.priority,
    cr.is_mandatory,
    cap.is_security_related,
    COALESCE(pcap.support_status, 'not_yet_verified'::capability_support_status) AS support_status,
    COALESCE(pcap.confidence_score,0) AS confidence_score,
    requirement_priority_weight(cr.priority) AS priority_weight,
    capability_support_points(COALESCE(pcap.support_status, 'not_yet_verified'::capability_support_status)) AS support_points
  FROM candidates cand
  JOIN consultation_requirements cr ON cr.consultation_id=p_consultation_id
  LEFT JOIN capabilities cap ON cap.id=cr.capability_id
  LEFT JOIN product_capabilities pcap
    ON pcap.product_id=cand.id AND pcap.capability_id=cr.capability_id AND pcap.edition_id IS NULL
  WHERE cr.capability_id IS NOT NULL
), capability_agg AS (
  SELECT
    cand.id AS product_id,
    COALESCE(
      100 * SUM(rr.support_points * rr.priority_weight) / NULLIF(SUM(rr.priority_weight),0),
      100
    ) AS functional_score,
    COALESCE(
      100 * AVG(rr.support_points) FILTER (WHERE rr.is_mandatory),
      100
    ) AS mandatory_score,
    COALESCE(
      100 * SUM(rr.support_points * rr.priority_weight) FILTER (WHERE rr.is_security_related) /
      NULLIF(SUM(rr.priority_weight) FILTER (WHERE rr.is_security_related),0),
      100
    ) AS security_score,
    COALESCE(100 * AVG(rr.confidence_score), 0) AS evidence_score,
    COUNT(*) FILTER (
      WHERE rr.is_mandatory AND rr.support_status IN ('not_supported','unknown','not_yet_verified','partially_supported','addon','third_party_integration','custom_configuration')
    )::integer AS mandatory_gap_count,
    COUNT(*) FILTER (
      WHERE rr.priority='important' AND rr.support_status IN ('not_supported','unknown','not_yet_verified')
    )::integer AS important_gap_count
  FROM candidates cand
  LEFT JOIN requirement_rows rr ON rr.product_id=cand.id
  GROUP BY cand.id
), integration_rows AS (
  SELECT
    cand.id AS product_id,
    ci.priority,
    ci.is_mandatory,
    COALESCE(pi.support_status,'not_yet_verified'::capability_support_status) AS support_status,
    capability_support_points(COALESCE(pi.support_status,'not_yet_verified'::capability_support_status)) AS support_points,
    requirement_priority_weight(ci.priority) AS priority_weight
  FROM candidates cand
  JOIN consultation_integrations ci ON ci.consultation_id=p_consultation_id
  LEFT JOIN product_integrations pi
    ON pi.product_id=cand.id AND pi.integration_id=ci.integration_id AND pi.edition_id IS NULL
), integration_agg AS (
  SELECT cand.id AS product_id,
    COALESCE(100 * SUM(ir.support_points*ir.priority_weight)/NULLIF(SUM(ir.priority_weight),0),100) AS integration_score,
    COUNT(*) FILTER (
      WHERE ir.is_mandatory AND ir.support_status IN ('not_supported','unknown','not_yet_verified')
    )::integer AS integration_mandatory_gaps
  FROM candidates cand
  LEFT JOIN integration_rows ir ON ir.product_id=cand.id
  GROUP BY cand.id
), deployment_agg AS (
  SELECT cand.id AS product_id,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM consultation_deployment_preferences cdp WHERE cdp.consultation_id=p_consultation_id) THEN 100::numeric
      WHEN EXISTS (
        SELECT 1
        FROM consultation_deployment_preferences cdp
        JOIN product_deployment_models pdm ON pdm.product_id=cand.id AND pdm.deployment_model_id=cdp.deployment_model_id AND pdm.edition_id IS NULL
        WHERE cdp.consultation_id=p_consultation_id AND cdp.preference_type='required'
      ) THEN 100::numeric
      WHEN EXISTS (
        SELECT 1 FROM consultation_deployment_preferences cdp
        WHERE cdp.consultation_id=p_consultation_id AND cdp.preference_type='required'
      ) THEN 0::numeric
      WHEN EXISTS (
        SELECT 1
        FROM consultation_deployment_preferences cdp
        JOIN product_deployment_models pdm ON pdm.product_id=cand.id AND pdm.deployment_model_id=cdp.deployment_model_id AND pdm.edition_id IS NULL
        WHERE cdp.consultation_id=p_consultation_id AND cdp.preference_type='preferred'
      ) THEN 100::numeric
      ELSE 50::numeric
    END AS deployment_score,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM consultation_deployment_preferences cdp
        WHERE cdp.consultation_id=p_consultation_id AND cdp.preference_type='required'
      ) AND NOT EXISTS (
        SELECT 1 FROM consultation_deployment_preferences cdp
        JOIN product_deployment_models pdm ON pdm.product_id=cand.id AND pdm.deployment_model_id=cdp.deployment_model_id AND pdm.edition_id IS NULL
        WHERE cdp.consultation_id=p_consultation_id AND cdp.preference_type='required'
      ) THEN 1 ELSE 0
    END AS required_deployment_gap
  FROM candidates cand
), regional_agg AS (
  SELECT cand.id AS product_id,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM consultation_countries cc WHERE cc.consultation_id=p_consultation_id AND cc.requirement_type='must_support') THEN 100::numeric
      WHEN NOT EXISTS (SELECT 1 FROM product_countries pc WHERE pc.product_id=cand.id) THEN 50::numeric
      WHEN NOT EXISTS (
        SELECT 1 FROM consultation_countries cc
        WHERE cc.consultation_id=p_consultation_id AND cc.requirement_type='must_support'
          AND NOT EXISTS (SELECT 1 FROM product_countries pc WHERE pc.product_id=cand.id AND pc.country_id=cc.country_id)
      ) THEN 100::numeric
      ELSE 0::numeric
    END AS regional_score
  FROM candidates cand
), budget_agg AS (
  SELECT cand.id AS product_id,
    CASE
      WHEN ctx.budget_max IS NULL THEN 100::numeric
      WHEN NOT EXISTS (SELECT 1 FROM product_pricing pp WHERE pp.product_id=cand.id) THEN 50::numeric
      WHEN EXISTS (
        SELECT 1 FROM product_pricing pp
        WHERE pp.product_id=cand.id
          AND pp.currency=ctx.budget_currency
          AND pp.amount_min IS NOT NULL
          AND pp.amount_min <= ctx.budget_max
      ) THEN 100::numeric
      ELSE 0::numeric
    END AS budget_score
  FROM candidates cand CROSS JOIN consultation_ctx ctx
), scored AS (
  SELECT
    cand.id AS product_id,
    cand.name AS product_name,
    ca.functional_score,
    ca.mandatory_score,
    ia.integration_score,
    da.deployment_score,
    ba.budget_score,
    ra.regional_score,
    ca.security_score,
    ca.evidence_score,
    (ca.mandatory_gap_count + ia.integration_mandatory_gaps + da.required_deployment_gap)::integer AS mandatory_gap_count,
    ca.important_gap_count,
    (
      ca.functional_score * p.functional_weight/100 +
      ca.mandatory_score * p.mandatory_weight/100 +
      ia.integration_score * p.integration_weight/100 +
      da.deployment_score * p.deployment_weight/100 +
      ba.budget_score * p.budget_weight/100 +
      ra.regional_score * p.regional_weight/100 +
      ca.security_score * p.security_weight/100
    ) AS overall_score
  FROM candidates cand
  CROSS JOIN profile p
  JOIN capability_agg ca ON ca.product_id=cand.id
  JOIN integration_agg ia ON ia.product_id=cand.id
  JOIN deployment_agg da ON da.product_id=cand.id
  JOIN regional_agg ra ON ra.product_id=cand.id
  JOIN budget_agg ba ON ba.product_id=cand.id
)
SELECT
  s.product_id,
  s.product_name,
  round(s.overall_score,2),
  round(s.functional_score,2),
  round(s.mandatory_score,2),
  round(s.integration_score,2),
  round(s.deployment_score,2),
  round(s.budget_score,2),
  round(s.regional_score,2),
  round(s.security_score,2),
  round(s.evidence_score,2),
  s.mandatory_gap_count,
  s.important_gap_count,
  CASE
    WHEN s.mandatory_gap_count > 0 THEN 'conditional'::recommendation_status
    WHEN s.overall_score >= 90 THEN 'strong_match'::recommendation_status
    WHEN s.overall_score >= 75 THEN 'recommended'::recommendation_status
    WHEN s.overall_score >= 55 THEN 'possible_match'::recommendation_status
    ELSE 'excluded'::recommendation_status
  END
FROM scored s
ORDER BY (s.mandatory_gap_count > 0), s.overall_score DESC, s.evidence_score DESC, s.product_name;
$$;

CREATE OR REPLACE FUNCTION generate_consultation_recommendations(
  p_consultation_id bigint,
  p_scoring_version text DEFAULT 'v1'
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  inserted_count integer;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM consultations WHERE id=p_consultation_id) THEN
    RAISE EXCEPTION 'consultation % does not exist', p_consultation_id;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM scoring_profiles WHERE version=p_scoring_version) THEN
    RAISE EXCEPTION 'scoring profile % does not exist', p_scoring_version;
  END IF;

  DELETE FROM consultation_recommendations
  WHERE consultation_id=p_consultation_id AND scoring_version=p_scoring_version;

  INSERT INTO consultation_recommendations (
    consultation_id, product_id, edition_id, recommendation_rank,
    overall_score, functional_score, mandatory_score, integration_score,
    deployment_score, budget_score, regional_score, security_score, evidence_score,
    mandatory_gap_count, important_gap_count, recommendation_status, scoring_version
  )
  SELECT
    p_consultation_id,
    x.product_id,
    NULL,
    row_number() OVER (ORDER BY (x.mandatory_gap_count > 0), x.overall_score DESC, x.evidence_score DESC, x.product_name)::integer,
    x.overall_score, x.functional_score, x.mandatory_score, x.integration_score,
    x.deployment_score, x.budget_score, x.regional_score, x.security_score, x.evidence_score,
    x.mandatory_gap_count, x.important_gap_count, x.recommendation_status, p_scoring_version
  FROM preview_consultation_scores(p_consultation_id,p_scoring_version) x;

  GET DIAGNOSTICS inserted_count = ROW_COUNT;

  -- Persist explicit capability gaps for explainability. Unknown is a gap, but it is
  -- deliberately distinguished from an explicit not-supported fact.
  INSERT INTO recommendation_gaps (
    recommendation_id, consultation_requirement_id, gap_type, severity, explanation
  )
  SELECT
    r.id,
    cr.id,
    CASE COALESCE(pc.support_status,'not_yet_verified'::capability_support_status)
      WHEN 'not_supported' THEN 'unsupported'::recommendation_gap_type
      WHEN 'partially_supported' THEN 'partial'::recommendation_gap_type
      WHEN 'addon' THEN 'partial'::recommendation_gap_type
      WHEN 'third_party_integration' THEN 'integration_required'::recommendation_gap_type
      WHEN 'enterprise_only' THEN 'plan_restriction'::recommendation_gap_type
      WHEN 'plan_dependent' THEN 'plan_restriction'::recommendation_gap_type
      WHEN 'custom_configuration' THEN 'partial'::recommendation_gap_type
      ELSE 'unknown'::recommendation_gap_type
    END,
    CASE WHEN cr.is_mandatory THEN 'critical'::gap_severity ELSE 'medium'::gap_severity END,
    CASE COALESCE(pc.support_status,'not_yet_verified'::capability_support_status)
      WHEN 'not_supported' THEN 'The product is explicitly recorded as not supporting this requirement.'
      WHEN 'partially_supported' THEN 'The product only partially supports this requirement.'
      WHEN 'addon' THEN 'This requirement depends on an add-on.'
      WHEN 'third_party_integration' THEN 'This requirement depends on a third-party integration.'
      WHEN 'enterprise_only' THEN 'This requirement is recorded as enterprise-only.'
      WHEN 'plan_dependent' THEN 'Availability depends on product plan or edition.'
      WHEN 'custom_configuration' THEN 'This requirement needs custom configuration.'
      ELSE 'Support for this requirement has not yet been verified; do not treat it as unsupported.'
    END
  FROM consultation_recommendations r
  JOIN consultation_requirements cr ON cr.consultation_id=r.consultation_id AND cr.capability_id IS NOT NULL
  LEFT JOIN product_capabilities pc
    ON pc.product_id=r.product_id AND pc.capability_id=cr.capability_id AND pc.edition_id IS NULL
  WHERE r.consultation_id=p_consultation_id
    AND r.scoring_version=p_scoring_version
    AND COALESCE(pc.support_status,'not_yet_verified'::capability_support_status) NOT IN ('supported')
    AND (cr.is_mandatory OR cr.priority='important');

  UPDATE consultations
  SET status='analysis', updated_at=now()
  WHERE id=p_consultation_id AND status IN ('draft','in_progress','requirements_review');

  RETURN inserted_count;
END;
$$;

COMMENT ON FUNCTION preview_consultation_scores(bigint,text) IS
'Deterministic, explainable product scoring. LLM output must not override these structured facts or silently convert unknown into unsupported.';

COMMENT ON FUNCTION generate_consultation_recommendations(bigint,text) IS
'Persists deterministic scores and explicit gaps for a consultation using a versioned scoring profile.';

COMMIT;
