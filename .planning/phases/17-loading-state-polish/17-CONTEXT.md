# Phase 17: Loading State Polish - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace remaining CircularProgressIndicator widgets in chat/AI detail screens with skeleton shimmer loading states matching the project's shared UX pattern established in Phase 10. Only two screens need changes: client chat detail and staff chat detail (which also serves as the AI data detail screen via route `/staff/ai/:sessionId`). No new features, no new screens.

</domain>

<decisions>
## Implementation Decisions

### Skeleton shape for Messages tab

- **D-01:** Create a new `AppSkeletonChat` widget that renders alternating left/right aligned skeleton bars mimicking chat bubble layout.
- **D-02:** Bot messages represented as left-aligned bars (~70% container width). User messages represented as right-aligned bars (~50% container width).
- **D-03:** Approximately 6-8 skeleton bars per loading state to fill the viewport and suggest a conversation flow.
- **D-04:** Widget uses same shimmer colors as existing skeletons (`colorScheme.surfaceContainerHighest` base, `colorScheme.surface` highlight) for M3 dark mode compatibility.

### Skeleton shape for Actions tab

- **D-05:** Use existing `AppSkeletonList` widget for Actions tab loading — generic rectangles match the card-like list items that actions display.
- **D-06:** Dimensions: `AppSkeletonList(itemCount: 3, itemHeight: 56)` — matching the pattern already used in desktop panels of `staff_ai_screen.dart`.

### Carried forward from Phase 10

- **D-07:** Skeleton displayed on first data load only (when no cached data exists). Not displayed during pull-to-refresh.
- **D-08:** Transition from skeleton to real content is instantaneous — no fade animation.
- **D-09:** Existing `AppSkeletonList` and `AppSkeletonCard` widgets remain unchanged. New `AppSkeletonChat` is additive.

### Agent's Discretion

- Exact bar heights within `AppSkeletonChat` (can vary between bars for visual interest)
- Exact border radius of skeleton bars (should roughly match bubble radius)
- Spacing between skeleton bars
- Whether to add a small avatar circle placeholder on the left side of "bot" bars
- `itemCount` fine-tuning for Actions tab if 3 feels too sparse

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skeleton widget pattern (Phase 10 foundation)

- `.planning/phases/10-cross-platform-polish/10-CONTEXT.md` — D-08 through D-11 define skeleton/shimmer philosophy, widget locations, instantaneous transitions
- `mobile/lib/shared/widgets/app_skeleton_list.dart` — Existing AppSkeletonList implementation (itemCount, itemHeight, padding params, shimmer colors)
- `mobile/lib/shared/widgets/app_skeleton_card.dart` — Existing AppSkeletonCard implementation (height, width, margin params)

### Target screens (files to modify)

- `mobile/lib/features/client/screens/client_chat_detail_screen.dart` — Lines 72 (Messages tab) and 203 (Actions tab) use CircularProgressIndicator
- `mobile/lib/features/staff/screens/staff_chat_detail_screen.dart` — Lines 69 (Messages tab) and 186 (Actions tab) use CircularProgressIndicator

### Reference implementation (desktop panels already using skeletons)

- `mobile/lib/features/staff/screens/staff_ai_screen.dart` — Lines 269 and 307 show AppSkeletonList used for messages/actions in desktop split panels

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **AppSkeletonList** (`mobile/lib/shared/widgets/app_skeleton_list.dart`): Column of shimmer rectangles with configurable count, height, padding. Used in 11+ screens.
- **AppSkeletonCard** (`mobile/lib/shared/widgets/app_skeleton_card.dart`): Single shimmer rectangle with configurable height/width/margin.
- **shimmer package**: Already in pubspec.yaml — `Shimmer.fromColors` is the rendering primitive.

### Established Patterns

- **AsyncValue.when()**: All screens use `when(loading: () => AppSkeletonList(...), error: ..., data: ...)`. The chat detail screens already have this pattern — just need the loading callback replaced.
- **Shimmer colors**: `baseColor: colorScheme.surfaceContainerHighest`, `highlightColor: colorScheme.surface` — consistent across all skeleton widgets.
- **Desktop panels**: `staff_ai_screen.dart` _MessagesPanel and _ActionsPanel already use AppSkeletonList correctly — new code for phone screens should mirror this behavior.

### Integration Points

- **New widget file**: `mobile/lib/shared/widgets/app_skeleton_chat.dart` — new file alongside existing skeleton widgets.
- **Import additions**: Both chat detail screens need `import` for the new AppSkeletonChat and existing AppSkeletonList.
- **No provider changes**: Only the `loading:` callback in `asyncValue.when()` is modified. No data layer or state changes.

</code_context>

<specifics>
## Specific Ideas

- Chat skeleton should visually suggest a conversation — alternating left/right alignment with different widths makes it immediately recognizable as "chat loading" vs generic list.
- Follow same visual language as existing skeletons (rounded rectangles, shimmer animation) but with chat-specific positioning.
- Desktop split panels already work correctly — this phase only targets the standalone phone/tablet detail screens.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

_Phase: 17-loading-state-polish_
_Context gathered: 2026-05-07_
