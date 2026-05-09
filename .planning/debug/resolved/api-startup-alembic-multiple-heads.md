---
status: resolved
trigger: "api-startup-alembic-multiple-heads — fcg3-api exits 255 on docker compose up: Alembic reports 'Revision 012a is present more than once' and 'Multiple head revisions are present for given argument head'"
created: 2026-05-06T11:30:00-03:00
updated: 2026-05-06T12:05:00-03:00
resolved_commit: 7303ce1
---

## Current Focus

hypothesis: RESOLVED. Alembic chain is linear (`011a → 012a → 012b → 013a`, single head `013a`); live migration runs verified in-container. Committed as `7303ce1`. User selected option A: commit alembic fix + archive this session; track seed.py corruption in a separate debug session.
test: (final) `git log -1 --format='%h %s'` → `7303ce1 fix(alembic): resolve duplicate 012a revision …`; `docker compose run --rm fastapi-app alembic heads` → `013a (head)`; live DB now at `013a` after first post-fix boot.
expecting: No further action on the alembic issue. End-to-end `fcg3-api` UP + `/health` 200 is BLOCKED by the separate seed.py merge corruption, to be handled in its own debug session — not a regression of this fix.
next_action: Archived to `.planning/debug/resolved/`. See "Known follow-up" below for seed.py work tracked separately.

## Known follow-up (NOT part of this session)

The same merge commit `4f1c12b` that caused the alembic collision also corrupted `backend/scripts/seed.py`:
- Duplicate `seed_scheduling` function (lines 471 and 597 — Python uses the second, but `main()` expects the first's return type)
- Unclosed `session.add(` at line 690 (orphan `slot.is_available = False` pasted into wrong scope)
- Lost appointment-creation loop inside `seed_users_and_current_period` (while `STUDENTS_DATA[*].appointments` still references `AppointmentSeed` entries)

This is tracked in a separate debug session. Post-alembic-fix, `fcg3-api` now fails at `scripts/seed.py:690 SyntaxError` during docker entrypoint's `python -m scripts.seed` step. That is expected and NOT a regression of the alembic fix (verified: error trace is a Python parse-time error, no alembic output).

## Symptoms

expected: `fcg3-api` container starts cleanly after `docker compose up`; Alembic upgrades to a single head.
actual: Container exits with code 255 immediately after Alembic errors. No API server bound to :8000. Other services (postgres, mcp, ai, flutter-web) start fine.
errors: |
  UserWarning: Revision 012a is present more than once
  ERROR [alembic.util.messaging] Multiple head revisions are present for given argument 'head'; please specify a specific target revision, '<branchname>@head' to narrow to a specific head, or 'heads' for all heads
  FAILED: Multiple head revisions are present for given argument 'head'
reproduction: |
  1. `docker compose up --build` (or `docker compose up` after a build).
  2. `fcg3-api` exits 255; `docker logs fcg3-api` shows the Alembic error above.
started: Surfaced this session, immediately after PR #5 (`feat/human-intervention`) was merged into the main branch. The merge commit `4f1c12b` brought together two parallel branches that each introduced a migration with `revision = "012a"`.

## Eliminated

(none yet — root cause confirmed by direct file inspection in Phase 1, no hypotheses needed elimination)

## Evidence

- timestamp: 2026-05-06T11:31:00-03:00
  checked: Knowledge base (.planning/debug/knowledge-base.md)
  found: Recent resolved session `chat-session-never-closes` (2026-05-06) introduced migration with `revision = "012a"` (file: 012_fix_pg_cron_session_autoclose_quoting.py). High-probability candidate hypothesis: a parallel branch added another migration also using "012a".
  implication: Confirms the duplicate id is a real possibility from recent activity. Need to enumerate all 012-prefixed files.

- timestamp: 2026-05-06T11:32:00-03:00
  checked: `ls backend/alembic/versions/` and `grep -nE "^(revision|down_revision)" 011..013`
  found: Three files starting with "012_":
    - 011_add_pg_cron_session_autoclose.py            → revision "011a", down_revision "010a"
    - 012_expand_resources_add_authorization.py        → revision "012a", down_revision "011a"   (duplicate)
    - 012_fix_pg_cron_session_autoclose_quoting.py     → revision "012a", down_revision "011a"   (duplicate)
    - 013_add_human_intervention_status.py            → revision "013a", down_revision "012a"   (ambiguous parent)
  implication: ROOT CAUSE CONFIRMED. Two migrations declare identical (revision, down_revision) → divergent heads from 011a. `013a` cannot resolve its parent.

- timestamp: 2026-05-06T11:33:00-03:00
  checked: `git log` of both 012 files
  found: `012_fix_pg_cron_session_autoclose_quoting.py` committed first (3b316d2, 03:02 -0300) on what became the development branch. `012_expand_resources_add_authorization.py` committed later (e1d22e7, 06:42 -0300) on `feat/human-intervention` without rebasing on latest development. Merge commit `4f1c12b` brought both 012a's into the same tree.
  implication: Classic merge-collision migration ID conflict. No malice or design error in either migration individually — failure mode is process (no rebase + Alembic doesn't auto-detect ID collision until both files coexist).

- timestamp: 2026-05-06T11:34:00-03:00
  checked: `docker exec fcg3-postgres psql -c "SELECT version_num FROM alembic_version;"`  + schema introspection of `resources` table + `SELECT command FROM cron.job;`
  found: alembic_version = "012a". `resources` table has NO `description` / `requires_authorization` columns and the check constraint is the OLD 3-value form. `cron.job.command` uses correct single quotes.
  implication: The applied "012a" in the DB is the pg_cron-fix migration (012_fix_pg_cron_session_autoclose_quoting.py), NOT the resource-expansion migration. Therefore: pg_cron fix is "frozen" as 012a. The resource-expansion migration is unapplied and SAFE TO RENAME.

- timestamp: 2026-05-06T11:35:00-03:00
  checked: docker-compose.yml command for fastapi-app service
  found: `command: bash -c "alembic upgrade head && python -m scripts.seed && exec uvicorn ..."` → Alembic runs on every container start. Failure here aborts the entire chain (seed never runs, uvicorn never binds). This explains exit code 255 (alembic CLI failure) and absence of any uvicorn log line.
  implication: The fix MUST resolve to a single head before the next `docker compose up` will succeed. No retry or fallback path exists in the entrypoint.

- timestamp: 2026-05-06T11:45:00-03:00
  checked: After applying the rename + revision id changes, ran `docker compose run --rm --no-deps fastapi-app alembic heads` and `alembic history --verbose`.
  found: `alembic heads` → "013a (head)" (single). History shows clean linear chain: `<base> → 001a → 002a → ... → 010a → 011a → 012a → 012b → 013a`.
  implication: ALEMBIC ROOT CAUSE FULLY RESOLVED. No more divergent heads. Original UserWarning and "Multiple head revisions" error are gone.

- timestamp: 2026-05-06T11:50:00-03:00
  checked: `docker compose up -d fastapi-app` followed by `docker logs fcg3-api --tail 50`.
  found: First boot attempt still showed the old "Multiple head revisions" error from a stale `__pycache__` (left over from before the rename, owned by container's root). After `docker run --rm -v ./backend/alembic/versions/__pycache__:/cache alpine rm -rf /cache/*`, the second boot attempt cleanly ran:
    - `Running upgrade 012a -> 012b, expand resources with new types, description, requires_authorization; add authorization_file_url to appointments`
    - `Running upgrade 012b -> 013a, add human intervention status to chat_sessions`
  Then crashed on `python -m scripts.seed` with: `File "/app/scripts/seed.py", line 690 / session.add( / SyntaxError: '(' was never closed`.
  implication: The Alembic problem the user originally reported is gone. fastapi-app now fails on a SECOND, INDEPENDENT bug introduced by the same merge: `backend/scripts/seed.py` is corrupted.

- timestamp: 2026-05-06T11:53:00-03:00
  checked: `git show 4f1c12b -- backend/scripts/seed.py` (the merge commit) + `grep -n "Appointment\|seed_scheduling\|slot.is_available" backend/scripts/seed.py`
  found: The merge introduced THREE distinct issues in seed.py:
    (a) DUPLICATE FUNCTION: `seed_scheduling` is defined twice — first at line 471 (development branch version, returns `list[SchedulingSlot]`), then again at line 597 (feat/human-intervention version, returns `None`). Python keeps the second definition, but `main()` line 765 calls it as `slots = await seed_scheduling(session)` expecting a list, and passes `slots` to `seed_users_and_current_period`.
    (b) SYNTAX ERROR: Inside the second `seed_scheduling` (lines 689-698) the merge mangled a `session.add(SchedulingSlot(...))` block — the closing `)` was dropped and an orphan `slot.is_available = False` line from the development branch's APPOINTMENT-creation block was pasted into the wrong scope.
    (c) LOST LOGIC: The development branch's `Appointment(...)` seeding inside `seed_users_and_current_period` (which iterates `student_seed.appointments` and creates Appointment rows + marks slots unavailable) is GONE — the loop was lost in the merge but `STUDENTS_DATA` still references `AppointmentSeed` entries.
  implication: This is a SEPARATE, LARGER bug. Fixing it requires merge-conflict reasoning (which version of seed_scheduling to keep? does the human-intervention branch's expanded resource list need appointments wired in? does the appointments-loop need to be re-added?). These are decisions that need human input — they are not simple syntax repair. Recommend a SEPARATE debug session focused on the seed.py merge corruption, OR explicit user authorization to attempt the merge-resolution here.

## Resolution

root_cause: |
  Migration ID collision created by independent parallel branches. Two files in `backend/alembic/versions/` both declared `revision = "012a"` with `down_revision = "011a"`:
    1. `012_fix_pg_cron_session_autoclose_quoting.py` (committed 03:02 on what became development; ALREADY APPLIED to local DB — `alembic_version = "012a"`)
    2. `012_expand_resources_add_authorization.py` (committed 06:42 on `feat/human-intervention` without rebasing; NOT applied)
  When PR #5 (`feat/human-intervention`) was merged via `4f1c12b`, both files entered the same tree. Alembic loads ALL files in `versions/`, sees `012a` twice, warns "Revision 012a is present more than once", and refuses to resolve `head` because there are now two divergent heads from `011a`. The downstream `013_add_human_intervention_status.py` references `down_revision = "012a"` ambiguously, but its head status is moot — Alembic fails before getting that far. The fastapi-app docker entrypoint runs `alembic upgrade head` first, so the failure aborts the whole boot and `fcg3-api` exits 255.
fix: |
  Linearize the chain (preferred over a merge migration because the two 012a files touch independent subsystems and there is no shared state to merge):
    1. Rename file `012_expand_resources_add_authorization.py` → `012b_expand_resources_add_authorization.py` (or keep filename but doesn't matter — Alembic uses the `revision` constant, not the filename; we'll bump filename for human readability).
    2. In that file: change `revision = "012a"` → `revision = "012b"` and KEEP `down_revision = "011a"` ❌ — actually CHANGE `down_revision` to `"012a"` so the chain is 011a → 012a (pg_cron fix, already applied) → 012b (resources) → 013a (human intervention).
    3. In `013_add_human_intervention_status.py`: change `down_revision = "012a"` → `down_revision = "012b"`.
  Net effect: local DB stays at 012a (no manual `alembic_version` patching needed); next `alembic upgrade head` advances DB through 012b → 013a normally, applying the resource-expansion + human-intervention migrations in order.
verification: |
  - `docker compose run --rm --no-deps fastapi-app alembic heads` → "013a (head)" (single head ✓)
  - `alembic history --verbose` → linear chain `001a → ... → 011a → 012a → 012b → 013a` (no branches ✓)
  - `docker compose up -d fastapi-app` → alembic runs cleanly, applies `012a -> 012b -> 013a` ✓
  - End-to-end `fcg3-api` Up + bound to :8000 + `curl /health` → BLOCKED by separate seed.py SyntaxError bug introduced by the same merge commit. NOT a regression of the alembic fix; verified by reading the new error trace which is a Python parse-time error inside `scripts/seed.py:690`, not an alembic error.
files_changed:
  - backend/alembic/versions/012b_expand_resources_add_authorization.py  # renamed from 012_expand_resources_add_authorization.py + revision "012a"→"012b" + down_revision "011a"→"012a" + added merge-context note in docstring
  - backend/alembic/versions/013_add_human_intervention_status.py        # down_revision "012a"→"012b" (both in docstring "Revises:" and revision identifier block)
