# compiler-cli/src

> Path: `modules/compiler-cli/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)

CLI entry point and command dispatch. The command implementations live in
[`cli/`](cli/AGENTS.md).

## Tree

```text
src/
├── AGENTS.md      ← you are here
├── main.zig       ← argv parser + subcommand dispatch (`botopink <cmd>`)
└── cli/           ← one file per subcommand + shared helpers
    └── AGENTS.md
```

## Files

| File | Role |
|---|---|
| `main.zig` | Parses `botopink <command> [options]` and calls into `cli/<command>.zig`. Owns `VERSION` and the `HELP` text. Commands: `build`, `check`, `run`, `test`, `format` (alias `fmt`), `new`, `clean`, `migrate`, `help` (`--help`/`-h`), `version` (`--version`/`-v`). |

## Development notes

- `main.zig` keeps a `parseXxxOpts(...)` helper per command with options
  (`parseBuildOpts`, `parseRunOpts`, `parseTestOpts`, `parseFormatOpts`,
  `parseNewOpts`; `migrate` reads `--dry-run` inline) — keep them deterministic
  and side-effect free.
- When command flags change, update **both** the parser and the `HELP` block
  in `main.zig` together (e.g. `test --json` is parsed but not yet listed in `HELP`).
- User-facing output flows through `cli/reporter.zig` (`reporter.stdout`,
  `errMsg`, `hintMsg`, …).
- `main.zig` is also the root of the CLI test module, so every `test {}` block
  reachable from its imports runs under `zig build test`.
