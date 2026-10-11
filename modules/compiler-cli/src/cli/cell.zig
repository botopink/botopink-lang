/// `botopink cell new <path>` and `botopink cell check <cell|directory>` —
/// decision 464 over the cell shape of decisions 457 and 462.
///
/// A cell is a directory:
///
///     <cell>/src/<module>.bp                     the program; `main.bp` holds `pub fn main`
///     <cell>/snapshot/output/<module>.snap       the answer on every target
///     <cell>/snapshot/targets/<t>/<module>.snap  target <t>'s departure, where it departs
///     <cell>/targets                             the targets it is narrowed to (when narrowed)
///     <cell>/docs.md                             the reference text — `check` ignores it
///     <cell>/botopink.json                       optional: the cell's own manifest (a path
///                                                dependency, a wasm host); else `MANIFEST`
///
/// `check` builds each cell **in this process** — `build.zig`'s pipeline with
/// `reporter.sink` pointed at a buffer, so a refusal is read off exactly the
/// text `botopink build` prints — and runs the built program with `node`,
/// `erl` or `wasmtime` (`run.programArgv`), its stdout, stderr and exit status
/// captured. It never writes an accepted `.snap`: a mismatch is a
/// `<file>.snap.new` candidate beside it and exit 1, a new cell gets
/// candidates, and a person accepts one by renaming it (decision 67: no update
/// flag). The `.snap` format is `cell_snap.zig`'s.
const std = @import("std");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const build_cmd = @import("./build.zig");
const run_cmd = @import("./run.zig");
const otp = @import("./otp.zig");
const libs = @import("./libs.zig");
const snap = @import("./cell_snap.zig");

const Target = config.Target;
const Snap = snap.Snap;

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = union(enum) {
    new: []const u8,
    check: []const u8,
};

/// Every target a cell runs on unless its `targets` file narrows it.
pub const ALL_TARGETS = [_]Target{ .commonJS, .erlang, .beam, .wasm };

/// The manifest a cell without a `botopink.json` builds under. The package is
/// `language_tests` — the name every cell of `tests/language` is built under
/// (an erlang / BEAM atom starts with it, decision 109, and a host template
/// may spell one).
pub const MANIFEST = "{ \"name\": \"language_tests\", \"version\": \"0.0.1\", \"src\": \"src/\" }\n";

/// Where the scratch projects go, under the directory the command started in:
/// the root every scratch directory of the CLI and the compiler shares, which
/// `zig build clean-tmp` reaps at a 1-day TTL.
const TMP_ROOT = ".botopinkbuild/tmp";

/// A program that runs longer is a failed cell, never a skipped one.
const RUN_TIMEOUT_S = 300;

/// The texts a narrowing stands on (`tests/language/AGENTS.md` § Narrowing a
/// cell): the build of an excluded target refuses the cell on a host binding.
const HOST_BINDING_REFUSALS = [_][]const u8{ "has no `#[@External.<Target>(", "std-unsupported-on-target:" };

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options, env_map: libs.EnvMap) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    return switch (opts) {
        .new => |path| newCell(arena, io, path),
        .check => |path| check(gpa, arena, io, path, env_map),
    };
}

// ── new ───────────────────────────────────────────────────────────────────────

const MAIN_BP =
    \\pub fn main() {
    \\    @print("hello");
    \\}
    \\
;

fn newCell(arena: std.mem.Allocator, io: std.Io, path: []const u8) !u8 {
    const cwd = std.Io.Dir.cwd();
    if (cwd.access(io, path, .{})) |_| {
        reporter.errMsg(try std.fmt.allocPrint(arena, "{s} already exists — a cell is scaffolded into a new directory", .{path}));
        return 1;
    } else |_| {}
    const main_bp = try std.fs.path.join(arena, &.{ path, "src", "main.bp" });
    const docs = try std.fs.path.join(arena, &.{ path, "docs.md" });
    try cwd.createDirPath(io, try std.fs.path.join(arena, &.{ path, "src" }));
    try cwd.writeFile(io, .{ .sub_path = main_bp, .data = MAIN_BP });
    const name = std.fs.path.basename(std.mem.trimEnd(u8, path, "/"));
    try cwd.writeFile(io, .{ .sub_path = docs, .data = try std.fmt.allocPrint(arena, "# {s}\n\nWhat this cell shows.\n", .{name}) });
    reporter.created(main_bp);
    reporter.created(docs);
    reporter.hintMsg(try std.fmt.allocPrint(arena, "write the program, then `botopink cell check {s}` writes its candidate snapshots", .{path}));
    return 0;
}

// ── check ─────────────────────────────────────────────────────────────────────

const Ctx = struct {
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    io: std.Io,
    env_map: libs.EnvMap,
    /// The directory the command started in, absolute; every path printed is
    /// relative to it.
    home: []const u8,
    out: std.ArrayListUnmanaged(u8) = .empty,

    fn rel(self: *Ctx, abs: []const u8) []const u8 {
        if (std.mem.startsWith(u8, abs, self.home) and abs.len > self.home.len and abs[self.home.len] == '/')
            return abs[self.home.len + 1 ..];
        return abs;
    }

    fn say(self: *Ctx, comptime fmt: []const u8, args: anytype) void {
        self.out.print(self.arena, fmt, args) catch {};
    }

    fn flush(self: *Ctx) void {
        reporter.stdout(self.io, self.out.items);
        self.out.clearRetainingCapacity();
    }
};

fn check(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io, path: []const u8, env_map: libs.EnvMap) !u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const home = try arena.dupe(u8, buf[0..try std.process.currentPath(io, &buf)]);
    var ctx: Ctx = .{ .gpa = gpa, .arena = arena, .io = io, .env_map = env_map, .home = home };
    const root = try std.fs.path.resolve(arena, &.{ home, path });

    var dir = std.Io.Dir.cwd().openDir(io, root, .{}) catch {
        reporter.errMsg(try std.fmt.allocPrint(arena, "{s} is not a directory", .{path}));
        return 1;
    };
    dir.close(io);
    var cells: std.ArrayListUnmanaged([]const u8) = .empty;
    try discover(arena, io, root, &cells);
    if (cells.items.len == 0) {
        reporter.errMsg(try std.fmt.allocPrint(arena, "no cell under {s} — a cell is a directory holding src/main.bp", .{path}));
        return 1;
    }

    var passed: usize = 0;
    for (cells.items) |cell| {
        const ok = checkCell(&ctx, cell) catch |err| blk: {
            ctx.say("FAIL {s}\n  {s}\n", .{ ctx.rel(cell), @errorName(err) });
            break :blk false;
        };
        if (ok) {
            passed += 1;
            ctx.say("ok   {s}\n", .{ctx.rel(cell)});
        }
        ctx.flush();
    }
    const failed = cells.items.len - passed;
    ctx.say("cells: {d} checked — {d} passed, {d} failed\n", .{ cells.items.len, passed, failed });
    ctx.flush();
    return if (failed == 0) 0 else 1;
}

/// `root` itself when it is a cell (it holds `src/`), else every cell under
/// it, sorted — never inside a cell, a hidden directory or `node_modules`.
fn discover(arena: std.mem.Allocator, io: std.Io, root: []const u8, out: *std.ArrayListUnmanaged([]const u8)) !void {
    if (isDir(io, try std.fs.path.join(arena, &.{ root, "src" }))) {
        try out.append(arena, root);
        return;
    }
    const names = try childNames(arena, io, root, .dirs);
    for (names) |name| {
        if (name[0] == '.' or std.mem.eql(u8, name, "node_modules")) continue;
        try discover(arena, io, try std.fs.path.join(arena, &.{ root, name }), out);
    }
}

fn isDir(io: std.Io, path: []const u8) bool {
    var d = std.Io.Dir.cwd().openDir(io, path, .{}) catch return false;
    d.close(io);
    return true;
}

fn exists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

/// The names in `dir` (directories, files or both), sorted.
fn childNames(arena: std.mem.Allocator, io: std.Io, dir_path: []const u8, which: enum { dirs, files, all }) ![]const []const u8 {
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    var d = std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true }) catch return names.items;
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |e| {
        const is_dir = e.kind == .directory;
        const keep = switch (which) {
            .dirs => is_dir,
            .files => !is_dir,
            .all => true,
        };
        if (keep) try names.append(arena, try arena.dupe(u8, e.name));
    }
    std.mem.sort([]const u8, names.items, {}, lessThan);
    return names.items;
}

fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.order(u8, a, b) == .lt;
}

// ── one cell ──────────────────────────────────────────────────────────────────

/// One accepted `.snap`: where it is and what it says.
const File = struct {
    path: []const u8,
    text: []const u8,
    snap: Snap,
};

const Files = std.StringArrayHashMapUnmanaged(File);

const Accepted = struct {
    output: Files = .empty,
    targets: [ALL_TARGETS.len]Files = @splat(.empty),
    count: usize = 0,
};

/// What one target answered: each module with a non-empty answer, by its
/// snapshot name, and the program's stderr (ANSI stripped) when it ran.
const Answer = struct {
    modules: std.StringArrayHashMapUnmanaged(Snap) = .empty,
    stderr: []const u8 = "",
};

/// A target that gave no answer: the tool failed, not the language.
const ToolError = struct {
    message: []const u8,
    detail: []const u8 = "",
};

const Observed = union(enum) {
    answer: Answer,
    tool_error: ToolError,
};

fn checkCell(ctx: *Ctx, cell: []const u8) !bool {
    const a = ctx.arena;
    const io = ctx.io;
    const rel = ctx.rel(cell);

    if (!exists(io, try std.fs.path.join(a, &.{ cell, "src", "main.bp" }))) {
        ctx.say("FAIL {s}\n  a cell holds src/main.bp — its entry, `pub fn main`\n", .{rel});
        return false;
    }
    var why: []const u8 = "";
    const declared = readTargets(a, io, cell, &why) catch |err| switch (err) {
        error.Malformed => {
            ctx.say("FAIL {s}\n  {s}/targets: {s}\n", .{ rel, rel, why });
            return false;
        },
        else => return err,
    };
    const snapshot_dir = try std.fs.path.join(a, &.{ cell, "snapshot" });
    // The candidates are this run's output: last run's go first.
    try removeCandidates(a, io, snapshot_dir);
    const accepted = readAccepted(ctx, cell, declared, &why) catch |err| switch (err) {
        error.Malformed => {
            ctx.say("FAIL {s}\n  {s}\n", .{ rel, why });
            return false;
        },
        else => return err,
    };

    // Build and run in a scratch copy of the cell, one per cell.
    var observed: [ALL_TARGETS.len]?Answer = @splat(null);
    var audits: std.ArrayListUnmanaged([]const u8) = .empty;
    var tool_errors: std.ArrayListUnmanaged([]const u8) = .empty;
    {
        var scratch = try Scratch.open(ctx, cell);
        defer scratch.close(ctx);
        for (ALL_TARGETS, 0..) |t, i| {
            if (contains(declared, t)) {
                switch (try scratch.observe(ctx, t)) {
                    .answer => |ans| observed[i] = ans,
                    .tool_error => |e| try tool_errors.append(a, try std.fmt.allocPrint(a, "{s}: {s}{s}", .{ t.toString(), e.message, try indentDetail(a, e.detail) })),
                }
            } else if (declared.len < ALL_TARGETS.len) {
                if (try scratch.audit(ctx, t)) |problem| try audits.append(a, try std.fmt.allocPrint(a, "{s}: {s}", .{ t.toString(), problem }));
            }
        }
    }
    if (tool_errors.items.len > 0 or audits.items.len > 0) {
        ctx.say("FAIL {s}\n", .{rel});
        for (tool_errors.items) |e| ctx.say("  {s}\n", .{e});
        for (audits.items) |e| ctx.say("  {s}\n", .{e});
        return false;
    }
    return compare(ctx, cell, declared, accepted, &observed);
}

fn contains(targets: []const Target, t: Target) bool {
    for (targets) |x| if (x == t) return true;
    return false;
}

fn indentDetail(a: std.mem.Allocator, detail: []const u8) ![]const u8 {
    const text = std.mem.trimEnd(u8, detail, "\n");
    if (text.len == 0) return "";
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |l| try out.print(a, "\n      {s}", .{l});
    return out.items;
}

/// The cell's `targets` file — target names separated by blanks — or every
/// target when there is none. A narrowing that names an unknown target, one
/// twice, none, or all of them is malformed.
fn readTargets(a: std.mem.Allocator, io: std.Io, cell: []const u8, why: *[]const u8) ![]const Target {
    const path = try std.fs.path.join(a, &.{ cell, "targets" });
    const text = std.Io.Dir.cwd().readFileAlloc(io, path, a, .limited(4096)) catch |err| switch (err) {
        error.FileNotFound => return &ALL_TARGETS,
        else => return err,
    };
    var list: std.ArrayListUnmanaged(Target) = .empty;
    var it = std.mem.tokenizeAny(u8, text, " \t\r\n");
    while (it.next()) |name| {
        const t = Target.fromString(name) orelse {
            why.* = try std.fmt.allocPrint(a, "unknown target `{s}` (commonJS, erlang, beam, wasm)", .{name});
            return error.Malformed;
        };
        if (contains(list.items, t)) {
            why.* = try std.fmt.allocPrint(a, "`{s}` is named twice", .{name});
            return error.Malformed;
        }
        try list.append(a, t);
    }
    if (list.items.len == 0) {
        why.* = "names no target";
        return error.Malformed;
    }
    if (list.items.len == ALL_TARGETS.len) {
        why.* = "names every target, so it narrows nothing — delete it";
        return error.Malformed;
    }
    // In `ALL_TARGETS` order, whatever order the file wrote.
    var ordered: std.ArrayListUnmanaged(Target) = .empty;
    for (ALL_TARGETS) |t| if (contains(list.items, t)) try ordered.append(a, t);
    return ordered.items;
}

/// Delete every `*.snap.new` under `dir`.
fn removeCandidates(a: std.mem.Allocator, io: std.Io, dir: []const u8) !void {
    for (try childNames(a, io, dir, .all)) |name| {
        const p = try std.fs.path.join(a, &.{ dir, name });
        if (isDir(io, p)) {
            try removeCandidates(a, io, p);
        } else if (std.mem.endsWith(u8, name, ".snap" ++ snap.NEW_SUFFIX)) {
            std.Io.Dir.cwd().deleteFile(io, p) catch {};
        }
    }
}

/// Read `snapshot/`: `output/**.snap` and `targets/<t>/**.snap`, each parsed.
/// Anything else there, a departure for a target the cell does not run, or a
/// malformed `.snap` refuses the cell (`why`).
fn readAccepted(ctx: *Ctx, cell: []const u8, declared: []const Target, why: *[]const u8) !Accepted {
    const a = ctx.arena;
    const io = ctx.io;
    var acc: Accepted = .{};
    const dir = try std.fs.path.join(a, &.{ cell, "snapshot" });
    for (try childNames(a, io, dir, .all)) |name| {
        const p = try std.fs.path.join(a, &.{ dir, name });
        if (std.mem.eql(u8, name, "output") and isDir(io, p)) {
            try readSnaps(ctx, p, "", &acc.output, &acc.count, why);
        } else if (std.mem.eql(u8, name, "targets") and isDir(io, p)) {
            for (try childNames(a, io, p, .all)) |tname| {
                const tp = try std.fs.path.join(a, &.{ p, tname });
                const t = Target.fromString(tname) orelse {
                    why.* = try std.fmt.allocPrint(a, "{s}: not a target (commonJS, erlang, beam, wasm)", .{ctx.rel(tp)});
                    return error.Malformed;
                };
                if (!contains(declared, t) or !isDir(io, tp)) {
                    why.* = try std.fmt.allocPrint(a, "{s}: a departure for a target the cell does not run", .{ctx.rel(tp)});
                    return error.Malformed;
                }
                try readSnaps(ctx, tp, "", &acc.targets[@intFromEnum(t)], &acc.count, why);
            }
        } else {
            why.* = try std.fmt.allocPrint(a, "{s}: snapshot/ holds output/ and targets/<target>/ only", .{ctx.rel(p)});
            return error.Malformed;
        }
    }
    return acc;
}

fn readSnaps(ctx: *Ctx, dir: []const u8, prefix: []const u8, into: *Files, count: *usize, why: *[]const u8) !void {
    const a = ctx.arena;
    const io = ctx.io;
    for (try childNames(a, io, dir, .all)) |name| {
        const p = try std.fs.path.join(a, &.{ dir, name });
        const key = if (prefix.len == 0) name else try std.fmt.allocPrint(a, "{s}/{s}", .{ prefix, name });
        if (isDir(io, p)) {
            try readSnaps(ctx, p, key, into, count, why);
            continue;
        }
        if (!std.mem.endsWith(u8, name, ".snap")) {
            why.* = try std.fmt.allocPrint(a, "{s}: not a .snap", .{ctx.rel(p)});
            return error.Malformed;
        }
        const text = try std.Io.Dir.cwd().readFileAlloc(io, p, a, .limited(16 * 1024 * 1024));
        var bad: snap.Malformed = .{};
        const s = snap.parse(a, text, &bad) catch |err| switch (err) {
            error.Malformed => {
                why.* = try std.fmt.allocPrint(a, "{s}:{d}: {s}", .{ ctx.rel(p), bad.line, bad.reason });
                return error.Malformed;
            },
            else => |e| return e,
        };
        try into.put(a, key[0 .. key.len - ".snap".len], .{ .path = p, .text = text, .snap = s });
        count.* += 1;
    }
}

// ── the scratch project ───────────────────────────────────────────────────────

/// A copy of the cell — everything but `snapshot/`, `docs.md`, `targets` and
/// hidden entries — under `<home>/.botopinkbuild/tmp/cell-<64 random bits>/`,
/// with `MANIFEST` when the cell has no manifest of its own. The process works
/// in it while it is open (every CLI path is relative to the current
/// directory) and returns home when it closes.
const Scratch = struct {
    dir: []const u8,
    manifest: []const u8,

    fn open(ctx: *Ctx, cell: []const u8) !Scratch {
        const a = ctx.arena;
        var rand: [8]u8 = undefined;
        ctx.io.random(&rand);
        const dir = try std.fmt.allocPrint(a, "{s}/{s}/cell-{x:0>16}", .{ ctx.home, TMP_ROOT, std.mem.readInt(u64, &rand, .little) });
        try std.Io.Dir.cwd().createDirPath(ctx.io, dir);
        try copyTree(a, ctx.io, cell, dir, true);
        const manifest_path = try std.fs.path.join(a, &.{ dir, "botopink.json" });
        const manifest = std.Io.Dir.cwd().readFileAlloc(ctx.io, manifest_path, a, .limited(64 * 1024)) catch |err| switch (err) {
            error.FileNotFound => blk: {
                try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = manifest_path, .data = MANIFEST });
                break :blk MANIFEST;
            },
            else => return err,
        };
        try std.process.setCurrentPath(ctx.io, dir);
        return .{ .dir = dir, .manifest = manifest };
    }

    fn close(self: *Scratch, ctx: *Ctx) void {
        std.process.setCurrentPath(ctx.io, ctx.home) catch {};
        std.Io.Dir.cwd().deleteTree(ctx.io, self.dir) catch {};
    }

    /// Build and run the cell on `t`. On wasm the program runs on both hosts
    /// of decision 334 — the `wasi` build under `wasmtime` and the `browser`
    /// build under `node` — unless the cell's manifest names its host, and
    /// two hosts that answer differently are a failed cell.
    fn observe(self: *Scratch, ctx: *Ctx, t: Target) !Observed {
        if ((t == .erlang or t == .beam) and !try otp.check(ctx.arena, ctx.io))
            return .{ .tool_error = .{ .message = "`erl` on PATH does not run the OTP release the compiler emits for" } };
        const out_dir = try std.fmt.allocPrint(ctx.arena, "out-{s}", .{t.toString()});
        const first = try buildAndRun(ctx, t, out_dir);
        if (t != .wasm or std.mem.indexOf(u8, self.manifest, "\"wasm\"") != null) return first;
        if (first == .tool_error) return first;

        const brace = std.mem.indexOfScalar(u8, self.manifest, '{') orelse return first;
        const browser_manifest = try std.fmt.allocPrint(ctx.arena, "{s} \"wasm\": {{ \"host\": \"browser\" }},{s}", .{ self.manifest[0 .. brace + 1], self.manifest[brace + 1 ..] });
        try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = "botopink.json", .data = browser_manifest });
        const second = try buildAndRun(ctx, t, "out-wasm-browser");
        try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = "botopink.json", .data = self.manifest });
        switch (second) {
            .tool_error => |e| return .{ .tool_error = .{ .message = try std.fmt.allocPrint(ctx.arena, "the browser host: {s}", .{e.message}), .detail = e.detail } },
            .answer => |ans| if (!try sameAnswer(ctx.arena, first.answer, ans)) {
                return .{ .tool_error = .{
                    .message = "the wasm hosts disagree",
                    .detail = try std.fmt.allocPrint(ctx.arena, "wasi (wasmtime):\n{s}browser (node):\n{s}", .{ try describe(ctx.arena, first.answer), try describe(ctx.arena, ans) }),
                } };
            },
        }
        return first;
    }

    /// A target the `targets` file leaves out: its build must refuse the cell
    /// on a host binding — the one reason a program structurally has no row
    /// on a target. Null when it does; else what is wrong.
    fn audit(self: *Scratch, ctx: *Ctx, t: Target) !?[]const u8 {
        _ = self;
        const a = ctx.arena;
        if ((t == .erlang or t == .beam) and !try otp.check(a, ctx.io))
            return "`erl` on PATH does not run the OTP release the compiler emits for";
        const out_dir = try std.fmt.allocPrint(a, "out-{s}", .{t.toString()});
        var captured: std.Io.Writer.Allocating = .init(a);
        const code = try buildCaptured(ctx, t, out_dir, &captured.writer);
        if (code == 0) return try std.fmt.allocPrint(a, "excluded by `targets`, but `botopink build --target {s}` accepts the cell — a narrowing stands on a host-binding refusal: let it run on {s}", .{ t.toString(), t.toString() });
        const text = try stripAnsi(a, captured.written());
        for (HOST_BINDING_REFUSALS) |phrase| if (std.mem.indexOf(u8, text, phrase) != null) return null;
        const beam_memory = try std.fmt.allocPrint(a, "`#[@BeamMemory]` has no meaning on the {s} backend", .{t.toString()});
        if (std.mem.indexOf(u8, text, beam_memory) != null) return null;
        const first = firstErrorLine(text) orelse "no error line";
        return try std.fmt.allocPrint(a, "excluded by `targets`, and {s} refuses it for another reason than a host binding ({s}) — let it run there, its refusal answered in snapshot/targets/{s}/", .{ t.toString(), first, t.toString() });
    }
};

/// Copy `from` into `to`. At the top level `snapshot/`, `docs.md` and
/// `targets` stay behind; hidden entries stay behind at every level.
fn copyTree(a: std.mem.Allocator, io: std.Io, from: []const u8, to: []const u8, top: bool) !void {
    const cwd = std.Io.Dir.cwd();
    for (try childNames(a, io, from, .all)) |name| {
        if (name[0] == '.') continue;
        if (top and (std.mem.eql(u8, name, "snapshot") or std.mem.eql(u8, name, "docs.md") or std.mem.eql(u8, name, "targets"))) continue;
        const src = try std.fs.path.join(a, &.{ from, name });
        const dst = try std.fs.path.join(a, &.{ to, name });
        if (isDir(io, src)) {
            try cwd.createDirPath(io, dst);
            try copyTree(a, io, src, dst, false);
        } else {
            const data = try cwd.readFileAlloc(io, src, a, .limited(64 * 1024 * 1024));
            try cwd.writeFile(io, .{ .sub_path = dst, .data = data });
        }
    }
}

/// `botopink build --target t --out out_dir` in this process, everything it
/// would print to stderr written to `w` instead.
fn buildCaptured(ctx: *Ctx, t: Target, out_dir: []const u8, w: *std.Io.Writer) !u8 {
    reporter.sink = w;
    defer reporter.sink = null;
    return build_cmd.run(ctx.gpa, ctx.io, .{ .target = t, .out_dir = out_dir }, ctx.env_map);
}

/// Build the scratch project on `t` and run the program: its answer is the
/// refusals the build printed, or what the program printed and whether it
/// aborted.
fn buildAndRun(ctx: *Ctx, t: Target, out_dir: []const u8) !Observed {
    const a = ctx.arena;
    var captured: std.Io.Writer.Allocating = .init(a);
    var argv: ?[]const []const u8 = null;
    const code = try buildCaptured(ctx, t, out_dir, &captured.writer);
    if (code == 0) {
        reporter.sink = &captured.writer;
        defer reporter.sink = null;
        const proj = config.load(a, ctx.io) catch return .{ .tool_error = .{ .message = "botopink.json does not load", .detail = captured.written() } };
        argv = try run_cmd.programArgv(a, ctx.io, proj, t, out_dir, "main");
    }
    if (argv == null) {
        const text = try stripAnsi(a, captured.written());
        const modules = try refusalsOf(a, text);
        if (modules.count() == 0) return .{ .tool_error = .{ .message = "the build failed and named no refusal", .detail = text } };
        return .{ .answer = .{ .modules = modules } };
    }

    const res = std.process.run(a, ctx.io, .{
        .argv = argv.?,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
        .timeout = .{ .duration = .{ .raw = .{ .nanoseconds = RUN_TIMEOUT_S * std.time.ns_per_s }, .clock = .real } },
    }) catch |err| return .{ .tool_error = .{ .message = switch (err) {
        error.Timeout => try std.fmt.allocPrint(a, "the program ran past {d} s", .{RUN_TIMEOUT_S}),
        else => try std.fmt.allocPrint(a, "`{s}` could not be run: {s}", .{ argv.?[0], @errorName(err) }),
    } } };
    const abort = switch (res.term) {
        .exited => |c| c != 0,
        else => true,
    };
    var ans: Answer = .{ .stderr = try stripAnsi(a, res.stderr) };
    try ans.modules.put(a, "main", .{ .stdout = res.stdout, .abort = abort });
    return .{ .answer = ans };
}

fn sameAnswer(a: std.mem.Allocator, x: Answer, y: Answer) !bool {
    return std.mem.eql(u8, try describe(a, x), try describe(a, y));
}

/// Every module's `.snap` text of an answer, one after the other.
fn describe(a: std.mem.Allocator, ans: Answer) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (ans.modules.keys(), ans.modules.values()) |k, v| {
        try out.print(a, "  {s}.snap:\n", .{k});
        var lines = std.mem.splitScalar(u8, std.mem.trimEnd(u8, try snap.render(a, v), "\n"), '\n');
        while (lines.next()) |l| try out.print(a, "    {s}\n", .{l});
    }
    return out.items;
}

/// `text` without its ANSI colour sequences (`ESC [ … m`).
pub fn stripAnsi(a: std.mem.Allocator, text: []const u8) ![]const u8 {
    if (std.mem.indexOfScalar(u8, text, 0x1b) == null) return text;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == 0x1b and i + 1 < text.len and text[i + 1] == '[') {
            var j = i + 2;
            while (j < text.len and (std.ascii.isDigit(text[j]) or text[j] == ';')) j += 1;
            if (j < text.len and text[j] == 'm') {
                i = j + 1;
                continue;
            }
        }
        try out.append(a, text[i]);
        i += 1;
    }
    return out.items;
}

fn isErrorLine(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "error:") or std.mem.startsWith(u8, line, "error[");
}

/// `error: N module(s) failed to compile: …` — the build's summary, which
/// names modules, not a refusal.
fn isSummary(line: []const u8) bool {
    return std.mem.indexOf(u8, line, " module(s) failed to compile: ") != null;
}

fn firstErrorLine(text: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (isErrorLine(line) and !isSummary(line)) return line;
    }
    return null;
}

/// The refusals in what a build printed, by module: each `error…` line (the
/// summary aside) and the first `--> <file>:<line>:<col>` under it, filed
/// under the module that file is (`src/shapes/circle.bp` → `shapes/circle`);
/// an unlocated refusal is `main`'s.
pub fn refusalsOf(a: std.mem.Allocator, text: []const u8) !std.StringArrayHashMapUnmanaged(Snap) {
    var flat: std.ArrayListUnmanaged(snap.Refusal) = .empty;
    var open = false;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (isErrorLine(line)) {
            open = !isSummary(line);
            if (open) try flat.append(a, .{ .message = line });
        } else if (std.mem.startsWith(u8, line, "warning")) {
            open = false;
        } else if (open and flat.items[flat.items.len - 1].at == null) {
            const t = std.mem.trimStart(u8, line, " ");
            if (std.mem.startsWith(u8, t, "--> ")) flat.items[flat.items.len - 1].at = t["--> ".len..];
        }
    }
    var grouped: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(snap.Refusal)) = .empty;
    for (flat.items) |r| {
        const module = if (r.at) |at| moduleOf(at) else "main";
        const gop = try grouped.getOrPut(a, module);
        if (!gop.found_existing) gop.value_ptr.* = .empty;
        try gop.value_ptr.append(a, r);
    }
    var out: std.StringArrayHashMapUnmanaged(Snap) = .empty;
    for (grouped.keys(), grouped.values()) |k, v| try out.put(a, k, .{ .refusals = v.items });
    return out;
}

/// `src/shapes/circle.bp:3:7` → `shapes/circle`.
fn moduleOf(at: []const u8) []const u8 {
    var path = at;
    inline for (0..2) |_| {
        if (std.mem.lastIndexOfScalar(u8, path, ':')) |c| {
            const tail = path[c + 1 ..];
            if (tail.len > 0 and for (tail) |ch| {
                if (!std.ascii.isDigit(ch)) break false;
            } else true) path = path[0..c];
        }
    }
    if (std.mem.startsWith(u8, path, "src/")) path = path["src/".len..];
    if (std.mem.endsWith(u8, path, ".bp")) path = path[0 .. path.len - ".bp".len];
    return path;
}

// ── compare and write candidates ──────────────────────────────────────────────

/// Compare every module's answer on every declared target with the accepted
/// `.snap` it reads (`targets/<t>/` where the target departs, else `output/`,
/// else empty), and write a candidate where they differ — or, for a new cell
/// (no `.snap` at all), for every module that answers and for `main`.
fn compare(ctx: *Ctx, cell: []const u8, declared: []const Target, acc: Accepted, observed: *const [ALL_TARGETS.len]?Answer) !bool {
    const a = ctx.arena;
    const new_cell = acc.count == 0;
    var report: std.ArrayListUnmanaged(u8) = .empty;

    // Every module any target answered or any snapshot names.
    var names: std.StringArrayHashMapUnmanaged(void) = .empty;
    if (new_cell) try names.put(a, "main", {});
    for (declared) |t| {
        for (observed[@intFromEnum(t)].?.modules.keys()) |k| try names.put(a, k, {});
        for (acc.targets[@intFromEnum(t)].keys()) |k| try names.put(a, k, {});
    }
    for (acc.output.keys()) |k| try names.put(a, k, {});
    const sorted = try a.dupe([]const u8, names.keys());
    std.mem.sort([]const u8, sorted, {}, lessThan);

    const n = declared.len;
    for (sorted) |m| {
        const ok = try a.alloc(bool, n);
        const cand = try a.alloc([]const u8, n);
        const eff = try a.alloc(?File, n);
        const own = try a.alloc(bool, n);
        var all_ok = true;
        for (declared, 0..) |t, i| {
            const ti = @intFromEnum(t);
            const ans = observed[ti].?;
            const target_file = acc.targets[ti].get(m);
            own[i] = target_file != null;
            eff[i] = target_file orelse acc.output.get(m);
            const got = ans.modules.get(m) orelse Snap{};
            const want = if (eff[i]) |f| f.snap else Snap{};
            ok[i] = snap.matches(want, got, ans.stderr);
            cand[i] = try snap.render(a, try snap.candidate(a, if (eff[i]) |f| f.snap else null, got, ans.stderr));
            if (!ok[i]) all_ok = false;
        }
        if (all_ok and !new_cell) continue;

        // A target with a departure of its own that no longer holds: its
        // candidate goes beside that departure.
        for (declared, 0..) |t, i| {
            if (own[i] and !ok[i]) try writeCandidate(ctx, &report, cell, t, m, cand[i], eff[i].?.text, "does not answer its accepted departure");
        }

        // The targets that read `output/`.
        var on_output: std.ArrayListUnmanaged(usize) = .empty;
        var any_failed = false;
        var any_held = false;
        for (0..n) |i| {
            if (own[i]) continue;
            try on_output.append(a, i);
            if (ok[i]) any_held = true else any_failed = true;
        }
        if (!new_cell and !any_failed) continue;
        const out_file = acc.output.get(m);
        const output_text = if (out_file) |f| f.text else "";

        if (!new_cell and out_file != null and any_held) {
            // `output/` holds on some targets: the others depart from it.
            for (on_output.items) |i| {
                if (!ok[i]) try writeCandidate(ctx, &report, cell, declared[i], m, cand[i], output_text, "departs from the accepted output — a departure to review");
            }
            continue;
        }

        // No target holds `output/` (or there is none yet): the answer is the
        // one the targets agree on, or the majority's; else a person chooses.
        var groups: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(usize)) = .empty;
        for (on_output.items) |i| {
            const gop = try groups.getOrPut(a, cand[i]);
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            try gop.value_ptr.append(a, i);
        }
        if (groups.count() == 0) continue;
        var best: usize = 0;
        for (groups.values(), 0..) |g, gi| {
            if (g.items.len > groups.values()[best].items.len) best = gi;
        }
        const majority = groups.values()[best].items;
        const majority_text = groups.keys()[best];
        if (groups.count() == 1 or majority.len * 2 > on_output.items.len) {
            const empty = std.mem.eql(u8, majority_text, snap.HEADER ++ "\n");
            if (!empty or out_file != null or std.mem.eql(u8, m, "main")) {
                const why = if (groups.count() == 1)
                    (if (out_file == null) "the answer every target gives" else "every target answers otherwise")
                else
                    "the majority's answer";
                const on = try targetList(a, declared, if (groups.count() == 1) on_output.items else majority);
                try writeOutputCandidate(ctx, &report, cell, m, on, majority_text, output_text, why);
            }
            for (groups.values(), 0..) |g, gi| {
                if (gi == best) continue;
                for (g.items) |i| try writeCandidate(ctx, &report, cell, declared[i], m, cand[i], majority_text, "departs from the majority — a departure to review");
            }
        } else {
            for (on_output.items) |i| try writeCandidate(ctx, &report, cell, declared[i], m, cand[i], output_text, "no majority — a person chooses which answer is the language's (snapshot/output/) and which targets depart");
        }
    }

    if (report.items.len == 0) return true;
    ctx.say("FAIL {s}{s}\n{s}", .{ ctx.rel(cell), if (new_cell) " — a new cell: no accepted snapshot yet, candidates written" else "", report.items });
    return false;
}

fn targetList(a: std.mem.Allocator, declared: []const Target, idx: []const usize) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (idx, 0..) |i, k| {
        if (k > 0) try out.append(a, ' ');
        try out.appendSlice(a, declared[i].toString());
    }
    return out.items;
}

fn writeOutputCandidate(ctx: *Ctx, report: *std.ArrayListUnmanaged(u8), cell: []const u8, module: []const u8, on: []const u8, text: []const u8, before: []const u8, why: []const u8) !void {
    const path = try std.fmt.allocPrint(ctx.arena, "{s}/snapshot/output/{s}.snap" ++ snap.NEW_SUFFIX, .{ cell, module });
    try writeFileMkdir(ctx, path, text);
    try reportCandidate(ctx, report, on, module, path, before, text, why);
}

fn writeCandidate(ctx: *Ctx, report: *std.ArrayListUnmanaged(u8), cell: []const u8, t: Target, module: []const u8, text: []const u8, before: []const u8, why: []const u8) !void {
    const path = try std.fmt.allocPrint(ctx.arena, "{s}/snapshot/targets/{s}/{s}.snap" ++ snap.NEW_SUFFIX, .{ cell, t.toString(), module });
    try writeFileMkdir(ctx, path, text);
    try reportCandidate(ctx, report, t.toString(), module, path, before, text, why);
}

fn writeFileMkdir(ctx: *Ctx, path: []const u8, text: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(ctx.io, d);
    try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = path, .data = text });
}

fn reportCandidate(ctx: *Ctx, report: *std.ArrayListUnmanaged(u8), on: []const u8, module: []const u8, path: []const u8, before: []const u8, after: []const u8, why: []const u8) !void {
    const a = ctx.arena;
    try report.print(a, "  {s} on {s}: {s}\n    candidate {s}\n", .{ module, on, why, ctx.rel(path) });
    const d = try snap.diff(a, before, after);
    var lines = std.mem.splitScalar(u8, std.mem.trimEnd(u8, d, "\n"), '\n');
    while (lines.next()) |l| try report.print(a, "      {s}\n", .{l});
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "refusalsOf files each located refusal under its module and skips the summary" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text =
        \\  Compiling 2 module(s)...
        \\warning: `out` is born with no element type
        \\ --> src/main.bp:2:9
        \\
        \\error[namespace-type-self]: a namespace type has no value
        \\ --> src/main.bp:7:15
        \\  |
        \\7 |     fn double(self: Self) -> i32 { return 2; }
        \\  |               ^^^^
        \\
        \\error: `f` has no `#[@External.<Target>(…)]` for the wasm backend
        \\  --> src/shapes/circle.bp:21:12
        \\
        \\error: dependency 'x' was not found under any library root
        \\error: 2 module(s) failed to compile: main, shapes/circle
        \\
    ;
    const got = try refusalsOf(a, text);
    try testing.expectEqual(@as(usize, 2), got.count());
    const main = got.get("main").?;
    try testing.expectEqual(@as(usize, 2), main.refusals.len);
    try testing.expectEqualStrings("error[namespace-type-self]: a namespace type has no value", main.refusals[0].message);
    try testing.expectEqualStrings("src/main.bp:7:15", main.refusals[0].at.?);
    try testing.expectEqualStrings("error: dependency 'x' was not found under any library root", main.refusals[1].message);
    try testing.expect(main.refusals[1].at == null);
    const circle = got.get("shapes/circle").?;
    try testing.expectEqualStrings("src/shapes/circle.bp:21:12", circle.refusals[0].at.?);
}

test "moduleOf reads the module off a location" {
    try testing.expectEqualStrings("main", moduleOf("src/main.bp:7:15"));
    try testing.expectEqualStrings("shapes/circle", moduleOf("src/shapes/circle.bp:3:1"));
    try testing.expectEqualStrings("lib/util", moduleOf("lib/util.bp:1:1"));
}

test "stripAnsi drops colour sequences only" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    try testing.expectEqualStrings("error: x [1]", try stripAnsi(arena.allocator(), "\x1b[1m\x1b[31merror\x1b[0m: x [1]"));
}
