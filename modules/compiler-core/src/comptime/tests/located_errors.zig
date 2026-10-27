//! C-21 — every `TypeError` the checker raises carries a location.
//!
//! Walks every single-file conformance cell every target refuses
//! (`conformance/modules/<cell>/src/main.bp` alone, its
//! `snapshot/output/main.snap` holding a `refused` record — the former
//! `tests/language/reject/` cells), and every single-file case of a module's
//! `refused/` package (decision 779: `src/cases/<case>/mod.bp` alone, its
//! `snapshot/output/cases/<case>/mod.snap` refused), and every single-file
//! case of a self-checking module (decision 989: `cases/<case>/src/main.bp`
//! alone, its `== <case>` section of `snapshot/main.snap` refused), through the same `comptime.compile` the CLI
//! runs, and requires each type error to carry a `loc`. An unlocated error renders as a message with no ` --> file:L:C`
//! line and no source excerpt: the reader is told what is wrong and not
//! where. The checker's own unit tests hold the same line from the other side
//! — `assertTypeErrorSnap` and `typeErrorMessage` refuse an unlocated error.
//!
//! A cell that does not reach the checker (a parse error, a CLI refusal such
//! as an unresolved import) is not a type error and is not counted here; the
//! cell's snapshot names its location (`at <file>:<line>:<col>`).

const std = @import("std");
const test_scratch = @import("test_scratch");
const comptimeMod = @import("../../comptime.zig");

const cells_dir = "../../conformance/modules";

/// The cell's one source when it is a single-file cell every target refuses:
/// `src/` holds `main.bp` alone and `snapshot/output/main.snap` a `refused`
/// record. Null otherwise.
fn refusedSingleFile(gpa: std.mem.Allocator, io: std.Io, cells: std.Io.Dir, name: []const u8) !?[]u8 {
    var cell = cells.openDir(io, name, .{}) catch return null;
    defer cell.close(io);
    const snap = cell.readFileAlloc(io, "snapshot/output/main.snap", gpa, .limited(1024 * 1024)) catch return null;
    defer gpa.free(snap);
    if (std.mem.indexOf(u8, snap, "\nrefused ") == null) return null;
    var src = cell.openDir(io, "src", .{ .iterate = true }) catch return null;
    defer src.close(io);
    var it = src.iterate();
    var count: usize = 0;
    while (try it.next(io)) |e| {
        count += 1;
        if (e.kind != .file or !std.mem.eql(u8, e.name, "main.bp")) return null;
    }
    if (count != 1) return null;
    return try src.readFileAlloc(io, "main.bp", gpa, .unlimited);
}

/// The single-file refused cases of a `refused/` package (decision 779), each as
/// `<package>/src/cases/<case>` and its one source `mod.bp`, appended to `out`.
fn refusedCases(gpa: std.mem.Allocator, io: std.Io, cells: std.Io.Dir, name: []const u8, out: *std.ArrayList([2][]u8)) !void {
    var pkg = cells.openDir(io, name, .{}) catch return;
    defer pkg.close(io);
    var cases = pkg.openDir(io, "src/cases", .{ .iterate = true }) catch return;
    defer cases.close(io);
    var it = cases.iterate();
    while (try it.next(io)) |e| {
        if (e.kind != .directory) continue;
        const snap_path = try std.fmt.allocPrint(gpa, "snapshot/output/cases/{s}/mod.snap", .{e.name});
        defer gpa.free(snap_path);
        const snap = pkg.readFileAlloc(io, snap_path, gpa, .limited(1024 * 1024)) catch continue;
        defer gpa.free(snap);
        if (std.mem.indexOf(u8, snap, "\nrefused ") == null) continue;
        var case = try cases.openDir(io, e.name, .{ .iterate = true });
        defer case.close(io);
        var files = case.iterate();
        var sources: usize = 0;
        while (try files.next(io)) |f| {
            if (f.kind != .file or !std.mem.eql(u8, f.name, "docs.md")) sources += 1;
        }
        if (sources != 1) continue;
        const src = case.readFileAlloc(io, "mod.bp", gpa, .unlimited) catch continue;
        try out.append(gpa, .{ try std.fmt.allocPrint(gpa, "{s}/src/cases/{s}", .{ name, e.name }), src });
    }
}

/// The single-file refused cases of a self-checking module (decision 989):
/// each `== <case>` section of `<module>/snapshot/main.snap` (every target's,
/// no ` on <t>`) holding a `refused` record, whose `cases/<case>/src/` holds
/// `main.bp` alone — appended to `out` as `<module>/cases/<case>` and its source.
/// The module's leftover full cells (`<module>/cells/<case>/`) are read as cells.
fn refusedModuleCases(gpa: std.mem.Allocator, io: std.Io, cells: std.Io.Dir, name: []const u8, out: *std.ArrayList([2][]u8)) !void {
    var module = cells.openDir(io, name, .{}) catch return;
    defer module.close(io);
    if (module.openDir(io, "cells", .{ .iterate = true })) |cd| {
        var cells_of = cd;
        defer cells_of.close(io);
        var it = cells_of.iterate();
        while (try it.next(io)) |e| {
            if (e.kind != .directory) continue;
            if (try refusedSingleFile(gpa, io, cells_of, e.name)) |src|
                try out.append(gpa, .{ try std.fmt.allocPrint(gpa, "{s}/cells/{s}", .{ name, e.name }), src });
        }
    } else |_| {}
    const snap = module.readFileAlloc(io, "snapshot/main.snap", gpa, .limited(16 * 1024 * 1024)) catch return;
    defer gpa.free(snap);
    var section: ?[]const u8 = null;
    var taken: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, snap, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "== ")) {
            const head = line[3..];
            section = if (std.mem.indexOf(u8, head, " on ") == null) head else null;
            continue;
        }
        const case = section orelse continue;
        if (!std.mem.startsWith(u8, line, "refused ")) continue;
        if (taken) |t| if (std.mem.eql(u8, t, case)) continue;
        taken = case;
        const src_rel = try std.fmt.allocPrint(gpa, "cases/{s}/src", .{case});
        defer gpa.free(src_rel);
        var src = module.openDir(io, src_rel, .{ .iterate = true }) catch continue;
        defer src.close(io);
        var it = src.iterate();
        var count: usize = 0;
        var alone = true;
        while (try it.next(io)) |e| {
            count += 1;
            if (e.kind != .file or !std.mem.eql(u8, e.name, "main.bp")) alone = false;
        }
        if (!alone or count != 1) continue;
        const text = try src.readFileAlloc(io, "main.bp", gpa, .unlimited);
        try out.append(gpa, .{ try std.fmt.allocPrint(gpa, "{s}/cases/{s}", .{ name, case }), text });
    }
}

/// Every cell under `dir` as a path relative to it: a directory holding a
/// `botopink.json` (a module keeps its cells under `<module>/cells/`, its packages
/// at `<module>/run/` and `<module>/refused/`; a decision's `draft/` is no cell).
fn collectCells(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, prefix: []const u8, out: *std.ArrayList([]u8)) !void {
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        if (entry.kind != .directory or std.mem.eql(u8, entry.name, "draft")) continue;
        const rel = if (prefix.len == 0) try gpa.dupe(u8, entry.name) else try std.fmt.allocPrint(gpa, "{s}/{s}", .{ prefix, entry.name });
        var sub = try dir.openDir(io, entry.name, .{ .iterate = true });
        defer sub.close(io);
        if (sub.access(io, "botopink.json", .{})) {
            try out.append(gpa, rel);
        } else |_| {
            defer gpa.free(rel);
            try collectCells(gpa, io, sub, rel, out);
        }
    }
}

test "C-21: every type error a reject cell raises carries a location" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var dir = try std.Io.Dir.cwd().openDir(io, cells_dir, .{ .iterate = true });
    defer dir.close(io);

    var names: std.ArrayList([]u8) = .empty;
    defer {
        for (names.items) |n| gpa.free(n);
        names.deinit(gpa);
    }
    try collectCells(gpa, io, dir, "", &names);
    std.mem.sort([]u8, names.items, {}, struct {
        fn lt(_: void, a: []u8, b: []u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);

    const build_root = test_scratch.path(io, "comptime/located_errors");

    var type_errors: usize = 0;
    var unlocated: std.ArrayList(u8) = .empty;
    defer unlocated.deinit(gpa);
    var walked: usize = 0;
    var sources: std.ArrayList([2][]u8) = .empty;
    defer {
        for (sources.items) |s| {
            gpa.free(s[0]);
            gpa.free(s[1]);
        }
        sources.deinit(gpa);
    }
    for (names.items) |name| {
        if (try refusedSingleFile(gpa, io, dir, name)) |src| {
            try sources.append(gpa, .{ try gpa.dupe(u8, name), src });
        } else {
            try refusedCases(gpa, io, dir, name, &sources);
            try refusedModuleCases(gpa, io, dir, name, &sources);
        }
    }
    for (sources.items) |s| {
        const name = s[0];
        const src = s[1];
        walked += 1;
        var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src }}, io, build_root);
        defer session.deinit(gpa);
        for (session.outputs.items) |output| switch (output.outcome) {
            .typeError => |te| {
                type_errors += 1;
                if (te.loc == null) {
                    const msg = try te.message(gpa);
                    defer gpa.free(msg);
                    try unlocated.print(gpa, "  {s}: {s}\n", .{ name, msg });
                }
            },
            else => {},
        };
    }
    // The corpus is the conformance suite's refusals; an empty walk measures nothing.
    try std.testing.expect(walked > 100);
    if (unlocated.items.len > 0) {
        std.debug.print("\nC-21: unlocated type errors ({d} type errors walked):\n{s}", .{ type_errors, unlocated.items });
        return error.UnlocatedTypeError;
    }
    try std.testing.expect(type_errors > 50);
}

// An embedded std module is parsed before any program module is read, from
// the source the build embedded. One that does not parse — a reserved word
// used as a name in a `libs/std/src` file — reached the CLI as
// `compilation failed` / `UnexpectedToken`, with no file and no line. It is
// located at the std file it was built from, rendered as any module's parse
// error is, and the build stops with `error.EmbeddedStdRefused`.
test "an embedded std module that does not parse is located at its libs/std/src file" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const src =
        \\pub fn ok() -> i32 {
        \\    return 1;
        \\}
        \\
        \\fn reservedProbe(from: string) -> string {
        \\    return from;
        \\}
        \\
    ;
    var lx = @import("../../lexer.zig").Lexer.init(src);
    var p = @import("../../parser.zig").Parser.init(try lx.scanAll(a));
    try std.testing.expectError(error.UnexpectedToken, p.parse(a));
    const text = try comptimeMod.embeddedStdDiagnostic(a, "std/path", src, null, &p);
    try std.testing.expect(std.mem.indexOf(u8, text, "error[reserved-word-as-name]") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "--> libs/std/src/path.bp:5:18") != null);
    try std.testing.expectError(error.EmbeddedStdRefused, comptimeMod.parseEmbeddedStd(a, "std/path", src));
}

// Decision 451 (3) — a raise inside a decorator body or a `comptime` body is
// located at the call that raised (`random.float()`, a `@panic` in a
// function the body calls), not at the annotation or the `comptime`
// expression that ran it; the calls of the chain are the `called from` lines
// (decision 532), the last one the annotation or the `comptime`.
test "a raise inside a decorator or a comptime is located at the call that raised" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const build_root = test_scratch.path(io, "comptime/raise_location");
    const cases = [_]struct { src: []const u8, line: u32, col: u32, entry: [2]u32 }{
        .{
            .src =
            \\import {io.random} from "std";
            \\
            \\fn drawn(syntax decl: unknown) -> void {
            \\    val x = random.float();
            \\    @emit("pub fn label() -> string { return \"" + compiler.name(decl)! + " ${x}\"; }");
            \\}
            \\
            \\#[drawn]
            \\type Point(x: i32, y: i32)
            \\
            \\pub fn main() -> void {
            \\    print(label());
            \\}
            \\
            \\import {compiler} from "std";
            \\
            \\import {io.terminal.print} from "std";
            ,
            .line = 4,
            .col = 13,
            .entry = .{ 8, 3 },
        },
        .{
            .src =
            \\import {io.random} from "std";
            \\
            \\pub fn main() -> void {
            \\    val atBuild = comptime random.float();
            \\    print(atBuild);
            \\}
            \\
            \\import {io.terminal.print} from "std";
            ,
            .line = 4,
            .col = 28,
            .entry = .{ 4, 19 },
        },
        // Any raise, not only a std refusal: a `@panic` in a function of this
        // module the body calls is located at the `@panic`, not at the call
        // of the function, the annotation or the `comptime`.
        .{
            .src =
            \\fn checked(n: i32) -> i32 {
            \\    if (n > 1) {
            \\        panic("too big");
            \\    }
            \\    return n;
            \\}
            \\
            \\fn sized(syntax decl: unknown) -> void {
            \\    val n = checked(2);
            \\    @emit("pub fn label() -> string { return \"" + compiler.name(decl)! + " ${n}\"; }");
            \\}
            \\
            \\#[sized]
            \\type Point(x: i32, y: i32)
            \\
            \\pub fn main() -> void {
            \\    print(label());
            \\}
            \\
            \\import {compiler} from "std";
            \\
            \\import {io.terminal.print, failure.panic} from "std";
            ,
            .line = 3,
            .col = 9,
            .entry = .{ 13, 3 },
        },
        .{
            .src =
            \\fn checked(n: i32) -> i32 {
            \\    if (n > 1) {
            \\        panic("too big");
            \\    }
            \\    return n;
            \\}
            \\
            \\pub fn main() -> void {
            \\    val atBuild = comptime checked(3);
            \\    print(atBuild);
            \\}
            \\
            \\import {io.terminal.print, failure.panic} from "std";
            ,
            .line = 3,
            .col = 9,
            .entry = .{ 9, 19 },
        },
    };
    for (cases) |c| {
        var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = c.src }}, io, build_root);
        defer session.deinit(gpa);
        var seen = false;
        for (session.outputs.items) |output| switch (output.outcome) {
            .typeError => |te| {
                seen = true;
                const loc = te.loc.?;
                try std.testing.expectEqual(c.line, loc.line);
                try std.testing.expectEqual(c.col, loc.col);
                // Decision 532: the program's frame that ran the build — the
                // annotation, the `comptime` — is the last `called from` line.
                try std.testing.expect(te.frames.len >= 1);
                const last = te.frames[te.frames.len - 1];
                try std.testing.expectEqual(c.entry, [2]u32{ @intCast(last.loc.line), @intCast(last.loc.col) });
            },
            else => {},
        };
        try std.testing.expect(seen);
    }
}

// The decorator emit memo (`template_eval.cachedEmit`) is process-wide and
// keyed by the declarations' formatted source, which drops positions; a
// located function's module bakes its frames (`'__bp_push'(File, Line, Col, R)`) in. One
// decorator compiled at two positions in one process — the conformance cell
// `decorator_random_float_unseeded` walked by C-21 and the first case above,
// when one test process runs both — must locate each raise at its own build's
// line, never at the earlier build's.
test "a raise inside a decorator is located in its own build when an earlier build put the same decorator elsewhere" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    const build_root = test_scratch.path(io, "comptime/raise_location_moved");
    const decorated =
        \\import {io.random} from "std";
        \\
        \\fn drawn(syntax decl: unknown) -> void {
        \\    val x = random.float();
        \\    @emit("pub fn moved() -> string { return \"" + compiler.name(decl)! + " ${x}\"; }");
        \\}
        \\
        \\#[drawn]
        \\type Point(x: i32, y: i32)
        \\
        \\pub fn main() -> void {
        \\    print(moved());
        \\}
        \\
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    ;
    const cases = [_]struct { src: []const u8, line: u32 }{
        .{ .src = "\n\n\n" ++ decorated, .line = 7 },
        .{ .src = decorated, .line = 4 },
        .{ .src = "\n" ++ decorated, .line = 5 },
    };
    for (cases) |c| {
        var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = c.src }}, io, build_root);
        defer session.deinit(gpa);
        var seen = false;
        for (session.outputs.items) |output| switch (output.outcome) {
            .typeError => |te| {
                seen = true;
                try std.testing.expectEqual(c.line, te.loc.?.line);
                try std.testing.expectEqual(@as(u32, 13), te.loc.?.col);
            },
            else => {},
        };
        try std.testing.expect(seen);
    }
}
