import json
import httpx
from .settings import settings

SYSTEM_INSTRUCTION = """You are TechSelect AI, a software-selection consultant. Extract business requirements only from what the user says. Do not invent vendor capabilities, pricing, compliance, integrations, or rankings. Ask only the most important missing questions. Product recommendations are produced by a deterministic database scoring engine, not by you."""

EXTRACTION_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "assistant_message": {"type": "string"},
        "company": {
            "type": "object",
            "additionalProperties": False,
            "properties": {
                "country": {"type": ["string", "null"]},
                "industry": {"type": ["string", "null"]},
                "employee_count": {"type": ["integer", "null"]},
                "expected_users": {"type": ["integer", "null"]}
            },
            "required": ["country", "industry", "employee_count", "expected_users"]
        },
        "budget": {
            "type": "object",
            "additionalProperties": False,
            "properties": {
                "min": {"type": ["number", "null"]},
                "max": {"type": ["number", "null"]},
                "currency": {"type": ["string", "null"]},
                "period": {"type": ["string", "null"]}
            },
            "required": ["min", "max", "currency", "period"]
        },
        "requirements": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "text": {"type": "string"},
                    "priority": {"type": "string", "enum": ["must_have", "important", "nice_to_have"]},
                    "mandatory": {"type": "boolean"}
                },
                "required": ["text", "priority", "mandatory"]
            }
        },
        "deployment_preferences": {"type": "array", "items": {"type": "string"}},
        "integrations": {"type": "array", "items": {"type": "string"}},
        "compliance": {"type": "array", "items": {"type": "string"}},
        "languages": {"type": "array", "items": {"type": "string"}},
        "follow_up_questions": {"type": "array", "items": {"type": "string"}}
    },
    "required": ["assistant_message", "company", "budget", "requirements", "deployment_preferences", "integrations", "compliance", "languages", "follow_up_questions"]
}

def extract_requirements(message: str, context: str = "") -> dict:
    if not settings.openai_api_key:
        return {
            "assistant_message": "I can capture this requirement, but AI extraction is not configured yet. Please provide country, company size, expected users, budget and any must-have integrations.",
            "company": {"country": None, "industry": None, "employee_count": None, "expected_users": None},
            "budget": {"min": None, "max": None, "currency": None, "period": None},
            "requirements": [{"text": message, "priority": "important", "mandatory": False}],
            "deployment_preferences": [], "integrations": [], "compliance": [], "languages": [],
            "follow_up_questions": ["Which country will use the solution?", "How many users need access?", "What budget range should I work within?"]
        }

    payload = {
        "model": settings.openai_model,
        "instructions": SYSTEM_INSTRUCTION,
        "input": f"Existing consultation context:\n{context}\n\nLatest user message:\n{message}",
        "text": {
            "format": {
                "type": "json_schema",
                "name": "techselect_requirement_extraction",
                "strict": True,
                "schema": EXTRACTION_SCHEMA
            }
        }
    }
    with httpx.Client(timeout=45) as client:
        response = client.post(
            "https://api.openai.com/v1/responses",
            headers={"Authorization": f"Bearer {settings.openai_api_key}", "Content-Type": "application/json"},
            json=payload,
        )
        response.raise_for_status()
        data = response.json()
    text = data.get("output_text")
    if not text:
        for item in data.get("output", []):
            for content in item.get("content", []):
                if content.get("type") == "output_text":
                    text = content.get("text")
                    break
    if not text:
        raise RuntimeError("OpenAI response did not contain structured output")
    return json.loads(text)
