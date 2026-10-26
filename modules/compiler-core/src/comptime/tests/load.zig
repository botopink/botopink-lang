//! Decisions 780–783, 786, 982 — `comptime compiler.load(path)` through the
//! same `comptime.compile` the CLI runs, over a package held in memory whose
//! loads name packages beside it (`packages/<x>/botopink.json` and
//! `packages/<x>/src/main.bp`): the loaded package's refusals are the answer
//! and never the caller's; a path naming no package is `load-not-a-package`;
//! a compiler with no reader refuses the load (`load-no-reader`); a package
//! that loads itself is refused inside the nested compile (`load-cycle`)
//! instead of compiling forever.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const moduleMod = @import("../../module.zig");

/// The package's files, by path relative to its `botopink.json`.
const files = [_][2][]const u8{
    .{ "packages/fine/botopink.json", "{ \"name\": \"fine\" }" },
    .{
        "packages/fine/src/main.bp",
        \\pub fn main() -> void {}
        \\
    },
    .{ "packages/broken/botopink.json", "{ \"name\": \"broken\" }" },
    .{
        "packages/broken/src/main.bp",
        \\pub fn main() -> void {
        \\    val n: i32 = "not a number";
        \\}
        \\
    },
    .{ "packages/self/botopink.json", "{ \"name\": \"self\" }" },
    .{
        "packages/self/src/main.bp",
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/self") catch { r -> print(r.diagnostics.length); r.module };
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
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = source, .srcPath = "src/main.bp", .root = true, .files = reader }}, io, null);
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
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/broken") catch { r -> print(r.diagnostics.length); r.module };
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
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/broken") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    ;
    const got = (try compileMain(gpa, src, null)) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-no-reader: "));
}

test "decision 982 (2): a path that names no package is `load-not-a-package`" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/nothing") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    ;
    const got = (try compileMain(gpa, src, memory(std.testing.io))) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-not-a-package: "));
    const file = (try compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/fine/src/main.bp") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    , memory(std.testing.io))) orelse return error.TestExpectedRefusal;
    defer gpa.free(file);
    try std.testing.expect(std.mem.indexOf(u8, file, "load-not-a-package: ") != null and std.mem.indexOf(u8, file, "names a file") != null);
}

test "decision 780 (5): a file that loads itself ends — its own load is refused inside the nested compile" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/self") catch { r -> print(r.diagnostics.length); r.module };
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
        \\fn show(m: compiler.Module) -> void {
        \\    print("${m.name()} ${m.path()}");
        \\}
        \\
        \\pub fn main() -> void {
        \\    val fine = comptime compiler.load("packages/fine");
        \\    try fine catch { r -> print(r.diagnostics.length); r.module };
        \\    try comptime compiler.load("packages/broken") catch { r -> show(r.module); r.module };
        \\}
        \\
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) }}, io, null);
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

test "decisions 786, 805 (4), 982 (4): the `Module`'s `name` is the loaded manifest's — none before its load answered — and it carries no target" {
    const loadMod = @import("../load.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const loaded: loadMod.Loaded = .{ .path = "packages/alpha" };
    try std.testing.expectEqualStrings("", loaded.name());
    const e = try loadMod.rewrite(arena, .{ .line = 3, .col = 5 }, loaded, &.{});
    try std.testing.expect(e.* == .call);
}

test "decision 787: a `run()` in an init body brings the loaded file into the program as a package of its own" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    val loaded = comptime compiler.load("packages/fine");
        \\    case loaded {
        \\        Ok(m) -> compiler.init({ -> try m.run() catch { f -> print(f.message) }; });
        \\        Error(r) -> print("refused");
        \\    }
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) }}, io, null);
    defer session.deinit(gpa);
    var main_ok = false;
    var loaded_ok = false;
    for (session.outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) main_ok = o.outcome == .ok;
        if (std.mem.eql(u8, o.name, "bp_load__packages__fine/main")) loaded_ok = o.outcome == .ok;
    }
    try std.testing.expect(main_ok);
    try std.testing.expect(loaded_ok);
}

test "decision 787: a load no `run()` reaches stays out of the program" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    val loaded = comptime compiler.load("packages/fine");
        \\    case loaded {
        \\        Ok(m) -> compiler.init({ -> print(m.path()) });
        \\        Error(r) -> print("refused");
        \\    }
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) }}, io, null);
    defer session.deinit(gpa);
    for (session.outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) try std.testing.expect(o.outcome == .ok);
        try std.testing.expect(!std.mem.startsWith(u8, o.name, "bp_load__"));
    }
}

test "decision 792 (5): a loaded package is named from its path" {
    const loadMod = @import("../load.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    try std.testing.expectEqualStrings("bp_load__packages__fine", try loadMod.packageName(arena, "packages/fine"));
    try std.testing.expect(loadMod.isLoadedPackage("bp_load__packages__fine"));
    try std.testing.expect(!loadMod.isLoadedPackage("lib"));
}

test "decision 787: a read's path is known as written — a literal, or a `+` of literals a `comptime` parameter left" {
    const loadMod = @import("../load.zig");
    const ast = @import("../../ast.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const at: ast.Loc = .{ .line = 1, .col = 1 };
    var a: ast.Expr = .{ .literal = .{ .loc = at, .kind = .{ .stringLit = "packages/" } } };
    var b: ast.Expr = .{ .literal = .{ .loc = at, .kind = .{ .stringLit = "fine" } } };
    var c: ast.Expr = .{ .literal = .{ .loc = at, .kind = .{ .stringLit = "/" } } };
    var ab: ast.Expr = .{ .binaryOp = .{ .loc = at, .op = .add, .lhs = &a, .rhs = &b } };
    const abc: ast.Expr = .{ .binaryOp = .{ .loc = at, .op = .add, .lhs = &ab, .rhs = &c } };
    try std.testing.expectEqualStrings("packages/fine/", (try loadMod.foldedPath(arena, &abc)).?);
    var n: ast.Expr = .{ .identifier = .{ .loc = at, .kind = .{ .ident = "name" } } };
    const an: ast.Expr = .{ .binaryOp = .{ .loc = at, .op = .add, .lhs = &a, .rhs = &n } };
    try std.testing.expect((try loadMod.foldedPath(arena, &an)) == null);
}

test "decision 787: a `Module` a body handed an executor is written back as its maker's call (811 (4))" {
    const loadMod = @import("../load.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena, "{\"name\":\"fine\",\"path\":\"packages/fine\"}", .{});
    try std.testing.expectEqualStrings(
        loadMod.module_fn ++ "(name: \"fine\", path: \"packages/fine\")",
        (try loadMod.recordSource(arena, parsed)).?,
    );
    try std.testing.expectEqualStrings("packages/fine", loadMod.valuePath(parsed, null).?);
    const refused = try std.json.parseFromSliceLeaky(std.json.Value, arena, "{\"module\":{\"name\":\"b\",\"path\":\"packages/b\"},\"diagnostics\":[]}", .{});
    try std.testing.expectEqualStrings("packages/b", loadMod.valuePath(refused, "module").?);
    try std.testing.expect((try loadMod.recordSource(arena, .{ .integer = 3 })) == null);
}

/// Whether compiling `src` (its `main` and every loaded package) succeeds and
/// brings the loaded `packages/fine` into the program.
fn bringsFine(gpa: std.mem.Allocator, src: []const u8) !bool {
    const io = std.testing.io;
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) }}, io, null);
    defer session.deinit(gpa);
    var main_ok = false;
    var loaded_ok = false;
    for (session.outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) main_ok = o.outcome == .ok;
        if (std.mem.eql(u8, o.name, "bp_load__packages__fine/main")) loaded_ok = o.outcome == .ok;
    }
    return main_ok and loaded_ok;
}

test "decision 792 (4), (7): `run()` on a local alias of the captured `Module` in the init body runs the loaded file" {
    try std.testing.expect(try bringsFine(std.testing.allocator,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    val loaded = comptime compiler.load("packages/fine");
        \\    case loaded {
        \\        Ok(m) -> compiler.init({ ->
        \\            val m2 = m;
        \\            val m3 = m2;
        \\            try m3.run() catch { f -> print(f.message) };
        \\        });
        \\        Error(r) -> print("refused");
        \\    }
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    ));
}

test "decision 792 (4): `run()` on a receiver traced to no load of the body is `run-module-untraced`" {
    const gpa = std.testing.allocator;
    const got = (try compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    val loaded = comptime compiler.load("packages/fine");
        \\    case loaded {
        \\        Ok(m) -> compiler.init({ ->
        \\            var m2 = m;
        \\            try m2.run() catch { f -> print(f.message) };
        \\        });
        \\        Error(r) -> print("refused");
        \\    }
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    , memory(std.testing.io))) orelse return error.TestUnexpectedResult;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "run-module-untraced: "));
}

test "decision 789 (4): an expanded function's handled load that returns takes its branch at build" {
    try std.testing.expect(try bringsFine(std.testing.allocator,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\fn runCase(comptime name: string) -> void {
        \\    val loaded = try comptime compiler.load("packages/" + name) catch { r ->
        \\        compiler.init({ -> print("refused " + r.module.path()) });
        \\        return;
        \\    };
        \\    compiler.init({ -> try loaded.run() catch { f -> print(f.message) }; });
        \\}
        \\
        \\comptime {
        \\    runCase("fine");
        \\    runCase("broken");
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    ));
}
