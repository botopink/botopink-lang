# compiler-core/src/format — formatter reference

> Path: `modules/compiler-core/src/format/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)

The Wadler-Lindig pretty-printer lives at [`../format.zig`](../format.zig).
This directory hosts the snapshot tests that lock down its output.

## Tree

```text
format/
└── tests.zig     ← round-trip snapshot tests
```

## Round-trip contract

The formatter has two non-negotiable rules:

1. **AST-preserving** — `parse(format(parse(src)))` must equal `parse(src)`.
   A formatter that changes meaning is a bug, not a style preference.
2. **Idempotent** — `format(format(src)) == format(src)`. Running the
   formatter twice in CI must produce zero diffs.

Both rules are enforced by tests in this directory. If you change a
formatting rule, update the affected snapshots (look for
`.snap.md.new` after `zig build test`).

## Algorithm

Wadler-Lindig pretty printing in a few sentences:

- The AST is first turned into a `Document` tree of `text`, `nest`, `line`,
  `group`, `concat`.
- The renderer then chooses, for each `group`, whether to keep it on one
  line or break it across lines, based on the configured column width.
- This is exactly the algorithm popularised by Haskell's `Text.PrettyPrint`
  — there is nothing botopink-specific about the core layout engine.

## Formatting rules (current release)

| Construct | Rule |
|---|---|
| Record fields | No `val` prefix → `record { name: Type, ... }` |
| Struct fields | No `val` prefix → `struct { name: Type, ... }` |
| Enum variants | Comma-separated; single-line when no methods → `enum { Red, Rgb(r,g,b), }` |
| Interface methods | `fn`-prefixed → `interface { fn method(p): T, }` |
| Pipeline `\|>` | Each `\|>` on its own line for long chains |
| Array literals | Trailing comma → multi-line; otherwise inline |
| Case arms | Preserve `emptyLineBefore` as extra blank line |

Concrete before/after pairs: [`./examples.md`](examples.md).

## Driving the formatter

| Surface | What it does |
|---|---|
| `botopink format` | Format every `.bp` in `src/` in place |
| `botopink format --check` | Diff vs. formatted output; exit non-zero on any difference |
| `botopink.format.format(alloc, ast)` | Library entry — returns the formatted source string |

## Adding a formatting rule

1. Edit `../format.zig` — typically a new arm in the `Document` builder.
2. Add a before/after snapshot under `../../snapshots/parser/` (the
   formatter shares the parser test directory, since the contract is
   parser-round-trip).
3. Update [`./examples.md`](examples.md) so users learn the new style.

## See also

- Round-trip pairs the formatter against → [`../parser/docs.md`](../parser/docs.md).
- Examples → [`./examples.md`](examples.md).
- Full language reference → [`../../../../docs.md`](../../../../docs.md).
