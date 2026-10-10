//! Decision 337 (2) and (3) — `mod m;` binds the namespace `m`, and a module
//! namespace of the package is walked as std's is (decisions 110 and 111).
//!
//! In the module that declares it, `mod config;` / `pub mod config;` binds
//! `config` as `import {config};` binds it elsewhere: `config.splitPath(x)`
//! with no import. The namespace walks a folder module's tree: with
//! `src/mod1/mod.bp` declaring `pub mod mod2;`, `mod mod1;` alone allows
//! `mod1.mod2.splitPath(x)` — each step a `pub mod`; a plain `mod` stays
//! private to its declaring module's subtree, and `mod1.mod2` from outside
//! `mod1` is refused at `mod2` (`private-module`).
//!
//! Rewritten here, on the parsed program, into the forms the checker and the
//! four backends already lower (the `std_namespace.zig` pass, over the
//! package's own modules — `mod_tree.zig` says which exist):
//!
//! - a `mod m;` whose namespace the module reads gains the item that binds it
//!   (`import {config};`, `import {mod1.mod2};` — the child's path in the
//!   package), located at the `mod`'s name;
//! - `ns.child` (a module namespace, then a `mod` child of it) becomes the
//!   namespace of the child, bound under a local no source can spell
//!   (`__bp_ns_mod1_mod2`) with the item `mod1.mod2 as __bp_ns_mod1_mod2`;
//! - `ns.Type` (a `pub` type of the module) in a type, a constructor call or a
//!   path (`config.Color.Red`) becomes the leaf `Type` with the item
//!   `config.Type` — under a local `__bp_ns_<ns>__<Type>` when the module
//!   declares a top-level `Type` of its own (`pub type Pair = mod2.Pair;`, the
//!   re-export of decision 337 (3));
//! - `ns.name` in value position (a `pub fn` or `pub val` of the module, not a
//!   call) becomes the local `__bp_ns_<ns>__<name>` with the item `ns.name as
//!   …` — `pub val splitPath = mod2.splitPath;`.
//!
//! Two refusals belong to the binding: in the declaring module `import
//! {config};` is a second spelling of the namespace (`redundant-module-import`
//! at the item, fix: delete it), and a top-level declaration named like a
//! declared module is `import-name-collision` at the declaration.
//!
//! Runs in `analyzeSource`, first, when the session is a module tree
//! (`mod_tree.Tree.known`); the formatter prints the source as written.
const std = @import("std");
const ast = @import("../ast.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const mod_tree = @import("mod_tree.zig");
const mayHoldExpr = @import("std_namespace.zig").mayHoldExpr;

const Error = error{OutOfMemory};
const Refusal = error{Refused};

pub const Result = union(enum) {
    ok: ast.Program,
    refused: TypeError,
};

const Ctx = struct {
    arena: std.mem.Allocator,
    tree: *const mod_tree.Tree,
    /// The module being rewritten, by its key, and its package.
    path: []const u8,
    package: []const u8,
    /// Local → the module key it is the namespace of: a `mod` child of this
    /// module, or an import item whose whole path names a module.
    names: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// The `mod` children of this module, by name.
    modBound: std.StringHashMapUnmanaged(mod_tree.Child) = .empty,
    /// Names an import item of this module already binds.
    imported: std.StringHashMapUnmanaged(void) = .empty,
    /// `mod` children whose namespace the module reads.
    used: std.StringArrayHashMapUnmanaged(void) = .empty,
    /// Top-level declaration names of the module.
    own: std.StringHashMapUnmanaged(void) = .empty,
    /// Items to add, keyed by the local each binds.
    added: std.StringArrayHashMapUnmanaged(ast.ImportPath) = .empty,
    refusal: ?TypeError = null,
    /// The top-level declaration being walked — where a rewrite in a type,
    /// which carries no location of its own, is located.
    declLoc: ast.Loc = .{ .line = 0, .col = 0 },

    fn refuse(self: *Ctx, loc: ast.Loc, comptime fmt: []const u8, args: anytype, hint: ?[]const u8) (Error || Refusal) {
        const msg = try std.fmt.allocPrint(self.arena, fmt, args);
        self.refusal = TypeError.custom(msg, hint).withLoc(loc);
        return error.Refused;
    }

    /// `key`'s segments in its package, plus `leaf` when given.
    fn segmentsOf(self: *Ctx, key: []const u8, leaf: ?[]const u8) Error![]const []const u8 {
        var out: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = std.mem.splitScalar(u8, mod_tree.localPath(self.package, key), '/');
        while (it.next()) |s| try out.append(self.arena, s);
        if (leaf) |l| try out.append(self.arena, l);
        return out.toOwnedSlice(self.arena);
    }

    fn localFor(self: *Ctx, key: []const u8, member: ?[]const u8) Error![]const u8 {
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try out.appendSlice(self.arena, "__bp_ns_");
        for (mod_tree.localPath(self.package, key)) |c| try out.append(self.arena, if (c == '/') '_' else c);
        if (member) |m| {
            try out.appendSlice(self.arena, "__");
            try out.appendSlice(self.arena, m);
        }
        return out.items;
    }

    fn add(self: *Ctx, local: []const u8, item: ast.ImportPath) Error!void {
        if (!self.added.contains(local)) try self.added.put(self.arena, local, item);
    }

    /// Whether this module is `parent` or inside its subtree.
    fn within(self: *const Ctx, parent: []const u8) bool {
        if (std.mem.eql(u8, self.path, parent)) return true;
        return self.path.len > parent.len and self.path[parent.len] == '/' and std.mem.startsWith(u8, self.path, parent);
    }

    /// The child `name` of module `parent`, refused `private-module` at `loc`
    /// when it is a plain `mod` and this module is outside `parent`'s subtree.
    fn child(self: *Ctx, parent: []const u8, name: []const u8, loc: ast.Loc) (Error || Refusal)!?[]const u8 {
        const c = self.tree.childOf(parent, name) orelse return null;
        if (!c.isPub and !self.within(parent)) return self.refuse(
            loc,
            "{s}: `{s}` is a private module of `{s}` — declared `mod {s};`, it is reached only from inside `{s}`",
            .{ diagnostics.private_module, name, mod_tree.localPath(self.package, parent), name, mod_tree.localPath(self.package, parent) },
            "Declare it `pub mod` in its parent to reach it from here, or reach what it holds through a `pub` declaration of its parent.",
        );
        return c.key;
    }

    /// The module key a namespace expression names: a namespace local, or a
    /// `mod` child of one (`mod1.mod2`).
    fn moduleOf(self: *Ctx, e: *const ast.Expr) (Error || Refusal)!?[]const u8 {
        if (e.* != .identifier) return null;
        switch (e.identifier.kind) {
            .ident => |n| {
                const key = self.names.get(n) orelse return null;
                if (self.modBound.contains(n)) try self.used.put(self.arena, n, {});
                return key;
            },
            .identAccess => |a| {
                if (a.optional) return null;
                const parent = (try self.moduleOf(a.receiver)) orelse return null;
                return self.child(parent, a.member, e.identifier.loc);
            },
            .dotIdent => return null,
        }
    }

    /// The leaf a `pub` type of `key` is bound under here: its name, or a
    /// local when this module declares that name itself.
    fn typeLeaf(self: *Ctx, key: []const u8, name: []const u8, loc: ast.Loc) Error![]const u8 {
        if (self.own.contains(name)) {
            const local = try self.localFor(key, name);
            try self.add(local, .{ .segments = try self.segmentsOf(key, name), .alias = local, .loc = loc });
            return local;
        }
        try self.add(name, .{ .segments = try self.segmentsOf(key, name), .loc = loc });
        return name;
    }

    fn entry(self: *Ctx, key: []const u8) ?mod_tree.Entry {
        return self.tree.entries.get(key);
    }

    fn rewrite(self: *Ctx, e: *ast.Expr) (Error || Refusal)!bool {
        if (e.* == .call and e.call.kind == .call) return self.rewriteCtorCall(e);
        if (e.* != .identifier) return false;
        const a = switch (e.identifier.kind) {
            .identAccess => |a| a,
            else => return false,
        };
        if (a.optional or a.member.len == 0) return false;
        const loc = e.identifier.loc;
        const key = (try self.moduleOf(a.receiver)) orelse return false;
        // A `mod` child: the child's namespace.
        if (try self.child(key, a.member, loc)) |sub| {
            const local = try self.localFor(sub, null);
            try self.add(local, .{ .segments = try self.segmentsOf(sub, null), .alias = local, .loc = loc });
            e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = local } } };
            return true;
        }
        const ent = self.entry(key) orelse return false;
        if (ent.declaresType(a.member)) {
            const leaf = try self.typeLeaf(key, a.member, loc);
            e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = leaf } } };
            return true;
        }
        // A value through the namespace — a `pub fn` or `pub val` that is not
        // called here (a call is a call node with a receiver).
        if (ent.declares(a.member)) {
            const local = try self.localFor(key, a.member);
            try self.add(local, .{ .segments = try self.segmentsOf(key, a.member), .alias = local, .loc = loc });
            e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = local } } };
            return true;
        }
        return false;
    }

    /// `ns.Type(…)` — a `pub` type's constructor through the namespace —
    /// becomes the leaf call `Type(…)`; `ns.f(…)` of a function `ns`
    /// re-exports becomes a call through the declaring module's namespace. Answers false (the walk goes on into
    /// the receiver and the arguments) either way.
    fn rewriteCtorCall(self: *Ctx, e: *ast.Expr) (Error || Refusal)!bool {
        const c = &e.call.kind.call;
        const recv = c.receiver orelse return false;
        if (c.optional) return false;
        const key = (try self.moduleOf(recv)) orelse return false;
        // A function the module re-exports (`pub val splitPath =
        // mod2.splitPath;`) is called through the namespace of the module
        // that declares it.
        if (try self.tree.reexportOf(self.arena, key, c.callee)) |re| if (!re.isType) {
            const local = try self.localFor(re.owner, null);
            const loc = recv.getLoc();
            try self.add(local, .{ .segments = try self.segmentsOf(re.owner, null), .alias = local, .loc = loc });
            const r = try self.arena.create(ast.Expr);
            r.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = local } } };
            c.receiver = r;
            return false;
        };
        const ent = self.entry(key) orelse return false;
        if (!ent.declaresType(c.callee)) return false;
        c.callee = try self.typeLeaf(key, c.callee, recv.getLoc());
        c.receiver = null;
        return false;
    }

    /// `ns.Type` / `mod1.mod2.Type` written as a type.
    fn typeName(self: *Ctx, name: []const u8) (Error || Refusal)!?[]const u8 {
        const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return null;
        const member = name[dot + 1 ..];
        var it = std.mem.splitScalar(u8, name[0..dot], '.');
        const root = it.next().?;
        var key = self.names.get(root) orelse return null;
        if (self.modBound.contains(root)) try self.used.put(self.arena, root, {});
        const loc = self.declLoc;
        while (it.next()) |seg| key = (try self.child(key, seg, loc)) orelse return null;
        const ent = self.entry(key) orelse return null;
        if (!ent.declaresType(member)) return null;
        return try self.typeLeaf(key, member, loc);
    }

    fn rewriteTypeRef(self: *Ctx, t: *ast.TypeRef) (Error || Refusal)!void {
        switch (t.*) {
            .named => |n| if (try self.typeName(n)) |leaf| {
                t.* = .{ .named = leaf };
            },
            .generic => |*g| if (!g.is_builtin) {
                if (try self.typeName(g.name)) |leaf| g.name = leaf;
            },
            else => {},
        }
    }

    fn walk(self: *Ctx, comptime T: type, ptr: *T) (Error || Refusal)!void {
        if (T == ast.Expr) {
            if (try self.rewrite(ptr)) return;
        }
        if (T == ast.TypeRef) try self.rewriteTypeRef(ptr);
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

/// Every name a declaration binds inside it: a parameter, a lambda's or a
/// loop's binder, a `val` / `var`.
const Binders = struct {
    arena: std.mem.Allocator,
    names: std.StringArrayHashMapUnmanaged(void) = .empty,

    fn walk(self: *Binders, comptime T: type, ptr: *const T) Error!void {
        if (T == ast.Param) try self.names.put(self.arena, ptr.name, {});
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| {
                if (comptime hasField(s.fields, "params") and fieldIs(s.fields, "params", []const []const u8)) {
                    for (ptr.params) |n| try self.names.put(self.arena, n, {});
                }
                if (comptime hasField(s.fields, "name") and hasField(s.fields, "value") and hasField(s.fields, "mutable") and fieldIs(s.fields, "name", []const u8)) {
                    try self.names.put(self.arena, ptr.name, {});
                }
                inline for (s.fields) |f| {
                    if (f.is_comptime) continue;
                    if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
                }
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
                .one => if (comptime mayHoldExpr(p.child)) try self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }

    fn hasField(comptime fields: anytype, comptime name: []const u8) bool {
        inline for (fields) |f| if (comptime std.mem.eql(u8, f.name, name)) return true;
        return false;
    }

    fn fieldIs(comptime fields: anytype, comptime name: []const u8, comptime T: type) bool {
        inline for (fields) |f| if (comptime std.mem.eql(u8, f.name, name)) return f.type == T;
        return false;
    }
};

const Named = struct { name: []const u8, loc: ast.Loc };

fn declNamed(d: ast.DeclKind) ?Named {
    return switch (d) {
        .type_ => |t| .{ .name = t.name, .loc = t.loc },
        .typeAlias => |a| .{ .name = a.name, .loc = a.loc },
        .@"fn" => |f| .{ .name = f.name, .loc = f.nameLoc },
        .val => |v| .{ .name = v.name, .loc = v.nameLoc },
        .behavior => |b| .{ .name = b.name, .loc = .{ .line = 0, .col = 0 } },
        .delegate => |dg| .{ .name = dg.name, .loc = .{ .line = 0, .col = 0 } },
        else => null,
    };
}

/// Rewrite `program` (the arena-owned parse of the module `path` of
/// `package`) in place. A program that declares no `mod` and reads no module
/// namespace of the package is returned untouched.
pub fn expand(arena: std.mem.Allocator, program: ast.Program, tree: *const mod_tree.Tree, path: []const u8, package: []const u8) Error!Result {
    if (!tree.known) return .{ .ok = program };
    var ctx = Ctx{ .arena = arena, .tree = tree, .path = path, .package = package };
    return run(&ctx, program) catch |err| switch (err) {
        error.Refused => .{ .refused = ctx.refusal.? },
        error.OutOfMemory => error.OutOfMemory,
    };
}

fn run(ctx: *Ctx, program_in: ast.Program) (Error || Refusal)!Result {
    const arena = ctx.arena;
    // Decision 337 (3) — `pub type Pair = mod2.Pair;` re-exports the type:
    // the module holds `mod2`'s `Pair` under its own name (the item
    // `mod1.mod2.Pair`), and an import of `mod1.Pair` is an import of it
    // (`comptime.zig` `resolveImports`, `mod_tree.Tree.reexports`). A type
    // alias of a type to its own name would be a second type of the name.
    var program = program_in;
    var reexported: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
    {
        var kept: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
        var kept_blanks: std.ArrayListUnmanaged(bool) = .empty;
        for (program.decls, 0..) |d, i| {
            if (d == .typeAlias) if (ctx.tree.reexports.get(try mod_tree.reexportKey(arena, ctx.path, d.typeAlias.name))) |r| if (r.isType) {
                try reexported.append(arena, .{ .segments = try ctx.segmentsOf(r.owner, d.typeAlias.name), .loc = d.typeAlias.targetLoc });
                continue;
            };
            try kept.append(arena, d);
            if (program.blankLineBefore.len == program.decls.len) try kept_blanks.append(arena, program.blankLineBefore[i]);
        }
        if (reexported.items.len > 0) {
            program.decls = kept.items;
            program.blankLineBefore = kept_blanks.items;
        }
    }
    for (program.decls) |d| switch (d) {
        .mod => |md| if (ctx.tree.childOf(ctx.path, md.name)) |c| {
            try ctx.modBound.put(arena, md.name, c);
            try ctx.names.put(arena, md.name, c.key);
        },
        else => if (declNamed(d)) |n| try ctx.own.put(arena, n.name, {}),
    };
    // A top-level declaration named like a declared module.
    for (program.decls) |d| if (declNamed(d)) |n| if (ctx.modBound.get(n.name)) |c| {
        const loc = if (n.loc.line != 0) n.loc else c.loc;
        return ctx.refuse(
            loc,
            "{s}: `{s}` is declared here and is the module `mod {s};` declares — `mod` binds the module's namespace in this module",
            .{ diagnostics.import_name_collision, n.name, n.name },
            "Rename the declaration, or the module.",
        );
    };
    for (program.decls) |d| switch (d) {
        .use => |u| {
            if (u.source != .root or u.package != null or u.activationOnly) continue;
            for (u.imports) |imp| {
                if (imp.activate) continue;
                const local = imp.name();
                const whole = try mod_tree.keyIn(arena, ctx.package, try imp.fullPath(arena));
                if (ctx.modBound.get(local)) |c| {
                    if (std.mem.eql(u8, whole, c.key)) return ctx.refuse(
                        imp.loc,
                        "{s}: `{s}` is already bound by `mod {s};` in this module — delete this item",
                        .{ diagnostics.redundant_module_import, local, c.name },
                        "`mod` binds the module's namespace in the module that declares it; an import of it there is a second spelling.",
                    );
                    return ctx.refuse(
                        imp.loc,
                        "{s}: `{s}` is already bound by `mod {s};` in this module; this item would bind it again",
                        .{ diagnostics.import_name_collision, local, c.name },
                        "Rename the item with `as`.",
                    );
                }
                try ctx.imported.put(arena, local, {});
                if (ctx.tree.entries.contains(whole)) try ctx.names.put(arena, local, whole);
            }
        },
        else => {},
    };
    if (ctx.names.count() == 0) return .{ .ok = program };

    for (program.decls) |*d| {
        if (declNamed(d.*)) |n| ctx.declLoc = n.loc;
        // A parameter or local of the declaration named like a namespace
        // shadows it somewhere in it: its dotted reads there are left as
        // written, for the checker's scopes to answer (a call through the
        // namespace resolves there too; the `mod` item is still added).
        var binders = Binders{ .arena = arena };
        try binders.walk(ast.DeclKind, d);
        var hidden: std.ArrayListUnmanaged(struct { name: []const u8, key: []const u8 }) = .empty;
        for (binders.names.keys()) |b| if (ctx.names.fetchRemove(b)) |kv| {
            try hidden.append(arena, .{ .name = kv.key, .key = kv.value });
            if (ctx.modBound.contains(b)) try ctx.used.put(arena, b, {});
        };
        try ctx.walk(ast.DeclKind, @constCast(d));
        for (hidden.items) |h| try ctx.names.put(arena, h.name, h.key);
    }

    var items: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
    for (ctx.used.keys()) |n| {
        if (ctx.imported.contains(n)) continue;
        const c = ctx.modBound.get(n).?;
        const segs = try ctx.segmentsOf(c.key, null);
        try items.append(arena, .{
            .segments = segs,
            .alias = if (std.mem.eql(u8, segs[segs.len - 1], n)) null else n,
            .loc = c.loc,
        });
    }
    for (ctx.added.values()) |imp| try items.append(arena, imp);
    try items.appendSlice(arena, reexported.items);
    if (items.items.len == 0) return .{ .ok = program };
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + 1);
    decls[0] = .{ .use = .{ .imports = items.items, .source = .root, .ownPackage = ctx.package } };
    @memcpy(decls[1..], program.decls);
    var out = program;
    out.decls = decls;
    if (program.blankLineBefore.len == program.decls.len) {
        const blanks = try arena.alloc(bool, decls.len);
        blanks[0] = false;
        @memcpy(blanks[1..], program.blankLineBefore);
        out.blankLineBefore = blanks;
    }
    return .{ .ok = out };
}

/// Every dotted name `program` reads outside its imports — `a.b.c` as an
/// expression, a call's receiver and callee (`a.b.f(x)` is `a.b.f`), a dotted
/// type (`config.Pair`) — as its segments. The CLI's module-tree resolver
/// draws an edge from each module a chain walks to the reader, so a module
/// that reads `mod1.mod2.f()` through `mod mod1;` compiles after both.
pub fn chains(arena: std.mem.Allocator, program: ast.Program) Error![]const []const []const u8 {
    var c = Chains{ .arena = arena };
    for (program.decls) |*d| try c.walk(ast.DeclKind, @constCast(d));
    return c.out.items;
}

const Chains = struct {
    arena: std.mem.Allocator,
    out: std.ArrayListUnmanaged([]const []const u8) = .empty,

    fn segments(self: *Chains, e: *const ast.Expr, acc: *std.ArrayListUnmanaged([]const u8)) Error!bool {
        if (e.* != .identifier) return false;
        switch (e.identifier.kind) {
            .ident => |n| try acc.append(self.arena, n),
            .identAccess => |a| {
                if (!try self.segments(a.receiver, acc)) return false;
                try acc.append(self.arena, a.member);
            },
            .dotIdent => return false,
        }
        return true;
    }

    fn note(self: *Chains, e: *const ast.Expr) Error!void {
        var acc: std.ArrayListUnmanaged([]const u8) = .empty;
        switch (e.*) {
            .identifier => |id| if (id.kind == .identAccess) {
                if (try self.segments(e, &acc)) try self.out.append(self.arena, acc.items);
            },
            .call => |c| if (c.kind == .call) if (c.kind.call.receiver) |r| {
                if (!try self.segments(r, &acc)) return;
                try acc.append(self.arena, c.kind.call.callee);
                try self.out.append(self.arena, acc.items);
            },
            else => {},
        }
    }

    fn noteType(self: *Chains, name: []const u8) Error!void {
        if (std.mem.indexOfScalar(u8, name, '.') == null) return;
        var acc: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = std.mem.splitScalar(u8, name, '.');
        while (it.next()) |seg| try acc.append(self.arena, seg);
        try self.out.append(self.arena, acc.items);
    }

    fn walk(self: *Chains, comptime T: type, ptr: *T) Error!void {
        if (T == ast.Expr) try self.note(ptr);
        if (T == ast.TypeRef) switch (ptr.*) {
            .named => |n| try self.noteType(n),
            .generic => |g| try self.noteType(g.name),
            else => {},
        };
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

const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const Module = @import("../module.zig").Module;

fn expandFor(arena: std.mem.Allocator, mods: []const Module, which: usize) !Result {
    const tree = try mod_tree.build(arena, mods);
    var lx = Lexer.init(mods[which].source);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const program = try p.parse(arena);
    return expand(arena, program, &tree, mods[which].path, mods[which].package);
}

test "mod namespace: `mod` binds the namespace it reads, and the walk reaches a pub child" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const mods = [_]Module{
        .{ .path = "main", .source =
        \\pub mod config;
        \\mod mod1;
        \\pub fn main() {
        \\    val a = config.splitPath("x");
        \\    val b = mod1.mod2.splitPath("y");
        \\}
        },
        .{ .path = "config", .source = "pub fn splitPath(p: string) -> string { return p; }\n" },
        .{ .path = "mod1", .source = "pub mod mod2;\n" },
        .{ .path = "mod1/mod2", .source = "pub fn splitPath(p: string) -> string { return p; }\n" },
    };
    const program = (try expandFor(arena, &mods, 0)).ok;
    const imports = program.decls[0].use.imports;
    try std.testing.expectEqual(@as(usize, 3), imports.len);
    try std.testing.expectEqualStrings("config", try imports[0].fullPath(arena));
    try std.testing.expectEqualStrings("mod1", try imports[1].fullPath(arena));
    try std.testing.expectEqualStrings("mod1/mod2", try imports[2].fullPath(arena));
    try std.testing.expectEqualStrings("__bp_ns_mod1_mod2", imports[2].name());
}

test "mod namespace: a private child is refused from outside its parent" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const mods = [_]Module{
        .{ .path = "main", .source = "pub mod mod1;\npub fn main() { val b = mod1.mod2.f(); }\n" },
        .{ .path = "mod1", .source = "mod mod2;\n" },
        .{ .path = "mod1/mod2", .source = "pub fn f() -> i32 { return 1; }\n" },
    };
    const te = (try expandFor(arena, &mods, 0)).refused;
    try std.testing.expect(std.mem.indexOf(u8, te.kind.custom.message, "private-module") != null);
}

test "mod namespace: an import of the module `mod` binds is redundant" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const mods = [_]Module{
        .{ .path = "main", .source = "pub mod config;\nimport {config};\npub fn main() {}\n" },
        .{ .path = "config", .source = "pub fn f() -> i32 { return 1; }\n" },
    };
    const te = (try expandFor(arena, &mods, 0)).refused;
    try std.testing.expect(std.mem.indexOf(u8, te.kind.custom.message, "redundant-module-import") != null);
}
