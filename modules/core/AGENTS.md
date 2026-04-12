# core

Main Zig package. See the root `AGENTS.md` for the full architecture and
conventions reference. This file covers package-level layout only.

## Layout

```
build.zig          Zig build script
src/               All source (see src/AGENTS.md)
snapshots/         Snapshot files consumed by tests
  parser/          AST snapshots
  codegen/         Codegen snapshots (commonJS/, erlang/, errors/)
  comptime/        Comptime evaluation snapshots (ast/, errors/)
```

## Running

All commands from this directory:

```bash
zig build           # compile
zig build test      # run all tests
zig build run       # run CLI stub
zig build test -- --test-filter "some test name"
```

## Recent Syntax Changes (v0.0.11-beta)

### Struct fields
- `val` keyword is implicit: `struct { _count: i32 = 0, fn increment... }`
- Comma `,` replaces semicolon `;` as member separator
- Single-line when no methods: `struct { x: f32, y: f32 }`

### Enum variants
- Comma after all variants (no semicolon on last): `enum { Red, Rgb(r, g, b), }`
- Single-line when no methods: `enum { North, South, East, West }`

### Record syntax
- Block-based with braces: `record { x: i32, y: i32 }`
- `val` keyword is implicit for fields (not written in source, not included in formatted output)
- Single-line when no methods: `record { first: T, second: T }`

### Removed
- `if val Pattern = expr { body }` — use `case` expression instead
- `private` keyword on struct/enum/record fields — all fields are private by default

### New Targets
- **Erlang codegen** — `zig build test` now generates `.erl` files via `codegen/erlang.zig`
- **Erlang comptime runtime** — comptime expressions evaluated via Erlang's `json:encode/1`

## Conventions

See `../AGENTS.md` for core architecture and testing guidelines. No separate Node.js or Wasm modules — all JS is generated natively in Zig by `core/src/codegen/commonJS/emit.zig`.
