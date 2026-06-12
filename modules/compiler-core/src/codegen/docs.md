# compiler-core/src/codegen — backend reference

> Path: `modules/compiler-core/src/codegen/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)

Per-target backends and their shared infrastructure. The public façade is
[`../codegen.zig`](../codegen.zig).

## Tree

```text
codegen/
├── config.zig        ← Config / Target / ComptimeRuntime / TypeDefLang
├── moduleOutput.zig  ← shared types: Module, ModuleOutput, GenerateResult
├── commonJS.zig      ← CommonJS emitter (1600+ lines)
├── erlang.zig        ← Erlang emitter
├── beam_asm.zig      ← BEAM Assembly `.S` emitter (complete — 0 unsupported)
├── wat.zig           ← WebAssembly Text `.wat` emitter (complete — 0 unsupported)
├── typescript.zig    ← TypeScript `.d.ts` typedef generator
├── runtime.zig       ← runtime helpers used when executing generated code
├── snapshot.zig      ← snapshot helpers for codegen tests
└── tests.zig         ← `assertJs`, `assertJsSingle`, `assertJsError`, …
```

## Design: emitters are blind

This is the single most important property of this directory:

> **Emitters know nothing about comptime specialization.**

By the time an emitter sees the AST, every comptime decision has already
been made by [`../comptime/transform.zig`](../comptime/docs.md). Concretely:

- `program.decls` contains both originals and specialized clones
  (`scale_$0`) as regular `DeclKind.fn` nodes.
- Inlined comptime vals appear as plain decls (`const x = 6.28;`).
- Calls have been rewritten to mangled names with comptime args dropped.

The emitter therefore only needs to:

1. Iterate `program.decls` from the already-transformed AST.
2. Render each `DeclKind` to the target language.
3. Honour the entry-point wrapper convention (below).

This separation keeps emitters small, target-agnostic in spirit, and easy to
swap. **Do not** reintroduce comptime awareness into an emitter — push the
work into the transform pass instead.

## Codegen API surface (in `../codegen.zig`)

```text
compile(alloc, modules, io, config)        → ComptimeSession   (lex + parse + infer + transform)
codegenEmit(alloc, outputs, config)        → []ModuleOutput    (blind emit)
generate(alloc, modules, io, config)       = compile + codegenEmit  (convenience)
```

`ComptimeSession` owns the shared arena and the per-module `ComptimeOutput`;
its `deinit()` releases everything in one call.

## Entry-point convention

When the user module defines `fn main()` with zero args, both backends emit
an extra wrapper that `botopink run` invokes:

| Target | Wrapper | How `botopink run` invokes it |
|---|---|---|
| CommonJS | `function _botopink_main() { …top stmts; main(); } _botopink_main();` at end of file | `node out/main.js` runs the trailing call automatically |
| Erlang | `'_botopink_main'/0` (quoted atom to keep the leading `_`) + `main(_Args) -> '_botopink_main'().` | `escript out/main.erl` invokes `main/1` |
| BEAM ASM | `{function, '_botopink_main', 0, L}` tail-calls `main/0`; `{function, main, 1, L}` tail-calls `'_botopink_main'/0` | `erlc +from_asm out/main.S && erl -s main _botopink_main -s init stop` |
| WASM | `(func $_botopink_main (export "_botopink_main") (call $main))` | `wasmtime run --invoke _botopink_main out/main.wat` |

For Erlang the function name **must** be quoted (`'_botopink_main'`) because
plain identifiers may not start with `_` — `_botopink_main` alone would be
parsed as an unbound variable, not a function name.

## Configuration

`config.zig` exposes:

| Type | Purpose |
|---|---|
| `TargetSource` | `commonJS` \| `erlang` \| `beam` \| `wasm` |
| `ComptimeRuntime` | which external runtime evaluates comptime exprs (`node` for commonJS/wasm; `erlang` for erlang/beam) |
| `TypeDefLang` | optional secondary output (`typescript` for now) |
| `Config` | the bundle passed to `codegen.generate(...)` |

Add a new target by extending `Target`, wiring its emitter into
`codegen.zig`, and adding a snapshot directory under
`../../snapshots/codegen/<name>/<dialect>/`. Step-by-step in
[`./examples.md`](examples.md).

## Snapshot format

`../../snapshots/codegen/<slug>.snap.md` is multi-section:

```text
----- SOURCE CODE -- main.bp
...

----- COMPTIME JAVASCRIPT
...                              (empty when no comptime exprs)

----- JAVASCRIPT -- main.js
...

----- TYPESCRIPT TYPEDEF -- main.d.ts   (when configured)
```

Error snapshots live under `../../snapshots/codegen/errors/`.

## try / catch lowering

`try` / `catch` lower to **pattern matching on the `@Result` `Ok`/`Error` tag**
in every target — never to host exceptions (no JS `try/catch`, no Erlang
`try…catch`, no BEAM `try`/`try_case`). A `@Result` is represented as:

| Target | Ok | Error | tag test |
|---|---|---|---|
| commonJS | `{ ok: V }` | `{ error: E }` | `"error" in _t` |
| erlang / beam | `{ok, V}` | `{error, E}` | `is_tagged_tuple … {atom, ok}` |
| wasm | ptr; `[ptr]==0`, `[ptr+4]=V` | ptr; `[ptr]!=0`, `[ptr+4]=E` | `i32.load` of `[ptr]` |

- **Producer side**: inside a `#[@result]` fn (`-> @Result<…>`), inference records each
  `return`/`throw` site in `Env.result_jump_lowerings` and the transform pass
  rewrites them to `return __bp_ok(v)` / `return __bp_error(e)` builtin calls
  (`return try f()` drops the redundant unwrap and passes `f()` through), so
  every backend constructs the same `{ok, V}` / `{error, E}` value — `throw`
  never becomes a host exception in a `@Result` fn.
- `try expr` (no catch) unwraps `Ok`; on `Error` it short-circuits the enclosing
  function with the error variant. JS/BEAM/WAT use a real early `return`; Erlang
  (no early return) nests the rest of the body inside the `{ok, V}` arm — the
  same nesting handles an `if` whose then-branch ends in `return`
  (`emitEarlyReturnIf`).
- `try expr catch h` keeps the `Ok` value or applies the handler on `Error`
  (a lambda handler receives the unwrapped error). Emitted as an expression.
- Codegen is type-erased, so the *non-`@Result`* guard lives in inference
  (`tryUnwrapOrError` in `comptime/infer.zig`), not here.

## Notes

- All public functions use `alloc: std.mem.Allocator` (not `allocator`).
- Emitter structs may carry an `alloc` field, but it must always be supplied
  via `init`.
- All emitters are native Zig.
- `beam` — **0 unsupported across 143 snapshots.** Covers: numerics, locals
  (y-registers), calls (regular + tail), decl methods, booleans, assign/+=,
  throw, strings (`{literal, <<"…">>}`), `@print` → `io:format/2`, field
  access/assign (`get_map_elements`/`put_map_exact`), arrays → lists, tuples
  (`put_tuple2`), lambdas (`make_fun2` + deferred bodies, tail expr returned),
  `case` (all pattern types), try/catch, pipeline, method calls, loops (stub),
  break, `@Result`/`@Option` methods (`__bp_*` → `{ok, V}`/`{error, E}` match
  + `call_fun` closure application; option absence = `undefined`).
  Validated against `erlc +from_asm`.
- `wasm` — **0 unsupported across 143 snapshots.** Covers: numerics, locals,
  calls, assign/+=, `!x` → `i32.eqz`, null, `@todo`/`@panic` → `unreachable`,
  globals, entry wrapper. Strings/tuples/arrays/lambdas/loops emit numeric
  stubs (`i32.const 0`); `@print` as nop; case/pipeline/tryCatch/destructuring
  handled. `@Result`/`@Option` methods (`__bp_*`) lower to tag loads/branches
  over the linear-memory `[tag, payload]` layout (option absence = `0`);
  `map`/`flatMap` inline a literal closure body (no first-class funs).
  Runtime uses `wasmtime run --invoke _botopink_main`.
- Roadmap for both → [`/TODO.md`](../../../../TODO.md).

## See also

- Transform pass (what hands the AST to emitters) →
  [`../comptime/docs.md`](../comptime/docs.md).
- Runtime helpers for executing emitted code →
  [`../comptime/runtime/docs.md`](../comptime/runtime/docs.md).
- Step-by-step: adding a target → [`./examples.md`](examples.md).
