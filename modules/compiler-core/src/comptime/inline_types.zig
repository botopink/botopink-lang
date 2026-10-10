//! Decision 207 — a parameter's type written inline:
//! `pub fn link(props: type(href: string, label: string, external: bool = false)) -> string`.
//!
//! The parser keeps the fields on `Param.inlineFields` with the placeholder
//! `typeRef` `ast.inline_type_name`. This pass, run on the parsed program
//! before the checker and the backends see it (`analyzeSource`), turns every
//! inline parameter of a top-level `fn` into an ordinary record type of the
//! module — `type BpInline__link__props(href: string, …)`, declared just
//! before the function, private, and named by no source — and points the
//! parameter's `typeRef` at it, so no checker rule and no backend learns a new
//! node. A diagnostic names the type by its owner (``the props of `link` ``,
//! `error.zig`).
//!
//! **The construction spelling** is the call's own labelled arguments: in
//! `link(href: "/a", label: "A")` every label that names a field of the inline
//! type (and no parameter of `link`) gathers into the inline value, which is
//! rewritten here into the record's constructor call
//! `link(props: BpInline__link__props(href: "/a", label: "A"))` — the
//! labelled-call grammar that exists, matched by the checker against the inline
//! type's fields (a missing field without a default, an unknown label and a
//! wrong type are the constructor's ordinary refusals). A value already of the
//! type is passed as the parameter itself (`link(props)` while forwarding).
//! The checker refuses what would make that reading ambiguous
//! (`infer.refuseInlineParamRules`): a second inline parameter on one
//! function, and a field named like another parameter of the function. An
//! inline parameter of anything but a top-level `fn` is refused too.
//!
//! The rewrite sees the calls of the module that declares the function; a call
//! from another module meets the function's labels only (the type is not
//! exported), and is refused by the ordinary label check.
const std = @import("std");
const ast = @import("../ast.zig");

const Error = error{OutOfMemory};
const TypeError = @import("error.zig").TypeError;

/// The column offset of a rewritten constructor call's loc: past any written
/// column, and taken off again before a diagnostic is shown
/// (`locatedAtCall`), so a refusal of the constructor is located at the call.
const synthetic_col: usize = 1_000_000;

/// A diagnostic located at a rewritten constructor call points at the call
/// the source wrote.
pub fn locatedAtCall(te: TypeError) TypeError {
    var out = te;
    if (out.loc) |*l| {
        if (l.col > synthetic_col) l.col %= synthetic_col;
    }
    return out;
}

const InlineFn = struct {
    /// The inline parameter's index and name.
    index: usize,
    param: []const u8,
    /// The declared record's name.
    type_name: []const u8,
    fields: []const ast.Field,
    params: []const ast.Param,
};

const Ctx = struct {
    arena: std.mem.Allocator,
    fns: std.StringHashMapUnmanaged(InlineFn) = .empty,

    fn isField(fields: []const ast.Field, label: []const u8) bool {
        for (fields) |f| if (std.mem.eql(u8, f.name, label)) return true;
        return false;
    }

    fn isParam(params: []const ast.Param, label: []const u8) bool {
        for (params) |p| if (std.mem.eql(u8, p.name, label)) return true;
        return false;
    }

    /// `link(href: …, label: …)` → `link(props: BpInline__link__props(href: …, label: …))`.
    fn rewriteCall(self: *Ctx, e: *ast.Expr) Error!void {
        if (e.* != .call or e.call.kind != .call) return;
        const c = &e.call.kind.call;
        if (c.receiver != null or c.calleeExpr != null or c.is_builtin) return;
        const f = self.fns.get(c.callee) orelse return;
        var gathered: std.ArrayListUnmanaged(ast.CallArg) = .empty;
        var kept: std.ArrayListUnmanaged(ast.CallArg) = .empty;
        var at: ?usize = null;
        for (c.args) |a| {
            const l = a.label orelse {
                try kept.append(self.arena, a);
                continue;
            };
            if (isField(f.fields, l) and !isParam(f.params, l)) {
                if (at == null) at = kept.items.len;
                try gathered.append(self.arena, a);
            } else try kept.append(self.arena, a);
        }
        const pos = at orelse return;
        const ctor = try self.arena.create(ast.Expr);
        // Every loc-keyed table of the checker needs the constructor call at a
        // place no written node holds: the outer call's line, past any column.
        const ctorLoc: ast.Loc = .{ .line = e.call.loc.line, .col = e.call.loc.col + synthetic_col * (f.index + 1), .expansion = e.call.loc.expansion };
        ctor.* = .{ .call = .{ .loc = ctorLoc, .kind = .{ .call = .{
            .receiver = null,
            .callee = f.type_name,
            .is_builtin = false,
            .args = try gathered.toOwnedSlice(self.arena),
            .trailing = &.{},
        } } } };
        try kept.insert(self.arena, pos, .{ .label = f.param, .value = ctor });
        c.args = try kept.toOwnedSlice(self.arena);
    }

    fn walk(self: *Ctx, comptime T: type, ptr: *T) Error!void {
        if (T == ast.Expr) try self.rewriteCall(ptr);
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |fld| {
                if (fld.is_comptime) continue;
                if (comptime mayHoldExpr(fld.type)) try self.walk(fld.type, &@field(ptr.*, fld.name));
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
                    for (ptr.*) |*x| try self.walk(p.child, @constCast(x));
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*x| try self.walk(arr.child, x);
            },
            else => {},
        }
    }
};

fn mayHoldExpr(comptime T: type) bool {
    if (T == ast.TypeRef) return false;
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExpr(p.child) else true,
        else => true,
    };
}

/// The record an inline parameter declares, named for its owner.
pub fn typeNameFor(arena: std.mem.Allocator, owner: []const u8, param: []const u8) Error![]const u8 {
    return std.fmt.allocPrint(arena, "{s}{s}__{s}", .{ ast.inline_type_prefix, owner, param });
}

/// Rewrite `program` (the arena-owned parse of one module). A program with no
/// inline parameter type is returned untouched.
pub fn expand(arena: std.mem.Allocator, program: ast.Program) Error!ast.Program {
    var ctx = Ctx{ .arena = arena };
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var any = false;
    for (program.decls) |d| {
        if (d == .@"fn") {
            const f = d.@"fn";
            var params: ?[]ast.Param = null;
            for (f.params, 0..) |p, i| {
                const fields = p.inlineFields orelse continue;
                any = true;
                if (params == null) params = try arena.dupe(ast.Param, f.params);
                const name = try typeNameFor(arena, f.name, p.name);
                try out.append(arena, .{ .type_ = .{
                    .name = name,
                    .isPub = f.isPub,
                    .shape = .{ .record = fields },
                    .loc = p.typeLoc,
                } });
                params.?[i].typeRef = .{ .named = name };
                params.?[i].typeName = name;
                if (!ctx.fns.contains(f.name)) try ctx.fns.put(arena, f.name, .{
                    .index = i,
                    .param = p.name,
                    .type_name = name,
                    .fields = fields,
                    .params = f.params,
                });
            }
            if (params) |ps| {
                var nf = f;
                nf.params = ps;
                try out.append(arena, .{ .@"fn" = nf });
                continue;
            }
        }
        try out.append(arena, d);
    }
    if (!any) return program;
    const decls = try out.toOwnedSlice(arena);
    if (ctx.fns.count() > 0) {
        for (decls) |*d| try ctx.walk(ast.DeclKind, d);
    }
    return .{ .decls = decls };
}

test "inline types: a parameter's inline type becomes a record of the module, and a call's field labels its constructor" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    const src =
        \\fn link(props: type(href: string, label: string = "x")) -> string {
        \\    return props.href;
        \\}
        \\fn main() {
        \\    val a = link(href: "/a");
        \\}
    ;
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const program = try expand(arena, try p.parse(arena));
    try std.testing.expectEqual(@as(usize, 3), program.decls.len);
    try std.testing.expectEqualStrings("BpInline__link__props", program.decls[0].type_.name);
    try std.testing.expectEqualStrings("BpInline__link__props", program.decls[1].@"fn".params[0].typeRef.named);
    const call = program.decls[2].@"fn".body[0].expr.binding.kind.localBind.value.call.kind.call;
    try std.testing.expectEqual(@as(usize, 1), call.args.len);
    try std.testing.expectEqualStrings("props", call.args[0].label.?);
    try std.testing.expectEqualStrings("BpInline__link__props", call.args[0].value.call.kind.call.callee);
}
