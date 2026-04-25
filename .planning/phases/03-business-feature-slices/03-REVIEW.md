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

Re-review covered the phase 03 backend feature slices, shared infrastructure, migrations, targeted regression tests, and the public API documentation. The codebase is closer to the intended contract, but there are still a few correctness issues in appointment creation, document status transitions, enrollment-period activation, and slot generation edge-case handling.

## Warnings

### WR-01: Appointment creation builds the response from an unloaded relationship

**File:** `backend/src/features/appointments/services.py:302-305`
**Issue:** After `Appointment` is flushed and refreshed, `book_appointment()` returns `_build_appointment_response(appointment)`, but that helper dereferences `appointment.slot` and `appointment.slot.resource`. The new `appointment` instance never reloads its `slot` relationship, so this path can trigger async lazy-loading at response-building time and fail with `MissingGreenlet`/500 instead of returning the booked appointment.
**Fix:** Re-query the appointment with `joinedload(Appointment.slot).joinedload(SchedulingSlot.resource)` before building the response, or assign the already-loaded `slot` object to the appointment relationship before serializing.

```python
result = await db.execute(
    select(Appointment)
    .options(joinedload(Appointment.slot).joinedload(SchedulingSlot.resource))
    .where(Appointment.id == appointment.id)
)
appointment = result.scalar_one()
return _build_appointment_response(appointment)
```

### WR-02: Document status validation allows skipping required lifecycle steps

**File:** `backend/src/features/documents/services.py:119-149`
**Issue:** `update_document_status()` only rejects backwards or same-state transitions (`new_idx <= current_idx`). That means invalid jumps like `requested -> ready`, `requested -> delivered`, or `processing -> delivered` are currently accepted, even though the service and docs define the lifecycle as `requested -> processing -> ready -> delivered`.
**Fix:** Only allow the next immediate state in the sequence.

```python
if new_idx != current_idx + 1:
    raise ConflictException(
        code="TRANSICAO_STATUS_INVALIDA",
        message=(
            f"Transicao de status invalida: '{document.status}' -> '{data.status}'. "
            f"Status deve seguir a ordem: {' -> '.join(_STATUS_ORDER)}"
        ),
    )
```

### WR-03: Enrollment-period activation can leave multiple active periods and break current-period lookup

**File:** `backend/src/features/enrollment/services.py:57-77,115-136`
**Issue:** `get_current_period()` uses `scalar_one_or_none()` and assumes there is at most one active period, but `update_period()` allows setting `is_active=True` without first deactivating other active periods. Once two overlapping active periods exist, `GET /enrollment-periods/current` can fail with `MultipleResultsFound` and return 500.
**Fix:** Enforce a single active enrollment period inside `create_period()`/`update_period()` by clearing existing active rows (or rejecting the change) before saving the new active period.

```python
if update_data.get("is_active") is True:
    active_periods = await db.execute(
        select(EnrollmentPeriod).where(
            EnrollmentPeriod.is_active.is_(True),
            EnrollmentPeriod.id != period.id,
        )
    )
    for other in active_periods.scalars():
        other.is_active = False
```

### WR-04: Slot creation accepts invalid ranges that generate zero slots

**File:** `backend/src/features/appointments/services.py:199-238`
**Issue:** `create_slots()` validates `start < end`, but if the interval is shorter than `slot_duration_minutes` (for example `08:00-08:20` with `30` minutes), the loop never executes and the endpoint still returns `201` with an empty list. That silently accepts a request that created nothing.
**Fix:** Reject ranges that cannot generate at least one slot before entering the loop.

```python
duration = timedelta(minutes=data.slot_duration_minutes)
if datetime.combine(data.date, start) + duration > datetime.combine(data.date, end):
    raise ValidationException(
        message="Intervalo informado nao comporta nenhum slot",
        details=[
            {"field": "slot_duration_minutes", "message": "A duracao precisa caber no intervalo informado"}
        ],
    )
```

---

_Reviewed: 2026-04-25T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
