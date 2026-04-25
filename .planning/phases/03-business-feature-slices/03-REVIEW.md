---
phase: 03-business-feature-slices
reviewed: 2026-04-25T00:00:00Z
depth: standard
files_reviewed: 48
files_reviewed_list:
  - backend/alembic/versions/008_add_notes_to_documents.py
  - backend/alembic/versions/009_add_locked_status_to_enrollments.py
  - backend/scripts/verify_enrollment_lock_gap.py
  - backend/src/features/appointments/__init__.py
  - backend/src/features/appointments/controllers.py
  - backend/src/features/appointments/routes.py
  - backend/src/features/appointments/schemas.py
  - backend/src/features/appointments/services.py
  - backend/src/features/courses/controllers.py
  - backend/src/features/courses/routes.py
  - backend/src/features/courses/schemas.py
  - backend/src/features/courses/services.py
  - backend/src/features/documents/controllers.py
  - backend/src/features/documents/models.py
  - backend/src/features/documents/routes.py
  - backend/src/features/documents/schemas.py
  - backend/src/features/documents/services.py
  - backend/src/features/enrollment/controllers.py
  - backend/src/features/enrollment/models.py
  - backend/src/features/enrollment/routes.py
  - backend/src/features/enrollment/schemas.py
  - backend/src/features/enrollment/services.py
  - backend/src/features/grades/__init__.py
  - backend/src/features/grades/controllers.py
  - backend/src/features/grades/routes.py
  - backend/src/features/grades/schemas.py
  - backend/src/features/grades/services.py
  - backend/src/features/staff/__init__.py
  - backend/src/features/staff/controllers.py
  - backend/src/features/staff/routes.py
  - backend/src/features/staff/schemas.py
  - backend/src/features/staff/services.py
  - backend/src/features/students/__init__.py
  - backend/src/features/students/controllers.py
  - backend/src/features/students/routes.py
  - backend/src/features/students/schemas.py
  - backend/src/features/students/services.py
  - backend/src/main.py
  - backend/src/shared/__init__.py
  - backend/src/shared/base_service.py
  - backend/src/shared/dependencies.py
  - backend/src/shared/exceptions.py
  - backend/src/shared/pagination.py
  - backend/src/shared/responses.py
  - backend/tests/integration/test_students_available_courses.py
  - backend/tests/unit/test_grades_cra.py
  - backend/tests/unit/test_students_academic_summary.py
  - docs/api.md
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 48
**Status:** issues_found

## Summary

Re-review covered the Phase 03 business feature slices, shared backend infrastructure, relevant migrations/scripts, and the public API contract in `docs/api.md`. The major remaining problems are API contract mismatches and a couple of server-side validation gaps that can still produce incorrect behavior or uncaught database/integrity failures.

## Warnings

### WR-01: Service-token auth trusts any `X-Student-Id` without verifying the student exists

**File:** `backend/src/shared/dependencies.py:81-116`
**Issue:** The service-token branch accepts any syntactically valid UUID and returns `UserContext(role="service")` without checking whether that student exists or is active. Endpoints such as document creation, enrollment creation, and appointment booking then use `user.id` directly. A bad internal caller (or a leaked service token) can therefore target a nonexistent student and trigger downstream foreign-key errors/500s instead of a controlled 401/404.
**Fix:** Validate `x_student_id` against the students table before returning `UserContext`, and reject missing/inactive/nonexistent students with a canonical auth or not-found error.

```python
from src.features.auth.models import Student
from sqlalchemy import select

student = await db.execute(select(Student.id).where(Student.id == student_id, Student.status == "active"))
if student.scalar_one_or_none() is None:
    raise _unauthorized("IDENTIFICACAO_INVALIDA", "Aluno da chamada de servico nao existe")
```

### WR-02: Student update path can raise raw integrity errors for duplicate unique fields

**File:** `backend/src/features/students/services.py:152-161`
**Issue:** `update_student()` applies incoming fields directly and relies on `BaseService.update()`. Unlike `create_student()`, it does not pre-check uniqueness for fields such as `email` (and `phone`, if present), even though the model enforces unique constraints. Updating a student to a duplicate value can therefore bubble up as an uncaught database `IntegrityError` instead of a controlled 409 business response.
**Fix:** Before calling `self.update(...)`, query for conflicting `email`/`phone` values owned by another student and raise `ConflictException` with the same business-level behavior used on create.

### WR-03: `GET /scheduling/slots` response shape does not match the documented API contract

**File:** `backend/src/features/appointments/controllers.py:55-73`
**Issue:** The endpoint returns a raw JSON array (`response_model=list[SlotResponse]`), but `docs/api.md:566-581` documents this route as returning `{ "data": [...] }`. This is a contract regression for clients generated or implemented from the published API docs.
**Fix:** Either wrap the returned list in the documented envelope or update `docs/api.md` so implementation and published contract match exactly.

### WR-04: `GET /enrollment-periods/current` response shape does not match the documented API contract

**File:** `backend/src/features/enrollment/controllers.py:64-79`
**Issue:** The controller returns `{ "data": period }` or `{ "data": null }`, while `docs/api.md:396-407` documents the successful response as the raw period object. This mismatch can break MCP or frontend consumers that are coded against the documented shape.
**Fix:** Return the raw `EnrollmentPeriodResponse` object when a period exists (and document the null case clearly), or update the docs and all consumers to the wrapped `{data: ...}` format.

---

_Reviewed: 2026-04-25T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
