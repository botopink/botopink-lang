# compiler-core/src/parser — parser reference

> Path: `modules/compiler-core/src/parser/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)

The `Parser` struct (state, token cursor, shared block/annotation/param helpers)
lives at `../parser.zig`; the recursive-descent grammar is split into sibling
modules here by sub-grammar (`types`/`patterns`/`decls`/`exprs`), each a set of
free functions on `*Parser` re-exported by `parser.zig` as thin `pub const`
aliases (see [`./AGENTS.md`](AGENTS.md) for the convention). This directory also
holds the test harness; snapshots live at
[`../../snapshots/parser/`](../../snapshots/parser/AGENTS.md).

## Tree

```text
parser/
├── types.zig      ← type-ref sub-grammar
├── patterns.zig   ← case/pattern sub-grammar
├── decls.zig      ← declaration sub-grammar (+ params)
├── exprs.zig      ← expression sub-grammar (precedence climbing)
└── tests.zig      ← `assertParser` / `expectParseError` snapshot tests
```

## Strategy: hand-written recursive descent

There is no parser generator. Each grammar rule is a function on `*Parser`,
named after the rule. Rules called as `this.parseX(alloc)` resolve whether they
live in `parser.zig` or in a sub-grammar module (`types`/`patterns`/`decls`/
`exprs`) — the latter are re-exported as `pub const parseX = exprs.parseX;`
aliases, so call sites don't care where a rule lives:

- `parse` → top-level decls (in `parser.zig`)
- decl rules (`parseFnDecl`/`parseRecordDecl`/`parseEnumDecl`/…) → `decls.zig`
- `parseExpr` / `parsePrimary` → expression entry & primaries → `exprs.zig`
- `parseCaseExpr` / `parsePattern` → `patterns.zig`
- `parseTypeRef` → `types.zig`

Precedence is encoded in `exprs.zig`'s `precedence_table` (driven by the
precedence-climbing `parseBinaryExpr`); the named entry points `prec.lowest` /
`prec.equality` stay public on `Parser` for callers in other sub-grammars. To
add a new operator, add a row to `precedence_table` at the correct level.

## Helper functions

| Helper | What it does |
|---|---|
| `boxExpr(alloc, expr)` | Heap-allocates an `Expr` and returns the pointer. Used wherever an `*Expr` field is needed. |
| `parseStmtListInBraces(alloc)` | Parses `{ stmt; stmt; … }`. Used by `if`, `loop`, function bodies. |
| `parseCommaSeparatedIdentifiers(alloc, stopAt)` | Parses `a, b, c` up to `stopAt`. Used by destructuring patterns. |
| `reportReservedWordError()` | Centralised error when a reserved word is used as an identifier. Keeps the message uniform across constructs. |

## Allocator contract

```zig
var p = Parser.init(tokens);
const program = try p.parseProgram(alloc);
```

`Parser.init(tokens)` does **not** store an allocator. Every parse method
takes `alloc: std.mem.Allocator` so the caller controls the AST's lifetime
(typically an arena).

## AST construction

- All nodes are `union(enum)` (see [`../ast.zig`](../ast.zig)).
- Heap-allocated branches must be `deinit(alloc)`'d on error paths.
- Type annotations always go through `TypeRef` — never a raw
  `typeName: []const u8`.
- Records, structs, enums, and interfaces with **shorthand** syntax share
  the same AST nodes as the long-form declarations. Parsing differs;
  representation does not.

## Error reporting

`expectParseError(source, "expected message")` is the canonical pattern for
locking down a diagnostic. When changing an error message you must update
both the test and any user-facing copy.

For positional/caret rendering see `../print.zig` — the parser produces a
structured `ParseError` and `print` turns it into a rustc-style message.

## Testing pattern

```zig
test "use decl" {
    try assertParser(std.testing.allocator, @src(), "use std.{print}");
}
```

The first run creates `../../snapshots/parser/<slug>.snap.md`; subsequent
runs compare. On mismatch a `.snap.md.new` is written next to the original.

Concrete examples and walk-throughs: [`./examples.md`](examples.md).

## See also

- Lexer (token stream consumed by the parser) →
  [`../lexer/docs.md`](../lexer/docs.md).
- Snapshot fixtures → [`../../snapshots/parser/AGENTS.md`](../../snapshots/parser/AGENTS.md).
- Formatter must consume the AST round-trippably →
  [`../format/docs.md`](../format/docs.md).
