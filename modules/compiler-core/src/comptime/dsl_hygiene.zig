//! Decision 112 — DSL hygiene: each name of a template's built code resolves
//! in the scope of whoever wrote it.
//!
//! A template (`-> @Expr<T>` / `-> @ExprCustom<T>`) hands back code text with
//! two authors: the library wrote the frame (`e.build("double(" + … + ")")`),
//! the consumer wrote what is between the quotes (`e.text()`). The text is
//! spliced into the consumer's module, so without this pass every name in it
//! resolved there: a private helper of the library was unbound, and a consumer
//! declaring its own `double` captured the library's call.
//!
//! The consumer's spans are the places the capture's own text reappears
//! verbatim in the built code (a hole's placeholder is the consumer's too, and
//! is spliced back by `infer.substituteHoles`). Every other name is the
//! library's: when the library's module declares it, the name is renamed to
//! an alias (`__bp_tpl_<owner>__<name>`) bound to that declaration — its
//! identity, `<lib>@<path>@@<Decl>` (decision 109), not a copy — and
//! `comptime.zig` (`withTemplateImports`) imports the alias from the owner so
//! every backend lowers it as the cross-module reference it already knows. A
//! name the library does not declare (a builtin, a local of the built code, a
//! name the library itself imports) keeps resolving where it did.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("template.zig");

pub const Error = error{OutOfMemory};

/// The byte ranges of `src` the consumer wrote: each non-empty text piece of
/// each capture, at every place it occurs.
pub fn userSpans(arena: std.mem.Allocator, src: []const u8, captures: []const template.CapturedExpr) Error![]const [2]usize {
    var spans: std.ArrayListUnmanaged([2]usize) = .empty;
    for (captures) |*cap| {
        var pieces: std.ArrayListUnmanaged([]const u8) = .empty;
        if (cap.text) |t| {
            try pieces.append(arena, t);
        } else if (cap.node.* == .literal and cap.node.literal.kind == .stringTemplate) {
            for (cap.node.literal.kind.stringTemplate.parts) |part| switch (part) {
                .text => |t| try pieces.append(arena, t),
                .expr => {},
            };
        }
        for (pieces.items) |piece| {
            if (piece.len == 0) continue;
            var from: usize = 0;
            while (std.mem.indexOfPos(u8, src, from, piece)) |at| {
                try spans.append(arena, .{ at, at + piece.len });
                from = at + piece.len;
            }
        }
    }
    return spans.items;
}

/// Renames the library's names in `root` (the parsed built code of `src`).
/// `resolve` answers a name the owner module declares with the alias to bind
/// it under, or null when the owner does not declare it.
pub fn apply(
    arena: std.mem.Allocator,
    root: *ast.Expr,
    src: []const u8,
    spans: []const [2]usize,
    resolver: anytype,
) Error!void {
    var ctx = Ctx(@TypeOf(resolver)){
        .arena = arena,
        .src = src,
        .spans = spans,
        .resolver = resolver,
        .locals = std.StringHashMap(void).init(arena),
    };
    // A name the built code binds itself (a lambda parameter, a `val`) is
    // the code's own, whoever wrote it.
    try ctx.collectLocals(ast.Expr, root);
    try ctx.walk(ast.Expr, root);
}

/// Whether a value of `T` can reach an `ast.Expr` — prunes strings, locations
/// and type references, which the walk would otherwise visit byte by byte.
fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

fn Ctx(comptime Resolver: type) type {
    return struct {
        arena: std.mem.Allocator,
        src: []const u8,
        spans: []const [2]usize,
        resolver: Resolver,
        locals: std.StringHashMap(void),

        const Self = @This();

        fn offsetOf(self: *const Self, loc: ast.Loc) ?usize {
            if (loc.line == 0 or loc.col == 0) return null;
            var line: usize = 1;
            var i: usize = 0;
            while (line < loc.line) : (i += 1) {
                if (i >= self.src.len) return null;
                if (self.src[i] == '\n') line += 1;
            }
            const off = i + loc.col - 1;
            return if (off <= self.src.len) off else null;
        }

        /// True when the name at `loc` was written by the library.
        fn libraryWrote(self: *const Self, loc: ast.Loc) bool {
            const off = self.offsetOf(loc) orelse return false;
            for (self.spans) |s| if (off >= s[0] and off < s[1]) return false;
            return true;
        }

        fn rename(self: *Self, name: []const u8, loc: ast.Loc) Error!?[]const u8 {
            if (self.locals.contains(name)) return null;
            if (!self.libraryWrote(loc)) return null;
            return try self.resolver.aliasFor(name);
        }

        fn visitExpr(self: *Self, e: *ast.Expr) Error!void {
            switch (e.*) {
                .identifier => |*id| switch (id.kind) {
                    .ident => |n| if (try self.rename(n, id.loc)) |alias| {
                        id.kind = .{ .ident = alias };
                    },
                    else => {},
                },
                .call => |*c| switch (c.kind) {
                    .call => |*cc| if (cc.receiver == null and cc.calleeExpr == null and !cc.is_builtin) {
                        if (try self.rename(cc.callee, c.loc)) |alias| cc.callee = alias;
                    },
                    else => {},
                },
                else => {},
            }
        }

        fn noteLocals(self: *Self, e: *const ast.Expr) Error!void {
            switch (e.*) {
                .function => |f| for (f.kind.params) |p| try self.locals.put(p, {}),
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| try self.locals.put(lb.name, {}),
                    else => {},
                },
                else => {},
            }
        }

        const Mode = enum { locals, rename };

        fn collectLocals(self: *Self, comptime T: type, ptr: *T) Error!void {
            try self.walkIn(.locals, T, ptr);
        }

        fn walk(self: *Self, comptime T: type, ptr: *T) Error!void {
            try self.walkIn(.rename, T, ptr);
        }

        /// Every field of every AST node, by type (`alias_erase.zig`'s walk).
        fn walkIn(self: *Self, comptime mode: Mode, comptime T: type, ptr: *T) Error!void {
            if (T == ast.Expr) switch (mode) {
                .locals => try self.noteLocals(ptr),
                .rename => try self.visitExpr(ptr),
            };
            if (comptime !mayHoldExpr(T)) return;
            switch (@typeInfo(T)) {
                .@"struct" => |st| inline for (st.fields) |f| {
                    if (f.is_comptime) continue;
                    try self.walkIn(mode, f.type, &@field(ptr.*, f.name));
                },
                .@"union" => |u| if (u.tag_type != null) {
                    switch (ptr.*) {
                        inline else => |*payload| try self.walkIn(mode, @TypeOf(payload.*), payload),
                    }
                },
                .optional => |o| if (ptr.*) |*inner| try self.walkIn(mode, o.child, inner),
                .pointer => |pi| switch (pi.size) {
                    .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") {
                        try self.walkIn(mode, pi.child, @constCast(ptr.*));
                    },
                    .slice => for (ptr.*) |*e| try self.walkIn(mode, pi.child, @constCast(e)),
                    else => {},
                },
                else => {},
            }
        }
    };
}
