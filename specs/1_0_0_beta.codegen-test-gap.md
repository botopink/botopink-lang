# Codegen Test Coverage & Runtime Fixes

**Version:** 1.0.0-beta
**Status:** planning
**Created:** 2026-06-30
**Author:** ericfillipe
**Replaces:** `1_0_0_beta.run-log-audit.md`, `1_0_0_beta.comptime-codegen-coverage.md`

---

## Status

**Current:** planning

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

---

## Step 1 — Audit codegen coverage & runtime health

**Status:** completed
**Assignee:** ericfillipe

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

### 1.5 — Parser features without codegen tests

191 of 208 parser features (91.8%) have zero codegen tests:

| Category | Missing |
|----------|---------|
| Annotations | 9 |
| Imports | 10 |
| Lambdas | 7 |
| Operator precedence | 7 |
| Interface extends | 10 |
| Implement blocks | 7 |
| Record/enum/function shorthand | 18 |
| String interpolation | 5 |
| Other (use hooks, delegates, tagged calls, etc.) | 116 |

---

## Step 2 — Fix runtime crashes (all backends)

**Status:** pending
**Assignee:**

### Cross-cutting (all backends)

1. **try/catch propagation** — `try_propagate_without_catch`, `try_with_inline_catch_handler`, `try_catch_returns_handler_value_on_error`, `try_catch_on_result_with_default_fallback`, `try_propagation_in_result_fn`. The lowering exists but result-unwrapping at runtime is broken across all backends.
2. **Record destructuring in fn params** — `destructure_record_parameter_in_fn`. The generated code crashes on destructure-in-signature + `@print` of bound fields.

### commonJS (13 crashes + 8 limitations)

3. **Fix `.len` → `.length`** — Resolves 6 `undefined` limitations + crashes in string/array `.len` operations. Map `.len` to native `length` property in JS codegen.
4. **`if` without `else`** — Emit ternary `cond ? value : undefined` to avoid `undefined` fallthrough.
5. **String methods dispatch** — `string_methods_map_to_native_js_names`, `string_slice_*` — fix native method name mapping.
6. **Array operations** — `array_slice_2_arg_lowers_byte`, `array_zip_via_external_node_template` — fix lowering.
7. **try/catch, destructure, loop break** — Fix remaining 4 crash sites.

### Erlang (38 crashes)

8. **Template system** — All 6 `template_end_to_end_*` tests fail. The Erlang runtime representation of `@Expr` parts doesn't match what escript expects.
9. **Pipeline operator** — `pipeline_simple_chain`, `pipeline_with_labeled_args` — pipeline `|>` lowering in Erlang doesn't thread arguments correctly.
10. **Instance methods** — `bool_instance_default_fn_methods`, `numeric_instance_methods` — external Erlang functions referenced in annotations aren't compiled into the module.

### BEAM (21 crashes)

11. **try/catch** — BEAM `try`/`catch` block structure doesn't preserve `@Result` unwrapping correctly.
12. **Anonymous record literal** — `anon_record_*` (2 files). BEAM backend explicitly flags these as unsupported; either implement lowering or skip runtime execution.
13. **String `.len` in arithmetic** — `string_len_participates_in_arithmetic`. The tagged integer from `.len` doesn't participate in BEAM arithmetic ops cleanly.

### WASM (48 crashes)

14. **External host functions** — All 8 `external_*` tests crash because WASM modules can't import Node.js functions. **Fix:** skip RUN LOG capture for `external_*` tests on WASM target (WAT lowering is still verified by the source snapshot).
15. **Template system** — All 5 `template_end_to_end_*` tests crash. Templates rely on comptime `@expr` evaluation + runtime string building not available in wasmtime.
16. **Iterator `yield`** — `iterator_fromlist_yields_array_items` crashes. WASM has no coroutine/generator support.
17. **Case/switch on literals** — `case_number_literal_patterns`, `case_string_literal_patterns`, `case_or_patterns_with_numbers` — WASM lowering for case on literals doesn't produce working BR_TABLE or IF chains.
18. **Instance methods** — `bool_instance_default_fn_methods`, `numeric_instance_methods` — instance methods call host functions not available in wasmtime.
19. **Array builtins** — `Array.at`, `.indexOf`, `.join`, `.zip` — lower to external host calls not present in WASM runtime.

### Acceptance criteria

- [ ] All 13 commonJS crashes/limitations fixed or documented as intentional
- [ ] All 38 Erlang crashes fixed or documented
- [ ] All 21 BEAM crashes fixed or documented
- [ ] All 48 WASM crashes fixed or documented (excluding intentional skips)
- [ ] `zig build test` passes
- [ ] Empty RUN LOGs replaced with actual output where fixes applied

### Files to modify

| File | Purpose |
|------|---------|
| `codegen/js.zig` | `.len` fix, `if`-without-`else`, string methods, array ops |
| `codegen/erlang.zig` | Template runtime, pipeline lowering, instance methods |
| `codegen/beam_asm.zig` | try/catch, anon record, string `.len` arithmetic |
| `codegen/wat.zig` | Case/switch lowering, instance method skips |
| `codegen/runtime.zig` | WASM skip logic for external-dependent tests |
| `codegen/tests/features.zig` | Update tests whose RUN LOG changes |

---

## Step 3 — Remove 76 orphaned snapshot files

**Status:** pending
**Assignee:**

76 empty files across all 4 backends (19 per backend), unchanged since initial
commit `0c30a38`. No current test references any of these names. The snapshot
system (`snap.zig`) doesn't auto-delete unused files — remove them manually.

**Acceptance criteria:**
- [ ] All 76 orphaned files deleted from `snapshots/codegen/{node,erlang,beam,wasm}/`
- [ ] `zig build test` passes (orphaned files are never read, so no test impact)
- [ ] No empty directories left behind

---

## Step 4 — Implement codegen tests for optional/null

**Status:** pending
**Assignee:**

8 comptime tests exist. **Zero codegen tests.** Optional types are fundamental
to error handling and API design.

### Test 4.1: `if` null-check binding with `@print`

```botopink
// slug: optional_if_null_check_print
fn greet(x: ?string) -> string {
    if (x) { s -> return "hello " + s; };
    return "nobody";
}
fn main() {
    @print(greet("world"));
    @print(greet(null));
}
// expected RUN LOG: hello world\nnobody
```

### Test 4.2: Nested null-check with record field

```botopink
// slug: optional_nested_null_check_record
record Profile { name: string, bio: ?string }
fn bio(p: Profile) -> string {
    if (p.bio) { b -> return b; };
    return "(no bio)";
}
fn main() {
    @print(bio(Profile(name: "alice", bio: "dev")));
    @print(bio(Profile(name: "bob", bio: null)));
}
// expected RUN LOG: dev\n(no bio)
```

### Test 4.3: Null-check with `else` branch

```botopink
// slug: optional_if_null_else_both_branches
fn describe(x: ?i32) -> string {
    if (x) { n -> return "got " + n; }
    else { return "nothing"; };
}
fn main() {
    @print(describe(42));
    @print(describe(null));
}
// expected RUN LOG: got 42\nnothing
```

### Test 4.4: Optional annotation type

```botopink
// slug: optional_explicit_type_annotation
fn safeDivide(a: i32, b: i32) -> ?i32 {
    if (b == 0) { return null; };
    return a / b;
}
fn main() {
    val r1: ?i32 = safeDivide(10, 2);
    val r2: ?i32 = safeDivide(10, 0);
    if (r1) { v -> @print(v); };
    if (r2) { v -> @print(v); } else { @print("null"); };
}
// expected RUN LOG: 5\nnull
```

### Test 4.5: Optional with string annotation

```botopink
// slug: optional_string_annotation_default
fn maybeName(present: bool) -> ?string {
    if (present) { return "found"; };
    return null;
}
fn main() {
    @print(maybeName(true));
    @print(maybeName(false));
}
// expected RUN LOG: found\n
```

### Test 4.6: Optional chaining across backends

```botopink
// slug: optional_chaining_on_optional_field
record Inner { value: string }
record Outer { inner: ?Inner }
fn main() {
    val o1 = Outer(inner: Inner(value: "hi"));
    val o2 = Outer(inner: null);
    @print(o1.inner?.value);
    @print(o2.inner?.value);
}
// expected RUN LOG: hi\n
```

### Acceptance criteria

- [ ] 6 optional/null codegen tests added to `codegen/tests/values.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output for each test

---

## Step 5 — Implement codegen tests for cross-module imports

**Status:** pending
**Assignee:**

8 comptime tests verify import resolution. **Zero codegen tests.**

### Test 5.1: Import single val

```botopink
// Module: lib.bp
pub val answer = 42;

// Module: main.bp
import {answer} from "lib";
fn main() {
    @print(answer);
}
// expected RUN LOG: 42
```

### Test 5.2: Import multiple vals

```botopink
// Module: math.bp
pub val PI = 3.14;
pub val E = 2.71;

// Module: main.bp
import {PI, E} from "math";
fn main() {
    @print(PI);
    @print(E);
}
// expected RUN LOG: 3.14\n2.71
```

### Test 5.3: Import function

```botopink
// Module: calc.bp
pub fn add(x: i32, y: i32) -> i32 { return x + y; }

// Module: main.bp
import {add} from "calc";
fn main() {
    @print(add(3, 4));
}
// expected RUN LOG: 7
```

### Test 5.4: Import record constructor

```botopink
// Module: point.bp
pub record Point { x: i32, y: i32 }

// Module: main.bp
import {Point} from "point";
fn main() {
    val p = Point(x: 10, y: 20);
    @print(p.x);
}
// expected RUN LOG: 10
```

### Test 5.5: Three-level import chain

```botopink
// Module: a.bp
pub val name = "a";

// Module: b.bp
import {name} from "a";
pub val greeting = "hello " + name;

// Module: main.bp
import {greeting} from "b";
fn main() {
    @print(greeting);
}
// expected RUN LOG: hello a
```

### Acceptance criteria

- [ ] 5 cross-module import codegen tests added to `codegen/tests/features.zig`
- [ ] Each test creates multiple `.bp` files in a temp dir
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output per module

---

## Step 6 — Implement codegen tests for template/@Expr

**Status:** pending
**Assignee:**

11 comptime tests verify `@Expr` template capture. **Zero codegen runtime
tests.** Templates are used for HTML generation, SQL builders, and DSLs.

### Test 6.1: Simple `@Expr` pass-through

```botopink
// slug: template_expr_pass_through_with_print
pub fn identity(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
fn main() {
    val msg = identity "hello";
    @print(msg);
}
// expected RUN LOG: hello
```

### Test 6.2: Template with runtime hole

```botopink
// slug: template_expr_hole_with_runtime_value
pub fn greet(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
fn main() {
    val name = "botopink";
    val msg = greet "hello ${name}!";
    @print(msg);
}
// expected RUN LOG: hello botopink!
```

### Test 6.3: Template parts iteration

```botopink
// slug: template_parts_text_build_end_to_end
pub fn upper(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "";
    loop (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + p.text;
        };
    };
    return @expr(acc);
}
fn main() {
    val msg = upper "hello world";
    @print(msg);
}
// expected RUN LOG: hello world
```

### Test 6.4: Template lookup + ref

```botopink
// slug: template_lookup_ref_splices_caller_scope
val prefix = "[bot] ";
pub fn tagged(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("prefix");
    if (hit) { b -> return @expr(b.ref() + q.text()); };
    return q;
}
fn main() {
    val msg = tagged "message received";
    @print(msg);
}
// expected RUN LOG: [bot] message received
```

### Acceptance criteria

- [ ] 4 template/@Expr codegen tests added to `codegen/tests/comptime.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes
- [ ] RUN LOG captures correct output

---

## Step 7 — Implement codegen tests for interface/implement

**Status:** pending
**Assignee:**

16 comptime tests verify interface checking. **Zero codegen runtime tests.**

### Test 7.1: Interface with method dispatch

```botopink
// slug: interface_method_dispatch_with_print
val Show = interface {
    fn show(self: Self) -> string;
}
record Point { x: i32, y: i32 }
val ShowPoint = implement Show for Point {
    fn show(self: Self) -> string {
        return "(" + self.x + ", " + self.y + ")";
    }
}
fn main() {
    val p = Point(x: 1, y: 2);
    @print(p.show());
    @print(ShowPoint.show(p));
}
// expected RUN LOG: (1, 2)\n(1, 2)
```

### Test 7.2: Interface with field

```botopink
// slug: interface_with_field_and_method
val Identifiable = interface {
    val id: i32,
    fn tag(self: Self) -> string;
}
record User { id: i32, name: string }
val IdUser = implement Identifiable for User {
    fn tag(self: Self) -> string {
        return "#" + self.id + ":" + self.name;
    }
}
fn main() {
    val u = User(id: 1, name: "alice");
    @print(u.id);
    @print(u.tag());
}
// expected RUN LOG: 1\n#1:alice
```

### Test 7.3: Interface with multiple abstract methods

```botopink
// slug: interface_multiple_methods_with_print
val Canvas = interface {
    fn draw(self: Self) -> string;
    fn scale(self: Self, factor: f64) -> string;
}
record Square { size: f64 }
val DrawSquare = implement Canvas for Square {
    fn draw(self: Self) -> string {
        return "square(" + self.size + ")";
    }
    fn scale(self: Self, factor: f64) -> string {
        return "square(" + (self.size * factor) + ")";
    }
}
fn main() {
    val s = Square(size: 10.0);
    @print(s.draw());
    @print(s.scale(2.0));
}
// expected RUN LOG: square(10)\nsquare(20)
```

### Test 7.4: Two interfaces with qualified dispatch

```botopink
// slug: interface_two_impls_qualified_dispatch
val Flyer = interface { fn move(self: Self) -> string; }
val Swimmer = interface { fn move(self: Self) -> string; }
record Duck { name: string }
val DuckFly = implement Flyer for Duck {
    fn move(self: Self) -> string { return self.name + " flies"; }
}
val DuckSwim = implement Swimmer for Duck {
    fn move(self: Self) -> string { return self.name + " swims"; }
}
fn main() {
    val d = Duck(name: "donald");
    @print(DuckFly.move(d));
    @print(DuckSwim.move(d));
}
// expected RUN LOG: donald flies\ndonald swims
```

### Acceptance criteria

- [ ] 4 interface/implement codegen tests added to `codegen/tests/aggregates.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes

---

## Step 8 — Implement codegen tests for generics

**Status:** pending
**Assignee:**

3 comptime tests verify generic types. **Zero codegen runtime tests.**

### Test 8.1: Generic record

```botopink
// slug: generic_record_pair_with_print
record Pair<A, B> { first: A, second: B }
fn swap<A, B>(p: Pair<A, B>) -> Pair<B, A> {
    return Pair(first: p.second, second: p.first);
}
fn main() {
    val p = Pair(first: 1, second: "one");
    val s = swap(p);
    @print(s.first);
    @print(s.second);
}
// expected RUN LOG: one\n1
```

### Test 8.2: Generic identity function

```botopink
// slug: generic_fn_identity_with_print
fn identity<T>(x: T) -> T { return x; }
fn main() {
    @print(identity(42));
    @print(identity("hello"));
}
// expected RUN LOG: 42\nhello
```

### Test 8.3: Generic enum Option

```botopink
// slug: generic_enum_option_with_print
enum @Option<T> { None, Some(T) }
fn describe<T>(opt: @Option<T>) -> string {
    return case opt {
        None -> "nothing";
        Some(v) -> "something";
    };
}
fn main() {
    @print(describe(@Option.Some(42)));
    @print(describe(@Option.None));
}
// expected RUN LOG: something\nnothing
```

### Acceptance criteria

- [ ] 3 generic type codegen tests added to `codegen/tests/values.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes

---

## Step 9 — Implement codegen tests for comptime eval + specialization

**Status:** pending
**Assignee:**

2 comptime tests verify comptime blocks and params. **Zero codegen runtime
tests** across all four backends.

### Test 9.1: Comptime block yields constant

```botopink
// slug: comptime_block_constant_lower_to_literal
val ANSWER = comptime {
    val x = 10;
    val y = 32;
    break x + y;
};
fn main() {
    @print(ANSWER);
}
// expected RUN LOG: 42
```

### Test 9.2: Comptime params with specialization

```botopink
// slug: comptime_param_specialization_with_print
fn repeat(comptime times: i32, msg: string) -> string {
    var acc = "";
    loop (0..times) { _ ->
        acc = acc + msg;
    };
    return acc;
}
fn main() {
    @print(repeat(3, "ha"));
    @print(repeat(2, "ho"));
}
// expected RUN LOG: hahaha\nhoho
```

### Test 9.3: Comptime type-meta specialization

```botopink
// slug: comptime_type_meta_specialization
fn describe<T>(comptime _: T) -> string {
    return "generic";
}
fn main() {
    @print(describe(42));
    @print(describe("text"));
}
// expected RUN LOG: generic\ngeneric
```

### Acceptance criteria

- [ ] 3 comptime eval codegen tests added to `codegen/tests/features.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes

---

## Step 10 — Implement codegen tests for record/enum

**Status:** pending
**Assignee:**

17 record comptime tests (1 codegen), 11 enum comptime tests (1 codegen).

### Test 10.1: Record constructor with field access

```botopink
// slug: record_constructor_field_access
record Book { title: string, pages: i32 }
fn main() {
    val b = Book(title: "Botopink Guide", pages: 200);
    @print(b.title);
    @print(b.pages);
}
// expected RUN LOG: Botopink Guide\n200
```

### Test 10.2: Record method using self fields

```botopink
// slug: record_method_self_field_arithmetic
record Rect { w: f64, h: f64,
    fn area(self: Self) -> f64 {
        return self.w * self.h;
    }
}
fn main() {
    val r = Rect(w: 5.0, h: 3.0);
    @print(r.area());
}
// expected RUN LOG: 15
```

### Test 10.3: Enum constructor with case match

```botopink
// slug: enum_constructor_case_match_with_print
enum Color { Red, Green, Blue }
fn describe(c: Color) -> string {
    return case c {
        Red -> "red";
        Green -> "green";
        Blue -> "blue";
    };
}
fn main() {
    @print(describe(Color.Red));
    @print(describe(Color.Blue));
}
// expected RUN LOG: red\nblue
```

### Test 10.4: Enum payload variant with field access

```botopink
// slug: enum_payload_variant_field_access
enum Shape {
    Circle(radius: f64),
    Square(side: f64),
}
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
```

### Test 10.5: Enum sections with nested variants

```botopink
// slug: enum_sections_nested_variants
enum HttpStatus {
    Success { Ok, Created, NoContent }
    Error { NotFound, ServerError(code: i32) }
}
fn describe(s: HttpStatus) -> string {
    return case s {
        Success_Ok -> "200 OK";
        Success_Created -> "201 Created";
        Error_NotFound -> "404";
        Error_ServerError(code) -> "500 (" + code + ")";
        _ -> "unknown";
    };
}
fn main() {
    @print(describe(HttpStatus.Success.Ok));
    @print(describe(HttpStatus.Error.NotFound));
}
// expected RUN LOG: 200 OK\n404
```

### Test 10.6: Record field update (immutable)

```botopink
// slug: record_field_update_immutable
record Point { x: i32, y: i32 }
fn moveRight(p: Point, dx: i32) -> Point {
    return Point(x: p.x + dx, y: p.y);
}
fn main() {
    val p = Point(x: 1, y: 2);
    val p2 = moveRight(p, 10);
    @print(p2.x);
    @print(p2.y);
}
// expected RUN LOG: 11\n2
```

### Acceptance criteria

- [ ] 6 record/enum codegen tests added to `codegen/tests/aggregates.zig` or `values.zig`
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes

---

## Step 11 — Implement codegen tests for lambda, operators, annotations

**Status:** pending
**Assignee:**

Quick-win tests for high-impact untested features.

### Test 11.1: Lambda as argument

```botopink
// slug: lambda_as_map_argument_with_print
fn map(xs: i32[], f: fn(i32) -> i32) -> i32[] {
    var acc: i32[] = [];
    loop (xs) { x -> acc = acc.push(f(x)); };
    return acc;
}
fn main() {
    val doubled = map([1, 2, 3], { x -> return x * 2; });
    @print(doubled.len);
}
// expected RUN LOG: 3
```

### Test 11.2: Operator precedence

```botopink
// slug: operator_precedence_arithmetic_with_print
fn main() {
    @print(1 + 2 * 3);
    @print(10 - 4 / 2);
}
// expected RUN LOG: 7\n8
```

### Test 11.3: String interpolation edge cases

```botopink
// slug: string_interpolation_escaped_dollar_with_print
fn main() {
    val name = "alice";
    @print("hello \${name}");
    @print("hello ${name}");
}
// expected RUN LOG: hello ${name}\nhello alice
```

### Acceptance criteria

- [ ] 3 additional codegen tests added
- [ ] Each test runs on all 4 backends
- [ ] `zig build test` passes

---

## Summary

| Metric | Count |
|--------|-------|
| Codegen tests designed in this spec | 37 |
| Runtime crashes to fix | 120 (across 4 backends) |
| Known limitations to fix (`undefined` output) | 13 |
| Orphaned files to remove | 76 |
| Total snapshot files | 1,066 (+37 new) |
| Current comptime→codegen coverage | ~10% |
| Target coverage after this spec | ~25% |

### Key findings

1. **Only ~10% of comptime-verified features have codegen runtime tests.** The
   type system is well-tested; the lowering pipeline is not.

2. **120 snapshots have `@print` but empty RUN LOG** — the runtime crashed.
   WASM is worst (48 crashes), Node.js is best (13 crashes). These tests pass
   only because the snapshot matches empty output.

3. **Optional/null, templates, imports, and interface/implement have zero
   codegen tests** — despite being core language features used in nearly every
   real program.

4. **Node.js is the most resilient backend** — 13 crashes vs 21 (BEAM), 38
   (Erlang), 48 (WASM). JS runtime semantics align best with the current
   codegen lowering.

5. **191 parser features (91.8%) have zero codegen tests** — the parser is
   well-tested but the codegen pipeline is narrowly tested.

### Execution order recommendation

1. **Step 3 first** (orphaned file removal) — zero risk, cleans the tree
2. **Step 2** (runtime crash fixes) — fixes existing failing behavior
3. **Steps 4-11** (new codegen tests) — additive, no regression risk
4. Steps 4-11 can run in parallel (they add tests to different categories)

## Notes

- Error-diagnostic comptime tests verify compile-time error messages. They
  intentionally have no codegen test — codegen is never reached for invalid
  programs.
- Some comptime features are tested in the `beam`, `erlang`, `node`, and `wasm`
  subdirectories under `snapshots/comptime/`. These are AST snapshots (verify
  typed-AST structure per backend), not runtime execution tests.
- RUN LOG capture drops stderr to maintain host-independence across dev
  workstations and CI runners.
- WASM backend `external_*` tests should skip RUN LOG capture (WAT lowering is
  still verified by the source snapshot).

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created — merged run-log-audit + comptime-codegen-coverage | ericfillipe |
