//! Decision 1071 (1) — the reflection records a decorator body reads have a
//! run-time form under their public names in std's `compiler.bp` (`Field`,
//! `Method`, `Variant`, `Param`, `DeclAnnotation`, `DeclKind`), built only by
//! the crossing, while the checker types a body against its own records
//! (`__Decl__Field`, … in `comptime.zig` `decl_reflection_src`). A value is
//! one or the other by where it comes from (`unify.zig` `reflectionAlike`), so
//! the two are held here field by field: the same names in the same order, each
//! field's type the same once the compiler's names are read as std's.
//!
//! One difference is the decision's own and named here, nothing else:
//! `DeclAnnotation.decorator` is the decorator's qualified name at run time (a
//! `string`, C0's I3) where the checker holds a `Decorator`. A method's typed
//! meta crosses beside it, kept by the codec inside `Decl` (decision 1075 (1)),
//! so std's `Method` is the checker's, field for field.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const unifyMod = @import("../unify.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const ast = @import("../../ast.zig");

/// A field whose run-time type is not the checker's: the record, the field,
/// the checker's type, std's.
const run_time_typed = [_][4][]const u8{.{ "DeclAnnotation", "decorator", "Decorator", "string" }};

fn compilerSource() ![]const u8 {
    for (comptimeMod.std_pkg_modules) |m| if (std.mem.eql(u8, m.path, "std/compiler")) return m.source;
    return error.CompilerModuleMissing;
}

fn parse(arena: std.mem.Allocator, src: []const u8) !ast.Program {
    var lx = Lexer.init(src);
    var p = Parser.init(try lx.scanAll(arena));
    return p.parse(arena);
}

fn typeDecl(program: ast.Program, name: []const u8) ?ast.TypeDecl {
    for (program.decls) |d| if (d == .type_ and std.mem.eql(u8, d.type_.name, name)) return d.type_;
    return null;
}

/// The checker's spelling of a type read as std's: each compiler-own
/// reflection name replaced by its public one.
fn publicSpelling(arena: std.mem.Allocator, text: []const u8) ![]const u8 {
    var out = text;
    for (unifyMod.reflection_records) |r| out = try std.mem.replaceOwned(u8, arena, out, r[1], r[0]);
    return out;
}

/// Every difference between the checker's records and std's, one line each.
fn drift(arena: std.mem.Allocator, checker_src: []const u8, std_src: []const u8) ![]const []const u8 {
    const checker = try parse(arena, checker_src);
    const stdp = try parse(arena, std_src);
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (unifyMod.reflection_records) |r| {
        const public = r[0];
        const internal = r[1];
        const mine = typeDecl(checker, internal) orelse {
            try out.append(arena, try std.fmt.allocPrint(arena, "the checker declares no `{s}`", .{internal}));
            continue;
        };
        const theirs = typeDecl(stdp, public) orelse {
            try out.append(arena, try std.fmt.allocPrint(arena, "compiler.bp declares no `{s}`", .{public}));
            continue;
        };
        if (!theirs.isPub) try out.append(arena, try std.fmt.allocPrint(arena, "compiler.bp's `{s}` is not `pub`", .{public}));
        if (std.meta.activeTag(mine.shape) != std.meta.activeTag(theirs.shape)) {
            try out.append(arena, try std.fmt.allocPrint(arena, "`{s}` and `{s}` are not both records or both enums", .{ internal, public }));
            continue;
        }
        // An enum: the same variants in the same order.
        const mv = mine.variants();
        const tv = theirs.variants();
        if (mv.len != tv.len) try out.append(arena, try std.fmt.allocPrint(arena, "`{s}` has {d} variants, `{s}` {d}", .{ internal, mv.len, public, tv.len }));
        for (mv, 0..) |v, i| {
            if (i >= tv.len) break;
            if (!std.mem.eql(u8, v.name, tv[i].name) or v.fields.len != 0 or tv[i].fields.len != 0)
                try out.append(arena, try std.fmt.allocPrint(arena, "`{s}`'s variant {d} is `{s}`, `{s}`'s `{s}`", .{ internal, i, v.name, public, tv[i].name }));
        }
        // A record: the checker's fields, in order, and no other.
        const mf = mine.recordFields();
        const tf = theirs.recordFields();
        for (mf, 0..) |f, i| {
            if (i >= tf.len) {
                try out.append(arena, try std.fmt.allocPrint(arena, "`{s}` lacks `{s}`'s field `{s}`", .{ public, internal, f.name }));
                continue;
            }
            const g = tf[i];
            if (!std.mem.eql(u8, f.name, g.name)) {
                try out.append(arena, try std.fmt.allocPrint(arena, "`{s}`'s field {d} is `{s}`, `{s}`'s `{s}`", .{ internal, i, f.name, public, g.name }));
                continue;
            }
            var want = try publicSpelling(arena, try std.fmt.allocPrint(arena, "{f}", .{f.typeRef}));
            for (run_time_typed) |rt| if (std.mem.eql(u8, rt[0], public) and std.mem.eql(u8, rt[1], f.name) and std.mem.eql(u8, rt[2], want)) {
                want = rt[3];
            };
            const got = try std.fmt.allocPrint(arena, "{f}", .{g.typeRef});
            if (!std.mem.eql(u8, want, got))
                try out.append(arena, try std.fmt.allocPrint(arena, "`{s}.{s}` is `{s}` to the checker and `{s}` in compiler.bp", .{ public, f.name, want, got }));
        }
        for (tf[@min(mf.len, tf.len)..]) |g|
            try out.append(arena, try std.fmt.allocPrint(arena, "compiler.bp's `{s}` holds `{s}`, which the checker's `{s}` does not", .{ public, g.name, internal }));
    }
    return out.items;
}

test "decision 1071 (1): the checker's reflection records and std's are one shape, field by field" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const items = try drift(arena, comptimeMod.decl_reflection_src, try compilerSource());
    for (items) |line| std.debug.print("reflection drift: {s}\n", .{line});
    try std.testing.expectEqual(@as(usize, 0), items.len);
}

test "decision 1071 (1): a field std's record lacks, or spells another type, is named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src = try compilerSource();
    const retyped = try std.mem.replaceOwned(u8, arena, src, "pub type Param(name: string, typeName: string)", "pub type Param(name: string, typeName: i32)");
    const items = try drift(arena, comptimeMod.decl_reflection_src, retyped);
    try std.testing.expectEqual(@as(usize, 1), items.len);
    try std.testing.expectEqualStrings("`Param.typeName` is `string` to the checker and `i32` in compiler.bp", items[0]);
    const extra = try std.mem.replaceOwned(u8, arena, src, "pub type Field(name: string, typeName: string, annotations: DeclAnnotation[])", "pub type Field(name: string, typeName: string, annotations: DeclAnnotation[], index: i32)");
    const more = try drift(arena, comptimeMod.decl_reflection_src, extra);
    try std.testing.expectEqual(@as(usize, 1), more.len);
    try std.testing.expectEqualStrings("compiler.bp's `Field` holds `index`, which the checker's `__Decl__Field` does not", more[0]);
    const kinds = try std.mem.replaceOwned(u8, arena, src, "pub type DeclKind { Type, Behavior, Fn, Method, Field, Val, Element, Component }", "pub type DeclKind { Type, Behavior, Fn, Method, Field, Val, Component, Element }");
    const swapped = try drift(arena, comptimeMod.decl_reflection_src, kinds);
    try std.testing.expectEqual(@as(usize, 2), swapped.len);
}

/// Decision 1075 (2) — how a value of each enum `primitives.bp` declares is
/// held at run time; an enum named nowhere here fails the sweep.
fn runTimeForm(name: []const u8) ?[]const u8 {
    for (comptimeMod.prelude_run_time_enums) |e| if (std.mem.eql(u8, e.name, name)) return "prepended to the module that names it (`withPreludeEnumDecls`)";
    if (std.mem.eql(u8, name, "YieldStep")) return "prepended to the module that names it (`withYieldStepDecl`)";
    if (std.mem.eql(u8, name, "Result")) return "each backend's own `Ok` / `Error`";
    for (unifyMod.reflection_records) |r| if (std.mem.eql(u8, r[1], name)) return "std `compiler`'s record of the public name";
    return null;
}

test "decision 1075 (2): every enum of primitives.bp has a run-time form" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const program = try parse(arena, @import("std_prelude").builtins);
    var enums: usize = 0;
    var missing: usize = 0;
    for (program.decls) |d| {
        if (d != .type_ or d.type_.variants().len == 0) continue;
        enums += 1;
        if (runTimeForm(d.type_.name) == null) {
            std.debug.print("primitives.bp's enum `{s}` has no run-time form and no refusal of its run-time use\n", .{d.type_.name});
            missing += 1;
        }
    }
    try std.testing.expect(enums >= 5);
    try std.testing.expectEqual(@as(usize, 0), missing);
}
