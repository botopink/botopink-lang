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

/// A loaded package's `main.bp` that loads its own `cases/inner` and runs it.
const nested_runner =
    \\import {compiler, io.terminal.print} from "std";
    \\
    \\var got: string = "";
    \\
    \\comptime {
    \\    val loaded = comptime compiler.load("cases/inner");
    \\    case loaded {
    \\        Ok(m) -> compiler.init({ ->
    \\            val r = m.run();
    \\            got = case r {
    \\                Ok(t) -> t;
    \\                Error(f) -> f.message;
    \\            };
    \\        });
    \\        Error(r) -> compiler.init({ -> got = "refused"; });
    \\    }
    \\}
    \\
    \\pub fn main() -> void {
    \\    print(got);
    \\}
    \\
;

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
    .{ "packages/tested/botopink.json", "{ \"name\": \"tested\" }" },
    .{
        "packages/tested/src/main.bp",
        \\fn double(n: i32) -> i32 {
        \\    return n * 2;
        \\}
        \\
        \\test "doubles" {
        \\    assert double(2) == 4;
        \\}
        \\
    },
    .{ "packages/self/botopink.json", "{ \"name\": \"self\" }" },
    .{ "packages/printed/botopink.json", "{ \"name\": \"printed\" }" },
    .{
        "packages/printed/src/main.bp",
        \\import {io.terminal.print} from "std";
        \\
        \\comptime {
        \\    print("first");
        \\    print("second");
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    },
    .{ "packages/refused_after_print/botopink.json", "{ \"name\": \"refused_after_print\" }" },
    .{
        "packages/refused_after_print/src/main.bp",
        \\import {io.terminal.print} from "std";
        \\
        \\comptime {
        \\    print("before");
        \\}
        \\
        \\pub fn main() -> i32 {
        \\    return "not a number";
        \\}
        \\
    },
    .{ "packages/raise_in_helper/botopink.json", "{ \"name\": \"raise_in_helper\" }" },
    .{
        "packages/raise_in_helper/src/helper.bp",
        \\import {compiler, failure.panic} from "std";
        \\
        \\pub fn shout(syntax t: string) -> string {
        \\    val s = compiler.text(t);
        \\    panic("boom " + s);
        \\    return compiler.build("\"" + s + "\"");
        \\}
        \\
    },
    .{
        "packages/raise_in_helper/src/main.bp",
        \\mod helper;
        \\
        \\import {helper.shout};
        \\import {io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    print(shout @`hi`);
        \\}
        \\
    },
    .{ "packages/bad_target/botopink.json", "{ \"name\": \"bad_target\",\n  \"targets\": [\"jvm\"] }" },
    .{ "packages/bad_target/src/main.bp", "pub fn main() -> void {}\n" },
    // A loaded package that loads and runs its own (the conformance suite's
    // root over its modules): two of them each load a `cases/inner` of their own.
    .{ "packages/outer/botopink.json", "{ \"name\": \"outer\" }" },
    .{ "packages/outer/src/main.bp", nested_runner },
    .{ "packages/outer/cases/inner/botopink.json", "{ \"name\": \"inner\" }" },
    .{ "packages/outer/cases/inner/src/main.bp", "import {io.terminal.print} from \"std\";\n\npub fn main() -> void {\n    print(\"outer's\");\n}\n" },
    .{ "packages/other/botopink.json", "{ \"name\": \"other\" }" },
    .{ "packages/other/src/main.bp", nested_runner },
    .{ "packages/other/cases/inner/botopink.json", "{ \"name\": \"inner\" }" },
    .{ "packages/other/cases/inner/src/main.bp", "import {io.terminal.print} from \"std\";\n\npub fn main() -> void {\n    print(\"other's\");\n}\n" },
    .{ "packages/bad_json/botopink.json", "{ \"name\": " },
    .{ "packages/bad_json/src/main.bp", "pub fn main() -> void {}\n" },

    // Decision 993 (1) — a manifest naming its `src` and `entry`.
    .{ "packages/lib_root/botopink.json", "{ \"name\": \"lib_root\", \"src\": \"lib/\", \"entry\": \"root.bp\" }" },
    .{ "packages/lib_root/lib/root.bp", "pub fn main() -> void {}\n" },
    .{ "packages/lib_root/src/main.bp", "pub fn main() -> i32 {\n    return \"never compiled\";\n}\n" },
    .{ "packages/missing_entry/botopink.json", "{ \"name\": \"missing_entry\", \"src\": \"lib/\", \"entry\": \"root.bp\" }" },
    .{ "packages/missing_entry/src/main.bp", "pub fn main() -> void {}\n" },
    // Decision 993 (1) — a package with a dependency of its own.
    .{ "packages/uses_greet/botopink.json", "{ \"name\": \"uses_greet\", \"dependencies\": { \"greet\": { \"path\": \"../greet\" } } }" },
    .{
        "packages/uses_greet/src/main.bp",
        \\import {hello} from "greet";
        \\
        \\pub fn main() -> void {
        \\    val s: string = hello();
        \\}
        \\
    },

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
    // A package a resolver answered outside the caller (`/elsewhere/<dir>`,
    // decision 993 (2)) is the memory's `<dir>`.
    const outside = "/elsewhere/";
    const key = if (std.mem.startsWith(u8, root, outside))
        std.fs.path.join(arena, &.{ root[outside.len..], rel }) catch return error.OutOfMemory
    else
        rel;
    for (files) |f| if (std.mem.eql(u8, f[0], key)) return arena.dupe(u8, f[1]) catch error.OutOfMemory;
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
        \\        Ok(m) -> compiler.init({ -> print(try m.run() catch { f -> f.message }); });
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

test "decision 787: a loaded package that loads and runs its own — each nested load its own package, compiled before the package that runs it" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    val a = comptime compiler.load("packages/outer");
        \\    case a {
        \\        Ok(m) -> compiler.init({ -> print(try m.run() catch { f -> f.message }); });
        \\        Error(r) -> print("refused");
        \\    }
        \\    val b = comptime compiler.load("packages/other");
        \\    case b {
        \\        Ok(m) -> compiler.init({ -> print(try m.run() catch { f -> f.message }); });
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
    const names = [_][]const u8{ "bp_load__packages__outer__cases__inner/main", "bp_load__packages__outer/main", "bp_load__packages__other__cases__inner/main", "bp_load__packages__other/main", "main" };
    var at = [_]?usize{null} ** names.len;
    for (session.outputs.items, 0..) |o, i| {
        for (names, 0..) |n, k| if (std.mem.eql(u8, o.name, n)) {
            try std.testing.expect(o.outcome == .ok);
            at[k] = i;
        };
    }
    for (at) |i| try std.testing.expect(i != null);
    // A nested package compiles before the loaded package that runs it.
    try std.testing.expect(at[0].? < at[1].?);
    try std.testing.expect(at[2].? < at[3].?);
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
    // A resolver's directory is a whole path (decision 993 (2)): every byte
    // that is no identifier's is escaped, so the name stays one.
    try std.testing.expectEqualStrings("bp_load____w__botopink_x2dlang___x2etasks__css", try loadMod.packageName(arena, "/w/botopink-lang/.tasks/css"));
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
        loadMod.module_fn ++ "(name: \"fine\", path: \"packages/fine\", buildOutput: \"\")",
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
        \\            print(try m3.run() catch { f -> f.message });
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
        \\            print(try m2.run() catch { f -> f.message });
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
        \\    compiler.init({ -> print(try loaded.run() catch { f -> f.message }); });
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

/// Load `path` directly (`load.compileFile`) inside a compile's state, after
/// a first compile has readied std's template, and hand `check` the entry.
fn withLoaded(path: []const u8, check: *const fn (entry: @import("../load.zig").Entry) anyerror!void) !void {
    const loadMod = @import("../load.zig");
    const gpa = std.testing.allocator;
    const got = try compileMain(gpa, "pub fn main() -> void {}\n", null);
    defer if (got) |m| gpa.free(m);
    const saved = try loadMod.enter();
    defer loadMod.leave(saved);
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const io = std.testing.io;
    const answer = try loadMod.compileFile(arena_state.allocator(), .{ .path = path, .files = memory(io), .io = io, .build_root = null });
    try std.testing.expect(answer == .diagnostics);
    try check(loadMod.entryOf(path).?);
}

test "decision 989 (4): a loaded package's build prints are its `buildOutput`, in order, a line each" {
    try withLoaded("packages/printed", struct {
        fn check(e: @import("../load.zig").Entry) anyerror!void {
            try std.testing.expectEqual(@as(usize, 0), e.diagnostics.len);
            try std.testing.expectEqualStrings("first\nsecond\n", e.build_output);
        }
    }.check);
}

test "decisions 904, 989 (4): a refused package keeps what its build printed before the refusal" {
    try withLoaded("packages/refused_after_print", struct {
        fn check(e: @import("../load.zig").Entry) anyerror!void {
            try std.testing.expectEqual(@as(usize, 1), e.diagnostics.len);
            try std.testing.expectEqualStrings("before\n", e.build_output);
        }
    }.check);
}

test "decisions 532, 989 (4): a raise at build in a helper file lists the calls it crossed, `<file>:<line>:<col>`, innermost first" {
    try withLoaded("packages/raise_in_helper", struct {
        fn check(e: @import("../load.zig").Entry) anyerror!void {
            try std.testing.expectEqual(@as(usize, 1), e.diagnostics.len);
            const d = e.diagnostics[0];
            try std.testing.expectEqualStrings("src/helper.bp", d.file);
            try std.testing.expectEqual(@as(usize, 1), d.from.len);
            try std.testing.expectEqualStrings("src/main.bp:7:11", d.from[0]);
        }
    }.check);
    try withLoaded("packages/broken", struct {
        fn check(e: @import("../load.zig").Entry) anyerror!void {
            try std.testing.expectEqual(@as(usize, 0), e.diagnostics[0].from.len);
        }
    }.check);
}

test "decision 989 (4): a manifest the compiler refuses is one `Diagnostic` of `botopink.json`, never the caller's" {
    try withLoaded("packages/bad_target", struct {
        fn check(e: @import("../load.zig").Entry) anyerror!void {
            try std.testing.expectEqual(@as(usize, 1), e.diagnostics.len);
            const d = e.diagnostics[0];
            try std.testing.expectEqualStrings("botopink.json", d.file);
            try std.testing.expectEqualStrings("unknown target `jvm` (commonJS, erlang, beam, wasm)", d.message);
            try std.testing.expectEqual(@as(usize, 2), d.line);
            try std.testing.expectEqual(@as(usize, 15), d.column);
        }
    }.check);
    try withLoaded("packages/bad_json", struct {
        fn check(e: @import("../load.zig").Entry) anyerror!void {
            try std.testing.expectEqual(@as(usize, 1), e.diagnostics.len);
            try std.testing.expectEqualStrings("botopink.json", e.diagnostics[0].file);
            try std.testing.expectEqual(@as(usize, 0), e.diagnostics[0].line);
        }
    }.check);
}

/// A `run()` of the package at `path` in an init body, compiled with `extra`
/// modules before the caller's own: whether the caller and the loaded
/// package's module `loaded` compiled.
fn runLoaded(gpa: std.mem.Allocator, path: []const u8, loaded: []const u8, extra: []const moduleMod.Module) !struct { main_ok: bool, loaded_ok: bool } {
    const io = std.testing.io;
    const src = try std.fmt.allocPrint(gpa,
        \\import {{compiler, io.terminal.print}} from "std";
        \\
        \\comptime {{
        \\    val loaded = comptime compiler.load("{s}");
        \\    case loaded {{
        \\        Ok(m) -> compiler.init({{ -> print(try m.run() catch {{ f -> f.message }}); }});
        \\        Error(r) -> print("refused");
        \\    }}
        \\}}
        \\
        \\pub fn main() -> void {{}}
        \\
    , .{path});
    defer gpa.free(src);
    var modules: std.ArrayListUnmanaged(moduleMod.Module) = .empty;
    defer modules.deinit(gpa);
    try modules.appendSlice(gpa, extra);
    try modules.append(gpa, .{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) });
    var session = try comptimeMod.compile(gpa, modules.items, io, null);
    defer session.deinit(gpa);
    var main_ok = false;
    var loaded_ok = false;
    for (session.outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) main_ok = o.outcome == .ok;
        if (std.mem.eql(u8, o.name, loaded)) loaded_ok = o.outcome == .ok;
    }
    return .{ .main_ok = main_ok, .loaded_ok = loaded_ok };
}

test "decision 993 (1): a loaded package compiles from the entry its manifest's `src` and `entry` name" {
    const got = try runLoaded(std.testing.allocator, "packages/lib_root", "bp_load__packages__lib_root/root", &.{});
    try std.testing.expect(got.main_ok);
    try std.testing.expect(got.loaded_ok);
}

test "decision 993 (1): a manifest naming an entry that is not there is `load-not-a-package`, naming it" {
    const gpa = std.testing.allocator;
    const got = (try compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/missing_entry") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    , memory(std.testing.io))) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-not-a-package: "));
    try std.testing.expect(std.mem.indexOf(u8, got, "names a package with no `lib/root.bp`") != null);
}

/// The caller's own `greet`, the fallback with no resolver.
const greet_module: moduleMod.Module = .{ .path = "greet/root", .source = "pub fn hello() -> string {\n    return \"hi\";\n}\n", .srcPath = "src/root.bp", .package = "greet" };

test "decision 993 (1): with no resolver, a loaded package's dependency is the caller's module of that name" {
    const loadMod = @import("../load.zig");
    try std.testing.expect(loadMod.resolver == null);
    const got = try runLoaded(std.testing.allocator, "packages/uses_greet", "bp_load__packages__uses_greet/main", &.{greet_module});
    try std.testing.expect(got.main_ok);
    try std.testing.expect(got.loaded_ok);
}

const FakeResolver = struct {
    var calls: usize = 0;
    var refuse = false;
    fn resolve(_: ?*anyopaque, _: std.Io, dir: []const u8) anyerror!@import("../load.zig").Resolution {
        calls += 1;
        std.debug.assert(std.mem.endsWith(u8, dir, "packages/uses_greet"));
        if (refuse) return .{ .refused = .{ .message = "dependency \"greet\" not found", .line = 1, .column = 40 } };
        return .{ .ok = .{ .modules = &.{greet_module} } };
    }
};

test "decision 993 (1): with a resolver, a loaded package's own dependencies join the program its `run()` compiles" {
    const loadMod = @import("../load.zig");
    loadMod.resolver = .{ .resolve = FakeResolver.resolve };
    defer loadMod.resolver = null;
    FakeResolver.calls = 0;
    FakeResolver.refuse = false;
    // The caller holds no `greet`: the package's own comes from the resolver.
    const got = try runLoaded(std.testing.allocator, "packages/uses_greet", "bp_load__packages__uses_greet/main", &.{});
    try std.testing.expect(got.main_ok);
    try std.testing.expect(got.loaded_ok);
    try std.testing.expect(FakeResolver.calls > 0);
}

test "decision 993 (1): a resolver's refusal is the loaded package's `Diagnostic` at `botopink.json`, never the caller's" {
    const gpa = std.testing.allocator;
    const loadMod = @import("../load.zig");
    loadMod.resolver = .{ .resolve = FakeResolver.resolve };
    defer loadMod.resolver = null;
    FakeResolver.refuse = true;
    defer FakeResolver.refuse = false;
    const got = try compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/uses_greet") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    , memory(std.testing.io));
    defer if (got) |m| gpa.free(m);
    try std.testing.expect(got == null);
}

// ── compiler.load(package: …) (decision 993 (2)) ─────────────────────────────

const NameResolver = struct {
    const Mode = enum { under, outside, unknown, ambiguous };
    var mode: Mode = .under;
    var asked_buf: [64]u8 = undefined;
    var asked: []const u8 = "";
    fn byName(_: ?*anyopaque, _: std.Io, name: []const u8, _: []const u8) anyerror!@import("../load.zig").NameResolution {
        asked = std.fmt.bufPrint(&asked_buf, "{s}", .{name}) catch "";
        return switch (mode) {
            .under => .{ .found = .{ .dir = "/work/packages/uses_greet", .rel = "packages/uses_greet" } },
            .outside => .{ .found = .{ .dir = "/elsewhere/packages/uses_greet" } },
            .unknown => .unknown,
            .ambiguous => .{ .refused = "\"uses_greet\" is declared by two libraries: /a/uses_greet and /b/uses_greet — a name resolves to one library; rename one of them" },
        };
    }
};

fn loadByName(gpa: std.mem.Allocator, mode: NameResolver.Mode) !?[]u8 {
    const loadMod = @import("../load.zig");
    loadMod.resolver = .{ .resolve = FakeResolver.resolve, .by_name = NameResolver.byName };
    defer loadMod.resolver = null;
    NameResolver.mode = mode;
    FakeResolver.refuse = false;
    return compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load(package: "uses_greet") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    , memory(std.testing.io));
}

test "decision 993 (2): a name the resolver finds under the caller loads that directory as a package" {
    const got = try loadByName(std.testing.allocator, .under);
    defer if (got) |m| std.testing.allocator.free(m);
    try std.testing.expect(got == null);
    try std.testing.expectEqualStrings("uses_greet", NameResolver.asked);
}

test "decision 993 (2): a name the resolver finds outside the caller loads the directory it answered" {
    const got = try loadByName(std.testing.allocator, .outside);
    defer if (got) |m| std.testing.allocator.free(m);
    try std.testing.expect(got == null);
}

test "decision 993 (2): a name no library declares is `load-package-unknown`, naming it and `botopink packages --list`" {
    const got = (try loadByName(std.testing.allocator, .unknown)) orelse return error.TestExpectedRefusal;
    defer std.testing.allocator.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-package-unknown: "));
    try std.testing.expect(std.mem.indexOf(u8, got, "package: \"uses_greet\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, got, "botopink packages --list") != null);
}

test "decision 993 (2): a name two libraries declare is `load-package-refused`, with the dependency resolution's text" {
    const got = (try loadByName(std.testing.allocator, .ambiguous)) orelse return error.TestExpectedRefusal;
    defer std.testing.allocator.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-package-refused: "));
    try std.testing.expect(std.mem.indexOf(u8, got, "is declared by two libraries") != null);
}

test "decision 993 (2): with no resolver, a name is `load-no-resolver`" {
    const gpa = std.testing.allocator;
    const loadMod = @import("../load.zig");
    try std.testing.expect(loadMod.resolver == null);
    const got = (try compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load(package: "uses_greet") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    , memory(std.testing.io))) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-no-resolver: "));
}

test "decision 993 (2): `package:` and a path together, or a wrong label, is `load-arguments`" {
    const gpa = std.testing.allocator;
    const got = (try compileMain(gpa,
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    try comptime compiler.load("packages/fine", package: "fine") catch { r -> print(r.diagnostics.length); r.module };
        \\}
        \\
    , memory(std.testing.io))) orelse return error.TestExpectedRefusal;
    defer gpa.free(got);
    try std.testing.expect(std.mem.startsWith(u8, got, "load-arguments: "));
}

test "decision 993 (3): a `test()` brings the package in with its tests lowered to functions it lists, no `main` needed" {
    const gpa = std.testing.allocator;
    const src =
        \\import {compiler, io.terminal.print} from "std";
        \\
        \\comptime {
        \\    val loaded = comptime compiler.load("packages/tested");
        \\    case loaded {
        \\        Ok(m) -> compiler.init({ ->
        \\            val answer = m.`test`();
        \\            case answer {
        \\                Ok(report) -> print(report.cases.length);
        \\                Error(r) -> print(r.message);
        \\            }
        \\        });
        \\        Error(r) -> print("refused");
        \\    }
        \\}
        \\
        \\pub fn main() -> void {}
        \\
    ;
    const io = std.testing.io;
    const loadMod = @import("../load.zig");
    var session = try comptimeMod.compile(gpa, &.{.{ .path = "", .source = src, .srcPath = "src/main.bp", .root = true, .files = memory(io) }}, io, null);
    defer session.deinit(gpa);
    var main_ok = false;
    var root_found = false;
    for (session.outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) main_ok = o.outcome == .ok;
        if (!std.mem.eql(u8, o.name, "bp_load__packages__tested/main")) continue;
        root_found = true;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => return error.LoadedRootRefused,
        };
        var case_fn = false;
        var loaded_tests = false;
        var loaded_main = false;
        for (ok.transformed.decls) |d| switch (d) {
            .@"fn" => |f| {
                if (std.mem.eql(u8, f.name, loadMod.test_case_prefix ++ "0")) case_fn = true;
                if (std.mem.eql(u8, f.name, loadMod.loaded_tests_fn)) loaded_tests = true;
                if (std.mem.eql(u8, f.name, loadMod.loaded_main_fn)) loaded_main = true;
            },
            .@"test" => return error.TestBlockKept,
            else => {},
        };
        try std.testing.expect(case_fn);
        try std.testing.expect(loaded_tests);
        try std.testing.expect(!loaded_main);
    }
    try std.testing.expect(main_ok);
    try std.testing.expect(root_found);
}

test "decision 993 (3): `run` and `` `test` `` are the lowered calls of a `Module`; each package entry begins with its initialisers" {
    const loadMod = @import("../load.zig");
    try std.testing.expectEqual(loadMod.CallKind.run, loadMod.moduleCallKind("run").?);
    try std.testing.expectEqual(loadMod.CallKind.test_, loadMod.moduleCallKind("`test`").?);
    try std.testing.expect(loadMod.moduleCallKind("test") == null);
    try std.testing.expect(loadMod.isLoadedEntry(loadMod.loaded_main_fn));
    try std.testing.expect(loadMod.isLoadedEntry(loadMod.loaded_tests_fn));
    try std.testing.expect(!loadMod.isLoadedEntry(loadMod.loaded_tests_off_fn));
    try std.testing.expect(loadMod.endsWithLoadedEntry("bp_x__" ++ loadMod.loaded_tests_fn));
}
