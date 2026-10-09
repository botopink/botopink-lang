//! Decision 320's string reads, hoisted per binding (front 04-js step 10).
//!
//! `length`, `at`, `indexOf` and `lastIndexOf` count codepoints on commonJS
//! through `js_prelude`'s helpers, each of which asks `__bp_has_surrogate(s)`
//! on every call. A string is immutable, so the answer belongs to the BINDING
//! that holds it: this pass finds, in one function, the reads whose receiver
//! is a name bound exactly once in that function — a parameter or a `val` —
//! and gives the binding a slot, `let <name>$sp = null;`, next to its
//! declaration. A read then asks the slot (`<name>$sp ??=
//! __bp_has_surrogate(<name>)`) and takes the native JavaScript read when the
//! string holds no surrogate: the test runs once per binding, not once per
//! read. A `val` bound to a string literal holding no surrogate needs no test
//! at all, and neither does such a literal read directly.
//!
//! Soundness rests on two walks over the same function:
//!
//! 1. every binder of the function — parameters, `val` / `var`, destructuring,
//!    `if val`, loop and lambda parameters, `case` and `val assert` patterns —
//!    is counted per name, and every assignment to a name marks it. A name is
//!    a candidate only when it has ONE binder, that binder is a parameter or a
//!    `val` the backend declares as a plain `const`, and nothing assigns it.
//!    A pattern contributes every name it spells, so a walk that
//!    over-counts only drops candidates;
//! 2. a scoped walk approves a read only where its candidate is in scope: a
//!    parameter everywhere in the body, a `val` in the statements after it in
//!    its own statement list (nested blocks and closures included). With one
//!    binder in the function, a name read there can only be that binder.
//!
//! The switches below have no `else`, so a new expression kind does not
//! compile until it is placed. Code the walks do not open (a parameter's
//! default) gets no approval and keeps the helper call.

const std = @import("std");
const ast = @import("../../ast.zig");

/// What the backend writes for one approved read, keyed by the address of the
/// read's receiver node.
pub const Read = union(enum) {
    /// The receiver is a string literal holding no surrogate, or a `val`
    /// bound to one: the native JavaScript read.
    native,
    /// The receiver's slot (`<name>$sp`): native read when it answers false.
    slot: []const u8,
};

pub const Slots = struct {
    reads: std.AutoHashMapUnmanaged(usize, Read) = .empty,
    /// The `val`s whose slot a read uses, keyed by the address of the bound
    /// value node — the backend writes `let <name>$sp = null;` after them.
    vals: std.AutoHashMapUnmanaged(usize, []const u8) = .empty,
    /// The parameters whose slot a read uses — declared first in the body.
    params: std.ArrayListUnmanaged([]const u8) = .empty,

    pub fn read(self: *const Slots, receiver: *const ast.Expr) ?Read {
        return self.reads.get(@intFromPtr(receiver));
    }

    pub fn valSlot(self: *const Slots, value: *const ast.Expr) ?[]const u8 {
        return self.vals.get(@intFromPtr(value));
    }
};

/// The slot of the binding `name`.
pub fn slotName(gpa: std.mem.Allocator, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(gpa, "{s}$sp", .{name});
}

/// True when the string literal's source text holds no surrogate once decoded:
/// no four-byte UTF-8 sequence (a character past U+FFFF is a surrogate pair in
/// JavaScript) and no `\u` escape (which may spell one). Conservative.
pub fn literalSurrogateFree(text: []const u8) bool {
    for (text, 0..) |c, i| {
        if (c >= 0xF0) return false;
        if (c == '\\' and i + 1 < text.len and text[i + 1] == 'u') return false;
    }
    return true;
}

const Binder = struct {
    count: u32 = 0,
    /// The one binder is a parameter or a plain `val`.
    slot_kind: bool = false,
    assigned: bool = false,
    /// A `val` bound to a surrogate-free string literal.
    free: bool = false,
    /// The bound value node of a `val` (its key in `Slots.vals`); null for a
    /// parameter.
    value: ?*const ast.Expr = null,
};

/// `ctx` answers two questions about the backend's lowering:
///   - `ctx.plainVal(value: ast.Expr) bool` — a `val` bound to `value` is
///     written as one `const` declaration;
///   - `ctx.stringRead(e: ast.Expr) ?*ast.Expr` — `e` is a string read the
///     backend lowers through a codepoint helper: its receiver node.
pub fn analyze(gpa: std.mem.Allocator, ctx: anytype, params: []const ast.Param, body: []const ast.Stmt) !Slots {
    var w: Walk(@TypeOf(ctx)) = .{ .gpa = gpa, .ctx = ctx };
    for (params) |p| {
        if (p.destruct) |d| {
            try w.destructNames(d);
            continue;
        }
        if (std.mem.eql(u8, p.name, "self")) continue;
        const b = try w.binder(p.name);
        b.count += 1;
        b.slot_kind = true;
    }
    try w.stmts(body);

    w.scoring = true;
    for (params) |p| {
        if (p.destruct != null or std.mem.eql(u8, p.name, "self")) continue;
        if (w.candidate(p.name)) try w.active.put(gpa, p.name, {});
    }
    try w.stmts(body);
    return w.out;
}

fn Walk(comptime Ctx: type) type {
    return struct {
        const Self = @This();

        gpa: std.mem.Allocator,
        ctx: Ctx,
        /// false: the counting walk; true: the scoped walk that approves reads.
        scoring: bool = false,
        binders: std.StringHashMapUnmanaged(Binder) = .empty,
        active: std.StringHashMapUnmanaged(void) = .empty,
        out: Slots = .{},

        fn binder(self: *Self, name: []const u8) !*Binder {
            const gop = try self.binders.getOrPut(self.gpa, name);
            if (!gop.found_existing) gop.value_ptr.* = .{};
            return gop.value_ptr;
        }

        fn other(self: *Self, name: []const u8) !void {
            if (self.scoring) return;
            const b = try self.binder(name);
            b.count += 1;
            b.slot_kind = false;
        }

        fn candidate(self: *Self, name: []const u8) bool {
            const b = self.binders.get(name) orelse return false;
            return b.count == 1 and b.slot_kind and !b.assigned;
        }

        fn stmts(self: *Self, list: []const ast.Stmt) anyerror!void {
            var opened: std.ArrayListUnmanaged([]const u8) = .empty;
            for (list) |s| {
                const bound = try self.stmt(s);
                if (bound) |n| try opened.append(self.gpa, n);
            }
            for (opened.items) |n| _ = self.active.remove(n);
        }

        /// Walks one statement; answers the candidate `val` it opens, if any.
        fn stmt(self: *Self, s: ast.Stmt) anyerror!?[]const u8 {
            switch (s.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| {
                        try self.expr(lb.value);
                        if (!self.scoring) {
                            const bd = try self.binder(lb.name);
                            bd.count += 1;
                            bd.slot_kind = !lb.mutable and self.ctx.plainVal(lb.value.*);
                            bd.value = lb.value;
                            bd.free = switch (lb.value.*) {
                                .literal => |l| switch (l.kind) {
                                    .stringLit => |t| literalSurrogateFree(t),
                                    else => false,
                                },
                                else => false,
                            };
                            return null;
                        }
                        if (!self.candidate(lb.name)) return null;
                        try self.active.put(self.gpa, lb.name, {});
                        return lb.name;
                    },
                    else => {},
                },
                else => {},
            }
            try self.exprValue(s.expr);
            return null;
        }

        fn expr(self: *Self, e: *const ast.Expr) anyerror!void {
            try self.exprValue(e.*);
        }

        fn exprValue(self: *Self, e: ast.Expr) anyerror!void {
            if (self.scoring) if (self.ctx.stringRead(e)) |recv| try self.approve(recv);
            switch (e) {
                .literal => |lit| switch (lit.kind) {
                    .stringTemplate => |t| for (t.parts) |p| switch (p) {
                        .expr => |x| try self.expr(x),
                        .text => {},
                    },
                    .stringLit, .numberLit, .null_, .comment => {},
                },
                .identifier => |id| switch (id.kind) {
                    .ident, .dotIdent => {},
                    .identAccess => |ia| try self.expr(ia.receiver),
                },
                .binaryOp => |op| {
                    try self.expr(op.lhs);
                    try self.expr(op.rhs);
                },
                .unaryOp => |op| try self.expr(op.expr),
                .jump => |j| switch (j.kind) {
                    .@"return", .throw_, .try_ => |v| if (v) |x| try self.expr(x),
                    .await_ => |x| try self.expr(x),
                    .@"break" => |br| if (br.value) |x| try self.expr(x),
                    .yield => |y| if (y.value) |x| try self.expr(x),
                    .@"continue" => {},
                },
                .branch => |br| switch (br.kind) {
                    .if_ => |i| {
                        try self.expr(i.cond);
                        if (i.binding) |n| try self.other(n);
                        try self.stmts(i.then_);
                        if (i.else_) |els| try self.stmts(els);
                    },
                    .tryCatch => |tc| {
                        try self.expr(tc.expr);
                        try self.expr(tc.handler);
                    },
                },
                .loop => |lp| {
                    try self.expr(lp.iter);
                    if (lp.indexRange) |r| try self.expr(r);
                    for (lp.params) |n| try self.other(n);
                    try self.stmts(lp.body);
                },
                .binding => |b| switch (b.kind) {
                    // A `val` in expression position: its name is a binder
                    // the scoped walk never opens.
                    .localBind => |lb| {
                        try self.expr(lb.value);
                        try self.other(lb.name);
                    },
                    .assign => |a| {
                        switch (a.target) {
                            .name => |n| if (!self.scoring) {
                                (try self.binder(n)).assigned = true;
                            },
                            .fieldAccess => |fa| try self.expr(fa.receiver),
                        }
                        try self.expr(a.value);
                    },
                    .localBindDestruct => |lb| {
                        try self.destructNames(lb.pattern);
                        try self.expr(lb.value);
                    },
                },
                .useHook => |u| try self.expr(u.kind.inner),
                .call => |c| switch (c.kind) {
                    .call => |cc| {
                        if (cc.receiver) |r| try self.expr(r);
                        if (cc.calleeExpr) |ce| try self.expr(ce);
                        for (cc.args) |a| try self.expr(a.value);
                        for (cc.trailing) |tl| {
                            for (tl.params) |n| try self.other(n);
                            try self.stmts(tl.body);
                        }
                    },
                    .pipeline => |p| {
                        try self.expr(p.lhs);
                        try self.expr(p.rhs);
                    },
                },
                .function => |f| {
                    for (f.kind.params) |n| try self.other(n);
                    try self.stmts(f.kind.body);
                },
                .collection => |col| switch (col.kind) {
                    .arrayLit => |al| {
                        for (al.elems) |x| try self.exprValue(x);
                        if (al.spreadExpr) |x| try self.expr(x);
                    },
                    .tupleLit => |tl| for (tl.elems) |x| try self.exprValue(x),
                    .range => |r| {
                        try self.expr(r.start);
                        if (r.end) |x| try self.expr(x);
                    },
                    .case => |cs| {
                        for (cs.subjects) |x| try self.exprValue(x);
                        for (cs.arms) |arm| {
                            try self.patternNames(arm.pattern);
                            if (arm.guard) |g| try self.exprValue(g);
                            try self.exprValue(arm.body);
                        }
                    },
                    .grouped => |x| try self.expr(x),
                    .behaviorLit => |bl| for (bl.fields) |f| try self.expr(f.value),
                },
                .comptime_ => |ct| switch (ct.kind) {
                    .comptimeExpr => |x| try self.expr(x),
                    .comptimeBlock => |cb| try self.stmts(cb.body),
                    .assert => |a| {
                        try self.expr(a.condition);
                        if (a.message) |m| try self.expr(m);
                    },
                    .assertPattern => |ap| {
                        try self.patternNames(ap.pattern);
                        try self.expr(ap.expr);
                        try self.expr(ap.handler);
                    },
                },
            }
        }

        fn approve(self: *Self, recv: *const ast.Expr) !void {
            const key = @intFromPtr(recv);
            switch (recv.*) {
                .literal => |l| switch (l.kind) {
                    .stringLit => |t| if (literalSurrogateFree(t)) try self.out.reads.put(self.gpa, key, .native),
                    else => {},
                },
                .identifier => |id| switch (id.kind) {
                    .ident => |n| {
                        if (!self.active.contains(n)) return;
                        const b = self.binders.get(n).?;
                        if (b.free) return self.out.reads.put(self.gpa, key, .native);
                        const slot = try slotName(self.gpa, n);
                        try self.out.reads.put(self.gpa, key, .{ .slot = slot });
                        if (b.value) |v| {
                            try self.out.vals.put(self.gpa, @intFromPtr(v), slot);
                        } else {
                            for (self.out.params.items) |have| if (std.mem.eql(u8, have, slot)) return;
                            try self.out.params.append(self.gpa, slot);
                        }
                    },
                    else => {},
                },
                else => {},
            }
        }

        fn patternNames(self: *Self, p: ast.Pattern) anyerror!void {
            switch (p) {
                .wildcard, .numberLit, .stringLit => {},
                .ident => |n| try self.other(n),
                .variant => |v| {
                    try self.other(v.name);
                    switch (v.payload) {
                        .binding => |n| try self.other(n),
                        .fields => |fs| for (fs) |n| try self.other(n),
                        .literals => |ps| for (ps) |x| try self.patternNames(x),
                    }
                    for (v.labels) |n| try self.other(n);
                },
                .list => |l| {
                    for (l.elems) |el| switch (el) {
                        .bind => |n| try self.other(n),
                        .wildcard, .numberLit => {},
                    };
                    if (l.spread) |n| try self.other(n);
                },
                .@"or", .multi => |ps| for (ps) |x| try self.patternNames(x),
            }
        }

        fn destructNames(self: *Self, d: ast.ParamDestruct) anyerror!void {
            switch (d) {
                .names => |n| for (n.fields) |f| {
                    try self.other(f.field_name);
                    try self.other(f.bind_name);
                },
                .tuple_ => |t| for (t) |n| try self.other(n),
                .list, .ctor => |p| try self.patternNames(p),
            }
        }
    };
}

// ── tests ────────────────────────────────────────────────────────────────────

test "literalSurrogateFree: BMP text is free, an astral character or a \\u escape is not" {
    try std.testing.expect(literalSurrogateFree("alpha"));
    try std.testing.expect(literalSurrogateFree("a\u{2014}b"));
    try std.testing.expect(!literalSurrogateFree("a\u{1F44D}"));
    try std.testing.expect(!literalSurrogateFree("e\\u{301}"));
}
