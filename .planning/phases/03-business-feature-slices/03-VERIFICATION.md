---
phase: 03-business-feature-slices
verified: 2026-04-25T04:07:25Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/7
  gaps_closed:
    - "Staff can list, create, update, and soft-delete students; both student and staff can view student detail and academic summary including CRA, with ownership verified on every mutating operation."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Send two concurrent POST /api/v1/appointments requests for the same slot against the running API."
    expected: "Exactly one request succeeds and the other returns 409 SLOT_JA_RESERVADO."
    why_human: "Code and service-level locking are present, but this verifier did not run a real concurrent API race against PostgreSQL."
  - test: "Call GET /api/v1/courses/{id}/prerequisites with a seeded multi-level prerequisite chain."
    expected: "The nested prerequisite tree matches the actual parent-child prerequisite graph."
    why_human: "The recursive CTE and tree builder exist, but full semantic correctness still depends on realistic seeded graph data."
---

# Phase 3: Business Feature Slices Verification Report

**Phase Goal:** All FastAPI business endpoints are operational, role-gated, and IDOR-safe — providing the complete API surface that the MCP server will proxy in Phase 4.
**Verified:** 2026-04-25T04:07:25Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Staff can list/create/update/soft-delete students; student/staff can view detail and academic summary including CRA | ✓ VERIFIED | `backend/src/features/students/controllers.py:49-235` still exposes the full student + student-scoped grade surface with `require_staff` and `check_ownership`; `backend/src/features/students/services.py:234-255` now derives `next_appointment` from `SchedulingSlot.date` + `start_time`; `pytest tests/unit/test_students_academic_summary.py -q` passed `2` tests. |
| 2 | Authenticated user can browse courses/curriculum; recursive prerequisite tree and eligible-course filtering work | ✓ VERIFIED | `backend/src/features/courses/services.py:157-210` implements `WITH RECURSIVE prereq_tree`; `backend/src/features/students/services.py:293-346` still filters available courses to passed-prereq courses only. |
| 3 | Student can complete draft → confirmed enrollment flow, drop courses, lock enrollment, and invalid enrollment attempts are rejected | ✓ VERIFIED | `backend/src/features/enrollment/services.py:256-342`, `348-434`, and `511-607` implement create/confirm/drop/lock rules; `confirm_enrollment()` uses `with_for_update()` at `371`; `python -m scripts.verify_enrollment_lock_gap` passed in `fastapi-app`. |
| 4 | Student can view grades/transcript; CRA is weighted correctly and staff can update grades | ✓ VERIFIED | `backend/src/features/grades/services.py:45-86` calculates CRA in pure Python with `Decimal`; `123-216` and `222-280` wire grade listing, transcript, update, and academic-summary CRA flow; `pytest tests/unit/test_grades_cra.py -q` passed `13` tests. |
| 5 | Student can request documents and manage appointments; staff can update document status, create slots, and view dashboard KPIs | ✓ VERIFIED | `backend/src/features/documents/controllers.py:48-143` and `services.py:37-150` cover DOCS-01..04; `backend/src/features/appointments/controllers.py:55-185` and `services.py:101-138, 144-238, 252-360` cover APPT-01..04 + APPT-STAFF-01 with slot locking; `backend/src/features/staff/controllers.py:28-41` and `services.py:26-119` implement STAFF-01. |
| 6 | Gap-closure 03-09 fixed `/students/{id}/available-courses` to return HTTP 200 raw list contract | ✓ VERIFIED | `backend/src/features/students/controllers.py:168-183` returns `courses` directly under `response_model=list[AvailableCourseItem]`; `docs/api.md:283-300` now documents the raw array; `pytest tests/integration/test_students_available_courses.py -q` passed. |
| 7 | Gap-closure 03-10 fixed locked-enrollment schema drift in PostgreSQL | ✓ VERIFIED | `backend/alembic/versions/009_add_locked_status_to_enrollments.py:23-37` recreates `ck_enrollments_status` with `locked`; container reports `009a (head)`; runtime verifier confirms persisted `status='locked'` and post-lock drop rejection. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `backend/src/main.py` | Registers all Phase 3 routers | ✓ VERIFIED | Includes students, courses, curriculum, enrollment, documents, scheduling, appointments, grades, and staff routers at `91-102`. |
| `backend/src/shared/dependencies.py` | Dual-auth + ownership enforcement | ✓ VERIFIED | `get_current_user_or_service()` is JWT-first with service-token fallback; `check_ownership()` and `require_staff()` remain present at `50-152`. |
| `backend/src/features/students/services.py` | Student CRUD + academic summary + available courses | ✓ VERIFIED | STU-06 fix landed at `234-255`; STU-07 prerequisite filtering remains at `274-346`. |
| `backend/src/features/students/controllers.py` | Student endpoints + grade views + available-courses contract fix | ✓ VERIFIED | 9 routes exist; role gating and ownership checks remain wired throughout. |
| `backend/src/features/courses/services.py` | Course/curriculum logic with recursive CTE | ✓ VERIFIED | Recursive prerequisite tree and curriculum grouping are substantive and wired. |
| `backend/src/features/enrollment/services.py` | Full enrollment lifecycle logic | ✓ VERIFIED | Create/confirm/update/drop/lock/list logic present and substantive. |
| `backend/src/features/grades/services.py` | CRA and grade update logic | ✓ VERIFIED | Pure CRA helper, transcript builder, and update flow present. |
| `backend/src/features/documents/services.py` | Document lifecycle logic | ✓ VERIFIED | Request/list/detail/status-update lifecycle implemented. |
| `backend/src/features/appointments/services.py` | Slot and appointment logic | ✓ VERIFIED | Slot generation, overlap detection, SELECT FOR UPDATE booking, cancellation, and list logic implemented. |
| `backend/src/features/staff/services.py` | Dashboard KPI aggregation | ✓ VERIFIED | Real `func.count()` queries across students, enrollments, documents, appointments, chat sessions, and enrollment periods. |
| `backend/alembic/versions/009_add_locked_status_to_enrollments.py` | DB constraint repair for lock flow | ✓ VERIFIED | Upgrade and downgrade explicitly manage `ck_enrollments_status`. |
| `backend/scripts/verify_enrollment_lock_gap.py` | Runtime PostgreSQL verifier for 03-10 | ✓ VERIFIED | Script seeds runtime entities, calls real services, re-reads DB, and asserts post-lock drop rejection. |
| `backend/tests/integration/test_students_available_courses.py` | Regression coverage for 03-09 | ✓ VERIFIED | Authenticated route test asserts HTTP 200 and top-level list shape. |
| `backend/tests/unit/test_students_academic_summary.py` | Regression coverage for 03-11 | ✓ VERIFIED | Proves earliest slot datetime beats `Appointment.created_at` and null case still works. |
| `backend/tests/unit/test_grades_cra.py` | CRA behavior coverage | ✓ VERIFIED | CRA math and grade helper behavior pass 13 unit tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `backend/src/features/students/controllers.py` | `backend/src/features/students/services.py` | `student_service.get_available_courses(db, student_id)` | ✓ WIRED | Controller returns service result directly at `182-183`. |
| `backend/src/features/students/services.py` | `backend/src/features/grades/services.py` | `grade_service.get_cra_for_student()` | ✓ WIRED | Academic summary GPA is sourced from `grade_service` at `217-220`. |
| `backend/src/features/students/services.py` | `appointments + scheduling_slots` | slot query for next appointment | ✓ WIRED | `234-255` selects slot date/time and returns combined datetime. |
| `backend/src/features/courses/services.py` | `prerequisites` table | recursive CTE | ✓ WIRED | `171-199` executes `WITH RECURSIVE prereq_tree`. |
| `backend/src/features/enrollment/services.py` | `enrollment_periods` + `prerequisites` | period/prereq validation before create/confirm | ✓ WIRED | Active-period validation and prereq checks exist in `193-250` and `272-342`. |
| `backend/src/features/appointments/services.py` | `scheduling_slots` table | `with_for_update()` during booking | ✓ WIRED | `272-276` locks the slot row before reservation. |
| `backend/alembic/versions/009_add_locked_status_to_enrollments.py` | `backend/src/features/enrollment/models.py` | `ck_enrollments_status` | ✓ WIRED | Migration and ORM model both allow `locked`. |
| `backend/src/main.py` | feature routers | `app.include_router(...)` | ✓ WIRED | All Phase 3 routers remain registered. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `students/services.py` | `gpa` | `grade_service.get_cra_for_student()` | Yes | ✓ FLOWING |
| `students/services.py` | `next_appointment` | `SchedulingSlot.date` + `SchedulingSlot.start_time` | Yes | ✓ FLOWING |
| `students/services.py` | available courses list | curriculum, grades, prerequisites queries | Yes | ✓ FLOWING |
| `courses/services.py` | prerequisite tree | recursive SQL query against `prerequisites` + `courses` | Yes | ✓ FLOWING |
| `enrollment/services.py` | lock persistence | ORM + PostgreSQL constraint | Yes | ✓ FLOWING |
| `staff/services.py` | dashboard KPIs | `func.count()` queries across domain tables | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| STU-06 regression | `pytest tests/unit/test_students_academic_summary.py -q` | `2 passed in 0.35s` | ✓ PASS |
| STU-07 raw-list contract | `pytest tests/integration/test_students_available_courses.py -q` | `1 passed in 0.93s` | ✓ PASS |
| GRADES CRA behavior | `pytest tests/unit/test_grades_cra.py -q` | `13 passed in 0.22s` | ✓ PASS |
| ENROLL-06 PostgreSQL lock flow | `docker compose exec -T fastapi-app sh -lc "cd /app && python -m scripts.verify_enrollment_lock_gap"` | `PASS: confirm succeeded, lock persisted status='locked' in PostgreSQL, and drop_course remained blocked after lock.` | ✓ PASS |
| Alembic head state | `docker compose exec -T fastapi-app sh -lc "cd /app && alembic current"` | `009a (head)` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| STU-01 | 03-01, 03-02 | Staff list students with pagination/filters | ✓ SATISFIED | `students/controllers.py:49-67` returns paginated list; `students/services.py:48-97` applies search, semester, and status filters. |
| STU-02 | 03-02 | Staff create student | ✓ SATISFIED | `students/controllers.py:92-103` + `students/services.py:111-146`. |
| STU-03 | 03-02 | Staff update student | ✓ SATISFIED | `students/controllers.py:110-122` + `students/services.py:152-161`. |
| STU-04 | 03-02 | Staff soft-delete student | ✓ SATISFIED | `students/controllers.py:129-140` + `students/services.py:167-177` set `status="inactive"`. |
| STU-05 | 03-02 | Student or staff view student detail | ✓ SATISFIED | `students/controllers.py:73-85` enforces ownership for non-staff. |
| STU-06 | 03-02, 03-11 | Academic summary with semester/completed/CRA/status/pending docs/next appointment | ✓ SATISFIED | `students/services.py:183-268` now returns slot-based `next_appointment`; `test_students_academic_summary.py` proves earliest slot semantics and null case. |
| STU-07 | 03-02, 03-09 | Available courses respecting prerequisites | ✓ SATISFIED | `students/services.py:274-346` filters by passed prerequisites; route contract fixed at `students/controllers.py:168-183`; regression test passes. |
| COURSE-01 | 03-03 | List courses with filters | ✓ SATISFIED | `courses/controllers.py:45-59` + `courses/services.py:50-108`. |
| COURSE-02 | 03-03 | Course detail with direct prerequisites | ✓ SATISFIED | `courses/controllers.py:66-73` + `courses/services.py:114-151`. |
| COURSE-03 | 03-03 | Recursive prerequisite tree | ✓ SATISFIED | `courses/services.py:157-210` implements recursive CTE and tree builder. |
| CURR-01 | 03-03 | Active curriculum by semester | ✓ SATISFIED | `courses/controllers.py:104-110` + `courses/services.py:257-274, 303-349`. |
| CURR-02 | 03-03 | Curriculum by ID | ✓ SATISFIED | `courses/controllers.py:117-124` + `courses/services.py:280-297`. |
| ENROLL-01 | 03-04 | Active enrollment period | ✓ SATISFIED | `enrollment/controllers.py:64-79` exposes current period endpoint; service validates active date window. |
| ENROLL-02 | 03-04 | Create draft enrollment | ✓ SATISFIED | `enrollment/controllers.py:96-112` + `enrollment/services.py:256-342`. |
| ENROLL-03 | 03-04 | Confirm enrollment | ✓ SATISFIED | `enrollment/controllers.py:119-137` + `enrollment/services.py:348-434` with row lock at `371`. |
| ENROLL-04 | 03-04 | Modify draft enrollment | ✓ SATISFIED | `enrollment/controllers.py:144-165` + `enrollment/services.py:440-505`. |
| ENROLL-05 | 03-04 | Drop individual course | ✓ SATISFIED | `enrollment/controllers.py:172-194` + `enrollment/services.py:511-558` enforce draft-only drop. |
| ENROLL-06 | 03-04, 03-10 | Lock full enrollment | ✓ SATISFIED | `enrollment/services.py:564-607` locks enrollment and courses; migration `009a` + runtime verifier prove PostgreSQL persistence. |
| ENROLL-07 | 03-01, 03-04 | List enrollments with filters | ✓ SATISFIED | `enrollment/controllers.py:226-254` auto-filters non-staff to own records. |
| ENROLL-08 | 03-04 | Reject invalid enrollments | ✓ SATISFIED | `enrollment/services.py:193-250` and `272-342` enforce active period, duplicates, and prerequisites. |
| ENROLL-STAFF-01 | 03-04 | Staff create enrollment period | ✓ SATISFIED | `enrollment/controllers.py:293-308` + period service create flow. |
| ENROLL-STAFF-02 | 03-04 | Staff update enrollment period | ✓ SATISFIED | `enrollment/controllers.py:315-330` + period service update flow. |
| ENROLL-STAFF-03 | 03-04 | Staff list enrollment periods | ✓ SATISFIED | `enrollment/controllers.py:271-286` returns paginated period list. |
| GRADES-01 | 03-05 | View grades by discipline/period | ✓ SATISFIED | `students/controllers.py:190-213` delegates to `grade_service.get_student_grades()`. |
| GRADES-02 | 03-05 | Full transcript | ✓ SATISFIED | `students/controllers.py:219-235` returns transcript model dump from `grade_service.get_transcript()`. |
| GRADES-03 | 03-05 | Correct CRA calculation | ✓ SATISFIED | `grades/services.py:45-86` and `259-280`; CRA tests pass. |
| GRADES-04 | 03-05 | Staff post/update grades | ✓ SATISFIED | `grades/controllers.py` staff PUT route + `grades/services.py:222-253`. |
| DOCS-01 | 03-01, 03-06 | Student list documents with filters | ✓ SATISFIED | `documents/controllers.py:70-98` auto-filters non-staff to own records; `services.py:37-58` applies filters. |
| DOCS-02 | 03-06 | Document detail with download URL when ready | ✓ SATISFIED | `documents/controllers.py:105-118` + `services.py:64-73`. |
| DOCS-03 | 03-06 | Request document emission | ✓ SATISFIED | `documents/controllers.py:48-63` + `services.py:79-96` create `requested` documents. |
| DOCS-04 | 03-06 | Staff update status and file URL | ✓ SATISFIED | `documents/controllers.py:125-143` + `services.py:102-150` enforce ordered lifecycle and `file_url` on `ready`. |
| APPT-01 | 03-07 | Query available slots | ✓ SATISFIED | `appointments/controllers.py:55-73` + `services.py:101-138` with default today→today+7 range. |
| APPT-02 | 03-07 | Book appointment with lock | ✓ SATISFIED | `appointments/controllers.py:112-127` + `services.py:252-305` with `with_for_update()`. |
| APPT-03 | 03-07 | Cancel own appointment | ✓ SATISFIED | `appointments/controllers.py:167-185` + `services.py:311-360` enforce ownership for non-staff and release slot. |
| APPT-04 | 03-01, 03-07 | List appointments with filters | ✓ SATISFIED | `appointments/controllers.py:134-160` returns paginated list with student auto-filter. |
| APPT-STAFF-01 | 03-07 | Staff create slots | ✓ SATISFIED | `appointments/controllers.py:80-95` + `services.py:144-238` generate slots from time range and check overlap. |
| STAFF-01 | 03-08 | Staff dashboard KPIs | ✓ SATISFIED | `staff/controllers.py:28-41` + `staff/services.py:26-119` aggregate six KPIs from real tables. |

**Orphaned requirements:** None. Every Phase 03 requirement declared in plan frontmatter maps back to `REQUIREMENTS.md` and is accounted for above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `backend/src/features/students/services.py` | 188-191 | Stale docstring still says CRA is a placeholder returning `0.0` | ℹ️ Info | Implementation is correct, but the comment no longer matches the code. |
| `backend/src/main.py` | 79-87 | Validation handler uses English `VALIDATION_ERROR` envelope instead of the Portuguese-only shared-layer wording | ⚠️ Warning | Not blocking Phase 03 goal, but diverges from the shared error-code convention from 03-01. |
| `docs/api.md` | 392-408 | `GET /enrollment-periods/current` docs show a raw object while controller returns `{ "data": ... }` | ⚠️ Warning | Contract drift can confuse MCP/tool consumers and future tests. |
| `docs/api.md` | 568-580 | `GET /scheduling/slots` docs show a wrapped `{ "data": [...] }` payload while controller returns `list[SlotResponse]` | ⚠️ Warning | Another docs/runtime contract mismatch. |
| `backend/src/features/scheduling/models.py` | 19-22 | `Resource.resource_type` constraint omits `staff` while appointments docs/controllers expose resources as staff | ⚠️ Warning | The API mapping works, but the schema still only models `room/lab/equipment`, leaving the staff-resource semantics partially aligned. |

### Human Verification Required

### 1. Concurrent slot booking race

**Test:** Send two concurrent `POST /api/v1/appointments` requests for the same slot.
**Expected:** Exactly one succeeds; the other returns `409 SLOT_JA_RESERVADO`.
**Why human:** The service code uses `SELECT FOR UPDATE`, but this verifier did not execute a true concurrent API race.

### 2. Recursive prerequisite output quality

**Test:** Hit `GET /api/v1/courses/{id}/prerequisites` with a seeded multi-level prerequisite chain.
**Expected:** The nested tree matches the expected prerequisite hierarchy.
**Why human:** Static review confirms the recursive CTE and builder exist, but realistic graph correctness still depends on seeded PostgreSQL data.

### Gaps Summary

The previous STU-06 gap is closed.

- `backend/src/features/students/services.py:234-255` now returns a slot-based `next_appointment` datetime.
- `backend/tests/unit/test_students_academic_summary.py` locks that behavior with regression coverage.
- The earlier 03-09 and 03-10 fixes remain intact: the available-courses contract test passes, and the PostgreSQL enrollment-lock verifier still passes at Alembic head `009a`.

All tracked Phase 03 must-haves now verify in code and automated checks. The phase is no longer blocked by implementation gaps, but two runtime behaviors still merit human confirmation before final signoff, so status remains `human_needed` rather than `passed`.

---

_Verified: 2026-04-25T04:07:25Z_
_Verifier: the agent (gsd-verifier)_
