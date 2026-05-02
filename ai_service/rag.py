"""RAG tool for academic knowledge base lookups."""

from __future__ import annotations

from typing import Any

from langchain_core.tools import tool


MAX_RESULTS = 3


def create_rag_tool(
    db_pool: Any,
    embeddings: Any,
    similarity_threshold: float = 0.45,
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
            return ""

        chunks: list[str] = []
        for content, source, category, similarity in rows:
            chunks.append(
                "[Fonte: "
                f"{source} | Categoria: {category} | Relevancia: {similarity:.2f}]\n"
                f"{content}"
            )

        return "\n\n---\n\n".join(chunks)

    return search_knowledge_base
