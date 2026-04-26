"""Behavioral coverage for knowledge-base ingest."""

from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace

from ai_service import ingest


class _FakeCursor:
    def __init__(self):
        self.statements = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def execute(self, query, params):
        normalized = " ".join(str(query).split())
        self.statements.append((normalized, list(params)))


class _FakeConnection:
    def __init__(self):
        self.cursor_instance = _FakeCursor()
        self.commit_count = 0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def cursor(self):
        return self.cursor_instance

    def commit(self):
        self.commit_count += 1


def test_ingest_processes_known_documents_and_writes_audit_summary(
    monkeypatch,
    tmp_path: Path,
    capsys,
) -> None:
    source_dir = tmp_path / "knowledge"
    source_dir.mkdir()
    for filename in ingest.CATEGORY_MAP:
        (source_dir / filename).write_text(f"conteudo de {filename}", encoding="utf-8")

    audit_path = tmp_path / ".last_ingest.json"
    fake_connection = _FakeConnection()

    monkeypatch.setattr(
        "ai_service.ingest.AUDIT_PATH",
        audit_path,
    )
    monkeypatch.setattr(
        "ai_service.ingest.IngestSettings.from_env",
        classmethod(
            lambda cls: SimpleNamespace(
                database_url="postgresql://db",
                openai_api_key="openai-key",
            )
        ),
    )
    monkeypatch.setattr(
        "ai_service.ingest.psycopg.connect",
        lambda database_url: fake_connection,
    )
    monkeypatch.setattr(
        "ai_service.ingest.load_document",
        lambda path: f"texto:{path.name}",
    )
    monkeypatch.setattr(
        "ai_service.ingest.build_chunks",
        lambda text, chunk_size, overlap: [f"{text}-parte-1", f"{text}-parte-2"],
    )
    monkeypatch.setattr(
        "ai_service.ingest.embed_chunks",
        lambda chunks, api_key: [[0.1, 0.2], [0.3, 0.4]],
    )

    summary = ingest.main(str(source_dir), chunk_size=500, overlap=50)
    output = capsys.readouterr().out
    audit = json.loads(audit_path.read_text(encoding="utf-8"))

    assert summary["documents_processed"] == 5
    assert summary["total_chunks"] == 10
    assert summary["chunks_by_category"] == {
        "agendamento": 2,
        "curriculo": 2,
        "faq": 2,
        "regras_matricula": 2,
        "regulamento": 2,
    }
    assert audit["embedding_model"] == "text-embedding-3-small"
    assert "Documents processed: 5" in output
    assert "Total chunks: 10" in output
    assert fake_connection.commit_count == 5

    deletes = [statement for statement in fake_connection.cursor_instance.statements if statement[0].startswith("DELETE FROM knowledge_base_chunks")]
    inserts = [statement for statement in fake_connection.cursor_instance.statements if statement[0].startswith("INSERT INTO knowledge_base_chunks")]

    assert len(deletes) == 5
    assert len(inserts) == 10
    assert deletes[0][1] == ["matricula.md"]
    inserted_categories = {statement[1][3] for statement in inserts}
    assert inserted_categories == set(ingest.CATEGORY_MAP.values())
