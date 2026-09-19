/// Project source loading — the driver-side entry to the explicit module tree.
///
/// `load` resolves a package's modules by following `mod` declarations from its
/// root (`resolver.zig`), warns about orphaned `.bp` files, and falls back to
/// the legacy blind `src/` walk (`scanner.zig`) — with a deprecation warning —
/// for packages that have no `main.bp`/`root.bp` root yet. Every CLI command
/// (build/check/test/format) loads project sources through here so the tree
/// model and its fallback live in one place.
const std = @import("std");
const bp = @import("botopink");
const config = @import("./config.zig");
const resolver = @import("./resolver.zig");
const scanner = @import("./scanner.zig");
const reporter = @import("./reporter.zig");

const Module = bp.Module;

/// Loaded project modules. `modules` (path + source) are gpa-owned; `orphans`
/// likewise — `free` releases both regardless of which loader produced them
/// (the ownership contract is identical for the resolver and the blind scan).
pub const Loaded = struct {
    modules: []Module,
    orphans: []resolver.Orphan = &.{},

    pub fn free(self: *Loaded, gpa: std.mem.Allocator) void {
        for (self.modules) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
        }
        gpa.free(self.modules);
        resolver.freeOrphans(gpa, self.orphans);
    }
};

/// Load the package's project modules from `src_dir` (relative to cwd), using
/// `proj.entry` to pick the module-tree root. Resolution errors are reported to
/// stderr before being returned.
pub fn load(
    gpa: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
    src_dir: []const u8,
) !Loaded {
    var da = std.heap.ArenaAllocator.init(gpa);
    defer da.deinit();
    var diag: resolver.Diagnostic = .{ .kind = resolver.Error.RootNotFound };

    // The names an `import … from "<name>"` may reach outside the module tree:
    // the project's declared dependencies (`std` is built in and always allowed).
    // Without them the resolver cannot tell a dependency from a typo.
    const externals = try proj.dependencyNames(da.allocator());

    const res = resolver.resolve(gpa, io, src_dir, proj.entry, externals, proj.files, da.allocator(), &diag) catch |err| switch (err) {
        resolver.Error.RootNotFound => {
            // No explicit root yet — fall back to the legacy blind walk so
            // unmigrated packages keep building (deprecated for one release).
            const mods = try scanner.scanSources(gpa, io, src_dir);
            if (mods.len > 0) {
                reporter.warnMsg("no module-tree root (src/main.bp or src/root.bp) — using the deprecated implicit src/ scan");
                reporter.hintMsg("declare a root with `mod` declarations; the implicit scan will be removed in a future release");
            }
            return .{ .modules = mods };
        },
        else => {
            reportDiag(da.allocator(), diag);
            return err;
        },
    };

    for (res.orphans) |o| {
        reporter.warnDetail("module not reached by any `mod` path — not compiled:", o.file);
    }
    return .{ .modules = res.modules, .orphans = res.orphans };
}

/// Apply `load`'s import-source rule to a flat, non-package source directory —
/// the `test/` suite, which `botopink test` and `botopink check` discover with
/// `scanner.scanSourcesWithFiles` instead of the resolver. Without this a
/// `*_test.bp` naming a module that does not exist bound nothing and said
/// nothing, exactly as a `src/` module did before the resolver learned the rule.
///
/// `project_modules` are the already-resolved `src/` modules — passed so a test
/// file may import the package it tests; they carry no file path because they
/// have already been checked and cannot fail here. Returns the resolver error
/// after reporting it, so the caller only has to propagate a failure.
pub fn checkFlatImports(
    gpa: std.mem.Allocator,
    proj: config.ProjectConfig,
    project_modules: []const Module,
    flat: scanner.Scan,
) !void {
    if (flat.modules.len == 0) return;

    var da = std.heap.ArenaAllocator.init(gpa);
    defer da.deinit();
    const a = da.allocator();

    const mods = try std.mem.concat(a, Module, &.{ project_modules, flat.modules });
    const files = try a.alloc([]const u8, mods.len);
    @memset(files[0..project_modules.len], "");
    @memcpy(files[project_modules.len..], flat.files);

    const externals = try proj.dependencyNames(a);
    var diag: resolver.Diagnostic = .{ .kind = resolver.Error.RootNotFound };
    resolver.checkSources(a, mods, files, externals, a, &diag) catch |err| {
        reportDiag(a, diag);
        return err;
    };
}

/// `file:line:col` for a diagnostic that carries a location, `""` otherwise.
/// Falls back to the raw text on an allocation failure — a diagnostic is never
/// worth failing over.
fn originOf(arena: std.mem.Allocator, diag: resolver.Diagnostic) []const u8 {
    if (diag.line == 0 or diag.file.len == 0) return "";
    return std.fmt.allocPrint(arena, "{s}:{d}:{d}", .{ diag.file, diag.line, diag.col }) catch diag.file;
}

fn reportDiag(arena: std.mem.Allocator, diag: resolver.Diagnostic) void {
    switch (diag.kind) {
        resolver.Error.AmbiguousModule => {
            reporter.errMsg("ambiguous module: both a sibling file and a folder index exist");
            reporter.warnDetail("  declared as `mod", diag.name);
            reporter.hintMsg("keep exactly one — either the `.bp` file or the `/mod.bp` folder index");
        },
        resolver.Error.ModuleNotFound => {
            reporter.errMsg("unresolved module declaration");
            reporter.warnDetail("  `mod` name:", diag.name);
            reporter.hintMsg("expected a sibling `<name>.bp` or a folder index `<name>/mod.bp` next to the declaring file");
        },
        resolver.Error.DuplicateModule => {
            reporter.errMsg("module reached by more than one `mod` path");
            reporter.warnDetail("  module:", diag.name);
        },
        resolver.Error.UnresolvedImportSource => {
            reporter.errMsg("unresolved import source — no such module or dependency");
            reporter.warnDetail("  `from` names:", diag.name);
            reporter.warnDetail("  imported by:", diag.importer);
            const origin = originOf(arena, diag);
            if (origin.len > 0) reporter.warnDetail("  at:", origin);
            reporter.hintMsg("declare it in the module tree (`mod <name>;`), or add it to `dependencies` in botopink.json");
        },
        resolver.Error.UnexportedImport => {
            reporter.errMsg("imported symbol is not exported by the named module");
            reporter.warnDetail("  symbol:", diag.name);
            reporter.warnDetail("  imported by:", diag.importer);
            reporter.warnDetail("  from module:", diag.target);
            const origin = originOf(arena, diag);
            if (origin.len > 0) reporter.warnDetail("  at:", origin);
            reporter.hintMsg("declare it `pub` in that module, or import it from the module that defines it");
        },
        resolver.Error.PrivateModuleImport => {
            reporter.errMsg("import crosses a private module boundary");
            reporter.warnDetail("  private `mod`:", diag.name);
            reporter.warnDetail("  imported by:", diag.importer);
            reporter.warnDetail("  target module:", diag.target);
            reporter.hintMsg("make every `mod` on the path `pub mod`, or move the import inside the private subtree");
        },
        resolver.Error.RootNotFound => {
            reporter.errMsg("no module-tree root found (src/main.bp or src/root.bp)");
        },
        else => reporter.errMsg("failed to resolve the module tree"),
    }
}
