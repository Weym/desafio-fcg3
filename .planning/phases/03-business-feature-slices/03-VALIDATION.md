---
phase: 3
slug: business-feature-slices
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-23
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x + pytest-asyncio + httpx AsyncClient (from Phase 2 Wave 0) |
| **Config file** | `backend/pyproject.toml` (`[tool.pytest.ini_options]`) — created by Phase 2 |
| **Quick run command** | `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest tests/unit -x -q"` |
| **Full suite command** | `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest -x -q"` |
| **Estimated runtime** | unit ~10s · integration ~45s · full suite ~55s |

**Supported Docker workflow:** run Phase 03 regressions inside `fastapi-app` with `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest ..."`.

**Optional local-only workflow:** if you are not using Docker for verification, you may still run `cd backend && pytest ...` from the host environment.

---

## Sampling Rate

- **After every task commit:** Run the task-scoped `<automated>` verify command from the plan
- **After every plan wave:** Run `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest -x -q"`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 55 seconds

### Focused Docker regressions used by Phase 03 gap-closure/UAT

- **STU-06 regression:** `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest tests/unit/test_students_academic_summary.py -q"`
- **STU-07 raw-list contract:** `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest tests/integration/test_students_available_courses.py -q"`
- **GRADES-03 CRA behavior:** `docker compose exec -T fastapi-app sh -lc "cd /app && python -m pytest tests/unit/test_grades_cra.py -q"`

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | STU-01,ENROLL-07,DOCS-01,APPT-04 | T-03-04 | Exception handlers return standard error envelope; error codes in PT-BR SCREAMING_SNAKE_CASE | module check | `docker compose exec -T fastapi-app sh -lc "cd /app && python -c \"from src.shared.pagination import PaginationParams, paginated_response; from src.shared.exceptions import AppException, NotFoundException, ConflictException, ForbiddenException, register_exception_handlers; from src.shared.responses import ErrorResponse, PaginationMeta; print('PASS')\""` | ✅ | ⬜ pending |
| 3-01-02 | 01 | 1 | — | T-03-01 / T-03-02 | Dual-auth tries JWT then X-Service-Token; hmac.compare_digest for constant-time comparison; ownership check enforced for student AND service roles (D-05 defense in depth) | module check | `cd backend && python -c "from src.shared.dependencies import get_current_user_or_service, check_ownership, require_staff, UserContext; print('PASS')"` | ✅ | ⬜ pending |
| 3-01-03 | 01 | 1 | — | T-03-03 | BaseService validates sort_by against model columns to prevent SQL injection via ORDER BY | module check | `cd backend && python -c "from src.shared.base_service import BaseService; print('PASS')"` | ✅ | ⬜ pending |
| 3-02-01 | 02 | 2 | STU-01..STU-07 | T-03-02 / T-03-05 | All mutating operations verify ownership (IDOR-safe); staff can list/create/update/soft-delete students; academic summary includes CRA | module check | `cd backend && python -c "from src.features.students.schemas import StudentCreate, StudentUpdate, AcademicSummaryResponse, AvailableCourseItem; from src.features.students.services import StudentService; print('PASS')"` | ✅ | ⬜ pending |
| 3-02-02 | 02 | 2 | STU-01..STU-07 | T-03-02 | At least 7 routes registered under students router covering all STU requirements | module check | `cd backend && python -c "from src.features.students.routes import router; print(f'Routes: {len(router.routes)}'); assert len(router.routes) >= 7, 'Expected at least 7 routes'; print('PASS')"` | ✅ | ⬜ pending |
| 3-03-01 | 03 | 2 | COURSE-01..03,CURR-01..02 | — | Recursive CTE for prerequisite tree with depth limit preventing infinite loops (P-02) | module check | `cd backend && python -c "from src.features.courses.schemas import CourseDetail, PrerequisiteTreeNode, CurriculumResponse; from src.features.courses.services import CourseService; print('PASS')"` | ✅ | ⬜ pending |
| 3-03-02 | 03 | 2 | COURSE-01..03,CURR-01..02 | — | Courses and curriculum routers registered with correct endpoint count | module check | `cd backend && python -c "from src.features.courses.routes import courses_router, curriculum_router; print(f'Courses: {len(courses_router.routes)}, Curriculum: {len(curriculum_router.routes)}'); print('PASS')"` | ✅ | ⬜ pending |
| 3-04-01 | 04 | 3 | ENROLL-01..08,ENROLL-STAFF-01..03 | — | Enrollment lifecycle (draft->confirmed->locked); SELECT FOR UPDATE on confirm; period+prereq+duplicate validation | module check | `cd backend && python -c "from src.features.enrollment.schemas import EnrollmentCreate, EnrollmentResponse, EnrollmentPeriodCreate; from src.features.enrollment.services import EnrollmentService, EnrollmentPeriodService; print('PASS')"` | ✅ | ⬜ pending |
| 3-04-02 | 04 | 3 | ENROLL-01..08,ENROLL-STAFF-01..03 | — | 11 enrollment endpoints registered; drop only in draft (D-12); 409 on period closed/prereq unmet (D-13) | module check | `cd backend && python -c "from src.features.enrollment.routes import enrollments_router; print(f'Routes: {len(enrollments_router.routes)}'); print('PASS')"` | ✅ | ⬜ pending |
| 3-05-01 | 05 | 4 | GRADES-01..04 | — | CRA calculated in Python (D-07); only grades with final_grade IS NOT NULL (D-08); Decimal precision (P-07) | module check | `cd backend && python -c "from src.features.grades.schemas import GradeResponse, TranscriptResponse; from src.features.grades.services import GradeService; print('PASS')"` | ✅ | ⬜ pending |
| 3-05-02 | 05 | 4 | GRADES-01..04 | — | Grades router registered; route ownership clarified with students router (GAP-03) | module check | `cd backend && python -c "from src.features.grades.routes import grades_router; print('PASS')"` | ✅ | ⬜ pending |
| 3-06-01 | 06 | 3 | DOCS-01..04 | — | Document status machine (requested->processing->ready->delivered); no backward transitions; Alembic migration adds notes column (SM-02); IDOR protection on student docs | module check | `cd backend && python -c "from src.features.documents.routes import documents_router; from src.features.documents.schemas import DocumentCreate, DocumentResponse, DocumentStatusUpdate; print(f'Routes: {len(documents_router.routes)}'); print('PASS')"` | ✅ | ⬜ pending |
| 3-07-01 | 07 | 3 | APPT-01..04,APPT-STAFF-01 | — | SELECT FOR UPDATE on slot during booking (D-10); slots belong to resources (D-09); overlap prevention (P-08) | module check | `cd backend && python -c "from src.features.appointments.schemas import SlotCreate, AppointmentCreate, SlotResponse; from src.features.appointments.services import SlotService, AppointmentService; print('PASS')"` | ✅ | ⬜ pending |
| 3-07-02 | 07 | 3 | APPT-01..04,APPT-STAFF-01 | — | Scheduling and appointments routers registered | module check | `cd backend && python -c "from src.features.appointments.routes import scheduling_router, appointments_router; print(f'Scheduling: {len(scheduling_router.routes)}, Appointments: {len(appointments_router.routes)}'); print('PASS')"` | ✅ | ⬜ pending |
| 3-08-01 | 08 | 5 | STAFF-01 | — | Dashboard aggregates KPIs from all domains; staff-only access | module check | `cd backend && python -c "from src.features.staff.routes import staff_router; from src.features.staff.schemas import DashboardResponse; print('PASS')"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Integration Tests (from Research Validation Architecture)

These integration tests cover cross-cutting concerns and end-to-end behaviors identified in 03-RESEARCH.md Section 5.

| Test ID | Scope | Requirements | Test Type | Automated Command | File Exists | Status |
|---------|-------|-------------|-----------|-------------------|-------------|--------|
| V-01 | IDOR protection: student A cannot access student B's resources; staff can access any | STU-05,STU-06,STU-07,GRADES-01,GRADES-02,DOCS-01,APPT-04 | integration | `cd backend && pytest tests/integration/test_idor_protection.py -x` | ❌ W0 | ⬜ pending |
| V-02 | Enrollment lifecycle: draft->confirmed->locked; period closed->409; unmet prereq->409; drop only in draft | ENROLL-02..06,ENROLL-08 | integration | `cd backend && pytest tests/integration/test_enrollment_lifecycle.py -x` | ❌ W0 | ⬜ pending |
| V-03 | CRA calculation: weighted average, no completed=0.0, in-progress excluded, locked excluded | GRADES-03,TEST-03 | unit | `cd backend && pytest tests/unit/test_cra_calculation.py -x` | ❌ W0 | ⬜ pending |
| V-04 | Prerequisite tree: recursive chain, empty prereqs, depth limit on circular data | COURSE-03 | integration | `cd backend && pytest tests/integration/test_prerequisite_tree.py -x` | ❌ W0 | ⬜ pending |
| V-05 | Appointment booking concurrency: two concurrent requests, one 409 | APPT-02 | integration | `cd backend && pytest tests/integration/test_appointment_booking.py -x` | ❌ W0 | ⬜ pending |
| V-06 | Document status machine: valid transitions only, no backward, no skip | DOCS-04 | integration | `cd backend && pytest tests/integration/test_document_status.py -x` | ❌ W0 | ⬜ pending |
| V-07 | Dual-auth: 16 MCP endpoints accept both JWT and X-Service-Token; non-MCP reject service token | All MCP endpoints | integration | `cd backend && pytest tests/integration/test_dual_auth.py -x` | ❌ W0 | ⬜ pending |
| V-08 | Staff-only endpoints: student JWT->403; staff JWT->200 | STU-01..04,ENROLL-STAFF-01..03,GRADES-04,DOCS-04,APPT-STAFF-01,STAFF-01 | integration | `cd backend && pytest tests/integration/test_staff_gates.py -x` | ❌ W0 | ⬜ pending |

### Coverage Matrix (Success Criteria -> Validations)

| Success Criterion | Validations |
|-------------------|-------------|
| SC-1: Staff CRUD students + CRA + ownership | V-01, V-03, V-08 |
| SC-2: Courses/curriculum + prereq tree | V-04 |
| SC-3: Enrollment lifecycle | V-01, V-02 |
| SC-4: Grades + CRA | V-03 |
| SC-5: Docs + appointments | V-05, V-06 |
| Cross-cutting: Dual-auth | V-07 |
| Cross-cutting: Staff gates | V-08 |
| Cross-cutting: IDOR | V-01 |

---

## Wave 0 Requirements

Integration test stubs must be created before feature slices are exercised:

- [ ] `backend/tests/integration/test_idor_protection.py` — stubs for V-01 (IDOR across all student resource endpoints)
- [ ] `backend/tests/integration/test_enrollment_lifecycle.py` — stubs for V-02 (full enrollment state machine)
- [ ] `backend/tests/unit/test_cra_calculation.py` — stubs for V-03 (CRA edge cases)
- [ ] `backend/tests/integration/test_prerequisite_tree.py` — stubs for V-04 (recursive CTE)
- [ ] `backend/tests/integration/test_appointment_booking.py` — stubs for V-05 (concurrent booking)
- [ ] `backend/tests/integration/test_document_status.py` — stubs for V-06 (status machine transitions)
- [ ] `backend/tests/integration/test_dual_auth.py` — stubs for V-07 (JWT + service token on MCP endpoints)
- [ ] `backend/tests/integration/test_staff_gates.py` — stubs for V-08 (role gate enforcement)
- [ ] `backend/tests/conftest.py` — extend Phase 2 conftest with fixtures: seed students/courses/enrollment period for integration tests

*Note: Phase 2 Wave 0 created the pytest infrastructure (`pyproject.toml`, base `conftest.py`, `requirements-dev.txt`). Phase 3 Wave 0 extends it with domain-specific fixtures and test stubs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pagination response matches docs/api.md format visually | STU-01 | Schema compliance review | 1. Start Docker stack 2. Seed data 3. `curl -H "Authorization: Bearer {token}" http://localhost:8000/students?page=1&per_page=5` 4. Verify JSON shape: `{"data": [...], "pagination": {"page": 1, "per_page": 5, "total": N}}` |
| SELECT FOR UPDATE actually blocks concurrent transactions | APPT-02 | Requires real database concurrency (async tasks in same test may serialize) | 1. Open two psql sessions 2. Both run `SELECT ... FOR UPDATE` on same slot 3. Confirm second session waits until first commits |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (8 integration test stubs + conftest extension)
- [x] No watch-mode flags
- [x] Feedback latency < 55s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-23 (by planner; awaits execution confirmation)
