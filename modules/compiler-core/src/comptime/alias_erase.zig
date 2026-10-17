//! Type-alias erasure for the backends (decision 118 rule 1).
//!
//! An alias (`type Parser<T> = @Result<T, ParseError>;`) is transparent to the
//! checker, which substitutes it while it builds types, and absent from every
//! backend: before codegen, each `TypeRef` in the program that names an alias
//! is replaced by the alias's target with the arguments substituted, so a
//! backend that reads a written type (wasm's value representation, erlang's
//! record shapes, the `.d.ts`) reads the type the alias stands for and never
//! learns the alias exists.
//!
//! One position keeps the alias: a declared return type (`returnType`) whose
//! alias ends at a builtin wrapper (`-> Parser<i32>`). Decision 118 makes the
//! wrapper written in the return the switch that activates an effect; an alias
//! types the function and activates nothing, so the backends must keep seeing a
//! plain function there — which is what the unexpanded name gives them. Every
//! other alias of a return (`-> Id`, `-> Pair<A, B>`) is expanded like any
//! other position.
//!
//! The walk is reflective (every field of every AST node, by type), so a node
//! kind added later that carries a `TypeRef` is erased without an edit here.
//! It rewrites in place, as `transform.zig` does: the program handed to it is
//! the arena-owned transformed program.
const std = @import("std");
const ast = @import("../ast.zig");

pub const Aliases = std.StringHashMapUnmanaged(ast.TypeAliasDecl);

const Error = error{OutOfMemory};

/// Erase every alias `program` writes, in place, against `aliases` (the
/// module's own and the imported ones — `Env.typeAliases`).
pub fn erase(arena: std.mem.Allocator, program: ast.Program, aliases: *const Aliases) Error!ast.Program {
    if (aliases.count() == 0) return program;
    var ctx = Ctx{ .arena = arena, .aliases = aliases };
    for (program.decls) |*d| try ctx.walk(ast.DeclKind, @constCast(d));
    return program;
}

const Ctx = struct {
    arena: std.mem.Allocator,
    aliases: *const Aliases,

    fn walk(self: *Ctx, comptime T: type, ptr: *T) Error!void {
        if (T == ast.TypeRef) return self.eraseRef(ptr);
        if (T == ast.TypeAliasDecl) return; // the declaration itself: nothing to erase
        switch (@typeInfo(T)) {
            .@"struct" => |s| {
                // `Param.typeName` mirrors a plain named `typeRef`.
                const mirrorsName = if (T == ast.Param)
                    ptr.typeRef == .named and std.mem.eql(u8, ptr.typeName, ptr.typeRef.named)
                else
                    false;
                inline for (s.fields) |f| {
                    if (f.is_comptime) continue;
                    if (comptime std.mem.eql(u8, f.name, "returnType") and f.type == ?ast.TypeRef) {
                        if (@field(ptr.*, f.name)) |*rt| {
                            if (self.isWrapperAlias(rt.*)) {
                                // Keep the alias's name; its arguments are
                                // ordinary positions.
                                if (rt.* == .generic) for (rt.generic.args) |*a| try self.eraseRef(a);
                            } else try self.eraseRef(rt);
                        }
                    } else {
                        try self.walk(f.type, &@field(ptr.*, f.name));
                    }
                }
                if (T == ast.Param and mirrorsName) {
                    ptr.typeName = if (ptr.typeRef == .named) ptr.typeRef.named else "";
                }
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| try self.walk(@TypeOf(payload.*), payload),
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (@typeInfo(p.child) != .@"fn" and @typeInfo(p.child) != .@"opaque") {
                    try self.walk(p.child, @constCast(ptr.*));
                },
                .slice => if (comptime mayHoldTypeRef(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, @constCast(e));
                },
                else => {},
            },
            .array => |a| if (comptime mayHoldTypeRef(a.child)) {
                for (ptr) |*e| try self.walk(a.child, e);
            },
            else => {},
        }
    }

    /// Replace `ptr.*` when it names an alias, then erase inside it.
    fn eraseRef(self: *Ctx, ptr: *ast.TypeRef) Error!void {
        var depth: usize = 0;
        while (self.expand(ptr.*)) |expanded| : (depth += 1) {
            // The checker refused a recursive alias; the cap only guards a
            // program that reached codegen without it.
            if (depth >= 32) break;
            ptr.* = expanded;
        }
        switch (ptr.*) {
            .named, .typeparam => {},
            .array => |e| try self.eraseRef(e),
            .optional => |e| try self.eraseRef(e),
            .tuple_ => |es| for (es) |*e| try self.eraseRef(e),
            .labeledTuple => |lt| for (lt.elems) |*e| try self.eraseRef(e),
            .function => |f| {
                for (f.params) |*e| try self.eraseRef(e);
                try self.eraseRef(f.returnType);
            },
            .generic => |g| for (g.args) |*e| try self.eraseRef(e),
        }
    }

    /// The target of the alias `ref` names, arguments substituted; null when
    /// `ref` names no alias or is written with the wrong arity (the checker
    /// already refused that).
    fn expand(self: *Ctx, ref: ast.TypeRef) ?ast.TypeRef {
        const name, const args = switch (ref) {
            .named => |n| .{ n, &[_]ast.TypeRef{} },
            .generic => |g| if (g.is_builtin or ref.unionMembers() != null) return null else .{ g.name, @as([]const ast.TypeRef, g.args) },
            else => return null,
        };
        const alias = self.aliases.get(name) orelse return null;
        if (alias.genericParams.len != args.len) return null;
        return substitute(self.arena, alias.target, alias.genericParams, args) catch null;
    }

    /// A return that goes through an alias ending at a builtin `@Wrapper<…>`.
    fn isWrapperAlias(self: *Ctx, ref: ast.TypeRef) bool {
        var cur = ref;
        var depth: usize = 0;
        while (depth < 32) : (depth += 1) {
            const next = self.expand(cur) orelse break;
            cur = next;
        }
        if (depth == 0) return false;
        return cur == .generic and cur.generic.is_builtin;
    }
};

/// `target` with each `params[i]` (a bare `.named`) replaced by `args[i]`.
/// Copies every node it rebuilds into `arena`; shares the leaves.
fn substitute(arena: std.mem.Allocator, target: ast.TypeRef, params: []const ast.GenericParam, args: []const ast.TypeRef) Error!ast.TypeRef {
    switch (target) {
        .named => |n| {
            for (params, args) |p, a| if (std.mem.eql(u8, p.name, n)) return a;
            return target;
        },
        .array => |e| {
            const box = try arena.create(ast.TypeRef);
            box.* = try substitute(arena, e.*, params, args);
            return .{ .array = box };
        },
        .optional => |e| {
            const box = try arena.create(ast.TypeRef);
            box.* = try substitute(arena, e.*, params, args);
            return .{ .optional = box };
        },
        .tuple_ => |es| return .{ .tuple_ = try substituteAll(arena, es, params, args) },
        .labeledTuple => |lt| return .{ .labeledTuple = .{
            .elems = try substituteAll(arena, lt.elems, params, args),
            .labels = lt.labels,
        } },
        .function => |f| {
            const ret = try arena.create(ast.TypeRef);
            ret.* = try substitute(arena, f.returnType.*, params, args);
            return .{ .function = .{
                .params = try substituteAll(arena, f.params, params, args),
                .returnType = ret,
                .paramNames = f.paramNames,
            } };
        },
        .generic => |g| return .{ .generic = .{
            .name = g.name,
            .args = try substituteAll(arena, g.args, params, args),
            .is_builtin = g.is_builtin,
        } },
        .typeparam => return target,
    }
}

fn substituteAll(arena: std.mem.Allocator, refs: []const ast.TypeRef, params: []const ast.GenericParam, args: []const ast.TypeRef) Error![]ast.TypeRef {
    const out = try arena.alloc(ast.TypeRef, refs.len);
    for (refs, 0..) |r, i| out[i] = try substitute(arena, r, params, args);
    return out;
}

/// False for element types that cannot reach a `TypeRef` (bytes, numbers,
/// enums), so strings and name lists are not walked element by element.
fn mayHoldTypeRef(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float => false,
        .pointer => |p| if (p.size == .slice) mayHoldTypeRef(p.child) else true,
        else => true,
    };
}

test "erase: a plain alias and a generic one expand; a wrapper return keeps its alias" {
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\type Id = i32;
        \\type Pair<A, B> = #(A, B);
        \\type Parser<T> = @Result<T, string>;
        \\fn f(x: Id, p: Pair<Id, string>) -> Id { return x; }
        \\fn g(s: string) -> Parser<Id> { return h(s); }
    ;
    var lx = lexer.Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = parser.Parser.init(tokens);
    const program = try p.parse(arena);
    var aliases: Aliases = .empty;
    for (program.decls) |d| if (d == .typeAlias) try aliases.put(arena, d.typeAlias.name, d.typeAlias);
    _ = try erase(arena, program, &aliases);

    const f = program.decls[3].@"fn";
    try std.testing.expectEqualStrings("i32", f.params[0].typeRef.named);
    const pair = f.params[1].typeRef.tuple_;
    try std.testing.expectEqualStrings("i32", pair[0].named);
    try std.testing.expectEqualStrings("string", pair[1].named);
    try std.testing.expectEqualStrings("i32", f.returnType.?.named);

    // `-> Parser<Id>` keeps the alias: it activates nothing (decision 118).
    const g = program.decls[4].@"fn";
    try std.testing.expectEqualStrings("Parser", g.returnType.?.generic.name);
    try std.testing.expectEqualStrings("i32", g.returnType.?.generic.args[0].named);
}
