/// `botopink cell new <path>` and `botopink cell check <cell|directory>` —
/// decision 464 over the cell shape of decisions 457 and 462.
///
/// A cell is a directory:
///
///     <cell>/src/<module>.bp                     the program; `main.bp` holds `pub fn main`
///     <cell>/snapshot/output/<module>.snap       the answer on every target
///     <cell>/snapshot/targets/<t>/<module>.snap  target <t>'s departure, where it departs
///     <cell>/botopink.json                       the cell's own manifest (decision 475): its
///                                                package name, `"targets"` when narrowed,
///                                                a path dependency, a named wasm host
///     <cell>/docs.md                             the reference text — `check` ignores it
///
/// A module may hold several cells (decision 765): `<module>/cases/<case>/` is
/// a full cell as above, and the module itself holds a `docs.md` beside
/// `cases/` and no `src/`. `cell new <module>/cases/<case>` writes the case and
/// appends a link to it in the module's `docs.md`; `check` over the module (or
/// over its parent) finds every case, and refuses a module holding both `cases/`
/// and `src/`, or a `cases/<x>` that is no cell.
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
const manifest = @import("manifest");
const code_cache = @import("./code_cache.zig");

const Target = config.Target;
const Snap = snap.Snap;

// ── Options ───────────────────────────────────────────────────────────────────

pub const CheckOpts = struct {
    /// Cells or directories of cells, checked in the order given (each
    /// directory's cells sorted); a cell reached twice is checked once.
    paths: []const []const u8,
    /// Cells checked at once; null is `defaultJobs`.
    jobs: ?usize = null,
    /// `--cold`: the code cache is not read, and what ran is written
    /// (decision 509 (5)); handed on to every cell's process.
    cold: bool = false,
};

pub const Options = union(enum) {
    new: []const u8,
    check: CheckOpts,
};

/// Every target a cell runs on unless its manifest's `"targets"` narrows it.
pub const ALL_TARGETS = [_]Target{ .commonJS, .erlang, .beam, .wasm };

/// Where the scratch projects go, under the directory the command started in:
/// the root every scratch directory of the CLI and the compiler shares, which
/// `zig build clean-tmp` reaps at a 1-day TTL.
const TMP_ROOT = ".botopinkbuild/tmp";

/// A program that runs longer is a failed cell, never a skipped one.
const RUN_TIMEOUT_S = 300;

/// The texts a narrowing stands on (`conformance/AGENTS.md` § Narrowing a
/// cell): the build of an excluded target refuses the cell on a host binding,
/// or on a dependency that declares no target its dependant holds (decision
/// 676, `dependency-target-missing`) — a refusal no build of the graph passes.
const HOST_BINDING_REFUSALS = [_][]const u8{ "has no implementation for the ", "std-unsupported-on-target:", "error[dependency-target-missing]:" };

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options, env_map: libs.EnvMap) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    return switch (opts) {
        .new => |path| newCell(arena, io, path),
        .check => |c| blk: {
            if (c.cold) code_cache.cold = true;
            break :blk check(gpa, arena, io, c, env_map);
        },
    };
}

// ── new ───────────────────────────────────────────────────────────────────────

const MAIN_BP =
    \\import {io.terminal.print} from "std";
    \\
    \\pub fn main() {
    \\    print("hello");
    \\}
    \\
;

/// `<module>/cases/<case>`: the module's directory, or null when `path` is no case path.
fn moduleOfCase(path: []const u8) ?[]const u8 {
    const trimmed = std.mem.trimEnd(u8, path, "/");
    const cases_dir = std.fs.path.dirname(trimmed) orelse return null;
    if (!std.mem.eql(u8, std.fs.path.basename(cases_dir), "cases")) return null;
    const module_dir = std.fs.path.dirname(cases_dir) orelse return null;
    if (std.fs.path.basename(module_dir).len == 0) return null;
    return module_dir;
}

/// The link line a module's `docs.md` gets for the case `case`.
fn caseLink(arena: std.mem.Allocator, case: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "[cases/{s}/src/main.bp](cases/{s}/src/main.bp)\n", .{ case, case });
}

/// `docs` with the link to `case` appended (a `# <module>` page when `docs` is null).
fn withCaseLink(arena: std.mem.Allocator, docs: ?[]const u8, module: []const u8, case: []const u8) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    if (docs) |text| {
        try out.appendSlice(arena, text);
        if (text.len > 0 and text[text.len - 1] != '\n') try out.append(arena, '\n');
    } else {
        try out.appendSlice(arena, try std.fmt.allocPrint(arena, "# {s}\n\n", .{module}));
    }
    try out.appendSlice(arena, try caseLink(arena, case));
    return out.items;
}

/// The member of the workspace enclosing `path` that already has `name`, as the
/// path of its manifest (decision 512 (1): a member's name is unique); null
/// when there is no workspace listing `path`, or no member has the name.
fn nameTakenBy(arena: std.mem.Allocator, io: std.Io, path: []const u8, name: []const u8) !?[]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const home = buf[0..try std.process.currentPath(io, &buf)];
    const abs = try std.fs.path.resolve(arena, &.{ home, path });
    var err: ?manifest.Located = null;
    // The directory is not there yet, so the workspace is found by its globs
    // (`workspaceOf`) and expanded: its members are the ones on disk.
    const wm = (manifest.workspaceOf(arena, io, abs, &err) catch return null) orelse return null;
    const ws = manifest.expand(arena, io, wm, &err) catch return null;
    if (ws.member(name)) |other| return other.manifest.path;
    return null;
}

fn newCell(arena: std.mem.Allocator, io: std.Io, path: []const u8) !u8 {
    const cwd = std.Io.Dir.cwd();
    if (cwd.access(io, path, .{})) |_| {
        reporter.errMsg(try std.fmt.allocPrint(arena, "{s} already exists — a cell is scaffolded into a new directory", .{path}));
        return 1;
    } else |_| {}
    // The cell is a project like any other (decision 475): its manifest names
    // the package after the cell's directory.
    const name = std.fs.path.basename(std.mem.trimEnd(u8, path, "/"));
    if (manifest.nameRefusal(name)) |why| {
        reporter.errMsg(try std.fmt.allocPrint(arena, "`{s}` cannot name the cell's package: {s}", .{ name, why }));
        return 1;
    }
    const module_dir = moduleOfCase(path);
    if (module_dir) |m| {
        if (isDir(io, try std.fs.path.join(arena, &.{ m, "src" }))) {
            reporter.errMsg(try std.fmt.allocPrint(arena, "{s} holds src/ — a module holds cases or is a cell, not both (decision 765)", .{m}));
            return 1;
        }
    }
    if (try nameTakenBy(arena, io, path, name)) |other| {
        reporter.errMsg(try std.fmt.allocPrint(arena, "`{s}` is already the name of a member of the workspace ({s}) — a member's name is unique (decision 512); name the case otherwise", .{ name, other }));
        return 1;
    }
    const main_bp = try std.fs.path.join(arena, &.{ path, "src", "main.bp" });
    const docs = try std.fs.path.join(arena, &.{ path, "docs.md" });
    const manifest_path = try std.fs.path.join(arena, &.{ path, "botopink.json" });
    try cwd.createDirPath(io, try std.fs.path.join(arena, &.{ path, "src" }));
    try cwd.writeFile(io, .{ .sub_path = manifest_path, .data = try std.fmt.allocPrint(arena, "{{ \"name\": \"{s}\", \"version\": \"0.0.1\", \"src\": \"src/\" }}\n", .{name}) });
    try cwd.writeFile(io, .{ .sub_path = main_bp, .data = MAIN_BP });
    try cwd.writeFile(io, .{ .sub_path = docs, .data = try std.fmt.allocPrint(arena, "# {s}\n\nWhat this cell shows.\n", .{name}) });
    reporter.created(manifest_path);
    reporter.created(main_bp);
    reporter.created(docs);
    if (module_dir) |m| {
        const module_docs = try std.fs.path.join(arena, &.{ m, "docs.md" });
        const before: ?[]const u8 = cwd.readFileAlloc(io, module_docs, arena, .limited(16 * 1024 * 1024)) catch null;
        const text = try withCaseLink(arena, before, std.fs.path.basename(m), name);
        try cwd.writeFile(io, .{ .sub_path = module_docs, .data = text });
        if (before == null) reporter.created(module_docs);
    }
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

    /// Every byte reaches stdout: a write that fails is retried (a pipe the
    /// children share can be non-blocking and refuse a write for a moment),
    /// never dropped — a report that loses a line loses a cell.
    fn flush(self: *Ctx) void {
        var rest: []const u8 = self.out.items;
        var failures: usize = 0;
        while (rest.len > 0) {
            const n = std.Io.File.stdout().writeStreaming(self.io, &.{}, &.{rest}, 1) catch {
                failures += 1;
                if (failures > 2000) break;
                self.io.sleep(.fromMilliseconds(5), .real) catch {};
                continue;
            };
            rest = rest[n..];
        }
        self.out.clearRetainingCapacity();
    }
};

fn check(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io, opts: CheckOpts, env_map: libs.EnvMap) !u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const home = try arena.dupe(u8, buf[0..try std.process.currentPath(io, &buf)]);
    var ctx: Ctx = .{ .gpa = gpa, .arena = arena, .io = io, .env_map = env_map, .home = home };

    var cells: std.ArrayListUnmanaged([]const u8) = .empty;
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    for (opts.paths) |path| {
        const root = try std.fs.path.resolve(arena, &.{ home, path });
        var dir = std.Io.Dir.cwd().openDir(io, root, .{}) catch {
            reporter.errMsg(try std.fmt.allocPrint(arena, "{s} is not a directory", .{path}));
            return 1;
        };
        dir.close(io);
        var found: std.ArrayListUnmanaged([]const u8) = .empty;
        var refused: std.ArrayListUnmanaged([]const u8) = .empty;
        try discover(arena, io, root, &found, &refused);
        if (refused.items.len > 0) {
            for (refused.items) |why| reporter.errMsg(why);
            return 1;
        }
        if (found.items.len == 0) {
            reporter.errMsg(try std.fmt.allocPrint(arena, "no cell under {s} — a cell is a directory holding src/main.bp", .{path}));
            return 1;
        }
        for (found.items) |cell| {
            if ((try seen.getOrPut(arena, cell)).found_existing) continue;
            try cells.append(arena, cell);
        }
    }

    var passed: usize = 0;
    const jobs = @min(opts.jobs orelse defaultJobs(io), cells.items.len);
    if (jobs > 1) {
        passed = try checkParallel(&ctx, cells.items, jobs);
    } else for (cells.items) |cell| {
        // Every cell is checked in this process, one after another: what it
        // allocates (its scratch paths, its build's text, its report) lives in
        // an arena of its own, freed once its report is out, so a run over a
        // thousand cells holds one cell's at a time.
        var cell_arena = std.heap.ArenaAllocator.init(gpa);
        defer cell_arena.deinit();
        ctx.arena = cell_arena.allocator();
        defer {
            ctx.out = .empty;
            ctx.arena = arena;
        }
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

// ── the pool ──────────────────────────────────────────────────────────────────

/// Default cells at once (decision 468): one job per CPU bounded by
/// `MemAvailable / 768 MiB`, a job counted as ~2 runnable threads, so half of
/// that, at least 1.
fn defaultJobs(io: std.Io) usize {
    const cpus = std.Thread.getCpuCount() catch 1;
    var jobs = cpus;
    var buf: [4096]u8 = undefined;
    if (std.Io.Dir.cwd().readFile(io, "/proc/meminfo", &buf)) |text| {
        const key = "MemAvailable:";
        if (std.mem.indexOf(u8, text, key)) |at| {
            var it = std.mem.tokenizeAny(u8, text[at + key.len ..], " \t\n");
            if (it.next()) |tok| if (std.fmt.parseUnsigned(u64, tok, 10)) |kb| {
                jobs = @min(jobs, @as(usize, @intCast(@max(kb * 1024 / (768 * 1024 * 1024), 1))));
            } else |_| {};
        }
    } else |_| {}
    return @max(jobs / 2, 1);
}

const Slot = struct {
    /// What the worker printed for the cell: its verdict line and the lines
    /// under it.
    out: []const u8 = "",
    ok: bool = false,
    /// The worker's stderr (warnings of generated code), passed on in order —
    /// on the first cell of its share.
    err: []const u8 = "",
    done: std.Io.Event = .unset,
};

/// How many cells one worker process checks, one after another: about two
/// shares per job, so a slow share leaves the others something to take, and
/// at most `MAX_SHARE`, so a share that dies costs little to check again.
const MAX_SHARE = 32;

fn shareSize(cells: usize, jobs: usize) usize {
    return std.math.clamp(std.math.divCeil(usize, cells, jobs * 2) catch 1, 1, MAX_SHARE);
}

const Pool = struct {
    ctx: *Ctx,
    cells: []const []const u8,
    slots: []Slot,
    share: usize,
    self_exe: []const u8,
    next: std.atomic.Value(usize) = .init(0),

    fn work(pool: *Pool) void {
        while (pool.runNext()) {}
    }

    /// Take the next share of cells and check it in a process of its own
    /// (the build is in process and keeps global state — the report sinks,
    /// the directory — so two cells never build at once in one process). The
    /// process checks its cells one after another with `--jobs 1`, so each
    /// prints what it prints alone. A cell its process left without a verdict
    /// (the process died on it) is checked again in a process of its own, and
    /// so is each cell after it.
    fn runNext(pool: *Pool) bool {
        const first = pool.next.fetchAdd(pool.share, .monotonic);
        if (first >= pool.cells.len) return false;
        const last = @min(first + pool.share, pool.cells.len);
        const share = pool.cells[first..last];
        const a = std.heap.page_allocator;
        var report: []const u8 = "";
        if (pool.runChild(share)) |res| {
            pool.slots[first].err = res.err;
            for (share, first..) |cell, i| {
                if (sectionOf(pool.ctx, res.out, cell)) |sec| {
                    pool.slots[i].out = sec.text;
                    pool.slots[i].ok = sec.ok;
                }
            }
            report = res.out;
        } else |_| {}
        for (share, first..) |cell, i| {
            const slot = &pool.slots[i];
            if (needsAlone(report, pool.ctx.rel(cell), share.len)) {
                if (pool.runChild(&.{cell})) |res| {
                    slot.err = res.err;
                    if (sectionOf(pool.ctx, res.out, cell)) |sec| {
                        slot.out = sec.text;
                        slot.ok = sec.ok and res.exit_ok;
                    } else slot.out = res.out;
                } else |err| {
                    slot.out = std.fmt.allocPrint(a, "FAIL {s}\n  {s}\n", .{ pool.ctx.rel(cell), @errorName(err) }) catch "";
                }
            }
            // A slot is never left without a line naming its cell: the parent
            // adds one (`hasVerdict`) when this is empty or names no verdict.
            slot.done.set(pool.ctx.io);
        }
        return true;
    }

    const Child = struct {
        /// The child's stdout, its last line (its own `cells: …` summary) off.
        out: []const u8,
        err: []const u8,
        exit_ok: bool,
    };

    fn runChild(pool: *Pool, cells: []const []const u8) !Child {
        const a = std.heap.page_allocator;
        var argv: std.ArrayListUnmanaged([]const u8) = .empty;
        defer argv.deinit(a);
        try argv.appendSlice(a, &.{ pool.self_exe, "cell", "check", "--jobs", "1" });
        if (code_cache.cold) try argv.append(a, "--cold");
        try argv.appendSlice(a, cells);
        const res = try std.process.run(a, pool.ctx.io, .{
            .argv = argv.items,
            .environ_map = pool.ctx.env_map,
            .stdout_limit = .limited(64 * 1024 * 1024),
            .stderr_limit = .limited(16 * 1024 * 1024),
        });
        const exit_ok = switch (res.term) {
            .exited => |c| c == 0,
            else => false,
        };
        const body = std.mem.trimEnd(u8, res.stdout, "\n");
        const cut = if (std.mem.lastIndexOfScalar(u8, body, '\n')) |n| n + 1 else 0;
        if (!std.mem.startsWith(u8, body[cut..], "cells: ")) {
            return .{ .out = res.stdout, .err = res.stderr, .exit_ok = false };
        }
        return .{ .out = body[0..cut], .err = res.stderr, .exit_ok = exit_ok };
    }
};

/// Whether `want` goes back to be checked in a process of its own after its
/// share's worker printed `report` (empty when the worker could not run): the
/// share held more than one cell and the report has no verdict line naming it
/// — the worker died on that cell or before it. A cell with a verdict, `FAIL`
/// included, is never checked again.
fn needsAlone(report: []const u8, want: []const u8, share_len: usize) bool {
    return share_len > 1 and sectionFor(report, want) == null;
}

/// The verdict line `line` gives `want` (a cell as printed): `.ok` for
/// `ok   <want>`, `.fail` for `FAIL <want>` alone or followed by ` — …`.
fn verdictOf(line: []const u8, want: []const u8) ?enum { ok, fail } {
    if (std.mem.startsWith(u8, line, "ok   ") and std.mem.eql(u8, line["ok   ".len..], want)) return .ok;
    if (!std.mem.startsWith(u8, line, "FAIL ")) return null;
    const rest = line["FAIL ".len..];
    if (!std.mem.startsWith(u8, rest, want)) return null;
    const tail = rest[want.len..];
    return if (tail.len == 0 or std.mem.startsWith(u8, tail, " — ")) .fail else null;
}

/// Whether `line` is a verdict line at all (a cell's report starts with one;
/// every line under it is indented).
fn isVerdictLine(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "ok   ") or std.mem.startsWith(u8, line, "FAIL ");
}

const Section = struct { text: []const u8, ok: bool };

/// The lines a worker printed for `cell`: its verdict line and every line up
/// to the next verdict line; null when no verdict line names it.
fn sectionOf(ctx: *Ctx, out: []const u8, cell: []const u8) ?Section {
    return sectionFor(out, ctx.rel(cell));
}

fn sectionFor(out: []const u8, want: []const u8) ?Section {
    var at: usize = 0;
    while (at < out.len) {
        const nl = std.mem.indexOfScalarPos(u8, out, at, '\n') orelse out.len;
        const line = out[at..nl];
        if (verdictOf(line, want)) |v| {
            var end = @min(nl + 1, out.len);
            while (end < out.len) {
                const e = std.mem.indexOfScalarPos(u8, out, end, '\n') orelse out.len;
                if (isVerdictLine(out[end..e])) break;
                end = @min(e + 1, out.len);
            }
            return .{ .text = out[at..end], .ok = v == .ok };
        }
        at = nl + 1;
    }
    return null;
}

/// Whether `out` holds the verdict line of `cell`: `ok   <cell>` for a pass,
/// a `FAIL <cell>` line for anything else.
fn hasVerdict(ctx: *Ctx, out: []const u8, cell: []const u8, ok: bool) bool {
    const want = ctx.rel(cell);
    var lines = std.mem.splitScalar(u8, out, '\n');
    while (lines.next()) |l| {
        if (verdictOf(l, want)) |v| return (v == .ok) == ok;
    }
    return false;
}

/// Check `cells` on `jobs` workers, each a process checking a share of them
/// (`shareSize`); the report is printed in the cells' order. Returns how many
/// passed.
fn checkParallel(ctx: *Ctx, cells: []const []const u8, jobs: usize) !usize {
    const a = ctx.arena;
    const slots = try a.alloc(Slot, cells.len);
    for (slots) |*s| s.* = .{};
    const self_exe = try std.process.executablePathAlloc(ctx.io, a);
    var pool: Pool = .{ .ctx = ctx, .cells = cells, .slots = slots, .share = shareSize(cells.len, jobs), .self_exe = self_exe };
    const workers = try a.alloc(?std.Io.Future(void), jobs);
    var started: usize = 0;
    for (workers) |*w| {
        w.* = ctx.io.concurrent(Pool.work, .{&pool}) catch null;
        if (w.* != null) started += 1;
    }
    defer for (workers) |*w| if (w.*) |*f| f.cancel(ctx.io);
    var passed: usize = 0;
    var slot_index: usize = 0;
    for (slots) |*slot| {
        if (started == 0) while (!slot.done.isSet() and pool.runNext()) {};
        slot.done.waitUncancelable(ctx.io);
        const cell = cells[slot_index];
        slot_index += 1;
        if (slot.ok) passed += 1;
        ctx.flush();
        if (slot.err.len > 0) std.Io.File.stderr().writeStreamingAll(ctx.io, slot.err) catch {};
        ctx.say("{s}", .{slot.out});
        // Every cell found is in the report: a verdict line (`ok` or `FAIL`)
        // naming it, whatever the worker did (an allocation that failed, a
        // child that printed nothing, a pass with no `ok` line).
        if (!hasVerdict(ctx, slot.out, cell, slot.ok)) {
            if (slot.ok) {
                passed -= 1;
                ctx.say("FAIL {s}\n  the check process reported success without a verdict line\n", .{ctx.rel(cell)});
            } else {
                ctx.say("FAIL {s}\n  the check process left no report\n", .{ctx.rel(cell)});
            }
        }
        ctx.flush();
    }
    return passed;
}

/// `root` itself when it is a cell (it holds `src/`), else every cell under
/// it, sorted — never inside a cell, a hidden directory, `node_modules` or a
/// `deps` directory (a cell's own dependency packages live there, and a
/// `deps/<pkg>` holding `src/` is a package, never a cell). A directory
/// holding `cases/` is a module of cases (decision 765): each `cases/<case>`
/// is a cell. `refused` collects what the layout forbids — a directory
/// holding both `cases/` and `src/`, and a `cases/<x>` that is no cell.
fn discover(
    arena: std.mem.Allocator,
    io: std.Io,
    root: []const u8,
    out: *std.ArrayListUnmanaged([]const u8),
    refused: *std.ArrayListUnmanaged([]const u8),
) !void {
    const cases = try std.fs.path.join(arena, &.{ root, "cases" });
    const has_cases = isDir(io, cases);
    if (isDir(io, try std.fs.path.join(arena, &.{ root, "src" }))) {
        if (has_cases) try refused.append(arena, try std.fmt.allocPrint(arena, "{s} holds both cases/ and src/ — a module holds cases or is a cell, not both (decision 765)", .{root}));
        try out.append(arena, root);
        return;
    }
    if (has_cases) {
        for (try childNames(arena, io, cases, .dirs)) |name| {
            if (name[0] == '.') continue;
            const case = try std.fs.path.join(arena, &.{ cases, name });
            if (!isDir(io, try std.fs.path.join(arena, &.{ case, "src" }))) {
                try refused.append(arena, try std.fmt.allocPrint(arena, "{s} is no cell — a case is a directory holding src/main.bp (decision 765)", .{case}));
                continue;
            }
            try out.append(arena, case);
        }
        return;
    }
    const names = try childNames(arena, io, root, .dirs);
    for (names) |name| {
        if (name[0] == '.' or std.mem.eql(u8, name, "node_modules") or std.mem.eql(u8, name, "deps")) continue;
        try discover(arena, io, try std.fs.path.join(arena, &.{ root, name }), out, refused);
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
    if (!exists(io, try std.fs.path.join(a, &.{ cell, "botopink.json" }))) {
        ctx.say("FAIL {s}\n  a cell holds botopink.json — its own manifest, a project like any other (decision 475)\n", .{rel});
        return false;
    }
    if (exists(io, try std.fs.path.join(a, &.{ cell, "targets" }))) {
        ctx.say("FAIL {s}\n  {s}/targets: a cell is narrowed by its manifest's \"targets\" (decision 475), never by a `targets` file\n", .{ rel, rel });
        return false;
    }
    var why: []const u8 = "";
    const written = readTargets(a, io, cell, &why) catch |err| switch (err) {
        error.Malformed => {
            ctx.say("FAIL {s}\n  {s}/botopink.json \"targets\": {s}\n", .{ rel, rel, why });
            return false;
        },
        else => return err,
    };
    // A cell that writes no `"targets"` holds its dependencies' (decision
    // 770): the targets none of them holds are left out, and audited.
    const declared = if (try writesTargets(a, io, cell)) written else (try heldOf(ctx, cell)) orelse written;
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

    // Build and run in a scratch copy of the cell, one per target: a program
    // that writes into its working directory (`conformance/modules/decisions-taken/fs_walk_dangling_link_not_found-711/cases/std_fs_walk_root_spellings`
    // makes a tree and a dangling link) finds on every target the directory it
    // would find alone.
    var observed: [ALL_TARGETS.len]?Answer = @splat(null);
    var audits: std.ArrayListUnmanaged([]const u8) = .empty;
    var tool_errors: std.ArrayListUnmanaged([]const u8) = .empty;
    for (ALL_TARGETS, 0..) |t, i| {
        const runs = contains(declared, t);
        if (!runs and declared.len == ALL_TARGETS.len) continue;
        var scratch = try Scratch.open(ctx, cell);
        defer scratch.close(ctx);
        if (runs) {
            switch (try scratch.observe(ctx, t)) {
                .answer => |ans| observed[i] = ans,
                .tool_error => |e| try tool_errors.append(a, try std.fmt.allocPrint(a, "{s}: {s}{s}", .{ t.toString(), e.message, try indentDetail(a, e.detail) })),
            }
        } else {
            if (try scratch.audit(ctx, t)) |problem| try audits.append(a, try std.fmt.allocPrint(a, "{s}: {s}", .{ t.toString(), problem }));
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

/// The cell's manifest's `"targets"` — an array of target names — or every
/// target when it has none. A narrowing that is not an array of strings, names
/// an unknown target, one twice, none, or all of them is malformed. (A
/// manifest that is not JSON is the build's to refuse, located.)
fn readTargets(a: std.mem.Allocator, io: std.Io, cell: []const u8, why: *[]const u8) ![]const Target {
    const path = try std.fs.path.join(a, &.{ cell, "botopink.json" });
    const text = try std.Io.Dir.cwd().readFileAlloc(io, path, a, .limited(64 * 1024));
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, a, text, .{}) catch return &ALL_TARGETS;
    if (parsed != .object) return &ALL_TARGETS;
    // A cell that writes no `"targets"` has its workspace's (decision 512 (3)):
    // a library's `conformance/modules/botopink.json` declares its cells'.
    const field = parsed.object.get("targets") orelse (try workspaceTargets(a, io, cell)) orelse return &ALL_TARGETS;
    if (field != .array) {
        why.* = "is not an array of target names";
        return error.Malformed;
    }
    var list: std.ArrayListUnmanaged(Target) = .empty;
    for (field.array.items) |item| {
        if (item != .string) {
            why.* = "is not an array of target names";
            return error.Malformed;
        }
        const name = item.string;
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
        why.* = "names every target, so it narrows nothing — delete the field";
        return error.Malformed;
    }
    // In `ALL_TARGETS` order, whatever order the file wrote.
    var ordered: std.ArrayListUnmanaged(Target) = .empty;
    for (ALL_TARGETS) |t| if (contains(list.items, t)) try ordered.append(a, t);
    return ordered.items;
}

/// Whether the cell's own manifest writes `"targets"`.
fn writesTargets(a: std.mem.Allocator, io: std.Io, cell: []const u8) !bool {
    const path = try std.fs.path.join(a, &.{ cell, "botopink.json" });
    const text = try std.Io.Dir.cwd().readFileAlloc(io, path, a, .limited(64 * 1024));
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, a, text, .{}) catch return false;
    if (parsed != .object) return false;
    return parsed.object.get("targets") != null;
}

/// The targets a cell that writes no `"targets"` holds (decision 770): its
/// workspace's and its dependencies', in `ALL_TARGETS` order, as the build
/// resolves them in a scratch copy. Null when the closure does not resolve —
/// every build then refuses the cell, and that refusal is its answer.
fn heldOf(ctx: *Ctx, cell: []const u8) !?[]const Target {
    const a = ctx.arena;
    var scratch = try Scratch.open(ctx, cell);
    defer scratch.close(ctx);
    var sink: std.Io.Writer.Allocating = .init(a);
    reporter.sink = &sink.writer;
    manifest.sink = &sink.writer;
    defer reporter.sink = null;
    defer manifest.sink = null;
    const proj = config.load(a, ctx.io) catch return null;
    const held = libs.heldTargets(ctx.gpa, ctx.io, a, proj, ctx.env_map) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    var out: std.ArrayListUnmanaged(Target) = .empty;
    for (ALL_TARGETS) |t| {
        for (held) |h| if (std.mem.eql(u8, h, t.toString())) {
            try out.append(a, t);
            break;
        };
    }
    return out.items;
}

/// The `"targets"` of the workspace the cell is a member of (`manifest.workspaceOf`,
/// its globs alone — a sibling's manifest is never read), or null.
fn workspaceTargets(a: std.mem.Allocator, io: std.Io, cell: []const u8) !?std.json.Value {
    var err: ?manifest.Located = null;
    const ws = (manifest.workspaceOf(a, io, cell, &err) catch return null) orelse return null;
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, a, ws.text, .{}) catch return null;
    if (parsed != .object) return null;
    return parsed.object.get("targets");
}

/// The cache root of the cell's dependencies (decisions 225, 509 (4)): the
/// workspace it is a member of — every `conformance/modules/` is one, so a
/// library's cells share one cache — else the cell's own directory.
fn cacheRootOf(a: std.mem.Allocator, io: std.Io, cell: []const u8) ![]const u8 {
    var err: ?manifest.Located = null;
    const ws = (manifest.workspaceOf(a, io, cell, &err) catch null) orelse return cell;
    return ws.dir();
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

/// `cell`'s path relative to the workspace directory `ws_dir` that lists it
/// (`a/b` for `<ws_dir>/a/b`); the cell's basename when the path does not lie under it.
fn memberPath(ws_dir: []const u8, cell: []const u8) []const u8 {
    var base = ws_dir;
    while (base.len > 1 and base[base.len - 1] == std.fs.path.sep) base = base[0 .. base.len - 1];
    if (cell.len > base.len + 1 and std.mem.startsWith(u8, cell, base) and cell[base.len] == std.fs.path.sep)
        return std.mem.trim(u8, cell[base.len + 1 ..], &.{std.fs.path.sep});
    return std.fs.path.basename(cell);
}

/// The workspace manifest `text` with its `"workspaces"` array replaced by the
/// one literal entry `member`: the scratch copy holds only the cell, so the
/// root's other entries (`a/*`, `b/c/*`) would name directories it lacks.
fn soleMember(a: std.mem.Allocator, text: []const u8, member: []const u8) ![]const u8 {
    const key = std.mem.indexOf(u8, text, "\"workspaces\"") orelse return text;
    const open = std.mem.indexOfScalarPos(u8, text, key, '[') orelse return text;
    const close = std.mem.indexOfScalarPos(u8, text, open, ']') orelse return text;
    return std.fmt.allocPrint(a, "{s}[\"{s}\"]{s}", .{ text[0..open], member, text[close + 1 ..] });
}

/// A copy of the cell, one per target — everything but `snapshot/`, `docs.md`
/// and hidden entries — under `<home>/.botopinkbuild/tmp/cell-<64 random bits>/`, its
/// manifest the cell's own (`checkCell` refused a cell without one). The process works
/// in it while it is open (every CLI path is relative to the current
/// directory) and returns home when it closes.
const Scratch = struct {
    /// The scratch directory, removed when it closes.
    root: []const u8,
    /// The copy of the cell — `root` itself, or `<root>/<cell>` when the cell
    /// is a workspace member.
    dir: []const u8,
    manifest: []const u8,
    /// The environment before the scratch project's own (`cellEnv`).
    prev_env: libs.EnvMap,
    /// `code_cache.root_override` before this cell's.
    prev_root: ?[]const u8,

    fn open(ctx: *Ctx, cell: []const u8) !Scratch {
        const a = ctx.arena;
        var rand: [8]u8 = undefined;
        ctx.io.random(&rand);
        const root = try std.fmt.allocPrint(a, "{s}/{s}/cell-{x:0>16}", .{ ctx.home, TMP_ROOT, std.mem.readInt(u64, &rand, .little) });
        // A cell that is a member of a workspace (a library's
        // `conformance/modules/`, decision 512 (5)) is built as one: the copy
        // sits in a workspace of its own whose manifest is the cell's
        // workspace's — its dependencies made absolute against the workspace's
        // directory — and whose one member is the cell, so the cell inherits
        // what it inherits in place, and no sibling is read.
        var err: ?manifest.Located = null;
        const ws = manifest.workspaceOf(a, ctx.io, cell, &err) catch null;
        // The copy keeps the cell's path relative to the workspace root, and the
        // copied manifest lists that path alone (`soleMember`).
        const dir = if (ws) |w| try std.fs.path.join(a, &.{ root, memberPath(w.dir(), cell) }) else root;
        try std.Io.Dir.cwd().createDirPath(ctx.io, dir);
        if (ws) |w| {
            const ws_text = try soleMember(a, try absolutizePathDeps(a, w.text, w.dir(), false), memberPath(w.dir(), cell));
            try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = try std.fs.path.join(a, &.{ root, manifest.FILENAME }), .data = ws_text });
        }
        try copyTree(a, ctx.io, cell, dir, true, std.Io.Dir.cwd().realPathFileAlloc(ctx.io, cell, a) catch cell);
        // The copy lives elsewhere, so what the manifest names relative to the
        // cell is made absolute against the cell's own directory.
        const manifest_path = try std.fs.path.join(a, &.{ dir, "botopink.json" });
        const original = try std.Io.Dir.cwd().readFileAlloc(ctx.io, manifest_path, a, .limited(64 * 1024));
        const manifest_text = try absolutizePathDeps(a, original, cell, true);
        if (!std.mem.eql(u8, original, manifest_text))
            try std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = manifest_path, .data = manifest_text });
        const prev_env = ctx.env_map;
        ctx.env_map = try cellEnv(ctx, cell);
        // The cell's dependencies are cached where the cell lives (decision
        // 509 (4)), never in the scratch copy.
        const prev_root = code_cache.root_override;
        code_cache.root_override = try cacheRootOf(a, ctx.io, cell);
        try std.process.setCurrentPath(ctx.io, dir);
        return .{ .root = root, .dir = dir, .manifest = manifest_text, .prev_env = prev_env, .prev_root = prev_root };
    }

    fn close(self: *Scratch, ctx: *Ctx) void {
        std.process.setCurrentPath(ctx.io, ctx.home) catch {};
        ctx.env_map = self.prev_env;
        code_cache.root_override = self.prev_root;
        std.Io.Dir.cwd().deleteTree(ctx.io, self.root) catch {};
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

        // The host goes in last, before the closing brace, so every line and
        // column of the cell's own manifest — where a refusal of it is located —
        // is the same in the two builds.
        const brace = std.mem.lastIndexOfScalar(u8, self.manifest, '}') orelse return first;
        const browser_manifest = try std.fmt.allocPrint(ctx.arena, "{s}, \"wasm\": {{ \"host\": \"browser\" }} {s}", .{ std.mem.trimEnd(u8, self.manifest[0..brace], " \t\r\n"), self.manifest[brace..] });
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

    /// A target the manifest's `"targets"` leaves out: its build must refuse the cell
    /// on a host binding — the one reason a program structurally has no row
    /// on a target — or on a dependency's missing target (decision 676). Null
    /// when it does; else what is wrong.
    fn audit(self: *Scratch, ctx: *Ctx, t: Target) !?[]const u8 {
        _ = self;
        const a = ctx.arena;
        if ((t == .erlang or t == .beam) and !try otp.check(a, ctx.io))
            return "`erl` on PATH does not run the OTP release the compiler emits for";
        const out_dir = try std.fmt.allocPrint(a, "out-{s}", .{t.toString()});
        var captured: std.Io.Writer.Allocating = .init(a);
        const code = try buildCaptured(ctx, t, out_dir, &captured.writer);
        if (code == 0) return try std.fmt.allocPrint(a, "excluded by \"targets\", but `botopink build --target {s}` accepts the cell — a narrowing stands on a host-binding refusal: let it run on {s}", .{ t.toString(), t.toString() });
        const text = try stripAnsi(a, captured.written());
        for (HOST_BINDING_REFUSALS) |phrase| if (std.mem.indexOf(u8, text, phrase) != null) return null;
        const beam_memory = try std.fmt.allocPrint(a, "`#[compiler.beamMemory(…)]` has no meaning on the {s} backend", .{t.toString()});
        if (std.mem.indexOf(u8, text, beam_memory) != null) return null;
        const first = firstErrorLine(text) orelse "no error line";
        return try std.fmt.allocPrint(a, "excluded by \"targets\", and {s} refuses it for another reason than a host binding ({s}) — let it run there, its refusal answered in snapshot/targets/{s}/", .{ t.toString(), first, t.toString() });
    }
};

/// The environment a cell builds under: the command's own, with
/// `BOTOPINK_LIB_ROOTS` extended by the tiers of the project the cell is
/// (decision 483) — the command's roots (relative ones against the directory
/// the command started in), the cell's `.botopinkbuild/deps/` (and its
/// workspace's), then the walk-up from the cell's own directory. The scratch
/// copy skips hidden entries and sits elsewhere, so it could reach none of
/// them by itself.
fn cellEnv(ctx: *Ctx, cell: []const u8) !libs.EnvMap {
    const a = ctx.arena;
    const map = try a.create(std.process.Environ.Map);
    map.* = std.process.Environ.Map.init(a);
    if (ctx.env_map) |src| {
        for (src.keys(), src.values()) |k, v| try map.put(k, v);
    }
    const env_roots = try libs.parseEnvRoots(ctx.gpa, ctx.env_map, ctx.home);
    defer libs.freeRoots(ctx.gpa, env_roots);
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    for (env_roots) |r| try roots.append(a, r);
    for (try manifest.depsRoots(a, ctx.io, cell)) |d| try roots.append(a, d);
    const walk_up = try libs.rootsFrom(ctx.gpa, ctx.io, &.{}, cell);
    defer libs.freeRoots(ctx.gpa, walk_up);
    for (walk_up) |r| try roots.append(a, r);
    var value: std.ArrayListUnmanaged(u8) = .empty;
    for (roots.items, 0..) |r, i| {
        if (i > 0) try value.append(a, ':');
        try value.appendSlice(a, r);
    }
    try map.put(libs.ENV_VAR, value.items);
    return map;
}

/// `text` (a cell's manifest) with every relative `"path": "…"` dependency
/// that leaves `cell_dir` made absolute against it, nothing else touched. A
/// path that stays inside the cell is the copy's own (`copyTree` carries it),
/// so it stays as written: a refusal located in it is then relative to the
/// cell (`deps/…`), and the columns of the manifest after it do not move.
/// `keep_inside` false (the workspace's manifest, whose copy holds only the cell)
/// makes every relative path absolute.
fn absolutizePathDeps(a: std.mem.Allocator, text: []const u8, cell_dir: []const u8, keep_inside: bool) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (std.mem.indexOfPos(u8, text, i, "\"path\"")) |k| {
        var j = k + "\"path\"".len;
        while (j < text.len and std.ascii.isWhitespace(text[j])) j += 1;
        if (j >= text.len or text[j] != ':') {
            try out.appendSlice(a, text[i..j]);
            i = j;
            continue;
        }
        j += 1;
        while (j < text.len and std.ascii.isWhitespace(text[j])) j += 1;
        if (j >= text.len or text[j] != '"') {
            try out.appendSlice(a, text[i..j]);
            i = j;
            continue;
        }
        const start = j + 1;
        const end = std.mem.indexOfScalarPos(u8, text, start, '"') orelse break;
        const value = text[start..end];
        try out.appendSlice(a, text[i..start]);
        if (value.len == 0 or std.fs.path.isAbsolute(value) or std.mem.indexOfScalar(u8, value, '\\') != null) {
            try out.appendSlice(a, value);
        } else {
            const resolved = try std.fs.path.resolve(a, &.{ cell_dir, value });
            const base = try std.fs.path.resolve(a, &.{cell_dir});
            const inside = resolved.len > base.len and std.mem.startsWith(u8, resolved, base) and resolved[base.len] == std.fs.path.sep;
            try out.appendSlice(a, if (inside and keep_inside) value else resolved);
        }
        i = end;
    }
    try out.appendSlice(a, text[i..]);
    return out.items;
}

/// Copy `from` into `to`. At the top level `snapshot/` and `docs.md` stay
/// behind; hidden entries stay behind at every level. A symbolic link to a
/// directory outside the cell (`cell_real`, the cell's real path) stays a
/// link, its target made absolute: the compiler resolves a linked package
/// through its real path, where its `path` dependencies and its enclosing
/// workspace are, and a copy of the package's files in the cell's tree would
/// be read through the cell's own `deps/botopink.json`, whose literal
/// `"workspaces"` entries name directories the copy lacks (B-132).
fn copyTree(a: std.mem.Allocator, io: std.Io, from: []const u8, to: []const u8, top: bool, cell_real: []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    for (try childNames(a, io, from, .all)) |name| {
        if (name[0] == '.') continue;
        if (top and (std.mem.eql(u8, name, "snapshot") or std.mem.eql(u8, name, "docs.md"))) continue;
        const src = try std.fs.path.join(a, &.{ from, name });
        const dst = try std.fs.path.join(a, &.{ to, name });
        if (isDir(io, src)) {
            if (try outsideLinkTarget(a, io, src, cell_real)) |target| {
                try cwd.symLink(io, target, dst, .{ .is_directory = true });
                continue;
            }
            try cwd.createDirPath(io, dst);
            try copyTree(a, io, src, dst, false, cell_real);
        } else {
            const data = try cwd.readFileAlloc(io, src, a, .limited(64 * 1024 * 1024));
            try cwd.writeFile(io, .{ .sub_path = dst, .data = data });
        }
    }
}

/// The real path `src` links to when `src` is a symbolic link to a directory
/// that lies outside `cell_real`; null otherwise.
fn outsideLinkTarget(a: std.mem.Allocator, io: std.Io, src: []const u8, cell_real: []const u8) !?[]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    _ = std.Io.Dir.cwd().readLink(io, src, &buf) catch return null;
    const real = std.Io.Dir.cwd().realPathFileAlloc(io, src, a) catch return null;
    const inside = real.len > cell_real.len and std.mem.startsWith(u8, real, cell_real) and real[cell_real.len] == std.fs.path.sep;
    return if (inside) null else real;
}

/// `botopink build --target t --out out_dir` in this process, everything it
/// would print to stderr written to `w` instead.
fn buildCaptured(ctx: *Ctx, t: Target, out_dir: []const u8, w: *std.Io.Writer) !u8 {
    reporter.sink = w;
    manifest.sink = w;
    defer reporter.sink = null;
    defer manifest.sink = null;
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
        manifest.sink = &captured.writer;
        defer reporter.sink = null;
        defer manifest.sink = null;
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

/// Whether the two wasm hosts answered alike: the same text — or, when both
/// refuse the program, the same modules refused at the same places. A refusal
/// may name the host it was built for (`std-unsupported-on-target: … on host
/// 'wasi'` / `'browser'`); the cell's answer is the `wasi` build's, and the
/// `browser` build must refuse it where `wasi` does (the rule of
/// `tests/language/run.sh` before the cells moved here was weaker: both
/// refused, nothing printed).
fn sameAnswer(a: std.mem.Allocator, x: Answer, y: Answer) !bool {
    if (std.mem.eql(u8, try describe(a, x), try describe(a, y))) return true;
    if (!refusesOnly(x) or !refusesOnly(y) or x.modules.count() != y.modules.count()) return false;
    for (x.modules.keys(), x.modules.values()) |k, xs| {
        const ys = y.modules.get(k) orelse return false;
        if (xs.refusals.len != ys.refusals.len) return false;
        for (xs.refusals, ys.refusals) |xr, yr| {
            if ((xr.at == null) != (yr.at == null)) return false;
            if (xr.at) |at| if (!std.mem.eql(u8, at, yr.at.?)) return false;
        }
    }
    return true;
}

fn refusesOnly(ans: Answer) bool {
    if (ans.modules.count() == 0) return false;
    for (ans.modules.values()) |m| if (m.refusals.len == 0) return false;
    return true;
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
    // The caret line of the open refusal is read once, right after its `-->`.
    var caret_read = false;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (isErrorLine(line)) {
            open = !isSummary(line);
            caret_read = false;
            if (open) try flat.append(a, .{ .message = line });
        } else if (std.mem.startsWith(u8, line, "warning")) {
            open = false;
        } else if (open and std.mem.startsWith(u8, std.mem.trimStart(u8, line, " "), "= called from ")) {
            // Decision 532 — a `called from` line of the open refusal.
            const t = std.mem.trimStart(u8, line, " ");
            const last = &flat.items[flat.items.len - 1];
            var grown: std.ArrayListUnmanaged([]const u8) = .empty;
            try grown.appendSlice(a, last.from);
            try grown.append(a, t["= called from ".len..]);
            last.from = grown.items;
        } else if (open and flat.items[flat.items.len - 1].at == null) {
            const t = std.mem.trimStart(u8, line, " ");
            if (std.mem.startsWith(u8, t, "--> ")) flat.items[flat.items.len - 1].at = t["--> ".len..];
        } else if (open and !caret_read) {
            if (caretLabel(line)) |l| {
                caret_read = true;
                if (l.len > 0) flat.items[flat.items.len - 1].label = l;
            }
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

/// The text beside the caret of a source-snippet line (`  |   ^^^ the label`):
/// "" when the carets stand alone, null when the line is no caret line.
fn caretLabel(line: []const u8) ?[]const u8 {
    const bar = std.mem.indexOfScalar(u8, line, '|') orelse return null;
    if (std.mem.trim(u8, line[0..bar], " 0123456789").len != 0) return null;
    const after = std.mem.trimStart(u8, line[bar + 1 ..], " ");
    if (after.len == 0 or after[0] != '^') return null;
    const rest = std.mem.trimStart(u8, after, "^");
    return std.mem.trim(u8, rest, " ");
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
        \\error: `f` has no implementation for the wasm backend
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

test "refusalsOf reads the label beside the caret, and none when the caret stands alone" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text =
        \\error[case-bare-name-arm]: a name alone is not a pattern
        \\ --> src/main.bp:7:9
        \\  |
        \\7 |         n { "other" }
        \\  |         ^ use _ { n -> … } to bind the matched value
        \\  |
        \\  = hint: An arm names a type.
        \\
        \\error[x]: bare caret
        \\ --> src/main.bp:9:1
        \\  |
        \\9 | foo
        \\  | ^^^
        \\
    ;
    const got = (try refusalsOf(a, text)).get("main").?;
    try testing.expectEqualStrings("use _ { n -> … } to bind the matched value", got.refusals[0].label.?);
    try testing.expect(got.refusals[1].label == null);
}

test "refusalsOf reads the called-from lines of a raise at build under the refusal (decision 532)" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text =
        \\error: {error,{panic,<<"boom">>}}
        \\ --> src/deco.bp:3:5
        \\  |
        \\3 |     panic("boom");
        \\  |     ^
        \\  |
        \\  = hint: the decorator's body raised
        \\  = called from src/main.bp:9:3
        \\  = called from src/main.bp:12:1
        \\
    ;
    const got = try refusalsOf(a, text);
    try testing.expect(got.get("main") == null);
    const deco = got.get("deco").?;
    try testing.expectEqualStrings("src/deco.bp:3:5", deco.refusals[0].at.?);
    try testing.expectEqual(@as(usize, 2), deco.refusals[0].from.len);
    try testing.expectEqualStrings("src/main.bp:9:3", deco.refusals[0].from[0]);
    try testing.expectEqualStrings("src/main.bp:12:1", deco.refusals[0].from[1]);
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

test "absolutizePathDeps resolves a relative path against the cell, leaving the rest" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text = "{ \"name\": \"c\", \"dependencies\": { \"k\": { \"path\": \"../../lib/k\" }, \"z\": { \"path\": \"/abs/z\" } } }";
    const got = try absolutizePathDeps(a, text, "/w/cells/modules/c", true);
    try std.testing.expectEqualStrings("{ \"name\": \"c\", \"dependencies\": { \"k\": { \"path\": \"/w/cells/lib/k\" }, \"z\": { \"path\": \"/abs/z\" } } }", got);
}

test "absolutizePathDeps keeps a path inside the cell as written, so columns and locations hold" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const text = "{ \"dependencies\": { \"m\": { \"path\": \"deps/m\" } }, \"bpp\": \"m\" }";
    try std.testing.expectEqualStrings(text, try absolutizePathDeps(a, text, "/w/cells/modules/c", true));
}

test "discover finds the cells of a directory and never a nested package under deps/" {
    const io = std.testing.io;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const test_scratch = @import("test_scratch");
    test_scratch.remove(io, "cell-discover");
    defer test_scratch.remove(io, "cell-discover");
    const root = test_scratch.path(io, "cell-discover/modules");
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "one", "src" }));
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "one", "deps", "pkg", "src" }));
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(a, &.{ root, "one", "deps", "pkg", "botopink.json" }), .data = "{ \"name\": \"pkg\" }" });
    // A leftover tree outside any cell: `modules/<cell>/deps/<pkg>/src`.
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "modules", "one", "deps", "pkg", "src" }));
    var cells: std.ArrayListUnmanaged([]const u8) = .empty;
    var refused: std.ArrayListUnmanaged([]const u8) = .empty;
    try discover(a, io, root, &cells, &refused);
    try std.testing.expectEqual(@as(usize, 1), cells.items.len);
    try std.testing.expectEqualStrings(try std.fs.path.join(a, &.{ root, "one" }), cells.items[0]);
    try std.testing.expectEqual(@as(usize, 0), refused.items.len);
}

test "discover finds the cases of a module, and refuses src/ beside cases/ and a case that is no cell (decision 765)" {
    const io = std.testing.io;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const test_scratch = @import("test_scratch");
    test_scratch.remove(io, "cell-discover-cases");
    defer test_scratch.remove(io, "cell-discover-cases");
    const root = test_scratch.path(io, "cell-discover-cases/modules");
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "m", "cases", "b", "src" }));
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "m", "cases", "a", "src" }));
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "plain", "src" }));
    var cells: std.ArrayListUnmanaged([]const u8) = .empty;
    var refused: std.ArrayListUnmanaged([]const u8) = .empty;
    try discover(a, io, root, &cells, &refused);
    try std.testing.expectEqual(@as(usize, 3), cells.items.len);
    try std.testing.expectEqualStrings(try std.fs.path.join(a, &.{ root, "m", "cases", "a" }), cells.items[0]);
    try std.testing.expectEqualStrings(try std.fs.path.join(a, &.{ root, "m", "cases", "b" }), cells.items[1]);
    try std.testing.expectEqual(@as(usize, 0), refused.items.len);
    // src/ beside cases/, and a case without src/.
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "m", "src" }));
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ root, "other", "cases", "stray" }));
    cells = .empty;
    try discover(a, io, root, &cells, &refused);
    try std.testing.expectEqual(@as(usize, 2), refused.items.len);
    try std.testing.expect(std.mem.indexOf(u8, refused.items[0], "m holds both cases/ and src/") != null);
    try std.testing.expect(std.mem.indexOf(u8, refused.items[1], "other/cases/stray is no cell") != null);
}

test "moduleOfCase reads the module off a case path, and the docs link is appended (decision 765)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectEqualStrings("modules/m", moduleOfCase("modules/m/cases/c").?);
    try std.testing.expectEqualStrings("m", moduleOfCase("m/cases/c/").?);
    try std.testing.expect(moduleOfCase("modules/m/c") == null);
    try std.testing.expect(moduleOfCase("cases/c") == null);
    try std.testing.expectEqualStrings("# m\n\n[cases/c/src/main.bp](cases/c/src/main.bp)\n", try withCaseLink(a, null, "m", "c"));
    try std.testing.expectEqualStrings("# m\n\ntext\n[cases/d/src/main.bp](cases/d/src/main.bp)\n", try withCaseLink(a, "# m\n\ntext", "m", "d"));
}

test "a worker's report is cut into each cell's section by its verdict line" {
    const out =
        \\ok   cells/a
        \\FAIL cells/ab — a new cell: no accepted snapshot yet, candidates written
        \\  main on commonJS: the answer every target gives
        \\    candidate cells/ab/snapshot/output/main.snap.new
        \\FAIL cells/b
        \\  wasm: the program ran past 300 s
        \\
    ;
    const a = sectionFor(out, "cells/a").?;
    try testing.expect(a.ok);
    try testing.expectEqualStrings("ok   cells/a\n", a.text);
    const ab = sectionFor(out, "cells/ab").?;
    try testing.expect(!ab.ok);
    try testing.expect(std.mem.endsWith(u8, ab.text, "main.snap.new\n"));
    try testing.expect(std.mem.startsWith(u8, ab.text, "FAIL cells/ab — "));
    const b = sectionFor(out, "cells/b").?;
    try testing.expect(!b.ok);
    try testing.expectEqualStrings("FAIL cells/b\n  wasm: the program ran past 300 s\n", b.text);
    // A cell no verdict line names has no section: the parent reports it.
    try testing.expect(sectionFor(out, "cells/c") == null);
    try testing.expect(sectionFor(out, "cells") == null);
}

test "a share whose worker died keeps the verdicts it printed and sends each other cell back alone" {
    // A report cut short after two of four cells: the third has no verdict
    // line (the process died on it) and the fourth was never reached.
    const wants = [_][]const u8{ "a/one", "a/two", "a/three", "a/four" };
    const cut = "ok   a/one\nFAIL a/two\n  expected 1\n";
    const expect = [_]bool{ false, false, true, true };
    for (wants, expect) |w, e| try std.testing.expectEqual(e, needsAlone(cut, w, wants.len));
    // No report at all (the worker could not run): every cell goes back.
    for (wants) |w| try std.testing.expect(needsAlone("", w, wants.len));
    // A share of one cell is never rerun: it already ran alone.
    try std.testing.expect(!needsAlone("", "a/one", 1));
}

test "a share is about two per job, at least one cell and at most MAX_SHARE" {
    try testing.expectEqual(@as(usize, 1), shareSize(5, 4));
    try testing.expectEqual(@as(usize, 2), shareSize(5, 2));
    try testing.expectEqual(@as(usize, MAX_SHARE), shareSize(1085, 6));
    try testing.expectEqual(@as(usize, 1), shareSize(1, 8));
}

test "soleMember lists the cell alone, the rest of the manifest as written" {
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const text = "{ \"name\": \"w\", \"workspaces\": [\"a/x/*\", \"b/y/*\"], \"targets\": [\"erlang\"] }";
    try std.testing.expectEqualStrings(
        "{ \"name\": \"w\", \"workspaces\": [\"b/y/c\"], \"targets\": [\"erlang\"] }",
        try soleMember(arena.allocator(), text, "b/y/c"),
    );
}

test "memberPath keeps the cell's path under the workspace root" {
    try std.testing.expectEqualStrings("c", memberPath("/w/modules", "/w/modules/c"));
    try std.testing.expectEqualStrings("group/c", memberPath("/w/modules/", "/w/modules/group/c"));
    try std.testing.expectEqualStrings("c", memberPath("/w/other", "/w/modules/c"));
}
