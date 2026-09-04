"""
Deterministic Offline Embedding Function for Safety RAG
========================================================
Implements ChromaDB's EmbeddingFunction interface using normalized L2
hashed term vectors. Runs 100% locally with zero internet dependency,
zero latency, and deterministic reproducibility.
"""

from typing import List
from chromadb.api.types import Documents, EmbeddingFunction, Embeddings
from sklearn.feature_extraction.text import HashingVectorizer


class OfflineSafetyEmbeddingFunction(EmbeddingFunction):
    """
    High-speed, 100% offline text embedder producing normalized 384-dimensional
    dense vectors compatible with ChromaDB cosine distance metric.
    """

    def __init__(self, n_features: int = 384):
        self.n_features = n_features
        self.vectorizer = HashingVectorizer(
            n_features=n_features,
            alternate_sign=False,
            norm="l2",
            lowercase=True,
            ngram_range=(1, 2),
        )

    def name(self) -> str:
        return "offline_safety_hashing_embedder"

    def __call__(self, input: Documents) -> Embeddings:
        sparse_matrix = self.vectorizer.transform(input)
        return sparse_matrix.toarray().astype(float).tolist()


# Singleton instance
safety_embedder = OfflineSafetyEmbeddingFunction(n_features=384)
