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
  info: 2
  total: 6
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 48
**Status:** issues_found

## Summary

Reviewed the Phase 03 backend feature-slice additions plus the API contract doc. The implementation is generally cohesive, but there are a few correctness gaps around enrollment locking, grade mutation after locking, and period selection logic that can produce inconsistent academic state or misleading staff data.

## Warnings

### WR-01: Locked enrollments can be recreated for the same period

**File:** `backend/src/features/enrollment/services.py:291-299`
**Issue:** `create_enrollment()` blocks only `draft` and `confirmed` enrollments for the same student+period. After a student locks an enrollment, they can create a brand-new draft in the same active period, effectively bypassing the “irreversible” lock/trancamento rule.
**Fix:** Include `locked` in the conflict check, or explicitly allow only `cancelled` enrollments to be replaced.

```python
Enrollment.status.in_(["draft", "confirmed", "locked"])
```

### WR-02: Locking an enrollment does not lock its grade records

**File:** `backend/src/features/enrollment/services.py:596-603`
**Issue:** `lock_enrollment()` updates `Enrollment` and `EnrollmentCourse` statuses but leaves related `Grade` rows unchanged. Downstream grade logic already treats `Grade.status == "locked"` as special, so the current behavior leaves the academic state inconsistent after trancamento.
**Fix:** In the same transaction, update all grades linked to the enrollment’s non-dropped `EnrollmentCourse` rows to `status="locked"`.

```python
for ec in enrollment.enrollment_courses:
    if ec.status != "dropped":
        ec.status = "locked"
        for grade in ec.grades:
            grade.status = "locked"
```

### WR-03: Locked grades can still be edited and silently unlocked

**File:** `backend/src/features/grades/services.py:239-249`
**Issue:** `update_grade()` always recalculates `grade_final` and overwrites `status`, with no guard for `grade.status == "locked"`. Even if grades are later locked correctly, this endpoint can mutate them and change the status back to `approved`/`failed`.
**Fix:** Reject updates for locked grades before applying any mutation.

```python
if grade.status == "locked":
    raise ConflictException(
        code="OPERACAO_NAO_PERMITIDA",
        message="Notas de disciplinas trancadas nao podem ser alteradas",
    )
```

### WR-04: Staff dashboard can report an expired or future enrollment period as active

**File:** `backend/src/features/staff/services.py:105-118`
**Issue:** `_get_enrollment_period_summary()` filters only by `is_active=True`. If staff forgets to flip the flag off, the dashboard may show an already-ended period with negative `days_remaining`, or a future period that has not started yet, as the active one.
**Fix:** Reuse the same date-window rule used elsewhere: `is_active=True`, `start_date <= today`, and `end_date >= today`.

```python
select(EnrollmentPeriod).where(
    EnrollmentPeriod.is_active.is_(True),
    EnrollmentPeriod.start_date <= today,
    EnrollmentPeriod.end_date >= today,
)
```

## Info

### IN-01: Scheduling slots response does not match the documented envelope

**File:** `backend/src/features/appointments/controllers.py:55-73`
**Issue:** `GET /scheduling/slots` returns a raw JSON list, while `docs/api.md:566-581` documents `{ "data": [...] }`. This kind of contract drift tends to break generated clients and MCP integrations.
**Fix:** Either wrap the response in `{"data": ...}` or update `docs/api.md` to document the raw-list shape.

### IN-02: Enrollment current-period response shape also drifts from the API doc

**File:** `backend/src/features/enrollment/controllers.py:64-79`
**Issue:** `GET /enrollment-periods/current` returns `{"data": ...}` / `{"data": null}`, while `docs/api.md:396-407` documents a raw period object. This creates another avoidable contract mismatch.
**Fix:** Align the controller and doc to the same response shape, preferably with an explicit response model.

---

_Reviewed: 2026-04-25T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
