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

A `//` comment inside a `loop` body does not parse today — keep it on the line
above the loop (front 06, parser).

### Assert

<!-- docs-check: body -->
```botopink
val x = 1;
assert x > 0;
assert x > 0, "x must be positive";
```

## Functions

### Parameters with defaults

```botopink
fn greet(name: string, greeting: string = "hello") -> string {
    return greeting + ", " + name + "!";
}
```

The default is **not applied yet**: every call still passes every argument
(`greet("world")` reports `'greet' expects 2 argument(s), got 1`). Front 06
row N1 closes it.

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

Only `External.<Target>` is read. A lower-case `@external(node, …)` matches
nothing: the function is left without a host and nothing says so.

## Builtins

```botopink
fn greet() {
    @print("hello");
}

fn notReady() -> i32 { @todo(); }
```

Other builtins (`@panic`, `@field`, `@emit`, …) are declared in
`libs/std/src/builtins.d.bp` and `libs/std/src/builtins_fns.d.bp`.

## Tests

```botopink
test "addition works" {
    assert 1 + 1 == 2;
}
```

Test blocks are declared at module level. Run with `botopink test`
(`--target`, `--filter <substring>`).

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
else `root.bp`). `dependencies` also accepts an array of bare names.

## Decided, not yet implemented

These are settled language rules that the compiler does not accept yet. They
are listed so nothing here reads as working code; each names the front that
closes it.

| Rule | Today | Closes with |
|---|---|---|
| Union types (`i32 \| string`) | not parsed | 06 N20 |
| The `unknown` type | `unknown` parses as an ordinary type name, with none of its assignability rules | 06 N19 |
| `x is i32` testing a value by range, narrowing inside the block | not parsed | 06 N21 |
| `case` arms written `Pattern { … }`, and `when (…)` guards | arms are `pattern -> value;` — a final `_` arm already works | 06 N22 |
| `break <value>` making the loop an expression | the loop's value is a **list** holding it | 06 N12 |
| Inclusive range patterns `1...9` (`..` stays iteration) | not parsed | 06 N22 |
| `val assert Ok(value) = parse("42") catch 0` binding `value` | the pattern's bindings stay unbound (`unbound variable 'value'`) | 06 N11 |
| `val assert <pattern> = <expr>;` with no `catch` (a failed match is fatal) | refused — write the `catch` form. At this commit the parser still aborts on it; 06 replaces that with `error[assert-pattern-missing-catch]` | 06 N25 |
| `assert x is Some(n)` | not parsed | 06 N11 |
| A parameter default being applied at a call | every argument is required | 06 N1 |
| `Self<T>` required in a generic type or behavior | bare `Self` accepted | 06 N18 |
| A `//` comment inside a `loop` body | not parsed | 06 (parser) |
