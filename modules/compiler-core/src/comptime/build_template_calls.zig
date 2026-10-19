//! Decision 637 — a template answering `anyvalue` called in a template's
//! body (`` return code @`Element(tag: ${tag})`; ``) runs where that body
//! runs, at build: the holes of its text are expressions of the body, whose
//! values — a `syntax` value or a value known at build — the called template
//! reads (`compiler.holes(q)`, `compiler.isSyntax(v)`), and the call's value
//! is the code it built (`{'__bp_ast', Node}` from its `compiler.ast`).
//!
//! The body's comptime module is emitted from its declaration as written, so
//! each such call is lowered here before it is: `` f @`text` `` becomes
//! `__bp_build_f(__bp_captureOf("text", [h0, h1, …]))`, each `hi` the i-th
//! hole's expression parsed from the text (`Ctx.holes`), and the called
//! template travels with the body under that name (the resident prelude
//! already has a `code/1`). `lower` copies what it changes and leaves the
//! declaration it was given as it was.
const std = @import("std");
const ast = @import("../ast.zig");
const prelude = @import("runtime/prelude.zig");

pub const Error = std.mem.Allocator.Error || error{HoleNotAnExpression};

/// The name a lowered call's template travels under in the body's module.
pub fn carriedName(arena: std.mem.Allocator, callee: []const u8) std.mem.Allocator.Error![]const u8 {
    return std.fmt.allocPrint(arena, "__bp_build_{s}", .{callee});
}

/// Whether `f` answers `anyvalue` (a template whose return the parser read
/// as `__Expr<__anyvalue>`, `parser/compiler_surface.zig`).
pub fn answersAnyvalue(f: ast.FnDecl) bool {
    const rt = f.returnType orelse return false;
    if (rt != .generic or !std.mem.eql(u8, rt.generic.name, ast.expr_type_name) or rt.generic.args.len != 1) return false;
    const inner = rt.generic.args[0];
    return inner == .named and std.mem.eql(u8, inner.named, ast.anyvalue_param_name);
}

/// `ctx` answers `isBuildTemplate(callee) bool` (the callee is a template
/// answering `anyvalue` where the body is written) and `holes(text, textLoc)
/// Error![]ast.Expr` (the text's hole expressions, located in it).
pub fn Lowering(comptime Ctx: type) type {
    return struct {
        arena: std.mem.Allocator,
        ctx: Ctx,
        /// The templates the lowered calls name, each once.
        callees: std.ArrayListUnmanaged([]const u8) = .empty,

        const Self = @This();

        /// `f` with its build template calls lowered, or `f` itself when it
        /// has none.
        pub fn lower(self: *Self, f: ast.FnDecl) Error!ast.FnDecl {
            if (!self.holdsAny([]ast.Stmt, f.body)) return f;
            var out = f;
            out.body = try self.copy([]ast.Stmt, f.body);
            return out;
        }

        fn isBuildCall(self: *Self, e: ast.Expr) bool {
            if (e != .call or e.call.kind != .call) return false;
            const c = e.call.kind.call;
            if (c.is_builtin or c.receiver != null or c.templateText == null or c.args.len != 1) return false;
            return self.ctx.isBuildTemplate(c.callee);
        }

        fn holdsAny(self: *Self, comptime T: type, v: T) bool {
            if (T == ast.Expr and self.isBuildCall(v)) return true;
            if (comptime !mayHoldExpr(T)) return false;
            switch (@typeInfo(T)) {
                .@"struct" => |st| {
                    inline for (st.fields) |fd| {
                        if (fd.is_comptime) continue;
                        if (self.holdsAny(fd.type, @field(v, fd.name))) return true;
                    }
                    return false;
                },
                .@"union" => |u| {
                    if (u.tag_type == null) return false;
                    switch (v) {
                        inline else => |payload| return self.holdsAny(@TypeOf(payload), payload),
                    }
                },
                .optional => |o| return if (v) |inner| self.holdsAny(o.child, inner) else false,
                .pointer => |pi| switch (pi.size) {
                    .one => return if (@typeInfo(pi.child) == .@"fn" or @typeInfo(pi.child) == .@"opaque") false else self.holdsAny(pi.child, v.*),
                    .slice => {
                        for (v) |item| if (self.holdsAny(pi.child, item)) return true;
                        return false;
                    },
                    else => return false,
                },
                else => return false,
            }
        }

        fn copy(self: *Self, comptime T: type, v: T) Error!T {
            if (T == ast.Expr and self.isBuildCall(v)) return self.lowerCall(v);
            if (comptime !mayHoldExpr(T)) return v;
            switch (@typeInfo(T)) {
                .@"struct" => |st| {
                    var out = v;
                    inline for (st.fields) |fd| {
                        if (fd.is_comptime) continue;
                        @field(out, fd.name) = try self.copy(fd.type, @field(v, fd.name));
                    }
                    return out;
                },
                .@"union" => |u| {
                    if (u.tag_type == null) return v;
                    switch (v) {
                        inline else => |payload, tag| return @unionInit(T, @tagName(tag), try self.copy(@TypeOf(payload), payload)),
                    }
                },
                .optional => |o| return if (v) |inner| try self.copy(o.child, inner) else null,
                .pointer => |pi| switch (pi.size) {
                    .one => {
                        if (@typeInfo(pi.child) == .@"fn" or @typeInfo(pi.child) == .@"opaque") return v;
                        if (!self.holdsAny(pi.child, v.*)) return v;
                        const p = try self.arena.create(pi.child);
                        p.* = try self.copy(pi.child, v.*);
                        return p;
                    },
                    .slice => {
                        if (!self.holdsAny(T, v)) return v;
                        const out = try self.arena.alloc(pi.child, v.len);
                        for (v, out) |item, *o| o.* = try self.copy(pi.child, item);
                        return out;
                    },
                    else => return v,
                },
                else => return v,
            }
        }

        fn lowerCall(self: *Self, e: ast.Expr) Error!ast.Expr {
            const c = e.call.kind.call;
            const text = c.templateText.?;
            const loc = e.call.loc;
            const textLoc = c.args[0].value.getLoc();
            const holes = try self.ctx.holes(text, textLoc);
            const boxed = try self.arena.alloc(ast.Expr, holes.len);
            @memcpy(boxed, holes);
            const list = try self.box(.{ .collection = .{ .loc = textLoc, .kind = .{ .arrayLit = .{ .elems = boxed } } } });
            const textLit = try self.box(.{ .literal = .{ .loc = textLoc, .kind = .{ .stringLit = try quoted(self.arena, text) } } });
            const captureArgs = try self.arena.alloc(ast.CallArg, 2);
            captureArgs[0] = .{ .label = null, .value = textLit };
            captureArgs[1] = .{ .label = null, .value = list };
            const capture = try self.box(.{ .call = .{ .loc = textLoc, .kind = .{ .call = .{
                .receiver = null,
                .callee = prelude.capture_of_fn,
                .is_builtin = false,
                .args = captureArgs,
                .trailing = &.{},
            } } } });
            const args = try self.arena.alloc(ast.CallArg, 1);
            args[0] = .{ .label = null, .value = capture };
            for (self.callees.items) |n| {
                if (std.mem.eql(u8, n, c.callee)) break;
            } else try self.callees.append(self.arena, c.callee);
            return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
                .receiver = null,
                .callee = try carriedName(self.arena, c.callee),
                .is_builtin = false,
                .args = args,
                .trailing = &.{},
            } } } };
        }

        fn box(self: *Self, e: ast.Expr) std.mem.Allocator.Error!*ast.Expr {
            const p = try self.arena.create(ast.Expr);
            p.* = e;
            return p;
        }
    };
}

/// A string literal's text for `text`'s bytes (the lexeme between the
/// quotes): `\` and `"` escaped, a line break written `\n`.
fn quoted(arena: std.mem.Allocator, text: []const u8) std.mem.Allocator.Error![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (text) |ch| switch (ch) {
        '\\' => try out.appendSlice(arena, "\\\\"),
        '"' => try out.appendSlice(arena, "\\\""),
        '\n' => try out.appendSlice(arena, "\\n"),
        '\r' => try out.appendSlice(arena, "\\r"),
        '\t' => try out.appendSlice(arena, "\\t"),
        else => try out.append(arena, ch),
    };
    return out.items;
}

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}
