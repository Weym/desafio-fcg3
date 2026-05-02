---
phase: 05-ai-service
reviewed: 2026-05-02T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - ai_service/config.py
  - ai_service/rag.py
  - ai_service/tests/test_rag_retrieval.py
  - mcp_server/middleware.py
  - mcp_server/tests/test_middleware_logging.py
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-05-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the files touched by Plan 05-10 (the gap-closure plan that made the RAG similarity threshold configurable and fixed the `mcp_action_logs` INSERT to populate the NOT NULL `id` column via `gen_random_uuid()`).

**Core refactors are correct:**

- **RAG threshold refactor** — `create_rag_tool` now accepts `similarity_threshold` as a keyword argument (default `0.45`), the module-level `SIMILARITY_THRESHOLD = 0.75` constant is gone, and the caller in `ai_service/agent.py` explicitly threads `settings.RAG_SIMILARITY_THRESHOLD` through. The parameter is referenced correctly inside the SQL `execute(...)` call, the defaults in `config.py` (`0.45`) and `rag.py` (`0.45`) agree, and the new unit tests exercise the custom-threshold path.
- **MCP INSERT fix** — The INSERT into `mcp_action_logs` now includes the `id` column populated by `gen_random_uuid()` as a SQL literal. Parameter numbering is intact: 8 placeholders (`$1..$8`) for 8 Python positional arguments (chat_session_id, tool_name, input_params, output_result, None, latency_ms, retry, effective_status). This matches the Alembic schema in `006_create_chat_knowledge_tables.py` where `id` is `UUID NOT NULL` with no server default. The success test adds an `"gen_random_uuid()" in query` assertion, and the 9-tuple unpacking of `await_args.args` in the existing tests correctly accounts for the unchanged parameter count.

**Security:** `_sanitize_input_params` continues to strip `student_id` before logging (project invariant preserved). `gen_random_uuid()` is a SQL literal, not interpolated user input — no injection risk. No hardcoded secrets.

One warning and four info-level items below, none blocking.

## Warnings

### WR-01: Test `test_retrieval_returns_empty_string_when_no_chunk_meets_threshold` does not actually exercise the threshold filter

**File:** `ai_service/tests/test_rag_retrieval.py:77-90`
**Issue:** The test name promises that the RAG tool returns `""` when no chunk meets the similarity threshold, but the fake cursor is seeded with `_FakeCursor([])` — i.e., the DB already returns zero rows regardless of threshold. The test verifies the empty-rows → empty-string code path, not the threshold-filtering behavior. There is no assertion that the threshold value was forwarded to the SQL `execute(...)` call in this test, nor is there a test that returns rows with similarity below the threshold to confirm the SQL `WHERE ... >= %s` clause was constructed with the configured value on the no-match path.

Given that the threshold refactor is the entire point of this gap plan, the no-match case should verify that the threshold was actually passed to the query — otherwise a future regression (e.g., accidentally re-introducing a hardcoded threshold, or shadowing the parameter) would go undetected here. The positive-path test (`test_retrieval_uses_threshold_and_formats_top_chunks`) and `test_retrieval_uses_custom_threshold` do assert `cursor.calls[0][1] == (..., ..., threshold)`, but only for cases where rows are returned.

**Fix:** Add a threshold assertion to the no-match test (cheap, one line):
```python
def test_retrieval_returns_empty_string_when_no_chunk_meets_threshold(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    class FakeEmbeddings:
        def embed_query(self, query: str):
            return [0.3, 0.4]

    cursor = _FakeCursor([])

    tool = create_rag_tool(
        _FakePool(cursor), FakeEmbeddings(), similarity_threshold=0.75
    )

    assert tool.func("assunto sem resultado") == ""
    # Regression guard: threshold must still be forwarded to SQL on no-match path.
    assert cursor.calls[0][1] == ("[0.3, 0.4]", "[0.3, 0.4]", 0.75)
```

## Info

### IN-01: Dead module constant `MAX_RESULTS = 3` in `ai_service/rag.py`

**File:** `ai_service/rag.py:10`
**Issue:** `MAX_RESULTS = 3` is defined at module scope but never referenced. The SQL query hardcodes `LIMIT 3` on line 40. This is leftover from before the threshold refactor and now has two sources of truth (one unused). If someone edits `MAX_RESULTS` thinking it controls the limit, the query will silently keep returning 3 rows.
**Fix:** Either inline `MAX_RESULTS` into the query via parameterization, or delete the constant:
```python
# Option A (preferred): parameterize
query = """
    SELECT content, source, category,
           1 - (embedding <=> %s::vector) AS similarity
    FROM knowledge_base_chunks
    WHERE 1 - (embedding <=> %s::vector) >= %s
    ORDER BY similarity DESC
    LIMIT %s
"""
cursor.execute(query, (vector_str, vector_str, similarity_threshold, MAX_RESULTS))

# Option B: delete the unused constant
# (remove line 10)
```

### IN-02: Unused `monkeypatch` parameter in two RAG tests

**File:** `ai_service/tests/test_rag_retrieval.py:50, 77`
**Issue:** `test_retrieval_uses_threshold_and_formats_top_chunks` and `test_retrieval_returns_empty_string_when_no_chunk_meets_threshold` accept a `monkeypatch: pytest.MonkeyPatch` argument but never use it. `test_retrieval_uses_custom_threshold` correctly omits it. Unused fixture parameters are harmless but add noise and can mislead readers into assuming some patching is happening.
**Fix:** Remove the `monkeypatch` parameter from those two tests:
```python
def test_retrieval_uses_threshold_and_formats_top_chunks() -> None:
    ...

def test_retrieval_returns_empty_string_when_no_chunk_meets_threshold() -> None:
    ...
```

### IN-03: `RAG_SIMILARITY_THRESHOLD` is not bounds-validated

**File:** `ai_service/config.py:37-39`
**Issue:** The env value is coerced with `float(...)` but not validated to be within the valid cosine-similarity range `[0.0, 1.0]`. The plan's threat model explicitly accepts this (T-05-10-01 in `05-10-PLAN.md`: misconfiguration is a self-evident error, not an attack vector), so this is intentional. Flagging only so the decision is traceable from the source: an operator who sets `RAG_SIMILARITY_THRESHOLD=-1` or `=2.0` gets either "everything matches" or "nothing matches" with no log warning at startup.
**Fix (optional)** — fail-loud validation at import time:
```python
RAG_SIMILARITY_THRESHOLD: float = float(
    os.environ.get("RAG_SIMILARITY_THRESHOLD", "0.45")
)

def __post_init__(self) -> None:
    # ... existing DATABASE_URL logic ...
    if not 0.0 <= self.RAG_SIMILARITY_THRESHOLD <= 1.0:
        raise ValueError(
            f"RAG_SIMILARITY_THRESHOLD must be in [0.0, 1.0], "
            f"got {self.RAG_SIMILARITY_THRESHOLD}"
        )
```
Per the ADR / threat model this is a "nice to have," not required.

### IN-04: Retry/error test paths do not re-assert `gen_random_uuid()` in the SQL

**File:** `mcp_server/tests/test_middleware_logging.py:66-93, 95-132`
**Issue:** The `gen_random_uuid()` assertion was added only to `test_tool_logging_middleware_logs_successful_calls` (line 55). The error-path test (`test_tool_logging_middleware_logs_errors_without_output`) and retry-success test (`test_tool_logging_middleware_records_retry_success_and_latency`) unpack `execute.await_args.args` but skip the `query` string check. Since all three paths go through the same `_log_call` method and the same SQL string, this is not a correctness gap — but if `_log_call` were ever split into success/error branches in the future, the error path could silently drop the `id` column again without test failure.
**Fix (defense in depth):** In the two tests that currently discard `query` via `_, _, _, ...`, bind it and assert once more:
```python
query, _, _, input_params, output_result, _, _, _, status = (
    mock_context.lifespan_context["db_pool"].execute.await_args.args
)
assert "gen_random_uuid()" in query
```

---

_Reviewed: 2026-05-02T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
