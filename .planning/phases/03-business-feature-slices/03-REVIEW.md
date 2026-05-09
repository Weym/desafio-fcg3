---
phase: 03-business-feature-slices
reviewed: 2026-04-25T18:45:00Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - backend/alembic/versions/008_add_notes_to_documents.py
  - backend/alembic/versions/009_add_locked_status_to_enrollments.py
  - backend/scripts/verify_enrollment_lock_gap.py
  - backend/src/features/appointments/controllers.py
  - backend/src/features/appointments/schemas.py
  - backend/src/features/appointments/services.py
  - backend/src/features/courses/controllers.py
  - backend/src/features/courses/models.py
  - backend/src/features/courses/schemas.py
  - backend/src/features/courses/services.py
  - backend/src/features/documents/controllers.py
  - backend/src/features/documents/models.py
  - backend/src/features/documents/schemas.py
  - backend/src/features/documents/services.py
  - backend/src/features/enrollment/controllers.py
  - backend/src/features/enrollment/models.py
  - backend/src/features/enrollment/schemas.py
  - backend/src/features/enrollment/services.py
  - backend/src/features/grades/controllers.py
  - backend/src/features/grades/services.py
  - backend/src/features/staff/schemas.py
  - backend/src/features/staff/services.py
  - backend/src/features/students/controllers.py
  - backend/src/features/students/models.py
  - backend/src/features/students/schemas.py
  - backend/src/features/students/services.py
  - backend/src/main.py
  - backend/src/shared/base_service.py
  - backend/src/shared/dependencies.py
  - backend/tests/integration/test_students_available_courses.py
  - backend/tests/unit/test_course_prerequisite_tree.py
  - backend/tests/unit/test_grades_cra.py
  - backend/tests/unit/test_students_academic_summary.py
  - docs/api.md
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-25T18:45:00Z
**Depth:** standard
**Files Reviewed:** 34
**Status:** issues_found

## Summary

Re-reviewed the current Phase 03 business-slice code after the 03-14 COURSE-03 repair. The prerequisite-tree recursion bug is now resolved and backed by focused regression coverage, so the previous COURSE-03 warning is stale and should remain closed.

Two Phase 03 issues still remain: one authorization gap on the draft-enrollment update route, and one enrollment-creation race that can still admit duplicate active enrollments under concurrent requests.

## Warnings

### WR-01: Draft enrollment update route still accepts service-token callers

**File:** `backend/src/features/enrollment/controllers.py:144-165`
**Issue:** `PUT /enrollments/{id}` is documented in `docs/api.md` as a student-only endpoint, but the controller uses `get_current_user_or_service` and never rejects `role="service"`. Any caller holding `X-Service-Token` plus an `X-Student-Id` can therefore mutate a student's draft enrollment through an endpoint that is not supposed to be MCP/service-accessible.
**Fix:** Restrict this route to JWT student auth only, or explicitly reject service/staff roles before calling the service.

```python
if user.role != "student":
    raise ForbiddenException("Esta acao requer autenticacao do aluno")
```

### WR-02: Enrollment creation is still vulnerable to duplicate-active races

**File:** `backend/src/features/enrollment/services.py:311-347`
**Issue:** `create_enrollment()` checks for an existing active enrollment and then inserts a new row without any lock or database uniqueness guarantee. Two concurrent requests for the same student and period can both pass the pre-check and create duplicate `draft`/`confirmed`/`locked` enrollments for the same term.
**Fix:** Enforce the invariant at the database boundary with a partial unique index on active statuses, then translate `IntegrityError` into the existing `MATRICULA_JA_EXISTENTE` conflict.

```python
CREATE UNIQUE INDEX uq_active_enrollment_per_period
ON enrollments (student_id, enrollment_period_id)
WHERE status IN ('draft', 'confirmed', 'locked');
```

---

_Reviewed: 2026-04-25T18:45:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
