---
status: diagnosed
trigger: "Locking an enrollment succeeds after confirmation, marks the enrollment as locked, and preserves the rule that draft-only actions such as dropping a course are no longer allowed afterward. Actual: POST /enrollments/{id}/lock returned HTTP 500 with PostgreSQL CheckViolationError on constraint ck_enrollments_status when updating enrollments.status to 'locked'."
created: 2026-04-24T00:00:00Z
updated: 2026-04-24T00:11:00Z
---

## Current Focus

hypothesis: Existing database schema still rejects enrollments.status='locked' even though service/model code now uses it.
test: Compare runtime service/model status values against Alembic-defined check constraints and migration history.
expecting: If migration/schema mismatch exists, code will allow 'locked' while DB constraint only permits older statuses.
next_action: return diagnosis with confirmed schema mismatch root cause

## Symptoms

expected: Locking a confirmed enrollment succeeds, sets enrollment status to locked, and keeps draft-only actions blocked afterward.
actual: Confirm succeeds and creates in_progress grade records, but POST /enrollments/{id}/lock returns HTTP 500.
errors: PostgreSQL CheckViolationError on constraint ck_enrollments_status when updating enrollments.status to 'locked'.
reproduction: POST /api/v1/enrollments/93d81d9d-9a39-4db9-b85d-35b97a0196bf/lock after confirming the enrollment.
started: Live UAT in phase 03 business feature slices.

## Eliminated

## Evidence

- timestamp: 2026-04-24T00:05:00Z
  checked: .planning/debug/knowledge-base.md
  found: Knowledge base file does not exist.
  implication: No prior resolved pattern to reuse.

- timestamp: 2026-04-24T00:06:00Z
  checked: backend/src/features/enrollment/services.py
  found: lock_enrollment explicitly sets enrollment.status = 'locked' before flush.
  implication: The application code intentionally writes 'locked' during POST /enrollments/{id}/lock.

- timestamp: 2026-04-24T00:07:00Z
  checked: backend/src/features/enrollment/models.py
  found: ORM model constraint ck_enrollments_status allows ('draft', 'confirmed', 'cancelled', 'locked').
  implication: The Python model was updated for lock support, so the app layer expects 'locked' to be a valid enrollment status.

- timestamp: 2026-04-24T00:08:00Z
  checked: backend/alembic/versions/004_create_enrollment_tables.py
  found: Database migration creates ck_enrollments_status as status IN ('draft', 'confirmed', 'cancelled') with no 'locked' value.
  implication: Databases created from migrations reject 'locked' at the PostgreSQL constraint level.

- timestamp: 2026-04-24T00:09:00Z
  checked: backend/alembic/**/*.py and grep for ck_enrollments_status / locked
  found: No later Alembic migration alters ck_enrollments_status; only the ORM model mentions locked for enrollments.
  implication: Schema drift persists in migrated environments, causing CheckViolationError when lock_enrollment flushes.

- timestamp: 2026-04-24T00:10:00Z
  checked: .planning/phases/03-business-feature-slices/03-UAT.md and 03-04-SUMMARY.md
  found: UAT recorded PostgreSQL CheckViolationError on ck_enrollments_status during lock, and the implementation summary already noted a follow-up DB migration was still needed.
  implication: The observed production behavior matches the documented unresolved migration gap.

## Resolution

root_cause:
  The lock feature writes enrollments.status='locked' in service code, but the actual PostgreSQL schema created by Alembic still enforces ck_enrollments_status as only ('draft', 'confirmed', 'cancelled'). The ORM model was updated without a matching migration, so db.flush() fails with CheckViolationError in migrated environments.
fix:
verification:
files_changed: []
