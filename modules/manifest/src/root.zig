/// `botopink.json` — the one manifest model every tool reads.
///
/// The CLI (`compiler-cli/src/cli/config.zig`, `libs.zig`), the language server
/// (`language-server/src/project_graph.zig`), the lib-test runner
/// (`lib-test-runner/src/discovery.zig`) and `bpmp` (`bpmp/src/manifest.zig`,
/// `dep/spec.zig`) each used to carry their own reading of the manifest, and the
/// four readings disagreed (decisions 75 and 76 of 1.0.10-beta list how). This
/// package is the seam they now share: it depends on `std` only, so the runner
/// and `bpmp` keep their "no compiler-core" contract while reading the same
/// fields, the same shapes and the same errors as the compiler.
///
/// Two kinds of manifest (decision 75):
///
///   * a **package** — `name`, `version`, `src`, `entry`, `files`, `target`,
///     `targets`, `dependencies`; what `botopink build/test` compiles and what a
///     consumer imports by name;
///   * a **workspace** — `"workspaces": ["modules/*", "examples/*"]`; never a
///     package (no `src`/`files`/`entry`/`dependencies`), it only declares its
///     **members**: every directory an entry expands to that holds a
///     `botopink.json`. A member's `name` is its import name.
///
/// `dependencies` is the object form only (decision 76):
///
///   `{ "<name>": { "path": "…" } | { "git": "…", "branch"|"tag"|"rev": "…" } | { "workspace": true } }`
///
/// Every refusal here is a `Located` error — the message, the manifest file and
/// the line/column of the offending entry — rendered in the CLI's diagnostic
/// shape, so the same text reaches a terminal, the runner's log and the editor.
/// Nothing is parsed and ignored, and no field turns a refusal off (decision 67).
///
/// Schema document: `docs/botopink-json.md` — keep it in sync with this file.
const std = @import("std");

pub const FILENAME = "botopink.json";

// ── Located errors ─────────────────────────────────────────────────────────────

/// A manifest error with a place: the message, the manifest it is in, the raw
/// text (for the caret line) and a 1-based line/column plus span in bytes.
pub const Located = struct {
    message: []const u8,
    file: []const u8,
    source: []const u8,
    line: usize,
    col: usize,
    span: usize,

    /// Render in the shape the CLI uses for every located diagnostic:
    ///
    ///   error: <message>
    ///    --> <file>:<line>:<col>
    ///     |
    ///   N | <source line>
    ///     | ^^^
    ///
    pub fn render(self: Located, w: *std.Io.Writer) !void {
        const line_w = digitWidth(self.line);
        try w.print("error: {s}\n", .{self.message});
        try w.splatByteAll(' ', line_w);
        try w.print("--> {s}:{d}:{d}\n", .{ self.file, self.line, self.col });
        try w.splatByteAll(' ', line_w + 1);
        try w.writeAll("|\n");
        try w.print("{d} | {s}\n", .{ self.line, lineText(self.source, self.line) });
        try w.splatByteAll(' ', line_w + 1);
        try w.writeAll("| ");
        try w.splatByteAll(' ', if (self.col > 0) self.col - 1 else 0);
        try w.splatByteAll('^', @max(self.span, 1));
        try w.writeAll("\n\n");
    }

    /// `render` into an owned string. The only way the allocating writer
    /// fails is out of memory.
    pub fn renderAlloc(self: Located, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        defer aw.deinit();
        self.render(&aw.writer) catch return error.OutOfMemory;
        return aw.toOwnedSlice();
    }

    /// `render` to stderr. Rendering is best effort — a diagnostic is never
    /// worth failing over.
    pub fn print(self: Located) void {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        const text = self.renderAlloc(fba.allocator()) catch {
            std.debug.print("error: {s}\n --> {s}:{d}:{d}\n", .{ self.message, self.file, self.line, self.col });
            return;
        };
        std.debug.print("{s}", .{text});
    }
};

fn digitWidth(n: usize) usize {
    var w: usize = 1;
    var v = n;
    while (v >= 10) : (v /= 10) w += 1;
    return w;
}

/// The text of 1-based `line` in `source`, without its newline.
fn lineText(source: []const u8, line: usize) []const u8 {
    var it = std.mem.splitScalar(u8, source, '\n');
    var n: usize = 1;
    while (it.next()) |l| : (n += 1) {
        if (n == line) return std.mem.trimEnd(u8, l, "\r");
    }
    return "";
}

/// Byte offset → 1-based line and column.
fn lineCol(text: []const u8, offset: usize) struct { line: usize, col: usize } {
    const end = @min(offset, text.len);
    var line: usize = 1;
    var line_start: usize = 0;
    for (text[0..end], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    return .{ .line = line, .col = end - line_start + 1 };
}

const Span = struct { offset: usize, len: usize };

/// Where `"<key>"` sits in the manifest text; the first byte when absent (the
/// message carries the name either way, so an unexpected shape degrades to a
/// diagnostic on line 1 rather than to none).
fn locateKey(text: []const u8, key: []const u8) Span {
    var buf: [256]u8 = undefined;
    const quoted = std.fmt.bufPrint(&buf, "\"{s}\"", .{key}) catch return .{ .offset = 0, .len = 1 };
    if (std.mem.indexOf(u8, text, quoted)) |at| return .{ .offset = at, .len = quoted.len };
    return .{ .offset = 0, .len = @min(text.len, 1) };
}

/// Where `"<entry>"` sits after `"<key>"`: the entry itself, else the key, else
/// the first byte.
fn locateEntry(text: []const u8, key: []const u8, entry: []const u8) Span {
    var kbuf: [256]u8 = undefined;
    const qkey = std.fmt.bufPrint(&kbuf, "\"{s}\"", .{key}) catch return .{ .offset = 0, .len = 1 };
    var ebuf: [512]u8 = undefined;
    const qentry = std.fmt.bufPrint(&ebuf, "\"{s}\"", .{entry}) catch return locateKey(text, key);
    if (std.mem.indexOf(u8, text, qkey)) |k| {
        if (std.mem.indexOfPos(u8, text, k, qentry)) |at| return .{ .offset = at, .len = qentry.len };
        return .{ .offset = k, .len = qkey.len };
    }
    return .{ .offset = 0, .len = @min(text.len, 1) };
}

fn located(text: []const u8, file: []const u8, span: Span, message: []const u8) Located {
    const lc = lineCol(text, span.offset);
    return .{ .message = message, .file = file, .source = text, .line = lc.line, .col = lc.col, .span = span.len };
}

// ── The model ──────────────────────────────────────────────────────────────────

/// The pin of a `git` dependency. The three spellings are exclusive: an entry
/// with two of them is a located error, not a "strongest pin wins".
pub const DepRef = union(enum) {
    branch: []const u8,
    rev: []const u8,
    tag: []const u8,
    none,
};

/// One `dependencies` entry's source. Exactly one of `git`, `path`, `workspace`.
pub const DepSpec = struct {
    git: ?[]const u8 = null,
    path: ?[]const u8 = null,
    ref: DepRef = .none,
    /// `{ "workspace": true }` — the sibling member of the enclosing workspace
    /// with this entry's name.
    workspace: bool = false,

    pub fn isGit(self: DepSpec) bool {
        return self.git != null;
    }

    pub fn isPath(self: DepSpec) bool {
        return self.path != null;
    }
};

pub const DepEntry = struct {
    name: []const u8,
    spec: DepSpec,
};

pub const Kind = enum { package, workspace };

/// A parsed `botopink.json`. Strings point into the arena the manifest was
/// parsed with; `text` is the raw file so an error can be located in it.
pub const Manifest = struct {
    /// The path the manifest was read from (as given by the caller — relative
    /// stays relative), used in every located message.
    path: []const u8,
    text: []const u8,
    kind: Kind,
    name: []const u8,
    version: []const u8 = "0.1.0",
    description: ?[]const u8 = null,
    /// Source directory, relative to the manifest's directory (default `src/`).
    src: []const u8 = "src/",
    /// Module-tree root under `src` (`main.bp` for a binary, `root.bp` for a
    /// library). `null` lets the resolver detect it.
    entry: ?[]const u8 = null,
    /// The default build target, when declared.
    target: ?[]const u8 = null,
    /// The target whitelist the runner honours; a member inherits its
    /// workspace's when it declares none (set by `expand`).
    targets: ?[]const []const u8 = null,
    /// The modules a consumer may import, each relative to `src`.
    files: []const []const u8 = &.{},
    dependencies: []const DepEntry = &.{},
    /// A workspace's member globs, verbatim (`modules/*`, `examples/acme-app`).
    workspaces: []const []const u8 = &.{},

    pub fn isWorkspace(self: Manifest) bool {
        return self.kind == .workspace;
    }

    /// The directory holding the manifest.
    pub fn dir(self: Manifest) []const u8 {
        return std.fs.path.dirname(self.path) orelse ".";
    }

    /// True when the whitelist is absent or contains `target`.
    pub fn supportsTarget(self: Manifest, target: []const u8) bool {
        const list = self.targets orelse return true;
        for (list) |t| if (std.mem.eql(u8, t, target)) return true;
        return false;
    }
};

pub const Error = error{
    /// The manifest was refused; `out_err` carries the located message.
    Invalid,
} || std.mem.Allocator.Error;

pub const ReadError = Error || error{NotFound};

/// Parse `text` as the manifest at `path`. On `error.Invalid` the located
/// refusal is in `out_err`; everything else is `OutOfMemory`.
pub fn parse(arena: std.mem.Allocator, text: []const u8, path: []const u8, out_err: *?Located) Error!Manifest {
    var parsed = std.json.parseFromSlice(std.json.Value, arena, text, .{}) catch {
        out_err.* = located(text, path, .{ .offset = 0, .len = 1 }, "botopink.json is not valid JSON");
        return error.Invalid;
    };
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) {
        out_err.* = located(text, path, .{ .offset = 0, .len = 1 }, "botopink.json must be a JSON object");
        return error.Invalid;
    }
    const obj = root.object;

    var m: Manifest = .{ .path = path, .text = text, .kind = .package, .name = "" };

    m.name = try requireString(arena, obj, "name", text, path, out_err);
    if (try optionalString(arena, obj, "version", text, path, out_err)) |v| m.version = v;
    m.description = try optionalString(arena, obj, "description", text, path, out_err);
    if (try optionalString(arena, obj, "src", text, path, out_err)) |v| m.src = v;
    m.entry = try optionalString(arena, obj, "entry", text, path, out_err);
    m.target = try optionalString(arena, obj, "target", text, path, out_err);
    m.targets = try optionalStringArray(arena, obj, "targets", text, path, out_err);
    if (try optionalStringArray(arena, obj, "files", text, path, out_err)) |f| m.files = f;

    if (obj.get("workspaces") != null) {
        m.kind = .workspace;
        const globs = (try optionalStringArray(arena, obj, "workspaces", text, path, out_err)) orelse unreachable;
        m.workspaces = globs;
        // A workspace is not a package: nothing compiles from it and nothing
        // imports it, so the package fields have no meaning here.
        for ([_][]const u8{ "src", "files", "entry", "dependencies" }) |field| {
            if (obj.get(field) != null) {
                out_err.* = located(text, path, locateKey(text, field), try std.fmt.allocPrint(
                    arena,
                    "a workspace manifest cannot carry \"{s}\" — a workspace declares members, it is not a package; move \"{s}\" to the member's own botopink.json",
                    .{ field, field },
                ));
                return error.Invalid;
            }
        }
        for (globs) |g| try checkGlobForm(arena, g, text, path, out_err);
        return m;
    }

    if (obj.get("dependencies")) |deps_val| {
        m.dependencies = try parseDependencies(arena, deps_val, text, path, out_err);
    }
    return m;
}

/// Read `<dir>/botopink.json` and `parse` it; the manifest's `path` is the
/// joined path. `error.NotFound` when the file cannot be read.
pub fn read(arena: std.mem.Allocator, io: std.Io, dir: []const u8, out_err: *?Located) ReadError!Manifest {
    const path = try std.fs.path.join(arena, &.{ dir, FILENAME });
    const text = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(1024 * 1024)) catch return error.NotFound;
    return parse(arena, text, path, out_err);
}

/// True when `<dir>/botopink.json` exists and declares `workspaces` — the
/// probe the three root walk-ups use to add an ancestor workspace as a root.
/// A manifest that does not parse answers false; the walk-up is not the place
/// to report it (the command that reads it does).
pub fn isWorkspaceDir(io: std.Io, dir: []const u8) bool {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const path = std.fs.path.join(fba.allocator(), &.{ dir, FILENAME }) catch return false;
    var text_buf: [64 * 1024]u8 = undefined;
    var fba2 = std.heap.FixedBufferAllocator.init(&text_buf);
    const text = std.Io.Dir.cwd().readFileAlloc(io, path, fba2.allocator(), .limited(64 * 1024)) catch return false;
    // Cheap probe before parsing: the key must at least appear.
    if (std.mem.indexOf(u8, text, "\"workspaces\"") == null) return false;
    var arena_inst = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_inst.deinit();
    var parsed = std.json.parseFromSlice(std.json.Value, arena_inst.allocator(), text, .{}) catch return false;
    defer parsed.deinit();
    if (parsed.value != .object) return false;
    const v = parsed.value.object.get("workspaces") orelse return false;
    return v == .array;
}

fn requireString(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error![]const u8 {
    const v = obj.get(key) orelse {
        out_err.* = located(text, path, .{ .offset = 0, .len = 1 }, try std.fmt.allocPrint(arena, "botopink.json has no \"{s}\"", .{key}));
        return error.Invalid;
    };
    if (v != .string) {
        out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be a string", .{key}));
        return error.Invalid;
    }
    return try arena.dupe(u8, v.string);
}

fn optionalString(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!?[]const u8 {
    const v = obj.get(key) orelse return null;
    switch (v) {
        .null => return null,
        .string => |s| return try arena.dupe(u8, s),
        else => {
            out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be a string", .{key}));
            return error.Invalid;
        },
    }
}

fn optionalStringArray(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!?[]const []const u8 {
    const v = obj.get(key) orelse return null;
    if (v == .null) return null;
    if (v != .array) {
        out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be an array of strings", .{key}));
        return error.Invalid;
    }
    var out = try arena.alloc([]const u8, v.array.items.len);
    for (v.array.items, 0..) |item, i| {
        if (item != .string) {
            out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be an array of strings — entry {d} is not a string", .{ key, i + 1 }));
            return error.Invalid;
        }
        out[i] = try arena.dupe(u8, item.string);
    }
    return out;
}

/// Only two glob forms are required by decision 75: `<dir>/*` (every child of
/// `<dir>` that holds a manifest) and a literal `<dir>`.
fn checkGlobForm(arena: std.mem.Allocator, g: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!void {
    const bad = g.len == 0 or
        std.fs.path.isAbsolute(g) or
        std.mem.startsWith(u8, g, "..") or
        (std.mem.indexOfScalar(u8, g, '*') != null and !(std.mem.endsWith(u8, g, "/*") and std.mem.count(u8, g, "*") == 1));
    if (bad) {
        out_err.* = located(text, path, locateEntry(text, "workspaces", g), try std.fmt.allocPrint(
            arena,
            "workspaces entry \"{s}\" is not a supported form — use \"<dir>/*\" (every child of <dir> holding a botopink.json) or a literal \"<dir>\" inside the workspace",
            .{g},
        ));
        return error.Invalid;
    }
}

const DEP_SHAPE = "{ \"<name>\": { \"path\": \"…\" } | { \"git\": \"…\", \"branch\"|\"tag\"|\"rev\": \"…\" } | { \"workspace\": true } }";

fn parseDependencies(arena: std.mem.Allocator, node: std.json.Value, text: []const u8, path: []const u8, out_err: *?Located) Error![]const DepEntry {
    switch (node) {
        .object => {},
        .array => |arr| {
            // The string array is the shape decision 76 retired. Name the fix
            // with the first entry so the message is a rewrite, not a rule.
            const first: []const u8 = if (arr.items.len > 0 and arr.items[0] == .string) arr.items[0].string else "<name>";
            out_err.* = located(text, path, locateKey(text, "dependencies"), try std.fmt.allocPrint(
                arena,
                "\"dependencies\" must be an object, not an array — write {s}; for example [\"{s}\"] becomes {{ \"{s}\": {{ \"path\": \"../{s}\" }} }}",
                .{ DEP_SHAPE, first, first, first },
            ));
            return error.Invalid;
        },
        else => {
            out_err.* = located(text, path, locateKey(text, "dependencies"), try std.fmt.allocPrint(arena, "\"dependencies\" must be an object — {s}", .{DEP_SHAPE}));
            return error.Invalid;
        },
    }
    const obj = node.object;
    var out = try arena.alloc(DepEntry, obj.count());
    var i: usize = 0;
    var it = obj.iterator();
    while (it.next()) |kv| {
        const name = kv.key_ptr.*;
        const spec_node = kv.value_ptr.*;
        const at = locateEntry(text, "dependencies", name);
        if (spec_node != .object) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" must be an object — {s}", .{ name, DEP_SHAPE }));
            return error.Invalid;
        }
        const s = spec_node.object;
        var spec: DepSpec = .{};
        var pins: usize = 0;

        if (s.get("git")) |v| {
            if (v != .string) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"git\" must be a string", .{name}));
                return error.Invalid;
            }
            spec.git = try arena.dupe(u8, v.string);
        }
        if (s.get("path")) |v| {
            if (v != .string) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"path\" must be a string", .{name}));
                return error.Invalid;
            }
            spec.path = try arena.dupe(u8, v.string);
        }
        if (s.get("workspace")) |v| {
            if (v != .bool or !v.bool) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"workspace\" can only be true — {{ \"workspace\": true }} names the sibling member of the enclosing workspace", .{name}));
                return error.Invalid;
            }
            spec.workspace = true;
        }
        inline for (.{ "branch", "tag", "rev" }) |pin| {
            if (s.get(pin)) |v| {
                if (v != .string) {
                    out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"{s}\" must be a string", .{ name, pin }));
                    return error.Invalid;
                }
                pins += 1;
                const dup = try arena.dupe(u8, v.string);
                spec.ref = if (comptime std.mem.eql(u8, pin, "branch")) .{ .branch = dup } else if (comptime std.mem.eql(u8, pin, "tag")) .{ .tag = dup } else .{ .rev = dup };
            }
        }

        const sources = @as(usize, @intFromBool(spec.git != null)) + @intFromBool(spec.path != null) + @intFromBool(spec.workspace);
        if (sources == 0) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" declares no source — one of \"git\", \"path\" or \"workspace\": true is required", .{name}));
            return error.Invalid;
        }
        if (sources > 1) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" declares more than one source — exactly one of \"git\", \"path\" or \"workspace\": true", .{name}));
            return error.Invalid;
        }
        if (pins > 1) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" declares more than one pin — exactly one of \"branch\", \"tag\" or \"rev\"", .{name}));
            return error.Invalid;
        }
        if (pins == 1 and spec.git == null) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" pins a ref without a \"git\" source — a pin applies to a git dependency only", .{name}));
            return error.Invalid;
        }
        out[i] = .{ .name = try arena.dupe(u8, name), .spec = spec };
        i += 1;
    }
    return out[0..i];
}

// ── Workspaces ─────────────────────────────────────────────────────────────────

pub const Member = struct {
    /// The member's import name — its manifest's `name`.
    name: []const u8,
    /// The member's directory (`<workspace>/<expansion>`).
    dir: []const u8,
    manifest: Manifest,
};

pub const Workspace = struct {
    dir: []const u8,
    manifest: Manifest,
    members: []const Member,

    pub fn member(self: Workspace, name: []const u8) ?Member {
        for (self.members) |m| if (std.mem.eql(u8, m.name, name)) return m;
        return null;
    }

    /// The member whose directory is `dir` (both compared as given — callers
    /// pass paths built from the same base).
    pub fn memberAt(self: Workspace, dir: []const u8) ?Member {
        for (self.members) |m| if (samePath(m.dir, dir)) return m;
        return null;
    }

    /// `a, b, c` — for messages that list the members.
    pub fn memberList(self: Workspace, arena: std.mem.Allocator) ![]const u8 {
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        for (self.members, 0..) |m, i| {
            if (i > 0) try buf.appendSlice(arena, ", ");
            try buf.appendSlice(arena, m.name);
        }
        if (self.members.len == 0) try buf.appendSlice(arena, "none");
        return buf.toOwnedSlice(arena);
    }
};

/// Two paths name the same directory when they are byte-equal after trailing
/// separators are dropped. Callers build both from one base (the workspace
/// directory, or the process cwd), so no realpath is needed.
fn samePath(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, std.mem.trimEnd(u8, a, "/"), std.mem.trimEnd(u8, b, "/"));
}

/// Expand a workspace manifest into its members and check the rules of
/// decision 75 over them:
///
///   * every `workspaces` entry expands to directories holding a manifest
///     (a `<dir>/*` glob skips a child without one; a literal `<dir>` must have one);
///   * a member is a package, never a workspace;
///   * two members with one `name` is an error;
///   * a member's `targets` may only restrict the workspace's; a member without
///     `targets` inherits them;
///   * `{ "workspace": true }` names a sibling member; a `path` that lands on a
///     sibling member or on the workspace itself is refused.
///
/// `m.path` must be the workspace's manifest path; member paths are built under
/// its directory.
pub fn expand(arena: std.mem.Allocator, io: std.Io, m: Manifest, out_err: *?Located) Error!Workspace {
    std.debug.assert(m.isWorkspace());
    const ws_dir = m.dir();
    var members: std.ArrayListUnmanaged(Member) = .empty;

    for (m.workspaces) |g| {
        if (std.mem.endsWith(u8, g, "/*")) {
            const base = try std.fs.path.join(arena, &.{ ws_dir, g[0 .. g.len - 2] });
            var d = std.Io.Dir.cwd().openDir(io, base, .{ .iterate = true }) catch {
                out_err.* = located(m.text, m.path, locateEntry(m.text, "workspaces", g), try std.fmt.allocPrint(
                    arena,
                    "workspaces entry \"{s}\": {s} is not a directory that can be read",
                    .{ g, base },
                ));
                return error.Invalid;
            };
            defer d.close(io);
            // Sorted, so the member order (and every message that lists it) is stable.
            var names: std.ArrayListUnmanaged([]const u8) = .empty;
            var it = d.iterate();
            while (it.next(io) catch null) |entry| {
                if (entry.kind != .directory) continue;
                try names.append(arena, try arena.dupe(u8, entry.name));
            }
            std.mem.sort([]const u8, names.items, {}, struct {
                fn lt(_: void, a: []const u8, b: []const u8) bool {
                    return std.mem.lessThan(u8, a, b);
                }
            }.lt);
            for (names.items) |child| {
                const member_dir = try std.fs.path.join(arena, &.{ base, child });
                const manifest_path = try std.fs.path.join(arena, &.{ member_dir, FILENAME });
                std.Io.Dir.cwd().access(io, manifest_path, .{}) catch continue; // not a member
                try addMember(arena, io, &members, m, g, member_dir, out_err);
            }
        } else {
            const member_dir = try std.fs.path.join(arena, &.{ ws_dir, g });
            const manifest_path = try std.fs.path.join(arena, &.{ member_dir, FILENAME });
            std.Io.Dir.cwd().access(io, manifest_path, .{}) catch {
                out_err.* = located(m.text, m.path, locateEntry(m.text, "workspaces", g), try std.fmt.allocPrint(
                    arena,
                    "workspaces entry \"{s}\": {s} does not exist — a literal entry names a directory holding a botopink.json",
                    .{ g, manifest_path },
                ));
                return error.Invalid;
            };
            try addMember(arena, io, &members, m, g, member_dir, out_err);
        }
    }

    var ws: Workspace = .{ .dir = ws_dir, .manifest = m, .members = members.items };

    // Second pass — rules that need the whole member set.
    for (members.items) |*mem| {
        const mm = &mem.manifest;
        for (mm.dependencies) |dep| {
            const at = locateEntry(mm.text, "dependencies", dep.name);
            if (dep.spec.workspace) {
                if (std.mem.eql(u8, dep.name, mem.name)) {
                    out_err.* = located(mm.text, mm.path, at, try std.fmt.allocPrint(arena, "\"{s}\" cannot depend on itself", .{dep.name}));
                    return error.Invalid;
                }
                if (ws.member(dep.name) == null) {
                    out_err.* = located(mm.text, mm.path, at, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": {{ \"workspace\": true }} names no member of {s} (members: {s})",
                        .{ dep.name, m.path, try ws.memberList(arena) },
                    ));
                    return error.Invalid;
                }
            } else if (dep.spec.path) |p| {
                const target = try std.fs.path.resolve(arena, &.{ mem.dir, p });
                const ws_abs = try std.fs.path.resolve(arena, &.{ws_dir});
                if (samePath(target, ws_abs)) {
                    out_err.* = located(mm.text, mm.path, at, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": path \"{s}\" points at the workspace itself — a workspace is not a package; depend on one of its members with {{ \"workspace\": true }} (members: {s})",
                        .{ dep.name, p, try ws.memberList(arena) },
                    ));
                    return error.Invalid;
                }
                for (members.items) |other| {
                    const other_abs = try std.fs.path.resolve(arena, &.{other.dir});
                    if (samePath(target, other_abs)) {
                        out_err.* = located(mm.text, mm.path, at, try std.fmt.allocPrint(
                            arena,
                            "\"{s}\": path \"{s}\" points at the sibling member \"{s}\" — use {{ \"workspace\": true }}",
                            .{ dep.name, p, other.name },
                        ));
                        return error.Invalid;
                    }
                }
            }
        }
        // `targets`: inherit, or restrict.
        if (m.targets) |ws_targets| {
            if (mm.targets) |own| {
                for (own) |t| {
                    if (!m.supportsTarget(t)) {
                        out_err.* = located(mm.text, mm.path, locateEntry(mm.text, "targets", t), try std.fmt.allocPrint(
                            arena,
                            "\"{s}\" is not one of the workspace's targets [{s}] ({s}) — a member may only restrict the workspace's targets",
                            .{ t, try joinQuoted(arena, ws_targets), m.path },
                        ));
                        return error.Invalid;
                    }
                }
            } else mm.targets = ws_targets;
        }
    }
    ws.members = try members.toOwnedSlice(arena);
    return ws;
}

fn joinQuoted(arena: std.mem.Allocator, items: []const []const u8) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (items, 0..) |s, i| {
        if (i > 0) try buf.appendSlice(arena, ", ");
        try buf.append(arena, '"');
        try buf.appendSlice(arena, s);
        try buf.append(arena, '"');
    }
    return buf.toOwnedSlice(arena);
}

fn addMember(
    arena: std.mem.Allocator,
    io: std.Io,
    members: *std.ArrayListUnmanaged(Member),
    ws: Manifest,
    glob: []const u8,
    member_dir: []const u8,
    out_err: *?Located,
) Error!void {
    const mm = read(arena, io, member_dir, out_err) catch |err| switch (err) {
        error.NotFound => {
            out_err.* = located(ws.text, ws.path, locateEntry(ws.text, "workspaces", glob), try std.fmt.allocPrint(
                arena,
                "workspaces entry \"{s}\": {s}/botopink.json could not be read",
                .{ glob, member_dir },
            ));
            return error.Invalid;
        },
        error.Invalid => return error.Invalid,
        error.OutOfMemory => return error.OutOfMemory,
    };
    if (mm.isWorkspace()) {
        out_err.* = located(mm.text, mm.path, locateKey(mm.text, "workspaces"), try std.fmt.allocPrint(
            arena,
            "\"{s}\" is a member of {s} and cannot itself be a workspace — workspaces do not nest",
            .{ mm.name, ws.path },
        ));
        return error.Invalid;
    }
    for (members.items) |other| {
        if (std.mem.eql(u8, other.name, mm.name)) {
            out_err.* = located(mm.text, mm.path, locateKey(mm.text, "name"), try std.fmt.allocPrint(
                arena,
                "member name \"{s}\" is declared twice in {s}: {s} and {s}",
                .{ mm.name, ws.path, other.manifest.path, mm.path },
            ));
            return error.Invalid;
        }
    }
    try members.append(arena, .{ .name = mm.name, .dir = member_dir, .manifest = mm });
}

/// The workspace `project_dir` is a member of, if any: the nearest ancestor
/// holding a workspace manifest whose expansion lists `project_dir`. An
/// ancestor workspace that does not list the directory is not its workspace
/// (`null`). `project_dir` must be absolute. A workspace that does not expand
/// is a located error — the member cannot know its siblings.
pub fn enclosingWorkspace(arena: std.mem.Allocator, io: std.Io, project_dir: []const u8, out_err: *?Located) Error!?Workspace {
    var dir: []const u8 = std.fs.path.dirname(project_dir) orelse return null;
    while (true) {
        if (isWorkspaceDir(io, dir)) {
            const m = read(arena, io, dir, out_err) catch |err| switch (err) {
                error.NotFound => return null,
                else => |e| return e,
            };
            const ws = try expand(arena, io, m, out_err);
            const abs_target = try std.fs.path.resolve(arena, &.{project_dir});
            for (ws.members) |mem| {
                const abs_member = try std.fs.path.resolve(arena, &.{mem.dir});
                if (samePath(abs_member, abs_target)) return ws;
            }
            return null;
        }
        const parent = std.fs.path.dirname(dir) orelse return null;
        if (std.mem.eql(u8, parent, dir)) return null;
        dir = parent;
    }
}

/// A package is a library when its module tree is rooted at `root.bp` rather
/// than `main.bp`: `entry` decides when set, else the presence of
/// `<src>/main.bp`. A library member with no `files` ships nothing to a
/// consumer — the failure `botopink test` and the runner report.
pub fn isLibraryPackage(io: std.Io, m: Manifest) bool {
    if (m.entry) |e| return !std.mem.eql(u8, std.fs.path.basename(e), "main.bp");
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const main_path = std.fs.path.join(fba.allocator(), &.{ m.dir(), std.mem.trimEnd(u8, m.src, "/"), "main.bp" }) catch return true;
    std.Io.Dir.cwd().access(io, main_path, .{}) catch return true;
    return false;
}

pub const SHIPS_NOTHING = "ships nothing: manifest has no \"files\" — a workspace member that is a library lists every module a consumer may import";

/// The located `ships nothing` error for a library member without `files`, or
/// null when the member ships something (or is an application).
pub fn shipsNothing(io: std.Io, m: Manifest) ?Located {
    if (m.files.len > 0) return null;
    if (!isLibraryPackage(io, m)) return null;
    return located(m.text, m.path, locateKey(m.text, "name"), SHIPS_NOTHING);
}

// ── Discovery across roots ─────────────────────────────────────────────────────

/// One library a root list makes reachable by name: a package directory that
/// is an immediate child of a root, or a member of a workspace that is a root
/// or a root's child. A workspace itself is an entry too (`is_workspace`), so a
/// lookup by its name can say what it is instead of "not found".
pub const Entry = struct {
    /// Import name: the directory name of a plain package, the manifest `name`
    /// of a member, the directory name of a workspace.
    name: []const u8,
    dir: []const u8,
    /// Null when `problem` prevented parsing.
    manifest: ?Manifest,
    /// The enclosing workspace of a member.
    workspace: ?*const Workspace = null,
    is_workspace: bool = false,
    /// Why this entry cannot be used: a manifest that does not parse, a
    /// workspace that does not expand, a name declared by two libraries.
    problem: ?Located = null,
};

/// Discover every library the ordered `roots` make reachable, one shared walk
/// for the compiler, the runner and the language server:
///
///   * a root whose own `botopink.json` is a workspace contributes its members;
///   * otherwise each immediate child holding a `botopink.json` contributes
///     itself (a package) or its members (a workspace) — no recursion beyond
///     that, no environment variable;
///   * the same directory reached through two roots is one entry;
///   * two **members** with one `name` in different directories (across roots,
///     or a member and a plain package) are both marked with a located problem
///     — first-root-wins is what decision 75 retires. Two plain packages with
///     one name keep first-root-wins, as they always did.
///
/// A manifest that is refused marks only its own entry (or its workspace's
/// members' entry) with the problem — a broken sibling never fails a build
/// that does not use it. Entries keep root order.
pub fn scanRoots(arena: std.mem.Allocator, io: std.Io, roots: []const []const u8) std.mem.Allocator.Error![]Entry {
    var entries: std.ArrayListUnmanaged(Entry) = .empty;
    for (roots) |root| {
        var err: ?Located = null;
        if (read(arena, io, root, &err)) |own| {
            if (own.isWorkspace()) {
                try addWorkspaceEntries(arena, io, &entries, own, std.fs.path.basename(root), root);
                continue;
            }
            // A root that is itself a package: not a layout any tool produces;
            // scan its children like any other root.
        } else |e| switch (e) {
            error.NotFound => {},
            error.Invalid => {
                // The root's own manifest is broken but it is not a workspace
                // (or cannot be told); children still count.
            },
            error.OutOfMemory => return error.OutOfMemory,
        }
        var d = std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true }) catch continue;
        defer d.close(io);
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = d.iterate();
        while (it.next(io) catch null) |entry| {
            if (entry.kind != .directory) continue;
            try names.append(arena, try arena.dupe(u8, entry.name));
        }
        std.mem.sort([]const u8, names.items, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        for (names.items) |child| {
            const child_dir = try std.fs.path.join(arena, &.{ root, child });
            var cerr: ?Located = null;
            const cm = read(arena, io, child_dir, &cerr) catch |e| switch (e) {
                error.NotFound => continue,
                error.Invalid => {
                    try addUnique(arena, &entries, .{ .name = child, .dir = child_dir, .manifest = null, .problem = cerr });
                    continue;
                },
                error.OutOfMemory => return error.OutOfMemory,
            };
            if (cm.isWorkspace()) {
                try addWorkspaceEntries(arena, io, &entries, cm, child, child_dir);
            } else {
                try addUnique(arena, &entries, .{ .name = child, .dir = child_dir, .manifest = cm });
            }
        }
    }
    return resolveDuplicateNames(arena, entries.items);
}

fn addWorkspaceEntries(
    arena: std.mem.Allocator,
    io: std.Io,
    entries: *std.ArrayListUnmanaged(Entry),
    m: Manifest,
    name: []const u8,
    dir: []const u8,
) std.mem.Allocator.Error!void {
    var err: ?Located = null;
    const ws = expand(arena, io, m, &err) catch |e| switch (e) {
        error.Invalid => {
            try addUnique(arena, entries, .{ .name = name, .dir = dir, .manifest = m, .is_workspace = true, .problem = err });
            return;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    const ws_ptr = try arena.create(Workspace);
    ws_ptr.* = ws;
    for (ws.members) |mem| {
        try addUnique(arena, entries, .{ .name = mem.name, .dir = mem.dir, .manifest = mem.manifest, .workspace = ws_ptr });
    }
    // The umbrella after its members: a core member named like its umbrella's
    // directory (`repository/rakun/modules/rakun`) is what `rakun` means.
    try addUnique(arena, entries, .{ .name = name, .dir = dir, .manifest = m, .is_workspace = true, .workspace = ws_ptr });
}

/// Append unless the same directory is already listed (one directory reached
/// through two roots — the enclosing workspace of the cwd and `repository/`,
/// typically — is one library).
fn addUnique(arena: std.mem.Allocator, entries: *std.ArrayListUnmanaged(Entry), e: Entry) std.mem.Allocator.Error!void {
    const abs = try std.fs.path.resolve(arena, &.{e.dir});
    for (entries.items) |x| {
        const xabs = try std.fs.path.resolve(arena, &.{x.dir});
        if (samePath(abs, xabs)) return;
    }
    try entries.append(arena, e);
}

/// One name, two directories: two plain packages keep first-root-wins (the
/// later one is dropped, as it always was); a pair involving a workspace member
/// is refused on both sides. A workspace entry never competes — a core member
/// named like its umbrella's directory is told apart by `is_workspace`.
fn resolveDuplicateNames(arena: std.mem.Allocator, entries: []Entry) std.mem.Allocator.Error![]Entry {
    var out: std.ArrayListUnmanaged(Entry) = .empty;
    outer: for (entries) |e| {
        if (!e.is_workspace) {
            for (out.items) |*seen| {
                if (seen.is_workspace or !std.mem.eql(u8, seen.name, e.name)) continue;
                if (seen.workspace == null and e.workspace == null) continue :outer; // first root wins
                const message = try std.fmt.allocPrint(
                    arena,
                    "\"{s}\" is declared by two libraries: {s} and {s} — a name resolves to one library; rename one of them",
                    .{ e.name, seen.dir, e.dir },
                );
                if (seen.problem == null) seen.problem = nameProblem(seen.*, message);
                var dup = e;
                if (dup.problem == null) dup.problem = nameProblem(dup, message);
                try out.append(arena, dup);
                continue :outer;
            }
        }
        try out.append(arena, e);
    }
    return out.toOwnedSlice(arena);
}

fn nameProblem(e: Entry, message: []const u8) Located {
    if (e.manifest) |m| return located(m.text, m.path, locateKey(m.text, "name"), message);
    return .{ .message = message, .file = e.dir, .source = "", .line = 1, .col = 1, .span = 1 };
}

/// The library named `name`: the first package or member so named; a
/// workspace so named only when no package is (so a lookup can say what the
/// umbrella is instead of "not found").
pub fn find(entries: []const Entry, name: []const u8) ?Entry {
    var umbrella: ?Entry = null;
    for (entries) |e| {
        if (!std.mem.eql(u8, e.name, name)) continue;
        if (e.is_workspace) {
            if (umbrella == null) umbrella = e;
            continue;
        }
        return e;
    }
    return umbrella;
}

// ── Dependency resolution ──────────────────────────────────────────────────────

pub const ResolvedDep = struct {
    dir: []const u8,
    manifest: Manifest,
};

/// Resolve one `dependencies` entry of the project at `project_dir` (absolute)
/// whose manifest is `project`:
///
///   * `{ "workspace": true }` → the sibling member of the enclosing workspace
///     with that name; no enclosing workspace, or no such member, is a located
///     error in the project's manifest;
///   * `{ "path": … }` → `<project_dir>/<path>`, which must hold a package of
///     that name; a workspace, a sibling member (use `{ "workspace": true }`) and
///     a name mismatch are located errors;
///   * `{ "git": … }` → the first entry named so in `entries`, then in
///     `fallback_entries` (where `bpmp install` materialises it); an entry with
///     a problem returns that problem; a workspace is refused with its member
///     list; `null` when nothing carries the name.
pub fn resolveDependency(
    arena: std.mem.Allocator,
    io: std.Io,
    project: Manifest,
    project_dir: []const u8,
    dep: DepEntry,
    entries: []const Entry,
    fallback_entries: []const Entry,
    out_err: *?Located,
) Error!?ResolvedDep {
    const at = locateEntry(project.text, "dependencies", dep.name);
    if (dep.spec.workspace) {
        const ws = (try enclosingWorkspace(arena, io, project_dir, out_err)) orelse {
            out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": {{ \"workspace\": true }} but {s} is not a member of any workspace — no ancestor botopink.json lists this directory under \"workspaces\"",
                .{ dep.name, project.path },
            ));
            return error.Invalid;
        };
        const mem = ws.member(dep.name) orelse {
            out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": {{ \"workspace\": true }} names no member of {s} (members: {s})",
                .{ dep.name, ws.manifest.path, try ws.memberList(arena) },
            ));
            return error.Invalid;
        };
        return .{ .dir = mem.dir, .manifest = mem.manifest };
    }
    if (dep.spec.path) |p| {
        const target = try std.fs.path.resolve(arena, &.{ project_dir, p });
        var terr: ?Located = null;
        const tm = read(arena, io, target, &terr) catch |e| switch (e) {
            error.NotFound => {
                out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
                    arena,
                    "\"{s}\": path \"{s}\" holds no botopink.json (looked at {s}/botopink.json)",
                    .{ dep.name, p, target },
                ));
                return error.Invalid;
            },
            error.Invalid => {
                out_err.* = terr;
                return error.Invalid;
            },
            error.OutOfMemory => return error.OutOfMemory,
        };
        if (tm.isWorkspace()) {
            var werr: ?Located = null;
            const ws = expand(arena, io, tm, &werr) catch |e| switch (e) {
                error.Invalid => {
                    out_err.* = werr;
                    return error.Invalid;
                },
                error.OutOfMemory => return error.OutOfMemory,
            };
            out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": path \"{s}\" is a workspace, not a package — depend on one of its members: {s}",
                .{ dep.name, p, try ws.memberList(arena) },
            ));
            return error.Invalid;
        }
        if (try enclosingWorkspace(arena, io, project_dir, out_err)) |ws| {
            for (ws.members) |mem| {
                if (samePath(try std.fs.path.resolve(arena, &.{mem.dir}), target)) {
                    out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": path \"{s}\" points at the sibling member \"{s}\" — use {{ \"workspace\": true }}",
                        .{ dep.name, p, mem.name },
                    ));
                    return error.Invalid;
                }
            }
        }
        if (!std.mem.eql(u8, tm.name, dep.name)) {
            out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": path \"{s}\" holds a package named \"{s}\" — the dependency key is the import name and must match",
                .{ dep.name, p, tm.name },
            ));
            return error.Invalid;
        }
        return .{ .dir = target, .manifest = tm };
    }
    // git: by name across the roots, then the install store.
    const found = find(entries, dep.name) orelse find(fallback_entries, dep.name) orelse return null;
    if (found.problem) |pr| {
        out_err.* = pr;
        return error.Invalid;
    }
    if (found.is_workspace) {
        const list = if (found.workspace) |ws| try ws.memberList(arena) else "none";
        out_err.* = located(project.text, project.path, at, try std.fmt.allocPrint(
            arena,
            "\"{s}\" is a workspace, not a package — import one of its members: {s}",
            .{ dep.name, list },
        ));
        return error.Invalid;
    }
    return .{ .dir = found.dir, .manifest = found.manifest.? };
}

// ── Tests ──────────────────────────────────────────────────────────────────────
//
// Fixtures live under `tests/fixtures/` (cwd is `modules/manifest`, set by
// build.zig): a good workspace and one broken manifest per located error.

const testing = std.testing;
const FIX = "tests/fixtures";

fn parseText(arena: std.mem.Allocator, text: []const u8) !Manifest {
    var err: ?Located = null;
    return parse(arena, text, "botopink.json", &err);
}

/// Parse `text` expecting a refusal; returns the rendered located error.
fn refuse(arena: std.mem.Allocator, text: []const u8) ![]const u8 {
    var err: ?Located = null;
    const r = parse(arena, text, "botopink.json", &err);
    try testing.expectError(error.Invalid, r);
    return try err.?.renderAlloc(arena);
}

test "parse: a package manifest — every field the tools read" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const m = try parseText(a,
        \\{ "name": "acme", "version": "0.0.1", "description": "d", "src": "lib/", "entry": "root.bp",
        \\  "target": "commonJS", "targets": ["commonJS", "erlang"], "files": ["root.bp", "http.bp"],
        \\  "dependencies": {
        \\    "std-extra": { "path": "../std-extra" },
        \\    "jhonstart": { "git": "https://github.com/botopink/jhonstart.git", "branch": "feat" },
        \\    "acme-core": { "workspace": true }
        \\  } }
    );
    try testing.expectEqual(Kind.package, m.kind);
    try testing.expectEqualStrings("acme", m.name);
    try testing.expectEqualStrings("0.0.1", m.version);
    try testing.expectEqualStrings("d", m.description.?);
    try testing.expectEqualStrings("lib/", m.src);
    try testing.expectEqualStrings("root.bp", m.entry.?);
    try testing.expectEqualStrings("commonJS", m.target.?);
    try testing.expectEqual(@as(usize, 2), m.targets.?.len);
    try testing.expectEqual(@as(usize, 2), m.files.len);
    try testing.expectEqual(@as(usize, 3), m.dependencies.len);
    try testing.expectEqualStrings("../std-extra", m.dependencies[0].spec.path.?);
    try testing.expectEqualStrings("feat", m.dependencies[1].spec.ref.branch);
    try testing.expect(m.dependencies[2].spec.workspace);
    try testing.expect(m.supportsTarget("erlang"));
    try testing.expect(!m.supportsTarget("wasm"));
}

test "parse: defaults when the optional fields are absent" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const m = try parseText(arena_inst.allocator(),
        \\{ "name": "p" }
    );
    try testing.expectEqualStrings("0.1.0", m.version);
    try testing.expectEqualStrings("src/", m.src);
    try testing.expect(m.entry == null);
    try testing.expect(m.target == null);
    try testing.expect(m.targets == null);
    try testing.expectEqual(@as(usize, 0), m.files.len);
    try testing.expectEqual(@as(usize, 0), m.dependencies.len);
    try testing.expect(m.supportsTarget("wasm"));
}

test "parse: the string-array dependencies form is a located error naming the fix (76)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p",
        \\  "dependencies": ["erika"] }
    );
    try testing.expectEqualStrings(
        \\error: "dependencies" must be an object, not an array — write { "<name>": { "path": "…" } | { "git": "…", "branch"|"tag"|"rev": "…" } | { "workspace": true } }; for example ["erika"] becomes { "erika": { "path": "../erika" } }
        \\ --> botopink.json:2:3
        \\  |
        \\2 |   "dependencies": ["erika"] }
        \\  |   ^^^^^^^^^^^^^^
        \\
        \\
    , out);
}

test "parse: an empty dependencies array is refused too — the object form is the only form" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p", "dependencies": [] }
    );
    try testing.expect(std.mem.indexOf(u8, out, "must be an object, not an array") != null);
}

test "parse: a dependency with no source is a located error" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p", "dependencies": {
        \\  "x": { "branch": "feat" } } }
    );
    try testing.expectEqualStrings(
        \\error: dependency "x" declares no source — one of "git", "path" or "workspace": true is required
        \\ --> botopink.json:2:3
        \\  |
        \\2 |   "x": { "branch": "feat" } } }
        \\  |   ^^^
        \\
        \\
    , out);
}

test "parse: two pins, two sources, a pin without git, and workspace: false are located errors" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const two_pins = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "git": "https://e/x.git", "branch": "feat", "rev": "deadbeef" } } }
    );
    try testing.expect(std.mem.indexOf(u8, two_pins, "error: dependency \"x\" declares more than one pin — exactly one of \"branch\", \"tag\" or \"rev\"") != null);
    const two_sources = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "path": "../x", "workspace": true } } }
    );
    try testing.expect(std.mem.indexOf(u8, two_sources, "error: dependency \"x\" declares more than one source — exactly one of \"git\", \"path\" or \"workspace\": true") != null);
    const pin_no_git = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "path": "../x", "tag": "v1" } } }
    );
    try testing.expect(std.mem.indexOf(u8, pin_no_git, "error: dependency \"x\" pins a ref without a \"git\" source") != null);
    const ws_false = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "workspace": false } } }
    );
    try testing.expect(std.mem.indexOf(u8, ws_false, "error: dependency \"x\": \"workspace\" can only be true") != null);
}

test "parse: a workspace manifest — kind, globs, and no package field" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const m = try parseText(a,
        \\{ "name": "acme", "targets": ["commonJS"], "workspaces": ["modules/*", "examples/acme-app"] }
    );
    try testing.expect(m.isWorkspace());
    try testing.expectEqual(@as(usize, 2), m.workspaces.len);

    const with_files = try refuse(a,
        \\{ "name": "acme",
        \\  "workspaces": ["modules/*"],
        \\  "files": ["root.bp"] }
    );
    try testing.expectEqualStrings(
        \\error: a workspace manifest cannot carry "files" — a workspace declares members, it is not a package; move "files" to the member's own botopink.json
        \\ --> botopink.json:3:3
        \\  |
        \\3 |   "files": ["root.bp"] }
        \\  |   ^^^^^^^
        \\
        \\
    , with_files);
    for ([_][]const u8{ "src", "entry", "dependencies" }) |field| {
        const text = try std.fmt.allocPrint(a, "{{ \"name\": \"w\", \"workspaces\": [\"m/*\"], \"{s}\": {s} }}", .{ field, if (std.mem.eql(u8, field, "dependencies")) "{}" else "\"x\"" });
        const out = try refuse(a, text);
        const want = try std.fmt.allocPrint(a, "error: a workspace manifest cannot carry \"{s}\"", .{field});
        try testing.expect(std.mem.indexOf(u8, out, want) != null);
    }
}

test "parse: unsupported glob forms are located errors" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const out = try refuse(a,
        \\{ "name": "w", "workspaces": ["modules/**"] }
    );
    try testing.expect(std.mem.indexOf(u8, out, "error: workspaces entry \"modules/**\" is not a supported form — use \"<dir>/*\"") != null);
    for ([_][]const u8{ "*/src", "../x", "/abs", "" }) |g| {
        const text = try std.fmt.allocPrint(a, "{{ \"name\": \"w\", \"workspaces\": [\"{s}\"] }}", .{g});
        _ = try refuse(a, text);
    }
}

test "expand: the fixture workspace — members, inherited targets, example member" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var err: ?Located = null;
    const m = try read(a, testing.io, FIX ++ "/workspace", &err);
    try testing.expect(m.isWorkspace());
    const ws = try expand(a, testing.io, m, &err);
    try testing.expectEqual(@as(usize, 4), ws.members.len);
    try testing.expectEqualStrings("acme, acme-empty, acme-web, acme-app", try ws.memberList(a));
    // `acme` restricts to commonJS; `acme-web` and `acme-app` inherit both.
    const core = ws.member("acme").?;
    try testing.expectEqual(@as(usize, 1), core.manifest.targets.?.len);
    const web = ws.member("acme-web").?;
    try testing.expectEqual(@as(usize, 2), web.manifest.targets.?.len);
    try testing.expectEqualStrings(FIX ++ "/workspace/modules/acme-web", web.dir);
    try testing.expect(web.manifest.dependencies[0].spec.workspace);
    // The example is a member like any other, and an application ships nothing by design.
    const app = ws.member("acme-app").?;
    try testing.expect(!isLibraryPackage(testing.io, app.manifest));
    try testing.expect(shipsNothing(testing.io, app.manifest) == null);
    // A library member with no `files` ships nothing.
    const empty = ws.member("acme-empty").?;
    try testing.expect(isLibraryPackage(testing.io, empty.manifest));
    const sn = shipsNothing(testing.io, empty.manifest).?;
    try testing.expectEqualStrings(
        \\error: ships nothing: manifest has no "files" — a workspace member that is a library lists every module a consumer may import
        \\ --> tests/fixtures/workspace/modules/acme-empty/botopink.json:2:3
        \\  |
        \\2 |   "name": "acme-empty",
        \\  |   ^^^^^^
        \\
        \\
    , try sn.renderAlloc(a));
    try testing.expect(shipsNothing(testing.io, core.manifest) == null);
}

/// The first two rendered lines: the message and the `--> file:line:col` location.
fn expectHead(out: []const u8, message: []const u8, location: []const u8) !void {
    var it = std.mem.splitScalar(u8, out, '\n');
    const l1 = it.next() orelse return error.TestExpectedHead;
    const l2 = it.next() orelse return error.TestExpectedHead;
    try testing.expectEqualStrings(message, l1);
    try testing.expectEqualStrings(location, std.mem.trimStart(u8, l2, " "));
}

/// Read + expand a fixture workspace expecting a refusal; returns the rendered error.
fn refuseWorkspace(a: std.mem.Allocator, dir: []const u8) ![]const u8 {
    var err: ?Located = null;
    const m = try read(a, testing.io, dir, &err);
    const r = expand(a, testing.io, m, &err);
    try testing.expectError(error.Invalid, r);
    return try err.?.renderAlloc(a);
}

test "expand: a member that is a workspace, a duplicate member name, a missing literal entry" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings(
        \\error: "inner" is a member of tests/fixtures/bad/nested-workspace/botopink.json and cannot itself be a workspace — workspaces do not nest
        \\ --> tests/fixtures/bad/nested-workspace/modules/inner/botopink.json:3:3
        \\  |
        \\3 |   "workspaces": ["sub/*"]
        \\  |   ^^^^^^^^^^^^
        \\
        \\
    , try refuseWorkspace(a, FIX ++ "/bad/nested-workspace"));
    try testing.expectEqualStrings(
        \\error: member name "dup" is declared twice in tests/fixtures/bad/duplicate-member/botopink.json: tests/fixtures/bad/duplicate-member/modules/a/botopink.json and tests/fixtures/bad/duplicate-member/modules/b/botopink.json
        \\ --> tests/fixtures/bad/duplicate-member/modules/b/botopink.json:1:3
        \\  |
        \\1 | { "name": "dup", "files": ["root.bp"] }
        \\  |   ^^^^^^
        \\
        \\
    , try refuseWorkspace(a, FIX ++ "/bad/duplicate-member"));
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/missing-literal"),
        "error: workspaces entry \"modules/ghost\": tests/fixtures/bad/missing-literal/modules/ghost/botopink.json does not exist — a literal entry names a directory holding a botopink.json",
        "--> tests/fixtures/bad/missing-literal/botopink.json:1:31",
    );
    const missing_dir = try refuseWorkspace(a, FIX ++ "/bad/missing-dir");
    try testing.expect(std.mem.indexOf(u8, missing_dir, "error: workspaces entry \"nope/*\": tests/fixtures/bad/missing-dir/nope is not a directory that can be read") != null);
}

test "expand: a member may only restrict the workspace's targets" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    try expectHead(
        try refuseWorkspace(arena_inst.allocator(), FIX ++ "/bad/target-widen"),
        "error: \"erlang\" is not one of the workspace's targets [\"commonJS\"] (tests/fixtures/bad/target-widen/botopink.json) — a member may only restrict the workspace's targets",
        "--> tests/fixtures/bad/target-widen/modules/wide/botopink.json:1:43",
    );
}

test "expand: a path to a sibling member, a path to the workspace, an unknown workspace dependency, a self dependency" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/sibling-path"),
        "error: \"core\": path \"../core\" points at the sibling member \"core\" — use { \"workspace\": true }",
        "--> tests/fixtures/bad/sibling-path/modules/web/botopink.json:2:21",
    );
    const to_ws = try refuseWorkspace(a, FIX ++ "/bad/workspace-path");
    try testing.expect(std.mem.indexOf(u8, to_ws, "error: \"umbrella\": path \"../../\" points at the workspace itself — a workspace is not a package; depend on one of its members with { \"workspace\": true } (members: web)") != null);
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/workspace-dep-missing"),
        "error: \"ghost\": { \"workspace\": true } names no member of tests/fixtures/bad/workspace-dep-missing/botopink.json (members: web)",
        "--> tests/fixtures/bad/workspace-dep-missing/modules/web/botopink.json:2:21",
    );
    const self_dep = try refuseWorkspace(a, FIX ++ "/bad/self-dep");
    try testing.expect(std.mem.indexOf(u8, self_dep, "error: \"web\" cannot depend on itself") != null);
}

test "scanRoots: a root's workspace child contributes its members; a plain package keeps its directory name" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{FIX ++ "/roots/repository"};
    const entries = try scanRoots(a, testing.io, &roots);
    // `plain` (a package dir), the `workspace` umbrella and its four members.
    try testing.expectEqual(@as(usize, 6), entries.len);
    try testing.expect(find(entries, "plain") != null);
    try testing.expect(find(entries, "plain").?.workspace == null);
    const umbrella = find(entries, "workspace").?;
    try testing.expect(umbrella.is_workspace);
    try testing.expect(umbrella.problem == null);
    const web = find(entries, "acme-web").?;
    try testing.expect(web.workspace != null);
    try testing.expectEqualStrings(FIX ++ "/roots/repository/workspace/modules/acme-web", web.dir);
    try testing.expect(find(entries, "acme-app") != null);
    try testing.expect(find(entries, "nomanifest") == null);
}

test "scanRoots: a root that is itself a workspace contributes its members, and a directory reached twice is one entry" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{ FIX ++ "/roots/repository/workspace", FIX ++ "/roots/repository" };
    const entries = try scanRoots(a, testing.io, &roots);
    try testing.expectEqual(@as(usize, 6), entries.len);
    try testing.expect(find(entries, "acme").?.problem == null);
}

test "scanRoots: two members with one name across roots are both a located problem; a broken sibling marks only itself" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{ FIX ++ "/roots/repository", FIX ++ "/roots/other" };
    const entries = try scanRoots(a, testing.io, &roots);
    // `other/` holds a second workspace declaring `acme-web` again, and a
    // package whose manifest still uses the array form.
    var count: usize = 0;
    for (entries) |e| {
        if (std.mem.eql(u8, e.name, "acme-web")) {
            count += 1;
            const text = try e.problem.?.renderAlloc(a);
            try testing.expect(std.mem.indexOf(u8, text, "error: \"acme-web\" is declared by two libraries: tests/fixtures/roots/repository/workspace/modules/acme-web and tests/fixtures/roots/other/second/modules/acme-web") != null);
        }
    }
    try testing.expectEqual(@as(usize, 2), count);
    try testing.expect(find(entries, "acme").?.problem == null);
    const broken = find(entries, "array-deps").?;
    try testing.expect(broken.manifest == null);
    try testing.expect(std.mem.indexOf(u8, broken.problem.?.message, "must be an object, not an array") != null);
    // Two plain packages named `plain`: the first root wins, the second is dropped.
    var plain_count: usize = 0;
    for (entries) |e| if (std.mem.eql(u8, e.name, "plain")) {
        plain_count += 1;
    };
    try testing.expectEqual(@as(usize, 1), plain_count);
    try testing.expectEqualStrings(FIX ++ "/roots/repository/plain", find(entries, "plain").?.dir);
}

test "scanRoots + find: a core member named like its umbrella's directory is the library, the umbrella is not" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{FIX ++ "/roots/named"};
    const entries = try scanRoots(a, testing.io, &roots);
    const core = find(entries, "rakun").?;
    try testing.expect(!core.is_workspace);
    try testing.expect(core.workspace != null);
    try testing.expect(core.problem == null);
    try testing.expectEqualStrings(FIX ++ "/roots/named/rakun/modules/rakun", core.dir);
    // A workspace with no member of its name still answers, as the umbrella.
    try testing.expect(find(entries, "workspace") == null);
    const second_roots = [_][]const u8{FIX ++ "/roots/other"};
    const second = try scanRoots(a, testing.io, &second_roots);
    try testing.expect(find(second, "second").?.is_workspace);
}

test "resolveDependency: workspace, path, git-by-name, a workspace by name, a member by path" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_n];

    const roots = [_][]const u8{FIX ++ "/roots/repository"};
    const entries = try scanRoots(a, io, &roots);

    // `acme-web` depends on `acme` with { "workspace": true }.
    const web_dir = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/repository/workspace/modules/acme-web" });
    var err: ?Located = null;
    const web = try read(a, io, web_dir, &err);
    const core = (try resolveDependency(a, io, web, web_dir, web.dependencies[0], entries, &.{}, &err)).?;
    try testing.expectEqualStrings("acme", core.manifest.name);
    try testing.expect(std.mem.endsWith(u8, core.dir, "/modules/acme"));

    // `plain` depends on `acme-web` by name (git form) and on `local` by path.
    const plain_dir = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/repository/plain" });
    const plain = try read(a, io, plain_dir, &err);
    const by_name = (try resolveDependency(a, io, plain, plain_dir, plain.dependencies[0], entries, &.{}, &err)).?;
    try testing.expectEqualStrings("acme-web", by_name.manifest.name);
    const by_path = (try resolveDependency(a, io, plain, plain_dir, plain.dependencies[1], entries, &.{}, &err)).?;
    try testing.expectEqualStrings("local", by_path.manifest.name);
    try testing.expect(std.mem.endsWith(u8, by_path.dir, "/roots/local"));
    // A name nothing carries is null (the caller words "not found").
    try testing.expect((try resolveDependency(a, io, plain, plain_dir, .{ .name = "absent", .spec = .{ .git = "https://e/a.git" } }, entries, &.{}, &err)) == null);

    // The workspace by name, with its members listed.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "workspace", .spec = .{ .git = "https://e/w.git" } }, entries, &.{}, &err));
    try testing.expectEqualStrings("\"workspace\" is a workspace, not a package — import one of its members: acme, acme-empty, acme-web, acme-app", err.?.message);

    // A member depending on a sibling by path (the workspace rule, at resolution time).
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, web, web_dir, .{ .name = "acme", .spec = .{ .path = "../acme" } }, entries, &.{}, &err));
    try testing.expectEqualStrings("\"acme\": path \"../acme\" points at the sibling member \"acme\" — use { \"workspace\": true }", err.?.message);

    // { "workspace": true } outside any workspace.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "acme", .spec = .{ .workspace = true } }, entries, &.{}, &err));
    try testing.expect(std.mem.startsWith(u8, err.?.message, "\"acme\": { \"workspace\": true } but "));
    try testing.expect(std.mem.indexOf(u8, err.?.message, "is not a member of any workspace") != null);

    // A path that holds no manifest, and a path whose package has another name.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "x", .spec = .{ .path = "../nowhere" } }, entries, &.{}, &err));
    try testing.expect(std.mem.startsWith(u8, err.?.message, "\"x\": path \"../nowhere\" holds no botopink.json"));
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "other", .spec = .{ .path = "../../local" } }, entries, &.{}, &err));
    try testing.expectEqualStrings("\"other\": path \"../../local\" holds a package named \"local\" — the dependency key is the import name and must match", err.?.message);
    // A path to a workspace.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "ws", .spec = .{ .path = "../workspace" } }, entries, &.{}, &err));
    try testing.expectEqualStrings("\"ws\": path \"../workspace\" is a workspace, not a package — depend on one of its members: acme, acme-empty, acme-web, acme-app", err.?.message);
}

test "enclosingWorkspace: a member finds its workspace; a package outside finds none; isWorkspaceDir probes" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_n];
    var err: ?Located = null;
    const member = try std.fs.path.join(a, &.{ cwd, FIX ++ "/workspace/examples/acme-app" });
    const ws = (try enclosingWorkspace(a, io, member, &err)).?;
    try testing.expectEqualStrings("acme", ws.manifest.name);
    const outside = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/local" });
    try testing.expect((try enclosingWorkspace(a, io, outside, &err)) == null);
    try testing.expect(isWorkspaceDir(io, FIX ++ "/workspace"));
    try testing.expect(!isWorkspaceDir(io, FIX ++ "/roots/local"));
    try testing.expect(!isWorkspaceDir(io, FIX ++ "/nowhere"));
}

test "Located.render: the CLI diagnostic shape, width-aware" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const l: Located = .{ .message = "m", .file = "f.json", .source = "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\n{ \"x\": 1 }", .line = 11, .col = 3, .span = 3 };
    try testing.expectEqualStrings(
        \\error: m
        \\  --> f.json:11:3
        \\   |
        \\11 | { "x": 1 }
        \\   |   ^^^
        \\
        \\
    , try l.renderAlloc(arena_inst.allocator()));
}
