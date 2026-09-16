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
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const prelude = @import("std_prelude");
const primOpTemplate = @import("../comptime/primOpTemplate.zig");
const erlEmitter = @import("./beam/erl_emitter.zig");
const beamEmitter = @import("./beam/beam_emitter.zig");
/// Instruction operand / destination shorthands — every `.S` line this backend
/// writes is built from these and rendered by `beam_emitter.zig`; the backend
/// never formats target text itself.
const Op = beamEmitter.Operand;
const Dst = beamEmitter.Dest;
const Term = @import("./beam/term.zig").Term;

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;
const CrossModule = crossModule.CrossModule;

/// §A5 annotation-driven prim-method dispatch entry shared with the erlang
/// backend (same data, different consumer). Parsed from
/// `@external(erlang, "mod", "sym[(args)]")` on a primitive interface method.
/// `arity_branches` (`prim-op-annotation`) is non-empty when the annotation
/// carries `when($argc == N): "..."` clauses; BEAM short-circuits these
/// (still owned by the inline switch below).
const PrimErlangCall = struct {
    module: []const u8,
    symbol: []const u8,
    args: ?[]const []const u8,
    arity_branches: []const ast.ArityBranch = &.{},
};

/// Map a primitive `PrimKind` to its controller interface name in
/// `primitives.d.bp`. The BEAM dispatcher only handles three kinds (`Array`,
/// `String`, `Bool`); numeric methods are not yet lowered on BEAM (recorded as
/// a backend limit, falls through to the value-receiver path).
fn primIfaceForKind(k: envMod.PrimKind) ?[]const u8 {
    return switch (k) {
        .array => "Array",
        .string => "String",
        .bool => "Bool",
        else => null,
    };
}

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

/// Marker kinds emitted by `transform.zig::tryLowerFutureJump`.
const FutureWrapKindBeam = enum { resolved, rejected };

/// Recognise the `__bp_future_resolved(<t>)` / `__bp_future_rejected(<e>)`
/// builtin marker calls so the BEAM return emitter can strip them back to
/// the eager-lowering shape (mirrors erlang.zig). The promise wrap is
/// implicit in BEAM's sync rendering.
fn futureWrapCallNameBeam(e: ast.Expr) ?FutureWrapKindBeam {
    if (e != .call) return null;
    if (e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (!c.is_builtin or c.args.len != 1) return null;
    if (std.mem.eql(u8, c.callee, "__bp_future_resolved")) return .resolved;
    if (std.mem.eql(u8, c.callee, "__bp_future_rejected")) return .rejected;
    return null;
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
        // One extra slot: the tuple itself is parked on the stack while
        // `erlang:element/2` is called once per binding (a `call_ext` frees
        // every x-register, so an x-scratch would not survive the first one).
        .tuple_ => |bindings| @intCast(bindings.len + 1),
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
            .@"break" => |v| if (v.value) |vv| countLocalsInExpr(vv.*, count),
            .yield => |y| if (y.value) |v| countLocalsInExpr(v.*, count),
            .try_ => |v| if (v) |vv| countLocalsInExpr(vv.*, count),
            else => {},
        },
        .collection => |col| switch (col.kind) {
            .recordLit => |rl| for (rl.fields) |f| countLocalsInExpr(f.value.*, count),
            .interfaceLit => |il| for (il.fields) |f| countLocalsInExpr(f.value.*, count),
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
                        .comptime_trace = try comptimeMod.trace.renderAlloc(alloc, ok.comptime_traces),
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
    try em.collectPrimErlangDispatch(program);
    // §D2 — record every `import {<name>} from "std"` so a qualified call like
    // `math.floor(x)` lowers to a remote `math:floor(X)` instead of falling
    // through to the value-receiver path (parity with the erlang backend).
    try em.collectStdImports(program);

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
            .comment => |c| try beamEmitter.writeSourceComment(em.out, .{
                .level = if (c.is_module) .module else if (c.is_doc) .doc else .line,
                .text = c.text,
            }),
            .record => |r| try em.emitRecord(r),
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
    //
    // NB — BIF auto-import shadowing (parity note with `erlang.zig`):
    // the source backend emits `-compile({no_auto_import,[fn/arity, …]}).`
    // in the module prelude when a user fn shadows an auto-imported BIF
    // (see `loadAutoImportedBifsFromPrelude` in `erlang.zig`). The BEAM
    // assembly form does not need the directive: calls are already
    // disambiguated — local calls reference labels (`{call, N, {f, X}}`)
    // and remote calls carry an explicit `{extfunc, mod, fn, N}` triple,
    // so there is no name-resolution stage that could prefer a BIF over a
    // user fn. The `erlc +from_asm` pipeline does not re-resolve names.
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

    /// The instruction operand this binding reads/writes.
    fn operand(self: Reg) beamEmitter.Operand {
        return switch (self) {
            .x => |n| beamEmitter.Operand.xr(n),
            .y => |n| beamEmitter.Operand.yr(n),
        };
    }

    /// The destination form of the same register.
    fn dest(self: Reg) beamEmitter.Dest {
        return switch (self) {
            .x => |n| beamEmitter.Dest.xr(n),
            .y => |n| beamEmitter.Dest.yr(n),
        };
    }
};

fn fnKey(alloc: std.mem.Allocator, name: []const u8, arity: usize) ![]u8 {
    return std.fmt.allocPrint(alloc, "{s}/{d}", .{ name, arity });
}

fn hasExternalInline(annotations: []const ast.Annotation, target: []const u8) bool {
    for (annotations) |a| {
        if (!std.mem.startsWith(u8, a.name, "External.")) continue;
        if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
        if (a.args.len == 0) continue;
        if (std.mem.eql(u8, a.args[a.args.len - 1], "true")) return true;
    }
    return false;
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
    /// Nullary enum variant names (`Lt`, `Ok`, …) declared in this module. A
    /// bare `.ident` case pattern naming one is a match test against the
    /// variant atom; anything else is a binding. Populated by
    /// `collectRecordShapes`.
    enum_variants: std.StringHashMap(void),
    /// Interface associated `default fn` qualified names (`"Array.range"`). Pure
    /// botopink, emitted as local mangled fns (`'Array_range'`) since the
    /// interface decl is inlined into each consuming module; an
    /// `Interface.method(...)` call resolves to that local fn, not a remote
    /// `array:range`. Populated by `collectInterfaces`.
    interface_assoc: std.StringHashMap(void),
    /// §A5 annotation-driven prim-method dispatch (parity with the erlang
    /// emitter): `<Iface>.<method>` → `(host module, host symbol, ordered arg
    /// names)`. The BEAM dispatcher uses the template shape to pick a register
    /// layout (`primRecvOnly` / `primFunThenList` / `primRecvThenArgs`); only
    /// the irreducible cases (`++` ops, inline funs, BIF aliases) stay in the
    /// `emitPrimMethod` switch fallback.
    prim_erlang_dispatch: std.StringHashMap(PrimErlangCall),
    /// §A6 BEAM-target template bodies (v0.beta.22 front 03). `<Iface>.<method>`
    /// → multi-line `.S` body string with `$self` / `$0..$N` / `$args` markers.
    /// Populated from `#[@External.Beam("""…""")]` (or legacy `external(beam,
    /// """…""")`) annotations on primitive interface methods. The BEAM dispatch
    /// path (`tryEmitPrimAnnotation`) consults this map FIRST — when an entry
    /// exists, the template wins over both the inline `emitPrimMethod` arm and
    /// any erlang-derived dispatch in `prim_erlang_dispatch`. Substitution
    /// convention: `$self` → `{x, 0}`, `$N` → `{x, N+1}`, `$args` → the
    /// comma-separated `{x, 1..N}` list. The consumer pre-loads `recv` into
    /// `x0` and each positional arg into `x_{i+1}` before rendering.
    prim_beam_templates: std.StringHashMap([]const u8),
    /// §D2 — modules imported from the `"std"` package (e.g. `import {math}
    /// from "std"` → `"math"`). A qualified call whose receiver is in this
    /// set lowers to a remote `call_ext` into the lowercase module atom,
    /// parity with the erlang backend's `std_imports` path.
    std_imports: std.StringHashMap(void),

    /// Lazily-emitted synth helper fns for the inline prim methods that need
    /// register stashing across calls — `xs.at(i)` (bounds-safe `lists:nth`
    /// + `undefined` fallback), `xs.indexOf(item)` (recursive linear scan),
    /// `xs.join(sep)` per-element stringify fun. Each is emitted into
    /// `deferred_lambdas` the first time it is referenced; the cached name
    /// (heap-owned, freed in `deinit`) is reused for every subsequent call
    /// site so the synth body lands once per module.
    at_helper_name: ?[]const u8 = null,
    indexOf_helper_name: ?[]const u8 = null,
    stringify_helper_name: ?[]const u8 = null,

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
            .enum_variants = std.StringHashMap(void).init(alloc),
            .interface_assoc = std.StringHashMap(void).init(alloc),
            .prim_erlang_dispatch = std.StringHashMap(PrimErlangCall).init(alloc),
            .prim_beam_templates = std.StringHashMap([]const u8).init(alloc),
            .std_imports = std.StringHashMap(void).init(alloc),
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
        self.enum_variants.deinit();
        var ia = self.interface_assoc.keyIterator();
        while (ia.next()) |k| self.alloc.free(k.*);
        self.interface_assoc.deinit();
        var dit = self.prim_erlang_dispatch.iterator();
        while (dit.next()) |entry| {
            self.alloc.free(entry.key_ptr.*);
            self.alloc.free(entry.value_ptr.module);
            self.alloc.free(entry.value_ptr.symbol);
            if (entry.value_ptr.args) |args| {
                for (args) |a| self.alloc.free(a);
                self.alloc.free(args);
            }
            for (entry.value_ptr.arity_branches) |b| self.alloc.free(b.template);
            if (entry.value_ptr.arity_branches.len > 0) self.alloc.free(entry.value_ptr.arity_branches);
        }
        self.prim_erlang_dispatch.deinit();
        var bt = self.prim_beam_templates.iterator();
        while (bt.next()) |entry| {
            self.alloc.free(entry.key_ptr.*);
            self.alloc.free(entry.value_ptr.*);
        }
        self.prim_beam_templates.deinit();
        self.std_imports.deinit();
        if (self.at_helper_name) |n| self.alloc.free(n);
        if (self.indexOf_helper_name) |n| self.alloc.free(n);
        if (self.stringify_helper_name) |n| self.alloc.free(n);
    }

    /// §A5: collect `@external(erlang, …)` annotations on primitive interface
    /// methods into `prim_erlang_dispatch`. Scans `program.decls` first and
    /// reparses the embedded `primitives.d.bp` so the table sees every prim
    /// interface (`Array`/`String`/`Bool`) even when none made it into the
    /// transformed program. Mirrors the erlang backend's collector — the same
    /// `PrimErlangCall` type drives both, but the dispatcher in each backend
    /// translates the template shape into its own emission convention.
    fn collectPrimErlangDispatch(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| {
            if (decl != .interface) continue;
            try self.collectIfaceErlangDispatch(decl.interface);
        }
        var arena = std.heap.ArenaAllocator.init(self.alloc);
        defer arena.deinit();
        const alloc_arena = arena.allocator();
        var lx = lexerMod.Lexer.init(prelude.primitives);
        const tokens = lx.scanAll(alloc_arena) catch return;
        var p = parserMod.Parser.init(tokens);
        var prim_program = p.parse(alloc_arena) catch return;
        defer prim_program.deinit(alloc_arena);
        for (prim_program.decls) |decl| {
            if (decl != .interface) continue;
            try self.collectIfaceErlangDispatch(decl.interface);
        }
    }

    fn collectIfaceErlangDispatch(self: *Emitter, iface: ast.InterfaceDecl) !void {
        var slots: [16][]const u8 = undefined;
        for (iface.methods) |m| {
            // §A6 BEAM-target template path (v0.beta.22 front 03): an
            // `@External.Beam("""…""")` annotation with a single body arg
            // (the template form — `bref.module.len == 0`) wins over the
            // erlang-derived dispatch + the inline `emitPrimMethod` switch.
            // The body lands in `prim_beam_templates` keyed on `<Iface>.<m>`;
            // `tryEmitPrimAnnotation` renders it after pre-loading recv into
            // `{x, 0}` and each positional arg into `{x, i+1}`. The 2-body-arg
            // form `@External.Beam("mod", "sym")` is the legacy host-call
            // shape — it stays out of `prim_beam_templates` and flows through
            // the erlang/dispatch path's bare-symbol case (same call_ext
            // shape). `looksLikeTemplate` is NOT the discriminator here: many
            // valid BEAM bodies (e.g. a single `{call_ext, ...}.` for a
            // 0-arg method) carry no `$`-marker yet are still template form.
            if (m.externalFor("beam")) |bref| {
                if (bref.module.len == 0 and
                    !hasExternalInline(m.annotations, "beam"))
                {
                    const bkey = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ iface.name, m.name });
                    if (self.prim_beam_templates.contains(bkey)) {
                        self.alloc.free(bkey);
                    } else {
                        try self.prim_beam_templates.put(bkey, try self.alloc.dupe(u8, bref.symbol));
                    }
                }
            }
            // `prim-op-annotation` arity-branch entries are stored verbatim
            // here too — `tryEmitPrimAnnotation` short-circuits on them so
            // BEAM's inline switch keeps owning the lowering (slice etc).
            if (ast.externalHasArityBranches(m.annotations, "erlang")) {
                if (hasExternalInline(m.annotations, "erlang") or
                    hasExternalInline(m.annotations, "beam")) continue;
                const key = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ iface.name, m.name });
                if (self.prim_erlang_dispatch.contains(key)) {
                    self.alloc.free(key);
                    continue;
                }
                var branches: std.ArrayList(ast.ArityBranch) = .empty;
                errdefer branches.deinit(self.alloc);
                for (m.annotations) |a| {
                    if (!std.mem.startsWith(u8, a.name, "External.") or !std.ascii.eqlIgnoreCase(a.name["External.".len..], "erlang")) continue;
                    for (a.args) |raw| {
                        const b = ast.parseArityBranchArg(raw) orelse continue;
                        try branches.append(self.alloc, .{
                            .argc = b.argc,
                            .template = try self.alloc.dupe(u8, b.template),
                        });
                    }
                }
                try self.prim_erlang_dispatch.put(key, .{
                    .module = "",
                    .symbol = "",
                    .args = null,
                    .arity_branches = try branches.toOwnedSlice(self.alloc),
                });
                continue;
            }
            const ref = m.externalFor("erlang") orelse continue;
            // BEAM reads the erlang annotation as its source of truth (no
            // separate `@external(beam, …)` is used in `primitives.d.bp`), so
            // either an `inline: true` on the erlang annotation OR on an
            // explicit beam one marks the method irreducible on BEAM.
            if (hasExternalInline(m.annotations, "erlang") or
                hasExternalInline(m.annotations, "beam")) continue;
            const key = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ iface.name, m.name });
            if (self.prim_erlang_dispatch.contains(key)) {
                self.alloc.free(key);
                continue;
            }
            const tmpl = ast.parseExternalCallTemplate(ref.symbol, &slots);
            const owned_args: ?[][]const u8 = if (tmpl.args) |args| blk: {
                const out = try self.alloc.alloc([]const u8, args.len);
                for (args, 0..) |a, i| out[i] = try self.alloc.dupe(u8, a);
                break :blk out;
            } else null;
            try self.prim_erlang_dispatch.put(key, .{
                .module = try self.alloc.dupe(u8, ref.module),
                .symbol = try self.alloc.dupe(u8, tmpl.symbol),
                .args = owned_args,
            });
        }
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

    /// §D2 — record every module name imported from the `"std"` package, so a
    /// qualified call `<mod>.<callee>(args)` whose receiver names one lowers
    /// to a remote `call_ext` into that module atom. Parity with the erlang
    /// backend's `collectStdImports`.
    fn collectStdImports(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .use => |u| {
                const from_std = switch (u.source) {
                    .module => |m| std.mem.eql(u8, m, "std"),
                    .root => false,
                };
                if (!from_std) continue;
                for (u.imports) |imp| {
                    try self.std_imports.put(imp.segments[imp.segments.len - 1], {});
                }
            },
            else => {},
        };
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
            // A nullary enum variant is an atom, so a bare `Lt ->` case arm is a
            // *test* against that atom, not a binding. Parity with the erlang
            // backend's `enum_variants` (`erlang.zig` `collectTypeShapes`).
            .@"enum" => |e| for (e.variants) |v| try self.enum_variants.put(v.name, {}),
            else => {},
        };
        const xc = self.cross orelse return;
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const name = imp.name();
                const info = xc.exports.get(name) orelse continue;
                switch (info.kind) {
                    .record => {},
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

    // ── per-fn state ─────────────────────────────────────────────────────────

    fn resetFnState(self: *Emitter, arity: u32) void {
        self.reg_map.clearRetainingCapacity();
        self.next_y = 0;
        self.num_y = 0;
        self.cur_arity = arity;
        self.min_live = 0;
    }

    /// First x-register free for staging an operand.
    ///
    /// `{x, 0}` is the universal result register — every `lowerExprIntoX0`
    /// writes it — so a scratch slot may never be `{x, 0}`. Above that, the
    /// only x-registers holding a live value are the ones the *enclosing*
    /// lowering has already staged, which it records by raising `min_live`
    /// (a BEAM `Live` count: `x0..x_{min_live-1}` are live). Parameters are
    /// spilled to y-slots by `bindParams`, so `cur_arity` no longer describes
    /// any live x-register and must not be used as a scratch base.
    fn scratchBase(self: *const Emitter) u32 {
        return @max(self.min_live, 1);
    }

    /// Raise the live-register floor to `live` for the duration of a nested
    /// lowering, returning the previous floor for the caller to restore. A
    /// floor of 0 (nothing staged yet) is left untouched: claiming `{x, 0}`
    /// live before anything has written it trips the loader's
    /// `uninitialized_reg` check.
    fn raiseLive(self: *Emitter, live: u32) u32 {
        const saved = self.min_live;
        if (live > 0) self.min_live = @max(self.min_live, live);
        return saved;
    }

    /// Bind the incoming parameters to y-slots (`y0..y{n-1}`) and reserve the
    /// local slots after them.
    ///
    /// BEAM x-registers are both caller-clobbered (every `call` destroys them)
    /// and the codegen's only expression destination, so a parameter left in
    /// `{x, i}` dies the first time the body evaluates *anything*: a field read
    /// (`self.x` lands in `{x, 0}`, overwriting `self`), a nested call, a
    /// staged `gc_bif` operand. Copying every parameter into a stack slot right
    /// after `allocate` makes the whole x-file free scratch and is what keeps
    /// `Vec2_lengthSq(self)` able to read `self.y` after `self.x`.
    ///
    /// Must be called after `num_y` is known and before the body is emitted;
    /// `emitParamSpill` writes the actual `{move, {x, i}, {y, i}}` prologue
    /// after `emitFrame`.
    fn bindParams(self: *Emitter, names: []const []const u8) !void {
        for (names, 0..) |n, i| {
            try self.reg_map.put(n, .{ .y = @intCast(i) });
        }
        self.next_y = @intCast(names.len);
    }

    /// Collect the declared parameter names (in order) into `buf` — the input
    /// `bindParams` takes, for the param lists that carry a `.name` field.
    fn paramNames(params: anytype, buf: [][]const u8) []const []const u8 {
        var n: usize = 0;
        for (params) |p| {
            if (n == buf.len) break;
            buf[n] = p.name;
            n += 1;
        }
        return buf[0..n];
    }

    /// Emit the `{move, {x, i}, {y, i}}` prologue that backs `bindParams`.
    fn emitParamSpill(self: *Emitter, count: usize) !void {
        for (0..count) |i| {
            try beamEmitter.writeMoveOp(self.out, Op.xr(i), Dst.yr(i));
        }
    }

    /// Count the y-slots needed for a function body: one slot per `localBind`.
    /// Conservative: every `val` gets a slot even when its lifetime ends
    /// before a call. Refining this is Fase 9 (polish).
    fn precountLocals(_: *Emitter, body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        countLocalsRec(body, &n);
        return n;
    }

    /// `precountLocals` for a bare expression (a top-level `val`'s value).
    fn precountLocalsInExpr(_: *Emitter, e: ast.Expr) u32 {
        var n: u32 = 0;
        countLocalsInExpr(e, &n);
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

        // Params arrive in `x0..x{arity-1}` and are spilled to `y0..y{arity-1}`
        // by the prologue below (see `bindParams`).
        var names_buf: [64][]const u8 = undefined;
        var nparams: usize = 0;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            if (nparams == names_buf.len) break;
            names_buf[nparams] = p.name;
            nparams += 1;
        }
        self.num_y = @as(u32, @intCast(nparams)) + self.precountLocals(f.body);
        try self.bindParams(names_buf[0..nparams]);

        try beamEmitter.writeBlankLine(self.out);
        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. The BEAM model is processes +
        // message passing (spawn/receive); this backend currently emits the
        // eager body, with full process-based lowering left as future work.
        if (f.effect != null and f.effect.? != .result) {
            try beamEmitter.writeTopComment(self.out, "#[@future] / #[@asyncGenerator] — eager lowering", .{});
        }
        var fn_buf: [256]u8 = undefined;
        const fn_atom = try atomName(f.name, &fn_buf);
        try beamEmitter.writeFunctionHeader(self.out, fn_atom, arity, entry_label);
        try beamEmitter.writeLabel(self.out, func_info_label);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, fn_atom, arity);
        try beamEmitter.writeLabel(self.out, entry_label);

        try self.emitFrame(arity);
        try self.emitParamSpill(nparams);

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
        var names_buf: [64][]const u8 = undefined;
        const names = paramNames(m.params, &names_buf);
        self.num_y = @as(u32, @intCast(names.len)) + self.precountLocals(m.body.?);
        try self.bindParams(names);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, mangled, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, mangled, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);

        try self.emitFrame(arity);
        try self.emitParamSpill(names.len);

        self.cur_line += 1;
        try self.emitBody(m.body.?);
    }

    fn emitImplementMethod(self: *Emitter, qualifier: []const u8, m: ast.ImplementMethod) !void {
        const arity = implementMethodArity(m);
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ qualifier, m.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        var names_buf: [64][]const u8 = undefined;
        const names = paramNames(m.params, &names_buf);
        self.num_y = @as(u32, @intCast(names.len)) + self.precountLocals(m.body);
        try self.bindParams(names);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, mangled, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, mangled, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);

        try self.emitFrame(arity);
        try self.emitParamSpill(names.len);

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
        self.num_y = 1 + self.precountLocals(g.body);
        try self.bindParams(&.{g.selfParam.name});

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, mangled, 1, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, mangled, 1);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(1);
        try self.emitParamSpill(1);
        self.cur_line += 1;
        try self.emitBody(g.body);
    }

    fn emitSetter(self: *Emitter, owner: []const u8, s: anytype) !void {
        const arity = s.params.len;
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, s.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        var names_buf: [64][]const u8 = undefined;
        const names = paramNames(s.params, &names_buf);
        self.num_y = @as(u32, @intCast(names.len)) + self.precountLocals(s.body);
        try self.bindParams(names);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, mangled, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, mangled, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(arity);
        try self.emitParamSpill(names.len);
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

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, v.name, 0, entry_label);
        try beamEmitter.writeLabel(self.out, func_info_label);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, v.name, 0);
        try beamEmitter.writeLabel(self.out, entry_label);
        self.cur_line += 1;

        // `emitReturn` always emits `{deallocate, NumY}`, so the frame has to
        // exist even for a `val` whose value needs no stack slot — a bare
        // `{deallocate, 0}` is rejected by the loader with `{allocated, none}`
        // as soon as the function is reachable.
        self.num_y = self.precountLocalsInExpr(v.value.*);
        try self.emitFrame(0);
        try self.lowerExprIntoX0(v.value.*);
        try self.emitReturn();
    }

    /// Emit `return.`, preceded by `{deallocate, N}.` when the current function
    /// owns a y-stack frame.
    fn emitReturn(self: *Emitter) !void {
        try beamEmitter.writeDeallocate(self.out, self.num_y);
        try beamEmitter.writeReturn(self.out);
    }

    /// Emit the function-prologue `{allocate, NumY, Arity}` for the current
    /// frame, followed by `{init_yregs, …}` nilling every y-slot when the frame
    /// has any. BEAM requires each allocated y-slot to hold a valid term before
    /// the next GC point (a call or `gc_bif`); a slot written only on a later
    /// branch would otherwise be flagged `{uninitialized_reg, {y, k}}` by the
    /// loader. (`allocate_zero` was the old shorthand for this but no longer
    /// assembles on current OTP.)
    fn emitFrame(self: *Emitter, arity: usize) !void {
        try beamEmitter.writeAllocate(self.out, self.num_y, arity);
        if (self.num_y > 0) try beamEmitter.writeInitYregs(self.out, self.num_y);
    }

    // ── entrypoint wrappers when main/0 exists ───────────────────────────────

    fn emitEntrypointWrappers(self: *Emitter) !void {
        const wrapper = try self.fnLabelsFor("'_botopink_main'", 0);
        const main1 = try self.fnLabelsFor("main", 1);
        const main0 = try self.fnLabelsFor("main", 0);

        // '_botopink_main'/0 → tail-calls main/0.
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, "'_botopink_main'", 0, wrapper.entry);
        try beamEmitter.writeLabel(self.out, wrapper.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, "'_botopink_main'", 0);
        try beamEmitter.writeLabel(self.out, wrapper.entry);
        try beamEmitter.writeCall(self.out, .only, 0, .{ .local = main0.entry }, 0);
        self.cur_line += 1;

        // main/1 → discards argv and tail-calls _botopink_main/0.
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, "main", 1, main1.entry);
        try beamEmitter.writeLabel(self.out, main1.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, "main", 1);
        try beamEmitter.writeLabel(self.out, main1.entry);
        try beamEmitter.writeCall(self.out, .only, 0, .{ .local = wrapper.entry }, 0);
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
            try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
            try self.emitReturn();
        }
    }

    fn emitStmt(self: *Emitter, stmt: ast.Stmt) anyerror!void {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| {
                        // §1F F4F-T2 — `#[@future]` eager lowering on BEAM:
                        // strip the `__bp_future_resolved(<t>)` marker back
                        // to its inner value, and lower `__bp_future_rejected(<e>)`
                        // as `erlang:throw(<e>)` (mirrors the erlang.zig path).
                        if (futureWrapCallNameBeam(val.*)) |kind| {
                            const inner_arg = val.*.call.kind.call.args[0].value.*;
                            switch (kind) {
                                .resolved => {
                                    try self.lowerExprIntoX0(inner_arg);
                                    try self.emitReturn();
                                },
                                .rejected => {
                                    try self.lowerExprIntoX0(inner_arg);
                                    try beamEmitter.writeCall(self.out, .only, 1, .{ .ext = .{ .module = "erlang", .function = "throw" } }, 0);
                                },
                            }
                            return;
                        }
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
                        try beamEmitter.writeMoveOp(self.out, Op.atom("undef"), Dst.xr(0));
                    }
                    try beamEmitter.writeCall(self.out, .only, 1, .{ .ext = .{ .module = "erlang", .function = "throw" } }, 0);
                },
                .@"break" => |br| {
                    if (br.value) |v| {
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
                    try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
                    try self.emitReturn();
                },
                else => |k| try beamEmitter.writeComment(self.out, "unsupported jump: {s}", .{@tagName(k)}),
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
                // `is_map` first: the subject is typed `any` whenever it comes
                // from a call, and the loader rejects a bare `get_map_elements`
                // on an untyped register (`bad_type, needed t_map`). Same
                // narrowing `lowerIdentAccess` does for a field read.
                const scratch = self.scratchBase();
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                const not_map = self.allocLabel();
                const done = self.allocLabel();
                const first_y = self.next_y;
                try beamEmitter.writeTest(self.out, .is_map, not_map, &.{Op.xr(scratch)});
                for (n.fields) |fld| {
                    const fail = self.allocLabel();
                    try beamEmitter.writeGetMapElements(self.out, fail, Op.xr(scratch), fld.field_name, Dst.xr(0));
                    try beamEmitter.writeLabel(self.out, fail);
                    const y_idx = self.next_y;
                    self.next_y += 1;
                    try self.reg_map.put(fld.bind_name, .{ .y = y_idx });
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                }
                // The not-a-map arm has to write every binding slot too: the
                // validator merges both paths and rejects a later read of a slot
                // one of them left unwritten (`{unassigned, {y, 1}}`) — the
                // function-entry `init_yregs` does not satisfy it.
                try beamEmitter.writeJump(self.out, done);
                try beamEmitter.writeLabel(self.out, not_map);
                for (0..n.fields.len) |k| {
                    try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.yr(first_y + k));
                }
                try beamEmitter.writeLabel(self.out, done);
                try beamEmitter.writeMoveOp(self.out, Op.xr(scratch), Dst.xr(0));
            },
            .tuple_ => |bindings| {
                // `erlang:element/2` rather than `get_tuple_element`: the
                // subject is typed `any` whenever it comes from a call, and the
                // loader wants a statically known tuple arity for the raw
                // instruction (`bad_type, needed t_tuple`). The subject is
                // parked in a y-slot because each `call_ext` frees the whole
                // x-file. `destructYSlots` reserves that extra slot.
                const subj_y = self.next_y;
                self.next_y += 1;
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(subj_y));
                for (bindings, 0..) |name, i| {
                    try beamEmitter.writeMoveOp(self.out, Op.int(i + 1), Dst.xr(0));
                    try beamEmitter.writeMoveOp(self.out, Op.yr(subj_y), Dst.xr(1));
                    try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
                    const y_idx = self.next_y;
                    self.next_y += 1;
                    try self.reg_map.put(name, .{ .y = y_idx });
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                }
                try beamEmitter.writeMoveOp(self.out, Op.yr(subj_y), Dst.xr(0));
            },
            else => try beamEmitter.writeComment(self.out, "unsupported destructure pattern", .{}),
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
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
    }

    /// `name = expr` or `name += expr`: evaluate the new value and store
    /// back into the variable's y-slot.
    fn emitAssign(self: *Emitter, a: anytype) anyerror!void {
        switch (a.target) {
            .name => |name| {
                const reg = self.reg_map.get(name) orelse {
                    try beamEmitter.writeComment(self.out, "assign to unknown variable: {s}", .{name});
                    return;
                };
                switch (a.op) {
                    .assign => {
                        try self.lowerExprIntoX0(a.value.*);
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
                    },
                    .plusAssign => {
                        try self.lowerExprIntoX0(a.value.*);
                        const scratch = self.scratchBase();
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                        try beamEmitter.writeGcBif(self.out, .add, scratch + 1, &.{ reg.operand(), Op.xr(scratch) }, Dst.xr(0));
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
                    },
                }
            },
            .fieldAccess => |*fa| {
                try self.lowerExprIntoX0(a.value.*);
                const scratch = self.scratchBase();
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                const saved_live = self.raiseLive(scratch + 1);
                try self.lowerExprIntoX0(fa.receiver.*);
                self.min_live = saved_live;
                try beamEmitter.writePutMap(self.out, true, Op.xr(0), Dst.xr(0), scratch + 1, &.{.{ .key = Op.atom(fa.field), .value = Op.xr(scratch) }});
                if (self.reg_map.get("self")) |reg| {
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
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
            try beamEmitter.writeTest(self.out, .is_eq, else_label, &.{ Op.xr(0), Op.atom("true") });
        }

        // then branch (cond true).
        for (i.then_) |s| try self.emitStmt(s);
        const then_returns = i.then_.len > 0 and stmtIsReturn(i.then_[i.then_.len - 1]);

        // Skip the unconditional jump-to-end when the then branch already
        // exits via `return.` — otherwise BEAM will see unreachable code.
        const end_label: ?u32 = if (!then_returns) self.allocLabel() else null;
        if (end_label) |el| try beamEmitter.writeJump(self.out, el);

        // else branch.
        try beamEmitter.writeLabel(self.out, else_label);
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

        if (end_label) |el| try beamEmitter.writeLabel(self.out, el);
    }

    /// Lower `lhs <op> rhs` (a comparison) as a `{test, is_<op>, {f, F}, [A, B]}.`
    /// instruction whose failure target is `fail_label`. Returns false if the
    /// expression is not a recognised comparison.
    fn lowerComparisonAsTest(self: *Emitter, cond: ast.Expr, fail_label: u32) anyerror!bool {
        switch (cond) {
            .binaryOp => |bin| {
                const cmp = comparisonTestOp(bin.op) orelse return false;

                const lhs_simple = self.simpleTerm(bin.lhs.*);
                const rhs_simple = self.simpleTerm(bin.rhs.*);

                var lhs_final: Op = undefined;
                var rhs_final: Op = undefined;

                if (lhs_simple != null and rhs_simple != null) {
                    lhs_final = lhs_simple.?;
                    rhs_final = rhs_simple.?;
                } else {
                    const scratch = self.scratchBase();
                    if (lhs_simple) |ls| {
                        try beamEmitter.writeMoveOp(self.out, ls, Dst.xr(scratch));
                    } else {
                        try self.lowerExprIntoX0(bin.lhs.*);
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                    }
                    lhs_final = Op.xr(scratch);
                    if (rhs_simple) |rs| {
                        rhs_final = rs;
                    } else {
                        // The staged lhs must survive the rhs lowering.
                        const saved_live = self.raiseLive(scratch + 1);
                        try self.lowerExprIntoX0(bin.rhs.*);
                        self.min_live = saved_live;
                        rhs_final = Op.xr(0);
                    }
                }

                const a = if (cmp.swap) rhs_final else lhs_final;
                const b = if (cmp.swap) lhs_final else rhs_final;
                try beamEmitter.writeTest(self.out, cmp.opcode, fail_label, &.{ a, b });
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
                                try beamEmitter.writeMoveOp(self.out, Op.xr(xn), Dst.xr(0));
                            },
                            .y => |yn| {
                                try beamEmitter.writeMoveOp(self.out, Op.yr(yn), Dst.xr(0));
                            },
                        }
                        return;
                    }
                    if (self.cv.get(n)) |val| {
                        try beamEmitter.writeMoveOp(self.out, .{ .term = Term.atomOf(val) }, Dst.xr(0));
                        return;
                    }
                    // A module-level `val` is emitted as a 0-arity function, so a
                    // bare reference is a call — local for this module's own
                    // vals, remote for an imported `pub val` (which used to
                    // lower to the bare atom `'HOST'`).
                    if (self.crossOwnerOf(n, .val)) |owner| {
                        var name_buf: [256]u8 = undefined;
                        const val_atom = atomName(n, &name_buf) catch n;
                        try beamEmitter.writeCall(
                            self.out,
                            .normal,
                            0,
                            .{ .ext = .{ .module = owner, .function = val_atom } },
                            0,
                        );
                        return;
                    }
                    try beamEmitter.writeMove(self.out, Term.atomOf(n), 0);
                    return;
                },
                .dotIdent => |d| {
                    try beamEmitter.writeMove(self.out, Term.atomOf(d), 0);
                    return;
                },
                .identAccess => |ia| {
                    try self.lowerIdentAccess(ia, id.loc, 0);
                    return;
                },
            },
            .literal => |lit| switch (lit.kind) {
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .numberLit => |n| {
                    try beamEmitter.writeMoveOp(self.out, Op.num(n), Dst.xr(0));
                    return;
                },
                .null_ => {
                    // `undefined`, not `nil`: `nil` is the empty *list* on BEAM,
                    // and the `@Option` helpers here (and the erlang backend's
                    // `.null_ => A("undefined")`) test absence against
                    // `undefined`.
                    try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
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
                    try beamEmitter.writeComment(self.out, "unsupported: record literal", .{});
                    try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
                    return;
                },
                .interfaceLit => {
                    try beamEmitter.writeComment(self.out, "unsupported: interface literal", .{});
                    try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
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
                    try beamEmitter.writeCall(self.out, .only, 1, .{ .ext = .{ .module = "erlang", .function = "throw" } }, 0);
                    return;
                },
                .try_ => |val| {
                    // `try expr` (no catch): unwrap `{ok, V}`, or early-return the
                    // `{error, E}` tuple to propagate it up.
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                        const err_label = self.allocLabel();
                        const cont_label = self.allocLabel();
                        try beamEmitter.writeTest(self.out, .is_tagged_tuple, err_label, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom("ok") });
                        try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 1, Dst.xr(0));
                        try beamEmitter.writeJump(self.out, cont_label);
                        try beamEmitter.writeLabel(self.out, err_label);
                        try self.emitReturn();
                        try beamEmitter.writeLabel(self.out, cont_label);
                    }
                    return;
                },
                else => {},
            },
            .comptime_ => {
                try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
                return;
            },
            .function => |f| switch (f.kind.syntax) {
                .lambda => {
                    try self.lowerLambda(f.kind, self.min_live);
                    return;
                },
                .fnExpr => {
                    try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
                    return;
                },
            },
            .loop => |lp| {
                try self.lowerLoop(lp);
                return;
            },
            else => {},
        }

        try beamEmitter.writeComment(self.out, "unsupported expr in tail position: {s}", .{@tagName(e)});
        try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
    }

    /// Lower `-e` into `{x, dest}`. Constant-folds literal numerics.
    fn lowerNeg(self: *Emitter, inner: ast.Expr, dest: u32) !void {
        switch (inner) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    try beamEmitter.writeMoveOp(self.out, Op.negNum(n), Dst.xr(dest));
                    return;
                },
                else => {},
            },
            else => {},
        }
        if (self.simpleTerm(inner)) |it| {
            try beamEmitter.writeGcBif(self.out, .sub, self.min_live, &.{ Op.int(0), it }, Dst.xr(dest));
        } else {
            try self.lowerExprIntoX0(inner);
            const scratch = self.scratchBase();
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
            try beamEmitter.writeGcBif(self.out, .sub, scratch + 1, &.{ Op.int(0), Op.xr(scratch) }, Dst.xr(dest));
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
            try beamEmitter.writeTest(self.out, .is_eq, else_label, &.{ Op.xr(0), Op.atom("true") });
        }

        const end_label = self.allocLabel();
        const then_fell = try self.emitValueBody(i.then_);
        if (then_fell) try beamEmitter.writeJump(self.out, end_label);

        try beamEmitter.writeLabel(self.out, else_label);
        if (i.else_) |els| {
            _ = try self.emitValueBody(els);
        } else {
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
        }
        try beamEmitter.writeLabel(self.out, end_label);
    }

    /// Lower a body whose last statement is its value: all but the last are
    /// emitted as statements, the last is lowered into `{x, 0}` and control
    /// falls through. Returns true when it fell through (produced a value),
    /// false when the last statement was an explicit jump (`return`/`throw`/…)
    /// that transferred control on its own.
    fn emitValueBody(self: *Emitter, body: []const ast.Stmt) anyerror!bool {
        if (body.len == 0) {
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
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
            else => try beamEmitter.writeComment(self.out, "unsupported in arith position: {s}", .{@tagName(e)}),
        }
    }

    /// Arithmetic via `gc_bif`. Handles non-simple operands by materializing
    /// them into scratch x-registers above `cur_arity`.
    fn lowerArithGcBif(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const bif: beamEmitter.GcBif = switch (bin.op) {
            .add => .add,
            .sub => .sub,
            .mul => .mul,
            .div => .div_,
            .mod => .rem,
            else => unreachable,
        };
        const lhs_simple = self.simpleTerm(bin.lhs.*);
        const rhs_simple = self.simpleTerm(bin.rhs.*);

        if (lhs_simple != null and rhs_simple != null) {
            try beamEmitter.writeGcBif(self.out, bif, self.min_live, &.{ lhs_simple.?, rhs_simple.? }, Dst.xr(dest));
            return;
        }

        const scratch = self.scratchBase();
        if (lhs_simple) |ls| {
            try beamEmitter.writeMoveOp(self.out, ls, Dst.xr(scratch));
        } else {
            try self.lowerExprIntoX0(bin.lhs.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
        }

        const rhs_final: Op = if (rhs_simple) |rs| rs else blk: {
            // The staged lhs sits in `{x, scratch}`; a `gc_bif`/call inside the
            // rhs would otherwise drop it (`not_live`).
            const saved_live = self.raiseLive(scratch + 1);
            try self.lowerExprIntoX0(bin.rhs.*);
            self.min_live = saved_live;
            break :blk Op.xr(0);
        };

        try beamEmitter.writeGcBif(
            self.out,
            bif,
            @max(scratch + 1, self.min_live),
            &.{ Op.xr(scratch), rhs_final },
            Dst.xr(dest),
        );
    }

    /// Lower a comparison (`<`, `>`, `==`, …) as a value: emits a `{test, …}`
    /// then branches to produce `{atom, true}` or `{atom, false}` in `{x, dest}`.
    fn lowerCmpAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const cmp = comparisonTestOp(bin.op) orelse unreachable;

        const lhs_simple = self.simpleTerm(bin.lhs.*);
        const rhs_simple = self.simpleTerm(bin.rhs.*);

        var lhs_final: Op = undefined;
        var rhs_final: Op = undefined;

        if (lhs_simple != null and rhs_simple != null) {
            lhs_final = lhs_simple.?;
            rhs_final = rhs_simple.?;
        } else {
            const scratch = self.scratchBase();
            if (lhs_simple) |ls| {
                try beamEmitter.writeMoveOp(self.out, ls, Dst.xr(scratch));
            } else {
                try self.lowerExprIntoX0(bin.lhs.*);
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
            }
            lhs_final = Op.xr(scratch);

            if (rhs_simple) |rs| {
                rhs_final = rs;
            } else {
                const saved_live = self.raiseLive(scratch + 1);
                try self.lowerExprIntoX0(bin.rhs.*);
                self.min_live = saved_live;
                rhs_final = Op.xr(0);
            }
        }

        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        const a = if (cmp.swap) rhs_final else lhs_final;
        const b = if (cmp.swap) lhs_final else rhs_final;
        try beamEmitter.writeTest(self.out, cmp.opcode, false_label, &.{ a, b });
        try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(dest));
        try beamEmitter.writeJump(self.out, end_label);
        try beamEmitter.writeLabel(self.out, false_label);
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(dest));
        try beamEmitter.writeLabel(self.out, end_label);
    }

    /// `a && b` → short-circuit: test `a`, if false → false, else evaluate `b`.
    fn lowerAndAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const lhs_simple = self.simpleTerm(bin.lhs.*);
        const lhs_final: Op = if (lhs_simple) |ls| ls else blk: {
            const scratch = self.scratchBase();
            try self.lowerExprIntoX0(bin.lhs.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
            break :blk Op.xr(scratch);
        };
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try beamEmitter.writeTest(self.out, .is_eq, false_label, &.{ lhs_final, Op.atom("true") });
        try self.lowerExprIntoX0(bin.rhs.*);
        if (dest != 0) try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(dest));
        try beamEmitter.writeJump(self.out, end_label);
        try beamEmitter.writeLabel(self.out, false_label);
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(dest));
        try beamEmitter.writeLabel(self.out, end_label);
    }

    /// `a || b` → short-circuit: test `a`, if true → true, else evaluate `b`.
    fn lowerOrAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const lhs_simple = self.simpleTerm(bin.lhs.*);
        const lhs_final: Op = if (lhs_simple) |ls| ls else blk: {
            const scratch = self.scratchBase();
            try self.lowerExprIntoX0(bin.lhs.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
            break :blk Op.xr(scratch);
        };
        const true_label = self.allocLabel();
        const end_label = self.allocLabel();
        try beamEmitter.writeTest(self.out, .is_ne_exact, true_label, &.{ lhs_final, Op.atom("true") });
        try self.lowerExprIntoX0(bin.rhs.*);
        if (dest != 0) try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(dest));
        try beamEmitter.writeJump(self.out, end_label);
        try beamEmitter.writeLabel(self.out, true_label);
        try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(dest));
        try beamEmitter.writeLabel(self.out, end_label);
    }

    /// `!x` → test x against true, produce the opposite atom.
    fn lowerNot(self: *Emitter, inner: ast.Expr, dest: u32) anyerror!void {
        try self.lowerExprIntoX0(inner);
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try beamEmitter.writeTest(self.out, .is_eq, false_label, &.{ Op.xr(0), Op.atom("true") });
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(dest));
        try beamEmitter.writeJump(self.out, end_label);
        try beamEmitter.writeLabel(self.out, false_label);
        try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(dest));
        try beamEmitter.writeLabel(self.out, end_label);
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
                        try self.materializeCallArgs(cc.args, cc.trailing[0..0]);
                        const labels = self.fnLabelsFor(mangled, arity) catch {
                            try beamEmitter.writeComment(self.out, "unresolved extension call: {s}/{d}", .{ mangled, arity });
                            if (mode == .tail) try self.emitReturn();
                            return;
                        };
                        switch (mode) {
                            .non_tail => try beamEmitter.writeCall(self.out, .normal, arity, .{ .local = labels.entry }, 0),
                            .tail => try beamEmitter.writeCall(self.out, .last, arity, .{ .local = labels.entry }, self.num_y),
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
            // §D2 — `"std"` package qualified call: a lowercase receiver naming
            // an imported std module (`math`, `path`, …) lowers to a remote
            // `call_ext` into that module atom. Parity with the erlang
            // backend's `std_imports` path.
            if (recv_name) |rn| {
                if (self.std_imports.contains(rn)) {
                    try self.materializeCallArgs(cc.args, cc.trailing);
                    const arity = cc.args.len + cc.trailing.len;
                    var fn_buf: [256]u8 = undefined;
                    const fn_atom = atomName(cc.callee, &fn_buf) catch cc.callee;
                    try beamEmitter.writeCall(
                        self.out,
                        if (mode == .tail) .last else .normal,
                        arity,
                        .{ .ext = .{ .module = rn, .function = fn_atom } },
                        self.num_y,
                    );
                    return;
                }
            }
            // Module-qualified remote call: a PascalCase identifier receiver that
            // isn't a local binding is a module reference: `List.map(xs, f)` →
            // `list:map(xs, f)` (mirrors the Erlang backend's `isModuleRef`/
            // `erlangModule`). The receiver names the module, so it is *not*
            // prepended as an argument; trailing lambdas become fun arguments.
            if (recv_name) |rn| {
                // §enum-sections F4 — synthesised inner enums carry the F1
                // mangling `__<EnumName>__<Path>` (double underscore, third
                // byte uppercase). Treat them as type-name receivers so a
                // call like `__Token__Color.Red(_inner: …)` resolves to a
                // tagged tuple rather than the unresolved-method-call path.
                const isSynthesisedTypeRecv = rn.len >= 3 and rn[0] == '_' and rn[1] == '_' and std.ascii.isUpper(rn[2]);
                if (rn.len > 0 and rn.len <= 128 and
                    (std.ascii.isUpper(rn[0]) or isSynthesisedTypeRecv) and !self.reg_map.contains(rn))
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
                            try self.materializeCallArgs(cc.args, cc.trailing);
                            try beamEmitter.writeCall(
                                self.out,
                                if (mode == .tail) .last else .normal,
                                arity,
                                .{ .ext = .{ .module = owner, .function = mangled } },
                                self.num_y,
                            );
                            return;
                        }
                        if (self.fnLabelsFor(mangled, arity)) |labels| {
                            try self.materializeCallArgs(cc.args, cc.trailing);
                            switch (mode) {
                                .non_tail => try beamEmitter.writeCall(self.out, .normal, arity, .{ .local = labels.entry }, 0),
                                .tail => try beamEmitter.writeCall(self.out, .last, arity, .{ .local = labels.entry }, self.num_y),
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
                            try self.materializeCallArgs(cc.args, cc.trailing);
                            switch (mode) {
                                .non_tail => try beamEmitter.writeCall(self.out, .normal, arity, .{ .local = labels.entry }, 0),
                                .tail => try beamEmitter.writeCall(self.out, .last, arity, .{ .local = labels.entry }, self.num_y),
                            }
                            return;
                        } else |_| {}
                    }
                    const total = cc.args.len + cc.trailing.len;
                    const scratch = self.scratchBase();
                    const saved_live = self.min_live;
                    for (cc.args, 0..) |arg, i| {
                        // Args already staged (`scratch..scratch+i-1`) must
                        // survive this one's own calls / gc_bifs. Nothing is
                        // staged yet for `i == 0`, and claiming `{x, 0}` live
                        // before anything wrote it is `uninitialized_reg`.
                        if (i > 0) _ = self.raiseLive(@intCast(scratch + i));
                        try self.lowerExprIntoX0(arg.value.*);
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch + i));
                    }
                    for (cc.trailing, 0..) |trail, j| {
                        // Positional args sit in scratch..scratch+args.len-1 and
                        // earlier trailing funs in the slots after — all must
                        // survive the closure's test_heap. `Live` is a prefix
                        // count, so before the first operand it may only be
                        // whatever the caller already claimed.
                        const slot = scratch + cc.args.len + j;
                        const live: u32 = if (cc.args.len + j == 0) self.min_live else @intCast(slot);
                        _ = self.raiseLive(live);
                        try self.lowerLambda(trail, live);
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(slot));
                    }
                    self.min_live = saved_live;
                    for (0..total) |i| {
                        try beamEmitter.writeMoveOp(self.out, Op.xr(scratch + i), Dst.xr(i));
                    }
                    var mbuf: [128]u8 = undefined;
                    @memcpy(mbuf[0..rn.len], rn);
                    mbuf[0] = std.ascii.toLower(mbuf[0]);
                    const mod = mbuf[0..rn.len];
                    try beamEmitter.writeCall(
                        self.out,
                        if (mode == .tail) .last else .normal,
                        total,
                        .{ .ext = .{ .module = mod, .function = cc.callee } },
                        self.num_y,
                    );
                    return;
                }
            }
            if (recv_name) |rn| {
                if (self.reg_map.get(rn)) |reg| {
                    const recv_term = reg.operand();
                    try beamEmitter.writeMoveOp(self.out, recv_term, Dst.xr(0));
                } else {
                    try beamEmitter.writeMove(self.out, Term.atomOf(rn), 0);
                }
            } else {
                try self.lowerExprIntoX0(recv_expr.*);
            }
            const scratch = self.scratchBase();
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
            const saved_live = self.min_live;
            for (cc.args, 0..) |arg, i| {
                _ = self.raiseLive(@intCast(scratch + 1 + i));
                try self.lowerExprIntoX0(arg.value.*);
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch + 1 + i));
            }
            self.min_live = saved_live;
            try beamEmitter.writeMoveOp(self.out, Op.xr(scratch), Dst.xr(0));
            for (0..cc.args.len) |i| {
                try beamEmitter.writeMoveOp(self.out, Op.xr(scratch + 1 + i), Dst.xr(1 + i));
            }
            const total_arity = 1 + cc.args.len;
            const labels = self.fnLabelsFor(cc.callee, total_arity) catch {
                try beamEmitter.writeComment(self.out, "unresolved method call: {s}/{d}", .{ cc.callee, total_arity });
                if (mode == .tail) try self.emitReturn();
                return;
            };
            switch (mode) {
                .non_tail => try beamEmitter.writeCall(self.out, .normal, total_arity, .{ .local = labels.entry }, 0),
                .tail => try beamEmitter.writeCall(self.out, .last, total_arity, .{ .local = labels.entry }, self.num_y),
            }
            return;
        }
        // Trailing lambdas (`each(xs) { x -> … }`) are positional arguments
        // after the parenthesised ones, so the callee's arity counts both and
        // `materializeCallArgs` lays them out together.
        const arity = cc.args.len + cc.trailing.len;

        // A top-level function resolves to a reserved label pair → direct call.
        if (self.fnLabelsFor(cc.callee, arity)) |labels| {
            try self.materializeCallArgs(cc.args, cc.trailing);
            switch (mode) {
                .non_tail => try beamEmitter.writeCall(self.out, .normal, arity, .{ .local = labels.entry }, 0),
                .tail => try beamEmitter.writeCall(self.out, .last, arity, .{ .local = labels.entry }, self.num_y),
            }
            return;
        } else |_| {}

        // Otherwise, a name bound to a local (a `syntax fn` parameter or a
        // `val f = {x -> …}`) holds a fun and is applied via `call_fun`. Params
        // and locals live in y-slots, so the fun is loaded into `{x, arity}`
        // *after* the arguments are laid out — nothing the arg staging writes
        // can reach it, and the load itself can't disturb the arg registers.
        if (self.reg_map.get(cc.callee)) |reg| {
            const fun_term = reg.operand();
            try self.materializeCallArgs(cc.args, cc.trailing);
            try beamEmitter.writeMoveOp(self.out, fun_term, Dst.xr(arity));
            try beamEmitter.writeCallFun(self.out, arity);
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

        // An imported `pub fn` has no local label — it lives in the exporting
        // module, so the call is remote (`math:double/1`). Without this the site
        // recorded a `%% unresolved local call` comment and silently left the
        // last staged argument in `{x, 0}`.
        if (self.crossOwnerOf(cc.callee, .@"fn")) |owner| {
            try self.materializeCallArgs(cc.args, cc.trailing);
            var name_buf: [256]u8 = undefined;
            const fn_atom = atomName(cc.callee, &name_buf) catch cc.callee;
            try beamEmitter.writeCall(
                self.out,
                if (mode == .tail) .last else .normal,
                arity,
                .{ .ext = .{ .module = owner, .function = fn_atom } },
                self.num_y,
            );
            return;
        }

        try self.materializeCallArgs(cc.args, cc.trailing);
        try beamEmitter.writeComment(self.out, "unresolved local call: {s}/{d}", .{ cc.callee, arity });
        if (mode == .tail) try self.emitReturn();
    }

    /// Owning module atom for a cross-module export of the given kind, or null
    /// when the name is local, shadowed by a register, or exported with a
    /// different shape.
    fn crossOwnerOf(self: *const Emitter, name: []const u8, kind: crossModule.ExportKind) ?[]const u8 {
        const xc = self.cross orelse return null;
        const info = xc.exports.get(name) orelse return null;
        if (info.kind != kind) return null;
        const owner = crossModule.moduleBasename(info.module);
        // A module never calls into itself remotely.
        if (std.mem.eql(u8, owner, self.module_name)) return null;
        return owner;
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
    // Inline funs / arithmetic / structural compares cover the rest of the
    // BEAM-irreducible prim methods: `isEmpty` (`=:= []`), 2-arg `slice`
    // (`primArraySlice2` — `gc_bif` arithmetic + `lists:sublist/3`), string
    // `contains` / `startsWith` (`primCmpAgainstNomatch` — `binary:match/2`
    // / `string:prefix/2` + `=/= nomatch`), `at` (`primAt` — `is_ge`/`is_lt`
    // bounds check + `lists:nth/2` or `undefined`, lowered through the
    // `ensureAtHelper` synth fn), `indexOf` (`primIndexOf` — recursive
    // `'-bp_indexOf-'/3` via `call_only`), `join` (`primJoin` —
    // `lists:map` + `lists:join` + `iolist_to_binary`, with the per-element
    // stringify fun shipped via `ensureStringifyHelper` + `make_fun3`).
    // `append`/`prepend`/`push` keep their hand-rolled list-cons / `lists:
    // append` shapes (`primPrepend`/`primAppendElem`/`primAppendList`).
    // Returns `true` when handled; `false` falls through to the
    // value-receiver local-call path so a method we haven't lowered records
    // a `%% unresolved` comment instead of mis-emitting.
    fn emitPrimMethod(self: *Emitter, k: envMod.PrimKind, callee: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        const eq = std.mem.eql;
        // §A5 annotation-driven path: if the receiver's interface method carries
        // a recognisable `@external(erlang, "mod", "sym[(args)]")` shape (1-arg
        // self / 2-arg self-first / 2-arg arg-first), lower via the matching
        // x-register pattern and return. The inline switch below handles the
        // BEAM-irreducible cases (`++` ops, inline funs, custom heap shapes,
        // BIF aliases).
        if (try self.tryEmitPrimAnnotation(k, callee, recv_expr, cc, mode)) return true;
        switch (k) {
            .array => {
                if (eq(u8, callee, "contains")) try self.primArgThenList("lists", "member", recv_expr, cc, mode) else if (eq(u8, callee, "len") or eq(u8, callee, "length") or eq(u8, callee, "size")) try self.primRecvOnly("erlang", "length", recv_expr, mode) else if (eq(u8, callee, "prepend")) try self.primPrepend(recv_expr, cc, mode) else if (eq(u8, callee, "push")) try self.primAppendElem(recv_expr, cc, mode) else if (eq(u8, callee, "append")) try self.primAppendList(recv_expr, cc, mode) else if (eq(u8, callee, "isEmpty")) try self.primIsEmpty(recv_expr, mode) else if (eq(u8, callee, "slice") and cc.args.len + cc.trailing.len == 2) {
                    if (!try self.primArraySlice2(recv_expr, cc, mode)) return false;
                } else if (eq(u8, callee, "at") and cc.args.len + cc.trailing.len == 1) try self.primAt(recv_expr, cc, mode) else if (eq(u8, callee, "indexOf") and cc.args.len + cc.trailing.len == 1) try self.primIndexOf(recv_expr, cc, mode) else if (eq(u8, callee, "join") and cc.args.len + cc.trailing.len == 1) try self.primJoin(recv_expr, cc, mode) else return false;
                return true;
            },
            .string => {
                if (eq(u8, callee, "split")) try self.primRecvThenArgs("string", "split", recv_expr, cc, Op.atom("all"), mode) else if (eq(u8, callee, "slice") and cc.args.len + cc.trailing.len == 1) try self.primRecvThenArgs("string", "slice", recv_expr, cc, null, mode) else if (eq(u8, callee, "contains")) try self.primCmpAgainstNomatch("binary", "match", recv_expr, cc, mode) else if (eq(u8, callee, "startsWith")) try self.primCmpAgainstNomatch("string", "prefix", recv_expr, cc, mode) else return false;
                return true;
            },
            .bool, .int, .float => return false,
        }
    }

    /// §A5 BEAM dispatch: emit a primitive method call from its `@external(erlang,
    /// "mod", "sym[(args)]")` annotation. Recognises three template shapes:
    /// `[self]` (1-arg call, `primRecvOnly`), `[X, self]` (2-arg with the
    /// receiver second, `primFunThenList` — fun or value, same byte shape) and
    /// `[self, X]` (2-arg with the receiver first, `primRecvThenArgs`). Bare
    /// symbol → declaration order: `[self, …cc.args]`, dispatched via the
    /// receiver-first path. Returns false on any unrecognised shape so the
    /// inline allow-list keeps owning irreducible cases.
    fn tryEmitPrimAnnotation(self: *Emitter, k: envMod.PrimKind, callee: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        const iface_name = primIfaceForKind(k) orelse return false;
        var b: [128]u8 = undefined;
        const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface_name, callee }) catch return false;
        // §A6 BEAM-target template path (v0.beta.22 front 03): an
        // `@External.Beam("""…""")` annotation whose body carries `$self` /
        // `$0..$N` / `$args` markers renders as multi-line `.S` after pre-
        // loading `recv` into `x0` and each positional arg into `x_{i+1}`.
        // Wins over both the erlang-derived dispatch below AND the inline
        // `emitPrimMethod` arm — the template author owns the full lowering.
        if (self.prim_beam_templates.get(key)) |body| {
            try self.renderBeamTemplate(body, recv_expr, cc, mode);
            return true;
        }
        const call = self.prim_erlang_dispatch.get(key) orelse return false;
        // `prim-op-annotation` template form (erlang only for now): BEAM has not
        // migrated, so fall through to the inline switch below for these. The
        // erlang collector stores template bodies with `module == ""` and
        // `args == null`, and the symbol carries `$`-markers. Arity-branched
        // entries (`when($argc == N)`) likewise short-circuit so BEAM's switch
        // continues to own arity-branched lowerings (Array/String `slice`).
        if (call.arity_branches.len > 0) return false;
        if (primOpTemplate.looksLikeTemplate(call.symbol)) return false;
        if (call.args) |args| {
            if (args.len == 1 and std.mem.eql(u8, args[0], "self")) {
                try self.primRecvOnly(call.module, call.symbol, recv_expr, mode);
                return true;
            }
            if (args.len == 2 and std.mem.eql(u8, args[1], "self")) {
                // `(arg, self)` — swapped 2-arg call. `primFunThenList` and
                // `primArgThenList` emit byte-identical shapes, so either covers
                // both fun args (`map/filter/forEach`) and value args (`member`).
                try self.primFunThenList(call.module, call.symbol, recv_expr, cc, mode);
                return true;
            }
            if (args.len == 2 and std.mem.eql(u8, args[0], "self") and cc.args.len + cc.trailing.len == 1) {
                try self.primRecvThenArgs(call.module, call.symbol, recv_expr, cc, null, mode);
                return true;
            }
            return false;
        }
        // Bare symbol — declaration order.
        if (cc.args.len + cc.trailing.len == 0) {
            try self.primRecvOnly(call.module, call.symbol, recv_expr, mode);
            return true;
        }
        if (cc.args.len + cc.trailing.len == 1) {
            try self.primRecvThenArgs(call.module, call.symbol, recv_expr, cc, null, mode);
            return true;
        }
        return false;
    }

    /// §A6 BEAM-target template renderer (v0.beta.22 front 03). Pre-loads
    /// `recv` into `x0` and each positional arg into `x_{i+1}` in
    /// declaration order, then walks `body` via the shared
    /// `comptime/primOpTemplate.zig` renderer with a BEAM-aware ctx that
    /// substitutes `$self` → `{x, 0}`, `$N` → `{x, N+1}`, and `$args` →
    /// the comma-separated `{x, 1..N}` list (mirroring the BEAM call_ext
    /// arg convention).
    ///
    /// **Pre-load shape**: args first in reverse order (`N-1, N-2, …, 0`),
    /// then `recv` last. Each arg lower goes through `x0` and is moved to
    /// its target `x_{i+1}`; `min_live` is raised to `argc + 1` so an arg
    /// load's `test_heap` / `gc_bif` won't clobber any earlier-loaded
    /// register. `recv` lands in `x0` directly (no trailing move), keeping
    /// the byte sequence minimal.
    ///
    /// **Tail mode**: `mode == .tail` appends `emitReturn` after the
    /// template body. The author can also choose to end the body with a
    /// `call_ext_last` / explicit `return.` — the trailing `return.` is
    /// idempotent (the loader collapses adjacent returns).
    fn renderBeamTemplate(self: *Emitter, body: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const argc_usize = cc.args.len + cc.trailing.len;
        const argc: u32 = @intCast(argc_usize);
        // Pre-load args N-1..0 in reverse (each into x0 → moved to x_{i+1}).
        // The reverse order lets each load see the prior-loaded args in their
        // final positions (`x_{i+2..N}`); the `min_live = argc + 1` floor
        // keeps every preserved arg register alive across the load.
        const saved_live = self.min_live;
        self.min_live = @max(self.min_live, argc + 1);
        var i = argc_usize;
        while (i > 0) {
            i -= 1;
            try self.lowerPrimArgIntoX0(cc, i);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(i + 1));
        }
        // recv lowers last into x0 (no trailing move). `min_live` is still
        // raised so the lowering itself preserves `x_{1..N}`.
        try self.lowerExprIntoX0(recv_expr.*);
        self.min_live = saved_live;

        const Ctx = struct {
            emitter: *Emitter,
            argc: usize,
            pub fn writeByte(c: *@This(), ch: u8) anyerror!void {
                try c.emitter.out.writeByte(ch);
            }
            pub fn writeAll(c: *@This(), s: []const u8) anyerror!void {
                try c.emitter.out.writeAll(s);
            }
            pub fn emitRecv(c: *@This()) anyerror!void {
                try beamEmitter.writeArg(c.emitter.out, Op.xr(0));
            }
            pub fn emitArg(c: *@This(), idx: usize) anyerror!void {
                try beamEmitter.writeArg(c.emitter.out, Op.xr(idx + 1));
            }
        };
        var ctx = Ctx{ .emitter = self, .argc = argc_usize };
        try primOpTemplate.render(body, &ctx);
        // `unquoteAnnotationArg` strips ONE trailing `\n` from a `"""…"""`
        // body so the author's natural multi-line form (one stmt per line,
        // closing `"""` on its own line) renders without an empty trailing
        // line. Add the newline back so the rendered body's last `.` lands
        // on its own line — matching every `bodyPrint("...".\n", ...)`
        // statement an inline arm would emit.
        if (body.len == 0 or body[body.len - 1] != '\n') try self.out.writeByte('\n');

        if (mode == .tail) try self.emitReturn();
    }

    /// Lower positional arg `i` (a regular arg or trailing lambda) into `x0`,
    /// honouring the caller's `min_live` floor. Mirrors `lowerPrimFunArg`
    /// for arg index 0 but extends to higher indices for multi-arg templates.
    fn lowerPrimArgIntoX0(self: *Emitter, cc: anytype, i: usize) anyerror!void {
        if (i < cc.args.len) {
            try self.lowerExprIntoX0(cc.args[i].value.*);
        } else {
            const ti = i - cc.args.len;
            try self.lowerLambda(cc.trailing[ti], self.min_live);
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
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = tail
        try self.lowerPrimFunArg(cc, 2); // x0 = head (arg 0), min_live=2 keeps x1
        try beamEmitter.writeTestHeap(self.out, 2, 2);
        try beamEmitter.writePutList(self.out, Op.xr(0), Op.xr(1), Dst.xr(0));
        if (mode == .tail) try self.emitReturn();
    }

    /// `recv.append(xs)` → `recv ++ xs` (`lists:append/2`; `xs` is already a list).
    /// The (often-literal) arg is lowered first into `x1`, then the receiver into
    /// `x0` — a simple receiver won't clobber `x1`.
    fn primAppendList(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerPrimFunArg(cc, 1); // x0 = the list to append
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = that list
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv
        try self.emitPrimCallExt("lists", "append", 2, mode);
    }

    /// `recv.push(x)` → `recv ++ [x]` (`lists:append/2`).
    fn primAppendElem(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = recv
        try self.lowerPrimFunArg(cc, 2); // x0 = the element, min_live=2 keeps x1
        try beamEmitter.writeTestHeap(self.out, 2, 2);
        try beamEmitter.writePutList(self.out, Op.xr(0), Op.nil, Dst.xr(0)); // x0 = [elem]
        // Want `lists:append(Recv, [elem])` → x0 = Recv, x1 = [elem].
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(2)); // x2 = [elem]
        try beamEmitter.writeMoveOp(self.out, Op.xr(1), Dst.xr(0)); // x0 = recv
        try beamEmitter.writeMoveOp(self.out, Op.xr(2), Dst.xr(1)); // x1 = [elem]
        try self.emitPrimCallExt("lists", "append", 2, mode);
    }

    /// `recv.isEmpty()` → the boolean `recv =:= []`.
    fn primIsEmpty(self: *Emitter, recv_expr: *const ast.Expr, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = recv
        const not_empty = self.allocLabel();
        const end_l = self.allocLabel();
        try beamEmitter.writeTest(self.out, .is_eq, not_empty, &.{ Op.xr(0), Op.nil });
        try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(0));
        try beamEmitter.writeJump(self.out, end_l);
        try beamEmitter.writeLabel(self.out, not_empty);
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(0));
        try beamEmitter.writeLabel(self.out, end_l);
        if (mode == .tail) try self.emitReturn();
    }

    /// `xs.slice(start, end)` — 2-arg array slice (`lists:sublist(L, S+1,
    /// E-S)`). Recv lands in `x0`; `S+1` is computed into `x1` via `gc_bif '+'`
    /// from `simpleTerm` of `args[0]`; `E-S` into `x2` via `gc_bif '-'` from
    /// `simpleTerm` of `args[1]` and `args[0]`. Both args must be `simpleTerm`-
    /// reducible (a reg-resident ident or a literal int); a complex sub-expr
    /// would need a scratch slot for the recv and isn't supported in F4 —
    /// returns `false` so the caller falls through to the local-call path.
    /// Matches the erlang template `lists:sublist($self, ($0)+1, (($1)-($0)))`.
    fn primArraySlice2(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        const start_term = self.simpleTerm(cc.args[0].value.*) orelse return false;
        const end_term = self.simpleTerm(cc.args[1].value.*) orelse return false;
        try self.lowerExprIntoX0(recv_expr.*);
        // x1 = start + 1, preserving x0 (live=1 keeps recv across gc_bif).
        try beamEmitter.writeGcBif(
            self.out,
            .add,
            @max(1, self.min_live),
            &.{ start_term, Op.int(1) },
            Dst.xr(1),
        );
        // x2 = end - start, preserving x0+x1 (live=2 keeps recv and start+1).
        try beamEmitter.writeGcBif(
            self.out,
            .sub,
            @max(2, self.min_live),
            &.{ end_term, start_term },
            Dst.xr(2),
        );
        try self.emitPrimCallExt("lists", "sublist", 3, mode);
        return true;
    }

    /// `s.contains(needle)` / `s.startsWith(prefix)`: 2-arg recv-first call
    /// (`binary:match/2`, `string:prefix/2`) whose result is compared against
    /// the `nomatch` atom — the BIF returns either a positional payload
    /// (`{Start, Len}` / the tail string) or the `nomatch` sentinel, so the
    /// public boolean shape is `result =/= nomatch`. String-literal args land
    /// directly in `x1` via `emitStringLiteral` (sidestepping `simpleTerm`'s
    /// numeric-only support); register-resident args use the simple path.
    /// The call_ext runs in non-tail mode regardless of the caller — we need
    /// the result alive for the comparison — and an outer `mode == .tail`
    /// adds the trailing `emitReturn` after the boolean lands in `x0`.
    /// Matches the erlang template `(binary:match($self, $0) =/= nomatch)`
    /// / `(string:prefix($self, $0) =/= nomatch)` byte-for-byte.
    fn primCmpAgainstNomatch(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        if (cc.args.len + cc.trailing.len != 1) {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (bad arity): {s}/{d}", .{ fn_name, cc.args.len + cc.trailing.len });
            if (mode == .tail) try self.emitReturn();
            return;
        }
        try self.lowerExprIntoX0(recv_expr.*);
        // Load the needle/prefix into {x, 1} without clobbering the receiver.
        const arg = cc.args[0].value.*;
        if (arg == .literal and arg.literal.kind == .stringLit) {
            try self.emitStringLiteral(arg.literal.kind.stringLit, 1);
        } else if (self.simpleTerm(arg)) |t| {
            try beamEmitter.writeMoveOp(self.out, t, Dst.xr(1));
        } else {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (complex arg): {s}/2", .{fn_name});
            if (mode == .tail) try self.emitReturn();
            return;
        }
        try self.emitPrimCallExt(mod, fn_name, 2, .non_tail);
        // BEAM `test, is_eq, Lbl, [A, B]` falls through on `A == B` and jumps
        // on `A != B`. The boolean we want is `result =/= nomatch`, so:
        //   • fall-through (result == nomatch) → false
        //   • jump-taken (result != nomatch, i.e. found) → true
        const found_l = self.allocLabel();
        const end_l = self.allocLabel();
        try beamEmitter.writeTest(self.out, .is_eq, found_l, &.{ Op.xr(0), Op.atom("nomatch") });
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(0));
        try beamEmitter.writeJump(self.out, end_l);
        try beamEmitter.writeLabel(self.out, found_l);
        try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(0));
        try beamEmitter.writeLabel(self.out, end_l);
        if (mode == .tail) try self.emitReturn();
    }

    /// `xs.at(i)` — bounds-safe 0-based index. Lower the receiver into `x0` and
    /// the index into `x1`, then `call`/`call_last` into the lazily-emitted synth
    /// helper `'-bp_at-'/2`. The helper owns the whole bounds check
    /// (`length(L)` + `is_ge` against 0 + `is_lt` against length + `lists:nth(I
    /// + 1, L)` on the hit branch, `undefined` on miss) so the call-site stays
    /// a single `call`. Index args that aren't `simpleTerm`-reducible (a reg-
    /// resident ident or a literal int) are lowered fresh into `x1` after the
    /// receiver lands in `x0`; both common forms (`val`-bound list, literal /
    /// `val`-bound index) reduce. Matches the erlang template
    /// `(fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of
    /// true -> lists:nth(__I + 1, __L); false -> undefined end end)($self, $0)`.
    fn primAt(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = list
        const idx = cc.args[0].value.*;
        if (self.simpleTerm(idx)) |t| {
            try beamEmitter.writeMoveOp(self.out, t, Dst.xr(1));
        } else if (idx == .literal and idx.literal.kind == .numberLit) {
            // Fall-through: `simpleTerm` already handles numeric literals.
            unreachable;
        } else {
            // Complex idx — would need a stash slot across the lowering of
            // both ops. Falls back to the local-call path so the snapshot
            // records a `%% unresolved` comment instead of mis-emitting.
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (complex idx): at/2", .{});
            if (mode == .tail) try self.emitReturn();
            return;
        }
        const helper = try self.ensureAtHelper();
        const labels = try self.fnLabelsFor(helper, 2);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 2, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 2, .{ .local = labels.entry }, self.num_y),
        }
    }

    /// `xs.indexOf(item)` — linear scan returning the 0-based index of the
    /// first `item =:= xs[i]` match, or `-1` when absent. Lower the receiver
    /// into `x0` and the item into `x1`, then `call`/`call_last` into the
    /// lazily-emitted synth helper `'-bp_indexOf-'/3 (L, X, I)` which walks
    /// the list recursively via `call_only` (BEAM's tail-call form). The
    /// helper takes the running index as its 3rd arg (initially `0`) instead
    /// of capturing it in a closure — `make_fun3` here uses an empty free-var
    /// list, so a closed-over `__X` couldn't be emitted, and a 3-arg local
    /// fn is the cleanest equivalent. Matches the erlang template
    /// `(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H
    /// =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) ->
    /// -1 end, __Find(0, __L) end)($self, $0)`.
    fn primIndexOf(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = list
        const item = cc.args[0].value.*;
        if (self.simpleTerm(item)) |t| {
            try beamEmitter.writeMoveOp(self.out, t, Dst.xr(1));
        } else if (item == .literal and item.literal.kind == .stringLit) {
            try self.emitStringLiteral(item.literal.kind.stringLit, 1);
        } else {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (complex item): indexOf/2", .{});
            if (mode == .tail) try self.emitReturn();
            return;
        }
        try beamEmitter.writeMoveOp(self.out, Op.int(0), Dst.xr(2)); // x2 = starting index
        const helper = try self.ensureIndexOfHelper();
        const labels = try self.fnLabelsFor(helper, 3);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 3, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 3, .{ .local = labels.entry }, self.num_y),
        }
    }

    /// `xs.join(sep)` — render each element to an iolist piece and concatenate
    /// with `sep` between them. Lower the receiver into `x0`; `move x0,x1`
    /// holds the list while `emitMakeFun` writes the stringify closure into
    /// `x0` (live=2 keeps the list). `call_ext lists:map/2` produces a list
    /// of binary/iolist pieces; another `move x0,x1` parks it as `lists:join`'s
    /// second arg while the separator is loaded into `x0`. `call_ext
    /// lists:join/2` interleaves the separator (an iolist itself); a final
    /// `call_ext iolist_to_binary/1` flattens the whole thing to the single
    /// binary the surface type promises. Matches the erlang template
    /// `iolist_to_binary(lists:join($0, lists:map(fun(__E) -> if is_binary(__E)
    /// -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) ->
    /// __E; true -> io_lib:format("~p", [__E]) end end, $self)))`.
    fn primJoin(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        if (cc.args.len + cc.trailing.len != 1) {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (bad arity): join/{d}", .{cc.args.len + cc.trailing.len});
            if (mode == .tail) try self.emitReturn();
            return;
        }
        try self.lowerExprIntoX0(recv_expr.*); // x0 = list
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = list
        const helper = try self.ensureStringifyHelper();
        const helper_labels = try self.fnLabelsFor(helper, 1);
        // x0 = stringify closure (`make_fun3` writes x0; live=2 preserves x1).
        try self.emitMakeFun(helper_labels.entry, 2);
        // lists:map(Fun, List) → x0 = mapped iolist pieces.
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = "map" } }, 0);
        // Stage the call to lists:join(Sep, MappedList): mapped → x1, sep → x0.
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = mapped list
        const sep = cc.args[0].value.*;
        if (sep == .literal and sep.literal.kind == .stringLit) {
            try self.emitStringLiteral(sep.literal.kind.stringLit, 0);
        } else if (self.simpleTerm(sep)) |t| {
            try beamEmitter.writeMoveOp(self.out, t, Dst.xr(0));
        } else {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (complex sep): join/2", .{});
            if (mode == .tail) try self.emitReturn();
            return;
        }
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = "join" } }, 0);
        // Flatten the joined iolist into a single binary — the type the
        // method's surface signature promises.
        try self.emitPrimCallExt("erlang", "iolist_to_binary", 1, mode);
    }

    /// Emit (once per module) the synth helper backing `xs.at(i)` — owns the
    /// bounds check + `lists:nth` choreography so the call-site reduces to a
    /// single `call`. The helper takes `(L, I)` in `{x, 0}`/`{x, 1}`, spills
    /// both to y-slots so they survive the `erlang:length/1` call, then either
    /// tail-calls `lists:nth(I + 1, L)` on the hit branch or returns the
    /// `undefined` atom on miss. Cached on the emitter so repeat call sites
    /// in the same module share one helper.
    fn ensureAtHelper(self: *Emitter) anyerror![]const u8 {
        if (self.at_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'-bp_at-'");
        try self.reserveFn(name, 2);
        const labels = try self.fnLabelsFor(name, 2);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;

        const fail_l = self.allocLabel();
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, name, 2, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, name, 2);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try beamEmitter.writeAllocate(self.out, 2, 2);
        try beamEmitter.writeInitYregs(self.out, 2);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(1)); // y1 = list
        try beamEmitter.writeMoveOp(self.out, Op.xr(1), Dst.yr(0)); // y0 = index
        try beamEmitter.writeTest(self.out, .is_ge, fail_l, &.{ Op.yr(0), Op.int(0) });
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(0));
        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "length" } }, 0); // x0 = length
        try beamEmitter.writeTest(self.out, .is_lt, fail_l, &.{ Op.yr(0), Op.xr(0) });
        try beamEmitter.writeGcBif(self.out, .add, 0, &.{ Op.yr(0), Op.int(1) }, Dst.xr(0)); // x0 = I+1
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(1)); // x1 = list
        try beamEmitter.writeCall(self.out, .last, 2, .{ .ext = .{ .module = "lists", .function = "nth" } }, 2);
        try beamEmitter.writeLabel(self.out, fail_l);
        try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
        try beamEmitter.writeDeallocate(self.out, 2);
        try beamEmitter.writeReturn(self.out);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.at_helper_name = name;
        return name;
    }

    /// Emit (once per module) the synth helper backing `xs.indexOf(item)` —
    /// a 3-arg recursive walker `(L, X, I)` that tail-recurses via `call_only`
    /// with the index running through `{x, 2}`. The 3-arg form replaces the
    /// erlang template's closed-over `__X` (`make_fun3`'s free-var list is
    /// empty here). Cached on the emitter so repeat call sites share one
    /// helper. The recursion uses `call_only` (BEAM's framelessness-preserving
    /// tail call) so the linear scan doesn't grow the stack.
    fn ensureIndexOfHelper(self: *Emitter) anyerror![]const u8 {
        if (self.indexOf_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'-bp_indexOf-'");
        try self.reserveFn(name, 3);
        const labels = try self.fnLabelsFor(name, 3);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;

        const empty_l = self.allocLabel();
        const neq_l = self.allocLabel();
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, name, 3, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, name, 3);
        try beamEmitter.writeLabel(self.out, labels.entry);
        // No frame — the function uses x-regs only and tail-recurses via
        // `call_only`, so `allocate`/`deallocate` would be wasted work.
        try beamEmitter.writeTest(self.out, .is_nonempty_list, empty_l, &.{Op.xr(0)});
        try beamEmitter.writeGetList(self.out, Op.xr(0), Dst.xr(3), Dst.xr(4)); // x3 = head, x4 = tail
        try beamEmitter.writeTest(self.out, .is_eq, neq_l, &.{ Op.xr(3), Op.xr(1) });
        try beamEmitter.writeMoveOp(self.out, Op.xr(2), Dst.xr(0)); // return index
        try beamEmitter.writeReturn(self.out);
        try beamEmitter.writeLabel(self.out, neq_l);
        try beamEmitter.writeMoveOp(self.out, Op.xr(4), Dst.xr(0)); // x0 = tail
        try beamEmitter.writeGcBif(self.out, .add, 3, &.{ Op.xr(2), Op.int(1) }, Dst.xr(2)); // x2 = I+1
        try beamEmitter.writeCall(self.out, .only, 3, .{ .local = labels.entry }, 0);
        try beamEmitter.writeLabel(self.out, empty_l);
        try beamEmitter.writeMoveOp(self.out, Op.int(-1), Dst.xr(0));
        try beamEmitter.writeReturn(self.out);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.indexOf_helper_name = name;
        return name;
    }

    /// Emit (once per module) the synth helper backing the per-element
    /// stringify fun `lists:map(stringify, xs)` in `primJoin` — `(E)`
    /// dispatches on `E`'s runtime tag: `is_binary` → `E` as-is, `is_integer`
    /// → `integer_to_binary(E)`, else `io_lib:format("~p", [E])` (the iolist
    /// is flattened by the outer `iolist_to_binary` wrapper). The erlang
    /// template also has an `is_list` arm; collapsed here into the
    /// `io_lib:format` fallback since BEAM's `iolist_to_binary` accepts
    /// nested iolists either way. Cached on the emitter so a module joining
    /// several arrays shares one stringify helper.
    fn ensureStringifyHelper(self: *Emitter) anyerror![]const u8 {
        if (self.stringify_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'-bp_stringify-'");
        try self.reserveFn(name, 1);
        const labels = try self.fnLabelsFor(name, 1);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;

        const not_bin_l = self.allocLabel();
        const not_int_l = self.allocLabel();
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, name, 1, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, name, 1);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try beamEmitter.writeAllocate(self.out, 0, 1);
        try beamEmitter.writeTest(self.out, .is_binary, not_bin_l, &.{Op.xr(0)});
        try beamEmitter.writeDeallocate(self.out, 0);
        try beamEmitter.writeReturn(self.out);
        try beamEmitter.writeLabel(self.out, not_bin_l);
        try beamEmitter.writeTest(self.out, .is_integer, not_int_l, &.{Op.xr(0)});
        try beamEmitter.writeCall(self.out, .last, 1, .{ .ext = .{ .module = "erlang", .function = "integer_to_binary" } }, 0);
        try beamEmitter.writeLabel(self.out, not_int_l);
        // io_lib:format("~p", [E]) — build the `[E]` cons in x1, format
        // string in x0, then tail-call `call_ext_last`.
        try beamEmitter.writeTestHeap(self.out, 2, 1);
        try beamEmitter.writePutList(self.out, Op.xr(0), Op.nil, Dst.xr(1)); // x1 = [E]
        try beamEmitter.writeMove(self.out, Term.str("~p"), 0);
        try beamEmitter.writeCall(self.out, .last, 2, .{ .ext = .{ .module = "io_lib", .function = "format" } }, 0);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.stringify_helper_name = name;
        return name;
    }

    /// `fn(Fun, Recv)` — `lists:map`/`filter`/`foreach`. The list lands in `x1`,
    /// the closure (a positional fun arg or a trailing lambda) in `x0`.
    fn primFunThenList(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = List
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = List (x0 still List)
        try self.lowerPrimFunArg(cc, 2); // x0 = Fun (closure live=2 keeps x1)
        try self.emitPrimCallExt(mod, fn_name, 2, mode);
    }

    /// `fn(Arg, Recv)` — `lists:member`. List in `x1`, the data arg in `x0`.
    fn primArgThenList(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = List
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // x1 = List
        try self.lowerPrimFunArg(cc, 2); // x0 = Arg
        try self.emitPrimCallExt(mod, fn_name, 2, mode);
    }

    /// `fn(Recv, Arg [, Lit])` — receiver stays in `x0`; the (simple) arg goes to
    /// `x1`, with an optional literal in `x2` (`string:split(S, Sep, all)`). A
    /// non-simple arg would need to clobber `x0`, so it falls back to the limit.
    fn primRecvThenArgs(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, extra_lit: ?Op, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*); // x0 = Recv
        if (cc.args.len > 0) {
            const t = self.simpleTerm(cc.args[0].value.*) orelse {
                try beamEmitter.writeComment(self.out, "prim method not lowered on beam (complex arg): {s}/{d}", .{ fn_name, cc.args.len + 1 });
                if (mode == .tail) try self.emitReturn();
                return;
            };
            try beamEmitter.writeMoveOp(self.out, t, Dst.xr(1));
        }
        var arity: usize = 1 + cc.args.len;
        if (extra_lit) |lit| {
            try beamEmitter.writeMoveOp(self.out, lit, Dst.xr(2));
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
            try beamEmitter.writeMoveOp(self.out, Op.nil, Dst.xr(0));
        }
    }

    fn emitPrimCallExt(self: *Emitter, mod: []const u8, fn_name: []const u8, arity: usize, mode: CallMode) anyerror!void {
        try beamEmitter.writeCall(
            self.out,
            if (mode == .tail) .last else .normal,
            arity,
            .{ .ext = .{ .module = mod, .function = fn_name } },
            self.num_y,
        );
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
                const recv_term = reg.operand();
                try beamEmitter.writeMoveOp(self.out, recv_term, Dst.xr(0));
            } else {
                try beamEmitter.writeMove(self.out, Term.atomOf(rn), 0);
            }
        } else {
            try self.lowerExprIntoX0(recv_expr.*);
        }
        const scratch = self.scratchBase();
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
        const saved_live = self.min_live;
        for (args, 0..) |arg, i| {
            _ = self.raiseLive(@intCast(scratch + 1 + i));
            try self.lowerExprIntoX0(arg.value.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch + 1 + i));
        }
        self.min_live = saved_live;
        try beamEmitter.writeMoveOp(self.out, Op.xr(scratch), Dst.xr(0));
        for (0..args.len) |i| {
            try beamEmitter.writeMoveOp(self.out, Op.xr(scratch + 1 + i), Dst.xr(1 + i));
        }
        const total_arity = 1 + args.len;
        const labels = self.fnLabelsFor(mangled, total_arity) catch {
            try beamEmitter.writeComment(self.out, "unresolved extension call: {s}/{d}", .{ mangled, total_arity });
            if (mode == .tail) try self.emitReturn();
            return;
        };
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, total_arity, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, total_arity, .{ .local = labels.entry }, self.num_y),
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
            try beamEmitter.writeMove(self.out, Term.mapOf(&.{}), 0);
            return;
        }
        // Scratch slots start above every staged register and never at
        // `{x, 0}`, which each `lowerExprIntoX0` overwrites; storing a value
        // there would clobber it as soon as the next field is evaluated.
        const scratch = self.scratchBase();
        const saved_live = self.min_live;
        for (args, 0..) |arg, i| {
            if (i > 0) _ = self.raiseLive(@intCast(scratch + i));
            try self.lowerExprIntoX0(arg.value.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch + i));
        }
        self.min_live = saved_live;
        var pairs: [16]beamEmitter.MapPair = undefined;
        for (args, 0..) |arg, i| {
            const key: []const u8 = arg.label orelse if (fields != null and i < fields.?.len) fields.?[i] else "_arg";
            pairs[i] = .{ .key = Op.atom(key), .value = Op.xr(scratch + i) };
        }
        try beamEmitter.writePutMap(
            self.out,
            false,
            .{ .term = Term.mapOf(&.{}) },
            Dst.xr(0),
            scratch + n,
            pairs[0..n],
        );
    }

    /// Build a tagged tuple `{Tag, Field0, …}` from an enum variant constructor
    /// `Shape.Circle(r: 5)` → `{Circle, 5}`. The tag atom matches the one tested
    /// by `is_tagged_tuple` when the variant is pattern-matched. Result in `{x, 0}`.
    fn lowerTaggedTuple(self: *Emitter, tag: []const u8, args: anytype) anyerror!void {
        const n = args.len;
        const scratch = self.scratchBase();
        const saved_live = self.min_live;
        for (args, 0..) |arg, i| {
            if (i > 0) _ = self.raiseLive(@intCast(scratch + i));
            try self.lowerExprIntoX0(arg.value.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch + i));
        }
        self.min_live = saved_live;
        // A tuple of `n + 1` elements (tag + fields) needs `n + 2` heap words.
        try beamEmitter.writeTestHeap(self.out, n + 2, scratch + n);
        var tag_buf: [256]u8 = undefined;
        const tag_atom = try atomName(tag, &tag_buf);
        var elems: [17]Op = undefined;
        elems[0] = Op.atom(tag_atom);
        for (0..n) |i| elems[i + 1] = Op.xr(scratch + i);
        try beamEmitter.writePutTuple2(self.out, Dst.xr(0), elems[0 .. n + 1]);
    }

    /// Builtins (`@print`, `@todo`, …) map to specific BEAM call_ext targets.
    /// Fase 2 only handles `@todo` cleanly (errors out at runtime); printing
    /// and the rest of the builtins require strings/binaries (Fase 3+).
    fn lowerBuiltinCall(self: *Emitter, cc: anytype, mode: CallMode) anyerror!void {
        if (std.mem.eql(u8, cc.callee, "todo") or std.mem.eql(u8, cc.callee, "panic")) {
            const atom: []const u8 = if (std.mem.eql(u8, cc.callee, "todo")) "undef" else "panic";
            try beamEmitter.writeMove(self.out, Term.atomOf(atom), 0);
            try beamEmitter.writeCall(
                self.out,
                if (mode == .tail) .only else .normal,
                1,
                .{ .ext = .{ .module = "erlang", .function = "error" } },
                0,
            );
            return;
        }
        if (std.mem.eql(u8, cc.callee, "print")) {
            const io_kind: beamEmitter.CallKind = if (mode == .tail) .only else .normal;
            // `@print(a, b, …)` prints every argument, space-separated (parity
            // with the commonJS backend's `console.log`). Only the single-arg
            // shape keeps the original instruction sequence, so the 200-odd
            // one-argument snapshots stay byte-identical.
            if (cc.args.len > 1 and cc.args.len <= 16) {
                const n = cc.args.len;
                const base = self.scratchBase();
                const saved_live = self.min_live;
                for (cc.args, 0..) |arg, i| {
                    if (i > 0) _ = self.raiseLive(@intCast(base + i));
                    try self.lowerExprIntoX0(arg.value.*);
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(base + i));
                }
                self.min_live = saved_live;
                // Every cons cell is reserved at once: nothing between this
                // `test_heap` and the last `put_list` can run the collector.
                try beamEmitter.writeTestHeap(self.out, n * 2, base + n);
                try beamEmitter.writeMoveOp(self.out, Op.nil, Dst.xr(0));
                var i = n;
                while (i > 0) {
                    i -= 1;
                    try beamEmitter.writePutList(self.out, Op.xr(base + i), Op.xr(0), Dst.xr(0));
                }
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
                var fmt_buf: [16 * 3 + 2]u8 = undefined;
                var w: usize = 0;
                for (0..n) |k| {
                    if (k > 0) {
                        fmt_buf[w] = ' ';
                        w += 1;
                    }
                    @memcpy(fmt_buf[w..][0..2], "~p");
                    w += 2;
                }
                @memcpy(fmt_buf[w..][0..2], "~n");
                w += 2;
                try beamEmitter.writeMove(self.out, Term.str(fmt_buf[0..w]), 0);
                try beamEmitter.writeCall(self.out, io_kind, 2, .{ .ext = .{ .module = "io", .function = "format" } }, 0);
                return;
            }
            if (cc.args.len > 0) {
                try self.lowerExprIntoX0(cc.args[0].value.*);
            }
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
            try beamEmitter.writeMove(self.out, Term.str("~p~n"), 0);
            try beamEmitter.writeTestHeap(self.out, 2, 2);
            try beamEmitter.writePutList(self.out, Op.xr(1), Op.nil, Dst.xr(1));
            try beamEmitter.writeCall(self.out, io_kind, 2, .{ .ext = .{ .module = "io", .function = "format" } }, 0);
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
        try beamEmitter.writeComment(self.out, "unsupported builtin: @{s} (Fase 3+)", .{cc.callee});
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
        const disc = self.scratchBase();
        const pstash = disc + 1;

        if (std.mem.eql(u8, callee, "__bp_ok") or std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor (`return v` / `throw e` in a `-> @Result<…>` fn):
            // build the idiomatic `{ok, V}` / `{error, E}` pair.
            const tag: []const u8 = if (std.mem.eql(u8, callee, "__bp_ok")) "ok" else "error";
            try self.lowerExprIntoX0(recv.*);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(disc));
            try beamEmitter.writeTestHeap(self.out, 3, disc + 1);
            try beamEmitter.writePutTuple2(self.out, Dst.xr(0), &.{ Op.atom(tag), Op.xr(disc) });
            return;
        }

        const is_result_map = std.mem.eql(u8, callee, "__bp_result_map");
        if (is_result_map or std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            const else_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try beamEmitter.writeTest(self.out, .is_tagged_tuple, else_l, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom("ok") });
            // Ok: extract the payload, apply the fn to it. The payload sits in
            // `{x, pstash}` and must survive the closure's `test_heap`, so raise
            // the make_fun3 live floor across the fn lowering. A BEAM `Live`
            // count is a *prefix* — claiming `{x, pstash}` also claims every
            // register below it — so `{x, disc}` is filled with the subject
            // first; leaving the hole made the closure's `test_heap` report
            // `{{x, 1}, not_live}`.
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(disc));
            try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 1, Dst.xr(pstash));
            const saved_live = self.raiseLive(pstash + 1);
            try self.lowerFnInto0(arg1);
            self.min_live = saved_live;
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
            try beamEmitter.writeMoveOp(self.out, Op.xr(pstash), Dst.xr(0));
            try beamEmitter.writeCallFun(self.out, 1);
            if (is_result_map) {
                // `map` rewraps the result as `{ok, Result}`; `flatMap` expects
                // the fn to already return a `@Result`, so it passes through.
                // Stash the result in `disc` (`{x, cur_arity+1}`) — contiguous with
                // `{x, 0}` — so the rewrap `test_heap` Live count covers only live
                // registers (`x1` above it is dead after `call_fun`).
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(disc));
                try beamEmitter.writeTestHeap(self.out, 3, disc + 1);
                try beamEmitter.writePutTuple2(self.out, Dst.xr(0), &.{ Op.atom("ok"), Op.xr(disc) });
            }
            try beamEmitter.writeJump(self.out, end_l);
            // Not Ok: the `{error, E}` tuple is still in `{x, 0}` — propagate untouched.
            try beamEmitter.writeLabel(self.out, else_l);
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            const else_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try beamEmitter.writeTest(self.out, .is_tagged_tuple, else_l, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom("ok") });
            try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 1, Dst.xr(0));
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, else_l);
            try self.lowerFnInto0(arg1);
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_isOk") or std.mem.eql(u8, callee, "__bp_result_isError")) {
            const want: []const u8 = if (std.mem.eql(u8, callee, "__bp_result_isOk")) "ok" else "error";
            const false_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try beamEmitter.writeTest(self.out, .is_tagged_tuple, false_l, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom(want) });
            try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(0));
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, false_l);
            try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(0));
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            // A present option is the bare value; `undefined` marks absence.
            // Both `map` and `flatMap` simply apply the fn to a present value.
            const present_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try beamEmitter.writeTest(self.out, .is_eq, present_l, &.{ Op.xr(0), Op.atom("undefined") });
            // None: `{x, 0}` already holds `undefined`.
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, present_l);
            // `{x, disc}` is filled so the prefix `Live` count raised below has
            // no uninitialized hole (see the result `map`/`flatMap` path).
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(disc));
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(pstash));
            const saved_live = self.raiseLive(pstash + 1);
            try self.lowerFnInto0(arg1);
            self.min_live = saved_live;
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
            try beamEmitter.writeMoveOp(self.out, Op.xr(pstash), Dst.xr(0));
            try beamEmitter.writeCallFun(self.out, 1);
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            const present_l = self.allocLabel();
            const end_l = self.allocLabel();
            try self.lowerExprIntoX0(recv.*);
            try beamEmitter.writeTest(self.out, .is_eq, present_l, &.{ Op.xr(0), Op.atom("undefined") });
            // None: evaluate the default into `{x, 0}`.
            try self.lowerFnInto0(arg1);
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, present_l);
            // Present: `{x, 0}` already holds the value.
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        try beamEmitter.writeComment(self.out, "unsupported Result/Option op: {s}", .{callee});
    }

    /// Lower the fn/default argument of a Result/Option op into `{x, 0}`. A
    /// missing argument (shouldn't happen for the ops that read one) falls back
    /// to `undefined`.
    fn lowerFnInto0(self: *Emitter, arg: ?*ast.Expr) anyerror!void {
        if (arg) |a| {
            try self.lowerExprIntoX0(a.*);
        } else {
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
        }
    }

    /// Lay out call arguments into `{x, 0}..{x, arity-1}`, with any trailing
    /// lambdas (`each(xs) { x -> … }`) following the parenthesised ones.
    ///
    /// Arguments that all reduce to a `simpleTerm` (a literal, or a y-resident
    /// binding) move straight into their final register. Otherwise every
    /// argument is first staged into a scratch slot above `scratchBase()` and
    /// only then shuffled down: an argument's own lowering goes through
    /// `{x, 0}` and would overwrite an earlier argument already parked there.
    /// While argument `i` is being lowered the live floor is raised to cover
    /// the `i` slots already staged, so a `gc_bif`/`call`/closure inside it
    /// cannot drop them.
    fn materializeCallArgs(self: *Emitter, args: anytype, trailing: anytype) anyerror!void {
        const total = args.len + trailing.len;
        if (total > 16) {
            try beamEmitter.writeComment(self.out, "unsupported: call with > 16 args", .{});
            return;
        }
        var terms: [16]?Op = undefined;
        var has_complex = trailing.len > 0;
        for (args, 0..) |arg, i| {
            terms[i] = self.simpleTerm(arg.value.*);
            if (terms[i] == null) has_complex = true;
        }

        if (!has_complex) {
            for (args, 0..) |_, i| {
                try beamEmitter.writeMoveOp(self.out, terms[i].?, Dst.xr(i));
            }
            return;
        }

        const scratch_base = self.scratchBase();
        const saved_min = self.min_live;
        for (args, 0..) |arg, i| {
            if (terms[i]) |t| {
                try beamEmitter.writeMoveOp(self.out, t, Dst.xr(scratch_base + i));
            } else {
                if (i > 0) _ = self.raiseLive(@intCast(scratch_base + i));
                try self.lowerExprIntoX0(arg.value.*);
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch_base + i));
            }
        }
        for (trailing, 0..) |trail, j| {
            const slot = scratch_base + args.len + j;
            // `Live` is a prefix count, so it may only cover x-registers that
            // something has actually written. Before the first operand nothing
            // has (`main/0` + a bare trailing lambda → `{{x, 0}, not_live}`);
            // after it `{x, 0}` always holds the last lowered value.
            const live: u32 = if (args.len + j == 0) self.min_live else @intCast(slot);
            _ = self.raiseLive(live);
            try self.lowerLambda(trail, live);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(slot));
        }
        self.min_live = saved_min;
        for (0..total) |i| {
            try beamEmitter.writeMoveOp(self.out, Op.xr(scratch_base + i), Dst.xr(i));
        }
    }

    /// Build an Erlang list from an array literal. Elements are consed
    /// right-to-left via `{put_list, Elem, Tail, {x, 0}}`.
    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        if (al.spreadExpr) |se| {
            try self.lowerExprIntoX0(se.*);
        } else {
            try beamEmitter.writeMoveOp(self.out, Op.nil, Dst.xr(0));
        }
        if (al.elems.len > 0) {
            // One cons cell is reserved per element, *after* that element has
            // been evaluated. Reserving all `n * 2` words up front only works
            // when no element allocates: an element that builds a record or
            // calls a function runs the collector and the reservation is gone
            // by the time `put_list` runs (`{heap_overflow, …}` from the
            // loader — `list_literal_of_records_len`).
            const scratch = self.scratchBase();
            var i: usize = al.elems.len;
            while (i > 0) {
                i -= 1;
                // The tail accumulator is stashed here while the next element is
                // computed into `x0`; the slot must differ from `x0`, so
                // `scratchBase` floors it at 1 (a 0-arity fn like `main/0`
                // would otherwise alias `x0` and cons `[Elem | Elem]`).
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                const saved_live = self.raiseLive(scratch + 1);
                try self.lowerExprIntoX0(al.elems[i]);
                self.min_live = saved_live;
                // `{x, 0}` holds the element and `{x, scratch}` the tail — both
                // must survive the cons allocation.
                try beamEmitter.writeTestHeap(self.out, 2, scratch + 1);
                try beamEmitter.writePutList(self.out, Op.xr(0), Op.xr(scratch), Dst.xr(0));
            }
        }
    }

    /// Build an Erlang tuple from a tuple literal via `{put_tuple2, ...}`.
    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        const n = tl.elems.len;
        const scratch_base = self.scratchBase();
        const saved_live = self.min_live;
        for (tl.elems, 0..) |elem, i| {
            if (i > 0) _ = self.raiseLive(@intCast(scratch_base + i));
            try self.lowerExprIntoX0(elem);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch_base + i));
        }
        self.min_live = saved_live;
        try beamEmitter.writeTestHeap(self.out, n + 1, scratch_base + n);
        var elems: [16]Op = undefined;
        for (0..n) |i| elems[i] = Op.xr(scratch_base + i);
        try beamEmitter.writePutTuple2(self.out, Dst.xr(0), elems[0..n]);
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
        const subj = self.scratchBase();
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(subj));
        const saved_live = self.raiseLive(subj + 1);
        const restore = self.allocLabel();
        const lowered = try self.lowerComparisonAsTest(g, restore);
        if (!lowered) {
            try self.lowerExprIntoX0(g);
            try beamEmitter.writeTest(self.out, .is_eq, restore, &.{ Op.xr(0), Op.atom("true") });
        }
        self.min_live = saved_live;
        return GuardCtx{ .restore = restore, .subj = subj };
    }

    /// Counterpart to `emitGuardPre`: emit the restore block. It must be placed
    /// after the arm body's `{jump, end}` and immediately before this arm's
    /// fail label, so the failing-guard path restores the subject and flows
    /// into the next arm's pattern test.
    fn emitGuardPost(self: *Emitter, ctx: ?GuardCtx) !void {
        const c = ctx orelse return;
        try beamEmitter.writeLabel(self.out, c.restore);
        try beamEmitter.writeMoveOp(self.out, Op.xr(c.subj), Dst.xr(0));
    }

    /// Lower a `case expr { pat -> body; ... }` into a chain of BEAM test
    /// instructions with fall-through labels. Optional `pat if guard -> body`
    /// guards are honoured via `emitGuardPre`/`emitGuardPost`.
    fn lowerCase(self: *Emitter, subjects: anytype, arms: anytype) anyerror!void {
        if (subjects.len == 0) {
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
            return;
        }
        try self.lowerExprIntoX0(subjects[0]);

        const end_label = self.allocLabel();
        for (arms) |arm| {
            switch (arm.pattern) {
                .numberLit => |n| {
                    const next = self.allocLabel();
                    try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(0), Op.num(n) });
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try beamEmitter.writeJump(self.out, end_label);
                    try self.emitGuardPost(guard_ctx);
                    try beamEmitter.writeLabel(self.out, next);
                },
                .stringLit => |s| {
                    const next = self.allocLabel();
                    // The subject is stashed above the live floor while `{x, 0}`
                    // is overwritten with the literal for the comparison, and is
                    // moved back on *both* edges: falling through to the next arm
                    // with the literal still in `{x, 0}` made every later arm
                    // compare literal-against-literal (`case_string_literal_patterns`
                    // printed `hello/hi/hi`).
                    const subj = self.scratchBase();
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(subj));
                    const saved_live = self.raiseLive(subj + 1);
                    try self.emitStringLiteral(s, 0);
                    self.min_live = saved_live;
                    try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(subj), Op.xr(0) });
                    try beamEmitter.writeMoveOp(self.out, Op.xr(subj), Dst.xr(0));
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try beamEmitter.writeJump(self.out, end_label);
                    try self.emitGuardPost(guard_ctx);
                    try beamEmitter.writeLabel(self.out, next);
                    try beamEmitter.writeMoveOp(self.out, Op.xr(subj), Dst.xr(0));
                },
                .ident => |name| {
                    if (self.enum_variants.contains(name)) {
                        // A nullary enum variant (`Lt ->`) is an atom to test
                        // against, not a name to bind. Without the test the
                        // first arm swallowed every subject
                        // (`HttpMethod_name('Post')` returned `<<"GET">>`).
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(name, &vbuf);
                        const next = self.allocLabel();
                        try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(0), Op.atom(vatom) });
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try beamEmitter.writeJump(self.out, end_label);
                        try self.emitGuardPost(guard_ctx);
                        try beamEmitter.writeLabel(self.out, next);
                    } else if (std.mem.eql(u8, name, "_")) {
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try beamEmitter.writeJump(self.out, end_label);
                        try self.emitGuardPost(guard_ctx);
                    } else {
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(name, .{ .y = y_idx });
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try beamEmitter.writeJump(self.out, end_label);
                        try self.emitGuardPost(guard_ctx);
                    }
                },
                .wildcard => {
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try beamEmitter.writeJump(self.out, end_label);
                    try self.emitGuardPost(guard_ctx);
                },
                .@"or" => |pats| {
                    const arm_label = self.allocLabel();
                    for (pats) |p| {
                        switch (p) {
                            .numberLit => |n| {
                                try beamEmitter.writeTest(self.out, .is_ne_exact, arm_label, &.{ Op.xr(0), Op.num(n) });
                            },
                            else => {},
                        }
                    }
                    const next = self.allocLabel();
                    try beamEmitter.writeJump(self.out, next);
                    try beamEmitter.writeLabel(self.out, arm_label);
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try beamEmitter.writeJump(self.out, end_label);
                    try self.emitGuardPost(guard_ctx);
                    try beamEmitter.writeLabel(self.out, next);
                },
                .variant => |v| switch (v.payload) {
                    .fields => |fields| {
                        const next = self.allocLabel();
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(v.name, &vbuf);
                        try beamEmitter.writeTest(self.out, .is_tagged_tuple, next, &.{ Op.xr(0), .{ .untagged = @intCast(fields.len + 1) }, Op.atom(vatom) });
                        for (fields, 0..) |bname, i| {
                            try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), i + 1, Dst.xr(1));
                            const y_idx = self.next_y;
                            self.next_y += 1;
                            try self.reg_map.put(bname, .{ .y = y_idx });
                            try beamEmitter.writeMoveOp(self.out, Op.xr(1), Dst.yr(y_idx));
                        }
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try beamEmitter.writeJump(self.out, end_label);
                        try self.emitGuardPost(guard_ctx);
                        try beamEmitter.writeLabel(self.out, next);
                    },
                    .binding => |binding| {
                        const next = self.allocLabel();
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(v.name, &vbuf);
                        try beamEmitter.writeTest(self.out, .is_tuple, next, &.{Op.xr(0)});
                        try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 0, Dst.xr(1));
                        try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(1), Op.atom(vatom) });
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(binding, .{ .y = y_idx });
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try beamEmitter.writeJump(self.out, end_label);
                        try self.emitGuardPost(guard_ctx);
                        try beamEmitter.writeLabel(self.out, next);
                    },
                    .literals => {
                        // Literal-argument variants are not lowered specially yet.
                        const guard_ctx = try self.emitGuardPre(arm.guard);
                        try self.lowerExprIntoX0(arm.body);
                        try beamEmitter.writeJump(self.out, end_label);
                        try self.emitGuardPost(guard_ctx);
                    },
                },
                .list => |lst| {
                    const next = self.allocLabel();
                    if (lst.elems.len == 0 and lst.spread == null) {
                        try beamEmitter.writeTest(self.out, .is_nil, next, &.{Op.xr(0)});
                    } else {
                        for (lst.elems) |_| {
                            try beamEmitter.writeTest(self.out, .is_nonempty_list, next, &.{Op.xr(0)});
                            try beamEmitter.writeGetList(self.out, Op.xr(0), Dst.xr(1), Dst.xr(0));
                        }
                        if (lst.spread) |spread_name| {
                            if (spread_name.len > 0) {
                                const y_idx = self.next_y;
                                self.next_y += 1;
                                try self.reg_map.put(spread_name, .{ .y = y_idx });
                                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                            }
                        }
                    }
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try beamEmitter.writeJump(self.out, end_label);
                    try self.emitGuardPost(guard_ctx);
                    try beamEmitter.writeLabel(self.out, next);
                },
                .multi => |pats| {
                    const next = self.allocLabel();
                    for (pats, 0..) |p, i| {
                        if (i < subjects.len) {
                            switch (p) {
                                .numberLit => |n| {
                                    const subj_term = self.simpleTerm(subjects[i]) orelse blk: {
                                        try self.lowerExprIntoX0(subjects[i]);
                                        break :blk Op.xr(0);
                                    };
                                    try beamEmitter.writeTest(self.out, .is_eq, next, &.{ subj_term, Op.num(n) });
                                },
                                .wildcard => {},
                                .ident => |name| {
                                    if (!std.mem.eql(u8, name, "_")) {
                                        try self.lowerExprIntoX0(subjects[i]);
                                        const y_idx = self.next_y;
                                        self.next_y += 1;
                                        try self.reg_map.put(name, .{ .y = y_idx });
                                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                                    }
                                },
                                else => {},
                            }
                        }
                    }
                    const guard_ctx = try self.emitGuardPre(arm.guard);
                    try self.lowerExprIntoX0(arm.body);
                    try beamEmitter.writeJump(self.out, end_label);
                    try self.emitGuardPost(guard_ctx);
                    try beamEmitter.writeLabel(self.out, next);
                },
            }
        }
        try beamEmitter.writeLabel(self.out, end_label);
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
        try beamEmitter.writeTestHeapAlloc(self.out, 0, 1, @max(live, self.min_live));
        try beamEmitter.writeMakeFun3(self.out, entry_label);
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
        self.num_y = arity + self.precountLocals(lam.body);
        try self.bindParams(lam.params);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, fun_name, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, fun_name, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(arity);
        try self.emitParamSpill(arity);
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
        try beamEmitter.writeTest(self.out, .is_tagged_tuple, err_label, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom("ok") });
        try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 1, Dst.xr(0));
        try beamEmitter.writeJump(self.out, end_label);

        try beamEmitter.writeLabel(self.out, err_label);
        try self.lowerExprIntoX0(tc.handler.*);
        try beamEmitter.writeLabel(self.out, end_label);
    }

    /// Lower `start..end` → `lists:seq(Start, End)`. An open-ended range
    /// (`start..`) mirrors the Erlang backend and passes the atom `infinity`
    /// as the upper bound. Result list lands in `{x, 0}`.
    fn lowerRange(self: *Emitter, r: anytype) anyerror!void {
        // Materialize both bounds into scratch x-registers above the live
        // argument floor so neither clobbers the other while evaluating. Floor at
        // 1: a 0-arity fn (`main/0`) would otherwise stash `start` in `x0` and then
        // overwrite it computing `end` (`lists:seq(end-1, end-1)` → `[end-1]`).
        const base = self.scratchBase();

        try self.lowerExprIntoX0(r.start.*);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(base));

        if (r.end) |end| {
            // `a..b` is half-open `[a, b)` (parity with wasm/erlang/`Array.range`),
            // but `lists:seq/2` is inclusive — so the upper bound is `b - 1`.
            const saved_live = self.raiseLive(base + 1);
            try self.lowerExprIntoX0(end.*);
            self.min_live = saved_live;
            try beamEmitter.writeGcBif(self.out, .sub, @max(base + 1, self.min_live), &.{ Op.xr(0), Op.int(1) }, Dst.xr(0));
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(base + 1));
        } else {
            try beamEmitter.writeMoveOp(self.out, Op.atom("infinity"), Dst.xr(base + 1));
        }

        try beamEmitter.writeMoveOp(self.out, Op.xr(base), Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.xr(base + 1), Dst.xr(1));
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = "seq" } }, 0);
    }

    /// Lower `lhs |> rhs`: evaluate lhs, then call rhs as function with result.
    fn lowerPipeline(self: *Emitter, pl: anytype) anyerror!void {
        try self.lowerExprIntoX0(pl.lhs.*);
        switch (pl.rhs.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |name| {
                    const labels = self.fnLabelsFor(name, 1) catch {
                        try beamEmitter.writeComment(self.out, "unresolved pipeline fn: {s}/1", .{name});
                        return;
                    };
                    try beamEmitter.writeCall(self.out, .normal, 1, .{ .local = labels.entry }, 0);
                },
                else => try beamEmitter.writeComment(self.out, "unsupported pipeline rhs", .{}),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    // `lhs |> f(a, b)` → `f(lhs, a, b)`. The piped value is
                    // stashed above the staging area, the declared args are
                    // staged after it, and only then is everything shuffled
                    // into `{x, 0}..{x, n}` — materializing the args straight
                    // into their final registers would overwrite the stash.
                    const scratch = self.scratchBase();
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                    const saved_live = self.min_live;
                    for (cc.args, 0..) |arg, i| {
                        _ = self.raiseLive(@intCast(scratch + 1 + i));
                        try self.lowerExprIntoX0(arg.value.*);
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch + 1 + i));
                    }
                    self.min_live = saved_live;
                    const total = cc.args.len + 1;
                    try beamEmitter.writeMoveOp(self.out, Op.xr(scratch), Dst.xr(0));
                    for (0..cc.args.len) |i| {
                        try beamEmitter.writeMoveOp(self.out, Op.xr(scratch + 1 + i), Dst.xr(1 + i));
                    }
                    const labels = self.fnLabelsFor(cc.callee, total) catch {
                        try beamEmitter.writeComment(self.out, "unresolved pipeline fn: {s}/{d}", .{ cc.callee, total });
                        return;
                    };
                    try beamEmitter.writeCall(self.out, .normal, total, .{ .local = labels.entry }, 0);
                },
                .pipeline => |inner_pl| {
                    try self.lowerPipeline(inner_pl);
                },
            },
            else => try beamEmitter.writeComment(self.out, "unsupported pipeline rhs", .{}),
        }
    }

    fn hasYieldOrBreakValue(body: []const ast.Stmt) bool {
        for (body) |stmt| {
            switch (stmt.expr) {
                .jump => |j| switch (j.kind) {
                    .yield => return true,
                    .@"break" => |v| if (v.value != null) return true,
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
        self.num_y = arity + self.precountLocals(lp.body);
        self.in_loop_lambda = true;
        try self.bindParams(lp.params);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, fun_name, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, fun_name, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(arity);
        try self.emitParamSpill(arity);

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
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
        try self.emitMakeFun(labels.entry, 2);

        const func = if (has_map) "map" else "foreach";
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = func } }, 0);
    }

    /// Emit a string literal's lexeme content as a BEAM binary into `{x, dest}`:
    /// `{move, {literal, <<"str">>}, {x, D}}` (escapes resolved like the erlang
    /// backend, via `erlEmitter.writeBinaryFromLexeme`).
    fn emitStringLiteral(self: *Emitter, s: []const u8, dest: u32) !void {
        try beamEmitter.writeMoveOp(self.out, .{ .lexeme = s }, Dst.xr(dest));
    }

    /// Lower `receiver.member` into `{x, dest}` via `{get_map_elements, ...}`.
    /// The receiver is evaluated into x0, then the field is extracted.
    fn lowerIdentAccess(self: *Emitter, ia: anytype, loc: ast.Loc, dest: u32) anyerror!void {
        // §enum-sections F4 — `<EnumName>.<UnitVariant>` resolves to the
        // variant atom (`'__500'`), not a map read on the type name. Detect
        // the shape syntactically: receiver is a bare ident, name is
        // PascalCase or the synthesised `__<Enum>__<Path>` form, and the
        // ident isn't a value-bound register/comptime val. Mirrors the
        // erlang backend's `enum_names` lookup without needing a separate
        // map (the receiver name alone tells the codegen this is a type).
        if (ia.receiver.* == .identifier and ia.receiver.*.identifier.kind == .ident) {
            const rn = ia.receiver.*.identifier.kind.ident;
            const isPascal = rn.len > 0 and std.ascii.isUpper(rn[0]);
            const isSynth = rn.len >= 3 and rn[0] == '_' and rn[1] == '_' and std.ascii.isUpper(rn[2]);
            if ((isPascal or isSynth) and !self.reg_map.contains(rn) and self.cv.get(rn) == null) {
                try beamEmitter.writeMove(self.out, Term.atomOf(ia.member), dest);
                return;
            }
        }
        // `xs.len` / `s.length` on a primitive: inference records the receiver's
        // primitive kind at this loc, and the member is the host length op, not
        // a map key. Without this the `get_map_elements` path below fails its
        // `is_map` test and falls through leaving the *receiver* in `dest`
        // (`pts.len` printed the whole list).
        if (self.instance_lowerings.get(loc)) |il| switch (il) {
            .prim => |k| {
                try self.lowerExprIntoX0(ia.receiver.*);
                switch (k) {
                    // `string:length/1` counts graphemes, so it has to stay a
                    // real call (parity with the erlang backend).
                    .string => {
                        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "string", .function = "length" } }, 0);
                        if (dest != 0) try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(dest));
                    },
                    // `length/1` is a gc_bif, not a call: a `call_ext` here would
                    // clobber the caller-saved x-registers an enclosing argument
                    // staging is holding (`xs.slice(1, xs.length)` lost both
                    // staged args → `uninitialized_reg {x, 1}`).
                    else => try beamEmitter.writeGcBif(
                        self.out,
                        .length,
                        @max(self.min_live, 1),
                        &.{Op.xr(0)},
                        Dst.xr(dest),
                    ),
                }
                return;
            },
            .record => {},
        };

        try self.lowerExprIntoX0(ia.receiver.*);

        // `t._N` is a tuple-element access (`#(a, b)._0`), not a map field. Use the
        // runtime-checked `erlang:element(N+1, T)` BIF (1-based) rather than
        // `get_tuple_element`: the receiver is typed `any` (an assoc-fn param /
        // cross-module result), and `is_tuple` alone leaves the arity unknown, so
        // `get_tuple_element` fails the loader (`bad_type, needed t_tuple,1`).
        if (tupleIndexMember(ia.member)) |idx| {
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1)); // tuple → x1
            try beamEmitter.writeMoveOp(self.out, Op.int(idx + 1), Dst.xr(0)); // index → x0
            try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
            if (dest != 0) try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(dest));
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
            try beamEmitter.writeTest(self.out, .is_eq, present_l, &.{ Op.xr(0), Op.atom("undefined") });
            // Receiver IS `undefined` (test fell through) → result is `undefined`.
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(dest));
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, present_l);
            try beamEmitter.writeTest(self.out, .is_map, undef_l, &.{Op.xr(0)});
            try beamEmitter.writeGetMapElements(self.out, undef_l, Op.xr(0), member, Dst.xr(dest));
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, undef_l);
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(dest));
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        const fail_label = self.allocLabel();
        // Refine x0's type to map before reading a field. A locally-built map is
        // already typed, but a receiver returned from a cross-module `call_ext`
        // (`Response.ok(...)`) is typed `any` — the BEAM loader then rejects a
        // bare `get_map_elements` (`bad_type, needed t_map`). The `is_map` test
        // narrows it; on failure both fall through past the read.
        try beamEmitter.writeTest(self.out, .is_map, fail_label, &.{Op.xr(0)});
        try beamEmitter.writeGetMapElements(self.out, fail_label, Op.xr(0), member, Dst.xr(dest));
        try beamEmitter.writeLabel(self.out, fail_label);
    }

    /// Render a "simple" expression (literal number or identifier already
    /// mapped to a register) as a BEAM term in `buf`. Returns the rendered
    /// slice or null if the expression is too complex.
    fn simpleTerm(self: *Emitter, e: ast.Expr) ?Op {
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.reg_map.get(n)) |reg| return reg.operand();
                    return null;
                },
                else => return null,
            },
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| return Op.num(n),
                .null_ => return Op.atom("undefined"),
                else => return null,
            },
            .unaryOp => |un| switch (un.op) {
                .neg => switch (un.expr.*) {
                    .literal => |lit| switch (lit.kind) {
                        .numberLit => |n| return Op.negNum(n),
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

/// Render `name` as the inner text of an `{atom, _}` term — the shared BEAM
/// rule: bare when valid, otherwise single-quoted and escaped. PascalCase enum
/// tags (`Circle`) would parse as a variable and reserved words (`end`) as
/// keywords, so both get quoted; pre-quoted names pass through unchanged.
const atomName = erlEmitter.atomText;

/// A comparison lowered to a BEAM `test` instruction: the opcode plus whether
/// the operands must be swapped.
const CmpTest = struct { opcode: beamEmitter.TestOp, swap: bool };

/// Map a comparison operator to a *valid* BEAM test instruction. BEAM provides
/// only `is_lt` and `is_ge` for ordering — there is no `is_gt`/`is_le` opcode
/// (`beam_opcodes:opcode(is_gt, _)` fails to assemble), so `>` and `<=` are
/// emitted as `is_lt`/`is_ge` with the operands swapped. Returns null for
/// operators that are not comparisons.
fn comparisonTestOp(op: anytype) ?CmpTest {
    return switch (op) {
        .lt => .{ .opcode = .is_lt, .swap = false },
        .gt => .{ .opcode = .is_lt, .swap = true },
        .lte => .{ .opcode = .is_ge, .swap = true },
        .gte => .{ .opcode = .is_ge, .swap = false },
        .eq => .{ .opcode = .is_eq, .swap = false },
        .ne => .{ .opcode = .is_ne_exact, .swap = false },
        else => null,
    };
}
