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

### 1. Welcome message personalization

expected: Agent responds with personalized greeting ('Oi, [Nome], sou o Alpha...') followed by answering the question
result: [pending]

### 2. Farewell detection + session close

expected: Agent responds with warm farewell using student name; session status becomes 'closed'
result: [pending]

### 3. Off-scope question redirection

expected: Agent politely redirects to academic scope without answering
result: [pending]

### 4. Prompt injection defense

expected: Input sanitizer strips injection; agent warns about off-pattern message; no system prompt leaked
result: [pending]

### 5. Idle timeout follow-up + auto-close

expected: Receive 'Precisa de mais alguma coisa?' after 5 min; goodbye + close after 10 min total
result: [pending]

### 6. Lazy OTP — read-only then mutating

expected: First query answered without OTP; second triggers verification request mid-conversation
result: [pending]

### 7. Plain text responses (no markdown)

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
