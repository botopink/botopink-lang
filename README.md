# botopink

> Compiler and language server for the botopink language, written in [Zig](https://ziglang.org/).

## Overview

**botopink** is a programming language with its own syntax, currently in early development. This repository contains the full compiler toolchain: lexer, parser, AST representation, Hindley-Milner type inference, JavaScript/Erlang code generation with comptime evaluation, a source code formatter, and a complete LSP language server.

## Compiler Pipeline

The compiler is a **pure function** from `.bp` source to emitted target code.
Comptime evaluation runs inside the compiler via an embedded
[wasm3](https://github.com/wasm3/wasm3) interpreter — same engine regardless of
the final codegen target. Executing the emitted code is downstream of the
compiler and is the user's concern (browser, node, `erl`, etc.).

```
.bp source files
  ↓
LEXING
  → tokens (incl. sub-language spans: @ExprCustom/erika/jhonstart/emilia)
  → sub-language lexer registry kicks in per spanned span
  ↓
PARSING
  → raw AST (Expr / TypedExpr nodes)
  → decorator annotations bound to their targets (#[@effect], #[@External.<targert>(...)], #[@future], #[@iterator], …)
  → custom-AST nodes for sub-languages (q.custom payload preserved)
  → declarations registered (records, interfaces, fns, decorator definitions)
  ↓
MODULE RESOLUTION
  → project_graph.zig walks botopink.json deps + `mod` siblings
  → from "<lib>" resolves to <lib>/src/root.bp
  → cross-module imports linked, cycles flagged
  → only .bp / mod.bp enter the tree (.d.bp is doc/marker-only)
  ↓
COLLECT PASS
  → interface members cached (collectInterfaceMembersCached)
  → record method tables built (incl. collision mangling per record_method_collisions)
  → primitive interface chains assembled (prim_iface_chain map)
  → decorator surface registered (which fns are @emit consumers, capture surface, etc.)
  ↓
TYPE INFERENCE (multi-pass on the AST until fixpoint)
  Pass A — local inference
    → leaves get literal/concrete types
    → bindings flow forward through scopes
  Pass B — generic substitution
    → inferTypeMethods walks method calls, propagates generic params
    → primMethodReturnTypeFromIface substitutes T in primitive interface returns
    → chained method substitution (xs.map(...).filter(...) carries T through hops)
  Pass C — unification
    → unify() reconciles inferred vs declared (struct-tuple, named-args, optional, future)
    → eager unwrap rules: @Future<T> ≡ T inside await ctx; @Option<T> chained
    → back-propagation: declared val type informs RHS generic call sites
  Pass D — effect & annotation typing
    → effect markers (#[@<effect>]) shape fn signatures
    → declare-fn @result / @future exceptions for #[@External.<targert>(...)] bodies
    → annotation-on-builder hooks recorded
  ↓
TYPE CHECK
  → final pass verifies every binding satisfies its declared/inferred type
  → diagnostics emitted with binding hover material (CompileResult.bindingsFor)
  ↓
COMPTIME PHASE  (wasm3, target-independent)
  Step 1 — template/decorator harvest
    → walk AST for @code / @expr / @capture / @decorator usages
    → bundle each invocation with its descriptor blob (file/line/col/scope/parts)
  Step 2 — lower harvested body to WAT
    → wat backend lowers the template body using its standard codegen path
    → record types, anon ctors, optionals, strings, lists, try/catch — all real
  Step 3 — prelude link
    → wat_runtime.prelude(allocator) hands back:
        raw-infra WAT (fd_write import, __bp_alloc, __emit_raw, __bp_err)
      ++ compiled libs/std/src/template_runtime.bp (records, ctors, __capture__*, __decl__*, outcome envelopes)
      [4-layer cache: L0 build-time embed → L1 in-proc singleton → L2 on-disk → L3 cold]
  Step 4 — wasm3 execution
    → wasm3_host.runWat runs the linked wasm
    → @capture / @decl reflection methods resolve against the descriptor blob
    → host calls flush emitted source fragments via __emit_raw (iovec at offset 200)
  Step 5 — outcome splice
    → Outcome JSON parsed: { code | capture | error }
    → emitted fragments spliced back into the AST at the invocation site
    → error envelopes surface as diagnostics with original file/line/col
  ↓
POST-COMPTIME TYPE CHECK
  → spliced fragments are real AST: re-run inference passes A–D over them
  → newly-introduced bindings, generic instantiations, and decorator-produced
    fns all satisfy the same type rules as hand-written source
  ↓
CODEGEN  (per target, parallel-safe)
  → BEAM ASM    → codegen/beam_asm.zig   → .S
  │   prim_beam_templates + renderBeamTemplate substitute $self/$N/$args
  │   over @External.Beam("""…""") bodies (front 03)
  ├ Erlang     → codegen/erlang.zig      → .erl
  │   tryArrayPrimFallback / tryEmitPrimAnnotation walks prim_iface_chain
  │   record method collisions mangled to <recordtype>_<method>
  ├ commonJS   → codegen/commonJS.zig    → .js / .mjs
  │   require() with project-graph-aware relative paths
  │   sidecar .mjs shipping (libs.zig shipMjsSidecars)
  └ WAT        → codegen/wat.zig         → .wat (consumed by wasm3 at comptime
                                          and by user runs)
  ↓
EMIT
  → write files to zig-out / .botopinkbuild/ (per target convention)
  → no runtime invocation — execution is the user's concern downstream
```

## Recent Updates (May 2026)

- Refactored expression flow in `compiler-core` to the new categorized AST model (`literal`, `identifier`, `binaryOp`, `unaryOp`, `jump`, `branch`, `loop`, `binding`, `call`, `function`, `collection`, `comptime_`).
- Removed legacy expression variants (`controlFlow`, `staticCall`) and aligned parser, formatter, comptime pipeline, codegen emitters, and language-server integration.
- Refreshed parser/comptime/codegen snapshots for Zig `0.16.0` compatibility and updated generated baselines.
- Added `src/codegen/runtime.zig` runtime helpers and ignored compiled `format.o*.a` artifacts in version control.

## Project Structure

```
modules/
├── compiler-core/           # Compiler library (Zig): lexer → parser → infer → codegen
│   ├── src/                 # all compiler stages (root.zig is the public façade)
│   └── snapshots/           # parser / comptime / codegen snapshots
├── compiler-cli/            # `botopink` CLI executable — see AGENTS.md inside
├── language-server/         # `botopink-lsp` LSP executable + tests/ + snapshots/
├── lib-test-runner/         # `botopink-lib-test` — per-lib / per-backend test gate
└── bpmp/                    # `bpmp` — package manager + toolchain manager

libs/                        # bundled .bp libraries — see libs/AGENTS.md
├── std/                     # standard library (prelude loaded at infer time)
├── server/                  # framework-agnostic HTTP backing (from "server")
└── client/                  # client-side interfaces (scaffold)
```

The per-directory `AGENTS.md` files inside each package own the file-level
layout for that package; the tree above is a high-level index that does not
re-mirror them (avoiding two-source-of-truth drift). The four codegen
backends — **commonJS · erlang · beam · wasm** — all live in
`modules/compiler-core/src/codegen/`.

## Installation

```sh
# POSIX (one-liner)
curl --proto '=https' --tlsv1.2 -sSf https://botopink.dev/install.sh | sh
```

```powershell
# Windows (PowerShell)
iex (irm 'https://botopink.dev/install.ps1')
```

Each script detects your OS/arch, downloads the latest release, verifies
the sha256 sidecar of every archive, and installs the toolchain
(`botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp`) into
`$BPMP_HOME` (default `~/.bpmp/` on POSIX, `%USERPROFILE%\.bpmp` on
Windows). The post-install hint prints the one-line PATH export for your
shell; `bpmp env` prints the same later.

For **reproducible** installs (CI, containers), pin a version:

```sh
BOTOPINK_VERSION=v0.0.1 BOTOPINK_INSTALL_DIR=/opt/botopink \
    sh install.sh --no-modify-path --quiet
```

For everything the installers accept (flags + env vars + integrity
model + exit codes), see [`scripts/AGENTS.md`](scripts/AGENTS.md).

**Manual install**: grab a tarball from the
[Releases page](https://github.com/botopink/botopink-lang/releases) — they
ship as `<binary>-<version>-<target>.{tar.gz,zip}` with a `.sha256` sidecar
each. Verify with `sha256sum -c <file>.sha256` (POSIX) /
`Get-FileHash -Algorithm SHA256` (Windows), extract, and put `bpmp` on
your `PATH` (it shims the other binaries).

> Until `botopink.dev/install.sh` is configured, the one-liners point at
> `botopink.dev` for stability; the same scripts are available at
> `https://raw.githubusercontent.com/botopink/botopink-lang/main/scripts/install.{sh,ps1}`
> as a temporary fallback.

## Building (from source)

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
- Expressions: literals, field access, method calls, binary operators, unary operators, `return`, `throw`, `try`, `if`, `loop`, `break`, `continue`, `yield`, `comptime`, pipeline `|>`, and anonymous `fn(...) { ... }`
- Pipeline operator: `a |> b |> c` — left-associative function composition
- Lambda syntax: `{ params -> body }` — inline anonymous function
- Optional types `?T`, array types `T[]`, tuple types `#(T1,T2)` in type annotations
- `@Result(D, E)` builtin type — `Ok(data)` / `Error(error)` enum for error handling
- Array literals `[e1, e2, ...]`, tuple literals `#(e1, e2, ...)`
- `try expr [catch handler]` — `@Result` unwrapping with optional inline error handler; lowers to `Ok`/`Error` **pattern matching** (never host try/catch). `try` on a non-`@Result` value is a compile-time error
- `catch` as universal tail operator for error propagation
- `throw` type checking — the thrown value must match the `E` of the enclosing fn's `@Result<D, E>`
- `if (expr) { binding -> body }` — null-check with value binding
- `val/var name [: TypeRef] = expr` — optional type annotation on local bindings
- **Mandatory type annotations on function parameters**: `fn f(x: i32)` — required
- Parameter modifiers: `comptime`, `syntax`; type params via `comptime T: type`, optionally constrained: `comptime T: type string | int`
- Pattern matching: `case expr { pattern -> body; ... }` with OR patterns, list patterns, wildcard
- Structured parse error reporting with position and context
- **Allocator never stored** — `Parser.init(tokens)` receives no allocator

### AST
- Typed representation of all language nodes via Zig's `union(enum)`
- `Param.typeRef: TypeRef` — structured type references in function parameters (not flat strings)
- `TypeRef` union: `named`, `array`, `tuple_`, `optional`, `function` — covers all type annotation forms
- `ValDecl`, `FnDecl`, `DelegateDecl`, `RecordDecl`, `StructDecl`, `EnumDecl`, `InterfaceDecl`
- Generic parameters, parameter modifiers, getters/setters
- `ExprOf(phase)` categorized families: `literal`, `identifier`, `binaryOp`, `unaryOp`, `jump`, `branch`, `loop`, `binding`, `call`, `function`, `collection`, `comptime_`
- `CaseArm.emptyLineBefore` preserves intentional blank lines in `case` formatting

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

Four backends emit native target source, all Zig-implemented under
`modules/compiler-core/src/codegen/`:

#### CommonJS (JavaScript) — `commonJS.zig`
- Zig-native JS emitter — no Node.js intermediary
- **Comptime evaluation** — expressions marked `comptime` evaluated at compile time
- **Function specialization** — `comptime` parameters generate specialized versions
- **Loop unrolling** — loops over comptime arrays fully unrolled
- TypeScript `.d.ts` generation (optional)

#### Erlang — `erlang.zig`
- Zig-native Erlang emitter — generates `.erl` files directly
- Erlang-style operators: `div`, `rem`, `=:`, `=/=`, `=<`
- Module header, export declarations, function arity calculation

#### BEAM assembly — `beam_asm.zig`
- Emits BEAM `.S` assembly, compiled to `.beam` by `erlc`
- Module header, real function lowering, `case` lowering, recursion + loops
- Eager lowering of effect annotations (`@Future<T>` resolves to `T`,
  finite `@Iterator<T>` is a list)

#### WebAssembly text — `wat.zig`
- Emits `.wat` text, executed under `wasmtime` (linear memory + WASI)
- Linear-memory aggregates: arrays, tagged unions, `@print` via WASI

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

Tested via Gleam-style snapshot fixtures (cursor `↑` aligned to exact column).

## Requirements

- [Zig](https://ziglang.org/download/) `0.16.0` or later — the only **required** host runtime; comptime evaluation runs through the embedded wasm3 interpreter.
- Optional, only for end-to-end execution of emitted code with `botopink test --target <X>`:
  - Node.js — for the `commonJS` target
  - Erlang/OTP (`erl`, `erlc`) — for the `erlang` and `beam` targets
  - `wasmtime` (or any wasm runtime) — for the `wat` target

None of these are needed to build, test, or run the compiler itself.

For the complete set of examples covering every feature, see [docs.md](docs.md).
