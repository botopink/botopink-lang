# Specs Overview — 1.0.0-beta

**Version:** 1.0.0-beta
**Last updated:** 2026-06-30

---

## All specs

| Spec | Status | What it covers |
|------|--------|---------------|
| [`persistent-erl-runtime`](./1_0_0_beta.persistent-erl-runtime.md) | ✅ completed | Replace wasm3 with persistent erl subprocess (the foundation) |
| [`erl-comptime-speed`](./1_0_0_beta.erl-comptime-speed.md) | ✅ completed | BEAM cache, binary protocol, template/decorator erl path, remove Node.js |
| [`erl-comptime-gaps`](./1_0_0_beta.erl-comptime-gaps.md) | 🔴 in progress | 6 remaining gaps from erl-comptime-speed (decompiler, decorators, test failures) |
| [`comptime-type-introspection`](./1_0_0_beta.comptime-type-introspection.md) | 🟡 in progress | 5 builtins registered (inference-time); value eval + std functions pending |
| [`comptime-eval-and-types`](./1_0_0_beta.comptime-eval-and-types.md) | ⚪ planning | Granular decomposition of comptime eval (overlaps with comptime-type-introspection Steps 3-7) |
| [`state-narrowing`](./1_0_0_beta.state-narrowing.md) | 🟡 in progress | Audit + test matrix done; parser + inference engine pending |
| [`codegen-test-gap`](./1_0_0_beta.codegen-test-gap.md) | 🟡 in progress | Audit done; runtime crash fixes + 37 new tests pending |
| ~~`atomvm-runtime`~~ | ❌ cancelled | Replaced by persistent-erl-runtime. Spec removed. |

### Overlap notes

- **`comptime-type-introspection` Steps 3-7** ≈ **`comptime-eval-and-types` Steps 1-8**. The latter is more granular. Choose ONE to execute; reconcile the other.
- **`state-narrowing` Step 6** (codegen tests) defers to **`codegen-test-gap`** — not duplicated.
- **`erl-comptime-gaps`** documents the delta between what `erl-comptime-speed` promised and what was actually delivered.

## Dependency graph

```
persistent-erl-runtime ✅
  └──► erl-comptime-speed ✅
         └──► erl-comptime-gaps 🔴 (CRITICAL BLOCKER)
                ├──► comptime-type-introspection (Steps 3-7) 🟡
                │      └──► OR comptime-eval-and-types ⚪
                │
                ├──► state-narrowing (Steps 5-6) 🟡
                │
                └──► codegen-test-gap (Steps 6, 9) 🟡

codegen-test-gap Step 2 (crash fixes) 🟡
  └──► codegen-test-gap Steps 4-11 (new tests) 🟡

state-narrowing Step 3 (parser) 🟡
  └──► state-narrowing Step 4 (inference) 🟡
```

## Parallel work map

### Phase 1 — Unblock comptime eval (MUST DO FIRST)

```
┌──────────────────────────────────────┐
│ erl-comptime-gaps Step 1              │
│ Fix template body decompiler          │
│ (template_eval.zig: emitBpExpr)       │
└────────────┬─────────────────────────┘
             │ unblocks everything below ▼
    ┌────────┴───────────────────────┐
    │                                │
    ▼                                ▼
 comptime-type-introspection     state-narrowing
 Steps 3-7                       Steps 5-6
 (builtins eval + std fns)       (comptime + codegen tests)
    │
    └── OR use comptime-eval-and-types instead
```

### Phase 2 — Parallel work streams (after Phase 1)

| # | Stream | Spec + Step | Key files | Can run with |
|---|--------|-------------|-----------|-------------|
| A | Comptime builtins eval | comptime-type-introspection Step 3 | `comptime/eval.zig`, `comptime/infer.zig` | — |
| B | Comptime std functions | comptime-type-introspection Steps 4-5 | `libs/std/src/reflect.bp` | A |
| C | State narrowing parser | state-narrowing Step 3 | `parser/decls.zig` | — |
| D | State narrowing inference | state-narrowing Step 4 | `comptime/infer.zig`, `env.zig` | C, A ⚠️ |
| E | Erl decorator eval | erl-comptime-gaps Step 2 | `comptime/decorator_eval.zig` | — |
| F | Erl record layout fix | erl-comptime-gaps Step 3 | `comptime.zig` | — |
| G | Orphaned snapshots | codegen-test-gap Step 3 | `snapshots/codegen/**` | — |
| H | Codegen crash fixes | codegen-test-gap Step 2 | 4 backend files | — |
| I | Codegen new tests | codegen-test-gap Steps 4-11 | `codegen/tests/*.zig` | H |

> ⚠️ **Conflict:** Stream D (state-narrowing inference) and Stream A (comptime builtins eval) both touch `comptime/infer.zig`. Do sequentially or coordinate merge.

### Phase 3 — Polish

| Stream | Spec + Step |
|--------|-------------|
| Comptime builtin tests | comptime-type-introspection Steps 6-7 |
| State narrowing comptime tests | state-narrowing Steps 5-6 |
| Codegen template + comptime eval tests | codegen-test-gap Steps 6, 9 |
| Erl WAT RUN LOG | erl-comptime-gaps Step 5 |
| Erl benchmarks | erl-comptime-gaps Step 6 |
| Erl test failure cleanup | erl-comptime-gaps Step 4 (auto-resolved as gaps close) |

## Quick wins (no deps, low risk)

| # | Action | Spec | Time |
|---|--------|------|------|
| 1 | Delete 76 orphaned snapshot files | codegen-test-gap Step 3 | ~10 min |
| 2 | Fix `.len` → `.length` in JS codegen | codegen-test-gap Step 2 (commonJS) | ~30 min |
| 3 | Fix `if` without `else` in JS codegen | codegen-test-gap Step 2 (commonJS) | ~20 min |
| 4 | Skip WASM RUN LOG for `external_*` tests | codegen-test-gap Step 2 (WASM) | ~15 min |
| 5 | Fix record layout assumption | erl-comptime-gaps Step 3 | ~30 min |

## Task branch naming

```
spec/1_0_0_beta.<spec-name>-<step>
```

Examples: `spec/1_0_0_beta.erl-comptime-gaps-step1`, `spec/1_0_0_beta.codegen-test-gap-step2-node`

## Completed specs

| Spec | Notes |
|------|-------|
| `persistent-erl-runtime` | Persistent erl subprocess, stdin/stdout JSON-line protocol, BEAM codegen reuse, crash recovery, Node.js removed from comptime val path. 7 steps complete. |
| `erl-comptime-speed` | BEAM bytecode cache, binary framing protocol, template/decorator erl path (decompiler approach), `#[@Host]` lowering, persistent_node.zig removed. 8 steps complete. Remaining gaps tracked in `erl-comptime-gaps`. |
| ~~`atomvm-runtime`~~ | Cancelled — AtomVM approach abandoned in favor of persistent erl subprocess. Spec file removed. |

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Created — master index with dependency graph and parallel work map | ericfillipe |
| 2026-06-30 | Added persistent-erl-runtime, erl-comptime-speed, comptime-eval-and-types; marked overlaps | ericfillipe |
