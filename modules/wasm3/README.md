# modules/wasm3

Vendored snapshot of [wasm3](https://github.com/wasm3/wasm3) — a pure-C WebAssembly interpreter. Packaged as a self-contained Zig module; see [`./AGENTS.md`](AGENTS.md) for the integration contract.

## Pinned version

- **Tag**: `v0.5.0`
- **Commit**: `6b8bcb1e07bf26ebef09a7211b0a37a446eafd52`
- **Upstream**: https://github.com/wasm3/wasm3
- **License**: MIT (see `LICENSE`)

## What's vendored

Only `source/*.{c,h}` (the interpreter core) plus the LICENSE. The following upstream content is intentionally excluded — it ships demo platforms, toolchains and CMake fixtures we don't need:

- `platforms/` (Android/iOS/embedded demos)
- `extra/wapm-package/` (WAPM publishing config)
- `extra/*.png`, `extra/*.svg` (assets)
- `docs/` (upstream docs)
- `test/` (upstream test harness)
- `.github/` (upstream CI)
- `CMakeLists.txt` (replaced by botopink's `build.zig` block)

## How we build it

The module's own [`build.zig`](build.zig) exposes `link(b, compile)` +
`exposeHeaders(b, mod)` to the root workspace `build.zig`, which links these
16 `.c` files into every binary that imports `compiler-core`:

```
m3_api_libc.c m3_api_meta_wasi.c m3_api_tracer.c m3_api_uvwasi.c m3_api_wasi.c
m3_bind.c m3_code.c m3_compile.c m3_core.c m3_emit.c m3_env.c m3_exec.c
m3_function.c m3_info.c m3_module.c m3_parse.c
```

Compile flags: `-std=c11 -Os`. We do **not** set any of `d_m3HasWASI`/`d_m3HasMetaWASI`/`d_m3HasUVWASI` — `m3_api_wasi.c`, `m3_api_meta_wasi.c` and `m3_api_uvwasi.c` compile to nothing under those guards. botopink registers its own one-function WASI shim (`fd_write`) via wasm3's `m3_LinkRawFunction` API; see `modules/compiler-core/src/comptime/runtime/wasm3_host.zig`.

## Upgrading

1. Download the new upstream tag's `source/` tree.
2. Replace `modules/wasm3/source/` with it (byte-for-byte).
3. If the file list changed, update the `wasm3_srcs` array in `build.zig`.
4. Update this file's pinned version + commit hash.
5. `zig build test` on Linux + macOS + Windows.
