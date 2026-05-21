# compiler-core/src/format

> Path: `modules/compiler-core/src/format/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Formatter tests. The Wadler-Lindig pretty-printer itself is at `../format.zig`.

## Tree

```text
format/
├── AGENTS.md     ← you are here
└── tests.zig     ← round-trip snapshot tests
```

## Round-trip contract

`format(parse(src))` must produce output that re-parses to an equivalent AST,
and running `format` twice in a row must produce identical text.

## Formatting rules (current release)

| Construct | Rule |
|---|---|
| Record fields | No `val` prefix → `record { name: Type, ... }` |
| Struct fields | No `val` prefix → `struct { name: Type, ... }` |
| Enum variants | Comma-separated; single-line when no methods → `enum { Red, Rgb(r,g,b), }` |
| Interface methods | `fn`-prefixed → `interface { fn method(p): T, }` |
| Pipeline `\|>` | Each `\|>` on its own line for long chains |
| Array literals | trailing comma → multi-line; otherwise inline |
| Case arms | preserve `emptyLineBefore` as extra blank line |
