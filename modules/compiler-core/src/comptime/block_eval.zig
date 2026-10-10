/// Decisions 266 and 331 — a `comptime` the Zig folder (`eval.zig`) cannot read
/// — a call, a loop, a lambda, a record — runs on the comptime runtime (the
/// one decorators and templates run on, `runtime/runtime.zig`: BEAM or WAT by
/// the target, decision 84), never on the build target, and its value is
/// lifted back into the program as the construction every backend emits.
///
///   `comptime { … }` ─ `prepare`: a function `'__bp_ct_value'/0` over the
///     block (its `break v` → `return v`), the `@TypeInfo.all` answers spliced,
///     every liftable function value routed through a maker `'__bp_fn_<i>'/0`
///   ─ `collectSupport`: the module's functions it reaches, the imported ones
///     (`Env.importedFnSupport`), the record and enum types it names
///   ─ codegen/erlang.zig `emitComptimeModule` (untyped) + `main/1` → Erlang
///     text ─ runtime `evalWithArg` → JSON `{kind: value | error}` → `Value`
///   ─ `lift`: `Value` → `ast.Expr` (a literal, an array, a tuple, a record's
///     constructor call, an enum variant, a function reference)
///
/// **Function values.** A function is a value of the evaluation, not of the
/// program, so it has to be named on the way back. Every top-level function
/// written as a value (`two`, not `two()`) and every lambda that captures
/// nothing the block declares is built by a maker of its own — one code site,
/// no environment — so every evaluation of it is `=:=` to the maker's answer
/// on both runtimes (the BEAM compares a fun's module, index and environment;
/// `rt.zig` its table index and environment). `'__bp_lift'/2` matches a fun
/// against the makers and replies its index; the lift writes the function as
/// it was written. A lambda that captures the block's state matches none and
/// is refused (`comptime-value-not-liftable`), as is a resource (a pid, a
/// port, a reference): neither has a construction in the emitted program.
/// A function value that reaches what this module cannot carry (an
/// `@TypeInfo.all` thunk of another module's type, a function of a module the
/// block does not import) is a stub at compile time: calling it in the block
/// raises; lifting it writes the function.
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const envMod = @import("./env.zig");
const Env = envMod.Env;
const erlang = @import("../codegen/erlang.zig");
const crossModule = @import("../codegen/crossModule.zig");
const templateEval = @import("./template_eval.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const hostRuntime = @import("./runtime/runtime.zig");
const preludeMod = @import("./runtime/prelude.zig");
const etf = @import("./runtime/etf.zig");
const trace = @import("./trace.zig");
const diagnostics = @import("./diagnostics.zig");
const formatMod = @import("../format.zig");

pub const Error = error{OutOfMemory};

/// The synthetic function the block becomes.
pub const value_fn = "__bp_ct_value";
/// Prefix of the makers of the block's function values.
const maker_prefix = "__bp_fn_";
/// The record types the comptime prelude declares (`comptime.zig`
/// `decl_reflection_src`) that an `@TypeInfo.all` answer constructs.
const prelude_records = [_]erlang.HostRecord{
    .{ .name = "Declared", .fields = &.{ "name", "module", "meta", "returnTypeName", "value", "typedMeta" } },
    .{ .name = "DeclaredMeta", .fields = &.{ "key", "value" } },
    .{ .name = "DeclaredTypedMeta", .fields = &.{ "key", "value" } },
    .{ .name = "SourceLocation", .fields = &.{ "file", "line", "column", "fnName" } },
};

// ── values ───────────────────────────────────────────────────────────────────

/// What the runtime answered, read back from `'__bp_lift'/2`'s JSON.
pub const Value = union(enum) {
    null_,
    boolean: bool,
    integer: i64,
    float: f64,
    string: []const u8,
    list: []const Value,
    tuple: []const Value,
    /// A record: an untagged map in the untyped module (`erlang.zig`).
    record: []const Field,
    /// An enum variant without payload, by its atom.
    atom: []const u8,
    /// A function value: the maker's index, or null when no maker built it
    /// (a lambda capturing the block's state).
    function: ?usize,
    /// A pid, a port or a reference, as the runtime prints it.
    resource: []const u8,

    pub const Field = struct { name: []const u8, value: Value };
};

pub const Outcome = union(enum) {
    value: Value,
    /// The module did not compile, the block raised, or the runtime is
    /// missing — the text of the located diagnostic.
    err: []const u8,
};

// ── preparing the block ──────────────────────────────────────────────────────

/// A function value of the block, built by `'__bp_fn_<index>'/0`.
pub const Maker = struct {
    /// What the lift writes back: the identifier or the lambda as written.
    lift: *const ast.Expr,
    decl: ast.FnDecl,
};

pub const Prepared = struct {
    /// `'__bp_ct_value'/0`.
    value: ast.FnDecl,
    makers: []const Maker,
};

/// Every name the block declares (its locals, loop and lambda parameters, `if`
/// bindings): an identifier among them is no top-level function, and a lambda
/// that reads one captures the block's state.
fn declaredNames(arena: std.mem.Allocator, body: []const ast.Stmt) Error!std.StringHashMapUnmanaged(void) {
    var names: std.StringHashMapUnmanaged(void) = .empty;
    var w = NameWalk{ .arena = arena, .out = &names, .declared_only = true };
    for (body) |s| try w.expr(s.expr);
    return names;
}

/// A reflective walk of the untyped AST collecting names: with
/// `declared_only` the names a binding introduces, otherwise every identifier,
/// callee, method name and type name the code spells.
const NameWalk = struct {
    arena: std.mem.Allocator,
    out: *std.StringHashMapUnmanaged(void),
    declared_only: bool,

    fn put(self: *NameWalk, name: []const u8) Error!void {
        if (name.len == 0) return;
        try self.out.put(self.arena, name, {});
    }

    fn expr(self: *NameWalk, e: ast.Expr) Error!void {
        try self.walk(ast.Expr, &e);
    }

    fn walk(self: *NameWalk, comptime U: type, ptr: *const U) Error!void {
        if (U == ast.Expr) try self.visit(ptr.*);
        if (U == ast.TypeRef and !self.declared_only) return self.typeRef(ptr.*);
        if (U == ast.Pattern) return self.pattern(ptr.*);
        switch (@typeInfo(U)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldNames(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldNames(@TypeOf(payload.*))) try self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldNames(p.child)) try self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldNames(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }

    fn visit(self: *NameWalk, e: ast.Expr) Error!void {
        switch (e) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| if (self.declared_only) try self.put(lb.name),
                else => {},
            },
            .loop => |lp| if (self.declared_only) for (lp.params) |p| try self.put(p),
            .function => |f| if (self.declared_only) for (f.kind.params) |p| try self.put(p),
            .branch => |br| switch (br.kind) {
                .if_ => |i| if (self.declared_only) if (i.binding) |n| try self.put(n),
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (!self.declared_only) try self.put(n),
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (self.declared_only) {
                        for (cc.trailing) |tl| for (tl.params) |p| try self.put(p);
                    } else if (!cc.is_builtin) try self.put(cc.callee);
                },
                else => {},
            },
            else => {},
        }
    }

    fn typeRef(self: *NameWalk, tr: ast.TypeRef) Error!void {
        switch (tr) {
            .named => |n| try self.put(n),
            .array => |a| try self.typeRef(a.*),
            .optional => |o| try self.typeRef(o.*),
            .tuple_ => |es| for (es) |x| try self.typeRef(x),
            .labeledTuple => |lt| for (lt.elems) |x| try self.typeRef(x),
            .function => |f| {
                for (f.params) |x| try self.typeRef(x);
                try self.typeRef(f.returnType.*);
            },
            .generic => |g| {
                try self.put(g.name);
                for (g.args) |x| try self.typeRef(x);
            },
            .typeparam => |cs| for (cs) |x| try self.typeRef(x),
        }
    }

    fn pattern(self: *NameWalk, p: ast.Pattern) Error!void {
        // A case arm's pattern binds names; reading them is reading a local.
        if (!self.declared_only) return;
        try self.walkPattern(ast.Pattern, &p);
    }

    fn walkPattern(self: *NameWalk, comptime U: type, ptr: *const U) Error!void {
        switch (@typeInfo(U)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime std.mem.eql(u8, f.name, "name") or std.mem.eql(u8, f.name, "binding")) {
                    if (f.type == []const u8) try self.put(@field(ptr.*, f.name));
                    if (f.type == ?[]const u8) if (@field(ptr.*, f.name)) |n| try self.put(n);
                } else if (comptime mayHoldNames(f.type)) try self.walkPattern(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| {
                    const P = @TypeOf(payload.*);
                    if (P == []const u8) try self.put(payload.*) else if (comptime mayHoldNames(P)) try self.walkPattern(P, payload);
                },
            },
            .optional => |o| if (ptr.*) |*inner| try self.walkPattern(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldNames(p.child)) try self.walkPattern(p.child, ptr.*),
                .slice => if (comptime mayHoldNames(p.child)) {
                    for (ptr.*) |*e| try self.walkPattern(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }
};

fn mayHoldNames(comptime U: type) bool {
    return switch (@typeInfo(U)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque", .null, .undefined => false,
        .pointer => |p| if (p.child == u8) false else if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else true,
        else => true,
    };
}

/// Every name `body` reads: identifiers, callees, receivers' names, the type
/// names its annotations write.
fn readNames(arena: std.mem.Allocator, out: *std.StringHashMapUnmanaged(void), body: []const ast.Stmt) Error!void {
    var w = NameWalk{ .arena = arena, .out = out, .declared_only = false };
    for (body) |s| try w.expr(s.expr);
}

/// The names `body` reads that it does not declare itself (its locals, its
/// loop and lambda parameters, `params`): a parameter `beans` of an imported
/// function is no reference to this module's `fn beans`.
fn readFree(arena: std.mem.Allocator, out: *std.StringHashMapUnmanaged(void), body: []const ast.Stmt, params: []const ast.Param) Error!void {
    var read: std.StringHashMapUnmanaged(void) = .empty;
    try readNames(arena, &read, body);
    const declared = try declaredNames(arena, body);
    var it = read.keyIterator();
    outer: while (it.next()) |n| {
        if (declared.contains(n.*)) continue;
        for (params) |p| if (std.mem.eql(u8, p.name, n.*)) continue :outer;
        try out.put(arena, n.*, {});
    }
}

fn readMethodNames(arena: std.mem.Allocator, out: *std.StringHashMapUnmanaged(void), body: []const ast.Stmt) Error!void {
    var w = MethodWalk{ .arena = arena, .out = out };
    for (body) |s| try w.walk(ast.Expr, &s.expr);
}

/// The method names a body calls (`d.insert(…)`, `Dict.empty()`): what decides
/// which methods of an included type the module needs.
const MethodWalk = struct {
    arena: std.mem.Allocator,
    out: *std.StringHashMapUnmanaged(void),

    fn walk(self: *MethodWalk, comptime U: type, ptr: *const U) Error!void {
        if (U == ast.Expr) switch (ptr.*) {
            .call => |c| switch (c.kind) {
                .call => |cc| if (cc.receiver != null) try self.out.put(self.arena, cc.callee, {}),
                else => {},
            },
            else => {},
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldNames(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldNames(@TypeOf(payload.*))) try self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldNames(p.child)) try self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldNames(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }
};

/// An untyped rewrite by the location of the node it replaces
/// (`Env.enumSectionRewrites`, `Env.indexRewrites`).
pub const SectionRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr);

/// The two channels inference records an enum value's qualified form in,
/// read by `sectionRewrite`.
pub const Rewrites = struct {
    sections: *const SectionRewrites,
    index: *const SectionRewrites,

    pub fn of(env: *const Env) Rewrites {
        return .{ .sections = &env.enumSectionRewrites, .index = &env.indexRewrites };
    }

    fn empty(self: Rewrites) bool {
        return self.sections.count() == 0 and self.index.count() == 0;
    }
};

/// The node `e` stands for once inference's untyped rewrite of an enum
/// value is applied — `comptime/transform.zig`'s reading of the same
/// channels: a section path (`.Pad.All.4`, an `identAccess` at the chain's
/// outer location) is the qualified constructor (`Tok.Pad(_inner:
/// __Tok__Pad.All(_inner: __Tok__Pad__All.__4))`); a call takes the
/// rewrite's callee, and its arguments when the rewrite carries any (a tuple
/// element called by its label, a record update); a leading-dot variant
/// (`.Bold`), a leading-dot constructor (`.Hover(…)`) and a section's payload
/// leaf (`.Color.Hex(…)`) are the qualified forms inference resolved
/// (`Env.indexRewrites`). Null when nothing was recorded for `e`.
fn sectionRewrite(rw: Rewrites, e: ast.Expr) ?ast.Expr {
    switch (e) {
        .identifier => |id| switch (id.kind) {
            .identAccess => if (rw.sections.get(id.loc)) |r| return r.*,
            .dotIdent => if (rw.index.get(id.loc)) |r| if (r.* == .identifier) return r.*,
            else => {},
        },
        .call => |c| if (c.kind == .call) {
            if (!c.kind.call.is_builtin and (c.kind.call.calleeExpr != null or isPathReceiver(c.kind.call.receiver))) {
                if (rw.index.get(c.loc)) |r| if (r.* != .jump) return r.*;
            }
            const r = rw.sections.get(c.loc) orelse return null;
            if (r.* != .call or r.call.kind != .call) return null;
            var out = c;
            out.kind.call.callee = r.call.kind.call.callee;
            if (r.call.kind.call.args.len > 0) out.kind.call.args = r.call.kind.call.args;
            return .{ .call = out };
        },
        else => {},
    }
    return null;
}

/// `transform.zig`'s `isPathReceiver`: a receiver written as a path.
fn isPathReceiver(receiver: ?*ast.Expr) bool {
    const r = receiver orelse return false;
    if (r.* != .identifier) return false;
    return switch (r.identifier.kind) {
        .dotIdent, .identAccess => true,
        else => false,
    };
}

/// `f` with inference's untyped rewrites of its module applied
/// (`sectionRewrite`) — what a module exports for an importer to carry into
/// its comptime module (`comptime.zig` `registerExports`), whose own
/// rewrites are keyed by its own locations and say nothing of `f`'s.
pub fn sectionRewritten(arena: std.mem.Allocator, rw: Rewrites, f: ast.FnDecl) Error!ast.FnDecl {
    if (rw.empty()) return f;
    var w = RewriteWalk{ .rw = rw };
    for (f.body) |*st| w.walk(ast.Expr, &st.expr);
    if (!w.found) return f;
    var c = SectionCopier{ .arena = arena, .rw = rw };
    var out = f;
    out.body = try c.clone([]ast.Stmt, f.body);
    return out;
}

/// `e` with inference's untyped rewrites applied (`sectionRewrite`), or
/// null when `e` holds none — a decorator argument whose source text the
/// decorator module re-reads (`infer.decoratorArgValue`).
pub fn sectionRewrittenExpr(arena: std.mem.Allocator, rw: Rewrites, e: ast.Expr) Error!?ast.Expr {
    if (rw.empty()) return null;
    var w = RewriteWalk{ .rw = rw };
    w.walk(ast.Expr, &e);
    if (!w.found) return null;
    var c = SectionCopier{ .arena = arena, .rw = rw };
    return try c.clone(ast.Expr, e);
}

/// Whether a body holds a node `sectionRewrite` replaces.
const RewriteWalk = struct {
    rw: Rewrites,
    found: bool = false,

    fn walk(self: *RewriteWalk, comptime U: type, ptr: *const U) void {
        if (self.found) return;
        if (U == ast.Expr) if (sectionRewrite(self.rw, ptr.*) != null) {
            self.found = true;
            return;
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (fl.is_comptime) continue;
                if (comptime mayHoldNames(fl.type)) self.walk(fl.type, &@field(ptr.*, fl.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldNames(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |pt| switch (pt.size) {
                .one => if (comptime mayHoldNames(pt.child)) self.walk(pt.child, ptr.*),
                .slice => if (comptime mayHoldNames(pt.child)) {
                    for (ptr.*) |*e| self.walk(pt.child, e);
                },
                else => {},
            },
            else => {},
        }
    }
};

/// A copy of a body with every `sectionRewrite` applied, nothing else.
const SectionCopier = struct {
    arena: std.mem.Allocator,
    rw: Rewrites,

    fn clone(self: *SectionCopier, comptime U: type, v: U) Error!U {
        const w: U = if (U == ast.Expr) (sectionRewrite(self.rw, v) orelse v) else v;
        switch (@typeInfo(U)) {
            .@"struct" => |st| {
                var out: U = w;
                inline for (st.fields) |fl| {
                    if (fl.is_comptime) continue;
                    if (comptime mayHoldNames(fl.type)) @field(out, fl.name) = try self.clone(fl.type, @field(w, fl.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return w;
                switch (w) {
                    inline else => |payload, tag| {
                        const P = @TypeOf(payload);
                        if (comptime !mayHoldNames(P)) return w;
                        return @unionInit(U, @tagName(tag), try self.clone(P, payload));
                    },
                }
            },
            .optional => |o| return if (w) |inner| try self.clone(o.child, inner) else null,
            .pointer => |pt| switch (pt.size) {
                .one => {
                    if (comptime !mayHoldNames(pt.child)) return w;
                    const n = try self.arena.create(pt.child);
                    n.* = try self.clone(pt.child, w.*);
                    return n;
                },
                .slice => {
                    if (comptime !mayHoldNames(pt.child)) return w;
                    const out = try self.arena.alloc(pt.child, w.len);
                    for (w, 0..) |e, i| out[i] = try self.clone(pt.child, e);
                    return out;
                },
                else => return w,
            },
            else => return w,
        }
    }
};

/// Copies the block into the synthetic function's body, applying what the
/// transform would (an `@TypeInfo.all` answer, `@src()`) and routing each
/// liftable function value through a maker.
const Preparer = struct {
    env: *Env,
    arena: std.mem.Allocator,
    declared: std.StringHashMapUnmanaged(void),
    makers: std.ArrayListUnmanaged(Maker) = .empty,
    /// Inside an `@TypeInfo.all` answer: its functions belong to modules the
    /// evaluation does not carry, so their makers are stubs.
    in_rewrite: usize = 0,
    /// The lambda whose own body is being copied for its maker: not routed
    /// through a maker a second time.
    skip: ?*const ast.Expr = null,
    /// Copying a carried function's body (`expandedFn`), not the block: only
    /// a template call is replaced, by its expansion.
    expansions_only: bool = false,
    /// Evaluating a hole's build value (`holeValue`): a module-level `val`
    /// the code reads is its initializer — `knownAtBuild` admitted it.
    inline_vals: usize = 0,
    /// The untyped rewrites inference recorded for the code being copied
    /// (`Env.enumSectionRewrites` of the module that wrote it), applied as
    /// the transform applies them: the comptime module is emitted from the
    /// AST as written, where a section path (`.Pad.All.__4`) is a chain of
    /// map reads (`{badmap, 'Pad'}`).
    rw: Rewrites,

    fn clone(self: *Preparer, comptime U: type, v: U) Error!U {
        if (U == ast.Expr) {
            if (try self.replace(v)) |r| return r;
        }
        return self.copyNode(U, v);
    }

    /// `v` copied, each child through `clone`.
    fn copyNode(self: *Preparer, comptime U: type, v: U) Error!U {
        switch (@typeInfo(U)) {
            .@"struct" => |s| {
                var out: U = v;
                inline for (s.fields) |f| {
                    if (f.is_comptime) continue;
                    if (comptime mayHoldNames(f.type)) @field(out, f.name) = try self.clone(f.type, @field(v, f.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return v;
                switch (v) {
                    inline else => |payload, tag| {
                        const P = @TypeOf(payload);
                        if (comptime !mayHoldNames(P)) return v;
                        return @unionInit(U, @tagName(tag), try self.clone(P, payload));
                    },
                }
            },
            .optional => |o| return if (v) |inner| try self.clone(o.child, inner) else null,
            .pointer => |p| switch (p.size) {
                .one => {
                    if (comptime !mayHoldNames(p.child)) return v;
                    const n = try self.arena.create(p.child);
                    n.* = try self.clone(p.child, v.*);
                    return n;
                },
                .slice => {
                    if (comptime !mayHoldNames(p.child)) return v;
                    const out = try self.arena.alloc(p.child, v.len);
                    for (v, 0..) |e, i| out[i] = try self.clone(p.child, e);
                    return out;
                },
                else => return v,
            },
            else => return v,
        }
    }

    fn replace(self: *Preparer, written: ast.Expr) Error!?ast.Expr {
        const rewritten = sectionRewrite(self.rw, written);
        const e = rewritten orelse written;
        if (try self.replaceOne(e)) |r| return r;
        return if (rewritten != null) try self.copyNode(ast.Expr, e) else null;
    }

    fn replaceOne(self: *Preparer, e: ast.Expr) Error!?ast.Expr {
        // 01-compiler/14 step 8 — a template call the block (or a function
        // it carries) reaches is the code its expansion built
        // (`Env.templateExpansions`, by the call's location), copied with the
        // same rules: the caller's holes are in it already.
        if (e == .call and e.call.kind == .call and !e.call.kind.call.is_builtin) {
            if (self.env.templateExpansions.get(e.call.loc)) |expansion| return try self.clone(ast.Expr, expansion.*);
        }
        if (self.expansions_only) return null;
        switch (e) {
            .call => |c| if (c.kind == .call and c.kind.call.is_builtin) {
                if (self.env.srcRewrites.get(c.loc)) |rewrite| {
                    self.in_rewrite += 1;
                    defer self.in_rewrite -= 1;
                    return try self.clone(ast.Expr, rewrite.*);
                }
            },
            // A `comptime` inside the block is the block's own: its value is
            // computed here with the rest.
            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |inner| return try self.clone(ast.Expr, inner.*),
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |name| {
                    if (self.declared.contains(name)) return null;
                    if (self.inline_vals > 0 and self.inline_vals < max_build_depth) if (moduleVal(self.env, name)) |v| {
                        self.inline_vals += 1;
                        defer self.inline_vals -= 1;
                        return try self.clone(ast.Expr, v.value.*);
                    };
                    const ty = self.env.lookup(name) orelse return null;
                    if (ty.deref().* != .func) return null;
                    if (!isTopLevelFn(self.env, name)) return null;
                    const node = try self.arena.create(ast.Expr);
                    node.* = e;
                    return try self.maker(node, ty.deref().func.params.len, self.in_rewrite == 0 and isCarried(self.env, name));
                },
                else => {},
            },
            .function => |f| {
                if (f.kind.syntax == .asyncBlock) return null;
                if (try self.captures(e)) return null;
                const node = try self.arena.create(ast.Expr);
                node.* = e;
                return try self.maker(node, f.kind.params.len, self.in_rewrite == 0);
            },
            else => {},
        }
        return null;
    }

    /// Whether the lambda `e` reads a name the block declares outside it.
    fn captures(self: *Preparer, e: ast.Expr) Error!bool {
        var read: std.StringHashMapUnmanaged(void) = .empty;
        var w = NameWalk{ .arena = self.arena, .out = &read, .declared_only = false };
        try w.expr(e);
        var own: std.StringHashMapUnmanaged(void) = .empty;
        var d = NameWalk{ .arena = self.arena, .out = &own, .declared_only = true };
        try d.expr(e);
        var it = read.keyIterator();
        while (it.next()) |n| {
            if (own.contains(n.*)) continue;
            if (self.declared.contains(n.*)) return true;
        }
        return false;
    }

    /// `'__bp_fn_<i>'() -> <value>` — the value itself when `callable`, else
    /// a fun of the same arity that raises.
    fn maker(self: *Preparer, written: *const ast.Expr, arity: usize, callable: bool) Error!ast.Expr {
        const index = self.makers.items.len;
        const name = try std.fmt.allocPrint(self.arena, "{s}{d}", .{ maker_prefix, index });
        const loc = written.getLoc();
        const value = try self.arena.create(ast.Expr);
        const params = try self.arena.alloc([]const u8, arity);
        for (params, 0..) |*p, i| p.* = try std.fmt.allocPrint(self.arena, "a{d}", .{i});
        if (callable) {
            value.* = switch (written.*) {
                .function => |f| blk: {
                    var copy = f;
                    copy.kind.body = try self.clone([]ast.Stmt, f.kind.body);
                    break :blk .{ .function = copy };
                },
                // A function written as a value: a lambda calling it (an
                // untyped module spells no `fun f/A` of its own).
                else => blk: {
                    const args = try self.arena.alloc(ast.CallArg, arity);
                    for (args, params) |*a, p| {
                        const ref = try self.arena.create(ast.Expr);
                        ref.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = p } } };
                        a.* = .{ .label = null, .value = ref };
                    }
                    const body = try self.arena.alloc(ast.Stmt, 1);
                    body[0] = .{ .expr = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
                        .receiver = null,
                        .callee = written.identifier.kind.ident,
                        .is_builtin = false,
                        .args = args,
                        .trailing = &.{},
                    } } } } };
                    break :blk .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = params, .body = body } } };
                },
            };
        } else {
            const msg = try self.arena.create(ast.Expr);
            msg.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = "this function value is not callable while the comptime block runs: it reaches a module the evaluation does not carry" } } };
            const args = try self.arena.alloc(ast.CallArg, 1);
            args[0] = .{ .label = null, .value = msg };
            const body = try self.arena.alloc(ast.Stmt, 1);
            body[0] = .{ .expr = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
                .receiver = null,
                .callee = "panic",
                .is_builtin = true,
                .args = args,
                .trailing = &.{},
            } } } } };
            value.* = .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = params, .body = body } } };
        }
        const ret = try self.arena.alloc(ast.Stmt, 1);
        ret[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = value } } } };
        try self.makers.append(self.arena, .{ .lift = written, .decl = synthFn(name, ret) });
        return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = null,
            .callee = name,
            .is_builtin = false,
            .args = &.{},
            .trailing = &.{},
        } } } };
    }
};

fn synthFn(name: []const u8, body: []ast.Stmt) ast.FnDecl {
    return .{
        .isPub = false,
        .name = name,
        .genericParams = &.{},
        .params = &.{},
        .returnType = null,
        .body = body,
    };
}

/// A function the module declares at the top level, or one it imports.
fn isTopLevelFn(env: *Env, name: []const u8) bool {
    return env.fnDecls.contains(name) or env.importedFnSupport.contains(name) or env.importOwners.contains(name);
}

/// Whether the evaluation carries the function's body (this module's own, or
/// an import whose closure travels with it).
fn isCarried(env: *Env, name: []const u8) bool {
    if (env.fnDecls.get(name)) |f| return f.body.len > 0 and !f.isExternal();
    return env.importedFnSupport.contains(name);
}

/// The block's statements with its own `break v` turned into `return v`
/// (`if` arms included; a loop's `break` is the loop's).
fn breaksToReturns(arena: std.mem.Allocator, body: []ast.Stmt) Error![]ast.Stmt {
    const out = try arena.dupe(ast.Stmt, body);
    for (out) |*s| try breakToReturn(arena, &s.expr);
    return out;
}

fn breakToReturn(arena: std.mem.Allocator, e: *ast.Expr) Error!void {
    switch (e.*) {
        .jump => |j| switch (j.kind) {
            .@"break" => |b| if (b.label == null) {
                if (b.value) |v| e.* = .{ .jump = .{ .loc = j.loc, .kind = .{ .@"return" = v } } };
            },
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                var copy = i;
                copy.then_ = try breaksToReturns(arena, i.then_);
                if (i.else_) |els| copy.else_ = try breaksToReturns(arena, els);
                e.* = .{ .branch = .{ .loc = br.loc, .kind = .{ .if_ = copy } } };
            },
            else => {},
        },
        else => {},
    }
}

/// Copy `ct` (a `comptime <expr>` or `comptime { … }`) into the evaluation's
/// value function and its makers.
pub fn prepare(env: *Env, ct: ast.ComptimeExprOf(.untyped)) Error!Prepared {
    const arena = env.arena;
    const block: []const ast.Stmt = switch (ct.kind) {
        .comptimeBlock => |cb| cb.body,
        .comptimeExpr => |inner| blk: {
            const one = try arena.alloc(ast.Stmt, 1);
            one[0] = .{ .expr = .{ .jump = .{ .loc = ct.loc, .kind = .{ .@"break" = .{ .value = inner } } } } };
            break :blk one;
        },
        else => &.{},
    };
    var p = Preparer{ .env = env, .arena = arena, .declared = try declaredNames(arena, block), .rw = Rewrites.of(env) };
    const copied = try p.clone([]const ast.Stmt, block);
    const body = try breaksToReturns(arena, @constCast(copied));
    return .{ .value = synthFn(value_fn, body), .makers = p.makers.items };
}

// ── what the module carries ──────────────────────────────────────────────────

pub const Support = struct {
    fns: []const ast.FnDecl,
    types: []const ast.DeclKind,
};

/// The functions and types the value function and its makers reach, to a
/// fixed point: a function of this module (`Env.fnDecls`), an imported one
/// with its closure (`Env.importedFnSupport`), a type of this module or of a
/// module the build analysed (`Env.typeDeclRegistry`, std's
/// `Env.stdModuleTypes`), and — for a type — the methods the code calls on
/// anything, with the helper functions of the type's own module they reach.
pub fn collectSupport(env: *Env, prepared: Prepared) Error!Support {
    const arena = env.arena;
    var names: std.StringHashMapUnmanaged(void) = .empty;
    var methods: std.StringHashMapUnmanaged(void) = .empty;
    var fns: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    var fn_seen: std.StringHashMapUnmanaged(void) = .empty;
    try fn_seen.put(arena, value_fn, {});
    for (prepared.makers) |m| try fn_seen.put(arena, m.decl.name, {});

    try readFree(arena, &names, prepared.value.body, &.{});
    try readMethodNames(arena, &methods, prepared.value.body);
    for (prepared.makers) |m| {
        try readFree(arena, &names, m.decl.body, &.{});
        try readMethodNames(arena, &methods, m.decl.body);
    }

    const TypeEntry = struct { decl: ast.TypeDecl, helpers: []const ast.FnDecl, kept: std.StringHashMapUnmanaged(void) };
    var types: std.StringArrayHashMapUnmanaged(TypeEntry) = .empty;

    var changed = true;
    while (changed) {
        changed = false;
        var pending: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = names.keyIterator();
        while (it.next()) |n| pending.append(arena, n.*) catch return error.OutOfMemory;
        for (pending.items) |n| {
            if (fn_seen.contains(n) or types.contains(n)) continue;
            if (env.fnDecls.get(n)) |f| {
                try fn_seen.put(arena, n, {});
                // A host function (`#[@External.Erlang(…)]`) is carried as
                // its declaration: the module calls the host.
                if ((f.body.len == 0 and !f.isExternal()) or isComptimeOnly(f)) continue;
                const g = try expandedFn(env, f);
                try fns.append(arena, g);
                try readFn(arena, &names, &methods, g);
                changed = true;
                continue;
            }
            if (env.importedFnSupport.get(n)) |closure| {
                try fn_seen.put(arena, n, {});
                for (closure) |g| {
                    if (fnListed(fns.items, g)) continue;
                    try fns.append(arena, g);
                    try readFn(arena, &names, &methods, g);
                }
                changed = true;
                continue;
            }
            if (findType(env, n)) |found| {
                const entry = try types.getOrPut(arena, n);
                entry.value_ptr.* = .{ .decl = found.decl, .helpers = found.helpers, .kept = .empty };
                try readTypeShape(arena, &names, found.decl);
                changed = true;
            }
        }
        // The methods called on anything, of every included type.
        for (types.values()) |*entry| {
            for (entry.decl.methods) |m| {
                if (entry.kept.contains(m.name)) continue;
                if (!methods.contains(m.name)) continue;
                const body = m.body orelse continue;
                try entry.kept.put(arena, m.name, {});
                try readFree(arena, &names, body, m.params);
                try readMethodNames(arena, &methods, body);
                for (m.params) |p| try readTypeRef(arena, &names, p.typeRef);
                changed = true;
                // A helper of the type's own module the method reaches.
                var helper_names: std.StringHashMapUnmanaged(void) = .empty;
                try readFree(arena, &helper_names, body, m.params);
                for (entry.helpers) |h| {
                    if (!helper_names.contains(h.name) or fn_seen.contains(h.name)) continue;
                    try fn_seen.put(arena, h.name, {});
                    try fns.append(arena, h);
                    try readFn(arena, &names, &methods, h);
                }
            }
        }
    }

    var out_types: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (types.values()) |entry| {
        var decl = entry.decl;
        var kept: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        for (decl.methods) |m| if (entry.kept.contains(m.name)) try kept.append(arena, m);
        decl.methods = kept.items;
        decl.implement = &.{};
        decl.annotations = &.{};
        try out_types.append(arena, .{ .type_ = decl });
    }
    return .{ .fns = fns.items, .types = out_types.items };
}

/// `f` with every template call of its body replaced by its expansion
/// (`Env.templateExpansions`) and every section path by its qualified
/// constructor (`Env.enumSectionRewrites`): the comptime module is emitted
/// from the AST as written, where a template call has no lowering and a
/// section path is a chain of map reads. A function of this module
/// whose body was not inferred yet has no expansion recorded and is left as
/// written — its template call is refused at the `comptime`
/// (`unexpandedTemplateCall`).
fn expandedFn(env: *Env, f: ast.FnDecl) Error!ast.FnDecl {
    if (!try holdsExpansion(env, f.body) and !holdsSectionRewrite(Rewrites.of(env), f.body)) return f;
    var p = Preparer{ .env = env, .arena = env.arena, .declared = .empty, .expansions_only = true, .rw = Rewrites.of(env) };
    var out = f;
    out.body = @constCast(try p.clone([]const ast.Stmt, f.body));
    return out;
}

fn holdsSectionRewrite(rw: Rewrites, body: []const ast.Stmt) bool {
    if (rw.empty()) return false;
    var w = RewriteWalk{ .rw = rw };
    for (body) |*st| w.walk(ast.Expr, &st.expr);
    return w.found;
}

fn holdsExpansion(env: *Env, body: []const ast.Stmt) Error!bool {
    var w = ExpansionWalk{ .env = env };
    for (body) |*s| w.walk(ast.Expr, &s.expr);
    return w.found != null;
}

/// The first call of `body` whose location `Env.templateExpansions` holds, or
/// (with `unexpanded`) the first call of a template function no expansion
/// answers.
const ExpansionWalk = struct {
    env: *Env,
    unexpanded: bool = false,
    found: ?ast.Loc = null,
    callee: []const u8 = "",

    fn walk(self: *ExpansionWalk, comptime U: type, ptr: *const U) void {
        if (self.found != null) return;
        if (U == ast.Expr) switch (ptr.*) {
            .call => |c| if (c.kind == .call and !c.kind.call.is_builtin) {
                const expanded = self.env.templateExpansions.contains(c.loc);
                if (!self.unexpanded and expanded) {
                    self.found = c.loc;
                    return;
                }
                if (self.unexpanded and !expanded and c.kind.call.receiver == null and isTemplateName(self.env, c.kind.call.callee)) {
                    self.found = c.loc;
                    self.callee = c.kind.call.callee;
                    return;
                }
            },
            else => {},
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldNames(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldNames(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldNames(p.child)) self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldNames(p.child)) {
                    for (ptr.*) |*e| self.walk(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }
};

/// Whether `name` is a template function this module declares or imports.
fn isTemplateName(env: *Env, name: []const u8) bool {
    if (env.fnDecls.get(name)) |f| if (f.returnType) |rt| return rt.isTemplateReturnType();
    return env.templateFns.contains(name);
}

/// 01-compiler/14 step 8 — a template call left in what the comptime module
/// carries (a function of this module declared after the `comptime`, whose
/// body was not inferred when it ran; a function another module exports,
/// carried as written) has no lowering: the `comptime` is refused, naming the
/// call, instead of reaching the emitter.
pub fn unexpandedTemplateCall(env: *Env, prepared: Prepared, support: Support) Error!?[]const u8 {
    var w = ExpansionWalk{ .env = env, .unexpanded = true };
    for (prepared.value.body) |*s| w.walk(ast.Expr, &s.expr);
    for (prepared.makers) |m| for (m.decl.body) |*s| w.walk(ast.Expr, &s.expr);
    var in_fn: []const u8 = "";
    for (support.fns) |f| {
        if (w.found != null) break;
        for (f.body) |*s| w.walk(ast.Expr, &s.expr);
        if (w.found != null) in_fn = f.name;
    }
    const loc = w.found orelse return null;
    if (in_fn.len > 0) return try std.fmt.allocPrint(env.arena, "the comptime reaches the template call `{s}` at {d}:{d} in `{s}`, which is not expanded where the comptime runs — declare `{s}` before the `comptime` in this module", .{ w.callee, loc.line, loc.col, in_fn, in_fn });
    return try std.fmt.allocPrint(env.arena, "the comptime reaches the template call `{s}` at {d}:{d}, which is not expanded where the comptime runs", .{ w.callee, loc.line, loc.col });
}

/// A section path (`.Pad.All.4`, `Tok.Pad.All.4`) left as written in a
/// function of this module the comptime carries — declared after the
/// `comptime`, so its body was not inferred and no rewrite was recorded
/// (`Env.enumSectionRewrites`) — would be a chain of map reads on the
/// runtime (`{badmap, 'Pad'}`): the `comptime` is refused, naming the path,
/// as `unexpandedTemplateCall` refuses a template call.
pub fn unresolvedSectionPath(env: *Env, support: Support) Error!?[]const u8 {
    for (support.fns) |f| {
        if (!env.fnDecls.contains(f.name)) continue;
        var w = PathWalk{ .env = env };
        for (f.body) |*st| w.walk(ast.Expr, &st.expr);
        const loc = w.found orelse continue;
        return try std.fmt.allocPrint(env.arena, "the comptime reaches the section path `{s}` at {d}:{d} in `{s}`, which is not resolved where the comptime runs — declare `{s}` before the `comptime` in this module", .{ w.text, loc.line, loc.col, f.name, f.name });
    }
    return null;
}

/// Whether `f`'s body writes a section path: a decorator's function that
/// does is inferred before the decorator runs (`infer.sameLoweredFn`), so
/// the path is resolved in the module the decorator runs in.
pub fn writesSectionPath(env: *Env, f: ast.FnDecl) bool {
    var w = PathWalk{ .env = env, .any = true };
    for (f.body) |*st| w.walk(ast.Expr, &st.expr);
    return w.found != null;
}

/// The first section path of a body no rewrite answers (with `any`, the
/// first one).
const PathWalk = struct {
    env: *Env,
    any: bool = false,
    found: ?ast.Loc = null,
    text: []const u8 = "",

    fn walk(self: *PathWalk, comptime U: type, ptr: *const U) void {
        if (self.found != null) return;
        if (U == ast.Expr) if (sectionPathText(self.env, ptr.*)) |text| {
            if (self.any or !self.env.enumSectionRewrites.contains(ptr.identifier.loc)) {
                self.found = pathStart(ptr.*);
                self.text = text;
            }
            return;
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (fl.is_comptime) continue;
                if (comptime mayHoldNames(fl.type)) self.walk(fl.type, &@field(ptr.*, fl.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldNames(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |pt| switch (pt.size) {
                .one => if (comptime mayHoldNames(pt.child)) self.walk(pt.child, ptr.*),
                .slice => if (comptime mayHoldNames(pt.child)) {
                    for (ptr.*) |*e| self.walk(pt.child, e);
                },
                else => {},
            },
            else => {},
        }
    }
};

/// Where a member chain is written: its root's location (the chain's own
/// is its last member's).
fn pathStart(e: ast.Expr) ast.Loc {
    var at = e;
    while (at == .identifier and at.identifier.kind == .identAccess) at = at.identifier.kind.identAccess.receiver.*;
    return at.getLoc();
}

/// `e` as the section path it is written as — a member chain rooted at a
/// leading dot (`.Pad.All.4`), or at an enum carrying sections with two
/// members or more (`Tok.Pad.All`) — or null.
fn sectionPathText(env: *Env, e: ast.Expr) ?[]const u8 {
    if (e != .identifier or e.identifier.kind != .identAccess) return null;
    var members: usize = 0;
    var at = e;
    while (at == .identifier and at.identifier.kind == .identAccess) : (members += 1) at = at.identifier.kind.identAccess.receiver.*;
    if (at != .identifier) return null;
    switch (at.identifier.kind) {
        .dotIdent => {},
        .ident => |root| {
            if (members < 2) return null;
            const found = findDeclared(env, root) orelse return null;
            if (found.decl.sections().len == 0) return null;
        },
        else => return null,
    }
    var f = formatMod.Formatter.init(env.arena);
    const doc = f.fmtExpr(e) catch return "";
    return formatMod.render(env.arena, doc, std.math.maxInt(u16)) catch "";
}

fn fnListed(list: []const ast.FnDecl, f: ast.FnDecl) bool {
    for (list) |g| if (std.mem.eql(u8, g.name, f.name)) return true;
    return false;
}

/// A decorator or a template: never a function the evaluation calls.
fn isComptimeOnly(f: ast.FnDecl) bool {
    if (f.returnType) |rt| if (rt.isTemplateReturnType()) return true;
    for (f.params) |p| if (p.typeRef == .named and std.mem.eql(u8, p.typeRef.named, "Decl")) return true;
    return false;
}

fn readFn(arena: std.mem.Allocator, names: *std.StringHashMapUnmanaged(void), methods: *std.StringHashMapUnmanaged(void), f: ast.FnDecl) Error!void {
    try readFree(arena, names, f.body, f.params);
    try readMethodNames(arena, methods, f.body);
    for (f.params) |p| try readTypeRef(arena, names, p.typeRef);
    if (f.returnType) |rt| try readTypeRef(arena, names, rt);
}

fn readTypeRef(arena: std.mem.Allocator, names: *std.StringHashMapUnmanaged(void), tr: ast.TypeRef) Error!void {
    var w = NameWalk{ .arena = arena, .out = names, .declared_only = false };
    try w.typeRef(tr);
}

fn readTypeShape(arena: std.mem.Allocator, names: *std.StringHashMapUnmanaged(void), decl: ast.TypeDecl) Error!void {
    switch (decl.shape) {
        .record => |fields| for (fields) |f| try readTypeRef(arena, names, f.typeRef),
        // A payload's types — a section wrapper's `__Tok__Pad` among them.
        .enum_ => |e| for (e.variants) |v| for (v.fields) |f| try readTypeRef(arena, names, f.typeRef),
    }
}

const FoundType = struct { decl: ast.TypeDecl, helpers: []const ast.FnDecl };

/// The declaration of the type `name`: this module's, then std's, then the
/// one this module imports under that name (its declaring module, decisions
/// 170 and 337), then the one module this module imports from that declares
/// it (`make()` of `a/theme` answering `a/theme`'s `Ns`), then the one module
/// of the build declaring it. A type is its module plus its name: two
/// modules declaring `Ns` — `a/theme` and `b/theme` — are two types even
/// where both are written on the same line, so a step that finds two answers
/// none of them.
fn findType(env: *Env, name: []const u8) ?FoundType {
    const found = findDeclared(env, name) orelse return sectionType(env, name);
    return .{ .decl = withSectionWrappers(env.arena, found.decl) catch return null, .helpers = found.helpers };
}

/// A section of an enum (`docs.md` § Sections of an enum) is a type of its
/// own, `__<Enum>__<Section>[__<Sub>…]` — the name inference registers it
/// under (`infer.registerEnumSection`) and the rewrites construct
/// (`__Tok__Pad.All(…)`). No module declares it: it is built here from the
/// enum's declaration, with the `__` prefix on a numeric leaf (`__4`) and
/// a wrapper variant `<Sub>(_inner: __<Enum>__<Section>__<Sub>)` per
/// sub-section, as `comptime.zig` `withSynthesisedEnumDecls` gives the
/// backends.
fn sectionType(env: *Env, name: []const u8) ?FoundType {
    if (name.len < 3 or !std.mem.startsWith(u8, name, "__")) return null;
    var segs = std.mem.splitSequence(u8, name[2..], "__");
    const outer_name = segs.next() orelse return null;
    if (outer_name.len == 0) return null;
    const outer = findDeclared(env, outer_name) orelse return null;
    var sections = outer.decl.sections();
    var at: ?ast.EnumSection = null;
    while (segs.next()) |seg| {
        const next = for (sections) |sec| {
            if (std.mem.eql(u8, sec.name, seg)) break sec;
        } else return null;
        at = next;
        sections = next.sections;
    }
    const sec = at orelse return null;
    const variants = env.arena.alloc(ast.EnumVariant, sec.variants.len + sec.sections.len) catch return null;
    for (sec.variants, 0..) |v, i| {
        variants[i] = v;
        if (v.numeric) variants[i].name = std.fmt.allocPrint(env.arena, "__{s}", .{v.name}) catch return null;
    }
    for (sec.sections, 0..) |sub, i| variants[sec.variants.len + i] = sectionWrapper(env.arena, name, sub.name) catch return null;
    return .{
        .decl = .{ .name = name, .isPub = false, .shape = .{ .enum_ = .{ .variants = variants } } },
        .helpers = outer.helpers,
    };
}

/// `decl` with a wrapper variant `<Section>(_inner: __<Enum>__<Section>)` per
/// section of its body (`comptime.zig` `enrichEnumWithSectionWrappers`): the
/// emitter places a section's tag only through it.
fn withSectionWrappers(arena: std.mem.Allocator, decl: ast.TypeDecl) Error!ast.TypeDecl {
    const sections = decl.sections();
    if (sections.len == 0) return decl;
    const variants = decl.variants();
    const merged = try arena.alloc(ast.EnumVariant, variants.len + sections.len);
    @memcpy(merged[0..variants.len], variants);
    const prefix = try std.fmt.allocPrint(arena, "__{s}", .{decl.name});
    for (sections, 0..) |sec, i| merged[variants.len + i] = try sectionWrapper(arena, prefix, sec.name);
    var out = decl;
    out.shape = .{ .enum_ = .{ .variants = merged } };
    return out;
}

fn sectionWrapper(arena: std.mem.Allocator, owner: []const u8, section: []const u8) Error!ast.EnumVariant {
    const fields = try arena.alloc(ast.Field, 1);
    fields[0] = .{ .name = "_inner", .typeRef = .{ .named = try std.fmt.allocPrint(arena, "{s}__{s}", .{ owner, section }) }, .default = null };
    return .{ .name = section, .fields = fields, .numeric = false };
}

fn findDeclared(env: *Env, name: []const u8) ?FoundType {
    for (env.moduleDecls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, name)) return .{ .decl = t, .helpers = ownFns(env) },
        else => {},
    };
    var sit = env.stdModuleTypes.iterator();
    while (sit.next()) |e| for (e.value_ptr.*) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, name)) return .{ .decl = t, .helpers = env.stdModuleFns.get(e.key_ptr.*) orelse &.{} },
        else => {},
    };
    const registry = env.typeDeclRegistry orelse return null;
    if (env.importedTypeDecls.get(name)) |imported| {
        const d = (registry.get(imported.module) orelse return null).get(imported.name) orelse return null;
        return if (d == .type_) .{ .decl = d.type_, .helpers = &.{} } else null;
    }
    var from_imports: ?ast.TypeDecl = null;
    var from_module: []const u8 = "";
    var oit = env.importOwners.valueIterator();
    while (oit.next()) |o| {
        if (std.mem.eql(u8, o.owner, from_module)) continue;
        const d = (registry.get(o.owner) orelse continue).get(name) orelse continue;
        if (d != .type_) continue;
        if (from_imports != null) return null;
        from_imports = d.type_;
        from_module = o.owner;
    }
    if (from_imports) |t| return .{ .decl = t, .helpers = &.{} };
    var found: ?ast.TypeDecl = null;
    var it = registry.iterator();
    while (it.next()) |e| {
        const d = e.value_ptr.get(name) orelse continue;
        if (d != .type_) continue;
        if (found != null) return null;
        found = d.type_;
    }
    return if (found) |t| .{ .decl = t, .helpers = &.{} } else null;
}

fn ownFns(env: *Env) []const ast.FnDecl {
    var list: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    for (env.moduleDecls) |d| switch (d) {
        .@"fn" => |f| list.append(env.arena, f) catch return &.{},
        else => {},
    };
    return list.items;
}

// ── the module ───────────────────────────────────────────────────────────────

const placeholder_module = "comptime_module";

const Module = struct {
    module: []const u8,
    code: []const u8,
    listing: []const u8,
};

/// `main/1`, the function-value registry and the reply encoder. Raw text: the
/// same text on both runtimes (`wat/erl_parse.zig` reads the subset the
/// emitter writes).
fn hostForms(b: Ast.Builder, makers: usize) Error![]const Ast.Form {
    const R = Ast.Expr.r;
    const V = Ast.Expr.v;
    var registry: std.ArrayListUnmanaged(u8) = .empty;
    try registry.append(b.arena, '[');
    for (0..makers) |i| {
        if (i > 0) try registry.appendSlice(b.arena, ", ");
        try registry.print(b.arena, "{{{d}, '{s}{d}'()}}", .{ i, maker_prefix, i });
    }
    try registry.append(b.arena, ']');

    const main_body =
        \\try
        \\        json:encode(#{kind => <<"value">>, value => '__bp_lift'('__bp_ct_value'(), '__bp_fns'())})
        \\    catch
        \\        Class:Reason -> json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
        \\    end
    ;
    const lift_body =
        \\case V of
        \\        undefined -> null;
        \\        true -> true;
        \\        false -> false;
        \\        _ when erlang:is_integer(V) -> V;
        \\        _ when erlang:is_float(V) -> #{<<"float">> => V};
        \\        _ when erlang:is_binary(V) -> V;
        \\        _ when erlang:is_atom(V) -> #{<<"atom">> => erlang:atom_to_binary(V)};
        \\        _ when erlang:is_list(V) -> ['__bp_lift'(E, R) || E <- V];
        \\        _ when erlang:is_tuple(V) -> #{<<"tuple">> => ['__bp_lift'(E, R) || E <- erlang:tuple_to_list(V)]};
        \\        _ when erlang:is_map(V) -> #{<<"record">> => maps:map(fun(_, X) -> '__bp_lift'(X, R) end, V)};
        \\        _ when erlang:is_function(V) -> #{<<"fn">> => '__bp_fn_index'(V, R)};
        \\        _ -> #{<<"resource">> => '__bp_text'(V)}
        \\    end
    ;
    const index_body =
        \\case R of
        \\        [] -> null;
        \\        [{I, G} | _] when G =:= F -> I;
        \\        [_ | Rest] -> '__bp_fn_index'(F, Rest)
        \\    end
    ;
    const forms = try b.arena.alloc(Ast.Form, 4);
    forms[0] = try b.function("main", &.{V("_")}, &.{}, &.{R(main_body)});
    forms[1] = try b.function("__bp_fns", &.{}, &.{}, &.{R(registry.items)});
    forms[2] = try b.function("__bp_lift", &.{ V("V"), V("R") }, &.{}, &.{R(lift_body)});
    forms[3] = try b.function("__bp_fn_index", &.{ V("F"), V("R") }, &.{}, &.{R(index_body)});
    return forms;
}

fn buildModule(arena: std.mem.Allocator, owner: []const u8, prepared: Prepared, support: Support, unsupported: *erlang.UnsupportedMethod, why: *[]const u8) (Error || error{ UnsupportedMethod, EmitFailed, EvalFailed })!Module {
    const b: Ast.Builder = .{ .arena = arena };
    const forms = try hostForms(b, prepared.makers.len);
    const resident = try preludeMod.decoratorForms(b);

    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    try decls.append(arena, .{ .@"fn" = prepared.value });
    for (prepared.makers) |m| try decls.append(arena, .{ .@"fn" = m.decl });
    for (support.fns) |f| try decls.append(arena, .{ .@"fn" = f });
    try decls.appendSlice(arena, support.types);

    var config: erlang.ComptimeModule = .{
        .host_records = &prelude_records,
        .exports = &.{.{ .name = "main", .arity = 1 }},
        .forms = forms,
        .resident = .{
            .module = preludeMod.decorator_module,
            .forms = resident,
            .refs = try preludeMod.exportRefs(arena, resident),
        },
        .unsupported_method = unsupported,
    };
    const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls.items }, config) catch |err| switch (err) {
        error.UnsupportedComptimeMethod => return error.UnsupportedMethod,
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            why.* = @errorName(err);
            return error.EmitFailed;
        },
    };
    const module = crossModule.erlDeclAtom(arena, try templateEval.ownerId(arena, owner), .ct, "comptime", std.hash.Wyhash.hash(0, code)) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.EvalFailed,
    };
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });
    config.listing = true;
    const listing = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls.items }, config) catch return error.EvalFailed;
    return .{ .module = module, .code = renamed, .listing = listing };
}

/// Run the prepared block on this thread's comptime runtime.
pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    owner: []const u8,
    prepared: Prepared,
    support: Support,
    traces: ?*std.ArrayListUnmanaged(trace.Entry),
) (Error || error{EvalFailed})!Outcome {
    var unsupported: erlang.UnsupportedMethod = .{};
    var why: []const u8 = "";
    const m = buildModule(arena, owner, prepared, support, &unsupported, &why) catch |err| switch (err) {
        error.EmitFailed => return .{ .err = try std.fmt.allocPrint(arena, "the comptime block could not be lowered for the comptime runtime ({s})", .{why}) },
        error.UnsupportedMethod => return .{ .err = try std.fmt.allocPrint(
            arena,
            "the comptime block calls `.{s}(…)` with {d} argument(s) at {d}:{d}, which no primitive type and no type the block reaches provides",
            .{ unsupported.callee, unsupported.argc, unsupported.loc.line, unsupported.loc.col },
        ) },
        error.OutOfMemory => return error.OutOfMemory,
        error.EvalFailed => return error.EvalFailed,
    };
    const result = hostRuntime.evalWithArg(arena, io, "comptime", m.module, m.code, try etf.encode(arena, Term.tupleOf(&.{}))) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.EvalFailed => return error.EvalFailed,
    };
    const response = switch (result) {
        .response => |r| r,
        .unavailable => |reason| return .{ .err = reason },
    };
    if (traces) |list| {
        const listing = try hostRuntime.listingOf(arena, "comptime", m.module, m.code, m.listing);
        try list.append(arena, .{
            .kind = .@"comptime",
            .name = "block",
            .listing = listing.text,
            .lang = listing.lang,
            .reply = switch (response) {
                .ok => |stdout| stdout,
                .compile_error => |detail| try std.fmt.allocPrint(arena, "compile error: {s}", .{detail}),
                .runtime_error => |detail| try std.fmt.allocPrint(arena, "runtime error: {s}", .{detail}),
            },
        });
    }
    return switch (response) {
        .ok => |stdout| parseReply(arena, stdout),
        .compile_error => |detail| .{ .err = try std.fmt.allocPrint(arena, "the comptime block's module did not compile: {s}", .{clip(detail)}) },
        .runtime_error => |detail| .{ .err = try std.fmt.allocPrint(arena, "the comptime block raised: {s}", .{clip(detail)}) },
    };
}

fn clip(text: []const u8) []const u8 {
    return text[0..@min(text.len, 4096)];
}

fn parseReply(arena: std.mem.Allocator, stdout: []const u8) Error!Outcome {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, stdout, .{ .allocate = .alloc_always }) catch
        return .{ .err = try std.fmt.allocPrint(arena, "the comptime evaluator returned an unreadable result: {s}", .{clip(stdout)}) };
    if (parsed != .object) return .{ .err = "the comptime evaluator returned an unreadable result" };
    const kind = parsed.object.get("kind") orelse return .{ .err = "the comptime evaluator returned an unreadable result" };
    if (kind == .string and std.mem.eql(u8, kind.string, "value")) {
        const v = parsed.object.get("value") orelse return .{ .err = "the comptime evaluator returned no value" };
        return .{ .value = try readValue(arena, v) };
    }
    const msg = parsed.object.get("message");
    const text = if (msg) |m| (if (m == .string) m.string else "") else "";
    return .{ .err = try std.fmt.allocPrint(arena, "the comptime block raised: {s}", .{text}) };
}

fn readValue(arena: std.mem.Allocator, v: std.json.Value) Error!Value {
    return switch (v) {
        .null => .null_,
        .bool => |x| .{ .boolean = x },
        .integer => |n| .{ .integer = n },
        .float => |f| .{ .float = f },
        .number_string => |s| .{ .integer = std.fmt.parseInt(i64, s, 10) catch 0 },
        .string => |s| .{ .string = s },
        .array => |items| blk: {
            const out = try arena.alloc(Value, items.items.len);
            for (items.items, 0..) |item, i| out[i] = try readValue(arena, item);
            break :blk .{ .list = out };
        },
        .object => |obj| blk: {
            if (obj.get("float")) |f| break :blk .{ .float = switch (f) {
                .float => |x| x,
                .integer => |n| @floatFromInt(n),
                else => 0,
            } };
            if (obj.get("atom")) |a| break :blk .{ .atom = if (a == .string) a.string else "" };
            if (obj.get("fn")) |f| break :blk .{ .function = if (f == .integer and f.integer >= 0) @intCast(f.integer) else null };
            if (obj.get("resource")) |r| break :blk .{ .resource = if (r == .string) r.string else "" };
            if (obj.get("tuple")) |t| {
                const items = if (t == .array) t.array.items else &.{};
                const out = try arena.alloc(Value, items.len);
                for (items, 0..) |item, i| out[i] = try readValue(arena, item);
                break :blk .{ .tuple = out };
            }
            if (obj.get("record")) |r| {
                if (r != .object) break :blk .{ .record = &.{} };
                const out = try arena.alloc(Value.Field, r.object.count());
                var it = r.object.iterator();
                var i: usize = 0;
                while (it.next()) |e| : (i += 1) out[i] = .{ .name = e.key_ptr.*, .value = try readValue(arena, e.value_ptr.*) };
                break :blk .{ .record = out };
            }
            break :blk .null_;
        },
    };
}

// ── the lift ─────────────────────────────────────────────────────────────────

pub const Lifted = union(enum) {
    expr: *ast.Expr,
    /// `comptime-value-not-liftable`: the value has no construction in the
    /// emitted program — the message, located at the `comptime` by the caller.
    refused: []const u8,
};

const Lifter = struct {
    env: *Env,
    arena: std.mem.Allocator,
    prepared: Prepared,
    support: Support,
    root: ast.Loc,
    refusal: ?[]const u8 = null,

    /// A location of its own for each lifted node but the root: the backends
    /// key their lowerings by location, and the root's is the `comptime`'s.
    fn nextLoc(self: *Lifter) ast.Loc {
        self.env.comptimeLiftSeq += 1;
        return .{ .line = self.root.line, .col = lifted_col_base + self.env.comptimeLiftSeq, .expansion = self.root.expansion };
    }

    fn refuse(self: *Lifter, comptime fmt: []const u8, args: anytype) Error!?*ast.Expr {
        if (self.refusal == null) self.refusal = try std.fmt.allocPrint(self.arena, fmt, args);
        return null;
    }

    fn node(self: *Lifter, e: ast.Expr) Error!*ast.Expr {
        const n = try self.arena.create(ast.Expr);
        n.* = e;
        return n;
    }

    fn value(self: *Lifter, v: Value, hint: ?*T.Type, loc: ast.Loc) Error!?*ast.Expr {
        switch (v) {
            .null_ => return try self.node(.{ .literal = .{ .loc = loc, .kind = .null_ } }),
            .boolean => |b| return try self.node(.{ .identifier = .{ .loc = loc, .kind = .{ .ident = if (b) "true" else "false" } } }),
            .integer => |n| {
                const suffix = numericSuffix(hint, false);
                return try self.node(.{ .literal = .{ .loc = loc, .kind = .{ .numberLit = try std.fmt.allocPrint(self.arena, "{d}{s}", .{ n, suffix }) } } });
            },
            .float => |f| {
                if (!std.math.isFinite(f)) return self.refuse("{s}: the value is a non-finite float, which no literal writes", .{diagnostics.comptime_value_not_liftable});
                var text: std.ArrayListUnmanaged(u8) = .empty;
                try text.print(self.arena, "{d}", .{f});
                if (std.mem.indexOfAny(u8, text.items, ".eEn") == null) try text.appendSlice(self.arena, ".0");
                try text.appendSlice(self.arena, numericSuffix(hint, true));
                return try self.node(.{ .literal = .{ .loc = loc, .kind = .{ .numberLit = text.items } } });
            },
            .string => |s| return try self.node(.{ .literal = .{ .loc = loc, .kind = .{ .stringLit = try stringLexeme(self.arena, s) } } }),
            .list => |items| {
                const elem_hint = argOf(hint, 0);
                const elems = try self.arena.alloc(ast.Expr, items.len);
                for (items, 0..) |item, i| elems[i] = (try self.value(item, elem_hint, self.nextLoc()) orelse return null).*;
                return try self.node(.{ .collection = .{ .loc = loc, .kind = .{ .arrayLit = .{ .elems = elems } } } });
            },
            .tuple => |items| {
                if (try self.variant(items, hint, loc)) |n| return n;
                if (self.refusal != null) return null;
                const labels: []const []const u8 = if (hint) |h| switch (h.deref().*) {
                    .named => |n| if (n.labels.len == items.len) n.labels else &.{},
                    else => &.{},
                } else &.{};
                const elems = try self.arena.alloc(ast.Expr, items.len);
                for (items, 0..) |item, i| elems[i] = (try self.value(item, argOf(hint, i), self.nextLoc()) orelse return null).*;
                return try self.node(.{ .collection = .{ .loc = loc, .kind = .{ .tupleLit = .{ .elems = elems, .labels = labels } } } });
            },
            .record => |fields| {
                const name = self.recordName(fields, hint) orelse
                    return self.refuse("{s}: the value is a record of fields ({s}) no type the block reaches declares", .{ diagnostics.comptime_value_not_liftable, try fieldList(self.arena, fields) });
                const args = try self.arena.alloc(ast.CallArg, fields.len);
                for (fields, 0..) |f, i| {
                    const fv = try self.value(f.value, null, self.nextLoc()) orelse return null;
                    args[i] = .{ .label = f.name, .value = fv };
                }
                return try self.node(.{ .call = .{ .loc = loc, .kind = .{ .call = .{
                    .receiver = null,
                    .callee = try self.constructorName(name),
                    .is_builtin = false,
                    .args = args,
                    .trailing = &.{},
                } } } });
            },
            .atom => |a| {
                if (enumHint(self.env, hint)) |en| if (variantOf(en.def, a, 0)) |unit| {
                    const recv = try self.enumReceiver(en.name);
                    return try self.node(.{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = .{ .receiver = recv, .member = unit.name } } } });
                };
                return self.refuse("{s}: the value is the atom `{s}`, which names no construction of the program", .{ diagnostics.comptime_value_not_liftable, a });
            },
            .function => |index| {
                const i = index orelse return self.refuse("{s}: the value is a lambda that captures the comptime block's state — only a declared function, or a lambda reading nothing the block declares, is lifted", .{diagnostics.comptime_value_not_liftable});
                if (i >= self.prepared.makers.len) return self.refuse("{s}: the value is a function the comptime block did not write", .{diagnostics.comptime_value_not_liftable});
                return try self.node(self.prepared.makers[i].lift.*);
            },
            .resource => return self.refuse("{s}: the value is a resource — a process, a port or a reference lives only while the comptime block runs", .{diagnostics.comptime_value_not_liftable}),
        }
    }

    /// An enum's payload variant — `{Tag, F1, …}` in the untyped module — as
    /// its constructor call, `Tok.Tag(f1: …)`, when the expected type is an
    /// enum declaring `Tag` with that many fields. A section is its wrapper
    /// variant (`Tok.Pad(_inner: __Tok__Pad.All(_inner: __Tok__Pad__All.__4))`,
    /// the shape inference's rewrite of `.Pad.All.4` builds), each payload
    /// lifted against its field's type. Null when the hint names no such
    /// variant: the tuple is a tuple.
    fn variant(self: *Lifter, items: []const Value, hint: ?*T.Type, loc: ast.Loc) Error!?*ast.Expr {
        if (items.len < 2 or items[0] != .atom) return null;
        const en = enumHint(self.env, hint) orelse return null;
        const v = variantOf(en.def, items[0].atom, items.len - 1) orelse return null;
        const args = try self.arena.alloc(ast.CallArg, v.fields.len);
        for (v.fields, items[1..], 0..) |f, item, i| {
            const fv = try self.value(item, f.type_, self.nextLoc()) orelse return null;
            args[i] = .{ .label = f.name, .value = fv };
        }
        return try self.node(.{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = try self.enumReceiver(en.name),
            .callee = v.name,
            .is_builtin = false,
            .args = args,
            .trailing = &.{},
        } } } });
    }

    /// The enum a variant is written through: a section's own name
    /// (`__Tok__Pad`, which no import names), else the declared name
    /// (`constructorName`).
    fn enumReceiver(self: *Lifter, name: []const u8) Error!*ast.Expr {
        const spelled = if (std.mem.startsWith(u8, name, "__")) name else try self.constructorName(name);
        return try self.node(.{ .identifier = .{ .loc = self.nextLoc(), .kind = .{ .ident = spelled } } });
    }

    /// 01-compiler/14 step 8 — the record type `name`'s constructor, as the
    /// backends call it: by its declared name (decision 110 — an import's
    /// `as` on a type is a checker name only). When neither this module nor
    /// one of its imports declares it, the one module of the build that does
    /// is imported where the value is emitted (`Env.templateImports` under its
    /// alias, which `Env.importedTypeAliases` erases like any type alias) —
    /// `comptime styledComputed(…)` in a module that does not import `Styled`
    /// was a call of an unbound `Styled`. A prelude record or a type of std
    /// is called as before.
    fn constructorName(self: *Lifter, name: []const u8) Error![]const u8 {
        const env = self.env;
        for (env.moduleDecls) |d| switch (d) {
            .type_ => |t| if (std.mem.eql(u8, t.name, name)) return name,
            else => {},
        };
        var sit = env.stdModuleTypes.iterator();
        while (sit.next()) |e| for (e.value_ptr.*) |d| switch (d) {
            .type_ => |t| if (std.mem.eql(u8, t.name, name)) return name,
            else => {},
        };
        const registry = env.typeDeclRegistry orelse return name;
        var owner: ?[]const u8 = null;
        var it = registry.iterator();
        while (it.next()) |e| {
            const d = e.value_ptr.get(name) orelse continue;
            if (d != .type_) continue;
            if (owner != null) return name;
            owner = e.key_ptr.*;
        }
        const module = owner orelse return name;
        var imported = env.importedTypeDecls.iterator();
        while (imported.next()) |e| {
            if (std.mem.eql(u8, e.value_ptr.name, name) and std.mem.eql(u8, e.value_ptr.module, module)) return name;
        }
        const alias = try envMod.templateAlias(self.arena, module, name);
        if (!env.templateImports.contains(alias)) {
            try env.templateImports.put(env.arena, alias, .{ .owner = module, .name = name });
            try env.importedTypeAliases.put(env.arena, alias, name);
        }
        return name;
    }

    /// The record type a map is: the expected type when its fields are the
    /// map's keys, else the one type the evaluation carried (or the prelude
    /// declares) with exactly those fields.
    fn recordName(self: *Lifter, fields: []const Value.Field, hint: ?*T.Type) ?[]const u8 {
        if (hint) |h| switch (h.deref().*) {
            .named => |n| if (findType(self.env, n.name)) |found| {
                if (found.decl.shape == .record and sameFields(found.decl.shape.record, fields)) return n.name;
            },
            else => {},
        };
        var match: ?[]const u8 = null;
        for (self.support.types) |d| switch (d) {
            .type_ => |t| if (t.shape == .record and sameFields(t.shape.record, fields)) {
                if (match != null) return null;
                match = t.name;
            },
            else => {},
        };
        for (prelude_records) |r| if (sameNames(r.fields, fields)) {
            if (match != null) return null;
            match = r.name;
        };
        return match;
    }
};

const EnumHint = struct { name: []const u8, def: envMod.TypeDef.Enum };

/// The enum `hint` names (`?Tok` is `Tok`), as inference registered it —
/// its section wrappers included.
fn enumHint(env: *Env, hint: ?*T.Type) ?EnumHint {
    var h = (hint orelse return null).deref();
    if (h.* == .named and std.mem.eql(u8, h.named.name, "optional") and h.named.args.len == 1) h = h.named.args[0].deref();
    if (h.* != .named) return null;
    const def = env.lookupTypeDef(h.named.name) orelse return null;
    return if (def == .enum_) .{ .name = h.named.name, .def = def.enum_ } else null;
}

fn variantOf(en: envMod.TypeDef.Enum, tag: []const u8, arity: usize) ?envMod.VariantDef {
    for (en.variants) |v| if (std.mem.eql(u8, v.name, tag) and v.fields.len == arity) return v;
    return null;
}

/// Columns past any source line's width: a lifted node's location.
const lifted_col_base: usize = 1 << 24;

fn sameFields(decl: []const ast.Field, fields: []const Value.Field) bool {
    if (decl.len != fields.len) return false;
    for (decl) |d| {
        for (fields) |f| {
            if (std.mem.eql(u8, d.name, f.name)) break;
        } else return false;
    }
    return true;
}

fn sameNames(decl: []const []const u8, fields: []const Value.Field) bool {
    if (decl.len != fields.len) return false;
    for (decl) |d| {
        for (fields) |f| {
            if (std.mem.eql(u8, d, f.name)) break;
        } else return false;
    }
    return true;
}

fn fieldList(arena: std.mem.Allocator, fields: []const Value.Field) Error![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (fields, 0..) |f, i| {
        if (i > 0) try out.appendSlice(arena, ", ");
        try out.appendSlice(arena, f.name);
    }
    return out.items;
}

/// The `i`-th type argument of `hint` (an array's element, a tuple's element).
fn argOf(hint: ?*T.Type, i: usize) ?*T.Type {
    const h = hint orelse return null;
    return switch (h.deref().*) {
        .named => |n| if (i < n.args.len) n.args[i] else null,
        else => null,
    };
}

/// Decision 247 — the suffix that types a literal as `hint` when the bare
/// literal would type otherwise (`i32` for an integer, `f64` for a float).
fn numericSuffix(hint: ?*T.Type, floating: bool) []const u8 {
    const h = hint orelse return "";
    const name = switch (h.deref().*) {
        .named => |n| n.name,
        else => return "",
    };
    if (floating) {
        return if (std.mem.eql(u8, name, "f32")) "f" else "";
    }
    if (std.mem.eql(u8, name, "i32") or std.mem.eql(u8, name, "f64") or std.mem.eql(u8, name, "f32")) return "";
    const lexer = @import("../lexer.zig");
    for (lexer.number_suffixes) |s| if (std.mem.eql(u8, s.typeName, name)) return s.suffix;
    return "";
}

/// A string's bytes as a string literal's lexeme (escapes written back).
fn stringLexeme(arena: std.mem.Allocator, s: []const u8) Error![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (s) |c| switch (c) {
        '\\' => try out.appendSlice(arena, "\\\\"),
        '"' => try out.appendSlice(arena, "\\\""),
        '\n' => try out.appendSlice(arena, "\\n"),
        '\r' => try out.appendSlice(arena, "\\r"),
        '\t' => try out.appendSlice(arena, "\\t"),
        '$' => try out.appendSlice(arena, "\\$"),
        0 => try out.appendSlice(arena, "\\0"),
        else => if (c < 0x20) try out.print(arena, "\\u{{{x}}}", .{c}) else try out.append(arena, c),
    };
    return out.items;
}

/// `value` as the expression the program is emitted with, typed `ty` (the
/// `comptime`'s type) and located at `loc`.
pub fn lift(env: *Env, prepared: Prepared, support: Support, value: Value, ty: *T.Type, loc: ast.Loc) Error!Lifted {
    var l = Lifter{ .env = env, .arena = env.arena, .prepared = prepared, .support = support, .root = loc };
    const e = try l.value(value, ty, loc) orelse return .{ .refused = l.refusal orelse diagnostics.comptime_value_not_liftable };
    return .{ .expr = e };
}

// ── a hole's build value (decision 355) ─────────────────────────────────────

/// How deep `knownAtBuild` follows a `val` naming a `val`: past it the hole is
/// computed at render (a cycle is refused by inference before this runs).
const max_build_depth: usize = 32;

/// 01-compiler/14 step 8 — what a `${…}` hole of a template's literal is worth
/// at build (decision 355): `render` when the value is computed when the
/// program runs, `build` with the value as the term the template module reads
/// (`Part.value`), `refused` when it is known at build and raises there.
pub const HoleValue = union(enum) {
    render,
    build: Term,
    refused: struct { message: []const u8, loc: ast.Loc },
};

/// The module-level, non-`var` `val` `name` of this module, unless a local or
/// a parameter of the body being inferred shadows it.
fn moduleVal(env: *Env, name: []const u8) ?ast.ValDecl {
    if (env.localBindDepth(name) != null) return null;
    for (env.moduleDecls) |d| switch (d) {
        .val => |v| if (std.mem.eql(u8, v.name, name)) return if (v.mutable) null else v,
        else => {},
    };
    return null;
}

/// Decision 355 — a hole is known at build when its value is a literal, a
/// `comptime` value, a `val` of this module whose initializer is known at
/// build, or a template call (expanded already, `Env.templateExpansions`)
/// whose every argument is known at build — another `styled` / `styledProperty`
/// with no run-time hole. Anything else (a parameter, a local, a call, an
/// imported `val`, a `val` declared after the literal) is computed at render.
/// The rule reads the hole's value, never the template's text.
pub fn knownAtBuild(env: *Env, e: *const ast.Expr, depth: usize) bool {
    if (depth >= max_build_depth) return false;
    return switch (e.*) {
        .literal => |lit| switch (lit.kind) {
            .numberLit, .stringLit, .null_ => true,
            .stringTemplate => |t| for (t.parts) |part| switch (part) {
                .text => {},
                .expr => |hole| if (!knownAtBuild(env, hole, depth + 1)) break false,
            } else true,
            else => false,
        },
        .identifier => |id| switch (id.kind) {
            .ident => |name| std.mem.eql(u8, name, "true") or std.mem.eql(u8, name, "false") or
                if (moduleVal(env, name)) |v| knownAtBuild(env, v.value, depth + 1) else false,
            else => false,
        },
        .comptime_ => |ct| ct.kind == .comptimeExpr or ct.kind == .comptimeBlock,
        .call => |c| switch (c.kind) {
            .call => |cc| blk: {
                if (cc.is_builtin or cc.receiver != null or cc.trailing.len > 0) break :blk false;
                if (!env.templateExpansions.contains(c.loc)) break :blk false;
                for (cc.args) |a| if (!knownAtBuild(env, a.value, depth + 1)) break :blk false;
                break :blk true;
            },
            else => false,
        },
        else => false,
    };
}

/// The build value of the hole `e` (decision 355), evaluated on the comptime
/// runtime as a `comptime` of it would be — a `val`'s initializer, a template
/// call's expansion — and handed to the template as a term. A literal needs
/// no evaluation.
pub fn holeValue(env: *Env, io: std.Io, hole: *const ast.Expr) Error!HoleValue {
    if (!knownAtBuild(env, hole, 0)) return .render;
    // A `val` naming a `val` is the value its last initializer writes.
    var e = hole;
    var depth: usize = 0;
    while (depth < max_build_depth) : (depth += 1) switch (e.*) {
        .identifier => |id| switch (id.kind) {
            .ident => |name| if (moduleVal(env, name)) |v| {
                e = v.value;
            } else break,
            else => break,
        },
        else => break,
    };
    switch (e.*) {
        .literal => |lit| switch (lit.kind) {
            .stringLit => |lexeme| if (try templateEval.lexemeBytes(env.arena, lexeme)) |bytes| return .{ .build = Term.str(bytes) },
            .null_ => return .{ .build = Term.undefined_atom },
            else => {},
        },
        .identifier => |id| switch (id.kind) {
            .ident => |name| if (std.mem.eql(u8, name, "true") or std.mem.eql(u8, name, "false")) return .{ .build = .{ .boolean = name[0] == 't' } },
            else => {},
        },
        else => {},
    }
    const loc = hole.getLoc();
    const ct: ast.ComptimeExprOf(.untyped) = .{ .loc = loc, .kind = .{ .comptimeExpr = @constCast(e) } };
    var p = Preparer{ .env = env, .arena = env.arena, .declared = .empty, .inline_vals = 1, .rw = Rewrites.of(env) };
    const one = try env.arena.alloc(ast.Stmt, 1);
    one[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = try p.clone(*ast.Expr, ct.kind.comptimeExpr) } } } };
    const prepared: Prepared = .{ .value = synthFn(value_fn, one), .makers = p.makers.items };
    const support = try collectSupport(env, prepared);
    if (try unexpandedTemplateCall(env, prepared, support)) |msg| return .{ .refused = .{ .message = msg, .loc = loc } };
    if (try unresolvedSectionPath(env, support)) |msg| return .{ .refused = .{ .message = msg, .loc = loc } };
    const outcome = evaluate(env.arena, io, env.modulePath, prepared, support, &env.comptimeTraces) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.EvalFailed => return .{ .refused = .{ .message = "the comptime evaluator failed to run", .loc = loc } },
    };
    return switch (outcome) {
        .value => |v| if (try valueTerm(env.arena, v)) |t| .{ .build = t } else .render,
        .err => |msg| .{ .refused = .{ .message = msg, .loc = loc } },
    };
}

/// `v` as the term a template module reads (a record is its untagged map, a
/// variant its atom); a function value or a resource has none.
fn valueTerm(arena: std.mem.Allocator, v: Value) Error!?Term {
    return switch (v) {
        .null_ => Term.undefined_atom,
        .boolean => |b| .{ .boolean = b },
        .integer => |n| Term.int(n),
        .float => |f| .{ .float = f },
        .string => |str| Term.str(str),
        .atom => |a| Term.atomOf(a),
        .list, .tuple => |items| blk: {
            const out = try arena.alloc(Term, items.len);
            for (items, out) |item, *o| o.* = try valueTerm(arena, item) orelse return null;
            break :blk if (v == .list) Term.listOf(out) else Term.tupleOf(out);
        },
        .record => |fields| blk: {
            const out = try arena.alloc(Term.MapEntry, fields.len);
            for (fields, out) |f, *o| o.* = Term.field(f.name, try valueTerm(arena, f.value) orelse return null);
            break :blk Term.mapOf(out);
        },
        .function, .resource => null,
    };
}

// ── what a `comptime` may read ───────────────────────────────────────────────

pub const RuntimeRead = struct { name: []const u8, loc: ast.Loc };

/// The first name `ct` reads that has no value while the program is compiled:
/// a local or a parameter of the enclosing body, or a module-level `val` —
/// unless the block declares the name itself. The module-level rule is
/// `error.zig`'s `validateComptime`; this is its twin for a body.
pub fn runtimeRead(env: *Env, ct: ast.ComptimeExprOf(.untyped)) Error!?RuntimeRead {
    const root: ast.Expr = .{ .comptime_ = ct };
    const block: []const ast.Stmt = switch (ct.kind) {
        .comptimeBlock => |cb| cb.body,
        else => &.{},
    };
    var declared = try declaredNames(env.arena, block);
    if (ct.kind == .comptimeExpr) {
        var w = NameWalk{ .arena = env.arena, .out = &declared, .declared_only = true };
        try w.expr(ct.kind.comptimeExpr.*);
    }
    var r = ReadWalk{ .env = env, .declared = &declared };
    r.walk(ast.Expr, &root);
    return r.found;
}

const ReadWalk = struct {
    env: *Env,
    declared: *const std.StringHashMapUnmanaged(void),
    found: ?RuntimeRead = null,

    fn walk(self: *ReadWalk, comptime U: type, ptr: *const U) void {
        if (self.found != null) return;
        if (U == ast.Expr) switch (ptr.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |name| if (self.isRuntime(name)) {
                    self.found = .{ .name = name, .loc = id.loc };
                    return;
                },
                else => {},
            },
            else => {},
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldNames(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldNames(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldNames(p.child)) self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldNames(p.child)) {
                    for (ptr.*) |*e| self.walk(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }

    fn isRuntime(self: *ReadWalk, name: []const u8) bool {
        if (std.mem.eql(u8, name, "true") or std.mem.eql(u8, name, "false") or std.mem.eql(u8, name, "null")) return false;
        if (self.declared.contains(name)) return false;
        if (self.env.localBindDepth(name) != null) return true;
        for (self.env.moduleDecls) |d| switch (d) {
            .val => |v| if (std.mem.eql(u8, v.name, name)) return true,
            else => {},
        };
        return false;
    }
};

// ── tests ────────────────────────────────────────────────────────────────────

test "the reply reads back every value kind '__bp_lift'/2 writes" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const out = try parseReply(arena,
        \\{"kind":"value","value":[1,{"float":2.5},"s",true,null,{"tuple":[1,"a"]},{"record":{"x":1}},{"atom":"ok"},{"fn":0},{"fn":null},{"resource":"<0.1.0>"}]}
    );
    const items = out.value.list;
    try std.testing.expectEqual(@as(i64, 1), items[0].integer);
    try std.testing.expectEqual(@as(f64, 2.5), items[1].float);
    try std.testing.expectEqualStrings("s", items[2].string);
    try std.testing.expect(items[3].boolean);
    try std.testing.expect(items[4] == .null_);
    try std.testing.expectEqual(@as(usize, 2), items[5].tuple.len);
    try std.testing.expectEqualStrings("x", items[6].record[0].name);
    try std.testing.expectEqualStrings("ok", items[7].atom);
    try std.testing.expectEqual(@as(?usize, 0), items[8].function);
    try std.testing.expectEqual(@as(?usize, null), items[9].function);
    try std.testing.expect(items[10] == .resource);

    const failed = try parseReply(arena, "{\"kind\":\"error\",\"message\":\"error:badarith\"}");
    try std.testing.expectEqualStrings("the comptime block raised: error:badarith", failed.err);
}

test "decision 331: a capturing lambda, a resource and an unknown record are refused, not lifted" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var env = try @import("infer.zig").freshEnv(arena, std.heap.page_allocator);
    const prepared: Prepared = .{ .value = synthFn(value_fn, &.{}), .makers = &.{} };
    const support: Support = .{ .fns = &.{}, .types = &.{} };
    const ty = try env.namedType("unknown");
    const loc: ast.Loc = .{ .line = 3, .col = 5 };

    const cases = [_]struct { value: Value, needle: []const u8 }{
        .{ .value = .{ .function = null }, .needle = "captures the comptime block's state" },
        .{ .value = .{ .resource = "<0.1.0>" }, .needle = "a resource" },
        .{ .value = .{ .record = &.{.{ .name = "nobody", .value = .null_ }} }, .needle = "no type the block reaches declares" },
        .{ .value = .{ .float = std.math.inf(f64) }, .needle = "non-finite" },
    };
    for (cases) |c| {
        const out = try lift(&env, prepared, support, c.value, ty, loc);
        try std.testing.expect(out == .refused);
        try std.testing.expect(std.mem.startsWith(u8, out.refused, diagnostics.comptime_value_not_liftable));
        try std.testing.expect(std.mem.indexOf(u8, out.refused, c.needle) != null);
    }

    // A literal, a string with the characters a lexeme escapes, a list.
    const ok = try lift(&env, prepared, support, .{ .list = &.{ .{ .integer = -5 }, .{ .string = "a\"$\\" } } }, ty, loc);
    const elems = ok.expr.collection.kind.arrayLit.elems;
    try std.testing.expectEqualStrings("-5", elems[0].literal.kind.numberLit);
    try std.testing.expectEqualStrings("a\\\"\\$\\\\", elems[1].literal.kind.stringLit);
}

test "a block's own break becomes the value function's return; a loop's stays" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexerMod = @import("../lexer.zig");
    const parserMod = @import("../parser.zig");
    var lx = lexerMod.Lexer.init(
        \\val x = comptime {
        \\    var d = 0;
        \\    for ([1, 2]) { b -> if (b > 1) { break; } }
        \\    if (d > 0) { break 1; }
        \\    break d;
        \\};
    );
    var p = parserMod.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const body = try breaksToReturns(arena, program.decls[0].val.value.comptime_.kind.comptimeBlock.body);
    try std.testing.expect(body[1].expr == .loop);
    const inner = body[1].expr.loop.body[0].expr.branch.kind.if_.then_[0].expr;
    try std.testing.expect(inner.jump.kind == .@"break");
    try std.testing.expect(body[2].expr.branch.kind.if_.then_[0].expr.jump.kind == .@"return");
    try std.testing.expect(body[3].expr.jump.kind == .@"return");
}

// ── the types a decorator module carries ─────────────────────────────────────

/// The record and enum types `fns` (a decorator and the functions it reaches)
/// name — a package record an imported helper constructs (`Segment(…)` in
/// `routing`'s `parseSegment`), a type of the decorator's own module — with
/// the methods the functions call and the helpers of the type's module those
/// methods reach. A decorator module is untyped and one namespace: without
/// the declaration, `Segment(…)` lowered as a call of an undefined
/// `Segment/3` and the module did not compile on either runtime. `skip` names
/// the types the evaluator injects itself (`DeclKind`, `Span`, …).
pub fn typesReached(env: *Env, fns: []const ast.FnDecl, skip: []const []const u8) Error!Support {
    const arena = env.arena;
    var names: std.StringHashMapUnmanaged(void) = .empty;
    var methods: std.StringHashMapUnmanaged(void) = .empty;
    var fn_seen: std.StringHashMapUnmanaged(void) = .empty;
    for (fns) |f| {
        try fn_seen.put(arena, f.name, {});
        try readFn(arena, &names, &methods, f);
    }
    for (skip) |s| try fn_seen.put(arena, s, {});
    const TypeEntry = struct { decl: ast.TypeDecl, helpers: []const ast.FnDecl, kept: std.StringHashMapUnmanaged(void) };
    var types: std.StringArrayHashMapUnmanaged(TypeEntry) = .empty;
    var helpers: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    var changed = true;
    while (changed) {
        changed = false;
        var pending: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = names.keyIterator();
        while (it.next()) |n| try pending.append(arena, n.*);
        for (pending.items) |n| {
            if (fn_seen.contains(n) or types.contains(n)) continue;
            const found = findType(env, n) orelse continue;
            try types.put(arena, n, .{ .decl = found.decl, .helpers = found.helpers, .kept = .empty });
            try readTypeShape(arena, &names, found.decl);
            changed = true;
        }
        for (types.values()) |*entry| for (entry.decl.methods) |m| {
            if (entry.kept.contains(m.name) or !methods.contains(m.name)) continue;
            const body = m.body orelse continue;
            try entry.kept.put(arena, m.name, {});
            try readFree(arena, &names, body, m.params);
            try readMethodNames(arena, &methods, body);
            changed = true;
            var helper_names: std.StringHashMapUnmanaged(void) = .empty;
            try readFree(arena, &helper_names, body, m.params);
            for (entry.helpers) |h| {
                if (!helper_names.contains(h.name) or fn_seen.contains(h.name)) continue;
                try fn_seen.put(arena, h.name, {});
                try helpers.append(arena, h);
                try readFn(arena, &names, &methods, h);
            }
        };
    }
    var out_types: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (types.values()) |entry| {
        var decl = entry.decl;
        var kept: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        for (decl.methods) |m| if (entry.kept.contains(m.name)) try kept.append(arena, m);
        decl.methods = kept.items;
        decl.implement = &.{};
        decl.annotations = &.{};
        try out_types.append(arena, .{ .type_ = decl });
    }
    return .{ .fns = helpers.items, .types = out_types.items };
}
