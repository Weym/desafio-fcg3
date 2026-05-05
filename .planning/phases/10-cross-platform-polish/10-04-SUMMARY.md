---
phase: 10-cross-platform-polish
plan: 04
subsystem: mobile-flutter
tags: [cache, ttl, prefetch, riverpod, performance]
dependency_graph:
  requires: [10-01]
  provides: [ttl-cache-invalidation, tab-prefetch]
  affects: [all-data-providers, client-shell, staff-shell]
tech_stack:
  added: []
  patterns: [TTL-timer-invalidation, postFrameCallback-prefetch, ConsumerStatefulWidget]
key_files:
  created:
    - mobile/lib/core/providers/cache_provider.dart
  modified:
    - mobile/lib/features/client/providers/chat_provider.dart
    - mobile/lib/features/client/providers/document_provider.dart
    - mobile/lib/features/client/providers/appointment_provider.dart
    - mobile/lib/features/staff/providers/staff_dashboard_provider.dart
    - mobile/lib/features/staff/providers/staff_schedule_provider.dart
    - mobile/lib/features/staff/providers/staff_document_provider.dart
    - mobile/lib/features/staff/providers/staff_chat_provider.dart
    - mobile/lib/features/client/screens/client_shell.dart
    - mobile/lib/features/staff/screens/staff_shell.dart
decisions:
  - CacheTTL uses static map of timers keyed by provider name for simplicity
  - Timer-based invalidation over manual TTL check for zero-cost reads during window
  - Shells converted to ConsumerStatefulWidget for ref access in initState
metrics:
  duration: 2m28s
  completed: 2026-05-05T14:34:32Z
---

# Phase 10 Plan 04: TTL Cache Invalidation & Tab Prefetch Summary

**One-liner:** 5-minute TTL auto-invalidation on all 7 data providers with shell-level adjacent-tab prefetch for <2s perceived latency

## What Was Built

### CacheTTL Utility (`cache_provider.dart`)
- Static utility class with 5-minute `Duration` constant
- `schedule(ref, key)` method: cancels existing timer, starts new TTL timer, auto-calls `ref.invalidateSelf()` on expiry
- `ref.onDispose()` cleanup prevents memory leaks from orphaned timers
- Zero coupling — providers call one static method after fetching data

### Provider TTL Integration (7 providers)
All list-data providers now call `CacheTTL.schedule(ref, 'key')` after awaiting their service response:
- `chatSessionsProvider` → key: 'chatSessions'
- `documentsProvider` → key: 'documents'
- `appointmentsProvider` → key: 'appointments'
- `staffDashboardProvider` → key: 'staffDashboard'
- `staffAppointmentsProvider` → key: 'staffAppointments'
- `staffDocumentsProvider` → key: 'staffDocuments'
- `staffChatSessionsProvider` → key: 'staffChatSessions'

### Shell Prefetch (2 shells)
- `ClientShell` → `ConsumerStatefulWidget`, prefetches chat/documents/appointments on mount
- `StaffShell` → `ConsumerStatefulWidget`, prefetches dashboard/appointments/documents/chat on mount
- Uses `WidgetsBinding.instance.addPostFrameCallback` to avoid blocking initial render
- Since providers use `keepAlive`, prefetched data stays in memory until TTL expires

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 9a2be49 | feat(10-04): create TTL cache invalidation utility and apply to all data providers |
| 2 | f0ac8ab | feat(10-04): implement tab prefetch on shell navigation |

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `dart analyze lib/core/providers/cache_provider.dart` → No issues found
- `dart analyze lib/features/client/screens/client_shell.dart lib/features/staff/screens/staff_shell.dart` → No issues found
- `grep -r "CacheTTL.schedule" lib/features/` → 7 matches across all providers

## Self-Check: PASSED
