//! Decision 757 across a module boundary — a function of another module whose
//! `comptime t: type<T>` parameters specialise it and whose body reads one
//! (`type_token.copiedPerType`) is copied per type argument into the module
//! that calls it: the type a call writes is often this module's own, which
//! the declaring module cannot name, and that module is compiled first.
//!
//! Run before this module is inferred, over its program as written: every
//! call of such an imported function whose type arguments are types written
//! (or, in a function of this module copied per type, its own tokens handed
//! on) asks for a copy, `type_token.copyName(owner, name, types)`. A copy is
//! the declaration as its module carried it with the token parameters gone,
//! each read of a token the type's name, each type parameter a token binds the
//! type, and each name the body writes that resolves in the declaring module
//! bound here under its alias (decision 112's hygiene, as a function expanded
//! at its call site has it, 562): a value through `written_names.bindValue`,
//! a type or a namespace through the import `expand_call.importOf` writes. A
//! call of another such function of the declaring module is the call of its
//! copy, asked for in turn. Every location of a copy is moved into an
//! expansion of its own, so no rewrite keyed by a location of this module's
//! own code reaches it. The copies are inferred as this module's private
//! functions; `type_token.zig` points each recorded call at its copy.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const Env = envMod.Env;
const infer = @import("infer.zig");
const type_token = @import("type_token.zig");
const writtenNames = @import("written_names.zig");
const expand_call = @import("expand_call.zig");

const InferError = infer.InferError;

/// What a module's calls asked for: the imports its copies' names need, and
/// the copies.
pub const Planned = struct { imports: []const ast.DeclKind, copies: []const ast.DeclKind };

const ImpRequest = struct { owner: []const u8, decl: ast.FnDecl, types: []const []const u8 };
const LocalRequest = struct { decl: ast.FnDecl, types: []const []const u8 };

/// The copies the calls of `program` ask for. `fns` answers a declaring
/// module's `pub fn` by `(module, name)` — its declaration as that module
/// exported it — or null.
pub fn plan(env: *Env, program: ast.Program, own_package: []const u8, fns: anytype) InferError!Planned {
    if (env.tokenImports.count() == 0) return .{ .imports = &.{}, .copies = &.{} };
    var p: Planner(@TypeOf(fns)) = .{ .env = env, .program = program, .own_package = own_package, .fns = fns };
    for (program.decls) |d| switch (d) {
        .type_ => |t| try p.typeNames.put(env.arena, t.name, {}),
        .typeAlias => |a| try p.typeNames.put(env.arena, a.name, {}),
        .@"fn" => |f| if (type_token.fnSpecialises(f) and (try type_token.tokensOf(env.arena, f.params)).len > 0)
            try p.locals.put(env.arena, f.name, f),
        else => {},
    };
    try p.scan([]const ast.DeclKind, program.decls, &.{}, &.{});
    var li: usize = 0;
    var ii: usize = 0;
    while (li < p.localQueue.items.len or ii < p.impQueue.items.len) {
        while (li < p.localQueue.items.len) : (li += 1) {
            const r = p.localQueue.items[li];
            try p.scan([]ast.Stmt, r.decl.body, try type_token.tokensOf(env.arena, r.decl.params), r.types);
        }
        while (ii < p.impQueue.items.len) : (ii += 1) try p.build(p.impQueue.items[ii]);
    }
    return .{ .imports = p.imports.items, .copies = p.copies.items };
}

fn Planner(comptime Fns: type) type {
    return struct {
        const Self = @This();

        env: *Env,
        program: ast.Program,
        own_package: []const u8,
        fns: Fns,
        typeNames: std.StringHashMapUnmanaged(void) = .empty,
        locals: std.StringHashMapUnmanaged(ast.FnDecl) = .empty,
        seen: std.StringHashMapUnmanaged(void) = .empty,
        localQueue: std.ArrayListUnmanaged(LocalRequest) = .empty,
        impQueue: std.ArrayListUnmanaged(ImpRequest) = .empty,
        imports: std.ArrayListUnmanaged(ast.DeclKind) = .empty,
        importNames: std.StringHashMapUnmanaged(void) = .empty,
        copies: std.ArrayListUnmanaged(ast.DeclKind) = .empty,

        /// Whether `n`, written in this module, names a type.
        fn isTypeName(self: *Self, n: []const u8) bool {
            if (infer.isPrimitiveTypeName(n)) return true;
            if (self.typeNames.contains(n)) return true;
            if (self.env.importedTypeDecls.contains(n)) return true;
            if (self.env.importedTypeAliases.contains(n)) return true;
            if (self.env.typeDefs.contains(n)) return true;
            return false;
        }

        /// The type the argument `e` writes, under `subst` (a token of the
        /// function being scanned handed on, as `t` or the parser's `t.value`).
        fn typeArg(self: *Self, e: ast.Expr, names: []const []const u8, types: []const []const u8) ?[]const u8 {
            if (e != .identifier) return null;
            const n = switch (e.identifier.kind) {
                .ident => |n| n,
                .identAccess => |ia| blk: {
                    if (!std.mem.eql(u8, ia.member, "value")) return null;
                    if (ia.receiver.* != .identifier or ia.receiver.identifier.kind != .ident) return null;
                    break :blk ia.receiver.identifier.kind.ident;
                },
                else => return null,
            };
            for (names, 0..) |s, i| if (std.mem.eql(u8, s, n)) return types[i];
            if (e.identifier.kind != .ident) return null;
            return if (self.isTypeName(n)) n else null;
        }

        /// The types `call`'s arguments write at `decl`'s token parameters,
        /// or null when one is not a type.
        fn typesOf(self: *Self, decl: ast.FnDecl, call: anytype, names: []const []const u8, types: []const []const u8) InferError!?[]const []const u8 {
            var out: std.ArrayListUnmanaged([]const u8) = .empty;
            for (decl.params, 0..) |prm, i| {
                if (!type_token.isTokenParam(prm)) continue;
                if (i >= call.args.len or call.args[i].label != null) return null;
                const t = self.typeArg(call.args[i].value.*, names, types) orelse return null;
                try out.append(self.env.arena, t);
            }
            return out.items;
        }

        fn ask(self: *Self, key: []const u8) InferError!bool {
            return !(try self.seen.getOrPut(self.env.arena, key)).found_existing;
        }

        fn askImported(self: *Self, owner: []const u8, decl: ast.FnDecl, types: []const []const u8) InferError![]const u8 {
            const name = try type_token.copyName(self.env.arena, owner, decl.name, types);
            if (try self.ask(name)) try self.impQueue.append(self.env.arena, .{ .owner = owner, .decl = decl, .types = types });
            return name;
        }

        /// Every call of `v` that asks for a copy, `names` the tokens of the
        /// function being scanned and `types` the types they stand for.
        fn scan(self: *Self, comptime N: type, v: N, names: []const []const u8, types: []const []const u8) InferError!void {
            if (N == ast.Expr) if (v == .call) if (v.call.kind == .call) {
                const call = v.call.kind.call;
                if (!call.is_builtin and call.calleeExpr == null) {
                    if (call.receiver == null) {
                        if (self.locals.get(call.callee)) |f| {
                            if (try self.typesOf(f, call, names, types)) |ts| {
                                const key = try std.fmt.allocPrint(self.env.arena, "\x00{s}", .{try type_token.mangled(self.env.arena, f.name, ts)});
                                if (try self.ask(key)) try self.localQueue.append(self.env.arena, .{ .decl = f, .types = ts });
                            }
                        } else if (self.env.tokenImports.get(call.callee)) |imp| {
                            if (try self.typesOf(imp.decl, call, names, types)) |ts| _ = try self.askImported(imp.owner, imp.decl, ts);
                        }
                    } else if (call.receiver.?.* == .identifier and call.receiver.?.identifier.kind == .ident) {
                        const key = try std.fmt.allocPrint(self.env.arena, "{s}.{s}", .{ call.receiver.?.identifier.kind.ident, call.callee });
                        if (self.env.tokenImports.get(key)) |imp| if (try self.typesOf(imp.decl, call, names, types)) |ts| {
                            _ = try self.askImported(imp.owner, imp.decl, ts);
                        };
                    }
                }
            };
            switch (@typeInfo(N)) {
                .@"struct" => |st| inline for (st.fields) |f| {
                    if (!f.is_comptime) try self.scan(f.type, @field(v, f.name), names, types);
                },
                .@"union" => |u| if (u.tag_type != null) switch (v) {
                    inline else => |payload| try self.scan(@TypeOf(payload), payload, names, types),
                },
                .optional => |o| if (v) |inner| try self.scan(o.child, inner, names, types),
                .pointer => |pi| switch (pi.size) {
                    .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") try self.scan(pi.child, v.*, names, types),
                    .slice => if (pi.child != u8) for (v) |e| try self.scan(pi.child, e, names, types),
                    else => {},
                },
                else => {},
            }
        }

        /// The copy `r` asks for, written into this module.
        fn build(self: *Self, r: ImpRequest) InferError!void {
            const arena = self.env.arena;
            self.env.expansionCount += 1;
            var c: Copier(Fns) = .{
                .p = self,
                .owner = r.owner,
                .tokens = try type_token.tokensOf(arena, r.decl.params),
                .bound = try type_token.boundOf(arena, r.decl.params),
                .types = r.types,
                .exp = self.env.expansionCount,
            };
            for (r.decl.params) |prm| try c.binders.put(arena, prm.name, {});
            try c.collectBinders([]ast.Stmt, r.decl.body);
            var copy = r.decl;
            copy.name = try type_token.copyName(arena, r.owner, r.decl.name, r.types);
            copy.params = try c.copy([]ast.Param, try type_token.withoutTokens(arena, r.decl.params));
            copy.returnType = try c.copy(?ast.TypeRef, r.decl.returnType);
            copy.genericParams = try type_token.unbound(arena, r.decl.genericParams, c.bound);
            copy.body = try c.copy([]ast.Stmt, r.decl.body);
            copy.annotations = &.{};
            copy.isPub = false;
            copy.isDefault = false;
            copy.anonymousDefault = false;
            copy.defaultBy = null;
            copy.pubByDefault = false;
            try self.copies.append(arena, .{ .@"fn" = copy });
        }

        fn addImport(self: *Self, d: ast.DeclKind) InferError!void {
            const alias = d.use.imports[0].name();
            if ((try self.importNames.getOrPut(self.env.arena, alias)).found_existing) return;
            try self.imports.append(self.env.arena, d);
        }
    };
}

/// A copy of a body of `owner` for `types`: tokens and the type parameters
/// they bind written as the types, `owner`'s names as their aliases here, and
/// every location in the expansion `exp`.
fn Copier(comptime Fns: type) type {
    return struct {
        const Self = @This();

        p: *Planner(Fns),
        owner: []const u8,
        tokens: []const []const u8,
        bound: []const []const u8,
        types: []const []const u8,
        exp: u32,
        /// Every name the body binds (its parameters, locals, lambda and
        /// pattern names): never one of `owner`'s.
        binders: std.StringHashMapUnmanaged(void) = .empty,

        fn tokenType(self: *const Self, n: []const u8) ?[]const u8 {
            for (self.tokens, 0..) |t, i| if (std.mem.eql(u8, t, n)) return self.types[i];
            return null;
        }

        fn boundType(self: *const Self, n: []const u8) ?[]const u8 {
            for (self.bound, 0..) |t, i| if (std.mem.eql(u8, t, n)) return self.types[i];
            return null;
        }

        fn collectBinders(self: *Self, comptime N: type, v: N) InferError!void {
            const arena = self.p.env.arena;
            if (N == ast.Pattern) switch (v) {
                .ident => |n| if (std.mem.indexOfScalar(u8, n, '.') == null) try self.binders.put(arena, n, {}),
                .variant => |vr| switch (vr.payload) {
                    .binding => |n| try self.binders.put(arena, n, {}),
                    .fields => |fs| for (fs) |n| try self.binders.put(arena, n, {}),
                    .literals => {},
                },
                else => {},
            };
            if (N == ast.ParamDestruct) {
                var names: std.ArrayListUnmanaged([]const u8) = .empty;
                try expand_call.destructNames(arena, v, &names);
                for (names.items) |n| try self.binders.put(arena, n, {});
            }
            switch (@typeInfo(N)) {
                .@"struct" => |st| {
                    if (@hasField(N, "params") and @TypeOf(@field(v, "params")) == []const []const u8)
                        for (v.params) |n| try self.binders.put(arena, n, {});
                    if (@hasField(N, "name") and @hasField(N, "mutable") and @hasField(N, "value") and @TypeOf(@field(v, "name")) == []const u8)
                        try self.binders.put(arena, v.name, {});
                    inline for (st.fields) |f| {
                        if (!f.is_comptime) try self.collectBinders(f.type, @field(v, f.name));
                    }
                },
                .@"union" => |u| if (u.tag_type != null) switch (v) {
                    inline else => |payload| try self.collectBinders(@TypeOf(payload), payload),
                },
                .optional => |o| if (v) |inner| try self.collectBinders(o.child, inner),
                .pointer => |pi| switch (pi.size) {
                    .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") try self.collectBinders(pi.child, v.*),
                    .slice => if (pi.child != u8) for (v) |e| try self.collectBinders(pi.child, e),
                    else => {},
                },
                else => {},
            }
        }

        /// The name this module reaches `owner`'s `n` under, or null when `n`
        /// is not `owner`'s (a std prelude name, one of the body's own).
        fn alias(self: *Self, n: []const u8, wantType: bool) InferError!?[]const u8 {
            if (self.binders.contains(n) and !wantType) return null;
            const env = self.p.env;
            const r = env.reflection orelse return null;
            const w = (try r.written(env.arena, self.owner, n)) orelse return null;
            if (w.namespace != .none) {
                if (wantType) return null;
                const d = (try expand_call.importOf(env, self.p.program.decls, self.owner, n, w, self.p.own_package)) orelse return null;
                try self.p.addImport(d);
                return d.use.imports[0].name();
            }
            if (w.isType != wantType) return null;
            if (w.isType) {
                // The same type this module imports by the same name.
                if (env.importOwners.get(n)) |o| if (std.mem.eql(u8, o.owner, w.module) and std.mem.eql(u8, o.name, w.name)) return null;
                if (writtenNames.renamedAliasOf(env, w.module, w.name)) |al| return al;
                const d = (try expand_call.importOf(env, self.p.program.decls, self.owner, n, w, self.p.own_package)) orelse return null;
                try self.p.addImport(d);
                return d.use.imports[0].name();
            }
            return writtenNames.bindValue(env, w.module, w.name);
        }

        fn copy(self: *Self, comptime N: type, v: N) InferError!N {
            if (N == ast.Loc) return .{ .line = v.line, .col = v.col, .expansion = self.exp };
            if (N == ast.TypeRef) if (try self.rewriteType(v)) |t| return t;
            if (N == ast.Expr) if (try self.rewrite(v)) |e| return e;
            return self.copyPlain(N, v);
        }

        fn rewriteType(self: *Self, t: ast.TypeRef) InferError!?ast.TypeRef {
            switch (t) {
                .named => |n| {
                    if (self.boundType(n)) |ty| return .{ .named = ty };
                    if (try self.alias(n, true)) |al| return .{ .named = al };
                    return null;
                },
                .generic => |g| {
                    if (g.is_builtin) return null;
                    var out = try self.copyPlain(ast.TypeRef, t);
                    if (try self.alias(g.name, true)) |al| out.generic.name = al;
                    return out;
                },
                else => return null,
            }
        }

        fn rewrite(self: *Self, e: ast.Expr) InferError!?ast.Expr {
            switch (e) {
                .identifier => |id| switch (id.kind) {
                    .ident => |n| {
                        if (self.tokenType(n)) |ty| return .{ .identifier = .{ .loc = try self.copy(ast.Loc, id.loc), .kind = .{ .ident = ty } } };
                        if (try self.alias(n, false)) |al| return .{ .identifier = .{ .loc = try self.copy(ast.Loc, id.loc), .kind = .{ .ident = al } } };
                        return null;
                    },
                    // The parser's read of a token, `t.value`: the type.
                    .identAccess => |ia| {
                        if (std.mem.eql(u8, ia.member, "value") and ia.receiver.* == .identifier and ia.receiver.identifier.kind == .ident) {
                            if (self.tokenType(ia.receiver.identifier.kind.ident)) |ty| return .{ .identifier = .{ .loc = try self.copy(ast.Loc, id.loc), .kind = .{ .ident = ty } } };
                        }
                        return null;
                    },
                    else => return null,
                },
                .call => |c| {
                    if (c.kind != .call) return null;
                    const written = c.kind.call;
                    var out = try self.copyPlain(ast.Expr, e);
                    const call = &out.call.kind.call;
                    if (call.isType) |it| if (it == .named) if (self.tokenType(it.named)) |ty| {
                        call.isType = .{ .named = ty };
                    };
                    if (call.receiver != null or call.is_builtin or call.calleeExpr != null or call.callee.len == 0) return out;
                    if (self.binders.contains(call.callee)) return out;
                    // Another function of the declaring module copied per
                    // type: the call of its copy, asked for in turn.
                    const env = self.p.env;
                    if (env.reflection) |r| if (try r.written(env.arena, self.owner, call.callee)) |w| if (!w.isType and w.namespace == .none) {
                        if (self.p.fns.fnOf(w.module, w.name)) |f| if (try type_token.copiedPerType(env.arena, f)) {
                            const ts = (try self.ownTypesOf(f, written)) orelse return out;
                            call.callee = try self.p.askImported(w.module, f, ts);
                            var args: std.ArrayListUnmanaged(ast.CallArg) = .empty;
                            for (call.args, 0..) |a, i| if (i >= f.params.len or !type_token.isTokenParam(f.params[i])) try args.append(env.arena, a);
                            call.args = args.items;
                            return out;
                        };
                    };
                    if (try self.alias(call.callee, false)) |al| call.callee = al;
                    return out;
                },
                else => return null,
            }
        }

        /// The types a call of the body writes at `f`'s token parameters, as
        /// this module names them: a token of the body handed on, or a type
        /// of the declaring module (by its alias here) or a primitive.
        fn ownTypesOf(self: *Self, f: ast.FnDecl, call: anytype) InferError!?[]const []const u8 {
            var out: std.ArrayListUnmanaged([]const u8) = .empty;
            for (f.params, 0..) |prm, i| {
                if (!type_token.isTokenParam(prm)) continue;
                if (i >= call.args.len or call.args[i].label != null) return null;
                const a = call.args[i].value.*;
                if (a != .identifier) return null;
                const t: []const u8 = switch (a.identifier.kind) {
                    .ident => |n| self.tokenType(n) orelse (try self.alias(n, true)) orelse (if (infer.isPrimitiveTypeName(n) or self.p.isTypeName(n)) n else return null),
                    .identAccess => |ia| blk: {
                        if (!std.mem.eql(u8, ia.member, "value") or ia.receiver.* != .identifier or ia.receiver.identifier.kind != .ident) return null;
                        break :blk self.tokenType(ia.receiver.identifier.kind.ident) orelse return null;
                    },
                    else => return null,
                };
                try out.append(self.p.env.arena, t);
            }
            return out.items;
        }

        fn copyPlain(self: *Self, comptime N: type, v: N) InferError!N {
            const arena = self.p.env.arena;
            switch (@typeInfo(N)) {
                .@"struct" => |st| {
                    var out: N = v;
                    inline for (st.fields) |f| {
                        if (!f.is_comptime) @field(out, f.name) = try self.copy(f.type, @field(v, f.name));
                    }
                    return out;
                },
                .@"union" => |u| {
                    if (u.tag_type == null) return v;
                    switch (v) {
                        inline else => |payload, tag| return @unionInit(N, @tagName(tag), try self.copy(@TypeOf(payload), payload)),
                    }
                },
                .optional => |o| return if (v) |inner| try self.copy(o.child, inner) else null,
                .pointer => |pi| switch (pi.size) {
                    .one => {
                        if (@typeInfo(pi.child) == .@"fn" or @typeInfo(pi.child) == .@"opaque") return v;
                        const ptr = try arena.create(pi.child);
                        ptr.* = try self.copy(pi.child, v.*);
                        return ptr;
                    },
                    .slice => {
                        if (pi.child == u8) return v;
                        const out = try arena.alloc(pi.child, v.len);
                        for (v, 0..) |item, i| out[i] = try self.copy(pi.child, item);
                        return out;
                    },
                    else => return v,
                },
                else => return v,
            }
        }
    };
}
