---
status: investigating
trigger: "KPI card navigation from staff dashboard does NOT pre-apply query param filters on target screens"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: Both screens attempt to read query params via GoRouterState.of(context) inside addPostFrameCallback, but the chats screen explicitly stays on tab 0 ("Todos") and only filters the data list — it never switches to a dedicated tab; the documents screen sets filter to 'processing' but StaffDocumentFilter is an autoDispose Riverpod provider that resets to null on rebuild, and the redirect logic in GoRouter uses `state.matchedLocation` which strips query params
test: Trace query param flow end-to-end in all 4 files
expecting: Find the exact point where query params are lost or ignored
next_action: Document root cause

## Symptoms

expected: Tapping "Chats Hoje" KPI card navigates to /staff/chats?filter=hoje and shows today's chats pre-filtered; tapping "Docs Pendentes" navigates to /staff/documents?filter=pendentes and shows "Processando" tab selected
actual: Both screens show "Todos" tab/filter on arrival despite query params in the URL
errors: No errors — silent failure to apply filter
reproduction: Tap any KPI card on staff dashboard that has a query param filter
started: Since KPI cards were implemented with query params

## Eliminated

## Evidence

- timestamp: 2026-05-09T00:01:00Z
  checked: staff_dashboard_screen.dart lines 112, 121-122
  found: KPI cards correctly call context.go('${RoutePaths.staffChats}?filter=hoje') and context.go('${RoutePaths.staffDocuments}?filter=pendentes')
  implication: Query params ARE being sent from the dashboard side

- timestamp: 2026-05-09T00:02:00Z
  checked: app_router.dart lines 203-205 (staffChats route) and lines 224-225 (staffDocuments route)
  found: Both route builders instantiate const widgets — `const StaffChatsScreen()` and `const StaffDocumentsScreen()` — no query params are passed as constructor args. Query params must be read from GoRouterState at the screen level.
  implication: Router passes query params through GoRouterState, not constructor — this is valid go_router pattern

- timestamp: 2026-05-09T00:03:00Z
  checked: staff_chats_screen.dart lines 31-43 (initState)
  found: CRITICAL BUG — initState reads filter=hoje but then explicitly calls `_tabController.animateTo(0)` (index 0 = "Todos"). The comment says "Stay on Todos tab — filtering handled in list". The _AllSessionsTab widget (line 124-126) does read the filter and applies date-based filtering to the data, but the user sees tab label "Todos" which creates the perception of no filtering.
  implication: Chats screen has partial implementation — data IS filtered but tab selection doesn't reflect it visually. No indicator to user that "hoje" filter is active.

- timestamp: 2026-05-09T00:04:00Z
  checked: staff_documents_screen.dart lines 26-36 (initState) + staff_document_provider.dart lines 25-31
  found: initState correctly reads filter=pendentes and calls `ref.read(staffDocumentFilterProvider.notifier).setFilter('processing')`. The StaffDocumentFilter provider (line 26-31) is `@riverpod` (autoDispose by default in riverpod_annotation). However, the build() method watches this provider (line 41). The issue: setFilter('processing') is called inside addPostFrameCallback AFTER the first build(). The first build sees `filter == null` (Todos). Then setFilter triggers a rebuild with 'processing'. This SHOULD work... unless there's a timing/widget lifecycle issue.
  implication: Documents screen approach is actually correct architecturally — may work if timing is right. Need to verify if the autoDispose is causing a race.

- timestamp: 2026-05-09T00:05:00Z
  checked: staff_shell.dart lines 42-48 (_currentIndex) and lines 51-63 (_onTap)
  found: CRITICAL — _currentIndex uses `GoRouterState.of(context).matchedLocation` which returns the path WITHOUT query parameters. _onTap navigates to plain paths like `RoutePaths.staffChats` (no query params). When user is already on /staff/chats?filter=hoje and taps the "Chats" bottom nav tab, it navigates to /staff/chats (no filter), which rebuilds the screen WITHOUT the query param.
  implication: Shell's bottom nav doesn't preserve query params, but this isn't the primary bug — it's about initial arrival from KPI card.

- timestamp: 2026-05-09T00:06:00Z
  checked: Deeper analysis of chats screen behavior
  found: The chats screen has TWO separate problems: (1) initState animates to tab 0 which is correct since filter=hoje should filter within "Todos" tab, but there is NO visual indicator that a filter is active — user sees "Todos" tab selected and assumes no filter. (2) The _AllSessionsTab builds with GoRouterState.of(context) to check filter=hoje, which works on initial navigation, but if StaffChatsScreen is already mounted (ShellRoute keeps it alive), initState won't re-run on subsequent navigations. go_router with ShellRoute may NOT rebuild the child widget if it's already the active route.
  implication: The REAL bug for chats is that the filter works silently (no visual feedback) AND may not work on re-navigation if widget is already mounted.

## Resolution

root_cause: Two distinct but related failures — (1) StaffChatsScreen reads ?filter=hoje but explicitly stays on "Todos" tab with no visual filter indicator, making it appear unfiltered; (2) StaffDocumentsScreen sets filter in addPostFrameCallback which races with the first build, and the @riverpod autoDispose provider may reset between navigations. Both screens also fail on re-navigation because initState only runs once when ShellRoute keeps widgets alive.
fix: 
verification: 
files_changed: []
