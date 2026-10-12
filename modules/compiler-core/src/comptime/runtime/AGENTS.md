# compiler-core/src/comptime/runtime

> Path: `modules/compiler-core/src/comptime/runtime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The comptime runtime and the one entry the evaluators call. **Comptime runs on wasm only**
(decision 434): a decorator, template or `comptime` body is lowered to an Erlang module
(`../../codegen/erlang.zig` `emitComptimeModule`), which this runtime parses, lowers to wasm,
links into std-wasm's term library (`modules/std-wasm`, decoded from `std_wasm.wasm` once per process, decision 450) and runs in-process on wasm3 (`persistent_wat.zig`, `wat/`) —
for every target (`erlang`, `beam`, `commonJS`, `wasm`) and for a compilation that names none. A
compile spawns no `erl`; building the compiler runs no `erlc`. A host function the body reaches
answers by std-wasm (`modules/std-wasm`), else its `@External.Wasm(fn: …)` cell
(`../host_cells.zig`); its `@External.Erlang` cell never runs at build, and nothing here calls
`modules/beam-to-wasm` — a standalone utility botopink does not use (decision 452). (Comptime `val`s are folded in Zig by `../eval.zig` and never reach it.)

Decision 84 sent erlang and beam builds to a BEAM runtime (a persistent `erl` node handed `.beam`
bytes); decision 434 deleted it — `persistent_beam.zig`, `beam/program.zig`, `server_source.zig`,
`render_resident.zig`, `parity.zig` and the resident modules `zig build` compiled with `erlc` are
gone. Its Erlang → BEAM lowering lives on as the beam target's template compiler
(`../../codegen/beam/erl_lower.zig`).

## Tree

```text
runtime/
├── AGENTS.md            ← you are here
├── runtime.zig          ← the entry: `evalWithArg` (one evaluation), `listingOf` (its `COMPTIME WAT` listing), `can_spawn`
├── persistent_wat.zig   ← the executor: a linked module on wasm3, in-process, its instance kept per module
├── stages.zig           ← observation-only stage clock (`BOTOPINK_COMPTIME_STAGES=<file>`), read by `scripts/comptime_bench.sh`
├── reply_order.zig      ← a reply's JSON objects read with sorted keys (a map's atom order is not part of the answer)
├── wat/                 ← Erlang → wasm: parse, lower, link into std-wasm's term library (`wat/AGENTS.md`)
├── prelude.zig          ← the host glue: two Erlang modules, rendered from erl_ast forms
└── etf.zig              ← `Term` → Erlang external term format, for the `main/1` argument
```

## Files

| File | Role |
|---|---|
| `runtime.zig` | **The entry.** `evalWithArg(arena, io, host, module, code, arg) → Response{ok, compile_error, runtime_error}`: builds the linked module (`wat/program.zig`; a construct the lowering refuses is a `compile_error` naming it) and runs it (`persistent_wat.zig`). `listingOf(arena, host, module, code, erl_listing) → []const u8` is what a snapshot shows: the generated module's functions lowered to wasm, then `main/1`'s argument as `;;` lines — or `;; not lowered: <reason>` (`COMPTIME WAT`). `can_spawn` (false on `wasm32`) is the RUN LOG executors' precondition (`../../codegen/runtime.zig`); the comptime runtime needs no process. Nothing is selected per target or per thread: there is one runtime. |
| `persistent_wat.zig` | The wat runtime's executor. `evalWithArg(alloc, key, wasm, arg)`, `key` the module atom (the content key `wat/program.zig` caches the bytes under): the module's wasm3 instance — environment + runtime (8 MiB interpreter stack — the lowering has no tail calls, so a body's recursion depth is its iteration count), `m3_ParseModule`/`m3_LoadModule` of an owned copy of the linked bytes — is created on the module's first evaluation and **kept** (`Kept`, at most `max_kept` = 16 per process, oldest dropped first; taken out of the list while it runs, so two threads never share one). Every later evaluation of that module first resets it to the state `m3_LoadModule` left — linear memory resized to its load-time pages (`ResizeMemory`, wasm3's `m3_env.h`, `@cImport`ed for it) and overwritten with its load-time bytes, every global set back to its load-time value — so what survives is only what is a function of the bytes (the parsed module and the code wasm3 compiled lazily on first call), and a body never sees what a previous call site left; an instance an engine trap interrupted is dropped, never reused (front 14 step 2: instance + run went from 0.34 + 0.37 ms to 0.03 + 0.11 ms per evaluation of an N=200 build). Nothing outlives the process (decision 229). Then exports: `bp_init()` (the arena starts past the literals), `rt_alloc(len)` + a copy of the ETF argument into linear memory, `bp_main(ptr, len)` → the reply binary (`rt_bin_ptr`/`rt_bin_len`), or 0 / `rt_pending()` → `runtime_error` = `rt_describe(rt_class(), rt_reason())` (`Class:Reason` as `~p`). An engine failure (parse, load, trap) carries wasm3's message. No child process, no file, no pipe; the module imports nothing, so a body cannot reach the compiler's stdout — its `io:format` goes to a buffer in its own memory. On `wasm32` (the browser build, step 5) wasm3 is not `@cImport`ed: the page's engine runs the module behind three host imports `modules/compiler-web/glue.js` serves — `bp_host.run_module(wasm, arg) → status` (0 reply, 1 runtime error, 2 module refused; the same export sequence as here, run by `WebAssembly.Instance`), `bp_host.result_len()`, `bp_host.result_copy(dst)`. |
| `stages.zig` | Observation only. `BOTOPINK_COMPTIME_STAGES=<file>` (absolute path) makes each timed stage append `<stage> TAB <ns>` to `<file>` (opened once, `O_APPEND`, one `write` per line): `memo_key` (`infer.zig`'s template memo key), `module` (the evaluator's `buildModule`), `encode` (`etf.encode`), `lower` (`wat/program.zig`, a cache hit after the first), `instance` / `run` (the kept instance's creation or reset; `bp_init` through the reply), `listing` (the trace listing), `outcome` (the reply parsed). Unset or empty, `start` answers 0 and `stop` returns: nothing is opened and no answer depends on it. Read once per process; a no-op on `wasm32`. `scripts/comptime_bench.sh`'s E-2 sums the lines (`scripts/AGENTS.md`). |
| `reply_order.zig` | `sortObjects(*std.json.Value)` / `canonical(alloc, text)`: a reply's objects with their keys sorted, recursively. A reply is `json:encode` of a map, and a map iterates atom keys in an atom-table order (`wat/rt.zig` `atomRank` approximates OTP's), not part of the answer. `../trace.zig` (the `COMPTIME REPLY` section) and `../template_eval.zig` `typedValue` (a map lifted by `@expr` becomes a labeled tuple whose label order is this) read replies in this order. |
| `prelude.zig` | The host glue every generated comptime module used to carry a copy of — 54 of the 295 lines of the smallest realistic module, byte-identical in every module the compiler has ever produced. It is rendered from the same `erl_ast` forms the generated modules are, into two Erlang modules the wat runtime parses once per process (`wat/program.zig`) and lowers, with what a generated module reaches of them, into its program: **`bp_comptime_template`** (the capture API `text/1`, `parts/1`, `source/1`, `context/1`, `bindings/1`, `lookup/2` — a name that is not one of the capture's `words` throws the template failure `lookup("<name>"): not a word of the template's text; …` with the capture's parameter, never `undefined` (decision 237) — `ref/1`; the result constructors `build/2`, `custom/3`, `expr/1`, `code/1`; the failure throws `fail/2`, `failAt/3`, `compilerError/1`; the reply encoder `'__bp_reply'/1`; and `erlang.comptime_helper_forms`) and **`bp_comptime_decorator`** (`fail/2`, `failAt/3`, `compilerError/1`, `emit/1`, `addMember/2`, `addMember/3` (decision 370 (2): `decl.addMember(name, <k>)` — the body's `k`-th member function, `../expr_param.zig` — replies `#{kind => memberFn, name, index}`), `setMeta/3`, `addType/3`, `'__bp_typedMeta'/2` (decision 298: `decl.setMeta(v)` / `decl.addMeta(v)` — the body's `k`-th typed meta call, `../expr_param.zig` — replies `#{kind => typedMeta, index, data}`, the value walked by `'__bp_metaJson'/1` first so a comptime `null` (`undefined`) encodes as JSON `null`), `'__bp_contribute'/1`, `'__bp_emitted'/0`, `'__bp_failArg'/2` (decision 364 (3): a body's `x.fail(m)` — `../expr_param.zig` — throws the fail tag with the span `#{arg => J}`, the parameter's index after `@Decl`, which the checker reports at that argument) and the same helpers — every output of a body is one tagged map, `#{kind => <<"emit">> | <<"member">>, source => …}` , `#{kind => <<"meta">>, key => …, value => …}` or `#{kind => <<"assoc">>, name => …, source => …}`, consed onto the one process-dictionary list `'__bp_emitted'/0` reads back; decision 216). The two cannot be one module: a template's `fail/2` throws `'__bp_template_fail'` with the capture's parameter name, a decorator's throws `'__bp_decorator_fail'` without it; each carries its own copy of the four untyped helpers so neither prelude has a cross-module call. A generated module reaches them by `-import` (`ComptimeModule.resident`, `../../codegen/erlang.zig`), which leaves the lowered body's own text unchanged. `exportRefs` derives both the prelude's `-export` and the generated module's `-import` from the same forms, so nothing can be imported that the prelude does not export. What stays in the generated module: the lowered body, the `'__bp_prim_…'` shims its own method calls reached, and `main/0`. |
| `etf.zig` | `codegen/beam/term.zig` values as Erlang's external term format, so a capture or a `@Decl` handle reaches the runtime as `binary_to_term/1`-format bytes (`wat/rt.zig`'s ETF reader) instead of a literal baked into the generated module — which is what leaves the module with nothing that depends on the call site. `encode(arena, term)` writes the version byte 131 and then the minimal tag for each variant: `SMALL_ATOM_UTF8_EXT`/`ATOM_UTF8_EXT` for an atom (and for `true`/`false`), `BINARY_EXT`, `SMALL_INTEGER_EXT`/`INTEGER_EXT`/`SMALL_BIG_EXT` by magnitude, `NEW_FLOAT_EXT`, `NIL_EXT`, `LIST_EXT` (never the `STRING_EXT` shorthand — one encoding per variant), `SMALL_TUPLE_EXT`/`LARGE_TUPLE_EXT`, `MAP_EXT`. **Not** source text re-parsed at comptime: that was the retired `'__bp_erl_eval'/2` shape, measured at ≈ 50× a direct call in `../../codegen/beam/AGENTS.md`. Inline tests assert byte vectors read off `binary_to_list(term_to_binary(T))` on OTP 29, so the encoder is pinned to the format rather than to itself. **The shapes that cross it** (front 14 step 3), each with a fixture whose reply the body reads back (`../tests/helpers.zig` `canonicalReplies`): a template capture — `#{'__bp_capture', text, parts, source, context, bindings, words}` (decision 237: `bindings` only the scope entries whose name is one of the text's `words`, so the term is O(text)), `parts` a list of `Text`/`Interp` maps with their spans, holes as placeholders (`round trip ---- a holed template's parts …`); the capture whose `bindings` carry another module's declaration, read back by `lookup` into an `@ExprCustom` tree (`… names a declaration of another module`); a plain argument's scalar; and the `@Decl` handle — `kind` atom, `name`, `fields` (`name`, `typeName`, `annotations`), `variants`, `methods` (`name`, `params`, `returnType`, `annotations`), `returnType`, `annotations` (`name`, raw `args`) (`round trip ---- a @Decl handle carries …`). | `../../codegen/beam/beam_file.zig` encodes a `.beam`'s `LitT` literals with it too.

## Limits

What the comptime runtime does not do — the only runtime's limits (decision 434). Each raises (or
is refused) where a body meets it, and a fixture in `persistent_wat.zig` pins it — except the
second, which has nothing to pin.

1. **No isolation, no timeout.** A runaway body is a runaway wasm3 call on the compiler's thread.
   No generated module spawns, receives or touches ETS, and the lowering refuses all three by name
   before anything runs (`spawn/1` as an undefined function, `` `receive` ``, `ets:new/2` not in
   the runtime) — fixture `limit 1`.
2. **No `~p` line breaking past 80 columns.** OTP's `io_lib_pretty` breaks a long term across
   lines; this runtime's `~p` prints it on one line. No fixture, because nothing raises: the
   difference is layout, not a failure. A body reaches `~p` only through `'__bp_text'/1` (a
   non-binary term as text, `../../codegen/erlang.zig`), and no fixture or library body formats a
   term that wide.
3. **No integer beyond 64 bits.** An `+`, `-` or `*` that overflows `i64`, or a float truncated
   past it, raises `{bp_wat_runtime, <<"integer beyond 64 bits (a bignum)">>}` — fixture `limit 3`.

Case mapping is no limit since decision 443: `string:uppercase` / `lowercase` / `titlecase` answer
over all of Unicode through std-wasm's `text.caseInto` — OTP's answer (the full mappings, no final
sigma) — fixture `Unicode case mapping answers OTP's`.

The core-module subset (`wat/AGENTS.md`: a linked module imports nothing — no WASI, no network, no
timer) holds too: comptime asks no I/O of the host.

## Notes

- **The browser build carries the same runtime.** `modules/compiler-web/` builds compiler-core for
  `wasm32-wasi`: the lowering, the linker and `std_wasm.wasm` (the term library) are compiled in, and the
  linked module runs on the page's engine through `bp_host` (`persistent_wat.zig`) — every
  target's comptime answers there as it does natively.
- **A body's output** (`io:format`) goes to a buffer in the module's own memory, never to the
  compiler's stdout.
