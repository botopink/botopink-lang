//! Decision 907 — a function with a `syntax` parameter is one kind, and the
//! place it is used decides how it is read: `#[f]` applies it as a decorator,
//! the annotated declaration its first `syntax` parameter (663, 716); `f(e)`
//! expands it at the call, the written expression its `syntax` parameter
//! (719, 841). The signature decides nothing.
//!
//! The two uses run on two machineries — the decorator's (`syntax_params.zig`
//! reads the first `syntax` as the declaration handle) and the template's
//! (`compiler_surface.zig` reads the body as a build body answering code) —,
//! so after the parse, before either pass, each top-level function whose
//! first parameter is `syntax` is given the form its module's uses ask for
//! (`FnDecl.syntaxUse`):
//!
//! - annotated only, or called only: the function itself, in that form;
//! - annotated and called: the function stays the decorator, and a copy of
//!   it in the call's form, under `called_prefix` ++ its name (no source
//!   spells it), receives the module's calls, renamed here. Each copy is
//!   checked by its own use's rules against the one declared type (907 (2)).
//!
//! In the decorator's form the body's top-level `return <code>` gives back
//! nothing: an annotation stands where no expression does, so the code a body
//! answers is the call's alone, as a template annotation's is (311) — and the
//! function answers nothing there (907 (2): the return answers nothing or `T`
//! alike). A function the module neither annotates with nor calls keeps the
//! form its signature gives (`ast.expandedAtCall`) until the use travels with
//! the import (B-69). A `syntax` function whose first parameter is no `syntax`
//! one is only ever called (907 (2)) and is not touched here.

const std = @import("std");
const ast = @import("../ast.zig");
const mayHoldExpr = @import("../comptime/std_namespace.zig").mayHoldExpr;
const deepCopy = @import("../comptime/context_lower.zig").deepCopy;

/// The prefix of the copy that receives the calls of a function the module
/// both annotates with and calls (no source can spell it; a diagnostic drops
/// it, `comptime/error.zig`).
pub const called_prefix = ast.syntax_called_prefix;

const Uses = struct {
    annotated: bool = false,
    called: bool = false,
};

/// Give each top-level function whose first parameter is `syntax` the form
/// its uses ask for (see the file comment).
pub fn applyProgram(alloc: std.mem.Allocator, program: *ast.Program) error{OutOfMemory}!void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const scratch = arena_state.allocator();

    var uses: std.StringHashMapUnmanaged(Uses) = .empty;
    for (program.decls) |d| if (d == .@"fn" and isCandidate(d.@"fn")) try uses.put(scratch, d.@"fn".name, .{});
    if (uses.count() == 0) return;

    var collect: Collect = .{ .uses = &uses };
    for (program.decls) |*d| collect.walk(ast.DeclKind, d);

    var twins: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var renames: std.StringHashMapUnmanaged([]const u8) = .empty;
    for (program.decls) |*d| {
        if (d.* != .@"fn" or !isCandidate(d.@"fn")) continue;
        const f = &d.@"fn";
        const u = uses.get(f.name) orelse continue;
        if (u.annotated and u.called) {
            var twin = deepCopy(ast.FnDecl, alloc, f.*) catch return error.OutOfMemory;
            twin.name = try std.mem.concat(alloc, u8, &.{ called_prefix, f.name });
            twin.isPub = false;
            twin.isDefault = false;
            twin.pubByDefault = false;
            twin.docComment = null;
            twin.comment = null;
            twin.moduleComment = null;
            twin.annotations = &.{};
            twin.syntaxUse = .call;
            try twins.append(scratch, .{ .@"fn" = twin });
            try renames.put(scratch, f.name, twin.name);
            try asDecorator(alloc, f);
        } else if (u.annotated) {
            try asDecorator(alloc, f);
        } else if (u.called) {
            f.syntaxUse = .call;
        }
    }
    if (renames.count() > 0) {
        var rename: Rename = .{ .renames = &renames };
        for (program.decls) |*d| rename.walk(ast.DeclKind, d);
    }
    if (twins.items.len == 0) return;
    // Each copy right after the function it copies, so the program keeps its
    // order (a blank line before none of them).
    const n = program.decls.len + twins.items.len;
    const decls = try alloc.alloc(ast.DeclKind, n);
    const blank: []bool = if (program.blankLineBefore.len > 0) try alloc.alloc(bool, n) else &.{};
    var at: usize = 0;
    var next: usize = 0;
    for (program.decls, 0..) |d, i| {
        decls[at] = d;
        if (blank.len > 0) blank[at] = program.blankLineBefore[i];
        at += 1;
        if (next < twins.items.len and d == .@"fn" and renames.get(d.@"fn".name) != null and
            std.mem.eql(u8, twins.items[next].@"fn".name, renames.get(d.@"fn".name).?))
        {
            decls[at] = twins.items[next];
            if (blank.len > 0) blank[at] = false;
            at += 1;
            next += 1;
        }
    }
    alloc.free(program.decls);
    if (program.blankLineBefore.len > 0) alloc.free(program.blankLineBefore);
    program.decls = decls[0..at];
    program.blankLineBefore = if (blank.len > 0) blank[0..at] else &.{};
}

/// A top-level function with a body whose first parameter is `syntax` (no
/// `self` receiver, no template text `syntax q: string`): the one kind 907
/// reads by its use.
fn isCandidate(f: ast.FnDecl) bool {
    if (f.isDeclare or f.body.len == 0) return false;
    // Decision 788 — a `comptime { … }` block's decorator is no use of a
    // function the program writes.
    if (std.mem.startsWith(u8, f.name, ast.comptime_block_prefix)) return false;
    if (f.params.len == 0) return false;
    const p = f.params[0];
    if (p.arrival != .syntax or p.variadic or std.mem.eql(u8, p.name, "self")) return false;
    if (ast.templateTextIndex(f.params) != null) return false;
    if (f.returnType) |rt| if (rt.isTemplateReturnType()) return false;
    return ast.syntaxExprIndex(f.params) == 0;
}

/// The decorator's form: the body's top-level `return <code>` gives back
/// nothing, and the function answers nothing (see the file comment).
fn asDecorator(alloc: std.mem.Allocator, f: *ast.FnDecl) error{OutOfMemory}!void {
    f.syntaxUse = .decorator;
    for (f.body) |*s| if (s.expr == .jump and s.expr.jump.kind == .@"return") {
        s.expr.jump.kind.@"return" = null;
    };
    if (ast.answersNothing(f.returnType)) return;
    if (f.returnType) |*rt| rt.deinit(alloc);
    f.returnType = .{ .named = "void" };
}

const Collect = struct {
    uses: *std.StringHashMapUnmanaged(Uses),

    fn walk(self: *Collect, comptime T: type, ptr: *T) void {
        if (T == ast.Annotation) {
            const a = ptr.*;
            if (!a.is_builtin and a.template == null and a.templateText == null) {
                if (self.uses.getPtr(a.name)) |u| u.annotated = true;
            }
            return;
        }
        if (T == ast.Expr) if (calledName(ptr)) |name| {
            if (self.uses.getPtr(name)) |u| u.called = true;
        };
        if (T == ast.ImportDecl) return;
        descend(self, T, ptr);
    }
};

const Rename = struct {
    renames: *std.StringHashMapUnmanaged([]const u8),

    fn walk(self: *Rename, comptime T: type, ptr: *T) void {
        if (T == ast.Annotation or T == ast.ImportDecl) return;
        if (T == ast.Expr) if (calledName(ptr)) |name| {
            if (self.renames.get(name)) |to| ptr.call.kind.call.callee = to;
        };
        descend(self, T, ptr);
    }
};

/// The name a bare call `f(…)` (or `` f @`…` ``) calls — no receiver, no
/// builtin —, or null for any other expression.
fn calledName(e: *const ast.Expr) ?[]const u8 {
    if (e.* != .call or e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (c.receiver != null or c.is_builtin or c.callee.len == 0) return null;
    return c.callee;
}

fn descend(self: anytype, comptime T: type, ptr: *T) void {
    switch (@typeInfo(T)) {
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            if (comptime mayHoldExpr(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                    self.walk(@TypeOf(payload.*), payload);
                },
            }
        },
        .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
        .pointer => |p| switch (p.size) {
            .one => if (comptime mayHoldExpr(p.child)) self.walk(p.child, @constCast(ptr.*)),
            .slice => if (comptime mayHoldExpr(p.child)) {
                for (ptr.*) |*e| self.walk(p.child, @constCast(e));
            },
            else => {},
        },
        .array => |arr| if (comptime mayHoldExpr(arr.child)) {
            for (ptr) |*e| self.walk(arr.child, e);
        },
        else => {},
    }
}

test "a function annotated and called gets a copy that receives the calls" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\fn log(syntax e: unknown) -> void { return code @`print(1)`; }
        \\fn mark(syntax decl: unknown) -> void {}
        \\fn twice(syntax e: i32) -> i32 { return code @`${e} + ${e}`; }
        \\#[log] #[mark] val a = 1;
        \\fn main() -> void { log(a); }
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    try std.testing.expectEqualStrings("log", program.decls[0].@"fn".name);
    try std.testing.expect(program.decls[0].@"fn".syntaxUse.? == .decorator);
    try std.testing.expect(program.decls[0].@"fn".params[0].typeRef.isDeclType());
    try std.testing.expectEqualStrings(called_prefix ++ "log", program.decls[1].@"fn".name);
    try std.testing.expect(program.decls[1].@"fn".syntaxUse.? == .call);
    try std.testing.expect(program.decls[1].@"fn".params[0].typeRef.isExprType());
    // A marker's empty body has nothing to expand (604): untouched.
    try std.testing.expect(program.decls[2].@"fn".syntaxUse == null);
    try std.testing.expect(program.decls[2].@"fn".params[0].typeRef.isDeclType());
    try std.testing.expect(program.decls[3].@"fn".syntaxUse == null);
    const main = program.decls[5].@"fn";
    try std.testing.expectEqualStrings(called_prefix ++ "log", main.body[0].expr.call.kind.call.callee);
}
