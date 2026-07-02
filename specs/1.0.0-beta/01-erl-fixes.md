# Wave 1 — Foundation: Erl Runtime + Codegen Fixes

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe
**Blocks:** Wave 2 (`02-typesystem.md`)

---

## Status

**Current:** in progress — Steps 1, 2, 3, 5.1, 5.2, 5.3, 5.4, 5.5, 8a, 9 completed; comptime hang fixed

> The decompiler (`emitBpExpr`) was already complete for all listed constructs. The real gaps were: (a) `renderExprValue` in `beam.zig` missing expression kinds, (b) `evaluateErl` in `decorator_eval.zig` stubbed out, (c) record layout assumption in `patchHostMethods`, and (d) missing `fail`/`failAt`/`build` in `erl_prelude` + `patchHostMethods`.

| Step | Title | Status | Tests | Assignee |
|------|-------|--------|-------|----------|
| Step 1 | Fix template body decompiler | **completed** | already handled all constructs | |
| Step 2 | Fix decorator eval | **completed** | shares decompiler from template_eval | |
| Step 3 | Fix record layout assumption | **completed** | maps:get(descriptor, Self) | |
| Step 4 | Fix test failures + regenerate snapshots | **in progress** | 9 language-server + allocation leaks | |
| Step 5.1 | Extend renderExprValue (fnCall, identAccess, etc.) | **completed** | 8 expr | |
| Step 5.2 | Complete patchHostMethods (fail/failAt/build) | **completed** | 2 host | |
| Step 5.3 | Add fail/failAt to erl prelude | **completed** | 2 prelude | |
| Step 5.4 | Handle return in comptime blocks | **completed** | — | |
| Step 5.5 | Eval pipeline integration test | **completed** | 1 integration | |
| Step 6 | Add erl runtime regression tests | pending | 10 decompiler + 4 health + 3 decorator e2e + 3 error | |
| Step 7 | Comptime type evaluation & first-class types tests | pending | ≥12 type eval | |
| Step 8 | Fix codegen runtime crashes (all 4 backends) | pending | 14 per-backend snapshot | |
| Step 8a | Add 2-minute timeout to all runtime executions | **completed** | runtime.zig + persistent_erl.zig | |
| Step 8b | Fix persistent erl `read_frame` OTP 27 compat | **completed** | persistent_erl.zig | |
| Step 9 | Remove 110 orphaned snapshot files | **completed** | snapshot count | |
| Step 10 | New codegen tests: optional, imports, records, etc. | pending | 27 new (4 backends) | |
| Step 11 | New codegen tests: template/@Expr + comptime eval | pending | 7 new (4 backends) | |
| Step 12 | Restore WAT RUN LOG execution | pending | snapshot verify | |
| Step 13 | Regenerate snapshots, verify full suite | pending | full suite gate | |

### ✅ Fixed: comptime val + specialization hang

Test `codegen.tests.comptime.test.js: comptime specialization ---- comptime val used as specialization argument` no longer hangs.

**Root cause:** OTP 27's `file:read(standard_io, N)` returns `{ok, [Byte, ...]}` (a list of integers) instead of `{ok, <<...>>}` (a binary). The `read_frame/0` function in `botopink_comptime_server.erl` used binary pattern matching (`<<Len:32/unsigned-big-integer>>`) which failed silently, falling through to `_ -> eof`. The server never read the frame, never responded, and `readFrame` in Zig blocked forever on the pipe read.

**Fix (Step 8b):** Updated `read_frame/0` in `persistent_erl.zig` to convert list returns to binary before pattern matching:
```erlang
{ok, RawLen} ->
    LenBin = if is_binary(RawLen) -> RawLen; true -> list_to_binary(RawLen) end,
    <<Len:32/unsigned-big-integer>> = LenBin,
```

### ⚠️ Remaining failures (Step 4 — in progress)

**Test results:** 155 pass, 9 fail (164 total)

**Language-server failures (9 tests):**
All 9 failures are in `modules/language-server/src/tests/` and reproduce on the main repo (pre-existing):

| Test | File | Error |
|------|------|-------|
| completion: decorator-bearing record still lists bindings (R2) | completion.zig:751 | `items.len > 0` fails |
| sublanguage: custom AST is retrievable after compile | sublanguage.zig:60 | expected 1 entry, found 0 |
| sublanguage F2: malformed query yields diagnostic | sublanguage.zig:113 | diagnostic not found |
| sublanguage F3: hover on bound node | sublanguage.zig:123 | NoBindings |
| sublanguage F3: go-to-definition on bound node | sublanguage.zig:153 | NoDefinition |
| sublanguage F4: hover snapshot on bound node | sublanguage.zig:164 | NoBindings |
| sublanguage R4: cross-module erika expands Custom AST | sublanguage.zig:213 | expected 1, found 0 |
| sublanguage R4: cross-module literal paints tokens | sublanguage.zig:231 | `custom.len > 0` fails |
| sublanguage R4: malformed cross-module query diagnoses | sublanguage.zig:277 | diagnostic not found |

**Root cause analysis:** Template functions returning `@ExprCustom<T>` use `#[@Host]` methods (`e.build()`, `e.lookup()`, `e.custom()`) that require redirection to `botopink_comptime_prelude` calls. The `evaluateErl` path in `template_eval.zig` compiles the template body to Erlang and runs it via persistent_erl, but the generated Erlang code calls host methods that aren't patched for individual template bodies (only `template_runtime.erl` gets patched via `patchHostMethods`). This causes `evaluateErl` to return `EvalFailed`, so `customAstByLoc` stays empty and all sublanguage tests fail.

**Fix required:** Either extend `patchHostMethods` to also patch individual template body Erlang output, or implement `#[@Host]` method lowering in the Erlang codegen itself so host methods emit prelude calls directly.

### Step 4 — Remaining work

| Task | Status | Notes |
|------|--------|-------|
| Investigate root cause of sublanguage + completion test failures | **completed** | Root cause: `#[@Host]` methods not patched in template body Erlang output; `evaluateErl` returns `EvalFailed`; `customAstByLoc` stays empty |
| Update 01-erl-fixes.md spec with findings | **completed** | This section + Step 8b added |
| Fix the failing tests (9 language-server) | **pending** | Requires `#[@Host]` method lowering in erlang codegen or extending `patchHostMethods` to template bodies |
| Fix allocation leaks in codegen tests | **pending** | Multiple codegen tests leak 1 allocation each (values, string interpolation, loop, try/catch, @print, dispatch, destructure) |

## Context

After `persistent-erl-runtime` and `erl-comptime-speed` (both completed), the persistent erl subprocess handles all comptime. The decompiler (`template_eval.zig:emitBpExpr`) already handles all AST constructs (if/else, case, loop, identAccess, dotIdent, pipeline, string templates).  

The real gaps were:
- **decorator_eval.zig**: `evaluateErl()` was a stub returning `error.EvalFailed`
- **beam.zig**: `renderExprValue` only handled literals, binary ops, and simple arrays — missing fnCall, identAccess, if/else, case, recordLit
- **comptime.zig**: `patchHostMethods` used `element(2, Self)` but records are maps, not tuples; also missing `fail`/`failAt`/`build` methods
- **erl_prelude.zig**: Missing `fail`/`fail_at`/`build` Erlang functions
- **runtime.zig**: `executeBeamAsm` used `std.process.run` without timeout; `persistent_erl.zig` `ensureSpawned` had no `erlc` timeout

**What was delivered (by prior specs):**
- Persistent erl subprocess as sole comptime runtime
- BEAM bytecode cache
- Binary framing protocol
- `#[@Host]` lowering via post-processing of `template_runtime.erl`
- Node.js, wasm3, WAT, AtomVM — all removed

---

## Testing Strategy

| Layer | What | Where | When |
|-------|------|-------|------|
| **Unit** | Per-function correctness (decompiler, renderExprValue, patchHostMethods) | `comptime/tests/` — Zig tests calling functions directly | Within each step — write BEFORE fixing |
| **Integration** | End-to-end chains (BP source → erl eval → result) | `comptime/tests/` — compile .bp snippets through full pipeline | After unit tests pass |
| **Snapshot** | Codegen output across all 4 backends | `snapshots/codegen/{node,erlang,beam,wasm}/` | Regenerate after each codegen fix step |
| **Regression** | Fixed gaps stay fixed | `comptime/tests/templates.zig`, `comptime/tests/decorators.zig` | Step 6 — after fixes land |

**Test-first rule for Steps 1-5**: Write the test first, confirm it fails (red), then implement the fix (green). Every acceptance criterion must map to at least one test.

**Snapshot cycle**: `rm snapshots/codegen/<backend>/*.snap.md && zig build test` regenerates. Never hand-edit snapshots. A snapshot diff is either a bug (fix the codegen) or intentional (regenerate and commit).

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

### Tests (write before fixing)

Each test: parse BP snippet → decompile AST via `emitBpExpr` → re-parse → verify AST equality.

```botopink
// slug: decompile_if_else
fn merge(comptime a: type, comptime b: type) -> type {
    if (a == b) { break a; } else { break record {}; };
}

// slug: decompile_case_match
fn describe(comptime t: type) -> string {
    case (@typeInfo(t)) {
        TypeInfo.Int -> { break "integer"; };
        _ -> { break "other"; };
    };
}

// slug: decompile_loop_fields
fn fieldNames(comptime T: type) -> string[] {
    val info = @typeInfo(T);
    var names: string[] = [];
    loop (info.Record.fields) { f ->
        names = names.push(f.name);
    };
    break names;
}

// slug: decompile_field_access
fn firstFieldType(comptime T: type) -> type {
    val info = @typeInfo(T);
    break info.Record.fields[0].typeName;
}

// slug: decompile_dot_ident
fn isRecord(comptime T: type) -> bool {
    break @typeInfo(T) is TypeInfo.Record;
}

// slug: decompile_pipeline
fn countFields(comptime T: type) -> i32 {
    break (@typeInfo(T).Record.fields |> .len);
}

// slug: decompile_string_template
fn typeName(comptime T: type) -> string {
    break "type: ${T}";
}
```

**Test file:** `modules/compiler-core/src/comptime/tests/templates.zig`

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

### Tests (write before fixing)

```botopink
// slug: decorator_simple_attribute
#[result(value = 42)]
fn getAnswer() -> i32 { return 42; }
// getAnswer() should have attribute "result" with value 42

// slug: decorator_loop_body
#[validate(fields)]
record User { name: string, age: i32 }
// validate decorator body loops over fields — must not crash

// slug: decorator_conditional_body
#[guard(when: target is record)]
fn guardedFn(comptime T: type) -> type { break T; }
// guard decorator with conditional — must not crash

// slug: decorator_error_surface
#[fail("test error")]
fn badDecorator() -> void {}
// Should produce compiler diagnostic with "test error", not silent crash
```

**Test file:** `modules/compiler-core/src/comptime/tests/decorators.zig`

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

### Test

```zig
// Verify patchHostMethods correctly extracts descriptor from Capture record.
// Compile template_runtime.bp → Erlang → inspect tuple layout.
// If element(2, Self) matches actual position → test passes.
// If not → refactor to use named field or fix position.
test "patchHostMethods: descriptor extraction" {
    const erl_output = try compileModule("libs/std/src/template_runtime.bp", .erlang);
    // Verify Capture tuple layout: {capture, Descriptor, ...}
    try testing.expect(erl_output contains "element(2, Self)");
    // Verify no silent crash from wrong position
}
```

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
| Codegen snapshots (RUN LOG empty) | 5 | comptime eval produces `"null"` | Step 5 |
| LSP sublanguage tests | 9 | Templates not executing on erl | Step 1 |
| Memory leak | 1 | Unrelated — separate investigation | — |
| Snapshot diffs | 6 | comptime eval produces `"null"` | Step 5 |
| **Total** | **36** | | |

**Acceptance criteria:**
- [ ] 36 → 0 test failures
- [ ] `zig build test` passes with zero failures
- [ ] All snapshot files regenerated

---

## Step 5 — Make comptime eval work in Erl

**Status:** pending **Assignee:**
**Priority:** HIGH — blocks comptime eval for complex expressions

The persistent erl subprocess is the sole comptime runtime, but the eval pipeline has gaps:

| Gap | File | Impact |
|-----|------|--------|
| `renderExprValue` incomplete | `beam.zig:68-141` | Falls to `"null"` for: fn calls, field access, method calls, if/case/loop, record/enum construction, pipeline, string templates |
| `patchHostMethods` incomplete | `comptime.zig:423-451` | Missing `fail`/`failAt`/`build` on Capture/DeclHandle — template bodies crash at runtime |
| `erl_prelude` missing `fail`/`failAt` | `erl_prelude.zig` | No Erlang-side implementation for comptime error surfacing |
| `renderExprValue` only handles break not return | `beam.zig:68-141` | Return statements with values produce `"null"` |

### 5.1 — Extend `renderExprValue` for complex expressions

`beam.zig:renderExprValue()` currently handles: literals, binary ops on ints, array literals, break/return with values. Add support for:

| Expression | Priority | Used by |
|-----------|----------|---------|
| `fnCall` | CRITICAL | `@typeInfo(T)`, `@TypeOf(v)`, `@print(x)`, all builtin calls |
| `identAccess` (field access) | CRITICAL | `info.Record.fields`, `f.name`, record field reads |
| `dotIdent` | HIGH | `@typeInfo(T).Record`, enum variant access |
| `if/else` | HIGH | Comptime branching, `@comptimeError` guard |
| `case`/`match` | HIGH | Enum introspection, Result/Ok/Error handling |
| `collection.recordLit` | MEDIUM | `RecordField(name: "x", typeName: i32)`, struct construction |
| `loop` | MEDIUM | Field iteration over record fields |
| Pipeline `\|>` | LOW | Std function chaining |

### 5.2 — Complete `patchHostMethods`

`comptime.zig:patchHostMethods()` post-processes generated Erlang to replace `#[@Host]` stubs with prelude calls. Currently handles: `context`, `lookup`, `bindings`, `parts`, `custom`, `makeExpr`, `makeCode`.

**Missing methods to add:**
- `DeclHandle.fail(msg)` / `DeclHandle.failAt(span, msg)` → throw `{comptime_fail, ...}`
- `Capture.fail(msg)` / `Capture.failAt(span, msg)`
- `Capture.build(type)` → construct record from captures
- Any other `#[@Host]` methods used by template_runtime.bp

### 5.3 — Add `fail`/`failAt` to erl prelude

`erl_prelude.zig` exports descriptor walkers but has no `fail`/`failAt` functions. The bare `throw({comptime_fail, ...})` at line 126 needs proper Erlang functions that:
- Format the error message with span info
- Throw a structured `{comptime_fail, Message, Span}` tuple
- Are callable from patched `#[@Host]` stubs

### 5.4 — Handle `return` (not just `break`) in comptime blocks

`renderExprValue` walks comptime blocks looking for `break` with value. It should also handle `return` with value — both are valid exit paths.

### 5.5 — Eval pipeline integration test

Once renderExprValue is extended, add a round-trip test:
1. Build a BP snippet with complex comptime expressions (fn calls, field access, conditionals)
2. Run through the full eval pipeline: `comptimeEntry → buildScript → erl exec → parse result`
3. Verify JSON output has correct values (not `null`)

**Acceptance criteria:**
- [ ] `renderExprValue` handles fnCall, identAccess, dotIdent, if/else, case/match, recordLit
- [ ] `patchHostMethods` covers fail/failAt/build
- [ ] `erl_prelude` has fail/failAt Erlang functions
- [ ] Comptime blocks accept both `break` and `return` as exit paths
- [ ] Eval pipeline round-trip test passes
- [ ] `zig build test` passes — comptime tests that previously got `"null"` now get real values
- [ ] No WAT RUN LOG restoration — wasm3 is gone, erl is the sole comptime runtime

### Tests (write before fixing)

#### 5.1 Tests — `renderExprValue` per expression kind

Each test: build a `ComptimeEntry` from a typed expression → call `renderExprValue` → verify JSON output is not `"null"`.

```zig
// Test file: comptime/tests/eval_pipeline.zig

test "renderExprValue: fnCall" {
    // comptime x = @typeInfo(i32)
    // Expected: JSON with TypeInfo.Int structure, not "null"
}

test "renderExprValue: identAccess" {
    // comptime val info = @typeInfo(Point); val fields = info.Record.fields
    // Expected: JSON array of RecordField objects
}

test "renderExprValue: dotIdent" {
    // comptime val kind = @typeInfo(i32).Int  (or .Float, .Bool, etc.)
    // Expected: JSON with variant tag
}

test "renderExprValue: if_else" {
    // comptime val x = if (true) { 1 } else { 2 }
    // Expected: "1"
}

test "renderExprValue: case_match" {
    // comptime val x = case (@typeInfo(i32)) { TypeInfo.Int -> { 1 }; _ -> { 0 }; }
    // Expected: "1"
}

test "renderExprValue: recordLit" {
    // comptime val f = RecordField(name: "x", typeName: i32)
    // Expected: JSON object with name and typeName fields
}

test "renderExprValue: comptimeBlock_return" {
    // comptime { return 42; }
    // Expected: "42" (not "null")
}

test "renderExprValue: comptimeBlock_break" {
    // comptime { break 42; } 
    // Expected: "42"
}
```

#### 5.2 Tests — `patchHostMethods`

```zig
// Test file: comptime/tests/eval_pipeline.zig

test "patchHostMethods: fail on DeclHandle" {
    // Compile template that calls decl.fail("msg")
    // Verify generated Erlang calls botopink_comptime_prelude:fail(Decl, "msg")
}

test "patchHostMethods: failAt on Capture" {
    // Compile template that calls capture.failAt(span, "msg")
    // Verify generated Erlang calls botopink_comptime_prelude:fail_at(Capture, Span, "msg")
}
```

#### 5.3 Tests — `erl_prelude` fail/failAt

```erlang
% Test: compile prelude → call fail("test") → verify throw
% Expected: throw({comptime_fail, "test", #{}})

% Test: compile prelude → call fail_at("test", Span) → verify throw
% Expected: throw({comptime_fail, "test", Span})
```

#### 5.5 Integration test (after all sub-steps)

```zig
test "eval pipeline: complex comptime expression" {
    // Full pipeline: BP source → TypedExpr → ComptimeEntry → buildScript → erl exec
    const bp =
        \\val info = @typeInfo(Point);
        \\val names: string[] = [];
        \\loop (info.Record.fields) { f ->
        \\    names = names.push(f.name);
        \\};
        \\val count = names.len;
    ;
    const result = try evaluatePipeline(bp);
    try testing.expect(result.get("names") != null);
    try testing.expect(result.get("count") != null);
}
```

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/runtime/beam.zig` | `renderExprValue` — add missing expression kinds |
| `modules/compiler-core/src/comptime.zig` | `patchHostMethods` — add fail/failAt/build |
| `modules/compiler-core/src/comptime/runtime/erl_prelude.zig` | Add fail/failAt Erlang functions |
| `modules/compiler-core/src/comptime/tests/` | Integration test for eval pipeline |

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

### 7.4 — `#[@code]` type construction

```botopink
// slug: code_annotation_point_type
#[@code]
fn Point() -> TypeInfo {
    return TypeInfo.Record(fields: [
        RecordField(name: "x", typeName: i32),
        RecordField(name: "y", typeName: i32),
    ]);
}
val p: Point() = Point()(x: 1, y: 2);
@print(p.x);    // RUN LOG: 1

// slug: code_annotation_empty_record
#[@code]
fn Empty() -> TypeInfo {
    return TypeInfo.Record(fields: []);
}
val e = Empty()();
// Round-trip: @typeInfo(Empty()).Record.fields.len == 0
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
- [ ] 2 core builtins compute correct values (`@typeInfo`, `@TypeOf`)
- [ ] `#[@code]` annotation lifts TypeInfo to type at call site
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

### Tests — per backend verification strategy

For each fix, verify with a snapshot test:

```zig
// Pattern: fix → run test → snapshot gets RUN LOG (not empty, not crash)
test "codegen: .len → .length in JS" {
    // .bp: val s = "hello"; @print(s.len);
    // Expected RUN LOG: 5  (not undefined)
}

test "codegen: if without else in JS" {
    // .bp: val x = if (true) { 1; };
    // Expected RUN LOG: 1  (not crash)
}

test "codegen: try/catch in Erlang" {
    // .bp: val r: @Result<i32, string> = Ok(42);
    //       val v = try r;
    // Expected RUN LOG: 42
}

test "codegen: pipeline in Erlang" {
    // .bp: val x = [1,2,3] |> .len;
    // Expected RUN LOG: 3
}

test "codegen: try/catch in BEAM" {
    // .bp: val r: @Result<i32, string> = Ok(42);
    //       val v = try r;
    // Expected RUN LOG: 42
}

test "codegen: wasm external skip" {
    // .bp: uses external host functions
    // Expected: RUN LOG empty (documented skip), no crash
}
```

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
- **WASM:** `executeWat` currently returns `""` (wasm3 removed). If wasmtime is restored (Step 12), add the same timeout wrapper.

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

## Step 12 — Restore WAT RUN LOG execution

**Status:** pending **Assignee:**
**Priority:** LOW — codegen backend, only execution is gone

`codegen/runtime.zig:executeWat()` returns `""` because wasm3 was removed. The WAT codegen backend (`codegen/wat.zig`) is intact — only the runtime execution is missing.

**Options:**
- **A)** Restore wasmtime-based WAT execution (needs wasmtime on PATH)
- **B)** Accept empty RUN LOGs as new baseline

**Acceptance criteria:**
- [ ] Decision: option A or B
- [ ] If A: `executeWat()` runs WAT through wasmtime (use same `runWithTimeout` wrapper from Step 8a)
- [ ] If B: regenerate WAT snapshots with empty RUN LOG
- [ ] No test failures from WAT RUN LOG

### Files (if option A)

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/codegen/runtime.zig` | `executeWat` — wasmtime integration |

### Files (if option B)

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/codegen/snapshots/wasm/` | Regenerate WAT snapshots with empty RUN LOG |

---

## Step 13 — Regenerate snapshots, verify full suite

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

### Phase B — Codegen (Steps 8-13, parallel with Phase A)

1. **Step 9** first (orphans) — zero risk, independent
2. **Step 8** per backend — commonJS/WASM independent of erl steps; Erlang/BEAM may need Step 1
3. **Steps 10-11** after Step 8 — new tests
4. **Step 12** independent — restore WAT RUN LOG (codegen runtime)
5. **Step 13** final sweep

**Quick wins (no deps, under 30 min):**

| # | Action | Step | Time |
|---|--------|------|------|
| 1 | Delete 76 orphaned snapshots | 9 | ~10 min |
| 2 | Fix `.len` → `.length` in JS | 8 | ~30 min |
| 3 | Fix `if` without `else` in JS | 8 | ~20 min |
| 4 | Skip WASM RUN LOG for external tests | 8 | ~15 min |
| 5 | Fix record layout assumption | 3 | ~30 min |

## Test budget

| Category | Count | Step |
|----------|-------|------|
| Decompiler round-trip (unit) | 7 | 1 |
| Decorator e2e | 4 | 2 |
| Record layout unit | 1 | 3 |
| renderExprValue per-expr | 8 | 5.1 |
| patchHostMethods unit | 2 | 5.2 |
| erl_prelude unit | 2 | 5.3 |
| Eval pipeline integration | 1 | 5.5 |
| Decompiler round-trip (regression) | 10 | 6.1 |
| Persistent erl health | 4 | 6.2 |
| Decorator eval e2e (regression) | 3 | 6.3 |
| Error surface | 3 | 6.4 |
| Comptime type eval | ≥12 | 7 |
| Codegen crash fix snapshots | 14 | 8 |
| Timeout unit | 1 | 8a |
| New codegen tests | 27 | 10 |
| Template/@Expr codegen tests | 7 | 11 |
| WAT RUN LOG snapshot verify | — | 12 |
| **Total new tests** | **≥106** | |
| **Existing fixed** | 36 | 4 |
| **Grand total** | **≥142** | |

## Summary

| Step | Priority | Blocks | Parallel-safe |
|------|----------|--------|---------------|
| 1 — Decompiler | **CRITICAL** | Waves 2 | No |
| 2 — Decorator eval | HIGH | — | After Step 1 |
| 3 — Record layout | MEDIUM | — | Yes |
| 4 — Test failures | HIGH | — | After Steps 1-3, 5 |
| 5 — Comptime eval in Erl | HIGH | — | Yes |
| 6 — Erl regression tests | HIGH | — | After Steps 1-2, 5 |
| 7 — Type eval tests | HIGH | Wave 2 | After Steps 1-2, 5 |
| 8 — Codegen crash fixes | HIGH | Steps 10-11 | Yes (per backend) |
| 9 — Orphaned snapshots | LOW | — | Yes |
| 10 — New codegen tests | HIGH | — | After Step 8 |
| 11 — Template codegen tests | HIGH | — | After Steps 1 + 8 |
| 12 — WAT RUN LOG | LOW | — | Yes |
| 13 — Final sweep | HIGH | — | After all |

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Created from erl-comptime-gaps consolidation | ericfillipe |
| 2026-06-30 | Added Step 6: erl runtime regression tests (decompiler round-trip, persistent erl health, decorator e2e, error surface) | ericfillipe |
| 2026-06-30 | Step 5 → Comptime eval in Erl + Step 12 → WAT RUN LOG (codegen); Testing Strategy section + concrete tests per step + test budget (≥106 new) | ericfillipe |
| 2026-06-30 | Updated Step 7: `@makeRecord` removed — replaced by `#[@code]` annotation pattern. Only 2 core builtins tested (@typeInfo, @TypeOf) | ericfillipe |
| 2026-07-01 | Steps 1-3, 5.2-5.4, 8a, 9 completed. Decompiler already complete. Fixed record layout (maps:get). Added fail/failAt/build to prelude + patchHostMethods. Implemented decorator eval. Added timeouts to executeBeamAsm + persistent_erl. Deleted 110 orphaned snapshots. Pre-existing hang: test 114 (comptime val + specialization). | ericfillipe |
