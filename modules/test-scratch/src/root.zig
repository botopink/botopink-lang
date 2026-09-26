//! `test_scratch` — the one way a test spells a path it writes to.
//!
//! ## The defect this exists to make unrepeatable
//!
//! `zig build test` runs each test binary with its package directory as cwd
//! (`build.zig`: `run_*_tests.setCwd(...)`), so every test in the tree writes
//! into ONE shared checkout. A scratch path scoped per *test name* but not per
//! *run* is therefore shared by every process that runs the suite — a second
//! `zig build test` over the same checkout (another worktree's gate, a
//! hand-run test binary, CI and a developer at once). Each test opens by
//! `deleteTree`-ing its own root, so the second process empties the first
//! one's fixtures mid-test and reds a run nobody owns:
//!
//!     cli.config.workspaceRefusal …                FAIL (FileNotFound)
//!     cli.format_cmd decision 66: the walk reaches … expected 5, found 0
//!     cli.libs.resolveLibRoots: repository workspace … expected 2, found 0
//!     cli.resolver a `files` entry is not an orphan … FAIL (RootNotFound)
//!
//! One process is green; two are not. It is the same root cause as
//! `botopink test`'s old shared `.botopinkbuild/test-out/` (`cli/test_cmd.zig`)
//! and as the comptime runtime's scratch dirs (`codegen/runtime.zig`
//! `makeScratchDir`): a fixed path under a shared checkout. The remedy is the
//! same one, in the same shape — a **per-process** segment.
//!
//! ## The shape
//!
//!     .botopinkbuild/test-scratch/<id>/<rel>
//!
//! `<id>` is 64 random bits drawn once per process (`io.random`, the same
//! source the two siblings above use). `<rel>` is the caller's comptime path,
//! so a path is still per test AND now per run.
//!
//! It stays under `.botopinkbuild/` so `botopink clean` and the `.gitignore`
//! entry keep covering it with no new rule.
//!
//! ## No allocation
//!
//! `path` is keyed by a **comptime** `rel`, so each call site owns a static
//! buffer sized exactly `<root>/<rel>`, filled once. Nothing is allocated, so
//! nothing leaks under `std.testing.allocator` and no arena has to outlive the
//! path. Two call sites spelling the same `rel` share one instantiation and
//! therefore one buffer — the same bytes either way.
//!
//! ## Why it is not reachable from production code
//!
//! `build.zig` hands this module to the TEST modules only. A reference from
//! outside a `test` block is analysed by the executable build too, where the
//! module does not exist — so it does not compile. That is the refusal
//! (decision 67): not a warning, and no flag turns it off.
//!
//! The companion rule — a test may not spell a cwd-anchored `.botopinkbuild`
//! path by hand again — is `scripts/check-test-scratch.sh`, which `zig build
//! test` depends on.

const std = @import("std");

/// Every per-process root lives under this one directory, so a whole suite's
/// leftovers are one `rm -rf` and one `.gitignore` line.
pub const PREFIX = ".botopinkbuild/test-scratch";

/// 64 bits rendered as zero-padded hex.
const ID_LEN = 16;
const ROOT_LEN = PREFIX.len + 1 + ID_LEN;

/// An atomic spin-lock, the same shape `comptime/runtime/persistent_beam.zig`
/// uses: a test binary's tests may run on several threads, and two of them
/// drawing the root would give one process two roots.
var mu: std.atomic.Value(u8) = .init(0);
var root_buf: [ROOT_LEN]u8 = undefined;
var root_ready = false;

fn lock() void {
    while (mu.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlock() void {
    mu.store(0, .release);
}

/// This process's scratch root: `.botopinkbuild/test-scratch/<id>`.
pub fn root(io: std.Io) []const u8 {
    lock();
    defer unlock();
    return rootLocked(io);
}

fn rootLocked(io: std.Io) []const u8 {
    if (!root_ready) {
        var rand_bytes: [8]u8 = undefined;
        io.random(&rand_bytes);
        const id = std.mem.readInt(u64, &rand_bytes, .little);
        _ = std.fmt.bufPrint(&root_buf, PREFIX ++ "/{x:0>16}", .{id}) catch unreachable;
        root_ready = true;
    }
    return &root_buf;
}

/// `<this process's root>/<rel>`. `rel` is comptime — it keys the static
/// buffer the result lives in, so the slice is valid for the whole process and
/// costs no allocation.
pub fn path(io: std.Io, comptime rel: []const u8) []const u8 {
    comptime checkRel(rel);
    const Site = struct {
        var buf: [ROOT_LEN + 1 + rel.len]u8 = undefined;
        var ready = false;
    };
    lock();
    defer unlock();
    if (!Site.ready) {
        _ = std.fmt.bufPrint(&Site.buf, "{s}/" ++ rel, .{rootLocked(io)}) catch unreachable;
        Site.ready = true;
    }
    return &Site.buf;
}

/// `file://<this process's root>/<rel>` — the same path as `path`, as the URI
/// the language server speaks. Same static-buffer story, so it is also valid
/// for the whole process and allocates nothing.
pub fn uri(io: std.Io, comptime rel: []const u8) []const u8 {
    comptime checkRel(rel);
    const Site = struct {
        var buf: ["file://".len + ROOT_LEN + 1 + rel.len]u8 = undefined;
        var ready = false;
    };
    lock();
    defer unlock();
    if (!Site.ready) {
        _ = std.fmt.bufPrint(&Site.buf, "file://{s}/" ++ rel, .{rootLocked(io)}) catch unreachable;
        Site.ready = true;
    }
    return &Site.buf;
}

/// Remove a scratch subtree, best effort — the opening line and the `defer` of
/// a test that writes one. Nothing outside this process's root can be named,
/// so a typo cannot reach the checkout.
pub fn remove(io: std.Io, comptime rel: []const u8) void {
    std.Io.Dir.cwd().deleteTree(io, path(io, rel)) catch {};
}

/// A `rel` that could escape the per-process root would put the shared path
/// back. Refused at compile time.
fn checkRel(comptime rel: []const u8) void {
    if (rel.len == 0) @compileError("test_scratch: the relative path is empty");
    if (rel[0] == '/' or rel[0] == '\\') @compileError("test_scratch: '" ++ rel ++ "' is absolute — pass a path relative to this process's root");
    if (rel[rel.len - 1] == '/') @compileError("test_scratch: '" ++ rel ++ "' ends in a separator");
    if (rel[0] == '.') @compileError("test_scratch: '" ++ rel ++ "' starts with a dot — the root is already hidden");
    if (std.mem.indexOf(u8, rel, "..") != null) @compileError("test_scratch: '" ++ rel ++ "' walks up out of this process's root");
    if (std.mem.indexOf(u8, rel, "//") != null) @compileError("test_scratch: '" ++ rel ++ "' has an empty segment");
    if (std.mem.indexOfScalar(u8, rel, '{') != null or std.mem.indexOfScalar(u8, rel, '}') != null)
        @compileError("test_scratch: '" ++ rel ++ "' is used as a format string — braces are not allowed");
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "the root is under the shared prefix and carries a per-process segment" {
    const io = std.testing.io;
    const r = root(io);
    try std.testing.expect(std.mem.startsWith(u8, r, PREFIX ++ "/"));
    const id = r[PREFIX.len + 1 ..];
    try std.testing.expectEqual(@as(usize, ID_LEN), id.len);
    for (id) |c| try std.testing.expect(std.ascii.isHex(c));
}

test "the root is drawn once — every call in a process answers the same bytes" {
    const io = std.testing.io;
    try std.testing.expectEqualStrings(root(io), root(io));
    try std.testing.expectEqualStrings(root(io), path(io, "a")[0..ROOT_LEN]);
}

test "a path is the root, a separator and the caller's relative path" {
    const io = std.testing.io;
    defer remove(io, "guard");
    const p = path(io, "guard/ws/botopink.json");
    try std.testing.expectEqualStrings(root(io), p[0..ROOT_LEN]);
    try std.testing.expectEqualStrings("/guard/ws/botopink.json", p[ROOT_LEN..]);
    // Stable across calls: the same call site answers the same buffer.
    try std.testing.expectEqualStrings(p, path(io, "guard/ws/botopink.json"));
}

test "uri is the path behind a file:// scheme" {
    const io = std.testing.io;
    defer remove(io, "guard");
    const u = uri(io, "guard/uri/main.bp");
    try std.testing.expect(std.mem.startsWith(u8, u, "file://"));
    try std.testing.expectEqualStrings(path(io, "guard/uri/main.bp"), u["file://".len..]);
}

test "two relative paths under one root stay live at the same time" {
    const io = std.testing.io;
    defer remove(io, "guard");
    const a = path(io, "guard/two/a.bp");
    const b = path(io, "guard/two/b.bp");
    try std.testing.expect(!std.mem.eql(u8, a, b));
    try std.testing.expect(std.mem.endsWith(u8, a, "/guard/two/a.bp"));
    try std.testing.expect(std.mem.endsWith(u8, b, "/guard/two/b.bp"));
}

test "a tree written under a scratch path is removed by remove()" {
    const io = std.testing.io;
    remove(io, "guard");
    defer remove(io, "guard");
    try std.Io.Dir.cwd().createDirPath(io, path(io, "guard/removable/nested"));
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path(io, "guard/removable/nested/x.bp"), .data = "" });
    try std.Io.Dir.cwd().access(io, path(io, "guard/removable/nested/x.bp"), .{});
    remove(io, "guard/removable");
    try std.testing.expectError(error.FileNotFound, std.Io.Dir.cwd().access(io, path(io, "guard/removable"), .{}));
}
