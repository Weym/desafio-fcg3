---
phase: 21-roles-auth-expansion
fixed_at: 2026-05-09T18:45:00Z
review_path: .planning/phases/21-roles-auth-expansion/21-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 21: Code Review Fix Report

**Fixed at:** 2026-05-09T18:45:00Z
**Source review:** .planning/phases/21-roles-auth-expansion/21-REVIEW.md
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Backend/Mobile API contract mismatch — `pagination` vs `meta` key

**Files modified:** `mobile/lib/features/staff/services/staff_management_service.dart`
**Commit:** 04f578e
**Applied fix:** Changed `response.data['meta']['total']` to `response.data['pagination']['total']` to match the backend's `paginated_response()` envelope which uses the `"pagination"` key.

### WR-01: `StaffUpdate` allows setting optional fields to `null` but form cannot clear them

**Files modified:** `mobile/lib/features/staff/screens/staff_member_form_screen.dart`
**Commit:** 97717a4
**Applied fix:** In edit mode, the form now explicitly sends `null` for cleared optional fields (phone, position, work_schedule) instead of omitting them. Create mode remains unchanged — only sends non-empty values.

### WR-02: Search input not sanitized for SQL LIKE wildcards

**Files modified:** `backend/src/features/staff/services.py`
**Commit:** 2aa3541
**Applied fix:** Added `_escape_like()` helper that escapes `%`, `_`, and `\` characters in search input before building the ILIKE pattern. This prevents wildcard characters in user input from being interpreted as SQL LIKE metacharacters.

### WR-03: `GET /staff/members/{staff_id}` allows fetching provider records

**Files modified:** `backend/src/features/staff/services.py`
**Commit:** 76f5df2
**Applied fix:** Added a check in `get_staff_member()` that raises `NotFoundException` if the fetched staff record has `role == "provider"`. This makes the detail endpoint consistent with the list endpoint's D-17 filtering behavior.

## Skipped Issues

None — all in-scope findings were successfully fixed.

---

_Fixed: 2026-05-09T18:45:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
