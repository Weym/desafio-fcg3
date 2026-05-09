"""RAG tool for academic knowledge base lookups."""

from __future__ import annotations

import json
import logging
from typing import Any

from langchain_core.tools import tool

logger = logging.getLogger(__name__)

MAX_RESULTS = 3


def _log_rag_invocation(
    db_pool: Any,
    session_id: str | None,
    query: str,
    chunks_list: list[dict],
    threshold_met: bool,
) -> None:
    """Log RAG invocation to rag_logs table. Non-blocking — failures are logged as warnings."""
    if not session_id:
        return
    try:
        with db_pool.connection() as conn:
            with conn.cursor() as cur:
                # Get the latest chat_message_id for this session (the user message that triggered this RAG call)
                cur.execute(
                    """SELECT id FROM chat_messages
                       WHERE chat_session_id = %s::uuid AND role = 'user'
                       ORDER BY created_at DESC LIMIT 1""",
                    (session_id,),
                )
                row = cur.fetchone()
                if not row:
                    return
                chat_message_id = row[0]
                cur.execute(
                    """INSERT INTO rag_logs (chat_message_id, query, chunks_retrieved, threshold_met)
                       VALUES (%s, %s, %s::jsonb, %s)""",
                    (chat_message_id, query, json.dumps(chunks_list), threshold_met),
                )
            conn.commit()
    except Exception as exc:
        logger.warning("Failed to log RAG invocation: %s", exc)


def create_rag_tool(
    db_pool: Any,
    embeddings: Any,
    similarity_threshold: float = 0.45,
    session_id: str | None = None,
):
    """Create the LangChain knowledge-base search tool bound to a DB pool."""

    @tool
    def search_knowledge_base(search_query: str) -> str:
        """Pesquisa a base de conhecimento academica para responder duvidas sobre regras, regulamentos, prazos, curriculo e politicas do curso de Ciencia da Computacao. Use esta tool para perguntas de regulamento e orientacao academica; para consultar dados do aluno ou executar acoes, prefira as MCP tools."""

        normalized_query = search_query.strip()
        if not normalized_query:
            return ""

        query_vector = embeddings.embed_query(normalized_query)
        vector_str = str(query_vector)

        query = """
            SELECT
                content,
                source,
                category,
                1 - (embedding <=> %s::vector) AS similarity
            FROM knowledge_base_chunks
            WHERE 1 - (embedding <=> %s::vector) >= %s
            ORDER BY similarity DESC
            LIMIT 3
        """

        with db_pool.connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    query,
                    (vector_str, vector_str, similarity_threshold),
                )
                rows = cursor.fetchall()

        if not rows:
            # Log RAG invocation even when no results found
            _log_rag_invocation(db_pool, session_id, normalized_query, [], False)
            return ""

        chunks: list[str] = []
        chunks_log: list[dict] = []
        for idx, (content, source, category, similarity) in enumerate(rows):
            chunks.append(
                "[Fonte: "
                f"{source} | Categoria: {category} | Relevancia: {similarity:.2f}]\n"
                f"{content}"
            )
            chunks_log.append({
                "source": source,
                "category": category,
                "score": round(float(similarity), 4),
                "chunk_index": idx,
            })

        # Log RAG invocation with retrieved chunks
        _log_rag_invocation(
            db_pool, session_id, normalized_query, chunks_log, True
        )

        return "\n\n---\n\n".join(chunks)

    return search_knowledge_base
