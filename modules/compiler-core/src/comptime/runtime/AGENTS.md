# compiler-core/src/comptime/runtime

> Path: `modules/compiler-core/src/comptime/runtime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Comptime execution on the Erlang VM: one long-lived `erl` process per compiler
process runs decorator bodies and template bodies. (Comptime `val`s are folded in
Zig by `../eval.zig` and never reach the VM.)

## Tree

```text
runtime/
├── AGENTS.md           ← you are here
└── persistent_erl.zig  ← singleton `erl` server: spawn, framed protocol, evalDetailed
```

## Files

| File | Role |
|---|---|
| `persistent_erl.zig` | Lazily spawns `erl -noshell -pa .botopinkbuild/tmp/persistent_erl -eval "botopink_comptime_server:start(), halt()."` after `erlc`-compiling the embedded server module. Decorator and template modules carry their own host functions (see `../decorator_eval.zig`, `../template_eval.zig`). **Protocol:** length-prefixed binary frames both ways — request `<u32 BE len><cmd:u8><path>` (cmd 1 = compile+run `.erl`), response `<u32 BE len><payload>` = `main/0`'s iodata result or a payload tagged `__BP_ERL_COMPILE_ERROR__:` / `__BP_ERL_RUNTIME_ERROR__:`. `readExact` loops over short reads. `main/0` runs in a `spawn_monitor`ed process killed after `eval_timeout_ms` (10s); a non-iodata result becomes a runtime-error frame. **API:** `evalDetailed` → `Response { ok, compile_error, runtime_error }` (payload owned by caller). A transport failure kills the child and marks the singleton broken; the next request respawns (the failed one is not retried). Pipes are serialised by a spin-lock. |

## Notes

- **Never inherit the parent's stdio into the `erl` child.** stdin/stdout are
  the protocol pipes; stderr goes to `.botopinkbuild/tmp/persistent_erl/erl.stderr.log`.
  An inherited stderr held open by an `erl` that outlives the test binary makes
  `zig build test` wait for EOF and fail with "test runner failed to respond".
- The VM must `halt()` when `start()` returns (stdin EOF = parent exited);
  otherwise every run leaks an orphan `beam.smp`.
- Output written by comptime code to `standard_io` would corrupt the frame
  stream — comptime modules return their result from `main/0` instead of printing.
