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
//!   reaches it through `std_namespace.expand`, which runs first), the
//!   namespace item dropped when every use of it was such a call;
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

/// The two declarations as std writes them — each one's annotation and
/// `pub declare fn` line, taken from its module's source — as one source
/// text: what the compiler reads their signatures and cells from
/// (`registerBuiltinDecls`, `prelude_cache.builtins`, the backends' dispatch
/// and `comptime/builtins.zig`'s drift test). Null when a module no longer
/// declares its function.
pub fn declarationsText(alloc: std.mem.Allocator) error{OutOfMemory}!?[]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    inline for (@typeInfo(Fn).@"enum".fields) |fld| {
        const f: Fn = @enumFromInt(fld.value);
        const src = moduleSource(f.module()) orelse return null;
        const head = "pub declare fn " ++ fld.name ++ "(";
        const at = std.mem.indexOf(u8, src, head) orelse return null;
        const start = std.mem.lastIndexOf(u8, src[0..at], "#[") orelse at;
        const end = (std.mem.indexOfScalarPos(u8, src, at, ';') orelse return null) + 1;
        try out.appendSlice(alloc, src[start..end]);
        try out.append(alloc, '\n');
    }
    return out.items;
}

/// The two declarations parsed from their modules' own sources (each slice a
/// slice of the embedded source, as any std declaration's is): `print`,
/// then `panic`.
pub fn declarations(alloc: std.mem.Allocator) error{ OutOfMemory, StdDeclarationMissing }![]ast.FnDecl {
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    var out: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    inline for (@typeInfo(Fn).@"enum".fields) |fld| {
        const f: Fn = @enumFromInt(fld.value);
        const src = moduleSource(f.module()) orelse return error.StdDeclarationMissing;
        var lx = Lexer.init(src);
        const tokens = lx.scanAll(alloc) catch return error.StdDeclarationMissing;
        var p = Parser.init(tokens);
        const program = p.parse(alloc) catch return error.StdDeclarationMissing;
        const found = for (program.decls) |d| {
            if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, fld.name)) break d.@"fn";
        } else return error.StdDeclarationMissing;
        try out.append(alloc, found);
    }
    return out.items;
}

fn moduleSource(key: []const u8) ?[]const u8 {
    for (@import("std_prelude").pkg_modules) |spm| {
        if (std.mem.eql(u8, spm.path["std/".len..], key)) return spm.source;
    }
    return null;
}

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

/// True when an import item names what exists at build alone — std's
/// `compiler` value (decision 579): every read of it is the compiler's
/// (`parser/compiler_surface.zig`, `#[compiler.external(…)]`), so the item
/// binds nothing a backend reads and its module is no dependency.
pub fn isBuildOnlyItem(path: []const u8) bool {
    return std.mem.eql(u8, path, "compiler");
}

/// An item this pass takes out of the program: `print` / `panic` (once every
/// use was a call) and the `compiler` value.
pub fn isDroppedItem(path: []const u8) bool {
    return ofItemPath(path) != null or isBuildOnlyItem(path);
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
                .ident => |n| if (self.items.contains(n) or self.namespaces.contains(n)) try self.read.put(self.arena, n, {}),
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

/// Decision 669 — one `print` / `panic` a module's std imports reach: an item
/// (`import {failure.panic as fail}` → `fail`) or a namespace whose module
/// declares it (`import {io.terminal}` → `terminal`, read `terminal.print`).
/// `expand` drops such an import once every use was a call, so the module's
/// analysis no longer holds it; this is what it bound, for the code the module
/// writes as text and another module reads (a member a decorator hands
/// `compiler.addMember(source)`, `Reflection.stdCalls`).
pub const Item = struct {
    local: []const u8,
    callee: []const u8,
    namespace: bool,
};

/// Every `Item` the std imports of `program` bind, before `expand`.
pub fn itemsOf(arena: std.mem.Allocator, program: ast.Program) Error![]const Item {
    var out: std.ArrayListUnmanaged(Item) = .empty;
    for (program.decls) |d| switch (d) {
        .use => |u| {
            if (!fromStd(u)) continue;
            for (u.imports) |imp| {
                const whole = try imp.fullPath(arena);
                if (ofItemPath(whole)) |f| {
                    try out.append(arena, .{ .local = imp.name(), .callee = @tagName(f), .namespace = false });
                } else if (ofModule(whole)) |f| {
                    try out.append(arena, .{ .local = imp.name(), .callee = @tagName(f), .namespace = true });
                }
            }
        },
        else => {},
    };
    return out.items;
}

/// Decision 669 — rewrite the calls in `ptr` (code another module wrote, e.g.
/// a member a decorator handed on as text) that `items` — that module's std
/// imports — name, into the call node `expand` writes: what the code reads
/// resolves where it was written.
pub fn rewriteWith(arena: std.mem.Allocator, items: []const Item, comptime T: type, ptr: *T) Error!void {
    if (items.len == 0) return;
    var ctx = Ctx{ .arena = arena };
    for (items) |it| {
        const f = std.meta.stringToEnum(Fn, it.callee) orelse continue;
        if (it.namespace) try ctx.namespaces.put(arena, it.local, f) else try ctx.items.put(arena, it.local, f);
    }
    try ctx.walk(T, ptr);
}

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
    var build_only = false;
    for (program.decls) |d| if (d == .use and fromStd(d.use)) for (d.use.imports) |imp| {
        if (isBuildOnlyItem(try imp.fullPath(arena))) build_only = true;
    };
    if (ctx.items.count() == 0 and ctx.namespaces.count() == 0 and ctx.own == null and !build_only) return program;
    for (program.decls) |*d| try ctx.walk(ast.DeclKind, @constCast(d));
    if (ctx.items.count() == 0 and ctx.namespaces.count() == 0 and !build_only) return program;

    // The items every use of which became the call node bind nothing left;
    // so does a namespace (`import {io.terminal}`) every use of which was
    // such a call (144 B-151): the program reaches none of the module's other
    // members, so none of their hosts is linked.
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
                if (ofModule(whole) != null and ctx.namespaces.contains(imp.name()) and !ctx.read.contains(imp.name())) continue;
                if (isBuildOnlyItem(whole)) continue;
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
    // `print`, `fail` and `failure` (every use of it was the `panic` call)
    // leave the import.
    try std.testing.expect(program.decls[0] == .@"fn");
    const body = program.decls[0].@"fn".body;
    const want = [_][]const u8{ "print", "panic", "panic" };
    for (body, want) |st, w| {
        const cc = st.expr.call.kind.call;
        try std.testing.expect(cc.is_builtin);
        try std.testing.expect(cc.receiver == null);
        try std.testing.expectEqualStrings(w, cc.callee);
    }
}

test "std calls: the declarations are read from io/terminal.bp and failure.bp" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const text = (try declarationsText(arena_state.allocator())).?;
    try std.testing.expect(std.mem.indexOf(u8, text, "pub declare fn print(..values: unknown[]);") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "pub declare fn panic(message: string = \"panic\") -> noreturn;") != null);
    try std.testing.expect(std.mem.startsWith(u8, text, "#["));
    const decls = try declarations(arena_state.allocator());
    try std.testing.expectEqual(@as(usize, 2), decls.len);
    try std.testing.expectEqualStrings("print", decls[0].name);
    try std.testing.expectEqualStrings("panic", decls[1].name);
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

test "decision 669 — code another module wrote reaches the `print` / `panic` its imports bind" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    var lx = Lexer.init(
        \\import {failure.panic as fail, io.terminal} from "std";
        \\fn f() { fail("x"); terminal.print(1); panic("y"); }
    );
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const items = try itemsOf(arena, program);
    try std.testing.expectEqual(@as(usize, 2), items.len);
    try std.testing.expectEqualStrings("fail", items[0].local);
    try std.testing.expectEqualStrings("panic", items[0].callee);
    try std.testing.expect(items[1].namespace);
    var body = program.decls[1].@"fn";
    try rewriteWith(arena, items, ast.FnDecl, &body);
    const calls = [_][]const u8{ "panic", "print", "panic" };
    const builtin = [_]bool{ true, true, false };
    for (body.body, 0..) |s, i| {
        const cc = s.expr.call.kind.call;
        try std.testing.expectEqualStrings(calls[i], cc.callee);
        try std.testing.expectEqual(builtin[i], cc.is_builtin);
    }
}
