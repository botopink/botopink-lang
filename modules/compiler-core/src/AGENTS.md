# compiler-core/src

> Path: `modules/compiler-core/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)

All compiler stages live here. Each top-level `*.zig` is a façade; the
implementation delegates to a sibling directory of the same name.

## Tree

```text
src/
├── AGENTS.md             ← you are here
├── root.zig              ← public library entry (re-exports the public API)
├── main.zig              ← empty CLI stub used by `zig build run`
├── test_root.zig         ← aggregates each stage's tests.zig barrel
├── test_warmup.zig       ← pre-warms the stdlib template env before other tests
├── module.zig            ← `Module` struct — input module representation (`srcPath`: the package-relative display path `@src().file` answers)
├── ast.zig               ← AST node types (categorised)
├── lexer.zig             ← Lexer (delegates to lexer/token.zig)
├── parser.zig            ← Parser struct + token cursor + shared helpers (sub-grammars in parser/)
├── format.zig            ← Wadler-Lindig pretty printer (round-trip stable)
├── print.zig             ← rustc-style diagnostics renderer
├── comptime.zig          ← comptime façade (compile / compileTypesOnly / evaluateComptime)
├── codegen.zig           ← public codegen API
├── codegen/              ← per-target backends — see codegen/AGENTS.md
├── comptime/             ← HM inference + transform + comptime eval — see comptime/AGENTS.md
│   └── runtime/          ← persistent `erl` comptime runtime
├── lexer/                ← Token struct + lexer tests
├── parser/               ← Parser sub-grammars (types/patterns/decls/exprs) + tests
├── format/               ← Formatter tests
└── utils/                ← Snapshot/JSON helpers
```

## Top-level façades

| File | Role |
|---|---|
| `root.zig` | Library entry — re-exports `codegen`, `format`, `print_errors`, `Module`, `comptime_pipeline`, `Lexer`, `Parser`, `ast`, `types`, `CustomNode`/`CustomAstEntry`, … |
| `ast.zig` | All AST node types. Named types are one `TypeDecl` (`shape`: `.record` fields or `.enum_` variants + sections; helpers `isRecord`/`recordFields`/`variants`/`sections`) under `DeclKind.type_`; interfaces are `BehaviorDecl` under `DeclKind.behavior`; record fields and variant payload fields share `Field` (its `comments` are serialized only when present); `TypeRef.labeledTuple` is a `#(name: T, …)` type (`tupleElems()` covers both tuple forms); decision 8's own shapes travel in existing nodes under reserved spellings, each documented where it is defined — `unknown_type_name` (§2, N19), `union_type_name` (§3, N20, with `unionMembers()`), `is_builtin_name` (§4, N21, with the call's `isType`), `index_builtin_name` (decision 30's `xs[0]`, the receiver and the index as its two arguments — a `range` index is `xs[0..2]`), and `nullish_binding_name` (decision 28's `a ?? b`, desugared to `if (a) { <n> -> <n> } else { b }` — the optional binding form, which every backend already lowers), and `Pattern.variant`'s `shape`/`labels`/`rest` (§5, N22). `CallExpr.call.calleeExpr` carries the callee of `adder(3)(4)` as an **expression** (`callee` is then `""` and `receiver` stays null — a chained call is not a method call); it is null on every call written before decision 14 and omitted from the AST dump when null, so a consumer that does not read it lowers exactly the calls it lowered before. `ValDecl.mutable` + `ValDecl.annotations` are front 17's module-level `var` and its `#[@BeamMemory.<member>]` (decision 38; both omitted from the dump when false/empty, so a `val` dumps as before); `Annotation.labels` / `labelOf(i)` keep the label written before an argument (`keyed` in `keyed = true`, `inline` in `inline = true`) beside the positional `args`, dumped only when some argument was labelled |
| `lexer.zig` | Lexer façade → `lexer/token.zig` |
| `parser.zig` | Parser struct + cursor + shared helpers; sub-grammars in [`parser/`](parser/AGENTS.md). `parse` records a located `parseError` for every `UnexpectedToken` it returns (the token it stopped on, when no named rejection filled it). Owns the block-body loop (`parseBlockBody`, `parseStmtListInBraces`, `parseFnBodyInBraces`) and the static-prefix rule of `use` — `useBranchSeen`, `bindingUseLoc`, `tokenAt`, `useAfterBranch` (front 19 of 1.0.10-beta; see `parser/AGENTS.md`) |
| `comptime.zig` | Comptime façade — `ComptimeSession`, `compile`, `compileTypesOnly`, `evaluateComptime`, `registerStdlib` (`registerReflectionPrelude` registers the `@Decl` cluster + `SourceLocation` into the global env AND into the scratch env each std module is inferred in, so a std signature may name a prelude record — `snapshots.path(loc: SourceLocation)`). A module that does not lex or parse is an `Outcome.parseError` carrying a located `SyntaxError` (`.lex` / `.parse`), never a session-wide error |
| `format.zig` | Wadler-Lindig formatter |
| `print.zig` | rustc-style error renderer |
| `codegen.zig` | Public codegen API over the `codegen/` backends: `generateWith(alloc, modules, io, config, .{ .execute })` compiles and, only when `execute` is set, runs each emitted module (`run_output`). Every module comes back: one that did not lex, parse or type-check carries `result.diagnostic`, one that failed comptime validation `result.comptime_err` (`result.failed()`). `generate` is the snapshot harness's executing entry and drops the `diagnostic` entries (the harness derives those from its own comptime run) — drivers (the CLI) call `generateWith` with `.execute = false`. The comptime pass runs on `config.comptime_runtime orelse comptime/runtime/runtime.zig of(targetSource)` (decision 84: commonJS/wasm on the wat runtime, in-process; erlang/beam on the BEAM runtime), selected for the pass's duration (`runtime.select`) |

## Subdirectories

| Dir | Purpose | AGENTS |
|---|---|---|
| `lexer/` | `token.zig` + tests | [link](lexer/AGENTS.md) |
| `parser/` | sub-grammars + parser snapshot tests | [link](parser/AGENTS.md) |
| `format/` | formatter snapshot tests | [link](format/AGENTS.md) |
| `comptime/` | HM types, infer, unify, transform, specialize, template/decorator eval | [link](comptime/AGENTS.md) |
| `comptime/runtime/` | persistent `erl` comptime runtime | [link](comptime/runtime/AGENTS.md) |
| `codegen/` | per-target backends (commonJS, typescript `.d.ts`, erlang, beam_asm, wat) | [link](codegen/AGENTS.md) |
| `utils/` | snap.zig, pretty.zig, json_diff.zig | [link](utils/AGENTS.md) |

## Dir-specific conventions

- **Allocator pattern** — never store `allocator` as a struct field. Pass
  `alloc: std.mem.Allocator` to the method that needs it. Emitters may keep
  an `alloc` field but it must arrive via `init`.
- **Parser helpers** to know about — `boxExpr`, `parseStmtListInBraces`,
  `parseCommaSeparatedIdentifiers`, `reportReservedWordError`.
- **Type annotations** always use `TypeRef`.
- **Formatter** must round-trip: `format(parse(src))` must re-parse to an
  equivalent AST.
- **Test layout** — each stage keeps its tests in `<stage>/tests/<feature>.zig`
  (mirrors `language-server/src/tests/`), aggregated by a thin `<stage>/tests.zig`
  barrel (`test { _ = @import("tests/<feature>.zig"); … }`) that `test_root.zig`
  imports. The shared harness lives in `<stage>/tests/helpers.zig` (a pure
  `pub fn`/data module, no `test {}`); feature files do `const h = @import("helpers.zig");`.
  Snapshot paths derive from the **test name**, never the file — so a test block
  may move between feature files freely, but its `test "<stage>: <name>"` string
  must never be renamed.
