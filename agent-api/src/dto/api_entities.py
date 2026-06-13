from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel

class ChatRequest(BaseModel):
    question: str
    user: str
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    user: str
    answer: str
    session_id: UUID
    trace_id: UUID


class HistoryItem(BaseModel):
    question: str
    answer: str
    trace_id: UUID
    session_id: UUID
    user: Optional[str] = None
    retrieved_contexts: Optional[List[Dict[str, Any]]] = None
    created_at: datetime
    is_ok: Optional[bool] = None
    error_type_id: Optional[int] = None
    observations: Optional[str] = None

    class Config:
        from_attributes = True


class ErrorTypeResponse(BaseModel):
    id: int
    description: str

    class Config:
        from_attributes = True


class FeedbackRequest(BaseModel):
    trace_id: str
    is_ok: bool
    error_type_id: Optional[int] = None
    observations: Optional[str] = None


class FeedbackResponse(BaseModel):
    trace_id: UUID
    session_id: UUID
    question: str
    answer: str
    user: Optional[str] = None
    retrieved_contexts: Optional[List[Dict[str, Any]]] = None
    created_at: datetime
    is_ok: Optional[bool] = None
    error_type_id: Optional[int] = None
    observations: Optional[str] = None

    class Config:
        from_attributes = True


class UserSessionsResponse(BaseModel):
    user: str
    sessions: List[str]


# ── RAGAS Evaluation ─────────────────────────────────────────────────────────

class EvaluateRequest(BaseModel):
    trace_ids: Optional[List[str]] = None
    session_id: Optional[str] = None
    ground_truths: Optional[Dict[str, str]] = None  # {trace_id: expected_answer}


class MetricResult(BaseModel):
    metric: str
    score: Optional[float]


class EvaluateResponse(BaseModel):
    evaluation_id: str
    evaluated_at: datetime
    trace_ids: List[str]
    llm_judge: str
    metrics: List[MetricResult]
    langsmith_url: Optional[str] = None

    class Config:
        from_attributes = True