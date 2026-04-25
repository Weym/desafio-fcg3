---
phase: 03-business-feature-slices
reviewed: 2026-04-24T23:15:00Z
depth: deep
files_reviewed: 30
files_reviewed_list:
  - backend/src/shared/__init__.py
  - backend/src/shared/pagination.py
  - backend/src/shared/exceptions.py
  - backend/src/shared/responses.py
  - backend/src/shared/dependencies.py
  - backend/src/shared/base_service.py
  - backend/src/main.py
  - backend/src/features/students/schemas.py
  - backend/src/features/students/services.py
  - backend/src/features/students/controllers.py
  - backend/src/features/students/routes.py
  - backend/src/features/students/__init__.py
  - backend/src/features/courses/schemas.py
  - backend/src/features/courses/services.py
  - backend/src/features/courses/controllers.py
  - backend/src/features/courses/routes.py
  - backend/src/features/enrollment/schemas.py
  - backend/src/features/enrollment/services.py
  - backend/src/features/enrollment/controllers.py
  - backend/src/features/enrollment/routes.py
  - backend/src/features/documents/schemas.py
  - backend/src/features/documents/services.py
  - backend/src/features/documents/controllers.py
  - backend/src/features/documents/routes.py
  - backend/src/features/grades/schemas.py
  - backend/src/features/grades/services.py
  - backend/src/features/grades/controllers.py
  - backend/src/features/grades/routes.py
  - backend/src/features/appointments/schemas.py
  - backend/src/features/appointments/services.py
  - backend/src/features/appointments/controllers.py
  - backend/src/features/appointments/routes.py
  - backend/src/features/staff/schemas.py
  - backend/src/features/staff/services.py
  - backend/src/features/staff/controllers.py
  - backend/src/features/staff/routes.py
findings:
  critical: 3
  warning: 10
  info: 6
  total: 19
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-24T23:15:00Z
**Depth:** deep
**Files Reviewed:** 30+
**Status:** issues_found

## Summary

Phase 03 implements 7 feature slices (Students, Courses, Enrollment, Grades, Documents, Appointments, Staff Dashboard) plus shared infrastructure (pagination, exceptions, dual-auth, IDOR protection, BaseService). The architecture follows the vertical-slice pattern correctly, and security fundamentals are well-executed: IDOR protection is consistently applied, dual-auth works correctly, and service-token validation uses constant-time comparison. However, the review identified **3 critical issues** (ILIKE SQL injection via wildcard characters, missing `await` in exception handling causing bare `raise` from exception, and a missing `created_at` column on the Document model used by BaseService), **10 warnings** (logic bugs in update, missing commit on read-modify-write paths, inconsistent IDOR patterns), and **6 informational items** (unused imports, code smell patterns).

## Critical Issues

### CR-01: ILIKE Search Patterns Vulnerable to Wildcard Injection

**File:** `backend/src/features/students/services.py:67`
**Also:** `backend/src/features/courses/services.py:70`
**Issue:** User-supplied `search` string is interpolated directly into an ILIKE pattern via `f"%{search}%"`. While this is parameterized (no raw SQL injection), special LIKE metacharacters (`%`, `_`, `\`) in user input are NOT escaped. An attacker can craft search strings like `%` to match everything, `_____` to match fixed-length strings, or `\` to cause backend errors on some PostgreSQL configurations. This is a **data exfiltration risk** — a malicious search pattern can extract information about records that should not match a legitimate search.
**Fix:**
```python
# Add this utility to src/shared/pagination.py or a utils module:
def escape_like(value: str) -> str:
    """Escape LIKE/ILIKE metacharacters for safe parameterized queries."""
    return (
        value
        .replace("\\", "\\\\")
        .replace("%", "\\%")
        .replace("_", "\\_")
    )

# Then in services:
search_pattern = f"%{escape_like(search)}%"
```

### CR-02: `BaseService.update` Silently Skips `None` Values — Cannot Clear Optional Fields

**File:** `backend/src/shared/base_service.py:159-161`
**Issue:** The `update` method skips `None` values (`if value is not None and hasattr(instance, key)`). This makes it **impossible to clear optional fields** — for example, setting `phone` to `None` on a student update, or clearing `file_url`. Any caller passing `None` to explicitly clear a field will have that change silently ignored. This is a correctness bug: `StudentUpdate(phone=None)` with `exclude_unset=True` already handles the "not sent" case, but when a caller explicitly sends `null`, the intent is to clear the field.

The interaction with `model_dump(exclude_unset=True)` in callers (e.g., `students/services.py:160`) partially mitigates this — unset fields are excluded from the dict entirely. But `EnrollmentPeriodUpdate` allows `is_active: bool | None = None`, and other update schemas could pass explicit `None` to clear a value. The defense is fragile and the contract is misleading.
**Fix:**
```python
async def update(
    self,
    db: AsyncSession,
    instance: T,
    data: dict[str, Any],
) -> T:
    """Update entity fields from data dict.

    Sets all provided keys (including None to clear optional fields).
    Callers should use model_dump(exclude_unset=True) to omit unset fields.
    """
    for key, value in data.items():
        if hasattr(instance, key):
            setattr(instance, key, value)
    await db.flush()
    await db.refresh(instance)
    return instance
```

### CR-03: Academic Summary Returns `created_at` as `next_appointment` Instead of Appointment Datetime

**File:** `backend/src/features/students/services.py:248-250`
**Issue:** The academic summary queries the next appointment (joining `Appointment` with `SchedulingSlot` to get the slot date/time), but then returns `next_appointment_row.created_at` as the value. This is the **appointment creation timestamp**, not the actual scheduled date+time. The `AcademicSummaryResponse.next_appointment` field should represent *when* the appointment is scheduled (the slot's `date` + `start_time`), not when the record was created in the database.
**Fix:**
```python
# Replace lines 248-250 with:
if next_appointment_row is not None:
    # Get the slot for this appointment
    slot_result = await db.execute(
        select(SchedulingSlot).where(SchedulingSlot.id == next_appointment_row.slot_id)
    )
    slot = slot_result.scalar_one()
    next_appointment = datetime.combine(slot.date, slot.start_time)
else:
    next_appointment = None
```
Or refactor the original query to select the slot fields directly.

## Warnings

### WR-01: Document Model Uses `requested_at` Not `created_at` — BaseService Sort Fallback Will Use Primary Key

**File:** `backend/src/features/documents/models.py:36`
**Also affects:** `backend/src/shared/base_service.py:52-54`
**Issue:** The `Document` model has `requested_at` as its timestamp column, not `created_at`. `BaseService._get_sort_column` falls back to `created_at` when the user-supplied `sort_by` is invalid, but `Document` has no `created_at` column. It then falls back to the primary key (`id`), which is a UUID — sorting by UUID is semantically meaningless. `DocumentService` inherits `BaseService[Document]` and uses `self.list()` for listing, so the default sort order is broken for documents.
**Fix:** Override `_get_sort_column` in `DocumentService` to default to `requested_at`, or add `created_at` as an alias in the model:
```python
class DocumentService(BaseService[Document]):
    def _get_sort_column(self, sort_by: str) -> Any:
        valid_columns = self._get_valid_columns()
        if sort_by in valid_columns:
            return getattr(self.model, sort_by)
        # Document uses requested_at instead of created_at
        return getattr(self.model, "requested_at")
```

### WR-02: Enrollment `lock_enrollment` Missing SELECT FOR UPDATE — Race Condition

**File:** `backend/src/features/enrollment/services.py:575-579`
**Issue:** `confirm_enrollment` correctly uses `select(...).with_for_update()` for pessimistic locking, but `lock_enrollment` does NOT. Two concurrent lock requests could both pass the `status == "locked"` check and proceed to lock, which is benign (idempotent outcome), but the eager-loaded `enrollment_courses` could see stale data causing some courses to be skipped. More importantly, this is an inconsistency in the locking pattern that could mask bugs.
**Fix:**
```python
result = await db.execute(
    select(Enrollment)
    .options(selectinload(Enrollment.enrollment_courses))
    .where(Enrollment.id == enrollment_id)
    .with_for_update()  # Add pessimistic lock
)
```

### WR-03: `drop_course` Changes Status to `dropped` but Doesn't Delete — Could Leave Orphaned Records

**File:** `backend/src/features/enrollment/services.py:554-556`
**Issue:** `drop_course` sets `enrollment_course.status = "dropped"` instead of deleting the record. This is a soft-delete approach, which is fine. However, when `update_enrollment_courses` (ENROLL-04) replaces courses, it `await db.delete(ec)` for ALL existing courses (line 491) — including previously dropped ones. If a student drops a course, then updates their enrollment, the dropped record is deleted. This inconsistency means the "dropped" status is never meaningful in practice for draft enrollments, since any update wipes all enrollment_courses.
**Fix:** This is a design decision, but the inconsistency should be documented. If dropped courses should be preserved, `update_enrollment_courses` should only delete non-dropped courses. If not, `drop_course` could just delete instead of soft-deleting:
```python
# Option A: drop_course hard-deletes during draft
await db.delete(ec)
# Option B: update_enrollment_courses preserves dropped
for ec in existing_result.scalars().all():
    if ec.status != "dropped":
        await db.delete(ec)
```

### WR-04: `get_student` Endpoint Has Inconsistent IDOR Check

**File:** `backend/src/features/students/controllers.py:81-82`
**Issue:** The `get_student` endpoint manually checks `if user.role != "staff": check_ownership(student_id, user)`. But `check_ownership` already handles the staff bypass internally (`if user.role == "staff": return`). The extra `if` guard is redundant and creates a maintenance risk — if `check_ownership` behavior changes, this redundant guard could mask issues. All other endpoints (academic-summary, available-courses, grades, transcript) have the same redundant pattern.
**Fix:** Remove the redundant role check and call `check_ownership` unconditionally:
```python
# Simple and correct — check_ownership handles staff bypass
check_ownership(student_id, user)
student = await student_service.get_student(db, student_id)
```

### WR-05: `raise ... from` Missing in Exception Re-raises in `dependencies.py`

**File:** `backend/src/shared/dependencies.py:106-108`
**Issue:** The `except ValueError: raise _unauthorized(...)` pattern loses the original exception chain. PEP 3134 recommends using `raise ... from exc` for explicit exception chaining, or `raise ... from None` to suppress. Without it, Python will show a confusing "During handling of the above exception, another exception occurred" message in tracebacks.
**Fix:**
```python
except ValueError:
    raise _unauthorized(
        "IDENTIFICACAO_INVALIDA",
        "X-Student-Id deve ser um UUID valido",
    ) from None
```

### WR-06: Enrollment List Ignores `params.sort_by` — Always Sorts by `created_at`

**File:** `backend/src/features/enrollment/services.py:671`
**Issue:** The `list_enrollments` method hard-codes `query.order_by(order_func(Enrollment.created_at))` instead of using the `params.sort_by` value. Since this method uses a custom query (not `BaseService.list`), the sort_by validation from `_get_sort_column` is bypassed. The `params.order` direction IS respected, but the column is always `created_at`.
**Fix:** Either validate and apply `params.sort_by` or document that this endpoint only supports `created_at` sorting:
```python
# Minimal fix — use the validated sort column
sort_column = Enrollment.created_at  # Only Enrollment columns in this grouped query
if params.sort_by == "status":
    sort_column = Enrollment.status
query = query.order_by(order_func(sort_column))
```

### WR-07: `cancel_appointment` Refreshes After Flush but `slot` Relationship May Be Stale

**File:** `backend/src/features/appointments/services.py:348-354`
**Issue:** After setting `appointment.status = "cancelled"` and `appointment.slot.is_available = True`, the code calls `db.flush()` and `db.refresh(appointment)`. However, `refresh` only refreshes the appointment's own columns — the `slot` relationship that was modified is NOT refreshed. The `_build_appointment_response` function then accesses `appointment.slot`, which may have stale in-memory state. In practice this works because the in-memory mutation is correct, but it's fragile if any DB-side trigger modifies the slot.
**Fix:** Add explicit refresh of the slot:
```python
await db.flush()
await db.refresh(appointment)
await db.refresh(appointment.slot)
```

### WR-08: `create_document_request` Doesn't Set `requested_at` — Relies on DB Default

**File:** `backend/src/features/documents/services.py:90-96`
**Issue:** The `create_document_request` method builds `doc_data` without including `requested_at`. It relies on the DB `server_default=func.now()` to set this timestamp. While this works for INSERT, the `BaseService.create` method does `db.add(instance) → db.flush() → db.refresh(instance)`. The `refresh` should load the server-generated value, but this depends on correct SQLAlchemy configuration. If `requested_at` is not in the `doc_data` dict, the ORM model's Python-side default is `None`, and only `refresh` will fix it. This is a latent risk if the `refresh` is ever removed or if the column is accessed before refresh.
**Fix:** Explicitly set `requested_at` in the service:
```python
from datetime import datetime, timezone

doc_data = {
    "student_id": student_id,
    "type": data.type,
    "status": "requested",
    "notes": data.notes,
    "requested_at": datetime.now(timezone.utc),
}
```

### WR-09: Staff `require_staff` Guard Doesn't Accept `service` Role — MCP Cannot Access Staff Endpoints

**File:** `backend/src/shared/dependencies.py:149-151`
**Issue:** `require_staff` checks `if user.role != "staff"` and raises ForbiddenException. When MCP sends a request with `X-Service-Token`, the `UserContext.role` is `"service"`, which will be blocked by `require_staff`. This means MCP tools that need staff-level endpoints (e.g., staff dashboard, grade updates, document status updates) cannot use the service token path. This may be intentional per the architecture (MCP only proxies student-facing endpoints), but if any MCP tool needs staff endpoints in Phase 4, this will be a blocker.
**Fix:** If by design, add a comment documenting the intentional restriction. If MCP should access staff endpoints, update the guard:
```python
def require_staff(user: UserContext) -> None:
    if user.role not in ("staff", "service"):
        raise ForbiddenException("Esta acao requer permissao de staff")
```

### WR-10: `_time_from_str` Lacks Validation — Can Crash on Malformed Input

**File:** `backend/src/features/appointments/services.py:38-40`
**Issue:** `_time_from_str` splits on `:` and indexes `parts[0]` and `parts[1]`. If the input passes the regex validation (`^\d{2}:\d{2}$`) in the Pydantic schema, this is safe. However, the function is called in `create_slots` from the service layer where the schema may not have been applied (e.g., direct service calls in tests). Values like `"25:99"` will pass the regex but create invalid `time` objects causing `ValueError`.
**Fix:**
```python
def _time_from_str(s: str) -> time:
    """Parse HH:MM string to time object."""
    try:
        parts = s.split(":")
        return time(int(parts[0]), int(parts[1]))
    except (ValueError, IndexError) as e:
        raise ValidationException(
            message=f"Formato de horario invalido: '{s}'. Use HH:MM.",
        ) from e
```

## Info

### IN-01: Unused Import `Decimal` in `grades/schemas.py`

**File:** `backend/src/features/grades/schemas.py:8`
**Issue:** `from decimal import Decimal` is imported but never used in the file. All grade fields use `float | None`, not `Decimal`.
**Fix:** Remove `from decimal import Decimal`.

### IN-02: Inline Imports Inside Functions

**File:** `backend/src/features/students/services.py:85` (also lines 217, and `controllers.py:207, 232`)
**Issue:** Several files use inline `from sqlalchemy import asc, desc` or `from src.features.grades.services import grade_service` inside methods. While this avoids circular imports in some cases (the `grade_service` case), the `asc`/`desc` imports could be at module level since there's no circular dependency risk for SQLAlchemy utilities.
**Fix:** Move `from sqlalchemy import asc, desc` to module-level imports where there's no circular dependency risk. Keep the lazy imports for cross-feature service references where circular imports are a genuine concern.

### IN-03: `return type` Annotation Mismatch — `get_available_courses` Returns `dict` Not `list`

**File:** `backend/src/features/students/controllers.py:176`
**Issue:** `response_model=list[AvailableCourseItem]` but the function returns `dict` (`{"data": [...]}`). FastAPI will use the `response_model` for OpenAPI docs but the actual response is a different shape. The return type annotation says `dict` but the OpenAPI spec will expect a list.
**Fix:** Either return the list directly (matching `response_model`):
```python
return [c.model_dump() for c in courses]
```
Or change `response_model=None` to match the envelope pattern used elsewhere.

### IN-04: `type` Used as Parameter Name Shadows Python Builtin

**File:** `backend/src/features/documents/controllers.py:74`
**Issue:** `type: str | None = Query(...)` shadows the Python builtin `type()`. While this works and matches the API contract, it's a minor code smell.
**Fix:** Use `doc_type` as the Python parameter name with an alias:
```python
doc_type: str | None = Query(default=None, alias="type", description="Filter by document type")
```

### IN-05: `_NOT_FOUND_CODES` Dictionary Could Be Extended With Missing Resources

**File:** `backend/src/shared/exceptions.py:40-51`
**Issue:** The `_NOT_FOUND_CODES` dict covers most resources but doesn't include `resource` (for scheduling resources). When `NotFoundException("resource", id)` is raised in `appointments/services.py:164`, it falls through to the dynamic fallback `f"{resource.upper()}_NAO_ENCONTRADO"` which produces `RESOURCE_NAO_ENCONTRADO` — a mix of English and Portuguese.
**Fix:** Add `"resource": "RECURSO_NAO_ENCONTRADO"` to `_NOT_FOUND_CODES`.

### IN-06: Module-Level Service Singletons Could Complicate Testing

**File:** Multiple files (e.g., `student_service`, `course_service`, `enrollment_service`, etc.)
**Issue:** All services are instantiated as module-level singletons (e.g., `student_service = StudentService()`). While convenient, this pattern makes dependency injection for testing harder — tests must monkey-patch the module-level variable. FastAPI's `Depends()` system could manage service lifecycle instead.
**Fix:** This is a design pattern choice, not a bug. Consider documenting the testing strategy (e.g., "override via monkeypatch in pytest fixtures") or migrating to `Depends()` injection if testing becomes painful.

---

_Reviewed: 2026-04-24T23:15:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
