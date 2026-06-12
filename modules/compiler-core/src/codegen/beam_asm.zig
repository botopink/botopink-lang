/// BEAM Assembly (`.S`) codegen backend.
///
/// Emits the textual format produced by `erlc +to_asm <file>.erl`, which
/// `erlc +from_asm <file>.S` can re-assemble back to a `.beam`.
///
/// **Fase 2 scope** (this file): everything from Fase 1 (numeric `fn` decls,
/// arithmetic via `gc_bif`, comparisons via `{test, is_*, ...}`, `if/else`,
/// `return`, top-level `val`, `fn main/0` wrapper) plus:
///   - local bindings (`val name = expr`) via y-registers with
///     `{allocate, N, Arity}` / `{deallocate, N}` framing;
///   - local calls (`fn1(args)`) via `{call, Arity, {f, EntryLabel}}` for
///     non-tail position; `{call_last, ...}` / `{call_only, ...}` when the
///     call is the tail of a `return`;
///   - `@todo()` builtin lowered to `erlang:error(undef)`.
///
/// Subsequent fases (3–8) lowered strings/`@print`, records/structs, enums as
/// tagged tuples, closures (`make_fun2`), case/pattern matching, loops, ranges
/// (`lists:seq/2`), and try/catch (`{try, …}` / `{try_end, …}` / `{try_case,
/// …}`). Anything still unhandled emits `%% unsupported: <kind>` and is skipped.
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const crossModule = @import("./crossModule.zig");
const envMod = @import("../comptime/env.zig");

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;
const CrossModule = crossModule.CrossModule;

// ── helpers ──────────────────────────────────────────────────────────────────

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

fn isMain0(f: ast.FnDecl) bool {
    return std.mem.eql(u8, f.name, "main") and fnArityNoSelf(f) == 0;
}

/// True if `stmt` is a `return` expression. Used to suppress dead jumps after
/// an `if` branch that already exits.
fn stmtIsReturn(stmt: ast.Stmt) bool {
    return switch (stmt.expr) {
        .jump => |j| switch (j.kind) {
            .@"return" => true,
            else => false,
        },
        else => false,
    };
}

/// True if every control-flow path in `body` terminates explicitly (via
/// `return` or an `if` whose both branches return). Used to decide whether an
/// implicit `return.` is needed at the end of a fn body.
fn bodyExits(body: []const ast.Stmt) bool {
    if (body.len == 0) return false;
    const last = body[body.len - 1];
    return switch (last.expr) {
        .jump => |j| switch (j.kind) {
            .@"return", .throw_, .yield, .@"continue" => true,
            else => false,
        },
        .branch => |b| switch (b.kind) {
            .if_ => |i| {
                if (i.else_) |els| return bodyExits(i.then_) and bodyExits(els);
                return false;
            },
            else => false,
        },
        else => false,
    };
}

/// True for the synthetic top-level vals the comptime transform injects to
/// model script-level entrypoint calls (names starting with `_`).
fn isSyntheticEntrypointVal(v: ast.ValDecl) bool {
    return std.mem.startsWith(u8, v.name, "_");
}

/// Arity for an `InterfaceMethod` (`self` is always present in member methods
/// and gets x0; we count it just like a regular fn param).
fn methodArity(m: ast.InterfaceMethod) usize {
    return m.params.len;
}

/// True when a record/struct/enum method is an associated fn — no `self`
/// receiver, so it's reachable as `Type.method(...)` and, across modules, as a
/// remote `call_ext` into the owner.
fn isAssocMethod(m: ast.InterfaceMethod) bool {
    return m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self");
}

/// Arity for an `ImplementMethod` (same convention).
fn implementMethodArity(m: ast.ImplementMethod) usize {
    return m.params.len;
}

/// `_N` tuple-index member (`t._0`, `t._1`) → the 0-based index, else null.
/// Distinguishes tuple element access from a record field that happens to start
/// with `_`. Mirrors the erlang/wat backends.
fn tupleIndexMember(member: []const u8) ?u32 {
    if (member.len < 2 or member[0] != '_') return null;
    var n: u32 = 0;
    for (member[1..]) |c| {
        if (!std.ascii.isDigit(c)) return null;
        n = n * 10 + (c - '0');
    }
    return n;
}

/// True when another module imports `name` (so the owner must export its
/// associated fns for the consumer's remote `call_ext` to resolve).
fn isCrossImported(cross: ?*const CrossModule, name: []const u8) bool {
    const xc = cross orelse return false;
    return xc.imported.contains(name);
}

/// Append `'Owner_methodName'/arity` for every exported method in `methods`.
/// A method is exported when it's `pub`, or — when `force_assoc` (the owner
/// type is imported by another module) — when it's an associated fn another
/// module reaches via a remote call. Caller owns the `owned` tracker — every
/// allocated string is pushed there so it gets freed after the header.
fn collectMethodExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    owner: []const u8,
    methods: []const ast.InterfaceMethod,
    force_assoc: bool,
) !void {
    for (methods) |m| {
        if (m.body == null or m.is_declare) continue;
        if (!m.isPub and !(force_assoc and isAssocMethod(m))) continue;
        const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ owner, m.name });
        try owned.append(alloc, mangled);
        try exports.append(alloc, .{ .name = mangled, .arity = methodArity(m) });
    }
}

fn collectStructExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    s: ast.StructDecl,
    force_assoc: bool,
) !void {
    for (s.members) |mem| switch (mem) {
        .field => {},
        // Getters/setters don't carry an `isPub` bit — struct accessors are
        // always considered part of the struct's public surface.
        .getter => |g| {
            const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ s.name, g.name });
            try owned.append(alloc, mangled);
            try exports.append(alloc, .{ .name = mangled, .arity = 1 });
        },
        .setter => |st| {
            const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ s.name, st.name });
            try owned.append(alloc, mangled);
            try exports.append(alloc, .{ .name = mangled, .arity = st.params.len });
        },
        .method => |m| {
            if (m.body == null or m.is_declare) continue;
            if (!m.isPub and !(force_assoc and isAssocMethod(m))) continue;
            const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ s.name, m.name });
            try owned.append(alloc, mangled);
            try exports.append(alloc, .{ .name = mangled, .arity = methodArity(m) });
        },
    };
}

fn collectImplementExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    im: ast.ImplementDecl,
) !void {
    try collectExtensionExports(alloc, exports, owned, im.target, im.methods);
}

fn collectExtendExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    ex: ast.ExtendDecl,
) !void {
    try collectExtensionExports(alloc, exports, owned, ex.target, ex.methods);
}

/// Export every extension method as `'<qualifier>_<method>'/arity`. The
/// qualifier defaults to the target type (matching `emitImplementMethod`).
fn collectExtensionExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    target: []const u8,
    methods: []const ast.ImplementMethod,
) !void {
    for (methods) |m| {
        const qualifier = m.qualifier orelse target;
        const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ qualifier, m.name });
        try owned.append(alloc, mangled);
        try exports.append(alloc, .{ .name = mangled, .arity = implementMethodArity(m) });
    }
}

/// Number of y-slots a destructuring binding consumes — one per bound field
/// (record `{a, b}`) or tuple element (`#(a, b)`). Mirrors `emitDestructBind`.
fn destructYSlots(pattern: ast.ParamDestruct) u32 {
    return switch (pattern) {
        .names => |n| @intCast(n.fields.len),
        .tuple_ => |bindings| @intCast(bindings.len),
        else => 0,
    };
}

/// Number of y-slots a case-arm pattern binds — must match exactly what
/// `lowerCase` allocates via `next_y += 1`, so the function's `{allocate, N, _}`
/// frame is large enough for every binding (BEAM rejects a `{move, _, {y, k}}`
/// into an unallocated slot — `{invalid_store, {y, k}}`).
fn patternYSlots(p: ast.Pattern) u32 {
    return switch (p) {
        .wildcard, .numberLit, .stringLit, .@"or" => 0,
        .ident => |name| if (std.mem.eql(u8, name, "_")) 0 else 1,
        .variant => |v| switch (v.payload) {
            .binding => 1,
            .fields => |f| @intCast(f.len),
            .literals => 0,
        },
        .list => |lst| if (lst.spread) |s| (if (s.len > 0) @as(u32, 1) else 0) else 0,
        .multi => |pats| blk: {
            var n: u32 = 0;
            for (pats) |sp| switch (sp) {
                .ident => |nm| {
                    if (!std.mem.eql(u8, nm, "_")) n += 1;
                },
                else => {},
            };
            break :blk n;
        },
    };
}

/// Count every y-slot a function body consumes before any instruction is
/// emitted, so `{allocate, N, _}` covers them all. `next_y` is monotonic within
/// a frame, so this sums *all* bindings across every branch and nested
/// expression in the same frame: `val` bindings, destructures, and case-arm
/// pattern bindings. Lambda (`.function`) and loop bodies open their own frames
/// (the emitter saves/restores `next_y`), so their bindings are intentionally
/// not counted here.
fn countLocalsRec(body: []const ast.Stmt, count: *u32) void {
    for (body) |stmt| countLocalsInExpr(stmt.expr, count);
}

fn countLocalsInExpr(e: ast.Expr, count: *u32) void {
    switch (e) {
        .binding => |b| switch (b.kind) {
            .localBind => |lb| {
                count.* += 1;
                countLocalsInExpr(lb.value.*, count);
            },
            .localBindDestruct => |lb| {
                count.* += destructYSlots(lb.pattern);
                countLocalsInExpr(lb.value.*, count);
            },
            .assign => |a| countLocalsInExpr(a.value.*, count),
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                countLocalsInExpr(i.cond.*, count);
                countLocalsRec(i.then_, count);
                if (i.else_) |els| countLocalsRec(els, count);
            },
            .tryCatch => |tc| {
                countLocalsInExpr(tc.expr.*, count);
                countLocalsInExpr(tc.handler.*, count);
            },
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |v| countLocalsInExpr(v.*, count),
            .throw_ => |v| if (v) |vv| countLocalsInExpr(vv.*, count),
            .@"break" => |v| if (v) |vv| countLocalsInExpr(vv.*, count),
            .yield => |y| if (y.value) |v| countLocalsInExpr(v.*, count),
            .try_ => |v| if (v) |vv| countLocalsInExpr(vv.*, count),
            else => {},
        },
        .collection => |col| switch (col.kind) {
            .recordLit => |rl| for (rl.fields) |f| countLocalsInExpr(f.value.*, count),
            .grouped => |inner| countLocalsInExpr(inner.*, count),
            .case => |c| {
                for (c.subjects) |s| countLocalsInExpr(s, count);
                for (c.arms) |arm| {
                    count.* += patternYSlots(arm.pattern);
                    countLocalsInExpr(arm.body, count);
                }
            },
            .arrayLit => |al| {
                for (al.elems) |el| countLocalsInExpr(el, count);
                if (al.spreadExpr) |se| countLocalsInExpr(se.*, count);
            },
            .tupleLit => |tl| for (tl.elems) |el| countLocalsInExpr(el, count),
            .range => |r| {
                countLocalsInExpr(r.start.*, count);
                if (r.end) |end| countLocalsInExpr(end.*, count);
            },
        },
        .binaryOp => |bin| {
            countLocalsInExpr(bin.lhs.*, count);
            countLocalsInExpr(bin.rhs.*, count);
        },
        .unaryOp => |un| countLocalsInExpr(un.expr.*, count),
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.receiver) |r| countLocalsInExpr(r.*, count);
                for (cc.args) |arg| countLocalsInExpr(arg.value.*, count);
            },
            .pipeline => |pl| {
                countLocalsInExpr(pl.lhs.*, count);
                countLocalsInExpr(pl.rhs.*, count);
            },
        },
        .useHook => |uh| countLocalsInExpr(uh.kind.inner.*, count),
        // `.function` (lambda) and `.loop` open their own frames — their inner
        // bindings don't consume this frame's y-slots.
        else => {},
    }
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Cross-module link index — resolves an imported record's associated fn to
    // a remote `call_ext` into the owning module and an imported record literal
    // to the owner's map shape.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .typeError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const code = try emitBeamAsm(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, &cross);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── top-level emitter ────────────────────────────────────────────────────────

const ExportEntry = struct { name: []const u8, arity: usize };

fn emitBeamAsm(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    cross: ?*const CrossModule,
) ![]u8 {
    // Three passes:
    //   1. assign entry labels to every fn/top-val so wrappers can refer to
    //      them by `{f, N}`;
    //   2. emit each body into a buffer;
    //   3. emit the header (module + exports + attributes + labels) followed
    //      by the buffered bodies.
    //
    // The header needs the final label count, which is only known after
    // emitting; that's why bodies are buffered.

    var body_buf: std.Io.Writer.Allocating = .init(alloc);
    defer body_buf.deinit();

    // The BEAM module atom is the path basename (`std/order` → `order`,
    // `web/http` → `http`) — a slash is invalid in an unquoted module atom,
    // and cross-module `call_ext` targets resolve by basename (see
    // `crossModule.ownerModuleAtom`). Mirrors the Erlang backend's
    // `erl_module_name`.
    const module_atom = crossModule.moduleBasename(module_name);

    var em = Emitter.init(alloc, module_atom, &body_buf.writer, comptime_vals, rewrites);
    em.instance_lowerings = instance_lowerings;
    em.cross = cross;
    defer em.deinit();

    // Map each `implement`/`extend` block name to its target type + methods so
    // dispatch sites can resolve the mangled `'<target>_<method>'` callee.
    try em.collectExtensions(program);
    // Record/struct field orders (local + cross-imported) drive map construction
    // and cross-module associated-fn calls.
    try em.collectRecordShapes(program);
    // Interface associated `default fn`s (`Array.range`) resolve as local fns.
    try em.collectInterfaces(program);

    // Detect main/0 entrypoint (drives wrapper emission).
    var has_main_0 = false;
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (isMain0(f)) {
                has_main_0 = true;
            },
            else => {},
        }
    }

    // Pass 1: pre-assign labels (func_info, entry) for every emitted function
    // so wrappers and (eventually) local calls can resolve targets by name.
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| try em.reserveFn(f.name, fnArityNoSelf(f)),
            .val => |v| if (!has_main_0 and !isSyntheticEntrypointVal(v)) {
                try em.reserveFn(v.name, 0);
            },
            .record => |r| try em.reserveRecordMethods(r),
            .@"struct" => |s| try em.reserveStructMembers(s),
            .@"enum" => |e| try em.reserveEnumMethods(e),
            .interface => |i| try em.reserveInterfaceMethods(i),
            .implement => |im| try em.reserveImplementMethods(im),
            .extend => |ex| try em.reserveExtendMethods(ex),
            else => {},
        }
    }
    if (has_main_0) {
        try em.reserveFn("'_botopink_main'", 0);
        try em.reserveFn("main", 1);
    }

    // Collect exports: pub fns + entrypoint wrappers when main/0 exists.
    var exports: std.ArrayListUnmanaged(ExportEntry) = .empty;
    defer exports.deinit(alloc);
    // Mangled method names live in heap-allocated strings; track them so we
    // can free after the header is written.
    var owned_export_names: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (owned_export_names.items) |s| alloc.free(s);
        owned_export_names.deinit(alloc);
    }
    if (has_main_0) {
        try exports.append(alloc, .{ .name = "'_botopink_main'", .arity = 0 });
        try exports.append(alloc, .{ .name = "main", .arity = 1 });
    }
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (f.isPub) {
                try exports.append(alloc, .{ .name = f.name, .arity = fnArityNoSelf(f) });
            },
            .record => |r| try collectMethodExports(alloc, &exports, &owned_export_names, r.name, r.methods, isCrossImported(cross, r.name)),
            .@"struct" => |s| try collectStructExports(alloc, &exports, &owned_export_names, s, isCrossImported(cross, s.name)),
            .@"enum" => |e| try collectMethodExports(alloc, &exports, &owned_export_names, e.name, e.methods, isCrossImported(cross, e.name)),
            .implement => |im| try collectImplementExports(alloc, &exports, &owned_export_names, im),
            .extend => |ex| try collectExtendExports(alloc, &exports, &owned_export_names, ex),
            else => {},
        }
    }

    // Pass 2: emit each fn body into body_buf.
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| try em.emitFn(f),
            .val => |v| {
                if (!has_main_0 and !isSyntheticEntrypointVal(v)) {
                    try em.emitTopVal(v);
                }
            },
            .comment => |c| {
                const prefix = if (c.is_doc) "%%" else if (c.is_module) "%%%" else "%";
                try em.bodyPrint("{s} {s}\n", .{ prefix, c.text });
            },
            .record => |r| try em.emitRecord(r),
            .@"struct" => |s| try em.emitStruct(s),
            .@"enum" => |e| try em.emitEnum(e),
            // An interface's associated `default fn`s (`Array.range`, `Pair.of`)
            // are pure botopink — emit them as local mangled fns (`'Array_range'`).
            .interface => |i| try em.emitInterfaceAssoc(i),
            .implement => |im| try em.emitImplement(im),
            .extend => |ex| try em.emitExtend(ex),
            // Purely abstract decls (delegate), module-graph metadata (use), and
            // test blocks (only compiled under `botopink test`) don't lower to
            // runtime code — silently skip. `mod` declares a submodule in the
            // explicit tree; the submodule is compiled as its own unit.
            .delegate, .use, .mod, .@"test" => {},
        }
    }

    if (has_main_0) {
        try em.emitEntrypointWrappers();
    }

    // Now build the final output: header + exports + attributes + labels + body.
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();

    try aw.writer.print("{{module, {s}}}.\n", .{module_atom});

    try aw.writer.writeAll("{exports, [");
    for (exports.items, 0..) |e, i| {
        if (i > 0) try aw.writer.writeAll(", ");
        var ename_buf: [256]u8 = undefined;
        try aw.writer.print("{{{s}, {d}}}", .{ try atomName(e.name, &ename_buf), e.arity });
    }
    try aw.writer.writeAll("]}.\n");
    try aw.writer.writeAll("{attributes, []}.\n");
    try aw.writer.print("{{labels, {d}}}.\n", .{em.next_label});

    try aw.writer.writeAll(body_buf.written());
    for (em.deferred_lambdas.items) |lambda_code| {
        try aw.writer.writeAll(lambda_code);
    }

    return aw.toOwnedSlice();
}

// ── Emitter ──────────────────────────────────────────────────────────────────

const FnLabels = struct {
    func_info: u32,
    entry: u32,
};

/// A BEAM register reference: x-registers (caller-saved, clobbered by calls)
/// or y-registers (stack-frame locals, preserved across calls).
const Reg = union(enum) {
    x: u32,
    y: u32,

    fn format(self: Reg, buf: []u8) ![]const u8 {
        return switch (self) {
            .x => |n| std.fmt.bufPrint(buf, "{{x, {d}}}", .{n}),
            .y => |n| std.fmt.bufPrint(buf, "{{y, {d}}}", .{n}),
        };
    }
};

fn fnKey(alloc: std.mem.Allocator, name: []const u8, arity: usize) ![]u8 {
    return std.fmt.allocPrint(alloc, "{s}/{d}", .{ name, arity });
}

const Emitter = struct {
    alloc: std.mem.Allocator,
    module_name: []const u8,
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),

    /// Next available label index. Label 1 is reserved (BEAM convention).
    next_label: u32 = 2,

    /// `"name/arity"` → reserved label pair. Populated by `reserveFn` in pass 1.
    fn_labels: std.StringHashMap(FnLabels),

    /// Per-function: name → register (x for params, y for locals).
    reg_map: std.StringHashMap(Reg),
    /// Per-function: next y-slot available for a new local.
    next_y: u32 = 0,
    /// Per-function: total y-slots reserved (set by `precountLocals`).
    num_y: u32 = 0,
    /// Per-function: arity in x-registers (live registers floor for gc_bif).
    cur_arity: u32 = 0,
    /// Live-register floor for `make_fun3`'s `test_heap`: raised while a scratch
    /// x-register holds a value that must survive an inline closure allocation
    /// (e.g. the stashed `@Result` payload in `lowerResultOptionOp`).
    min_live: u32 = 0,
    /// Per-function: bumps the source-location placeholder.
    cur_line: u32 = 1,
    /// Module-wide lambda counter for generating unique fun names.
    lambda_count: u32 = 0,
    /// Current function name — used for lambda naming (`-fn/N-fun-K-`).
    cur_fn_name: []const u8 = "",
    /// Deferred lambda bodies — emitted after main pass 2.
    deferred_lambdas: std.ArrayListUnmanaged([]u8) = .empty,
    /// True when emitting a loop body lambda — makes break emit return.
    in_loop_lambda: bool = false,
    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Primitive (Array/String/Bool/numeric) receiver method lowering, keyed by
    /// call-site loc. A `.prim` entry routes `recv.m(args)` to a host op
    /// (`lists:map`, `string:uppercase`, …) — parity with the erlang backend's
    /// `emitPrimMethod`. Populated by inference; empty in the standalone path.
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering) = undefined,
    /// Extension block name → target type + methods, for resolving the mangled
    /// `'<target>_<method>'` callee at activated and qualified dispatch sites.
    ext_by_name: std.StringHashMap(ExtInfo),
    /// Cross-module link index (null in the standalone path).
    cross: ?*const CrossModule = null,
    /// Record/struct name → ordered field names (local decls + cross-imported).
    /// Drives `App(8080, "/")` → a `put_map_assoc` map keyed by field name.
    record_fields: std.StringHashMap([]const []const u8),
    /// Imported record/struct name → owning module atom. A qualified call whose
    /// receiver names one (`Response.ok(...)`) lowers to a remote `call_ext`
    /// into the owner (`http:'Response_ok'(...)`).
    imported_types: std.StringHashMap([]const u8),
    /// Interface associated `default fn` qualified names (`"Array.range"`). Pure
    /// botopink, emitted as local mangled fns (`'Array_range'`) since the
    /// interface decl is inlined into each consuming module; an
    /// `Interface.method(...)` call resolves to that local fn, not a remote
    /// `array:range`. Populated by `collectInterfaces`.
    interface_assoc: std.StringHashMap(void),

    /// Target type and methods of an `implement`/`extend` block.
    const ExtInfo = struct { target: []const u8, methods: []const ast.ImplementMethod };

    fn init(alloc: std.mem.Allocator, module_name: []const u8, out: *std.Io.Writer, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        return .{
            .alloc = alloc,
            .module_name = module_name,
            .out = out,
            .cv = cv,
            .fn_labels = std.StringHashMap(FnLabels).init(alloc),
            .reg_map = std.StringHashMap(Reg).init(alloc),
            .rewrites = rewrites,
            .ext_by_name = std.StringHashMap(ExtInfo).init(alloc),
            .record_fields = std.StringHashMap([]const []const u8).init(alloc),
            .imported_types = std.StringHashMap([]const u8).init(alloc),
            .interface_assoc = std.StringHashMap(void).init(alloc),
        };
    }

    fn deinit(self: *Emitter) void {
        var it = self.fn_labels.iterator();
        while (it.next()) |kv| self.alloc.free(kv.key_ptr.*);
        self.fn_labels.deinit();
        self.reg_map.deinit();
        for (self.deferred_lambdas.items) |s| self.alloc.free(s);
        self.deferred_lambdas.deinit(self.alloc);
        self.ext_by_name.deinit();
        var rf = self.record_fields.valueIterator();
        while (rf.next()) |names| self.alloc.free(names.*);
        self.record_fields.deinit();
        self.imported_types.deinit();
        var ia = self.interface_assoc.keyIterator();
        while (ia.next()) |k| self.alloc.free(k.*);
        self.interface_assoc.deinit();
    }

    /// Index interface associated `default fn`s (no `self`, with a body) by their
    /// qualified name (`"Array.range"`) so an `Interface.method(...)` call lowers
    /// to the local mangled fn `'Interface_method'` that `emitInterfaceAssoc`
    /// emits — parity with the erlang backend.
    fn collectInterfaces(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .interface => |i| {
                for (i.methods) |m| {
                    if (!m.is_default or m.body == null or !isAssocMethod(m)) continue;
                    const qn = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ i.name, m.name });
                    try self.interface_assoc.put(qn, {});
                }
            },
            else => {},
        };
    }

    fn isInterfaceAssoc(self: *Emitter, iface: []const u8, method: []const u8) bool {
        var b: [256]u8 = undefined;
        const qn = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface, method }) catch return false;
        return self.interface_assoc.contains(qn);
    }

    /// Reserve labels for an interface's associated `default fn`s (pass 1).
    fn reserveInterfaceMethods(self: *Emitter, i: ast.InterfaceDecl) !void {
        for (i.methods) |m| {
            if (!m.is_default or m.body == null or !isAssocMethod(m)) continue;
            try self.reserveMethod(i.name, m.name, methodArity(m));
        }
    }

    /// Emit an interface's associated `default fn`s as local mangled fns (pass 2).
    fn emitInterfaceAssoc(self: *Emitter, i: ast.InterfaceDecl) !void {
        for (i.methods) |m| {
            if (!m.is_default or m.body == null or !isAssocMethod(m)) continue;
            try self.emitMethodAsFn(i.name, m);
        }
    }

    fn collectExtensions(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .implement => |im| try self.ext_by_name.put(im.name, .{ .target = im.target, .methods = im.methods }),
            .extend => |ex| try self.ext_by_name.put(ex.name, .{ .target = ex.target, .methods = ex.methods }),
            else => {},
        };
    }

    /// Registers ordered field names for every local record/struct, plus every
    /// record/struct this module imports `from "<pkg>"` (resolved via the cross
    /// index). Imported types also record their owning module atom so an
    /// associated-fn call can `call_ext` into it.
    fn collectRecordShapes(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .record => |r| {
                const fields = try self.alloc.alloc([]const u8, r.fields.len);
                for (r.fields, 0..) |f, i| fields[i] = f.name;
                try self.record_fields.put(r.name, fields);
            },
            .@"struct" => |s| {
                var count: usize = 0;
                for (s.members) |m| {
                    if (m == .field) count += 1;
                }
                const fields = try self.alloc.alloc([]const u8, count);
                var i: usize = 0;
                for (s.members) |m| switch (m) {
                    .field => |f| {
                        fields[i] = f.name;
                        i += 1;
                    },
                    else => {},
                };
                try self.record_fields.put(s.name, fields);
            },
            else => {},
        };
        const xc = self.cross orelse return;
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const name = imp.name();
                const info = xc.exports.get(name) orelse continue;
                switch (info.kind) {
                    .record, .@"struct" => {
                        if (!self.record_fields.contains(name)) {
                            const fields = try self.alloc.dupe([]const u8, info.fields);
                            try self.record_fields.put(name, fields);
                        }
                        try self.imported_types.put(name, crossModule.moduleBasename(info.module));
                    },
                    else => {},
                }
            },
            else => {},
        };
    }

    /// Mangled `'<qualifier>_<method>'` name for a dispatch site, written into
    /// `buf`. `sym` is the extension block name from `rewrites`/the receiver;
    /// the qualifier defaults to the target type (matching `emitImplementMethod`).
    fn extMangledName(self: *Emitter, buf: []u8, sym: []const u8, method: []const u8) ?[]const u8 {
        const info = self.ext_by_name.get(sym) orelse return null;
        var qualifier = info.target;
        for (info.methods) |m| {
            if (std.mem.eql(u8, m.name, method)) {
                qualifier = m.qualifier orelse info.target;
                break;
            }
        }
        return std.fmt.bufPrint(buf, "'{s}_{s}'", .{ qualifier, method }) catch null;
    }

    fn allocLabel(self: *Emitter) u32 {
        const l = self.next_label;
        self.next_label += 1;
        return l;
    }

    fn reserveFn(self: *Emitter, name: []const u8, arity: usize) !void {
        const key = try fnKey(self.alloc, name, arity);
        try self.fn_labels.put(key, .{
            .func_info = self.allocLabel(),
            .entry = self.allocLabel(),
        });
    }

    fn fnLabelsFor(self: *Emitter, name: []const u8, arity: usize) !FnLabels {
        var buf: [256]u8 = undefined;
        const key = try std.fmt.bufPrint(&buf, "{s}/{d}", .{ name, arity });
        return self.fn_labels.get(key) orelse error.UnknownFunction;
    }

    fn bodyPrint(self: *Emitter, comptime fmt: []const u8, args: anytype) !void {
        try self.out.print(fmt, args);
    }

    fn bodyWrite(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }

    // ── per-fn state ─────────────────────────────────────────────────────────

    fn resetFnState(self: *Emitter, arity: u32) void {
        self.reg_map.clearRetainingCapacity();
        self.next_y = 0;
        self.num_y = 0;
        self.cur_arity = arity;
    }

    /// Count the y-slots needed for a function body: one slot per `localBind`.
    /// Conservative: every `val` gets a slot even when its lifetime ends
    /// before a call. Refining this is Fase 9 (polish).
    fn precountLocals(_: *Emitter, body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        countLocalsRec(body, &n);
        return n;
    }

    // ── fn ───────────────────────────────────────────────────────────────────

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        const arity = fnArityNoSelf(f);
        const labels = try self.fnLabelsFor(f.name, arity);
        const func_info_label = labels.func_info;
        const entry_label = labels.entry;

        self.resetFnState(@intCast(arity));
        self.cur_fn_name = f.name;
        self.num_y = self.precountLocals(f.body);

        // Bind params to x0..x{arity-1}.
        var x: u32 = 0;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. The BEAM model is processes +
        // message passing (spawn/receive); this backend currently emits the
        // eager body, with full process-based lowering left as future work.
        if (f.effect != null and f.effect.? != .result) {
            try self.bodyWrite("%% *fn (async/generator) — eager lowering\n");
        }
        var fn_buf: [256]u8 = undefined;
        const fn_atom = try atomName(f.name, &fn_buf);
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ fn_atom, arity, entry_label });
        try self.bodyPrint("  {{label, {d}}}.\n", .{func_info_label});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, fn_atom, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{entry_label});

        try self.emitFrame(arity);

        self.cur_line += 1;
        try self.emitBody(f.body);
    }

    // ── record / struct / enum / implement ───────────────────────────────────
    //
    // The declaration itself never emits standalone runtime code — the
    // constructor / field-access lowering belongs in Fase 4. What we do here
    // is reify every method (`fn`, `get`, `set`) with a body as a
    // module-level function named `'Owner_methodName'/arity`. Methods that
    // have no body (`declare fn ...`) are silently skipped.

    fn reserveMethod(self: *Emitter, owner: []const u8, suffix: []const u8, arity: usize) !void {
        var buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&buf, "'{s}_{s}'", .{ owner, suffix });
        try self.reserveFn(mangled, arity);
    }

    fn reserveRecordMethods(self: *Emitter, r: ast.RecordDecl) !void {
        for (r.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.reserveMethod(r.name, m.name, methodArity(m));
        }
    }

    fn reserveStructMembers(self: *Emitter, s: ast.StructDecl) !void {
        for (s.members) |mem| switch (mem) {
            .field => {},
            .getter => |g| try self.reserveMethod(s.name, g.name, 1),
            .setter => |st| {
                // Setters have explicit params; arity == params.len.
                try self.reserveMethod(s.name, st.name, st.params.len);
            },
            .method => |m| {
                if (m.body == null or m.is_declare) continue;
                try self.reserveMethod(s.name, m.name, methodArity(m));
            },
        };
    }

    fn reserveEnumMethods(self: *Emitter, e: ast.EnumDecl) !void {
        for (e.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.reserveMethod(e.name, m.name, methodArity(m));
        }
    }

    fn reserveImplementMethods(self: *Emitter, im: ast.ImplementDecl) !void {
        try self.reserveExtensionMethods(im.target, im.methods);
    }

    fn reserveExtendMethods(self: *Emitter, ex: ast.ExtendDecl) !void {
        try self.reserveExtensionMethods(ex.target, ex.methods);
    }

    fn reserveExtensionMethods(self: *Emitter, target: []const u8, methods: []const ast.ImplementMethod) !void {
        for (methods) |m| {
            const qualifier = m.qualifier orelse target;
            var buf: [256]u8 = undefined;
            const mangled = try std.fmt.bufPrint(&buf, "'{s}_{s}'", .{ qualifier, m.name });
            try self.reserveFn(mangled, implementMethodArity(m));
        }
    }

    fn emitRecord(self: *Emitter, r: ast.RecordDecl) !void {
        for (r.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.emitMethodAsFn(r.name, m);
        }
    }

    fn emitStruct(self: *Emitter, s: ast.StructDecl) !void {
        for (s.members) |mem| switch (mem) {
            .field => {},
            .getter => |g| try self.emitGetter(s.name, g),
            .setter => |st| try self.emitSetter(s.name, st),
            .method => |m| {
                if (m.body == null or m.is_declare) continue;
                try self.emitMethodAsFn(s.name, m);
            },
        };
    }

    fn emitEnum(self: *Emitter, e: ast.EnumDecl) !void {
        for (e.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.emitMethodAsFn(e.name, m);
        }
    }

    fn emitImplement(self: *Emitter, im: ast.ImplementDecl) !void {
        for (im.methods) |m| {
            const qualifier = m.qualifier orelse im.target;
            try self.emitImplementMethod(qualifier, m);
        }
    }

    fn emitExtend(self: *Emitter, ex: ast.ExtendDecl) !void {
        for (ex.methods) |m| {
            const qualifier = m.qualifier orelse ex.target;
            try self.emitImplementMethod(qualifier, m);
        }
    }

    fn emitMethodAsFn(self: *Emitter, owner: []const u8, m: ast.InterfaceMethod) !void {
        const arity = methodArity(m);
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, m.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        self.num_y = self.precountLocals(m.body.?);

        var x: u32 = 0;
        for (m.params) |p| {
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ mangled, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, mangled, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});

        try self.emitFrame(arity);

        self.cur_line += 1;
        try self.emitBody(m.body.?);
    }

    fn emitImplementMethod(self: *Emitter, qualifier: []const u8, m: ast.ImplementMethod) !void {
        const arity = implementMethodArity(m);
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ qualifier, m.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        self.num_y = self.precountLocals(m.body);

        var x: u32 = 0;
        for (m.params) |p| {
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ mangled, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, mangled, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});

        try self.emitFrame(arity);

        self.cur_line += 1;
        try self.emitBody(m.body);
    }

    /// `get fieldName(self: Self) -> T { ... }` — lowered as `'Owner_fieldName'/1`.
    /// Implementations vary (custom body vs. plain field read); we emit the
    /// method body as written. Plain field-access semantics arrive in Fase 4.
    fn emitGetter(self: *Emitter, owner: []const u8, g: anytype) !void {
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, g.name });
        const labels = try self.fnLabelsFor(mangled, 1);

        self.resetFnState(1);
        self.num_y = self.precountLocals(g.body);
        try self.reg_map.put(g.selfParam.name, .{ .x = 0 });

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, 1, {d}}}.\n", .{ mangled, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, 1}}.\n", .{ self.module_name, mangled });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.emitFrame(1);
        self.cur_line += 1;
        try self.emitBody(g.body);
    }

    fn emitSetter(self: *Emitter, owner: []const u8, s: anytype) !void {
        const arity = s.params.len;
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, s.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        self.num_y = self.precountLocals(s.body);
        var x: u32 = 0;
        for (s.params) |p| {
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ mangled, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, mangled, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.emitFrame(arity);
        self.cur_line += 1;
        try self.emitBody(s.body);
    }

    // ── top-level val (only when there's no fn main/0) ───────────────────────
    //
    // Erlang backend emits these as 0-arity functions. We mirror that — `val
    // pi = 3.14` becomes `pi/0` returning the literal. Only literal/numeric
    // expressions are supported in Fase 1; richer values fall to Fase 2+.

    fn emitTopVal(self: *Emitter, v: ast.ValDecl) !void {
        const labels = try self.fnLabelsFor(v.name, 0);
        const func_info_label = labels.func_info;
        const entry_label = labels.entry;

        self.resetFnState(0);

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, 0, {d}}}.\n", .{ v.name, entry_label });
        try self.bodyPrint("  {{label, {d}}}.\n", .{func_info_label});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, 0}}.\n", .{ self.module_name, v.name });
        try self.bodyPrint("  {{label, {d}}}.\n", .{entry_label});
        self.cur_line += 1;

        try self.lowerExprIntoX0(v.value.*);
        try self.emitReturn();
    }

    /// Emit `return.`, preceded by `{deallocate, N}.` when the current function
    /// owns a y-stack frame.
    fn emitReturn(self: *Emitter) !void {
        try self.bodyPrint("    {{deallocate, {d}}}.\n", .{self.num_y});
        try self.bodyWrite("    return.\n");
    }

    /// Emit the function-prologue `{allocate, NumY, Arity}` for the current
    /// frame, followed by `{init_yregs, …}` nilling every y-slot when the frame
    /// has any. BEAM requires each allocated y-slot to hold a valid term before
    /// the next GC point (a call or `gc_bif`); a slot written only on a later
    /// branch would otherwise be flagged `{uninitialized_reg, {y, k}}` by the
    /// loader. (`allocate_zero` was the old shorthand for this but no longer
    /// assembles on current OTP.)
    fn emitFrame(self: *Emitter, arity: usize) !void {
        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });
        if (self.num_y > 0) {
            try self.bodyWrite("    {init_yregs, {list, [");
            var k: u32 = 0;
            while (k < self.num_y) : (k += 1) {
                if (k > 0) try self.bodyWrite(", ");
                try self.bodyPrint("{{y, {d}}}", .{k});
            }
            try self.bodyWrite("]}}.\n");
        }
    }

    // ── entrypoint wrappers when main/0 exists ───────────────────────────────

    fn emitEntrypointWrappers(self: *Emitter) !void {
        const wrapper = try self.fnLabelsFor("'_botopink_main'", 0);
        const main1 = try self.fnLabelsFor("main", 1);
        const main0 = try self.fnLabelsFor("main", 0);

        // '_botopink_main'/0 → tail-calls main/0.
        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, '_botopink_main', 0, {d}}}.\n", .{wrapper.entry});
        try self.bodyPrint("  {{label, {d}}}.\n", .{wrapper.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, '_botopink_main'}}, 0}}.\n", .{self.module_name});
        try self.bodyPrint("  {{label, {d}}}.\n", .{wrapper.entry});
        try self.bodyPrint("    {{call_only, 0, {{f, {d}}}}}.\n", .{main0.entry});
        self.cur_line += 1;

        // main/1 → discards argv and tail-calls _botopink_main/0.
        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, main, 1, {d}}}.\n", .{main1.entry});
        try self.bodyPrint("  {{label, {d}}}.\n", .{main1.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, main}}, 1}}.\n", .{self.module_name});
        try self.bodyPrint("  {{label, {d}}}.\n", .{main1.entry});
        try self.bodyPrint("    {{call_only, 0, {{f, {d}}}}}.\n", .{wrapper.entry});
        self.cur_line += 1;
    }

    // ── body ─────────────────────────────────────────────────────────────────

    fn emitBody(self: *Emitter, body: []const ast.Stmt) !void {
        for (body) |stmt| {
            try self.emitStmt(stmt);
        }
        // BEAM functions must end with an exit instruction. When the source
        // didn't write an explicit `return`, fall back to returning the atom
        // `ok` so the frame is balanced (deallocate + return).
        if (!bodyExits(body)) {
            try self.bodyWrite("    {move, {atom, ok}, {x, 0}}.\n");
            try self.emitReturn();
        }
    }

    fn emitStmt(self: *Emitter, stmt: ast.Stmt) anyerror!void {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| {
                        // Tail-call detection: `return call(...)` becomes
                        // `{call_last, ...}` / `{call_only, ...}`, which encode
                        // deallocate + return atomically.
                        switch (val.*) {
                            .call => |c| switch (c.kind) {
                                .call => |cc| {
                                    try self.lowerCall(cc, .tail, c.loc);
                                    return;
                                },
                                else => {},
                            },
                            else => {},
                        }
                        try self.lowerExprIntoX0(val.*);
                    }
                    try self.emitReturn();
                },
                .throw_ => |val| {
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                    } else {
                        try self.bodyWrite("    {move, {atom, undef}, {x, 0}}.\n");
                    }
                    try self.bodyWrite("    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.\n");
                },
                .@"break" => |val| {
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                    }
                    if (self.in_loop_lambda) try self.emitReturn();
                },
                .yield => |y| {
                    if (y.value) |v| {
                        try self.lowerExprIntoX0(v.*);
                    }
                    try self.emitReturn();
                },
                .@"continue" => {
                    try self.bodyWrite("    {move, {atom, ok}, {x, 0}}.\n");
                    try self.emitReturn();
                },
                else => |k| try self.bodyPrint("    %% unsupported jump: {s}\n", .{@tagName(k)}),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| try self.emitIf(i),
                .tryCatch => |tc| try self.lowerTryCatch(tc),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| try self.emitLocalBind(lb.name, lb.value.*),
                .assign => |a| try self.emitAssign(a),
                .localBindDestruct => |lb| try self.emitDestructBind(lb.pattern, lb.value.*),
            },
            else => {
                try self.lowerExprIntoX0(stmt.expr);
            },
        }
    }

    /// Lower a destructuring binding (`{a, b} = expr` / `#(a, b) = expr`):
    /// evaluate `value` into `{x, 0}`, then bind each field into a y-slot.
    fn emitDestructBind(self: *Emitter, pattern: ast.ParamDestruct, value: ast.Expr) anyerror!void {
        try self.lowerExprIntoX0(value);
        switch (pattern) {
            .names => |n| {
                for (n.fields) |fld| {
                    const scratch = self.cur_arity;
                    try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                    const fail = self.allocLabel();
                    try self.bodyPrint(
                        "    {{get_map_elements, {{f, {d}}}, {{x, {d}}}, {{list, [{{atom, {s}}}, {{x, 0}}]}}}}.\n",
                        .{ fail, scratch, fld.field_name },
                    );
                    try self.bodyPrint("  {{label, {d}}}.\n", .{fail});
                    const y_idx = self.next_y;
                    self.next_y += 1;
                    try self.reg_map.put(fld.bind_name, .{ .y = y_idx });
                    try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                    try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
                }
            },
            .tuple_ => |bindings| {
                for (bindings, 0..) |name, i| {
                    try self.bodyPrint(
                        "    {{get_tuple_element, {{x, 0}}, {d}, {{x, 1}}}}.\n",
                        .{i},
                    );
                    const y_idx = self.next_y;
                    self.next_y += 1;
                    try self.reg_map.put(name, .{ .y = y_idx });
                    try self.bodyPrint("    {{move, {{x, 1}}, {{y, {d}}}}}.\n", .{y_idx});
                }
            },
            else => try self.bodyWrite("    %% unsupported destructure pattern\n"),
        }
    }

    /// Lower `val name = value`: evaluate `value` into `{x, 0}`, then move it
    /// to a freshly-allocated y-slot. The y-slot count was pre-reserved by
    /// `precountLocals` so the `{allocate, NumY, _}` at the top of the
    /// function already covers it.
    fn emitLocalBind(self: *Emitter, name: []const u8, value: ast.Expr) !void {
        try self.lowerExprIntoX0(value);
        const y_idx = self.next_y;
        self.next_y += 1;
        try self.reg_map.put(name, .{ .y = y_idx });
        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
    }

    /// `name = expr` or `name += expr`: evaluate the new value and store
    /// back into the variable's y-slot.
    fn emitAssign(self: *Emitter, a: anytype) anyerror!void {
        switch (a.target) {
            .name => |name| {
                const reg = self.reg_map.get(name) orelse {
                    try self.bodyPrint("    %% assign to unknown variable: {s}\n", .{name});
                    return;
                };
                switch (a.op) {
                    .assign => {
                        try self.lowerExprIntoX0(a.value.*);
                        var buf: [64]u8 = undefined;
                        const term = try reg.format(&buf);
                        try self.bodyPrint("    {{move, {{x, 0}}, {s}}}.\n", .{term});
                    },
                    .plusAssign => {
                        var reg_buf: [64]u8 = undefined;
                        const reg_term = try reg.format(&reg_buf);
                        try self.lowerExprIntoX0(a.value.*);
                        const scratch = self.cur_arity;
                        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                        try self.bodyPrint(
                            "    {{gc_bif, '+', {{f, 0}}, {d}, [{s}, {{x, {d}}}], {{x, 0}}}}.\n",
                            .{ scratch + 1, reg_term, scratch },
                        );
                        try self.bodyPrint("    {{move, {{x, 0}}, {s}}}.\n", .{reg_term});
                    },
                }
            },
            .fieldAccess => |*fa| {
                try self.lowerExprIntoX0(a.value.*);
                const scratch = self.cur_arity;
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                try self.lowerExprIntoX0(fa.receiver.*);
                try self.bodyPrint(
                    "    {{put_map_exact, {{f, 0}}, {{x, 0}}, {{x, 0}}, {d}, {{list, [{{atom, {s}}}, {{x, {d}}}]}}}}.\n",
                    .{ scratch + 1, fa.field, scratch },
                );
                if (self.reg_map.get("self")) |reg| {
                    var buf: [64]u8 = undefined;
                    const term = try reg.format(&buf);
                    try self.bodyPrint("    {{move, {{x, 0}}, {s}}}.\n", .{term});
                }
            },
        }
    }

    // ── if (cmp) { then } else { else } ──────────────────────────────────────
    //
    // Only handles cond = binaryOp comparison between two simple operands
    // (literal/identifier). Anything else → `%% unsupported`.

    fn emitIf(self: *Emitter, i: anytype) anyerror!void {
        const else_label = self.allocLabel();

        const lowered = try self.lowerComparisonAsTest(i.cond.*, else_label);
        if (!lowered) {
            try self.lowerExprIntoX0(i.cond.*);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{else_label});
        }

        // then branch (cond true).
        for (i.then_) |s| try self.emitStmt(s);
        const then_returns = i.then_.len > 0 and stmtIsReturn(i.then_[i.then_.len - 1]);

        // Skip the unconditional jump-to-end when the then branch already
        // exits via `return.` — otherwise BEAM will see unreachable code.
        const end_label: ?u32 = if (!then_returns) self.allocLabel() else null;
        if (end_label) |el| try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{el});

        // else branch.
        try self.bodyPrint("  {{label, {d}}}.\n", .{else_label});
        if (i.else_) |els| {
            for (els) |s| try self.emitStmt(s);
        }
        // A bare `if` with no else is a *statement*: when the condition is
        // false, control must fall through to whatever follows (the next
        // statement, or the trailing `return.` `emitBody` appends because
        // `bodyExits` is false for an else-less if). Emitting `move undefined`
        // + `return.` here would end the function early and turn every
        // following statement — e.g. the `return isOdd(n - 1)` tail of a
        // mutually-recursive base-case guard — into unreachable dead code.

        if (end_label) |el| try self.bodyPrint("  {{label, {d}}}.\n", .{el});
    }

    /// Lower `lhs <op> rhs` (a comparison) as a `{test, is_<op>, {f, F}, [A, B]}.`
    /// instruction whose failure target is `fail_label`. Returns false if the
    /// expression is not a recognised comparison.
    fn lowerComparisonAsTest(self: *Emitter, cond: ast.Expr, fail_label: u32) anyerror!bool {
        switch (cond) {
            .binaryOp => |bin| {
                const cmp = comparisonTestOp(bin.op) orelse return false;

                var lhs_buf: [64]u8 = undefined;
                var rhs_buf: [64]u8 = undefined;
                const lhs_simple = try self.simpleTerm(bin.lhs.*, &lhs_buf);
                const rhs_simple = try self.simpleTerm(bin.rhs.*, &rhs_buf);

                var lhs_final: []const u8 = undefined;
                var rhs_final: []const u8 = undefined;
                var lhs_final_buf: [64]u8 = undefined;
                var rhs_final_buf: [64]u8 = undefined;

                if (lhs_simple != null and rhs_simple != null) {
                    lhs_final = lhs_simple.?;
                    rhs_final = rhs_simple.?;
                } else {
                    const scratch = self.cur_arity;
                    if (lhs_simple) |ls| {
                        try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ ls, scratch });
                    } else {
                        try self.lowerExprIntoX0(bin.lhs.*);
                        if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                    }
                    lhs_final = try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});
                    if (rhs_simple) |rs| {
                        rhs_final = rs;
                    } else {
                        try self.lowerExprIntoX0(bin.rhs.*);
                        rhs_final = try std.fmt.bufPrint(&rhs_final_buf, "{{x, 0}}", .{});
                    }
                }

                const a = if (cmp.swap) rhs_final else lhs_final;
                const b = if (cmp.swap) lhs_final else rhs_final;
                try self.bodyPrint(
                    "    {{test, {s}, {{f, {d}}}, [{s}, {s}]}}.\n",
                    .{ cmp.opcode, fail_label, a, b },
                );
                return true;
            },
            else => return false,
        }
    }

    // ── lowering helpers ─────────────────────────────────────────────────────

    /// Lower `e` so its value lives in `{x, 0}`, ready for `return.`.
    fn lowerExprIntoX0(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            // `use` is a transparent prefix: lower the wrapped hook call. The
            // enclosing `val` moves the result into its y-slot.
            .useHook => |uh| return self.lowerExprIntoX0(uh.kind.inner.*),
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.reg_map.get(n)) |reg| {
                        switch (reg) {
                            .x => |xn| {
                                if (xn == 0) return;
                                try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{xn});
                            },
                            .y => |yn| {
                                try self.bodyPrint("    {{move, {{y, {d}}}, {{x, 0}}}}.\n", .{yn});
                            },
                        }
                        return;
                    }
                    if (self.cv.get(n)) |val| {
                        try self.bodyPrint("    {{move, {{atom, '{s}'}}, {{x, 0}}}}.\n", .{val});
                        return;
                    }
                    var nbuf: [256]u8 = undefined;
                    try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{try atomName(n, &nbuf)});
                    return;
                },
                .dotIdent => |d| {
                    var dbuf: [256]u8 = undefined;
                    try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{try atomName(d, &dbuf)});
                    return;
                },
                .identAccess => |ia| {
                    try self.lowerIdentAccess(ia, 0);
                    return;
                },
            },
            .literal => |lit| switch (lit.kind) {
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .numberLit => |n| {
                    var buf: [64]u8 = undefined;
                    const term = try formatNumberInto(&buf, n);
                    try self.bodyPrint("    {{move, {s}, {{x, 0}}}}.\n", .{term});
                    return;
                },
                .null_ => {
                    try self.bodyWrite("    {move, {atom, nil}, {x, 0}}.\n");
                    return;
                },
                .stringLit => |s| {
                    try self.emitStringLiteral(s, 0);
                    return;
                },
                .comment => return,
            },
            .binaryOp => {
                try self.lowerArith(e, 0);
                return;
            },
            .unaryOp => |un| switch (un.op) {
                .neg => {
                    try self.lowerNeg(un.expr.*, 0);
                    return;
                },
                .not => {
                    try self.lowerNot(un.expr.*, 0);
                    return;
                },
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    try self.lowerCall(cc, .non_tail, c.loc);
                    return;
                },
                .pipeline => |pl| {
                    try self.lowerPipeline(pl);
                    return;
                },
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    try self.emitValueIf(i);
                    return;
                },
                .tryCatch => |tc| {
                    try self.lowerTryCatch(tc);
                    return;
                },
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| {
                    try self.lowerExprIntoX0(inner.*);
                    return;
                },
                .arrayLit => |al| {
                    try self.lowerArrayLit(al);
                    return;
                },
                .tupleLit => |tl| {
                    try self.lowerTupleLit(tl);
                    return;
                },
                // Anonymous record literals are a deferred BEAM gap (named
                // records lower to put_map_assoc maps; same treatment applies).
                .recordLit => {
                    try self.bodyWrite("    %% unsupported: record literal\n");
                    try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
                    return;
                },
                .case => |c| {
                    try self.lowerCase(c.subjects, c.arms);
                    return;
                },
                .range => |r| {
                    try self.lowerRange(r);
                    return;
                },
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExprIntoX0(val.*);
                    try self.emitReturn();
                    return;
                },
                .throw_ => |val| {
                    if (val) |v| try self.lowerExprIntoX0(v.*);
                    try self.bodyWrite("    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.\n");
                    return;
                },
                .try_ => |val| {
                    // `try expr` (no catch): unwrap `{ok, V}`, or early-return the
                    // `{error, E}` tuple to propagate it up.
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                        const err_label = self.allocLabel();
                        const cont_label = self.allocLabel();
                        try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, [{{x, 0}}, 2, {{atom, ok}}]}}.\n", .{err_label});
                        try self.bodyWrite("    {get_tuple_element, {x, 0}, 1, {x, 0}}.\n");
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{cont_label});
                        try self.bodyPrint("  {{label, {d}}}.\n", .{err_label});
                        try self.emitReturn();
                        try self.bodyPrint("  {{label, {d}}}.\n", .{cont_label});
                    }
                    return;
                },
                else => {},
            },
            .comptime_ => {
                try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
                return;
            },
            .function => |f| switch (f.kind.syntax) {
                .lambda => {
                    try self.lowerLambda(f.kind, self.cur_arity);
                    return;
                },
                .fnExpr => {
                    try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
                    return;
                },
            },
            .loop => |lp| {
                try self.lowerLoop(lp);
                return;
            },
            else => {},
        }

        try self.bodyPrint("    %% unsupported expr in tail position: {s}\n", .{@tagName(e)});
        try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
    }

    /// Lower `-e` into `{x, dest}`. Constant-folds literal numerics.
    fn lowerNeg(self: *Emitter, inner: ast.Expr, dest: u32) !void {
        switch (inner) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    var buf: [64]u8 = undefined;
                    const term = try formatNegNumberInto(&buf, n);
                    try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ term, dest });
                    return;
                },
                else => {},
            },
            else => {},
        }
        var ibuf: [64]u8 = undefined;
        const inner_term = try self.simpleTerm(inner, &ibuf);
        if (inner_term) |it| {
            try self.bodyPrint(
                "    {{gc_bif, '-', {{f, 0}}, {d}, [{{integer, 0}}, {s}], {{x, {d}}}}}.\n",
                .{ self.cur_arity, it, dest },
            );
        } else {
            try self.lowerExprIntoX0(inner);
            const scratch = self.cur_arity;
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            var scratch_buf: [64]u8 = undefined;
            const scratch_term = try std.fmt.bufPrint(&scratch_buf, "{{x, {d}}}", .{scratch});
            try self.bodyPrint(
                "    {{gc_bif, '-', {{f, 0}}, {d}, [{{integer, 0}}, {s}], {{x, {d}}}}}.\n",
                .{ scratch + 1, scratch_term, dest },
            );
        }
    }

    /// Emit an `if (cmp) then else else` as a *value*: the chosen branch's value
    /// lands in `{x, 0}` and control falls through to a shared end label — no
    /// `return`/`deallocate`. This is correct whether the `if` feeds a binding
    /// (`val r = if …`), an argument, a case-arm body, or a following `return`
    /// (the caller emits the `return`). A branch that itself ends in an explicit
    /// `return`/jump keeps its own control flow and suppresses the merge jump.
    fn emitValueIf(self: *Emitter, i: anytype) anyerror!void {
        const else_label = self.allocLabel();
        const lowered = try self.lowerComparisonAsTest(i.cond.*, else_label);
        if (!lowered) {
            try self.lowerExprIntoX0(i.cond.*);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{else_label});
        }

        const end_label = self.allocLabel();
        const then_fell = try self.emitValueBody(i.then_);
        if (then_fell) try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});

        try self.bodyPrint("  {{label, {d}}}.\n", .{else_label});
        if (i.else_) |els| {
            _ = try self.emitValueBody(els);
        } else {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
        }
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// Lower a body whose last statement is its value: all but the last are
    /// emitted as statements, the last is lowered into `{x, 0}` and control
    /// falls through. Returns true when it fell through (produced a value),
    /// false when the last statement was an explicit jump (`return`/`throw`/…)
    /// that transferred control on its own.
    fn emitValueBody(self: *Emitter, body: []const ast.Stmt) anyerror!bool {
        if (body.len == 0) {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
            return true;
        }
        for (body[0 .. body.len - 1]) |stmt| try self.emitStmt(stmt);
        const last = body[body.len - 1];
        switch (last.expr) {
            .jump => {
                try self.emitStmt(last);
                return false;
            },
            else => {},
        }
        try self.lowerExprIntoX0(last.expr);
        return true;
    }

    /// Lower a binaryOp (arithmetic, comparison, or logical) so its value
    /// lands in `{x, dest}`.
    fn lowerArith(self: *Emitter, e: ast.Expr, dest: u32) anyerror!void {
        switch (e) {
            .binaryOp => |bin| switch (bin.op) {
                .add, .sub, .mul, .div, .mod => try self.lowerArithGcBif(bin, dest),
                .lt, .gt, .lte, .gte, .eq, .ne => try self.lowerCmpAsValue(bin, dest),
                .@"and" => try self.lowerAndAsValue(bin, dest),
                .@"or" => try self.lowerOrAsValue(bin, dest),
            },
            else => try self.bodyPrint("    %% unsupported in arith position: {s}\n", .{@tagName(e)}),
        }
    }

    /// Arithmetic via `gc_bif`. Handles non-simple operands by materializing
    /// them into scratch x-registers above `cur_arity`.
    fn lowerArithGcBif(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const bif: []const u8 = switch (bin.op) {
            .add => "'+'",
            .sub => "'-'",
            .mul => "'*'",
            .div => "'div'",
            .mod => "'rem'",
            else => unreachable,
        };
        var lhs_buf: [64]u8 = undefined;
        var rhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.lhs.*, &lhs_buf);
        const rhs_simple = try self.simpleTerm(bin.rhs.*, &rhs_buf);

        if (lhs_simple != null and rhs_simple != null) {
            try self.bodyPrint(
                "    {{gc_bif, {s}, {{f, 0}}, {d}, [{s}, {s}], {{x, {d}}}}}.\n",
                .{ bif, @max(self.cur_arity, self.min_live), lhs_simple.?, rhs_simple.?, dest },
            );
            return;
        }

        const scratch = self.cur_arity;
        if (lhs_simple) |ls| {
            try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ ls, scratch });
        } else {
            try self.lowerExprIntoX0(bin.lhs.*);
            if (scratch != 0)
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
        }

        var rhs_final_buf: [64]u8 = undefined;
        const rhs_final: []const u8 = if (rhs_simple) |rs| rs else blk: {
            try self.lowerExprIntoX0(bin.rhs.*);
            break :blk try std.fmt.bufPrint(&rhs_final_buf, "{{x, 0}}", .{});
        };

        var lhs_final_buf: [64]u8 = undefined;
        const lhs_final = try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});

        try self.bodyPrint(
            "    {{gc_bif, {s}, {{f, 0}}, {d}, [{s}, {s}], {{x, {d}}}}}.\n",
            .{ bif, @max(scratch + 1, self.min_live), lhs_final, rhs_final, dest },
        );
    }

    /// Lower a comparison (`<`, `>`, `==`, …) as a value: emits a `{test, …}`
    /// then branches to produce `{atom, true}` or `{atom, false}` in `{x, dest}`.
    fn lowerCmpAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const cmp = comparisonTestOp(bin.op) orelse unreachable;

        var lhs_buf: [64]u8 = undefined;
        var rhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.lhs.*, &lhs_buf);
        const rhs_simple = try self.simpleTerm(bin.rhs.*, &rhs_buf);

        var lhs_final_buf: [64]u8 = undefined;
        var rhs_final_buf: [64]u8 = undefined;
        var lhs_final: []const u8 = undefined;
        var rhs_final: []const u8 = undefined;

        if (lhs_simple != null and rhs_simple != null) {
            lhs_final = lhs_simple.?;
            rhs_final = rhs_simple.?;
        } else {
            const scratch = self.cur_arity;
            if (lhs_simple) |ls| {
                try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ ls, scratch });
            } else {
                try self.lowerExprIntoX0(bin.lhs.*);
                if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            }
            lhs_final = try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});

            if (rhs_simple) |rs| {
                rhs_final = rs;
            } else {
                try self.lowerExprIntoX0(bin.rhs.*);
                rhs_final = try std.fmt.bufPrint(&rhs_final_buf, "{{x, 0}}", .{});
            }
        }

        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        const a = if (cmp.swap) rhs_final else lhs_final;
        const b = if (cmp.swap) lhs_final else rhs_final;
        try self.bodyPrint("    {{test, {s}, {{f, {d}}}, [{s}, {s}]}}.\n", .{ cmp.opcode, false_label, a, b });
        try self.bodyPrint("    {{move, {{atom, true}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, false}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// `a && b` → short-circuit: test `a`, if false → false, else evaluate `b`.
    fn lowerAndAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        var lhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.lhs.*, &lhs_buf);
        var lhs_final_buf: [64]u8 = undefined;
        const lhs_final: []const u8 = if (lhs_simple) |ls| ls else blk: {
            const scratch = self.cur_arity;
            try self.lowerExprIntoX0(bin.lhs.*);
            if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            break :blk try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});
        };
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{s}, {{atom, true}}]}}.\n", .{ false_label, lhs_final });
        try self.lowerExprIntoX0(bin.rhs.*);
        if (dest != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, false}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// `a || b` → short-circuit: test `a`, if true → true, else evaluate `b`.
    fn lowerOrAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        var lhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.lhs.*, &lhs_buf);
        var lhs_final_buf: [64]u8 = undefined;
        const lhs_final: []const u8 = if (lhs_simple) |ls| ls else blk: {
            const scratch = self.cur_arity;
            try self.lowerExprIntoX0(bin.lhs.*);
            if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            break :blk try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});
        };
        const true_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, is_ne_exact, {{f, {d}}}, [{s}, {{atom, true}}]}}.\n", .{ true_label, lhs_final });
        try self.lowerExprIntoX0(bin.rhs.*);
        if (dest != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{true_label});
        try self.bodyPrint("    {{move, {{atom, true}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// `!x` → test x against true, produce the opposite atom.
    fn lowerNot(self: *Emitter, inner: ast.Expr, dest: u32) anyerror!void {
        try self.lowerExprIntoX0(inner);
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, false}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, true}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    // ── calls ────────────────────────────────────────────────────────────────

    /// `non_tail`: result lives in `{x, 0}` after the call; caller proceeds.
    /// `tail`: emit `call_last`/`call_only` (deallocate + return baked in).
    const CallMode = enum { non_tail, tail };

    /// Lower a `call.call` form into BEAM assembly. Evaluates each arg into
    /// `{x, i}`, then emits the appropriate call opcode.
    fn lowerCall(self: *Emitter, cc: anytype, mode: CallMode, loc: ast.Loc) anyerror!void {
        if (cc.is_builtin) {
            try self.lowerBuiltinCall(cc, mode);
            return;
        }
        if (cc.receiver) |recv_expr| {
            const recv_name: ?[]const u8 = switch (recv_expr.*) {
                .identifier => |idn| switch (idn.kind) {
                    .ident => |n| n,
                    else => null,
                },
                else => null,
            };
            // Static extension dispatch (F6).
            //
            // Activated: `recv.m(args)` carries a `rewrites` entry → call the
            // mangled `'<target>_m'(recv, args)` with the receiver prepended.
            if (self.rewrites.get(loc)) |sym| {
                var nbuf: [256]u8 = undefined;
                if (self.extMangledName(&nbuf, sym, cc.callee)) |mangled| {
                    try self.lowerExtCall(mangled, recv_expr, cc.args, mode);
                    return;
                }
            }
            // Qualified: `Sym.m(obj, args)` where `Sym` is an extension block
            // name → call `'<target>_m'(obj, args)`. The receiver names the
            // block (not a module / not an argument); `obj` is already arg 0.
            if (recv_name) |rn| {
                if (self.ext_by_name.contains(rn)) {
                    var nbuf: [256]u8 = undefined;
                    if (self.extMangledName(&nbuf, rn, cc.callee)) |mangled| {
                        const arity = cc.args.len;
                        try self.materializeCallArgs(cc.args);
                        const labels = self.fnLabelsFor(mangled, arity) catch {
                            try self.bodyPrint("    %% unresolved extension call: {s}/{d}\n", .{ mangled, arity });
                            if (mode == .tail) try self.emitReturn();
                            return;
                        };
                        switch (mode) {
                            .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ arity, labels.entry }),
                            .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ arity, labels.entry, self.num_y }),
                        }
                        return;
                    }
                }
            }
            // Primitive receiver method (`xs.map(f)`, `s.toUpper()`): inference
            // tagged this call-site loc with the receiver's primitive family, so
            // lower it to the host op (`lists:map`, `string:uppercase`) — parity
            // with the erlang backend's `emitPrimMethod`.
            if (self.instance_lowerings.get(loc)) |il| switch (il) {
                .prim => |k| {
                    if (try self.emitPrimMethod(k, cc.callee, recv_expr, cc, mode)) return;
                    // An unrecognised prim method (a `default fn` like `fold`/`all`,
                    // or one not yet lowered on BEAM) falls through to the
                    // value-receiver local-call path below — parity with the
                    // erlang backend's bare-`callee(Recv, …)` fallthrough.
                },
                .record => {},
            };
            // Module-qualified remote call: a PascalCase identifier receiver that
            // isn't a local binding is a module reference: `List.map(xs, f)` →
            // `list:map(xs, f)` (mirrors the Erlang backend's `isModuleRef`/
            // `erlangModule`). The receiver names the module, so it is *not*
            // prepended as an argument; trailing lambdas become fun arguments.
            if (recv_name) |rn| {
                if (rn.len > 0 and rn.len <= 128 and
                    std.ascii.isUpper(rn[0]) and !self.reg_map.contains(rn))
                {
                    // `Type.Variant(…)` — a PascalCase callee on a PascalCase
                    // type receiver is an enum variant constructor, not a module
                    // call → tagged tuple `{Variant, payload…}` (matches the tag
                    // tested by `is_tagged_tuple`). A lowercase callee (`List.map`)
                    // is a module-qualified remote call.
                    if (cc.callee.len > 0 and std.ascii.isUpper(cc.callee[0])) {
                        try self.lowerTaggedTuple(cc.callee, cc.args);
                        if (mode == .tail) try self.emitReturn();
                        return;
                    }
                    // A lowercase callee on a PascalCase record/struct receiver
                    // is an associated fn (`Response.ok(...)`), emitted by
                    // `emitMethodAsFn` as `'<Type>_<callee>'`. A LOCAL record
                    // calls that fn directly by label; an IMPORTED record
                    // (`from "web"`) calls it remotely in the owning module —
                    // never the lowercased type name (`response:ok`).
                    if (cc.trailing.len == 0 and self.record_fields.contains(rn)) {
                        var nbuf: [256]u8 = undefined;
                        const mangled = std.fmt.bufPrint(&nbuf, "'{s}_{s}'", .{ rn, cc.callee }) catch return;
                        const arity = cc.args.len;
                        if (self.imported_types.get(rn)) |owner| {
                            try self.materializeCallArgs(cc.args);
                            switch (mode) {
                                .non_tail => try self.bodyPrint(
                                    "    {{call_ext, {d}, {{extfunc, {s}, {s}, {d}}}}}.\n",
                                    .{ arity, owner, mangled, arity },
                                ),
                                .tail => try self.bodyPrint(
                                    "    {{call_ext_last, {d}, {{extfunc, {s}, {s}, {d}}}, {d}}}.\n",
                                    .{ arity, owner, mangled, arity, self.num_y },
                                ),
                            }
                            return;
                        }
                        if (self.fnLabelsFor(mangled, arity)) |labels| {
                            try self.materializeCallArgs(cc.args);
                            switch (mode) {
                                .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ arity, labels.entry }),
                                .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ arity, labels.entry, self.num_y }),
                            }
                            return;
                        } else |_| {}
                    }
                    // Associated `default fn` of an interface (`Array.range`, `Pair.of`):
                    // emitted as the local mangled fn `'<Interface>_<callee>'` by
                    // `emitInterfaceAssoc` (the interface is inlined), so call it
                    // directly — never a remote `array:range`.
                    if (cc.trailing.len == 0 and self.isInterfaceAssoc(rn, cc.callee)) {
                        var nbuf: [256]u8 = undefined;
                        const mangled = std.fmt.bufPrint(&nbuf, "'{s}_{s}'", .{ rn, cc.callee }) catch return;
                        const arity = cc.args.len;
                        if (self.fnLabelsFor(mangled, arity)) |labels| {
                            try self.materializeCallArgs(cc.args);
                            switch (mode) {
                                .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ arity, labels.entry }),
                                .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ arity, labels.entry, self.num_y }),
                            }
                            return;
                        } else |_| {}
                    }
                    const total = cc.args.len + cc.trailing.len;
                    const scratch = self.cur_arity;
                    for (cc.args, 0..) |arg, i| {
                        try self.lowerExprIntoX0(arg.value.*);
                        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + i});
                    }
                    for (cc.trailing, 0..) |trail, j| {
                        // Positional args sit in scratch..scratch+args.len-1 and
                        // earlier trailing funs in the slots after — all must
                        // survive the closure's test_heap.
                        try self.lowerLambda(trail, @intCast(scratch + cc.args.len + j));
                        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + cc.args.len + j});
                    }
                    for (0..total) |i| {
                        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ scratch + i, i });
                    }
                    var mbuf: [128]u8 = undefined;
                    @memcpy(mbuf[0..rn.len], rn);
                    mbuf[0] = std.ascii.toLower(mbuf[0]);
                    const mod = mbuf[0..rn.len];
                    switch (mode) {
                        .non_tail => try self.bodyPrint(
                            "    {{call_ext, {d}, {{extfunc, {s}, {s}, {d}}}}}.\n",
                            .{ total, mod, cc.callee, total },
                        ),
                        .tail => try self.bodyPrint(
                            "    {{call_ext_last, {d}, {{extfunc, {s}, {s}, {d}}}, {d}}}.\n",
                            .{ total, mod, cc.callee, total, self.num_y },
                        ),
                    }
                    return;
                }
            }
            if (recv_name) |rn| {
                if (self.reg_map.get(rn)) |reg| {
                    var rbuf: [64]u8 = undefined;
                    const recv_term = try reg.format(&rbuf);
                    try self.bodyPrint("    {{move, {s}, {{x, 0}}}}.\n", .{recv_term});
                } else {
                    var rnbuf: [256]u8 = undefined;
                    try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{try atomName(rn, &rnbuf)});
                }
            } else {
                try self.lowerExprIntoX0(recv_expr.*);
            }
            const scratch = self.cur_arity;
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            for (cc.args, 0..) |arg, i| {
                try self.lowerExprIntoX0(arg.value.*);
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + 1 + i});
            }
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
            for (0..cc.args.len) |i| {
                try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ scratch + 1 + i, 1 + i });
            }
            const total_arity = 1 + cc.args.len;
            const labels = self.fnLabelsFor(cc.callee, total_arity) catch {
                try self.bodyPrint("    %% unresolved method call: {s}/{d}\n", .{ cc.callee, total_arity });
                if (mode == .tail) try self.emitReturn();
                return;
            };
            switch (mode) {
                .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ total_arity, labels.entry }),
                .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ total_arity, labels.entry, self.num_y }),
            }
            return;
        }
        if (cc.trailing.len > 0) {
            for (cc.trailing) |trail| {
                try self.lowerLambda(trail, self.cur_arity);
                const scratch = self.cur_arity;
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            }
        }

        const arity = cc.args.len;

        // A top-level function resolves to a reserved label pair → direct call.
        if (self.fnLabelsFor(cc.callee, arity)) |labels| {
            try self.materializeCallArgs(cc.args);
            switch (mode) {
                .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ arity, labels.entry }),
                .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ arity, labels.entry, self.num_y }),
            }
            return;
        } else |_| {}

        // Otherwise, a name bound to a local (a `syntax fn` parameter or a
        // `val f = {x -> …}`) holds a fun and is applied via `call_fun`. The fun
        // must be loaded into `{x, arity}` *before* materializing the args — an
        // argument may target the very register the fun currently occupies (a
        // fun parameter in `{x, 0}` and a 1-arg call whose arg also lands there).
        if (self.reg_map.get(cc.callee)) |reg| {
            var rbuf: [64]u8 = undefined;
            const fun_term = try reg.format(&rbuf);
            try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ fun_term, arity });
            try self.materializeCallArgs(cc.args);
            try self.bodyPrint("    {{call_fun, {d}}}.\n", .{arity});
            if (mode == .tail) try self.emitReturn();
            return;
        }

        // A PascalCase callee that names a known record/struct (local or
        // cross-imported) is a constructor: `AppError(code: 400, msg: "x")` /
        // `App(8080, "/")` → a map `#{…}`. Positional args take their field name
        // from the declared order; reads use `get_map_elements` with the same
        // atom keys.
        if (cc.callee.len > 0 and std.ascii.isUpper(cc.callee[0])) {
            if (self.record_fields.get(cc.callee)) |fields| {
                try self.lowerRecordConstruct(cc.args, fields);
                if (mode == .tail) try self.emitReturn();
                return;
            }
            // No registered shape (e.g. an inferred/anonymous record) but all
            // args are labeled — fall back to label-keyed construction.
            if (allNamed(cc.args)) {
                try self.lowerRecordConstruct(cc.args, null);
                if (mode == .tail) try self.emitReturn();
                return;
            }
        }

        try self.materializeCallArgs(cc.args);
        try self.bodyPrint("    %% unresolved local call: {s}/{d}\n", .{ cc.callee, arity });
        if (mode == .tail) try self.emitReturn();
    }

    // ── primitive-receiver method lowering ────────────────────────────────────
    //
    // Mirrors the erlang backend's `emitPrimMethod`, but BEAM is register-based,
    // so each shape needs an explicit operand→x-register choreography. Three
    // reusable layouts cover the directly-host-callable methods:
    //
    //   • recv-only        `fn(Recv)`            → `lists:reverse`, `string:length`
    //   • fun-then-list    `fn(Fun, Recv)`       → `lists:map/filter/foreach`
    //   • recv-then-args   `fn(Recv, Arg…[Lit])` → `string:split`, `string:slice/2`
    //   • arg-then-list    `fn(Arg, Recv)`       → `lists:member`
    //
    // The fun-then-list layout exploits that a `move {x,0},{x,1}` leaves the list
    // live in *both* registers, so the closure's `make_fun3` (which always writes
    // `{x, 0}`) lands the fun in `x0` while the list survives in `x1` — correct at
    // any current arity, with no scratch gap to GC over.
    //
    // Methods needing inline funs / arithmetic / structural compares (`join`,
    // `indexOf`, `at`, `isEmpty`, 2-arg `slice`, `append`/`prepend`/`push`,
    // `string contains/startsWith`) are not yet lowered on BEAM; returning
    // `false` lets the caller fall through to the value-receiver path (a genuine
    // backend limit, recorded rather than faked). Returns `true` when handled.
    fn emitPrimMethod(self: *Emitter, k: envMod.PrimKind, callee: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        const eq = std.mem.eql;
        switch (k) {
            .array => {
                if (eq(u8, callee, "map")) try self.primFunThenList("lists", "map", recv_expr, cc, mode) else if (eq(u8, callee, "filter")) try self.primFunThenList("lists", "filter", recv_expr, cc, mode) else if (eq(u8, callee, "forEach")) try self.primFunThenList("lists", "foreach", recv_expr, cc, mode) else if (eq(u8, callee, "reverse")) try self.primRecvOnly("lists", "reverse", recv_expr, mode) else if (eq(u8, callee, "contains")) try self.primArgThenList("lists", "member", recv_expr, cc, mode) else if (eq(u8, callee, "len") or eq(u8, callee, "length") or eq(u8, callee, "size")) try self.primRecvOnly("erlang", "length", recv_expr, mode) else if (eq(u8, callee, "prepend")) try self.primPrepend(recv_expr, cc, mode) else if (eq(u8, callee, "push")) try self.primAppendElem(recv_expr, cc, mode) else if (eq(u8, callee, "append")) try self.primAppendList(recv_expr, cc, mode) else if (eq(u8, callee, "isEmpty")) try self.primIsEmpty(recv_expr, mode) else return false;
                return true;
            },
            .string => {
                if (eq(u8, callee, "length")) try self.primRecvOnly("string", "length", recv_expr, mode) else if (eq(u8, callee, "toUpper")) try self.primRecvOnly("string", "uppercase", recv_expr, mode) else if (eq(u8, callee, "toLower")) try self.primRecvOnly("string", "lowercase", recv_expr, mode) else if (eq(u8, callee, "trim")) try self.primRecvOnly("string", "trim", recv_expr, mode) else if (eq(u8, callee, "split")) try self.primRecvThenArgs("string", "split", recv_expr, cc, "{atom, all}", mode) else if (eq(u8, callee, "slice") and cc.args.len + cc.trailing.len == 1) try self.primRecvThenArgs("string", "slice", recv_expr, cc, null, mode) else return false;
                return true;
            },
            .bool, .int, .float => return false,
        }
    }

    /// `fn(Recv)` — the sole operand is the receiver, lowered straight into `x0`.
    fn primRecvOnly(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*);
        try self.emitPrimCallExt(mod, fn_name, 1, mode);
    }

    /// `recv.prepend(x)` → `[x | recv]` — a single cons cell.
    fn primPrepend(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv (the tail)
        try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n"); // x1 = tail
        try self.lowerPrimFunArg(cc, 2); // x0 = head (arg 0), min_live=2 keeps x1
        try self.bodyWrite("    {test_heap, 2, 2}.\n");
        try self.bodyWrite("    {put_list, {x, 0}, {x, 1}, {x, 0}}.\n");
        if (mode == .tail) try self.emitReturn();
    }

    /// `recv.append(xs)` → `recv ++ xs` (`lists:append/2`; `xs` is already a list).
    /// The (often-literal) arg is lowered first into `x1`, then the receiver into
    /// `x0` — a simple receiver won't clobber `x1`.
    fn primAppendList(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerPrimFunArg(cc, 1); // x0 = the list to append
        try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n"); // x1 = that list
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv
        try self.emitPrimCallExt("lists", "append", 2, mode);
    }

    /// `recv.push(x)` → `recv ++ [x]` (`lists:append/2`).
    fn primAppendElem(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv
        try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n"); // x1 = recv
        try self.lowerPrimFunArg(cc, 2); // x0 = the element, min_live=2 keeps x1
        try self.bodyWrite("    {test_heap, 2, 2}.\n");
        try self.bodyWrite("    {put_list, {x, 0}, nil, {x, 0}}.\n"); // x0 = [elem]
        // Want `lists:append(Recv, [elem])` → x0 = Recv, x1 = [elem].
        try self.bodyWrite("    {move, {x, 0}, {x, 2}}.\n"); // x2 = [elem]
        try self.bodyWrite("    {move, {x, 1}, {x, 0}}.\n"); // x0 = recv
        try self.bodyWrite("    {move, {x, 2}, {x, 1}}.\n"); // x1 = [elem]
        try self.emitPrimCallExt("lists", "append", 2, mode);
    }

    /// `recv.isEmpty()` → the boolean `recv =:= []`.
    fn primIsEmpty(self: *Emitter, recv_expr: *const ast.Expr, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv
        const not_empty = self.allocLabel();
        const end_l = self.allocLabel();
        try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, nil]}}.\n", .{not_empty});
        try self.bodyWrite("    {move, {atom, true}, {x, 0}}.\n");
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
        try self.bodyPrint("  {{label, {d}}}.\n", .{not_empty});
        try self.bodyWrite("    {move, {atom, false}, {x, 0}}.\n");
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
        if (mode == .tail) try self.emitReturn();
    }

    /// `fn(Fun, Recv)` — `lists:map`/`filter`/`foreach`. The list lands in `x1`,
    /// the closure (a positional fun arg or a trailing lambda) in `x0`.
    fn primFunThenList(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = List
        try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n"); // x1 = List (x0 still List)
        try self.lowerPrimFunArg(cc, 2); // x0 = Fun (closure live=2 keeps x1)
        try self.emitPrimCallExt(mod, fn_name, 2, mode);
    }

    /// `fn(Arg, Recv)` — `lists:member`. List in `x1`, the data arg in `x0`.
    fn primArgThenList(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = List
        try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n"); // x1 = List
        try self.lowerPrimFunArg(cc, 2); // x0 = Arg
        try self.emitPrimCallExt(mod, fn_name, 2, mode);
    }

    /// `fn(Recv, Arg [, Lit])` — receiver stays in `x0`; the (simple) arg goes to
    /// `x1`, with an optional literal in `x2` (`string:split(S, Sep, all)`). A
    /// non-simple arg would need to clobber `x0`, so it falls back to the limit.
    fn primRecvThenArgs(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, extra_lit: ?[]const u8, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = Recv
        var buf: [64]u8 = undefined;
        if (cc.args.len > 0) {
            const t = try self.simpleTerm(cc.args[0].value.*, &buf) orelse {
                try self.bodyPrint("    %% prim method not lowered on beam (complex arg): {s}/{d}\n", .{ fn_name, cc.args.len + 1 });
                if (mode == .tail) try self.emitReturn();
                return;
            };
            try self.bodyPrint("    {{move, {s}, {{x, 1}}}}.\n", .{t});
        }
        var arity: usize = 1 + cc.args.len;
        if (extra_lit) |lit| {
            try self.bodyPrint("    {{move, {s}, {{x, 2}}}}.\n", .{lit});
            arity += 1;
        }
        try self.emitPrimCallExt(mod, fn_name, arity, mode);
    }

    /// Lower the first call argument (positional fun/value or trailing lambda)
    /// into `x0`. `live` is the x-register floor any closure allocation must
    /// preserve — raised via `min_live` so it applies whether the fun arrives as
    /// a positional lambda (lowered through `lowerExprIntoX0`, which would
    /// otherwise request `live = cur_arity`) or a trailing one.
    fn lowerPrimFunArg(self: *Emitter, cc: anytype, live: u32) anyerror!void {
        const saved = self.min_live;
        self.min_live = @max(self.min_live, live);
        defer self.min_live = saved;
        if (cc.args.len > 0) {
            try self.lowerExprIntoX0(cc.args[0].value.*);
        } else if (cc.trailing.len > 0) {
            try self.lowerLambda(cc.trailing[0], live);
        } else {
            try self.bodyWrite("    {move, nil, {x, 0}}.\n");
        }
    }

    fn emitPrimCallExt(self: *Emitter, mod: []const u8, fn_name: []const u8, arity: usize, mode: CallMode) anyerror!void {
        switch (mode) {
            .non_tail => try self.bodyPrint("    {{call_ext, {d}, {{extfunc, {s}, {s}, {d}}}}}.\n", .{ arity, mod, fn_name, arity }),
            .tail => try self.bodyPrint("    {{call_ext_last, {d}, {{extfunc, {s}, {s}, {d}}}, {d}}}.\n", .{ arity, mod, fn_name, arity, self.num_y }),
        }
    }

    /// Activated extension dispatch: lower the receiver into `{x, 0}` and the
    /// args into `{x, 1..}`, then call the mangled `'<target>_<method>'`
    /// function with the receiver prepended (arity = 1 + args). Mirrors the
    /// value-receiver method-call shuffle but resolves the mangled callee.
    fn lowerExtCall(self: *Emitter, mangled: []const u8, recv_expr: anytype, args: anytype, mode: CallMode) anyerror!void {
        const recv_name: ?[]const u8 = switch (recv_expr.*) {
            .identifier => |idn| switch (idn.kind) {
                .ident => |n| n,
                else => null,
            },
            else => null,
        };
        if (recv_name) |rn| {
            if (self.reg_map.get(rn)) |reg| {
                var rbuf: [64]u8 = undefined;
                const recv_term = try reg.format(&rbuf);
                try self.bodyPrint("    {{move, {s}, {{x, 0}}}}.\n", .{recv_term});
            } else {
                try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{rn});
            }
        } else {
            try self.lowerExprIntoX0(recv_expr.*);
        }
        const scratch = self.cur_arity;
        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
        for (args, 0..) |arg, i| {
            try self.lowerExprIntoX0(arg.value.*);
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + 1 + i});
        }
        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
        for (0..args.len) |i| {
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ scratch + 1 + i, 1 + i });
        }
        const total_arity = 1 + args.len;
        const labels = self.fnLabelsFor(mangled, total_arity) catch {
            try self.bodyPrint("    %% unresolved extension call: {s}/{d}\n", .{ mangled, total_arity });
            if (mode == .tail) try self.emitReturn();
            return;
        };
        switch (mode) {
            .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ total_arity, labels.entry }),
            .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ total_arity, labels.entry, self.num_y }),
        }
    }

    /// True when every argument is named (`field: value`) — the shape of a
    /// record/struct constructor call. An empty argument list also qualifies
    /// (a zero-field record `Empty()`).
    fn allNamed(args: anytype) bool {
        for (args) |arg| {
            if (arg.label == null) return false;
        }
        return true;
    }

    /// Build a record/struct as an Erlang map via `put_map_assoc`. Each field
    /// value is evaluated into a scratch register, then the map is assembled
    /// with the field names as atom keys. A labeled arg uses its label; a
    /// positional arg (`App(8080, "/")`) takes the field name at its index from
    /// `fields` (the declared order). Result in `{x, 0}`.
    fn lowerRecordConstruct(self: *Emitter, args: anytype, fields: ?[]const []const u8) anyerror!void {
        const n = args.len;
        if (n == 0) {
            try self.bodyWrite("    {move, {literal, #{}}, {x, 0}}.\n");
            return;
        }
        // Scratch slots start at `max(cur_arity, 1)` — never `{x, 0}`, which each
        // `lowerExprIntoX0` overwrites; storing a value there would clobber it as
        // soon as the next field is evaluated.
        const scratch = @max(self.cur_arity, 1);
        for (args, 0..) |arg, i| {
            try self.lowerExprIntoX0(arg.value.*);
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + i});
        }
        try self.bodyPrint(
            "    {{put_map_assoc, {{f, 0}}, {{literal, #{{}}}}, {{x, 0}}, {d}, {{list, [",
            .{scratch + n},
        );
        for (args, 0..) |arg, i| {
            if (i > 0) try self.bodyWrite(", ");
            const key: []const u8 = arg.label orelse if (fields != null and i < fields.?.len) fields.?[i] else "_arg";
            var kb: [256]u8 = undefined;
            try self.bodyPrint("{{atom, {s}}}, {{x, {d}}}", .{ try atomName(key, &kb), scratch + i });
        }
        try self.bodyWrite("]}}.\n");
    }

    /// Build a tagged tuple `{Tag, Field0, …}` from an enum variant constructor
    /// `Shape.Circle(r: 5)` → `{Circle, 5}`. The tag atom matches the one tested
    /// by `is_tagged_tuple` when the variant is pattern-matched. Result in `{x, 0}`.
    fn lowerTaggedTuple(self: *Emitter, tag: []const u8, args: anytype) anyerror!void {
        const n = args.len;
        const scratch = @max(self.cur_arity, 1);
        for (args, 0..) |arg, i| {
            try self.lowerExprIntoX0(arg.value.*);
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + i});
        }
        // A tuple of `n + 1` elements (tag + fields) needs `n + 2` heap words.
        try self.bodyPrint("    {{test_heap, {d}, {d}}}.\n", .{ n + 2, scratch + n });
        var tag_buf: [256]u8 = undefined;
        const tag_atom = try atomName(tag, &tag_buf);
        try self.bodyPrint("    {{put_tuple2, {{x, 0}}, {{list, [{{atom, {s}}}", .{tag_atom});
        for (0..n) |i| {
            try self.bodyPrint(", {{x, {d}}}", .{scratch + i});
        }
        try self.bodyWrite("]}}.\n");
    }

    /// Builtins (`@print`, `@todo`, …) map to specific BEAM call_ext targets.
    /// Fase 2 only handles `@todo` cleanly (errors out at runtime); printing
    /// and the rest of the builtins require strings/binaries (Fase 3+).
    fn lowerBuiltinCall(self: *Emitter, cc: anytype, mode: CallMode) anyerror!void {
        if (std.mem.eql(u8, cc.callee, "todo") or std.mem.eql(u8, cc.callee, "panic")) {
            const atom: []const u8 = if (std.mem.eql(u8, cc.callee, "todo")) "undef" else "panic";
            try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{atom});
            const tag: []const u8 = if (mode == .tail) "call_ext_only" else "call_ext";
            try self.bodyPrint("    {{{s}, 1, {{extfunc, erlang, error, 1}}}}.\n", .{tag});
            return;
        }
        if (std.mem.eql(u8, cc.callee, "print")) {
            if (cc.args.len > 0) {
                try self.lowerExprIntoX0(cc.args[0].value.*);
            }
            try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n");
            try self.emitStringLiteral("~p~n", 0);
            try self.bodyWrite("    {test_heap, 2, 2}.\n");
            try self.bodyWrite("    {put_list, {x, 1}, nil, {x, 1}}.\n");
            const tag: []const u8 = if (mode == .tail) "call_ext_only" else "call_ext";
            try self.bodyPrint("    {{{s}, 2, {{extfunc, io, format, 2}}}}.\n", .{tag});
            return;
        }
        if (std.mem.eql(u8, cc.callee, "block")) {
            if (cc.trailing.len > 0) {
                const body = cc.trailing[0];
                for (body.body) |stmt| try self.emitStmt(stmt);
            }
            return;
        }
        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
            try self.lowerResultOptionOp(cc.callee, cc.args);
            if (mode == .tail) try self.emitReturn();
            return;
        }
        try self.bodyPrint("    %% unsupported builtin: @{s} (Fase 3+)\n", .{cc.callee});
    }

    /// Lower a `__bp_<domain>_<op>(receiver, arg?)` Result/Option method op into
    /// BEAM assembly. The value shapes mirror the Erlang backend so values
    /// interoperate: a `@Result` is the idiomatic OTP pair `{ok, V} | {error, E}`
    /// (element 1 is the payload), and a `@Option` is the bare payload or the
    /// atom `undefined` for absence. `args[0]` is the receiver; `args[1]` (when
    /// present) the fn/default. The result lands in `{x, 0}`.
    ///
    /// Register budget: `{x, 0}` carries the receiver/result; the discriminator
    /// goes to `{x, cur_arity + 1}` and a payload stash to `{x, cur_arity + 2}`.
    /// `map`/`flatMap` apply the fn via `call_fun` (which clobbers the
    /// caller-saved x-registers), so the payload is staged in the stash slot and
    /// loaded into `{x, 0}` immediately before the call.
    fn lowerResultOptionOp(self: *Emitter, callee: []const u8, args: anytype) anyerror!void {
        const recv = args[0].value;
        const arg1: ?*ast.Expr = if (args.len > 1) args[1].value else null;
        const disc = self.cur_arity + 1;
        const pstash = self.cur_arity + 2;

        if (std.mem.eql(u8, callee, "__bp_ok") or std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor (`return v` / `throw e` in a `-> @Result<…>` fn):
            // build the idiomatic `{ok, V}` / `{error, E}` pair.
            const tag: []const u8 = if (std.mem.eql(u8, callee, "__bp_ok")) "ok" else "error";
            try self.lowerExprIntoX0(recv.*);
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{disc});
            try self.bodyPrint("    {{test_heap, 3, {d}}}.\n", .{disc + 1});
            try self.bodyPrint("    {{put_tuple2, {{x, 0}}, {{list, [{{atom, {s}}}, {{x, {d}}}]}}}}.\n", .{ tag, disc });
            return;
        }

        const is_result_map = std.mem.eql(u8, callee, "__bp_result_map");
        if (is_result_map or std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            const else_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, [{{x, 0}}, 2, {{atom, ok}}]}}.\n", .{else_l});
            // Ok: extract the payload, apply the fn to it. The payload sits in
            // `{x, pstash}` and must survive the closure's `test_heap`, so raise
            // the make_fun3 live floor across the fn lowering.
            try self.bodyPrint("    {{get_tuple_element, {{x, 0}}, 1, {{x, {d}}}}}.\n", .{pstash});
            self.min_live = pstash + 1;
            try self.lowerFnInto0(arg1);
            self.min_live = 0;
            try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n");
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{pstash});
            try self.bodyWrite("    {call_fun, 1}.\n");
            if (is_result_map) {
                // `map` rewraps the result as `{ok, Result}`; `flatMap` expects
                // the fn to already return a `@Result`, so it passes through.
                // Stash the result in `disc` (`{x, cur_arity+1}`) — contiguous with
                // `{x, 0}` — so the rewrap `test_heap` Live count covers only live
                // registers (`x1` above it is dead after `call_fun`).
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{disc});
                try self.bodyPrint("    {{test_heap, 3, {d}}}.\n", .{disc + 1});
                try self.bodyPrint("    {{put_tuple2, {{x, 0}}, {{list, [{{atom, ok}}, {{x, {d}}}]}}}}.\n", .{disc});
            }
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            // Not Ok: the `{error, E}` tuple is still in `{x, 0}` — propagate untouched.
            try self.bodyPrint("  {{label, {d}}}.\n", .{else_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            const else_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, [{{x, 0}}, 2, {{atom, ok}}]}}.\n", .{else_l});
            try self.bodyWrite("    {get_tuple_element, {x, 0}, 1, {x, 0}}.\n");
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{else_l});
            try self.lowerFnInto0(arg1);
            try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_isOk") or std.mem.eql(u8, callee, "__bp_result_isError")) {
            const want: []const u8 = if (std.mem.eql(u8, callee, "__bp_result_isOk")) "ok" else "error";
            const false_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, [{{x, 0}}, 2, {{atom, {s}}}]}}.\n", .{ false_l, want });
            try self.bodyWrite("    {move, {atom, true}, {x, 0}}.\n");
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{false_l});
            try self.bodyWrite("    {move, {atom, false}, {x, 0}}.\n");
            try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            // A present option is the bare value; `undefined` marks absence.
            // Both `map` and `flatMap` simply apply the fn to a present value.
            const present_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, undefined}}]}}.\n", .{present_l});
            // None: `{x, 0}` already holds `undefined`.
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{present_l});
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{pstash});
            try self.lowerFnInto0(arg1);
            try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n");
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{pstash});
            try self.bodyWrite("    {call_fun, 1}.\n");
            try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            const present_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, undefined}}]}}.\n", .{present_l});
            // None: evaluate the default into `{x, 0}`.
            try self.lowerFnInto0(arg1);
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{present_l});
            // Present: `{x, 0}` already holds the value.
            try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
            return;
        }

        try self.bodyPrint("    %% unsupported Result/Option op: {s}\n", .{callee});
    }

    /// Lower the fn/default argument of a Result/Option op into `{x, 0}`. A
    /// missing argument (shouldn't happen for the ops that read one) falls back
    /// to `undefined`.
    fn lowerFnInto0(self: *Emitter, arg: ?*ast.Expr) anyerror!void {
        if (arg) |a| {
            try self.lowerExprIntoX0(a.*);
        } else {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
        }
    }

    /// Lay out call arguments into `{x, 0}..{x, arity-1}`. Currently expects
    /// each arg to be a `simpleTerm` (literal/identifier). Composite args go
    /// to Fase 9 (proper allocation).
    fn materializeCallArgs(self: *Emitter, args: anytype) anyerror!void {
        if (args.len > 16) {
            try self.bodyWrite("    %% unsupported: call with > 16 args\n");
            return;
        }
        var bufs: [16][64]u8 = undefined;
        var terms: [16]?[]const u8 = undefined;
        var has_complex = false;
        for (args, 0..) |arg, i| {
            terms[i] = try self.simpleTerm(arg.value.*, &bufs[i]);
            if (terms[i] == null) has_complex = true;
        }

        if (!has_complex) {
            for (args, 0..) |_, i| {
                try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ terms[i].?, i });
            }
            return;
        }

        const scratch_base = self.cur_arity;
        for (args, 0..) |arg, i| {
            if (terms[i]) |t| {
                try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ t, scratch_base + i });
            } else {
                // A complex arg lowered here must not let its inner `gc_bif`/closure
                // GC-clobber the scratch slots holding the args already
                // materialized (`scratch_base..scratch_base+i-1`): raise the live
                // floor so those survive (e.g. `repeat(value, times - 1)` saves
                // `value` then lowers the `times - 1` gc_bif).
                const saved_min = self.min_live;
                self.min_live = @max(self.min_live, @as(u32, @intCast(scratch_base + i)));
                try self.lowerExprIntoX0(arg.value.*);
                self.min_live = saved_min;
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch_base + i});
            }
        }
        for (args, 0..) |_, i| {
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ scratch_base + i, i });
        }
    }

    /// Build an Erlang list from an array literal. Elements are consed
    /// right-to-left via `{put_list, Elem, Tail, {x, 0}}`.
    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        if (al.spreadExpr) |se| {
            try self.lowerExprIntoX0(se.*);
        } else {
            try self.bodyWrite("    {move, nil, {x, 0}}.\n");
        }
        if (al.elems.len > 0) {
            // Live x-registers across the cons allocation: `x0` holds the
            // accumulator (the spread tail, or `nil`), plus any x-register an
            // element reads in the loop below. A `val` spilled to a y-slot
            // contributes nothing — which is exactly why the recursive
            // `[head, ..(recurse(...))]` builders assemble (the recursive call
            // clobbers the param x-registers, but `head` lives on the stack). The
            // scratch save slot is written *after* this `test_heap`, so it must
            // not be claimed live (`cur_arity + 1` over-claimed it → `not_live`).
            var live: u32 = 1;
            for (al.elems) |elem| switch (elem) {
                .identifier => |id| switch (id.kind) {
                    .ident => |nm| if (self.reg_map.get(nm)) |reg| switch (reg) {
                        .x => |xi| live = @max(live, xi + 1),
                        .y => {},
                    },
                    else => {},
                },
                else => {},
            };
            try self.bodyPrint("    {{test_heap, {d}, {d}}}.\n", .{ al.elems.len * 2, live });
            var i: usize = al.elems.len;
            while (i > 0) {
                i -= 1;
                // The tail accumulator is stashed here while the next element is
                // computed into `x0`; the slot must differ from `x0`, so floor it
                // at 1 (a 0-arity fn like `main/0` would otherwise alias `x0` and
                // cons `[Elem | Elem]`). No GC runs in this loop — the up-front
                // `test_heap` reserves every cons cell — so the slot stays live.
                const scratch = @max(self.cur_arity, 1);
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                try self.lowerExprIntoX0(al.elems[i]);
                try self.bodyPrint(
                    "    {{put_list, {{x, 0}}, {{x, {d}}}, {{x, 0}}}}.\n",
                    .{scratch},
                );
            }
        }
    }

    /// Build an Erlang tuple from a tuple literal via `{put_tuple2, ...}`.
    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        const n = tl.elems.len;
        const scratch_base = self.cur_arity;
        for (tl.elems, 0..) |elem, i| {
            try self.lowerExprIntoX0(elem);
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch_base + i});
        }
        try self.bodyPrint("    {{test_heap, {d}, {d}}}.\n", .{ n + 1, scratch_base + n });
        try self.bodyPrint("    {{put_tuple2, {{x, 0}}, {{list, [", .{});
        for (0..n) |i| {
            if (i > 0) try self.bodyWrite(", ");
            try self.bodyPrint("{{x, {d}}}", .{scratch_base + i});
        }
        try self.bodyWrite("]}}.\n");
    }

    /// Bookkeeping for a guarded case arm: the label that restores the subject
    /// and falls through to the next arm, plus the scratch x-register holding
    /// the saved subject.
    const GuardCtx = struct { restore: u32, subj: u32 };

    /// Emit the guard check for an arm whose pattern already matched and whose
    /// pattern variables are bound. A guard never reads `{x, 0}` directly (it
    /// only references bound names → y-slots), but lowering it can clobber
    /// `{x, 0}`, which later arms still need as the subject — so the subject is
    /// stashed in a scratch register first and `cur_arity` is bumped past it so
    /// the guard's own scratch use doesn't overwrite it. On a failing guard the
    /// matcher jumps to `restore` (emitted by `emitGuardPost`), which reloads
    /// the subject and falls through to the next arm. Returns null (no-op) when
    /// the arm carries no guard, keeping unguarded arms byte-identical.
    fn emitGuardPre(self: *Emitter, guard: ?ast.Expr) !?GuardCtx {
        const g = guard orelse return null;
        const subj = self.cur_arity;
        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{subj});
        self.cur_arity += 1;
        const restore = self.allocLabel();
        const lowered = try self.lowerComparisonAsTest(g, restore);
        if (!lowered) {
            try self.lowerExprIntoX0(g);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{restore});
        }
        self.cur_arity -= 1;
        return GuardCtx{ .restore = restore, .subj = subj };
    }

    /// Counterpart to `emitGuardPre`: emit the restore block. It must be placed
    /// after the arm body's `{jump, end}` and immediately before this arm's
    /// fail label, so the failing-guard path restores the subject and flows
    /// into the next arm's pattern test.
    fn emitGuardPost(self: *Emitter, ctx: ?GuardCtx) !void {
        const c = ctx orelse return;
        try self.bodyPrint("  {{label, {d}}}.\n", .{c.restore});
        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{c.subj});
    }

    /// Lower a `case expr { pat -> body; ... }` into a chain of BEAM test
    /// instructions with fall-through labels. Optional `pat if guard -> body`
    /// guards are honoured via `emitGuardPre`/`emitGuardPost`.
    fn lowerCase(self: *Emitter, subjects: anytype, arms: anytype) anyerror!void {
        if (subjects.len == 0) {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
            return;
        }
        try self.lowerExprIntoX0(subjects[0]);

        const end_label = self.allocLabel();
        for (arms) |arm| {
            switch (arm.pattern) {
                .numberLit => |n| {
                    var buf: [64]u8 = undefined;
                    const term = try formatNumberInto(&buf, n);
                    const next = self.allocLabel();
                    try self.bodyPrint(
                        "    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {s}]}}.\n",
                        .{ next, term },
                    );
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.emitGuardPost(guard_ctx);
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .stringLit => |s| {
                    const next = self.allocLabel();
                    try self.bodyPrint("    {{move, {{x, 0}}, {{x, 1}}}}.\n", .{});
                    try self.emitStringLiteral(s, 0);
                    try self.bodyPrint(
                        "    {{test, is_eq, {{f, {d}}}, [{{x, 1}}, {{x, 0}}]}}.\n",
                        .{next},
                    );
                    // On a match the subject is still in {x, 1} (saved above)
                    // while {x, 0} holds the string literal from the test. A
                    // guard stashes {x, 0} as the subject, so restore the real
                    // subject first; unguarded arms skip this (no churn).
                    if (arm.guard != null) try self.bodyWrite("    {move, {x, 1}, {x, 0}}.\n");
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.emitGuardPost(guard_ctx);
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .ident => |name| {
                    if (std.mem.eql(u8, name, "_")) {
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                        try self.emitGuardPost(guard_ctx);
                    } else {
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(name, .{ .y = y_idx });
                        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                        try self.emitGuardPost(guard_ctx);
                    }
                },
                .wildcard => {
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.emitGuardPost(guard_ctx);
                },
                .@"or" => |pats| {
                    const arm_label = self.allocLabel();
                    for (pats) |p| {
                        switch (p) {
                            .numberLit => |n| {
                                var buf: [64]u8 = undefined;
                                const term = try formatNumberInto(&buf, n);
                                try self.bodyPrint(
                                    "    {{test, is_ne_exact, {{f, {d}}}, [{{x, 0}}, {s}]}}.\n",
                                    .{ arm_label, term },
                                );
                            },
                            else => {},
                        }
                    }
                    const next = self.allocLabel();
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{next});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{arm_label});
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.emitGuardPost(guard_ctx);
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .variant => |v| switch (v.payload) {
                    .fields => |fields| {
                        const next = self.allocLabel();
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(v.name, &vbuf);
                        try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, [{{x, 0}}, {d}, {{atom, {s}}}]}}.\n", .{ next, fields.len + 1, vatom });
                        for (fields, 0..) |bname, i| {
                            try self.bodyPrint("    {{get_tuple_element, {{x, 0}}, {d}, {{x, 1}}}}.\n", .{i + 1});
                            const y_idx = self.next_y;
                            self.next_y += 1;
                            try self.reg_map.put(bname, .{ .y = y_idx });
                            try self.bodyPrint("    {{move, {{x, 1}}, {{y, {d}}}}}.\n", .{y_idx});
                        }
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                        try self.emitGuardPost(guard_ctx);
                        try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                    },
                    .binding => |binding| {
                        const next = self.allocLabel();
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(v.name, &vbuf);
                        try self.bodyPrint("    {{test, is_tuple, {{f, {d}}}, [{{x, 0}}]}}.\n", .{next});
                        try self.bodyPrint("    {{get_tuple_element, {{x, 0}}, 0, {{x, 1}}}}.\n", .{});
                        try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 1}}, {{atom, {s}}}]}}.\n", .{ next, vatom });
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(binding, .{ .y = y_idx });
                        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                        try self.emitGuardPost(guard_ctx);
                        try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                    },
                    .literals => {
                        // Literal-argument variants are not lowered specially yet.
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                        try self.emitGuardPost(guard_ctx);
                    },
                },
                .list => |lst| {
                    const next = self.allocLabel();
                    if (lst.elems.len == 0 and lst.spread == null) {
                        try self.bodyPrint("    {{test, is_nil, {{f, {d}}}, [{{x, 0}}]}}.\n", .{next});
                    } else {
                        for (lst.elems) |_| {
                            try self.bodyPrint("    {{test, is_nonempty_list, {{f, {d}}}, [{{x, 0}}]}}.\n", .{next});
                            try self.bodyWrite("    {get_list, {x, 0}, {x, 1}, {x, 0}}.\n");
                        }
                        if (lst.spread) |spread_name| {
                            if (spread_name.len > 0) {
                                const y_idx = self.next_y;
                                self.next_y += 1;
                                try self.reg_map.put(spread_name, .{ .y = y_idx });
                                try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                            }
                        }
                    }
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.emitGuardPost(guard_ctx);
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .multi => |pats| {
                    const next = self.allocLabel();
                    for (pats, 0..) |p, i| {
                        if (i < subjects.len) {
                            switch (p) {
                                .numberLit => |n| {
                                    var buf: [64]u8 = undefined;
                                    const term = try formatNumberInto(&buf, n);
                                    var subj_buf: [64]u8 = undefined;
                                    const subj_term = try self.simpleTerm(subjects[i], &subj_buf) orelse blk: {
                                        try self.lowerExprIntoX0(subjects[i]);
                                        break :blk try std.fmt.bufPrint(&subj_buf, "{{x, 0}}", .{});
                                    };
                                    try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{s}, {s}]}}.\n", .{ next, subj_term, term });
                                },
                                .wildcard => {},
                                .ident => |name| {
                                    if (!std.mem.eql(u8, name, "_")) {
                                        try self.lowerExprIntoX0(subjects[i]);
                                        const y_idx = self.next_y;
                                        self.next_y += 1;
                                        try self.reg_map.put(name, .{ .y = y_idx });
                                        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                                    }
                                },
                                else => {},
                            }
                        }
                    }
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.emitGuardPost(guard_ctx);
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
            }
        }
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// Emit a lambda body. When the final statement is a bare value-producing
    /// expression (`{ n -> n + 1 }`), it is the closure's return value: lower it
    /// into `{x, 0}` and return. Plain `emitBody` would instead append a `move
    /// ok` fallback and discard that value, which makes closures passed to
    /// `@Result`/`@Option` `map`/`flatMap` useless. Any other tail (an explicit
    /// `return`, a `yield`/`break`, an `if`/`case`, …) keeps `emitBody`'s
    /// behavior so loop and block lambdas are unaffected.
    fn emitLambdaBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        if (body.len > 0) {
            const last = body[body.len - 1].expr;
            const is_value_tail = switch (last) {
                .literal, .identifier, .binaryOp, .unaryOp, .call, .useHook => true,
                else => false,
            };
            if (is_value_tail) {
                for (body[0 .. body.len - 1]) |stmt| try self.emitStmt(stmt);
                try self.lowerExprIntoX0(last);
                try self.emitReturn();
                return;
            }
        }
        try self.emitBody(body);
    }

    /// Emit a closure value into `{x, 0}` for the fun at `entry_label`:
    /// a `test_heap` reserving one fun cell (preserving `live` x-registers
    /// across the possible GC) followed by `make_fun3`. `make_fun2` is rejected
    /// by current OTP's `+from_asm` (`unknown_instruction`); `make_fun3` carries
    /// the destination register and a free-var list — empty here, since captures
    /// aren't supported (lambda bodies only see their own params), so `NumFree`
    /// is 0. Omitting the preceding `test_heap` fails the loader with
    /// `{heap_overflow, …, {wanted, {1, funs}}}`.
    fn emitMakeFun(self: *Emitter, entry_label: u32, live: u32) !void {
        try self.bodyPrint("    {{test_heap, {{alloc, [{{words, 0}}, {{floats, 0}}, {{funs, 1}}]}}, {d}}}.\n", .{@max(live, self.min_live)});
        try self.bodyPrint("    {{make_fun3, {{f, {d}}}, 0, 0, {{x, 0}}, {{list, []}}}}.\n", .{entry_label});
    }

    /// Lower a lambda `{ params -> body }` into a deferred BEAM function and
    /// emit the closure value at the call site (`emitMakeFun`). Result in
    /// `{x, 0}`. `live` is the number of x-registers the caller needs preserved
    /// across the closure's `test_heap` (args already materialised + params).
    fn lowerLambda(self: *Emitter, lam: anytype, live: u32) anyerror!void {
        const idx = self.lambda_count;
        self.lambda_count += 1;
        const arity: u32 = @intCast(lam.params.len);

        var name_buf: [256]u8 = undefined;
        const fun_name = try std.fmt.bufPrint(&name_buf, "'-{s}/{d}-fun-{d}-'", .{ self.cur_fn_name, self.cur_arity, idx });

        try self.reserveFn(fun_name, arity);
        const labels = try self.fnLabelsFor(fun_name, arity);

        var lam_buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &lam_buf.writer;

        const saved_reg_map = self.reg_map;
        self.reg_map = std.StringHashMap(Reg).init(self.alloc);
        const saved_y = self.next_y;
        const saved_num_y = self.num_y;
        const saved_arity = self.cur_arity;
        // The closure has its own register frame: the outer `min_live` floor (a
        // stashed `@Result`/arg scratch slot) doesn't apply here and would make
        // the closure's `gc_bif`s over-claim live registers (`not_live`).
        const saved_min_live = self.min_live;
        self.min_live = 0;

        self.next_y = 0;
        self.cur_arity = arity;
        self.num_y = self.precountLocals(lam.body);

        var x: u32 = 0;
        for (lam.params) |p| {
            try self.reg_map.put(p, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ fun_name, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, fun_name, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.emitFrame(arity);
        try self.emitLambdaBody(lam.body);

        self.reg_map.deinit();
        self.reg_map = saved_reg_map;
        self.next_y = saved_y;
        self.num_y = saved_num_y;
        self.cur_arity = saved_arity;
        self.min_live = saved_min_live;
        self.out = saved_out;

        try self.deferred_lambdas.append(self.alloc, try lam_buf.toOwnedSlice());
        lam_buf.deinit();

        try self.emitMakeFun(labels.entry, live);
    }

    /// Lower `try expr catch handler` → BEAM try/catch block.
    /// `try expr catch handler` → match the Result tuple `{ok, V}` / `{error, E}`
    /// with `is_tagged_tuple` (never BEAM try/catch). Ok unwraps element 1; Error
    /// runs the handler.
    fn lowerTryCatch(self: *Emitter, tc: anytype) anyerror!void {
        try self.lowerExprIntoX0(tc.expr.*);

        const err_label = self.allocLabel();
        const end_label = self.allocLabel();

        // {ok, V}: fall through and unwrap; otherwise jump to the Error branch.
        try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, [{{x, 0}}, 2, {{atom, ok}}]}}.\n", .{err_label});
        try self.bodyWrite("    {get_tuple_element, {x, 0}, 1, {x, 0}}.\n");
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});

        try self.bodyPrint("  {{label, {d}}}.\n", .{err_label});
        try self.lowerExprIntoX0(tc.handler.*);
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// Lower `start..end` → `lists:seq(Start, End)`. An open-ended range
    /// (`start..`) mirrors the Erlang backend and passes the atom `infinity`
    /// as the upper bound. Result list lands in `{x, 0}`.
    fn lowerRange(self: *Emitter, r: anytype) anyerror!void {
        // Materialize both bounds into scratch x-registers above the live
        // argument floor so neither clobbers the other while evaluating. Floor at
        // 1: a 0-arity fn (`main/0`) would otherwise stash `start` in `x0` and then
        // overwrite it computing `end` (`lists:seq(end-1, end-1)` → `[end-1]`).
        const base = @max(self.cur_arity, 1);

        try self.lowerExprIntoX0(r.start.*);
        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{base});

        if (r.end) |end| {
            // `a..b` is half-open `[a, b)` (parity with wasm/erlang/`Array.range`),
            // but `lists:seq/2` is inclusive — so the upper bound is `b - 1`.
            try self.lowerExprIntoX0(end.*);
            try self.bodyPrint("    {{gc_bif, '-', {{f, 0}}, {d}, [{{x, 0}}, {{integer, 1}}], {{x, 0}}}}.\n", .{@max(base + 1, self.min_live)});
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{base + 1});
        } else {
            try self.bodyPrint("    {{move, {{atom, infinity}}, {{x, {d}}}}}.\n", .{base + 1});
        }

        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{base});
        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 1}}}}.\n", .{base + 1});
        try self.bodyWrite("    {call_ext, 2, {extfunc, lists, seq, 2}}.\n");
    }

    /// Lower `lhs |> rhs`: evaluate lhs, then call rhs as function with result.
    fn lowerPipeline(self: *Emitter, pl: anytype) anyerror!void {
        try self.lowerExprIntoX0(pl.lhs.*);
        switch (pl.rhs.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |name| {
                    const labels = self.fnLabelsFor(name, 1) catch {
                        try self.bodyPrint("    %% unresolved pipeline fn: {s}/1\n", .{name});
                        return;
                    };
                    try self.bodyPrint("    {{call, 1, {{f, {d}}}}}.\n", .{labels.entry});
                },
                else => try self.bodyWrite("    %% unsupported pipeline rhs\n"),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    const scratch = self.cur_arity;
                    try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                    try self.materializeCallArgs(cc.args);
                    const total = cc.args.len + 1;
                    var i: usize = cc.args.len;
                    while (i > 0) : (i -= 1) {
                        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ i - 1, i });
                    }
                    try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
                    const labels = self.fnLabelsFor(cc.callee, total) catch {
                        try self.bodyPrint("    %% unresolved pipeline fn: {s}/{d}\n", .{ cc.callee, total });
                        return;
                    };
                    try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ total, labels.entry });
                },
                .pipeline => |inner_pl| {
                    try self.lowerPipeline(inner_pl);
                },
            },
            else => try self.bodyWrite("    %% unsupported pipeline rhs\n"),
        }
    }

    fn hasYieldOrBreakValue(body: []const ast.Stmt) bool {
        for (body) |stmt| {
            switch (stmt.expr) {
                .jump => |j| switch (j.kind) {
                    .yield => return true,
                    .@"break" => |v| if (v != null) return true,
                    else => {},
                },
                .branch => |b| switch (b.kind) {
                    .if_ => |i| {
                        if (hasYieldOrBreakValue(i.then_)) return true;
                        if (i.else_) |els| if (hasYieldOrBreakValue(els)) return true;
                    },
                    else => {},
                },
                else => {},
            }
        }
        return false;
    }

    fn lowerLoop(self: *Emitter, lp: anytype) anyerror!void {
        const has_map = hasYieldOrBreakValue(lp.body);

        const idx = self.lambda_count;
        self.lambda_count += 1;
        const arity: u32 = @intCast(lp.params.len);

        var name_buf: [256]u8 = undefined;
        const fun_name = try std.fmt.bufPrint(&name_buf, "'-{s}/{d}-fun-{d}-'", .{ self.cur_fn_name, self.cur_arity, idx });

        try self.reserveFn(fun_name, arity);
        const labels = try self.fnLabelsFor(fun_name, arity);

        var lam_buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &lam_buf.writer;

        const saved_reg_map = self.reg_map;
        self.reg_map = std.StringHashMap(Reg).init(self.alloc);
        const saved_y = self.next_y;
        const saved_num_y = self.num_y;
        const saved_arity = self.cur_arity;
        const saved_loop_flag = self.in_loop_lambda;
        const saved_min_live = self.min_live;
        self.min_live = 0;

        self.next_y = 0;
        self.cur_arity = arity;
        self.num_y = self.precountLocals(lp.body);
        self.in_loop_lambda = true;

        var x: u32 = 0;
        for (lp.params) |p| {
            try self.reg_map.put(p, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ fun_name, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, fun_name, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.emitFrame(arity);

        try self.emitBody(lp.body);

        self.reg_map.deinit();
        self.reg_map = saved_reg_map;
        self.next_y = saved_y;
        self.num_y = saved_num_y;
        self.cur_arity = saved_arity;
        self.in_loop_lambda = saved_loop_flag;
        self.min_live = saved_min_live;
        self.out = saved_out;

        try self.deferred_lambdas.append(self.alloc, try lam_buf.toOwnedSlice());
        lam_buf.deinit();

        // Materialize the iterable FIRST, then build the body closure into `x0`.
        // A range iterator lowers via a `lists:seq` *call* that clobbers
        // x-registers (and uses `cur_arity` as scratch), so stashing the fun in an
        // x-register beforehand would lose it (`lists:foreach([_],[_])`). Instead
        // the list lands in `x1` (and stays in `x0` too), so the closure's
        // `make_fun3` — which always writes `x0` — keeps the list live in `x1`.
        try self.lowerExprIntoX0(lp.iter.*);
        try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n");
        try self.emitMakeFun(labels.entry, 2);

        const func = if (has_map) "map" else "foreach";
        try self.bodyPrint("    {{call_ext, 2, {{extfunc, lists, {s}, 2}}}}.\n", .{func});
    }

    /// Emit a string literal as a BEAM binary into `{x, dest}`.
    /// For OTP 24+ the simplest approach is `{move, {literal, <<"str">>}, {x, D}}`.
    fn emitStringLiteral(self: *Emitter, s: []const u8, dest: u32) !void {
        try self.bodyPrint("    {{move, {{literal, <<\"", .{});
        for (s) |c| switch (c) {
            '"' => try self.bodyWrite("\\\""),
            '\\' => try self.bodyWrite("\\\\"),
            '\n' => try self.bodyWrite("\\n"),
            '\r' => try self.bodyWrite("\\r"),
            '\t' => try self.bodyWrite("\\t"),
            else => try self.out.writeByte(c),
        };
        try self.bodyPrint("\">>}}, {{x, {d}}}}}.\n", .{dest});
    }

    /// Lower `receiver.member` into `{x, dest}` via `{get_map_elements, ...}`.
    /// The receiver is evaluated into x0, then the field is extracted.
    fn lowerIdentAccess(self: *Emitter, ia: anytype, dest: u32) anyerror!void {
        try self.lowerExprIntoX0(ia.receiver.*);

        // `t._N` is a tuple-element access (`#(a, b)._0`), not a map field. Use the
        // runtime-checked `erlang:element(N+1, T)` BIF (1-based) rather than
        // `get_tuple_element`: the receiver is typed `any` (an assoc-fn param /
        // cross-module result), and `is_tuple` alone leaves the arity unknown, so
        // `get_tuple_element` fails the loader (`bad_type, needed t_tuple,1`).
        if (tupleIndexMember(ia.member)) |idx| {
            try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n"); // tuple → x1
            try self.bodyPrint("    {{move, {{integer, {d}}}, {{x, 0}}}}.\n", .{idx + 1}); // index → x0
            try self.bodyWrite("    {call_ext, 2, {extfunc, erlang, element, 2}}.\n");
            if (dest != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{dest});
            return;
        }

        var member_buf: [256]u8 = undefined;
        const member = try atomName(ia.member, &member_buf);

        // Optional chaining (`recv?.member`): short-circuit to `undefined` when
        // the receiver is absent — parity with the erlang backend's guarding
        // immediate fun. A chain (`a?.b?.c`) composes because each link reads
        // the prior result from `{x, 0}` and propagates `undefined`. A non-map
        // or missing-key receiver also yields `undefined` (JS `?.` semantics).
        if (ia.optional) {
            const present_l = self.allocLabel();
            const undef_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, undefined}}]}}.\n", .{present_l});
            // Receiver IS `undefined` (test fell through) → result is `undefined`.
            try self.bodyPrint("    {{move, {{atom, undefined}}, {{x, {d}}}}}.\n", .{dest});
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{present_l});
            try self.bodyPrint("    {{test, is_map, {{f, {d}}}, [{{x, 0}}]}}.\n", .{undef_l});
            try self.bodyPrint(
                "    {{get_map_elements, {{f, {d}}}, {{x, 0}}, {{list, [{{atom, {s}}}, {{x, {d}}}]}}}}.\n",
                .{ undef_l, member, dest },
            );
            try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_l});
            try self.bodyPrint("  {{label, {d}}}.\n", .{undef_l});
            try self.bodyPrint("    {{move, {{atom, undefined}}, {{x, {d}}}}}.\n", .{dest});
            try self.bodyPrint("  {{label, {d}}}.\n", .{end_l});
            return;
        }

        const fail_label = self.allocLabel();
        // Refine x0's type to map before reading a field. A locally-built map is
        // already typed, but a receiver returned from a cross-module `call_ext`
        // (`Response.ok(...)`) is typed `any` — the BEAM loader then rejects a
        // bare `get_map_elements` (`bad_type, needed t_map`). The `is_map` test
        // narrows it; on failure both fall through past the read.
        try self.bodyPrint("    {{test, is_map, {{f, {d}}}, [{{x, 0}}]}}.\n", .{fail_label});
        try self.bodyPrint(
            "    {{get_map_elements, {{f, {d}}}, {{x, 0}}, {{list, [{{atom, {s}}}, {{x, {d}}}]}}}}.\n",
            .{ fail_label, member, dest },
        );
        try self.bodyPrint("  {{label, {d}}}.\n", .{fail_label});
    }

    /// Render a "simple" expression (literal number or identifier already
    /// mapped to a register) as a BEAM term in `buf`. Returns the rendered
    /// slice or null if the expression is too complex.
    fn simpleTerm(self: *Emitter, e: ast.Expr, buf: []u8) !?[]const u8 {
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.reg_map.get(n)) |reg| {
                        return try reg.format(buf);
                    }
                    return null;
                },
                else => return null,
            },
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    return try formatNumberInto(buf, n);
                },
                .null_ => return try std.fmt.bufPrint(buf, "{{atom, nil}}", .{}),
                else => return null,
            },
            .unaryOp => |un| switch (un.op) {
                .neg => switch (un.expr.*) {
                    .literal => |lit| switch (lit.kind) {
                        .numberLit => |n| return try formatNegNumberInto(buf, n),
                        else => return null,
                    },
                    else => return null,
                },
                else => return null,
            },
            else => return null,
        }
    }
};

/// True when `name` is a valid *unquoted* Erlang atom: a lowercase letter
/// followed by letters, digits, `_` or `@`. Anything else must be single-quoted
/// in the `.S` term syntax — notably PascalCase enum tags (`Circle`), which the
/// assembler would otherwise parse as an Erlang *variable* (`{atom, Circle}` →
/// `bad term`).
fn isUnquotedAtom(name: []const u8) bool {
    if (name.len == 0) return false;
    if (!(name[0] >= 'a' and name[0] <= 'z')) return false;
    for (name[1..]) |c| {
        if (!(std.ascii.isAlphanumeric(c) or c == '_' or c == '@')) return false;
    }
    return true;
}

/// Render `name` as the inner text of an `{atom, _}` term, single-quoting and
/// escaping it when it isn't a valid unquoted atom. Lowercase names pass through
/// unchanged (so `{atom, ok}` stays `ok`). `buf` must be large enough for the
/// quotes and any escaped characters (2*name.len + 2).
fn atomName(name: []const u8, buf: []u8) ![]const u8 {
    // Already single-quoted (e.g. a pre-mangled `'Owner_method'`) — leave as-is
    // so we don't double-quote it.
    if (name.len > 0 and name[0] == '\'') return name;
    if (isUnquotedAtom(name)) return name;
    var i: usize = 0;
    buf[i] = '\'';
    i += 1;
    for (name) |c| {
        if (c == '\'' or c == '\\') {
            buf[i] = '\\';
            i += 1;
        }
        buf[i] = c;
        i += 1;
    }
    buf[i] = '\'';
    i += 1;
    return buf[0..i];
}

/// A comparison lowered to a BEAM `test` instruction: the opcode plus whether
/// the operands must be swapped.
const CmpTest = struct { opcode: []const u8, swap: bool };

/// Map a comparison operator to a *valid* BEAM test instruction. BEAM provides
/// only `is_lt` and `is_ge` for ordering — there is no `is_gt`/`is_le` opcode
/// (`beam_opcodes:opcode(is_gt, _)` fails to assemble), so `>` and `<=` are
/// emitted as `is_lt`/`is_ge` with the operands swapped. Returns null for
/// operators that are not comparisons.
fn comparisonTestOp(op: anytype) ?CmpTest {
    return switch (op) {
        .lt => .{ .opcode = "is_lt", .swap = false },
        .gt => .{ .opcode = "is_lt", .swap = true },
        .lte => .{ .opcode = "is_ge", .swap = true },
        .gte => .{ .opcode = "is_ge", .swap = false },
        .eq => .{ .opcode = "is_eq", .swap = false },
        .ne => .{ .opcode = "is_ne_exact", .swap = false },
        else => null,
    };
}

/// Render a numeric literal into `buf`. Returns the populated slice.
fn formatNumberInto(buf: []u8, n: []const u8) ![]const u8 {
    var has_dot = false;
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') {
        has_dot = true;
        break;
    };
    if (has_dot) {
        return std.fmt.bufPrint(buf, "{{float, {s}}}", .{n});
    }
    return std.fmt.bufPrint(buf, "{{integer, {s}}}", .{n});
}

/// Render the negation of a numeric literal as `{integer, -N}` / `{float, -F}`.
fn formatNegNumberInto(buf: []u8, n: []const u8) ![]const u8 {
    var has_dot = false;
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') {
        has_dot = true;
        break;
    };
    if (has_dot) {
        return std.fmt.bufPrint(buf, "{{float, -{s}}}", .{n});
    }
    return std.fmt.bufPrint(buf, "{{integer, -{s}}}", .{n});
}
