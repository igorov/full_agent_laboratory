from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class History(Base):
    __tablename__ = "history"

    trace_id = Column(String, primary_key=True, nullable=False)
    session_id = Column(String, nullable=False, index=True)
    question = Column(String, nullable=False)
    answer = Column(String, nullable=False)
    input_tokens = Column(Integer, nullable=True)
    output_tokens = Column(Integer, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    user = Column(String, nullable=True)
    retrieved_contexts = Column(JSONB, nullable=True)
    is_ok = Column(Boolean, nullable=True)
    error_type_id = Column(Integer, ForeignKey("error_types.id"), nullable=True)
    observations = Column(Text, nullable=True)
