# Botopink language reference

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

Leaf modules are single files; folder modules use a `mod.bp` entry point.
`pub mod` is visible through the parent; a plain `mod` is private to its
declaring module's subtree. Only `pub` declarations are visible outside their
module.

### Imports

```botopink
import {dict, queue, order} from "std";   // stdlib modules
import {area} from "geometry";             // module in this package
import {name} from "shapes.circle";        // nested module path
import {of, erika} from "erika";           // library dependency
```

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

### Record

```botopink
record Point { x: i32, y: i32 }

val p = Point(x: 1, y: 2);
val px = p.x;
```

Records can carry methods:

```botopink
record Counter {
    n: i32,
    fn current(self: Self) -> i32 {
        return self.n;
    }
}
```

Anonymous records bind to a `val`:

```botopink
val Inner = record { value: i32 }
```

### Enum

```botopink
enum Color { Red, Green, Blue }

enum Shape {
    Circle(radius: f64),
    Square(side: f64),
}
```

### Interface

```botopink
interface Printable {
    fn print(self: Self),
}

record Person { name: string }

implement Printable for Person {
    fn print(self: Self) {
        @print(self.name);
    }
}
```

### Generics

```botopink
fn identity<T>(x: T) -> T { return x; }

enum Tree<T> {
    Leaf(value: T),
    Node(left: Tree<T>, right: Tree<T>),
}
```

Built-in generic types carry an `@` prefix: `@Result<D, E>`, `@Iterator<T>`,
`@Future<T>`, `@Expr<T>`. Optionals are `?T`; tuples are `#(A, B)`.

## Expressions

### Literals

```botopink
42             // i32
3.14           // f64
"hello"        // string
"hi ${name}!"  // string interpolation
true, false    // bool
```

### Arrays

```botopink
val xs = [1, 2, 3];
val tail = xs.slice(1, xs.length);    // [2, 3]
```

### Operators

```botopink
a + b, a - b, a * b, a / b, a % b     // arithmetic (+ also concatenates strings)
a == b, a != b, a < b, a > b, a <= b, a >= b
!x, x && y, x || y                    // logical
a |> f                                // pipe: f(a)
x?.field                              // optional chaining
```

### Lambdas and method chains

```botopink
val double = { n -> n * 2 };

val total = xs
    .filter({ n -> n % 2 == 0 })
    .map({ n -> n * 2 })
    .fold(0, { acc, n -> acc + n });
```

The pipe operator `|>` is left-associative.

### If / else

```botopink
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
fn area(shape: Shape) -> f64 {
    return case shape {
        Circle(radius) -> radius * radius * 3.14;
        Square(side) -> side * side;
    };
}
```

List and or-patterns:

```botopink
case items {
    [] -> "empty";
    [x] -> "one";
    [first, ..rest] -> "many";
}

case c {
    Red | Green -> true;
    Blue -> false;
}
```

### Loop

`loop` iterates a collection or a range; `break` exits with a value.

```botopink
loop (xs) { item ->
    @print(item);
};

loop (0..10) { i ->
    @print(i);
};
```

### Assert

```botopink
assert x > 0;
assert x > 0, "x must be positive";
assert x is Some(n);                                   // narrows x
val assert Ok(value) = result catch throw Error("not ok");
```

## Functions

### Parameters with defaults

```botopink
fn greet(name: string, greeting: string = "hello") -> string {
    return greeting + ", " + name + "!";
}
```

### Results

A `#[@result]` function returns `@Result<D, E>`; `throw` produces the error,
`try … catch` unwraps it.

```botopink
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";
    }
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
    return @expr(record { port: 8000 + t.length, debug: true });
}
```

### Host bindings

```botopink
#[@External.Node("./helpers.mjs", "parse"),
  @External.Erlang("helpers", "parse")]
pub declare fn parse(input: string) -> i32;
```

## Builtins

```botopink
@print("hello");
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
