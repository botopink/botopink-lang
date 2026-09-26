# compiler-core

> Path: `modules/compiler-core/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)

Main Zig library: lexer, parser, AST, type inference, comptime, codegen and
formatter. Imported as the `botopink` module by `compiler-cli` and
`language-server`.

## Tree

```text
compiler-core/
├── AGENTS.md            ← you are here
├── botopink.json        ← module version (drives auto-tagging)
├── src/                 ← all compiler stages — see src/AGENTS.md
└── snapshots/           ← .snap.md test fixtures
    ├── parser/          ← AST snapshots
    ├── codegen/         ← codegen output (beam/, erlang/, errors/, node/, wasm/)
    └── comptime/        ← comptime snapshots, one file per test (ast/, errors/, templates/)
```

## Commands (run from the workspace root)

The package has no `build.zig` of its own: the workspace `build.zig` builds it
and derives the embedded `std` modules from `libs/std/src/root.bp`.

```bash
zig build                                 # compile
zig build test                            # compiler-core + language-server + CLI tests
zig build test -Dtest-filter="import decl"
```

## High-level pipeline

```text
source → lex → parse → infer (HM) → transform (specialize) → codegen → target
                              ↘  format.zig   round-trippable formatter
                              ↘  print.zig    rustc-style diagnostics
```

## Children

| Dir | Purpose |
|---|---|
| [`src/`](src/AGENTS.md) | Implementation of every stage. |
| `snapshots/` | Test fixtures for parser/codegen/comptime. |

## Notes

- Every target (commonJS + `.d.ts` typedefs, erlang, BEAM assembly, WAT) is
  emitted natively in Zig under `src/codegen/`.
- Comptime evaluation (comptime vals, decorator and template bodies) runs in a
  persistent `erl` process — see
  [`src/comptime/runtime/`](src/comptime/runtime/AGENTS.md).
- For language syntax notes (records / enums / pipeline `|>` / numeric literals
  / etc.) see the workspace [`docs.md`](../../docs.md).
- **Test-mode codegen** (`----- RUN LOG -----` envelope per test): each
  backend's test runner wraps every `test "name" { … }` body with a fixed
  `TEST <file>:<line> <name>` header + a fenced ```logs``` block capturing the
  body's stdout. Contract: [`../compiler-cli/AGENTS.md`](../compiler-cli/AGENTS.md)
  (“`botopink test` output format”); emitters are `__bp_run_tests` in
  `src/codegen/commonJS.zig` and `__bp_run_one` / `__bp_run_tests` in
  `src/codegen/erlang.zig`.
- **A test body is a fallible context** (1.0.10-beta decision 74): a `try`
  whose operand is `Error(e)` inside a `test { … }` ends the test as
  `FAIL <name>  (<e>)  at <file>:<line>` — commonJS `throw new Error(e)`
  (`buildTryStmt`, `in_test_body`), erlang `erlang:error({bp_assert, E, Loc})`
  (`propagateTryExpr`, `in_test_body`) — instead of returning the Result the
  runner would ignore. A `try` inside a lambda is the lambda's. A bare
  `return;` is the `ok` position of a `-> @Result<void, E>` (parser +
  `transform.zig` `wrap_ok` over `null`).
- **`@src()`** (1.0.10-beta decision 73) is a comptime builtin answering the
  prelude record `SourceLocation(file, line, column, fnName)`: `infer.zig`
  `inferSrcBuiltin` rewrites the call into the constructor call with four
  literals (`env.srcRewrites`, spliced by `transform.zig`) and
  `comptime.zig` `withSourceLocationDecl` prepends the record's declaration to
  a program that names it, so no `src/codegen/*.zig` knows the builtin.
  `file` is `Module.srcPath` (package-relative, set by the CLI loaders) or
  `<name>.bp`; `fnName` is `env.currentFnName`. An unrecognised `@name(…)` is
  `unknown-builtin` now, not a silent `void`.
- **Bundled packages** (1.0.10-beta decisions 115–117): `build.zig`'s
  `bundled_packages` constant (`std` and the libraries under `libs/` the
  compiler ships) is the ONE list of their names; it generates
  `comptime.bundled_packages` (each non-std entry with its embedded `.bp`
  modules). The core spells none of them — the lib-agnostic gate still allows
  only `std` — and a non-std bundled library is ordinary code to the checker
  and the codegens: the CLI (`libs.loadDependencies`) and the LSP
  (`ProjectGraph`) load its modules as `<pkg>/<stem>`, so its erlang atoms are
  `<pkg>@<stem>` / `<pkg>@<stem>@@<Type>` (decision 109) and commonJS requires
  `./<pkg>/<stem>.js` with no new code. The std-only rules keep their `std/` test.

## Tagging

`compiler-core` is auto-tagged on push by
[`../../.github/workflows/tag.yml`](../../.github/workflows/tag.yml) (path
filter: `modules/compiler-core/**`):

- `compiler-core/<version>-feat` — moving; force-updated on each feat push.
- `compiler-core/<version>` — immutable; created once per master/main push.
  Re-push without bumping `botopink.json.version` → red gate.

`<version>` is `botopink.json.version` (this module's local manifest, NOT
the workspace `v*` release tags). Bump it in the same change that lands the
code you want tagged.
