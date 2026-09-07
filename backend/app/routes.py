import hashlib
import secrets
from fastapi import APIRouter, HTTPException
from psycopg.rows import dict_row
from .ai import extract_requirements
from .db import db_cursor
from .schemas import ConsultationStart, ChatMessageIn, RecommendationRequest

router = APIRouter()

@router.post("/consultations")
def start_consultation(payload: ConsultationStart):
    visitor_id = payload.visitor_session_id
    if not visitor_id and not payload.user_id:
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode()).digest()
        with db_cursor() as cur:
            cur.execute("INSERT INTO visitor_sessions(session_token_hash) VALUES (%s) RETURNING id", (token_hash,))
            visitor_id = cur.fetchone()[0]
    with db_cursor() as cur:
        cur.execute(
            """INSERT INTO consultations(visitor_session_id,user_id,company_id,category_id,business_problem,original_user_request,consultation_source,status)
               VALUES (%s,%s,%s,%s,%s,%s,'ai_chat','in_progress')
               RETURNING id, public_uuid""",
            (visitor_id, payload.user_id, payload.company_id, payload.category_id, payload.business_problem, payload.business_problem),
        )
        consultation_id, public_uuid = cur.fetchone()
        cur.execute("SELECT * FROM refresh_consultation_ai_state(%s,'v1')", (consultation_id,))
    return {"consultation_id": consultation_id, "public_uuid": str(public_uuid)}

@router.post("/consultations/{public_uuid}/messages")
def send_message(public_uuid: str, payload: ChatMessageIn):
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("SELECT id FROM consultations WHERE public_uuid=%s", (public_uuid,))
        consultation = cur.fetchone()
        if not consultation:
            raise HTTPException(404, "Consultation not found")
        consultation_id = consultation["id"]
        cur.execute("INSERT INTO consultation_messages(consultation_id,sender_type,message_text,message_type) VALUES (%s,'user',%s,'normal') RETURNING id", (consultation_id, payload.message))
        source_message_id = cur.fetchone()["id"]
        cur.execute("SELECT sender_type, message_text FROM consultation_messages WHERE consultation_id=%s ORDER BY created_at DESC LIMIT 12", (consultation_id,))
        context_rows = list(reversed(cur.fetchall()))
    context = "\n".join(f"{r['sender_type']}: {r['message_text']}" for r in context_rows)
    extracted = extract_requirements(payload.message, context)
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute(
            """INSERT INTO ai_extraction_runs(consultation_id,source_message_id,model_provider,model_name,prompt_version,status,raw_output)
               VALUES (%s,%s,'openai',%s,'v1','pending',%s::jsonb) RETURNING id""",
            (consultation_id, source_message_id, 'configured', __import__('json').dumps(extracted)),
        )
        run_id = cur.fetchone()["id"]
        for idx, q in enumerate(extracted.get("follow_up_questions", [])[:3]):
            cur.execute(
                """INSERT INTO ai_follow_up_questions(consultation_id,extraction_run_id,question_key,question_text,reason,field_kind,priority)
                   VALUES (%s,%s,%s,%s,'Critical information missing from current consultation','free_text',%s)
                   ON CONFLICT DO NOTHING""",
                (consultation_id, run_id, f"run-{run_id}-{idx}", q, 10 + idx),
            )
        cur.execute("INSERT INTO consultation_messages(consultation_id,sender_type,message_text,message_type) VALUES (%s,'assistant',%s,'question')", (consultation_id, extracted["assistant_message"]))
        cur.execute("SELECT * FROM refresh_consultation_ai_state(%s,'v1')", (consultation_id,))
        state = cur.fetchone()
    return {"message": extracted["assistant_message"], "extraction": extracted, "readiness": state}

@router.post("/consultations/{public_uuid}/recommendations")
def generate_recommendations(public_uuid: str, payload: RecommendationRequest):
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("SELECT id FROM consultations WHERE public_uuid=%s", (public_uuid,))
        consultation = cur.fetchone()
        if not consultation:
            raise HTTPException(404, "Consultation not found")
        consultation_id = consultation["id"]
        cur.execute("SELECT * FROM refresh_consultation_ai_state(%s,'v1')", (consultation_id,))
        state = cur.fetchone()
        if not state["ready_for_matching"]:
            raise HTTPException(409, {"message": "Consultation is not ready for matching", "missing": state["missing_critical_fields"]})
        cur.execute("SELECT generate_consultation_recommendations(%s,%s)", (consultation_id, payload.scoring_version))
        cur.execute(
            """SELECT r.recommendation_rank,p.name AS product_name,r.overall_score,r.functional_score,r.integration_score,r.deployment_score,r.budget_score,r.regional_score,r.security_score,r.evidence_score,r.recommendation_status,r.mandatory_gap_count
               FROM consultation_recommendations r JOIN products p ON p.id=r.product_id
               WHERE r.consultation_id=%s AND r.scoring_version=%s ORDER BY r.recommendation_rank""",
            (consultation_id, payload.scoring_version),
        )
        results = cur.fetchall()
    return {"recommendations": results, "scoring_version": payload.scoring_version}
