---
status: partial
phase: 22-fcm-push-notifications
source: [22-VERIFICATION.md]
started: 2026-05-09T00:00:00.000Z
updated: 2026-05-09T00:00:00.000Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Background push notification display

expected: When app is in background and backend dispatches a notification (e.g., document marked ready), the notification appears in the phone's system notification tray with correct title and body in Portuguese.
result: [pending]

### 2. Foreground snackbar and navigation

expected: When app is in foreground and a notification arrives, a floating SnackBar appears with the notification body and a "Ver" action button. Tapping "Ver" navigates to the correct screen. If user is already on the target screen, snackbar is suppressed and data auto-refreshes instead.
result: [pending]

### 3. Cold start deep-link navigation

expected: When app is terminated and user taps a notification, the app opens, completes auth check, and navigates to the correct screen. If JWT is expired, user is redirected to login, and after re-auth navigates to the intended destination.
result: [pending]

### 4. Token registration flow on real device

expected: After successful student login, a real FCM token is obtained from Firebase and sent to the backend via PUT /students/{id}/fcm-token. On logout, the token is deleted via DELETE endpoint. On token refresh (rare), the new token is automatically re-registered.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
