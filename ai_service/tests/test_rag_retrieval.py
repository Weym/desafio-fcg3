"""Behavioral coverage for RAG retrieval."""

from __future__ import annotations

import pytest

from ai_service.rag import SIMILARITY_THRESHOLD, create_rag_tool


class _FakeCursor:
    def __init__(self, rows):
        self.rows = rows
        self.calls = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def execute(self, query, params):
        self.calls.append((query, params))

    def fetchall(self):
        return self.rows


class _FakeConnection:
    def __init__(self, cursor):
        self._cursor = cursor

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def cursor(self):
        return self._cursor


class _FakePool:
    def __init__(self, cursor):
        self._cursor = cursor

    def connection(self):
        return _FakeConnection(self._cursor)


def test_retrieval_uses_threshold_and_formats_top_chunks(monkeypatch: pytest.MonkeyPatch) -> None:
    class FakeEmbeddings:
        def __init__(self):
            self.query = None

        def embed_query(self, query: str):
            self.query = query
            return [0.1, 0.2]

    rows = [
        ("Prazo de matrícula até sexta.", "matricula.md", "regras_matricula", 0.91),
        ("Trancamento vai até 30/04.", "calendario.md", "agendamento", 0.80),
    ]
    cursor = _FakeCursor(rows)
    fake_embeddings = FakeEmbeddings()

    tool = create_rag_tool(_FakePool(cursor), fake_embeddings)
    result = tool.func("prazo de matrícula")

    assert "Prazo de matrícula até sexta." in result
    assert "Trancamento vai até 30/04." in result
    assert cursor.calls[0][1] == ("[0.1, 0.2]", "[0.1, 0.2]", SIMILARITY_THRESHOLD)
    assert "LIMIT 3" in cursor.calls[0][0]


def test_retrieval_returns_empty_string_when_no_chunk_meets_threshold(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    class FakeEmbeddings:
        def embed_query(self, query: str):
            return [0.3, 0.4]

    cursor = _FakeCursor([])

    tool = create_rag_tool(_FakePool(cursor), FakeEmbeddings())

    assert tool.func("assunto sem resultado") == ""
