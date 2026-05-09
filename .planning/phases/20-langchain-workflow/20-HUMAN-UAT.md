---
status: partial
phase: 20-langchain-workflow
source: [20-VERIFICATION.md]
started: 2026-05-09T20:30:00Z
updated: 2026-05-09T20:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Welcome Message with Student Name

expected: Agent responds with personalized greeting ('Oi, [Nome], sou o Alpha...') followed by answering the question
result: [pending]

### 2. Farewell Detection with Accents

expected: Agent responds with warm farewell using student name; session status becomes 'closed'
result: [pending]

### 3. Off-Scope Redirection

expected: Agent politely redirects to academic scope without answering
result: [pending]

### 4. Prompt Injection Defense

expected: Input sanitizer strips injection; agent warns about off-pattern message; no system prompt leaked
result: [pending]

### 5. Idle Timeout

expected: Receive 'Precisa de mais alguma coisa?' after 5 min; goodbye + close after 10 min total
result: [pending]

### 6. Lazy OTP Flow

expected: First query answered without OTP; second (mutating) triggers verification request mid-conversation
result: [pending]

### 7. Plain-Text Delivery

expected: WhatsApp messages contain no markdown artifacts — plain text only
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
