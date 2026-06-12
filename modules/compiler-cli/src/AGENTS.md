# compiler-cli/src

> Path: `modules/compiler-cli/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

CLI entry point and command dispatch. The actual command implementations live
in [`cli/`](cli/AGENTS.md).

## Tree

```text
src/
├── AGENTS.md      ← you are here
├── docs.md        ← detailed entry & dispatch reference
├── main.zig       ← argv parser + subcommand dispatch (`botopink <cmd>`)
└── cli/           ← one file per subcommand + shared helpers
    ├── AGENTS.md
    ├── docs.md
    └── examples.md
```

## Files

| File | Role |
|---|---|
| `main.zig` | Parses `botopink <command> [options]` and calls into `cli/<command>.zig`. Owns `VERSION` and the `HELP` text. |

## Development notes

- `main.zig` keeps a `parseXxxOpts(...)` helper per command — keep them
  deterministic and side-effect free.
- When command flags change, update **both** the parser and the `HELP` block
  in `main.zig` together.
- All user-facing output flows through `cli/reporter.zig` — never `std.debug.print`.
