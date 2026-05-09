"""Test embed_documents vs embed_query vector comparison.

Compares the stored vector (from embed_documents during ingest) with a fresh
embed_query vector for the exact same text, to check if the two endpoints
produce different vectors through OpenRouter.
"""

import os
import numpy as np

os.environ.setdefault("EMBEDDING_PROVIDER", os.environ.get("EMBEDDING_PROVIDER", "openrouter"))

from ai_service.config import settings
from ai_service.embedding_factory import create_embeddings
from ai_service.database import normalize_psycopg_dsn
import psycopg


def cosine_similarity(a, b):
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


def main():
    dsn = normalize_psycopg_dsn(settings.DATABASE_URL)
    embeddings = create_embeddings(settings)

    print(f"Provider: {settings.EMBEDDING_PROVIDER}")
    print(f"Model: {settings.EMBEDDING_MODEL}")

    with psycopg.connect(dsn) as conn:
        # 1. Fetch the first stored chunk and its vector
        with conn.cursor() as cur:
            cur.execute("""
                SELECT content, source, embedding::text
                FROM knowledge_base_chunks
                WHERE source = 'matricula.md'
                ORDER BY chunk_index
                LIMIT 1
            """)
            row = cur.fetchone()

        content, source, stored_vector_str = row
        # Parse the stored vector string "[0.123, 0.456, ...]" into a list of floats
        stored_vector = [float(x) for x in stored_vector_str.strip("[]").split(",")]

        preview = content[:100].replace("\n", " ")
        print(f"\nChunk: {source} — \"{preview}...\"")
        print(f"Stored vector dim: {len(stored_vector)}")
        print(f"Stored vector norm: {np.linalg.norm(stored_vector):.6f}")

        # 2. Generate embed_query for the EXACT same text
        print(f"\n{'='*70}")
        print("TEST 1: embed_query com texto IDENTICO ao chunk armazenado")
        print(f"{'='*70}")

        query_vector = embeddings.embed_query(content)
        print(f"Query vector dim: {len(query_vector)}")
        print(f"Query vector norm: {np.linalg.norm(query_vector):.6f}")

        sim_query_vs_stored = cosine_similarity(query_vector, stored_vector)
        print(f"Cosine similarity (embed_query vs stored embed_documents): {sim_query_vs_stored:.6f}")

        # 3. Generate embed_documents for the same text (single item batch)
        print(f"\n{'='*70}")
        print("TEST 2: embed_documents (batch=1) com texto IDENTICO ao chunk armazenado")
        print(f"{'='*70}")

        doc_vectors = embeddings.embed_documents([content])
        doc_vector = doc_vectors[0]
        print(f"Doc vector dim: {len(doc_vector)}")
        print(f"Doc vector norm: {np.linalg.norm(doc_vector):.6f}")

        sim_doc_vs_stored = cosine_similarity(doc_vector, stored_vector)
        print(f"Cosine similarity (fresh embed_documents vs stored embed_documents): {sim_doc_vs_stored:.6f}")

        # 4. Compare embed_query vs fresh embed_documents directly
        print(f"\n{'='*70}")
        print("TEST 3: embed_query vs embed_documents (ambos frescos, mesmo texto)")
        print(f"{'='*70}")

        sim_query_vs_doc = cosine_similarity(query_vector, doc_vector)
        print(f"Cosine similarity (embed_query vs embed_documents): {sim_query_vs_doc:.6f}")

        # 5. Compare first 10 values to see actual differences
        print(f"\n{'='*70}")
        print("COMPARACAO: primeiros 10 valores de cada vetor")
        print(f"{'='*70}")
        print(f"{'idx':>4} | {'stored (embed_docs)':>20} | {'fresh embed_query':>20} | {'fresh embed_docs':>20} | {'diff q-s':>12}")
        print("-" * 90)
        for i in range(10):
            s = stored_vector[i]
            q = query_vector[i]
            d = doc_vector[i]
            print(f"{i:>4} | {s:>20.12f} | {q:>20.12f} | {d:>20.12f} | {abs(q-s):>12.9f}")

    # Summary
    print(f"\n{'='*70}")
    print("RESUMO")
    print(f"{'='*70}")
    print(f"  embed_query vs stored (embed_documents):  {sim_query_vs_stored:.6f}")
    print(f"  fresh embed_documents vs stored:          {sim_doc_vs_stored:.6f}")
    print(f"  embed_query vs fresh embed_documents:     {sim_query_vs_doc:.6f}")

    if sim_query_vs_stored < 0.95 and sim_doc_vs_stored > 0.95:
        print(f"\n  >>> CONFIRMADO: embed_query e embed_documents produzem vetores DIFERENTES")
        print(f"  >>> O problema e a incompatibilidade entre os dois endpoints via OpenRouter")
    elif sim_doc_vs_stored < 0.95:
        print(f"\n  >>> embed_documents tambem diverge — OpenRouter nao e deterministico entre chamadas")
    elif sim_query_vs_stored > 0.95:
        print(f"\n  >>> Vetores compativeis — o problema esta em outro lugar")
    else:
        print(f"\n  >>> Resultado ambiguo — investigar mais")


if __name__ == "__main__":
    main()
