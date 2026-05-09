---
phase: 05-ai-service
plan: "05-11"
reviewed: 2026-05-02T21:30:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - mcp_server/api_client.py
  - mcp_server/tools/student_tools.py
  - mcp_server/tools/enrollment_tools.py
  - mcp_server/tools/grade_tools.py
  - mcp_server/tools/document_tools.py
  - mcp_server/tools/scheduling_tools.py
  - mcp_server/tools/curriculum_tools.py
  - mcp_server/tests/test_api_client.py
  - mcp_server/tests/test_tool_http_wiring.py
  - mcp_server/tests/test_tool_schemas.py
  - ai_service/prompts/system_prompt.txt
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 05 (Plan 05-11): Code Review Report

**Reviewed:** 2026-05-02T21:30:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Plan 05-11 is a gap-closure plan for the MCP Server tools and AI service. The code is well-structured: tools follow a consistent pattern (dependency-injected `student_id`, `call_api` wrapper with retry logic, proper `ToolError` propagation). The `api_client.py` retry mechanism correctly distinguishes 4xx (no retry) from 5xx/timeout (one retry), matching the project conventions. The `student_id` is properly hidden from LLM-exposed tool schemas and injected via `Depends(resolve_student_id)` — the core IDOR-prevention security constraint is satisfied.

Three warnings and three info-level items were found. No critical security issues.

## Warnings

### WR-01: RAG Threshold Inconsistency Between System Prompt and Documentation

**File:** `ai_service/prompts/system_prompt.txt:12`
**Issue:** The system prompt instructs the LLM to treat scores below `0.45` as irrelevant:
```
Se a base de conhecimento nao retornar contexto relevante (score < 0.45), informe...
```
However, every architecture document (`docs/chatbot.md` lines 27, 47, 193, 237-238, 406) defines the RAG threshold as `0.75`. The `ai_service/config.py` defaults `RAG_SIMILARITY_THRESHOLD` to `0.45`, which is the runtime threshold used in `ai_service/rag.py`.

This means the system has two conflicting thresholds:
- **Runtime RAG retrieval** (config.py + rag.py): filters chunks at `0.45` — chunks between 0.45 and 0.75 *are* returned to the agent.
- **Documentation** (chatbot.md): says chunks below `0.75` should be discarded.

The system prompt's `0.45` aligns with the runtime default but contradicts the architectural decision. If the runtime threshold is intentionally `0.45` (after experimentation with `test_rag_length.py` showing 0.75 is too aggressive for short queries), the documentation should be updated. If 0.75 is correct, the config default and system prompt should change.

**Fix:** Align all three sources. If 0.45 is the tested threshold:
```
# docs/chatbot.md — update threshold references from 0.75 to 0.45
# system_prompt.txt — already correct at 0.45
# config.py — already correct at 0.45
```
If 0.75 is the intended threshold:
```python
# ai_service/config.py line 38
RAG_SIMILARITY_THRESHOLD: float = float(
    os.environ.get("RAG_SIMILARITY_THRESHOLD", "0.75")
)
```
```
# system_prompt.txt line 12
Se a base de conhecimento nao retornar contexto relevante (score < 0.75), informe
```

### WR-02: `request_document` Has No Input Validation on `type` Parameter

**File:** `mcp_server/tools/document_tools.py:17-18`
**Issue:** The `request_document` tool accepts a bare `type: str` parameter, relying entirely on the backend (`docs/api.md`, `backend/src/features/documents/schemas.py:26`) to validate that `type` is one of `transcript`, `enrollment_proof`, `declaration`, `certificate`. The tool description mentions valid types, but the LLM could hallucinate an invalid value (e.g., `"grade_report"`), which would result in a 422 error from the backend.

While the backend does validate, this violates defense-in-depth — the MCP tool should constrain its own inputs. The `docs/mcp.md` (line 363) even defines `"enum": ["transcript", "enrollment_proof", "declaration", "certificate"]` in the schema — the implementation doesn't enforce it.

**Fix:** Use `Literal` type to constrain the parameter:
```python
from typing import Literal

async def request_document(
    type: Literal["transcript", "enrollment_proof", "declaration", "certificate"],
    student_id: str = Depends(resolve_student_id),
    ctx: Context = CurrentContext(),
) -> dict[str, Any]:
```

### WR-03: `type` Parameter Shadows Python Built-in

**File:** `mcp_server/tools/document_tools.py:18`
**Issue:** The parameter name `type` shadows Python's built-in `type()` function. While this doesn't cause a runtime bug in this specific function (the built-in isn't used), it's a common code quality anti-pattern that linters flag (e.g., `A002` in Ruff/flake8-builtins). The `docs/mcp.md` schema uses `type` as the field name, so this mirrors the API contract — but the internal parameter name can differ.

**Fix:** Rename the internal parameter to `document_type` and map it in the JSON body:
```python
async def request_document(
    document_type: str,  # or Literal[...] per WR-02
    student_id: str = Depends(resolve_student_id),
    ctx: Context = CurrentContext(),
) -> dict[str, Any]:
    client = ctx.lifespan_context["http_client"]
    data, _ = await call_api(
        client,
        "POST",
        "/documents",
        json={"student_id": student_id, "type": document_type},
        student_id=student_id,
    )
    return data
```
Note: Verify that FastMCP exposes the parameter name to the LLM schema. If the LLM-facing schema must say `type`, use `Field(alias="type")` or keep the name and suppress the linter warning.

## Info

### IN-01: Unused `asyncio` Import in Test File

**File:** `mcp_server/tests/test_tool_http_wiring.py:3`
**Issue:** `import asyncio` is present but never used. The file uses `pytest.mark.asyncio` (from pytest-asyncio), not `asyncio.run()`. The sibling file `test_tool_schemas.py` correctly uses `asyncio.run()` for its synchronous test functions, but `test_tool_http_wiring.py` uses async test functions with `pytestmark = pytest.mark.asyncio` instead.
**Fix:** Remove the unused import:
```python
# Remove line 3: import asyncio
```

### IN-02: System Prompt Uses ASCII Instead of UTF-8 Portuguese

**File:** `ai_service/prompts/system_prompt.txt:1-13`
**Issue:** The system prompt avoids all accented characters (`Voce` instead of `Você`, `acoes` instead of `ações`, `matricula` instead of `matrícula`, `nao` instead of `não`). This is the text the LLM sees as its identity and behavioral instructions. While the LLM will still respond with proper Portuguese regardless, the prompt itself reads unnaturally and could subtly affect tone quality. This may be intentional (ASCII-safe for cross-platform compatibility) but is worth noting.
**Fix:** If UTF-8 encoding is guaranteed in the Docker container (standard for Python 3.12), use proper Portuguese:
```
Você é o assistente virtual da secretaria acadêmica do curso de Ciência da Computação.
```

### IN-03: `student_id` Included in POST JSON Bodies Despite Header Injection

**File:** `mcp_server/tools/enrollment_tools.py:29`, `mcp_server/tools/document_tools.py:27`, `mcp_server/tools/scheduling_tools.py:54`
**Issue:** Several tools send `student_id` both in the `X-Student-Id` header (via `call_api(student_id=...)`) AND in the JSON request body (e.g., `json={"student_id": student_id, ...}`). This is functionally correct — the backend uses the header for auth context and the body for resource creation — but creates a dual-path for the same identity value. If the backend ever validates that header and body `student_id` match, this is fine. If not, it's a potential IDOR vector if the two values diverge (though in this code they can't, since both come from `resolve_student_id`).

This is an informational note, not a bug — the current code is safe because both values come from the same dependency-injected source.
**Fix:** No action required unless the team wants to remove the body `student_id` and have the backend extract it solely from the header. This would be a backend API contract change.

---

_Reviewed: 2026-05-02T21:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
