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

test "decision 625 (2): `ast_build.zig`'s kinds are std's `compiler.Node`, record for record and field for field" {
    const astBuild = @import("../ast_build.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(try compilerSource());
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const node = for (program.decls) |d| {
        if (d == .typeAlias and std.mem.eql(u8, d.typeAlias.name, "Node")) break d.typeAlias;
    } else return error.NodeMissing;
    // `Node` is the union of the kinds, in the table's order.
    try std.testing.expect(node.target == .generic and std.mem.eql(u8, node.target.generic.name, ast.union_type_name));
    const members = node.target.generic.args;
    try std.testing.expectEqual(astBuild.kinds.len, members.len);
    for (astBuild.kinds, members) |k, m| {
        try std.testing.expect(m == .named);
        try std.testing.expectEqualStrings(@tagName(k.kind), m.named);
        const record = for (program.decls) |d| {
            if (d == .type_ and std.mem.eql(u8, d.type_.name, m.named)) break d.type_;
        } else return error.KindRecordMissing;
        const fields = record.recordFields();
        try std.testing.expectEqual(k.fields.len, fields.len);
        for (k.fields, fields) |want, f| try std.testing.expectEqualStrings(want, f.name);
    }
    // Each kind's field set is its own: a record is read by its fields.
    for (astBuild.kinds, 0..) |a, i| for (astBuild.kinds[i + 1 ..]) |b| {
        if (a.fields.len != b.fields.len) continue;
        const same = for (a.fields) |f| {
            const has = for (b.fields) |g| {
                if (std.mem.eql(u8, f, g)) break true;
            } else false;
            if (!has) break false;
        } else true;
        try std.testing.expect(!same);
    };
}

test "decision 786: the records `compiler.load` answers are std's `compiler.Module`, `Refused` and `Diagnostic`, field for field" {
    const loadMod = @import("../load.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(try compilerSource());
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    for (loadMod.records) |r| {
        const record = for (program.decls) |d| {
            if (d == .type_ and std.mem.eql(u8, d.type_.name, r.name)) break d.type_;
        } else {
            std.debug.print("compiler.bp declares no `{s}`\n", .{r.name});
            return error.RecordMissing;
        };
        const fields = record.recordFields();
        try std.testing.expectEqual(r.fields.len, fields.len);
        // A field named by a reserved word is written between backticks
        // (`` `from` ``, decision 991): compared by the name it spells.
        for (r.fields, fields) |want, f| try std.testing.expectEqualStrings(want, ast.unquotedName(f.name));
        // Decision 811 (4) — `Module` is opaque, made by the method without
        // `pub` the lowering calls (`load.module_maker`), its fields read
        // through `pub fn name` / `pub fn path` / `pub fn buildOutput`; `pub fn run` (decision 806)
        // beside them, and the capture a lowered `run()` opens and closes
        // (decision 989 (1), `load.capture_open` / `load.capture_close`),
        // without `pub` as the maker.
        if (std.mem.eql(u8, r.name, "Module")) {
            try std.testing.expect(record.isOpaque);
            for (record.methods) |m| {
                const lowering = std.mem.eql(u8, m.name, loadMod.module_maker) or
                    std.mem.eql(u8, m.name, loadMod.capture_open) or
                    std.mem.eql(u8, m.name, loadMod.capture_close);
                try std.testing.expectEqual(!lowering, m.isPub);
            }
            try std.testing.expectEqual(@as(usize, 7), record.methods.len);
        }
    }
    // `load` answers them: `Result<Module, Refused>`.
    const behavior = for (program.decls) |d| {
        if (d == .behavior and std.mem.eql(u8, d.behavior.name, "Compiler")) break d.behavior;
    } else return error.CompilerBehaviorMissing;
    const load = for (behavior.methods) |m| {
        if (std.mem.eql(u8, m.name, "load")) break m;
    } else return error.MemberMissing;
    const ret = load.returnType orelse return error.LoadReturnMissing;
    try std.testing.expect(ret == .generic and std.mem.eql(u8, ret.generic.name, "Result"));
    try std.testing.expectEqual(@as(usize, 2), ret.generic.args.len);
    try std.testing.expectEqualStrings("Module", ret.generic.args[0].named);
    try std.testing.expectEqualStrings("Refused", ret.generic.args[1].named);
}
