---
status: diagnosed
trigger: "Investigate why appointment cards and detail screen show fallback data instead of real student/resource names"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: Backend API never returns student_name, student_ra, or resource_name — those fields don't exist in AppointmentListItem schema
test: Compared Flutter model expected keys vs backend AppointmentListItem schema fields
expecting: Mismatch confirms root cause
next_action: Return diagnosis

## Symptoms

expected: Cards show real student name, RA, resource name; detail screen shows all fields; confirm works
actual: Cards show "?" avatar, "Aluno", "Recurso não definido"; detail shows "Não informado"/"Não definido"; confirm returns 404
errors: 404 on PUT /appointments/{id}/confirm
reproduction: Open staff schedule screen, observe any appointment card/detail
started: Phase 19 staff UX work — fields were added to Flutter model but backend never updated

## Eliminated

(none — root cause found on first hypothesis)

## Evidence

- timestamp: 2026-05-09
  checked: Backend AppointmentListItem schema (schemas.py:106-120)
  found: Schema has fields [id, slot_date, slot_start_time, reason, status, authorization_file_url, created_at]. NO student_name, student_ra, resource_name fields.
  implication: API response never contains these keys → Flutter deserializes them as null → fallback values shown

- timestamp: 2026-05-09
  checked: Backend _build_appointment_list_item() (services.py:79-89)
  found: Function only maps id, slot_date, slot_start_time, reason, status, authorization_file_url, created_at. Does NOT join Student or extract resource.name.
  implication: Even though query uses joinedload(Appointment.slot).joinedload(SchedulingSlot.resource), the builder function ignores student and resource data.

- timestamp: 2026-05-09
  checked: Flutter AppointmentModel (appointment_model.dart:20-25)
  found: Model declares @JsonKey(name: 'student_name') studentName, @JsonKey(name: 'student_ra') studentRa, @JsonKey(name: 'resource_name') resourceName — all nullable.
  implication: Flutter side is correctly wired to deserialize these if present. Problem is backend never sends them.

- timestamp: 2026-05-09
  checked: Flutter .g.dart (appointment_model.g.dart:19-21)
  found: Generated code reads json['student_name'], json['student_ra'], json['resource_name'] — correct snake_case keys.
  implication: Deserialization is correct. No key mismatch.

- timestamp: 2026-05-09
  checked: Backend controllers.py for /confirm endpoint
  found: No /confirm route exists. Only routes: POST /appointments, GET /appointments, PUT /appointments/{id}/cancel, POST /appointments/{id}/authorization
  implication: Flutter calls PUT /appointments/{id}/confirm (staff_schedule_service.dart:66) but no such backend route exists → 404.

- timestamp: 2026-05-09
  checked: Backend list_appointments query (services.py:401-404)
  found: Query already does joinedload(Appointment.slot).joinedload(SchedulingSlot.resource) AND Appointment has a student relationship. Data IS loaded from DB but _build_appointment_list_item ignores student.name, student.registration_number, and slot.resource.name.
  implication: Fix only needs to add these fields to schema + builder — no extra query changes needed.

## Resolution

root_cause: Backend AppointmentListItem schema and its builder function omit student_name, student_ra, and resource_name fields, so the API never returns them. Additionally, the PUT /appointments/{id}/confirm endpoint does not exist in the backend.
fix: (not applied — diagnosis only)
verification: (pending)
files_changed: []
