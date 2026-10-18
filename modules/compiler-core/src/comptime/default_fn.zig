//! Decisions 289 and 582 — a module's default function, and the namespace that
//! calls it.
//!
//! `pub default fn (…) -> R { … }` binds no name in its module: the parser
//! leaves its name empty (`FnDecl.anonymousDefault`) and `nameAnonymous` gives
//! it `ast.anonymous_default_name` — `default`, a keyword, so no declaration,
//! import or call of the module can spell it. `pub default <name>;` (the
//! parser's `markDefaultNames`) and `pub default fn Name(…)` keep their name.
//!
//! `import {a.b}` always binds the namespace of the module `a/b` (decision
//! 582): `b.Props` and `b.render` reach its items. Written as a value — called,
//! passed, bound (`b(p)`, `xs.map(b)`, `val f = b`) — the namespace is the
//! module's default. `callableNamespaces` rewrites each such use into a local
//! no source can spell (`__bp_default_<b>`) bound by the ordinary item
//! `import {a.b.<default's name> as __bp_default_<b>}`, which the checker binds
//! with the default's function type and every backend already lowers; the
//! namespace item itself stays, for its members. A namespace of a module with
//! no default written as a value is `namespace-not-a-value`, located at the use.
//!
//! `comptime.zig` registers each module's default (`key`) in its
//! `templateRegistry` when the module's exports are recorded.

const std = @import("std");
const ast = @import("../ast.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const mayHoldExpr = @import("std_namespace.zig").mayHoldExpr;
const Binders = @import("mod_namespace.zig").Binders;

const Error = error{OutOfMemory};
const Refusal = error{Refused};

pub const Result = union(enum) {
    ok: ast.Program,
    refused: TypeError,
};

/// The `templateRegistry` key of module `path`'s default function. No import
/// item can spell it: it holds two NULs.
pub fn key(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00\x00default", .{path});
}

/// `program` with its anonymous default function named
/// `ast.anonymous_default_name`; `program` itself when it has none.
pub fn nameAnonymous(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    const at = for (program.decls, 0..) |d, i| switch (d) {
        .@"fn" => |f| if (f.anonymousDefault) break i,
        else => {},
    } else return program;
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    decls[at].@"fn".name = ast.anonymous_default_name;
    var out = program;
    out.decls = decls;
    return out;
}

/// Decision 582 (3) — the package-namespace form is the brace form:
/// `import pkg;` is `import {pkg} from "pkg"`, `import x from "p";` is
/// `import {x} from "p"`, and `import x, {a} from "p";` is `import {x, a} from
/// "p"` — the namespace of the package's module `x`, callable as its default.
/// `program` itself when it holds no such import.
pub fn packageNamespaces(arena: std.mem.Allocator, program: ast.Program) Error!ast.Program {
    var decls: ?[]ast.DeclKind = null;
    for (program.decls, 0..) |d, di| {
        if (d != .use) continue;
        const u = d.use;
        const pkg = u.package orelse continue;
        if (u.activationOnly) continue;
        if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
        const items = try arena.alloc(ast.ImportPath, u.imports.len + 1);
        items[0] = .{ .segments = try arena.dupe([]const u8, &.{pkg}), .loc = u.packageLoc };
        @memcpy(items[1..], u.imports);
        var nu = u;
        nu.package = null;
        nu.imports = items;
        if (nu.source == .root) nu.source = .{ .module = pkg };
        decls.?[di] = .{ .use = nu };
    }
    var out = program;
    if (decls) |ds| out.decls = ds;
    return out;
}

/// A namespace the module's imports bind: the item that binds it, its use
/// decl, and the module's default when it has one.
const Namespace = struct {
    use: usize,
    item: ast.ImportPath,
    source: ast.ImportSource,
    default: ?ast.FnDecl,
};

const Ctx = struct {
    arena: std.mem.Allocator,
    names: std.StringHashMapUnmanaged(Namespace) = .empty,
    /// Items to add, by the use decl they join, keyed by the local each binds.
    added: std.StringArrayHashMapUnmanaged(struct { use: usize, item: ast.ImportPath }) = .empty,
    refusal: ?TypeError = null,

    fn hidden(self: *Ctx, local: []const u8) Error![]const u8 {
        return std.fmt.allocPrint(self.arena, "__bp_default_{s}", .{local});
    }

    /// The local a value use of the namespace `n` is rewritten to, its item
    /// noted; refused when the module declares no default.
    fn valueOf(self: *Ctx, n: []const u8, loc: ast.Loc) (Error || Refusal)![]const u8 {
        const ns = self.names.get(n).?;
        const def = ns.default orelse {
            const of_package = switch (ns.source) {
                .module => |p| try std.fmt.allocPrint(self.arena, " of the package `{s}`", .{p}),
                .root, .key => "",
            };
            const msg = try std.fmt.allocPrint(
                self.arena,
                "{s}: `{s}` is the namespace of the module `{s}`{s}, which declares no `pub default` — it is not a value",
                .{ diagnostics.namespace_not_a_value, n, try ns.item.dotted(self.arena), of_package },
            );
            self.refusal = TypeError.custom(msg, "Name an item through it (`ns.item`), or give the module a `pub default fn`.").withLoc(loc);
            return error.Refused;
        };
        const local = try self.hidden(n);
        if (!self.added.contains(local)) {
            const segs = try self.arena.alloc([]const u8, ns.item.segments.len + 1);
            @memcpy(segs[0..ns.item.segments.len], ns.item.segments);
            segs[ns.item.segments.len] = def.name;
            try self.added.put(self.arena, local, .{ .use = ns.use, .item = .{ .segments = segs, .alias = local, .loc = ns.item.loc } });
        }
        return local;
    }

    fn isNamespace(self: *const Ctx, e: *const ast.Expr) bool {
        return e.* == .identifier and e.identifier.kind == .ident and self.names.contains(e.identifier.kind.ident);
    }

    /// Rewrites `e` when it is a value use of a namespace; answers whether
    /// the walk is done with it.
    fn rewrite(self: *Ctx, e: *ast.Expr) (Error || Refusal)!bool {
        switch (e.*) {
            .identifier => |*id| switch (id.kind) {
                .ident => |n| if (self.names.contains(n)) {
                    id.kind = .{ .ident = try self.valueOf(n, id.loc) };
                    return true;
                },
                // `ns.member` — a member of the namespace, not a value use.
                .identAccess => |a| if (self.isNamespace(a.receiver)) return true,
                .dotIdent => {},
            },
            .call => |*cl| if (cl.kind == .call) {
                const c = &cl.kind.call;
                if (c.receiver) |r| {
                    // `ns.f(…)` — walk the arguments, not the receiver.
                    if (self.isNamespace(r)) {
                        try self.walk(@TypeOf(c.args), &c.args);
                        try self.walk(@TypeOf(c.trailing), &c.trailing);
                        return true;
                    }
                } else if (!c.is_builtin and c.calleeExpr == null and self.names.contains(c.callee)) {
                    c.callee = try self.valueOf(c.callee, e.getLoc());
                }
            },
            else => {},
        }
        return false;
    }

    fn walk(self: *Ctx, comptime T: type, ptr: *T) (Error || Refusal)!void {
        if (T == ast.Expr) {
            if (try self.rewrite(ptr)) return;
        }
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        try self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) try self.walk(p.child, @constCast(ptr.*)),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, @constCast(e));
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }
};

/// `program` with every value use of a module namespace it imports rewritten
/// to that module's default (decision 582). `defaults` answers a module path's
/// default (`key`); `exports` says which paths are modules. A use under a
/// parameter or local of the same name is the local's, left as written.
pub fn callableNamespaces(
    arena: std.mem.Allocator,
    program: ast.Program,
    defaults: *const std.StringHashMap(ast.FnDecl),
    exports: anytype,
) Error!Result {
    var ctx = Ctx{ .arena = arena };
    for (program.decls, 0..) |d, di| {
        if (d != .use) continue;
        const u = d.use;
        if (u.package != null or u.activationOnly) continue;
        switch (u.source) {
            .module => |m| if (std.mem.eql(u8, m, "std")) continue,
            .root, .key => {},
        }
        for (u.imports) |imp| {
            if (imp.activate) continue;
            const whole = switch (try u.leafSource(imp, arena, true)) {
                .module, .key => |p| p,
                .root => continue,
            };
            if (!exports.contains(whole)) continue;
            try ctx.names.put(arena, imp.name(), .{ .use = di, .item = imp, .source = u.source, .default = defaults.get(try key(arena, whole)) });
        }
    }
    if (ctx.names.count() == 0) return .{ .ok = program };
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    for (decls) |*d| {
        if (d.* == .use) continue;
        var binders = Binders{ .arena = arena };
        try binders.walk(ast.DeclKind, d);
        var shadowed: std.ArrayListUnmanaged(struct { name: []const u8, ns: Namespace }) = .empty;
        for (binders.names.keys()) |b| if (ctx.names.fetchRemove(b)) |kv| try shadowed.append(arena, .{ .name = kv.key, .ns = kv.value });
        ctx.walk(ast.DeclKind, d) catch |err| switch (err) {
            error.Refused => return .{ .refused = ctx.refusal.? },
            error.OutOfMemory => return error.OutOfMemory,
        };
        for (shadowed.items) |s| try ctx.names.put(arena, s.name, s.ns);
    }
    for (ctx.added.values()) |a| {
        const u = &decls[a.use].use;
        const items = try arena.alloc(ast.ImportPath, u.imports.len + 1);
        @memcpy(items[0..u.imports.len], u.imports);
        items[u.imports.len] = a.item;
        u.imports = items;
    }
    var out = program;
    out.decls = decls;
    return .{ .ok = out };
}

test "an anonymous default is named `default`" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = .{ .name = "", .isPub = true, .isDefault = true, .anonymousDefault = true, .genericParams = &.{}, .params = &.{}, .returnType = null, .body = &.{} } };
    const out = try nameAnonymous(arena, .{ .decls = decls });
    try std.testing.expectEqualStrings(ast.anonymous_default_name, out.decls[0].@"fn".name);
    try std.testing.expectEqualStrings("", decls[0].@"fn".name);
}
