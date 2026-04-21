# core/src/format

Formatter tests live here. The formatter implementation itself is at
`../format.zig` (Wadler-Lindig pretty-printer).

## Files

| File | Role |
|---|---|
| `tests.zig` | Snapshot tests for round-trip formatting (`format(parse(src)) == src`) |

## Round-trip contract

The formatter must be stable: running `format(parse(src))` twice must produce
identical output. Tests verify this property via snapshots.

## Conventions

See `../AGENTS.md` for core formatting rules. Key syntax (v0.0.11-beta):
- **Record fields**: formatted WITHOUT `val` prefix: `record { name: Type, ... }`
- **Struct fields**: formatted WITHOUT `val` prefix: `struct { name: Type, ... }`
- **Enum variants**: comma-separated, single-line when no methods: `enum { Red, Rgb(r, g, b), }`
- **Interface methods**: formatted with `fn` prefix: `interface { fn method(params): Type, }`
