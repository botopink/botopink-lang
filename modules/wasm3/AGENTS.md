# wasm3

> Path: `modules/wasm3/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Upstream: <https://github.com/wasm3/wasm3>
> Pinned version: see [`./README.md`](README.md)

Vendored [wasm3](https://github.com/wasm3/wasm3) — a pure-C WebAssembly
interpreter — packaged as a self-contained Zig module. `compiler-core` runs the
**wat comptime runtime** on it: a template or decorator body lowered to wasm and
linked into the embedded term library is instantiated and run in-process (see
`modules/compiler-core/src/comptime/runtime/persistent_wat.zig`, front 18 step
2). Every native executable and test binary that links `compiler-core` also
links wasm3; the browser build (`modules/compiler-web/`) does not — there the
page's engine is the executor. Re-vendored byte-identical from the tree deleted
on 2026-06-29 (`caa7377d`), with two build flags added (below).

## Tree

```text
wasm3/
├── AGENTS.md          ← you are here
├── README.md          ← upstream pin + excluded content + upgrade procedure
├── LICENSE            ← upstream MIT (unchanged)
├── build.zig          ← exports link() + exposeHeaders() + arrays
└── source/            ← vendored upstream `source/` tree (byte-identical)
    ├── m3_*.{c,h}     ← interpreter core + WASI/libc shims (16 .c, ~30 .h)
    └── extra/         ← embedded test wasm blobs + WASI reference header
```

## Integration contract

The module is **not** a Zig package (no `build.zig.zon`); it is a plain Zig
file `@import`ed by the root build. Paths inside it are written relative to
the workspace root because `b.path(...)` always resolves against
`b.build_root` regardless of where the `@import`ed file lives.

```zig
// repository/botopink-lang/build.zig
const wasm3 = @import("modules/wasm3/build.zig");

wasm3.exposeHeaders(b, core_mod);       // module-scoped @cImport header path
wasm3.exposeHeaders(b, core_test_mod);
wasm3.link(b, core_tests);              // per Compile target: srcs + libc
wasm3.link(b, lsp_tests);
wasm3.link(b, cli_tests);
wasm3.link(b, cli_exe);
wasm3.link(b, lsp_exe);
```

- `exposeHeaders(b, mod)` — adds the include path on `mod`. Required wherever
  Zig source `@cImport`s a wasm3 header (today: `compiler-core`'s
  `persistent_wat.zig`, only on a native target). `@cImport`
  resolves headers at the *module* level, not the Compile level.
- `link(b, compile)` — adds the C sources, the include path (for inter-`.c`
  `#include` resolution), and `link_libc = true` to a Compile target.
- `wasm3_srcs: [16][]const u8` / `wasm3_cflags: [7][]const u8` — exposed for
  introspection; the normal call path is `link()` which already uses them.

Two flags beyond upstream's: `-fwrapv` and `-fno-sanitize=undefined`. wasm's
integer arithmetic wraps and wasm3 implements it with plain C signed
arithmetic; Zig compiles C with UBSan on in Debug builds, which traps on the
first `i32.mul` that overflows (the term library's atom hash does, by design).

## Why this is a module (not vendor/)

The root build orchestrates `compiler-core`/`compiler-cli`/`language-server`
— each lives under `modules/` with its own scope. Inlining wasm3's
`wasm3_srcs` array and `linkWasm3` fn in the root build mixed concerns and
made adding sibling vendored C deps (e.g. quickjs-ng under front 02) a
copy-paste exercise. Packaging wasm3 as its own module keeps the integration
glue with the vendored code and gives future C deps a pattern to follow:
`modules/<name>/{AGENTS.md, README.md, LICENSE, build.zig, source/}`.

## Upgrade procedure

1. Pick the new upstream tag at <https://github.com/wasm3/wasm3>.
2. Replace `source/` byte-for-byte with the new upstream `source/` tree.
3. If the C file list changed, update `wasm3_srcs` in `build.zig` and the
   array length annotation in any docs that mention it. wasm3 v0.5.0 ships
   16 `.c` files; the `m3_api_*wasi.c` triple compiles to nothing under our
   guards (we don't set `d_m3HasWASI`/`MetaWASI`/`UVWASI`).
4. Update `README.md` with the new tag, commit SHA, and any newly-excluded
   upstream content.
5. `zig build && zig build test && zig build test-backends` from
   `repository/botopink-lang/` — every test that exercises the wasm comptime
   runtime should still pass byte-equal.

No new compile flags should land here without an explicit ADR — botopink's
WASI shim depends on `m3_LinkRawFunction` being the only WASI surface.
