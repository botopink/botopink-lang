# Examples — `botopink format` before / after

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Side-by-side `.bp` snippets showing what `botopink format` normalises.
Use these to learn the canonical style — anything outside this set will be
rewritten when you run the formatter.

## Records — no `val` prefix on fields

Before:

```text
record Point {
    val x : f32 ,
    val y : f32 ,
}
```

After:

```text
record Point {
    x: f32,
    y: f32,
}
```

Same rule for `struct`. The `val` keyword is for bindings; fields drop it.

## Enum — single-line when no methods

Before:

```text
enum Color {
    Red ,
    Green ,
    Blue ,
}
```

After:

```text
enum Color { Red, Green, Blue, }
```

With variant payloads:

```text
enum Shape {
    Circle(f32),
    Rect(f32, f32),
}
```

Stays multi-line when any variant carries data.

## Interface — `fn`-prefixed methods

Before:

```text
interface Stringer {
    to_string(): string,
}
```

After:

```text
interface Stringer {
    fn to_string(): string,
}
```

## Pipeline — one `|>` per line for long chains

Before (single line, > 80 cols):

```text
val r = [1,2,3] |> filter(fn(x) { x > 1 }) |> map(fn(x) { x * 2 }) |> sum();
```

After:

```text
val r =
    [1, 2, 3]
    |> filter(fn(x) { x > 1 })
    |> map(fn(x) { x * 2 })
    |> sum();
```

Short pipelines stay inline:

```text
val r = xs |> sum();
```

## Array literals — trailing comma forces multi-line

Without trailing comma (inline):

```text
val xs = [1, 2, 3, 4];
```

With trailing comma (multi-line):

```text
val xs = [
    1,
    2,
    3,
    4,
];
```

Use the trailing-comma form when diffs need to read clearly (one entry per
line).

## Case arms — blank lines preserved

Source:

```text
case shape {
    Circle(r)   -> 3.14 * r * r,

    Rect(w, h)  -> w * h,
    Point       -> 0.0,
}
```

After format — the blank line between `Circle` and `Rect` is preserved
(via `CaseArm.emptyLineBefore`):

```text
case shape {
    Circle(r)   -> 3.14 * r * r,

    Rect(w, h)  -> w * h,
    Point       -> 0.0,
}
```

## Round-trip stability

`format(parse(src))` must re-parse to the same AST, and running `format`
twice must produce identical text. Any "the formatter changed my code on
the second run" is a bug — file an issue.

## CI integration

```bash
botopink format --check
```

Exits non-zero on any unformatted file. Use this in CI to enforce
consistent style without churn.

## See also

- Formatter design notes → [`./docs.md`](docs.md).
- Syntax forms the formatter operates on → [`../parser/examples.md`](../parser/examples.md).
- Full language reference → [`../../../../docs.md`](../../../../docs.md).
