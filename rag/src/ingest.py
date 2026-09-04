"""
Knowledge Base Ingestion & Vector Indexing for Safety RAG Assistant
===================================================================
Parses statutory safety standards (CEA Regulations 2010, Lineman Monsoon SOP,
and PPE Specifications) into structured chunks and indexes them into persistent ChromaDB
using the deterministic OfflineSafetyEmbeddingFunction.
"""

import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

import re
from typing import Any, Dict, List
import chromadb
from rag.src.embeddings import safety_embedder
KB_DIR = os.path.join(BASE_DIR, "knowledge_base")
CHROMA_DIR = os.path.join(BASE_DIR, "chroma_db")
COLLECTION_NAME = "safety_regulations_sop"


def parse_markdown_sections(filepath: str) -> List[Dict[str, Any]]:
    """
    Parses a markdown document into logical chunks by top-level and second-level headers.
    """
    filename = os.path.basename(filepath)
    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()

    # Extract document title
    title_match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    doc_title = title_match.group(1).strip() if title_match else filename

    # Split on H2 headers (## Header)
    sections = re.split(r"\n(?=##\s+)", text)
    chunks = []

    for i, sec in enumerate(sections):
        sec = sec.strip()
        if not sec:
            continue

        header_match = re.match(r"^##\s+(.+)$", sec, re.MULTILINE)
        section_name = header_match.group(1).strip() if header_match else "General Provisions"

        # Content without the leading header line
        lines = sec.split("\n")
        body = "\n".join(lines[1:]).strip() if len(lines) > 1 else lines[0]

        chunks.append({
            "id": f"{filename}_{i}",
            "source": filename,
            "doc_title": doc_title,
            "section": section_name,
            "content": f"{doc_title} - {section_name}\n\n{body}"
        })

    return chunks


def ingest_knowledge_base() -> int:
    """
    Reads all knowledge base documents, chunks them, and stores them in persistent ChromaDB.
    """
    os.makedirs(CHROMA_DIR, exist_ok=True)
    client = chromadb.PersistentClient(path=CHROMA_DIR)
    try:
        client.delete_collection(COLLECTION_NAME)
    except Exception:
        pass

    collection = client.create_collection(
        name=COLLECTION_NAME,
        embedding_function=safety_embedder,
        metadata={"description": "CEA Safety Regulations 2010 and Lineman Monsoon SOP", "hnsw:space": "cosine"}
    )

    all_chunks = []
    for fname in os.listdir(KB_DIR):
        if fname.endswith(".md"):
            fpath = os.path.join(KB_DIR, fname)
            chunks = parse_markdown_sections(fpath)
            all_chunks.extend(chunks)

    print(f"[*] Parsed {len(all_chunks)} semantic chunks from {KB_DIR}")

    ids = [c["id"] for c in all_chunks]
    documents = [c["content"] for c in all_chunks]
    metadatas = [
        {
            "source": c["source"],
            "doc_title": c["doc_title"],
            "section": c["section"]
        }
        for c in all_chunks
    ]

    # Upsert into ChromaDB
    collection.upsert(
        ids=ids,
        documents=documents,
        metadatas=metadatas
    )

    print(f"[+] Successfully indexed {len(all_chunks)} chunks into ChromaDB collection '{COLLECTION_NAME}' at {CHROMA_DIR}")
    return len(all_chunks)


if __name__ == "__main__":
    ingest_knowledge_base()
