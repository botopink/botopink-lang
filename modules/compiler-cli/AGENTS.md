# compiler-cli

> Path: `modules/compiler-cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink` CLI executable. Depends on `compiler-core`.

## Tree

```text
compiler-cli/
├── AGENTS.md            ← you are here
├── build.zig            ← package build graph + `run` step
├── build.zig.zon        ← dependency manifest (compiler-core)
└── src/
    ├── AGENTS.md
    ├── main.zig         ← argv parser, subcommand dispatcher
    └── cli/             ← one file per subcommand + shared helpers
        └── AGENTS.md
```

## Commands

```bash
zig build               # produce ./zig-out/bin/botopink
zig build run -- help
zig build run -- version
```

## CLI behavior contract

- Exit `0` on success, non-zero on command failure.
- All user-facing status/errors must go through `src/cli/reporter.zig`.
- Keep command options aligned with help text in `src/main.zig` and the
  `cli/<cmd>.zig` implementation.

See [`src/AGENTS.md`](src/AGENTS.md) for the dispatch flow and
[`src/cli/AGENTS.md`](src/cli/AGENTS.md) for the per-command list.
