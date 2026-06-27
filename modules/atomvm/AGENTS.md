# atomvm

> Path: `modules/atomvm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Upstream: <https://github.com/atomvm/AtomVM>
> Pinned version: see [`./README.md`](README.md)

Vendored [AtomVM](https://github.com/atomvm/AtomVM) — a lightweight Erlang VM
that executes BEAM bytecode — packaged as a self-contained Zig module.
`compiler-core` uses it at comptime to run BEAM test/host snippets (see
`modules/compiler-core/src/comptime/runtime/atomvm_host.zig`); every executable
that links `compiler-core` must also link AtomVM.

## Tree

```text
atomvm/
├── AGENTS.md          ← you are here
├── README.md          ← upstream pin + excluded content + upgrade procedure
├── LICENSE            ← upstream Apache-2.0 OR LGPL-2.1-or-later (unchanged)
├── build.zig          ← exports link() + exposeHeaders() + arrays
└── source/            ← vendored upstream source tree
    ├── libAtomVM/     ← core VM interpreter (~28 .c, ~54 .h, .gperf sources)
    └── platforms/
        └── generic_unix/  ← Linux/macOS/FreeBSD sys layer (7 .c, 5 .h)
            └── lib/
```

## Integration contract

The module is **not** a Zig package (no `build.zig.zon`); it is a plain Zig
file `@import`ed by the root build. Paths inside it are written relative to
the workspace root because `b.path(...)` always resolves against
`b.build_root` regardless of where the `@import`ed file lives.

```zig
// repository/botopink-lang/build.zig
const atomvm = @import("modules/atomvm/build.zig");

atomvm.exposeHeaders(b, core_mod);  // module-scoped @cImport header path
atomvm.link(b, core_tests);         // per Compile target: srcs + libs
atomvm.link(b, cli_exe);
atomvm.link(b, lsp_exe);
```

- `exposeHeaders(b, mod)` — adds the include paths on `mod`. Required wherever
  Zig source `@cImport`s an AtomVM header (today: `compiler-core`). `@cImport`
  resolves headers at the *module* level, not the Compile level.
- `link(b, compile)` — adds the C sources, the include paths (for inter-`.c`
  `#include` resolution), `link_libc = true`, and system libs (libm, pthreads)
  to a Compile target.
- `atomvm_core_srcs: [28][]const u8` / `atomvm_platform_srcs: [10][]const u8`
  / `atomvm_cflags: [8][]const u8` — exposed for introspection; the normal call
  path is `link()` which already uses them.

**Build-time generated files**: `bifs_hash.h` and `nifs_hash.h` are
pre-generated via `gperf` from `bifs.gperf`/`nifs.gperf` and committed
alongside the vendored sources. `avm_version.h` is a static header (not
a CMake `configure_file` output) with the pinned version baked in.

**Compile flags**: SMP is disabled (`-DAVM_NO_SMP`) — comptime evaluation is
single-threaded and doesn't need socket/timer infrastructure. No mbedTLS,
so crypto and SSL NIFs are compile-time excluded via `#if ATOMVM_HAS_MBEDTLS`
guards.

## Why this is a module (not vendor/)

Same rationale as wasm3: packaging the vendored C dep as its own module
keeps the integration glue with the vendored code and provides a clean
pattern for future C deps. See `modules/wasm3/AGENTS.md` §"Why this is a
module".

## Upgrade procedure

1. Pick the new upstream tag at <https://github.com/atomvm/AtomVM>.
2. Replace `source/libAtomVM/` and `source/platforms/generic_unix/lib/`
   byte-for-byte with the new upstream trees.
3. If the C file list changed, update `atomvm_core_srcs` and
   `atomvm_platform_srcs` in `build.zig`.
4. Re-generate `bifs_hash.h` and `nifs_hash.h` via `gperf -t <input> > <output>`.
5. Update `avm_version.h` with the new version string.
6. Update `README.md` with the new tag, commit SHA, and any newly-excluded
   upstream content.
7. `zig build test` from the workspace root — comptime snapshot tests must
   pass byte-equal.
