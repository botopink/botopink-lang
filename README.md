# botopink

> Compiler and language server for the botopink language, written in [Zig](https://ziglang.org/).

## Overview

**botopink** is a programming language with its own syntax, currently in early development. This repository contains the full compiler toolchain: lexer, parser, AST representation, Hindley-Milner type inference, JavaScript/Erlang code generation with comptime evaluation, a source code formatter, and a complete LSP language server.

## Project Structure

```
modules/
├── compiler-core/           # Compiler library (Zig)
│   ├── src/
│   │   ├── root.zig         # Library entry point (no tests — use test_root.zig)
│   │   ├── test_root.zig    # Test entry point (imports all sub-module tests)
│   │   ├── lexer.zig        # Main lexer
│   │   ├── parser.zig       # Recursive-descent parser
│   │   ├── ast.zig          # AST nodes (union(enum) throughout)
│   │   ├── module.zig       # Module struct — input representation
│   │   ├── comptime.zig     # Target-agnostic comptime compilation
│   │   ├── format.zig       # Wadler-Lindig pretty-printer
│   │   ├── print.zig        # rustc-style error renderer
│   │   └── codegen.zig      # Public codegen API (2-phase)
│   ├── src/lexer/           # Token definitions + tests
│   ├── src/parser/          # Parser tests
│   ├── src/comptime/        # Hindley-Milner type inference + comptime
│   ├── src/codegen/         # JavaScript/Erlang code generation
│   │   ├── config.zig       # Target and runtime config
│   │   ├── commonJS.zig     # CommonJS backend
│   │   ├── erlang.zig       # Erlang backend
│   │   ├── typescript.zig   # TypeScript typedef generator
│   │   └── tests.zig        # Snapshot-based codegen tests
│   └── src/utils/           # Test infrastructure (snapshots, diffs)
├── compiler-cli/            # CLI executable `botopink`
│   └── src/cli/
│       ├── build.zig        # `botopink build` command
│       ├── check.zig        # `botopink check` command
│       ├── format_cmd.zig   # `botopink format` command
│       └── new.zig          # `botopink new` command
├── language-server/         # LSP server executable `botopink-lsp`
│   └── src/
│       ├── engine.zig       # LSP feature implementations
│       ├── compiler.zig     # Incremental compilation wrapper
│       ├── server.zig       # JSON-RPC loop
│       ├── protocol.zig     # LSP protocol types
│       ├── lsp_types.zig    # Position/offset helpers
│       ├── messages.zig     # Request/response handlers
│       ├── files.zig        # Open document state
│       ├── feedback.zig     # Client notification helpers
│       └── tests/           # 56 LSP engine tests
└── stdlib/                  # Standard library (.bp source files)
```

## Building

```sh
zig build           # compile botopink (CLI) + botopink-lsp
zig build test      # run all tests (compiler-core + language-server)
zig build run       # compile and run the botopink CLI
```

## Features

### Lexer
- Full tokenization of the botopink language
- Numeric literals in multiple bases (binary `0b`, octal `0o`, hexadecimal `0x`)
- Underscore digit separators: `1_000_000`, `0b1010_0011`
- Scientific notation: `1.5e-10`, `2E+3`
- String literals with escape sequences, including `\u{...}` for Unicode
- Integer, float (`.` suffix), and string (`++`) operators
- Structured lexical error reporting with exact position (byte offset, line, column)
- **Allocator never stored** — always passed as parameter to `scanAll(alloc)`, `deinit(alloc)`

### Parser
- Produces an AST from the token stream
- Declarations: `use`, `interface`, `struct`, `record`, `enum`, `implement`, `pub fn`, `val`, delegate
- Shorthand declarations: `struct Name {}`, `record Name(...) {}`, `enum Name {}`, `interface Name {}`
- Delegate declarations: `val X = interface fn(...)` and `[pub] declare fnX(...)` — single-method interface aliases
- Expressions: literals, field access, method calls, binary operators, `return`, `try`, `if`, `null`, `comptime`, `yield`, pipeline `|>`
- Pipeline operator: `a |> b |> c` — left-associative function composition
- Lambda syntax: `{ params -> body }` — inline anonymous function
- Optional types `?T`, error unions `E!T`, array types `T[]`, tuple types `#(T1,T2)` in type annotations
- Array literals `[e1, e2, ...]`, tuple literals `#(e1, e2, ...)`
- `try expr [catch handler]` — error-union unwrapping with optional inline error handler
- `catch` as universal tail operator for error propagation
- `if (expr) { binding -> body }` — null-check with value binding
- `val/var name [: TypeRef] = expr` — optional type annotation on local bindings
- **Mandatory type annotations on function parameters**: `fn f(x: i32)` — required
- Parameter modifiers: `comptime`, `syntax`, `typeinfo` (with optional constraints)
- Pattern matching: `case expr { pattern -> body; ... }` with OR patterns, list patterns, wildcard
- Structured parse error reporting with position and context
- **Allocator never stored** — `Parser.init(tokens)` receives no allocator

### AST
- Typed representation of all language nodes via Zig's `union(enum)`
- `Param.typeRef: TypeRef` — structured type references in function parameters (not flat strings)
- `TypeRef` union: `named`, `array`, `tuple_`, `optional`, `errorUnion`, `func` — covers all type annotation forms
- `ValDecl`, `FnDecl`, `DelegateDecl`, `RecordDecl`, `StructDecl`, `EnumDecl`, `InterfaceDecl`
- Generic parameters, parameter modifiers, getters/setters
- `ExprKind.pipeline`, `ExprKind.fnExpr`, `ExprKind.lambda`, `CaseArm.emptyLineBefore`

### Type System
- Hindley-Milner type inference with let-polymorphism
- Structural unification with occurs-check (rejects infinite types)
- Two-pass inference: type definitions registered first, then value declarations in order
- Built-in types: `i32`, `f64`, `string`, `bool`, `void`, and full numeric tower (`i8`–`u64`, `f32`, `f64`)
- Array `array<T>`, tuple `tuple<T1,T2,...>`, optional `optional<T>`
- `TypedBinding.type_` for `fn` declarations carries the actual `.func` type (not a name string),
  enabling correct signature help and hover in the language server
- `ComptimeOutput.Outcome` includes `.parseError` variant — incomplete sources (mid-edit)
  are handled gracefully without propagating errors

### Formatter
- Wadler-Lindig pretty-printer producing canonical source from any `ast.Program`
- `Doc` IR with flat/break rendering at configurable line width (default 80 columns)
- Round-trip stable: `format(parse(src))` re-parses to identical AST
- Pipeline `|>`, lambda `{ -> }`, case arms with `emptyLineBefore`

### Code Generation

#### CommonJS (JavaScript)
- Zig-native JS emitter — no Node.js intermediary
- **Comptime evaluation** — expressions marked `comptime` evaluated at compile time
- **Function specialization** — `comptime` parameters generate specialized versions
- **Loop unrolling** — loops over comptime arrays fully unrolled
- TypeScript `.d.ts` generation (optional)

#### Erlang
- Zig-native Erlang emitter — generates `.erl` files directly
- Erlang-style operators: `div`, `rem`, `=:`, `=/=`, `=<`
- Module header, export declarations, function arity calculation

### Codegen API
- **2-phase pipeline**:
  1. `compile(alloc, modules, io, config)` → `ComptimeSession`
  2. `codegenEmit(alloc, outputs, config)` → `[]ModuleOutput`
- **Convenience**: `generate(alloc, modules, io, config)` — runs both phases

### Language Server (LSP)

Full LSP implementation in `modules/language-server/`:

| Feature | Engine function |
|---------|----------------|
| Diagnostics | `engine.diagnose` — parse errors + comptime validation |
| Hover | `engine.hover` — inferred type of symbol under cursor |
| Go-to-definition | `engine.definition` — declaration location |
| Document symbols | `engine.documentSymbols` — all top-level declarations |
| Completion | `engine.completion` — bindings filtered by typed prefix |
| References | `engine.references` — all occurrences of a symbol |
| Rename | `engine.rename` — edits for all occurrences |
| Signature help | `engine.signatureHelp` — parameter info while typing a call |
| Inlay hints | `engine.inlayHints` — type annotations after declarations |
| Formatting | `engine.formatting` — full-file reformat |

**56 tests** with Gleam-style snapshot testing (cursor `↑` aligned to exact column).

## Requirements

- [Zig](https://ziglang.org/download/) `0.16.0` or later
- Node.js (for comptime expression evaluation at compile time)
- Erlang/OTP (optional, for Erlang codegen comptime evaluation)

For the complete set of examples covering every feature, see [docs.md](docs.md).
