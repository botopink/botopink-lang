# Codegen Test Coverage & Runtime Fixes

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe

---

## Status

**Current:** in progress — audit done; runtime crash fixes + new tests pending

> Step 1 (audit) complete. Steps 2-11 are all pending. This spec is the runtime verification gate — comptime tests verify types; codegen tests verify the whole pipeline produces correct output.

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Audit codegen coverage & runtime health | completed | ericfillipe |
| Step 2 | Fix runtime crashes (all backends) | pending | |
| Step 3 | Remove 76 orphaned snapshot files | pending | |
| Step 4 | Implement codegen tests for optional/null | pending | |
| Step 5 | Implement codegen tests for cross-module imports | pending | |
| Step 6 | Implement codegen tests for template/@Expr | pending | |
| Step 7 | Implement codegen tests for interface/implement | pending | |
| Step 8 | Implement codegen tests for generics | pending | |
| Step 9 | Implement codegen tests for comptime eval + specialization | pending | |
| Step 10 | Implement codegen tests for record/enum | pending | |
| Step 11 | Implement codegen tests for lambda, operators, annotations | pending | |

## Objective

Only ~10% of comptime-verified features have codegen runtime tests. 120
snapshots capture `@print` statements but have **empty RUN LOG** (runtime
crashed). 13 snapshots show `undefined` output from known codegen gaps. 191
parser features have zero codegen tests. This spec closes those gaps.

## Prerequisites

- `zig build test` passing
- Node.js, Erlang/OTP, wasmtime available for cross-backend verification
- [**BLOCKING for some tests**] `erl-comptime-gaps` — template/@Expr tests (Step 6) and comptime eval tests (Step 9) need the erl decompiler fixed

---

## Step 1 — Audit codegen coverage & runtime health

**Status:** completed **Assignee:** ericfillipe

### 1.1 — Snapshot inventory

| Category | Files | RUN LOG sections |
|----------|-------|-----------------|
| Has RUN LOG | 982 | 1,011 |
| Error snapshot (has ERROR) | 4 | 0 |
| No RUN LOG, no ERROR, non-empty | 4 | 0 |
| Orphaned empty files | 76 | 0 |
| **Total** | **1,066** | **1,011** |

### 1.2 — RUN LOG health per backend

| Backend | RUN LOGs | OK | LIMITATION (undefined) | Crash (empty) |
|---------|----------|-----|------------------------|---------------|
| node/commonJS | 254 | 246 | 8 | — |
| erlang/erlang | 253 | 251 | 2 | — |
| beam/beam | 252 | 248 | 4 | — |
| wasm/wasm | 252 | 252 | 0 | — |

**But:** 120 tests have `@print` in source yet empty RUN LOG — the runtime
crashed (non-zero exit). The snapshot matches empty output, so `zig build test`
passes, but the generated code doesn't actually work:

| Backend | Crashes | % of snapshots with @print |
|---------|---------|---------------------------|
| wasm/wasm | 48 | 19.0% |
| erlang/erlang | 38 | 15.0% |
| beam/beam | 21 | 8.3% |
| node/commonJS | 13 | 5.1% |
| **Total** | **120** | |

### 1.3 — Known codegen limitations (RUN LOG shows `undefined`)

| File | Backends affected | Root cause |
|------|-------------------|------------|
| `*_len_*` (6 files) | commonJS | `.len` mapped to JS `.len` instead of `.length` |
| `optional_fn_return_null_path` | commonJS, erlang, beam | Optional chaining on `null` with no default |
| `if_simple_conditional_in_fn_body` | commonJS, beam | `if` without `else` branch produces `undefined` |
| `anon_record_*` (2 files) | beam | Anonymous record literal not supported |

### 1.4 — Coverage gap by feature category

| Category | Comptime tests | Have codegen test | Gap | Priority |
|----------|---------------|-------------------|-----|----------|
| optional/null | 8 | 0 | 8 | **Critical** |
| template/@Expr | 11 | 0 | 11 | **Critical** |
| import/cross-module | 8 | 0 | 8 | **High** |
| interface/implement | 16 | 0 | 16 | **High** |
| generic types | 3 | 0 | 3 | **High** |
| decorators/annotations | 6 | 0 | 6 | **Medium** |
| comptime eval/specialization | 2 | 0 | 2 | **Medium** |
| enum variants | 11 | 1 | 10 | **Medium** |
| record/structs | 17 | 1 | 16 | **Medium** |
| result/try | 11 | 1 | 10 | **Medium** |
| case/pattern | 20 | 4 | 16 | **Medium** |
| operators | 30 | 2 | 28 | **Low** |
| literals/basic | 11 | 2 | 9 | **Low** |
| errors | 19 | 0 | 19 | N/A (error tests) |

---

## Step 2 — Fix runtime crashes (all backends)

**Status:** pending **Assignee:**

> **Parallelizable per backend.** Each backend's crashes are in different files. Node.js (13) and WASM (48) can be worked on simultaneously. Erlang (38) may need Step 1 of erl-comptime-gaps first.

### Cross-cutting (all backends)

1. **try/catch propagation** — `try_propagate_without_catch`, `try_with_inline_catch_handler`, `try_catch_returns_handler_value_on_error`, `try_catch_on_result_with_default_fallback`, `try_propagation_in_result_fn`. Result-unwrapping at runtime is broken.

### commonJS (13 crashes + 8 limitations) — `codegen/commonJS.zig`

2. **Fix `.len` → `.length`** — Resolves 6 `undefined` limitations. Map `.len` to native `length` property.
3. **`if` without `else`** — Emit ternary `cond ? value : undefined`.
4. **String methods dispatch** — Fix native method name mapping.
5. **Array operations** — `array_slice_2_arg`, `array_zip` — fix lowering.

### Erlang (38 crashes) — `codegen/erlang.zig`

6. **Template system** — All 6 `template_end_to_end_*` tests fail. May need erl-comptime-gaps Step 1.
7. **Pipeline operator** — `|>` lowering doesn't thread arguments correctly.
8. **Instance methods** — External Erlang functions not compiled into module.

### BEAM (21 crashes) — `codegen/beam_asm.zig`

9. **try/catch** — `@Result` unwrapping broken in BEAM try/catch blocks.
10. **Anonymous record literal** — Flagged as unsupported; implement or skip runtime execution.
11. **String `.len` in arithmetic** — Tagged integer from `.len` doesn't work in BEAM arithmetic.

### WASM (48 crashes) — `codegen/wat.zig` + `codegen/runtime.zig`

12. **External host functions** — 8 `external_*` tests crash. WASM can't import Node.js functions. **Fix:** skip RUN LOG for `external_*` on WASM (WAT lowering still verified by source snapshot).
13. **Template system** — 5 `template_end_to_end_*` tests crash.
14. **Iterator `yield`** — No coroutine/generator support in wasmtime.
15. **Case/switch on literals** — BR_TABLE or IF chains don't produce working code.
16. **Instance methods** — Call host functions not in wasmtime.
17. **Array builtins** — `Array.at`, `.indexOf`, `.join`, `.zip` call host functions not present.

### Acceptance criteria

- [ ] All 13 commonJS crashes/limitations fixed or documented as intentional
- [ ] All 38 Erlang crashes fixed or documented
- [ ] All 21 BEAM crashes fixed or documented
- [ ] All 48 WASM crashes fixed or documented (excluding intentional skips)
- [ ] `zig build test` passes
- [ ] Empty RUN LOGs replaced with actual output where fixes applied

---

## Step 3 — Remove 76 orphaned snapshot files

**Status:** pending **Assignee:**
**Parallel-safe:** Yes — independent of all other steps. Zero risk.

76 empty files across all 4 backends (19 per backend), unchanged since initial commit `0c30a38`. No current test references any of these names. The snapshot system (`snap.zig`) doesn't auto-delete unused files — remove them manually.

**Acceptance criteria:**
- [ ] All 76 orphaned files deleted from `snapshots/codegen/{node,erlang,beam,wasm}/`
- [ ] `zig build test` passes
- [ ] No empty directories left behind

---

## Step 4 — Implement codegen tests for optional/null

**Status:** pending **Assignee:**
**Parallel-safe:** Yes — independent test file. May need Step 2 (runtime fixes) for existing optional tests to pass first.

8 comptime tests exist. **Zero codegen tests.** 6 tests designed:
- `optional_if_null_check_print` — null-check binding with @print
- `optional_nested_null_check_record` — nested null-check with record field
- `optional_if_null_else_both_branches` — null-check with else branch
- `optional_explicit_type_annotation` — `?i32` annotation + safe divide
- `optional_string_annotation_default` — `?string` annotation + default
- `optional_chaining_on_optional_field` — `?.` chaining on optional field

**Acceptance criteria:**
- [ ] 6 optional/null codegen tests added to `codegen/tests/values.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output

---

## Step 5 — Implement codegen tests for cross-module imports

**Status:** pending **Assignee:**
**Parallel-safe:** Yes. Needs multi-file test support in temp dirs.

8 comptime tests exist. **Zero codegen tests.** 5 tests designed:
- Import single val, multiple vals, function, record constructor, 3-level import chain

**Acceptance criteria:**
- [ ] 5 cross-module import codegen tests added to `codegen/tests/features.zig`
- [ ] Each test creates multiple `.bp` files in a temp dir
- [ ] `zig build test` passes

---

## Step 6 — Implement codegen tests for template/@Expr

**Status:** pending **Assignee:**
**Depends on:** `erl-comptime-gaps` Step 1 (decompiler fix)

11 comptime tests exist. **Zero codegen tests.** 4 tests designed:
- `@Expr` pass-through, template with runtime hole, parts iteration, lookup+ref

**Acceptance criteria:**
- [ ] 4 template/@Expr codegen tests added to `codegen/tests/comptime.zig`
- [ ] Each test runs on all 4 backends
- [ ] RUN LOG captures correct output

---

## Step 7 — Implement codegen tests for interface/implement

**Status:** pending **Assignee:**
**Parallel-safe:** Yes.

16 comptime tests exist. **Zero codegen tests.** 4 tests designed:
- Method dispatch, interface with field, multiple abstract methods, two impls with qualified dispatch

**Acceptance criteria:**
- [ ] 4 interface/implement codegen tests added to `codegen/tests/aggregates.zig`
- [ ] Each test runs on all 4 backends

---

## Step 8 — Implement codegen tests for generics

**Status:** pending **Assignee:**
**Parallel-safe:** Yes.

3 comptime tests exist. **Zero codegen tests.** 3 tests designed:
- Generic record Pair, generic identity function, generic enum Option

**Acceptance criteria:**
- [ ] 3 generic type codegen tests added to `codegen/tests/values.zig`
- [ ] Each test runs on all 4 backends

---

## Step 9 — Implement codegen tests for comptime eval + specialization

**Status:** pending **Assignee:**
**Depends on:** `erl-comptime-gaps` Step 1

2 comptime tests exist. **Zero codegen tests.** 3 tests designed:
- Comptime block yields constant, comptime params with specialization, type-meta specialization

**Acceptance criteria:**
- [ ] 3 comptime eval codegen tests added to `codegen/tests/features.zig`
- [ ] Each test runs on all 4 backends

---

## Step 10 — Implement codegen tests for record/enum

**Status:** pending **Assignee:**
**Parallel-safe:** Yes.

17 record + 11 enum comptime tests (1 codegen each). 6 tests designed:
- Record constructor with field access, record method using self, enum constructor with case, enum payload variant, enum sections with nested variants, record field update (immutable)

**Acceptance criteria:**
- [ ] 6 record/enum codegen tests added to `codegen/tests/aggregates.zig`
- [ ] Each test runs on all 4 backends

---

## Step 11 — Implement codegen tests for lambda, operators, annotations

**Status:** pending **Assignee:**
**Parallel-safe:** Yes.

Quick-win tests: lambda as map argument, operator precedence, string interpolation edge cases.

**Acceptance criteria:**
- [ ] 3 additional codegen tests added
- [ ] Each test runs on all 4 backends

---

## Summary

| Metric | Count |
|--------|-------|
| Codegen tests designed in this spec | 37 |
| Runtime crashes to fix | 120 (across 4 backends) |
| Known limitations to fix (`undefined` output) | 13 |
| Orphaned files to remove | 76 |
| Current comptime→codegen coverage | ~10% |
| Target coverage after this spec | ~25% |

### Key findings

1. **Only ~10% of comptime-verified features have codegen runtime tests.**

2. **120 snapshots have `@print` but empty RUN LOG** — the runtime crashed. WASM is worst (48), Node.js best (13).

3. **Optional/null, templates, imports, and interface/implement have zero codegen tests.**

4. **Node.js is the most resilient backend** — 13 crashes vs 21 (BEAM), 38 (Erlang), 48 (WASM).

5. **191 parser features (91.8%) have zero codegen tests.**

### Execution order

1. **Step 3 first** — zero risk, cleans the tree, can run anytime
2. **Step 2** — fix existing crashes. Per-backend sub-steps can run in parallel (different files)
3. **Steps 4-11** — additive, no regression risk. Can all run in parallel once Step 2 is done
4. Steps 6 and 9 need `erl-comptime-gaps` Step 1 first

### Parallel work map

```
Step 3 (orphans) ─────────────────────►
Step 2 (crashes) ──┬─ commonJS ────────►
                    ├─ Erlang ──────────►
                    ├─ BEAM ────────────►
                    └─ WASM ────────────►
                         │
Steps 4-11 (new tests) ◄─┘ (after crash fixes)
  ├─ Step 4 (optional)
  ├─ Step 5 (imports)
  ├─ Step 7 (interfaces)
  ├─ Step 8 (generics)
  ├─ Step 10 (records/enums)
  ├─ Step 11 (lambdas/ops)
  ├─ Step 6 (templates) ─── needs erl-comptime-gaps
  └─ Step 9 (comptime eval) ─ needs erl-comptime-gaps
```

## Notes

- Error-diagnostic comptime tests intentionally have no codegen test — codegen is never reached for invalid programs.
- RUN LOG capture drops stderr for host-independence.
- WASM `external_*` tests should skip RUN LOG capture (WAT lowering verified by source snapshot).
- State-narrowing codegen tests (8 tests) live in [`1_0_0_beta.state-narrowing.md`](./1_0_0_beta.state-narrowing.md) Step 6 — not duplicated here.

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created — merged run-log-audit + comptime-codegen-coverage | ericfillipe |
| 2026-06-30 | Step 1 (audit) completed | ericfillipe |
| 2026-06-30 | Rewritten: added parallel work map, per-backend crash details, dependency annotations, removed state-narrowing codegen test duplication (deferred to its own spec) | ericfillipe |
