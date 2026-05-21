# compiler-core/src/codegen

> Path: `modules/compiler-core/src/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Per-target codegen backends. The public façade lives at `../codegen.zig`.

## Tree

```text
codegen/
├── AGENTS.md         ← you are here
├── config.zig        ← Config / Target (commonJS|erlang) / ComptimeRuntime / TypeDefLang
├── moduleOutput.zig  ← shared types: Module, ModuleOutput, GenerateResult
├── commonJS.zig      ← CommonJS emitter (blind: iterates transformed AST)
├── erlang.zig        ← Erlang emitter (blind)
├── typescript.zig    ← TypeScript `.d.ts` typedef generator
├── runtime.zig       ← runtime helpers used when executing generated JS/Erlang in tests
├── snapshot.zig      ← snapshot helpers for codegen tests
└── tests.zig         ← `assertJs`, `assertJsSingle`, `assertJsError`, …
```

## Entry-point convention

When the user module defines a `fn main()` with zero args, both backends emit
an extra entry-point wrapper:

| Target | Wrapper | How `botopink run` invokes it |
|---|---|---|
| CommonJS | `function _botopink_main() { …top stmts; main(); } _botopink_main();` at end of file | `node out/main.js` runs the trailing call automatically |
| Erlang | `'_botopink_main'/0` (quoted atom to keep the leading `_`) + `main(_Args) -> '_botopink_main'().` | `escript out/main.erl` invokes `main/1` |

For Erlang the function name **must** be quoted (`'_botopink_main'`) because
plain identifiers may not start with `_` — `_botopink_main` alone would be
parsed as an unbound variable, not a function name.

## Design: emitters are blind

The CommonJS / Erlang emitters know nothing about comptime specialization.
They only:

- iterate `program.decls` from the **already-transformed** AST
- render each `DeclKind` to the target language
- inlined comptime vals appear as plain decls (`const x = 6.28;`)
- specialized functions (`scale_$0`) are already present as regular `DeclKind.fn`
- calls are already rewritten to mangled names with comptime args removed

All specialization work happens earlier in
[`../comptime/transform.zig`](../comptime/AGENTS.md).

## Codegen API (`../codegen.zig`)

```text
compile(alloc, modules, io, config)        → ComptimeSession   (lex + parse + infer + transform)
codegenEmit(alloc, outputs, config)        → []ModuleOutput    (blind emit)
generate(...)                              = compile + codegenEmit  (convenience)
```

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

## Notes

- All public functions use `alloc: std.mem.Allocator` (renamed from `allocator`).
- Emitter structs may carry an `alloc` field, but it must always be supplied
  via `init`.
- No standalone JS/WASM codegen — JS and Erlang are produced natively in Zig.
