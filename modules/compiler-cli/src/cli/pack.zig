/// `botopink pack` (decision 1036) — the package's `wasi` program as one
/// WASI p2 component, `dist/<pkg>.wasm` at the package root, holding every
/// unit the program reaches, runnable by a standalone `wasmtime run`.
///
/// It reads the program's units from the wasm build's `out/wasm/` (the entry
/// `<pkg>@main.wasm`, whose `botopink.units` names them); the build runs
/// first the way `run`'s does, so a fresh `out/wasm/` is reused and a stale
/// or absent one is built. The component is compiler-core's
/// `codegen.wasmPack.pack`: the runner's frame with every unit embedded as a
/// core module instead of imported. `build` and `run` never pack; this
/// command alone does, with no flag of `build` doing it.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");
const run_cmd = @import("./run.zig");
const libs = @import("./libs.zig");
const code_cache = @import("./code_cache.zig");

pub const Options = struct {
    /// The build's output directory the units are read from (as `run`'s).
    out_dir: []const u8 = "out",
    /// `--cold`: the build reads nothing from the code cache.
    cold: bool = false,
    /// `--cache-root <dir>`: the cache root of the build (as `run`'s).
    cache_root: ?[]const u8 = null,
};

/// The packed file, relative to the package root.
pub const dist_dir = "dist";

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options, env_map: libs.EnvMap) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    if (opts.cache_root) |r| code_cache.root_override = r;

    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {},
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };
    if (proj.wasmHost() == .browser) {
        reporter.errMsg("`pack` writes a WASI component; this package's wasm host is the browser");
        return 1;
    }
    if (try run_cmd.refuseWithoutMain(arena, io, proj, "main")) return 1;

    const build_exit = try build_cmd.run(gpa, io, .{ .target = .wasm, .out_dir = opts.out_dir, .cold = opts.cold, .entry = "main" }, env_map);
    if (build_exit != 0) return build_exit;

    const packages: bp.codegen.crossModule.Packages = .{ .root = proj.name };
    const entry_path = try build_cmd.wasmEntryPath(arena, opts.out_dir, packages, "main");
    const entry = std.Io.Dir.cwd().readFileAlloc(io, entry_path, arena, .unlimited) catch {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no wasm entry at {s} — nothing to pack", .{entry_path}));
        return 1;
    };
    var failure: ?[]u8 = null;
    const component = (try bp.codegen.wasmPack.pack(arena, io, entry, .{ .dir = std.fs.path.dirname(entry_path) orelse "." }, &failure)) orelse {
        reporter.errMsg(try std.fmt.allocPrint(arena, "cannot pack {s}: {s}", .{ entry_path, failure.? }));
        return 1;
    };

    const path = try std.fmt.allocPrint(arena, "{s}/{s}.wasm", .{ dist_dir, proj.name });
    const tmp = try std.fmt.allocPrint(arena, "{s}.tmp", .{path});
    const cwd = std.Io.Dir.cwd();
    write: {
        cwd.createDirPath(io, dist_dir) catch break :write;
        cwd.writeFile(io, .{ .sub_path = tmp, .data = component }) catch break :write;
        cwd.rename(tmp, cwd, path, io) catch break :write;
        reporter.created(path);
        return 0;
    }
    reporter.errMsg(try std.fmt.allocPrint(arena, "cannot write {s}", .{path}));
    return 1;
}
