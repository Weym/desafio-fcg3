---
status: investigating
trigger: "Investigate why the personalized welcome message does not include the student's name"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:01:00Z
---

## Current Focus

hypothesis: CONFIRMED — The welcome instruction is never injected because `not history_messages` is always False
test: Traced full data flow from router.py commit → AI service load_chat_history
expecting: history_messages is non-empty because user message was committed before AI reads it
next_action: Document root cause and suggest fix

## Symptoms

expected: When a new session starts, the agent greets the student BY NAME (e.g., "Olá João, sou o Alpha...")
actual: The agent introduces itself as Alpha but does NOT include the student's name in the greeting
errors: None (no crash — behavioral bug)
reproduction: Start a new WhatsApp session with a registered student
started: Unknown — reported as current behavior

## Eliminated

## Evidence

- timestamp: 2026-05-09T00:00:30Z
  checked: Data flow from router.py → background.py → main.py → agent.py for student_name
  found: student_name is correctly passed through the entire chain — router passes student.name, background sends it in JSON, ChatRequest receives it, invoke_agent receives it
  implication: student_name arrives non-empty at agent.py — data flow is not the issue

- timestamp: 2026-05-09T00:00:45Z
  checked: Condition at agent.py:155 — `if is_new_session and not history_messages:`
  found: router.py saves user message to DB at line 168-170 AND commits it at line 186 BEFORE dispatching the background task at line 197. The AI service's load_chat_history at agent.py:148 queries the same DB and will find the already-committed user message. Therefore `history_messages` is NEVER empty on a new session, making the `not history_messages` condition always False.
  implication: The welcome SystemMessage with the student's name is NEVER injected — the conditional gate prevents it 100% of the time

- timestamp: 2026-05-09T00:01:00Z
  checked: Student model at auth/models.py — name field
  found: Student.name is Mapped[str] = mapped_column(String(255), nullable=False) — always present for active students
  implication: student.name in router.py is always a non-empty string for registered students — confirms data side is fine

## Resolution

root_cause: agent.py:155 — The condition `if is_new_session and not history_messages:` prevents the welcome instruction from ever being injected. By the time the AI service reads chat history from the DB, the user's first message has already been committed by the router (router.py:186 `await db.commit()` happens before line 197 `asyncio.create_task(process_message(...))`). So `load_chat_history()` always returns at least one message (the user's), making `not history_messages` always evaluate to False.
fix:
verification:
files_changed: []
