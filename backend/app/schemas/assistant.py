from typing import List, Optional
from pydantic import BaseModel, Field


class Citation(BaseModel):
    source: str
    section: Optional[str] = None
    relevance_score: Optional[float] = None
    text_snippet: Optional[str] = None


class AssistantQuery(BaseModel):
    query: str = Field(..., description="Natural language question from lineman or operator")
    pole_id: Optional[str] = Field(None, description="Optional context pole identifier")
    user_role: Optional[str] = Field("LINEMAN", description="LINEMAN, ADMIN, CITIZEN")


class AssistantResponse(BaseModel):
    answer: str
    citations: List[Citation] = []
    safety_level: str = "SAFE"
    recommended_ppe: List[str] = []
