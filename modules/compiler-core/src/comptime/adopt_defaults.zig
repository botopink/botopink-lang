//! A type adopts the instance `default fn`s of a behavior it implements — the
//! behavior's own module or another's (144 B-19). A behavior of this module is
//! adopted by every backend from its declaration (`erlang.zig`
//! `appendIfaceDefaults`, …). One reached through an import has its
//! declaration in another module, whose checked body this module's backends
//! never see: `Sq(n: 3).twice()` over an imported `Shape` was refused by the
//! checker and, once accepted, undefined on every target.
//!
//! So before this module is checked, each `type` implementing an imported
//! behavior receives a copy of each bodied instance `default fn` (a `self`
//! receiver) the behavior — and what it extends — declares and the type does
//! not, as a method of its own: checked here as the type's method (`Self` is
//! the type) and lowered by every backend as one. A copy's locations are moved
//! to lines of their own past every line of the module (`first_line`), so no
//! location-keyed plan of this module meets one of the behavior's file. A
//! generic behavior is not adopted this way (its type parameters would be
//! unbound in the copy).
const std = @import("std");
const ast = @import("../ast.zig");

const Error = error{OutOfMemory};

/// Where the first copy's lines start; each copy takes a block of its own.
pub const first_line: usize = 3_000_000;
const block: usize = 100_000;

/// `program` with every imported behavior's instance defaults adopted by the
/// types of `program` implementing it. `imported` is the checker's
/// `Env.importedBehaviorDecls`, keyed by the behavior's declared name.
pub fn expand(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
) Error!ast.Program {
    if (imported.count() == 0) return program;
    var decls: ?[]ast.DeclKind = null;
    var copies: usize = 0;
    for (program.decls, 0..) |d, di| {
        if (d != .type_ or d.type_.implement.len == 0) continue;
        const t = d.type_;
        var added: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        var seen: std.StringHashMapUnmanaged(void) = .empty;
        for (t.implement) |ref| {
            const name = switch (ref) {
                .named => |n| n,
                else => continue,
            };
            try collect(arena, program, imported, t, name, &added, &seen, &copies, 0);
        }
        if (added.items.len == 0) continue;
        const out = decls orelse blk: {
            const fresh = try arena.dupe(ast.DeclKind, program.decls);
            decls = fresh;
            break :blk fresh;
        };
        var nt = t;
        nt.methods = try std.mem.concat(arena, ast.BehaviorMethod, &.{ t.methods, added.items });
        out[di] = .{ .type_ = nt };
    }
    const new_decls = decls orelse return program;
    var p = program;
    p.decls = new_decls;
    return p;
}

fn collect(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    t: ast.TypeDecl,
    name: []const u8,
    added: *std.ArrayListUnmanaged(ast.BehaviorMethod),
    seen: *std.StringHashMapUnmanaged(void),
    copies: *usize,
    depth: usize,
) Error!void {
    if (depth >= 16) return;
    if (declaresBehavior(program, name)) return;
    const b = imported.get(name) orelse return;
    if (b.genericParams.len > 0) return;
    for (b.methods) |m| {
        if (!m.is_default or m.body == null) continue;
        if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
        if (seen.contains(m.name) or declaresMethod(t, m.name)) continue;
        try seen.put(arena, m.name, {});
        const dl = first_line + copies.* * block;
        copies.* += 1;
        try added.append(arena, try shift(ast.BehaviorMethod, arena, m, dl));
    }
    for (b.extends) |parent| try collect(arena, program, imported, t, parent, added, seen, copies, depth + 1);
}

fn declaresBehavior(program: ast.Program, name: []const u8) bool {
    for (program.decls) |d| if (d == .behavior and std.mem.eql(u8, d.behavior.name, name)) return true;
    return false;
}

fn declaresMethod(t: ast.TypeDecl, name: []const u8) bool {
    for (t.methods) |m| if (std.mem.eql(u8, m.name, name)) return true;
    return false;
}

/// A copy of `value` with every location's line moved by `dl` (a synthesised
/// `{0, 0}` stays). Strings and nodes holding no location are shared.
fn shift(comptime T: type, arena: std.mem.Allocator, value: T, dl: usize) Error!T {
    if (T == ast.Loc) {
        if (value.line == 0) return value;
        var l = value;
        l.line += dl;
        return l;
    }
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            if (T == std.mem.Allocator) return value;
            var out: T = value;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try shift(f.type, arena, @field(value, f.name), dl);
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return value;
            switch (value) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try shift(@TypeOf(payload), arena, payload, dl)),
            }
        },
        .optional => |o| return if (value) |v| try shift(o.child, arena, v, dl) else null,
        .pointer => |p| {
            if (p.child == u8 or @typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") return value;
            switch (p.size) {
                .one => {
                    const n = try arena.create(p.child);
                    n.* = try shift(p.child, arena, value.*, dl);
                    return n;
                },
                .slice => {
                    const items = try arena.alloc(p.child, value.len);
                    for (value, 0..) |item, i| items[i] = try shift(p.child, arena, item, dl);
                    return items;
                },
                else => return value,
            }
        },
        .array => |a| {
            var out: T = undefined;
            for (value, 0..) |item, i| out[i] = try shift(a.child, arena, item, dl);
            return out;
        },
        else => return value,
    }
}
