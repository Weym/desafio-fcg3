---
status: diagnosed
trigger: "Cadastro screen only saves Nome and Email, not other fields; expanded card only shows Email"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: Multi-layer field name mismatch between Flutter model and backend API schema + backend DB has no address/period/campus columns
test: Compared Flutter model fields vs backend StudentCreate/StudentUpdate schemas vs Student DB model
expecting: Field names should match; DB columns should exist for all fields
next_action: Return diagnosis

## Symptoms

expected: Creating/editing a student should persist all fields (Nome, Email, Celular, Endereço, RA, Período, Campus). Expanding a card should show Email, Telefone, Endereço, Período, Campus.
actual: Only Nome and Email are persisted. Expanding a card only shows Email (other fields are null so conditionally hidden).
errors: No runtime errors — fields are silently dropped
reproduction: Create a student filling all fields → only nome/email saved. Expand card → only email row visible.
started: Since StaffCadastroScreen was implemented

## Eliminated

(none needed — root cause found on first pass)

## Evidence

- timestamp: 2026-05-09
  checked: Flutter form _submit() method (staff_cadastro_screen.dart:550-568)
  found: Form builds data map with keys 'name', 'email', 'phone', 'address', 'ra', 'period', 'campus'
  implication: Form correctly collects all 7 fields

- timestamp: 2026-05-09
  checked: StaffCadastroService.createStudent/updateStudent (staff_cadastro_service.dart:20-29)
  found: Service passes the raw `data` map directly to dio.post/put — no field stripping here
  implication: Service layer is a passthrough — not the bottleneck

- timestamp: 2026-05-09
  checked: Backend StudentCreate schema (students/schemas.py:18-37)
  found: StudentCreate accepts ONLY: name, email, phone, registration_number, curriculum_id. Does NOT accept: address, ra, period, campus
  implication: Backend ignores 'address', 'ra', 'period', 'campus' from request body (Pydantic drops unknown fields by default). 'ra' maps to 'registration_number' on backend but Flutter sends 'ra'.

- timestamp: 2026-05-09
  checked: Backend StudentUpdate schema (students/schemas.py:40-55)
  found: StudentUpdate accepts ONLY: name, email, phone, semester, status. No address, ra, period, campus.
  implication: Same mismatch on update path

- timestamp: 2026-05-09
  checked: Student DB model (auth/models.py:16-46)
  found: Student table columns are: id, name, email, phone, registration_number, semester, status, enrollment_year, curriculum_id, created_at, updated_at. NO address column. NO campus column. NO period column (there's semester as int).
  implication: address and campus don't exist in the database at all. Flutter's 'period' conceptually maps to 'semester' but they're different types (string vs int).

- timestamp: 2026-05-09
  checked: Backend StudentListItem response (students/schemas.py:62-72)
  found: GET /students returns: id, name, email, registration_number, semester, status. Does NOT return phone.
  implication: Even if phone were saved, the list endpoint doesn't return it — so fromJson gets null for phone

- timestamp: 2026-05-09
  checked: Flutter StaffStudentModel.fromJson (staff_student_model.g.dart)
  found: Model expects JSON keys 'phone', 'address', 'ra', 'period', 'campus' — none of which are in the list response. 'registration_number' is returned but model expects 'ra'. 'semester' returned as int but model expects 'period' as String?.
  implication: Even for fields that DO exist in DB (phone, registration_number, semester), the JSON key names don't match.

- timestamp: 2026-05-09
  checked: Expanded card rendering (staff_cadastro_screen.dart:340-365)
  found: Card conditionally renders Telefone, Endereço, Período, Campus only if non-null (`if (student.phone != null)` etc.). Since all these are null due to deserialization mismatch, only the unconditional Email row shows.
  implication: Card rendering logic is correct — it's just getting null values because the data never made it through the pipeline.

## Resolution

root_cause: Three-layer mismatch: (1) Flutter sends field names ('ra', 'address', 'period', 'campus') that don't match backend Pydantic schema field names ('registration_number') or don't exist at all in the schema/DB; (2) Backend DB has no 'address' or 'campus' columns and uses 'semester' (int) instead of 'period' (string); (3) Backend list response doesn't return 'phone' and uses 'registration_number'/'semester' while Flutter model expects 'ra'/'period', so deserialization produces nulls.
fix: (pending)
verification: (pending)
files_changed: []
