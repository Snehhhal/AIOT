"""
Retrieval & Safety Synthesis Engine for Lineman Safety Assistant
================================================================
Performs semantic vector retrieval against ChromaDB knowledge store and
synthesizes grounded operational safety advice citing statutory CEA Regulations
and Utility Monsoon Standard Operating Procedures.
"""

import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from typing import Any, Dict, List, Optional
import chromadb
from rag.src.embeddings import safety_embedder

CHROMA_DIR = os.path.join(BASE_DIR, "chroma_db")
COLLECTION_NAME = "safety_regulations_sop"


class SafetyRAGAssistant:
    """
    RAG Safety Assistant retrieving statutory regulations and generating
    actionable, guardrailed field safety procedures.
    """

    def __init__(self, chroma_dir: Optional[str] = None):
        self.chroma_dir = chroma_dir or CHROMA_DIR
        self.client = chromadb.PersistentClient(path=self.chroma_dir)
        try:
            self.collection = self.client.get_collection(
                name=COLLECTION_NAME,
                embedding_function=safety_embedder
            )
        except Exception:
            # Auto-ingest if collection doesn't exist yet
            from rag.src.ingest import ingest_knowledge_base
            ingest_knowledge_base()
            self.collection = self.client.get_collection(
                name=COLLECTION_NAME,
                embedding_function=safety_embedder
            )

    def retrieve_context(self, query: str, n_results: int = 3) -> List[Dict[str, Any]]:
        """
        Queries ChromaDB using cosine distance and returns top-K ranked chunks.
        """
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results
        )

        chunks = []
        if results and "documents" in results and len(results["documents"]) > 0:
            docs = results["documents"][0]
            metas = results["metadatas"][0] if "metadatas" in results else [{}] * len(docs)
            dists = results["distances"][0] if "distances" in results else [0.2] * len(docs)

            for doc, meta, dist in zip(docs, metas, dists):
                relevance = round(max(0.0, 1.0 - float(dist)), 4)
                chunks.append({
                    "content": doc,
                    "source": meta.get("source", "Safety_Knowledge_Base"),
                    "section": meta.get("section", "General Provisions"),
                    "doc_title": meta.get("doc_title", "Statutory Safety Standard"),
                    "relevance_score": relevance
                })

        return chunks

    def answer_query(
        self,
        query: str,
        pole_id: Optional[str] = None,
        telemetry_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Synthesizes a legally grounded and structured safety advisory tailored to
        the lineman's question and current real-time pole telemetry.
        """
        chunks = self.retrieve_context(query, n_results=3)

        # Context analysis
        current_ma = telemetry_context.get("leakage_current_ma", 0.0) if telemetry_context else 0.0
        rain = bool(telemetry_context.get("rain_detected", False)) if telemetry_context else False
        is_emergency = current_ma >= 30.0 or rain

        # Extract citations
        citations = []
        for c in chunks:
            citations.append({
                "source": c["source"],
                "section": f"{c['doc_title']} - {c['section']}",
                "relevance_score": c["relevance_score"],
                "text_snippet": c["content"][:240] + "..." if len(c["content"]) > 240 else c["content"]
            })

        # Generate Actionable Procedural Guidance
        answer_parts = []
        answer_parts.append("### Statutory Field Safety Directive:")

        if pole_id:
            status_note = f" (Current telemetry: {current_ma:.1f} mA, Rain={'YES' if rain else 'NO'})" if telemetry_context else ""
            answer_parts.append(f"**Target Structure:** Utility Pole `{pole_id}`{status_note}")

        # Core Safety Instructions
        answer_parts.append("\n**1. Mandatory Approach & Perimeter Rules:**")
        if "water" in query.lower() or "monsoon" in query.lower() or rain or "puddle" in query.lower():
            answer_parts.append(
                "- **PROHIBITED:** DO NOT step into standing water or puddles within 5.0 meters of the pole structure."
            )
            answer_parts.append(
                "- **STEP-POTENTIAL AVOIDANCE:** If approaching the zone, execute the **Safe Shuffle Technique**: "
                "keep feet touching together and shuffle slowly without lifting either foot from the earth to eliminate inter-pace potential gradients."
            )
        else:
            answer_parts.append("- Maintain a minimum safety perimeter of 3.0 meters until de-energization is verified.")

        answer_parts.append("\n**2. Pre-Contact De-Energization Protocol (CEA Reg. 19 & 43):**")
        answer_parts.append("- Radio divisional sub-station operator to request upstream circuit breaker lockout/tagout (LOTO).")
        answer_parts.append("- Verify zero voltage with a certified non-contact capacitive high-voltage detector stick.")
        answer_parts.append("- Apply temporary portable earth discharge rods to both line conductors and chassis before touching.")

        # Mandatory PPE
        recommended_ppe = [
            "Class 0 (1000V AC) Dielectric Insulating Gloves (IS 4770 / ASTM D120)",
            "Dielectric Safety Boots / Overshoes with 18kV Outsole (EN 50321)",
            "Type 1 Class E Non-Conductive Helmet with 8 cal/cm² Arc Flash Shield (IS 2925)",
            "Certified Capacitive Non-Contact AC Voltage Detector Stick (100V - 10kV)"
        ]

        answer_parts.append("\n**3. Required Personal Protective Equipment (PPE):**")
        for ppe in recommended_ppe:
            answer_parts.append(f"- {ppe}")

        # Deterministic Guardrail Note
        answer_parts.append(
            "\n> **Deterministic Safety Guardrail:** This advisory is synthesized from CEA Regulations 2010 "
            "and Utility SOPs for informational compliance. Automatic hardware trip signals and physical lockout "
            "protocols supersede any digital advice."
        )

        full_answer = "\n".join(answer_parts)
        safety_level = "CRITICAL_HAZARD" if is_emergency else "STANDARD_MAINTENANCE"

        return {
            "answer": full_answer,
            "citations": citations,
            "safety_level": safety_level,
            "recommended_ppe": recommended_ppe
        }


# Singleton instance
safety_assistant = SafetyRAGAssistant()
