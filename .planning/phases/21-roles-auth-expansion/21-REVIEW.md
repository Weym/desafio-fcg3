---
phase: 21-roles-auth-expansion
reviewed: 2026-05-09T18:30:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - backend/alembic/versions/014_expand_staff_table_provider_role.py
  - backend/src/features/auth/models.py
  - backend/src/features/auth/routes.py
  - backend/src/shared/dependencies.py
  - backend/src/features/staff/controllers.py
  - backend/src/features/staff/schemas.py
  - backend/src/features/staff/services.py
  - backend/src/features/staff/routes.py
  - mobile/lib/core/models/user_model.dart
  - mobile/lib/core/router/route_names.dart
  - mobile/lib/core/router/app_router.dart
  - mobile/lib/features/staff/screens/staff_shell.dart
  - mobile/lib/features/staff/screens/staff_gestao_screen.dart
  - mobile/lib/features/staff/models/staff_member_model.dart
  - mobile/lib/features/staff/services/staff_management_service.dart
  - mobile/lib/features/staff/providers/staff_management_provider.dart
  - mobile/lib/features/staff/screens/staff_member_form_screen.dart
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 21: Code Review Report

**Reviewed:** 2026-05-09T18:30:00Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Phase 21 implements the provider role expansion across backend (auth, dependencies, staff CRUD) and Flutter mobile (navigation, models, screens). The backend implementation is solid — proper authorization guards, self-operation protection, and clean separation of concerns. The Flutter code follows existing patterns well. However, there is one critical data contract mismatch between backend and mobile that will cause a runtime crash, and a few minor warnings around edge cases.

## Critical Issues

### CR-01: Backend/Mobile API contract mismatch — `pagination` vs `meta` key

**File:** `mobile/lib/features/staff/services/staff_management_service.dart:27`
**Issue:** The Flutter service reads `response.data['meta']['total']` but the backend's `paginated_response()` returns the key as `"pagination"` (see `backend/src/shared/pagination.py:62`). This will throw a `Null check operator used on a null value` or `NoSuchMethodError` at runtime when the staff list is loaded — the `'meta'` key doesn't exist in the response.

The backend response shape is:
```json
{"data": [...], "pagination": {"page": 1, "per_page": 20, "total": 150}}
```

But the client expects:
```json
{"data": [...], "meta": {"total": 150}}
```

**Fix:**
```dart
// In mobile/lib/features/staff/services/staff_management_service.dart:27
// Change:
final total = response.data['meta']['total'] as int;
// To:
final total = response.data['pagination']['total'] as int;
```

## Warnings

### WR-01: `StaffUpdate` allows setting `phone`, `position`, `work_schedule` to `null` via update — potentially unintentional field clearing

**File:** `backend/src/features/staff/services.py:270`
**Issue:** `data.model_dump(exclude_unset=True)` correctly excludes fields not sent by the client. However, the `BaseService.update()` method at `base_service.py:160` sets **all** provided values including `None`. If a client sends `{"phone": null}` in the update payload, it will clear the phone field. This is technically correct behavior for a PUT endpoint, but combined with the Flutter form logic (which only sends non-empty fields on create but sends ALL fields on edit — see `staff_member_form_screen.dart:59-73`), there's a risk: if the user clears the phone field in the form, the Flutter code won't include `phone` in the data map at all, meaning it can never be cleared once set.

This is a design decision rather than a bug, but worth noting: the form cannot currently clear optional fields (phone, position, work_schedule) once they have been set, because empty strings are excluded from the payload.

**Fix:** If clearing is desired, change the form logic to explicitly include `null` for cleared optional fields:
```dart
// In staff_member_form_screen.dart, when building data for edit mode:
if (_isEditMode) {
  data['phone'] = phone.isEmpty ? null : phone;
  data['position'] = position.isEmpty ? null : position;
  data['work_schedule'] = workSchedule.isEmpty ? null : workSchedule;
}
```

### WR-02: Search input not sanitized for SQL LIKE wildcards

**File:** `backend/src/features/staff/services.py:177`
**Issue:** The search pattern is constructed as `f"%{search}%"` and passed directly to `ilike()`. If a user sends search strings containing `%` or `_` characters (SQL LIKE wildcards), they will be interpreted as pattern-matching wildcards rather than literal characters. For example, searching for `%` would match all records.

This is not a SQL injection vulnerability (SQLAlchemy parameterizes the value), but it is a logic correctness issue — users cannot search for literal `%` or `_` characters, and crafted patterns could return unexpected results.

**Fix:**
```python
# Escape SQL LIKE wildcards before building the pattern
import re

def _escape_like(value: str) -> str:
    """Escape SQL LIKE wildcards for literal matching."""
    return re.sub(r'([%_\\])', r'\\\1', value)

# In list_staff:
if search:
    escaped = _escape_like(search)
    search_pattern = f"%{escaped}%"
```

### WR-03: `GET /staff/members/{staff_id}` allows fetching the provider's own record

**File:** `backend/src/features/staff/services.py:211-213`
**Issue:** The `get_staff_member` endpoint (and `get_or_404`) does not filter out the provider's own record or other providers. While `list_staff` correctly filters `WHERE role != 'provider'` (D-17), the detail endpoint allows fetching any staff record by UUID — including another provider record if one existed. The provider can also fetch their own record via this endpoint, which is consistent with D-21 only blocking *edit/delete* on self (not read). However, if the intent of D-17 is to fully hide providers from the management UI, a determined user could still discover provider records by UUID enumeration.

This is low-severity because: (a) the list doesn't expose provider UUIDs, (b) UUID enumeration is impractical, and (c) reading one's own record may be intentional. Noting for completeness.

**Fix:** If full provider hiding is desired, add a check:
```python
async def get_staff_member(self, db: AsyncSession, staff_id: UUID) -> Staff:
    staff = await self.get_or_404(db, staff_id, "staff")
    if staff.role == "provider":
        raise NotFoundException("staff", staff_id)
    return staff
```

## Info

### IN-01: `dart:ui` imported but not directly used in staff_shell.dart

**File:** `mobile/lib/features/staff/screens/staff_shell.dart:1`
**Issue:** `import 'dart:ui';` is present but the only usage of `dart:ui` types is `ImageFilter.blur()` which is re-exported through `package:flutter/material.dart`. This import is redundant.

**Fix:** Remove the unused import:
```dart
// Remove line 1:
// import 'dart:ui';
```

### IN-02: Comment says "Staff shell with 4 tabs" but now has 6 tabs

**File:** `mobile/lib/core/router/app_router.dart:157`
**Issue:** The comment `// Staff shell with 4 tabs` is stale — the shell has had 5 tabs since phase 14, and now has 6 with the Gestão tab.

**Fix:**
```dart
// Staff shell with 6 tabs
```

---

_Reviewed: 2026-05-09T18:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
