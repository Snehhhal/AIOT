"""
Automated Test Suite for Safety RAG Assistant (Phase 10)
========================================================
Validates:
1. Deterministic offline HashingVectorizer embeddings (384-dim, L2-normalized).
2. Markdown section parsing and semantic chunking of statutory safety standards.
3. ChromaDB vector storage and semantic cosine similarity retrieval.
4. Grounded safety advisory generation with CEA 2010 citations and PPE checklists.
5. Cross-modal telemetry awareness (leakage current, waterlogging, emergency escalation).
6. End-to-end FastAPI endpoint POST /api/v1/assistant/query.
"""

import os
import pytest
import pytest_asyncio
import numpy as np
from httpx import AsyncClient, ASGITransport

from backend.main import app
from backend.app.core.seed import seed_initial_data
from rag.src.embeddings import OfflineSafetyEmbeddingFunction, safety_embedder
from rag.src.ingest import parse_markdown_sections, KB_DIR
from rag.src.retriever import SafetyRAGAssistant, safety_assistant


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    """Ensure schema tables and seed data exist before running tests."""
    await seed_initial_data()


# ==============================================================================
# 1. Offline Embedding Function Tests
# ==============================================================================

def test_offline_embedding_function():
    embedder = OfflineSafetyEmbeddingFunction(n_features=384)
    assert embedder.name() == "offline_safety_hashing_embedder"

    texts = [
        "Lineman de-energization protocol and step-potential mitigation.",
        "Earthing conductor testing under Central Electricity Authority regulations."
    ]
    vectors = embedder(texts)

    assert len(vectors) == 2
    assert len(vectors[0]) == 384
    assert len(vectors[1]) == 384

    # Verify L2 normalization: norm should be approximately 1.0
    norm_0 = np.linalg.norm(vectors[0])
    norm_1 = np.linalg.norm(vectors[1])
    assert abs(norm_0 - 1.0) < 1e-4
    assert abs(norm_1 - 1.0) < 1e-4

    # Verify deterministic reproducibility: same text produces identical vector
    repeat_vectors = embedder(["Lineman de-energization protocol and step-potential mitigation."])
    np.testing.assert_allclose(vectors[0], repeat_vectors[0], atol=1e-6)


# ==============================================================================
# 2. Markdown Parsing & Chunking Tests
# ==============================================================================

def test_parse_markdown_sections():
    sop_file = os.path.join(KB_DIR, "lineman_monsoon_sop.md")
    assert os.path.exists(sop_file), f"SOP file missing at {sop_file}"

    chunks = parse_markdown_sections(sop_file)
    assert len(chunks) >= 4

    # Verify chunk structure
    for chunk in chunks:
        assert "id" in chunk
        assert "source" in chunk
        assert "doc_title" in chunk
        assert "section" in chunk
        assert "content" in chunk
        assert len(chunk["content"]) > 30

    # Ensure critical safety topics were captured in headers
    sections = [c["section"] for c in chunks]
    assert any("Waterlogging" in s or "Puddle" in s for s in sections)
    assert any("Safe Shuffle" in s or "Potential" in s for s in sections)
    assert any("Isolation" in s or "Permit" in s for s in sections)


# ==============================================================================
# 3. Vector Retrieval & Semantic Search Tests
# ==============================================================================

def test_vector_retrieval_scenario_5():
    # Scenario 5 Query: 38mA leakage in standing water
    query = "What mandatory precautions must I take before isolating pole P-102 showing 38mA leakage in standing water?"
    chunks = safety_assistant.retrieve_context(query, n_results=3)

    assert len(chunks) == 3
    for c in chunks:
        assert c["relevance_score"] >= 0.0
        assert c["relevance_score"] <= 1.0
        assert c["source"].endswith(".md")
        assert len(c["content"]) > 0

    # Verify retrieved context contains relevant terms
    all_content = " ".join(c["content"].lower() for c in chunks)
    assert any(term in all_content for term in ["water", "leakage", "isolation", "de-energization", "earthing", "ppe"])


# ==============================================================================
# 4. Safety Synthesis & Guardrails Tests
# ==============================================================================

def test_safety_synthesis_waterlogging_and_critical_leakage():
    query = "Pole has 38mA leakage and there is water puddle around it. Can I approach to isolate?"
    telemetry_ctx = {
        "leakage_current_ma": 38.0,
        "touch_voltage_v": 52.0,
        "rain_detected": True,
        "temperature_c": 26.5,
        "humidity_pct": 98.0
    }

    result = safety_assistant.answer_query(
        query=query,
        pole_id="P-102",
        telemetry_context=telemetry_ctx
    )

    # 1. Critical hazard level escalation
    assert result["safety_level"] == "CRITICAL_HAZARD"

    answer = result["answer"]
    # 2. Must cite pole id
    assert "P-102" in answer
    # 3. Waterlogging perimeter and Safe Shuffle Technique must be mandated
    assert "PROHIBITED" in answer
    assert "Safe Shuffle Technique" in answer or "step-potential" in answer.lower()
    # 4. Mandatory pre-contact de-energization protocol
    assert "LOTO" in answer or "lockout" in answer.lower()
    assert "voltage detector stick" in answer.lower()
    # 5. Deterministic Guardrail must be present
    assert "Deterministic Safety Guardrail" in answer
    assert "supersede any digital advice" in answer.lower()

    # 6. PPE checklist validation
    ppe = result["recommended_ppe"]
    assert len(ppe) >= 3
    assert any("Gloves" in item for item in ppe)
    assert any("Boots" in item for item in ppe)
    assert any("Detector" in item for item in ppe)

    # 7. Citations present
    assert len(result["citations"]) > 0
    for citation in result["citations"]:
        assert "source" in citation
        assert "section" in citation
        assert citation["relevance_score"] >= 0.0


def test_safety_synthesis_dry_normal_conditions():
    query = "What is the procedure for routine inspection of an electrical pole?"
    telemetry_ctx = {
        "leakage_current_ma": 2.1,
        "touch_voltage_v": 3.0,
        "rain_detected": False,
        "temperature_c": 29.0,
        "humidity_pct": 55.0
    }

    result = safety_assistant.answer_query(
        query=query,
        pole_id="P-001",
        telemetry_context=telemetry_ctx
    )

    assert result["safety_level"] == "STANDARD_MAINTENANCE"
    assert "P-001" in result["answer"]
    assert "3.0 meters" in result["answer"]
    assert "Deterministic Safety Guardrail" in result["answer"]


# ==============================================================================
# 5. End-to-End FastAPI Endpoint Tests (POST /api/v1/assistant/query)
# ==============================================================================

@pytest.mark.asyncio
async def test_assistant_api_query_with_pole_id():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "query": "How do I safely inspect pole P-001 with suspected insulation degradation?",
            "pole_id": "P-001",
            "user_role": "TECHNICIAN"
        }
        res = await ac.post("/api/v1/assistant/query", json=payload)
        assert res.status_code == 200

        body = res.json()
        assert body["success"] is True
        assert "data" in body

        data = body["data"]
        assert "answer" in data
        assert "citations" in data
        assert "safety_level" in data
        assert "recommended_ppe" in data

        assert len(data["citations"]) > 0
        assert len(data["recommended_ppe"]) > 0
        assert "P-001" in data["answer"]


@pytest.mark.asyncio
async def test_assistant_api_query_general_without_pole_id():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "query": "What are the CEA 2010 requirements for earthing and neutral grounding?",
            "user_role": "ENGINEER"
        }
        res = await ac.post("/api/v1/assistant/query", json=payload)
        assert res.status_code == 200

        body = res.json()
        assert body["success"] is True
        data = body["data"]

        assert "answer" in data
        assert "CEA" in data["answer"] or "earthing" in data["answer"].lower()
        assert len(data["citations"]) > 0
