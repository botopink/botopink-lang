//! Decision 575 (3) — `Compiler` has one implementor, the compiler: its table
//! of members (`parser/compiler_surface.zig` `members`) is held here to the
//! behavior std declares in `libs/std/src/compiler.bp`, member for member — a
//! property is a `val`, every other member a `fn` — so neither can name a
//! member the other lacks; and, decision 616, parameter for parameter: how
//! each one after `self` arrives (`syntax`, `comptime`, a plain value) is the
//! table's `params`.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const surface = @import("../../parser/compiler_surface.zig");
const ast = @import("../../ast.zig");

fn compilerSource() ![]const u8 {
    for (comptimeMod.std_pkg_modules) |m| if (std.mem.eql(u8, m.path, "std/compiler")) return m.source;
    return error.CompilerModuleMissing;
}

test "decisions 575 (3), 616: the compiler's table of `Compiler` members is std's `compiler.bp`, each parameter's arrival included" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(try compilerSource());
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const behavior = for (program.decls) |d| {
        if (d == .behavior and std.mem.eql(u8, d.behavior.name, "Compiler")) break d.behavior;
    } else return error.CompilerBehaviorMissing;

    const Declared = struct { property: bool, params: []const ast.Param = &.{} };
    var declared: std.StringHashMapUnmanaged(Declared) = .empty;
    for (behavior.fields) |f| try declared.put(arena, f.name, .{ .property = true });
    for (behavior.methods) |m| try declared.put(arena, m.name, .{ .property = false, .params = m.params });
    try std.testing.expectEqual(surface.members.len, declared.count());
    for (surface.members) |m| {
        const d = declared.get(m.name) orelse {
            std.debug.print("`Compiler` in compiler.bp lacks the member `{s}`\n", .{m.name});
            return error.MemberMissing;
        };
        try std.testing.expectEqual(m.kind == .property, d.property);
        if (d.property) continue;
        // Every parameter after `self`, in order, arrives as the table says.
        const params = if (d.params.len > 0 and std.mem.eql(u8, d.params[0].name, "self")) d.params[1..] else d.params;
        if (params.len != m.params.len) {
            std.debug.print("`Compiler.{s}` declares {d} parameters after `self`, the table {d}\n", .{ m.name, params.len, m.params.len });
            return error.ArrivalMismatch;
        }
        for (params, m.params) |q, want| if (q.arrival != want) {
            std.debug.print("`Compiler.{s}`'s `{s}` arrives `{s}` in compiler.bp, `{s}` in the table\n", .{ m.name, q.name, @tagName(q.arrival), @tagName(want) });
            return error.ArrivalMismatch;
        };
    }
}
