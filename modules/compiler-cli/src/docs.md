# compiler-cli/src — entry & dispatch

> Path: `modules/compiler-cli/src/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md)

Detailed reference for the CLI entry point and command dispatch layer.

## Tree

```text
src/
├── main.zig       ← argv parser + subcommand dispatch (`botopink <cmd>`)
└── cli/           ← one file per subcommand + shared helpers
```

## main.zig responsibilities

`main.zig` is intentionally thin. It owns three things:

1. **`VERSION`** — single string constant emitted by `botopink version` and
   embedded in `--help` output.
2. **`HELP`** — the multi-line help block. Must stay in lock-step with each
   command's option parser; the source-of-truth for "what flags exist" is
   here.
3. **`parseXxxOpts(...)` helpers** — one per subcommand. Each helper is
   **side-effect free** and **deterministic**: it takes argv slice + allocator,
   returns a populated options struct, and never touches the filesystem.
   The actual work happens in `cli/<cmd>.zig`.

Why split it this way? Tests can call the parser directly without spinning up
a full command. And we can fuzz argv handling in isolation.

## Dispatch flow

```text
main()
  ├─ parse global flags (--version, --help)
  ├─ switch (cmd_name)
  │     ├─ "build"  → cli.build.run(parseBuildOpts(argv), alloc, io)
  │     ├─ "check"  → cli.check.run(parseCheckOpts(argv), alloc, io)
  │     ├─ "run"    → cli.run.run(parseRunOpts(argv), alloc, io)
  │     ├─ "format" → cli.format_cmd.run(parseFormatOpts(argv), alloc, io)
  │     ├─ "new"    → cli.new.run(...)
  │     └─ "clean"  → cli.clean.run(...)
  └─ return exit code from chosen command
```

## When command flags change

Three places must change together — the parser, the command implementation,
**and** the `HELP` block. Forgetting `HELP` is the most common drift; it ages
silently because tests don't read it.

## Per-command details

See [`cli/AGENTS.md`](cli/AGENTS.md) for the file list and
[`cli/docs.md`](cli/docs.md) for a detailed walk-through of each subcommand.
