# Erlang comptime execution — speed-optimised pipeline

**Version:** 1.0.0-beta
**Status:** completed
**Created:** 2026-06-29
**Author:** ericfillipe

---

## Status

**Current:** completed

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | BEAM bytecode cache for comptime modules | pending | |
| Step 2 | Switch template/decorator eval to persistent erl | pending | |
| Step 3 | Compile template_runtime.bp to BEAM prelude | pending | |
| Step 4 | Binary protocol: replace JSON-line with length-prefixed frames | pending | |
| Step 5 | Erlang port protocol for sub-ms round-trips | pending | |
| Step 6 | Parallel comptime evaluation within single erl instance | pending | |
| Step 7 | Remove persistent_node.zig (Node.js fallback) | pending | |
| Step 8 | Full test suite + snapshot regeneration | pending | |

## Objective

Complete the persistent-erl comptime pipeline so every comptime expression,
template body, and decorator body executes inside a single long-lived `erl`
process — **the sole comptime runtime** — with zero Node.js dependency,
zero runtime dispatch, and response latency measured in microseconds, not
milliseconds.

The current pipeline (after `persistent-erl-runtime` spec) has:

| Component | Runtime | Latency |
|-----------|---------|---------|
| Comptime vals (literals, ops, collections) | Persistent erl | ~2ms |
| Template bodies | Node.js (fallback) | ~15ms |
| Decorator bodies | Node.js (fallback) | ~15ms |

The erl path for templates/decorators returns `error.EvalFailed` — the Node.js
fallback is still active because `erlang.zig` lacks template body emission and
`#[@Host]` methods in `template_runtime.bp` have no Erlang target.

Target state — single `erl` runtime:

| Component | Runtime | Latency |
|-----------|---------|---------|
| Comptime vals | Persistent erl | ~0.3ms |
| Template bodies | Persistent erl | ~1ms |
| Decorator bodies | Persistent erl | ~1ms |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    botopink (Zig)                    │
│                                                     │
│  comptime.bp ──→ beam_asm.zig ──→ .beam bytes      │
│  template.bp ──→ erlang.zig   ──→ .erl source      │
│                                                     │
│              ┌──────────────────────┐               │
│              │   persistent_erl.zig │               │
│              │   (length-prefixed   │               │
│              │    binary frames)    │               │
│              └──────────┬───────────┘               │
└─────────────────────────┼──────────────────────────┘
                          │ stdin/stdout pipe
                  ┌───────┴────────┐
                  │      erl       │  (single process,
                  │  -noshell      │   spawned once)
                  │                │
                  │  Server loop:  │
                  │  ┌──────────┐  │
                  │  │ compile  │  │
                  │  │ load     │  │
                  │  │ execute  │  │
                  │  │ respond  │  │
                  │  └──────────┘  │
                  └────────────────┘
```

### Protocol evolution

```
CURRENT (persistent-erl-runtime):
  Zig → erl: "eval /path/to/module.erl\n"
  erl → Zig: "[{...}]\n"
  Per eval: compile:file + code:load_binary + Mod:main()

TARGET (this spec):
  Zig → erl: <4-byte-len><erl-source-bytes>
  erl → Zig: <4-byte-len><json-bytes>
  Per eval: compile:file (cached) + Mod:main()
```

## Steps

### Step 1 — BEAM bytecode cache for comptime modules

**Status:** pending

**Description:**
Add a BEAM bytecode cache keyed by Wyhash of the Erlang source. Cache lives
in `.botopinkbuild/tmp/beam_cache/`. On cache hit, skip `compile:file` and
directly `code:load_binary` the cached BEAM bytes.

Cache structure:
```
.botopinkbuild/tmp/beam_cache/<hash>.beam
```

The persistent erl server checks the cache directory before calling
`compile:file`. The Zig side pre-writes cached `.beam` files to avoid
the `compile:file` overhead on repeat evaluations.

**Acceptance criteria:**
- Identical comptime entries produce identical hash
- Cache hit skips `compile:file` entirely
- Cache miss compiles and stores
- `clean-tmp` reaps stale cache entries

### Step 2 — Switch template/decorator eval to persistent erl

**Status:** pending

**Description:**
Replace `evaluateErl()` stubs in `template_eval.zig` and `decorator_eval.zig`
with real implementations:

1. Compile the template/decorator body to Erlang source via `erlang.zig`
   codegen backend. The Erlang codegen must:
   - Emit a `-module(...)` wrapper
   - Lower captures to Erlang terms (binary descriptor format)
   - Map `#[@Host]` method calls to `botopink_comptime_prelude:lookup(Desc, Name)` etc.
   - Emit an entry function that calls the template body and returns the outcome

2. Write the Erlang source to a tmp `.erl` file

3. Call `persistent_erl.eval(path)` — the persistent erl compiles and executes

4. Parse the JSON outcome (same format as today's Node.js path)

**Erlang codegen for template bodies:**

For each `#[@Host]` method in `template_runtime.bp`, the Erlang codegen emits
a call to the prelude module:

| BP method | Erlang target |
|-----------|---------------|
| `capture.lookup(name)` | `botopink_comptime_prelude:lookup(Desc, Name)` |
| `capture.bindings()` | `botopink_comptime_prelude:bindings(Desc)` |
| `capture.parts()` | `botopink_comptime_prelude:parts(Desc)` |
| `capture.context()` | `botopink_comptime_prelude:context(Desc)` |
| `failRaw(msg, param, span)` | `botopink_comptime_prelude:fail_raw(Msg, Param, Span)` |
| `compilerError(msg)` | `botopink_comptime_prelude:compiler_error(Msg)` |

**Acceptance criteria:**
- `evaluateErl()` executes template bodies end-to-end
- `__expr`, `__code`, `__capture`, `Span`, `CustomNode` constructors work
- `__failRaw` / `__compilerError` surface errors correctly
- Template snapshot tests pass on the erl path
- Node.js path still available as opt-in fallback

### Step 3 — Compile template_runtime.bp to BEAM prelude

**Status:** pending

**Description:**
The `template_runtime.bp` stdlib module currently compiles to WAT (removed)
or is interpreted by the Node.js runtime. Compile it to BEAM bytecode via
`beam_asm.zig` and load it into the persistent erl at warmup time.

The compiled module provides Erlang-native implementations of:
- Record types: `Span`, `CustomNode`, `Capture`, `DeclHandle`
- Constructors: `makeExpr`, `makeCode`, `makeCapture`, `makeCustom`
- Field getters: `Capture.text`, `Capture.source`, `Capture.build`

Methods marked `#[@Host]` (lookup, bindings, context, parts, custom, failRaw,
compilerError) remain in the Erlang prelude module (`erl_prelude.zig`).

**Acceptance criteria:**
- `template_runtime.bp` compiles to valid BEAM via `beam_asm.zig`
- Compiled BEAM module loads into persistent erl at warmup
- Template bodies can call `template_runtime:makeExpr(Value)` etc.
- No Node.js needed for template surface types

### Step 4 — Binary protocol: replace JSON-line with length-prefixed frames

**Status:** pending

**Description:**
Replace the current stdin/stdout line protocol (`eval <path>\n` / `<json>\n`)
with length-prefixed binary frames:

```
FRAME = <len: u32 BE><payload: len bytes>
```

Zig side sends: `<4-byte-len><erl-source-bytes>`
Erl side responds: `<4-byte-len><json-result-bytes>`

Advantages over line protocol:
- No escaping needed (binary-safe)
- No line parsing overhead
- Fixed-size header (4 bytes vs variable-length hex + newline)
- Natural fit for Erlang's `{packet, 4}` port option

The server module is updated to use Erlang's `{packet, 4}` framing on stdin:

```erlang
start() ->
    {ok, _} = io:setopts(standard_io, [{packet, 4}, binary]),
    loop().
loop() ->
    receive
        {io_request, From, ReplyAs, {put_chars, _Data}} ->
            %% capture stdout via group_leader
            ...
    after 0 ->
        case io:get_chars("", 0) of
            ...
        end
    end.
```

**Acceptance criteria:**
- Binary frames round-trip correctly
- JSON output is identical to line protocol
- No regression in comptime val evaluation
- Latency improvement measurable (byte parsing vs line parsing)

### Step 5 — Erlang port protocol for sub-ms round-trips

**Status:** pending

**Description:**
Upgrade from stdin/stdout pipes to Erlang's native port protocol — the same
mechanism OTP uses for C Node and port drivers. The Zig side opens the `erl`
process as a port with `{packet, 4}` framing:

```bash
erl -noshell -pa <dir> -eval 'Port = open_port({fd, 0, 1}, [binary, {packet, 4}]), port_loop(Port).'
```

The Erlang port loop receives binary frames, dispatches to compile/execute,
and responds with binary frames. Benefits over stdin/stdout:
- Erlang's built-in packet framing (no manual length parsing)
- Port messages are delivered to Erlang process mailbox (no io:get_line polling)
- Lower overhead than `io:get_line` + `io:format`

Zig side still writes to stdin / reads from stdout (the port is mapped to
fds 0 and 1). The protocol is the same length-prefixed binary frames from
Step 4, but the Erlang side uses `{packet, 4}` for zero-cost framing.

**Acceptance criteria:**
- Port loop replaces `io:get_line` polling
- Same binary frame protocol
- Comptime eval latency drops to ~0.3ms per call (BEAM cache hit)

### Step 6 — Parallel comptime evaluation within single erl instance

**Status:** pending

**Description:**
The persistent erl process is single-threaded, but the BEAM VM supports
lightweight processes. Enable concurrent comptime evaluations by spawning
one Erlang process per eval request, each with its own isolated module
namespace.

```erlang
loop() ->
    receive
        {eval, From, Source} ->
            spawn(fun() ->
                {ok, Mod, Beam} = compile:forms(Source, [binary, return]),
                {module, _} = code:load_binary(Mod, "", Beam),
                Result = Mod:main(),
                From ! {result, Result}
            end),
            loop()
    end.
```

Zig side sends multiple eval requests without waiting for responses, then
collects results. This amortises the single-threaded bottleneck across
multiple parallel test invocations.

Note: `compile:file` writes to disk and may have global state. Use
`compile:forms` (in-memory compilation) for thread-safe concurrent evals.

**Acceptance criteria:**
- Multiple eval requests can be in-flight simultaneously
- Results are matched to requests by correlation ID
- No data races or module name collisions
- Throughput improves on multi-eval test suites

### Step 7 — Single runtime: remove persistent_node.zig and Node.js path

**Status:** pending

**Description:**
The persistent erl subprocess becomes the **sole comptime runtime**. Every
comptime expression, template body, and decorator body executes in the same
`erl` process. There is no fallback, no alternative, no dispatch table.

Delete the Node.js comptime path entirely:
- `modules/compiler-core/src/comptime/runtime/persistent_node.zig` — **deleted**
- `evaluateNode()` functions from `template_eval.zig` and `decorator_eval.zig` — removed
- Node.js prelude (~80 lines of inline JS) from both files — removed
- `.node` and `.wat` variants from `Runtime` enums — collapsed to single path
- `persistent_node` import from `codegen/runtime.zig` — removed
- `warmPersistentNodeRunner` from `comptime.zig` — already removed

The `executeJavaScript` function in `codegen/runtime.zig` stays — it spawns
`node` on demand for user-facing commonJS codegen snapshots. That is
**codegen output verification, not comptime**.

**Single runtime contract:**

```
                    ┌──────────┐
  .bp comptime ────→│   erl    │────→ results
  .bp template  ───→│(persist.)│
  .bp decorator ───→│          │
                    └──────────┘
```

No `if runtime == .erl` branching. No `catch fallback to node`. The erl
process is spawned once at compiler startup. If it dies, the compiler
reports a clear diagnostic and exits — there is no second runtime to
paper over the failure.

**Acceptance criteria:**
- `persistent_node.zig` no longer exists
- `Runtime` enums have a single variant or are removed entirely
- `zig build test` passes with exactly one comptime runtime
- `grep -r "persistent_node\|evaluateNode\|evaluateWat" modules/compiler-core/src/comptime/` returns zero matches
- Compiler has zero Node.js code paths for comptime

### Step 8 — Full test suite + snapshot regeneration

**Status:** pending

**Description:**
Run the complete test matrix with the new erl pipeline:
```bash
zig build test           # compiler-core + language-server + cli
zig build test-libs      # all libs/* packages
zig build test-backends  # BEAM/WASM/Erlang execution parity
```

Regenerate all comptime snapshots. Template and decorator snapshots must
produce semantically equivalent results to the Node.js path.

Benchmark comptime eval latency and verify against targets.

**Acceptance criteria:**
- Full test suite passes (erl on PATH)
- Comptime val eval: ~0.3ms per call (with BEAM cache)
- Template eval: ~1ms per call
- No Node.js dependency for any comptime path

---

## Latency targets

| Benchmark | Pre-spec | Step 1-2 | Step 4-5 | Step 6 |
|-----------|----------|----------|----------|--------|
| Comptime val (cache miss) | ~50ms (erlc+erl spawn) | ~2ms | ~2ms | ~0.5ms |
| Comptime val (cache hit) | ~50ms | ~2ms | ~0.3ms | ~0.1ms |
| Template body | ~15ms (Node.js) | ~3ms | ~1ms | ~0.5ms |
| 100 evals (batch) | ~5s | ~200ms | ~30ms | ~10ms |

---

## Scope

What changes:
- `comptime/runtime/persistent_erl.zig` — binary protocol + BEAM cache
- `comptime/runtime/erl_prelude.zig` — extended with performance-critical functions
- `comptime/template_eval.zig` — replace JS prelude with Erlang codegen
- `comptime/decorator_eval.zig` — same
- `codegen/erlang.zig` — add template body emission
- `libs/std/src/template_runtime.bp` — add Erlang target annotations

What does NOT change:
- User-facing codegen backends (commonJS, TypeScript, Erlang, BEAM, WASM)
- The BEAM codegen backend (`beam_asm.zig`) — reused as-is
- LSP analysis

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-29 | Spec created | ericfillipe |
