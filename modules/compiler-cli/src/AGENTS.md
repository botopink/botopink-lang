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
| `main.zig` | Parses `botopink <command> [options]` and calls into `cli/<command>.zig`. Owns `VERSION` and the `HELP` text. Commands: `build`, `check`, `run`, `test`, `format` (alias `fmt`), `new`, `clean`, `migrate` (and its `migrate effects` subcommand — the word must come first), `help` (`--help`/`-h`), `version` (`--version`/`-v`). Carries the unit tests for every parser (contract rows C8, C10–C12, C14). |

## Development notes

- `main.zig` keeps a `parseXxxOpts(...)` helper per command (`parseBuildOpts`,
  `parseCheckOpts`, `parseRunOpts`, `parseTestOpts`, `parseFormatOpts`,
  `parseNewOpts`, `parseMigrateOpts`, `parseNoOpts` for `clean`) — pure: they
  return `ArgError` with the offending token in `ArgDiag`, and `usageError`
  prints it (exit 1). **No parser drops a token**: an unknown flag, an
  unexpected positional or an unsupported target is an error. `--flag=value`
  is accepted wherever `--flag value` is.
- Parsed option lists (`run` extra args, `format` files) are allocated in the
  process arena, so no command frees them and the parsers run leak-free under
  `std.testing.allocator`.
- When command flags change, update **both** the parser, its unit test and the
  `HELP` block in `main.zig` together.
- User-facing output flows through `cli/reporter.zig` (`reporter.stdout`,
  `errMsg`, `hintMsg`, …).
- `main.zig` is also the root of the CLI test module, so every `test {}` block
  reachable from its imports runs under `zig build test`.
