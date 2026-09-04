# RAG (Retrieval-Augmented Generation) Safety Knowledge Base

## Overview
Grounds LLM responses in statutory electrical safety codes and standard operating procedures for field technicians and utility operators.

## Directory Layout
* `knowledge_base/`: Source safety manuals, statutory regulations, and SOP markdown/PDF files:
  - Central Electricity Authority (Measures relating to Safety and Electric Supply) Regulations.
  - Distribution Utility Monsoon Emergency Manual.
  - Lineman Safety Handbook & PPE Specifications.
* `src/`: Ingestion, chunking, and embedding retrieval scripts:
  - `ingest.py`: Splits documents into chunks and loads embeddings into ChromaDB.
  - `retriever.py`: Cosine similarity search retrieving top-K relevant chunks.
* `chroma_db/`: Persistent local vector store.

## Dependencies
Install dedicated RAG dependencies via `rag/requirements.txt`.
