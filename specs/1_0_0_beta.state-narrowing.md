# State Narrowing — Control-Flow Type Refinement

**Version:** 1.0.0-beta
**Status:** planning
**Created:** 2026-06-30
**Author:** ericfillipe
**Replaces:** `1_0_0_beta.state-narrowing.md` (expanded with type guards from `1_0_0_beta.ts-advanced-types-bp.md` §2.4)

---

## Status

**Current:** planning

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
- Spec `1_0_0_beta.codegen-test-gap.md` (codegen tests for narrowed values go there)

---

## Step 1 — Audit existing narrowing coverage

**Status:** completed
**Assignee:** ericfillipe

### What already exists

Botopink already has comptime-level narrowing tests:

| Pattern | Test slug | Narrowing |
|---------|-----------|-----------|
| `if (x)` null check | `if_null_check_binding_returns_optional` | `?T → T` in then-branch |
| `if (x)` with else | `if_null_check_binding_with_else` | `?T → T` in then, `?T` in else |
| `if (x)` body ignores | `null_check_binding_if_x_e_body_ignores_binding` | Narrowed if binding unused |
| `case` variant field access | `field_access_after_pattern_matching` | Enum variant fields accessible after match |
| `case` variant field access 2 | `access_variant_specific_field_after_matching` | Variant-specific field access |
| Variant scope | `variant_does_not_escape_clause_scope` | Bindings don't leak out of `case` arm |
| Optional annotation | `optional_annotation_i32_val_with_null` | `?i32` type inference |
| Type mismatch with null | `type_mismatch_i32_bool` | Error on type mismatch |

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
| `case` on `@Result` with `try`-fallthrough | Medium | Error propagation |
| `else if` chain narrowing | Low | Multi-branch refinement |
| Narrowing across function boundaries | Low | Advanced |
| Loop invariant narrowing | Low | While/loop |

---

## Step 2 — Design narrowing test matrix

**Status:** completed
**Assignee:** ericfillipe

### 2.1 — `if` null-check narrowing

```botopink
// slug: narrow_if_null_check_record_field_access
record User { name: string }
fn greet(maybeUser: ?User) -> string {
    if (maybeUser) { u ->
        return "hello " + u.name;  // u: User (narrowed from ?User)
    };
    return "no user";
}

// slug: narrow_if_null_check_bool
fn and(a: ?bool, b: ?bool) -> ?bool {
    if (a) { va ->
        if (b) { vb ->
            return va && vb;       // both narrowed to bool
        };
    };
    return null;
}

// slug: narrow_if_null_check_chained
record A { b: ?record { c: i32 } }
fn getC(x: ?A) -> ?i32 {
    if (x) { a ->
        if (a.b) { b ->
            return b.c;            // doubly-narrowed
        };
    };
    return null;
}
```

### 2.2 — `if` null-check with `else` branch

```botopink
// slug: narrow_if_null_else_returns_different_type
fn describe(x: ?i32) -> string {
    if (x) { n -> return "got " + n; };  // n: i32
    return "nothing";                      // x still ?i32 here
}

// slug: narrow_if_null_else_uses_original_type
fn fallback(x: ?string) -> string {
    if (x) { s -> return s; };      // s: string
    return "default";                // x was null
}
```

### 2.3 — `case` narrowing on `@Result<D,E>`

```botopink
// slug: narrow_case_result_ok_err
#[@result]
fn parse(n: i32) -> @Result<string, string> {
    if (n < 0) { throw "negative"; };
    return "ok";
}
fn handle(n: i32) -> string {
    val r = parse(n);
    return case r {
        Ok(v) -> "parsed: " + v;     // v: string
        Err(e) -> "error: " + e;     // e: string
    };
}

// slug: narrow_case_result_different_payload_types
record User { name: string }
enum AppError { NotFound, Timeout(msg: string) }
#[@result]
fn fetchUser(id: i32) -> @Result<User, AppError> {
    if (id == 0) { throw AppError.NotFound; };
    return User(name: "alice");
}
fn main() {
    val r = fetchUser(1);
    case r {
        Ok(u) -> @print(u.name);            // u: User
        Err(NotFound) -> @print("404");
        Err(Timeout(msg)) -> @print("timeout: " + msg);  // msg: string
    };
}
```

### 2.4 — `case` narrowing on `@Option<T>`

```botopink
// slug: narrow_case_option_some_none
enum @Option<T> { None, Some(T) }
fn describe(opt: @Option<i32>) -> string {
    return case opt {
        None -> "empty";
        Some(v) -> "value: " + v;     // v: i32
    };
}
```

### 2.5 — `case` narrowing on user-defined enum variants

```botopink
// slug: narrow_case_enum_variant_field_bindings
enum Shape {
    Circle(radius: f64),
    Rectangle(w: f64, h: f64),
    Point,
}
fn area(s: Shape) -> f64 {
    return case s {
        Circle(radius) -> 3.14 * radius * radius;   // radius: f64
        Rectangle(w, h) -> w * h;                     // w: f64, h: f64
        Point -> 0.0;
    };
}

// slug: narrow_case_enum_nested_variant_access
enum Result_ { OkData(val: record { code: i32, msg: string }), Fail }
fn describe(r: Result_) -> string {
    return case r {
        OkData(d) -> d.msg;           // d: { code: i32, msg: string }
        Fail -> "failed";
    };
}
```

### 2.6 — `case` with OR patterns

```botopink
// slug: narrow_case_or_patterns_shared_bindings
enum Animal {
    Dog(breed: string),
    Cat(breed: string),
    Fish,
}
fn breed(a: Animal) -> string {
    return case a {
        Dog(b) | Cat(b) -> b;         // b: string from either variant
        Fish -> "none";
    };
}
```

### 2.7 — `case` with guard clauses

```botopink
// slug: narrow_case_guard_bound_identifier
fn describe(n: i32) -> string {
    return case n {
        x if (x > 0) -> "positive: " + x;   // x: i32
        x if (x < 0) -> "negative: " + x;   // x: i32
        _ -> "zero";
    };
}

// slug: narrow_case_guard_variant_field
enum Response {
    Data(code: i32, body: string),
    Error(code: i32),
}
fn handle(r: Response) -> string {
    return case r {
        Data(code, body) if (code == 200) -> body;   // narrowed to Data
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
    return n + 1;                       // n: i32 (narrowed from assert)
}

// slug: narrow_assert_pattern_enum_variant
enum Status { Ready, Busy(count: i32), Down }
fn work(s: Status) -> i32 {
    assert s is Busy(n);
    return n;                           // n: i32
}
```

### 2.9 — Early return narrowing

```botopink
// slug: narrow_early_return_guard_clause
fn greet(x: ?string) -> string {
    if (!x) { return "nobody"; };
    return "hello " + x;                // x: string (narrowed by early return)
}
```

### 2.10 — `else if` chain narrowing

```botopink
// slug: narrow_else_if_chain
fn classify(x: ?i32) -> string {
    if (x == 0) { return "zero"; }
    else if (x > 0) { return "positive: " + x; }   // x: i32
    else if (x < 0) { return "negative: " + x; }   // x: i32
    else { return "null"; }
}
```

### 2.11 — Narrowing across `if` with `&&`

```botopink
// slug: narrow_if_and_condition
record Box { weight: i32 }
fn describe(b: ?Box) -> string {
    if (b && b.weight > 10) {          // b narrowed to Box for .weight access
        return "heavy: " + b.weight;
    };
    return "light or none";
}
```

### 2.12 — Optional chaining with narrowing

```botopink
// slug: narrow_optional_chaining_field_access
record Inner { value: i32 }
record Outer { inner: ?Inner }
fn getValue(o: Outer) -> ?i32 {
    return o.inner?.value;              // .value only accessed if inner != null
}
```

### 2.13 — Narrowing failure tests (must error)

```botopink
// slug: narrow_error_variant_field_in_wrong_arm
enum Shape {
    Circle(radius: f64),
    Square(side: f64),
}
fn bad(s: Shape) -> f64 {
    return case s {
        Circle(radius) -> radius;
        Square(side) -> radius;          // ERROR: radius not in scope
    };
}

// slug: narrow_error_optional_field_without_narrowing
record User { name: string }
fn bad(maybeUser: ?User) -> string {
    return maybeUser.name;               // ERROR: ?User has no field 'name'
}
```

### 2.14 — Type guards (user-defined narrowing functions)

Type guards extend the narrowing system with user-defined predicates. A
function with return type `-> param is NarrowedType` tells the inference
engine to refine the argument type at the call site.

**Syntax:**

```
fn name(param: T) -> param is NarrowedType { ... }
```

**Rules:**

1. **Parser:** `->` followed by `ident is Type` in fn return position is a
   type guard return.
2. **Inference:** At call site, when `if (guard(x))`, the type of `x` inside
   the then-branch is refined to `NarrowedType`. In the else-branch, `x` is
   `T \ NarrowedType`.
3. **Soundness:** The compiler verifies the function body covers all cases
   and returns `true` only when the parameter is provably of the narrowed type.
4. **Assertion mode:** `guard(x)` as a statement (not in `if`) narrows `x`
   unconditionally — the guard must `@panic` internally if the condition fails.
5. **Negation:** `if (!guard(x))` narrows `x` in the else-branch.
6. **Chaining:** `if (isA(x) && isB(x.a))` — narrowing composes between guards.

**Tests:**

```botopink
// slug: typeguard_enum_variant_narrowing
enum Shape { Circle(radius: f64), Square(side: f64) }
fn isCircle(s: Shape) -> s is Shape.Circle {
    return case s { Circle(_) -> true; _ -> false; };
}
fn area(s: Shape) -> f64 {
    if (isCircle(s)) {
        return 3.14 * s.radius * s.radius;  // s: Circle
    };
    return s.side * s.side;  // s: Square (narrowed by else)
}

// slug: typeguard_assertion_mode
fn assertNonEmpty(s: ?string) -> s is string {
    if (s.len > 0) { return true; };
    @panic("empty or null string");
}
fn yell(s: ?string) -> string {
    assertNonEmpty(s);  // assertion mode: s narrowed to string
    return s.toUpper();
}

// slug: typeguard_negation_narrowing
fn isError(r: @Result<i32, string>) -> r is @Result.Err {
    return case r { Err(_) -> true; _ -> false; };
}
fn describe(r: @Result<i32, string>) -> string {
    if (isError(r)) {
        return "error: " + r.e;    // r narrowed to Err(string)
    };
    return "ok: " + r.d;           // r narrowed to Ok(i32)
}
```

---

## Step 3 — Implement parser support for type guards

**Status:** pending
**Assignee:**

Add parsing for `-> ident is Type` in function return position.

**Acceptance criteria:**
- [ ] `fn isX(x: T) -> x is NarrowedType { ... }` parses correctly
- [ ] Parser snapshot tests added
- [ ] `zig build test` passes

### Files to modify

| File | Purpose |
|------|---------|
| `parser/decls.zig` | Parse `-> ident is Type` in fn return type |
| `parser/tests/decls.zig` | Parser tests for type guard syntax |

---

## Step 4 — Implement inference engine narrowing

**Status:** pending
**Assignee:**

Implement all 12 narrowing patterns in the Hindley-Milner inference engine.

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
| `comptime/infer.zig` | Narrowing logic in all control-flow constructs |
| `comptime/env.zig` | Scoped type environments for narrowed branches |
| `parser/decls.zig` | Type guard return type annotation (from Step 3) |

---

## Step 5 — Implement comptime narrowing tests

**Status:** pending
**Assignee:**

Add the 25+ narrowing tests from Section 2 to the comptime test suite in
`modules/compiler-core/src/comptime/tests/`. Each test verifies that the
inference engine correctly narrows types or rejects invalid narrowing.

**Acceptance criteria:**
- [ ] All 25+ narrowing tests pass with `zig build test`
- [ ] Each narrowing pattern has at least one positive test (correct narrowing)
- [ ] Each narrowing pattern has at least one negative test (should error)
- [ ] Snapshot files auto-created

### Files to create/modify

| File | Purpose |
|------|---------|
| `comptime/tests/narrowing.zig` | New test file with all narrowing tests |
| `comptime/tests/AGENTS.md` | Add entry for narrowing.zig |

---

## Step 6 — Implement codegen narrowing tests (all 4 backends)

**Status:** pending
**Assignee:**

For each narrowing pattern, add codegen tests that verify the narrowed value
produces correct runtime output (RUN LOG capture). The comptime tests verify
type inference; the codegen tests verify end-to-end behavior.

Detailed test designs live in `1_0_0_beta.codegen-test-gap.md` (the codegen
test gap spec). This step creates the subset that exercises narrowing
semantics at runtime.

**Acceptance criteria:**
- [ ] At least 8 narrowing codegen tests added
- [ ] Each test runs on all 4 backends (node, erlang, beam, wasm)
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output

### Priority codegen tests

```botopink
// slug: narrow_if_null_with_print
fn main() {
    val x: ?i32 = 42;
    if (x) { n -> @print(n); };           // RUN LOG: 42
}

// slug: narrow_case_enum_area_with_print
enum Shape { Circle(radius: f64), Square(side: f64) }
fn area(s: Shape) -> f64 {
    return case s {
        Circle(r) -> 3.14 * r * r;
        Square(s) -> s * s;
    };
}
fn main() {
    @print(area(Shape.Circle(2.0)));
    @print(area(Shape.Square(3.0)));
}
// expected RUN LOG: 12.56\n9

// slug: narrow_case_result_ok_err_with_print
#[@result]
fn fetch(ok: bool) -> @Result<string, string> {
    if (ok) { return "data"; };
    throw "fail";
}
fn main() {
    val r1 = fetch(true);
    val msg1 = case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg1);
    val r2 = fetch(false);
    val msg2 = case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg2);
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

---

## Summary

| Metric | Count |
|--------|-------|
| Narrowing patterns identified | 13 |
| Positive tests designed | 19 |
| Negative tests designed | 6 |
| Type guard tests designed | 3 |
| Codegen tests prioritized | 4 |

### Key findings

1. **Botopink already has 8 comptime narrowing tests** for null-check, variant
   access, and optional type inference — but coverage is sparse.

2. **No codegen tests exist** for narrowing patterns. The existing comptime
   tests only verify type inference, not runtime behavior.

3. **Critical gaps:** `@Result<D,E>` narrowing with different payload types,
   `@Option<T>` narrowing, early-return guard clause narrowing, type guards,
   and `assert` pattern narrowing have zero tests.

4. **Type guards** (`fn isX(x: T) -> x is NarrowedType`) are the most impactful
   new feature — they enable user-defined narrowing predicates that compose
   with `if`, `else`, negation, and assertion mode.

5. **The `!x` prefix operator** for boolean negation is needed for early-return
   guard clauses (`if (!x) { return; }`). Verify it's supported by the parser
   before writing those tests.

## Notes

- Type narrowing is purely a **comptime/inference** concern — the codegen just
  receives an already-typed AST. Codegen tests are still valuable to verify
  the whole pipeline.
- `case` arm narrowing (fields available only in matched variant) is the most
  complex part of the inference engine.
- Type guard return syntax (`-> param is Type`) requires parser changes before
  inference work can begin on that pattern.

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created — state narrowing + type guards, merged from ts-advanced-types §2.4 | ericfillipe |
