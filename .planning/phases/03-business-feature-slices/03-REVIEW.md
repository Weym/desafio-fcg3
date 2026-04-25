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

Re-reviewed the original Phase 03 scope across the business feature slices, shared helpers, migrations, targeted tests, and API documentation. Most of the slice structure is consistent, but the enrollment lifecycle still has correctness gaps around locking, and the shared/student update paths still contain request-handling bugs that can surface as incorrect state transitions or unexpected 500s.

This report is the last pre-fix re-review captured by the `--auto` loop. The fixes described in `03-REVIEW-FIX.md` iteration 3 were applied after this review, but the workflow hit its iteration cap before a final post-fix re-review could confirm a clean state.

## Warnings

### WR-01: Cancelled enrollments can still be locked

**File:** `backend/src/features/enrollment/services.py:613-621`
**Issue:** `lock_enrollment()` only rejects the already-locked state. That means an enrollment in `cancelled` status can still be moved to `locked`, even though the method contract says locking is only valid from `draft` or `confirmed`. This breaks the enrollment state machine and can mutate records that should be terminal.
**Fix:** Add an explicit allowed-status guard before mutating the record.

```python
if enrollment.status not in {"draft", "confirmed"}:
    raise ConflictException(
        code="OPERACAO_NAO_PERMITIDA",
        message="Somente matriculas em rascunho ou confirmadas podem ser trancadas",
    )
```

### WR-02: Lock flow is not protected against concurrent confirm requests

**File:** `backend/src/features/enrollment/services.py:386-392,595-603,623-628`
**Issue:** `confirm_enrollment()` uses `SELECT ... FOR UPDATE`, but `lock_enrollment()` reads the same enrollment without a row lock. Concurrent confirm/lock requests can therefore interleave: one request can create grade rows while the other marks the enrollment and courses as locked, leaving grade state out of sync with the final enrollment state.
**Fix:** Load the enrollment with `with_for_update()` inside `lock_enrollment()` too, then apply the status transition only after the lock is acquired.

```python
result = await db.execute(
    select(Enrollment)
    .options(
        selectinload(Enrollment.enrollment_courses).selectinload(EnrollmentCourse.grades)
    )
    .where(Enrollment.id == enrollment_id)
    .with_for_update()
)
```

### WR-03: Student creation still misses duplicate phone validation

**File:** `backend/src/features/students/services.py:120-146`
**Issue:** `create_student()` validates duplicate `email` and `registration_number`, but not duplicate `phone`. The `students.phone` column is unique (`backend/src/features/auth/models.py:30-32`), so a repeated phone number will fall through to the database and likely return an unhandled integrity error instead of a controlled 409 response.
**Fix:** Mirror the update-path phone uniqueness check before calling `create()`.

```python
if data.phone is not None:
    existing_phone = await db.execute(
        select(Student.id).where(Student.phone == data.phone)
    )
    if existing_phone.scalar_one_or_none() is not None:
        raise ConflictException(
            code="TELEFONE_JA_CADASTRADO",
            message="Ja existe um aluno cadastrado com este telefone",
        )
```

### WR-04: Shared update helper cannot clear nullable fields

**File:** `backend/src/shared/base_service.py:156-163`
**Issue:** `BaseService.update()` ignores every field whose new value is `None`. That makes it impossible for feature slices to intentionally clear nullable columns such as `students.phone` or similar optional attributes during partial updates, even when the API explicitly sends `null`.
**Fix:** Apply all provided keys and let callers control which fields are included via `exclude_unset=True`.

```python
for key, value in data.items():
    if hasattr(instance, key):
        setattr(instance, key, value)
```

---

_Reviewed: 2026-04-25T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
