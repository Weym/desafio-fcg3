---
phase: 09
reviewed: 2026-05-05T04:30:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - mobile/lib/core/router/app_router.dart
  - mobile/lib/core/router/route_names.dart
  - mobile/lib/features/staff/screens/staff_shell.dart
  - mobile/lib/features/staff/screens/staff_home_screen.dart
  - mobile/lib/features/staff/screens/staff_dashboard_screen.dart
  - mobile/lib/features/staff/screens/staff_schedule_screen.dart
  - mobile/lib/features/staff/screens/staff_appointment_detail_screen.dart
  - mobile/lib/features/staff/screens/staff_ai_screen.dart
  - mobile/lib/features/staff/screens/staff_chat_detail_screen.dart
  - mobile/lib/features/staff/screens/staff_documents_screen.dart
  - mobile/lib/features/staff/screens/widgets/update_status_sheet.dart
  - mobile/lib/features/staff/screens/widgets/send_document_sheet.dart
  - mobile/lib/features/staff/screens/widgets/create_slot_sheet.dart
  - mobile/lib/features/staff/services/staff_dashboard_service.dart
  - mobile/lib/features/staff/services/staff_schedule_service.dart
  - mobile/lib/features/staff/services/staff_document_service.dart
  - mobile/lib/features/staff/services/staff_chat_service.dart
  - mobile/lib/features/staff/providers/staff_dashboard_provider.dart
  - mobile/lib/features/staff/providers/staff_schedule_provider.dart
  - mobile/lib/features/staff/providers/staff_document_provider.dart
  - mobile/lib/features/staff/providers/staff_chat_provider.dart
  - mobile/lib/features/staff/models/staff_dashboard_model.dart
  - mobile/lib/features/staff/models/scheduling_slot_model.dart
  - mobile/lib/features/staff/models/student_summary_model.dart
  - backend/src/features/documents/controllers.py
  - backend/src/features/documents/routes.py
  - backend/src/main.py
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-05-05T04:30:00Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Phase 9 implements a comprehensive staff interface: Flutter screens (Dashboard, Schedule, AI/Chat, Documents), backend file upload endpoint, router integration, and supporting data layer (models, services, providers). The code is well-structured with consistent patterns, proper error/loading/empty states, and good separation of concerns.

However, there are **2 critical issues** (a crash-prone router cast and unauthenticated file access), **3 warnings** (incomplete filename sanitization, potential API contract mismatch, and missing time validation), and **2 info-level** code quality items.

## Critical Issues

### CR-01: Deep-link crash — unchecked cast of `state.extra` in appointment detail route

**File:** `mobile/lib/core/router/app_router.dart:164`
**Issue:** The route builder does `state.extra as AppointmentModel` which will throw a `TypeError` and crash the app when the route `/staff/schedule/:appointmentId` is accessed via deep link, browser URL bar, app restoration, or any navigation path that doesn't pass the `extra` parameter. `state.extra` is `null` by default for deep-linked routes.
**Fix:**
```dart
builder: (context, state) {
  final appointment = state.extra as AppointmentModel?;
  if (appointment == null) {
    // Fallback: navigate back or show error
    return const Scaffold(
      body: Center(child: Text('Agendamento nao encontrado')),
    );
  }
  return StaffAppointmentDetailScreen(appointment: appointment);
},
```

Alternatively, adopt the pattern used for chat detail — pass only the `appointmentId` via path parameters and fetch the data from a provider inside the detail screen.

### CR-02: Uploaded documents served without authentication

**File:** `backend/src/main.py:117`
**Issue:** `app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")` serves all uploaded files (academic transcripts, enrollment proofs, certificates) to any unauthenticated request. Anyone who knows or guesses the URL (UUID-prefixed, but still guessable with brute force or leaked URLs) can access sensitive student documents without authorization.
**Fix:** Replace `StaticFiles` with a protected endpoint that validates the user's JWT/service token before serving the file:
```python
@app.get("/uploads/documents/{filename}")
async def serve_document(
    filename: str,
    user: UserContext = Depends(get_current_user_or_service),
):
    """Serve uploaded document with auth check."""
    file_path = os.path.join("uploads/documents", filename)
    if not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path)
```

For MVP, at minimum restrict to authenticated users. For production, verify the requesting user is the document owner or staff.

## Warnings

### WR-01: Incomplete filename sanitization in upload endpoint — path traversal defense-by-coincidence

**File:** `backend/src/features/documents/controllers.py:200`
**Issue:** The filename from the upload is used directly after UUID prefix: `safe_filename = f"{file_id}_{file.filename}"`. While the UUID prefix prevents simple `../` traversal (because `uuid_../` is a literal dirname), filenames containing path separators like `a/../evil.pdf` would resolve to `uploads/documents/evil.pdf` — overwriting other uploaded files. The defense relies on intermediate directories not existing rather than explicit sanitization. If future code adds `os.makedirs(os.path.dirname(file_path), exist_ok=True)`, full traversal becomes exploitable.
**Fix:**
```python
import re

# Sanitize filename: keep only safe characters
original_name = file.filename or "upload"
safe_name = re.sub(r'[^\w.\-]', '_', os.path.basename(original_name))
safe_filename = f"{file_id}_{safe_name}"
```

### WR-02: Staff `createDocument` sends `student_id` in body but backend ignores it

**File:** `mobile/lib/features/staff/services/staff_document_service.dart:59`
**Issue:** The `createDocument` method sends `'student_id': studentId` in the POST body to `/documents`. However, the backend endpoint `POST /documents` (DOCS-03 in controllers.py:51-66) explicitly uses `user.id` from the authenticated context and ignores any `student_id` in the body (per T-03-26 IDOR protection). This means staff cannot proactively create documents for students via this endpoint — the document would be created for the staff user's ID instead.
**Fix:** Either:
1. Create a separate staff endpoint (`POST /staff/documents`) that accepts `student_id` in the body with proper staff authorization, OR
2. Modify the existing endpoint to allow staff users to specify a `student_id` in the body while keeping the IDOR guard for student users:
```python
if user.role == "staff" and data.student_id:
    effective_student_id = data.student_id
else:
    effective_student_id = user.id
```

### WR-03: Create slot sheet missing start-time < end-time validation

**File:** `mobile/lib/features/staff/screens/widgets/create_slot_sheet.dart:88-104`
**Issue:** The `_submit` method validates that fields are non-empty but does not validate that `_selectedStartTime` is before `_selectedEndTime`. Staff can accidentally create slots where end time precedes start time (e.g., 17:00 - 08:00), which would either crash the backend or create invalid scheduling data.
**Fix:** Add time comparison before submission:
```dart
if (_selectedStartTime != null && _selectedEndTime != null) {
  final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
  final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
  if (endMinutes <= startMinutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Horario de termino deve ser posterior ao inicio')),
    );
    return;
  }
}
```

## Info

### IN-01: Duplicated status helper functions across schedule screens

**File:** `mobile/lib/features/staff/screens/staff_schedule_screen.dart:147-167` and `mobile/lib/features/staff/screens/staff_appointment_detail_screen.dart:225-245`
**Issue:** `_statusBackgroundColor`, `_statusTextColor`, and `_statusLabel` are identically duplicated across both files. This creates maintenance burden — if a new status is added, both files must be updated.
**Fix:** Extract into a shared utility file:
```dart
// mobile/lib/features/staff/screens/widgets/appointment_status_helpers.dart
Color appointmentStatusBackgroundColor(String status) => switch (status) { ... };
Color appointmentStatusTextColor(String status) => switch (status) { ... };
String appointmentStatusLabel(String status) => switch (status) { ... };
```

### IN-02: Statistics computed client-side by fetching all sessions

**File:** `mobile/lib/features/staff/services/staff_chat_service.dart:52-62`
**Issue:** `getStatistics()` fetches ALL chat sessions and computes counts client-side. This works for small datasets but is architecturally suboptimal — if session count grows to thousands, this fetches unnecessary data over the network. The SUMMARY acknowledges this as a deliberate decision (no backend endpoint exists), so flagging as info only.
**Fix:** When a backend `/staff/chat-statistics` endpoint is available, switch to:
```dart
Future<Map<String, dynamic>> getStatistics() async {
  final response = await _client.dio.get('/staff/chat-statistics');
  return response.data as Map<String, dynamic>;
}
```

---

_Reviewed: 2026-05-05T04:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
