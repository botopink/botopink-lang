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
//!
//! Decision 799: a program's contract implemented for a primitive
//! (`StringShout implement Shout for string {}`) is adopted the same way, into
//! the std behavior that holds the primitive's members (`adoptForPrimitives`).
//! A contract an extension block implements for a type of the module
//! (`TagShout implement Shout for Tag {}`, the block local or imported and
//! activated) gives the type the contract's `default fn`s as `pub` methods of
//! its own, the `implement` clause untouched (`adoptForBlocks`, decisions 799, 684).
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
    imported_blocks: []const ast.ImplementDecl,
) Error!ast.Program {
    var copies: usize = 0;
    const with_prims = try adoptForPrimitives(arena, program, imported, imported_blocks, &copies);
    const with_blocks = try adoptForBlocks(arena, with_prims, imported, imported_blocks, &copies);
    return adoptForTypes(arena, with_blocks, imported, &copies);
}

fn adoptForTypes(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    copies_in: *usize,
) Error!ast.Program {
    if (imported.count() == 0) return program;
    var decls: ?[]ast.DeclKind = null;
    var copies = copies_in.*;
    defer copies_in.* = copies;
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

/// Decision 799 (1), 872 — a contract an extension block implements for a type
/// of this module (`TagShout implement Shout for Tag {}`) gives the type the
/// contract's instance `default fn`s, as methods of its own: each bodied
/// `default fn` (a `self` receiver) of the contract, and of what it extends,
/// that the type and the block do not write. The block is the module's own or
/// one imported and activated. The type is not a value of the contract (684):
/// only its methods are added, its `implement` clause is not. A generic
/// contract is not adopted this way.
fn adoptForBlocks(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    imported_blocks: []const ast.ImplementDecl,
    copies_in: *usize,
) Error!ast.Program {
    var blocks: std.ArrayListUnmanaged(ast.ImplementDecl) = .empty;
    for (program.decls) |d| if (d == .implement) try blocks.append(arena, d.implement);
    try blocks.appendSlice(arena, imported_blocks);
    if (blocks.items.len == 0) return program;
    var decls: ?[]ast.DeclKind = null;
    var copies = copies_in.*;
    defer copies_in.* = copies;
    for (program.decls, 0..) |d, di| {
        if (d != .type_) continue;
        const t = d.type_;
        var added: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        var seen: std.StringHashMapUnmanaged(void) = .empty;
        for (blocks.items) |im| {
            if (!std.mem.eql(u8, im.target, t.name)) continue;
            for (im.methods) |m| try seen.put(arena, m.name, {});
            for (im.interfaces) |ref| {
                const name = switch (ref) {
                    .named => |n| n,
                    else => continue,
                };
                try collectForBlock(arena, program, imported, t, name, &added, &seen, &copies, 0);
            }
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
    const with_types = if (decls) |nd| blk: {
        var p = program;
        p.decls = nd;
        break :blk p;
    } else program;
    return adoptForImportedTargets(arena, with_types, imported, copies_in);
}

/// Decision 872 — a block of this module for a record another module declares
/// (`import {types.Tag}; pub TagShout implement Shout for Tag {}`): the type's
/// module is compiled without the block, so the contract's `default fn`s are
/// added to the block as methods of its own (`fn shout(self: Self)`), the way
/// a block's written method reaches the record, here and in every importer
/// that activates the block. A block for a type of this module is
/// `adoptForBlocks`'s; one for a primitive, `adoptForPrimitives`'s.
fn adoptForImportedTargets(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    copies_in: *usize,
) Error!ast.Program {
    var decls: ?[]ast.DeclKind = null;
    var copies = copies_in.*;
    defer copies_in.* = copies;
    for (program.decls, 0..) |d, di| {
        if (d != .implement) continue;
        const im = d.implement;
        if (primitiveHolder(im.target) != null or !importsName(program, im.target)) continue;
        var added: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        var seen: std.StringHashMapUnmanaged(void) = .empty;
        for (im.methods) |m| try seen.put(arena, m.name, {});
        for (im.interfaces) |ref| {
            const name = switch (ref) {
                .named => |n| n,
                else => continue,
            };
            try collectForImported(arena, program, imported, name, &added, &seen, &copies, 0);
        }
        if (added.items.len == 0) continue;
        const out = decls orelse blk: {
            const fresh = try arena.dupe(ast.DeclKind, program.decls);
            decls = fresh;
            break :blk fresh;
        };
        const methods = try arena.alloc(ast.ImplementMethod, added.items.len);
        for (added.items, methods) |m, *o| o.* = .{
            .qualifier = null,
            .name = m.name,
            .params = m.params,
            .body = m.body.?,
            .returnType = m.returnType,
            .loc = m.nameLoc,
            .marker = m.marker,
            .markerLoc = m.markerLoc,
        };
        var ni = im;
        ni.methods = try std.mem.concat(arena, ast.ImplementMethod, &.{ im.methods, methods });
        out[di] = .{ .implement = ni };
    }
    const new_decls = decls orelse return program;
    var p = program;
    p.decls = new_decls;
    return p;
}

/// True when `program` imports a symbol bound as `name`.
fn importsName(program: ast.Program, name: []const u8) bool {
    for (program.decls) |d| {
        if (d != .use) continue;
        for (d.use.imports) |item| if (std.mem.eql(u8, item.name(), name)) return true;
    }
    return false;
}

fn collectForImported(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    name: []const u8,
    added: *std.ArrayListUnmanaged(ast.BehaviorMethod),
    seen: *std.StringHashMapUnmanaged(void),
    copies: *usize,
    depth: usize,
) Error!void {
    if (depth >= 16) return;
    const b = ownBehavior(program, name) orelse imported.get(name) orelse return;
    if (b.genericParams.len > 0) return;
    for (b.methods) |m| {
        if (!m.is_default or m.body == null) continue;
        if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
        if (seen.contains(m.name)) continue;
        try seen.put(arena, m.name, {});
        const dl = first_line + copies.* * block;
        copies.* += 1;
        try added.append(arena, try shift(ast.BehaviorMethod, arena, m, dl));
    }
    for (b.extends) |parent| try collectForImported(arena, program, imported, parent, added, seen, copies, depth + 1);
}

fn collectForBlock(
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
    const b = ownBehavior(program, name) orelse imported.get(name) orelse return;
    if (b.genericParams.len > 0) return;
    for (b.methods) |m| {
        if (!m.is_default or m.body == null) continue;
        if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
        if (seen.contains(m.name) or declaresMethod(t, m.name)) continue;
        try seen.put(arena, m.name, {});
        const dl = first_line + copies.* * block;
        copies.* += 1;
        // A member the contract gives the type is the contract's, public where
        // the contract is (859 (2)).
        var copy = try shift(ast.BehaviorMethod, arena, m, dl);
        copy.isPub = true;
        try added.append(arena, copy);
    }
    for (b.extends) |parent| try collectForBlock(arena, program, imported, t, parent, added, seen, copies, depth + 1);
}

/// The type parameters the holder declares — `array<T>`'s `T`, the element.
fn holderParams(holder: []const u8) []const []const u8 {
    if (std.mem.eql(u8, holder, "array")) return &.{"T"};
    return &.{};
}

/// Decision 799 — the member table that holds a primitive's members, for an
/// implementation's target: the type's own (decision 641, `pub type string
/// { … }`). The numeric widths share their contracts (`Signed`, `Float`) and
/// are not here.
pub fn primitiveHolder(target: []const u8) ?[]const u8 {
    for ([_][]const u8{ "string", "bool", "bigint", "bytes", "array" }) |t| if (std.mem.eql(u8, target, t)) return t;
    return null;
}

/// Decision 799 (1) — a program's contract implemented for a primitive
/// (`StringShout implement Shout for string {}`) gives the primitive the
/// contract's members: each bodied instance `default fn` of the contract, and
/// of what it extends, is copied into the members of the std behavior that
/// holds the primitive's (`primitiveHolder`), as a program's own member of it
/// — checked there with `Self` the primitive and lowered by every backend as
/// one (the primitive type's own member table, decision 641). The copy's locations
/// move to lines of their own (`shift`), and it carries the implementation
/// (`ast.AdoptedBy`) a refusal of it is located at: a member the primitive
/// already has is `behavior-member-redeclared` there (799 (4)). A member the
/// block writes itself is the block's. The contract's own body is checked
/// against the contract as written.
fn adoptForPrimitives(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    imported_blocks: []const ast.ImplementDecl,
    copies: *usize,
) Error!ast.Program {
    var holders: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(ast.BehaviorMethod)) = .empty;
    var at: std.StringHashMapUnmanaged(ast.Loc) = .empty;
    // The blocks of the module, then the ones imported and activated.
    var blocks: std.ArrayListUnmanaged(ast.ImplementDecl) = .empty;
    for (program.decls) |d| if (d == .implement) try blocks.append(arena, d.implement);
    try blocks.appendSlice(arena, imported_blocks);
    for (blocks.items) |im| {
        const holder = primitiveHolder(im.target) orelse continue;
        const gop = try holders.getOrPut(arena, holder);
        if (!gop.found_existing) {
            gop.value_ptr.* = .empty;
            try at.put(arena, holder, im.loc);
        }
        var seen: std.StringHashMapUnmanaged(void) = .empty;
        for (im.methods) |m| try seen.put(arena, m.name, {});
        for (gop.value_ptr.items) |m| try seen.put(arena, m.name, {});
        for (im.interfaces) |ref| {
            const name, const args: []const ast.TypeRef = switch (ref) {
                .named => |n| .{ n, &.{} },
                .generic => |g| .{ g.name, g.args },
                else => continue,
            };
            const subs = try contractSubs(arena, program, imported, im, holder, name, args);
            try collectForPrimitive(arena, program, imported, im, name, name, subs, gop.value_ptr, &seen, copies, 0);
        }
    }
    if (holders.count() == 0) return program;
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    try decls.appendSlice(arena, program.decls);
    // A synthesised holder goes after the module's imports, before any body
    // that calls its members is inferred.
    var head: usize = 0;
    while (head < decls.items.len and decls.items[head] == .use) head += 1;
    var it = holders.iterator();
    while (it.next()) |e| {
        if (e.value_ptr.items.len == 0) continue;
        const holder = e.key_ptr.*;
        // A declaration of the table already in the program receives the
        // copies there: one declaration per name.
        const own = for (decls.items) |*d| {
            if (d.* == .behavior and std.mem.eql(u8, d.behavior.name, holder)) break d;
        } else null;
        if (own) |d| {
            d.behavior.methods = try std.mem.concat(arena, ast.BehaviorMethod, &.{ d.behavior.methods, e.value_ptr.items });
            continue;
        }
        const params = holderParams(holder);
        const gps = try arena.alloc(ast.GenericParam, params.len);
        for (params, 0..) |n, i| gps[i] = .{ .name = n };
        try decls.insert(arena, head, .{
            .behavior = .{
                .name = holder,
                .genericParams = gps,
                .fields = &.{},
                .methods = e.value_ptr.items,
                .nameLoc = at.get(holder).?,
                // The primitive's own member table (decision 641), the adopted
                // members added to std's.
                .primitiveType = true,
            },
        });
        head += 1;
    }
    var p = program;
    p.decls = decls.items;
    return p;
}

fn collectForPrimitive(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    im: ast.ImplementDecl,
    written: []const u8,
    name: []const u8,
    subs: []const Sub,
    added: *std.ArrayListUnmanaged(ast.BehaviorMethod),
    seen: *std.StringHashMapUnmanaged(void),
    copies: *usize,
    depth: usize,
) Error!void {
    if (depth >= 16) return;
    const b = ownBehavior(program, name) orelse imported.get(name) orelse return;
    for (b.methods) |m| {
        if (!m.is_default or m.body == null) continue;
        if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
        if (seen.contains(m.name)) continue;
        try seen.put(arena, m.name, {});
        const dl = first_line + copies.* * block;
        copies.* += 1;
        var copy = try rename(ast.BehaviorMethod, arena, try shift(ast.BehaviorMethod, arena, m, dl), subs);
        const by = try arena.create(ast.AdoptedBy);
        by.* = .{ .implementation = im.name, .contract = written, .target = im.target, .loc = im.loc };
        copy.adoptedBy = by;
        try added.append(arena, copy);
    }
    for (b.extends) |parent| try collectForPrimitive(arena, program, imported, im, written, parent, subs, added, seen, copies, depth + 1);
}

/// A type name of a contract's copy and what it is written as in the holder.
const Sub = struct { from: []const u8, to: ast.TypeRef };

/// The contract's type parameters as the holder reads them:
/// `ArrPick<E> implement Pick<E> for array<E> {}` maps `Pick`'s own parameter
/// to the argument written on the contract (`E`), and that, a parameter of the
/// block written on the target, to the holder's (`Array<T>`'s `T`).
fn contractSubs(
    arena: std.mem.Allocator,
    program: ast.Program,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    im: ast.ImplementDecl,
    holder: []const u8,
    name: []const u8,
    args: []const ast.TypeRef,
) Error![]const Sub {
    const b = ownBehavior(program, name) orelse imported.get(name) orelse return &.{};
    const params = holderParams(holder);
    var bound: std.ArrayListUnmanaged(Sub) = .empty;
    for (im.targetArgs, 0..) |t, i| {
        if (i >= params.len or t != .named) continue;
        try bound.append(arena, .{ .from = t.named, .to = .{ .named = params[i] } });
    }
    var out: std.ArrayListUnmanaged(Sub) = .empty;
    for (b.genericParams, 0..) |gp, i| {
        if (i >= args.len) break;
        try out.append(arena, .{ .from = gp.name, .to = try rename(ast.TypeRef, arena, args[i], bound.items) });
    }
    return out.items;
}

/// A copy of `value` with every type named in `subs` written as its
/// replacement. Strings and nodes holding no type are shared.
fn rename(comptime T: type, arena: std.mem.Allocator, value: T, subs: []const Sub) Error!T {
    if (subs.len == 0) return value;
    if (T == ast.TypeRef) {
        if (value == .named) for (subs) |s| if (std.mem.eql(u8, s.from, value.named)) return s.to;
    }
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            if (T == std.mem.Allocator) return value;
            var out: T = value;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try rename(f.type, arena, @field(value, f.name), subs);
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return value;
            switch (value) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try rename(@TypeOf(payload), arena, payload, subs)),
            }
        },
        .optional => |o| return if (value) |v| try rename(o.child, arena, v, subs) else null,
        .pointer => |p| {
            if (p.child == u8 or @typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") return value;
            switch (p.size) {
                .one => {
                    const n = try arena.create(p.child);
                    n.* = try rename(p.child, arena, value.*, subs);
                    return n;
                },
                .slice => {
                    const items = try arena.alloc(p.child, value.len);
                    for (value, 0..) |item, i| items[i] = try rename(p.child, arena, item, subs);
                    return items;
                },
                else => return value,
            }
        },
        .array => |a| {
            var out: T = undefined;
            for (value, 0..) |item, i| out[i] = try rename(a.child, arena, item, subs);
            return out;
        },
        else => return value,
    }
}

fn ownBehavior(program: ast.Program, name: []const u8) ?ast.BehaviorDecl {
    for (program.decls) |d| if (d == .behavior and std.mem.eql(u8, d.behavior.name, name)) return d.behavior;
    return null;
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
