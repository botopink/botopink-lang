/// Project configuration — the `botopink.json` of the project being built.
///
/// The manifest model itself lives in the shared `manifest` module
/// (`modules/manifest/src/root.zig`): fields, the workspace form, the
/// dependency object and every located refusal. This file is the CLI's view of
/// it — `load` reads the manifest in cwd, refuses a workspace (a command runs
/// inside a member, never on the umbrella), finds the enclosing workspace when
/// there is one, and hands the commands a `ProjectConfig` with the defaults
/// they expect (`target` is `commonJS` when unset). Every refusal is printed
/// here, located, before `error.ConfigInvalid` is returned, so a caller prints
/// nothing more.
const std = @import("std");
const manifest = @import("manifest");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");

// ── Types ─────────────────────────────────────────────────────────────────────

pub const Target = enum {
    commonJS,
    erlang,
    beam,
    wasm,

    pub fn fromString(s: []const u8) ?Target {
        if (std.mem.eql(u8, s, "commonJS")) return .commonJS;
        if (std.mem.eql(u8, s, "erlang")) return .erlang;
        if (std.mem.eql(u8, s, "beam")) return .beam;
        if (std.mem.eql(u8, s, "wasm")) return .wasm;
        return null;
    }

    pub fn toString(self: Target) []const u8 {
        return switch (self) {
            .commonJS => "commonJS",
            .erlang => "erlang",
            .beam => "beam",
            .wasm => "wasm",
        };
    }
};

/// The dependency shapes, shared with every other reader of the manifest.
pub const DepRef = manifest.DepRef;
pub const DepSpec = manifest.DepSpec;
pub const DepEntry = manifest.DepEntry;

/// Parsed representation of `botopink.json`, with the CLI's defaults applied.
pub const ProjectConfig = struct {
    name: []const u8,
    version: []const u8 = "0.1.0",
    target: []const u8 = "commonJS",
    /// Module-tree root file, relative to `src/` (e.g. `"main.bp"` for a binary
    /// package, `"root.bp"` for a library). When null the resolver auto-detects:
    /// `main.bp` if present (binary), else `root.bp` (library). The resolver
    /// follows `mod` declarations from this file to build the package's modules.
    entry: ?[]const u8 = null,
    /// The object-form dependencies (decision 76) — `{ "<name>": { "path" } |
    /// { "git", pin } | { "workspace": true } }`, each already validated.
    dependencies: []const DepEntry = &.{},
    /// The manifest's `files` — modules this package ships to something outside
    /// its own `mod` tree, each a path relative to `src`. A consumer of a
    /// dependency loads them (`libs.loadDependencies`); `libs/std` uses them for
    /// the ambient modules the compiler build embeds into the global type env.
    /// Either way the module is reached, which is why a `files` entry is not an
    /// orphan.
    files: []const []const u8 = &.{},
    /// The full manifest (raw text included, so a later refusal can be located).
    /// The default is an empty package, for a hand-rolled config in a test.
    manifest: manifest.Manifest = .{ .path = manifest.FILENAME, .text = "", .kind = .package, .name = "" },
    /// The project's directory, absolute — the base every `path` dependency
    /// resolves against.
    dir: []const u8 = ".",
    /// The workspace this project is a member of, when it is one (decision 75):
    /// `{ "workspace": true }` dependencies resolve to its members.
    workspace: ?manifest.Workspace = null,

    /// The manifest's `src` as a directory relative to the project (onze
    /// F5): `"src/"` → `"src"`, `"."` or `"./"` → `"."`. Every command loads
    /// the project's own modules from here; a hand-rolled config answers
    /// the manifest default, `src`.
    pub fn srcDir(self: ProjectConfig) []const u8 {
        var s = std.mem.trimEnd(u8, self.manifest.src, "/");
        if (std.mem.startsWith(u8, s, "./") and s.len > 2) s = s[2..];
        return if (s.len == 0) "." else s;
    }

    /// The manifest's `target`, or null when it names a target the compiler
    /// does not support. Never degrades an unknown target to commonJS — the
    /// caller reports it (`reportUnsupportedTarget`) and fails.
    pub fn parsedTarget(self: ProjectConfig) ?Target {
        return Target.fromString(self.target);
    }

    /// Convenience: flatten `dependencies` to just the names — the shape the
    /// resolver's import-source rule consumes. Caller owns the slice (free with
    /// `gpa.free`); element strings remain owned by the config arena.
    pub fn dependencyNames(self: ProjectConfig, gpa: std.mem.Allocator) ![]const []const u8 {
        var names = try gpa.alloc([]const u8, self.dependencies.len);
        for (self.dependencies, 0..) |d, i| names[i] = d.name;
        return names;
    }
};

// ── Loader ────────────────────────────────────────────────────────────────────

pub const LoadError = error{
    ConfigNotFound,
    /// The manifest was refused (not valid JSON, a retired shape, a workspace
    /// where a package is needed, …). The located diagnostic has been printed.
    ConfigInvalid,
} || std.mem.Allocator.Error;

/// Load and parse `botopink.json` from the current working directory.
/// The returned value and all strings in it are owned by `arena`.
pub fn load(arena: std.mem.Allocator, io: std.Io) LoadError!ProjectConfig {
    const data = std.Io.Dir.cwd().readFileAlloc(
        io,
        manifest.FILENAME,
        arena,
        .limited(64 * 1024),
    ) catch return error.ConfigNotFound;

    var err: ?manifest.Located = null;
    const m = manifest.parse(arena, data, manifest.FILENAME, &err) catch |e| switch (e) {
        error.Invalid => {
            err.?.print();
            return error.ConfigInvalid;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    if (m.isWorkspace()) {
        // A workspace declares members; the commands compile a member.
        (try workspaceRefusal(arena, io, m)).print();
        return error.ConfigInvalid;
    }
    var cfg = fromManifest(m);

    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = std.process.currentPath(io, &cwd_buf) catch return cfg;
    cfg.dir = try arena.dupe(u8, cwd_buf[0..n]);

    cfg.workspace = manifest.enclosingWorkspace(arena, io, cfg.dir, &err) catch |e| switch (e) {
        error.Invalid => {
            err.?.print();
            return error.ConfigInvalid;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    return cfg;
}

/// Parse a botopink.json blob from memory, printing a refusal. Splits out the
/// on-disk read so tests can drive synthetic JSON without touching the
/// filesystem. `dir` stays `.` and no enclosing workspace is looked up.
pub fn parse(arena: std.mem.Allocator, data: []const u8) LoadError!ProjectConfig {
    var err: ?manifest.Located = null;
    return parseLocated(arena, data, manifest.FILENAME, &err) catch |e| switch (e) {
        error.ConfigInvalid => {
            err.?.print();
            return error.ConfigInvalid;
        },
        else => |other| return other,
    };
}

/// `parse` without the printing: the refusal is handed back in `out_err`.
pub fn parseLocated(arena: std.mem.Allocator, data: []const u8, path: []const u8, out_err: *?manifest.Located) LoadError!ProjectConfig {
    const m = manifest.parse(arena, data, path, out_err) catch |e| switch (e) {
        error.Invalid => return error.ConfigInvalid,
        error.OutOfMemory => return error.OutOfMemory,
    };
    if (m.isWorkspace()) {
        // Without `io` the members cannot be listed; `load` does that.
        out_err.* = locatedAtWorkspaces(m, WORKSPACE_NOT_A_PACKAGE);
        return error.ConfigInvalid;
    }
    return fromManifest(m);
}

const WORKSPACE_NOT_A_PACKAGE = "botopink.json is a workspace, not a package — run this command inside one of its members";

fn fromManifest(m: manifest.Manifest) ProjectConfig {
    return .{
        .name = m.name,
        .version = m.version,
        .target = m.target orelse "commonJS",
        .entry = m.entry,
        .dependencies = m.dependencies,
        .files = m.files,
        .manifest = m,
    };
}

/// The located refusal for running a package command on a workspace manifest,
/// listing the members when the workspace expands.
pub fn workspaceRefusal(arena: std.mem.Allocator, io: std.Io, m: manifest.Manifest) std.mem.Allocator.Error!manifest.Located {
    var err: ?manifest.Located = null;
    const ws = manifest.expand(arena, io, m, &err) catch |e| switch (e) {
        error.Invalid => return err.?,
        error.OutOfMemory => return error.OutOfMemory,
    };
    return locatedAtWorkspaces(m, try std.fmt.allocPrint(
        arena,
        "{s} is a workspace, not a package — run this command inside one of its members: {s}",
        .{ m.path, try ws.memberList(arena) },
    ));
}

fn locatedAtWorkspaces(m: manifest.Manifest, message: []const u8) manifest.Located {
    // Find the `"workspaces"` key for the caret; line 1 when it is not there.
    const key = "\"workspaces\"";
    const offset = std.mem.indexOf(u8, m.text, key) orelse 0;
    var line: usize = 1;
    var line_start: usize = 0;
    for (m.text[0..offset], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    return .{ .message = message, .file = m.path, .source = m.text, .line = line, .col = offset - line_start + 1, .span = key.len };
}

/// Walk parent directories until `botopink.json` is found or the fs root is
/// reached. Returns the path to that directory (caller owns via `gpa`), or
/// null if not found.
pub fn findProjectRoot(gpa: std.mem.Allocator, io: std.Io) !?[]u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &buf);
    var dir = buf[0..n];

    while (true) {
        const candidate = try std.fs.path.join(gpa, &.{ dir, manifest.FILENAME });
        defer gpa.free(candidate);

        std.Io.Dir.cwd().access(io, candidate, .{}) catch {
            const parent = std.fs.path.dirname(dir) orelse return null;
            if (std.mem.eql(u8, parent, dir)) return null;
            dir = buf[0..parent.len];
            @memcpy(buf[0..parent.len], parent);
            continue;
        };

        return try gpa.dupe(u8, dir);
    }
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "parse: object form with git+branch" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{
        \\  "name": "p",
        \\  "dependencies": {
        \\    "jhonstart": { "git": "https://github.com/botopink/jhonstart.git", "branch": "feat" }
        \\  }
        \\}
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 1), cfg.dependencies.len);
    try testing.expectEqualStrings("jhonstart", cfg.dependencies[0].name);
    const spec = cfg.dependencies[0].spec;
    try testing.expectEqualStrings("https://github.com/botopink/jhonstart.git", spec.git.?);
    try testing.expectEqualStrings("feat", spec.ref.branch);
    try testing.expectEqualStrings("commonJS", cfg.target);
}

test "parse: object form with path-only, and workspace: true" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const cfg = try parse(arena,
        \\{
        \\  "name": "p",
        \\  "dependencies": {
        \\    "local": { "path": "../local-lib" },
        \\    "sibling": { "workspace": true }
        \\  }
        \\}
    );
    try testing.expectEqual(@as(usize, 2), cfg.dependencies.len);
    const spec = cfg.dependencies[0].spec;
    try testing.expectEqual(@as(?[]const u8, null), spec.git);
    try testing.expectEqualStrings("../local-lib", spec.path.?);
    try testing.expect(spec.ref == .none);
    try testing.expect(cfg.dependencies[1].spec.workspace);
}

test "parseLocated: the string-array dependencies form is ConfigInvalid, located (76)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var err: ?manifest.Located = null;
    try testing.expectError(error.ConfigInvalid, parseLocated(arena,
        \\{ "name": "p", "dependencies": ["foo", "bar"] }
    , "botopink.json", &err));
    try testing.expect(std.mem.startsWith(u8, err.?.message, "\"dependencies\" must be an object, not an array"));
    try testing.expectEqualStrings("botopink.json", err.?.file);
    try testing.expectEqual(@as(usize, 1), err.?.line);
    try testing.expectEqual(@as(usize, 16), err.?.col);
}

test "parseLocated: a dependency without a source, and a non-object dependencies field, are ConfigInvalid" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var err: ?manifest.Located = null;
    try testing.expectError(error.ConfigInvalid, parseLocated(arena,
        \\{ "name": "p", "dependencies": { "x": { "branch": "feat" } } }
    , "botopink.json", &err));
    try testing.expectEqualStrings("dependency \"x\" declares no source — one of \"git\", \"path\" or \"workspace\": true is required", err.?.message);
    err = null;
    try testing.expectError(error.ConfigInvalid, parseLocated(arena,
        \\{ "name": "p", "dependencies": "nope" }
    , "botopink.json", &err));
    try testing.expect(std.mem.startsWith(u8, err.?.message, "\"dependencies\" must be an object"));
}

test "parseLocated: a workspace manifest is not a project" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var err: ?manifest.Located = null;
    try testing.expectError(error.ConfigInvalid, parseLocated(arena,
        \\{ "name": "acme", "workspaces": ["modules/*"] }
    , "botopink.json", &err));
    try testing.expectEqualStrings(WORKSPACE_NOT_A_PACKAGE, err.?.message);
    try testing.expectEqual(@as(usize, 19), err.?.col);
}

test "parse: missing dependencies field → empty slice" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const cfg = try parse(arena,
        \\{ "name": "p" }
    );
    try testing.expectEqual(@as(usize, 0), cfg.dependencies.len);
    try testing.expect(cfg.workspace == null);
}

test "dependencyNames: flattens to bare names" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const cfg = try parse(arena,
        \\{ "name": "p", "dependencies": { "a": { "path": "../a" }, "b": { "workspace": true } } }
    );
    const names = try cfg.dependencyNames(testing.allocator);
    defer testing.allocator.free(names);
    try testing.expectEqual(@as(usize, 2), names.len);
    try testing.expectEqualStrings("a", names[0]);
    try testing.expectEqualStrings("b", names[1]);
}

test "files: the manifest's declared surface is read; absent is empty" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const cfg = try parse(arena,
        \\{ "name": "std", "files": ["primitives.bp", "builtins.d.bp"] }
    );
    try testing.expectEqual(@as(usize, 2), cfg.files.len);
    try testing.expectEqualStrings("primitives.bp", cfg.files[0]);
    try testing.expectEqualStrings("builtins.d.bp", cfg.files[1]);

    const none = try parse(arena,
        \\{ "name": "p" }
    );
    try testing.expectEqual(@as(usize, 0), none.files.len);
}

test "workspaceRefusal lists the members of an expandable workspace" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    const ws = test_scratch.path(io, "config-ws/acme");
    test_scratch.remove(io, "config-ws");
    defer test_scratch.remove(io, "config-ws");
    try std.Io.Dir.cwd().createDirPath(io, test_scratch.path(io, "config-ws/acme/modules/acme-core"));
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = test_scratch.path(io, "config-ws/acme/botopink.json"), .data = "{ \"name\": \"acme\",\n  \"workspaces\": [\"modules/*\"] }\n" });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = test_scratch.path(io, "config-ws/acme/modules/acme-core/botopink.json"), .data = "{ \"name\": \"acme-core\", \"files\": [\"root.bp\"] }" });
    var err: ?manifest.Located = null;
    const m = try manifest.read(arena, io, ws, &err);
    const l = try workspaceRefusal(arena, io, m);
    const want = try std.fmt.allocPrint(arena, "{s}/botopink.json is a workspace, not a package — run this command inside one of its members: acme-core", .{ws});
    try testing.expectEqualStrings(want, l.message);
    try testing.expectEqual(@as(usize, 2), l.line);
    try testing.expectEqual(@as(usize, 3), l.col);
}
