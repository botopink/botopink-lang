# Wave 2 — Comptime Type System

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe
**Depends on:** Wave 1 (`01-erl-fixes.md` Step 1)

---

## Status

**Current:** in progress — inference-time type resolution done; value eval + narrowing implementation pending

> Consolidates `comptime-type-introspection`, `comptime-eval-and-types`, and `state-narrowing` into one sequential wave. Ordered by dependency: type infrastructure → type introspection → state narrowing.

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | `type` as first-class comptime value | pending | |
| Step 2 | Implement comptime value evaluation for builtins | pending | |
| Step 3 | Implement comptime eval loop for std functions | pending | |
| Step 4 | Implement std functions in .bp | pending | |
| Step 5 | Comptime tests for builtins + std functions | pending | |
| Step 6 | Parser support for type guards | pending | |
| Step 7 | Inference engine state narrowing | pending | |
| Step 8 | Comptime narrowing tests | pending | |
| Step 9 | Codegen narrowing tests (all 4 backends) | pending | |

## What's already done

3 core builtins registered in the compiler, resolve correct return types during inference:
- `@typeInfo(T)` — returns `TypeInfo` type (not value yet)
- `@TypeOf(v)` — returns type of value (inference-time only)
- `@makeRecord(fields)` — returns fresh type variable (not concrete yet)

Types are embedded in compiler as Zig source. `RecordField.typeName` (not `type` — keyword conflict). 23 snapshot tests pass.

> **Design note:** `@RecordKeys` and `@Field` are NOT compiler builtins — they're std functions in `types.bp` built on `@typeInfo`. Formerly registered as inference-time builtins; those registrations should be removed when the std versions land (Step 4).

State-narrowing audit + test matrix designed (24 tests across 14 patterns). Existing comptime narrowing coverage: 8 tests for null-check + variant access — sparse.

---

## Part A — Type Infrastructure (Steps 1-5)

### Step 1 — `type` as first-class comptime value

**Status:** pending **Assignee:**

`type` becomes a valid annotation and value at comptime. Bindings can hold type values, pass them as `comptime T: type` params, return from functions.

```botopink
val T = i32;                              // T: type = i32
val Point = record { x: i32, y: i32 };    // Point: type
fn identityType(comptime T: type) -> type { break T; }
```

**Implementation:**
- Register `"type"` as builtin type in `Env.registerBuiltins`
- The type of a type is `type`; unify with `"type"` named type
- Parser: support `val x: type = ...` and `comptime x: type` in param lists

**Acceptance criteria:**
- [ ] `type` usable as annotation, value, param, return type
- [ ] `zig build test` passes

### Files

| File | Purpose |
|------|---------|
| `comptime/env.zig` | Register `type` builtin |
| `comptime/infer.zig` | Unify `type` values |
| `parser/decls.zig` | Support `type` in val/param annotations |

---

### Step 2 — Implement comptime value evaluation for core builtins

**Status:** pending **Assignee:**

3 core builtins must compute actual values at comptime, not just types. `@RecordKeys` and `@Field` are implemented as std functions in `types.bp` (see Step 4), not as compiler builtins.

```botopink
@typeInfo(i32)                    → TypeInfo.Int (value)
@typeInfo(record { x: i32 })      → TypeInfo.Record(fields: [...])
@typeInfo(enum { A, B(x: i32) })  → TypeInfo.Enum(variants: [...])
@TypeOf(42)                      → i32 (type value)
@makeRecord([RecordField("a", i32)]) → concrete record type
```

**Acceptance criteria:**
- [ ] All 5 value-eval cases above produce correct results
- [ ] Remove inference-time-only registrations for `@RecordKeys` and `@Field` from compiler
- [ ] `zig build test` passes

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/eval.zig` | Value evaluation for each builtin |
| `modules/compiler-core/src/comptime/infer.zig` | Wire eval results into inference |

---

### Step 3 — Implement comptime eval loop for std functions

**Status:** pending **Assignee:**

Build evaluation loop so `.bp` functions with `comptime` params can execute during inference:
1. Resolve comptime params to concrete values
2. Evaluate function body expression by expression
3. Handle builtins (`@typeInfo`, `@RecordKeys`, `@makeRecord`, `@comptimeError`)
4. Handle loops over comptime arrays, `break` with type value, `if/else` with comptime conditions

**Acceptance criteria:**
- [ ] Comptime functions with `type` params evaluate correctly
- [ ] `if/else`, `loop`, `break` work in comptime context
- [ ] `@comptimeError` builtin implemented
- [ ] `zig build test` passes

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/specialize.zig` | Extend or create eval_types.zig |
| `modules/compiler-core/src/comptime/builtins.zig` | Register @comptimeError |

---

### Step 4 — Implement std functions in .bp

**Status:** pending **Assignee:**

Six std functions built purely in user-space `.bp` code using the 3 core builtins:

**Type manipulation** (`libs/std/src/reflect.bp`):
```botopink
fn mergeRecords(comptime A: type, comptime B: type) -> type { ... }
fn partial(comptime T: type) -> type { ... }
fn omit(comptime T: type, comptime name: string) -> type { ... }
fn pick(comptime T: type, comptime names: string[]) -> type { ... }
```

**Type introspection** (`libs/std/src/types.bp`):
```botopink
fn recordKeys(comptime T: type) -> string[] {
    // Uses @typeInfo(T).Record.fields → extracts field names
}
fn field(comptime T: type, v: T, comptime name: string) -> any {
    // Uses @typeInfo(T) + runtime field access
}
```

`recordKeys` and `field` are std functions — NOT compiler builtins. They prove `@typeInfo` is sufficient for field-level introspection. The compiler-side `@RecordKeys`/`@Field` inference-time registrations should be removed once these land.

**Acceptance criteria:**
- [ ] All 6 functions compile and produce correct types/values
- [ ] `mergeRecords` conflict detection works
- [ ] `recordKeys(record { x: i32, y: string })` → `["x", "y"]`
- [ ] `field(Point(x: 1, y: 2), "x")` → `1`
- [ ] Remove `@RecordKeys`/`@Field` inference-time builtin registrations from compiler
- [ ] `zig build test` passes

---

### Step 5 — Comptime tests for builtins + std functions

**Status:** pending **Assignee:**

~20 comptime tests verifying value-level evaluation of builtins and std functions.

**Acceptance criteria:**
- [ ] Tests for all 5 builtins with multiple input types
- [ ] Tests for mergeRecords, partial, omit, pick (success + error paths)
- [ ] Tests in `comptime/tests/builtins_typeinfo.zig`
- [ ] `zig build test` passes

---

## Part B — State Narrowing (Steps 6-9)

### Step 6 — Parser support for type guards

**Status:** pending **Assignee:**

Add parsing for `-> ident is Type` in function return position:

```botopink
fn isCircle(s: Shape) -> s is Shape.Circle { ... }
fn isError(r: @Result<i32, string>) -> r is @Result.Err { ... }
```

**Acceptance criteria:**
- [ ] Type guard syntax parses correctly
- [ ] Parser snapshot tests added
- [ ] `zig build test` passes

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/parser/decls.zig` | Parse `-> ident is Type` |

---

### Step 7 — Inference engine state narrowing

**Status:** pending **Assignee:**

Implement 13 narrowing patterns in the Hindley-Milner inference engine:

| # | Pattern | Example |
|---|---------|---------|
| 1 | `if (x)` null-check | `?T → T` in then-branch |
| 2 | `if (x)` else branch | `?T → T` in then, `?T` in else |
| 3 | `case` on `@Result<D,E>` | `Ok(v): D`, `Err(e): E` |
| 4 | `case` on `@Option<T>` | `Some(v): T`, `None` |
| 5 | `case` on user enum variants | Variant-specific field access |
| 6 | OR patterns | Shared field types across arms |
| 7 | Guard clauses | Narrowed type visible in guard |
| 8 | `assert x is Pattern` | `x` narrowed after assert |
| 9 | Early return `if (!x) { return; }` | `x` narrowed after guard |
| 10 | `else if` chains | Each branch narrows correctly |
| 11 | `if (x && x.field)` | `x` narrowed before `.field` |
| 12 | Optional chaining `x?.field` | Only access field if non-null |
| 13 | Type guards | `if (isX(x))` narrows `x` at call site |

**Acceptance criteria:**
- [ ] All 13 patterns narrow correctly
- [ ] Narrowing failure tests produce correct errors
- [ ] `zig build test` passes

### Files

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/infer.zig` | Narrowing logic in all control-flow constructs |
| `modules/compiler-core/src/comptime/env.zig` | Scoped type environments for narrowed branches |

---

### Step 8 — Comptime narrowing tests

**Status:** pending **Assignee:**

24 narrowing tests (22 positive + 2 negative) covering all 14 patterns from the test matrix. Tests verify inference produces correct types after narrowing.

```botopink
// slug: narrow_if_null_check_record_field_access
fn greet(maybeUser: ?User) -> string {
    if (maybeUser) { u -> return "hello " + u.name; };
    return "no user";
}

// slug: narrow_case_result_ok_err
fn handle(n: i32) -> string {
    val r = parse(n);
    return case r { Ok(v) -> "parsed: " + v; Err(e) -> "error: " + e; };
}
```

**Acceptance criteria:**
- [ ] 24 tests in `comptime/tests/narrowing.zig`
- [ ] `zig build test` passes

---

### Step 9 — Codegen narrowing tests (all 4 backends)

**Status:** pending **Assignee:**
**Depends on:** Wave 3 Step 1 (runtime crash fixes)

≥8 codegen tests verifying narrowed values produce correct runtime output:

```botopink
// slug: narrow_if_null_with_print
fn main() {
    val x: ?i32 = 42;
    if (x) { n -> @print(n); };           // RUN LOG: 42
}

// slug: narrow_case_result_ok_err_with_print
fn main() {
    val r1 = fetch(true);
    @print(case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; });
    val r2 = fetch(false);
    @print(case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; });
}
// expected RUN LOG: OK:data\nERR:fail
```

**Acceptance criteria:**
- [ ] ≥8 narrowing codegen tests, all 4 backends
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output

---

## Execution order

```
Step 1 (type as value)
  └──► Step 2 (builtins value eval)
         └──► Step 3 (comptime eval loop)
                └──► Step 4 (std functions in .bp)
                       └──► Step 5 (comptime tests)

Step 6 (parser: type guards) ── independent, can run after Step 1
  └──► Step 7 (inference: narrowing) ── needs Step 6
         └──► Step 8 (comptime narrowing tests) ── needs Step 7
                └──► Step 9 (codegen narrowing tests) ── needs Wave 3
```

Steps 6-9 (narrowing) can run in parallel with Steps 2-5 (type introspection) once Step 1 is done. ⚠️ Both touch `comptime/infer.zig`.

## Summary

| Metric | Count |
|--------|-------|
| New builtins | 5 + `@comptimeError` |
| New std functions | 4 |
| Narrowing patterns | 13 |
| Comptime tests | ~44 (20 builtins + 24 narrowing) |
| Codegen tests | ≥8 |

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Created from comptime-type-introspection + state-narrowing + comptime-eval-and-types consolidation | ericfillipe |
