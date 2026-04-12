# core/src/parser

Parser tests live here. The parser itself is at `../parser.zig`.

## Files

| File | Role |
|---|---|
| `tests.zig` | Snapshot tests via `assertParser(allocator, @src(), source)` |

## Testing pattern

```zig
test "some decl" {
    try assertParser(std.testing.allocator, @src(), "val x = 42");
}
```

Snapshot path: `../../snapshots/parser/<slug>.snap.md`.
Use `expectParseError(source, "expected error text")` for error-case tests.

## Conventions

See `../AGENTS.md` for core testing and architecture guidelines. AST nodes use `union(enum)` — always call `deinit(allocator)` on heap-allocated nodes.
