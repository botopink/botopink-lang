//! Decision 606 (2) — the two std functions a program calls by an import:
//! `print` of `io/terminal.bp` and `panic` of `failure.bp`.
//!
//! Each is an ordinary std declaration (`pub declare fn print(..values:
//! unknown[])`, `pub declare fn panic(message: string = "panic") ->
//! noreturn`), imported where it is used — std's own modules included, by the
//! same import (`import {failure.panic};`). What the compiler does at a call
//! of one is the same whatever the spelling: the checker types each argument
//! as text (`Display`, decision 27; the text holes, 530) and every backend
//! lowers the call from the declaration's cells. So a call that resolves to
//! one of them is rewritten here, on the parsed program, into the one call
//! node the checker and the backends read — the call of `print` / `panic`
//! with no receiver, marked `is_builtin` — before either sees the module:
//!
//! - `import {io.terminal.print} from "std"; print(x)` (an alias included,
//!   `import {failure.panic as fail}`), the item dropped when every use of it
//!   was a call: it binds nothing a backend reads;
//! - `import {io.terminal} from "std"; terminal.print(x)` (a folder, `io`,
//!   reaches it through `std_namespace.expand`, which runs first);
//! - inside `io/terminal.bp` and `failure.bp`, the module's own bare call.
//!
//! A name of the module's own — a `fn print` it declares — is never touched:
//! it is no import.
const std = @import("std");
const ast = @import("../ast.zig");

const Error = error{OutOfMemory};

pub const Fn = enum {
    print,
    panic,

    /// The std module that declares it.
    pub fn module(f: Fn) []const u8 {
        return switch (f) {
            .print => "io/terminal",
            .panic => "failure",
        };
    }
};

fn ofModule(key: []const u8) ?Fn {
    inline for (@typeInfo(Fn).@"enum".fields) |fld| {
        const f: Fn = @enumFromInt(fld.value);
        if (std.mem.eql(u8, f.module(), key)) return f;
    }
    return null;
}

/// The function a whole import path names (`io/terminal/print`), or null.
pub fn ofItemPath(path: []const u8) ?Fn {
    inline for (@typeInfo(Fn).@"enum".fields) |fld| {
        const f: Fn = @enumFromInt(fld.value);
        const m = f.module();
        if (path.len == m.len + 1 + fld.name.len and std.mem.startsWith(u8, path, m) and path[m.len] == '/' and std.mem.endsWith(u8, path, fld.name)) return f;
    }
    return null;
}

fn fromStd(u: ast.ImportDecl) bool {
    return switch (u.source) {
        .module => |m| std.mem.eql(u8, m, "std"),
        .root, .key => false,
    };
}

const Ctx = struct {
    arena: std.mem.Allocator,
    /// An imported item's local → the function it names.
    items: std.StringHashMapUnmanaged(Fn) = .empty,
    /// A namespace local → the function its module declares.
    namespaces: std.StringHashMapUnmanaged(Fn) = .empty,
    /// The module's own function, written bare inside its module.
    own: ?Fn = null,
    /// Item locals read as a value somewhere: their import stays.
    read: std.StringHashMapUnmanaged(void) = .empty,

    fn rewriteCall(self: *Ctx, cc: anytype) void {
        if (cc.is_builtin) return;
        if (cc.receiver) |r| {
            if (r.* != .identifier) return;
            const n = switch (r.identifier.kind) {
                .ident => |n| n,
                else => return,
            };
            const f = self.namespaces.get(n) orelse return;
            if (!std.mem.eql(u8, cc.callee, @tagName(f))) return;
            cc.receiver = null;
            cc.is_builtin = true;
            cc.callee = @tagName(f);
            return;
        }
        if (self.items.get(cc.callee)) |f| {
            cc.is_builtin = true;
            cc.callee = @tagName(f);
            return;
        }
        if (self.own) |f| if (std.mem.eql(u8, cc.callee, @tagName(f))) {
            cc.is_builtin = true;
        };
    }

    fn walk(self: *Ctx, comptime T: type, ptr: *T) Error!void {
        if (T == ast.ImportDecl) return;
        if (T == ast.Expr) switch (ptr.*) {
            .call => |*c| switch (c.kind) {
                .call => |*cc| self.rewriteCall(cc),
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (self.items.contains(n)) try self.read.put(self.arena, n, {}),
                else => {},
            },
            else => {},
        };
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

const mayHoldExpr = @import("std_namespace.zig").mayHoldExpr;

/// Rewrite `program` in place (the arena-owned parse of one module). `key` is
/// the module's std key (`io/terminal`) when it is one of std's, else null.
pub fn expand(arena: std.mem.Allocator, program: ast.Program, key: ?[]const u8) Error!ast.Program {
    var ctx = Ctx{ .arena = arena };
    if (key) |k| ctx.own = ofModule(k);
    for (program.decls) |d| switch (d) {
        .use => |u| {
            if (!fromStd(u)) continue;
            for (u.imports) |imp| {
                const whole = try imp.fullPath(arena);
                if (ofItemPath(whole)) |f| {
                    try ctx.items.put(arena, imp.name(), f);
                } else if (ofModule(whole)) |f| {
                    try ctx.namespaces.put(arena, imp.name(), f);
                }
            }
        },
        else => {},
    };
    if (ctx.items.count() == 0 and ctx.namespaces.count() == 0 and ctx.own == null) return program;
    for (program.decls) |*d| try ctx.walk(ast.DeclKind, @constCast(d));
    if (ctx.items.count() == 0) return program;

    // The items every use of which became the call node bind nothing left.
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (program.decls) |d| switch (d) {
        .use => |u| {
            if (!fromStd(u)) {
                try decls.append(arena, d);
                continue;
            }
            var kept: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
            for (u.imports) |imp| {
                const whole = try imp.fullPath(arena);
                if (ofItemPath(whole) != null and !ctx.read.contains(imp.name())) continue;
                try kept.append(arena, imp);
            }
            if (kept.items.len == 0) continue;
            var nu = u;
            nu.imports = try kept.toOwnedSlice(arena);
            try decls.append(arena, .{ .use = nu });
        },
        else => try decls.append(arena, d),
    };
    return .{ .decls = try decls.toOwnedSlice(arena) };
}

test "std calls: an imported print, a namespace's panic, an alias" {
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\import {io.terminal.print, failure, failure.panic as fail} from "std";
        \\fn main() {
        \\    print(1, 2);
        \\    failure.panic("a");
        \\    fail("b");
        \\}
    ;
    var lx = Lexer.init(src);
    var p = Parser.init(try lx.scanAll(arena));
    const program = try expand(arena, try p.parse(arena), null);
    // `print` and `fail` leave the import; `failure` stays.
    try std.testing.expectEqual(@as(usize, 1), program.decls[0].use.imports.len);
    try std.testing.expectEqualStrings("failure", program.decls[0].use.imports[0].name());
    const body = program.decls[1].@"fn".body;
    const want = [_][]const u8{ "print", "panic", "panic" };
    for (body, want) |st, w| {
        const cc = st.expr.call.kind.call;
        try std.testing.expect(cc.is_builtin);
        try std.testing.expect(cc.receiver == null);
        try std.testing.expectEqualStrings(w, cc.callee);
    }
}

test "std calls: a module's own print is no import" {
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\fn print(x: i32) {}
        \\fn main() { print(1); }
    ;
    var lx = Lexer.init(src);
    var p = Parser.init(try lx.scanAll(arena));
    const program = try expand(arena, try p.parse(arena), null);
    try std.testing.expect(!program.decls[1].@"fn".body[0].expr.call.kind.call.is_builtin);
}
