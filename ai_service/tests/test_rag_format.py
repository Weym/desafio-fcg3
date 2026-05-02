"""Test: compare Python cosine vs pgvector cosine for the same vectors.

If Python gives 1.0 but pgvector gives 0.668, the issue is in how we pass
the vector to PostgreSQL.
"""

import os
import numpy as np

os.environ.setdefault("EMBEDDING_PROVIDER", os.environ.get("EMBEDDING_PROVIDER", "openrouter"))

from ai_service.config import settings
from ai_service.embedding_factory import create_embeddings
from ai_service.database import normalize_psycopg_dsn
import psycopg


def main():
    dsn = normalize_psycopg_dsn(settings.DATABASE_URL)
    embeddings = create_embeddings(settings)

    with psycopg.connect(dsn) as conn:
        # Get stored chunk
        with conn.cursor() as cur:
            cur.execute("""
                SELECT content, embedding::text
                FROM knowledge_base_chunks
                WHERE source = 'matricula.md'
                ORDER BY chunk_index LIMIT 1
            """)
            content, stored_vec_str = cur.fetchone()

        stored_vec = [float(x) for x in stored_vec_str.strip("[]").split(",")]

        # Generate query embedding for EXACT same text
        query_vec = embeddings.embed_query(content)

        # Method 1: str(list) — what rag.py does
        vector_str_method1 = str(query_vec)

        # Method 2: pgvector-style format "[0.1, 0.2, ...]"
        vector_str_method2 = "[" + ",".join(f"{v:.12f}" for v in query_vec) + "]"

        print(f"Method 1 (str(list)) first 60 chars: {vector_str_method1[:60]}")
        print(f"Method 2 (formatted) first 60 chars: {vector_str_method2[:60]}")
        print(f"Method 1 length: {len(vector_str_method1)}")
        print(f"Method 2 length: {len(vector_str_method2)}")

        # Python cosine
        a, b = np.array(query_vec), np.array(stored_vec)
        python_sim = float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))
        print(f"\nPython cosine similarity: {python_sim:.6f}")

        # pgvector with method 1 (what rag.py uses)
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    1 - (embedding <=> %s::vector) AS sim_method1
                FROM knowledge_base_chunks
                WHERE source = 'matricula.md'
                ORDER BY chunk_index LIMIT 1
            """, (vector_str_method1,))
            sim1 = cur.fetchone()[0]

        print(f"pgvector with str(list):  {sim1:.6f}")

        # pgvector with method 2 (formatted)
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    1 - (embedding <=> %s::vector) AS sim_method2
                FROM knowledge_base_chunks
                WHERE source = 'matricula.md'
                ORDER BY chunk_index LIMIT 1
            """, (vector_str_method2,))
            sim2 = cur.fetchone()[0]

        print(f"pgvector with formatted:  {sim2:.6f}")

        # Check if str(list) truncates precision
        print(f"\n{'='*70}")
        print("COMPARACAO DE FORMATO: primeiros 5 valores")
        print(f"{'='*70}")
        print(f"{'idx':>4} | {'float original':>25} | {'str(list) parse':>25} | {'formatted parse':>25}")
        print("-" * 110)

        # Parse method1 back to see what pgvector receives
        # str(list) produces something like "[0.005924224853515625, ...]"
        m1_parsed = vector_str_method1.strip("[]").split(", ")
        m2_parsed = vector_str_method2.strip("[]").split(",")

        for i in range(5):
            orig = query_vec[i]
            m1 = m1_parsed[i]
            m2 = m2_parsed[i]
            print(f"{i:>4} | {orig:>25.18f} | {m1:>25s} | {m2:>25s}")

        # Check vector dimensions pgvector receives
        with conn.cursor() as cur:
            cur.execute("SELECT vector_dims(%s::vector)", (vector_str_method1,))
            dim1 = cur.fetchone()[0]
            cur.execute("SELECT vector_dims(%s::vector)", (vector_str_method2,))
            dim2 = cur.fetchone()[0]

        print(f"\npgvector parsed dimensions — method1: {dim1}, method2: {dim2}")
        print(f"Original vector length: {len(query_vec)}")

        if dim1 != len(query_vec):
            print(f"\n>>> PROBLEMA: pgvector recebe {dim1} dimensoes mas o vetor tem {len(query_vec)}!")
            print(f">>> str(list) pode estar truncando ou causando parse errado")


if __name__ == "__main__":
    main()
