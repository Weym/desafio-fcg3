---
phase: 19-staff-ux-corrections
reviewed: 2026-05-09T18:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - mobile/lib/features/staff/screens/staff_shell.dart
  - mobile/lib/features/staff/screens/staff_dashboard_screen.dart
  - mobile/lib/features/staff/screens/staff_schedule_screen.dart
  - mobile/lib/features/staff/screens/staff_appointment_detail_screen.dart
  - mobile/lib/features/staff/screens/staff_documents_screen.dart
  - mobile/lib/features/staff/screens/staff_resources_screen.dart
  - mobile/lib/features/staff/screens/staff_cadastro_screen.dart
  - mobile/lib/features/staff/screens/staff_chats_screen.dart
  - mobile/lib/features/staff/screens/staff_chat_detail_screen.dart
  - mobile/lib/features/staff/screens/widgets/send_document_sheet.dart
  - mobile/lib/features/staff/providers/staff_schedule_provider.dart
  - mobile/lib/features/staff/providers/staff_document_provider.dart
  - mobile/lib/features/staff/providers/staff_chat_provider.dart
  - mobile/lib/features/staff/providers/staff_cadastro_provider.dart
  - mobile/lib/features/staff/services/staff_resource_service.dart
  - mobile/lib/features/staff/services/staff_cadastro_service.dart
  - mobile/lib/features/staff/models/staff_student_model.dart
  - mobile/lib/shared/widgets/staff_search_bar.dart
  - mobile/lib/core/router/route_names.dart
  - mobile/lib/core/router/app_router.dart
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 19: Code Review Report

**Reviewed:** 2026-05-09T18:00:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Phase 19 implements Staff UX corrections including a glass bottom nav shell, dashboard with KPIs, schedule/appointments management, documents, resources, student cadastro, and chats screens. The code is generally well-structured with consistent patterns (filter tabs, async state handling, error/empty states). However, there is one critical crash-risk issue (unsafe cast in router), several warnings around missing `mounted` checks and logic errors, and a few info-level items.

## Critical Issues

### CR-01: Unsafe cast of `state.extra` will crash if navigated via deep link or without extra

**File:** `mobile/lib/core/router/app_router.dart:176`
**Issue:** The appointment detail route casts `state.extra as AppointmentModel` without null check. If the route is navigated via deep link, browser URL bar, or any mechanism that doesn't pass `extra`, this will throw a `TypeError` at runtime and crash the app. This is a common GoRouter pitfall.
**Fix:**
```dart
builder: (context, state) {
  final appointment = state.extra as AppointmentModel?;
  if (appointment == null) {
    // Redirect back or show error
    return const Scaffold(
      body: Center(child: Text('Agendamento não encontrado')),
    );
  }
  return StaffAppointmentDetailScreen(appointment: appointment);
},
```

## Warnings

### WR-01: `_calculateAiRate` has dead-code division-by-zero guard

**File:** `mobile/lib/features/staff/screens/staff_dashboard_screen.dart:272-276`
**Issue:** The method adds `+ 10` to `total` (making `total` always ≥ 10), then immediately checks `if (total == 0) return 0;` which can never be true. More importantly, the formula `(total - 1) / total * 100` always produces a value near 90-99%, regardless of actual AI resolution. This appears to be a mock/placeholder that will produce misleading metrics in production.
**Fix:** Either clearly mark this as mock data in the UI (e.g., show "Demo" badge) or implement real calculation logic:
```dart
double _calculateAiRate(StaffDashboardModel dashboard) {
  // TODO: Replace with real AI resolution rate from backend
  if (dashboard.activeChatSessions == 0) return 0;
  return (dashboard.aiResolvedSessions / dashboard.activeChatSessions * 100)
      .clamp(0, 100);
}
```

### WR-02: Route path mismatch — StaffChatDetail navigates to `/staff/chats/:id` but RoutePaths.staffChatDetail points to `/staff/ai/:sessionId`

**File:** `mobile/lib/core/router/route_names.dart:62` and `mobile/lib/features/staff/screens/staff_chats_screen.dart:373`
**Issue:** `RoutePaths.staffChatDetail` is defined as `/staff/ai/:sessionId`, but the `_ChatSessionCard` in chats screen navigates to `/staff/chats/${item.id}`. The router does have a matching nested route under `staffChats` (line 203-210 of app_router.dart with name `'staff-chats-detail'`), so this works at runtime. However, the naming is confusing and inconsistent — `RouteNames.staffChatDetail` / `RoutePaths.staffChatDetail` refer to the AI tab's chat detail, not the unified chats tab. This creates a maintenance trap where someone might use `RoutePaths.staffChatDetail` expecting it to route to the chats tab detail.
**Fix:** Add explicit constants for the chats-tab detail route:
```dart
// In RoutePaths:
static const String staffChatsDetail = '/staff/chats/:sessionId';

// In RouteNames:
static const String staffChatsDetail = 'staff-chats-detail';
```

### WR-03: `_StaffDocumentDetailContent` stores `WidgetRef ref` as a field — fragile pattern

**File:** `mobile/lib/features/staff/screens/staff_documents_screen.dart:266-270`
**Issue:** `WidgetRef` is stored as a field on a `StatelessWidget`. While this works when the sheet is shown immediately, it ties widget lifecycle to a specific `ref` instance. If the parent is disposed while the sheet is visible, `ref.read(...)` may fail or return stale data. The standard pattern is to use `ConsumerStatelessWidget` or `ConsumerWidget` to get a fresh `ref`.
**Fix:**
```dart
class _StaffDocumentDetailContent extends ConsumerWidget {
  final DocumentModel document;

  const _StaffDocumentDetailContent({required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ref from build parameter instead of stored field
    ...
  }
}
```

### WR-04: Unused import `dart:ui` in staff_shell.dart

**File:** `mobile/lib/features/staff/screens/staff_shell.dart:1`
**Issue:** `dart:ui` is imported for `ImageFilter`, which is actually re-exported by `package:flutter/material.dart`. While not a bug, the linter will flag it as unnecessary import. More importantly, `ImageFilter.blur` is from `dart:ui` but Flutter already re-exports it — this is harmless but inconsistent with the rest of the codebase.
**Fix:** This is acceptable as `ImageFilter` comes from `dart:ui`. No change required unless linter flags it. Downgraded to info.

## Info

### IN-01: TODO comment left in production code

**File:** `mobile/lib/features/staff/screens/widgets/send_document_sheet.dart:1`
**Issue:** `// TODO: Bulk send (D-18) - add "Enviar para Turma" mode toggle` — tracking task left as comment.
**Fix:** Move to issue tracker or planning artifact. Remove from source file once feature is scheduled.

### IN-02: Unused import `dart:convert` not fully utilized — `jsonEncode` usage is correct

**File:** `mobile/lib/features/staff/screens/staff_chat_detail_screen.dart:1`
**Issue:** The `dart:convert` import is used for `jsonEncode` on lines 407/430 to display action log input/output. This is fine, just noting it's present and used correctly.
**Fix:** No action needed — verified the import is used.

### IN-03: Duplicated `_FilterTab` widget across multiple files

**Files:**
- `mobile/lib/features/staff/screens/staff_schedule_screen.dart:174-223`
- `mobile/lib/features/staff/screens/staff_documents_screen.dart:461-510`
- `mobile/lib/features/staff/screens/staff_resources_screen.dart:181-228`
- `mobile/lib/features/staff/screens/staff_cadastro_screen.dart:205-252`

**Issue:** The `_FilterTab` widget is copied nearly identically across 4 files with only minor variations (some use `Expanded` wrapper, some have different padding). This duplication increases maintenance burden.
**Fix:** Extract into a shared widget (e.g., `mobile/lib/shared/widgets/segmented_filter_tab.dart`) with parameters for padding and whether to wrap in `Expanded`.

---

_Reviewed: 2026-05-09T18:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
