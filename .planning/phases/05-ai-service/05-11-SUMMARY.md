---
phase: 05-ai-service
plan: 11
subsystem: mcp, ai
tags: [httpx, header-injection, X-Student-Id, fastmcp, rag, system-prompt]

# Dependency graph
requires:
  - phase: 04-mcp-server
    provides: MCP tool infrastructure with call_api, resolve_student_id, and FastMCP DI
  - phase: 05-ai-service
    provides: RAG pipeline with configurable similarity threshold
provides:
  - Centralized X-Student-Id header injection via api_client.py student_id kwarg
  - All 16 MCP tools now send X-Student-Id on every proxied request to FastAPI
  - System prompt RAG threshold corrected to match code default (0.45)
  - 4 regression tests proving header injection behavior
affects: [06-whatsapp-webhook]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Centralized header injection in api_client.py — tools pass student_id kwarg, client merges into headers"
    - "All MCP tools resolve student_id via Depends(resolve_student_id) for X-Student-Id header injection"

key-files:
  created: []
  modified:
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

key-decisions:
  - "Centralized student_id kwarg in call_api_raw/call_api rather than per-tool header manipulation"
  - "All 16 tools now resolve student_id even if they don't use it in URL/body — backend requires X-Student-Id on all X-Service-Token requests"

patterns-established:
  - "Header injection pattern: tools pass student_id to call_api, which merges X-Student-Id into headers before httpx.request()"
  - "STUDENT_SCOPED_TOOLS == EXPECTED_TOOL_NAMES: every tool resolves student_id via DI"

requirements-completed: [AI-03, AI-04, MCP-02]

# Metrics
duration: 4min
completed: 2026-05-02
---

# Phase 05 Plan 11: MCP X-Student-Id Header Injection + System Prompt RAG Threshold Fix Summary

**Centralized X-Student-Id header injection in api_client.py with student_id kwarg, wired through all 16 MCP tools, and corrected system prompt RAG threshold from 0.75 to 0.45**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-02T21:23:33Z
- **Completed:** 2026-05-02T21:28:19Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Fixed the IDENTIFICACAO_AUSENTE blocker: `call_api_raw` and `call_api` now accept a `student_id` kwarg and inject `X-Student-Id` header into every proxied request to FastAPI backend
- All 16 MCP tools updated to pass `student_id=student_id` to `call_api`; 9 tools that previously lacked `student_id` now resolve it via `Depends(resolve_student_id)`
- Fixed system prompt RAG threshold mismatch: changed 0.75 → 0.45 to match `RAG_SIMILARITY_THRESHOLD` code default
- Added 4 regression tests proving header injection, omission when None, merge with existing headers, and persistence on retry
- Updated `test_tool_http_wiring.py` TOOL_SPECS to expect `student_id` in all 16 call_api kwargs
- Updated `test_tool_schemas.py` STUDENT_SCOPED_TOOLS to cover all 16 tools; dead else branch removed

## Task Commits

Each task was committed atomically:

1. **Task 1: Centralized X-Student-Id injection in api_client.py + system prompt fix** - `88e2ccf` (fix)
2. **Task 2: Update all MCP tool files to pass student_id to call_api + add regression tests** - `cdcdf72` (feat)

## Files Created/Modified

- `mcp_server/api_client.py` — Added `student_id: str | None = None` kwarg to `call_api_raw` and `call_api`; merges `X-Student-Id` header when provided
- `mcp_server/tools/student_tools.py` — Added `student_id=student_id` to both `call_api` calls
- `mcp_server/tools/enrollment_tools.py` — Added `student_id` param (via Depends) to `confirm_enrollment`, `drop_course`, `lock_enrollment`; added `student_id=student_id` to all 4 `call_api` calls
- `mcp_server/tools/grade_tools.py` — Added `student_id=student_id` to both `call_api` calls
- `mcp_server/tools/document_tools.py` — Added `student_id` param to `get_document_status`; added `student_id=student_id` to both `call_api` calls
- `mcp_server/tools/scheduling_tools.py` — Added `student_id` param to `get_available_slots` and `cancel_appointment`; added `student_id=student_id` to all 3 `call_api` calls
- `mcp_server/tools/curriculum_tools.py` — Added `Depends` import, `resolve_student_id` import, `student_id` param to all 3 tools; added `student_id=student_id` to all `call_api` calls
- `mcp_server/tests/test_api_client.py` — 4 new regression tests for header injection
- `mcp_server/tests/test_tool_http_wiring.py` — All 16 TOOL_SPECS updated with `student_id` in kwargs and expected_kwargs
- `mcp_server/tests/test_tool_schemas.py` — STUDENT_SCOPED_TOOLS aliased to EXPECTED_TOOL_NAMES; simplified test
- `ai_service/prompts/system_prompt.txt` — RAG threshold corrected from 0.75 to 0.45

## Decisions Made

- **Centralized injection over per-tool headers:** `student_id` kwarg in `call_api_raw`/`call_api` keeps header logic in one place. Tools just pass the value through.
- **All 16 tools resolve student_id:** The backend requires `X-Student-Id` on every request that uses `X-Service-Token`. Even tools that don't use student_id in the URL/body (like `get_curriculum`) must send the header. This is why all tools now resolve it via DI.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all changes applied cleanly, all 42 relevant tests pass (10 api_client + 16 wiring + 3 schema + 10 middleware + 3 healthcheck).

## User Setup Required

None — no external service configuration required.

## Threat Surface Scan

No new threat surface introduced. The `X-Student-Id` header is derived server-side from DB-validated `chat_sessions` via `resolve_student_id` — never from agent input. The header value cannot be spoofed by the LLM agent (T-05-11-01 mitigated). The `student_id` parameter uses `Depends(resolve_student_id)` which is DI-injected by FastMCP, NOT exposed in tool input schemas (T-05-11-02 mitigated, verified by `test_student_id_is_hidden_from_all_tool_input_schemas`).

## Next Phase Readiness

- MCP → FastAPI integration unblocked: all tool calls will now include `X-Student-Id` header
- RAG grounding corrected: system prompt and code threshold aligned at 0.45
- Phase 06 (WhatsApp Webhook & Integration) can proceed with full end-to-end MCP tool execution
- Pre-existing issue: `test_compose_uses_package_entrypoint` fails due to relative path resolution inside Docker container — not related to this plan's changes

---
*Phase: 05-ai-service*
*Completed: 2026-05-02*

## Self-Check: PASSED

All 11 modified files verified present on disk. Both task commits (88e2ccf, cdcdf72) verified in git log.
