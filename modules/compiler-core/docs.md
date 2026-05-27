# compiler-core — architecture & pipeline

> Path: `modules/compiler-core/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md) · Language ref: [`../../docs.md`](../../docs.md)

Detailed architectural reference for the main Zig library — lexer, parser,
AST, type inference, comptime, codegen and formatter. Imported as the
`botopink` module by `compiler-cli` and `language-server`.

## Tree

```text
compiler-core/
├── build.zig            ← build graph (`zig build [run|test]`)
├── build.zig.zon        ← deps (stdlib)
├── src/                 ← all compiler stages — see src/docs.md
└── snapshots/           ← all .snap.md test fixtures
    ├── parser/          ← AST snapshots
    ├── codegen/         ← target output (erlang/, node/, errors/)
    └── comptime/        ← inference + evaluation snapshots
```

## Full pipeline

```text
source → lexer → parser → AST → infer (HM) → comptime transform → codegen → target
                                                      ↘ format.zig (formatter)
                                                      ↘ print.zig  (diagnostics)
```

| Stage | Owner | Output |
|---|---|---|
| **Lex** | `src/lexer.zig` (+ `src/lexer/token.zig`) | `[]Token` |
| **Parse** | `src/parser.zig` | untyped `Program` (AST) |
| **Infer (HM)** | `src/comptime/infer.zig` | `[]TypedBinding`, full type env |
| **Transform** | `src/comptime/transform.zig` (`Aggregator`) | specialized + rewritten typed AST |
| **Codegen** | `src/codegen/<target>.zig` | target source (`.js`, `.erl`, `.d.ts`) |
| **Format (side branch)** | `src/format.zig` | normalized, round-trip-stable `.bp` |
| **Diagnostics (side branch)** | `src/print.zig` | rustc-style caret messages |

## Public API entry points

| API | File | What it returns |
|---|---|---|
| Lexer | `src/lexer.zig` → `src/lexer/token.zig` | `[]Token` |
| Parser | `src/parser.zig` | `Program` (untyped AST) |
| AST types | `src/ast.zig` | `union(enum)` node definitions |
| Type inference + comptime | `src/comptime.zig` (delegates to `comptime/`) | `ComptimeSession`, `compile`, `evaluateComptime` |
| Formatter | `src/format.zig` | normalized source string |
| Diagnostics renderer | `src/print.zig` | rendered error message |
| Codegen façade | `src/codegen.zig` (`compile` / `codegenEmit` / `generate`) | `[]ModuleOutput` |

`src/root.zig` re-exports everything that downstream packages may consume —
treat `@import("botopink").<X>` as the only stable surface.

## AST model (current categories)

`ExprOf(phase)` is organized by expression family. Both untyped and typed
phases share the same shape:

- `literal`, `identifier`
- `binaryOp`, `unaryOp`
- `jump` (`return`, `throw`, `try`, `break`, `yield`, `continue`)
- `branch` (`if`, `tryCatch`)
- `loop`
- `binding`, `call`, `function`, `collection`, `comptime_`

Type annotations always use **`TypeRef`** (`named`, `array`, `tuple_`,
`optional`, `function`). Record/struct/enum/interface shorthand
declarations map to the same AST nodes as the long-form equivalents.

Legacy variants (`controlFlow`, `staticCall`) have been removed — do not
reintroduce them.

## Snapshot testing

| Location | Purpose |
|---|---|
| `snapshots/parser/` | AST golden snapshots (140 files) |
| `snapshots/codegen/{erlang,node,errors}/` | Target outputs + error rendering |
| `snapshots/comptime/{erlang,node}/{,errors/}` | Inference / eval results |

On mismatch the tests write `<name>.snap.md.new`. Review and either promote
(replace the `.snap.md`) or discard (delete + fix the bug). Don't commit
`.snap.md.new` files.

## Conventions specific to compiler-core

- `Parser.init(tokens)` and `Lexer.init(source)` do **not** store an
  allocator — it is always passed as `alloc: std.mem.Allocator` to the method
  that needs it.
- Formatter must be round-trip stable: `format(parse(src))` must re-parse to
  an equivalent AST.
- Pipeline `|>` is left-associative — preserve stable formatting across cycles.
- Codegen is implemented entirely in Zig under `src/codegen/`. There is **no**
  standalone Node.js/WASM compiler.
- Comptime evaluation is target-agnostic; runtime backends live in
  [`src/comptime/runtime/`](src/comptime/runtime/docs.md).

## Where to go next

- Façade structure & stage roles → [`src/docs.md`](src/docs.md).
- Per-target emitters → [`src/codegen/docs.md`](src/codegen/docs.md).
- HM inference + Aggregator → [`src/comptime/docs.md`](src/comptime/docs.md).
- Language syntax (records, enums, pipeline `|>`, numeric literals, …) →
  [`../../docs.md`](../../docs.md).
