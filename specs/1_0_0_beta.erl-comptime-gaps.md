# Erl comptime — remaining gaps

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe
**Blocks:** `comptime-type-introspection` (Step 3), `state-narrowing` (Steps 5-6)

---

## Status

**Current:** in progress — 6 gaps identified; none fixed yet

> This spec is the **critical blocker** for both `comptime-type-introspection` and `state-narrowing` because those specs need comptime evaluation to work, and comptime evaluation runs in the erl subprocess.

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Fix template body decompiler (Gap 1) | pending | |
| Step 2 | Fix decorator eval decompiler (Gap 2) | pending | |
| Step 3 | Fix record layout assumption in patchHostMethods (Gap 3) | pending | |
| Step 4 | Fix 36 test failures (Gap 4) | pending | |
| Step 5 | Restore WAT RUN LOG execution (Gap 5) | pending | |
| Step 6 | Add comptime eval latency benchmarks (Gap 6) | pending | |

## What was delivered (erl-comptime-speed spec)

- Persistent erl subprocess as sole comptime runtime
- BEAM bytecode cache
- Binary framing protocol
- AST-to-BP-source decompiler for template bodies
- `#[@Host]` lowering via post-processing of `template_runtime.erl`
- Node.js, wasm3, WAT, AtomVM — all removed

The infrastructure is solid. The gaps are in the **decompiler** (AST → BP source), not in the runtime.

---

## Step 1 — Fix template body decompiler (Gap 1)

**Status:** pending **Assignee:**
**Priority:** CRITICAL — blocks `comptime-type-introspection` Step 3 and `state-narrowing` Steps 5-6

`emitBpExpr` in `template_eval.zig` only handles:
- Literals (string, number, null)
- Simple identifiers
- Function calls (`.call.call`)
- Binary ops
- Return/throw

**Missing constructs (produce `"null"` in decompiled BP):**

| Missing | Used by | Impact |
|---------|---------|--------|
| `if/else` | mergeRecords conflict detection | Wrong merge result |
| `case`/`match` | Enum introspection, Result handling | Crash or wrong output |
| Loops (`loop`) | mergeRecords field join, pick, omit | Empty record types |
| `identAccess` (field access) | `info.Record.fields`, `f.name` | Null deref |
| `dotIdent` | `@typeInfo(T).Record` | Null deref |
| Pipeline `|>` | Std function chaining | Wrong output |
| String templates | Error messages, string building | Silent failure |

**Acceptance criteria:**
- [ ] `emitBpExpr` handles `If`, `Case`, `Loop`, `identAccess`, `dotIdent`, pipeline, string templates
- [ ] Template bodies using these constructs compile to correct BP source
- [ ] `zig build test` passes (template tests unblocked)

### Files to modify

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/template_eval.zig` | `emitBpExpr` — add missing Expr variants |
| `modules/compiler-core/src/comptime/tests/templates.zig` | Verify decompiler output |
| `modules/compiler-core/src/ast.zig` | Reference for ExprOf variants (§ExprOf) |

---

## Step 2 — Fix decorator eval decompiler (Gap 2)

**Status:** pending **Assignee:**
**Priority:** HIGH — 10 decorator test failures

`decorator_eval.zig:evaluateErl()` returns `error.EvalFailed`. Decorator bodies (annotations like `#[@result]`, `#[@Host]`) need a BP source decompiler — either share `emitBpExpr`/`emitBpStmt` from `template_eval.zig` or implement equivalents.

**Acceptance criteria:**
- [ ] Decorator bodies decompile to valid BP source
- [ ] `evaluateErl()` returns successful eval results
- [ ] 10 decorator test failures resolved
- [ ] `zig build test` passes

### Files to modify

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/decorator_eval.zig` | Implement `emitBpStmt`/`emitBpExpr` or import from template_eval.zig |
| `modules/compiler-core/src/comptime/tests/decorators.zig` | Verify decorator eval snapshots |

---

## Step 3 — Fix record layout assumption in patchHostMethods (Gap 3)

**Status:** pending **Assignee:**
**Priority:** MEDIUM — potential silent bug

`comptime.zig:patchHostMethods()` uses `element(2, Self)` to extract the descriptor from the Capture record, assuming tuple layout. If Erlang codegen changes record representation (maps vs tuples, field reordering), this breaks silently.

**Acceptance criteria:**
- [ ] Verify actual Erlang output for `template_runtime.bp` to confirm tuple layout
- [ ] Add test that validates descriptor extraction
- [ ] Or: refactor to use named field access instead of positional

### Files to modify

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime.zig` | `patchHostMethods` — verify or fix record access |

---

## Step 4 — Fix 36 test failures (Gap 4)

**Status:** pending **Assignee:**
**Priority:** HIGH — consequence of Gaps 1-3

| Category | Count | Root cause | Fixed by |
|----------|-------|------------|----------|
| Decorator eval | 10 | Gap 2 | Step 2 |
| Template eval (complex bodies) | 5 | Gap 1 | Step 1 |
| Codegen snapshots (RUN LOG empty) | 5 | wasm3 removed, executeWat returns "" | Step 5 |
| LSP sublanguage tests | 9 | Templates not executing on erl | Step 1 |
| Memory leak | 1 | Unrelated — needs separate investigation | — |
| Snapshot diffs | 6 | WAT → Erlang output change | Step 5 |

**Acceptance criteria:**
- [ ] 36 → 0 test failures
- [ ] `zig build test` passes with zero failures
- [ ] All snapshot files regenerated

---

## Step 5 — Restore WAT RUN LOG execution (Gap 5)

**Status:** pending **Assignee:**
**Priority:** LOW — cosmetic, WAT backend is intact

`codegen/runtime.zig:executeWat()` returns `""` because wasm3 was removed. WAT codegen snapshots show empty RUN LOG.

**Options:**
- A) Restore wasmtime-based WAT execution (requires wasmtime on PATH)
- B) Accept empty RUN LOGs as the new baseline

**Acceptance criteria:**
- [ ] Decision made: option A or B
- [ ] If A: `executeWat()` runs WAT through wasmtime and captures output
- [ ] If B: regenerate WAT snapshots with empty RUN LOG
- [ ] No test failures from WAT RUN LOG
- [ ] `zig build test` passes

### Files to modify (if option A)

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/codegen/runtime.zig` | `executeWat` — wasmtime integration |

---

## Step 6 — Add comptime eval latency benchmarks (Gap 6)

**Status:** pending **Assignee:**
**Priority:** NICE-TO-HAVE

The spec's latency targets (~0.3ms comptime val, ~1ms template body) were never measured. Infrastructure exists (BEAM cache, binary protocol, persistent process).

**Acceptance criteria:**
- [ ] Benchmark harness added under `modules/compiler-core/`
- [ ] Measures: `@typeInfo` eval time, template body decompile+eval time
- [ ] Results documented in this spec

---

## Summary

| Gap | Priority | Blocks | Parallel-safe |
|-----|----------|--------|---------------|
| 1 — Decompiler | **CRITICAL** | comptime-introspection, state-narrowing | No — blocks others |
| 2 — Decorator eval | HIGH | 10 test failures | Yes (after Step 1) |
| 3 — Record layout | MEDIUM | — | Yes |
| 4 — Test failures | HIGH | — | Resolved by Steps 1-3, 5 |
| 5 — WAT RUN LOG | LOW | 11 test failures | Yes |
| 6 — Benchmarks | NICE-TO-HAVE | — | Yes |

### Execution order

1. **Step 1 first** — unblocks everything that needs comptime eval
2. **Step 2** (decorator) can parallel with Step 1 if shared decompiler extracted first
3. **Steps 3, 5, 6** are independent — can run anytime
4. **Step 4** is a consequence — resolves as gaps are fixed

## Notes

- Alternative to fixing the decompiler: compile template bodies directly to Erlang via `erlang.zig` codegen, avoiding BP→AST→BP→Erlang round-trip. But requires `erlang.zig` to handle `#[@Host]` method lowering at the call site — more invasive change.
- The persistent erl process + BEAM cache + binary protocol are solid. Focus on the decompiler.

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created — 6 gaps from erl-comptime-speed | ericfillipe |
| 2026-06-30 | Rewritten: added structured steps, priority matrix, blocking deps, parallel-safe indicators | ericfillipe |
