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

## Type annotations always use `TypeRef`

```text
val n: i32 = 0;
val xs: Array<i32> = [1, 2];
val opt: ?string = none;             // optional
val result: i32!ParseError = parse(); // error union
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
