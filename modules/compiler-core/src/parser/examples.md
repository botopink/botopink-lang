# Examples — `.bp` syntax (declarations, expressions, statements)

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Canonical `.bp` snippets covering every grammar form the parser accepts.
Use them as a quick reference for "what does X look like in botopink".

## Top-level declarations

### `val` binding

```text
val pi = 3.14;
val greeting: string = "hello";
val numbers: Array<i32> = [1, 2, 3];
```

### `fn` declaration

```text
fn add(a: i32, b: i32) i32 = a + b;

fn greet(name: string) {
    println("hello, " + name);
}

fn divmod(a: i32, b: i32) (i32, i32) = (a / b, a % b);
```

### `record`

```text
record Point {
    x: f32,
    y: f32,
}

val origin = Point { x: 0.0, y: 0.0 };
```

### `struct` (mutable-by-design alternative to record)

```text
struct Counter {
    count: i32,
}
```

### `enum`

```text
enum Color { Red, Green, Blue }

enum Shape {
    Circle(f32),
    Rect(f32, f32),
    Point,
}
```

### `interface`

```text
interface Stringer {
    fn to_string(): string,
}
```

### `use` import

```text
use std.{print, println};
use my.module.Counter;
```

### `test` block (anonymous / named)

```text
test {
    assert 1 + 1 == 2;
}

test "addition works" {
    val r = 2 + 3;
    assert r == 5, "sum should be five";
}
```

Top-level only — `test` inside a `fn` body is a parse error. The optional
string literal names the test; the body is a normal statement block.

## Expressions

### Literals & identifiers

```text
42
3.14
"hello"
true
some_variable
```

### Arithmetic & comparison

```text
a + b * c
(x + y) / 2
a == b && c != d
```

### Function call

```text
greet("world")
Point { x: 1.0, y: 2.0 }
arr.length()
```

### Optional chaining `?.`

```text
user?.name           // identAccess with optional = true
name?.to_upper()     // method-call link with optional = true
```

`?.` (token `questionDot`) short-circuits to null when the receiver is
null/absent. Only the member and method-call link forms exist; `?.[i]` /
`?.(args)` are reserved (no base index syntax yet).

### Pipeline `|>` (left-associative)

```text
[1, 2, 3]
    |> filter(fn(x) { x > 1 })
    |> map(fn(x) { x * 2 })
    |> sum()
```

Equivalent without pipeline:

```text
sum(map(filter([1, 2, 3], fn(x) { x > 1 }), fn(x) { x * 2 }))
```

### Anonymous function

```text
val double = fn(x: i32) i32 { x * 2 };
val incr   = fn(x) { x + 1 };       // type inferred
```

### Parenthesised grouping

```text
val r = (a + b) * c;
val pair = (1, "two");              // also tuple literal
```

### `if` expression

```text
val abs = if x < 0 { -x } else { x };
```

### `case` (pattern match)

```text
case shape {
    Circle(r)    -> 3.14 * r * r,
    Rect(w, h)   -> w * h,
    Point        -> 0.0,
}
```

### `try` / `catch`

```text
val v = try parse(s) catch err {
    println("bad input: " + err.message);
    0
};
```

## Statements (inside blocks)

```text
fn f() {
    val x = 1;          // val binding
    let mut y = 2;      // mutable binding
    y = y + x;          // assignment
    return y;           // explicit return
}
```

`loop` / `break` / `continue`:

```text
fn count_to(n: i32) {
    let mut i = 0;
    loop {
        if i >= n { break; }
        i = i + 1;
    }
}
```

## Async, generators & iterators (`*fn`, `await`, `yield`, `loop await`)

`*fn` marks a function whose return implements `@Future<_>` (async) or
`@Iterator<_>` / `@AsyncIterator<_, _>` (generator). It sets `FnDecl.isStarFn`;
`await`/`yield` then follow from the return type.

```text
*fn fetch(url: string) -> @Future<Response> {   // async function
    val body = await download(url);             // await → jump.await_
    return body;
}

*fn fib() -> @Iterator<Int> :gen {              // labelled generator
    yield :gen 1;                               // yield with label
    yield 1;                                    // yield without label
}

pub *fn stream() -> @AsyncIterator<Int, Error> {  // async generator
    yield 1;
}

val producer = *fn(n) { yield n; };             // anonymous *fn expression

fn consume(items: Int[]) {
    loop await (items) { item ->                // loop await → LoopExpr.awaitLoop
        handle(item);
    }
    loop :acc (items) { item ->                 // labelled loop
        yield :acc item;
    }
}
```

A `*fn` must have a body (it is sugar, not a declaration); a bodyless `*fn`
is a parse error.

## Type annotations always use `TypeRef`

```text
val n: i32 = 0;
val xs: Array<i32> = [1, 2];
val opt: ?string = none;             // optional
val result: @Result<i32, ParseError> = parse(); // result type
val pair: (i32, string) = (1, "x");  // tuple
val cb: fn(i32) i32 = double;        // function type
```

## Comptime

```text
val tau: f32 = comptime 2.0 * 3.14159265;

fn scale(comptime factor: f32, x: f32) f32 = x * factor;
val a = scale(2.0, 5.0);   // specialised at compile time
```

Deeper comptime patterns: [`../comptime/examples.md`](../comptime/examples.md).

## Expr templates (meta-kinds, interpolation, tagged calls, `@Expr`)

```text
val greeting = "hello ${name}!";          // ${…} interpolation (string template)

val block =                               // `\\` line string (Zig style):
    \\<div>                                //   lines join with newlines;
    \\  <p>${name}</p>                     //   same conventions as """…"""
    \\</div>
;

fn parse(comptime T: type string | int, raw: string) -> T;   // `type` meta-kind

pub fn html(comptime template: @Expr<string>) -> @Expr<string> { // builtin type
    return template;                      // an @Expr param IS an expr value
}

fn answer() -> @Expr<i32> {               // write the bound when you know it
    return @expr(42);                     // explicit construction (builtin call)
}

fn conf<T>() -> @Expr<T> {                // generic — type revealed at expansion
    return @code("8080");                 // (when the signature cannot state it)
}

val page = html """
<p>${name}</p>
""";                                      // tagged call — html("""…""")
```

- `type` is a contextual meta-kind keyword in type position (`comptime`
  modifier required). `@Expr<E>` is an ordinary **builtin generic type** and
  always carries its parameter (a type only the expansion knows is a fn
  generic: `fn yaml<T>(…) -> @Expr<T>`) — there is no `expr` keyword; code
  values are constructed only via the `@expr(value)` / `@code(text)`
  builtins and the `Expr<E>` interface methods (`build`, `ref`).
- Inside string literals the `${…}` hole stays in the string token and the
  parser re-scans it (`stringTemplate` parts).
- A string literal immediately after an identifier / `a.b` access is a
  tagged call (`is_tagged` flag on the call node).

## Complete file

```text
use std.{println};

record Point { x: f32, y: f32 }

fn distance(a: Point, b: Point) f32 = {
    val dx = a.x - b.x;
    val dy = a.y - b.y;
    sqrt(dx * dx + dy * dy)
}

fn main() {
    val p = Point { x: 0.0, y: 0.0 };
    val q = Point { x: 3.0, y: 4.0 };
    println("distance = " + distance(p, q).to_string());
}
```

## See also

- Parser design → [`./docs.md`](docs.md).
- Tokens that compose these forms → [`../lexer/examples.md`](../lexer/examples.md).
- Full language reference → [`../../../../docs.md`](../../../../docs.md).
