//! comptime: decision 551 — a `comptime` parameter whose default is a
//! `@TypeInfo.all(…)` query, answered for the program the call that leaves it
//! out is compiled in (`comptime.zig` `fillCatalogueDefaults`).

const std = @import("std");
const ast = @import("../../ast.zig");
const comptimeMod = @import("../../comptime.zig");
const Module = @import("../../module.zig").Module;
const h = @import("helpers.zig");

const frame =
    \\pub fn m(syntax decl: unknown) {
    \\    decl.setMeta("role", compiler.name(decl)!);
    \\}
    \\
    \\#[m]
    \\pub fn frameCore() -> i32 {
    \\    return 0;
    \\}
    \\
    \\pub fn boot(comptime modules: Declared<unknown>[] = @TypeInfo.all(with: m)) {
    \\    @print(modules.length.toString());
    \\}
    \\
    \\import {compiler} from "std";
;

/// The names the answers of `program` import (`import {<name> as __bp_ti_<k>} from "<module>"`),
/// as `<module>.<name>`.
pub fn answerImports(arena: std.mem.Allocator, program: ast.Program) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (program.decls) |d| {
        if (d != .use) continue;
        const module = switch (d.use.source) {
            .module => |m| m,
            .key => |k| k,
            .root => continue,
        };
        for (d.use.imports) |imp| {
            const alias = imp.alias orelse continue;
            if (!std.mem.startsWith(u8, alias, "__bp_ti_")) continue;
            try out.append(arena, try std.fmt.allocPrint(arena, "{s}.{s}", .{ module, imp.segments[imp.segments.len - 1] }));
        }
    }
    std.mem.sort([]const u8, out.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);
    return out.items;
}

fn outputOf(session: *const comptimeMod.ComptimeSession, name: []const u8) !comptimeMod.ComptimeOutput {
    for (session.outputs.items) |o| if (std.mem.eql(u8, o.name, name)) return o;
    return error.TestNoOutput;
}

test "catalogue default: a module of the program analysed after the root is listed — the session compiles again, the root analysed last" {
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    // `zz` comes after the root in the order the driver hands: the first
    // session answers without `late`, finds the answer stale and compiles
    // again with the root after every other module.
    const modules = [_]Module{
        .{ .path = "frame/root", .package = "frame", .source = frame },
        .{ .path = "main", .root = true, .source =
        \\pub mod zz;
        \\import {boot, m} from "frame";
        \\
        \\#[m]
        \\pub fn local() -> i32 {
        \\    return 1;
        \\}
        \\
        \\pub fn main() {
        \\    boot();
        \\}
        \\
        },
        .{ .path = "zz", .source =
        \\import {m} from "frame";
        \\
        \\#[m]
        \\pub fn late() -> i32 {
        \\    return 9;
        \\}
        \\
        },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, build_root, "erlang");
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |o| {
        if (o.outcome != .ok) std.debug.print("\n{s}: {s}\n", .{ o.name, @tagName(o.outcome) });
        try std.testing.expect(o.outcome == .ok);
    }
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const main = try outputOf(&session, "main");
    const got = try answerImports(arena_state.allocator(), main.outcome.ok.transformed);
    const want = [_][]const u8{ "frame/root.frameCore", "zz.late" };
    try std.testing.expectEqual(want.len, got.len);
    for (want, got) |w, g| try std.testing.expectEqualStrings(w, g);
}

test "catalogue default: a call outside the package's root is refused at the call" {
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    const modules = [_]Module{
        .{ .path = "frame/root", .package = "frame", .source = frame },
        .{ .path = "setup", .source =
        \\import {boot} from "frame";
        \\
        \\pub fn start() {
        \\    boot();
        \\}
        \\
        },
        .{ .path = "main", .root = true, .source =
        \\pub mod setup;
        \\
        \\pub fn main() {
        \\    @print("main");
        \\}
        \\
        },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, build_root, "erlang");
    defer session.deinit(std.testing.allocator);
    const setup = try outputOf(&session, "setup");
    try std.testing.expect(setup.outcome == .typeError);
    const message = try setup.outcome.typeError.message(std.testing.allocator);
    defer std.testing.allocator.free(message);
    try std.testing.expect(std.mem.startsWith(u8, message, "typeinfo-all-default-outside-root: `boot` leaves out `modules`"));
    const at = setup.outcome.typeError.loc orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual([2]usize{ 4, 5 }, [2]usize{ at.line, at.col });
}
