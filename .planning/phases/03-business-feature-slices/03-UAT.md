---
status: resolved
phase: 03-business-feature-slices
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md, 03-04-SUMMARY.md, 03-05-SUMMARY.md, 03-06-SUMMARY.md, 03-07-SUMMARY.md, 03-08-SUMMARY.md]
started: 2026-04-25T02:08:47.8036531Z
updated: 2026-04-25T03:37:18.7540932Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test

expected: Stop any running services for this project and start the backend stack from scratch. The services should boot without import or migration errors, and a primary live check such as `GET /health` or `GET /api/v1/courses` should return real JSON successfully.
result: pass

### 2. Student Academic Summary

expected: Fetching a student's academic summary should return the student's own consolidated data, including CRA, completed credits, pending documents, and next appointment, without exposing another student's data.
result: pass

### 3. Available Courses Filtering

expected: Fetching available courses for a student should only return courses whose prerequisites are already satisfied by that student; courses with unmet prerequisites should not appear.
result: issue
reported: "GET /api/v1/students/{id}/available-courses returned HTTP 500 Internal Server Error during live verification. FastAPI raised ResponseValidationError because the route declares response_model=list[AvailableCourseItem] but returned an object with a top-level data key instead of a raw list."
severity: blocker

### 4. Course Prerequisite Tree

expected: Fetching a course prerequisite tree should return the full nested chain for multi-level prerequisites and stop safely instead of looping forever on circular data.
result: pass

### 5. Draft Enrollment Validation

expected: Creating a draft enrollment during an active period should succeed for eligible courses, while unmet prerequisites or a closed period should return a 409 with the documented Portuguese error behavior.
result: pass

### 6. Enrollment Confirm And Lock

expected: Confirming a draft enrollment should create in-progress grade records, and locking that enrollment should make it irreversible and prevent draft-only actions such as dropping a course afterward.
result: issue
reported: "Live verification partially passed: POST /enrollments/{id}/confirm returned 200 and created an in_progress grade record for SMA0301, but POST /enrollments/{id}/lock returned HTTP 500. FastAPI logs show PostgreSQL CheckViolationError on constraint ck_enrollments_status when updating enrollment.status to 'locked'."
severity: blocker

### 7. Grades, Transcript, And CRA

expected: Student grades and transcript endpoints should show entered grades, server-calculated final grades, approved/failed status, and a CRA that matches the weighted calculation; the same CRA should appear in academic summary.
result: pass

### 8. Document Request Lifecycle

expected: A student should be able to request a document and see it in list/detail views, while staff status updates should only move forward through requested -> processing -> ready -> delivered, with `ready` requiring a file URL.
result: pass

### 9. Scheduling Availability And Booking

expected: Staff-created time slots should appear as available to students, booking one should reserve it successfully, and cancelling the appointment should release the slot back to availability.
result: pass

### 10. Double-Booking Protection

expected: If two booking attempts target the same slot, only one should succeed and the other should receive a conflict response, with no duplicate appointment created for that slot.
result: pass

### 11. Staff Dashboard Access And KPIs

expected: The staff dashboard should return all six KPI fields with current counts for staff users, and non-staff access should be rejected.
result: pass

## Summary

total: 11
passed: 9
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Fetching available courses for a student returns a successful list response containing only courses whose prerequisites are already satisfied by that student."
  status: resolved
  reason: "Live verification: GET /api/v1/students/{id}/available-courses returned HTTP 500 Internal Server Error. FastAPI raised ResponseValidationError because the route declares response_model=list[AvailableCourseItem] but returned an object with a top-level data key instead of a raw list."
  severity: blocker
  test: 3
  root_cause: "The controller for GET /students/{id}/available-courses declares response_model=list[AvailableCourseItem] but returns {'data': [...]} instead of a raw list, so FastAPI raises ResponseValidationError and returns HTTP 500."
  artifacts:
    - path: "backend/src/features/students/controllers.py"
      issue: "Route response_model expects list[AvailableCourseItem], but handler returns a wrapped dict with a top-level data key."
    - path: "backend/src/features/students/services.py"
      issue: "Service already returns list[AvailableCourseItem]; filtering logic is not the failing layer."
    - path: "docs/api.md"
      issue: "Docs describe a wrapped {'data': [...]} response, which conflicts with the controller's declared FastAPI response model."
  missing:
    - "Make the endpoint contract consistent by either returning a raw list or declaring a wrapper response model that matches the documented {'data': [...]} shape."
    - "Add or update an integration test that verifies GET /students/{id}/available-courses returns HTTP 200 with the intended response shape."
  debug_session: ".planning/debug/available-courses-500-validation.md"
- truth: "Locking an enrollment succeeds after confirmation, marks the enrollment as locked, and preserves the rule that draft-only actions such as dropping a course are no longer allowed afterward."
  status: resolved
  reason: "Live verification: POST /enrollments/{id}/confirm returned 200 and created an in_progress grade record, but POST /enrollments/{id}/lock returned HTTP 500. FastAPI logs show PostgreSQL CheckViolationError on constraint ck_enrollments_status when updating enrollment.status to 'locked'."
  severity: blocker
  test: 6
  root_cause: "The lock endpoint correctly sets enrollment.status = 'locked', but the live PostgreSQL schema still enforces ck_enrollments_status with only ('draft', 'confirmed', 'cancelled'). The ORM model was updated to include 'locked', but no Alembic migration updated the database constraint, so db.flush() fails with CheckViolationError."
  artifacts:
    - path: "backend/src/features/enrollment/services.py"
      issue: "lock_enrollment writes status='locked' before flush."
    - path: "backend/src/features/enrollment/models.py"
      issue: "ORM/model constraint includes 'locked', so application code expects the value to be valid."
    - path: "backend/alembic/versions/004_create_enrollment_tables.py"
      issue: "Database constraint ck_enrollments_status still allows only draft, confirmed, cancelled."
    - path: ".planning/phases/03-business-feature-slices/03-04-SUMMARY.md"
      issue: "Phase summary already documented that a follow-up migration was still needed for the locked status."
  missing:
    - "Add an Alembic migration that updates ck_enrollments_status to include 'locked'."
    - "Apply the migration in the runtime database and rerun the confirm -> lock flow to verify HTTP 200 and persisted locked status."
  debug_session: ".planning/debug/enrollment-lock-checkviolation.md"
