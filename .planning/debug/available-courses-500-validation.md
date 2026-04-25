---
status: investigating
trigger: "Truth: Fetching available courses for a student returns a successful list response containing only courses whose prerequisites are already satisfied by that student. Actual: Live verification of GET /api/v1/students/{id}/available-courses returned HTTP 500 Internal Server Error. Observed backend error: FastAPI ResponseValidationError: route declares response_model=list[AvailableCourseItem] but input was {'data': [...]}. Reproduction: call GET /api/v1/students/b14bbb63-0168-4d43-afba-b6bd200b9663/available-courses with valid X-Service-Token and matching X-Student-Id. Severity: blocker"
created: 2026-04-24T00:00:00Z
updated: 2026-04-24T00:10:00Z
---

## Current Focus

hypothesis: GET /students/{id}/available-courses has an internal API contract mismatch: service returns a list, but controller wraps it in {"data": ...} while the decorator still declares response_model=list[AvailableCourseItem]
test: compare service return type, controller return statement, schema shape, and API docs for the endpoint
expecting: evidence will show prerequisite logic succeeds but FastAPI fails during response serialization because controller returns a dict where response_model requires a list
next_action: record evidence and conclude whether the 500 is caused by the controller contract mismatch rather than prerequisite filtering logic

## Symptoms

expected: Fetching available courses for a student returns a successful list response containing only courses whose prerequisites are already satisfied by that student.
actual: GET /api/v1/students/{id}/available-courses returns HTTP 500 Internal Server Error during live verification.
errors: FastAPI ResponseValidationError because route declares response_model=list[AvailableCourseItem] but returned an object with a top-level data key instead of a raw list.
reproduction: Call GET /api/v1/students/b14bbb63-0168-4d43-afba-b6bd200b9663/available-courses with valid X-Service-Token and matching X-Student-Id.
started: Observed during Phase 03 UAT test 3.

## Eliminated

## Evidence

- timestamp: 2026-04-24T00:05:00Z
  checked: .planning/phases/03-business-feature-slices/03-UAT.md
  found: UAT records the live failure as FastAPI ResponseValidationError saying response_model=list[AvailableCourseItem] but the route returned an object with a top-level data key.
  implication: The runtime failure is happening in response validation/serialization, not in prerequisite filtering itself.

- timestamp: 2026-04-24T00:07:00Z
  checked: backend/src/features/students/controllers.py
  found: The available-courses route decorator declares response_model=list[AvailableCourseItem] on lines 168-171, but the handler returns {"data": [c.model_dump() for c in courses]} on line 183 and is even annotated as returning dict on line 176.
  implication: The controller implementation contradicts its declared FastAPI response contract, which would trigger ResponseValidationError.

- timestamp: 2026-04-24T00:08:00Z
  checked: backend/src/features/students/services.py and backend/src/features/students/schemas.py
  found: StudentService.get_available_courses returns list[AvailableCourseItem], and AvailableCourseItem is defined as the item schema for the endpoint list.
  implication: The service layer already produces the raw list shape FastAPI expects; the mismatch is introduced in the controller wrapper.

- timestamp: 2026-04-24T00:09:00Z
  checked: docs/api.md
  found: API docs for GET /students/{id}/available-courses show a wrapped response shape {"data": [ ... ]}.
  implication: The endpoint contract is inconsistent across code and docs; either the controller should declare a wrapped response model, or it should return the raw list. In the current code, docs/controller wrapper disagree with the decorator, causing the 500.
## Resolution

root_cause: The available-courses controller has a response contract mismatch. FastAPI is told to validate the response as list[AvailableCourseItem], but the handler wraps the service result in {"data": ...}. When FastAPI serializes the response, it receives a dict instead of the declared list and raises ResponseValidationError, producing HTTP 500.
fix: 
verification: 
files_changed: []
