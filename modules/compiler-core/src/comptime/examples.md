# Examples — comptime in `.bp`

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Concrete `.bp` snippets showing every place the `comptime` keyword is
accepted. Each example is followed by what the code looks like after the
transform pass has finished (which is what codegen emits).

## Comptime values

```text
val pi: f32  = comptime 3.14159265;
val tau: f32 = comptime 2.0 * 3.14159265;
val days     = comptime 7 * 24;
```

After inlining (what codegen sees):

```text
val pi: f32  = 3.14159265;
val tau: f32 = 6.2831853;
val days     = 168;
```

`comptime` may wrap any pure expression — arithmetic, function calls into
the stdlib, record literal construction, even small loops.

## Comptime arguments

```text
fn pow(comptime n: i32, x: f32) f32 = {
    let mut r: f32 = 1.0;
    let mut i = 0;
    loop {
        if i >= n { break; }
        r = r * x;
        i = i + 1;
    }
    r
}

val a = pow(2, 5.0);     // 25.0
val b = pow(3, 2.0);     // 8.0
```

Each call site with a distinct comptime argument generates a specialised
clone. After the transform pass:

```text
fn pow_$0(x: f32) f32 = x * x;          // n = 2
fn pow_$1(x: f32) f32 = x * x * x;      // n = 3

val a = pow_$0(5.0);
val b = pow_$1(2.0);
```

The original `pow` is dropped (`isFullySpecialized` → true).

## Mixing comptime and runtime args

```text
fn linear(comptime m: f32, comptime b: f32, x: f32) f32 = m * x + b;

val f1 = fn(x) { linear(2.0, 1.0, x) };  // captures specialised closure
val y  = f1(5.0);                        // 11.0
```

After transform:

```text
fn linear_$0(x: f32) f32 = 2.0 * x + 1.0;
val f1 = fn(x) { linear_$0(x) };
val y  = f1(5.0);
```

## Comptime inside record construction

```text
record Config {
    buffer_size: i32,
    name: string,
}

val cfg = Config {
    buffer_size: comptime 64 * 1024,
    name: "default",
};
```

After inlining:

```text
val cfg = Config { buffer_size: 65536, name: "default" };
```

## Reflection builtins (always comptime)

```text
val t = typeOf(42);            // → i32 type at comptime
val n = typeName(some_val);    // → string at comptime
val s = sizeOf(Point);         // → integer at comptime
```

These calls vanish at runtime — the result is folded into the surrounding
literal.

## A complete program

```text
fn pow(comptime n: i32, x: f32) f32 = {
    let mut r: f32 = 1.0;
    let mut i = 0;
    loop {
        if i >= n { break; }
        r = r * x;
        i = i + 1;
    }
    r
}

val cube_of_2 = pow(3, 2.0);
val sq_of_5   = pow(2, 5.0);

fn main() {
    println(cube_of_2.to_string());
    println(sq_of_5.to_string());
}
```

`botopink build` produces output that contains only `pow_$0`, `pow_$1`,
`main`, and the two precomputed call sites. Run `botopink run` to print
`8` then `25`.

## Comptime errors you might see

| Source | Error |
|---|---|
| `val x = comptime read_file("a.txt");` | `comptime expression is impure` |
| `pow(some_runtime_var, x)` | `comptime argument must be statically known` |
| `comptime divide(1, 0)` | `comptime evaluation panicked: division by zero` |
| `val x: i32 = comptime "hello";` | `type mismatch: i32 vs string` |

The diagnostic carries the offending source range and a hint.

## See also

- Comptime architecture (`Aggregator` pass) → [`./docs.md`](docs.md).
- How the inlined literal reaches the target → [`../codegen/examples.md`](../codegen/examples.md).
- Full language reference → [`../../../../docs.md`](../../../../docs.md).
