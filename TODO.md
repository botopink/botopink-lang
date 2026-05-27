# TODO — Botopink Compiler

## Done

### @Result(D, E) migration
- [x] Remove `TypeRef.errorUnion` variant from AST (`ast.zig`)
- [x] Remove `E!T` parsing from `parseTypeRef` (`parser.zig`)
- [x] Remove `errorUnion` from type inference — `appendTypeRefStr` and `resolveTypeRefInContext` (`infer.zig`)
- [x] Remove `errorUnion` from formatter (`format.zig`)
- [x] Remove `errorUnion` from TypeScript codegen (`typescript.zig`)
- [x] Remove `errorUnion` from language server hover (`engine.zig`)
- [x] Add `@Result(D, E)` builtin declaration to `builtins.d.bp`
- [x] Add `TypeRef.builtin` variant for `@Name(T1, T2)` type annotations (`ast.zig`)
- [x] Parse `@Name(T1, T2)` in `parseBaseTypeRef` (`parser.zig`)
- [x] Handle `builtin` TypeRef in type inference — `appendTypeRefStr`, `resolveTypeRefInContext` (`infer.zig`)
- [x] Handle `builtin` TypeRef in formatter (`format.zig`)
- [x] Handle `builtin` TypeRef in TypeScript codegen — `@Result(D,E)` emits tagged union (`typescript.zig`)
- [x] Handle `builtin` TypeRef in LSP hover (`engine.zig`)
- [x] Add `@Result` to `inferBuiltinCallReturnType` — returns `namedTypeArgs("Result", args)` (`infer.zig`)
- [x] Semantic awareness: `try expr` unwraps `@Result(D,E)` to `D` via `unwrapResultType` (`infer.zig`)
- [x] `catch` handler: lambda handlers use return type for unification (`infer.zig`)
- [x] Error message: `T!E` syntax rejected with hint to use `@Result(D, E)` (`parser.zig`, `print.zig`)
- [x] Tests: parser error test for rejected `E!T`, 3 comptime inference tests, 15 codegen tests (60 snapshots)

### typeinfo → typeparam migration
- [x] Remove `typeinfo` keyword/token from lexer
- [x] Remove `typeinfo` ParamModifier variant from AST
- [x] Remove `comptime: typeinfo T` parsing path from parser
- [x] Remove `typeinfoConstraints` field from Param
- [x] Replace builtins.d.bp `typeinfo` params with `comptime T: typeparam`
- [x] Formatter: `comptime` params output as `comptime name: type` (pre-name style)

### Runtime expansion
- [x] Add `wasm` variant to `Runtime` enum (`eval.zig`)
- [x] Create `comptime/runtime/wasm.zig` — WAT-based comptime eval via wasmtime
- [x] Add `beam` variant to `Runtime` enum (`eval.zig`)
- [x] Create `comptime/runtime/beam.zig` — BEAM comptime eval (delegates to erlang)
- [x] Update codegen configs: `beam` uses `.beam` comptimeRuntime, `wasm` uses `.wasm` comptimeRuntime

### @print test coverage
- [x] Add `@print` to ~20 existing codegen tests (operators, destructuring, pipeline, loop, if, try/catch, lambda, negation, assign)
- [x] Add `@print` to ~10 existing comptime tests (literals, binary ops, records, case, pub fn)
- [x] Add 5 new `@print` dedicated tests in `comptime/tests.zig`
- [x] Add 4 new `@print` dedicated tests in `codegen/tests.zig`
- [x] Regenerate all snapshots (4 runtimes × 4 targets)

---

## Pending — Syntax

### Result: builtin fn → generic enum

Migrar de:
```
fn Result(comptime D: typeparam, comptime E: typeparam) type
```
Para:
```
pub enum Result<R, E> {
    Ok(result: R),
    Error(error: E);
}
```

#### Syntax: angle-bracket generics
- [ ] Lexer: add `<` and `>` as valid tokens after type identifiers (angle-bracket generics context)
- [ ] Parser: parse `<T1, T2>` type parameters in enum/struct declarations
- [ ] Parser: parse `Result<D, E>` as generic type reference (not `@Result(D, E)`)
- [ ] AST: add generic type parameter support to enum/struct declarations
- [ ] AST: add `TypeRef.generic` variant for `Name<T1, T2>` type references

#### Result as first-class enum
- [ ] Remove `@Result` from builtins — no longer a `@builtin` function
- [ ] Define `Result<R, E>` as a generic enum in stdlib (`builtins.d.bp` or separate file)
- [ ] Variants: `Ok(result: R)` and `Error(error: E)` — named fields, not positional
- [ ] Remove `TypeRef.builtin` variant from AST (or repurpose for other builtins)
- [ ] Remove `@Result` from `inferBuiltinCallReturnType` in `infer.zig`

#### Type inference updates
- [ ] Inference: resolve `Result<D, E>` as generic enum instantiation
- [ ] `try expr`: unwrap `Result<D, E>` to `D` — update `unwrapResultType` for enum-based Result
- [ ] `catch` handler: extract `E` from `Result<D, E>` enum for lambda parameter type
- [ ] `throw expr`: infer as constructing `Result.Error(error: expr)` — wrap in Error variant

#### Codegen updates
- [ ] CommonJS: `Result.Ok(result: v)` → `{ tag: "Ok", result: v }`, `Result.Error(error: e)` → `{ tag: "Error", error: e }`
- [ ] Erlang: `Result.Ok(result: v)` → `{ok, V}`, `Result.Error(error: e)` → `{error, E}`
- [ ] BEAM ASM: same tagged-tuple pattern
- [ ] WAT: tagged struct in linear memory (i32 tag + payload)
- [ ] TypeScript: `Result<D, E>` → `{ tag: "Ok", result: D } | { tag: "Error", error: E }`
- [ ] Formatter: emit `Result<D, E>` syntax
- [ ] LSP hover: display `Result<D, E>` with variant info

#### Migration & cleanup
- [ ] Error message: reject old `@Result(D, E)` syntax with hint to use `Result<D, E>`
- [ ] Tests: update all existing @Result tests and snapshots
- [ ] Update `try`/`catch` codegen tests to verify new enum-based lowering

---

## Pending — Type System

### Typeparam constraints
- [ ] Constraint syntax: `comptime f: typeparam string | int` — type constraints on typeparam
- [ ] Parser: parse `|`-separated type list after `typeparam` in param type position
- [ ] Inference: validate comptime argument satisfies declared constraints
- [ ] Error message: clear diagnostic when constraint is violated

### Throw type checking
- [ ] Semantic awareness of `throw`: verify thrown value matches the `E` type of enclosing `@Result` return
- [ ] Error message: mismatch between thrown type and declared `E` in `@Result(D, E)`

---

## Pending — Codegen

### try/catch lowering
- [ ] Codegen: `try`/`catch` should lower to pattern matching on `Ok`/`Error` variants (not JS try/catch)
- [ ] CommonJS: `try expr catch fallback` → `const _r = expr(); if (_r.tag === "Error") { ... } else { _r.data }`
- [ ] Erlang: `try`/`catch` → `case Expr of {ok, V} -> V; {error, E} -> Fallback end`
- [ ] BEAM ASM: same pattern via `{test, is_tagged_tuple, ...}` or case dispatch
- [ ] WAT: `try`/`catch` → `if` on Ok/Error i32 tag in linear memory

### BEAM ASM — remaining fases
- [ ] **Fase 3**: strings/binaries — `{put_string, ...}`, binary syntax, `@print` via `io:format`
- [ ] **Fase 4**: records/structs — map creation `{put_map_assoc, ...}`, field access
- [ ] **Fase 5**: enums — tagged tuple `{tag, Fields...}`, case dispatch on tag
- [ ] **Fase 6**: closures/lambdas — `{make_fun3, ...}`, higher-order calls
- [ ] **Fase 7**: ranges — `lists:seq/2` or loop counter lowering
- [ ] **Fase 8**: try/catch — `{try, ...}` / `{try_end, ...}` / `{try_case, ...}` instructions
- [ ] **Fase 9**: polish — proper register allocation, tail-call optimization, dead code elimination

### WAT — remaining features
- [ ] Destructure patterns (record, tuple) in WAT
- [ ] Pipeline operator lowering in WAT
- [ ] String operations (concat, compare) via linear memory
- [ ] Enum/record representation in linear memory (tagged structs)
- [ ] try/catch → tag-based if/else in WASM

### Erlang codegen gaps
- [ ] List patterns in case arms (currently placeholder)
- [ ] Constructor patterns in case arms (currently placeholder)
- [ ] Proper arity tracking for qualified function calls

---

## Pending — Stdlib

- [ ] `Result.map(fn(D) -> D2)` — transform Ok value
- [ ] `Result.flatMap(fn(D) -> @Result(D2, E))` — chain fallible operations
- [ ] `Result.unwrapOr(default: D)` — extract Ok or use default
- [ ] `Result.isOk()` / `Result.isError()` — boolean predicates
- [ ] `Option.map` / `Option.flatMap` / `Option.unwrapOr` — mirror Result API

---

## Pending — Language Features

### Lambda syntax
- [ ] Lambda with full type annotations: `val func: fn(String, Int) -> String = { s, i -> ... }`
- [ ] Infer lambda param types from context when annotation is present

### Pattern matching
- [ ] Exhaustiveness checking for case expressions
- [ ] Nested pattern matching (pattern inside pattern)
- [ ] Guard clauses in case arms: `case x { n if n > 0 -> ... }`

---

## Pending — Tooling

### Language Server
- [ ] Go-to-definition for imported symbols (`use { X } from "mod"`)
- [ ] Auto-complete for record/struct fields
- [ ] Auto-complete for enum variants
- [ ] Diagnostic squiggles for type errors in editor

### Formatter
- [ ] Format `@Result(D, E)` return type annotations consistently
- [ ] Format `comptime` param modifiers consistently with type constraints
