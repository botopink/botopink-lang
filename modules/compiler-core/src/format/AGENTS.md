# compiler-core/src/format

> Path: `modules/compiler-core/src/format/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Formatter tests. The Wadler-Lindig pretty-printer itself is at `../format.zig`.

## Tree

```text
format/
├── AGENTS.md     ← you are here
├── tests.zig     ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/        ← format tests, split by feature
    ├── helpers.zig      ← shared harness (`assertFormat`/`assertFormatAs`/`assertIdempotent`)
    ├── imports.zig      ← import formatting
    ├── declarations.zig ← val/const/let, type/behavior/implement/extend, the 1.0.3 separator rule, fn/pub fn, test blocks, empty lines
    ├── expressions.zig  ← binary/call/access/lambda/precedence/pipeline/tagged calls
    ├── literals.zig     ← list/tuple/array/float/int/string literals
    ├── patterns.zig     ← case / pattern / assert
    ├── comments.zig     ← comments / doc / todo
    └── idempotent.zig   ← idempotent round-trips
```

## Round-trip contract

`format(parse(src))` must produce output that re-parses to an equivalent AST,
and running `format` twice in a row must produce identical text.

## Formatting rules

| Construct | Rule |
|---|---|
| Declarations | Only the 1.0.3 surface is printed, whatever the source spelled (`record`/`enum`/`interface` included): `type`, `behavior`; no `;` after them |
| Record (`type`) | Field list in parentheses, no `val` → `type Point(x: i32, y: i32)`; compact without a trailing comma (even past the width), open one field per line with the trailing comma when the source had one or a field carries a `//` comment; field annotations and defaults inline; no body when there are no methods; ` implement B` after the field list |
| Enum (`type`) | `type Color { Red, Rgb(r: i32, g: i32, b: i32) }` compact; open (one item per line, trailing comma added) with a trailing comma, a section or a method; a blank line before the first method |
| Behavior | `behavior Name<G> extends B { … }`; `val x: T;`, bodyless `fn …;`, `default fn … { }`; a blank line between the field, signature and default-method groups; `{}` when empty |
| Pipeline `\|>` | A single step with no comments stays inline if it fits; multi-step chains (or any step comment) put each `\|>` on its own line |
| Array / list literals | Trailing comma or comments → multi-line; otherwise inline if it fits |
| Blank lines | `emptyLinesBefore` on statements and case arms is preserved as blank lines |
| Test blocks | `test { … }` / `test "name" { … }` — no trailing semicolon, body formatted like a `fn` body |
