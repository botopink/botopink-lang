# State Narrowing — Control-Flow Type Refinement

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe

---

## Status

**Current:** in progress — audit and test matrix done; implementation (parser + inference) not started

> Steps 1-2 (audit + test design) are complete. Steps 3-6 (implementation) are all pending. The spec was previously marked "completed" but only the planning phase was done.

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Audit existing narrowing coverage | completed | ericfillipe |
| Step 2 | Design narrowing test matrix | completed | ericfillipe |
| Step 3 | Implement parser support for type guards | pending | |
| Step 4 | Implement inference engine narrowing | pending | |
| Step 5 | Implement comptime narrowing tests | pending | |
| Step 6 | Implement codegen narrowing tests (all 4 backends) | pending | |

## Objective

Add TypeScript-style control-flow type narrowing to the botopink inference
engine: when the compiler can prove that a variable's type is more specific
inside a particular branch (after `if`, `case`, `assert`, early-return,
optional chaining, or type guard call), it narrows the type for subsequent
expressions in that branch.

This spec also introduces **type guards** — functions annotated with
`-> param is NarrowedType` that tell the inference engine to narrow the
argument type at the call site.

## Prerequisites

- `zig build test` passing
- [**BLOCKING**] Parser must support `!x` prefix operator for early-return guard clauses (`if (!x) { return; }`) — verify before Step 4
- Codegen tests (Step 6) depend on [`1_0_0_beta.codegen-test-gap.md`](./1_0_0_beta.codegen-test-gap.md) for test infrastructure

---

## Step 1 — Audit existing narrowing coverage

**Status:** completed **Assignee:** ericfillipe

### What already exists

Botopink already has comptime-level narrowing tests:

| Pattern | Test slug | Narrowing |
|---------|-----------|-----------|
| `if (x)` null check | `if_null_check_binding_returns_optional` | `?T → T` in then-branch |
| `if (x)` with else | `if_null_check_binding_with_else` | `?T → T` in then, `?T` in else |
| `case` variant field access | `field_access_after_pattern_matching` | Enum variant fields accessible after match |
| `case` variant field access 2 | `access_variant_specific_field_after_matching` | Variant-specific field access |
| Variant scope | `variant_does_not_escape_clause_scope` | Bindings don't leak out of `case` arm |
| Optional annotation | `optional_annotation_i32_val_with_null` | `?i32` type inference |

### What's missing

| Narrowing pattern | Priority | Risk |
|-------------------|----------|------|
| `case` on `@Result<D,E>` with polymorphic payload | High | Core error handling |
| `case` on `@Option<T>` (`Some(v)` / `None`) | High | Optional values |
| Enum variant narrowing — different payload types per arm | High | Discriminated unions |
| `if (x)` narrowing for `?bool`, `?string`, `?record` | High | Non-`?i32` optional types |
| Type guards (`fn isX(x: T) -> x is NarrowedType`) | High | User-defined narrowing |
| `assert` pattern narrowing | Medium | Pattern-match assertions |
| Early-return narrowing (`if (!x) { return; }`) | Medium | Guard clauses |
| Nested narrowing (if inside case arm) | Medium | Complex control flow |
| `else if` chain narrowing | Low | Multi-branch refinement |
| Narrowing across function boundaries | Low | Advanced |
| Loop invariant narrowing | Low | While/loop |

---

## Step 2 — Design narrowing test matrix

**Status:** completed **Assignee:** ericfillipe

25+ tests designed across 14 narrowing patterns (see full test matrix below).

### Test patterns designed

| # | Pattern | Slug prefix | Positive | Negative |
|---|---------|-------------|----------|----------|
| 1 | `if` null-check narrowing | `narrow_if_null_check_*` | 3 | — |
| 2 | `if` null-check with `else` | `narrow_if_null_else_*` | 2 | — |
| 3 | `case` on `@Result<D,E>` | `narrow_case_result_*` | 2 | — |
| 4 | `case` on `@Option<T>` | `narrow_case_option_*` | 1 | — |
| 5 | `case` on user enum variants | `narrow_case_enum_*` | 2 | — |
| 6 | `case` with OR patterns | `narrow_case_or_*` | 1 | — |
| 7 | `case` with guard clauses | `narrow_case_guard_*` | 2 | — |
| 8 | `assert` pattern narrowing | `narrow_assert_*` | 2 | — |
| 9 | Early return narrowing | `narrow_early_return_*` | 1 | — |
| 10 | `else if` chain | `narrow_else_if_*` | 1 | — |
| 11 | `if` with `&&` condition | `narrow_if_and_*` | 1 | — |
| 12 | Optional chaining | `narrow_optional_chaining_*` | 1 | — |
| 13 | Narrowing failure tests | `narrow_error_*` | — | 2 |
| 14 | Type guards | `typeguard_*` | 3 | — |
| **Total** | | | **22** | **2** |

Full test source code in the detailed test matrix at the end of this spec.

---

## Step 3 — Implement parser support for type guards

**Status:** pending **Assignee:**

Add parsing for `-> ident is Type` in function return position.

```botopink
fn isCircle(s: Shape) -> s is Shape.Circle { ... }
fn isError(r: @Result<i32, string>) -> r is @Result.Err { ... }
```

**Acceptance criteria:**
- [ ] `fn isX(x: T) -> x is NarrowedType { ... }` parses correctly
- [ ] Parser snapshot tests added
- [ ] `zig build test` passes

### Files to modify

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/parser/decls.zig` | Parse `-> ident is Type` in fn return type |
| `modules/compiler-core/src/parser/tests/declarations.zig` | Parser tests for type guard syntax |

---

## Step 4 — Implement inference engine narrowing

**Status:** pending **Assignee:**

Implement all narrowing patterns in the Hindley-Milner inference engine.

**Acceptance criteria:**
- [ ] `if (x)` narrows `?T → T` for `?i32`, `?bool`, `?string`, `?record`
- [ ] `case` narrows to matched variant + binds payload fields
- [ ] `case` on `@Result<D,E>` narrows `Ok(v): D` and `Err(e): E`
- [ ] `case` on `@Option<T>` narrows `Some(v): T` and `None`
- [ ] OR patterns narrow to shared field types
- [ ] Guard clauses see narrowed type
- [ ] `assert x is Pattern` narrows `x` after the assert
- [ ] Early return `if (!x) { return; }` narrows `x` after the if
- [ ] `else if` chains narrow correctly
- [ ] `if (x && x.field)` narrows `x` before `.field` access
- [ ] Optional chaining `x?.field` only accesses field if non-null
- [ ] Type guards narrow the argument at the call site
- [ ] Narrowing failure tests produce correct errors

### Files to modify

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/infer.zig` | Narrowing logic in all control-flow constructs |
| `modules/compiler-core/src/comptime/env.zig` | Scoped type environments for narrowed branches |

---

## Step 5 — Implement comptime narrowing tests

**Status:** pending **Assignee:**

Add the 24 narrowing tests from Step 2 to the comptime test suite.

**Acceptance criteria:**
- [ ] All 24 narrowing tests pass with `zig build test`
- [ ] Each narrowing pattern has at least one positive test (correct narrowing)
- [ ] Each narrowing pattern has at least one negative test (should error)
- [ ] Snapshot files auto-created

### Files to create

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/tests/narrowing.zig` | All narrowing tests |

---

## Step 6 — Implement codegen narrowing tests (all 4 backends)

**Status:** pending **Assignee:**

For each narrowing pattern, add codegen tests that verify runtime behavior (RUN LOG capture).

**Depends on:** Step 4 (inference engine), `codegen-test-gap.md` Step 2 (runtime crash fixes).

Priority tests:

```botopink
// slug: narrow_if_null_with_print
fn main() {
    val x: ?i32 = 42;
    if (x) { n -> @print(n); };           // RUN LOG: 42
}

// slug: narrow_case_enum_area_with_print
enum Shape { Circle(radius: f64), Square(side: f64) }
fn area(s: Shape) -> f64 {
    return case s { Circle(r) -> 3.14 * r * r; Square(s) -> s * s; };
}
fn main() {
    @print(area(Shape.Circle(2.0)));
    @print(area(Shape.Square(3.0)));
}
// expected RUN LOG: 12.56\n9

// slug: narrow_case_result_ok_err_with_print
#[@result]
fn fetch(ok: bool) -> @Result<string, string> {
    if (ok) { return "data"; }; throw "fail";
}
fn main() {
    val r1 = fetch(true);
    @print(case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; });
    val r2 = fetch(false);
    @print(case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; });
}
// expected RUN LOG: OK:data\nERR:fail

// slug: narrow_early_return_with_print
fn greet(x: ?string) -> string {
    if (!x) { return "nobody"; };
    return "hello " + x;
}
fn main() {
    @print(greet("world"));
    @print(greet(null));
}
// expected RUN LOG: hello world\nnobody
```

**Acceptance criteria:**
- [ ] ≥8 narrowing codegen tests added
- [ ] Each test runs on all 4 backends (node, erlang, beam, wasm)
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output

---

## Detailed test matrix

### 2.1 — `if` null-check narrowing

```botopink
// slug: narrow_if_null_check_record_field_access
record User { name: string }
fn greet(maybeUser: ?User) -> string {
    if (maybeUser) { u -> return "hello " + u.name; };
    return "no user";
}

// slug: narrow_if_null_check_bool
fn and(a: ?bool, b: ?bool) -> ?bool {
    if (a) { va -> if (b) { vb -> return va && vb; }; };
    return null;
}

// slug: narrow_if_null_check_chained
record A { b: ?record { c: i32 } }
fn getC(x: ?A) -> ?i32 {
    if (x) { a -> if (a.b) { b -> return b.c; }; };
    return null;
}
```

### 2.2 — `if` null-check with `else` branch

```botopink
// slug: narrow_if_null_else_returns_different_type
fn describe(x: ?i32) -> string {
    if (x) { n -> return "got " + n; };
    return "nothing";
}

// slug: narrow_if_null_else_uses_original_type
fn fallback(x: ?string) -> string {
    if (x) { s -> return s; };
    return "default";
}
```

### 2.3 — `case` narrowing on `@Result<D,E>`

```botopink
// slug: narrow_case_result_ok_err
#[@result]
fn parse(n: i32) -> @Result<string, string> { ... }
fn handle(n: i32) -> string {
    val r = parse(n);
    return case r { Ok(v) -> "parsed: " + v; Err(e) -> "error: " + e; };
}

// slug: narrow_case_result_different_payload_types
record User { name: string }
enum AppError { NotFound, Timeout(msg: string) }
#[@result]
fn fetchUser(id: i32) -> @Result<User, AppError> { ... }
fn main() {
    val r = fetchUser(1);
    case r {
        Ok(u) -> @print(u.name);
        Err(NotFound) -> @print("404");
        Err(Timeout(msg)) -> @print("timeout: " + msg);
    };
}
```

### 2.4 — `case` narrowing on `@Option<T>`

```botopink
// slug: narrow_case_option_some_none
fn describe(opt: @Option<i32>) -> string {
    return case opt { None -> "empty"; Some(v) -> "value: " + v; };
}
```

### 2.5 — `case` narrowing on user-defined enum variants

```botopink
// slug: narrow_case_enum_variant_field_bindings
enum Shape { Circle(radius: f64), Rectangle(w: f64, h: f64), Point }
fn area(s: Shape) -> f64 {
    return case s {
        Circle(radius) -> 3.14 * radius * radius;
        Rectangle(w, h) -> w * h;
        Point -> 0.0;
    };
}

// slug: narrow_case_enum_nested_variant_access
enum Result_ { OkData(val: record { code: i32, msg: string }), Fail }
fn describe(r: Result_) -> string {
    return case r { OkData(d) -> d.msg; Fail -> "failed"; };
}
```

### 2.6 — `case` with OR patterns

```botopink
// slug: narrow_case_or_patterns_shared_bindings
enum Animal { Dog(breed: string), Cat(breed: string), Fish }
fn breed(a: Animal) -> string {
    return case a { Dog(b) | Cat(b) -> b; Fish -> "none"; };
}
```

### 2.7 — `case` with guard clauses

```botopink
// slug: narrow_case_guard_bound_identifier
fn describe(n: i32) -> string {
    return case n { x if (x > 0) -> "positive: " + x; x if (x < 0) -> "negative: " + x; _ -> "zero"; };
}

// slug: narrow_case_guard_variant_field
enum Response { Data(code: i32, body: string), Error(code: i32) }
fn handle(r: Response) -> string {
    return case r {
        Data(code, body) if (code == 200) -> body;
        Data(code, body) if (code == 404) -> "not found";
        Error(code) -> "error " + code;
    };
}
```

### 2.8 — `assert` pattern narrowing

```botopink
// slug: narrow_assert_pattern_after_assert
fn process(x: ?i32) -> i32 {
    assert x is Some(n);
    return n + 1;
}

// slug: narrow_assert_pattern_enum_variant
enum Status { Ready, Busy(count: i32), Down }
fn work(s: Status) -> i32 {
    assert s is Busy(n);
    return n;
}
```

### 2.9 — Early return narrowing

```botopink
// slug: narrow_early_return_guard_clause
fn greet(x: ?string) -> string {
    if (!x) { return "nobody"; };
    return "hello " + x;
}
```

### 2.10 — `else if` chain narrowing

```botopink
// slug: narrow_else_if_chain
fn classify(x: ?i32) -> string {
    if (x == 0) { return "zero"; }
    else if (x > 0) { return "positive: " + x; }
    else if (x < 0) { return "negative: " + x; }
    else { return "null"; }
}
```

### 2.11 — Narrowing across `if` with `&&`

```botopink
// slug: narrow_if_and_condition
record Box { weight: i32 }
fn describe(b: ?Box) -> string {
    if (b && b.weight > 10) { return "heavy: " + b.weight; };
    return "light or none";
}
```

### 2.12 — Optional chaining with narrowing

```botopink
// slug: narrow_optional_chaining_field_access
record Inner { value: i32 }
record Outer { inner: ?Inner }
fn getValue(o: Outer) -> ?i32 { return o.inner?.value; }
```

### 2.13 — Narrowing failure tests (must error)

```botopink
// slug: narrow_error_variant_field_in_wrong_arm — ERROR: radius not in scope in Square arm
// slug: narrow_error_optional_field_without_narrowing — ERROR: ?User has no field 'name'
```

### 2.14 — Type guards (user-defined narrowing functions)

```botopink
// slug: typeguard_enum_variant_narrowing
fn isCircle(s: Shape) -> s is Shape.Circle {
    return case s { Circle(_) -> true; _ -> false; };
}
fn area(s: Shape) -> f64 {
    if (isCircle(s)) { return 3.14 * s.radius * s.radius; };
    return s.side * s.side;
}

// slug: typeguard_assertion_mode
fn assertNonEmpty(s: ?string) -> s is string {
    if (s.len > 0) { return true; };
    @panic("empty or null string");
}
fn yell(s: ?string) -> string {
    assertNonEmpty(s);
    return s.toUpper();
}

// slug: typeguard_negation_narrowing
fn isError(r: @Result<i32, string>) -> r is @Result.Err {
    return case r { Err(_) -> true; _ -> false; };
}
fn describe(r: @Result<i32, string>) -> string {
    if (isError(r)) { return "error: " + r.e; };
    return "ok: " + r.d;
}
```

---

## Summary

| Metric | Count |
|--------|-------|
| Narrowing patterns identified | 14 |
| Positive tests designed | 22 |
| Negative tests designed | 2 |
| Codegen tests prioritized | 4+ |

### Key findings

1. **Botopink already has 8 comptime narrowing tests** for null-check, variant access, and optional type inference — but coverage is sparse.

2. **No codegen tests exist** for narrowing patterns. The existing comptime tests only verify type inference, not runtime behavior.

3. **Critical gaps:** `@Result<D,E>` narrowing, `@Option<T>` narrowing, early-return guard clauses, type guards, and `assert` pattern narrowing have zero tests.

4. **Type guards** (`fn isX(x: T) -> x is NarrowedType`) are the most impactful new feature — they enable user-defined narrowing predicates.

5. **Steps 3-4 can be parallelized:** parser changes (Step 3) and inference engine work (Step 4) touch different files for the most part. Step 4 depends on Step 3 only for the type guard return type AST node shape.

## Notes

- Type narrowing is purely a **comptime/inference** concern — codegen receives an already-typed AST.
- `case` arm narrowing (fields available only in matched variant) is the most complex part.
- Type guard return syntax (`-> param is Type`) requires parser changes before inference work.
- This spec does NOT overlap with `comptime-type-introspection` — narrowing is about control-flow type refinement, not type construction.

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created — state narrowing + type guards | ericfillipe |
| 2026-06-30 | Steps 1-2 completed: audit and test matrix designed | ericfillipe |
| 2026-06-30 | Rewritten: fixed status from "completed" to "in progress"; steps 3-6 correctly marked pending; removed codegen duplication (deferred to codegen-test-gap); added detailed test matrix inline | ericfillipe |
