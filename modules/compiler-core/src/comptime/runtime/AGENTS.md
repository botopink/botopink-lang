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
| `persistent_erl.zig` | Lazily spawns `erl -noshell -pa .botopinkbuild/tmp/persistent_erl/<server_hash> -eval "botopink_comptime_server:start(), halt()."`. `prepareServer` builds that directory once per server source (Wyhash of `server_erl`): it writes the source and runs `erlc` in a random `<server_hash>.<nonce>.tmp` staging directory and renames it onto `<server_hash>/` — a warm directory skips `erlc`, and processes sharing a cwd never compile or load a truncated file (a lost rename race reuses the winner's identical `.beam`). Decorator and template modules carry their own host functions (see `../decorator_eval.zig`, `../template_eval.zig`). **Protocol:** length-prefixed binary frames both ways — request `<u32 BE len><cmd:u8><path>` (cmd 1 = compile+run `.erl`), response `<u32 BE len><payload>` = `main/0`'s iodata result or a payload tagged `__BP_ERL_COMPILE_ERROR__:` / `__BP_ERL_RUNTIME_ERROR__:`. `readExact` loops over short reads. `main/0` runs in a `spawn_monitor`ed process killed after `eval_timeout_ms` (10s), with `standard_error` as its group leader; a non-iodata result becomes a runtime-error frame. At start the server moves the default logger handler to `standard_error`. `readFrame` refuses a length above `max_frame_len` (16 MiB) before allocating. **API:** `evalDetailed` → `Response { ok, compile_error, runtime_error }` (payload owned by caller). A transport failure kills the child and marks the singleton broken — `error.PersistentErlFrameTooLarge` for an over-cap frame, `error.PersistentErlBroken` otherwise — and `lastTransportError()` holds the message until the next request; the next request respawns (the failed one is not retried). Pipes are serialised by a spin-lock. Inline tests: concurrent `prepareServer` calls on a cold directory, a printing/logging body keeps the frame stream clean, an over-cap frame is a transport error followed by a respawn, and `readFrame` against a file. |

## Notes

- **Never inherit the parent's stdio into the `erl` child.** stdin/stdout are
  the protocol pipes; stderr goes to `.botopinkbuild/tmp/persistent_erl/erl.stderr.log`.
  An inherited stderr held open by an `erl` that outlives the test binary makes
  `zig build test` wait for EOF and fail with "test runner failed to respond".
- The VM must `halt()` when `start()` returns (stdin EOF = parent exited);
  otherwise every run leaks an orphan `beam.smp`.
- **stdout carries frames and nothing else.** Three writers used to share it:
  the frames, the default logger handler (a SIGTERM prints `SIGTERM received`
  through it) and whatever `main/0` printed through its inherited group leader.
  The server now moves the logger handler to `standard_error` and runs `main/0`
  (and every process it spawns) with `standard_error` as group leader, so
  `io:format/1`, `io:get_line/1` and log events from a comptime body land in
  `erl.stderr.log`. A body that writes to `user` explicitly still bypasses both;
  text there reads as a length far past `max_frame_len`, so it fails as
  `error.PersistentErlFrameTooLarge` with a message instead of a multi-GiB
  allocation.
- **`erl.stderr.log` is a write-only debug log, by decision.** It holds erl's own
  stderr, the logger's output and everything comptime bodies print. It is
  truncated at every spawn and has one path per cwd, not per spawn: processes
  running in the same cwd (parallel test binaries, two builds) interleave and
  truncate each other's output, so it is best-effort. Nothing in the compiler
  reads it back, and it is not surfaced into diagnostics (a comptime failure already carries its Erlang
  diagnostic in the reply frame); the transport-error message names the path so
  a broken stream points at it. Read it by hand when a comptime body misbehaves.
