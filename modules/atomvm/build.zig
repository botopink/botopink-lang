/// modules/atomvm — vendored AtomVM interpreter packaged as a self-contained
/// Zig module. Imported by the root `build.zig` via
///
///     const atomvm = @import("modules/atomvm/build.zig");
///     atomvm.exposeHeaders(b, core_mod);   // module-scoped header path
///     atomvm.link(b, compile_target);      // per Compile target: sources + libs
///
/// The vendored sources live under `source/`; see `README.md` for the upstream
/// pin and `AGENTS.md` for the integration contract + upgrade procedure.
const std = @import("std");

/// AtomVM core library C sources — pinned to upstream tag `v0.6.5`.
/// Paths are relative to this `build.zig` and resolved against the root
/// build's path root by prefixing the module dir at the call site.
pub const atomvm_core_srcs = [_][]const u8{
    "modules/atomvm/source/libAtomVM/atom.c",
    "modules/atomvm/source/libAtomVM/atomshashtable.c",
    "modules/atomvm/source/libAtomVM/atom_table.c",
    "modules/atomvm/source/libAtomVM/avmpack.c",
    "modules/atomvm/source/libAtomVM/bif.c",
    "modules/atomvm/source/libAtomVM/bitstring.c",
    "modules/atomvm/source/libAtomVM/context.c",
    "modules/atomvm/source/libAtomVM/debug.c",
    "modules/atomvm/source/libAtomVM/defaultatoms.c",
    "modules/atomvm/source/libAtomVM/dictionary.c",
    "modules/atomvm/source/libAtomVM/externalterm.c",
    "modules/atomvm/source/libAtomVM/globalcontext.c",
    "modules/atomvm/source/libAtomVM/iff.c",
    "modules/atomvm/source/libAtomVM/interop.c",
    "modules/atomvm/source/libAtomVM/mailbox.c",
    "modules/atomvm/source/libAtomVM/memory.c",
    "modules/atomvm/source/libAtomVM/module.c",
    "modules/atomvm/source/libAtomVM/nifs.c",
    "modules/atomvm/source/libAtomVM/port.c",
    "modules/atomvm/source/libAtomVM/posix_nifs.c",
    "modules/atomvm/source/libAtomVM/refc_binary.c",
    "modules/atomvm/source/libAtomVM/resources.c",
    "modules/atomvm/source/libAtomVM/scheduler.c",
    "modules/atomvm/source/libAtomVM/stacktrace.c",
    "modules/atomvm/source/libAtomVM/term.c",
    "modules/atomvm/source/libAtomVM/timer_list.c",
    "modules/atomvm/source/libAtomVM/unicode.c",
    "modules/atomvm/source/libAtomVM/valueshashtable.c",
};

/// Platform (generic_unix) C sources. These implement the sys abstraction
/// layer for Linux, macOS, and FreeBSD.
pub const atomvm_platform_srcs = [_][]const u8{
    "modules/atomvm/source/platforms/generic_unix/lib/mapped_file.c",
    "modules/atomvm/source/platforms/generic_unix/lib/otp_socket_platform.c",
    "modules/atomvm/source/platforms/generic_unix/lib/platform_defaultatoms.c",
    "modules/atomvm/source/platforms/generic_unix/lib/platform_nifs.c",
    "modules/atomvm/source/platforms/generic_unix/lib/smp.c",
    "modules/atomvm/source/platforms/generic_unix/lib/socket_driver.c",
    "modules/atomvm/source/platforms/generic_unix/lib/sys.c",
    "modules/atomvm/source/libAtomVM/inet.c",
    "modules/atomvm/source/libAtomVM/otp_net.c",
    "modules/atomvm/source/libAtomVM/otp_socket.c",
};

/// Compile flags. `-std=gnu11` for AtomVM's C11 + POSIX requirement;
/// `-Os` keeps the VM compact. Disable SMP and task driver for simpler
/// embedding — comptime evaluation is single-threaded and doesn't need
/// sockets/timers.
///
/// Feature test macros mirror what CMake's `define_if_function_exists` and
/// `define_if_symbol_exists` detect on Linux — needed because Zig doesn't
/// run CMake's configure step.
pub const atomvm_cflags = [_][]const u8{
    "-std=gnu11",
    "-Os",
    "-DAVM_NO_SMP",
    "-D_GNU_SOURCE",
    "-DHAVE_OPEN",
    "-DHAVE_CLOSE",
    "-DHAVE_SOCKET",
    "-DHAVE_SELECT",
    "-DHAVE_OPENDIR",
    "-DHAVE_CLOSEDIR",
    "-DHAVE_READDIR",
    "-DHAVE_ATOMIC",
    "-DHAVE_SIGNAL",
    "-Wno-unused-function",
    "-Wno-unused-variable",
    "-Wno-unused-parameter",
    "-Wno-missing-field-initializers",
    "-Wno-sign-compare",
};

/// Expose AtomVM's header directories on `mod`'s include path. `@cImport`
/// header resolution is module-scoped (not Compile-scoped), so call this on
/// every Zig module that translates an AtomVM header — today that is
/// `compiler-core` (see `comptime/runtime/atomvm_host.zig`).
pub fn exposeHeaders(b: *std.Build, mod: *std.Build.Module) void {
    mod.addIncludePath(b.path("modules/atomvm/source/libAtomVM"));
    mod.addIncludePath(b.path("modules/atomvm/source/platforms/generic_unix/lib"));
}

/// Link vendored AtomVM into a Compile target (test binary or executable).
/// Every artifact whose root module imports `compiler-core` needs this.
/// Brings in the C sources, the include paths, and system libraries
/// (libc, libm, pthreads, libdl).
pub fn link(b: *std.Build, compile: *std.Build.Step.Compile) void {
    const root = compile.root_module;

    // Core VM sources
    root.addCSourceFiles(.{
        .files = &atomvm_core_srcs,
        .flags = &atomvm_cflags,
    });

    // Platform sources
    root.addCSourceFiles(.{
        .files = &atomvm_platform_srcs,
        .flags = &atomvm_cflags,
    });

    // Include paths for inter-.c #include resolution
    root.addIncludePath(b.path("modules/atomvm/source/libAtomVM"));
    root.addIncludePath(b.path("modules/atomvm/source/platforms/generic_unix/lib"));

    // System libraries: libc (always), libm (math), pthreads (SMP stubs),
    // libdl (dynamic port driver loading — disabled, but headers reference it)
    root.link_libc = true;
    root.linkSystemLibrary("m", .{});
    root.linkSystemLibrary("pthread", .{});
}
