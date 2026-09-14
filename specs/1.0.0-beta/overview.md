# Specs — 1.0.0-beta

**Version:** 1.0.0-beta
**Last updated:** 2026-06-30

---

## 2 Waves

| # | Spec | Status | What |
|---|------|--------|------|
| 1 | [`01-erl-fixes`](./01-erl-fixes.md) | 🔴 in progress | Erl runtime + comptime eval (7 steps) + Codegen hardening (6 steps). 13 steps total. **CRITICAL — blocks wave 2.** |
| 2 | [`02-typesystem`](./02-typesystem.md) | 🟡 in progress | Type introspection builtins, std functions, state narrowing, type guards. 9 steps. |

## Dependency chain

```
Wave 1: 01-erl-fixes (foundation — runtime + codegen)
  ├── Part A: Erl runtime (Steps 1-7)
  │     └──► unblocks comptime eval for Wave 2
  ├── Part B: Codegen hardening (Steps 8-13)
  │     └──► Steps 8-9 independent (quick wins)
  │     └──► Steps 10-11 depend on Step 8
  │     └──► Step 12: WAT RUN LOG (codegen runtime)
  │     └──► Step 13: final sweep
  │
  └──► Wave 2: 02-typesystem
         └──► needs Wave 1 Step 1 (decompiler) for comptime eval
         └──► needs Wave 1 Step 8 (crash fixes) for codegen narrowing tests

## Parallel work within each wave

### Wave 1
- **Part A** (Steps 1-7, erl runtime): Steps 3, 5 independent. Step 6 after 1-2. Step 7 after 1-2.
- **Part B** (Steps 8-12, codegen): Step 9 independent (quick win). Step 8 per-backend parallel. Steps 10-11 after 8.

### Wave 2
- Steps 1-5 (type infrastructure) and Steps 6-9 (narrowing) after Step 1
- ⚠️ Steps 2 and 7 both touch `comptime/infer.zig`

## Quick wins (no deps, <30 min each)

| # | Action | Wave | Time |
|---|--------|------|------|
| 1 | Delete 76 orphaned snapshots | 1 | ~10 min |
| 2 | Fix `.len` → `.length` in JS | 1 | ~30 min |
| 3 | Fix `if` without `else` in JS | 1 | ~20 min |
| 4 | Fix record layout assumption | 1 | ~30 min |

## Branch naming

```
spec/1.0.0-beta.<wave>-<step>
```

Examples: `spec/1.0.0-beta.wave1-step1`, `spec/1.0.0-beta.wave1-step8-wasm`

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Step 5 replaced: Restore WAT RUN LOG → Comptime eval pipeline in Erl (renderExprValue + patchHostMethods + erl_prelude) | ericfillipe |
| 2026-06-30 | Restructured into 2 waves. Wave 1 (12 steps): erl runtime fixes + codegen hardening. Wave 2 (9 steps): type introspection + state narrowing. | ericfillipe |
