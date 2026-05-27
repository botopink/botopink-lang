# compiler-core/src — façade structure & stage interplay

> Path: `modules/compiler-core/src/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md)

Each top-level `*.zig` file in this directory is a **façade**: it exposes a
small public surface and delegates the heavy lifting to a sibling
subdirectory of the same name. This document explains the façade pattern,
the inter-stage pipeline, and the conventions that hold everything together.

## Tree

```text
src/
├── root.zig         ← public library entry (re-exports)
├── main.zig         ← minimal CLI stub used by `zig build run`
├── test_root.zig    ← aggregates all test files
├── module.zig       ← `Module` struct — input module representation
├── ast.zig          ← AST node types (categorised)
├── lexer.zig        ← Lexer façade        → lexer/
├── parser.zig       ← Parser              → parser/ (tests)
├── format.zig       ← Wadler-Lindig fmt   → format/ (tests)
├── print.zig        ← rustc-style errors
├── comptime.zig     ← target-agnostic comptime façade → comptime/
├── codegen.zig      ← public codegen API  → codegen/
├── codegen/         ← per-target emitters
├── comptime/        ← HM + transform
│   └── runtime/     ← external eval scripts (Node + Erlang)
├── lexer/           ← Token + lexer tests
├── parser/          ← parser snapshot tests
├── format/          ← formatter snapshot tests
└── utils/           ← snapshot helpers (shared with LSP tests)
```

## The façade pattern

A typical façade looks like this:

```zig
// src/codegen.zig — public surface
pub fn compile(alloc, modules, io, config) !ComptimeSession { … }
pub fn codegenEmit(alloc, outputs, config) ![]ModuleOutput { … }
pub fn generate(alloc, modules, io, config) ![]ModuleOutput {
    var session = try compile(alloc, modules, io, config);
    defer session.deinit();
    return codegenEmit(alloc, session.outputs, config);
}

// src/codegen/commonJS.zig — implementation
// (1600+ lines, called only via codegen.zig)
```

Façade benefits:

1. Downstream packages (`compiler-cli`, `language-server`) import a stable
   `botopink` module and never reach into internals.
2. Subdirectory implementations can be reorganised freely without breaking
   callers.
3. Each façade is small enough to read top-to-bottom; deep details live
   beside the implementation.

## Pipeline at this level

```text
lex ──► parse ──► infer ──► transform (Aggregator) ──► codegen
                                  ↘ AST is rewritten in place:
                                    specialized fns injected,
                                    comptime args dropped,
                                    comptime vals inlined,
                                    dead originals filtered
```

1. **Lex / parse** — source → typed AST scaffolding.
2. **Infer** — Hindley–Milner type inference (`comptime/infer.zig`).
3. **Transform** — `comptime/transform.zig` `Aggregator` scans for comptime
   calls, generates specialized `FnDecl` nodes, rewrites callees to mangled
   names, removes comptime args, inlines comptime vals, drops dead
   originals. Deep walk-through:
   [`comptime/docs.md`](comptime/docs.md) and
   [`comptime/examples.md`](comptime/examples.md).
4. **Codegen** — `codegen/commonJS.zig` or `codegen/erlang.zig`: blind emit
   from the transformed AST. See
   [`codegen/docs.md`](codegen/docs.md).

## Conventions specific to this directory

- **Allocator pattern**: never store `allocator` as a struct field. Always
  pass it as `alloc: std.mem.Allocator` to the method that needs it.
  Emitters (internal) may keep an `alloc` field but it must arrive via
  `init`.
- **Parser helpers** worth knowing about:
  - `boxExpr(alloc, expr)` — heap-allocate an `Expr` pointer.
  - `parseStmtListInBraces(alloc)` — parse `{ stmt; … }` blocks.
  - `parseCommaSeparatedIdentifiers(alloc, stopAt)`.
  - `reportReservedWordError()` — centralised reserved-word error.
- **Type annotations** always use `TypeRef` (`named`, `array`, `tuple_`,
  `optional`, `function`).
- **Formatter** must round-trip: `format(parse(src))` must re-parse to an
  equivalent AST, and a second `format` pass must produce identical text.

## Current-release highlights (v0.0.13-beta)

- Pipeline `|>` (`ExprKind.pipeline`) — left-associative.
- Anonymous function expression `fn(params) { body }` (`ExprKind.fnExpr`).
- Parenthesised expression (`ExprKind.grouped`).
- `CaseArm.emptyLineBefore` preserves blank lines between arms.
- `ArrayLit.trailingComma` forces multi-line array formatting.
- `Param.typeRef` replaces raw `typeName: []const u8`.
- Lexer: `1_000_000` digit separators, scientific notation, unary `-` in
  primary.

## See also

- Public API + AST model overview → [`../docs.md`](../docs.md).
- Per-stage deep dives → the `docs.md` in each subdirectory.
