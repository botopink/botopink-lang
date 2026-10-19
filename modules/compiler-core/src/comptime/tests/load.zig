//! Decisions 780–783 — `comptime compiler.load(path)` through the same
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
        \\    try comptime compiler.load("src/cases/self.bp") catch { ds -> print(ds.length); };
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
        \\    try comptime compiler.load("src/cases/broken.bp") catch { ds -> print(ds.length); };
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
        \\    try comptime compiler.load("src/cases/broken.bp") catch { ds -> print(ds.length); };
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
        \\    try comptime compiler.load("src/cases/nothing.bp") catch { ds -> print(ds.length); };
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
        \\    try comptime compiler.load("src/cases/self.bp") catch { ds -> print(ds.length); };
        \\}
        \\
    ;
    const got = try compileMain(gpa, src, memory(std.testing.io));
    defer if (got) |m| gpa.free(m);
    try std.testing.expect(got == null);
}
