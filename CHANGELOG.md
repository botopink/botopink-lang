# Changelog

All notable changes to the botopink language will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.0.11-beta] — 2026-04-12

### Added
- **Comptime evaluation** — constant folding, block evaluation with `break`, val inlining
- **Comptime loop unrolling** — conditional folding, nested if-else chains, case expression folding
- **Function specialization** — distinct args generate specialized functions (`fn_$0`, `fn_$1`), identical args reuse
- **Erlang codegen target** — full runtime support for comptime evaluation
- **Erlang comptime runtime** — dynamic module naming, JSON encoding via `json:encode/1`
- **Pattern matching with `case`** — number/string/wildcard/variant/or/list patterns with spread
- **Enum declarations** — unit variants, payload variants, methods with `case` dispatch
- **Lambda syntax** — trailing lambdas, named args, multiple trailing lambdas, binary addition
- **`yield expr`** — loop accumulation into result collections
- **`val` top-level constants** — type inference, arithmetic folding at comptime
- **Parameter modifiers** — `comptime`, `syntax`, `typeinfo` with optional constraints
- **`pub fn` declarations** — exported functions with generics and type annotations
- **`todo` expression** — placeholder that throws "not implemented"
- **Type definition generation** — TypeScript typedefs with unique IDs
- **Unique IDs on AST nodes** — struct, enum, record, interface declarations tracked
- **Multi-module imports** — public functions and values across modules
- **Comprehensive documentation** — `docs.md` language reference, AGENTS.md files, README
- **Snapshot testing infrastructure** — parser, codegen, comptime, type errors

### Changed
- **Project structure** — core code moved to `modules/core/`
- **Codegen pipeline** — two-phase API: `compile()` → `ComptimeSession`, `codegenEmit()` → `ModuleOutput`
- **Comptime module** — extracted eval, render, snapshot logic into separate files
- **Specialization** — moved to AST transform pass with Aggregator module
- **Emitter** — replaced with JsBuilder for proper indentation
- **JSON binding** — unified types across comptime module
- **Block parsing** — unified logic
- **Snapshots** — grouped per-module, multi-section format (SOURCE CODE, COMPTIME JS, TYPED AST JSON)
- **Naming** — applied Zig conventions to all identifiers

### Removed
- `if val Pattern = expr { body }` — replaced by `case` expression
- `private` keyword on struct/enum/record fields — all fields private by default
- `ifVal` pattern matching node
- Raw string injection in specialization (now uses `Emitter.emitSpecializedFn`)

### Fixed
- Reduced memory leaks in comptime tests from 733 to 16
- Case codegen indentation issues

---

## [0.0.1-alpha] — 2026-03-22

### Added
- Initial project setup
- Zig build system (`build.zig`)
- Basic module structure

[Unreleased]: https://github.com/botopink/botopink-lang/compare/v0.0.11-beta...HEAD
[0.0.11-beta]: https://github.com/botopink/botopink-lang/compare/v0.0.1-alpha...v0.0.11-beta
[0.0.1-alpha]: https://github.com/botopink/botopink-lang/releases/tag/v0.0.1-alpha
