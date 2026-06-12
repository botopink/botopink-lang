# Changelog

All notable changes to the botopink compiler workspace are documented in this file.

## Unreleased

### Changed (breaking)

- **Explicit module system** (`mod` / `pub mod`, Rust-style) — module-system
  - A package now declares its module tree explicitly from a root
    (`main.bp` for a binary, `root.bp` for a library — `botopink.json` `entry`
    chooses, auto-detected as `main.bp` then `root.bp`) by following `mod` /
    `pub mod` declarations, instead of the compiler implicitly compiling every
    `.bp` under `src/`. `mod` is now a reserved keyword.
  - `mod Name;` resolves a sibling `Name.bp` **or** a folder index `Name/mod.bp`
    (exactly one — both/neither is an error). A `.bp` not reached through any
    `mod` path is reported **orphaned** and is not compiled.
  - **Path-visibility**: an import may cross into a module only if every `mod`
    on its path is `pub mod`; a private `mod` is reachable only within its
    declaring module's subtree. An `import … from "a.b"` that names a package
    module must publicly export the symbol.
  - **Migration**: packages without a `main.bp`/`root.bp` root still build via
    the legacy implicit `src/` scan, now **deprecated** behind a warning, to be
    removed in a future release. Add a root with `mod` declarations to opt in.

### Added

- **Record / array ergonomics for the UI framework** (jhonstart-language-gaps)
  - Records carry **function-typed fields** (`record State<T> { value: T, set: fn(next: T) }`);
    codegen stores the closure like any field.
  - `get` / `set` are **soft keywords** — usable as record field names,
    record-literal labels, destructuring names, member access, method-call
    names, and named-call labels (the hook shape `{ value, set }`, `s.set(x)`).
  - **Anonymous record types** as annotations / return types
    (`-> { value: T, set: fn(T) }`, `TypeRef.record_type` → structural `Type.record`).
  - A **function type returns an array** — `fn() -> T[]` (and `?T[]`, `T[][]`)
    parse + infer in any position (declaration, field, annotation).
  - **`Children` coercion**: an `Element[]` (any array), a single value
    implementing `@Context` (an `Element`), or a `string` coerces into a
    `Children`-typed parameter — the builder children model `div([a, b])` /
    `div(child)` / `div("text")`.

- **`@Result` / `@Option` method API** (stdlib)
  - `@Result<R, E>`: `.map`, `.flatMap`, `.unwrapOr`, `.isOk`, `.isError`.
  - `@Option<T>` (the canonical spelling of `?T`): `.map`, `.flatMap`, `.unwrapOr`.
  - Resolved by type inference and lowered inline per backend: `commonJS` and
    `erlang` emit the full form (`Ok`/`Error` tag match, option presence check);
    `beam` and `wasm` emit a documented stub.
  - Documented in `libs/std/src/builtins.d.bp`.
- **Method calls on expressions** — `CallExpr.receiver` is now an expression, so
  method chains (`a().map(f).unwrapOr(0)`) and zero-arg method calls (`r.isOk()`)
  parse and type-check.

## v0.0.13-beta (May 2026)

### Highlights

- **`use` hook codegen (F8)**
  - `use` is now a prefix operator (`val {v, s} = use state(0)`); the AST node
    collapsed to `Expr.useHook { inner }` and binding moved to `val`/`var`.
  - CommonJS lowers hooks to React: `state`→`useState`, `memo`→`useMemo`,
    `effect`→`useEffect` (via the `"use"+Capitalize` convention), with an
    inferred dependency array for `memo`/`effect`. Erlang/BEAM/WAT lower `use`
    transparently into the binding's slot.
  - Phantom `@Context` base structs emit no runtime code; the `.d.ts` erases
    `@Context<B, R>` to its Return type `R`.
  - Parser fix: no-param trailing lambdas `{ -> … }` now consume their arrow.
- **`try` / `catch` lower to `Ok`/`Error` pattern matching**
  - Across all four backends (commonJS, erlang, beam, wasm), `try`/`catch` now
    lower to a pattern match on the `@Result` tag instead of host exceptions
    (no JS `try/catch`, no Erlang `try…catch`, no BEAM `try`/`try_case`).
  - `try expr` propagates the `Error` variant via an early return (Erlang nests
    the remainder of the body inside the `{ok, V}` arm); `try expr catch h`
    keeps the `Ok` value or applies the handler (lambda handlers receive the
    unwrapped error).
  - Applying `try`/`catch` to a non-`@Result` value is now a compile-time error
    (`try on non-Result`).

- **Expression-flow refactor across compiler-core** (`b86c5de`)
  - `ast.ExprOf(phase)` now uses categorized families:
    `literal`, `identifier`, `binaryOp`, `unaryOp`, `jump`, `branch`, `loop`, `binding`, `call`, `function`, `collection`, `comptime_`.
  - Parser, formatter, comptime transform/specialization, JS/Erlang runtimes, and LSP integration were updated to the new shape.
  - Legacy variants such as `controlFlow`/`staticCall` are no longer active in the main AST flow.
- **Snapshot baseline refresh** (`b86c5de`, `e61ba77`)
  - Parser, comptime, and codegen snapshots were regenerated to match Zig `0.16.0` behavior and the new AST shape.
  - Obsolete snapshot files were removed where test semantics changed.
- **Codegen/runtime cleanup**
  - Runtime execution helpers are now centralized under `modules/compiler-core/src/codegen/runtime.zig`.
  - Stale path `modules/compiler-core/src/codegen/d` was removed from tracked sources.

### Maintenance

- **Ignore generated static library artifacts** (`e98f4f5`)
  - Added ignore rule for `format.o*.a` to avoid polluting commits with local Zig artifacts.

### Compatibility context in this release line

- `787e5c0` — Zig `0.16.0` compatibility and parser consistency fixes.
- `9b93b5c` — removed `staticCall` and aligned compiler/LSP code paths for Zig `0.16`.

## v0.0.12-beta (April 2026)

- Added full `language-server` module with diagnostics, hover, definition, references, rename, signature help, inlay hints, and formatting.
- Standardized parser parameter typing around `TypeRef`.
- Unified workspace build flow for compiler CLI + language server.
- Improved comptime/LSP resilience for incomplete sources.

## v0.0.11-beta (April 2026)

- Consolidated allocator style to **never store, always pass** in parser/codegen APIs.
- Added Erlang code generation backend parity and snapshot coverage improvements.
- Added/expanded language features including pipeline (`|>`), anonymous `fn` expressions, and richer pattern matching snapshots.
