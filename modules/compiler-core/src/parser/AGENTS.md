# compiler-core/src/parser

> Path: `modules/compiler-core/src/parser/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Parser tests. The parser implementation itself is at `../parser.zig`.

## Tree

```text
parser/
├── AGENTS.md      ← you are here
└── tests.zig      ← `assertParser` / `expectParseError` snapshot tests
```

## Testing pattern

```zig
test "use decl" {
    try assertParser(std.testing.allocator, @src(), "use std.{print}");
}
```

- Snapshot path: `../../snapshots/parser/<slug>.snap.md`
- Error tests: `expectParseError(source, "expected message")`

## Notes

- AST nodes are `union(enum)`; always call `deinit(alloc)` on heap-allocated
  branches.
- `Parser.init(tokens)` does **not** store an allocator; parse methods receive
  `alloc: std.mem.Allocator`.
