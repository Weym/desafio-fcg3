# Phase 17: Loading State Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 17-loading-state-polish
**Areas discussed:** Skeleton shape fidelity

---

## Skeleton Shape Fidelity

### Messages Tab Skeleton

| Option | Description | Selected |
| --- | --- | --- |
| Chat-bubble skeleton | 6-8 alternating rectangles: narrow on left, wide on right to suggest conversation. Requires new widget (AppSkeletonChat). Matches 'mirror actual layout' principle. | ✓ |
| Generic rectangles | Same AppSkeletonList as desktop panels. Keeps widgets minimal. Consistent with existing patterns. | |
| You decide | Let the agent figure out based on effort vs. visual fidelity tradeoffs. | |

**User's choice:** Chat-bubble skeleton
**Notes:** User wants the skeleton to visually mirror the actual chat layout rather than using generic rectangles.

### Bubble Layout Positioning

| Option | Description | Selected |
| --- | --- | --- |
| Alternating left/right | Bot messages left-aligned (~70% width), user messages right-aligned (~50% width). Mimics real chat layout closely. | ✓ |
| Varying widths, no alignment | All skeleton bars same alignment but varying widths to suggest variety without explicit bubble positioning. | |

**User's choice:** Alternating left/right
**Notes:** None — straightforward selection of the recommended layout.

### Actions Tab Skeleton

| Option | Description | Selected |
| --- | --- | --- |
| Generic AppSkeletonList | Actions are card-like list items. AppSkeletonList with itemHeight 56-72 matches well. | ✓ |
| Custom action skeleton | Icon placeholder + text lines. More effort for marginal fidelity gain. | |

**User's choice:** Generic AppSkeletonList
**Notes:** Actions tab doesn't need special treatment — standard list skeleton is appropriate.

---

## Agent's Discretion

- Exact bar heights within AppSkeletonChat
- Border radius of skeleton bars
- Spacing between skeleton bars
- Whether to include avatar circle placeholder
- itemCount fine-tuning for Actions tab

## Deferred Ideas

None — discussion stayed within phase scope.
