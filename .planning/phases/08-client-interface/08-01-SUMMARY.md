---
phase: 08-client-interface
plan: 01
title: "Client Data Layer (Models, Services, Providers)"
subsystem: mobile/flutter
tags: [models, services, providers, riverpod, json-serializable, codegen]
dependency_graph:
  requires: [07-scaffold-auth]
  provides: [client-models, client-services, client-providers]
  affects: [08-02, 08-03, 08-04, 08-05]
tech_stack:
  added: []
  patterns: [JsonSerializable-codegen, DioClient-injection, riverpod-annotation]
key_files:
  created:
    - mobile/lib/features/client/models/chat_session_model.dart
    - mobile/lib/features/client/models/chat_message_model.dart
    - mobile/lib/features/client/models/action_log_model.dart
    - mobile/lib/features/client/models/document_model.dart
    - mobile/lib/features/client/models/appointment_model.dart
    - mobile/lib/features/client/services/chat_service.dart
    - mobile/lib/features/client/services/document_service.dart
    - mobile/lib/features/client/services/appointment_service.dart
    - mobile/lib/features/client/providers/chat_provider.dart
    - mobile/lib/features/client/providers/document_provider.dart
    - mobile/lib/features/client/providers/appointment_provider.dart
  modified: []
decisions:
  - "Used `if (x != null)` pattern for nullable map entries (Dart null-aware element syntax conflicts with typed maps in Dio data)"
  - "DocumentFilter as @riverpod class with notifier pattern for filter state management"
  - "Services handle both `{data: [...]}` envelope and raw array API responses"
metrics:
  duration: "4m45s"
  completed: "2026-05-04T18:06:58Z"
---

# Phase 08 Plan 01: Client Data Layer Summary

**One-liner:** 5 domain models with JSON codegen, 3 service classes calling REST endpoints, 3 Riverpod providers exposing async state for chat, documents, and appointments.

## What Was Built

### Task 1: Domain Models (5 files)

| Model | Key Fields | Getters |
|-------|-----------|---------|
| ChatSessionModel | id, status, startedAt, endedAt, whatsappPhone, messageCount | `isActive` |
| ChatMessageModel | id, role, content, mediaType, createdAt | `isUser`, `isAssistant` |
| ActionLogModel | id, toolName, inputParams, outputResult, reasoning, latencyMs, retry, status, createdAt | `isError` |
| DocumentModel | id, type, status, fileUrl, notes, requestedAt, completedAt | `isDownloadable`, `isPending` |
| AppointmentModel | id, slotId, reason, status, date, startTime, endTime, createdAt | `isUpcoming` |

All models use `@JsonSerializable()` with `@JsonKey(name: ...)` for snake_case API mapping.

### Task 2: Service Classes (3 files)

| Service | Endpoints |
|---------|-----------|
| ChatService | `GET /chat-sessions`, `GET /chat-sessions/{id}/messages`, `GET /chat-sessions/{id}/action-logs` |
| DocumentService | `GET /documents`, `GET /documents/{id}`, `POST /documents` |
| AppointmentService | `GET /appointments` |

All follow the AuthService DioClient injection pattern.

### Task 3: Riverpod Providers (3 files + codegen)

| Provider | Type | Purpose |
|----------|------|---------|
| chatServiceProvider | `@Riverpod(keepAlive: true)` | ChatService singleton |
| chatSessionsProvider | `@riverpod` async | List of chat sessions |
| chatMessagesProvider | `@riverpod` async (family) | Messages for session ID |
| actionLogsProvider | `@riverpod` async (family) | Action logs for session ID |
| documentServiceProvider | `@Riverpod(keepAlive: true)` | DocumentService singleton |
| documentsProvider | `@riverpod` async | List of documents |
| DocumentFilter | `@riverpod` notifier class | Filter state (null = all) |
| appointmentServiceProvider | `@Riverpod(keepAlive: true)` | AppointmentService singleton |
| appointmentsProvider | `@riverpod` async | List of appointments |

## Verification Results

- ✅ `flutter pub run build_runner build --delete-conflicting-outputs` — 28 outputs, 0 errors
- ✅ `flutter analyze lib/features/client/` — No issues found
- ✅ 5 model `.g.dart` files generated
- ✅ 3 provider `.g.dart` files generated

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | acc3781 | feat(08-01): add domain models with JSON serialization |
| 2 | 9dfe7eb | feat(08-01): add service classes for API communication |
| 3 | 850e4be | feat(08-01): add Riverpod providers for all client domains |

## Self-Check: PASSED

All files verified to exist on disk. All commits verified in git log. Static analysis passes with no issues.
