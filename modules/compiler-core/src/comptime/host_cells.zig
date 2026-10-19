//! Decision 341 — the host functions a comptime module carries, and the cell
//! each comptime runtime runs.
//!
//! A body that runs at build (a decorator's, a template's, a `comptime`) is
//! one untyped module on the comptime runtime (`block_eval.zig`,
//! `decorator_eval.zig`, `template_eval.zig`): every function it reaches has
//! to be in it. Three things make a host function reachable there:
//!
//! - **std's functions travel.** A std function the code calls — through a
//!   namespace (`hash.contentHash(x)`) or a leaf import (`contentHash(x)`) —
//!   is carried with every function of its module (and of the std modules it
//!   imports) it reaches, each renamed `__bp_std__<module>__<name>` so none
//!   meets a function of the program of the same name (`StdFn`, built once by
//!   `comptime.registerStdlib`; `Writer` renames the calls a module writes).
//!   The node loads no std module: before this a std call was `call to
//!   undefined function contentHash/1`, or an unsupported method.
//! - **A bodyless host function travels with its cells** — this module's own
//!   (`declare fn`), an imported one, a std one — and with the function its
//!   `.Wasm(body: …)` binding names (`hostSupport`).
//! - **The comptime runtime resolves each host function in order** (decisions
//!   434 (4), 452, `forRuntime`): its std-wasm implementation — the export its
//!   `.Wasm(std: "<module>.<function>")` cell names (decision 440 (3),
//!   `stdCell`, `servedByStdWasm`; there is no match by name) —, else the
//!   botopink function its `.Wasm(body: …)` binding names (`callOf`);
//!   none → refused naming both (`comptime-host-cell-unavailable`). One
//!   adapter has a form at build: `wasi: .Attempt` (decisions 518, 543,
//!   `attemptAtBuild`), so `attempt` answers in a comptime body as in a wasm
//!   program.
//!   `.Erlang` never runs at build: the cell binds the erlang and
//!   beam targets only, and nothing in botopink calls beam-to-wasm (452).
//!   `.JavaScript` never serves: there is no Node at comptime.
//!
//! What a decorator may call is decided when its package is compiled
//! (`checkDecorators`, decisions 341, 434, 452): a host function it reaches
//! needs one of the two cells (`unservedReason`), or the call is refused,
//! located, naming the function and what is missing. The answer is one for
//! every target, whatever the package's `targets`.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("./env.zig");
const Env = envMod.Env;
const blockEval = @import("./block_eval.zig");
const diagnostics = @import("./diagnostics.zig");
const validation = @import("./error.zig");
const stdWasm = @import("std_wasm");

pub const Error = error{OutOfMemory};

/// Every carried std function's name starts so (`mangle`).
pub const std_prefix = "__bp_std__";

/// The name std function `name` of std module `module` (`hash`, `io/fs`)
/// has in a comptime module: `__bp_std__hash__contentHash`,
/// `__bp_std__io_fs__readText`.
pub fn mangle(arena: std.mem.Allocator, module: []const u8, name: []const u8) Error![]const u8 {
    const m = try arena.dupe(u8, module);
    std.mem.replaceScalar(u8, m, '/', '_');
    return std.fmt.allocPrint(arena, std_prefix ++ "{s}__{s}", .{ m, name });
}

/// How a diagnostic names a function a comptime module carries: a std one
/// as `<module>.<name>` (`hash.contentHash`), any other as declared.
pub fn display(arena: std.mem.Allocator, name: []const u8) Error![]const u8 {
    if (!std.mem.startsWith(u8, name, std_prefix)) return name;
    const rest = name[std_prefix.len..];
    const cut = std.mem.lastIndexOf(u8, rest, "__") orelse return rest;
    return std.fmt.allocPrint(arena, "{s}.{s}", .{ rest[0..cut], rest[cut + 2 ..] });
}

// ── what a module's std imports name ────────────────────────────────────────

/// A local name a module's `import … from "std"` binds: a std module (the
/// namespace form, `leaf == null`) or one function of one (`leaf`).
pub const StdRef = struct { module: []const u8, leaf: ?[]const u8 = null };
pub const StdTable = std.StringHashMapUnmanaged(StdRef);

/// The std names `decls` import, by the local name each binds — read from
/// the import as written, so a function another module carries keeps the
/// meaning its own module gave it. `isModule` answers whether a full path
/// (`hash`, `io/fs`) is a std module.
pub fn stdTable(arena: std.mem.Allocator, decls: []const ast.DeclKind, modules: anytype) Error!StdTable {
    var out: StdTable = .empty;
    for (decls) |d| switch (d) {
        .use => |u| {
            const from_std = switch (u.source) {
                .module => |m| std.mem.eql(u8, m, "std"),
                else => false,
            };
            if (!from_std) continue;
            for (u.imports) |imp| {
                const whole = try imp.fullPath(arena);
                if (modules.contains(whole)) {
                    try out.put(arena, imp.name(), .{ .module = whole });
                } else if (imp.isQualified()) {
                    try out.put(arena, imp.name(), .{ .module = try imp.prefixPath(arena), .leaf = imp.leaf() });
                }
            }
        },
        else => {},
    };
    return out;
}

// ── renaming the std calls a body writes ────────────────────────────────────

/// A copy of a function body with every call (and value) of a std function
/// renamed to its carried name (`mangle`): `hash.contentHash(x)` and a leaf
/// `contentHash(x)` both become `__bp_std__hash__contentHash(x)`. With `own`,
/// the functions of the module being renamed are renamed too (a std module's
/// own, carried beside the program's). A name the function declares itself
/// (a parameter, a local, a lambda's or a loop's parameter) is never renamed.
const Renamer = struct {
    arena: std.mem.Allocator,
    table: *const StdTable,
    /// This module's functions → their carried names (std modules only).
    own: ?*const std.StringHashMapUnmanaged([]const u8) = null,
    /// Whether a carried name exists (`StdCarried` or the names being built).
    exists: *const std.StringHashMapUnmanaged(void),
    shadow: std.StringHashMapUnmanaged(void) = .empty,
    /// The carried names the body reaches, in the order met.
    reached: std.ArrayListUnmanaged([]const u8) = .empty,
    changed: bool = false,

    fn note(self: *Renamer, name: []const u8) Error!void {
        for (self.reached.items) |r| if (std.mem.eql(u8, r, name)) return;
        try self.reached.append(self.arena, name);
    }

    fn resolveName(self: *Renamer, name: []const u8) Error!?[]const u8 {
        if (self.shadow.contains(name)) return null;
        if (self.own) |own| if (own.get(name)) |m| return m;
        const ref = self.table.get(name) orelse return null;
        const leaf = ref.leaf orelse return null;
        const m = try mangle(self.arena, ref.module, leaf);
        return if (self.exists.contains(m)) m else null;
    }

    fn resolveNs(self: *Renamer, ns: []const u8, callee: []const u8) Error!?[]const u8 {
        if (self.shadow.contains(ns)) return null;
        const ref = self.table.get(ns) orelse return null;
        if (ref.leaf != null) return null;
        const m = try mangle(self.arena, ref.module, callee);
        return if (self.exists.contains(m)) m else null;
    }

    fn replace(self: *Renamer, e: ast.Expr) Error!?ast.Expr {
        switch (e) {
            .call => |c| if (c.kind == .call and !c.kind.call.is_builtin and c.kind.call.calleeExpr == null) {
                const cc = c.kind.call;
                const renamed: ?[]const u8 = if (cc.receiver) |r| blk: {
                    if (r.* != .identifier) break :blk null;
                    break :blk switch (r.identifier.kind) {
                        .ident => |ns| try self.resolveNs(ns, cc.callee),
                        else => null,
                    };
                } else try self.resolveName(cc.callee);
                const name = renamed orelse return null;
                try self.note(name);
                self.changed = true;
                var out = c;
                // The call still starts where its receiver is written
                // (`io.random.float()` at `io`): where a raise inside it is
                // located (decision 451 (3), `erlang.ComptimeModule.located`).
                if (cc.receiver) |r| out.loc = r.getLoc();
                out.kind.call.receiver = null;
                out.kind.call.callee = name;
                out.kind.call.args = try self.clone([]ast.CallArg, cc.args);
                out.kind.call.trailing = try self.clone([]ast.TrailingLambda, cc.trailing);
                return .{ .call = out };
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (try self.resolveName(n)) |name| {
                    try self.note(name);
                    self.changed = true;
                    var out = id;
                    out.kind = .{ .ident = name };
                    return .{ .identifier = out };
                },
                else => {},
            },
            else => {},
        }
        return null;
    }

    fn clone(self: *Renamer, comptime U: type, v: U) Error!U {
        if (U == ast.Expr) if (try self.replace(v)) |r| return r;
        if (U == ast.TypeRef or U == ast.Pattern) return v;
        switch (@typeInfo(U)) {
            .@"struct" => |st| {
                var out: U = v;
                inline for (st.fields) |fl| {
                    if (fl.is_comptime) continue;
                    if (comptime blockEval.mayHoldNames(fl.type)) @field(out, fl.name) = try self.clone(fl.type, @field(v, fl.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return v;
                switch (v) {
                    inline else => |payload, tag| {
                        const P = @TypeOf(payload);
                        if (comptime !blockEval.mayHoldNames(P)) return v;
                        return @unionInit(U, @tagName(tag), try self.clone(P, payload));
                    },
                }
            },
            .optional => |o| return if (v) |inner| try self.clone(o.child, inner) else null,
            .pointer => |pt| switch (pt.size) {
                .one => {
                    if (comptime !blockEval.mayHoldNames(pt.child)) return v;
                    const n = try self.arena.create(pt.child);
                    n.* = try self.clone(pt.child, v.*);
                    return n;
                },
                .slice => {
                    if (comptime !blockEval.mayHoldNames(pt.child)) return v;
                    const out = try self.arena.alloc(pt.child, v.len);
                    for (v, 0..) |e, i| out[i] = try self.clone(pt.child, e);
                    return out;
                },
                else => return v,
            },
            else => return v,
        }
    }

    /// `f`'s body renamed; `f` itself (the same body) when nothing in it is.
    fn function(self: *Renamer, f: ast.FnDecl) Error!ast.FnDecl {
        self.shadow = try blockEval.declaredNames(self.arena, f.body);
        for (f.params) |p| try self.shadow.put(self.arena, p.name, {});
        const body = try self.clone([]ast.Stmt, f.body);
        if (!self.changed) return f;
        var out = f;
        out.body = body;
        return out;
    }
};

// ── std, carried ────────────────────────────────────────────────────────────

/// One std function as a comptime module carries it: renamed (`mangle`), its
/// calls of its own module's functions and of the std functions it imports
/// renamed too, and a `.Wasm(body: x)` binding naming `x`'s carried
/// name. `reaches` lists the carried names it needs beside it.
pub const StdFn = struct {
    decl: ast.FnDecl,
    reaches: []const []const u8,
};
pub const StdCarried = std.StringHashMapUnmanaged(StdFn);

/// One std module, as `registerStdlib` inferred it.
pub const StdModule = struct { name: []const u8, decls: []const ast.DeclKind };

/// Every top-level function of every module of `modules`, carried (`StdFn`).
/// `isModule` answers whether a full path is a std module.
pub fn buildStdCarried(arena: std.mem.Allocator, modules: []const StdModule, isModule: anytype) Error!*StdCarried {
    var exists: std.StringHashMapUnmanaged(void) = .empty;
    for (modules) |m| for (m.decls) |d| if (d == .@"fn") {
        try exists.put(arena, try mangle(arena, m.name, d.@"fn".name), {});
    };
    const out = try arena.create(StdCarried);
    out.* = .empty;
    for (modules) |m| {
        const table = try stdTable(arena, m.decls, isModule);
        var own: std.StringHashMapUnmanaged([]const u8) = .empty;
        for (m.decls) |d| if (d == .@"fn") try own.put(arena, d.@"fn".name, try mangle(arena, m.name, d.@"fn".name));
        for (m.decls) |d| {
            if (d != .@"fn") continue;
            const f = d.@"fn";
            var r = Renamer{ .arena = arena, .table = &table, .own = &own, .exists = &exists };
            var decl = try r.function(f);
            decl.name = own.get(f.name).?;
            decl.isPub = false;
            // `fn:x` names a function of this module: its carried name.
            if (wasmBinding(f)) |binding| if (std.mem.startsWith(u8, binding.text, "fn:")) {
                if (own.get(binding.text["fn:".len..])) |target| {
                    try r.note(target);
                    decl.implementations = try withWasmTarget(arena, f.implementations, binding.index, target);
                }
            };
            try out.put(arena, decl.name, .{ .decl = decl, .reaches = r.reached.items });
        }
    }
    return out;
}

/// `implementations` with the `.Wasm` one at `index` binding `body: <target>`.
fn withWasmTarget(arena: std.mem.Allocator, implementations: []const ast.Implementation, index: usize, target: []const u8) Error![]ast.Implementation {
    const out = try arena.dupe(ast.Implementation, implementations);
    out[index].cell = .{ .kind = .body, .value = target };
    out[index].text = try std.fmt.allocPrint(arena, "fn:{s}", .{target});
    return out;
}

/// The `.Wasm` implementation of `f` — its index and its text (`fn:x`,
/// `op:f64.floor`, `wasi:…`) — a binding for any host.
pub fn wasmBinding(f: ast.FnDecl) ?struct { index: usize, text: []const u8 } {
    for (f.implementations, 0..) |impl, i| {
        if (impl.target != .wasm) continue;
        return .{ .index = i, .text = impl.text };
    }
    return null;
}

/// Whether `f` is a host function: declared without a body, served by its
/// implementations.
pub fn isHost(f: ast.FnDecl) bool {
    return f.body.len == 0 and f.isExternal();
}

// ── a module's functions, carried ───────────────────────────────────────────

/// The functions written in one module (`env`'s), carried into a comptime
/// module: `rewrite` renames their std calls; `hostSupport` answers what they
/// need beside them.
pub const Writer = struct {
    env: *Env,
    table: StdTable,
    exists: std.StringHashMapUnmanaged(void) = .empty,

    pub fn init(env: *Env, decls: []const ast.DeclKind) Error!Writer {
        var w = Writer{ .env = env, .table = try stdTable(env.arena, decls, &env.stdModules) };
        if (env.stdCarried) |carried| {
            var it = carried.keyIterator();
            while (it.next()) |k| try w.exists.put(env.arena, k.*, {});
        }
        return w;
    }

    /// The carried name of the std function `ns.callee` names, or null.
    pub fn resolveNs(self: *Writer, ns: []const u8, callee: []const u8) Error!?[]const u8 {
        var r = Renamer{ .arena = self.env.arena, .table = &self.table, .exists = &self.exists };
        return r.resolveNs(ns, callee);
    }

    /// The carried name of the std function a leaf import binds as `name`.
    pub fn resolveLeaf(self: *Writer, name: []const u8) Error!?[]const u8 {
        var r = Renamer{ .arena = self.env.arena, .table = &self.table, .exists = &self.exists };
        return r.resolveName(name);
    }

    /// `f` with its std calls renamed, or `f` itself when it writes none;
    /// one copy per function of the module (`Env.stdRewritten`).
    pub fn rewrite(self: *Writer, f: ast.FnDecl) Error!ast.FnDecl {
        return self.rewriteAs(f, f);
    }

    /// `f` — a copy of `original` another pass made (its `same` calls
    /// lowered, its tuple reads relabelled) — renamed, one copy per
    /// `original`: every closure carrying the function carries that one.
    pub fn rewriteAs(self: *Writer, original: ast.FnDecl, f: ast.FnDecl) Error!ast.FnDecl {
        if (self.table.count() == 0 or f.body.len == 0) return f;
        const key = @intFromPtr(original.body.ptr);
        if (self.env.stdRewritten.get(key)) |done| return done;
        var r = Renamer{ .arena = self.env.arena, .table = &self.table, .exists = &self.exists };
        const out = try r.function(f);
        try self.env.stdRewritten.put(self.env.arena, key, out);
        return out;
    }
};

/// What `fns` need beside them in a comptime module that are not among
/// them: the bodyless host functions their bodies name — of this module
/// (`local`, by name) or carried in an imported closure — with the function
/// a `fn:` binding names and what that one reaches in its module, and every
/// std function they reach (`StdCarried`, closed). `local` answers a name
/// with a function of this module (`Env.fnDecls`, or the program's decls).
pub fn hostSupport(env: *Env, local: anytype, fns: []const ast.FnDecl) Error![]const ast.FnDecl {
    const arena = env.arena;
    var have: std.StringHashMapUnmanaged(void) = .empty;
    for (fns) |f| try have.put(arena, f.name, {});
    var out: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    // `bound`: the function was reached through a `fn:` binding (or from one
    // that was), so nothing carries what it calls yet.
    const Pending = struct { f: ast.FnDecl, bound: bool };
    var pending: std.ArrayListUnmanaged(Pending) = .empty;
    for (fns) |f| try pending.append(arena, .{ .f = f, .bound = false });
    var i: usize = 0;
    while (i < pending.items.len) : (i += 1) {
        const f = pending.items[i].f;
        var names: std.StringHashMapUnmanaged(void) = .empty;
        try blockEval.readFreeNames(arena, &names, f.body, f.params);
        // A `fn:` binding is a call of the function it names.
        var target: []const u8 = "";
        if (isHost(f)) if (wasmBinding(f)) |b| if (std.mem.startsWith(u8, b.text, "fn:")) {
            target = b.text["fn:".len..];
            try names.put(arena, target, {});
        };
        var it = names.keyIterator();
        while (it.next()) |n| {
            if (have.contains(n.*)) continue;
            if (std.mem.startsWith(u8, n.*, std_prefix)) {
                const carried = env.stdCarried orelse continue;
                const sf = carried.get(n.*) orelse continue;
                try have.put(arena, n.*, {});
                // Decision 720 — a std function that runs only when the program
                // runs is carried as a raise: reached while the build runs (a
                // call through a function value the checker cannot follow), it
                // is `run-in-build` at that call; never reached, nothing.
                if (try runsOnlyAtRunTime(arena, carried, n.*, 0)) {
                    const raise = try runInBuildRaiser(arena, sf.decl);
                    try out.append(arena, try callOf(arena, sf.decl, raise.name));
                    try out.append(arena, raise);
                    continue;
                }
                try out.append(arena, sf.decl);
                try pending.append(arena, .{ .f = sf.decl, .bound = true });
                continue;
            }
            const g: ast.FnDecl = local.get(n.*) orelse continue;
            // A function with a body is carried already when the code
            // reaches it by a call (`infer.decoratorSupport`,
            // `block_eval.collectSupport`); the ones met here are the host
            // functions, what their bindings name, and what those call.
            const bound = pending.items[i].bound or std.mem.eql(u8, n.*, target);
            if (!isHost(g) and !bound) continue;
            try have.put(arena, n.*, {});
            try out.append(arena, g);
            try pending.append(arena, .{ .f = g, .bound = bound });
        }
    }
    return out.items;
}

// ── each runtime runs its cell ──────────────────────────────────────────────

pub const Selected = union(enum) {
    ok: []ast.DeclKind,
    /// A host function none of the comptime sources serves.
    refused: []const u8,
};

/// `decls` (a comptime module's) with each host function as the comptime
/// runtime — wasm, for every target (decision 434) — runs it, by the first of
/// its cells present (434 (4), 452): its std-wasm implementation, the botopink
/// function its `.Wasm(body: …)` binding names; none → refused. An
/// `.Erlang` cell never runs at build.
pub fn forRuntime(arena: std.mem.Allocator, decls: []const ast.DeclKind) Error!Selected {
    const out = try arena.dupe(ast.DeclKind, decls);
    for (out) |*d| {
        if (d.* != .@"fn" or !isHost(d.@"fn")) continue;
        const f = d.@"fn";
        if (runInBuildRaise(f)) |raise| {
            d.* = .{ .@"fn" = try withErlangTemplate(arena, f, raise) };
            continue;
        }
        if (stdCell(f)) |cell| switch (cell) {
            .ok => |e| {
                d.* = .{ .@"fn" = try servedByStdWasm(arena, f, e) };
                continue;
            },
            .unknown => |name| return .{ .refused = try noStdExport(arena, f, name) },
        };
        // Its `.Wasm(body: …)` cell.
        const b = wasmBinding(f) orelse return .{ .refused = try unavailable(arena, f) };
        if (isAttemptAdapter(b.text)) {
            d.* = .{ .@"fn" = try attemptAtBuild(arena, f) };
            continue;
        }
        if (!std.mem.startsWith(u8, b.text, "fn:")) return .{ .refused = try unavailable(arena, f) };
        d.* = .{ .@"fn" = try callOf(arena, f, b.text["fn:".len..]) };
    }
    return .{ .ok = out };
}

/// Decision 720 — the `.Wasm` binding text of a std function carried as a
/// raise (`runInBuildStub`): never written in a source, read by `forRuntime`.
const run_in_build_binding = "build:run-in-build";

/// Decisions 376 (4), 720 — whether the carried std function `name` runs only
/// when the program runs: a host declared without `#[@Stage.Any]` that no
/// comptime cell serves, or a body reaching one. A host one of the two cells
/// serves (a seeded draw, decision 451) runs at build as it always did.
fn runsOnlyAtRunTime(arena: std.mem.Allocator, carried: *const StdCarried, name: []const u8, depth: usize) Error!bool {
    if (depth > 24) return false;
    const sf = carried.get(name) orelse return false;
    const f = sf.decl;
    if (isHost(f)) {
        for (f.annotations) |a| if (a.is_builtin and std.mem.eql(u8, a.name, "Stage.Any")) return false;
        return try unservedReason(arena, f) != null;
    }
    for (sf.reaches) |r| {
        if (std.mem.eql(u8, r, name)) continue;
        if (try runsOnlyAtRunTime(arena, carried, r, depth + 1)) return true;
    }
    return false;
}

/// Decision 720 — the host a std function `f` that runs only when the program
/// runs is carried as a call of (`callOf`): its one cell raises
/// `run-in-build`, naming `f`; the comptime runtime reports the raise at the
/// call that reached `f` (decision 532), the frames down to the body the build
/// was running. `f` keeps a body, so a value naming it is a function value.
fn runInBuildRaiser(arena: std.mem.Allocator, f: ast.FnDecl) Error!ast.FnDecl {
    const raise = try std.fmt.allocPrint(
        arena,
        "erlang:error({{bp_wat_runtime, <<\"{s}: `{s}` runs only when the program runs, and the build reached it\">>}})",
        .{ diagnostics.run_in_build, try display(arena, f.name) },
    );
    const impl = try arena.alloc(ast.Implementation, 2);
    impl[0] = .{ .target = .erlang, .template = raise, .text = raise };
    impl[1] = .{ .target = .wasm, .text = run_in_build_binding };
    var out = f;
    out.name = try std.fmt.allocPrint(arena, "{s}__run_in_build", .{f.name});
    out.body = &.{};
    out.isDeclare = true;
    out.annotations = &.{};
    out.implementations = impl;
    return out;
}

/// The raise a `runInBuildStub` carries, or null for any other function.
fn runInBuildRaise(f: ast.FnDecl) ?[]const u8 {
    const b = wasmBinding(f) orelse return null;
    if (!std.mem.eql(u8, b.text, run_in_build_binding)) return null;
    for (f.implementations) |i| if (i.target == .erlang) return i.template;
    return null;
}

/// The refusal of a host function neither of the two comptime cells serves
/// (decisions 434 (4), 452), naming both.
fn unavailable(arena: std.mem.Allocator, f: ast.FnDecl) Error![]const u8 {
    const name = try display(arena, f.name);
    return std.fmt.allocPrint(arena, "{s}: `{s}` is reached at comptime and has no `.Wasm(std: \"…\")` cell (std-wasm) and no `.Wasm(body: …)` cell — the two cells the comptime runtime answers by; an `.Erlang` cell never runs at build (decisions 434, 452)", .{ diagnostics.comptime_host_cell_unavailable, name });
}

/// What `f`'s `.Wasm(std: "<module>.<function>")` cell names
/// (decision 440 (3)): the std-wasm export, or the name when std-wasm has
/// none of it (the checker refuses that at the annotation,
/// `infer.refuseStdBinding`); null when `f` has no `std:` cell.
pub fn stdCell(f: ast.FnDecl) ?union(enum) { ok: stdWasm.Export, unknown: []const u8 } {
    const b = wasmBinding(f) orelse return null;
    if (!std.mem.startsWith(u8, b.text, std_cell_prefix)) return null;
    const name = b.text[std_cell_prefix.len..];
    return if (stdWasm.find(name)) |e| .{ .ok = e } else .{ .unknown = name };
}

/// The prefix of a binding std-wasm serves (decision 440 (3)).
pub const std_cell_prefix = "std:";

fn noStdExport(arena: std.mem.Allocator, f: ast.FnDecl, name: []const u8) Error![]const u8 {
    return std.fmt.allocPrint(arena, "{s}: `{s}`'s .Wasm(std: \"{s}\") names no function std-wasm implements (decision 440)", .{ diagnostics.comptime_host_cell_unavailable, try display(arena, f.name), name });
}

/// `f` as a call of the std-wasm export its `std:` cell names: its one cell
/// becomes `.Erlang("bp_std_wasm:<symbol>(…)")`, which the comptime
/// module writes as `bp_std_wasm:<symbol>(…)` and the wat runtime's lowering
/// calls as `rt_std_<symbol>`.
fn servedByStdWasm(arena: std.mem.Allocator, f: ast.FnDecl, e: stdWasm.Export) Error!ast.FnDecl {
    var buf: [128]u8 = undefined;
    var call: std.ArrayListUnmanaged(u8) = .empty;
    try call.print(arena, "{s}:{s}(", .{ stdWasm.erlang_module, e.symbolInto(&buf) });
    for (0..f.params.len) |k| try call.print(arena, "{s}${d}", .{ if (k > 0) ", " else "", k });
    try call.append(arena, ')');
    return withErlangTemplate(arena, f, call.items);
}

/// `f` with its one implementation the `.Erlang` template `template`.
fn withErlangTemplate(arena: std.mem.Allocator, f: ast.FnDecl, template: []const u8) Error!ast.FnDecl {
    const impl = try arena.alloc(ast.Implementation, 1);
    impl[0] = .{ .target = .erlang, .template = template, .text = template };
    var out = f;
    out.implementations = impl;
    return out;
}

/// Decisions 518, 543 — `wasi: .Attempt` (std's `failure.caught`, under
/// `attempt` and `attemptTask`) runs at build as in a wasm program: the thunk
/// called, an abort it raises caught — `{ok, Value}`, or `{error, Message}`
/// with the abort's text. A comptime module is Erlang lowered to wasm, its
/// aborts the Erlang errors the untyped emitter raises: `{panic, M}` and
/// `{todo, M}` (`@panic`, `@todo`) and a failed assert's `{bp_assert, Msg,
/// Where, Panic}` (its panic text, decision 527 (2)); any other raise goes on,
/// as a trap goes on through a wasm `try_table`.
pub fn isAttemptAdapter(text: []const u8) bool {
    return std.mem.eql(u8, text, "wasi:attempt");
}

const attempt_at_build =
    "(fun(__F) -> try {ok, __F()} catch " ++
    "error:{__T, __M} when __T =:= panic orelse __T =:= todo -> {error, unicode:characters_to_binary(__M)}; " ++
    "error:{bp_assert, _, _, __M} -> {error, unicode:characters_to_binary(__M)} end end)($0)";

/// `f` (a `wasi: .Attempt` binding) with its one cell the comptime's form,
/// `attempt_at_build`, which the comptime module writes inline.
fn attemptAtBuild(arena: std.mem.Allocator, f: ast.FnDecl) Error!ast.FnDecl {
    return withErlangTemplate(arena, f, attempt_at_build);
}

/// `fn <f>(<params>) { return <target>(<params>); }` — a host function bound
/// to a botopink function, as the wat runtime runs it.
fn callOf(arena: std.mem.Allocator, f: ast.FnDecl, target: []const u8) Error!ast.FnDecl {
    const loc: ast.Loc = f.nameLoc;
    const args = try arena.alloc(ast.CallArg, f.params.len);
    for (args, f.params) |*a, p| {
        const ref = try arena.create(ast.Expr);
        ref.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = p.name } } };
        a.* = .{ .label = null, .value = ref };
    }
    const call = try arena.create(ast.Expr);
    call.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = target,
        .is_builtin = false,
        .args = args,
        .trailing = &.{},
    } } } };
    const body = try arena.alloc(ast.Stmt, 1);
    body[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = call } } } };
    var out = f;
    out.annotations = &.{};
    out.implementations = &.{};
    out.isDeclare = false;
    out.body = body;
    return out;
}

// ── what a decorator may call (decisions 341, 434) ──────────────────────────

/// Why the host function `f` cannot run at comptime, or null when one of the
/// two cells serves it (decisions 434 (4), 452): its `std:` cell (std-wasm),
/// its `.Wasm(body: …)` cell.
/// The answer is one for every target.
pub fn unservedReason(arena: std.mem.Allocator, f: ast.FnDecl) Error!?[]const u8 {
    if (runInBuildRaise(f) != null) return null;
    if (stdCell(f)) |cell| switch (cell) {
        .ok => return null,
        .unknown => |name| return try noStdExport(arena, f, name),
    };
    if (wasmBinding(f)) |b| if (std.mem.startsWith(u8, b.text, "fn:") or isAttemptAdapter(b.text)) return null;
    return try unavailable(arena, f);
}

/// Refuses, at the call, a host function a decorator of this module reaches
/// — in its body, in a function of this module it calls, or through a std
/// function or an imported one — that neither of the two comptime cells
/// serves (decisions 341, 434), when the package itself is compiled. `decls`
/// is the module as parsed; `env` holds its imports' closures
/// (`Env.importedFnSupport`).
pub fn checkDecorators(env: *Env, decls: []const ast.DeclKind, isDecorator: anytype) Error!?validation.TypeError {
    const arena = env.arena;
    var local: std.StringHashMapUnmanaged(ast.FnDecl) = .empty;
    for (decls) |d| if (d == .@"fn") try local.put(arena, d.@"fn".name, d.@"fn");
    var writer = try Writer.init(env, decls);
    for (decls) |d| {
        if (d != .@"fn") continue;
        const dfn = d.@"fn";
        if (dfn.body.len == 0 or !isDecorator(dfn.params)) continue;
        // The functions of this module the decorator reaches, by calls.
        var seen: std.StringHashMapUnmanaged(void) = .empty;
        var queue: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
        try queue.append(arena, dfn);
        try seen.put(arena, dfn.name, {});
        var i: usize = 0;
        while (i < queue.items.len) : (i += 1) {
            const f = queue.items[i];
            var calls = CallWalk{ .arena = arena };
            for (f.body) |*st| try calls.walk(ast.Expr, &st.expr);
            const shadow = try blockEval.declaredNames(arena, f.body);
            for (calls.found.items) |c| {
                if (c.ns == null and (shadow.contains(c.callee) or paramNamed(f, c.callee))) continue;
                if (c.ns) |ns| if (shadow.contains(ns) or paramNamed(f, ns)) continue;
                // A function of this module.
                if (c.ns == null) if (local.get(c.callee)) |g| {
                    if (isHost(g)) {
                        if (try unservedReason(arena, g)) |msg| return located(msg, c.loc);
                    } else if (!seen.contains(g.name)) {
                        try seen.put(arena, g.name, {});
                        try queue.append(arena, g);
                    }
                    continue;
                };
                // A std function, and every std function it reaches.
                const std_name: ?[]const u8 = if (c.ns) |ns| try writer.resolveNs(ns, c.callee) else try writer.resolveLeaf(c.callee);
                if (std_name) |sn| {
                    if (try stdUnserved(env, sn)) |msg| return located(msg, c.loc);
                    continue;
                }
                // An imported function, with its closure.
                if (c.ns == null) if (env.importedFnSupport.get(c.callee)) |closure| {
                    for (closure) |g| if (isHost(g)) {
                        if (try unservedReason(arena, g)) |msg| return located(msg, c.loc);
                    };
                };
            }
        }
    }
    return null;
}

fn paramNamed(f: ast.FnDecl, name: []const u8) bool {
    for (f.params) |p| if (std.mem.eql(u8, p.name, name)) return true;
    return false;
}

fn located(msg: []const u8, loc: ast.Loc) validation.TypeError {
    return validation.TypeError.custom(msg, "A host function a decorator reaches runs at comptime on the wasm runtime, for every target (decisions 434, 452): give it an `.Wasm(std: \"…\")` cell (std-wasm) or an `.Wasm(body: …)` cell naming a botopink body. An `.Erlang` cell never runs at build. `.JavaScript` never serves a decorator: there is no Node at comptime.").withLoc(loc);
}

/// The std function `name` (carried) and every one it reaches: the reason
/// the first host function among them that no source serves cannot run.
fn stdUnserved(env: *Env, name: []const u8) Error!?[]const u8 {
    const carried = env.stdCarried orelse return null;
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    var queue: std.ArrayListUnmanaged([]const u8) = .empty;
    try queue.append(env.arena, name);
    var i: usize = 0;
    while (i < queue.items.len) : (i += 1) {
        const n = queue.items[i];
        if (seen.contains(n)) continue;
        try seen.put(env.arena, n, {});
        const sf = carried.get(n) orelse continue;
        if (isHost(sf.decl)) {
            if (try unservedReason(env.arena, sf.decl)) |msg| return msg;
            // A `fn:` binding's target is the wasm cell, not a call to check.
            continue;
        }
        for (sf.reaches) |r| try queue.append(env.arena, r);
    }
    return null;
}

/// Every call a body writes that is not a builtin: `callee(…)`, or
/// `ns.callee(…)` with `ns` a name.
const CallWalk = struct {
    arena: std.mem.Allocator,
    found: std.ArrayListUnmanaged(Call) = .empty,

    const Call = struct { ns: ?[]const u8, callee: []const u8, loc: ast.Loc };

    fn walk(self: *CallWalk, comptime U: type, ptr: *const U) Error!void {
        if (U == ast.Expr) switch (ptr.*) {
            .call => |c| {
                // A `compiler.init` executor is run-time code (decisions 575 (3), 580): it is
                // spliced into the program's init list, so what it calls is not reached at build.
                if (ast.isExecutorCall(ptr.*)) return;
                if (c.kind == .call and !c.kind.call.is_builtin and c.kind.call.calleeExpr == null) {
                    const cc = c.kind.call;
                    if (cc.receiver) |r| {
                        if (r.* == .identifier and r.identifier.kind == .ident) try self.found.append(self.arena, .{ .ns = r.identifier.kind.ident, .callee = cc.callee, .loc = c.loc });
                    } else try self.found.append(self.arena, .{ .ns = null, .callee = cc.callee, .loc = c.loc });
                }
            },
            else => {},
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (fl.is_comptime) continue;
                if (comptime blockEval.mayHoldNames(fl.type)) try self.walk(fl.type, &@field(ptr.*, fl.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime blockEval.mayHoldNames(@TypeOf(payload.*))) try self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |pt| switch (pt.size) {
                .one => if (comptime blockEval.mayHoldNames(pt.child)) try self.walk(pt.child, ptr.*),
                .slice => if (comptime blockEval.mayHoldNames(pt.child)) {
                    for (ptr.*) |*e| try self.walk(pt.child, e);
                },
                else => {},
            },
            else => {},
        }
    }
};

test "stdCell: the export a std: cell names, and a name std-wasm lacks" {
    var impl = [_]ast.Implementation{.{ .target = .wasm, .cell = .{ .kind = .std_, .value = "hash.contentHash" }, .text = "std:hash.contentHash" }};
    const f: ast.FnDecl = .{ .isPub = true, .name = "contentHash", .genericParams = &.{}, .params = &.{}, .returnType = null, .body = &.{}, .implementations = &impl };
    try std.testing.expectEqualStrings("hash.contentHash", stdCell(f).?.ok.name);
    var bad = [_]ast.Implementation{.{ .target = .wasm, .cell = .{ .kind = .std_, .value = "hash.sha256" }, .text = "std:hash.sha256" }};
    const g: ast.FnDecl = .{ .isPub = true, .name = "sha256", .genericParams = &.{}, .params = &.{}, .returnType = null, .body = &.{}, .implementations = &bad };
    try std.testing.expectEqualStrings("hash.sha256", stdCell(g).?.unknown);
    var fnc = [_]ast.Implementation{.{ .target = .wasm, .cell = .{ .kind = .body, .value = "body" }, .text = "fn:body" }};
    const h: ast.FnDecl = .{ .isPub = true, .name = "h", .genericParams = &.{}, .params = &.{}, .returnType = null, .body = &.{}, .implementations = &fnc };
    try std.testing.expect(stdCell(h) == null);
}
