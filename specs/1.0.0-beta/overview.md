# Specs — 1.0.0-beta

**Version:** 1.0.0-beta
**Last updated:** 2026-06-30

---

## 3 Waves

| # | Spec | Status | What |
|---|------|--------|------|
| 1 | [`01-erl-fixes`](./01-erl-fixes.md) | 🔴 in progress | Erl runtime fixes (7 steps: decompiler, decorator eval, record layout, test failures, WAT RUN LOG, regression tests, type eval tests). **CRITICAL — blocks waves 2 and 3.** |
| 2 | [`02-typesystem`](./02-typesystem.md) | 🟡 in progress | Type introspection builtins, std functions, state narrowing, type guards. |
| 3 | [`03-codegen`](./03-codegen.md) | 🟡 in progress | Runtime crash fixes (120 across 4 backends) + 34 new codegen tests. |

## Completed (reference)

| Spec | What |
|------|------|
| [`persistent-erl-runtime`](./persistent-erl-runtime.md) | Replace wasm3 with persistent erl subprocess |
| [`erl-comptime-speed`](./erl-comptime-speed.md) | BEAM cache, binary protocol, single erl runtime |

## Dependency chain

```
Wave 1: 01-erl-fixes (decompiler)
  ├──► Wave 2: 02-typesystem (builtins + narrowing)
  │      └──► needs Wave 3 Step 1 for codegen narrowing tests
  │
  └──► Wave 3: 03-codegen (crash fixes + new tests)
         └──► Steps 3-4 (template/comptime tests)
```

## Parallel work within each wave

### Wave 1
- Steps 3 (record layout) and 5 (WAT RUN LOG) independent
- Step 2 (decorator) can start after Step 1's decompiler is reusable

### Wave 2
- Steps 1-5 (type infrastructure) and Steps 6-9 (narrowing) after Step 1
- ⚠️ Steps 2 and 7 both touch `comptime/infer.zig`

### Wave 3
- Step 2 (orphans) independent — do first
- Step 1 per-backend sub-steps parallel (different files)
- Steps 3-4 parallel per category after Step 1

## Quick wins (no deps, <30 min each)

| # | Action | Wave | Time |
|---|--------|------|------|
| 1 | Delete 76 orphaned snapshots | 3 | ~10 min |
| 2 | Fix `.len` → `.length` in JS | 3 | ~30 min |
| 3 | Fix `if` without `else` in JS | 3 | ~20 min |
| 4 | Skip WASM RUN LOG for external tests | 3 | ~15 min |
| 5 | Fix record layout assumption | 1 | ~30 min |

## Branch naming

```
spec/1.0.0-beta.<wave>-<step>
```

Examples: `spec/1.0.0-beta.wave1-step1`, `spec/1.0.0-beta.wave3-step1-wasm`

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Restructured into 3 waves; merged comptime-type-introspection + state-narrowing + comptime-eval-and-types into wave 2; merged codegen-test-gap into wave 3 | ericfillipe |
