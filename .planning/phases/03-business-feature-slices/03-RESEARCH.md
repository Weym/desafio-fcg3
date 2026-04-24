# Phase 3: Business Feature Slices — Research

**Researched:** 2026-04-23
**Depth:** Level 2 (retroactive research) — Phase was planned without prior research. This document performs gap analysis against canonical docs (`docs/api.md`, `docs/database.md`, `docs/mcp.md`), validates technical patterns, and identifies schema mismatches that existing plans missed.

---

## 1. Schema Mismatches & Extensions

Cross-referencing `docs/database.md`, `docs/api.md`, and CONTEXT.md decisions revealed the following discrepancies.

### SM-01: `enrollments.status` missing `locked` value

- **Source:** `docs/database.md` defines `enrollments.status` as `VARCHAR(20)` with values: `draft`, `confirmed`, `cancelled`
- **Conflict:** Decision D-11 (CONTEXT.md) adds `locked` as a valid enrollment status ("Lock operates at TWO levels: enrollment to `locked` AND all enrollment_courses to locked")
- **Impact:** No Alembic migration needed (VARCHAR accepts any string), but application validation schemas and documentation must include `locked`. Plan 03-04 correctly implements this but the schema discrepancy should be noted in code comments.
- **Action:** Planner must ensure Pydantic schemas include `locked` in the valid enrollment status enum.

### SM-02: `documents` table missing `notes` column

- **Source:** `docs/api.md` POST /documents request: `{ "type": "transcript", "notes": "Preciso para estagio" }`
- **Conflict:** `docs/database.md` `documents` table has NO `notes` column. Only: `id`, `student_id`, `type`, `status`, `file_url`, `requested_at`, `completed_at`.
- **Impact:** Phase 3 must either: (a) add `notes TEXT NULLABLE` column via Alembic migration, or (b) drop `notes` from the API.
- **Recommendation:** Add the column — `notes` is useful context for staff processing document requests.
- **Action:** Plan 03-06 must include an Alembic migration adding `notes TEXT NULLABLE` to `documents`.

### SM-03: `resources` vs `staff` for scheduling

- **Source:** `docs/api.md` `GET /scheduling/slots` accepts `?staff_id=uuid` and returns `{ "staff": { "id": "uuid", "name": "Maria Coordenadora" } }`
- **Conflict:** `docs/database.md` has `scheduling_slots.resource_id FK -> resources.id` where `resources.resource_type` can be `room`, `lab`, `equipment`. No `staff_id` on slots.
- **Decision D-09:** Keep resources table. API adapts response.
- **Impact:** The planning must address how `staff_id` query param maps to `resource_id`. Options: (a) Staff are represented as `resources` with `resource_type='staff'`, (b) Add `staff_id` FK to `scheduling_slots`, (c) Slots created by staff have `resource_id` pointing to a resource associated with that staff member.
- **Recommendation:** Staff are represented as `resources` entries with `resource_type='staff'`. Create resources for staff during seed data. `staff_id` query param maps to filtering resources by name/id where type='staff'.
- **Action:** Plan 03-07 must clarify this mapping and potentially add seed data for staff-as-resources.

### SM-04: `enrollment_year` on students — not in API create

- **Source:** `docs/database.md` `students.enrollment_year INTEGER NOT NULL`
- **Conflict:** `docs/api.md` POST /students request body: `{ "name", "email", "phone", "registration_number", "curriculum_id" }` — no `enrollment_year`.
- **Impact:** Either auto-calculate from `NOW().year` at creation time, or add to API request body.
- **Recommendation:** Auto-calculate with `DEFAULT EXTRACT(YEAR FROM NOW())` or set in service layer.
- **Action:** Plan 03-02 must handle this field.

---

## 2. API-to-Plan Gap Analysis

### GAP-01: `PUT /students/{id}/fcm-token` — NOT COVERED

- **Source:** `docs/api.md` under Students endpoints: `PUT /students/{id}/fcm-token` — Student only. Request: `{ "fcm_token": "eF1k2..." }`
- **Plans searched:** 03-01 through 03-08 — none mention this endpoint.
- **No matching requirement ID** in REQUIREMENTS.md — FCM is listed under v2 deferred requirements.
- **Recommendation:** DEFER to Phase 6 or post-MVP. FCM token management is tied to push notifications which are out of Phase 3 scope. The endpoint exists in api.md but has no matching requirement.
- **Action:** Explicitly mark as deferred with rationale.

### GAP-02: `POST /notifications/send` — NOT COVERED

- **Source:** `docs/api.md` under Notifications: `POST /notifications/send` — Staff or internal.
- **Plans searched:** 03-01 through 03-08 — none mention this endpoint.
- **No matching requirement ID** — FCM notifications are v2/deferred.
- **Recommendation:** DEFER. Same rationale as GAP-01.

### GAP-03: Grades endpoints on `/students/{id}/grades` and `/students/{id}/transcript`

- **Source:** `docs/api.md` places these under Students: `GET /students/{id}/grades` and `GET /students/{id}/transcript`. Both are MCP-accessible.
- **Current coverage:** Plan 03-05 (Grades slice) handles the business logic for these endpoints.
- **Issue:** The URL paths are under `/students/{id}/` which is owned by the Students router (Plan 03-02). Plan 03-05 creates a separate grades feature directory. This creates a routing ambiguity — which router owns these paths?
- **Recommendation:** These endpoints should be registered in the **students router** (single router owns `/students/{id}/*` paths) but delegate to the **grades service** for business logic. Alternatively, use a separate grades router mounted at `/students/{id}/grades` via include_router.
- **Action:** Plans 03-02 and 03-05 need explicit coordination on route ownership.

### GAP-04: `GET /appointments` response shape

- **Source:** `docs/api.md` shows `GET /appointments` with `?student_id=uuid&status=scheduled` — paginated response.
- **Plan 03-07** covers this but the response should include nested staff/resource info per api.md's slot response pattern.
- **Action:** Plan 03-07 should specify response schema includes resource/staff context.

---

## 3. Technical Pattern Decisions

### TP-01: Recursive CTE for prerequisite trees (COURSE-03)

- **Context:** `GET /courses/{id}/prerequisites` must return full recursive tree.
- **SQLAlchemy pattern:**
  ```python
  from sqlalchemy import text
  
  PREREQUISITE_TREE_CTE = text("""
  WITH RECURSIVE prereq_tree AS (
      SELECT p.course_id, p.prerequisite_id, c.code, c.name, c.credits, 1 AS depth
      FROM prerequisites p
      JOIN courses c ON c.id = p.prerequisite_id
      WHERE p.course_id = :course_id
      
      UNION ALL
      
      SELECT p.course_id, p.prerequisite_id, c.code, c.name, c.credits, pt.depth + 1
      FROM prerequisites p
      JOIN courses c ON c.id = p.prerequisite_id
      JOIN prereq_tree pt ON pt.prerequisite_id = p.course_id
      WHERE pt.depth < :max_depth
  )
  SELECT DISTINCT prerequisite_id AS id, code, name, credits, depth
  FROM prereq_tree
  ORDER BY depth, code
  """)
  ```
- **Depth limit:** 10 (prevents infinite recursion from circular references in dirty data)
- **Alternative:** SQLAlchemy ORM CTE via `cte()` method — more Pythonic but harder to debug. Raw SQL CTE is simpler and more maintainable for this case.
- **Confidence:** HIGH

### TP-02: SELECT FOR UPDATE for appointment booking (APPT-02)

- **Context:** Two students cannot reserve the same slot simultaneously.
- **SQLAlchemy async pattern:**
  ```python
  from sqlalchemy import select
  from sqlalchemy.ext.asyncio import AsyncSession
  
  async def book_appointment(db: AsyncSession, slot_id: UUID, student_id: UUID, reason: str):
      # Pessimistic lock on the slot
      stmt = select(SchedulingSlot).where(
          SchedulingSlot.id == slot_id,
          SchedulingSlot.is_available == True
      ).with_for_update()
      
      result = await db.execute(stmt)
      slot = result.scalar_one_or_none()
      
      if not slot:
          raise ConflictException(code="HORARIO_INDISPONIVEL", message="Horario ja reservado ou inexistente")
      
      slot.is_available = False
      appointment = Appointment(student_id=student_id, slot_id=slot_id, reason=reason)
      db.add(appointment)
      await db.commit()
      return appointment
  ```
- **Key:** `with_for_update()` acquires row-level lock until transaction commits. Other transactions attempting to lock the same row will wait (or timeout).
- **Confidence:** HIGH

### TP-03: Generic Base CRUD Service

- **Pattern:** Generic class with TypeVar for model:
  ```python
  from typing import TypeVar, Generic, Type
  from sqlalchemy.ext.asyncio import AsyncSession
  
  T = TypeVar("T")
  
  class BaseService(Generic[T]):
      def __init__(self, model: Type[T]):
          self.model = model
      
      async def list(self, db: AsyncSession, pagination: PaginationParams, 
                     filters: dict | None = None) -> tuple[list[T], int]:
          ...
      
      async def get_by_id(self, db: AsyncSession, id: UUID) -> T | None:
          ...
      
      async def get_or_404(self, db: AsyncSession, id: UUID, 
                           resource_name: str = "recurso") -> T:
          ...
      
      async def create(self, db: AsyncSession, data: dict) -> T:
          ...
      
      async def update(self, db: AsyncSession, id: UUID, data: dict) -> T:
          ...
  ```
- **sort_by validation:** Must validate column name against model's `__table__.columns` to prevent SQL injection via sort parameter.
- **Filter pattern:** Accept `dict[str, Any]` where keys map to model columns. Use `==` for scalars, `ILIKE` for string fields explicitly marked as searchable.
- **Confidence:** HIGH

### TP-04: Dual-Auth Dependency

- **Pattern:** Single FastAPI Depends that tries JWT first, falls back to X-Service-Token:
  ```python
  async def get_current_user_or_service(
      request: Request,
      db: AsyncSession = Depends(get_db)
  ) -> UserContext:
      # 1. Try JWT Bearer
      auth_header = request.headers.get("Authorization")
      if auth_header and auth_header.startswith("Bearer "):
          return await validate_jwt(auth_header[7:], db)
      
      # 2. Try X-Service-Token
      service_token = request.headers.get("X-Service-Token")
      if service_token:
          return validate_service_token(service_token, request)
      
      raise HTTPException(401, "Autenticacao necessaria")
  ```
- **UserContext:** Contains `id`, `role`, `name`, `email` regardless of auth mechanism. For service token, `id` comes from the request body/path and `role` is `service`.
- **Confidence:** HIGH

### TP-05: CRA Calculation (GRADES-03)

- **Formula:** `CRA = Sum(grade_final * credits) / Sum(credits)` for all grades where `grade_final IS NOT NULL`
- **Pure Python implementation per D-07:**
  ```python
  def calculate_cra(grades_with_credits: list[tuple[float, int]]) -> float:
      """Calculate CRA from list of (grade_final, credits) tuples."""
      if not grades_with_credits:
          return 0.0
      
      total_weighted = sum(grade * credits for grade, credits in grades_with_credits)
      total_credits = sum(credits for _, credits in grades_with_credits)
      
      if total_credits == 0:
          return 0.0
      
      return round(total_weighted / total_credits, 2)
  ```
- **Exclusion rules (D-08):** Only include grades where `grade_final IS NOT NULL`. This automatically excludes `in_progress` (no final grade yet) and `locked` (no final grade).
- **Confidence:** HIGH

### TP-06: Pagination Dependency

- **FastAPI Depends pattern:**
  ```python
  class PaginationParams:
      def __init__(
          self,
          page: int = Query(1, ge=1),
          per_page: int = Query(20, ge=1, le=100),
          sort_by: str = Query("created_at"),
          order: str = Query("desc", regex="^(asc|desc)$"),
      ):
          self.page = page
          self.per_page = per_page
          self.sort_by = sort_by
          self.order = order
          self.offset = (page - 1) * per_page
  ```
- **Response schema:**
  ```json
  {
    "data": [...],
    "pagination": { "page": 1, "per_page": 20, "total": 150 }
  }
  ```
- **Confidence:** HIGH

### TP-07: Document Status Machine

- **Valid transitions:** `requested -> processing -> ready -> delivered`
- **No backward transitions allowed**
- **Implementation:** Validation function that receives `(current_status, new_status)` and checks against allowed transitions dict:
  ```python
  DOCUMENT_STATUS_TRANSITIONS = {
      "requested": ["processing"],
      "processing": ["ready"],
      "ready": ["delivered"],
      "delivered": [],
  }
  ```
- **Confidence:** HIGH

---

## 4. Pitfalls (Phase-specific)

### P-01: `sort_by` SQL injection via pagination

- **Symptom:** User passes `sort_by=1;DROP TABLE students` and if string-interpolated into ORDER BY, it executes.
- **Mitigation:** BaseService.list() MUST validate `sort_by` against `model.__table__.columns.keys()`. Reject any value not in the column list with 400 error.

### P-02: Circular prerequisite references in CTE

- **Symptom:** If `courses` table has A -> B -> C -> A circular reference, recursive CTE enters infinite loop.
- **Mitigation:** `WHERE pt.depth < :max_depth` clause (max 10). Also add `DISTINCT` to prevent duplicate rows. Data integrity should be enforced at insert time with a check, but CTE must be defensive.

### P-03: Race condition in enrollment confirmation

- **Symptom:** Two concurrent confirm requests for the same draft enrollment could both succeed, creating duplicate grade records.
- **Mitigation:** Use `SELECT FOR UPDATE` on the enrollment row during confirmation. Check status is `draft` within the locked transaction.

### P-04: Enrollment period time zone ambiguity

- **Symptom:** Period end_date is `DATE` type (no time). "Is period active?" check using `end_date >= today` could fail at midnight depending on server timezone.
- **Mitigation:** Always compare using `date.today()` in the application layer with explicit server timezone. Document the timezone convention (UTC or local).

### P-05: IDOR on nested resources

- **Symptom:** Student A accesses `GET /students/{B_id}/grades` — must be blocked even if A has a valid JWT.
- **Mitigation:** `check_ownership` dependency from Plan 03-01 must apply to ALL endpoints under `/students/{id}/` — not just mutating ones. Read-only endpoints with student data are equally sensitive.

### P-06: `enrollment_courses` duplicate validation

- **Symptom:** Student adds the same course twice in the `course_ids` array of `POST /enrollments`.
- **Mitigation:** (a) Deduplicate `course_ids` in the service layer before insert, (b) UNIQUE constraint `(enrollment_id, course_id)` in DB provides secondary defense. Return 409 with `DISCIPLINA_DUPLICADA` if caught.

### P-07: Grade auto-calculation precision

- **Symptom:** `(8.5 + 7.0) / 2 = 7.75` — floating point. But `DECIMAL(4,2)` in DB rounds. Using Python `float` could produce `7.749999...`.
- **Mitigation:** Use `Decimal` type in Python for grade arithmetic. SQLAlchemy maps `DECIMAL` to Python `Decimal` by default.

### P-08: Slot generation overlaps

- **Symptom:** Staff creates slots `08:00-12:00 @ 30min` but also has existing slots in that range. Could create overlapping slots.
- **Mitigation:** Before generating slots, query existing slots for the same resource_id + date range. Skip time ranges that already have a slot. Or simply reject with 409 if any overlap exists.

---

## 5. Validation Architecture (Nyquist Dimension 8)

### V-01: IDOR protection on student resources

- **Scope:** Student A authenticated → `GET /students/{B_id}/academic-summary` → 403. Staff → same endpoint → 200.
- **Req coverage:** STU-05, STU-06, STU-07, GRADES-01, GRADES-02, DOCS-01, APPT-04
- **Command:** `pytest backend/tests/integration/test_idor_protection.py -x`

### V-02: Enrollment lifecycle (draft → confirmed → locked)

- **Scope:** Create enrollment (draft) → add courses → confirm → attempt drop (fail) → lock → verify all enrollment_courses locked. Also: create enrollment outside period → 409. Add course with unmet prereq → 409.
- **Req coverage:** ENROLL-02, ENROLL-03, ENROLL-04, ENROLL-05, ENROLL-06, ENROLL-08
- **Command:** `pytest backend/tests/integration/test_enrollment_lifecycle.py -x`

### V-03: CRA calculation

- **Scope:** (a) 3 courses with grades: CRA = weighted average. (b) No completed grades: CRA = 0.0. (c) Mix of in_progress + completed: only completed counted. (d) Locked courses excluded.
- **Req coverage:** GRADES-03, TEST-03
- **Command:** `pytest backend/tests/unit/test_cra_calculation.py -x`

### V-04: Prerequisite tree recursion

- **Scope:** Course with chain A→B→C returns tree depth 2. Course with no prereqs returns empty. Depth limit prevents infinite loop with circular data.
- **Req coverage:** COURSE-03
- **Command:** `pytest backend/tests/integration/test_prerequisite_tree.py -x`

### V-05: Appointment booking concurrency

- **Scope:** Two concurrent booking requests for same slot — one succeeds, one gets 409.
- **Req coverage:** APPT-02
- **Command:** `pytest backend/tests/integration/test_appointment_booking.py -x`

### V-06: Document status machine

- **Scope:** requested→processing OK, requested→ready FAIL (skip step), ready→processing FAIL (backward), delivered→requested FAIL.
- **Req coverage:** DOCS-04
- **Command:** `pytest backend/tests/integration/test_document_status.py -x`

### V-07: Dual-auth on MCP endpoints

- **Scope:** 16 MCP-accessible endpoints respond correctly to both JWT Bearer and X-Service-Token. Non-MCP endpoints reject X-Service-Token.
- **Req coverage:** All MCP-accessible endpoints
- **Command:** `pytest backend/tests/integration/test_dual_auth.py -x`

### V-08: Staff-only endpoint protection

- **Scope:** Student JWT on staff-only endpoints (POST /students, GET /staff/dashboard, etc.) → 403. Staff JWT → 200.
- **Req coverage:** STU-01, STU-02, STU-03, STU-04, ENROLL-STAFF-01/02/03, GRADES-04, DOCS-04, APPT-STAFF-01, STAFF-01
- **Command:** `pytest backend/tests/integration/test_staff_gates.py -x`

### Coverage matrix

| Success Criterion | Validations |
|-------------------|-------------|
| SC-1 (Staff CRUD students + CRA) | V-01, V-03, V-08 |
| SC-2 (Courses/curriculum + prereq tree) | V-04 |
| SC-3 (Enrollment lifecycle) | V-01, V-02 |
| SC-4 (Grades + CRA) | V-03 |
| SC-5 (Docs + appointments) | V-05, V-06 |
| Cross-cutting: Dual-auth | V-07 |
| Cross-cutting: Staff gates | V-08 |
| Cross-cutting: IDOR | V-01 |

---

## 6. Dependencies / Libraries

Phase 3 does NOT require new Python libraries beyond what Phase 1 and Phase 2 install. All patterns use:
- `fastapi` (routes, dependencies, exception handlers)
- `sqlalchemy[asyncio]` + `asyncpg` (ORM, async queries, CTE, FOR UPDATE)
- `pydantic` (request/response schemas)
- `python-jose` (JWT validation — from Phase 2)

No additional `requirements.txt` entries needed.

---

## 7. Summary of Required Plan Amendments

| Issue | Affected Plans | Action Required |
|-------|----------------|-----------------|
| SM-01: `locked` status on enrollments | 03-04 | Ensure Pydantic enum includes `locked`; add code comment about DB schema |
| SM-02: Missing `notes` column on documents | 03-06 | Add Alembic migration task, add `notes` to create schema |
| SM-03: staff_id → resource_id mapping for slots | 03-07 | Clarify how `?staff_id` query maps to resource_id filter |
| SM-04: enrollment_year auto-calculation | 03-02 | Handle in create_student service (auto-set from year) |
| GAP-01: FCM token endpoint | None | Explicitly defer (no requirement ID) |
| GAP-02: Notifications endpoint | None | Explicitly defer (no requirement ID) |
| GAP-03: Grades endpoints route ownership | 03-02, 03-05 | Clarify which router owns `/students/{id}/grades` and `/students/{id}/transcript` |
| P-01: sort_by injection | 03-01 | Must validate against model columns |
| P-03: Enrollment confirm race condition | 03-04 | Add SELECT FOR UPDATE on enrollment during confirm |
| P-06: Duplicate courses in enrollment | 03-04 | Validate deduplication in service layer |
| P-07: Grade precision | 03-05 | Use Decimal type for arithmetic |
| P-08: Slot overlap prevention | 03-07 | Add overlap check before slot generation |

---

*End of research.*
