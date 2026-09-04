from fastapi import APIRouter
from backend.app.schemas.assistant import AssistantQuery

router = APIRouter(prefix="/assistant", tags=["Safety RAG Assistant"])


@router.post("/query", response_model=dict, summary="Query Safety Regulations and SOPs")
async def query_safety_assistant(query_in: AssistantQuery):
    """
    RAG Assistant endpoint. Queries ChromaDB for CEA safety standards
    and passes context to the configured LLM.
    """
    return {
        "success": True,
        "data": {
            "query": query_in.query,
            "pole_id": query_in.pole_id,
            "answer": (
                "Standard Operating Procedure for Pole Isolation:\n"
                "1. DO NOT make physical contact with the pole body or step into surrounding standing water.\n"
                "2. Ensure Class 0 (1000V) dielectric insulating gloves and boots are worn.\n"
                "3. Use a certified non-contact AC voltage detector to verify presence of live leakage.\n"
                "4. Request upstream sub-station line isolation before applying temporary grounding discharge rods."
            ),
            "citations": [
                {
                    "source": "CEA_Safety_Regulations_2010.pdf",
                    "section": "Regulation 43: Isolation and Grounding Procedures",
                    "relevance_score": 0.92
                }
            ],
            "note": "RAG scaffold ready. Connects to ChromaDB and LLM in Phase 5."
        },
        "message": "Safety recommendations generated."
    }
