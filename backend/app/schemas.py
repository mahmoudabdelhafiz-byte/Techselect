from typing import Any
from pydantic import BaseModel, Field

class ConsultationStart(BaseModel):
    visitor_session_id: int | None = None
    user_id: int | None = None
    company_id: int | None = None
    business_problem: str = Field(min_length=5)
    category_id: int | None = None

class ChatMessageIn(BaseModel):
    message: str = Field(min_length=1)

class RecommendationRequest(BaseModel):
    scoring_version: str = "v1"

class ExtractionResult(BaseModel):
    assistant_message: str
    extracted: dict[str, Any]
    follow_up_questions: list[str] = []
