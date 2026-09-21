# Botopink language reference

This reference describes the language as the compiler accepts it today. Every
`botopink` fence here is compiled by `zig build test-docs`; the two that are
tables rather than modules say so in a `docs-check` comment.

## Syntax changes

A type is declared with `type` and a contract with `behavior`; `record`, `enum`
and `interface` are gone, and so are `auto`, `derive`, `get`, `macro`,
`opaque`, `private`, `set`, `new` and `delegate` — all of them are ordinary
identifiers now. An anonymous group of values is a tuple, `#(…)`, which
replaces the old anonymous record. Repetition is `loop` only; `while` reports
an error naming `loop (condition)`. A host template numbers its parameters
positionally (`$0`, `$1`, …).

The move from the previous surface, declaration by declaration, is in
[`MIGRATION.md`](https://github.com/botopink/projects/blob/feat/specs/1.0.4-beta/MIGRATION.md).

## Program structure

A Botopink program is a sequence of declarations — bindings, functions, types,
imports, and module declarations. Execution starts at `fn main()`.

```botopink
// hello.bp
fn main() {
    @print("hello, botopink");
}
```

### Modules

Projects use an explicit, Rust-style module tree. The root module (`main.bp`
for a binary, `root.bp` for a library) declares which submodules to include;
the compiler follows these declarations instead of compiling every `.bp` it
finds.

<!-- docs-check: project modules src/main.bp -->
```botopink
// src/main.bp
import {area} from "geometry";
import {describe} from "shapes";

pub mod geometry;    // resolves src/geometry.bp
pub mod shapes;      // resolves src/shapes/mod.bp

fn main() {
    @print(area(3, 4));    // 12
    @print(describe());    // circle
}
```

<!-- docs-check: project modules src/geometry.bp -->
```botopink
// src/geometry.bp
pub fn area(w: i32, h: i32) -> i32 {
    return w * h;
}
```

<!-- docs-check: project modules src/shapes/mod.bp -->
```botopink
// src/shapes/mod.bp
pub fn describe() -> string {
    return "circle";
}
```

Leaf modules are single files; folder modules use a `mod.bp` entry point.
`pub mod` is visible through the parent; a plain `mod` is private to its
declaring module's subtree. Only `pub` declarations are visible outside their
module.

### Imports

An import either names the module it reads from, or names nothing and resolves
the sibling module that exports the names. Both forms are the language.

<!-- docs-check: project imports src/main.bp -->
```botopink
// src/main.bp
import {math} from "std";              // a stdlib module
import {area} from "geometry";         // a module of this package, named
import {name} from "shapes.circle";    // a nested module path
import {perimeter};                    // the shorthand — the sibling that exports it

pub mod geometry;
pub mod shapes;

fn main() {
    @print(area(3, 4));             // 12
    @print(name());                 // circle
    @print(perimeter(3, 4));        // 14
    @print(math.abs(0.0 - 1.0));    // 1
}
```

<!-- docs-check: project imports src/geometry.bp -->
```botopink
// src/geometry.bp
pub fn area(w: i32, h: i32) -> i32 {
    return w * h;
}

pub fn perimeter(w: i32, h: i32) -> i32 {
    return (w + h) * 2;
}
```

<!-- docs-check: project imports src/shapes/mod.bp -->
```botopink
// src/shapes/mod.bp
pub mod circle;
```

<!-- docs-check: project imports src/shapes/circle.bp -->
```botopink
// src/shapes/circle.bp
pub fn name() -> string {
    return "circle";
}
```

A library is imported the same way, under the name `botopink.json` declares it
in `dependencies`:

<!-- docs-check: skip a library dependency needs that library declared in `dependencies`; the docs harness builds a scratch project with none -->
```botopink
import {of, erika} from "erika";   // a library dependency
```

A `from` that names neither a module of this package, nor a declared
dependency, nor `std` is an error — it is reported where it is written, rather
than binding nothing in silence.

## Bindings

### val — immutable binding

```botopink
val x = 42;
val greeting = "hello";
```

Types are inferred via Hindley-Milner unification. Explicit annotations are
optional:

```botopink
val count: i32 = 42;
val names: string[] = ["alice", "bob"];
```

### var — mutable binding

<!-- docs-check: body -->
```botopink
var n = 0;
n = n + 1;
```

### fn — function

```botopink
fn add(x: i32, y: i32) -> i32 {
    return x + y;
}
```

## Types

### Primitives

`i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `string`, `bool`, `void`.
Their methods are declared in `libs/std/src/primitives.bp`.

### type — records

A `type` whose fields are written in parentheses is a record: the declaration
mirrors construction.

```botopink
type Point(x: i32, y: i32)

val p = Point(x: 1, y: 2);
val px = p.x;
```

A body adds methods:

```botopink
type Counter(n: i32) {
    fn current(self: Self) -> i32 {
        return self.n;
    }
}
```

An anonymous group of values is a tuple, not a type declaration. A tuple is
positional at run time; a label is a compile-time name, lent by the variable
used to build it or written in the type:

```botopink
fn box() -> #(value: i32) {
    val value = 1;
    return #(value);    // the variable lends the label
}

fn read() -> i32 {
    val inner = box();
    return inner.value;    // same element as inner.0
}
```

### type — enums

A `type` whose body lists variants is an enum:

```botopink
type Color { Red, Green, Blue }

type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

fn main() {
    val c = Color.Red;
    val s = Shape.Circle(radius: 2.0);
    @print(case c { Red -> "red"; _ -> "other"; });
    @print(case s { Circle(r) -> r; Square(side) -> side; });    // 2
}
```

A variant is built through its type — `Color.Red`, `Shape.Circle(radius: 2.0)`;
inside a `case` pattern the bare name is enough. A bare `Red` in expression
position type-checks but no backend lowers it (the generated program reports an
unbound `Red` at run time), so always write the qualified form.

### behavior

```botopink
behavior Printable {
    fn print(self: Self);
}

type Person(name: string) implement Printable {
    fn print(self: Self) {
        @print(self.name);
    }
}
```

### Generics

```botopink
fn identity<T>(x: T) -> T { return x; }

type Tree<T> {
    Leaf(value: T),
    Node(left: Tree<T>, right: Tree<T>),
}
```

Built-in generic types carry an `@` prefix: `@Result<D, E>`, `@Iterator<T>`,
`@Future<T>`, `@Expr<T>`. Optionals are `?T`; tuples are `#(A, B)`.

### Union types, `unknown`, and `is`

A union type is written `A | B`. `unknown` holds any value and, unlike a union,
cannot be used as another type until it has been tested — `val b: i32 = a;` on an
`unknown` reports "an `unknown` value cannot be used as another type without
testing it". `x is <Type>` answers a `bool` and narrows `x` inside the branch it
guards.

```botopink
fn describe(x: i32 | string) -> string {
    if (x is i32) {
        return "an integer";
    };
    return "a string";
}

fn read(raw: unknown) -> string {
    if (raw is string) {
        return raw;
    };
    return "not a string";
}
```

`is` tests a type; it does not bind. Read a variant's payload in a `case` arm
(`Circle(radius) -> …`, below) and an optional with `if (x) { n -> … }`;
`assert x is Some(v)` is a located error.

## Expressions

### Literals

<!-- docs-check: skip a table of literal forms, not a module -->
```botopink
42             // i32
3.14           // f64
"hello"        // string
"hi ${name}!"  // string interpolation
true, false    // bool
```

### Arrays

<!-- docs-check: body -->
```botopink
val xs = [1, 2, 3];
val tail = xs.slice(1, xs.length);    // [2, 3]
```

### Operators

<!-- docs-check: skip an operator table, not a module -->
```botopink
a + b, a - b, a * b, a / b, a % b     // arithmetic (+ also concatenates strings)
a == b, a != b, a < b, a > b, a <= b, a >= b
!x, x && y, x || y                    // logical
a |> f                                // pipe: f(a)
x?.field                              // optional chaining
```

### Lambdas and method chains

<!-- docs-check: body -->
```botopink
val double = { n -> n * 2 };
val xs = [1, 2, 3, 4];

val total = xs
    .filter({ n -> n % 2 == 0 })
    .map({ n -> n * 2 })
    .fold(0, { acc, n -> acc + n });    // 12
```

The pipe operator `|>` is left-associative.

### If / else

<!-- docs-check: body -->
```botopink
val x = 1;
val s = if (x > 0) { "positive" } else { "negative" };
```

`if` on an optional unwraps it in the then-branch:

```botopink
fn show(x: ?i32) {
    if (x) { n -> @print(n); };
}
```

### Case (pattern matching)

```botopink
type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

fn area(shape: Shape) -> f64 {
    return case shape {
        Circle(radius) -> radius * radius * 3.14;
        Square(side) -> side * side;
    };
}
```

List and or-patterns:

```botopink
type Color { Red, Green, Blue }

fn warm(c: Color) -> bool {
    return case c {
        Red | Green -> true;
        Blue -> false;
    };
}

fn size(items: i32[]) -> string {
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

A section of an enum is itself a type, written by its path, so a function can
take one section instead of the whole enum:

```botopink
type Token {
    Text { Bold, Italic },
    Hover(inner: Token[]),
}

fn textToCss(t: Token.Text) -> string {
    return case t {
        Bold -> "font-weight:bold";
        Italic -> "font-style:italic";
    };
}
```

An arm may also be written as a block, `<pattern> { … }`. A block arm takes an
optional `when (…)` guard, and a pattern may be a literal, a type (`i32`) or `_`.

```botopink
fn grade(n: i32) {
    case n {
        i32 when (n > 100) { @print("impossible"); }
        0 { @print("zero"); }
        _ { @print("something else"); }
    };
}
```

A range in a pattern is `..`, exclusive, exactly as in a loop. The compiler is
behind that rule and still asks for `...` — see
[Decided, not yet implemented](#decided-not-yet-implemented).

A name alone is not a pattern: to give the matched value a name, bind it in the
body (`_ { n -> … }`).

### Loop

`loop` is the only repetition form. It takes a collection, a range or a
condition, or nothing at all; `break` leaves it.

A range excludes its end: `0..10` yields `0` to `9`.

<!-- docs-check: body -->
```botopink
val xs = [1, 2, 3];

loop (xs) { item ->
    @print(item);
};

loop (0..10) { i ->
    @print(i);
};

var n = 0;
loop (n < 3) {
    n = n + 1;
};

loop {
    n = n - 1;
    if (n == 0) { break; };
};
```

A `//` comment inside a `loop` body parses like any other comment.

### Assert

<!-- docs-check: body -->
```botopink
val x = 1;
assert x > 0;
assert x > 0, "x must be positive";
```

`val assert <pattern> = <expr>;` binds the pattern's names and is **fatal** when
the match fails, so the names below the binding are never unbound. It takes no
`catch` — `try … catch` is the form that supplies a fallback.

```botopink
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";
    };
    return 42;
}

fn load() {
    val assert Ok(n) = parse("42");
    @print(n);
}
```

### use — imports, activation, and hooks

One keyword, two roles: a **declaration** (the import list and the extension
activation) and an **expression prefix** (the hook activation). Grammar:

<!-- docs-check: skip a grammar, not a module -->
```
ImportItem     := DottedName "*"? ("as" Ident)?   // in `import { … } from "…"`
ActivationStmt := DottedName "*" ";"              // module level only
UseExpr        := "use" Expr                      // prefix; the operand is a call
```

**Declaration role.** `import { name* } from "…"` opts an imported `implement`
/ `extend` into scope (see *Imports*). The bare statement `Name*;` at module
level names a local symbol, and is refused either way: an extension declared in
the module is applied on its own — `` `Name*` is redundant: an extension declared
in this module is auto-applied; `*` is only for imports `` (`redundantActivation`)
— and anything else is `'Name' does not name an implement/extend symbol`
(`notAnExtension`).

**Expression role.** A **hook** is a function whose return type is
`@Context<Owner, R>`: `Owner` is the type the hook is anchored to, `R` is what it
yields. A hook is named by its noun, without a `use` prefix (`state`, `effect`,
`router`, `pathname` — never `useState`), because the keyword *is* the
activation. `val x = use <hook>(…)` activates the hook and binds `R`; a bare
`use <hook>(…);` activates a void hook; `val {a, b} = use …` binds `R`'s fields
by name. The activating body is a `#[@context]` function whose return type is
the owner — a **component**, `#[@context] fn Widget() -> Element`, where
`Element` is a type that `implement @Context<Element, Element>` — or is itself
`@Context<Owner, _>` — a **custom hook** composing hooks. A body that carries a
**wrapper effect** instead (`#[@future]` today) and whose return type *unwraps*
to the owner activates too, with no second annotation: `@Future<T>` is looked
through to `T`, so `#[@future] fn Page() -> @Future<Element>` is owned by
`Element` (and one fn carries one effect annotation — `#[@future] #[@context]`
is `effect-duplicate-annotation`). Every `use` in one body agrees on the one
`Owner` its return type names.

```botopink
type Element(count: i32) implement @Context<Element, Element>
type State(value: i32, name: string) implement @Context<Element, State>

// A hook: the noun, the owner, the yield. No annotation — its body activates nothing.
fn state(initial: i32) -> @Context<Element, State> {
    return State(value: initial, name: "state");
}

// A custom hook composes hooks: `#[@context]`, and a return that is `@Context<Element, _>`.
#[@context]
fn counter(start: i32) -> @Context<Element, State> {
    val s = use state(start * 2);
    return s;
}

// A component: `#[@context]`, and a return that is the owner type.
#[@context]
fn Widget(n: i32) -> Element {
    val c = use state(n);
    val {value, name} = use counter(n);
    return Element(count: c.value + value);
}

// A wrapper effect activates on its own: `@Future<Element>` unwraps to the owner.
#[@future]
fn Page() -> @Future<Element> {
    val c = use state(1);
    return Element(count: c.value);
}

// Without `use` the same call is an ordinary call — the first-render value.
fn Plain() -> Element {
    val c = state(7);
    return Element(count: c.value);
}
```

The rules, each with its diagnostic:

- **The body needs an effect.** A `use` in a body that carries **no** effect
  annotation is refused at the `use`: when the return type implements
  `@Context` (the owner type, or the `@Context<…>` wrapper) the message names
  the annotation — `` use-without-context-effect: `use` needs `#[@context]` on
  the enclosing fn 'Widget': its return type 'Element' implements @Context, but
  a body with no effect annotation does not activate a hook `` — and a bare
  `fn … -> Element` without it is an ordinary function. When the return type
  does not implement `@Context` at all (`-> string`, `-> void`, a module-level
  `val`) it is `` use-of-non-context-fn: `use` not allowed: function returns
  'string' which does not implement @Context ``. `#[@context]` itself accepts
  either return shape: `-> @Context<B, R>` or a named type implementing
  `@Context<B, _>`.
- **A wrapper effect is enough when its return owns the context.** The
  dispensation above is the return type answering the question the annotation
  would have: `#[@future] fn Page() -> @Future<Element>` activates, because
  `@Future<Element>` unwraps to the owner. It switches no refusal off —
  `#[@future] fn … -> @Future<i32>` with a `use` is still
  `` use-of-non-context-fn: `use` not allowed ``, and `#[@context]` over a
  return type that owns no context is still
  `` effect-wrapper-mismatch: `#[@context]` requires a `-> @Context<…>` return
  type ``.
- **The operand is a hook.** `use plain()` where `plain : -> User` is
  `` use-of-non-context-fn: `use` requires @Context: 'User' does not implement
  @Context ``.
- **One owner per body.** `use connection()` with `connection : ->
  @Context<Http, _>` inside a body owned by `Element` is
  `` context-anchor-violation: function returns @Context<Element, _> but `use`
  returns @Context<Http, _> ``.
- **The static prefix.** Every `use` of a function body comes before its first
  `if`, `case`, `loop` or `return`, at any nesting: `val c = use …` after a
  `return`, and a `use` inside an `if`'s own block, are both parse errors —
  `` `use` must be in static prefix `` with the hint `Move all `use` statements
  to the top of the function body, before any `if`, `case`, `loop`, or
  `return``. A lambda body is another function: its own prefix starts over, so
  `use memo({ -> return count * 2; })` keeps the enclosing prefix intact.
- **The type is `R`.** `val c = use state(0)` binds `c : State`. A tuple `R`
  destructures positionally, `val #(a, b) = use pair()`, but its element types
  are not propagated yet — each name is a fresh type variable (front 19 step 3).
- **`use` never leaves a function body.** There is no module-level `use` and no
  `use client;` / `use server;` directive (decision 87 of 1.0.10-beta): a
  framework's boundary markers are its own decorators (`#[client]`).

**Lowering.** `use f(x)` is `f(x)` on every backend (decision 88). The prefix is
the activation the checker validated, not a rename: nothing is turned into
`useState`, no dependency array is inferred — a hook that takes one declares it
as a parameter (`memo(compute, deps)`). A client runtime supplies hook semantics
through what `f` does; the pure body above is what every backend runs, and what
the server renders.

**The provider side.** `#[@context]` is also the effect under which
`@getContex(T)` reads the active provider of `T` on the same owner tree; a
provider stack is not part of this section.

## Functions

`use` and `#[@context]` (hooks and components) are under *Expressions › use*.

### Parameters with defaults

```botopink
fn greet(name: string, greeting: string = "hello") -> string {
    return greeting + ", " + name + "!";
}
```

The default is **not applied yet**: every call still passes every argument
(`greet("world")` reports `'greet' expects 2 argument(s), got 1`). 1.0.5-beta
front `01-checker` step 7 closes it.

### Results

A `#[@result]` function returns `@Result<D, E>`; `throw` produces the error,
`try … catch` unwraps it.

```botopink
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";
    };
    return 0;
}

fn load() {
    val n = try parse("42") catch 0;
    val ok = parse("42").isOk();
}
```

### Iterators

```botopink
#[@iterator]
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
```

## Comptime

### Compile-time evaluation

```botopink
val result = comptime {
    val x = 10;
    break x * 2;
};
```

### Template functions

A function taking `comptime q: @Expr<…>` expands at the call site; `@expr`
lifts a comptime value back into code.

```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val port = 8000 + t.length;
    val debug = true;
    return @expr(#(port, debug));    // the labels come from the variable names
}
```

### Host bindings

```botopink
#[@External.Node("./helpers.mjs", "parse"),
  @External.Erlang("helpers", "parse")]
pub declare fn parse(input: string) -> i32;
```

A binding may also be a template, where `$0`, `$1`, … are the declared
parameters — on a method, `self` is `$0`:

```botopink
#[@External.Node("$0.toUpperCase()"),
  @External.Erlang("string:uppercase($0)")]
pub declare fn shout(text: string) -> string;
```

Only `External.<Target>` is read. A lower-case `@external(node, …)` is a located
error naming the capitalised form (`` `#[@external]` binds no host — an external
target is written `External.<Target>` ``), rather than a function left silently
without a host.

A relative path (`"./helpers.mjs"`, `"helpers"` on erlang) names a **sidecar** the
library keeps beside its sources, in `<src>/sidecars/` or `<src>/`. `botopink
build` and `botopink test` copy it next to the emitted module, from the
directory the dependency resolved to — so it ships the same whether the library
is a workspace member, a `{ "path": … }` package outside every library root, or
one of two checkouts declaring the name. A sidecar the build cannot ship is a
located error on the `dependencies` entry that named the library, never a
silent exit 0. See [`docs/botopink-json.md`](./docs/botopink-json.md) § Host
sidecars.

## Builtins

```botopink
fn greet() {
    @print("hello");
}

fn notReady() -> i32 { @todo(); }
```

Other builtins (`@panic`, `@field`, `@emit`, …) are declared in
`libs/std/src/builtins.d.bp` and `libs/std/src/builtins_fns.d.bp`. Builtin
names are exact: an unrecognised `@name(…)` is `error[unknown-builtin]`
(with the nearest name when one is an edit away), never a silent `void`.

### `@src()` and `SourceLocation`

```botopink
// A builtin record every module sees:
//   type SourceLocation(file: string, line: i32, column: i32, fnName: string)

fn where() -> SourceLocation {
    return @src();
}

test "src: a test knows its own name" {
    val loc = @src();
    @print(loc.file, loc.line, loc.column, loc.fnName);
    // src/example.bp 10 15 src: a test knows its own name
}
```

`@src()` is the place it is written, evaluated at compile time: the four
fields are literals at the call site and the expression costs nothing at run
time — every backend emits the same code it emits for the constructor call
`SourceLocation(file: "…", line: N, column: C, fnName: "…")`.

| Field | Value |
|---|---|
| `file` | the source file relative to the root of its package, forward slashes, with extension (`src/emilia.bp`, `test/color_test.bp`) |
| `line`, `column` | 1-based position of the `@` — the numbers a diagnostic prints |
| `fnName` | the enclosing `fn`'s name; `Type.method` inside a method; the test name inside `test "…" { }` (`test_<idx>` for an anonymous block); `""` at module level. A lambda does not change it |

`@src()` takes no arguments and no trailing lambda (`@src(1)` is
`error[src-takes-no-arguments]`). It is a value like any other: `@src().line`
reads a field in place. Its consumer is the test contract — `std/asserts`
messages and `std/snapshots` paths are computed from the caller's `@src()`.

## Tests

```botopink
test "addition works" {
    assert 1 + 1 == 2;
}
```

Test blocks are declared at module level. Run with `botopink test`
(`--target`, `--filter <substring>`).

A test body is a **fallible context**: a `try` whose operand is an `Error(e)`
ends the test as `FAIL <name>  (<e>)  at <file>:<line>` — `e` is the message
(a non-string `e` is rendered) and the `at` is the test's own line. The
statements after the failed `try` do not run; a `try` inside a lambda is the
lambda's, not the test's. An assertion helper is therefore an ordinary
`#[@result] fn … -> @Result<void, string>` whose `ok` position is the empty
`return;`:

```botopink
#[@result]
fn isPositive(n: i32) -> @Result<void, string> {
    if (n <= 0) { throw "asserts.isPositive: value not positive"; };
    return;
}

test "t: a propagated error fails the test" {
    try isPositive(-1);     // FAIL t: a propagated error fails the test  (asserts.isPositive: value not positive)  at src/main.bp:12
}
```

### Mocks

`std/mocks` is the Mockito-style double: `when(...)` stubs a return, the
matchers `eq` / `anyInt` / `anyString` pick which call a stub answers, and
`verify(mock, spec)` checks how many matching calls were recorded. It is the
old `onze` library, retired into std (1.0.10-beta front 01-std, decision 71).
commonJS and erlang only — its cells are `pub declare fn` with a Node and an
Erlang template each, so `import {mocks} from "std"` is refused on beam and
wasm, where `botopink test` does not run.

```botopink
import {mocks} from "std";

behavior UserRepo {
    fn find(self: Self, id: i32) -> string;
}

// The double: every method funnels through `mocks.invoke`, which records the
// call and answers the matching stub value or the type-default.
type MockUserRepo(__id: string) implement UserRepo {
    fn find(self: Self, id: i32) -> string {
        return mocks.invoke(self.__id, "find", [mocks.key(id)], "");
    }
}

fn mockUserRepo() -> UserRepo { return MockUserRepo(__id: mocks.newMock()); }

test "repo: eq(v) stubs only the matching argument" {
    val repo = mockUserRepo();
    val _s = mocks.when(repo.find(mocks.eq(7))).thenReturn("ana");
    assert repo.find(7) == "ana";
    assert repo.find(8) == "";
    val _v = mocks.verify(repo, mocks.times(2)).find(mocks.anyInt());
}
```

`#[mock]` writes that double for you — it reflects the annotated `behavior`'s
methods through `@Decl` and `@emit`s the type plus a `mock<Name>()` factory.
**It fires inside the module that declares it only.** `@emit` splices its text
into the module that hosts the annotated behavior, and the text names the
runtime bare (`invoke`, `key`, `newMock`), which resolves in `std/mocks` and
nowhere else: a `from "std"` import binds the module handle (`mocks`), never
its functions, and `#[mocks.mock]` is not looked up as a decorator at all. So a
consumer writes the double by hand, as above. Recorded in
`specs/1.0.10-beta/01-std/onze-migration.md` § *Language gaps*.

Two more limits carried over from the old library: a matched `thenThrow` is a
host throw, not an `@Result`, so the caller catches it with `asserts.throws`
and not with `try … catch`; and there is no generic `any<T>()` matcher, because
it would need a per-type default it cannot synthesize.

## Backends

| Target     | Output | Runner                      |
|------------|--------|-----------------------------|
| `commonJS` | `.js`  | `node` ≥ 20                 |
| `erlang`   | `.erl` | `escript` (OTP)             |
| `beam`     | `.S`   | artifact — `erlc +from_asm` |
| `wasm`     | `.wat` | `wasmtime`                  |

Select the target with `--target`:

```bash
botopink run --target commonJS
botopink build --target erlang
```

## Project manifest

Every project carries a `botopink.json` at its root:

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "target": "commonJS",
  "dependencies": {
    "erika": { "git": "https://github.com/botopink/erika.git", "branch": "feat" }
  }
}
```

Optional `entry` names the module-tree root under `src/` (default: `main.bp`,
else `root.bp`). `dependencies` is an object — one entry per import name, each
with exactly one source: `{ "path": "…" }`, `{ "git": "…", "branch"|"tag"|"rev":
"…" }` or `{ "workspace": true }` (the sibling member of the enclosing
workspace). A manifest with `"workspaces": ["modules/*", "examples/*"]` is a
workspace: it declares members and is not a package. Every field, both forms
and every refusal are in [`docs/botopink-json.md`](docs/botopink-json.md).

## Decided, not yet implemented

These are settled language rules that the compiler does not accept yet. They
are listed so nothing here reads as working code; each names the front that
closes it, or says that it has none yet. Every row below was re-derived by
**running** the form, not by reading the previous revision of this table.

| Rule | Today | Closes with |
|---|---|---|
| `break <value>` making the loop an expression | the loop's value is a **list** holding it: `val v = loop (0..10) { i -> if (i == 3) { break i; }; };` prints `[3]` on commonJS, on erlang and on wasm alike | 1.0.5-beta — three backends answer the same way, so the row is the rule's rather than one backend's; `01-checker` assigns the two commonJS suite lines to `04-js` |
| A parameter default being applied at a call | every argument is required — `greet("world")` on `fn greet(name: string, greeting: string = "hello")` reports `'greet' expects 2 argument(s), got 1` | 1.0.5-beta `01-checker` step 7 |
| `Self<T>` required in a generic type or behavior | bare `Self` is accepted inside a generic declaration; `Self<T>` parses and then fails to check (`type mismatch: expected Self, got Holder`) | 1.0.5-beta `01-checker` step 6 |
| A block-shaped statement ends itself: no `;` after the closing brace of an `if`, `loop` or `case` in statement position | the `;` is required — dropping it reports `this token cannot appear here` at the **next** statement, with the "may be missing its `;`" hint. Every fence above therefore writes it | 1.0.5-beta `15-language-surface` step 2, with `16-formatter` (the formatter has to stop printing it in the same wave) |
| A pattern range written `..` and exclusive, as in a loop — `...` leaves the grammar | inverted: `1..9` in an arm reds `error[pattern-range-exclusive]` ("write `...` — an inclusive range, both ends matched"), and `1...9` is accepted. As a value it answers something different on every backend: `case 9 { 1...9 { 1 } _ { 0 } }` prints `1` on commonJS, `0` on erlang and `256` on wasm | 1.0.5-beta — owner unassigned; the rule is decided (the `...` token, the diagnostic and the run-time semantics) |

Six of the twelve rows this table carried before this revision left it because
the compiler now accepts the form: union types, the `unknown` type and its
assignability rule, `x is <Type>` with narrowing, `case` arms written
`Pattern { … }` with `when (…)` guards, `val assert <pattern> = <expr>;`
(binding its names, and fatal when the match fails), and a `//` comment inside a
`loop` body. Each is documented above, in the section that teaches the form.

Two more left it because the form is **deliberately absent**, so that neither
reads as unfinished work:

| Form | What the compiler says |
|---|---|
| `assert x is Some(n)` — `is` binding a payload | `error[is-variant-binding]`: `is` tests a type; it does not bind. Read the payload in a `case` arm |
| `val assert Ok(v) = parse("42") catch 0` | ``a `val assert` over a `@Result` takes no `catch` `` — the match is fatal, and `try … catch` is the form that supplies a fallback |
