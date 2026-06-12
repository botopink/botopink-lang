# compiler-cli — design notes

> Path: `modules/compiler-cli/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md) · Examples: [`src/cli/examples.md`](src/cli/examples.md)

Detailed reference for the `botopink` CLI executable. Pairs with the lean
[`AGENTS.md`](AGENTS.md) which is intentionally just a tree + role.

## Tree

```text
compiler-cli/
├── build.zig            ← Zig build graph + `run` step
├── build.zig.zon        ← dependency manifest (compiler-core)
└── src/
    ├── main.zig         ← argv parser, subcommand dispatcher
    └── cli/             ← one file per subcommand + shared helpers
```

## Lifecycle of a CLI invocation

```text
argv → main.parseArgs → dispatch to cli/<cmd>.zig
                              │
                              ├─ config.zig    (load botopink.json)
                              ├─ scanner.zig   (deterministic module scan)
                              ├─ @import("botopink")  (compiler-core)
                              └─ reporter.zig  (unified status/error output)
                              ↓
                          process exit code
```

1. **`main.zig`** parses `botopink <command> [options]` and owns the `VERSION`
   constant + `HELP` text.
2. Each `cli/<cmd>.zig` follows the same skeleton: parse opts → load config →
   scan modules → call compiler-core → emit through reporter.
3. Exit `0` on success, non-zero on any command failure. Failures bubble
   through `reporter.errMsg`.

## Why a dedicated reporter

All user-facing output (status lines, errors, hints) is routed through
`cli/reporter.zig`. This keeps the visible style consistent (`error: …` /
`hint: …`) and makes future colour/json modes a one-file change. Calling
`std.debug.print` directly is a bug — it bypasses styling and may leak
debug output into release binaries.

## Configuration & target resolution

- `cli/config.zig` parses the project's `botopink.json` (target, entry module,
  out dir, etc.).
- The target maps to a `codegen.TargetSource` enum (`commonJS | erlang | beam | wasm`) that
  compiler-core consumes. See
  [`../compiler-core/src/codegen/docs.md`](../compiler-core/src/codegen/docs.md).
- `cli/scanner.zig` walks `src/` and returns modules sorted by path. Order
  matters: codegen output and snapshot stability depend on a deterministic
  module list.

## Add a new subcommand

1. Create `src/cli/<name>.zig` with a `pub fn run(...)` entry.
2. Wire it into `src/main.zig`: extend the dispatch `switch`, add a
   `parseXxxOpts(...)` helper, update the `HELP` block.
3. Use `reporter.zig` for any user-facing output.
4. Add a usage example to the workspace [`README.md`](../../README.md) if the
   command is user-facing.

Concrete walk-through: [`src/cli/examples.md`](src/cli/examples.md).
