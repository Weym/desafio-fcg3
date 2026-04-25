---
phase: 03-business-feature-slices
verified: 2026-04-25T03:33:31.8688670Z
status: gaps_found
score: 6/7 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Staff can list, create, update, and soft-delete students; both student and staff can view student detail and academic summary including CRA, with ownership verified on every mutating operation."
    status: partial
    reason: "STU-06 is only partially met because academic summary computes the 'next appointment' candidate from scheduling_slots but returns Appointment.created_at instead of the upcoming slot datetime."
    artifacts:
      - path: "backend/src/features/students/services.py"
        issue: "Lines 234-250 order by SchedulingSlot.date/start_time, but lines 247-250 assign next_appointment from next_appointment_row.created_at."
    missing:
      - "Return a slot-based timestamp for next_appointment (for example combine SchedulingSlot.date and SchedulingSlot.start_time)."
      - "Add automated coverage for academic-summary next_appointment semantics."
---

# Phase 3: Business Feature Slices Verification Report

**Phase Goal:** All FastAPI business endpoints are operational, role-gated, and IDOR-safe — providing the complete API surface that the MCP server will proxy in Phase 4.
**Verified:** 2026-04-25T03:33:31.8688670Z
**Status:** gaps_found
**Re-verification:** No — fresh full verification of the phase after plans 03-09 and 03-10

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Staff can list/create/update/soft-delete students; student/staff can view detail and academic summary including CRA | ✗ FAILED | Student CRUD, ownership checks, and CRA wiring exist, but `backend/src/features/students/services.py:234-250` returns `Appointment.created_at` for `next_appointment`, not the upcoming slot datetime, so STU-06 is only partial. |
| 2 | Authenticated user can browse courses/curriculum; recursive prerequisite tree and eligible-course filtering work | ✓ VERIFIED | `backend/src/features/courses/services.py:171-210` implements `WITH RECURSIVE`; `backend/src/features/students/services.py:287-340` filters available courses by approved prerequisites. |
| 3 | Student can complete draft → confirmed enrollment flow, drop courses, lock enrollment, and invalid enrollment attempts are rejected | ✓ VERIFIED | `backend/src/features/enrollment/services.py` implements create/confirm/update/drop/lock/list; `confirm_enrollment()` uses `with_for_update()` and `drop_course()` enforces draft-only. |
| 4 | Student can view grades/transcript; CRA is weighted correctly and staff can update grades | ✓ VERIFIED | `backend/src/features/grades/services.py:45-87` calculates CRA in pure Python with `Decimal`; `pytest tests/unit/test_grades_cra.py -q` passed `13` tests. |
| 5 | Student can request/list documents; staff can update document status; student can book/view/cancel appointments; staff can create slots | ✓ VERIFIED | Documents and appointments controllers/services are present and wired; booking uses `with_for_update()` in `backend/src/features/appointments/services.py:272-305`. |
| 6 | Gap-closure 03-09 fixed `/students/{id}/available-courses` to return HTTP 200 raw list contract | ✓ VERIFIED | `backend/src/features/students/controllers.py:168-183` now returns `courses` directly; `pytest tests/integration/test_students_available_courses.py -q` passed. |
| 7 | Gap-closure 03-10 fixed locked-enrollment schema drift in PostgreSQL | ✓ VERIFIED | `backend/alembic/versions/009_add_locked_status_to_enrollments.py` updates `ck_enrollments_status`; container DB is at `009a (head)` and `python -m scripts.verify_enrollment_lock_gap` passed. |

**Score:** 6/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `backend/src/main.py` | Registers all Phase 3 routers | ✓ VERIFIED | Includes students, courses, curriculum, enrollment, documents, scheduling, appointments, grades, and staff routers. |
| `backend/src/shared/dependencies.py` | Dual-auth + ownership enforcement | ✓ VERIFIED | JWT-first, service-token fallback, `check_ownership`, `require_staff`. |
| `backend/src/features/students/services.py` | Student CRUD + academic summary + available courses | ⚠️ PARTIAL | All major methods exist, but `next_appointment` uses `Appointment.created_at` instead of slot date/time. |
| `backend/src/features/students/controllers.py` | Student endpoints + grade views + available-courses contract fix | ✓ VERIFIED | 03-09 raw-list fix is present; grades and transcript routes are wired. |
| `backend/src/features/courses/services.py` | Course/curriculum logic with recursive CTE | ✓ VERIFIED | Recursive CTE and semester-grouped curriculum builder exist. |
| `backend/src/features/enrollment/services.py` | Full enrollment lifecycle logic | ✓ VERIFIED | Create, confirm, update, drop, lock, and list behaviors all present. |
| `backend/src/features/grades/services.py` | CRA and grade update logic | ✓ VERIFIED | Pure Python CRA, transcript builder, grade final/status calculation. |
| `backend/src/features/documents/services.py` | Document lifecycle logic | ✓ VERIFIED | Request/list/detail/status-update flow implemented. |
| `backend/src/features/appointments/services.py` | Slot and appointment logic | ✓ VERIFIED | Slot generation, overlap detection, booking lock, cancellation, listing. |
| `backend/src/features/staff/services.py` | Dashboard KPI aggregation | ✓ VERIFIED | 6 DB-backed KPI queries and enrollment period summary. |
| `backend/alembic/versions/009_add_locked_status_to_enrollments.py` | DB constraint repair for lock flow | ✓ VERIFIED | Recreates `ck_enrollments_status` with `locked`. |
| `backend/scripts/verify_enrollment_lock_gap.py` | Runtime PostgreSQL verifier for 03-10 | ✓ VERIFIED | Script exists and passed against running container. |
| `backend/tests/integration/test_students_available_courses.py` | Regression coverage for 03-09 | ✓ VERIFIED | Confirms HTTP 200 + top-level raw list. |
| `backend/tests/unit/test_grades_cra.py` | CRA behavior coverage | ✓ VERIFIED | 13 unit tests passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `backend/src/features/students/controllers.py` | `backend/src/features/students/services.py` | `student_service.get_available_courses(db, student_id)` | ✓ WIRED | Controller returns service result directly after 03-09. |
| `backend/src/features/students/services.py` | `backend/src/features/grades/services.py` | `grade_service.get_cra_for_student()` | ✓ WIRED | Academic summary GPA uses real CRA service call. |
| `backend/src/features/students/services.py` | `appointments + scheduling_slots` | slot query for next appointment | ⚠️ PARTIAL | Query locates the next slot, but returned value is `Appointment.created_at` instead of the slot datetime. |
| `backend/src/features/courses/services.py` | `prerequisites` table | recursive CTE | ✓ WIRED | `WITH RECURSIVE prereq_tree` query present and used. |
| `backend/src/features/enrollment/services.py` | `enrollment_periods` + `prerequisites` | period/prereq validation before create/confirm | ✓ WIRED | Rejects closed periods and unmet prerequisites with conflict codes. |
| `backend/src/features/appointments/services.py` | `scheduling_slots` table | `with_for_update()` during booking | ✓ WIRED | Booking path locks slot row before reservation. |
| `backend/alembic/versions/009_add_locked_status_to_enrollments.py` | `backend/src/features/enrollment/models.py` | `ck_enrollments_status` | ✓ WIRED | Migration and ORM constraint both allow `locked`. |
| `backend/src/main.py` | feature routers | `app.include_router(...)` | ✓ WIRED | All Phase 3 routers are registered. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `students/services.py` | `gpa` | `grade_service.get_cra_for_student()` | Yes | ✓ FLOWING |
| `students/services.py` | `next_appointment` | `Appointment` joined to `SchedulingSlot` | No — wrong field returned | ✗ HOLLOW |
| `students/services.py` | available courses list | curriculum, grades, prerequisites queries | Yes | ✓ FLOWING |
| `courses/services.py` | prerequisite tree | recursive SQL query against `prerequisites` + `courses` | Yes | ✓ FLOWING |
| `enrollment/services.py` | lock persistence | ORM + PostgreSQL constraint | Yes | ✓ FLOWING |
| `staff/services.py` | dashboard KPIs | `func.count()` queries across domain tables | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| CRA calculation and grade helpers | `pytest tests/unit/test_grades_cra.py -q` | `13 passed in 0.20s` | ✓ PASS |
| Available-courses raw-list regression | `pytest tests/integration/test_students_available_courses.py -q` | `1 passed in 0.86s` | ✓ PASS |
| Locked enrollment runtime proof | `docker compose exec -T fastapi-app sh -lc "cd /app && python -m scripts.verify_enrollment_lock_gap"` | `PASS: confirm succeeded... drop_course remained blocked after lock.` | ✓ PASS |
| Migrated DB revision | `docker compose exec -T fastapi-app sh -lc "cd /app && alembic current"` | `009a (head)` | ✓ PASS |
| Running API baseline | `docker compose exec -T fastapi-app sh -lc "cd /app && python - <<'PY' ... /health ... PY"` | `{'status': 'ok'}` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| STU-01 | 03-01, 03-02 | Staff list students with pagination/filters | ✓ SATISFIED | `list_students()` + paginated controller response. |
| STU-02 | 03-02 | Staff create student | ✓ SATISFIED | `create_student()` validates unique email/registration number. |
| STU-03 | 03-02 | Staff update student | ✓ SATISFIED | `update_student()` wired to PUT controller. |
| STU-04 | 03-02 | Staff soft-delete student | ✓ SATISFIED | `soft_delete_student()` sets `status="inactive"`. |
| STU-05 | 03-02 | Student or staff view student detail | ✓ SATISFIED | Detail route enforces ownership for non-staff. |
| STU-06 | 03-02 | Academic summary with semester/completed/CRA/status/pending docs/next appointment | ✗ BLOCKED | Summary aggregates real data, but `next_appointment` returns `Appointment.created_at` instead of the upcoming slot datetime. |
| STU-07 | 03-02, 03-09 | Available courses respecting prerequisites | ✓ SATISFIED | Service filters by approved prerequisites; 03-09 route/test/doc fix verified. |
| COURSE-01 | 03-03 | List courses with filters | ✓ SATISFIED | `list_courses()` uses search + semester filters. |
| COURSE-02 | 03-03 | Course detail with direct prerequisites | ✓ SATISFIED | `get_course_detail()` loads prerequisite relation. |
| COURSE-03 | 03-03 | Recursive prerequisite tree | ✓ SATISFIED | Recursive CTE implemented and wired to route. |
| CURR-01 | 03-03 | Active curriculum by semester | ✓ SATISFIED | `get_active_curriculum()` groups by semester. |
| CURR-02 | 03-03 | Curriculum by ID | ✓ SATISFIED | `get_curriculum_by_id()` returns curriculum or 404. |
| ENROLL-01 | 03-04 | Active enrollment period | ✓ SATISFIED | `get_current_period()` returns active period or null payload. |
| ENROLL-02 | 03-04 | Create draft enrollment | ✓ SATISFIED | `create_enrollment()` validates active period and courses. |
| ENROLL-03 | 03-04 | Confirm enrollment | ✓ SATISFIED | `confirm_enrollment()` uses row lock and creates grade records. |
| ENROLL-04 | 03-04 | Modify draft enrollment | ✓ SATISFIED | `update_enrollment_courses()` replaces course set in draft state. |
| ENROLL-05 | 03-04 | Drop individual course | ✓ SATISFIED | `drop_course()` enforces draft-only. |
| ENROLL-06 | 03-04, 03-10 | Lock full enrollment | ✓ SATISFIED | Service locks enrollment + courses; migration/script prove PostgreSQL persistence. |
| ENROLL-07 | 03-01, 03-04 | List enrollments with filters | ✓ SATISFIED | Paginated list endpoint with student auto-filter. |
| ENROLL-08 | 03-04 | Reject invalid enrollments | ✓ SATISFIED | Closed-period, duplicate, and prerequisite validations present. |
| ENROLL-STAFF-01 | 03-04 | Staff create enrollment period | ✓ SATISFIED | POST controller + service validation. |
| ENROLL-STAFF-02 | 03-04 | Staff update enrollment period | ✓ SATISFIED | PUT controller + service validation. |
| ENROLL-STAFF-03 | 03-04 | Staff list enrollment periods | ✓ SATISFIED | Paginated staff endpoint exists. |
| GRADES-01 | 03-05 | View grades by discipline/period | ✓ SATISFIED | `/students/{id}/grades` delegates to `get_student_grades()`. |
| GRADES-02 | 03-05 | Full transcript | ✓ SATISFIED | `/students/{id}/transcript` returns transcript + CRA. |
| GRADES-03 | 03-05 | Correct CRA calculation | ✓ SATISFIED | Pure Python `Decimal` CRA with passing unit tests. |
| GRADES-04 | 03-05 | Staff post/update grades | ✓ SATISFIED | `PUT /grades/{id}` recalculates final/status. |
| DOCS-01 | 03-01, 03-06 | Student list documents with filters | ✓ SATISFIED | Paginated list auto-filters non-staff to own records. |
| DOCS-02 | 03-06 | Document detail with download URL when ready | ✓ SATISFIED | Detail route returns `DocumentResponse`; ownership enforced. |
| DOCS-03 | 03-06 | Request document emission | ✓ SATISFIED | POST creates status `requested`. |
| DOCS-04 | 03-06 | Staff update status and file URL | ✓ SATISFIED | Lifecycle validation + optional file URL. |
| APPT-01 | 03-07 | Query available slots | ✓ SATISFIED | GET `/scheduling/slots` returns filtered available slots. |
| APPT-02 | 03-07 | Book appointment with lock | ✓ SATISFIED | Booking service locks slot row with `with_for_update()`. |
| APPT-03 | 03-07 | Cancel own appointment | ✓ SATISFIED | Cancellation releases slot and blocks non-owner non-staff users. |
| APPT-04 | 03-01, 03-07 | List appointments with filters | ✓ SATISFIED | Paginated list endpoint auto-filters non-staff to own records. |
| APPT-STAFF-01 | 03-07 | Staff create slots | ✓ SATISFIED | Slot generation from range + duration implemented. |
| STAFF-01 | 03-08 | Staff dashboard KPIs | ✓ SATISFIED | KPI aggregation service + staff-only route implemented. |

**Orphaned requirements:** None. All Phase 3 requirement IDs declared in plan frontmatter map back to `REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `backend/src/features/students/services.py` | 190 | Stale docstring still says CRA is a placeholder returning `0.0` | ℹ️ Info | Implementation is correct, but comment is misleading. |
| `backend/src/main.py` | 83 | Global validation handler uses `VALIDATION_ERROR` instead of the Phase 03-01 Portuguese-only wording | ⚠️ Warning | Not a roadmap blocker, but it diverges from one shared-layer must-have. |
| `docs/api.md` vs `backend/src/features/enrollment/controllers.py` | 396-408 vs 74-79 | Docs show raw current-period object, controller returns `{ "data": ... }` | ⚠️ Warning | Contract drift can confuse later consumers/tests. |
| `docs/api.md` vs `backend/src/features/appointments/controllers.py` | 568-580 vs 55-73 | Docs show wrapped slot list, controller returns raw `list[SlotResponse]` | ⚠️ Warning | Another docs/runtime contract drift. |
| `backend/src/features/scheduling/models.py` | 19-22 | `resource_type` constraint omits `staff` while appointment API surfaces resources as staff | ⚠️ Warning | Semantics for `staff_id` are only partially aligned with the schema. |

### Human Verification Required

### 1. Recursive prerequisite output quality

**Test:** Hit `GET /api/v1/courses/{id}/prerequisites` with a seeded multi-level prerequisite chain.
**Expected:** Nested tree is correct and readable, with proper parent-child structure.
**Why human:** Static review confirms the recursive CTE and builder exist, but realistic tree correctness still depends on seeded PostgreSQL data.

### 2. Concurrent slot booking race

**Test:** Send two concurrent `POST /api/v1/appointments` requests for the same slot.
**Expected:** Exactly one succeeds; the other returns `409 SLOT_JA_RESERVADO`.
**Why human:** Requires coordinated concurrent requests against the running API.

### Gaps Summary

Phase 03 is close, and the two explicit gap-closure plans did land correctly:

- **03-09** is verified by controller code plus a passing integration regression.
- **03-10** is verified by the migration, live Alembic head state, and the passing PostgreSQL runtime verifier script.

However, the phase goal is **not fully achieved yet** because **STU-06 is only partial**. The academic-summary endpoint finds the next scheduled appointment by slot date/time, but then returns the appointment record's creation timestamp instead of the actual upcoming appointment datetime. That means one of the user-visible summary fields is wired to the wrong data source.

Until `next_appointment` returns slot-based timing data, Phase 03 should remain **`gaps_found`**.

---

_Verified: 2026-04-25T03:33:31.8688670Z_
_Verifier: the agent (gsd-verifier)_
