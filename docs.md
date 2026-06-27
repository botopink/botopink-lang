# Botopink language reference

> Version: v0.0.13-beta

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

Projects use an explicit, Rust-style module tree. The root module (`main.bp`)
declares which submodules to include; the compiler follows these declarations
instead of compiling every `.bp` it finds.

```botopink
// src/main.bp
pub mod geometry;    // resolves src/geometry.bp
pub mod shapes;      // resolves src/shapes/mod.bp

import {area} from "geometry";
import {describe} from "shapes";

fn main() {
    @print(area(3, 4));    // 12
    @print(describe());     // circle
}
```

Leaf modules are single files; folder modules use a `mod.bp` entry point. Only
`pub` declarations are visible outside their module.

### Imports

```botopink
import {dict, queue, order} from "std";   // stdlib
import {area} from "geometry";             // sibling module
import {of, erika} from "erika";           // disk dependency
```

## Bindings

### val — immutable binding

```botopink
val x = 42;
val greeting = "hello";
val Point = record { x: i32, y: i32 };
```

Types are inferred via Hindley-Milner unification. Explicit annotations are
optional:

```botopink
val count: i32 = 42;
val names: Array<string> = ["alice", "bob"];
```

### var — mutable binding

```botopink
var n = 0;
n = n + 1;
```

### fn — function

```botopink
fn add(x: i32, y: i32) -> i32 {
    return x + y;
}

// Inferred return type
fn double(x: i32) { return x * 2; }

// Nested functions use `return` to exit the enclosing `fn`
fn outer() {
    fn inner() { return 42; }
    @print(inner());  // 42
}
```

## Types

### Primitives

`i32`, `i64`, `f64`, `string`, `bool`, `void`

### Record

```botopink
record Point { x: i32, y: i32 }

val p = Point(x: 1, y: 2);
val px = p.x;                       // field access
```

Records can have methods:

```botopink
record Point {
    x: i32,
    y: i32,

    fn magnitude(self: Self) -> f64 { ... }
}
```

### Enum

```botopink
enum Color { Red, Green, Blue }

val c = Color.Red;
```

Enum variants can carry payloads:

```botopink
enum Option<T> { None, Some(T) }
```

### Interface

```botopink
interface Show {
    fn show(self: Self) -> string;
}

implement Show for Point {
    fn show(self: Self) -> string {
        return "(" ++ self.x ++ ", " ++ self.y ++ ")";
    }
}
```

### Generics

```botopink
record Pair<A, B> { first: A, second: B }

fn identity<T>(x: T) -> T { return x; }

enum Option<T> { None, Some(T) }
enum @Result<D, E> { Ok(D), Error(E) }
```

Built-in generic types use `@Result`, `@Iterator`, `@Future`. User-defined
generics use angle brackets: `MyType<T>`.

### Type aliases

```botopink
val Age = record { years: i32 };
```

## Expressions

### Literals

```botopink
42             // i32
3.14           // f64
"hello"        // string
true, false    // bool
```

### Arrays

```botopink
val xs = [1, 2, 3];
val empty: Array<i32> = [];
val tail = xs.slice(1, xs.length);    // [2, 3]
```

### Operators

```botopink
a + b, a - b, a * b, a / b, a % b    // arithmetic
a ++ b                                // string / array concatenation
a == b, a != b, a < b, a > b          // comparison
a <= b, a >= b
!x, x && y, x || y                    // logical
a |> f                                // pipe: f(a)
```

### Pipeline

```botopink
val result = xs
    .filter({ n -> n % 2 == 0 })
    .map({ n -> n * 2 })
    .fold(0, { acc, n -> acc + n });
```

The pipeline operator `|>` is left-associative. A method call `x.f(y)` is
equivalent to `f(x, y)`.

### If / else

```botopink
val s = if (x > 0) { "positive" } else { "negative" };
```

If expressions return values; both branches must unify to the same type.

### Case (pattern matching)

```botopink
case color {
    Color.Red   -> "warm";
    Color.Green -> "calm";
    Color.Blue  -> { val _ = 1; "cool" };   // block arm
}
```

List patterns:

```botopink
case xs {
    []        -> "empty";
    [a, ...b] -> "first: " ++ a;
}
```

Or-patterns:

```botopink
case x {
    0 | 1 -> "small";
    _     -> "other";
}
```

### Loop

```botopink
var i = 0;
loop (i < 5) {
    @print(i);
    i = i + 1;
}
```

### Assert

```botopink
assert x > 0;
assert x > 0, "x must be positive";

// Pattern assertions
assert Ok(v) = result;
```

## Functions

### Parameters with defaults

```botopink
fn greet(name: string, greeting: string = "hello") -> string {
    return greeting ++ ", " ++ name ++ "!";
}
```

### Lambda

```botopink
val double = { n -> n * 2 };
val add = { a, b -> a + b };
```

### Trailing lambda

When the last argument is a lambda, it can be written after the closing paren:

```botopink
xs.filter({ n -> n > 0 });
xs.map({ n -> n * 2 });
```

### Trailing blocks

```botopink
result.map(r, { v ->
    val doubled = v * 2;
    return doubled;
});
```

## Comptime

Comptime evaluates code at compile time, producing values or AST fragments.

### Compile-time evaluation

```botopink
comptime {
    val layout = @print("computed at build time");
}
```

### Template functions

```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val text = q.text();
    return @expr(record {
        server: record { host: "0.0.0.0", port: 8000 + text.length },
        debug: true,
    });
}
```

### Annotations

```botopink
#[@External.Node("./helpers.mjs", "parse")]
pub declare fn parse(input: string) -> i32;

#[@iterator]
fn counter() -> @Iterator<i32> :gen { yield 1; }
```

## Builtins

### @print

```botopink
@print("hello");
@print(42);
```

### @todo

```botopink
fn notReady() -> i32 { @todo(); }
```

### @Result

```botopink
fn parse(s: string) -> @Result<i32, string> {
    return if (s == "") { Error("empty") } else { Ok(42) };
}

val r = parse("42");
r.isOk();                          // result methods
r.unwrapOr(0);
```

### @Expr

```botopink
pub fn lift<T>(comptime v: T) -> @Expr<T> {
    return @expr(v);
}
```

## Tests

```botopink
test "addition works" {
    assert 1 + 1 == 2;
}

test "strings concatenate" {
    assert "a" ++ "b" == "ab";
}
```

Tests blocks are declared at the module level. Run with `botopink test`.

## Backends

| Target     | Output         | Runtime           |
|------------|----------------|-------------------|
| `commonJS` | `.mjs`         | Node.js ≥ 20      |
| `erlang`   | `.erl`         | escript (OTP)     |
| `beam`     | `.beam`        | erlc + escript    |
| `wasm`     | `.wat`/`.wasm` | wasmtime          |

Select the target with `--target`:

```bash
botopink run --target commonJS
botopink run --target wasm
botopink build --target erlang
```

## Project manifest

Every project carries a `botopink.json` at its root:

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "sources": ["src"],
  "dependencies": {
    "disk-lib": { "git": "https://github.com/user/disk-lib", "branch": "main" }
  }
}
```
