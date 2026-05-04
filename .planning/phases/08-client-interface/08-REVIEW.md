---
phase: 08-client-interface
reviewed: 2026-05-04T19:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - mobile/lib/core/router/app_router.dart
  - mobile/lib/core/router/route_names.dart
  - mobile/lib/features/client/models/action_log_model.dart
  - mobile/lib/features/client/models/appointment_model.dart
  - mobile/lib/features/client/models/chat_message_model.dart
  - mobile/lib/features/client/models/chat_session_model.dart
  - mobile/lib/features/client/models/document_model.dart
  - mobile/lib/features/client/providers/appointment_provider.dart
  - mobile/lib/features/client/providers/chat_provider.dart
  - mobile/lib/features/client/providers/document_provider.dart
  - mobile/lib/features/client/providers/notification_provider.dart
  - mobile/lib/features/client/screens/client_chat_detail_screen.dart
  - mobile/lib/features/client/screens/client_chat_screen.dart
  - mobile/lib/features/client/screens/client_documents_screen.dart
  - mobile/lib/features/client/screens/client_home_screen.dart
  - mobile/lib/features/client/screens/client_notifications_screen.dart
  - mobile/lib/features/client/screens/client_support_screen.dart
  - mobile/lib/features/client/screens/widgets/document_request_sheet.dart
  - mobile/lib/features/client/services/appointment_service.dart
  - mobile/lib/features/client/services/chat_service.dart
  - mobile/lib/features/client/services/document_service.dart
  - mobile/lib/features/client/screens/client_shell.dart
findings:
  critical: 1
  warning: 4
  info: 4
  total: 9
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-05-04T19:00:00Z
**Depth:** standard
**Files Reviewed:** 22 (16 source + 6 generated `.g.dart` skimmed for consistency)
**Status:** issues_found

## Summary

Phase 08 implements the client-facing interface for the Flutter mobile app: 5 domain models with JSON serialization, 3 API service classes, Riverpod providers, 6 screens (home dashboard, chat list, chat detail with tabs, documents with filters, notifications, support), a document request bottom sheet, a shell with bottom navigation, and full GoRouter wiring with role guards.

**Overall quality is good.** The code follows project conventions (snake_case API mapping, Riverpod patterns, Material 3 theming), has proper error handling in most places, and the router redirect logic correctly enforces role-based access control.

**Key concerns:**
1. One **critical** compilation error (`initialValue` vs `value` in `DropdownButtonFormField`)
2. Several warnings around missing error handling, unsafe list access, and hardcoded placeholder data that could leak in production

## Critical Issues

### CR-01: Invalid `initialValue` property on DropdownButtonFormField

**File:** `mobile/lib/features/client/screens/widgets/document_request_sheet.dart:99`
**Issue:** `DropdownButtonFormField` does not have an `initialValue` parameter. The correct parameter is `value`. This will cause a compilation error — the Dart analyzer will reject this code.
**Fix:**
```dart
DropdownButtonFormField<String>(
  decoration: const InputDecoration(
    labelText: 'Tipo de documento',
  ),
  value: _selectedType,
  items: _documentTypes.entries
      .map(
        (entry) => DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        ),
      )
      .toList(),
  onChanged: (value) => setState(() => _selectedType = value),
  validator: (value) =>
      value == null ? 'Selecione o tipo de documento' : null,
),
```

## Warnings

### WR-01: Unsafe assumption that `sessions.first` is the latest session

**File:** `mobile/lib/features/client/screens/client_home_screen.dart:109`
**Issue:** `sessions.first` is used to display the "latest bot activity" but the list is not sorted before access. The API may return sessions in any order. If the API returns them in ascending order, `sessions.first` would be the *oldest* session, not the latest.
**Fix:**
```dart
data: (sessions) {
  String subtitle;
  if (sessions.isEmpty) {
    subtitle = 'Nenhuma atividade';
  } else {
    final sorted = List<ChatSessionModel>.from(sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    subtitle = _formatDateTime(sorted.first.startedAt);
  }
  // ...
```

### WR-02: Missing error handling in `_launchDownload` — silent failure

**File:** `mobile/lib/features/client/screens/client_documents_screen.dart:150-155`
**Issue:** When `canLaunchUrl` returns `false`, the function silently does nothing. The user clicks "download" and nothing happens — no feedback. Additionally, `Uri.parse` on a malformed URL will throw a `FormatException` that is unhandled.
**Fix:**
```dart
Future<void> _launchDownload(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Show feedback (requires context — consider making this a method on the widget)
    }
  } catch (_) {
    // Handle malformed URL
  }
}
```

### WR-03: Error message exposes raw error object to user

**File:** `mobile/lib/features/client/screens/client_chat_screen.dart:33`
**Issue:** `Text('Erro ao carregar sessoes: $error')` interpolates the raw Dart exception/error object into the UI. This could expose stack traces, DioException internals, or server error messages to end users — which is both a UX problem and a minor security concern (information disclosure).
**Fix:**
```dart
Text('Erro ao carregar sessoes'),
```
Same issue also exists at:
- `mobile/lib/features/client/screens/client_chat_detail_screen.dart:76` — messages error
- `mobile/lib/features/client/screens/client_chat_detail_screen.dart:195` — actions error

### WR-04: `_formatRelativeTime` returns "ha 0min" for just-now timestamps

**File:** `mobile/lib/features/client/screens/client_notifications_screen.dart:142-155`
**Issue:** When `diff.inMinutes` is 0 (event happened < 60 seconds ago), the function returns `"ha 0min"` which is confusing UX. Should show "agora" or "ha poucos segundos".
**Fix:**
```dart
String _formatRelativeTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.isNegative) {
    final absDiff = timestamp.difference(DateTime.now());
    if (absDiff.inMinutes < 1) return 'em breve';
    if (absDiff.inMinutes < 60) return 'em ${absDiff.inMinutes}min';
    if (absDiff.inHours < 24) return 'em ${absDiff.inHours}h';
    if (absDiff.inDays < 7) return 'em ${absDiff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'ha ${diff.inMinutes}min';
  if (diff.inHours < 24) return 'ha ${diff.inHours}h';
  if (diff.inDays < 7) return 'ha ${diff.inDays}d';
  return '${timestamp.day}/${timestamp.month}';
}
```

## Info

### IN-01: Duplicated `_typeLabel` function across files

**File:** `mobile/lib/features/client/screens/client_documents_screen.dart:158` and `mobile/lib/features/client/providers/notification_provider.dart:94`
**Issue:** The `_typeLabel(String type)` function that maps document type codes to Portuguese labels is duplicated in two files with identical logic. If a new document type is added, both must be updated independently.
**Fix:** Extract to a shared utility (e.g., `mobile/lib/features/client/utils/document_helpers.dart`) and import from both locations.

### IN-02: Duplicated `_formatDateTime` / `_formatDate` helper functions

**File:** `mobile/lib/features/client/screens/client_home_screen.dart:14-21`, `mobile/lib/features/client/screens/client_chat_screen.dart:96-103`, `mobile/lib/features/client/screens/client_chat_detail_screen.dart:114-118`, `mobile/lib/features/client/screens/client_chat_detail_screen.dart:234-239`
**Issue:** Date formatting logic is duplicated 4 times across screen files with minor variations. This violates DRY and creates maintenance risk.
**Fix:** Create a shared `date_formatters.dart` utility with `formatDateTime`, `formatDate`, `formatTime` functions.

### IN-03: Hardcoded support contact information

**File:** `mobile/lib/features/client/screens/client_support_screen.dart:4-7`
**Issue:** Email, phone, and WhatsApp URL are hardcoded as constants. While acceptable for MVP, these should ideally come from a remote configuration or environment config to allow updates without app releases.
**Fix:** No immediate action required for MVP, but consider moving to `AppConfig` or a remote config endpoint in future iterations.

### IN-04: `dart:convert` import used only for JSON pretty-printing in debug-like UI

**File:** `mobile/lib/features/client/screens/client_chat_detail_screen.dart:1`
**Issue:** The `dart:convert` import is used only for `JsonEncoder.withIndent` in the action logs expansion panel. This is fine for a developer/debug view, but if action log input/output data is large, it could cause jank when expanding tiles (synchronous JSON encoding on the UI thread). Minor concern for now.
**Fix:** No action needed — flagging for awareness. If performance becomes an issue, consider lazy rendering or `compute()` isolate for large payloads.

---

_Reviewed: 2026-05-04T19:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
