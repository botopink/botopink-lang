# lib-test-runner

> Path: `modules/lib-test-runner/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink-lib-test` executable: the CI gate that runs
every discovered project's test suite on each requested backend and aggregates
the results into a lib×target matrix. Projects are discovered across the resolved
**root list** (`discovery.resolveRoots`: `BOTOPINK_LIB_ROOTS` env entries →
bundled `repository/botopink-lang/libs` → sibling `repository/` → legacy flat
`libs/` → any `--lib-root` flag entries, de-duped first-occurrence-wins;
first-root-wins by name). It **shells out to the installed `botopink` binary** (`botopink test
--target <t>` with `cwd` set to each lib's own directory) and touches no compiler
internals — so it carries **no `compiler-core` dependency**. Its job is discovery
+ fan-out + aggregation + exit code, nothing the compiler already does.

## Tree

```text
lib-test-runner/
├── AGENTS.md            ← you are here
├── build.zig            ← package build graph + `run` + `test` steps
├── build.zig.zon        ← manifest (no dependencies — self-contained)
└── src/
    ├── main.zig         ← entry: resolve roots/binary → discover → run cells → matrix → exit
    ├── args.zig         ← CLI parsing (Target enum, node alias, =-form, all)  + unit tests
    ├── discovery.zig    ← enumerate <root>/*/ with botopink.json across roots, "has tests" probe + unit tests
    ├── runner.zig       ← per-(lib,target) `botopink test` spawn + status classification
    └── matrix.zig       ← Status enum, lib×target matrix render, summary + unit tests
```

## Commands

```bash
# from the workspace root:
zig build test-libs                                   # every lib, commonJS+erlang
zig build test-libs -- --target erlang --lib rakun    # one target, one lib
zig build test-libs -- --target all --strict          # supported targets, strict

# from this package:
zig build               # produce ./zig-out/bin/botopink-lib-test
zig build test          # arg-parsing + discovery + matrix unit tests
```

## CLI surface

```
botopink-lib-test [--target <t>[,<t>…] | --target all] [--lib <name>]
                  [--filter <s>] [--strict] [--bin <path>] [--lib-root <dir>]
                  [--json]
```

`--json` switches output from the text matrix to JSONL — see
"Test output passthrough (§T)" below for the schema.

- `--target` — repeatable / comma-separated. Accepts `commonJS|erlang|beam|wasm`
  plus the alias `node`→`commonJS`, and both `--target <t>` and `--target=<t>`.
  Default: `commonJS,erlang`. `all` expands to every *supported* target.
- `--lib <name>` — restrict to one project by name across roots (default: every
  project with a `botopink.json`).
- `--filter <s>` — forwarded to `botopink test --filter`.
- `--strict` — treat an unsupported target (beam/wasm) as a **failure** instead of
  a skip (default: skip with `~`, keeping the gate green until those backends run).
- `--bin <path>` — `botopink` binary path. Also read from `BOTOPINK_BIN`; defaults
  to `./zig-out/bin/botopink`, else the bare name `botopink` on `PATH`.
- `--lib-root <dir>` — extra root to scan; repeatable. Appended **after**
  `BOTOPINK_LIB_ROOTS` env entries and the walk-up roots. Useful for ad-hoc CI
  without mutating env (`botopink-lib-test --lib-root /tmp/store --lib foo`).

## Matrix legend & exit code

| Symbol | Meaning |
|---|---|
| `✓` | `botopink test` passed |
| `✗` | a red `.bp` test — the **only** status that fails the run |
| `–` | lib has no test blocks (green skip, never a failure) |
| `~` | target skipped: either not-yet-runnable (beam/wasm), or excluded by the lib's `"targets"` whitelist (see below). `--strict` flips the not-yet-runnable case to fail; the per-lib whitelist always skips. |

### Per-lib `"targets"` whitelist (`botopink.json`)

A lib may opt out of a backend with an explicit `"targets": [<list>]`
array in its `botopink.json`:

```json
{
  "name": "onze",
  "targets": ["commonJS"]
}
```

The runner reads this during discovery (`discovery.readManifestTargets`)
and reports `~` for any requested target not in the list — without
spawning `botopink test`. Used by commonJS-only libs whose erlang port
is not in scope (`onze`, `emilia`). The single-string `"target"` field
(canonical build target) is left unchanged; the new array field is the
runner-side filter.

Absent `"targets"` → the historic behaviour (every requested target is
attempted). A malformed list (non-array, mixed types) is silently
dropped to absent — a typo must not narrow the matrix without warning.

**Exit non-zero iff at least one cell is `✗`.** A no-tests lib (`–`) and a
skipped-unsupported target (`~`) never redden the gate.

## Test output passthrough (§T)

Each child `botopink test` invocation produces the per-test envelope
documented in
[`../compiler-cli/AGENTS.md#botopink-test-output-format-§t`](../compiler-cli/AGENTS.md):

```
TEST <file>:<line> <name>
----- RUN LOG -----
\`\`\`logs
<captured stdout>
\`\`\`
  ok | FAIL <name>  …
```

In text mode (no flag) the runner **re-emits the child's stdout
untouched**: a downstream tool that needs to attribute the §T envelope
to a lib uses the cyan section header written to **stderr**
(`── <lib> · <target> ──`) immediately before the cell's stdout — a
deliberate choice over per-line text prefixing, which would corrupt
the fenced ```` ```logs ```` blocks.

### `--json` mode (T3)

`botopink-lib-test --json` passes `--json` to each spawned
`botopink test`, parses each JSONL record on the child's stdout, and
re-emits with two extra leading keys spliced in immediately after the
opening `{`:

```
{"lib":"<name>","target":"<t>","event":"test",…original keys…}
{"lib":"<name>","target":"<t>","event":"summary","passed":<P>,"failed":<F>}
```

Per cell the runner also writes one structured record (so a consumer
can match every spawned cell to its outcome without re-parsing the
text matrix):

```
{"event":"cell_summary","lib":"<name>","target":"<t>","status":"pass|fail|skipped_unsupported|no_tests"}
```

The run terminates with a single aggregated record:

```
{"event":"run_summary","passed":<cells_pass>,"failed":<cells_fail>,
 "no_tests":<n>,"skipped":<n>}
```

In JSON mode the text matrix is suppressed (stdout is pure JSONL); the
cyan stderr header is also suppressed so a piped stderr stays free of
ANSI noise. Spawn / compile errors still surface on stderr.

Schema for the inner `event:"test"` and `event:"summary"` records is
the upstream contract from
[`../compiler-cli/AGENTS.md`](../compiler-cli/AGENTS.md) (`--json`
section). Forward-compatible: a JSON consumer that does not recognise
a key (e.g. a future `duration_ms`) should ignore it.

## Design contract

- **Orchestrate, don't reimplement.** Per-lib isolation falls out of spawning a
  child with `cwd = <lib_dir>` (the lib's own directory, under any resolved root):
  `botopink test` reads that lib's `botopink.json` and writes its own
  `.botopinkbuild/test-out/`. No global-cwd juggling.
- **Unsupported-target detection is child-driven**, not a hard-coded list: the
  runner scans the child's output for `"currently supports only"`. The moment
  `botopink test` learns `beam`/`wasm`, that target stops being skipped here with
  no change — only the default/`all` set widens (`args.Target.supported`).
- **No lib coupling, no core code.** The runner names no specific lib and imports
  nothing from `compiler-core`.

## Env

| Variable             | Read by                                | Effect                                                                 |
| -------------------- | -------------------------------------- | ---------------------------------------------------------------------- |
| `BOTOPINK_LIB_ROOTS` | `src/discovery.zig:resolveRoots`       | Prepends extra lib roots before the walk-up roots.                     |
| `BOTOPINK_BIN`       | `src/main.zig:resolveBin`              | Override `botopink` binary path (`--bin` takes precedence).            |

**`BOTOPINK_LIB_ROOTS` contract** (mirrors
[`compiler-cli`](../compiler-cli/AGENTS.md#env)):

- Path separator: `:` on POSIX, `;` on Windows (via `std.fs.path.delimiter`).
- Entries prepended to the walk-up result; the combined list (env → walk-up →
  `--lib-root`) is de-duplicated first-occurrence-wins (env always shadows a
  duplicate walk-up root).
- Non-existent entries silently dropped (a typo must not break a run that does
  not need the missing root).
- Empty entries and a trailing delimiter dropped.
- Relative entries resolved against cwd.
- Unset / empty → byte-identical to the legacy walk-up.
- `init.environ_map` is threaded into `discovery.resolveRoots`; tests pass `null`.

Schema: see [`docs/botopink-json.md`](../../docs/botopink-json.md).

See the root [`AGENTS.md`](../../AGENTS.md) for workspace commands and the
[`modules/AGENTS.md`](../AGENTS.md) package table.
