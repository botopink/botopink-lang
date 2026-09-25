# compiler-core/src/comptime/runtime

> Path: `modules/compiler-core/src/comptime/runtime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Comptime execution on the Erlang VM: one long-lived `erl` process per compiler
process runs decorator bodies and template bodies. (Comptime `val`s are folded in
Zig by `../eval.zig` and never reach the VM.)

## Tree

```text
runtime/
├── AGENTS.md            ← you are here
├── prelude.zig          ← the resident host glue: two Erlang modules, rendered from erl_ast forms
├── server_source.zig    ← the resident server's Erlang source (no imports; shared by the runtime and the renderer)
├── render_resident.zig  ← BUILD-TIME tool: writes the three `.erl` for `erlc` (root build.zig runs it)
├── etf.zig              ← `Term` → Erlang external term format, for the `main/1` argument
└── persistent_erl.zig   ← singleton `erl` server: spawn + embedded-`.beam` handshake, framed protocol, eval*WithArg
```

**How the three resident modules reach the node (decision 83, front 18 step 1c).**
`zig build` runs `render_resident` on the host with an output directory; it writes
`botopink_comptime_server.erl` (`server_source.source`), `bp_comptime_template.erl`
and `bp_comptime_decorator.erl` (`prelude.modules`); `erlc +deterministic -o <dir>`
compiles the three; the `.beam`s become anonymous imports of compiler-core and
`persistent_erl.zig` `@embedFile`s them (`resident_beams`). At spawn, `erl -noshell
-eval <bootstrap>` receives one cmd-4 frame per module over stdin, `code:load_binary/3`s
each, answers `ok` and calls `botopink_comptime_server:start()`. No `erlc` runs on a
user's machine, no `-pa` directory exists, and `.botopinkbuild/tmp/persistent_erl/`
holds only `erl.<id>.stderr.log`, one per process. `erlc` (OTP 28+) is therefore a dependency of **building**
the compiler — the renderer's module root has to be compiler-core's `src/`, so
`build.zig` copies the tree's `.zig` files into the cache with a one-line root
(`render_resident_main.zig`) beside them; nothing is added to the source tree for it.

## Files

| File | Role |
|---|---|
| `prelude.zig` | The host glue every generated comptime module used to carry a copy of — 54 of the 295 lines of the smallest realistic module, byte-identical in every module the compiler has ever produced. It is rendered from the same `erl_ast` forms the generated modules are, into two Erlang modules compiled once at server warmup: **`bp_comptime_template`** (the capture API `text/1`, `parts/1`, `source/1`, `context/1`, `bindings/1`, `lookup/2`, `ref/1`; the result constructors `build/2`, `custom/3`, `expr/1`, `code/1`; the failure throws `fail/2`, `failAt/3`, `compilerError/1`; the reply encoder `'__bp_reply'/1`; and `erlang.comptime_helper_forms`) and **`bp_comptime_decorator`** (`fail/2`, `failAt/3`, `compilerError/1`, `emit/1`, `'__bp_emitted'/0` and the same helpers). The two cannot be one module: a template's `fail/2` throws `'__bp_template_fail'` with the capture's parameter name, a decorator's throws `'__bp_decorator_fail'` without it; each carries its own copy of the four untyped helpers so neither prelude has a cross-module call. A generated module reaches them by `-import` (`ComptimeModule.resident`, `../../codegen/erlang.zig`), which leaves the lowered body's own text unchanged — the `COMPTIME ERLANG` snapshots are byte-identical across the move. `exportRefs` derives both the prelude's `-export` and the generated module's `-import` from the same forms, so nothing can be imported that the prelude does not export. What stays in the generated module: the lowered body, the `'__bp_prim_…'` shims its own method calls reached, and `main/0`. |
| `etf.zig` | `codegen/beam/term.zig` values as Erlang's external term format, so a capture or a `@Decl` handle reaches the node as `binary_to_term/1` input instead of a literal baked into the generated module — which is what leaves the module with nothing that depends on the call site. `encode(arena, term)` writes the version byte 131 and then the minimal tag for each variant: `SMALL_ATOM_UTF8_EXT`/`ATOM_UTF8_EXT` for an atom (and for `true`/`false`), `BINARY_EXT`, `SMALL_INTEGER_EXT`/`INTEGER_EXT`/`SMALL_BIG_EXT` by magnitude, `NEW_FLOAT_EXT`, `NIL_EXT`, `LIST_EXT` (never the `STRING_EXT` shorthand — one encoding per variant), `SMALL_TUPLE_EXT`/`LARGE_TUPLE_EXT`, `MAP_EXT`. **Not** source text re-parsed in the node: that is the `'__bp_erl_eval'/2` shape, measured at ≈ 50× a direct call in `../../codegen/beam/AGENTS.md`. Inline tests assert byte vectors read off `binary_to_list(term_to_binary(T))` on OTP 29, so the encoder is pinned to the format rather than to itself. |
| `server_source.zig` | The resident server's Erlang source as a Zig string (`module_name` = `botopink_comptime_server`, `eval_timeout_ms` = 10 s spliced in as `-define(EVAL_TIMEOUT_MS, …)`, `source`). It has no imports of its own because two programs read it: the runtime, which embeds the compiled `.beam` and documents the protocol, and the build-time renderer, which must not import the runtime (the runtime embeds what the renderer produces). The protocol itself — `loop/0`'s four commands, `compile_then`/`load_then`, `load_beam`, `safe_call`, `read_frame`/`write_frame` — is described under `persistent_erl.zig`. |
| `render_resident.zig` | **Build-time tool, never linked into the compiler.** `main(init)` takes one argument, an output directory, and writes `botopink_comptime_server.erl` (`server_source.source`), `bp_comptime_template.erl` and `bp_comptime_decorator.erl` (`prelude.modules`). Root `build.zig` runs it (`render-resident`, host target, its own host-targeted `std_prelude`) with an `addOutputDirectoryArg`, feeds the three files to `erlc +deterministic -o <out>` and hands the `.beam`s to compiler-core (and its test module) as anonymous imports. Its analysed closure is small (the prelude forms, `erl_ast`, `erl_emitter`, `erlang.comptime_helper_forms`) — ≈ 0.4 s to compile, cached like any artifact; `erlc` runs again only when a source changes. |
| `persistent_erl.zig` | Lazily spawns `erl -noshell -eval <bootstrap_eval>` with stdin/stdout piped and stderr → `.botopinkbuild/tmp/persistent_erl/erl.<id>.stderr.log`, where `<id>` is 64 random bits drawn once per process (`ensureStderrLogPath`; `stderrLogPath()` is what a diagnostic names) — the directory is created for the log alone, and is fixed, so two compilers sharing this cwd used to hand their two children ONE path and truncate each other's live log. **The three resident modules are embedded** (decision 83): `resident_beams` = `@embedFile("botopink_comptime_server.beam")` / `bp_comptime_template.beam` / `bp_comptime_decorator.beam`, produced by `erlc` at `zig build` from `server_source.zig` and `prelude.zig` via `render_resident.zig`. `bootstrap_eval` (Erlang, `erl_eval`-interpreted so it runs on any release) is `bootstrap_bindings` (`Floor = 28, Count = 3, Server = botopink_comptime_server,`) ++ the script: latin1 binary stdio; the default logger handler moved to `standard_error` *before* the first load (a loader's `=ERROR REPORT` would otherwise land on stdout ahead of the reply and read as a multi-GiB frame length); **decision 86's floor** — `Rel < Floor` answers one frame `__BP_ERL_BELOW_FLOOR__:erl is Erlang/OTP N; … needs OTP 28 or later` and `halt(3)`; then `Count` cmd-4 frames read from stdin and `code:load_binary/3`'d; every failure collected into one `__BP_ERL_LOAD_ERROR__:[{Mod, Reason}…]; erl is Erlang/OTP N and the embedded modules were compiled by the erlc that built this compiler` frame; success answers `ok` and calls `Server:start()`; `halt()` when `start/0` returns (stdin EOF). `ensureSpawned` spawns, then `handshake` sends one cmd-4 frame per `resident_beams` entry (`namedPayload`) and reads the one reply: `ok` → ready; the floor tag → `setTransportError(message)` + `error.PersistentErlBelowFloor`; anything else → `error.PersistentErlBroken` with the detail; the child is killed on any handshake failure and the singleton marked broken. A missing `erl` fails at `std.process.spawn` with no message, so the evaluators' PATH hint still fires. **Protocol:** length-prefixed binary frames both ways — request `<u32 BE len><cmd:u8><payload>`, response `<u32 BE len><payload>` = `main`'s iodata result or a payload tagged `__BP_ERL_COMPILE_ERROR__:` / `__BP_ERL_RUNTIME_ERROR__:`. Four commands: **cmd 1** compile+load `<path>` and run `main/0` (the one-shot path, kept for a self-contained module and for this file's regression tests), **cmd 2** compile+load `<path>` and answer the module atom, **cmd 3** call `<module>:main(<term>)` where the payload is `<u16 BE namelen><module><external term>`, **cmd 4** (front 18 step 1b) load `.beam` **bytes** carried in the frame — payload `<u16 BE namelen><module><beam bytes>`, no file, no `compile:file` — and answer the module atom; a `code:load_binary/3` rejection (`badfile`, an opcode above what the running release knows) comes back on the `__BP_ERL_COMPILE_ERROR__:` channel as `{load_binary, Mod, Reason}`, so the evaluators read a refused `.beam` exactly as they read a refused `.erl`. `compile_then`/`load_then` are shared by 1 and 2, `load_beam` serves 4, and `code:purge/1` runs before each load — one module serves every call site of a declaration, so a reload means the declaration changed. `readExact` loops over short reads. `main` runs in a `spawn_monitor`ed process killed after `server_source.eval_timeout_ms` (10 s), with `standard_error` as its group leader; a non-iodata result becomes a runtime-error frame. `readFrame` refuses a length above `max_frame_len` (16 MiB) before allocating. **API:** `evalDetailed` (cmd 1), `evalWithArg` (cmd 2 when this process has not loaded that module, then cmd 3) and `evalBeamWithArg` (the same with cmd 4 for `.beam` bytes assembled by `../../codegen/beam/beam_file.zig` — the evaluators will hand it the assembled module once `beam_asm.zig`'s untyped mode exists; today only its test does) → `Response { ok, compile_error, runtime_error }` (payload owned by caller). Both `…WithArg`s are one `evalLoaded(Load { erl_path | beam })`, which holds one lock across both commands so no thread slips between the load and the call; the `loaded` set of module atoms it keys off is cleared whenever a transport failure marks the singleton broken, because the respawned VM has loaded nothing. A transport failure kills the child and marks the singleton broken — `error.PersistentErlFrameTooLarge` for an over-cap frame, `error.PersistentErlBroken` otherwise — and `lastTransportError()` holds the message until the next request; the next request respawns (the failed one is not retried). Pipes are serialised by a spin-lock. Inline tests: the three embedded `.beam`s carry `FOR1`/`BEAM` and their atom, and the bootstrap names the floor, the count and the server; a printing/logging body keeps the frame stream clean; an over-cap frame is a transport error followed by a respawn; `readFrame` against a file; and cmd 4: `main(X) -> X.` assembled by `beam_file.zig` echoes its ETF argument twice (load+call, then call alone) and garbage bytes come back as `compile_error` naming `load_binary`/`badfile` without entering `loaded`. The file also holds a `comptime { _ = beamFile; }` reference so the assembler's and the opcode table's inline tests stay in the suite under any `-Dtest-filter` until `codegen/tests.zig` lists them. |

## Notes

- **Never inherit the parent's stdio into the `erl` child.** stdin/stdout are
  the protocol pipes; stderr goes to `.botopinkbuild/tmp/persistent_erl/erl.<id>.stderr.log`.
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
  `erl.<id>.stderr.log`. A body that writes to `user` explicitly still bypasses both;
  text there reads as a length far past `max_frame_len`, so it fails as
  `error.PersistentErlFrameTooLarge` with a message instead of a multi-GiB
  allocation.
- **`erl.<id>.stderr.log` is a write-only debug log, by decision.** It holds
  erl's own stderr, the logger's output and everything comptime bodies print. It
  is truncated at every spawn and has one path per **process**, not per spawn:
  `<id>` is 64 random bits drawn once (`ensureStderrLogPath`), so two compilers
  sharing this cwd (parallel test binaries, two builds) no longer truncate each
  other's live log — a respawn inside one process still truncates its own. Nothing in the compiler
  reads it back, and it is not surfaced into diagnostics (a comptime failure already carries its Erlang
  diagnostic in the reply frame); the transport-error message names the path so
  a broken stream points at it. Read it by hand when a comptime body misbehaves.
- **Who reads `lastTransportError()`.** `transportFailure` in
  [`../template_eval.zig`](../template_eval.zig) and in
  [`../decorator_eval.zig`](../decorator_eval.zig) — the two callers of
  `evalDetailed` / `evalWithArg`, and the only readers outside this file
  (`grep -rn lastTransportError modules/` is those two call sites, this file's
  declaration and its three inline regression tests). A failure that left a
  message becomes the diagnostic `the <template|decorator> evaluator's erl
  runtime failed (<error name>): <message>`; a failure that left none stays
  `error.EvalFailed`, because that case is `erl` or `erlc` missing and the
  caller's hint for it names `PATH` (`erl` only, now: `erlc` left the run-time
  path with decision 83 — a machine that builds the compiler needs it, a machine
  that runs it does not).
- **Below the floor.** An `erl` older than OTP 28 is refused by the bootstrap
  before any module is loaded, with both releases in the message
  (`error.PersistentErlBelowFloor`, carried by `lastTransportError`). The
  embedded `.beam`s were compiled by the `erlc` that built the binary, so a
  compiler built with a newer OTP than the machine's `erl` refuses too, as
  `__BP_ERL_LOAD_ERROR__` naming the module and `badfile`. Neither can be
  configured away (decision 67).
