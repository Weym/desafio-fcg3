---
status: partial
phase: 07-flutter-scaffold-auth
source: [07-VERIFICATION.md]
started: 2026-05-04T17:15:00Z
updated: 2026-05-04T17:15:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Launch app with no stored JWT — verify login screen appears

expected: Splash shows briefly, then navigates to LoginScreen with email field
result: [pending]

### 2. Complete full login flow — enter email, receive OTP, enter code

expected: After verify-code succeeds, app navigates to role-appropriate home with BottomNavigationBar
result: [pending]

### 3. Kill and relaunch app with stored valid JWT

expected: Splash checks token via GET /auth/me, navigates directly to home (no flash of login)
result: [pending]

### 4. Enter invalid OTP 3 times

expected: First 2: 'Codigo invalido (N tentativas restantes)'; 3rd: 'Tentativas esgotadas — novo codigo enviado'
result: [pending]

### 5. Student tries to access /staff URL; staff tries /client URL

expected: GoRouter redirect blocks cross-role access and routes to correct home
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
