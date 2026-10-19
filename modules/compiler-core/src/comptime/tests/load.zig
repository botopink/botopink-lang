//! Decisions 780–783, 786 — `comptime compiler.load(path)` through the same
//! `comptime.compile` the CLI runs, over a package held in memory: the
//! loaded file's refusals are the answer and never the caller's; a compiler
//! with no reader refuses the load (`load-no-reader`); a file that loads
//! itself is refused inside the nested compile (`load-cycle`) instead of
//! compiling forever.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const moduleMod = @import("../../module.zig");

/// The package's files, by path relative to its `botopink.json`.
const files = [_][2][]const u8{
    .{
        "src/cases/fine.bp",
        \\pub fn main() {}
        \\
    },
    .{
        "src/cases/broken.bp",
        \\pub fn main() {
        \\    val n: i32 = "not a number";
        \\}
        \\
    },
    .{
        "src/cases/self.bp",
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() {
        \\    try comptime compiler.load("src/cases/self.bp") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    },
};

fn readMemory(io: std.Io, arena: std.mem.Allocator, root: []const u8, rel: []const u8) moduleMod.PackageFiles.ReadError![]const u8 {
    _ = io;
    _ = root;
    for (files) |f| if (std.mem.eql(u8, f[0], rel)) return arena.dupe(u8, f[1]) catch error.OutOfMemory;
    return error.FileNotFound;
}

fn memory(io: std.Io) moduleMod.PackageFiles {
    return .{ .root = "", .io = io, .read = readMemory };
}

/// The one module's outcome: null when it compiled, else the message of its
/// type error (`error.Unexpected` for any other refusal).
fn compileMain(gpa: std.mem.Allocator, source: []const u8, reader: ?moduleMod.PackageFiles) !?[]u8 {
    const io = std.testing.io;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = source, .srcPath = "src/main.bp", .root = true, .files = reader }}, io, null, null);
    defer session.deinit(gpa);
    for (session.outputs.items) |o| if (std.mem.eql(u8, o.name, "main")) switch (o.outcome) {
        .ok => return null,
        .typeError => |te| return try te.message(gpa),
        else => return error.Unexpected,
    };
    return error.Unexpected;
}

test "decision 780: a loaded file's refusals are the answer, never a refusal of the program that loads it" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() {
        \\    try comptime compiler.load("src/cases/broken.bp") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    ;
    const got = try compileMain(gpa, src, memory(std.testing.io));
    defer if (got) |m| gpa.free(m);
    try std.testing.expect(got == null);
}

test "decision 780: a compiler handed no reader refuses the load, `load-no-reader`" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() {
        \\    try comptime compiler.load("src/cases/broken.bp") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    ;
    const got = (try compileMain(gpa, src, null)) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-no-reader: "));
}

test "decision 780: a path that names no file of the package is `load-file-missing`" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() {
        \\    try comptime compiler.load("src/cases/nothing.bp") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    ;
    const got = (try compileMain(gpa, src, memory(std.testing.io))) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-file-missing: "));
}

test "decision 780 (5): a file that loads itself ends — its own load is refused inside the nested compile" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() {
        \\    try comptime compiler.load("src/cases/self.bp") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    ;
    const got = try compileMain(gpa, src, memory(std.testing.io));
    defer if (got) |m| gpa.free(m);
    try std.testing.expect(got == null);
}

test "decision 786: the answer is the loaded file's `Module` on both sides" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\fn show(m: compiler.Module) {
        \\    print("${m.name} ${m.path} ${m.target}");
        \\}
        \\
        \\pub fn main() {
        \\    val fine = comptime compiler.load("src/cases/fine.bp");
        \\    try fine catch { r -> print(r.diagnostics.length); r.module };
        \\    try comptime compiler.load("src/cases/broken.bp") catch { r -> show(r.module); r.module };
        \\}
        \\
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) }}, io, null, null);
    defer session.deinit(gpa);
    for (session.outputs.items) |o| if (std.mem.eql(u8, o.name, "main")) switch (o.outcome) {
        .ok => return,
        .typeError => |te| {
            const m = try te.message(gpa);
            defer gpa.free(m);
            std.debug.print("{s}\n", .{m});
            return error.TestUnexpectedRefusal;
        },
        else => return error.TestUnexpectedRefusal,
    };
    return error.TestMainMissing;
}

test "decision 786: the `Module`'s `name` is the file's directory, its `target` std's `Target` variant" {
    const loadMod = @import("../load.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    try std.testing.expectEqualStrings("Wasm", loadMod.targetVariant("wasm"));
    try std.testing.expectEqualStrings("Wasm", loadMod.targetVariant("wasm.browser"));
    try std.testing.expectEqualStrings("Erlang", loadMod.targetVariant("erlang"));
    try std.testing.expectEqualStrings("Beam", loadMod.targetVariant("beam"));
    try std.testing.expectEqualStrings("Node", loadMod.targetVariant("commonJS"));
    try std.testing.expectEqualStrings("Node", loadMod.targetVariant(null));
    const loaded: loadMod.Loaded = .{ .path = "src/cases/alpha/mod.bp", .target = "erlang" };
    try std.testing.expectEqualStrings("alpha", loaded.name());
    const e = try loadMod.rewrite(arena, .{ .line = 3, .col = 5 }, loaded, &.{});
    try std.testing.expect(e.* == .call);
}

test "decision 786: a driver's own target wins over the lookup name — a BEAM build is `Beam`" {
    const loadMod = @import("../load.zig");
    const saved = loadMod.build_target;
    defer loadMod.build_target = saved;
    loadMod.build_target = "beam";
    try std.testing.expectEqualStrings("Beam", loadMod.targetVariant("erlang"));
    loadMod.build_target = "commonJS";
    try std.testing.expectEqualStrings("Node", loadMod.targetVariant("node"));
}
