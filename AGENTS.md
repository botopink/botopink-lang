# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Commands

All Zig commands run from `modules/core/`:

```bash
zig build           # compile the project
zig build test      # run all tests
zig build run       # run the CLI entry point
```

To run tests for a single file, use Zig's filter flag:

```bash
zig build test -- --test-filter "use decl"
```

## Architecture

The compiler is split into a **library module** (`modules/core/src/root.zig`) and a **CLI executable** (`modules/core/src/main.zig`). The library is what matters — the executable is currently a stub.

### Pipeline: source text → typed output

```
modules/core/src/lexer.zig        Lexer.init(src) → Lexer.scanAll(allocator) → []Token
modules/core/src/parser.zig       Parser.init(tokens) → Parser.parse(allocator) → ast.Program
modules/core/src/ast.zig          typed AST nodes (union(enum) pattern throughout)
modules/core/src/print.zig        rustc-style error rendering (position + hint lines)
modules/core/src/comptime/        Hindley-Milner type inference (env, unify, infer, error) + comptime evaluation
modules/core/src/format.zig       Wadler-Lindig pretty-printer: ast.Program → formatted source
```

### Pipeline: typed output → target code (codegen)

```
modules/core/src/codegen.zig                  Public API — Config, ComptimeSession, compile, codegenEmit, generate
modules/core/src/codegen/config.zig           Config struct: Target (commonJS | erlang…) + ComptimeRuntime
modules/core/src/codegen/moduleOutput.zig     Module (input) and ModuleOutput (result) types
modules/core/src/codegen/commonJS.zig         CommonJS pipeline — blind emitter (delegates comptime to comptime.zig)
modules/core/src/codegen/erlang.zig           Erlang pipeline — blind emitter with erlang runtime
modules/core/src/codegen/typescript.zig       TypeScript type definition generator
modules/core/src/codegen/snapshot.zig         Codegen snapshot test helpers
modules/core/src/codegen/tests.zig            Snapshot-based codegen tests (assertJs / assertJsError)
modules/core/src/comptime.zig                 Target-agnostic comptime compilation: compile, ComptimeSession
modules/core/src/comptime/error.zig           Comptime validation errors
modules/core/src/comptime/eval.zig            Comptime expression evaluation
modules/core/src/comptime/render.zig          Comptime value rendering
modules/core/src/comptime/snapshot.zig        Comptime snapshot utilities
modules/core/src/comptime/runtime/node.zig    Node.js comptime runtime
modules/core/src/comptime/runtime/erlang.zig  Erlang comptime runtime
```

The codegen pipeline uses a **two-phase API**:
- **Phase 1** `compile(allocator, modules, io, config) → ComptimeSession` — lex, parse, infer types, validate comptime purity, evaluate `comptime` expressions (via Node.js or Erlang runtime), transform AST (specialization, inlining). Returns a target-agnostic `ComptimeSession` that owns a shared arena (parse trees + type environments) and per-module outputs. Must stay alive until phase 2.
- **Phase 2** `codegenEmit(allocator, outputs, config) → []ModuleOutput` — emit target code for all compiled modules. Dispatches on `config.target` tag.
- **Convenience** `generate(...)` — runs both phases in sequence.

To add a new target (e.g. ESM): create `codegen/<target>.zig` with its own emit logic, add a case to the `Target` union in `config.zig`, and add a handler in the `codegenEmit` switch.

Token definitions live in `modules/core/src/lexer/token.zig` (TokenKind enum + Token struct with byte/line/col positions).

### AST design

All nodes use Zig's `union(enum)` for type-safe variants. Every heap-allocated node owns its children and exposes a `deinit(allocator)` method — always call it to avoid leaks.

Key types in `modules/core/src/ast.zig`:
- `Program` — root; holds `[]DeclKind`
- `DeclKind` — top-level declarations: `Use`, `Interface`, `Struct`, `Record`, `Enum`, `Implement`, `Fn`, `Val`, `Delegate`
- `ValDecl` — top-level constant: `val name = expr`
- `FnDecl` — top-level function: `is_pub`, `name`, `generic_params`, `params`, `return_type`, `body`
- `DelegateDecl` — single-method interface alias: `name`, `isPub`, `params`, `returnType`; declared as `val X = interface fn(...)` or `[pub] declare fnX(...)`
- `Param` — function parameter: `name`, `type_name`, `modifier` (`comptime`/`syntax`/`typeinfo`), optional `typeinfo_constraints` and `fn_type`
- `FnType` / `FnTypeParam` — function-type annotation for `syntax fn(item: T) -> R` params
- `Expr` — expressions: literals, `Call`, `BuiltinCall`, `Lambda`, `Case`, `LocalBind`, `Return`, `ThrowNew`, `Todo`, `Comptime`, `ComptimeBlock`, `Break` (optional value), `Yield` (loop accumulate), `Continue`, `Range` (start..end or start..), `Loop`, binary ops, self-field access/assign
- `Stmt` — wraps an `Expr` (statement = expression-statement for now)
- `Pattern` — case arm patterns: `Wildcard`, `Ident`, `VariantFields`, `NumberLit`, `StringLit`, `List` (with spread), `Or`

`StructMember` reuses `InterfaceMethod` for `fn` members inside structs. `ImplementMethod` adds an optional `qualifier` field for disambiguating multiple-interface methods (`UsbCharger.Connect`).

Shorthand declarations (`struct Name { }`, `record Name(...) {}`, `enum Name { }`, `interface Name { }`) are syntactic sugar for `val Name = <kind> { ... }`. The parser emits the same AST node as the long form, setting `name` from the declaration token instead of from a leading `val Name =`.

### Testing

Snapshot infrastructure lives in `modules/core/src/utils/`:

| File | Purpose |
|---|---|
| `snap.zig` | Core: read/write/compare `.snap.md` files, create `.snap.md.new` on mismatch |
| `pretty.zig` | Serialises any value to indented JSON via `std.json.Stringify` |
| `json_diff.zig` | Structural JSON diff printed to stderr on mismatch (json-diff style) |

Parser tests live in `modules/core/src/parser/tests.zig` and follow this pattern:

```zig
try assertParser(std.testing.allocator, @src(), "source code here");
```

The slug is derived automatically from the test name via `@src()`. Snapshot files are stored under `modules/core/snapshots/parser/<slug>.snap.md`. On the first run the `.snap.md` file is created automatically. On a mismatch the diff is printed to stderr and a `<slug>.snap.md.new` file is written; it is deleted automatically when the test passes again.

Type tests live in `modules/core/src/comptime/tests.zig` and provide two helpers:
- `assertTypes(allocator, source, &.{.{ "name", "Type" }, ...})` — runs inference and checks each declared name maps to the expected type string
- `assertTypeErrorSnap(allocator, @src(), source)` — runs inference, expects a `TypeError`, and snapshot-matches the rendered error message under `modules/core/snapshots/types/errors/<slug>.snap.md`

To update all snapshots after an intentional AST or type change, delete the affected `.snap.md` files and re-run `zig build test`.

Error-case parser tests use `expectParseError` which asserts the rendered error string matches exactly.

## Conventions

- All source code, comments, commit messages, and documentation must be in **English**.
- Arithmetic operators (`+`, `-`, `*`, `/`, `%`) and comparisons (`<`, `>`, `<=`, `>=`) work for all numeric types — no separate float variants. String concatenation uses `+`.
- Parameter modifiers (`comptime`, `syntax`, `typeinfo`) are parsed into `ParamModifier` enum — extend there when adding new modifiers.
- `comptime expr` wraps any expression; `comptime { break expr }` is the block form. `break [expr]` exits any block with an optional value. Bare `break` (no expression) exits with void/null.
- `loop (iter) { param -> body }` iterates over a collection or range. The loop body may use `yield expr` (accumulate into result list), `break [expr]` (exit early), `continue` (skip iteration), or `return expr` (exit enclosing function). When used as an expression (`val x = loop ...`), the result type is the list of yielded values.
- `yield expr` adds a value to the loop's result collection; the loop continues to the next iteration.
- `break [expr]` exits the current block (comptime/loop/if/try) with an optional value.
- `continue` skips the rest of the current loop iteration.
- `const` is not a surface keyword; use `val` for immutable bindings.
- `syntax fn(item: T) -> R` params store a `FnType` in `Param.fn_type`; all other params leave it `null`.
- `typeinfo` without a following type name (e.g. `comptime: typeinfo T`) means "accept any type" — `type_name` is `""` and `typeinfo_constraints` is `null`.
- Top-level `val Name = expr` (not struct/record/enum/interface/implement) parses as `ValDecl`. The top-level dispatch peeks one token past `val Name =` to decide which path to take.
- Shorthand type declarations (`struct Name {}`, `record Name(...) {}`, `enum Name {}`, `interface Name {}`) are parsed by the same handlers as their `val Name = <kind>` long form. The `name` field comes from the token immediately after the keyword, not from a leading `val`.
- `DelegateDecl` is a single-method interface alias. Val form: `val X = interface fn(...)`. Shorthand form: `[pub] declare fnX(...)`. Both share the same AST node — do not introduce a separate node for one form.
- The formatter (`modules/core/src/format.zig`) must stay round-trip stable: `format(parse(src))` should produce output that re-parses to an identical AST.
- `TypeRef` covers all type annotation forms: `named` (plain identifier), `array` (`T[]`), `tuple_` (`#(T1,T2)`), `optional` (`?T`), `errorUnion` (`E!T`). Always use `TypeRef` for new type-annotation fields — not raw `[]const u8`.
- Record fields are formatted WITH the `val` keyword prefix: `record(val name: Type, ...)`. The parser accepts both with and without `val`.
- `try expr [catch handler]` is the error-union unwrapping expression. `try_` and `tryCatch` are the corresponding AST nodes.
- `if (expr) { binding -> body }` — null-check with value binding. Extends `if_` with optional `binding: ?[]const u8`.
- Local bindings `val/var name [: TypeRef] = expr` accept an optional type annotation. The annotation is parsed and discarded; type inference resolves the type.
- `noTrailingLambda: bool` flag on `Parser` prevents `parsePrimary` from consuming a following `{` as a trailing lambda. Set it before parsing any expression that must not consume the next `{`.
