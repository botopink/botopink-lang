/// modules/wasm3 — vendored wasm3 interpreter packaged as a self-contained Zig
/// module. Imported by the root `build.zig` via
///
///     const wasm3 = @import("modules/wasm3/build.zig");
///     wasm3.exposeHeaders(b, core_mod);   // module-scoped header path
///     wasm3.link(b, compile_target);      // per Compile target: sources + libc
///
/// The vendored sources live under `source/`; see `README.md` for the upstream
/// pin and `AGENTS.md` for the integration contract + upgrade procedure.
const std = @import("std");

/// wasm3 interpreter C sources — pinned to upstream tag `v0.5.0`. botopink
/// registers its own one-function WASI shim via wasm3's `m3_LinkRawFunction`,
/// so none of the `d_m3HasWASI`/`MetaWASI`/`UVWASI` defines are set; the three
/// `m3_api_*wasi.c` files compile to nothing under those guards. Paths are
/// relative to this `build.zig` and resolved against the root build's path
/// root by prefixing the module dir at the call site.
pub const wasm3_srcs = [_][]const u8{
    "modules/wasm3/source/m3_api_libc.c",
    "modules/wasm3/source/m3_api_meta_wasi.c",
    "modules/wasm3/source/m3_api_tracer.c",
    "modules/wasm3/source/m3_api_uvwasi.c",
    "modules/wasm3/source/m3_api_wasi.c",
    "modules/wasm3/source/m3_bind.c",
    "modules/wasm3/source/m3_code.c",
    "modules/wasm3/source/m3_compile.c",
    "modules/wasm3/source/m3_core.c",
    "modules/wasm3/source/m3_emit.c",
    "modules/wasm3/source/m3_env.c",
    "modules/wasm3/source/m3_exec.c",
    "modules/wasm3/source/m3_function.c",
    "modules/wasm3/source/m3_info.c",
    "modules/wasm3/source/m3_module.c",
    "modules/wasm3/source/m3_parse.c",
};

/// Compile flags. `-Os` keeps the interpreter compact; the `-Wno-*` flags
/// silence two upstream-known warnings that the CMakeLists also suppresses
/// (int-to-pointer in `m3_emit.c`, sign-compare in `m3_env.c`) plus three
/// `-Wno-unused-*` that quiet noise from the conditionally-compiled WASI
/// stubs.
pub const wasm3_cflags = [_][]const u8{
    "-std=c11",
    "-Os",
    "-Wno-int-to-pointer-cast",
    "-Wno-sign-compare",
    "-Wno-unused-function",
    "-Wno-unused-variable",
    "-Wno-unused-parameter",
};

/// Expose wasm3's header directory on `mod`'s include path. `@cImport` header
/// resolution is module-scoped (not Compile-scoped), so call this on every
/// Zig module that translates a wasm3 header — today that is `compiler-core`
/// (see `comptime/runtime/wasm3_host.zig`).
pub fn exposeHeaders(b: *std.Build, mod: *std.Build.Module) void {
    mod.addIncludePath(b.path("modules/wasm3/source"));
}

/// Link vendored wasm3 into a Compile target (test binary or executable).
/// Every artifact whose root module imports `compiler-core` needs this:
/// `wasm3_host.zig` calls into the C API directly. Brings in the C sources,
/// the include path (for inter-`.c` `#include` resolution), and libc.
pub fn link(b: *std.Build, compile: *std.Build.Step.Compile) void {
    const root = compile.root_module;
    root.addCSourceFiles(.{
        .files = &wasm3_srcs,
        .flags = &wasm3_cflags,
    });
    root.addIncludePath(b.path("modules/wasm3/source"));
    root.link_libc = true;
}
