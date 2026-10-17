//! Decision 575 (3) — `Compiler` has one implementor, the compiler: its table
//! of members (`parser/compiler_surface.zig` `members`) is held here to the
//! behavior std declares in `libs/std/src/compiler.bp`, member for member — a
//! property is a `val`, every other member a `fn` — so neither can name a
//! member the other lacks.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const surface = @import("../../parser/compiler_surface.zig");

fn compilerSource() ![]const u8 {
    for (comptimeMod.std_pkg_modules) |m| if (std.mem.eql(u8, m.path, "std/compiler")) return m.source;
    return error.CompilerModuleMissing;
}

test "decision 575 (3): the compiler's table of `Compiler` members is std's `compiler.bp`" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(try compilerSource());
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const behavior = for (program.decls) |d| {
        if (d == .behavior and std.mem.eql(u8, d.behavior.name, "Compiler")) break d.behavior;
    } else return error.CompilerBehaviorMissing;

    var declared: std.StringHashMapUnmanaged(surface.Kind) = .empty;
    for (behavior.fields) |f| try declared.put(arena, f.name, .property);
    for (behavior.methods) |m| try declared.put(arena, m.name, .read);
    try std.testing.expectEqual(surface.members.len, declared.count());
    for (surface.members) |m| {
        const kind = declared.get(m.name) orelse {
            std.debug.print("`Compiler` in compiler.bp lacks the member `{s}`\n", .{m.name});
            return error.MemberMissing;
        };
        try std.testing.expectEqual(m.kind == .property, kind == .property);
    }
}
