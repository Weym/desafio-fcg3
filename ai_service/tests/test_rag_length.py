"""Test: similarity of short query vs full chunk, and full chunk vs itself.

This confirms whether the low 0.668 score is simply because short queries
have naturally lower cosine similarity against long chunks.
"""

import os

os.environ.setdefault("EMBEDDING_PROVIDER", os.environ.get("EMBEDDING_PROVIDER", "openrouter"))

from ai_service.config import settings
from ai_service.embedding_factory import create_embeddings
from ai_service.database import normalize_psycopg_dsn
import psycopg


def run_query(conn, embeddings, query_text, label):
    query_vec = embeddings.embed_query(query_text)
    vector_str = str(query_vec)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT
                source,
                category,
                1 - (embedding <=> %s::vector) AS similarity,
                left(content, 80) AS preview
            FROM knowledge_base_chunks
            ORDER BY embedding <=> %s::vector
            LIMIT 3
        """, (vector_str, vector_str))
        rows = cur.fetchall()

    print(f"\n{'='*70}")
    print(f"{label}")
    print(f"Query length: {len(query_text)} chars")
    print(f"{'='*70}")
    for source, cat, sim, preview in rows:
        print(f"  [{sim:.6f}] {source} ({cat}): {preview.replace(chr(10), ' ')}...")

    return rows[0][2] if rows else 0


def main():
    dsn = normalize_psycopg_dsn(settings.DATABASE_URL)
    embeddings = create_embeddings(settings)

    print(f"Provider: {settings.EMBEDDING_PROVIDER}")
    print(f"Model: {settings.EMBEDDING_MODEL}")

    with psycopg.connect(dsn) as conn:
        # Get the full chunk text
        with conn.cursor() as cur:
            cur.execute("""
                SELECT content FROM knowledge_base_chunks
                WHERE source = 'matricula.md' ORDER BY chunk_index LIMIT 1
            """)
            full_chunk = cur.fetchone()[0]

        print(f"\nFull chunk length: {len(full_chunk)} chars")

        # Test 1: Full chunk text as query (should be ~1.0)
        s1 = run_query(conn, embeddings, full_chunk,
            "TEST 1: Query = texto COMPLETO do chunk (deve ser ~1.0)")

        # Test 2: Just the title (what was tested before)
        s2 = run_query(conn, embeddings, "Guia de Matricula e Rematricula",
            "TEST 2: Query = so o titulo (31 chars)")

        # Test 3: First sentence of the chunk
        first_sentence = "Este documento consolida as orientacoes academicas usadas pela secretaria do curso de Ciencia da Computacao para o periodo de matricula."
        s3 = run_query(conn, embeddings, first_sentence,
            "TEST 3: Query = primeira frase do chunk (137 chars)")

        # Test 4: First paragraph
        first_para = full_chunk[:full_chunk.index("### 1.")]
        s4 = run_query(conn, embeddings, first_para,
            f"TEST 4: Query = primeiro paragrafo ({len(first_para)} chars)")

        # Test 5: A medium-length relevant query
        s5 = run_query(conn, embeddings,
            "Quais sao os prazos e regras para fazer matricula no curso de Ciencia da Computacao? Preciso saber sobre pre-requisitos e limites de disciplinas.",
            "TEST 5: Query semantica media (148 chars)")

        # Summary
        print(f"\n{'='*70}")
        print("RESUMO — Relacao entre tamanho da query e similaridade")
        print(f"{'='*70}")
        print(f"  Chunk completo como query:    {s1:.6f} (baseline)")
        print(f"  Titulo (31 chars):            {s2:.6f}")
        print(f"  Primeira frase (137 chars):   {s3:.6f}")
        print(f"  Primeiro paragrafo:           {s4:.6f}")
        print(f"  Query semantica (148 chars):  {s5:.6f}")
        print()

        if s1 > 0.95 and s2 < 0.75:
            print("  >>> CONFIRMADO: A baixa similaridade e inerente ao modelo de embeddings.")
            print("  >>> Queries curtas contra chunks longos naturalmente produzem scores mais baixos.")
            print("  >>> O threshold de 0.75 e muito alto para este cenario — precisa ser ajustado.")
            print(f"  >>> Sugestao: threshold entre {s2 - 0.05:.2f} e {s5:.2f}")


if __name__ == "__main__":
    main()
