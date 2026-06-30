# Wave 1 — Foundation: Erl Runtime + Codegen Fixes

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe
**Blocks:** Wave 2 (`02-typesystem.md`)

---

## Status

**Current:** in progress — 6 gaps identified; none fixed yet

> The persistent erl infrastructure is solid. All gaps are in the **decompiler** (AST → BP source) that feeds template/decorator bodies to the erl runtime. Fixing this unblocks comptime eval for everything else.

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Fix template body decompiler | pending | |
| Step 2 | Fix decorator eval | pending | |
| Step 3 | Fix record layout assumption | pending | |
| Step 4 | Fix test failures + regenerate snapshots | pending | |
| Step 5 | Restore WAT RUN LOG execution | pending | |
| Step 6 | Add erl runtime regression tests | pending | |
| Step 7 | Comptime type evaluation & first-class types tests | pending | |
| Step 8 | Fix codegen runtime crashes (all 4 backends) | pending | |
| Step 8a | Add 2-minute timeout to all runtime executions | pending | |
| Step 9 | Remove 76 orphaned snapshot files | pending | |
| Step 10 | New codegen tests: optional, imports, records, enums, generics, interfaces, lambdas, operators | pending | |
| Step 11 | New codegen tests: template/@Expr + comptime eval | pending | |
| Step 12 | Regenerate snapshots, verify full suite | pending | |

## Context

After `persistent-erl-runtime` and `erl-comptime-speed` (both completed), the persistent erl subprocess handles all comptime. But the decompiler (`template_eval.zig:emitBpExpr`) only handles basic constructs — complex template bodies produce `"null"`, decorator eval returns `error.EvalFailed`, and 36 tests fail.

**What was delivered (by prior specs):**
- Persistent erl subprocess as sole comptime runtime
- BEAM bytecode cache
- Binary framing protocol
- `#[@Host]` lowering via post-processing of `template_runtime.erl`
- Node.js, wasm3, WAT, AtomVM — all removed

---

## Step 1 — Fix template body decompiler

**Status:** pending **Assignee:**
**Priority:** CRITICAL — blocks Wave 2 + Wave 3

`emitBpExpr` in `template_eval.zig` only handles: literals, simple identifiers, function calls, binary ops, return/throw.

**Missing constructs (all produce `"null"` in decompiled BP):**

| Missing | Used by | Impact |
|---------|---------|--------|
| `if/else` | mergeRecords conflict detection | Wrong merge result |
| `case`/`match` | Enum introspection, Result handling | Crash or wrong output |
| `loop` | mergeRecords field join, pick, omit | Empty record types |
| `identAccess` (field access) | `info.Record.fields`, `f.name` | Null deref |
| `dotIdent` | `@typeInfo(T).Record` | Null deref |
| Pipeline `|>` | Std function chaining | Wrong output |
| String templates | Error messages, string building | Silent failure |

**Acceptance criteria:**
- [ ] `emitBpExpr` handles `If`, `Case`, `Loop`, `identAccess`, `dotIdent`, pipeline, string templates
- [ ] Template bodies using these constructs compile to correct BP source
- [ ] `zig build test` passes (template tests unblocked)

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/template_eval.zig` | `emitBpExpr` — add missing Expr variants |
| `modules/compiler-core/src/comptime/tests/templates.zig` | Verify decompiler output |
| `modules/compiler-core/src/ast.zig` | Reference for ExprOf variants |

---

## Step 2 — Fix decorator eval

**Status:** pending **Assignee:**
**Priority:** HIGH — 10 decorator test failures

`decorator_eval.zig:evaluateErl()` returns `error.EvalFailed`. Decorator bodies need a BP source decompiler. Share `emitBpExpr`/`emitBpStmt` from `template_eval.zig` or implement equivalents.

**Acceptance criteria:**
- [ ] Decorator bodies decompile to valid BP source
- [ ] `evaluateErl()` returns successful eval results
- [ ] 10 decorator test failures resolved
- [ ] `zig build test` passes

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/decorator_eval.zig` | Implement or import decompiler |
| `modules/compiler-core/src/comptime/tests/decorators.zig` | Verify decorator eval snapshots |

---

## Step 3 — Fix record layout assumption in patchHostMethods

**Status:** pending **Assignee:**
**Priority:** MEDIUM — potential silent bug

`comptime.zig:patchHostMethods()` uses `element(2, Self)` to extract the descriptor from the Capture record, assuming tuple layout at position 2. If Erlang codegen changes record representation (maps vs tuples, field reordering), this breaks silently.

**Acceptance criteria:**
- [ ] Verify actual Erlang output for `template_runtime.bp` to confirm tuple layout
- [ ] Add test that validates descriptor extraction
- [ ] Or: refactor to use named field access instead of positional

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime.zig` | `patchHostMethods` — verify or fix record access |

---

## Step 4 — Fix test failures + regenerate snapshots

**Status:** pending **Assignee:**
**Priority:** HIGH — consequence of Steps 1-3

| Category | Count | Root cause | Fixed by |
|----------|-------|------------|----------|
| Decorator eval | 10 | Step 2 | Step 2 |
| Template eval (complex bodies) | 5 | Step 1 | Step 1 |
| Codegen snapshots (RUN LOG empty) | 5 | wasm3 removed | Step 5 |
| LSP sublanguage tests | 9 | Templates not executing on erl | Step 1 |
| Memory leak | 1 | Unrelated — separate investigation | — |
| Snapshot diffs | 6 | WAT → Erlang output change | Step 5 |
| **Total** | **36** | | |

**Acceptance criteria:**
- [ ] 36 → 0 test failures
- [ ] `zig build test` passes with zero failures
- [ ] All snapshot files regenerated

---

## Step 5 — Restore WAT RUN LOG execution

**Status:** pending **Assignee:**
**Priority:** LOW — WAT backend is intact, only execution is gone

`codegen/runtime.zig:executeWat()` returns `""` because wasm3 was removed. Options:
- **A)** Restore wasmtime-based WAT execution (needs wasmtime on PATH)
- **B)** Accept empty RUN LOGs as new baseline

**Acceptance criteria:**
- [ ] Decision: option A or B
- [ ] If A: `executeWat()` runs WAT through wasmtime
- [ ] If B: regenerate WAT snapshots with empty RUN LOG
- [ ] No test failures from WAT RUN LOG

### Files (if option A)

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/codegen/runtime.zig` | `executeWat` — wasmtime integration |

---

## Step 6 — Add erl runtime regression tests

**Status:** pending **Assignee:**
**Priority:** HIGH — prevents regressions in the fixed gaps

Once the decompiler and decorator eval are fixed (Steps 1-2), add targeted regression tests so these gaps don't re-emerge silently.

### 6.1 — Decompiler round-trip tests

For each fixed `emitBpExpr` construct, add a test that:
1. Parses a `.bp` snippet using that construct
2. Decompiles the AST back to BP source via `emitBpExpr`
3. Re-parses the decompiled output
4. Verifies AST equality (round-trip stable)

Constructs to cover: `if/else`, `case`, `loop`, `identAccess`, `dotIdent`, pipeline, string templates, `break`, `return`.

### 6.2 — Persistent erl health tests

- **Warmup test:** spawn erl, ping, verify `pong` response
- **Crash recovery test:** kill erl mid-eval, verify next `eval()` respawns and succeeds
- **BEAM cache test:** identical comptime entries → cache hit (verify no recompile)
- **Binary protocol test:** length-prefixed frames round-trip correctly with edge cases (empty payload, max-size payload, UTF-8)

### 6.3 — Decorator eval tests

- Each decorator annotation type (`#[@result]`, `#[@Host]`, custom decorators) tested end-to-end
- Verify decorator bodies that use complex constructs (loops, conditionals) produce correct results

### 6.4 — Error surface tests

- Template body with invalid BP → erl returns clear error, not silent `"null"`
- Decorator body that throws → error surfaced as compiler diagnostic, not swallowed
- erl subprocess killed mid-eval → diagnostic message, not segfault

**Acceptance criteria:**
- [ ] ≥10 decompiler round-trip tests in `comptime/tests/templates.zig`
- [ ] ≥4 persistent erl health tests
- [ ] ≥3 decorator eval end-to-end tests
- [ ] ≥3 error surface tests
- [ ] `zig build test` passes
- [ ] Tests fail meaningfully if decompiler regresses (not just empty RUN LOG)

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/tests/templates.zig` | Decompiler round-trip tests |
| `modules/compiler-core/src/comptime/runtime/persistent_erl.zig` | May need test hooks (health check exposed) |
| `modules/compiler-core/src/comptime/tests/decorators.zig` | Decorator eval end-to-end tests |

---

## Step 7 — Comptime type evaluation & first-class types tests

**Status:** pending **Assignee:**
**Priority:** HIGH — validates the foundation for Wave 2 type introspection work

Once the erl runtime can execute comptime code (Steps 1-2), verify that the type system primitives work end-to-end. These tests prove the erl runtime + builtins + type infrastructure chain is solid before Wave 2 builds on it.

### 7.1 — `type` as first-class comptime value

```botopink
// slug: type_first_class_val_binding
val T = i32;
val x: T = 42;
@print(x);                         // RUN LOG: 42

// slug: type_first_class_fn_param
fn makePair(comptime A: type, comptime B: type) -> type {
    break record { first: A, second: B };
}
val IntString = makePair(i32, string);
// IntString is: record { first: i32, second: string }

// slug: type_first_class_fn_return
fn wrap(comptime T: type) -> type {
    break record { value: T };
}
val WrappedBool = wrap(bool);
val w: WrappedBool = WrappedBool(value: true);
@print(w.value);                   // RUN LOG: true
```

### 7.2 — `@typeInfo(T)` value evaluation

```botopink
// slug: typeinfo_primitive_types
@typeInfo(i32);      // TypeInfo.Int
@typeInfo(f64);      // TypeInfo.Float
@typeInfo(bool);     // TypeInfo.Bool
@typeInfo(string);   // TypeInfo.String

// slug: typeinfo_record_type
record Point { x: i32, y: i32 }
val info = @typeInfo(Point);
// info = TypeInfo.Record(fields: [RecordField("x", i32), RecordField("y", i32)])

// slug: typeinfo_enum_type
enum Color { Red, Green, Blue }
val info = @typeInfo(Color);
// info = TypeInfo.Enum(variants: [EnumVariant("Red", []), ...])

// slug: typeinfo_optional_type
val info = @typeInfo(?string);
// info = TypeInfo.Optional(inner: string)

// slug: typeinfo_array_type
val info = @typeInfo(i32[]);
// info = TypeInfo.Array(element: i32)
```

### 7.3 — `@TypeOf(v)` returning concrete type

```botopink
// slug: typeof_primitive
val n: i32 = 42;
val T = @TypeOf(n);    // T = i32

// slug: typeof_record
val p = Point(x: 1, y: 2);
val T = @TypeOf(p);    // T = Point

// slug: typeof_fn_return
fn getNum() -> i32 { return 10; }
val T = @TypeOf(getNum());  // T = i32
```

### 7.4 — `@makeRecord(fields)` creating concrete types

```botopink
// slug: makerecord_simple
val fields = [RecordField("name", string), RecordField("age", i32)];
val Person = @makeRecord(fields);
val p: Person = Person(name: "alice", age: 30);
@print(p.name);    // RUN LOG: alice

// slug: makerecord_empty
val Empty = @makeRecord([]);
val e = Empty();
// Round-trip: @typeInfo(Empty).Record.fields.len == 0
```

### 7.5 — Comptime loop over type fields

```botopink
// slug: comptime_loop_over_record_fields
record Config { port: i32, host: string, debug: bool }
val info = @typeInfo(Config);
var names: string[] = [];
loop (info.Record.fields) { f ->
    names = names.push(f.name);
};
// names = ["port", "host", "debug"]
```

### 7.6 — `@comptimeError` builtin

```botopink
// slug: comptime_error_basic
fn requirePositive(comptime n: i32) {
    if (n <= 0) { @comptimeError("must be positive, got " + n); };
}
// requirePositive(-1) → ERROR: must be positive, got -1

// slug: comptime_error_in_type_context
fn safeRecord(comptime T: type) -> type {
    val info = @typeInfo(T);
    if (info is TypeInfo.Record) { break T; };
    @comptimeError("expected record type, got " + @TypeOf(T));
}
// safeRecord(i32) → ERROR: expected record type, got i32
```

**Acceptance criteria:**
- [ ] ≥12 comptime type eval tests in `comptime/tests/builtins_typeinfo.zig`
- [ ] `type` usable as value, param, return type — all with @print validation
- [ ] 3 core builtins compute correct values at comptime (not just types)
- [ ] `@makeRecord` produces types that can be instantiated and printed
- [ ] `@comptimeError` surfaces clear error messages
- [ ] Comptime loops over record fields work (via @typeInfo, not @RecordKeys)
- [ ] `zig build test` passes
- [ ] Tests run on erl runtime (prove decompiler + eval chain works)
- [ ] `@RecordKeys`/`@Field` NOT tested as builtins — they're std functions (Wave 2 Step 4)

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/tests/builtins_typeinfo.zig` | All type eval tests |
| `modules/compiler-core/src/comptime/eval.zig` | Builtins value evaluation |
| `modules/compiler-core/src/comptime/infer.zig` | Wire eval into inference |

---

## Part B — Codegen Hardening (Steps 8-12)

### Context

Only ~10% of comptime-verified features have codegen runtime tests. 120 snapshots have `@print` but empty RUN LOG (runtime crashed). 13 show `undefined` from known gaps. 191 parser features (91.8%) have zero codegen tests.

**Audit summary (done):**

| Backend | OK | Limitations | Crashes |
|---------|-----|-------------|---------|
| node/commonJS | 246 | 8 | 13 |
| erlang/erlang | 251 | 2 | 38 |
| beam/beam | 248 | 4 | 21 |
| wasm/wasm | 252 | 0 | 48 |

**Coverage gaps:**

| Category | Comptime | Codegen | Gap |
|----------|----------|---------|-----|
| optional/null | 8 | 0 | 8 |
| template/@Expr | 11 | 0 | 11 |
| import/cross-module | 8 | 0 | 8 |
| interface/implement | 16 | 0 | 16 |
| generic types | 3 | 0 | 3 |
| record/enum | 28 | 2 | 26 |

---

## Step 8 — Fix codegen runtime crashes (all backends)

**Status:** pending **Assignee:**
**Parallel per backend** — different files.

### commonJS (13 crashes + 8 limitations) — `codegen/commonJS.zig`

1. **Fix `.len` → `.length`** — Resolves 6 `undefined` limitations
2. **`if` without `else`** — Emit ternary `cond ? value : undefined`
3. **String methods + Array operations** — Fix method name mapping + lowering
4. **try/catch propagation** — Result-unwrapping at runtime

### Erlang (38 crashes) — `codegen/erlang.zig`

5. **Template system** — 6 `template_end_to_end_*` tests (needs Step 1 decompiler)
6. **Pipeline operator** — `|>` lowering doesn't thread args correctly
7. **Instance methods** — External functions not compiled into module

### BEAM (21 crashes) — `codegen/beam_asm.zig`

8. **try/catch** — `@Result` unwrapping broken in BEAM blocks
9. **Anonymous record literal** — Implement or skip runtime execution
10. **String `.len` in arithmetic** — Tagged integer doesn't work in BEAM ops

### WASM (48 crashes) — `codegen/wat.zig` + `codegen/runtime.zig`

11. **External host functions** — Skip RUN LOG for `external_*` on WASM
12. **Template system + Iterators** — Skip or document as unsupported in wasmtime
13. **Case/switch on literals** — BR_TABLE doesn't produce working code
14. **Instance methods + Array builtins** — Host functions not in wasmtime → skip

**Acceptance criteria:**
- [ ] All commonJS/Erlang/BEAM/WASM crashes fixed or documented as intentional skips
- [ ] `zig build test` passes
- [ ] Empty RUN LOGs replaced with actual output where fixes applied

---

## Step 8a — Add 2-minute timeout to all runtime executions

**Status:** pending **Assignee:**
**Priority:** HIGH — hanging tests block the entire suite

Some spawned processes (`node`, `erl`, `erlc`, `wasmtime`) never terminate, causing `zig build test` to hang indefinitely. `std.process.run` blocks until the child exits — no built-in timeout.

### Fix: Replace `std.process.run` with `std.process.Child` + deadline

Create a helper `runWithTimeout` in `runtime.zig`:

```zig
/// Spawns a child process, captures stdout, kills it after `timeout_ms`.
/// Returns empty string on timeout or non-zero exit.
fn runWithTimeout(allocator, io, argv, timeout_ms) ![]u8
```

Implementation approach:
1. Use `std.process.Child.init(argv, allocator)` instead of `std.process.run`
2. Set `stdin_behavior = .Ignore`, `stdout_behavior = .Pipe`, `stderr_behavior = .Pipe`
3. Spawn the child via `child.spawn()`
4. Use a separate thread (`std.Thread.spawn`) that sleeps `timeout_ms` then calls `child.kill()`
5. Collect stdout from the pipe before the deadline
6. On timeout: return empty string (RUN LOG stays empty)
7. Always clean up: `child.deinit()` + join the watchdog thread

**Affected functions in `runtime.zig`:**

| Function | Current | Spawns |
|----------|---------|--------|
| `executeJavaScript` | `std.process.run` (×2) | `node` |
| `executeErlang` | `std.process.run` (×3) | `erlc`, `erl` |
| `executeBeamAsm` | `std.process.run` (×3) | `erlc`, `erl` |
| `executeWat` | stub (wasm3 removed) | — |

**Timeout value:** 120_000 ms (2 minutes) — generous enough for cold `erlc` + `erl` (~2s worst case), short enough that a hung suite doesn't waste CI minutes.

```zig
const RUNTIME_TIMEOUT_MS = 120_000; // 2 minutes
```

### Edge cases

- **Slow CI:** first `erlc` invocation may load BEAM compiler from disk (cold cache). 2 min covers this.
- **Persistent processes:** `node`/`erl` in comptime path are persistent (spawned once). This timeout is for **codegen snapshot execution** only — one-shot spawns.
- **WASM:** `executeWat` currently returns `""` (wasm3 removed). If wasmtime is restored (Step 5), add the same timeout wrapper.

**Acceptance criteria:**
- [ ] All `std.process.run` calls in `runtime.zig` replaced with timeout-gated spawns
- [ ] Hanging processes killed after 2 minutes (test continues, RUN LOG empty)
- [ ] `zig build test` never hangs — every test completes or times out
- [ ] Timeout produces a clear log message: `[TIMEOUT] <cmd> killed after 120s`
- [ ] Normal execution unaffected — fast spawns complete before timeout
- [ ] Cache hits still short-circuit (no spawn at all)

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/codegen/runtime.zig` | Add `runWithTimeout`, replace all `std.process.run` calls |
| `modules/compiler-core/src/codegen/tests/runtime_scratch.zig` | Add timeout test (spawn `sleep 999 && echo done`, verify killed) |

---

## Step 9 — Remove 76 orphaned snapshot files

**Status:** pending **Assignee:**
**Parallel-safe:** Yes — zero risk, independent of everything.

76 empty files (19 per backend) unchanged since `0c30a38`. No test references them.

**Acceptance criteria:**
- [ ] 76 orphaned files deleted from `snapshots/codegen/{node,erlang,beam,wasm}/`
- [ ] `zig build test` passes
- [ ] No empty directories left behind

---

## Step 10 — New codegen tests: optional, imports, records, enums, generics, interfaces, lambdas, operators

**Status:** pending **Assignee:**
**Parallel-safe per category.** Depends on Step 8 (crash fixes for existing tests).

27 tests across 6 categories, all backends:

| Category | Tests | Target file |
|----------|-------|-------------|
| Optional/null | 6 | `codegen/tests/values.zig` |
| Cross-module imports | 5 | `codegen/tests/features.zig` |
| Interface/implement | 4 | `codegen/tests/aggregates.zig` |
| Record/enum | 6 | `codegen/tests/aggregates.zig` |
| Generics | 3 | `codegen/tests/values.zig` |
| Lambda, operators, annotations | 3 | `codegen/tests/features.zig` |

Test designs in the original `codegen-test-gap` audit.

**Acceptance criteria:**
- [ ] 27 codegen tests added
- [ ] Each test runs on all 4 backends (with documented skips)
- [ ] RUN LOG captures correct output
- [ ] `zig build test` passes

---

## Step 11 — New codegen tests: template/@Expr + comptime eval

**Status:** pending **Assignee:**
**Depends on:** Step 1 (decompiler fix)

7 tests: 4 template/@Expr + 3 comptime eval.

```botopink
// slug: template_expr_hole_with_runtime_value
pub fn greet(comptime q: @Expr<string>) -> @Expr<string> { return q; }
fn main() {
    val name = "botopink";
    val msg = greet "hello ${name}!";
    @print(msg);
}
// RUN LOG: hello botopink!
```

**Acceptance criteria:**
- [ ] 7 tests added, all 4 backends
- [ ] `zig build test` passes

---

## Step 12 — Regenerate snapshots, verify full suite

**Status:** pending **Assignee:**

```bash
zig build test && zig build test-libs && zig build test-backends
```

**Acceptance criteria:**
- [ ] Full test suite passes
- [ ] ≥34 new codegen tests with correct RUN LOG
- [ ] ≥120 previously-crashed tests fixed or documented
- [ ] All snapshot files regenerated

---

## Execution order

### Phase A — Erl runtime (Steps 1-7)

1. **Step 1 first** — unblocks everything that needs comptime eval
2. **Step 2** — decorator eval, can share Step 1's decompiler
3. **Steps 3, 5** are independent — can run anytime
4. **Step 6** runs after Steps 1-2 — regression tests
5. **Step 7** runs after Steps 1-2 — validates builtins chain
6. **Step 4** resolves naturally as gaps close

### Phase B — Codegen (Steps 8-12, parallel with Phase A)

1. **Step 9** first (orphans) — zero risk, independent
2. **Step 8** per backend — commonJS/WASM independent of erl steps; Erlang/BEAM may need Step 1
3. **Steps 10-11** after Step 8 — new tests
4. **Step 12** final sweep

**Quick wins (no deps, under 30 min):**

| # | Action | Step | Time |
|---|--------|------|------|
| 1 | Delete 76 orphaned snapshots | 9 | ~10 min |
| 2 | Fix `.len` → `.length` in JS | 8 | ~30 min |
| 3 | Fix `if` without `else` in JS | 8 | ~20 min |
| 4 | Skip WASM RUN LOG for external tests | 8 | ~15 min |
| 5 | Fix record layout assumption | 3 | ~30 min |

## Summary

| Step | Priority | Blocks | Parallel-safe |
|------|----------|--------|---------------|
| 1 — Decompiler | **CRITICAL** | Waves 2 | No |
| 2 — Decorator eval | HIGH | — | After Step 1 |
| 3 — Record layout | MEDIUM | — | Yes |
| 4 — Test failures | HIGH | — | After Steps 1-3, 5 |
| 5 — WAT RUN LOG | LOW | — | Yes |
| 6 — Erl regression tests | HIGH | — | After Steps 1-2 |
| 7 — Type eval tests | HIGH | Wave 2 | After Steps 1-2 |
| 8 — Codegen crash fixes | HIGH | Steps 10-11 | Yes (per backend) |
| 9 — Orphaned snapshots | LOW | — | Yes |
| 10 — New codegen tests | HIGH | — | After Step 8 |
| 11 — Template codegen tests | HIGH | — | After Steps 1 + 8 |
| 12 — Final sweep | HIGH | — | After all |

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Created from erl-comptime-gaps consolidation | ericfillipe |
| 2026-06-30 | Added Step 6: erl runtime regression tests (decompiler round-trip, persistent erl health, decorator e2e, error surface) | ericfillipe |
| 2026-06-30 | Updated Step 7: `@RecordKeys`/`@Field` removed from builtins — they're std functions in Wave 2 Step 4; only 3 core builtins tested (@typeInfo, @TypeOf, @makeRecord) | ericfillipe |
