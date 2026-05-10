---
phase: 19-staff-ux-corrections
plan: 09
subsystem: ui, api
tags: [flutter, dart, go_router, riverpod, pydantic, field-mapping, filter-navigation]

# Dependency graph
requires:
  - phase: 19-staff-ux-corrections
    provides: "StaffChatsScreen unified tabs, StaffDocumentsScreen filter tabs, StaffCadastroScreen CRUD, backend intervention+document endpoints"
provides:
  - "KPI card filter navigation with initialFilter constructor params"
  - "Correct Concluídos tab filtering by 'closed' status only"
  - "Correct field name mapping (registration_number, semester) in cadastro CRUD"
  - "Phone field in StudentListItem response"
affects: [staff-dashboard, staff-chats, staff-documents, staff-cadastro]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "initialFilter constructor param pattern (replaces GoRouterState.of(context) async reads)"
    - "@JsonKey(name:) for backend field name mapping in models"
    - "Visual filter badge in AppBar when filter pre-applied"

key-files:
  created: []
  modified:
    - "mobile/lib/core/router/app_router.dart"
    - "mobile/lib/features/staff/screens/staff_chats_screen.dart"
    - "mobile/lib/features/staff/screens/staff_documents_screen.dart"
    - "mobile/lib/features/staff/models/staff_student_model.dart"
    - "mobile/lib/features/staff/models/staff_student_model.g.dart"
    - "mobile/lib/features/staff/screens/staff_cadastro_screen.dart"
    - "mobile/lib/features/staff/models/intervention_session_model.dart"
    - "backend/src/features/students/schemas.py"

key-decisions:
  - "Replace GoRouterState.of(context) async reads with constructor initialFilter param to eliminate race conditions"
  - "Remove phantom 'resolved' status entirely — DB only uses 'closed' for completed sessions"
  - "Remove address/campus fields from model and UI since they don't exist in DB schema"
  - "Map ra→registration_number via @JsonKey and semester as int (not String period)"

patterns-established:
  - "initialFilter param pattern: router extracts query params and passes as constructor args"
  - "Visual filter badge pattern: AppBar title shows Chip/Container when filter is pre-applied"

requirements-completed: [SFUX-02, SFUX-03, SFUX-22, SFUX-23, SFUX-24, SFUX-25]

# Metrics
duration: 6min
completed: 2026-05-10
---

# Phase 19 Plan 09: KPI Filter Navigation, Chat Tab Fix, and Cadastro Field Mapping Summary

**KPI cards pass initialFilter to screens via constructor, Concluídos tab uses 'closed' only, cadastro maps registration_number/semester correctly to backend**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-10T00:28:52Z
- **Completed:** 2026-05-10T00:35:06Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- KPI card tapping "Chats Hoje" navigates to /staff/chats?filter=hoje and pre-applies today filter with visual badge
- KPI card tapping "Docs Pendentes" navigates to /staff/documents?filter=pendentes and pre-applies processing filter with visual badge
- Concluídos tab in chats correctly filters by 'closed' status only (removed phantom 'resolved')
- Cadastro expanded card shows Email, Telefone, RA, Período from real backend data
- Form submits registration_number (not ra) and semester as int (not period as string)
- Backend StudentListItem now includes phone field
- Removed non-existent address/campus fields from UI and model

## Task Commits

Each task was committed atomically:

1. **Task 1: Pass initialFilter from router to StaffChatsScreen and StaffDocumentsScreen** - `8a463a2` (feat)
2. **Task 2: Fix Concluídos tab filter to use 'closed' instead of phantom 'resolved'** - `0d23772` (fix)
3. **Task 3: Fix cadastro field name mapping and form submission** - `45f9acf` (fix)

## Files Created/Modified
- `mobile/lib/core/router/app_router.dart` - Router extracts filter query param, passes as constructor arg
- `mobile/lib/features/staff/screens/staff_chats_screen.dart` - Accepts initialFilter, visual badge, removes GoRouterState reads
- `mobile/lib/features/staff/screens/staff_documents_screen.dart` - Accepts initialFilter, visual badge, uses constructor param
- `mobile/lib/features/staff/models/staff_student_model.dart` - @JsonKey mapping for registration_number/semester, remove address/campus
- `mobile/lib/features/staff/models/staff_student_model.g.dart` - Regenerated with correct field mappings
- `mobile/lib/features/staff/screens/staff_cadastro_screen.dart` - Fixed form fields, submit data, expanded card details
- `mobile/lib/features/staff/models/intervention_session_model.dart` - isResolved checks 'closed' not 'resolved'
- `backend/src/features/students/schemas.py` - Added phone to StudentListItem

## Decisions Made
- Replaced GoRouterState.of(context) async reads with constructor initialFilter param to eliminate race conditions between route navigation and frame callback timing
- Removed phantom 'resolved' status entirely — DB only uses 'closed' for completed intervention sessions
- Removed address/campus fields since they don't exist in the backend DB schema at all
- Used @JsonKey(name: 'registration_number') for Dart↔Python field name bridge

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 19 (Staff UX Corrections) plan 09 is the final plan — phase complete
- All 9 plans delivered: staff dashboard, schedule, chats, documents, resources, cadastro, backend endpoints, and gap closures
- Ready for next milestone step (Phase 20+ or verification)

---
*Phase: 19-staff-ux-corrections*
*Completed: 2026-05-10*

## Self-Check: PASSED

All 8 modified files verified on disk. All 3 task commits (8a463a2, 0d23772, 45f9acf) verified in git log.
