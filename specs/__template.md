# [SPEC NAME]

**Version:** 1.0.0-beta
**Status:** planning
**Created:** [DATE]
**Author:** [AUTHOR]

---

## Status

> **planning** → **in progress** → **completed** / **cancelled**

**Current:** planning

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | [Step title] | pending | [NAME] |

## Objective

[2-4 lines: what is achieved, what problem is solved.]

## Prerequisites

- [Dependencies, related specs, blocking conditions]
- [E.g.: Spec `X.md` completed]
- [E.g.: `zig build test` passing]

## Steps

Statuses: **pending** | **open** (in progress) | **completed** | **cancelled**

### Step 1 — [Step title]

**Status:** pending **Assignee:** [NAME]

**Acceptance criteria:**
- [ ] [Objective condition]
- [ ] `zig build test` passes

### Files to modify

| File | Purpose |
|------|---------|
| `path/to/file.zig` | What changes |

---

## Summary

| Metric | Count |
|--------|-------|
| [Metric] | [Value] |

## Working Memory

Create a `_memory.md` sibling file to track live thinking during spec
execution — current state, open questions, hunches, next actions. This file
is **not** committed (`.gitignore`-ed via `_memory.md`).

Two usage modes:

1. **Clean slate** — empty file; write whatever comes up while working.
2. **Spec snapshot** — copy the Steps table and current status from this
   spec into `_memory.md` as a checklist; tick off items, add per-step
   notes, keep the live state in one place.

Either way: update it liberally, delete it when the spec closes. Never
commit it — it's transient scratch, not a design artifact.

## Notes

- [Design decisions, risks, alternatives]

## Changelog

| Date | Change | Author |
|------|--------|--------|
| [DATE] | Spec created | [NAME] |
