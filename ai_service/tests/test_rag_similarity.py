"""Test RAG similarity determinism.

Runs the same query multiple times against the knowledge base to check:
1. Whether similarity scores are deterministic across runs
2. What the actual score range is for exact and semantic matches
"""

import os
import sys

# Ensure the env is set for the embedding provider
os.environ.setdefault("EMBEDDING_PROVIDER", os.environ.get("EMBEDDING_PROVIDER", "openrouter"))

from ai_service.config import settings
from ai_service.embedding_factory import create_embeddings
from ai_service.database import normalize_psycopg_dsn
import psycopg


def run_similarity_test(conn, embeddings, query: str, label: str, runs: int = 5):
    print(f"\n{'='*70}")
    print(f"TESTE: {label}")
    print(f"Query: \"{query}\"")
    print(f"Runs: {runs}")
    print(f"{'='*70}")

    scores_per_run = []

    for i in range(runs):
        query_vector = embeddings.embed_query(query)
        vector_str = str(query_vector)

        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    content,
                    source,
                    category,
                    1 - (embedding <=> %s::vector) AS similarity
                FROM knowledge_base_chunks
                ORDER BY similarity DESC
                LIMIT 3
                """,
                (vector_str,),
            )
            rows = cur.fetchall()

        top_score = rows[0][3] if rows else 0
        scores_per_run.append(top_score)

        print(f"\n  Run {i+1}: top similarity = {top_score:.6f}")
        for content, source, category, sim in rows[:2]:
            preview = content[:80].replace("\n", " ")
            print(f"    [{sim:.6f}] {source} ({category}): {preview}...")

    # Summary
    print(f"\n{'='*70}")
    print(f"RESUMO — {label}")
    print(f"{'='*70}")
    print(f"  Scores: {[f'{s:.6f}' for s in scores_per_run]}")
    print(f"  Min:    {min(scores_per_run):.6f}")
    print(f"  Max:    {max(scores_per_run):.6f}")
    print(f"  Delta:  {max(scores_per_run) - min(scores_per_run):.6f}")

    if max(scores_per_run) - min(scores_per_run) > 0.001:
        print(f"  >>> NAO-DETERMINISTICO: scores variam entre runs!")
    else:
        print(f"  >>> Deterministico: scores consistentes")

    return scores_per_run


def main():
    dsn = normalize_psycopg_dsn(settings.DATABASE_URL)
    embeddings = create_embeddings(settings)

    print(f"Provider: {settings.EMBEDDING_PROVIDER}")
    print(f"Model: {settings.EMBEDDING_MODEL}")

    with psycopg.connect(dsn) as conn:
        # Teste 1: Frase EXATA do titulo do documento
        run_similarity_test(
            conn, embeddings,
            "Guia de Matricula e Rematricula",
            "Frase exata do titulo",
            runs=5,
        )

        # Teste 2: Frase EXATA de um trecho do documento
        run_similarity_test(
            conn, embeddings,
            "A matricula regular ocorre duas vezes por ano, sempre antes do inicio letivo de cada semestre",
            "Frase exata do corpo do documento",
            runs=5,
        )

        # Teste 3: Query semantica normal
        run_similarity_test(
            conn, embeddings,
            "quais sao as regras de matricula?",
            "Query semantica simples",
            runs=5,
        )

    print("\n\nDone.")


if __name__ == "__main__":
    main()
