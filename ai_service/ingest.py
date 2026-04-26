from __future__ import annotations

import argparse
import json
import logging
import os
import time
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import psycopg

from ai_service.database import normalize_psycopg_dsn

LOGGER = logging.getLogger("ai_service.ingest")
KNOWLEDGE_DIR = Path(__file__).parent / "knowledge"
AUDIT_PATH = KNOWLEDGE_DIR / ".last_ingest.json"
EMBEDDING_MODEL = "text-embedding-3-small"

CATEGORY_MAP = {
    "matricula.md": "regras_matricula",
    "regulamento.pdf": "regulamento",
    "faq.md": "faq",
    "calendario.md": "agendamento",
    "curriculo.md": "curriculo",
}


@dataclass(frozen=True)
class IngestSettings:
    database_url: str
    openai_api_key: str

    @classmethod
    def from_env(cls) -> "IngestSettings":
        database_url = os.environ.get("DATABASE_URL")
        openai_api_key = os.environ.get("OPENAI_API_KEY")

        missing = [
            name
            for name, value in {
                "DATABASE_URL": database_url,
                "OPENAI_API_KEY": openai_api_key,
            }.items()
            if not value
        ]
        if missing:
            missing_str = ", ".join(missing)
            raise RuntimeError(
                f"Missing required environment variables: {missing_str}"
            )

        return cls(
            database_url=normalize_psycopg_dsn(database_url),
            openai_api_key=openai_api_key,
        )


@dataclass(frozen=True)
class ChunkRecord:
    source: str
    category: str
    chunk_index: int
    content: str


def configure_logging() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def ensure_known_sources(source_dir: Path) -> list[Path]:
    missing = [name for name in CATEGORY_MAP if not (source_dir / name).exists()]
    if missing:
        missing_str = ", ".join(missing)
        raise FileNotFoundError(f"Knowledge files not found: {missing_str}")

    return [source_dir / name for name in CATEGORY_MAP]


def load_document(source_path: Path) -> str:
    suffix = source_path.suffix.lower()
    if suffix == ".md":
        return source_path.read_text(encoding="utf-8")

    if suffix == ".pdf":
        return load_pdf_document(source_path)

    raise ValueError(f"Unsupported knowledge file type: {source_path.name}")


def load_pdf_document(source_path: Path) -> str:
    from langchain_community.document_loaders import PyPDFLoader

    try:
        pages = PyPDFLoader(str(source_path)).load()
        text = "\n\n".join(page.page_content for page in pages).strip()
        if text:
            return text
        LOGGER.warning("PDF loader returned empty content for %s", source_path.name)
    except Exception as exc:  # pragma: no cover - depends on runtime parser behavior
        LOGGER.warning("Failed to parse %s as PDF: %s", source_path.name, exc)

    fallback_text = source_path.read_text(encoding="utf-8", errors="ignore").strip()
    if not fallback_text:
        raise ValueError(f"No readable content found in {source_path.name}")
    LOGGER.info("Using plain-text fallback for %s", source_path.name)
    return fallback_text


def build_chunks(text: str, chunk_size: int, overlap: int) -> list[str]:
    from langchain_text_splitters import RecursiveCharacterTextSplitter

    splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(
        chunk_size=chunk_size,
        chunk_overlap=overlap,
        encoding_name="cl100k_base",
    )
    return [chunk.strip() for chunk in splitter.split_text(text) if chunk.strip()]


def embed_chunks(chunks: list[str], api_key: str) -> list[list[float]]:
    from langchain_openai import OpenAIEmbeddings

    embeddings = OpenAIEmbeddings(
        model=EMBEDDING_MODEL,
        api_key=api_key,
    )
    return embeddings.embed_documents(chunks)


def vector_to_pgvector(vector: Iterable[float]) -> str:
    return "[" + ", ".join(f"{value:.12f}" for value in vector) + "]"


def replace_source_chunks(
    conn: psycopg.Connection,
    chunk_records: list[ChunkRecord],
    vectors: list[list[float]],
) -> int:
    if not chunk_records:
        return 0

    source_name = chunk_records[0].source
    with conn.cursor() as cur:
        cur.execute(
            "DELETE FROM knowledge_base_chunks WHERE source = %s",
            [source_name],
        )
        for chunk_record, vector in zip(chunk_records, vectors, strict=True):
            cur.execute(
                """
                INSERT INTO knowledge_base_chunks (
                    content,
                    embedding,
                    source,
                    category,
                    chunk_index
                )
                VALUES (%s, %s::vector, %s, %s, %s)
                """,
                [
                    chunk_record.content,
                    vector_to_pgvector(vector),
                    chunk_record.source,
                    chunk_record.category,
                    chunk_record.chunk_index,
                ],
            )

    return len(chunk_records)


def write_audit_summary(summary: dict[str, object]) -> None:
    AUDIT_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def print_report(summary: dict[str, object]) -> None:
    print("Knowledge base ingestion complete")
    print(f"Documents processed: {summary['documents_processed']}")
    print(f"Total chunks: {summary['total_chunks']}")
    print("Chunks by category:")
    for category, count in summary["chunks_by_category"].items():
        print(f"- {category}: {count}")
    print(f"Execution time (s): {summary['execution_time_seconds']}")
    print(f"Audit file: {summary['audit_file']}")


def main(source: str, chunk_size: int, overlap: int) -> dict[str, object]:
    configure_logging()
    settings = IngestSettings.from_env()
    source_dir = Path(source).resolve()

    if not source_dir.exists():
        raise FileNotFoundError(f"Knowledge directory not found: {source_dir}")

    start_time = time.perf_counter()
    documents_processed = 0
    total_chunks = 0
    chunks_by_category: Counter[str] = Counter()

    with psycopg.connect(settings.database_url) as conn:
        for source_path in ensure_known_sources(source_dir):
            category = CATEGORY_MAP[source_path.name]
            content = load_document(source_path)
            chunk_texts = build_chunks(content, chunk_size=chunk_size, overlap=overlap)
            if not chunk_texts:
                LOGGER.warning("Skipping %s because no chunks were generated", source_path.name)
                continue

            chunk_records = [
                ChunkRecord(
                    source=source_path.name,
                    category=category,
                    chunk_index=index,
                    content=chunk_text,
                )
                for index, chunk_text in enumerate(chunk_texts)
            ]
            vectors = embed_chunks(chunk_texts, settings.openai_api_key)
            inserted_count = replace_source_chunks(conn, chunk_records, vectors)
            conn.commit()

            documents_processed += 1
            total_chunks += inserted_count
            chunks_by_category[category] += inserted_count
            LOGGER.info(
                "Processed %s with %s chunks",
                source_path.name,
                inserted_count,
            )

    execution_time = round(time.perf_counter() - start_time, 3)
    summary = {
        "documents_processed": documents_processed,
        "total_chunks": total_chunks,
        "chunks_by_category": dict(sorted(chunks_by_category.items())),
        "execution_time_seconds": execution_time,
        "source_directory": str(source_dir),
        "chunk_size": chunk_size,
        "chunk_overlap": overlap,
        "embedding_model": EMBEDDING_MODEL,
        "audit_file": str(AUDIT_PATH),
    }
    write_audit_summary(summary)
    print_report(summary)
    return summary


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest knowledge base documents")
    parser.add_argument(
        "--source",
        default=str(KNOWLEDGE_DIR),
        help="Path to knowledge docs",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=500,
        help="Chunk size in tokens",
    )
    parser.add_argument(
        "--overlap",
        type=int,
        default=50,
        help="Chunk overlap in tokens",
    )
    arguments = parser.parse_args()
    main(arguments.source, arguments.chunk_size, arguments.overlap)
