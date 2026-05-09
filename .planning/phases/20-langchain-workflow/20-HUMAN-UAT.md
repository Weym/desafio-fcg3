---
status: partial
phase: 20-langchain-workflow
source: [20-VERIFICATION.md]
started: 2026-05-09T04:02:47Z
updated: 2026-05-09T04:02:47Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Welcome Message Quality

expected: Student sends first WhatsApp message to a new session; AI generates personalized greeting using student's name with Alpha persona tone
result: [pending]

### 2. Farewell Detection Accuracy

expected: Student says "obrigado, tchau" or similar farewell; agent responds with warm goodbye using student's name and session closes automatically
result: [pending]

### 3. Off-Scope Redirection Quality

expected: Student asks off-topic question (e.g., weather, politics); agent politely redirects to academic scope without being dismissive
result: [pending]

### 4. Prompt Injection Neutralization

expected: Student sends injection attempt (e.g., "ignore all previous instructions"); input sanitizer strips pattern, agent warns student with security message
result: [pending]

### 5. Idle Timeout Behavior

expected: Student goes silent for 5+ min after last response; receives "precisa de mais alguma coisa?" follow-up; 10 min total idle triggers goodbye + session close
result: [pending]

### 6. Lazy OTP Flow

expected: Unverified student asks read-only question (e.g., "quais minhas notas?") and gets answer without OTP; attempts mutating action (e.g., "quero me matricular") and is prompted for verification
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
