# botopink

> Compiler for the botopink language, written in [Zig](https://ziglang.org/).

## Overview

**botopink** is a programming language with its own syntax, currently in early development. This repository contains the full compiler toolchain: lexer, parser, AST representation, Hindley-Milner type inference, JavaScript code generation with comptime evaluation, and a source code formatter.

## Project Structure

```
modules/
├── core/                    # Compiler library (Zig)
│   ├── src/
│   │   ├── root.zig         # Library entry point
│   │   ├── main.zig         # CLI stub
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
│   ├── src/codegen/         # JavaScript code generation
│   │   ├── config.zig       # Target and runtime config
│   │   ├── commonJS.zig     # CommonJS backend entry
│   │   ├── typescript.zig   # TypeScript typedef generator
│   │   └── tests.zig        # Snapshot-based codegen tests
│   └── src/utils/           # Test infrastructure (snapshots, diffs)
└── stdlib/                  # Standard library (.bp source files)
```

## Features

### Lexer
- Full tokenization of the botopink language
- Numeric literals in multiple bases (binary `0b`, octal `0o`, hexadecimal `0x`)
- String literals with escape sequences, including `\u{...}` for Unicode
- Integer, float (`.` suffix), and string (`++`) operators
- Structured lexical error reporting with exact position (byte offset, line, column)

### Parser
- Produces an AST from the token stream
- Declarations: `use`, `interface`, `struct`, `record`, `enum`, `implement`, `pub fn`, `val`, delegate
- Shorthand declarations: `struct Name {}`, `record Name(...) {}`, `enum Name {}`, `interface Name {}` (no leading `val Name =`)
- Delegate declarations: `val X = interface fn(...)` and `[pub] declare fnX(...)` — single-method interface aliases
- Expressions: literals, field access, method calls, binary operators, `return`, `throw [new]`, `try`, `if`, `null`, `comptime`, `yield`
- Optional types `?T`, error unions `E!T`, array types `T[]`, tuple types `#(T1,T2)` in type annotations
- Array literals `[e1, e2, ...]`, tuple literals `#(e1, e2, ...)`
- `try expr [catch handler]` — error-union unwrapping with optional inline error handler
- `if (expr) { binding -> body }` — null-check with value binding
- `val/var name [: TypeRef] = expr` — optional type annotation on local bindings
- Parameter modifiers: `comptime`, `syntax`, `typeinfo` (with optional constraints)
- `syntax fn(item: T) -> R` function-type parameters
- Structured parse error reporting with position and context

### AST
- Typed representation of all language nodes via Zig's `union(enum)`
- Parameter modifiers and generic parameters
- Support for getters, setters, and methods in structs
- `ValDecl` for top-level constants; `FnDecl` for top-level functions
- `DelegateDecl` for single-method interface aliases
- `FnType` / `FnTypeParam` for function-type annotations in `syntax` params
- `TypeRef` union: `named`, `array`, `tuple_`, `optional`, `errorUnion` — covers all type annotation forms
- `RecordField` with `TypeRef` and optional default value; `EnumVariantField` with `TypeRef`
- `StructDecl`, `EnumDecl`, `RecordDecl`, `InterfaceDecl` carry a unique `id: u32` assigned sequentially during parsing

### Type system
- Hindley-Milner type inference with let-polymorphism
- Structural unification with occurs-check (rejects infinite types)
- Two-pass inference: type definitions registered first, then value declarations inferred in order
- Built-in types: `i32`, `f64`, `string`, `bool`, `void`, and the full numeric tower (`i8`–`u64`, `f32`, `f64`, `v128`)
- Array type `array<T>` and tuple type `tuple<T1,T2,...>` (displayed as `#(T1,T2,...)`)
- Optional `optional<T>` from `null` literals and `?T` annotations
- Typed error reporting: `TypeMismatch`, `UnboundVariable`, `ArityMismatch`

### Formatter
- Wadler-Lindig pretty-printer producing canonical source from any `ast.Program`
- `Doc` IR with flat/break rendering at a configurable line width (default 80 columns)
- Covers all declaration and expression forms
- Round-trip stable: `format(parse(src))` re-parses to identical AST

### Code Generation (JavaScript/CommonJS)
- **Zig-native JS emitter** — no Node.js intermediary, no JSON serialization
- **Comptime evaluation** — expressions marked `comptime` are evaluated at compile time:
  - Constant folding: arithmetic, string concatenation, array literals
  - Block evaluation: `comptime { break expr; }` returns computed values
  - Runtime isolation: comptime code cannot reference runtime identifiers
- **Function specialization** — functions with `comptime` parameters generate specialized versions:
  - Each unique set of comptime arguments produces a dedicated function (`fn_$0`, `fn_$1`, ...)
  - String interning: identical string arguments reuse the same specialization
  - Comptime values are baked into the function body, removed from runtime signature
- **Loop unrolling** — loops over comptime arrays are fully unrolled at compile time:
  - Static branch folding: `if` conditions comparing loop variables to literals are resolved
  - True branches are inlined; false branches are eliminated entirely
  - Nested `if-else` chains and `case` expressions are both supported
  - Runtime arrays preserve the loop as a regular `for...of`
- **`case` expression codegen** — correct indentation for nested cases, block arms, `variantFields`, and `list` patterns; `break value` inside block arms emits `return value;` in the IIFE context
- **TypeScript type definitions** — optional `.d.ts` generation when configured
- **Error handling** — structured comptime validation errors with source locations

## Requirements

- [Zig](https://ziglang.org/download/) `0.16.0` or later
- Node.js (for comptime expression evaluation at compile time)

For the complete set of examples covering every feature (interfaces, structs, records, enums, loops, error handling, destructuring, lambdas, etc.), see [docs.md](docs.md).