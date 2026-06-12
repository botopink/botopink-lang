# compiler-cli/src/cli — subcommand internals

> Path: `modules/compiler-cli/src/cli/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)

Detailed reference for the per-subcommand implementations and the three
shared helpers (`config.zig`, `scanner.zig`, `reporter.zig`).

## Tree

```text
cli/
├── build.zig         ← `botopink build`
├── check.zig         ← `botopink check`
├── run.zig           ← `botopink run`
├── format_cmd.zig    ← `botopink format`
├── new.zig           ← `botopink new <name>`
├── clean.zig         ← `botopink clean`
├── config.zig        ← `botopink.json` loader
├── scanner.zig       ← deterministic module discovery
└── reporter.zig      ← stdout/stderr unified helpers
```

## Subcommand pipeline (common shape)

Every command follows the same five-step skeleton:

```text
1. parseOpts(argv)          → CommandOpts
2. config.load(alloc, "botopink.json")
                            → ProjectConfig
3. scanner.discoverModules(alloc, project_root)
                            → []Module (sorted by path)
4. botopink.<verb>(alloc, modules, config, io)
                            → ResultOrError
5. reporter.<status/error>(io, …)
```

### `build.zig`
Calls `botopink.codegen.generate(...)` and writes emitted files. Wraps fatal
errors into a friendly `reporter.errMsg` envelope.

### `check.zig`
Same pipeline as `build` but stops after `botopink.compile(...)` — no
filesystem emission. Used by editors / CI for fast feedback.

### `run.zig`
After a successful build, dispatches to `comptime/runtime/<node|erlang>.zig`
helpers to actually execute the emitted entry point.

### `format_cmd.zig`
Reads each `.bp` file, calls `botopink.format.format(...)`, then either
writes the result back or — with `--check` — diffs against the original and
exits non-zero on any mismatch (so CI fails on un-formatted code).

### `new.zig`
Drops a project template: `src/`, `botopink.json`, `.gitignore`, a starter
`main.bp`. Refuses to clobber existing directories.

### `clean.zig`
Removes `out/` (codegen outputs) and `.botopinkbuild/` (comptime runtime
scratch). Idempotent.

## Shared helpers

### `config.zig`
Parses `botopink.json` into a typed struct. Validates the `target` field
against the supported set (`commonJS`, `erlang`). Loose fields (e.g.
`build.target_options`) are passed through verbatim to compiler-core.

### `scanner.zig`
Walks `src/` and returns modules **sorted by path**. Determinism is critical:
codegen output and snapshot tests both depend on stable module ordering.

### `reporter.zig`
The single source of truth for CLI text. Exposed surface:

- `info(io, fmt, args)` — neutral status lines
- `success(io, fmt, args)` — coloured `✓ …`
- `errMsg(io, fmt, args)` — coloured `error: …` (stderr, exit-worthy)
- `hint(io, fmt, args)` — `hint: …` follow-up after an error
- `compilerError(io, err)` — formats a `botopink.print` diagnostic

Anything that calls `std.debug.print` directly is a bug.

## Adding a subcommand

End-to-end walk-through: [`./examples.md`](examples.md).
