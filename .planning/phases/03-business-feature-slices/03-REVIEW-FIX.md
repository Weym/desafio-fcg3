---
phase: 03-business-feature-slices
fixed_at: 2026-04-25T02:30:17.9617647-03:00
review_path: .planning/phases/03-business-feature-slices/03-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
summary: Fixed all warning findings by enforcing locked-enrollment conflicts, propagating enrollment locks to grades, blocking locked grade edits, and limiting staff dashboard periods to the current active date window.
---

# Phase 03: Code Review Fix Report

**Fixed at:** 2026-04-25T02:30:17.9617647-03:00
**Source review:** `.planning/phases/03-business-feature-slices/03-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### WR-01: Locked enrollments can be recreated for the same period

**Status:** fixed
**Files modified:** `backend/src/features/enrollment/services.py`
**Commit:** `9aa694d`
**Applied fix:** Expanded the duplicate-enrollment guard to treat `locked` enrollments as conflicting for the same student and enrollment period.

### WR-02: Locking an enrollment does not lock its grade records

**Status:** fixed
**Files modified:** `backend/src/features/enrollment/services.py`
**Commit:** `0ca7705`
**Applied fix:** Loaded enrollment-course grades during lock processing and updated related non-dropped grade rows to `status="locked"` in the same transaction.

### WR-03: Locked grades can still be edited and silently unlocked

**Status:** fixed: requires human verification
**Files modified:** `backend/src/features/grades/services.py`
**Commit:** `eaa68ca`
**Applied fix:** Added a conflict guard that rejects grade updates when the grade is already locked, preventing recalculation and status rewrites.

### WR-04: Staff dashboard can report an expired or future enrollment period as active

**Status:** fixed: requires human verification
**Files modified:** `backend/src/features/staff/services.py`
**Commit:** `8412a78`
**Applied fix:** Constrained the dashboard enrollment-period query to records that are active and whose date window includes today.

---

_Fixed: 2026-04-25T02:30:17.9617647-03:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
