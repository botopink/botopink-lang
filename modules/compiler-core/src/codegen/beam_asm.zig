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
/// `#[@External.Erlang("mod", "sym[(args)]")]` on a primitive behavior method.
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
/// `primitives.bp`. The BEAM dispatcher only handles three kinds (`Array`,
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

/// The primitive interfaces a receiver of kind `k` answers methods from, most
/// specific first — the `extends` chain of `libs/std/src/primitives.bp`
/// (`I32 extends Signed extends Integer extends Number`).
fn primIfaceChain(k: envMod.PrimKind) []const []const u8 {
    return switch (k) {
        .array => &.{"Array"},
        .string => &.{"String"},
        .bool => &.{"Bool"},
        .int => &.{ "I32", "I64", "Signed", "U32", "U64", "Integer", "Number" },
        .float => &.{ "F64", "F32", "Float", "Number" },
    };
}

/// The primitive kind whose chain contains `iface` (`Number` answers `.int`).
fn primKindForIface(iface: []const u8) ?envMod.PrimKind {
    for ([_]envMod.PrimKind{ .array, .string, .bool, .int, .float }) |k| {
        for (primIfaceChain(k)) |name| {
            if (std.mem.eql(u8, name, iface)) return k;
        }
    }
    return null;
}

// ── helpers ──────────────────────────────────────────────────────────────────

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

/// True when a number literal's token is a numeral (`42`, `-1.5`, `1e3`).
fn isNumericToken(t: []const u8) bool {
    if (t.len == 0) return false;
    for (t, 0..) |c, i| {
        if (std.ascii.isDigit(c) or c == '.' or c == '_' or c == 'e' or c == 'E') continue;
        if ((c == '-' or c == '+') and (i == 0 or t[i - 1] == 'e' or t[i - 1] == 'E')) continue;
        return false;
    }
    return std.ascii.isDigit(t[0]) or t[0] == '-' or t[0] == '+';
}

/// True when `t` is the `string` primitive.
fn isStringType(t: ?ast.TypeRef) bool {
    const ty = t orelse return false;
    return ty == .named and std.mem.eql(u8, ty.named, "string");
}

/// The numeric kind an expression statically has: an integer, a float, or a
/// number of unknown precision. Decides `+` (arithmetic vs `'__bp_add'/2`) and
/// `/` (`div` vs `'/'`). Parity with the erlang backend's `NumKind`.
const NumKind = enum { int, float, number };

/// The numeric kind a type names (`i32` → int, `f64` → float), or null.
fn numTypeKind(t: ?ast.TypeRef) ?NumKind {
    const ty = t orelse return null;
    if (ty != .named) return null;
    const n = ty.named;
    if (n.len < 2) return null;
    for (n[1..]) |ch| if (!std.ascii.isDigit(ch)) {
        return if (std.mem.eql(u8, n, "isize") or std.mem.eql(u8, n, "usize")) .int else null;
    };
    return switch (n[0]) {
        'i', 'u' => .int,
        'f' => .float,
        else => null,
    };
}

/// A float operand makes a float; two integers an integer; any other known
/// operand a number.
fn combineNum(a: ?NumKind, b: ?NumKind) ?NumKind {
    if (a == .float or b == .float) return .float;
    if (a == .int and b == .int) return .int;
    if (a != null or b != null) return .number;
    return null;
}

/// True for the builtins that print their arguments (`@print`, `@println`,
/// `@debug`) — all lowered to `'__bp_print'/1`.
fn isPrintBuiltin(callee: []const u8) bool {
    return std.mem.eql(u8, callee, "print") or std.mem.eql(u8, callee, "println") or
        std.mem.eql(u8, callee, "debug");
}

/// The bare variant name of a pattern's written path. `Shape.Circle` and the
/// dot shorthand `.Circle` are both spellings of the variant `Circle`, which is
/// the atom the constructor emits (`{'Circle', …}`); the pattern kept what the
/// author wrote, so a dotted arm tested `{atom, 'Shape.Circle'}` and never
/// matched (01's defect 1, 2026-09-18). `format.zig` round-trips the written
/// form, so the stripping belongs to the backend, not to the AST.
fn bareVariantName(written: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, written, '.')) |i| return written[i + 1 ..];
    return written;
}

/// True when a pattern's `ident` was written as a path (`Maybe.None`, `.None`):
/// §5.1 P8 — a name carrying a `.` is a variant, never a binding.
fn isVariantPath(written: []const u8) bool {
    return std.mem.indexOfScalar(u8, written, '.') != null;
}

/// True when a block's final statement is a bare value-producing expression, so
/// it is the block's value. The same set `emitLambdaBody` reads: anything else
/// (a `return`, a `val`, an assignment) runs as a statement and the block
/// answers `ok`.
fn armValueTail(e: ast.Expr) bool {
    return switch (e) {
        .literal, .identifier, .binaryOp, .unaryOp, .call, .useHook, .collection, .branch => true,
        else => false,
    };
}

/// A bare identifier expression naming a register the caller already bound —
/// the receiver and arguments a synthesised shim function hands `emitPrimMethod`.
fn shimIdent(name: []const u8) ast.Expr {
    return .{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .ident = name } } };
}

/// A bodyless `declare fn` backed by an `#[@External.<Target>]` annotation.
fn isHostDeclare(f: ast.FnDecl) bool {
    return f.isExternal() and f.body.len == 0;
}

/// True when this module must answer a `pub` host-backed `declare fn` with a
/// callable wrapper of its own. The BEAM twin of `erlang.zig`'s
/// `externalWrapperNeeded`, and the same reason: a bare call inlines the host
/// target at the CALL SITE, so a module that only DECLARES the function exported
/// nothing and defined nothing — `{exports, []}` in `std@erlang.S` — and a
/// qualified call from another module (`import { erlang } from "std"` then
/// `erlang.self()`) emitted `{call_ext, 0, {extfunc, std@erlang, self, 0}}`
/// against a module with no such function. `pub` IS the promise that the name
/// is callable from outside; whether this particular build reaches it must not
/// decide whether the module is complete
/// ([decision 64](../../../../specs/1.0.5-beta/decisions-taken.md)).
fn hostDeclareWrapperNeeded(f: ast.FnDecl) bool {
    return f.isPub and isHostDeclare(f);
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

/// A condition loop's labels, and the buffer (the frame) it is emitted into.
/// `valued` is set when the body carries a `break <value>` (decision 8 §10):
/// the loop is then an expression, every `break` leaves its value in `{x, 0}`
/// before it jumps to `exit`, and the condition's own failure path goes to
/// `fail` instead — which moves `undefined` in and falls through to `exit`.
const CondLoop = struct { top: u32, exit: u32, out: *std.Io.Writer, valued: bool = false };

/// True for a `break` / `continue` statement.
fn stmtIsLoopJump(stmt: ast.Stmt) bool {
    return switch (stmt.expr) {
        .jump => |j| j.kind == .@"break" or j.kind == .@"continue",
        else => false,
    };
}

/// True when a condition-loop body YIELDS a value — the generator protocol's
/// shape, which has no beam lowering of its own. A valued `break` is lowered
/// (decision 8 §10) and is `condLoopBreaksWithValue`'s question; the two are
/// asked separately, exactly as on erlang (`conditionLoopYieldsValue` /
/// `conditionLoopBreaksWithValue`).
fn condLoopYieldsValue(body: []const ast.Stmt) bool {
    return condLoopJumpHasValue(body, .yield);
}

/// True when a condition-loop body's `break` carries a value — the loop is then
/// an expression whose value is that `break`'s (decision 8 §10).
fn condLoopBreaksWithValue(body: []const ast.Stmt) bool {
    return condLoopJumpHasValue(body, .@"break");
}

/// True when `body` carries a `kind` jump WITH a value for the loop it belongs
/// to — directly or under an `if`, never inside a nested loop or a lambda,
/// which own their own jumps.
fn condLoopJumpHasValue(body: []const ast.Stmt, comptime kind: std.meta.Tag(ast.JumpExprOf(.untyped))) bool {
    for (body) |stmt| switch (stmt.expr) {
        .jump => |j| if (j.kind == kind) switch (j.kind) {
            .yield => |y| if (y.value != null) return true,
            .@"break" => |brk| if (brk.value != null) return true,
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                if (condLoopJumpHasValue(i.then_, kind)) return true;
                if (i.else_) |els| if (condLoopJumpHasValue(els, kind)) return true;
            },
            else => {},
        },
        else => {},
    };
    return false;
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
/// model script-level statements (names starting with `_`). A *named* val is a
/// 0-arity function; a synthetic one is a statement run by `'_botopink_main'`.
fn isSyntheticEntrypointVal(v: ast.ValDecl) bool {
    return std.mem.startsWith(u8, v.name, "_");
}

/// A synthetic statement that only calls `main()` — the entrypoint wrapper
/// already does, so it is not run a second time. Mirrors the erlang backend's
/// `isSyntheticMainEntrypointCall`.
fn isSyntheticMainCall(v: ast.ValDecl) bool {
    if (std.mem.startsWith(u8, v.name, "_main")) return true;
    return isSyntheticEntrypointVal(v) and isZeroArgMainCall(v.value.*);
}

fn isZeroArgMainCall(e: ast.Expr) bool {
    return switch (e) {
        .call => |c| switch (c.kind) {
            .call => |cc| !cc.is_builtin and cc.receiver == null and cc.args.len == 0 and
                cc.trailing.len == 0 and std.mem.eql(u8, cc.callee, "main"),
            else => false,
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |rp| isZeroArgMainCall(rp.*) else false,
            .try_ => |t| if (t) |tp| isZeroArgMainCall(tp.*) else false,
            else => false,
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| isZeroArgMainCall(g.*),
            else => false,
        },
        else => false,
    };
}

/// Arity for an `BehaviorMethod` (`self` is always present in member methods
/// and gets x0; we count it just like a regular fn param). A method whose body
/// reads `self` without declaring it (`fn inc() { self.count += 1; }`) takes the
/// receiver as an implicit first parameter.
fn methodArity(m: ast.BehaviorMethod) usize {
    return m.params.len + @intFromBool(hasImplicitSelf(m));
}

/// True when `m` reads `self` but does not declare it as its first parameter.
fn hasImplicitSelf(m: ast.BehaviorMethod) bool {
    if (m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self")) return false;
    const body = m.body orelse return false;
    return bodyMentionsSelf(body);
}

/// True when a record/struct/enum method is an associated fn — no `self`
/// receiver, so it's reachable as `Type.method(...)` and, across modules, as a
/// remote `call_ext` into the owner.
fn isAssocMethod(m: ast.BehaviorMethod) bool {
    if (hasImplicitSelf(m)) return false;
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
    // `t._N` and the bare `t.N` both read element N.
    const digits = if (member.len > 0 and member[0] == '_') member[1..] else member;
    if (digits.len == 0) return null;
    var n: u32 = 0;
    for (digits) |c| {
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
    methods: []const ast.BehaviorMethod,
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
fn countLocalsRec(em: *Emitter, body: []const ast.Stmt, count: *u32) void {
    for (body) |stmt| countLocalsInExpr(em, stmt.expr, count);
}

fn countLocalsInExpr(em: *Emitter, e: ast.Expr, count: *u32) void {
    switch (e) {
        .binding => |b| switch (b.kind) {
            .localBind => |lb| {
                count.* += 1;
                countLocalsInExpr(em, lb.value.*, count);
                if (em.isStringExpr(&em.count_strings, lb.value.*)) em.count_strings.put(lb.name, {}) catch {};
                if (em.numKind(&em.count_strings, lb.value.*)) |k| em.count_nums.put(lb.name, k) catch {};
            },
            .localBindDestruct => |lb| {
                count.* += destructYSlots(lb.pattern);
                countLocalsInExpr(em, lb.value.*, count);
            },
            .assign => |a| {
                countLocalsInExpr(em, a.value.*, count);
                if (a.op == .assign and a.target == .name) {
                    if (em.numKind(&em.count_strings, a.value.*)) |k| em.count_nums.put(a.target.name, k) catch {};
                }
                if (a.target == .fieldAccess) {
                    const fa = a.target.fieldAccess;
                    var read: ast.Expr = undefined;
                    var sum: ast.Expr = undefined;
                    const value = fieldAssignValue(fa, a.op, a.value, &read, &sum);
                    if (a.op == .plusAssign) countLocalsInExpr(em, value, count);
                    countLocalsInExpr(em, fa.receiver.*, count);
                    countStaging(em, &.{ value, fa.receiver.* }, count);
                }
                // A string `+=` builds its concatenation list on the stack.
                if (a.op == .plusAssign and a.target == .name and
                    (em.count_strings.contains(a.target.name) or em.isStringExpr(&em.count_strings, a.value.*))) count.* += 1;
            },
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                if (i.binding != null) count.* += 1;
                countLocalsInExpr(em, i.cond.*, count);
                countLocalsRec(em, i.then_, count);
                if (i.else_) |els| countLocalsRec(em, els, count);
            },
            .tryCatch => |tc| {
                count.* += 1; // the catch tag
                countLocalsInExpr(em, tc.expr.*, count);
                countLocalsInExpr(em, tc.handler.*, count);
            },
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |v| countLocalsInExpr(em, v.*, count),
            .throw_ => |v| if (v) |vv| countLocalsInExpr(em, vv.*, count),
            .@"break" => |v| if (v.value) |vv| countLocalsInExpr(em, vv.*, count),
            .yield => |y| if (y.value) |v| countLocalsInExpr(em, v.*, count),
            .try_ => |v| if (v) |vv| countLocalsInExpr(em, vv.*, count),
            .await_ => |v| countLocalsInExpr(em, v.*, count),
            else => {},
        },
        .collection => |col| switch (col.kind) {
            .behaviorLit => |il| countFieldStaging(em, il.fields, count),
            .grouped => |inner| countLocalsInExpr(em, inner.*, count),
            .case => |c| {
                for (c.subjects) |s| countLocalsInExpr(em, s, count);
                var binder_arm = false;
                for (c.arms) |arm| {
                    count.* += patternYSlots(arm.pattern);
                    if (arm.guard) |g| {
                        countLocalsInExpr(em, g, count);
                        // The subject waits on the stack across a guard that calls.
                        if (em.exprMayCall(&em.count_strings, g)) count.* += 1;
                    }
                    // A block arm runs in THIS frame (`Emitter.armBlock`), so
                    // its own bindings take this frame's y-slots; a lambda
                    // would have opened its own.
                    if (Emitter.armBlock(arm.body)) |blk| {
                        if (blk.params.len == 1) binder_arm = true;
                        countLocalsRec(em, blk.stmts, count);
                    } else {
                        countLocalsInExpr(em, arm.body, count);
                    }
                }
                // The slot `lowerCase` parks the subject in for a binder arm.
                if (binder_arm) count.* += 1;
            },
            .arrayLit => |al| {
                // One slot for the cons accumulator `lowerArrayLit` parks on
                // the stack while each element is evaluated.
                if (al.elems.len > 0) count.* += 1;
                for (al.elems) |el| countLocalsInExpr(em, el, count);
                if (al.spreadExpr) |se| countLocalsInExpr(em, se.*, count);
            },
            .tupleLit => |tl| {
                for (tl.elems) |el| countLocalsInExpr(em, el, count);
                countStaging(em, tl.elems, count);
            },
            .range => |r| {
                countLocalsInExpr(em, r.start.*, count);
                if (r.end) |end| {
                    countLocalsInExpr(em, end.*, count);
                    countStaging(em, &.{ r.start.*, end.* }, count);
                }
            },
        },
        .binaryOp => |bin| {
            // A string `+` chain is one concatenation: one stack slot for its
            // segment list, then each segment's own needs.
            if (bin.op == .add and em.isStringExpr(&em.count_strings, e)) {
                count.* += 1;
                countStringSegments(em, e, count);
                return;
            }
            countLocalsInExpr(em, bin.lhs.*, count);
            countLocalsInExpr(em, bin.rhs.*, count);
            countStaging(em, &.{ bin.lhs.*, bin.rhs.* }, count);
        },
        .unaryOp => |un| countLocalsInExpr(em, un.expr.*, count),
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.receiver) |r| countLocalsInExpr(em, r.*, count);
                for (cc.args) |arg| countLocalsInExpr(em, arg.value.*, count);
                countCallStaging(em, if (cc.receiver) |r| r.* else null, cc.args, count);
                // `@print(a, b, …)` builds its argument list on the stack.
                if (cc.is_builtin and isPrintBuiltin(cc.callee) and cc.args.len > 1) count.* += 1;
                // `@block { … }` runs its statements in this frame.
                if (cc.is_builtin and std.mem.eql(u8, cc.callee, "block")) {
                    for (cc.trailing) |t| countLocalsRec(em, t.body, count);
                }
                // Calling a module-level `val` that holds a fun parks the fun
                // on the stack while the arguments are staged (`lowerCall`).
                if (!cc.is_builtin and cc.receiver == null and em.top_vals.contains(cc.callee)) count.* += 1;
            },
            .pipeline => |pl| {
                countLocalsInExpr(em, pl.lhs.*, count);
                countLocalsInExpr(em, pl.rhs.*, count);
                if (pl.rhs.* == .call and pl.rhs.*.call.kind == .call) {
                    countCallStaging(em, pl.lhs.*, pl.rhs.*.call.kind.call.args, count);
                }
            },
        },
        .useHook => |uh| countLocalsInExpr(em, uh.kind.inner.*, count),
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| countLocalsInExpr(em, inner.*, count),
            .comptimeBlock => |cb| countLocalsRec(em, cb.body, count),
            .assert => |a| {
                countLocalsInExpr(em, a.condition.*, count);
                if (a.message) |m| countLocalsInExpr(em, m.*, count);
            },
            .assertPattern => |ap| {
                countLocalsInExpr(em, ap.expr.*, count);
                count.* += patternYSlots(ap.pattern);
                countLocalsInExpr(em, ap.expr.*, count);
                countLocalsInExpr(em, ap.handler.*, count);
            },
        },
        // `.function` (lambda) and `.loop` open their own frames — their inner
        // bindings don't consume this frame's y-slots. A two-parameter loop's
        // written index start that is neither a literal nor a local is staged
        // with the iterable (`lowerEnumerateIntoX0`).
        // A condition loop (decision 8 §10) runs in this frame: its condition
        // and body take this frame's slots.
        //
        // The **iterable** is lowered in this frame whichever loop it is
        // (`lowerLoop` materialises it before it builds the body closure, and
        // `lowerConditionLoop` re-evaluates the condition here), so its own
        // slots are this frame's: `loop ([1, 2, 3]) { x -> … }` parks the cons
        // accumulator of the array literal in a y-slot, and counting nothing
        // left the frame at `{allocate, 0, 0}` — the emitted `.S` did not
        // assemble (`{invalid_store, {y, 0}}`, "Internal consistency check
        // failed"). Over-counting only widens the frame; under-counting is a
        // loader error.
        .loop => |lp| {
            countLocalsInExpr(em, lp.iter.*, count);
            if (lp.condition) {
                countLocalsRec(em, lp.body, count);
            } else if (lp.params.len == 2) if (lp.indexRange) |ir| {
                if (ir.* == .collection and ir.collection.kind == .range) {
                    const start = ir.collection.kind.range.start.*;
                    const simple = switch (start) {
                        .literal => true,
                        .identifier => |id| id.kind == .ident and !em.top_vals.contains(id.kind.ident),
                        else => false,
                    };
                    if (!simple) countStaging(em, &.{ start, lp.iter.* }, count);
                }
            };
        },
        else => {},
    }
}

/// The value a field assignment stores: `value` for `=`, `recv.f + value` for
/// `+=` (built in the caller's `read`/`sum` nodes).
fn fieldAssignValue(fa: anytype, op: anytype, value: *ast.Expr, read: *ast.Expr, sum: *ast.Expr) ast.Expr {
    if (op != .plusAssign) return value.*;
    const loc: ast.Loc = .{ .line = 0, .col = 0 };
    read.* = .{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = .{ .receiver = fa.receiver, .member = fa.field } } } };
    sum.* = .{ .binaryOp = .{ .loc = loc, .op = .add, .lhs = read, .rhs = value } };
    return sum.*;
}

/// Stack slots `stageOperands` may take for `exprs` (`Emitter.stagingSlots`).
fn countStaging(em: *Emitter, exprs: []const ast.Expr, count: *u32) void {
    count.* += em.stagingSlots(&em.count_strings, exprs);
}

/// `countStaging` for a call's `[recv] ++ args`.
fn countCallStaging(em: *Emitter, recv: ?ast.Expr, args: anytype, count: *u32) void {
    var exprs: [Emitter.max_staged]ast.Expr = undefined;
    var n: usize = 0;
    if (recv) |r| {
        exprs[n] = r;
        n += 1;
    }
    for (args) |arg| {
        if (n == exprs.len) break;
        exprs[n] = arg.value.*;
        n += 1;
    }
    // A call on a fun-typed record field stages the arguments before the
    // field read, so a receiver that calls counts too.
    if (recv) |r| {
        if (em.exprMayCall(&em.count_strings, r)) {
            count.* += @intCast(n);
            return;
        }
    }
    countStaging(em, exprs[0..n], count);
}

fn countFieldStaging(em: *Emitter, fields: anytype, count: *u32) void {
    var exprs: [Emitter.max_staged]ast.Expr = undefined;
    for (fields, 0..) |f, i| {
        countLocalsInExpr(em, f.value.*, count);
        if (i < exprs.len) exprs[i] = f.value.*;
    }
    countStaging(em, exprs[0..@min(fields.len, exprs.len)], count);
}

fn countStringSegments(em: *Emitter, e: ast.Expr, count: *u32) void {
    if (e == .binaryOp and e.binaryOp.op == .add and em.isStringExpr(&em.count_strings, e)) {
        countStringSegments(em, e.binaryOp.lhs.*, count);
        countStringSegments(em, e.binaryOp.rhs.*, count);
        return;
    }
    countLocalsInExpr(em, e, count);
}

// ── free variables ───────────────────────────────────────────────────────────

/// Insertion-ordered name set, so a closure's captured environment — and with it
/// the emitted `make_fun3` — is deterministic.
const NameSet = std.StringArrayHashMapUnmanaged(void);

/// `collectNamesIn*` sink that records every name once, in first-use order.
const NameCollector = struct {
    alloc: std.mem.Allocator,
    set: NameSet = .empty,
    fn add(c: *NameCollector, n: []const u8) !void {
        try c.set.put(c.alloc, n, {});
    }
};

/// `collectNamesIn*` sink that only answers whether one name is mentioned.
const NameFinder = struct {
    target: []const u8,
    found: bool = false,
    fn add(c: *NameFinder, n: []const u8) !void {
        if (std.mem.eql(u8, n, c.target)) c.found = true;
    }
};

/// True when `body` reads `self` — a record/struct/enum method written without
/// a `self` parameter still receives its receiver as the first argument.
fn bodyMentionsSelf(body: []const ast.Stmt) bool {
    var finder: NameFinder = .{ .target = "self" };
    collectNamesInStmts(&finder, body) catch return false;
    return finder.found;
}

/// Every name `body` could read from an enclosing frame: identifiers, the
/// callee of an unqualified call (a local may hold a fun), assignment targets
/// and a spread's name. An over-approximation — the caller keeps only the names
/// bound in the enclosing frame, and a name the body rebinds itself is harmless
/// to capture.
fn collectNamesInStmts(ctx: anytype, body: []const ast.Stmt) anyerror!void {
    for (body) |stmt| try collectNamesInExpr(ctx, stmt.expr);
}

fn collectNamesInExpr(ctx: anytype, e: ast.Expr) anyerror!void {
    const walk = collectNamesInExpr;
    const walkBody = collectNamesInStmts;
    switch (e) {
        .literal => {},
        .identifier => |id| switch (id.kind) {
            .ident => |n| try ctx.add(n),
            .dotIdent => {},
            .identAccess => |ia| try walk(ctx, ia.receiver.*),
        },
        .binaryOp => |b| {
            try walk(ctx, b.lhs.*);
            try walk(ctx, b.rhs.*);
        },
        .unaryOp => |u| try walk(ctx, u.expr.*),
        .jump => |j| switch (j.kind) {
            .@"return", .throw_, .try_ => |v| if (v) |x| try walk(ctx, x.*),
            .await_ => |x| try walk(ctx, x.*),
            .@"break" => |b| if (b.value) |x| try walk(ctx, x.*),
            .yield => |y| if (y.value) |x| try walk(ctx, x.*),
            .@"continue" => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                try walk(ctx, i.cond.*);
                try walkBody(ctx, i.then_);
                if (i.else_) |els| try walkBody(ctx, els);
            },
            .tryCatch => |tc| {
                try walk(ctx, tc.expr.*);
                try walk(ctx, tc.handler.*);
            },
        },
        .loop => |lp| {
            try walk(ctx, lp.iter.*);
            if (lp.indexRange) |ir| try walk(ctx, ir.*);
            try walkBody(ctx, lp.body);
        },
        .binding => |b| switch (b.kind) {
            .localBind => |lb| try walk(ctx, lb.value.*),
            .localBindDestruct => |lb| try walk(ctx, lb.value.*),
            .assign => |a| {
                switch (a.target) {
                    .name => |n| try ctx.add(n),
                    .fieldAccess => |fa| try walk(ctx, fa.receiver.*),
                }
                try walk(ctx, a.value.*);
            },
        },
        .useHook => |uh| try walk(ctx, uh.kind.inner.*),
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.receiver) |r| try walk(ctx, r.*) else if (!cc.is_builtin) try ctx.add(cc.callee);
                for (cc.args) |arg| try walk(ctx, arg.value.*);
                for (cc.trailing) |t| try walkBody(ctx, t.body);
            },
            .pipeline => |pl| {
                try walk(ctx, pl.lhs.*);
                try walk(ctx, pl.rhs.*);
            },
        },
        .function => |f| try walkBody(ctx, f.kind.body),
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                for (al.elems) |el| try walk(ctx, el);
                if (al.spread) |sp| try ctx.add(sp);
                if (al.spreadExpr) |se| try walk(ctx, se.*);
            },
            .tupleLit => |tl| for (tl.elems) |el| try walk(ctx, el),
            .range => |r| {
                try walk(ctx, r.start.*);
                if (r.end) |end| try walk(ctx, end.*);
            },
            .case => |c| {
                for (c.subjects) |subj| try walk(ctx, subj);
                for (c.arms) |arm| {
                    if (arm.guard) |g| try walk(ctx, g);
                    try walk(ctx, arm.body);
                }
            },
            .grouped => |g| try walk(ctx, g.*),
            .behaviorLit => |il| for (il.fields) |f| try walk(ctx, f.value.*),
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |x| try walk(ctx, x.*),
            .comptimeBlock => |cb| try walkBody(ctx, cb.body),
            .assert => |a| {
                try walk(ctx, a.condition.*);
                if (a.message) |m| try walk(ctx, m.*);
            },
            .assertPattern => |ap| {
                try walk(ctx, ap.expr.*);
                try walk(ctx, ap.handler.*);
            },
        },
    }
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Cross-module link index — resolves an imported record's associated fn to
    // a remote `call_ext` into the owning module and an imported record literal
    // to the owner's map shape.
    var cross = try crossModule.buildIn(alloc, outputs, config.packages);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError, .typeError => try results.append(alloc, try ModuleOutput.failedModule(alloc, ct.*)),
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
                // An import this program cannot resolve to one module — the
                // index is keyed by the bare symbol name and two modules
                // export it. Backend-agnostic, reported the same way as the
                // atom fault below.
                if (cross.exportFault(ct.name)) |contest| {
                    try results.append(alloc, .{
                        .name = ct.name,
                        .src = ct.src,
                        .result = .{
                            .js = try alloc.dupe(u8, ""),
                            .comptime_script = null,
                            .diagnostic = .{ .type = .{ .message = try contest.message(alloc), .loc = null } },
                        },
                    });
                    continue;
                }
                // The atom the module will be named by must be its own: two
                // paths rendering one atom used to be a silent overwrite (or a
                // silent shadow across two output directories), which is the
                // failure this front exists to remove. Fail exactly the modules
                // involved, with a diagnostic, like a type error.
                if (cross.atomFault(ct.name)) |fault| {
                    try results.append(alloc, .{
                        .name = ct.name,
                        .src = ct.src,
                        .result = .{
                            .js = try alloc.dupe(u8, ""),
                            .comptime_script = null,
                            .diagnostic = .{ .type = .{ .message = try fault.message(alloc), .loc = null } },
                        },
                    });
                    continue;
                }
                // 06 C13 — a host-backed fn with no beam or erlang target
                // reaches the driver as a located diagnostic naming it.
                var missing: ?moduleOutput.MissingExternal = null;
                const emitted = emitBeamAsm(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, &cross, outputs, &missing) catch |err| {
                    const me = missing orelse return err;
                    try results.append(alloc, .{
                        .name = ct.name,
                        .src = ct.src,
                        .result = .{
                            .js = try alloc.dupe(u8, ""),
                            .comptime_script = null,
                            .diagnostic = try me.diagnostic(alloc),
                        },
                    });
                    continue;
                };
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = emitted.code,
                        .units = emitted.units,
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

const ExportEntry = beamEmitter.Export;

/// What one source file emits on this backend: its own `.S` module and, under
/// policy 3 of `13-module-identity`, one per `type` it declares
/// (`moduleOutput.Unit`). Both owned by the caller.
pub const EmittedBeam = struct {
    code: []u8,
    units: []moduleOutput.Unit = &.{},
};

fn emitBeamAsm(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    cross: ?*const CrossModule,
    all_outputs: []const ComptimeOutput,
    /// 06 C13 — set when the emit fails with `error.MissingExternalTarget`.
    missing: ?*?moduleOutput.MissingExternal,
) !EmittedBeam {
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

    // The BEAM module atom is the whole module path joined with `@`
    // (`std/order` → `std@order`, `web/api/http` → `web@api@http`) — a slash is
    // invalid in an unquoted module atom, and the path is what makes the atom
    // unique. It was the BASENAME, which made `models/user` and `services/user`
    // one module and let eleven `libs/std` modules shadow OTP. Cross-module
    // `call_ext` targets resolve through the same renderer
    // (`crossModule.erlAtom`, read here via `CrossModule.atomFor`), so a target
    // and the module it names can never disagree. Mirrors the Erlang backend's
    // `erl_module_name`.
    const module_atom = try crossModule.erlAtom(alloc, if (cross) |xc| xc.idOf(module_name) else .of(module_name));
    defer alloc.free(module_atom);

    var em = Emitter.init(alloc, module_atom, &body_buf.writer, comptime_vals, rewrites);
    em.module_path = module_name;
    errdefer if (missing) |slot| {
        slot.* = em.missing_external;
    };
    em.instance_lowerings = instance_lowerings;
    em.cross = cross;
    em.all_outputs = all_outputs;
    defer em.deinit();

    // Map each `implement`/`extend` block name to its target type + methods so
    // dispatch sites can resolve the mangled `'<target>_<method>'` callee.
    try em.collectExtensions(program);
    // Record/struct field orders (local + cross-imported) drive map construction
    // and cross-module associated-fn calls.
    try em.collectRecordShapes(program, all_outputs);
    // Interface associated `default fn`s (`Array.range`) resolve as local fns.
    try em.collectInterfaces(program);
    try em.collectPrimErlangDispatch(program);
    // §D2 — record every `import {<name>} from "std"` so a qualified call like
    // `math.floor(x)` lowers to a remote `math:floor(X)` instead of falling
    // through to the value-receiver path (parity with the erlang backend).
    try em.collectStdImports(program);
    try em.collectStringNames(program);

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
    //
    // Every *named* top-level `val` is a 0-arity function, whether or not the
    // module has a `main/0` (BEAM has no module-level storage): a read of it is
    // a local call. Only `_`-named synthetic statements run in order inside
    // `'_botopink_main'/0`. Parity with the erlang backend's `topValForms`.
    for (program.decls) |decl| {
        switch (decl) {
            // A host-backed `declare fn` has no body: every call lowers to
            // its host target at the call site (`lowerExternalCall`).
            .@"fn" => |f| if (!isHostDeclare(f)) try em.reserveFn(f.name, fnArityNoSelf(f)),
            .val => |v| if (!isSyntheticEntrypointVal(v)) {
                try em.reserveFn(v.name, 0);
                try em.top_vals.put(v.name, {});
            } else if (has_main_0 and !isSyntheticMainCall(v)) {
                try em.entry_stmts.append(alloc, v);
            },
            // Policy 3: a `type`'s methods belong to the TYPE's module, which
            // reserves its own labels when `emitTypeUnit` opens it. The file
            // module only records that the name IS one of its types, so a call
            // site can route into it instead of resolving a local label that no
            // longer exists.
            .type_ => |tdecl| {
                try em.own_types.put(tdecl.name, {});
                for (tdecl.methods) |m| {
                    if (m.body == null or m.is_declare) continue;
                    const key = try std.fmt.allocPrint(alloc, "{s}.{s}/{d}", .{ tdecl.name, m.name, methodArity(m) });
                    const gop = try em.own_type_methods.getOrPut(key);
                    if (gop.found_existing) alloc.free(key);
                }
            },
            .behavior => |i| try em.reserveInterfaceMethods(i),
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
            .@"fn" => |f| if (f.isPub and !isHostDeclare(f)) {
                try exports.append(alloc, .{ .name = f.name, .arity = fnArityNoSelf(f) });
            },
            // A `pub val` is reached from an importing module as a remote
            // 0-arity `call_ext` (`crossOwnerOf`), so the owner exports it.
            .val => |v| if (v.isPub and !isSyntheticEntrypointVal(v)) {
                try exports.append(alloc, .{ .name = v.name, .arity = 0 });
            },
            // Policy 3: the TYPE's module exports them (`closeTypeUnit`).
            .type_ => {},
            .implement => |im| try collectImplementExports(alloc, &exports, &owned_export_names, im),
            .extend => |ex| try collectExtendExports(alloc, &exports, &owned_export_names, ex),
            else => {},
        }
    }

    // Pass 2: emit each fn body into body_buf.
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (!isHostDeclare(f)) try em.emitFn(f),
            .val => |v| {
                if (!isSyntheticEntrypointVal(v)) {
                    try em.emitTopVal(v);
                }
            },
            .comment => |c| try beamEmitter.writeSourceComment(em.out, .{
                .level = if (c.is_module) .module else if (c.is_doc) .doc else .line,
                .text = c.text,
            }),
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => try em.emitRecord(tdecl),
                .enum_ => try em.emitEnum(tdecl),
            },
            // An interface's associated `default fn`s (`Array.range`, `Pair.of`)
            // are pure botopink — emit them as local mangled fns (`'Array_range'`).
            .behavior => |i| try em.emitInterfaceAssoc(i),
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

    // Interface `default fn`s some call site reached (a default body may reach
    // another, so the list grows while it is drained), then the run-time
    // primitive dispatch shims. A shim clause is one of those defaults' own
    // lowerings, so it can add to either list: both are drained to a fixpoint.
    try em.emitNeededDefaults();
    while (em.needed_prim_shims.count() > em.emitted_prim_shims) {
        try em.emitNeededPrimShims();
        try em.emitNeededDefaults();
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
    // Every file-level function a type module reached remotely, now that all of
    // them are lowered. Deduplicated against what is already exported.
    for (em.file_exports_needed.values()) |ref| {
        for (exports.items) |seen| {
            if (seen.arity == ref.arity and std.mem.eql(u8, seen.name, ref.name)) break;
        } else try exports.append(alloc, ref);
    }

    var header: std.Io.Writer.Allocating = .init(alloc);
    defer header.deinit();
    try beamEmitter.writeModuleForm(&header.writer, module_atom);
    try beamEmitter.writeExports(&header.writer, exports.items);
    try beamEmitter.writeAttributes(&header.writer);
    try beamEmitter.writeLabels(&header.writer, em.next_label);

    // The module is the rendered preamble, the function forms, then the
    // deferred lambda/helper forms — already-rendered sections joined, not
    // target text written here.
    var sections: std.ArrayListUnmanaged([]const u8) = .empty;
    defer sections.deinit(alloc);
    try sections.append(alloc, header.written());
    try sections.append(alloc, body_buf.written());
    try sections.appendSlice(alloc, em.deferred_lambdas.items);
    const code = try std.mem.concat(alloc, u8, sections.items);
    errdefer alloc.free(code);

    // Policy 3: the per-type modules, rendered as each unit closed. Ownership
    // moves to the caller, so `Emitter.deinit` must not free them again.
    const units = try alloc.alloc(moduleOutput.Unit, em.type_units.items.len);
    errdefer alloc.free(units);
    for (em.type_units.items, 0..) |u, i| units[i] = u;
    em.type_units.items.len = 0;
    return .{ .code = code, .units = units };
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
    /// The atom of the module being emitted — the FILE's own, or a `type`'s
    /// while `cur_type` is set. `{module, …}`, `{func_info, …}` and every
    /// `{line, …}` name it.
    module_name: []const u8,
    /// The module PATH this file came from (`std/dict`), beside `module_name`,
    /// which is the rendered atom. `crossModule.typeAtom` is given a path.
    module_path: []const u8 = "",
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),

    /// Policy 3 (`13-module-identity` half 2): every `type` declared in this
    /// file is a BEAM module of its own, `crossModule.typeAtom` — its methods
    /// live there under the names the programmer wrote, where the file's module
    /// used to hold them all as `'<Owner>_<method>'`. One entry per type in
    /// declaration order; `closeTypeUnit` renders it.
    type_units: std.ArrayListUnmanaged(moduleOutput.Unit) = .empty,
    /// The `type` whose module is being emitted, or null in the file's own.
    cur_type: ?[]const u8 = null,
    /// The `type`s THIS file declares — the ones whose methods moved out, so a
    /// call site can tell "another module of mine" from "not a type at all".
    own_types: std.StringHashMap(void),
    /// `"<Type>.<method>/<arity>"` for every bodied method one of those types
    /// declares. A method an `implement`/`extend` block gives the same type is
    /// NOT here: those stay in the file's module (an `implement` block emits no
    /// module yet), so routing them into the type's module would name a
    /// function the unit never defines.
    own_type_methods: std.StringHashMap(void),
    /// The file module's label table while a unit is open, so a call from
    /// inside the unit can recognise one of the FILE's functions and reach it
    /// remotely instead of failing to resolve. Null in the file's own module.
    file_labels: ?*std.StringHashMap(FnLabels) = null,
    /// The file module's atom while a unit is open (`module_name` is the
    /// unit's then).
    file_atom: []const u8 = "",
    /// Every file-level function a unit reached remotely, so the file module
    /// exports it. Filled during pass 2, read when the header is written —
    /// which happens after pass 2, so the list is complete.
    file_exports_needed: std.StringArrayHashMapUnmanaged(ExportEntry) = .empty,
    /// Owns the type atoms this emitter renders.
    atom_arena: std.heap.ArenaAllocator,

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
    /// 06 C13 — the host-backed fn whose beam/erlang target is missing, filled
    /// at the lowering site so `codegenEmit` reports the function name instead
    /// of the bare `MissingExternalTarget`.
    missing_external: ?moduleOutput.MissingExternal = null,
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
    /// The innermost condition loop (decision 8 §10) being emitted in this
    /// frame: its `break` jumps to `exit`, its `continue` to `top`. A lambda
    /// writes to another buffer (`out`), so its jumps never match.
    cond_loop: ?CondLoop = null,
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
    /// Every module of the compilation, for the declarations the link index
    /// does not carry (an imported enum's variants, another module's extension
    /// blocks).
    all_outputs: []const ComptimeOutput = &.{},
    /// Record/struct name → ordered field names (local decls + cross-imported).
    /// Drives `App(8080, "/")` → a `put_map_assoc` map keyed by field name.
    record_fields: std.StringHashMap([]const []const u8),
    /// Type name → the module PATH that declares it, for every type this
    /// module can name. Half 3 renders a record's tag and an enum's `__v__`
    /// variant atoms from the OWNER, so a consumer building an imported value
    /// writes the owner's atom. The BEAM twin of `erlang.zig`'s.
    type_owner_path: std.StringHashMap([]const u8),
    /// Variant name → the enum that declares it, first declaration winning.
    variant_enum: std.StringHashMap([]const u8),
    /// Enum name → its variants in DECLARATION order, each with the payload
    /// arity its tagged tuple carries. Decision 8 §4.2's `x is Shape`
    /// enumerates every tag the enum builds; the order has to be the source's,
    /// or one program would assemble two ways.
    enum_variant_names: std.StringHashMap([]const VariantShape),
    /// `"<Enum>.<Variant>"` for every enum whose variants this emit has seen.
    enum_variant_of: std.StringHashMap(void),
    /// Parameter name → its written type, for this function only: what tells a
    /// `case` which enum an unqualified arm (`.Color`) belongs to.
    local_types: std.StringHashMap([]const u8),
    /// The enum a `case` subject is of while its arms are lowered.
    enum_hint: ?[]const u8 = null,
    /// Imported record/struct name → owning module atom. A qualified call whose
    /// receiver names one (`Response.ok(...)`) lowers to a remote `call_ext`
    /// into the owner (`http:'Response_ok'(...)`).
    imported_types: std.StringHashMap([]const u8),
    /// Nullary enum variant names (`Lt`, `Ok`, …) declared in this module. A
    /// bare `.ident` case pattern naming one is a match test against the
    /// variant atom; anything else is a binding. Populated by
    /// `collectRecordShapes`.
    enum_variants: std.StringHashMap(void),
    /// Names of the enums this module declares. A PascalCase receiver that names
    /// one is a TYPE, not a module: a lowercase callee on it is an associated fn
    /// the enum declares, which `enumForms` emits as a plain local function.
    /// Parity with the erlang backend's `enum_names`.
    enum_names: std.StringHashMap(void),
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
    /// → multi-line `.S` body string with the receiver / `$0..$N` / `$args` markers
    /// (source templates are positional — the parser maps them, decision 5).
    /// Populated from `#[@External.Beam("""…""")]` (or legacy `external(beam,
    /// """…""")`) annotations on primitive interface methods. The BEAM dispatch
    /// path (`tryEmitPrimAnnotation`) consults this map FIRST — when an entry
    /// exists, the template wins over both the inline `emitPrimMethod` arm and
    /// any erlang-derived dispatch in `prim_erlang_dispatch`. Substitution
    /// convention: the receiver marker → `{x, 0}`, `$N` → `{x, N+1}`, `$args` → the
    /// comma-separated `{x, 1..N}` list. The consumer pre-loads `recv` into
    /// `x0` and each positional arg into `x_{i+1}` before rendering.
    prim_beam_templates: std.StringHashMap([]const u8),
    /// §D2 — modules imported from the `"std"` package (e.g. `import {math}
    /// from "std"` → `"math"`). A qualified call whose receiver is in this
    /// set lowers to a remote `call_ext` into the lowercase module atom,
    /// parity with the erlang backend's `std_imports` path.
    std_imports: std.StringHashMap(void),
    /// Named top-level `val`s of this module — each is a 0-arity function, so a
    /// bare reference is a local call.
    top_vals: std.StringHashMap(void),
    /// `_`-named synthetic top-level statements, run in source order by
    /// `'_botopink_main'/0` before it calls `main/0`.
    entry_stmts: std.ArrayListUnmanaged(ast.ValDecl) = .empty,
    /// Locals (and string-typed params) bound to a `string` in the frame being
    /// lowered — `isStringExpr` reads it to tell a string `+` from arithmetic.
    /// Cleared per function; a lambda/loop body inherits it (its captures).
    string_locals: std.StringHashMap(void),
    /// The same decision taken while `precountLocals` walks a body ahead of
    /// emission: a string `+` reserves a stack slot, so the count must see the
    /// bindings in the order the emission will.
    count_strings: std.StringHashMap(void),
    /// Module-level names that evaluate to a `string`: `fn … -> string` and
    /// top-level `val`s bound to a string expression.
    string_names: std.StringHashMap(void),
    /// Locals (and numeric-typed params) statically known to hold a number,
    /// with its kind (`numKind`). Cleared per function; a lambda/loop body
    /// inherits it, like `string_locals`.
    num_locals: std.StringHashMap(NumKind),
    /// `num_locals` as the count pass (`precountLocals`) sees it.
    count_nums: std.StringHashMap(NumKind),
    /// Module-level names answering a number: a `fn` declared with a numeric
    /// return type, a top-level `val` bound to a numeric expression.
    num_names: std.StringHashMap(NumKind),

    /// Lazily-emitted synth helper fns for the inline prim methods that need
    /// register stashing across calls — `xs.at(i)` (bounds-safe `lists:nth`
    /// + `undefined` fallback), `xs.indexOf(item)` (recursive linear scan),
    /// `xs.join(sep)` per-element stringify fun. Each is emitted into
    /// `deferred_lambdas` the first time it is referenced; the cached name
    /// (heap-owned, freed in `deinit`) is reused for every subsequent call
    /// site so the synth body lands once per module.
    at_helper_name: ?[]const u8 = null,
    index_helper_name: ?[]const u8 = null,
    slice_helper_name: ?[]const u8 = null,
    indexOf_helper_name: ?[]const u8 = null,
    stringify_helper_name: ?[]const u8 = null,
    print_helper_name: ?[]const u8 = null,
    add_helper_name: ?[]const u8 = null,
    eval_helper_name: ?[]const u8 = null,
    /// Owns the parsed `primitives.bp` prelude (and every key string built for
    /// the tables below) for the whole emission.
    prelude_arena: std.heap.ArenaAllocator,
    /// `declare fn`s with an `#[@External.<Target>]` annotation, from this
    /// module and from the prelude (`stringSlice1`), by name.
    externals: std.StringHashMap(ast.FnDecl),
    /// Bodied instance `default fn`s of the primitive interfaces
    /// (`"Array.fold"`), emitted on demand as `'<Iface>_<method>'(Self, …)`.
    iface_defaults: std.StringHashMap(IfaceDefault),
    /// The defaults some call site reached, in first-use order.
    needed_defaults: std.StringArrayHashMapUnmanaged(IfaceDefault) = .empty,
    /// The run-time primitive dispatch shims some untyped call site reached,
    /// keyed `"<callee>/<argc>"`, in first-use order (`ensurePrimShim`).
    needed_prim_shims: std.StringArrayHashMapUnmanaged(PrimShim) = .empty,
    /// How many of them have been emitted — the drain's watermark.
    emitted_prim_shims: usize = 0,
    /// Method names the program's own `behavior` declarations carry (the
    /// primitive interfaces excluded). A call to one of these is a user type's
    /// method that failed to resolve, never a primitive's, so it keeps the
    /// `{unresolved_method, …}` abort instead of reaching a dispatch shim.
    user_behavior_methods: std.StringHashMap(void),
    /// `"<Iface>.<method>"` for every interface method declared `-> Self`.
    self_returns: std.StringHashMap(void),
    /// The primitive kind `self` carries while an interface `default fn` body
    /// is emitted (inference recorded nothing for the prelude's bodies).
    self_prim_kind: ?envMod.PrimKind = null,
    /// The outer names a `lists:foldl` loop fun threads as its accumulator
    /// while its body is emitted — `break`/`continue` return them.
    fold_group: ?[]const []const u8 = null,
    /// Local closures (`val emit = { w -> out = out + w; }`) whose body
    /// reassigns names of the enclosing frame, keyed by the closure name,
    /// valued by those names (owned by `prelude_arena`). Such a closure takes
    /// the names as an extra argument after its own and answers their new
    /// values (`lowerMutatingClosure`); a statement-position call rebinds them
    /// (`closureMutation`). Cleared per function.
    mutating_closures: std.StringHashMap([]const []const u8),
    join_helper_name: ?[]const u8 = null,

    /// Target type and methods of an `implement`/`extend` block.
    const ExtInfo = struct { target: []const u8, methods: []const ast.ImplementMethod };

    /// An interface instance `default fn` and the interface declaring it.
    const IfaceDefault = struct { iface: []const u8, method: ast.BehaviorMethod };

    /// One `'__bp_prim_<callee>'/<argc + 1>` run-time dispatch shim an untyped
    /// call site reached. `name` is the quoted atom the call site calls.
    const PrimShim = struct { callee: []const u8, argc: usize, name: []const u8 };

    fn init(alloc: std.mem.Allocator, module_name: []const u8, out: *std.Io.Writer, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        return .{
            .alloc = alloc,
            .module_name = module_name,
            .out = out,
            .cv = cv,
            .fn_labels = std.StringHashMap(FnLabels).init(alloc),
            .own_types = std.StringHashMap(void).init(alloc),
            .own_type_methods = std.StringHashMap(void).init(alloc),
            .atom_arena = std.heap.ArenaAllocator.init(alloc),
            .reg_map = std.StringHashMap(Reg).init(alloc),
            .rewrites = rewrites,
            .ext_by_name = std.StringHashMap(ExtInfo).init(alloc),
            .record_fields = std.StringHashMap([]const []const u8).init(alloc),
            .type_owner_path = std.StringHashMap([]const u8).init(alloc),
            .variant_enum = std.StringHashMap([]const u8).init(alloc),
            .enum_variant_names = std.StringHashMap([]const VariantShape).init(alloc),
            .enum_variant_of = std.StringHashMap(void).init(alloc),
            .local_types = std.StringHashMap([]const u8).init(alloc),
            .imported_types = std.StringHashMap([]const u8).init(alloc),
            .enum_variants = std.StringHashMap(void).init(alloc),
            .enum_names = std.StringHashMap(void).init(alloc),
            .interface_assoc = std.StringHashMap(void).init(alloc),
            .user_behavior_methods = std.StringHashMap(void).init(alloc),
            .prim_erlang_dispatch = std.StringHashMap(PrimErlangCall).init(alloc),
            .prim_beam_templates = std.StringHashMap([]const u8).init(alloc),
            .std_imports = std.StringHashMap(void).init(alloc),
            .top_vals = std.StringHashMap(void).init(alloc),
            .prelude_arena = std.heap.ArenaAllocator.init(alloc),
            .externals = std.StringHashMap(ast.FnDecl).init(alloc),
            .iface_defaults = std.StringHashMap(IfaceDefault).init(alloc),
            .self_returns = std.StringHashMap(void).init(alloc),
            .string_locals = std.StringHashMap(void).init(alloc),
            .count_strings = std.StringHashMap(void).init(alloc),
            .string_names = std.StringHashMap(void).init(alloc),
            .num_locals = std.StringHashMap(NumKind).init(alloc),
            .count_nums = std.StringHashMap(NumKind).init(alloc),
            .num_names = std.StringHashMap(NumKind).init(alloc),
            .mutating_closures = std.StringHashMap([]const []const u8).init(alloc),
        };
    }

    fn deinit(self: *Emitter) void {
        var it = self.fn_labels.iterator();
        while (it.next()) |kv| self.alloc.free(kv.key_ptr.*);
        self.fn_labels.deinit();
        self.own_types.deinit();
        var otm = self.own_type_methods.keyIterator();
        while (otm.next()) |k| self.alloc.free(k.*);
        self.own_type_methods.deinit();
        for (self.type_units.items) |u| {
            self.alloc.free(u.atom);
            self.alloc.free(u.code);
        }
        self.type_units.deinit(self.alloc);
        self.file_exports_needed.deinit(self.alloc);
        self.atom_arena.deinit();
        self.reg_map.deinit();
        for (self.deferred_lambdas.items) |s| self.alloc.free(s);
        self.deferred_lambdas.deinit(self.alloc);
        self.ext_by_name.deinit();
        var rf = self.record_fields.valueIterator();
        while (rf.next()) |names| self.alloc.free(names.*);
        self.record_fields.deinit();
        self.type_owner_path.deinit();
        self.variant_enum.deinit();
        {
            var evn_it = self.enum_variant_names.valueIterator();
            while (evn_it.next()) |names| self.alloc.free(names.*);
        }
        self.enum_variant_names.deinit();
        {
            var evo_it = self.enum_variant_of.keyIterator();
            while (evo_it.next()) |k| self.alloc.free(k.*);
        }
        self.enum_variant_of.deinit();
        self.local_types.deinit();
        self.imported_types.deinit();
        self.enum_variants.deinit();
        self.enum_names.deinit();
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
        self.top_vals.deinit();
        self.entry_stmts.deinit(self.alloc);
        self.string_locals.deinit();
        self.count_strings.deinit();
        self.string_names.deinit();
        self.num_locals.deinit();
        self.count_nums.deinit();
        self.num_names.deinit();
        self.mutating_closures.deinit();
        if (self.add_helper_name) |n| self.alloc.free(n);
        if (self.print_helper_name) |n| self.alloc.free(n);
        if (self.join_helper_name) |n| self.alloc.free(n);
        if (self.eval_helper_name) |n| self.alloc.free(n);
        self.externals.deinit();
        self.iface_defaults.deinit();
        self.needed_defaults.deinit(self.alloc);
        self.user_behavior_methods.deinit();
        for (self.needed_prim_shims.keys()) |k| self.alloc.free(k);
        for (self.needed_prim_shims.values()) |v| self.alloc.free(v.name);
        self.needed_prim_shims.deinit(self.alloc);
        self.self_returns.deinit();
        self.prelude_arena.deinit();
        if (self.at_helper_name) |n| self.alloc.free(n);
        if (self.index_helper_name) |n| self.alloc.free(n);
        if (self.slice_helper_name) |n| self.alloc.free(n);
        if (self.indexOf_helper_name) |n| self.alloc.free(n);
        if (self.stringify_helper_name) |n| self.alloc.free(n);
    }

    /// §A5: collect `#[@External.Erlang(…)]` annotations on primitive behavior
    /// methods into `prim_erlang_dispatch`. Scans `program.decls` first and
    /// reparses the embedded `primitives.bp` so the table sees every prim
    /// interface (`Array`/`String`/`Bool`) even when none made it into the
    /// transformed program. Mirrors the erlang backend's collector — the same
    /// `PrimErlangCall` type drives both, but the dispatcher in each backend
    /// translates the template shape into its own emission convention.
    fn collectPrimErlangDispatch(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| {
            if (decl != .behavior) continue;
            try self.collectIfaceErlangDispatch(decl.behavior);
        }
        const arena = self.prelude_arena.allocator();
        var lx = lexerMod.Lexer.init(prelude.primitives);
        const tokens = lx.scanAll(arena) catch return;
        var p = parserMod.Parser.init(tokens);
        const prim_program = p.parse(arena) catch return;
        for (prim_program.decls) |decl| {
            if (decl != .behavior) continue;
            try self.collectIfaceErlangDispatch(decl.behavior);
        }
        for (program.decls) |decl| switch (decl) {
            .behavior => |i| {
                if (primKindForIface(i.name) != null) continue;
                for (i.methods) |m| try self.user_behavior_methods.put(m.name, {});
            },
            else => {},
        };
        // The program's own declarations win; the prelude fills the rest.
        try self.collectDefaultsAndExternals(program.decls);
        try self.collectDefaultsAndExternals(prim_program.decls);
    }

    /// Index the bodied instance `default fn`s and the `-> Self` methods of
    /// every interface in `decls`, and every host-backed `declare fn`.
    fn collectDefaultsAndExternals(self: *Emitter, decls: []const ast.DeclKind) !void {
        const arena = self.prelude_arena.allocator();
        for (decls) |decl| switch (decl) {
            .behavior => |i| for (i.methods) |m| {
                const key = try std.fmt.allocPrint(arena, "{s}.{s}", .{ i.name, m.name });
                if (m.returnType) |rt| {
                    if (rt == .named and std.mem.eql(u8, rt.named, "Self")) try self.self_returns.put(key, {});
                }
                if (!m.is_default or m.body == null) continue;
                if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
                if (self.iface_defaults.contains(key)) continue;
                try self.iface_defaults.put(key, .{ .iface = i.name, .method = m });
            },
            .@"fn" => |f| if (f.isExternal() and f.body.len == 0 and !self.externals.contains(f.name)) {
                try self.externals.put(f.name, f);
            },
            else => {},
        };
    }

    fn collectIfaceErlangDispatch(self: *Emitter, iface: ast.BehaviorDecl) !void {
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
            // separate `#[@External.Beam(…)]` is used in `primitives.bp`), so
            // either an `inline: true` on the erlang annotation OR on an
            // explicit beam one marks the method irreducible on BEAM.
            if (hasExternalInline(m.annotations, "erlang") or
                hasExternalInline(m.annotations, "beam")) continue;
            const key = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ iface.name, m.name });
            if (self.prim_erlang_dispatch.contains(key)) {
                self.alloc.free(key);
                continue;
            }
            // A `$`-marker template is Erlang source kept whole: its own
            // parentheses are not a `sym(args)` argument order.
            if (primOpTemplate.looksLikeTemplate(ref.symbol)) {
                try self.prim_erlang_dispatch.put(key, .{
                    .module = try self.alloc.dupe(u8, ref.module),
                    .symbol = try self.alloc.dupe(u8, ref.symbol),
                    .args = null,
                });
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
            .behavior => |i| {
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

    /// §D2 — the module atom of a `"std"` package module imported by its bare name
    /// (`order` → `std@order`). The bare segment used to be the atom, which is
    /// how eleven `libs/std` modules shadowed the OTP module of the same name.
    /// `buf` holds the path while the index is consulted; the returned slice is
    /// either the index's own or `seg` itself, and it is written out before the
    /// buffer dies.
    fn stdModuleAtom(self: *const Emitter, seg: []const u8, buf: []u8) []const u8 {
        const path = std.fmt.bufPrint(buf, "std/{s}", .{seg}) catch return seg;
        if (self.cross) |xc| if (xc.atoms.get(path)) |a| return a;
        return seg;
    }

    /// Records every module name imported from the "std" package: a qualified
    /// call `<mod>.<callee>(args)` whose receiver names one lowers to a remote
    /// `call_ext` into that module's atom. Parity with the erlang backend's
    /// `collectStdImports`.
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
    fn reserveInterfaceMethods(self: *Emitter, i: ast.BehaviorDecl) !void {
        for (i.methods) |m| {
            if (!m.is_default or m.body == null or !isAssocMethod(m)) continue;
            try self.reserveMethod(i.name, m.name, methodArity(m));
        }
    }

    /// Emit an interface's associated `default fn`s as local mangled fns (pass 2).
    fn emitInterfaceAssoc(self: *Emitter, i: ast.BehaviorDecl) !void {
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
    fn collectRecordShapes(self: *Emitter, program: ast.Program, all_outputs: []const ComptimeOutput) !void {
        for (program.decls) |decl| switch (decl) {
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => {
                    const fields = try self.alloc.alloc([]const u8, tdecl.recordFields().len);
                    for (tdecl.recordFields(), 0..) |f, i| fields[i] = f.name;
                    try self.record_fields.put(tdecl.name, fields);
                    try self.type_owner_path.put(tdecl.name, self.module_path);
                },
                .enum_ => {
                    try self.enum_names.put(tdecl.name, {});
                    try self.type_owner_path.put(tdecl.name, self.module_path);
                    try self.rememberVariantOrder(tdecl.name, tdecl.variants());
                    for (tdecl.variants()) |v| {
                        try self.enum_variants.put(v.name, {});
                        _ = try self.variant_enum.getOrPutValue(v.name, tdecl.name);
                        try self.rememberEnumVariant(tdecl.name, v.name);
                    }
                },
            },
            // A nullary enum variant is an atom, so a bare `Lt ->` case arm is a
            // *test* against that atom, not a binding. Parity with the erlang
            // backend's `enum_variants` (`erlang.zig` `collectTypeShapes`).
            else => {},
        };
        // A `from "std"` module import (`import {order} from "std"`) brings the
        // module's enums along: their variants are case-arm atoms too.
        for (program.decls) |decl| switch (decl) {
            .use => |u| {
                const from_std = switch (u.source) {
                    .module => |m| std.mem.eql(u8, m, "std"),
                    .root => false,
                };
                if (!from_std) continue;
                for (u.imports) |imp| {
                    const mod = imp.segments[imp.segments.len - 1];
                    for (all_outputs) |*other| {
                        if (!std.mem.eql(u8, crossModule.moduleBasename(other.name), mod)) continue;
                        const ok = switch (other.outcome) {
                            .ok => |*o| o,
                            else => continue,
                        };
                        for (ok.transformed.decls) |d| switch (d) {
                            .type_ => |e| {
                                if (e.isRecord()) continue;
                                _ = try self.type_owner_path.getOrPutValue(e.name, other.name);
                                try self.rememberVariantOrder(e.name, e.variants());
                                for (e.variants()) |v| {
                                    try self.enum_variants.put(v.name, {});
                                    _ = try self.variant_enum.getOrPutValue(v.name, e.name);
                                    try self.rememberEnumVariant(e.name, v.name);
                                }
                            },
                            else => {},
                        };
                    }
                }
            },
            else => {},
        };
        const xc = self.cross orelse return;
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const name = imp.name();
                // Resolved through the import's own `from "<mod>"`, not by the
                // bare name: several modules of a program may export one name
                // and `exports.get` answered with whichever the walk reached
                // last. A contest is refused in the driver, not guessed here.
                const info = xc.picked(name, u.source, null) orelse continue;
                const owner = self.atomOf(info.module);
                if (std.mem.eql(u8, owner, self.module_name)) continue;
                switch (info.kind) {
                    // An imported record is built with the owner's field order,
                    // and its methods and associated fns are remote calls into
                    // the TYPE's module (policy 3), not the owner file's.
                    .record => {
                        if (!self.record_fields.contains(name)) {
                            try self.record_fields.put(name, try self.alloc.dupe([]const u8, info.fields));
                        }
                        try self.imported_types.put(name, try crossModule.typeAtom(self.atom_arena.allocator(), self.idOf(info.module), name));
                        _ = try self.type_owner_path.getOrPutValue(name, info.module);
                    },
                    // An imported enum's nullary variants are atoms a `case`
                    // arm tests against, exactly like a local enum's.
                    .@"enum" => for (all_outputs) |*other| {
                        if (!std.mem.eql(u8, other.name, info.module)) continue;
                        const ok = switch (other.outcome) {
                            .ok => |*o| o,
                            else => continue,
                        };
                        for (ok.transformed.decls) |d| switch (d) {
                            .type_ => |e| if (!e.isRecord() and std.mem.eql(u8, e.name, name)) {
                                _ = try self.type_owner_path.getOrPutValue(e.name, info.module);
                                try self.rememberVariantOrder(e.name, e.variants());
                                for (e.variants()) |v| {
                                    try self.enum_variants.put(v.name, {});
                                    _ = try self.variant_enum.getOrPutValue(v.name, e.name);
                                    try self.rememberEnumVariant(e.name, v.name);
                                }
                            },
                            else => {},
                        };
                    },
                    else => {},
                }
            },
            else => {},
        };
    }

    /// The runtime tag atom of a variant pattern. `@Result` is `{ok, V}` /
    /// `{error, E}` (built by the `#[@result]` transform), so its `Ok`/`Err`
    /// arms test those lowercase tags; a user enum variant of the same name
    /// keeps its own. Parity with the erlang backend's `variantTag`.
    fn variantTag(self: *Emitter, written: []const u8) []const u8 {
        const name = bareVariantName(written);
        if (self.enum_variants.contains(name)) return self.qualifiedVariantTag(written, name) orelse name;
        if (std.mem.eql(u8, name, "Ok")) return "ok";
        if (std.mem.eql(u8, name, "Err") or std.mem.eql(u8, name, "Error")) return "error";
        return name;
    }

    /// Half 3 (decision 21): the tag of a variant this emit can place is
    /// `crossModule.variantAtom` — its enum and the enum's module. Null when no
    /// enum here declares the name.
    fn qualifiedVariantTag(self: *Emitter, written: []const u8, bare: []const u8) ?[]const u8 {
        const enum_name = self.enumOfVariantPath(written, bare) orelse return null;
        return self.variantTagAtom(enum_name, bare) catch null;
    }

    /// The tag of a variant whose enum the site already names.
    fn qualifiedVariantTagOf(self: *Emitter, enum_name: []const u8, variant: []const u8) ?[]const u8 {
        return self.variantTagAtom(enum_name, variant) catch null;
    }

    fn variantTagAtom(self: *Emitter, enum_name: []const u8, variant: []const u8) ![]const u8 {
        return crossModule.variantAtom(self.atom_arena.allocator(), self.idOf(self.typeOwnerPath(enum_name)), enum_name, variant);
    }

    /// Decision 21's T2 tag: element 1 of every value `type_name` builds.
    fn recordTagAtom(self: *Emitter, type_name: []const u8) ![]const u8 {
        return crossModule.typeAtom(self.atom_arena.allocator(), self.idOf(self.typeOwnerPath(type_name)), type_name);
    }

    /// The module path that DECLARES `type_name`. A synthesised inner enum
    /// (§enum-sections F4, `__Token__Color`) is re-synthesised in every module
    /// that writes the section path, so the OUTER enum's owner is its identity.
    fn typeOwnerPath(self: *const Emitter, type_name: []const u8) []const u8 {
        if (sectionOuterEnum(type_name)) |outer| return self.typeOwnerPath(outer);
        if (self.type_owner_path.get(type_name)) |path| return path;
        if (self.cross) |xc| if (xc.exports.get(type_name)) |info| switch (info.kind) {
            .record, .@"enum" => return info.module,
            else => {},
        };
        return self.module_path;
    }

    /// The enum a written variant path belongs to.
    fn enumOfVariantPath(self: *const Emitter, written: []const u8, bare: []const u8) ?[]const u8 {
        if (std.mem.lastIndexOfScalar(u8, written, '.')) |dot| {
            if (dot > 0) {
                const head = written[0..dot];
                const start = if (std.mem.lastIndexOfScalar(u8, head, '.')) |d| d + 1 else 0;
                const seg = head[start..];
                if (self.enum_names.contains(seg)) return seg;
            }
        }
        if (self.enum_hint) |hint| if (self.enumDeclaresVariant(hint, bare)) return hint;
        return self.variant_enum.get(bare);
    }

    /// The enum a `case` subject belongs to, when this emit can place it.
    fn enumOfSubject(self: *const Emitter, subject: ast.Expr) ?[]const u8 {
        const name = switch (subject) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| n,
                else => return null,
            },
            else => return null,
        };
        if (std.mem.eql(u8, name, "self")) {
            if (self.cur_type) |ct| if (self.enum_names.contains(ct)) return ct;
        }
        const written = self.local_types.get(name) orelse return null;
        if (self.enum_names.contains(written)) return written;
        // A section path is WRITTEN dotted (`Token.Bg`) and DECLARED under the
        // F1 mangling (`__Token__Bg`).
        if (std.mem.indexOfScalar(u8, written, '.') != null) {
            var buf: [256]u8 = undefined;
            var len: usize = 0;
            var it = std.mem.splitScalar(u8, written, '.');
            while (it.next()) |seg| {
                if (len + 2 + seg.len > buf.len) return null;
                buf[len] = '_';
                buf[len + 1] = '_';
                @memcpy(buf[len + 2 ..][0..seg.len], seg);
                len += 2 + seg.len;
            }
            if (self.enum_names.getKey(buf[0..len])) |declared| return declared;
        }
        return null;
    }

    /// Whether `enum_name` declares `variant` (`enum_variant_of`, keyed
    /// `<Enum>.<Variant>`). The beam twin of `erlang.zig`'s `isEnumVariantOf`.
    fn enumDeclaresVariant(self: *const Emitter, enum_name: []const u8, variant: []const u8) bool {
        var buf: [512]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ enum_name, variant }) catch return false;
        return self.enum_variant_of.contains(key);
    }

    /// Record an enum's variant names in declaration order (§4.2's `is`).
    fn rememberVariantOrder(self: *Emitter, enum_name: []const u8, variants: []const ast.EnumVariant) !void {
        if (self.enum_variant_names.contains(enum_name)) return;
        const shapes = try self.alloc.alloc(VariantShape, variants.len);
        for (variants, 0..) |v, i| shapes[i] = .{ .name = v.name, .fields = v.fields.len };
        try self.enum_variant_names.put(enum_name, shapes);
    }

    /// Record `<Enum>.<Variant>`; the key is duped, as the erlang backend's is.
    fn rememberEnumVariant(self: *Emitter, enum_name: []const u8, variant: []const u8) !void {
        const key = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ enum_name, variant });
        const gop = try self.enum_variant_of.getOrPut(key);
        if (gop.found_existing) self.alloc.free(key);
    }

    /// One variant of an enum: its written name and the number of payload
    /// fields its tagged tuple carries (0 for a unit variant, an atom).
    const VariantShape = struct { name: []const u8, fields: usize };

    /// The range an integer spelling admits, or null when the name is not an
    /// integer type. The beam twin of `erlang.zig`'s `integerPatternRange`.
    fn integerPatternRange(name: []const u8) ?struct { lo: ?[]const u8, hi: ?[]const u8 } {
        const table = .{
            .{ "i8", "-128", "127" },                .{ "i16", "-32768", "32767" },
            .{ "i32", "-2147483648", "2147483647" }, .{ "u8", "0", "255" },
            .{ "u16", "0", "65535" },                .{ "u32", "0", "4294967295" },
        };
        inline for (table) |row| {
            if (std.mem.eql(u8, name, row[0])) return .{ .lo = row[1], .hi = row[2] };
        }
        if (std.mem.eql(u8, name, "i64") or std.mem.eql(u8, name, "int") or
            std.mem.eql(u8, name, "isize")) return .{ .lo = null, .hi = null };
        if (std.mem.eql(u8, name, "u64") or std.mem.eql(u8, name, "uint") or
            std.mem.eql(u8, name, "usize")) return .{ .lo = "0", .hi = null };
        return null;
    }

    /// Decision 8 §4.2 — the run-time test of `T` against the value in
    /// `{x, 0}`, as a branch: the emitted tests FALL THROUGH when the value is
    /// a `T` and jump to `fail` when it is not, leaving `{x, 0}` untouched.
    /// A named `type` is what half 3 made testable — a record by its tag and
    /// arity, an enum by every tag it builds. Answers false when the type has
    /// no run-time test (a function type, a comptime type parameter), and the
    /// caller then jumps to `fail` unconditionally.
    fn emitTypeTestBranch(self: *Emitter, t: ast.TypeRef, fail: u32) anyerror!bool {
        switch (t) {
            .named => |n| {
                if (std.mem.eql(u8, n, "string")) {
                    try beamEmitter.writeTest(self.out, .is_binary, fail, &.{Op.xr(0)});
                    return true;
                }
                if (std.mem.eql(u8, n, "bool")) {
                    try beamEmitter.writeTest(self.out, .is_boolean, fail, &.{Op.xr(0)});
                    return true;
                }
                if (std.mem.eql(u8, n, "f32") or std.mem.eql(u8, n, "f64") or std.mem.eql(u8, n, "float")) {
                    try beamEmitter.writeTest(self.out, .is_float, fail, &.{Op.xr(0)});
                    return true;
                }
                // Decision 8 §2: `unknown` is every value.
                if (std.mem.eql(u8, n, "unknown") or std.mem.eql(u8, n, "any")) return true;
                if (integerPatternRange(n)) |range| {
                    try beamEmitter.writeTest(self.out, .is_integer, fail, &.{Op.xr(0)});
                    if (range.lo) |lo| try beamEmitter.writeTest(self.out, .is_ge, fail, &.{ Op.xr(0), Op.num(lo) });
                    if (range.hi) |hi| try beamEmitter.writeTest(self.out, .is_ge, fail, &.{ Op.num(hi), Op.xr(0) });
                    return true;
                }
                if (self.record_fields.get(n)) |fields| {
                    var tag_buf: [512]u8 = undefined;
                    const tag = try atomName(try self.recordTagAtom(n), &tag_buf);
                    try beamEmitter.writeTest(self.out, .is_tagged_tuple, fail, &.{
                        Op.xr(0),
                        .{ .untagged = @as(i64, @intCast(fields.len + 1)) },
                        Op.atom(tag),
                    });
                    return true;
                }
                if (self.enum_variant_names.get(n)) |variants| {
                    const ok_l = self.allocLabel();
                    for (variants) |v| {
                        const tag = self.qualifiedVariantTagOf(n, v.name) orelse v.name;
                        var tag_buf: [512]u8 = undefined;
                        const tag_atom = try atomName(tag, &tag_buf);
                        if (v.fields > 0) {
                            const skip = self.allocLabel();
                            try beamEmitter.writeTest(self.out, .is_tagged_tuple, skip, &.{
                                Op.xr(0),
                                .{ .untagged = @as(i64, @intCast(v.fields + 1)) },
                                Op.atom(tag_atom),
                            });
                            try beamEmitter.writeJump(self.out, ok_l);
                            try beamEmitter.writeLabel(self.out, skip);
                        } else {
                            // `is_ne_exact` branches when the two ARE equal.
                            try beamEmitter.writeTest(self.out, .is_ne_exact, ok_l, &.{ Op.xr(0), Op.atom(tag_atom) });
                        }
                    }
                    try beamEmitter.writeJump(self.out, fail);
                    try beamEmitter.writeLabel(self.out, ok_l);
                    return true;
                }
                return false;
            },
            .array => {
                try beamEmitter.writeTest(self.out, .is_list, fail, &.{Op.xr(0)});
                return true;
            },
            .generic => |g| {
                if (std.mem.eql(u8, g.name, "Array")) {
                    try beamEmitter.writeTest(self.out, .is_list, fail, &.{Op.xr(0)});
                    return true;
                }
                return self.emitTypeTestBranch(.{ .named = g.name }, fail);
            },
            .optional => |inner| {
                const ok_l = self.allocLabel();
                try beamEmitter.writeTest(self.out, .is_ne_exact, ok_l, &.{ Op.xr(0), Op.atom("undefined") });
                const ok = try self.emitTypeTestBranch(inner.*, fail);
                try beamEmitter.writeLabel(self.out, ok_l);
                return ok;
            },
            .tuple_, .labeledTuple => {
                const elems = t.tupleElems().?;
                try beamEmitter.writeTest(self.out, .is_tuple, fail, &.{Op.xr(0)});
                try beamEmitter.writeTest(self.out, .test_arity, fail, &.{ Op.xr(0), .{ .untagged = @as(i64, @intCast(elems.len)) } });
                // The ELEMENT types are not tested: reading one is a call, and a
                // call frees the register the remaining tests read. The erlang
                // twin does test them (a guard may call `element/2`), so a
                // tuple `is` is narrower here — written down in `AGENTS.md`,
                // not passed off as the same test.
                return true;
            },
            .function, .typeparam => return false,
        }
    }

    /// `x is T` in expression position: `true` or `false` in `{x, 0}`.
    fn lowerIsCall(self: *Emitter, cc: anytype) anyerror!void {
        const t = cc.isType orelse return error.InvalidArgs;
        if (cc.args.len != 1) return error.InvalidArgs;
        try self.lowerExprIntoX0(cc.args[0].value.*);
        const fail = self.allocLabel();
        const end = self.allocLabel();
        const testable = try self.emitTypeTestBranch(t, fail);
        if (!testable) try beamEmitter.writeJump(self.out, fail);
        try beamEmitter.writeMoveOp(self.out, Op.atom("true"), Dst.xr(0));
        try beamEmitter.writeJump(self.out, end);
        try beamEmitter.writeLabel(self.out, fail);
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(0));
        try beamEmitter.writeLabel(self.out, end);
    }

    /// The position of `name` in a record's declared field order.
    fn fieldIndexOf(fields: []const []const u8, name: []const u8) ?usize {
        for (fields, 0..) |f, i| if (std.mem.eql(u8, f, name)) return i;
        return null;
    }

    /// The owner module and mangled `'<qualifier>_<method>'` name of an
    /// `implement`/`extend` block named `sym` that another module declares.
    /// BEAM module atom of a module PATH (`std/order` → `std@order`), as the
    /// cross-module index rendered it once. A `call_ext` target and the
    /// `{module, …}` header of the module it names must agree, so both come from
    /// `crossModule.erlAtom` — never from the path's basename.
    fn atomOf(self: *const Emitter, path: []const u8) []const u8 {
        if (self.cross) |xc| return xc.atomFor(path);
        return crossModule.moduleBasename(path);
    }

    /// The identity of module `path` — its package and path (decision 109),
    /// which every atom this emitter renders starts with.
    fn idOf(self: *const Emitter, path: []const u8) crossModule.ModuleId {
        if (self.cross) |xc| return xc.idOf(path);
        return .of(path);
    }

    fn importedExtension(self: *const Emitter, buf: []u8, sym: []const u8, method: []const u8) ?struct { owner: []const u8, mangled: []const u8 } {
        for (self.all_outputs) |*other| {
            const owner = self.atomOf(other.name);
            if (std.mem.eql(u8, owner, self.module_name)) continue;
            const ok = switch (other.outcome) {
                .ok => |*o| o,
                else => continue,
            };
            for (ok.transformed.decls) |d| {
                const block: ExtInfo = switch (d) {
                    .implement => |im| if (std.mem.eql(u8, im.name, sym)) .{ .target = im.target, .methods = im.methods } else continue,
                    .extend => |ex| if (std.mem.eql(u8, ex.name, sym)) .{ .target = ex.target, .methods = ex.methods } else continue,
                    else => continue,
                };
                for (block.methods) |m| {
                    if (!std.mem.eql(u8, m.name, method)) continue;
                    const mangled = std.fmt.bufPrint(buf, "'{s}_{s}'", .{ m.qualifier orelse block.target, method }) catch return null;
                    return .{ .owner = owner, .mangled = mangled };
                }
            }
        }
        return null;
    }

    /// True when a record/struct this module knows declares a field `name`.
    fn someRecordHasField(self: *const Emitter, name: []const u8) bool {
        var it = self.record_fields.valueIterator();
        while (it.next()) |fields| {
            for (fields.*) |f| if (std.mem.eql(u8, f, name)) return true;
        }
        return false;
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
        self.string_locals.clearRetainingCapacity();
        self.num_locals.clearRetainingCapacity();
        self.mutating_closures.clearRetainingCapacity();
    }

    /// Record the string-typed parameters of the function about to be lowered,
    /// before its locals are counted.
    fn noteStringParams(self: *Emitter, params: []const ast.Param) !void {
        for (params) |p| {
            if (isStringType(p.typeRef)) try self.string_locals.put(p.name, {});
            if (numTypeKind(p.typeRef)) |k| try self.num_locals.put(p.name, k);
        }
    }

    /// Index the module-level names that evaluate to a `string` (two passes: a
    /// `val` may be initialised by a `fn` declared after it). Parity with the
    /// erlang backend's `collectStringNames`.
    fn collectStringNames(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (isStringType(f.returnType)) try self.string_names.put(f.name, {});
                if (numTypeKind(f.returnType)) |k| try self.num_names.put(f.name, k);
            },
            else => {},
        };
        for (program.decls) |decl| switch (decl) {
            .val => |v| {
                if (self.isStringExpr(&self.string_locals, v.value.*)) try self.string_names.put(v.name, {});
                if (self.numKind(&self.string_locals, v.value.*)) |k| try self.num_names.put(v.name, k);
            },
            else => {},
        };
    }

    /// True when `e` is statically a botopink `string` — a literal, a `+` with
    /// a string operand, a string local/param (`locals`), a string module-level
    /// name, or a call to a `fn … -> string`. A `+` over it is concatenation;
    /// anything unproven stays arithmetic. Mirrors the erlang backend.
    fn isStringExpr(self: *const Emitter, locals: *const std.StringHashMap(void), e: ast.Expr) bool {
        return switch (e) {
            .literal => |lit| lit.kind == .stringLit or lit.kind == .stringTemplate,
            .binaryOp => |bin| bin.op == .add and
                (self.isStringExpr(locals, bin.lhs.*) or self.isStringExpr(locals, bin.rhs.*)),
            .identifier => |id| switch (id.kind) {
                .ident => |n| locals.contains(n) or self.string_names.contains(n),
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| cc.receiver == null and !cc.is_builtin and self.string_names.contains(cc.callee),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |g| self.isStringExpr(locals, g.*),
                else => false,
            },
            else => false,
        };
    }

    /// The numeric kind `e` statically has, or null when it cannot be proven
    /// (`.number` when it is a number of unknown precision): a number literal
    /// (a float when it has a `.` or an exponent), a numeric local/parameter/
    /// module name, a primitive member read (`s.length`), a call to a `fn`
    /// declared numeric, and arithmetic over them (a float operand makes a
    /// float; `%` is an integer). `strings` names the pass asking — the
    /// emission's `string_locals` or the count pass's `count_strings` — and
    /// selects the matching numeric set. Mirrors the erlang backend.
    fn numKind(self: *const Emitter, strings: *const std.StringHashMap(void), e: ast.Expr) ?NumKind {
        const nums = if (strings == &self.count_strings) &self.count_nums else &self.num_locals;
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (std.mem.startsWith(u8, n, "0x") or std.mem.startsWith(u8, n, "0b") or std.mem.startsWith(u8, n, "0o"))
                    .int
                else if (std.mem.indexOfAny(u8, n, ".eE") != null) .float else .int,
                else => null,
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| nums.get(n) orelse self.num_names.get(n),
                .identAccess => |ia| if (self.instanceLowering(id.loc, ia.receiver.*)) |il| switch (il) {
                    .prim => .int,
                    .type_, .field_of => null,
                } else null,
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.numKind(strings, inner.*),
                else => null,
            },
            .unaryOp => |un| if (un.op == .neg) self.numKind(strings, un.expr.*) else null,
            .binaryOp => |bin| switch (bin.op) {
                .add => if (self.isStringExpr(strings, e)) null else combineNum(self.numKind(strings, bin.lhs.*), self.numKind(strings, bin.rhs.*)),
                // `-`, `*` and `/` only ever answer a number.
                .sub, .mul, .div => combineNum(self.numKind(strings, bin.lhs.*), self.numKind(strings, bin.rhs.*)) orelse .number,
                .mod => .int,
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| if (cc.receiver == null and !cc.is_builtin) self.num_names.get(cc.callee) else null,
                else => null,
            },
            else => null,
        };
    }

    /// True when `a + b` is neither a proven string concatenation nor proven
    /// arithmetic, so it dispatches at run time through `'__bp_add'/2`.
    fn addIsDynamic(self: *const Emitter, strings: *const std.StringHashMap(void), e: ast.Expr) bool {
        if (e != .binaryOp or e.binaryOp.op != .add) return false;
        if (self.isStringExpr(strings, e)) return false;
        return self.numKind(strings, e.binaryOp.lhs.*) == null and self.numKind(strings, e.binaryOp.rhs.*) == null;
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
    fn precountLocals(self: *Emitter, body: []const ast.Stmt) u32 {
        self.seedCountStrings();
        var n: u32 = 0;
        countLocalsRec(self, body, &n);
        return n;
    }

    /// Start a count from the string locals the emission will start from.
    fn seedCountStrings(self: *Emitter) void {
        self.count_strings.clearRetainingCapacity();
        var it = self.string_locals.keyIterator();
        while (it.next()) |k| self.count_strings.put(k.*, {}) catch {};
        self.count_nums.clearRetainingCapacity();
        var nit = self.num_locals.iterator();
        while (nit.next()) |kv| self.count_nums.put(kv.key_ptr.*, kv.value_ptr.*) catch {};
    }

    /// `precountLocals` for a bare expression (a top-level `val`'s value).
    fn precountLocalsInExpr(self: *Emitter, e: ast.Expr) u32 {
        self.seedCountStrings();
        var n: u32 = 0;
        countLocalsInExpr(self, e, &n);
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
        try self.noteStringParams(f.params);

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
        for (f.params) |p| {
            if (p.destruct) |d| self.num_y += destructYSlots(d);
        }
        try self.bindParams(names_buf[0..nparams]);

        try beamEmitter.writeBlankLine(self.out);
        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. The BEAM model is processes +
        // message passing (spawn/receive); this backend currently emits the
        // eager body, with full process-based lowering left as future work.
        // `#[@context]` is a plain function too (decision 88: it gates `use`).
        if (f.effect != null and f.effect.? != .result and f.effect.? != .context) {
            try beamEmitter.writeTopComment(self.out, "#[@future] / #[@futureGenerator] — eager lowering", .{});
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
        // A destructuring parameter (`{ name, .. }: Person`) binds its names
        // from the spilled argument before the body runs.
        {
            var slot: u32 = 0;
            self.local_types.clearRetainingCapacity();
            for (f.params) |p| {
                if (std.mem.eql(u8, p.name, "self")) continue;
                // The written type of a parameter is what tells a `case` on it
                // which enum an unqualified arm belongs to.
                if (writtenTypeName(p.typeRef)) |tn| try self.local_types.put(p.name, tn);
                if (p.destruct) |d| {
                    try beamEmitter.writeMoveOp(self.out, Op.yr(slot), Dst.xr(0));
                    try self.emitDestructFromX0(d, writtenTypeName(p.typeRef));
                }
                slot += 1;
            }
        }

        self.cur_line += 1;
        // An eager `#[@iterator]`/`#[@future]` body ending in a yielding loop
        // is that loop's list: the fn returns it instead of `ok`.
        if (f.effect != null and f.effect.? != .result and f.effect.? != .context and f.body.len > 0) {
            const last = f.body[f.body.len - 1].expr;
            if (last == .loop and hasYieldOrBreakValue(last.loop.body)) {
                for (f.body[0 .. f.body.len - 1]) |stmt| try self.emitStmt(stmt);
                try self.lowerExprIntoX0(last);
                try self.emitReturn();
                return;
            }
        }
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

    fn reserveRecordMethods(self: *Emitter, r: ast.TypeDecl) !void {
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

    fn reserveEnumMethods(self: *Emitter, e: ast.TypeDecl) !void {
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

    fn emitRecord(self: *Emitter, r: ast.TypeDecl) !void {
        try self.emitTypeUnit(r.name, r.methods, .{ .record = r });
    }

    /// What a `type`'s module answers about its own values (decision 8 §7,
    /// half 3): a record's field order, an enum's variants, or nothing for a
    /// declaration that builds no value of its own.
    const IdentityShape = union(enum) {
        record: ast.TypeDecl,
        enum_: ast.TypeDecl,
        none,
    };

    /// Policy 3: a `type`'s methods are emitted into the type's own module,
    /// `<file atom>@@<Type>` (decision 109), under the names the programmer wrote. Shared by
    /// `emitRecord` and `emitEnum` — a record and an enum differ in how their
    /// values are built, not in where their functions live.
    fn emitTypeUnit(self: *Emitter, type_name: []const u8, methods: []const ast.BehaviorMethod, ident: IdentityShape) !void {
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        defer buf.deinit();
        var unit = try self.openTypeUnit(type_name, &buf);
        defer unit.exports.deinit(self.alloc);
        // The file module's table has to be reachable from inside the unit, and
        // `unit` is the frame that outlives `openTypeUnit` — taking the address
        // there would dangle. Units never nest, so this is always the file's.
        self.file_labels = &unit.fn_labels;
        self.file_atom = unit.module_name;
        for (methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.reserveFn(m.name, methodArity(m));
            try unit.exports.append(self.alloc, .{ .name = m.name, .arity = methodArity(m) });
        }
        for (methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.emitMethodAsFn(type_name, m);
        }
        try self.emitTypeIdentity(type_name, ident, &unit);
        try self.closeTypeUnit(type_name, &unit, &buf);
    }

    /// Decision 8 §7, half 3: the two functions a `type`'s module answers
    /// about its own values, the BEAM twins of `erlang.zig`'s
    /// `recordIdentityForms` / `enumIdentityForms`.
    ///
    ///   * `'__bp_get'/2` turns a field NAME into its position, for the reads
    ///     the emitter could not place statically.
    ///   * `'__bp_format'/1` describes the value: `{record, "Point", [{"x", 1},
    ///     …]}`, `{variant, "Shape.Dot", []}`, or `{text, display(V)}` for a
    ///     type implementing `Display`. `'__bp_render'/1` in the printing
    ///     module turns the description into §7's text; the description keeps
    ///     the type module free of a printer of its own.
    fn emitTypeIdentity(self: *Emitter, type_name: []const u8, ident: IdentityShape, unit: *SavedBeamUnit) !void {
        switch (ident) {
            .none => return,
            .record => |r| {
                const fields = r.recordFields();
                if (fields.len > 0) try self.emitFieldGetter(fields, unit);
                try self.emitRecordFormat(type_name, r, unit);
            },
            .enum_ => |e| {
                if (e.variants().len == 0) return;
                try self.emitEnumFormat(type_name, e, unit);
            },
        }
    }

    /// `'__bp_get'(V, Field)`: a chain of `is_eq_exact` tests on the field
    /// atom, each answering `erlang:element(N + 1, V)`.
    fn emitFieldGetter(self: *Emitter, fields: anytype, unit: *SavedBeamUnit) !void {
        const name = "'__bp_get'";
        try self.reserveFn(name, 2);
        try unit.exports.append(self.alloc, .{ .name = name, .arity = 2 });
        const l = try self.fnLabelsFor(name, 2);
        const w = self.out;
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 2, l.entry);
        try beamEmitter.writeLabel(w, l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 2);
        try beamEmitter.writeLabel(w, l.entry);
        for (fields, 0..) |f, i| {
            const next = self.allocLabel();
            var buf: [256]u8 = undefined;
            try beamEmitter.writeTest(w, .is_eq_exact, next, &.{ Op.xr(1), Op.atom(try atomName(f.name, &buf)) });
            try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.xr(1));
            try beamEmitter.writeMoveOp(w, Op.int(@as(i64, @intCast(i + 2))), Dst.xr(0));
            try beamEmitter.writeCall(w, .only, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
            try beamEmitter.writeLabel(w, next);
        }
        try beamEmitter.writeMoveOp(w, Op.atom("undefined"), Dst.xr(0));
        try beamEmitter.writeReturn(w);
    }

    /// `'__bp_format'(V) -> {record, "Name", [{"f", element(N, V)}, …]}`, or
    /// `{text, display(V)}` when the type renders itself (decision 8 §7's
    /// `Display`). The pair list is built back to front so each
    /// `erlang:element/2` call — which frees every x-register — runs before the
    /// cons it feeds.
    fn emitRecordFormat(self: *Emitter, type_name: []const u8, r: ast.TypeDecl, unit: *SavedBeamUnit) !void {
        const name = "'__bp_format'";
        try self.reserveFn(name, 1);
        try unit.exports.append(self.alloc, .{ .name = name, .arity = 1 });
        const l = try self.fnLabelsFor(name, 1);
        const w = self.out;
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 1, l.entry);
        try beamEmitter.writeLabel(w, l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 1);
        try beamEmitter.writeLabel(w, l.entry);

        if (self.typeRendersItselfAs(r)) |display| {
            const dl = self.fnLabelsFor(display, 1) catch null;
            try beamEmitter.writeAllocate(w, 0, 1);
            if (dl) |labels| {
                try beamEmitter.writeCall(w, .normal, 1, .{ .local = labels.entry }, 0);
            } else {
                try beamEmitter.writeMoveOp(w, Op.str(""), Dst.xr(0));
            }
            try beamEmitter.writeTestHeap(w, 3, 1);
            try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.atom("text"), Op.xr(0) });
            try beamEmitter.writeDeallocate(w, 0);
            try beamEmitter.writeReturn(w);
            return;
        }

        const fields = r.recordFields();
        try beamEmitter.writeAllocate(w, 2, 1);
        try beamEmitter.writeInitYregs(w, 2);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(0)); // y0 = V
        try beamEmitter.writeMoveOp(w, Op.nil, Dst.yr(1)); // y1 = acc
        var i: usize = fields.len;
        while (i > 0) {
            i -= 1;
            try beamEmitter.writeMoveOp(w, Op.int(@as(i64, @intCast(i + 2))), Dst.xr(0));
            try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
            try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
            try beamEmitter.writeTestHeap(w, 5, 1);
            try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.str(fields[i].name), Op.xr(0) });
            try beamEmitter.writePutList(w, Op.xr(0), Op.yr(1), Dst.yr(1));
        }
        try beamEmitter.writeTestHeap(w, 4, 1);
        try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.atom("record"), Op.str(type_name), Op.yr(1) });
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);
    }

    /// `'__bp_format'/1` for an enum: one test per variant against the tag the
    /// constructor builds, each answering `{variant, "Enum.Variant", [{…}]}`.
    fn emitEnumFormat(self: *Emitter, type_name: []const u8, e: ast.TypeDecl, unit: *SavedBeamUnit) !void {
        const name = "'__bp_format'";
        try self.reserveFn(name, 1);
        try unit.exports.append(self.alloc, .{ .name = name, .arity = 1 });
        const l = try self.fnLabelsFor(name, 1);
        const w = self.out;
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 1, l.entry);
        try beamEmitter.writeLabel(w, l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 1);
        try beamEmitter.writeLabel(w, l.entry);
        try beamEmitter.writeAllocate(w, 2, 1);
        try beamEmitter.writeInitYregs(w, 2);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(0));

        for (e.variants()) |v| {
            const next = self.allocLabel();
            const tag = self.qualifiedVariantTagOf(e.name, v.name) orelse v.name;
            var tag_buf: [512]u8 = undefined;
            const tag_atom = try atomName(tag, &tag_buf);
            const written = try std.fmt.allocPrint(self.atom_arena.allocator(), "{s}.{s}", .{ type_name, v.name });
            if (v.fields.len == 0) {
                try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
                try beamEmitter.writeTest(w, .is_eq_exact, next, &.{ Op.xr(0), Op.atom(tag_atom) });
                try beamEmitter.writeTestHeap(w, 4, 1);
                try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.atom("variant"), Op.str(written), Op.nil });
                try beamEmitter.writeDeallocate(w, 2);
                try beamEmitter.writeReturn(w);
            } else {
                try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
                try beamEmitter.writeTest(w, .is_tagged_tuple, next, &.{ Op.xr(0), .{ .untagged = @as(i64, @intCast(v.fields.len + 1)) }, Op.atom(tag_atom) });
                try beamEmitter.writeMoveOp(w, Op.nil, Dst.yr(1));
                var i: usize = v.fields.len;
                while (i > 0) {
                    i -= 1;
                    try beamEmitter.writeMoveOp(w, Op.int(@as(i64, @intCast(i + 2))), Dst.xr(0));
                    try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
                    try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
                    try beamEmitter.writeTestHeap(w, 5, 1);
                    try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.str(v.fields[i].name), Op.xr(0) });
                    try beamEmitter.writePutList(w, Op.xr(0), Op.yr(1), Dst.yr(1));
                }
                try beamEmitter.writeTestHeap(w, 4, 1);
                try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.atom("variant"), Op.str(written), Op.yr(1) });
                try beamEmitter.writeDeallocate(w, 2);
                try beamEmitter.writeReturn(w);
            }
            try beamEmitter.writeLabel(w, next);
        }
        // A value no variant of this enum built: name the enum and nothing more.
        try beamEmitter.writeTestHeap(w, 4, 1);
        try beamEmitter.writePutTuple2(w, Dst.xr(0), &.{ Op.atom("variant"), Op.str(type_name), Op.nil });
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);
    }

    /// The method a type renders itself through (decision 8 §7's `Display`):
    /// a one-parameter `display` the type declares. Null otherwise.
    fn typeRendersItselfAs(self: *const Emitter, r: ast.TypeDecl) ?[]const u8 {
        _ = self;
        for (r.methods) |m| {
            if (m.is_declare or m.body == null) continue;
            if (std.mem.eql(u8, m.name, "display") and m.params.len == 1) return m.name;
        }
        return null;
    }

    /// The file-module emitter state a unit sets aside. Everything here is
    /// per-MODULE: a unit's labels start at 1 like any module's, its lambdas
    /// and helper shims are its own, and the file module gets back exactly what
    /// it had.
    const SavedBeamUnit = struct {
        module_name: []const u8,
        out: *std.Io.Writer,
        next_label: u32,
        lambda_count: u32,
        cur_type: ?[]const u8,
        file_labels: ?*std.StringHashMap(FnLabels),
        file_atom: []const u8,
        fn_labels: std.StringHashMap(FnLabels),
        deferred_lambdas: std.ArrayListUnmanaged([]u8),
        needed_defaults: std.StringArrayHashMapUnmanaged(IfaceDefault),
        needed_prim_shims: std.StringArrayHashMapUnmanaged(PrimShim),
        emitted_prim_shims: usize,
        exports: std.ArrayListUnmanaged(ExportEntry),
    };

    /// Open `type_name`'s module: its bodies write into `buf`, its labels start
    /// over, and `cur_type` makes a call to one of its own methods local while a
    /// call into the file's functions becomes a `call_ext` the file module then
    /// exports.
    fn openTypeUnit(self: *Emitter, type_name: []const u8, buf: *std.Io.Writer.Allocating) !SavedBeamUnit {
        const saved: SavedBeamUnit = .{
            .module_name = self.module_name,
            .out = self.out,
            .next_label = self.next_label,
            .lambda_count = self.lambda_count,
            .cur_type = self.cur_type,
            .file_labels = self.file_labels,
            .file_atom = self.file_atom,
            .fn_labels = self.fn_labels,
            .deferred_lambdas = self.deferred_lambdas,
            .needed_defaults = self.needed_defaults,
            .needed_prim_shims = self.needed_prim_shims,
            .emitted_prim_shims = self.emitted_prim_shims,
            .exports = .empty,
        };
        self.module_name = try crossModule.typeAtom(self.atom_arena.allocator(), self.idOf(self.module_path), type_name);
        self.out = &buf.writer;
        self.next_label = 2;
        self.lambda_count = 0;
        self.cur_type = type_name;
        // `file_labels` / `file_atom` are set by the caller, which owns the
        // frame the saved table lives in.
        self.fn_labels = std.StringHashMap(FnLabels).init(self.alloc);
        self.deferred_lambdas = .empty;
        self.needed_defaults = .empty;
        self.needed_prim_shims = .empty;
        self.emitted_prim_shims = 0;
        return saved;
    }

    /// Close `type_name`'s module: the defaults and shims its own bodies
    /// reached are drained into it, the header is written, and the file module
    /// gets its state back. A unit that emitted nothing is dropped — a `type`
    /// with no bodied method is not worth a file holding one `{module, …}`
    /// line, exactly as on the erlang backend.
    fn closeTypeUnit(self: *Emitter, type_name: []const u8, unit: *SavedBeamUnit, buf: *std.Io.Writer.Allocating) !void {
        _ = type_name;
        try self.emitNeededDefaults();
        while (self.needed_prim_shims.count() > self.emitted_prim_shims) {
            try self.emitNeededPrimShims();
            try self.emitNeededDefaults();
        }

        const empty = buf.written().len == 0 and self.deferred_lambdas.items.len == 0;
        if (!empty) {
            var header: std.Io.Writer.Allocating = .init(self.alloc);
            defer header.deinit();
            try beamEmitter.writeModuleForm(&header.writer, self.module_name);
            try beamEmitter.writeExports(&header.writer, unit.exports.items);
            try beamEmitter.writeAttributes(&header.writer);
            try beamEmitter.writeLabels(&header.writer, self.next_label);

            var sections: std.ArrayListUnmanaged([]const u8) = .empty;
            defer sections.deinit(self.alloc);
            try sections.append(self.alloc, header.written());
            try sections.append(self.alloc, buf.written());
            try sections.appendSlice(self.alloc, self.deferred_lambdas.items);
            const code = try std.mem.concat(self.alloc, u8, sections.items);
            errdefer self.alloc.free(code);
            const atom = try self.alloc.dupe(u8, self.module_name);
            errdefer self.alloc.free(atom);
            try self.type_units.append(self.alloc, .{ .atom = atom, .code = code });
        }

        // The unit's own tables go; the file module's come back.
        var it = self.fn_labels.iterator();
        while (it.next()) |kv| self.alloc.free(kv.key_ptr.*);
        self.fn_labels.deinit();
        for (self.deferred_lambdas.items) |l| self.alloc.free(l);
        self.deferred_lambdas.deinit(self.alloc);
        self.needed_defaults.deinit(self.alloc);
        for (self.needed_prim_shims.keys()) |k| self.alloc.free(k);
        for (self.needed_prim_shims.values()) |v| self.alloc.free(v.name);
        self.needed_prim_shims.deinit(self.alloc);

        self.module_name = unit.module_name;
        self.out = unit.out;
        self.next_label = unit.next_label;
        self.lambda_count = unit.lambda_count;
        self.cur_type = unit.cur_type;
        self.file_labels = unit.file_labels;
        self.file_atom = unit.file_atom;
        self.fn_labels = unit.fn_labels;
        self.deferred_lambdas = unit.deferred_lambdas;
        self.needed_defaults = unit.needed_defaults;
        self.needed_prim_shims = unit.needed_prim_shims;
        self.emitted_prim_shims = unit.emitted_prim_shims;
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

    fn emitEnum(self: *Emitter, e: ast.TypeDecl) !void {
        try self.emitTypeUnit(e.name, e.methods, .{ .enum_ = e });
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

    fn emitMethodAsFn(self: *Emitter, owner: []const u8, m: ast.BehaviorMethod) !void {
        const arity = methodArity(m);
        var name_buf: [256]u8 = undefined;
        const mangled = try self.methodFnName(&name_buf, owner, m.name);
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        try self.noteStringParams(m.params);
        var names_buf: [64][]const u8 = undefined;
        const names = if (hasImplicitSelf(m)) blk: {
            names_buf[0] = "self";
            break :blk names_buf[0 .. 1 + paramNames(m.params, names_buf[1..]).len];
        } else paramNames(m.params, &names_buf);
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
        try self.noteStringParams(m.params);
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

        // '_botopink_main'/0 → runs the synthetic top-level statements in
        // order, then tail-calls main/0.
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, "'_botopink_main'", 0, wrapper.entry);
        try beamEmitter.writeLabel(self.out, wrapper.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, "'_botopink_main'", 0);
        try beamEmitter.writeLabel(self.out, wrapper.entry);
        if (self.entry_stmts.items.len == 0) {
            try beamEmitter.writeCall(self.out, .only, 0, .{ .local = main0.entry }, 0);
        } else {
            self.resetFnState(0);
            self.cur_fn_name = "_botopink_main";
            var n: u32 = 0;
            for (self.entry_stmts.items) |v| n += self.precountLocalsInExpr(v.value.*);
            self.num_y = n;
            try self.emitFrame(0);
            for (self.entry_stmts.items) |v| try self.lowerExprIntoX0(v.value.*);
            try beamEmitter.writeCall(self.out, .last, 0, .{ .local = main0.entry }, self.num_y);
        }
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
                    if (self.inCondLoop()) |cl| {
                        // Decision 8 §10 — in a loop some `break` of which
                        // carries a value, every `break` leaves the loop's
                        // value in `{x, 0}`; a value-less one answers
                        // `undefined`, as the erlang lowering's third tuple
                        // element does.
                        if (cl.valued) {
                            if (br.value) |v| {
                                try self.lowerExprIntoX0(v.*);
                            } else {
                                try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
                            }
                        }
                        try beamEmitter.writeJump(self.out, cl.exit);
                        return;
                    }
                    if (br.value) |v| {
                        try self.lowerExprIntoX0(v.*);
                    } else if (self.fold_group) |names| {
                        try self.emitGroupIntoX0(names);
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
                    if (self.inCondLoop()) |cl| {
                        try beamEmitter.writeJump(self.out, cl.top);
                        return;
                    }
                    if (self.fold_group) |names| {
                        try self.emitGroupIntoX0(names);
                    } else {
                        try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
                    }
                    try self.emitReturn();
                },
                else => |k| try beamEmitter.writeComment(self.out, "unsupported jump: {s}", .{@tagName(k)}),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| try self.emitIf(i),
                .tryCatch => |tc| try self.lowerTryCatch(tc),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    // A closure reassigning names of this frame threads them.
                    if (lb.value.* == .function) {
                        const fe = lb.value.function;
                        if (try self.lowerMutatingClosure(lb.name, fe.kind.params, fe.kind.body)) return;
                    }
                    try self.emitLocalBind(lb.name, lb.value.*);
                },
                .assign => |a| try self.emitAssign(a),
                .localBindDestruct => |lb| try self.emitDestructBind(lb.pattern, lb.value.*),
            },
            // A statement `loop`/`forEach` whose body reassigns outer names
            // threads them through `lists:foldl` (a fun cannot write its
            // caller's stack slots).
            .loop => |lp| {
                if (lp.condition) {
                    if (condLoopYieldsValue(lp.body)) return error.ConditionLoopValueUnsupported;
                    try self.lowerConditionLoop(lp);
                    return;
                }
                if (!lp.awaitLoop and !hasYieldOrBreakValue(lp.body)) {
                    // One parameter, or two — `loop (xs) { x, i -> … }` /
                    // `loop (xs, 1..) { … }` — whose second one is the index.
                    if (lp.params.len == 1 and lp.indexRange == null) {
                        if (try self.lowerMutatingFold(.{ .params = &.{lp.params[0]} }, lp.body, lp.iter.*, null)) return;
                    } else if (lp.params.len == 2) {
                        if (try self.lowerMutatingFold(.{ .pair = .{ .item = lp.params[0], .index = lp.params[1] } }, lp.body, lp.iter.*, lp.indexRange)) return;
                    }
                }
                try self.lowerExprIntoX0(stmt.expr);
            },
            .call => {
                if (self.closureMutation(stmt.expr)) |cm| {
                    try self.lowerClosureMutationCall(cm);
                    return;
                }
                if (self.forEachLambda(stmt.expr)) |each| {
                    if (try self.lowerMutatingFold(.{ .params = &.{each.param} }, each.body, each.recv.*, null)) return;
                }
                try self.lowerExprIntoX0(stmt.expr);
                // `out.push(x)` on a local array rebinds it: the call's value
                // is the grown list.
                if (self.receiverMutation(stmt.expr)) |reg| {
                    try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
                }
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
        try self.emitDestructFromX0(pattern, null);
    }

    /// The record a `{ a, b }` destructuring is of: the written type when the
    /// site has one, else the one record declaring every field it names.
    fn recordOfDestruct(self: *const Emitter, fields: []const ast.FieldDestruct, hint: ?[]const u8) ?[]const u8 {
        if (hint) |h| if (self.record_fields.contains(h)) return h;
        if (fields.len == 0) return null;
        var found: ?[]const u8 = null;
        var it = self.record_fields.iterator();
        candidates: while (it.next()) |e| {
            for (fields) |fld| {
                if (fieldIndexOf(e.value_ptr.*, fld.field_name) == null) continue :candidates;
            }
            if (found != null) return null;
            found = e.key_ptr.*;
        }
        return found;
    }

    /// Bind the names of a destructuring `pattern` from the value in `{x, 0}`.
    fn emitDestructFromX0(self: *Emitter, pattern: ast.ParamDestruct, hint: ?[]const u8) anyerror!void {
        switch (pattern) {
            .names => |n| {
                // Decision 21 (T2): a record is `{TypeAtom, F1, …}`, so each
                // name is `erlang:element(N + 1, V)` when this emit can place
                // the record — the parameter's written type, else the one
                // record declaring every named field.
                if (self.recordOfDestruct(n.fields, hint)) |type_name| {
                    const declared = self.record_fields.get(type_name).?;
                    const tag = try self.recordTagAtom(type_name);
                    var tag_buf: [512]u8 = undefined;
                    const not_rec = self.allocLabel();
                    const done = self.allocLabel();
                    const first_y = self.next_y;
                    try beamEmitter.writeTest(self.out, .is_tagged_tuple, not_rec, &.{
                        Op.xr(0),
                        .{ .untagged = @as(i64, @intCast(declared.len + 1)) },
                        Op.atom(try atomName(tag, &tag_buf)),
                    });
                    for (n.fields) |fld| {
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(fld.bind_name, .{ .y = y_idx });
                        if (fieldIndexOf(declared, fld.field_name)) |at| {
                            try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), at + 1, Dst.yr(y_idx));
                        } else {
                            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.yr(y_idx));
                        }
                    }
                    // Both paths write every slot: the validator merges them and
                    // rejects a later read of one an arm left unwritten.
                    try beamEmitter.writeJump(self.out, done);
                    try beamEmitter.writeLabel(self.out, not_rec);
                    for (0..n.fields.len) |k| {
                        try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.yr(first_y + k));
                    }
                    try beamEmitter.writeLabel(self.out, done);
                    return;
                }
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
        if (self.isStringExpr(&self.string_locals, value)) try self.string_locals.put(name, {});
        if (self.numKind(&self.string_locals, value)) |k| try self.num_locals.put(name, k);
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
                        if (self.numKind(&self.string_locals, a.value.*)) |k| try self.num_locals.put(name, k);
                    },
                    .plusAssign => {
                        if (self.string_locals.contains(name) or self.isStringExpr(&self.string_locals, a.value.*)) {
                            const target: ast.Expr = .{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .ident = name } } };
                            try self.lowerStringSegments(&.{ target, a.value.* });
                            try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
                            return;
                        }
                        try self.lowerExprIntoX0(a.value.*);
                        // A name of unknown type plus an unproven value
                        // dispatches at run time.
                        if (!self.num_locals.contains(name) and self.numKind(&self.string_locals, a.value.*) == null) {
                            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
                            try beamEmitter.writeMoveOp(self.out, reg.operand(), Dst.xr(0));
                            try self.callAddHelper();
                            try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
                            return;
                        }
                        const scratch = self.scratchBase();
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
                        try beamEmitter.writeGcBif(self.out, .add, scratch + 1, &.{ reg.operand(), Op.xr(scratch) }, Dst.xr(0));
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), reg.dest());
                    },
                }
            },
            .fieldAccess => |*fa| {
                // `recv.f = v` → `maps:update(f, V, Recv)` (a call, so the
                // receiver needs no static map type); `recv.f += v` updates
                // with `recv.f + v`.
                var read: ast.Expr = undefined;
                var sum: ast.Expr = undefined;
                const value = fieldAssignValue(fa, a.op, a.value, &read, &sum);
                const st = try self.stageOperands(&.{ value, fa.receiver.* }, &[_]ast.TrailingLambda{});
                try self.emitParallelMove(&.{ Op.atom(fa.field), st.ops[0], st.ops[1] }, &.{ 0, 1, 2 });
                try beamEmitter.writeCall(self.out, .normal, 3, .{ .ext = .{ .module = "maps", .function = "update" } }, 0);
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
        try self.emitIfTest(i, else_label);

        // then branch (cond true).
        for (i.then_) |s| try self.emitStmt(s);
        const then_returns = i.then_.len > 0 and (stmtIsReturn(i.then_[i.then_.len - 1]) or
            (self.inCondLoop() != null and stmtIsLoopJump(i.then_[i.then_.len - 1])));

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

    /// The branch test of an `if`, jumping to `else_label` when the then-branch
    /// must not run. The binding form `if (x) { v -> … }` runs its branch when
    /// `x` is present (not `undefined`) and binds the value to `v`.
    fn emitIfTest(self: *Emitter, i: anytype, else_label: u32) anyerror!void {
        if (i.binding) |name| {
            try self.lowerExprIntoX0(i.cond.*);
            try beamEmitter.writeTest(self.out, .is_ne_exact, else_label, &.{ Op.xr(0), Op.atom("undefined") });
            const y_idx = self.next_y;
            self.next_y += 1;
            try self.reg_map.put(name, .{ .y = y_idx });
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
            return;
        }
        if (!try self.lowerComparisonAsTest(i.cond.*, else_label)) {
            try self.lowerExprIntoX0(i.cond.*);
            try beamEmitter.writeTest(self.out, .is_eq, else_label, &.{ Op.xr(0), Op.atom("true") });
        }
    }

    /// Lower `lhs <op> rhs` (a comparison) as a `{test, is_<op>, {f, F}, [A, B]}.`
    /// instruction whose failure target is `fail_label`. Returns false if the
    /// expression is not a recognised comparison.
    fn lowerComparisonAsTest(self: *Emitter, cond: ast.Expr, fail_label: u32) anyerror!bool {
        switch (cond) {
            .binaryOp => |bin| {
                const cmp = comparisonTestOp(bin.op) orelse return false;
                const st = try self.stageOperands(&.{ bin.lhs.*, bin.rhs.* }, &[_]ast.TrailingLambda{});
                const a = if (cmp.swap) st.ops[1] else st.ops[0];
                const b = if (cmp.swap) st.ops[0] else st.ops[1];
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
                    // A named module-level `val` of this module is a 0-arity
                    // function: a read is a local call — a `call_ext` into the
                    // file's module from inside a type's (policy 3).
                    if (self.top_vals.contains(n)) {
                        if (try self.tryFileCall(n, 0, .non_tail, 0)) return;
                        const labels = try self.fnLabelsFor(n, 0);
                        try beamEmitter.writeCall(self.out, .normal, 0, .{ .local = labels.entry }, 0);
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
                    // `true`/`false` are identifiers in the AST and atoms on BEAM.
                    if (std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false")) {
                        try beamEmitter.writeMoveOp(self.out, Op.atom(n), Dst.xr(0));
                        return;
                    }
                    // Nothing binds the name. It used to become the atom of its
                    // own name — a value, so the program printed the word. Now
                    // the site aborts: `erlang:error({unresolved_identifier, N})`.
                    try beamEmitter.writeComment(self.out, "unresolved identifier: {s}", .{n});
                    try beamEmitter.writeMove(self.out, Term.tupleOf(&[_]Term{ Term.atomOf("unresolved_identifier"), Term.atomOf(n) }), 0);
                    try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "error" } }, 0);
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
                    // The comptime pass parks some folded values that are not
                    // numbers (an array) in a number literal; a `{float, […]}`
                    // operand does not assemble, so that site aborts instead.
                    if (!isNumericToken(n)) {
                        try beamEmitter.writeComment(self.out, "folded comptime value is not a number literal", .{});
                        try beamEmitter.writeMove(self.out, Term.tupleOf(&[_]Term{ Term.atomOf("unlowered_comptime_value"), Term.str(n) }), 0);
                        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "error" } }, 0);
                        return;
                    }
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
                // An anonymous `record { a: 1 }` and an interface literal
                // (`@Decl(kind: …, name: …)`) are maps keyed by field name —
                // the same shape a declared record's constructor builds.
                .behaviorLit => |il| {
                    try self.lowerFieldMap(il.fields);
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
                // `await e` is eager: the value of `e`.
                .await_ => |inner| {
                    try self.lowerExprIntoX0(inner.*);
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
            .comptime_ => |ct| {
                try self.lowerComptime(ct);
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
                if (lp.condition) {
                    if (condLoopYieldsValue(lp.body)) return error.ConditionLoopValueUnsupported;
                    // A loop whose `break` carries a value leaves it in `{x, 0}`
                    // itself (decision 8 §10); one that cannot answer anything
                    // is `ok`, as it was.
                    const valued = condLoopBreaksWithValue(lp.body);
                    try self.lowerConditionLoop(lp);
                    if (!valued) try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
                    return;
                }
                try self.lowerLoop(lp);
                return;
            },
            else => {},
        }

        try beamEmitter.writeComment(self.out, "unsupported expr in tail position: {s}", .{@tagName(e)});
        try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
    }

    /// Lower a `comptime` node that reached codegen. A folded `comptime expr` /
    /// `comptime { … break v; }` is its value (the statements before the
    /// `break` run in this frame); `assert` and `assert Pattern = e catch h`
    /// are runtime checks.
    fn lowerComptime(self: *Emitter, ct: anytype) anyerror!void {
        switch (ct.kind) {
            .comptimeExpr => |inner| try self.lowerExprIntoX0(inner.*),
            .comptimeBlock => |cb| {
                for (cb.body) |stmt| {
                    if (stmt.expr == .jump and stmt.expr.jump.kind == .@"break") {
                        if (stmt.expr.jump.kind.@"break".value) |v| {
                            try self.lowerExprIntoX0(v.*);
                        } else {
                            try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
                        }
                        return;
                    }
                    try self.emitStmt(stmt);
                }
                try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
            },
            .assert => |a| try self.lowerAssert(a.condition.*, if (a.message) |m| m.* else null, ct.loc),
            // `assert Pat = e catch h` → `case e { Pat -> e; _ -> h }`; the
            // pattern's bindings stay visible to the statements after it.
            .assertPattern => |ap| {
                const arms = [_]ast.CaseArm{
                    .{ .pattern = ap.pattern, .body = ap.expr.* },
                    .{ .pattern = .wildcard, .body = ap.handler.* },
                };
                const subjects = [_]ast.Expr{ap.expr.*};
                try self.lowerCase(&subjects, &arms);
            },
        }
    }

    /// `assert cond[, msg]` — always fatal (semantics decision 4): when `cond`
    /// is not `true`, raise `erlang:error({bp_assert, Msg, <<"<mod>.bp:<line>">>})`,
    /// the same term the erlang backend's test runner catches. The statement's
    /// value is `ok`.
    fn lowerAssert(self: *Emitter, cond: ast.Expr, message: ?ast.Expr, loc: ast.Loc) anyerror!void {
        const fail_l = self.allocLabel();
        const ok_l = self.allocLabel();
        if (!try self.lowerComparisonAsTest(cond, fail_l)) {
            try self.lowerExprIntoX0(cond);
            try beamEmitter.writeTest(self.out, .is_eq_exact, fail_l, &.{ Op.xr(0), Op.atom("true") });
        }
        try beamEmitter.writeJump(self.out, ok_l);
        try beamEmitter.writeLabel(self.out, fail_l);
        if (message) |m| {
            try self.lowerExprIntoX0(m);
        } else {
            try beamEmitter.writeMove(self.out, Term.str("assertion failed"), 0);
        }
        const scratch = self.scratchBase();
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(scratch));
        var where_buf: [512]u8 = undefined;
        const where = std.fmt.bufPrint(&where_buf, "{s}.bp:{d}", .{ self.module_name, loc.line }) catch "?";
        try beamEmitter.writeMove(self.out, Term.str(where), scratch + 1);
        try beamEmitter.writeTestHeap(self.out, 4, scratch + 2);
        try beamEmitter.writePutTuple2(self.out, Dst.xr(0), &.{ Op.atom("bp_assert"), Op.xr(scratch), Op.xr(scratch + 1) });
        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "error" } }, 0);
        try beamEmitter.writeLabel(self.out, ok_l);
        try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
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
        try self.emitIfTest(i, else_label);

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
                .add => if (self.isStringExpr(&self.string_locals, e)) {
                    try self.lowerStringConcat(e);
                    if (dest != 0) try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(dest));
                } else if (self.addIsDynamic(&self.string_locals, e)) {
                    // Neither operand is provably a number or a string (a
                    // lambda's `{ x, y -> x + y }`): two binaries concatenate
                    // at run time, anything else adds.
                    const st = try self.stageOperands(&.{ bin.lhs.*, bin.rhs.* }, &[_]ast.TrailingLambda{});
                    try self.emitParallelMove(st.slice(), &.{ 0, 1 });
                    try self.callAddHelper();
                    if (dest != 0) try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(dest));
                } else try self.lowerArithGcBif(bin, dest),
                .sub, .mul, .div, .mod => try self.lowerArithGcBif(bin, dest),
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
            // `div` is integer division and raises `badarith` on a float; an
            // operand known to be a float takes `'/'`.
            .div => if (self.numKind(&self.string_locals, bin.lhs.*) == .float or
                self.numKind(&self.string_locals, bin.rhs.*) == .float) .fdiv else .div_,
            .mod => .rem,
            else => unreachable,
        };
        const st = try self.stageOperands(&.{ bin.lhs.*, bin.rhs.* }, &[_]ast.TrailingLambda{});
        try beamEmitter.writeGcBif(self.out, bif, @max(self.min_live, st.x_top), st.slice(), Dst.xr(dest));
    }

    /// Lower a comparison (`<`, `>`, `==`, …) as a value: emits a `{test, …}`
    /// then branches to produce `{atom, true}` or `{atom, false}` in `{x, dest}`.
    fn lowerCmpAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const cmp = comparisonTestOp(bin.op) orelse unreachable;
        const st = try self.stageOperands(&.{ bin.lhs.*, bin.rhs.* }, &[_]ast.TrailingLambda{});
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        const a = if (cmp.swap) st.ops[1] else st.ops[0];
        const b = if (cmp.swap) st.ops[0] else st.ops[1];
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
            if (if (self.self_prim_kind == null) self.rewrites.get(loc) else null) |sym| {
                var nbuf: [256]u8 = undefined;
                if (self.extMangledName(&nbuf, sym, cc.callee)) |mangled| {
                    try self.lowerExtCall(mangled, recv_expr, cc.args, mode);
                    return;
                }
                // An extension block another module declares (activated by a
                // star import, `import {PatoNada*} from "pond"`): the owner
                // emits and exports `'<target>_<method>'`, so the call is remote.
                if (self.importedExtension(&nbuf, sym, cc.callee)) |ext| {
                    const st = try self.stageCall(recv_expr, cc.args, &[_]ast.TrailingLambda{});
                    try self.placeStaged(&st);
                    try beamEmitter.writeCall(
                        self.out,
                        if (mode == .tail) .last else .normal,
                        1 + cc.args.len,
                        .{ .ext = .{ .module = ext.owner, .function = ext.mangled } },
                        self.num_y,
                    );
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
            if (self.instanceLowering(loc, recv_expr.*)) |il| switch (il) {
                .prim => |k| {
                    if (try self.emitPrimMethod(k, cc.callee, recv_expr, cc, mode)) return;
                    // An unrecognised prim method (a `default fn` like `fold`/`all`,
                    // or one not yet lowered on BEAM) falls through to the
                    // value-receiver local-call path below — parity with the
                    // erlang backend's bare-`callee(Recv, …)` fallthrough.
                },
                // A record/struct/enum receiver: its method is a function
                // taking the receiver first, in the TYPE's own module under
                // policy 3 — local when that module is the one being emitted,
                // a `call_ext` from anywhere else, and a `call_ext` is also
                // what reaches a type another module declares. It used to fall
                // into the fun-field heuristic below for the imported case,
                // read `norm` out of the record's map and `call_fun` the
                // `undefined` it found (`{badfun, #{x => 1, y => 2}}` at run
                // time).
                .type_ => |type_name| {
                    var nbuf: [256]u8 = undefined;
                    if (self.methodFnName(&nbuf, type_name, cc.callee)) |name| {
                        if (self.cur_type) |ct| if (std.mem.eql(u8, ct, type_name)) {
                            if (self.fnLabelsFor(name, 1 + cc.args.len)) |_| {
                                try self.lowerExtCall(name, recv_expr, cc.args, mode);
                                return;
                            } else |_| {}
                        };
                        if (try self.typeMethodModule(type_name, cc.callee, 1 + cc.args.len)) |owner| {
                            const st = try self.stageCall(recv_expr, cc.args, &[_]ast.TrailingLambda{});
                            try self.placeStaged(&st);
                            try beamEmitter.writeCall(
                                self.out,
                                if (mode == .tail) .last else .normal,
                                1 + cc.args.len,
                                .{ .ext = .{ .module = owner, .function = cc.callee } },
                                self.num_y,
                            );
                            return;
                        }
                        // Not a type with a module of its own (an `implement`
                        // or `extend` block's target, which stays in the file's
                        // module): the mangled local, as before.
                        if (self.fnLabelsFor(name, 1 + cc.args.len)) |_| {
                            try self.lowerExtCall(name, recv_expr, cc.args, mode);
                            return;
                        } else |_| {}
                    } else |_| {}
                },
                // A field READ never reaches the call path.
                .field_of => {},
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
                    var path_buf: [256]u8 = undefined;
                    try beamEmitter.writeCall(
                        self.out,
                        if (mode == .tail) .last else .normal,
                        arity,
                        .{ .ext = .{ .module = self.stdModuleAtom(rn, &path_buf), .function = fn_atom } },
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
                        try self.lowerTaggedTuple(self.qualifiedVariantTagOf(rn, cc.callee) orelse cc.callee, cc.args);
                        if (mode == .tail) try self.emitReturn();
                        return;
                    }
                    // A lowercase callee on a PascalCase record/struct receiver
                    // is an associated fn (`Response.ok(...)`, `Shape.unit()`)
                    // — a function of the TYPE's own module under policy 3,
                    // local only while that module is the one being emitted.
                    // It used to be the file module's `'<Type>_<callee>'`, and
                    // for an imported type a remote call to the owner FILE —
                    // never the lowercased type name (`response:ok`), which
                    // names a module nothing emits.
                    if (cc.trailing.len == 0 and (self.record_fields.contains(rn) or self.enum_names.contains(rn))) {
                        if (try self.typeAssocCall(rn, cc, mode)) return;
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
                    try self.materializeCallArgs(cc.args, cc.trailing);
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
            const total_arity = 1 + cc.args.len;
            // A value-receiver call answered by one of the FILE module's
            // functions, made from inside a type's: a `call_ext`, because
            // policy 3 put the two in separate modules.
            if (self.cur_type != null and self.isFileFn(cc.callee, total_arity)) {
                const st = try self.stageCall(recv_expr, cc.args, &[_]ast.TrailingLambda{});
                try self.placeStaged(&st);
                if (try self.tryFileCall(cc.callee, total_arity, mode, self.num_y)) return;
            }
            const labels = self.fnLabelsFor(cc.callee, total_arity) catch {
                // A record field holding a fun (`s.set(v)` on
                // `record State { set: fn(next: T) }`): read it, apply it.
                // 06 N24 — `c._1(9)` (what a labelled `c.set(9)` becomes)
                // takes the same route: read the element, apply it. The
                // `identAccess` below lowers `._N` through the tuple path.
                const fun_field = tupleIndexMember(cc.callee) != null or
                    if (self.instanceLowering(loc, recv_expr.*)) |il| il == .type_ else self.someRecordHasField(cc.callee);
                {
                    if (fun_field) {
                        var read: ast.Expr = .{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .identAccess = .{ .receiver = @constCast(recv_expr), .member = cc.callee } } } };
                        var exprs: [max_staged]ast.Expr = undefined;
                        for (cc.args, 0..) |arg, i| exprs[i] = arg.value.*;
                        exprs[cc.args.len] = read;
                        _ = &read;
                        const st = try self.stageOperands(exprs[0 .. cc.args.len + 1], cc.trailing);
                        var dsts: [max_staged]u32 = undefined;
                        var srcs: [max_staged]Op = undefined;
                        const n_args = cc.args.len + cc.trailing.len;
                        for (0..cc.args.len) |i| {
                            srcs[i] = st.ops[i];
                            dsts[i] = @intCast(i);
                        }
                        for (0..cc.trailing.len) |j| {
                            srcs[cc.args.len + j] = st.ops[cc.args.len + 1 + j];
                            dsts[cc.args.len + j] = @intCast(cc.args.len + j);
                        }
                        srcs[n_args] = st.ops[cc.args.len];
                        dsts[n_args] = @intCast(n_args);
                        try self.emitParallelMove(srcs[0 .. n_args + 1], dsts[0 .. n_args + 1]);
                        try beamEmitter.writeCallFun(self.out, n_args);
                        if (mode == .tail) try self.emitReturn();
                        return;
                    }
                }
                // An untyped receiver (`xs.map({ x -> x.toUpper() })`: the
                // lambda parameter carries no declared type, so inference
                // recorded no lowering for `x`) whose method some primitive
                // interface declares: dispatch on the receiver's runtime tag
                // through `'__bp_prim_<callee>'`, the erlang backend's answer to
                // the same shape. Only when inference recorded NOTHING — a
                // receiver it typed and whose method did not lower keeps the
                // abort, which is this front's documented backstop.
                if (self.instanceLowering(loc, recv_expr.*) == null) {
                    if (try self.ensurePrimShim(cc.callee, cc.args.len + cc.trailing.len)) |shim_name| {
                        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
                        try self.placeStaged(&st);
                        const shim_labels = try self.fnLabelsFor(shim_name, total_arity);
                        switch (mode) {
                            .non_tail => try beamEmitter.writeCall(self.out, .normal, total_arity, .{ .local = shim_labels.entry }, 0),
                            .tail => try beamEmitter.writeCall(self.out, .last, total_arity, .{ .local = shim_labels.entry }, self.num_y),
                        }
                        return;
                    }
                }
                try self.materializeCallArgs(cc.args, cc.trailing);
                try self.emitUnresolvedAbort("unresolved_method", cc.callee, total_arity);
                if (mode == .tail) try self.emitReturn();
                return;
            };
            {
                const st = try self.stageCall(recv_expr, cc.args, &[_]ast.TrailingLambda{});
                try self.placeStaged(&st);
            }
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

        // A host-backed `declare fn` lowers to its host target.
        if (self.externalDeclFor(cc.callee)) |f| {
            try self.lowerExternalCall(f, cc, mode, loc);
            return;
        }

        // One of the FILE module's functions, called from inside a type's: the
        // two are separate modules under policy 3.
        if (self.cur_type != null and self.isFileFn(cc.callee, arity)) {
            try self.materializeCallArgs(cc.args, cc.trailing);
            if (try self.tryFileCall(cc.callee, arity, mode, self.num_y)) return;
        }
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

        // A module-level `val` holding a fun (`val add = { x, y -> … }`): read
        // it (a 0-arity local call), park it on the stack while the arguments
        // are staged — staging may call and free the x-file — then `call_fun`.
        if (self.top_vals.contains(cc.callee)) {
            if (!try self.tryFileCall(cc.callee, 0, .non_tail, 0)) {
                const val_labels = try self.fnLabelsFor(cc.callee, 0);
                try beamEmitter.writeCall(self.out, .normal, 0, .{ .local = val_labels.entry }, 0);
            }
            const fun_y = self.next_y;
            self.next_y += 1;
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(fun_y));
            try self.materializeCallArgs(cc.args, cc.trailing);
            try beamEmitter.writeMoveOp(self.out, Op.yr(fun_y), Dst.xr(arity));
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
                try self.lowerRecordConstruct(cc.args, fields, cc.callee);
                if (mode == .tail) try self.emitReturn();
                return;
            }
            // No registered shape (e.g. an inferred/anonymous record) but all
            // args are labeled — fall back to label-keyed construction.
            if (allNamed(cc.args)) {
                try self.lowerRecordConstruct(cc.args, null, null);
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

        // `Ok(v)` / `Err(e)` / `new Error(msg)` build the `@Result` tuple the
        // `#[@result]` transform and the `Ok`/`Err` case arms use (a user
        // variant of the same name was matched above).
        if (!self.enum_variants.contains(cc.callee) and cc.args.len == 1 and cc.trailing.len == 0) {
            const tag: ?[]const u8 = if (std.mem.eql(u8, cc.callee, "Ok")) "ok" else if (std.mem.eql(u8, cc.callee, "Err") or std.mem.eql(u8, cc.callee, "Error")) "error" else null;
            if (tag) |t| {
                try self.lowerExprIntoX0(cc.args[0].value.*);
                const live = @max(self.min_live, 1);
                try beamEmitter.writeTestHeap(self.out, 3, live);
                try beamEmitter.writePutTuple2(self.out, Dst.xr(0), &.{ Op.atom(t), Op.xr(0) });
                if (mode == .tail) try self.emitReturn();
                return;
            }
        }

        // Nothing defines the callee: the site aborts rather than leaving an
        // argument in `{x, 0}` as the call's "value".
        try self.materializeCallArgs(cc.args, cc.trailing);
        try self.emitUnresolvedAbort("unresolved_call", cc.callee, arity);
        if (mode == .tail) try self.emitReturn();
    }

    /// `%% unresolved …` note plus `erlang:error({Kind, Name, Arity})`.
    fn emitUnresolvedAbort(self: *Emitter, kind: []const u8, name: []const u8, arity: usize) anyerror!void {
        try beamEmitter.writeComment(self.out, "{s}: {s}/{d}", .{ kind, name, arity });
        try beamEmitter.writeMove(self.out, Term.tupleOf(&[_]Term{ Term.atomOf(kind), Term.atomOf(name), Term.int(@intCast(arity)) }), 0);
        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "error" } }, 0);
    }

    /// The module atom holding `type_name`'s methods under policy 3 — this
    /// file's own type module (`own_types`), or the owner's for an imported
    /// type, which a consumer reaches two ways: by naming it in an
    /// `import { … }` (`imported_types`), and through a value some other import
    /// answers (`dict.empty()` gives a `Dict` nothing in this module named),
    /// which only the link index knows about. Null when the name is not a type
    /// with a module at all. The BEAM twin of `erlang.zig`'s `typeModuleAtom`.
    fn typeModuleAtom(self: *Emitter, type_name: []const u8) !?[]const u8 {
        if (self.own_types.contains(type_name)) {
            return try crossModule.typeAtom(self.atom_arena.allocator(), self.idOf(self.module_path), type_name);
        }
        if (self.imported_types.get(type_name)) |owner| return owner;
        const xc = self.cross orelse return null;
        const info = xc.exports.get(type_name) orelse return null;
        switch (info.kind) {
            .record, .@"enum" => {},
            else => return null,
        }
        return try crossModule.typeAtom(self.atom_arena.allocator(), self.idOf(info.module), type_name);
    }

    /// A call from inside a type module to one of the FILE module's functions
    /// — policy 3 split them into two modules, so the local label is gone.
    /// Emits the `call_ext`, records the export the file module then needs, and
    /// answers true; false when there is no unit open or the name is not one of
    /// the file's, and the caller keeps its own path.
    fn tryFileCall(self: *Emitter, name: []const u8, arity: usize, mode: CallMode, live: u32) anyerror!bool {
        if (self.cur_type == null) return false;
        if (!self.isFileFn(name, arity)) return false;
        const owner = try self.fileCallTarget(name, arity);
        var fn_buf: [256]u8 = undefined;
        const fn_atom = atomName(name, &fn_buf) catch name;
        try beamEmitter.writeCall(
            self.out,
            if (mode == .tail) .last else .normal,
            arity,
            .{ .ext = .{ .module = owner, .function = fn_atom } },
            live,
        );
        return true;
    }

    /// An associated `fn` of `type_name` called as `Type.f(args)`: local inside
    /// that type's own module, a `call_ext` into it from anywhere else. True
    /// when it was lowered, false to let the caller keep looking.
    fn typeAssocCall(self: *Emitter, type_name: []const u8, cc: anytype, mode: CallMode) anyerror!bool {
        const arity = cc.args.len;
        var nbuf: [256]u8 = undefined;
        const name = self.methodFnName(&nbuf, type_name, cc.callee) catch return false;
        if (self.cur_type) |ct| if (std.mem.eql(u8, ct, type_name)) {
            if (self.fnLabelsFor(name, arity)) |labels| {
                try self.materializeCallArgs(cc.args, cc.trailing);
                switch (mode) {
                    .non_tail => try beamEmitter.writeCall(self.out, .normal, arity, .{ .local = labels.entry }, 0),
                    .tail => try beamEmitter.writeCall(self.out, .last, arity, .{ .local = labels.entry }, self.num_y),
                }
                return true;
            } else |_| {}
        };
        if (try self.typeMethodModule(type_name, cc.callee, arity)) |owner| {
            try self.materializeCallArgs(cc.args, cc.trailing);
            try beamEmitter.writeCall(
                self.out,
                if (mode == .tail) .last else .normal,
                arity,
                .{ .ext = .{ .module = owner, .function = cc.callee } },
                self.num_y,
            );
            return true;
        }
        // Not the type's own function (an `implement` block's, say): the file
        // module's mangled local, as before.
        if (self.fnLabelsFor(name, arity)) |labels| {
            try self.materializeCallArgs(cc.args, cc.trailing);
            switch (mode) {
                .non_tail => try beamEmitter.writeCall(self.out, .normal, arity, .{ .local = labels.entry }, 0),
                .tail => try beamEmitter.writeCall(self.out, .last, arity, .{ .local = labels.entry }, self.num_y),
            }
            return true;
        } else |_| {}
        return false;
    }

    /// The module of `type_name`'s `method/arity`, when the TYPE is what
    /// declares it — a local type's own unit, or an imported type's module, the
    /// link index being the source that knows an imported type's method names.
    /// Null when it is not the type's method, so an `implement`/`extend` method
    /// on the same type keeps the file module's mangled local.
    fn typeMethodModule(self: *Emitter, type_name: []const u8, method: []const u8, arity: usize) !?[]const u8 {
        if (self.own_types.contains(type_name)) {
            var key_buf: [256]u8 = undefined;
            const key = std.fmt.bufPrint(&key_buf, "{s}.{s}/{d}", .{ type_name, method, arity }) catch return null;
            if (!self.own_type_methods.contains(key)) return null;
            return try self.typeModuleAtom(type_name);
        }
        const xc = self.cross orelse return null;
        const info = xc.exports.get(type_name) orelse return null;
        switch (info.kind) {
            .record, .@"enum" => {},
            else => return null,
        }
        for (info.methods) |m| {
            if (std.mem.eql(u8, m.name, method)) return try self.typeModuleAtom(type_name);
        }
        return null;
    }

    /// The function name `method` of type `owner` is DEFINED and CALLED under:
    /// the bare name inside that type's own module (policy 3 — the module
    /// boundary replaced the prefix), the `'<Owner>_<method>'` mangling
    /// everywhere else. A behavior's `default fn` keeps the mangling wherever it
    /// is emitted, because a behavior has no module (decision 23).
    fn methodFnName(self: *const Emitter, buf: []u8, owner: []const u8, method: []const u8) ![]const u8 {
        if (self.cur_type) |ct| {
            if (std.mem.eql(u8, ct, owner)) return std.fmt.bufPrint(buf, "{s}", .{method});
        }
        return std.fmt.bufPrint(buf, "'{s}_{s}'", .{ owner, method });
    }

    /// True when a unit is open and `name/arity` is one of the FILE module's
    /// functions — a call to it is a `call_ext` the file module has to export.
    fn isFileFn(self: *Emitter, name: []const u8, arity: usize) bool {
        const labels = self.file_labels orelse return false;
        const key = fnKey(self.alloc, name, arity) catch return false;
        defer self.alloc.free(key);
        return labels.contains(key);
    }

    /// Note that the file module must export `name/arity`, reached from inside
    /// a type module, and answer the file's atom to call it in.
    fn fileCallTarget(self: *Emitter, name: []const u8, arity: usize) ![]const u8 {
        const key = try fnKey(self.atom_arena.allocator(), name, arity);
        const gop = try self.file_exports_needed.getOrPut(self.alloc, key);
        if (!gop.found_existing) gop.value_ptr.* = .{ .name = name, .arity = arity };
        return self.file_atom;
    }

    /// Owning module atom for a cross-module export of the given kind, or null
    /// when the name is local, shadowed by a register, or exported with a
    /// different shape.
    fn crossOwnerOf(self: *const Emitter, name: []const u8, kind: crossModule.ExportKind) ?[]const u8 {
        const xc = self.cross orelse return null;
        const info = xc.exports.get(name) orelse return null;
        if (info.kind != kind) return null;
        const owner = self.atomOf(info.module);
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
        // §A5 annotation-driven path: if the receiver's interface method carries
        // a recognisable `#[@External.Erlang("mod", "sym[(args)]")]` shape (1-arg
        // self / 2-arg self-first / 2-arg arg-first), lower via the matching
        // x-register pattern and return. The inline switch below handles the
        // BEAM-irreducible cases (`++` ops, inline funs, custom heap shapes,
        // BIF aliases).
        if (try self.tryEmitPrimAnnotation(k, callee, recv_expr, cc, mode)) return true;
        if (try self.emitPrimInline(k, callee, recv_expr, cc, mode)) return true;
        // An `@External.Erlang` template (`"string:trim($0, leading)"`) is
        // Erlang source: evaluated at run time through `'__bp_erl_eval'/2`.
        if (self.primErlangTemplate(k, callee, cc.args.len + cc.trailing.len)) |template| {
            var exprs: [max_staged]ast.Expr = undefined;
            exprs[0] = recv_expr.*;
            for (cc.args, 0..) |arg, i| exprs[i + 1] = arg.value.*;
            try self.evalTemplate(template, true, exprs[0 .. 1 + cc.args.len], cc.trailing, mode);
            return true;
        }
        // A bodied interface `default fn` (`Array.fold`, `Number.clamp`).
        if (try self.callIfaceDefault(k, callee, recv_expr, cc, mode)) return true;
        return false;
    }

    /// The BEAM-irreducible primitive methods lowered inline (`++` shapes,
    /// bounds-checked `at`, `nomatch` comparisons).
    fn emitPrimInline(self: *Emitter, k: envMod.PrimKind, callee: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        const eq = std.mem.eql;
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

    /// The `@External.Erlang` template (single or the arity branch matching
    /// `argc`) of the first interface on `k`'s chain that declares `callee`.
    fn primErlangTemplate(self: *Emitter, k: envMod.PrimKind, callee: []const u8, argc: usize) ?[]const u8 {
        var b: [128]u8 = undefined;
        for (primIfaceChain(k)) |iface_name| {
            const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface_name, callee }) catch return null;
            const call = self.prim_erlang_dispatch.get(key) orelse continue;
            if (call.arity_branches.len > 0) {
                for (call.arity_branches) |br| {
                    if (br.argc == argc) return br.template;
                }
                return null;
            }
            if (primOpTemplate.looksLikeTemplate(call.symbol)) return call.symbol;
            return null;
        }
        return null;
    }

    /// Call the bodied instance `default fn` answering `callee` on `k`'s chain
    /// as the local `'<Iface>_<method>'(Recv, Args…)`, emitted on demand. An
    /// omitted trailing parameter takes its declared default (`s.slice(1)`).
    fn callIfaceDefault(self: *Emitter, k: envMod.PrimKind, callee: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        var b: [128]u8 = undefined;
        const d = for (primIfaceChain(k)) |iface_name| {
            const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface_name, callee }) catch return false;
            if (self.iface_defaults.getEntry(key)) |hit| {
                try self.needed_defaults.put(self.alloc, hit.key_ptr.*, hit.value_ptr.*);
                break hit.value_ptr.*;
            }
        } else return false;
        const params = d.method.params[1..];
        const given = cc.args.len + cc.trailing.len;
        if (given > params.len) return false;
        var nbuf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&nbuf, "'{s}_{s}'", .{ d.iface, d.method.name });
        if (self.fnLabelsFor(mangled, 1 + params.len)) |_| {} else |_| try self.reserveFn(mangled, 1 + params.len);

        var args: [max_staged]ast.CallArg = undefined;
        for (cc.args, 0..) |arg, i| args[i] = arg;
        var n = cc.args.len;
        // Trailing lambdas take the parameters after the positional ones; the
        // padding defaults come after both.
        const pad_from = given;
        const st = blk: {
            var i = pad_from;
            while (i < params.len) : (i += 1) {
                const def = if (params[i].default) |*dv| @constCast(dv) else return false;
                args[n] = .{ .label = null, .value = def };
                n += 1;
            }
            if (cc.trailing.len == 0) break :blk try self.stageCall(recv_expr, args[0..n], cc.trailing);
            // Positional args, then the trailing lambdas, then the defaults:
            // stage in that order by folding the defaults behind the lambdas.
            if (n == cc.args.len) break :blk try self.stageCall(recv_expr, args[0..n], cc.trailing);
            return false;
        };
        try self.placeStaged(&st);
        const labels = try self.fnLabelsFor(mangled, 1 + params.len);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 1 + params.len, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 1 + params.len, .{ .local = labels.entry }, self.num_y),
        }
        return true;
    }

    // ── run-time primitive dispatch (an untyped receiver) ────────────────────
    //
    // `xs.map({ x -> x.toUpper() })`: the lambda parameter carries no declared
    // type, so inference records no instance lowering for `x` and the typed
    // path above has nothing to dispatch on. Beam used to abort at run time
    // with `{unresolved_method, toUpper, 1}` (measured 2026-09-18 against
    // `bef762b`; the same program's straight-line form — `.trim()`, `.split()`,
    // `.join()` on a named local — runs). The erlang backend answers it with a
    // guarded shim per `(method, argc)` (`erlang.zig` `primShimForm`); this is
    // its BEAM twin, and the clause bodies are `emitPrimMethod`'s own
    // lowerings, so the typed tables stay the single source of truth.

    /// The primitive kinds a shim tests, in the erlang backend's order, with
    /// the BEAM type test each clause is guarded by.
    const prim_shim_kinds = [_]struct { kind: envMod.PrimKind, guard: beamEmitter.TestOp }{
        .{ .kind = .array, .guard = .is_list },
        .{ .kind = .string, .guard = .is_binary },
        .{ .kind = .bool, .guard = .is_boolean },
        .{ .kind = .int, .guard = .is_integer },
        .{ .kind = .float, .guard = .is_float },
    };

    /// True when some interface on `k`'s chain declares `callee`. The three
    /// tables `emitPrimMethod` walks — the `@External.Beam` bodies, the
    /// erlang-derived dispatch and the bodied `default fn`s — are all keyed
    /// `"<Iface>.<method>"`, so this asks them without emitting anything.
    /// Conservative by construction: a name no table names keeps the abort the
    /// call site already had.
    fn primKindDeclares(self: *const Emitter, k: envMod.PrimKind, callee: []const u8) bool {
        var b: [128]u8 = undefined;
        for (primIfaceChain(k)) |iface_name| {
            const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface_name, callee }) catch return false;
            if (self.prim_beam_templates.contains(key)) return true;
            if (self.prim_erlang_dispatch.contains(key)) return true;
            if (self.iface_defaults.contains(key)) return true;
        }
        return false;
    }

    /// The `'__bp_prim_<callee>'` shim for an untyped `recv.callee(a…)`, or null
    /// when no primitive interface declares `callee` — then the call site keeps
    /// its `{unresolved_method, …}` abort, which is the backstop this front's
    /// notes ask to keep. Reserves the name and queues the body; the body is
    /// emitted after the enclosing function, because writing it resets the
    /// per-function register state.
    fn ensurePrimShim(self: *Emitter, callee: []const u8, argc: usize) anyerror!?[]const u8 {
        if (self.user_behavior_methods.contains(callee)) return null;
        var answered = false;
        for (prim_shim_kinds) |pk| {
            if (self.primKindDeclares(pk.kind, callee)) answered = true;
        }
        if (!answered) return null;
        var kbuf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&kbuf, "{s}/{d}", .{ callee, argc }) catch return null;
        if (self.needed_prim_shims.get(key)) |s| return s.name;
        const name = try std.fmt.allocPrint(self.alloc, "'__bp_prim_{s}'", .{callee});
        try self.reserveFn(name, argc + 1);
        try self.needed_prim_shims.put(
            self.alloc,
            try self.alloc.dupe(u8, key),
            .{ .callee = callee, .argc = argc, .name = name },
        );
        return name;
    }

    /// Emit every shim a call site reached. A clause body may itself reach an
    /// interface `default fn` or another shim, so both lists are drained to a
    /// fixpoint (the caller re-drains `needed_defaults`).
    fn emitNeededPrimShims(self: *Emitter) anyerror!void {
        while (self.emitted_prim_shims < self.needed_prim_shims.count()) {
            const shim = self.needed_prim_shims.values()[self.emitted_prim_shims];
            self.emitted_prim_shims += 1;
            try self.emitPrimShimFn(shim);
        }
    }

    /// `'__bp_prim_<callee>'(Recv, Arg0, …)`: one clause per primitive kind that
    /// answers the call, each guarded by that kind's BEAM type test and bodied
    /// by `emitPrimMethod`'s own lowering, then the `{unresolved_method, …}`
    /// abort. A clause is lowered into a scratch buffer first — `emitPrimMethod`
    /// decides whether it can answer while it emits — and dropped whole when it
    /// cannot, so a kind that declares the method but has no BEAM lowering
    /// costs nothing.
    fn emitPrimShimFn(self: *Emitter, shim: PrimShim) anyerror!void {
        const arity = shim.argc + 1;
        const labels = try self.fnLabelsFor(shim.name, arity);

        var names_buf: [1 + max_staged][]const u8 = undefined;
        var arg_names_buf: [max_staged][16]u8 = undefined;
        names_buf[0] = "recv";
        for (0..shim.argc) |i| {
            names_buf[i + 1] = std.fmt.bufPrint(&arg_names_buf[i], "arg{d}", .{i}) catch "arg";
        }
        const names = names_buf[0..arity];

        self.resetFnState(@intCast(arity));
        self.self_prim_kind = null;
        self.cur_fn_name = shim.callee;
        // The frame holds exactly the spilled parameters: a clause body is one
        // expression, which stages through x-registers and takes no stack slot.
        // A clause that turns out to need one is dropped below.
        self.num_y = @intCast(arity);
        try self.bindParams(names);

        // The receiver and the arguments as the identifiers `bindParams` just
        // bound, so `emitPrimMethod` stages them like any other call's operands.
        var recv: ast.Expr = shimIdent(names[0]);
        var arg_exprs: [max_staged]ast.Expr = undefined;
        var call_args: [max_staged]ast.CallArg = undefined;
        for (0..shim.argc) |i| {
            arg_exprs[i] = shimIdent(names[i + 1]);
            call_args[i] = .{ .label = null, .value = &arg_exprs[i] };
        }
        const cc = .{
            .callee = shim.callee,
            .args = @as([]const ast.CallArg, call_args[0..shim.argc]),
            .trailing = @as([]const ast.TrailingLambda, &.{}),
        };

        // Rendered sections, joined at the end — a clause is lowered before it
        // is known whether it can be lowered at all, so the guard that jumps
        // past it cannot be written first.
        var sections: std.ArrayListUnmanaged([]u8) = .empty;
        defer {
            for (sections.items) |sec| self.alloc.free(sec);
            sections.deinit(self.alloc);
        }
        const saved_out = self.out;
        defer self.out = saved_out;

        for (prim_shim_kinds) |pk| {
            if (!self.primKindDeclares(pk.kind, shim.callee)) continue;
            var clause: std.Io.Writer.Allocating = .init(self.alloc);
            defer clause.deinit();
            self.out = &clause.writer;
            self.min_live = 0;
            const answered = self.emitPrimMethod(pk.kind, shim.callee, &recv, cc, .tail) catch false;
            if (!answered or self.next_y != arity) {
                self.next_y = @intCast(arity);
                continue;
            }
            const next = self.allocLabel();
            var pre: std.Io.Writer.Allocating = .init(self.alloc);
            defer pre.deinit();
            self.out = &pre.writer;
            try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
            try beamEmitter.writeTest(self.out, pk.guard, next, &.{Op.xr(0)});
            try sections.append(self.alloc, try pre.toOwnedSlice());
            try sections.append(self.alloc, try clause.toOwnedSlice());
            var post: std.Io.Writer.Allocating = .init(self.alloc);
            defer post.deinit();
            self.out = &post.writer;
            try beamEmitter.writeLabel(self.out, next);
            try sections.append(self.alloc, try post.toOwnedSlice());
        }

        // The head is rendered last because `num_y` is only final now, and
        // prepended: `allocate` has to name the frame every clause deallocates.
        var head: std.Io.Writer.Allocating = .init(self.alloc);
        defer head.deinit();
        self.out = &head.writer;
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, shim.name, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, shim.name, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(arity);
        try self.emitParamSpill(arity);
        try sections.insert(self.alloc, 0, try head.toOwnedSlice());

        // No kind answered: the receiver is named in the abort, exactly as the
        // call site used to raise it.
        var tail: std.Io.Writer.Allocating = .init(self.alloc);
        defer tail.deinit();
        self.out = &tail.writer;
        try self.emitUnresolvedAbort("unresolved_method", shim.callee, arity);
        try beamEmitter.writeDeallocate(self.out, self.num_y);
        try beamEmitter.writeReturn(self.out);
        try sections.append(self.alloc, try tail.toOwnedSlice());

        self.cur_line += 1;
        try self.deferred_lambdas.append(self.alloc, try std.mem.concat(self.alloc, u8, sections.items));
    }

    /// Emit every interface `default fn` a call site reached, with `self`
    /// carrying the interface's primitive kind. Drained to a fixpoint.
    fn emitNeededDefaults(self: *Emitter) anyerror!void {
        var i: usize = 0;
        while (i < self.needed_defaults.count()) : (i += 1) {
            const d = self.needed_defaults.values()[i];
            const saved_kind = self.self_prim_kind;
            defer self.self_prim_kind = saved_kind;
            self.self_prim_kind = primKindForIface(d.iface);
            self.cur_fn_name = d.method.name;
            try self.emitMethodAsFn(d.iface, d.method);
        }
    }

    /// The instance lowering of a value-receiver call or member read at `loc`.
    /// Inside an interface `default fn` body (parsed from the prelude, so
    /// inference recorded nothing and its locs may collide with the program's)
    /// it is re-derived from `self`'s kind instead.
    fn instanceLowering(self: *const Emitter, loc: ast.Loc, recv: ast.Expr) ?envMod.InstanceLowering {
        if (self.self_prim_kind != null) {
            const k = self.selfPrimKind(recv) orelse return null;
            return .{ .prim = k };
        }
        return self.instance_lowerings.get(loc);
    }

    /// The primitive kind of a `Self`-typed expression inside a `default fn`
    /// body: `self`, or a method call on one whose interface method returns
    /// `Self` (`self.filter(pred)`).
    fn selfPrimKind(self: *const Emitter, e: ast.Expr) ?envMod.PrimKind {
        const k = self.self_prim_kind orelse return null;
        switch (e) {
            .identifier => |id| return switch (id.kind) {
                .ident => |n| if (std.mem.eql(u8, n, "self")) k else null,
                else => null,
            },
            .call => |c| {
                const cc = switch (c.kind) {
                    .call => |x| x,
                    else => return null,
                };
                if (cc.is_builtin) return null;
                const recv = cc.receiver orelse return null;
                if (self.selfPrimKind(recv.*) == null) return null;
                var b: [128]u8 = undefined;
                for (primIfaceChain(k)) |iface| {
                    const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface, cc.callee }) catch return null;
                    if (self.self_returns.contains(key)) return k;
                }
                return null;
            },
            .collection => |col| return switch (col.kind) {
                .grouped => |g| self.selfPrimKind(g.*),
                else => null,
            },
            else => return null,
        }
    }

    /// A call to a host-backed `declare fn`: its `@External.Beam` `.S` body,
    /// else its `@External.Erlang` target — `module:symbol` as a `call_ext`,
    /// a template evaluated through `'__bp_erl_eval'/2`. A fn with no beam or
    /// erlang target fails the lowering (`MissingExternalTarget`), like the
    /// other backends.
    fn lowerExternalCall(self: *Emitter, f: ast.FnDecl, cc: anytype, mode: CallMode, loc: ast.Loc) anyerror!void {
        // 06 C13 — every exit below is `error.MissingExternalTarget`; naming the
        // fn and the call site here is what turns it into a located diagnostic
        // upstream.
        self.missing_external = .{ .name = f.name, .target = "beam", .loc = loc };
        const argc = cc.args.len + cc.trailing.len;
        const self_first = f.params.len > 0 and std.mem.eql(u8, f.params[0].name, "self");
        if (f.externalFor("beam")) |ref| {
            if (ref.module.len == 0 and !self_first) {
                try self.renderBeamTemplate(ref.symbol, null, cc, mode);
                return;
            }
        }
        var exprs: [max_staged]ast.Expr = undefined;
        if (cc.args.len > max_staged) return error.TooManyOperands;
        for (cc.args, 0..) |arg, i| exprs[i] = arg.value.*;
        if (ast.externalHasArityBranches(f.annotations, "erlang")) {
            const template = ast.externalArityBranchFor(f.annotations, "erlang", argc) orelse return error.MissingExternalTarget;
            try self.evalTemplate(template, self_first, exprs[0..cc.args.len], cc.trailing, mode);
            return;
        }
        const ref = f.externalFor("erlang") orelse return error.MissingExternalTarget;
        if (ref.module.len > 0 and !primOpTemplate.looksLikeTemplate(ref.symbol) and
            std.mem.indexOfScalar(u8, ref.symbol, '(') == null)
        {
            try self.materializeCallArgs(cc.args, cc.trailing);
            try beamEmitter.writeCall(
                self.out,
                if (mode == .tail) .last else .normal,
                argc,
                .{ .ext = .{ .module = ref.module, .function = ref.symbol } },
                self.num_y,
            );
            return;
        }
        if (ref.module.len > 0) return error.MissingExternalTarget;
        try self.evalTemplate(ref.symbol, self_first, exprs[0..cc.args.len], cc.trailing, mode);
    }

    /// The host-backed `declare fn` a bare call names — this module's (or the
    /// prelude's), or one imported from another module.
    fn externalDeclFor(self: *const Emitter, name: []const u8) ?ast.FnDecl {
        if (self.reg_map.contains(name)) return null;
        if (self.externals.get(name)) |f| return f;
        if (self.crossOwnerOf(name, .@"fn") == null) return null;
        for (self.all_outputs) |*other| {
            const ok = switch (other.outcome) {
                .ok => |*o| o,
                else => continue,
            };
            for (ok.transformed.decls) |d| switch (d) {
                .@"fn" => |f| if (std.mem.eql(u8, f.name, name) and isHostDeclare(f)) return f,
                else => {},
            };
        }
        return null;
    }

    /// Evaluate an `@External.Erlang` template at run time: the template, with
    /// the receiver marker → `__BpSelf` and `$N` → `__BpAN` (and `$stringify(e)` → its
    /// `~p` text), goes to `'__bp_erl_eval'(Source, #{'__BpSelf' => …})`,
    /// which scans, parses and evaluates it with `erl_eval`. The Erlang text is
    /// the annotation author's, carried as a binary operand — the backend
    /// writes no target syntax of its own. `exprs` starts with the receiver
    /// when `has_recv`.
    fn evalTemplate(self: *Emitter, template_raw: []const u8, has_recv: bool, exprs: []const ast.Expr, trailing: anytype, mode: CallMode) anyerror!void {
        var src: std.ArrayListUnmanaged(u8) = .empty;
        defer src.deinit(self.alloc);
        // A template written inside a `"…"` annotation keeps its `\"` escapes.
        var template: std.ArrayListUnmanaged(u8) = .empty;
        defer template.deinit(self.alloc);
        var ti: usize = 0;
        while (ti < template_raw.len) : (ti += 1) {
            if (template_raw[ti] == '\\' and ti + 1 < template_raw.len and template_raw[ti + 1] == '"') continue;
            try template.append(self.alloc, template_raw[ti]);
        }
        const Ctx = struct {
            em: *Emitter,
            out: *std.ArrayListUnmanaged(u8),
            argc: usize,
            pub fn writeByte(c: *@This(), ch: u8) anyerror!void {
                try c.out.append(c.em.alloc, ch);
            }
            pub fn writeAll(c: *@This(), s: []const u8) anyerror!void {
                try c.out.appendSlice(c.em.alloc, s);
            }
            pub fn emitRecv(c: *@This()) anyerror!void {
                try c.out.appendSlice(c.em.alloc, "__BpSelf");
            }
            pub fn emitArg(c: *@This(), idx: usize) anyerror!void {
                var name_buf: [16]u8 = undefined;
                try c.out.appendSlice(c.em.alloc, try std.fmt.bufPrint(&name_buf, "__BpA{d}", .{idx}));
            }
            pub fn emitStringifyOpen(c: *@This()) anyerror!void {
                try c.out.appendSlice(c.em.alloc, "iolist_to_binary(io_lib:format(\"~p\", [");
            }
            pub fn emitStringifyClose(c: *@This()) anyerror!void {
                try c.out.appendSlice(c.em.alloc, "]))");
            }
        };
        const off: usize = @intFromBool(has_recv);
        var ctx = Ctx{ .em = self, .out = &src, .argc = exprs.len - off + trailing.len };
        try primOpTemplate.render(template.items, &ctx);
        try src.append(self.alloc, '.');

        const st = try self.stageOperands(exprs, trailing);
        const live = @max(self.min_live, st.x_top);
        var names: [max_staged][16]u8 = undefined;
        var pairs: [max_staged]beamEmitter.MapPair = undefined;
        for (0..st.len) |i| {
            const key = if (has_recv and i == 0)
                "__BpSelf"
            else
                try std.fmt.bufPrint(&names[i], "__BpA{d}", .{i - off});
            pairs[i] = .{ .key = Op.atom(key), .value = st.ops[i] };
        }
        const bindings: Op = if (st.len == 0) .{ .term = Term.mapOf(&.{}) } else blk: {
            const dst = @max(live, 1);
            try beamEmitter.writePutMap(self.out, false, .{ .term = Term.mapOf(&.{}) }, Dst.xr(dst), live, pairs[0..st.len]);
            break :blk Op.xr(dst);
        };
        try self.emitParallelMove(&.{ Op.str(src.items), bindings }, &.{ 0, 1 });
        const helper = try self.ensureEvalHelper();
        const labels = try self.fnLabelsFor(helper, 2);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 2, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 2, .{ .local = labels.entry }, self.num_y),
        }
    }

    /// Emit (once per module) `'__bp_erl_eval'(Source, Bindings)`:
    /// `erl_scan:string` → `erl_parse:parse_exprs` → `erl_eval:exprs`, the
    /// value of the last expression. A step that does not answer `ok`/`value`
    /// raises its answer with `erlang:error/1`.
    fn ensureEvalHelper(self: *Emitter) anyerror![]const u8 {
        if (self.eval_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'__bp_erl_eval'");
        try self.reserveFn(name, 2);
        const labels = try self.fnLabelsFor(name, 2);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;
        const w = self.out;
        const fail = self.allocLabel();
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 2, labels.entry);
        try beamEmitter.writeLabel(w, labels.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 2);
        try beamEmitter.writeLabel(w, labels.entry);
        try beamEmitter.writeAllocate(w, 1, 2);
        try beamEmitter.writeInitYregs(w, 1);
        try beamEmitter.writeMoveOp(w, Op.xr(1), Dst.yr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "binary_to_list" } }, 0);
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erl_scan", .function = "string" } }, 0);
        try beamEmitter.writeTest(w, .is_tagged_tuple, fail, &.{ Op.xr(0), .{ .untagged = 3 }, Op.atom("ok") });
        try beamEmitter.writeGetTupleElement(w, Op.xr(0), 1, Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erl_parse", .function = "parse_exprs" } }, 0);
        try beamEmitter.writeTest(w, .is_tagged_tuple, fail, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom("ok") });
        try beamEmitter.writeGetTupleElement(w, Op.xr(0), 1, Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erl_eval", .function = "exprs" } }, 0);
        try beamEmitter.writeTest(w, .is_tagged_tuple, fail, &.{ Op.xr(0), .{ .untagged = 3 }, Op.atom("value") });
        try beamEmitter.writeGetTupleElement(w, Op.xr(0), 1, Dst.xr(0));
        try beamEmitter.writeDeallocate(w, 1);
        try beamEmitter.writeReturn(w);
        try beamEmitter.writeLabel(w, fail);
        try beamEmitter.writeCall(w, .last, 1, .{ .ext = .{ .module = "erlang", .function = "error" } }, 1);
        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.eval_helper_name = name;
        return name;
    }

    /// §A5 BEAM dispatch: emit a primitive method call from its `#[@External.Erlang(
    /// "mod", "sym[(args)]")` annotation. Recognises three template shapes:
    /// `[self]` (1-arg call, `primRecvOnly`), `[X, self]` (2-arg with the
    /// receiver second, `primFunThenList` — fun or value, same byte shape) and
    /// `[self, X]` (2-arg with the receiver first, `primRecvThenArgs`). Bare
    /// symbol → declaration order: `[self, …cc.args]`, dispatched via the
    /// receiver-first path. Returns false on any unrecognised shape so the
    /// inline allow-list keeps owning irreducible cases.
    fn tryEmitPrimAnnotation(self: *Emitter, k: envMod.PrimKind, callee: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        var b: [128]u8 = undefined;
        const key = for (primIfaceChain(k)) |iface_name| {
            const kk = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface_name, callee }) catch return false;
            if (self.prim_beam_templates.contains(kk) or self.prim_erlang_dispatch.contains(kk)) break kk;
        } else return false;
        // §A6 BEAM-target template path (v0.beta.22 front 03): an
        // `@External.Beam("""…""")` annotation whose body carries the receiver /
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

    /// §A6 BEAM-target template renderer (v0.beta.22 front 03). Stages `recv`
    /// and the positional args (`stageCall`) and places them in `x0` and
    /// `x_{i+1}`, then walks `body` via the shared `comptime/primOpTemplate.zig`
    /// renderer with a BEAM-aware ctx that substitutes the receiver marker → `{x, 0}`,
    /// `$N` → `{x, N+1}`, and `$args` → the comma-separated `{x, 1..N}` list
    /// (mirroring the BEAM call_ext arg convention).
    ///
    /// **Tail mode**: `mode == .tail` appends `emitReturn` after the
    /// template body. The author can also choose to end the body with a
    /// `call_ext_last` / explicit `return.` — the trailing `return.` is
    /// idempotent (the loader collapses adjacent returns).
    fn renderBeamTemplate(self: *Emitter, body: []const u8, recv_expr: ?*const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const argc_usize = cc.args.len + cc.trailing.len;
        // `recv` into `{x, 0}` and argument `i` into `{x, i + 1}` (a bare
        // `declare fn` call has no receiver: argument `i` is `{x, i}`).
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
        const arg_base: usize = @intFromBool(recv_expr != null);

        const Ctx = struct {
            emitter: *Emitter,
            argc: usize,
            arg_base: usize,
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
                try beamEmitter.writeArg(c.emitter.out, Op.xr(idx + c.arg_base));
            }
        };
        var ctx = Ctx{ .emitter = self, .argc = argc_usize, .arg_base = arg_base };
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

    /// `fn(Recv)` — the sole operand is the receiver, lowered straight into `x0`.
    fn primRecvOnly(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, mode: CallMode) anyerror!void {
        try self.lowerExprIntoX0(recv_expr.*);
        try self.emitPrimCallExt(mod, fn_name, 1, mode);
    }

    /// `recv.prepend(x)` → `[x | recv]` — a single cons cell.
    fn primPrepend(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try beamEmitter.writeTestHeap(self.out, 2, @max(self.min_live, st.x_top));
        try beamEmitter.writePutList(self.out, st.ops[1], st.ops[0], Dst.xr(0));
        if (mode == .tail) try self.emitReturn();
    }

    /// `recv.append(xs)` → `recv ++ xs` (`lists:append/2`; `xs` is already a list).
    /// The (often-literal) arg is lowered first into `x1`, then the receiver into
    /// `x0` — a simple receiver won't clobber `x1`.
    fn primAppendList(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
        try self.emitPrimCallExt("lists", "append", 2, mode);
    }

    /// `recv.push(x)` → `recv ++ [x]` (`lists:append/2`).
    fn primAppendElem(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        // `[Elem]` goes to the first register above every staged value.
        const live = @max(self.min_live, st.x_top);
        const tmp = @max(live, 1);
        try beamEmitter.writeTestHeap(self.out, 2, live);
        try beamEmitter.writePutList(self.out, st.ops[1], Op.nil, Dst.xr(tmp));
        try self.emitParallelMove(&.{ st.ops[0], Op.xr(tmp) }, &.{ 0, 1 });
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
    /// Matches the erlang template `lists:sublist($0, ($1)+1, (($2)-($1)))`.
    fn primArraySlice2(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!bool {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        const live = @max(self.min_live, st.x_top);
        // x{live} = start + 1, x{live+1} = end - start; both above every staged value.
        try beamEmitter.writeGcBif(self.out, .add, live, &.{ st.ops[1], Op.int(1) }, Dst.xr(live));
        try beamEmitter.writeGcBif(self.out, .sub, live + 1, &.{ st.ops[2], st.ops[1] }, Dst.xr(live + 1));
        try self.emitParallelMove(&.{ st.ops[0], Op.xr(live), Op.xr(live + 1) }, &.{ 0, 1, 2 });
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
    /// Matches the erlang template `(binary:match($0, $1) =/= nomatch)`
    /// / `(string:prefix($0, $1) =/= nomatch)` byte-for-byte.
    fn primCmpAgainstNomatch(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        if (cc.args.len + cc.trailing.len != 1) {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (bad arity): {s}/{d}", .{ fn_name, cc.args.len + cc.trailing.len });
            if (mode == .tail) try self.emitReturn();
            return;
        }
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
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
    /// true -> lists:nth(__I + 1, __L); false -> undefined end end)($0, $1)`.
    fn primAt(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
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
    /// -1 end, __Find(0, __L) end)($0, $1)`.
    fn primIndexOf(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
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
    /// __E; true -> io_lib:format("~p", [__E]) end end, $0)))`.
    fn primJoin(self: *Emitter, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        if (cc.args.len + cc.trailing.len != 1) {
            try beamEmitter.writeComment(self.out, "prim method not lowered on beam (bad arity): join/{d}", .{cc.args.len + cc.trailing.len});
            if (mode == .tail) try self.emitReturn();
            return;
        }
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
        const helper = try self.ensureJoinHelper();
        const labels = try self.fnLabelsFor(helper, 2);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 2, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 2, .{ .local = labels.entry }, self.num_y),
        }
    }

    /// Emit (once per module) `'-bp_join-'(List, Sep)`: every element through
    /// `'-bp_stringify-'/1` (`lists:map`), `lists:join(Sep, …)`, then
    /// `iolist_to_binary/1`. The separator waits on the stack across the map
    /// call.
    fn ensureJoinHelper(self: *Emitter) anyerror![]const u8 {
        if (self.join_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'-bp_join-'");
        try self.reserveFn(name, 2);
        const labels = try self.fnLabelsFor(name, 2);
        const stringify = try self.ensureStringifyHelper();
        const stringify_labels = try self.fnLabelsFor(stringify, 1);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;
        const w = self.out;
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 2, labels.entry);
        try beamEmitter.writeLabel(w, labels.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 2);
        try beamEmitter.writeLabel(w, labels.entry);
        try beamEmitter.writeAllocate(w, 1, 2);
        try beamEmitter.writeInitYregs(w, 1);
        try beamEmitter.writeMoveOp(w, Op.xr(1), Dst.yr(0));
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.xr(1));
        try beamEmitter.writeTestHeapAlloc(w, 0, 1, 2);
        try beamEmitter.writeMakeFun3(w, stringify_labels.entry, &.{});
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "map" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "join" } }, 0);
        try beamEmitter.writeCall(w, .last, 1, .{ .ext = .{ .module = "erlang", .function = "iolist_to_binary" } }, 1);
        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.join_helper_name = name;
        return name;
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
    /// Call `'__bp_add'/2` on `{x, 0}` and `{x, 1}`; the sum lands in `{x, 0}`.
    fn callAddHelper(self: *Emitter) anyerror!void {
        const name = try self.ensureAddHelper();
        const labels = try self.fnLabelsFor(name, 2);
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .local = labels.entry }, 0);
    }

    /// `'__bp_add'(A, B)`: `+` on operands of unknown type — two binaries
    /// concatenate (`iolist_to_binary([A, B])`), anything else adds. Parity
    /// with the erlang backend's helper of the same name.
    fn ensureAddHelper(self: *Emitter) anyerror![]const u8 {
        if (self.add_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'__bp_add'");
        try self.reserveFn(name, 2);
        const labels = try self.fnLabelsFor(name, 2);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;
        const w = self.out;

        const arith_l = self.allocLabel();
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 2, labels.entry);
        try beamEmitter.writeLabel(w, labels.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 2);
        try beamEmitter.writeLabel(w, labels.entry);
        try beamEmitter.writeTest(w, .is_binary, arith_l, &.{Op.xr(0)});
        try beamEmitter.writeTest(w, .is_binary, arith_l, &.{Op.xr(1)});
        try beamEmitter.writeTestHeap(w, 4, 2);
        try beamEmitter.writePutList(w, Op.xr(1), Op.nil, Dst.xr(1));
        try beamEmitter.writePutList(w, Op.xr(0), Op.xr(1), Dst.xr(0));
        try beamEmitter.writeCall(w, .only, 1, .{ .ext = .{ .module = "erlang", .function = "iolist_to_binary" } }, 0);
        try beamEmitter.writeLabel(w, arith_l);
        try beamEmitter.writeGcBif(w, .add, 2, &.{ Op.xr(0), Op.xr(1) }, Dst.xr(0));
        try beamEmitter.writeReturn(w);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.add_helper_name = name;
        return name;
    }

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
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        const arg: Op = if (st.len > 1) st.ops[1] else Op.nil;
        try self.emitParallelMove(&.{ arg, st.ops[0] }, &.{ 0, 1 });
        try self.emitPrimCallExt(mod, fn_name, 2, mode);
    }

    /// `fn(Arg, Recv)` — `lists:member`. List in `x1`, the data arg in `x0`.
    fn primArgThenList(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, mode: CallMode) anyerror!void {
        try self.primFunThenList(mod, fn_name, recv_expr, cc, mode);
    }

    /// `fn(Recv, Arg [, Lit])` — receiver stays in `x0`; the (simple) arg goes to
    /// `x1`, with an optional literal in `x2` (`string:split(S, Sep, all)`). A
    /// non-simple arg would need to clobber `x0`, so it falls back to the limit.
    fn primRecvThenArgs(self: *Emitter, mod: []const u8, fn_name: []const u8, recv_expr: *const ast.Expr, cc: anytype, extra_lit: ?Op, mode: CallMode) anyerror!void {
        const st = try self.stageCall(recv_expr, cc.args, cc.trailing);
        try self.placeStaged(&st);
        var arity: usize = st.len;
        if (extra_lit) |lit| {
            try beamEmitter.writeMoveOp(self.out, lit, Dst.xr(arity));
            arity += 1;
        }
        try self.emitPrimCallExt(mod, fn_name, arity, mode);
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
        const st = try self.stageCall(recv_expr, args, &[_]ast.TrailingLambda{});
        try self.placeStaged(&st);
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
    fn lowerRecordConstruct(self: *Emitter, args: anytype, fields: ?[]const []const u8, type_name: ?[]const u8) anyerror!void {
        // Decision 21 (T2): `{TypeAtom, F1, …, Fn}`, the fields in DECLARED
        // order, a field the call does not fill `undefined`. Without a declared
        // shape (an anonymous, all-labelled construct) there is no order and no
        // type to name, so the map it used to be stands.
        const declared = fields orelse {
            const n = args.len;
            if (n == 0) {
                try beamEmitter.writeMove(self.out, Term.mapOf(&.{}), 0);
                return;
            }
            const st = try self.stageCall(null, args, &[_]ast.TrailingLambda{});
            var pairs: [max_staged]beamEmitter.MapPair = undefined;
            for (args, 0..) |arg, i| {
                pairs[i] = .{ .key = Op.atom(arg.label orelse "_arg"), .value = st.ops[i] };
            }
            try beamEmitter.writePutMap(
                self.out,
                false,
                .{ .term = Term.mapOf(&.{}) },
                Dst.xr(0),
                @max(self.min_live, st.x_top),
                pairs[0..n],
            );
            return;
        };
        if (declared.len + 1 > max_staged) return error.TooManyOperands;
        var tag_buf: [256]u8 = undefined;
        const tag = try atomName(try self.recordTagAtom(type_name.?), &tag_buf);
        const st = try self.stageCall(null, args, &[_]ast.TrailingLambda{});
        var elems: [max_staged + 1]Op = undefined;
        elems[0] = Op.atom(tag);
        for (0..declared.len) |i| elems[i + 1] = Op.atom("undefined");
        for (args, 0..) |arg, i| {
            const at = if (arg.label) |lbl| fieldIndexOf(declared, lbl) orelse i else i;
            if (at >= declared.len) continue;
            elems[at + 1] = st.ops[i];
        }
        try beamEmitter.writeTestHeap(self.out, declared.len + 2, @max(self.min_live, st.x_top));
        try beamEmitter.writePutTuple2(self.out, Dst.xr(0), elems[0 .. declared.len + 1]);
    }

    /// `#{name => Value, …}` from literal fields, via `put_map_assoc`.
    fn lowerFieldMap(self: *Emitter, fields: anytype) anyerror!void {
        if (fields.len == 0) {
            try beamEmitter.writeMove(self.out, Term.mapOf(&.{}), 0);
            return;
        }
        if (fields.len > max_staged) return error.TooManyOperands;
        var exprs: [max_staged]ast.Expr = undefined;
        for (fields, 0..) |f, i| exprs[i] = f.value.*;
        const st = try self.stageOperands(exprs[0..fields.len], &[_]ast.TrailingLambda{});
        var pairs: [max_staged]beamEmitter.MapPair = undefined;
        for (fields, 0..) |f, i| pairs[i] = .{ .key = Op.atom(f.name), .value = st.ops[i] };
        try beamEmitter.writePutMap(
            self.out,
            false,
            .{ .term = Term.mapOf(&.{}) },
            Dst.xr(0),
            @max(self.min_live, st.x_top),
            pairs[0..fields.len],
        );
    }

    /// Build a tagged tuple `{Tag, Field0, …}` from an enum variant constructor
    /// `Shape.Circle(r: 5)` → `{Circle, 5}`. The tag atom matches the one tested
    /// by `is_tagged_tuple` when the variant is pattern-matched. Result in `{x, 0}`.
    fn lowerTaggedTuple(self: *Emitter, tag: []const u8, args: anytype) anyerror!void {
        const n = args.len;
        const st = try self.stageCall(null, args, &[_]ast.TrailingLambda{});
        // A tuple of `n + 1` elements (tag + fields) needs `n + 2` heap words.
        try beamEmitter.writeTestHeap(self.out, n + 2, @max(self.min_live, st.x_top));
        var tag_buf: [256]u8 = undefined;
        const tag_atom = try atomName(tag, &tag_buf);
        var elems: [max_staged + 1]Op = undefined;
        elems[0] = Op.atom(tag_atom);
        for (0..n) |i| elems[i + 1] = st.ops[i];
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
        if (isPrintBuiltin(cc.callee)) {
            try self.lowerPrint(cc.args, mode);
            return;
        }
        if (std.mem.eql(u8, cc.callee, ast.is_builtin_name) and cc.isType != null) {
            try self.lowerIsCall(cc);
            if (mode == .tail) try self.emitReturn();
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
        if (std.mem.eql(u8, cc.callee, ast.index_builtin_name)) {
            try self.lowerIndexExpr(cc, mode);
            return;
        }
        // A builtin this backend does not lower **aborts**, it does not fall
        // through. Emitting only a comment left whatever happened to be in
        // `{x, 0}` there — the receiver, or the previous statement's `ok` — so
        // the program ran to completion and printed a wrong answer with exit 0.
        // `12-language-tests` measured that on the index expression before
        // `lowerIndexExpr` existed, and `@print(v is i32)` still shows it:
        // beam printed `7` and then `ok` three times for four `is` tests, where
        // erlang refuses to compile (`function is/1 undefined`) and commonJS
        // answers the four booleans. A silent wrong answer is worse than a
        // crash, and this backend's own convention is the loud one — the same
        // `{unresolved_identifier, N}` / `{unresolved_method, N, A}` backstop
        // (README `Notes`: "the run-time abort on an unbound name is the
        // backstop, not a fix"). No beam snapshot reaches this path, so nothing
        // is re-recorded by making it loud.
        try self.emitUnresolvedAbort("unsupported_builtin", cc.callee, cc.args.len);
    }

    /// Decision 30's index expression, which the parser hands every backend as
    /// the builtin call `"[]"` over `(receiver, index)` (`ast.zig:1717-1740`):
    /// `xs[0]`, `d["k"]`, `s[0]`, `t[0]` and the slice `xs[0..2]` — the same
    /// node with a `range` second argument. Beam has no type at the call site
    /// (the checker's half of decision 30 is `01-checker`'s), so the receiver is
    /// told apart by its runtime tag inside one of two helpers; the slice is
    /// told apart HERE, because the range is in the AST and lowering it as a
    /// value would build the `lists:seq/2` list the slice does not need.
    ///
    /// Before this, the call fell into the unrecognised-builtin path: `xs[0]`
    /// printed the whole list and `xs[2]` printed `ok` (measured 2026-09-18).
    fn lowerIndexExpr(self: *Emitter, cc: anytype, mode: CallMode) anyerror!void {
        if (cc.args.len != 2) {
            try beamEmitter.writeComment(self.out, "unsupported index arity: {d}", .{cc.args.len});
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
            if (mode == .tail) try self.emitReturn();
            return;
        }
        const recv = cc.args[0].value;
        const idx = cc.args[1].value;
        const no_trailing: []const ast.TrailingLambda = &.{};
        if (idx.* == .collection and idx.collection.kind == .range) {
            const r = idx.collection.kind.range;
            if (r.end) |end| {
                const st = try self.stageOperands(&.{ recv.*, r.start.*, end.* }, no_trailing);
                try self.emitParallelMove(&.{ st.ops[0], st.ops[1], st.ops[2] }, &.{ 0, 1, 2 });
            } else {
                const st = try self.stageOperands(&.{ recv.*, r.start.* }, no_trailing);
                try self.emitParallelMove(&.{ st.ops[0], st.ops[1] }, &.{ 0, 1 });
                try beamEmitter.writeMoveOp(self.out, Op.atom("infinity"), Dst.xr(2));
            }
            const helper = try self.ensureSliceHelper();
            const labels = try self.fnLabelsFor(helper, 3);
            switch (mode) {
                .non_tail => try beamEmitter.writeCall(self.out, .normal, 3, .{ .local = labels.entry }, 0),
                .tail => try beamEmitter.writeCall(self.out, .last, 3, .{ .local = labels.entry }, self.num_y),
            }
            return;
        }
        const st = try self.stageOperands(&.{ recv.*, idx.* }, no_trailing);
        try self.emitParallelMove(&.{ st.ops[0], st.ops[1] }, &.{ 0, 1 });
        const helper = try self.ensureIndexHelper();
        const labels = try self.fnLabelsFor(helper, 2);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 2, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 2, .{ .local = labels.entry }, self.num_y),
        }
    }

    /// Emit (once per module) `'__bp_index'(Recv, Idx)` — decision 30's scalar
    /// index, dispatched on the receiver's runtime tag: a map answers
    /// `maps:get(Idx, Recv, undefined)`, a binary the one-character
    /// `string:slice(Recv, Idx, 1)`, a tuple `element(Idx + 1, Recv)`, and
    /// anything else (a list) the bounds-checked `'-bp_at-'/2` the `xs.at(i)`
    /// method already uses, so an out-of-range index answers `undefined`
    /// instead of raising.
    fn ensureIndexHelper(self: *Emitter) anyerror![]const u8 {
        if (self.index_helper_name) |n| return n;
        const at = try self.ensureAtHelper();
        const at_labels = try self.fnLabelsFor(at, 2);
        const name = try self.alloc.dupe(u8, "'__bp_index'");
        try self.reserveFn(name, 2);
        const labels = try self.fnLabelsFor(name, 2);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;

        const not_map = self.allocLabel();
        const not_bin = self.allocLabel();
        const not_tuple = self.allocLabel();
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, name, 2, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, name, 2);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try beamEmitter.writeAllocate(self.out, 2, 2);
        try beamEmitter.writeInitYregs(self.out, 2);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(0)); // y0 = receiver
        try beamEmitter.writeMoveOp(self.out, Op.xr(1), Dst.yr(1)); // y1 = index

        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(self.out, .is_map, not_map, &.{Op.xr(0)});
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(2));
        try beamEmitter.writeCall(self.out, .last, 3, .{ .ext = .{ .module = "maps", .function = "get" } }, 2);

        try beamEmitter.writeLabel(self.out, not_map);
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(self.out, .is_binary, not_bin, &.{Op.xr(0)});
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(1));
        try beamEmitter.writeMoveOp(self.out, Op.int(1), Dst.xr(2));
        try beamEmitter.writeCall(self.out, .last, 3, .{ .ext = .{ .module = "string", .function = "slice" } }, 2);

        try beamEmitter.writeLabel(self.out, not_bin);
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(self.out, .is_tuple, not_tuple, &.{Op.xr(0)});
        try beamEmitter.writeGcBif(self.out, .add, 0, &.{ Op.yr(1), Op.int(1) }, Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(self.out, .last, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 2);

        try beamEmitter.writeLabel(self.out, not_tuple);
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(1));
        try beamEmitter.writeCall(self.out, .last, 2, .{ .local = at_labels.entry }, 2);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.index_helper_name = name;
        return name;
    }

    /// Emit (once per module) `'__bp_slice'(Recv, Start, End)` — decision 30's
    /// index whose index is a range, half-open like every other `..` in the
    /// language, with `End` the atom `infinity` for `xs[0..]` (the convention
    /// `lowerRange` already uses). A binary answers `string:slice/2,3` and
    /// anything else `lists:sublist/3`, both of which clamp instead of raising.
    fn ensureSliceHelper(self: *Emitter) anyerror![]const u8 {
        if (self.slice_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'__bp_slice'");
        try self.reserveFn(name, 3);
        const labels = try self.fnLabelsFor(name, 3);
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;

        const bounded = self.allocLabel();
        const open_list = self.allocLabel();
        const bounded_list = self.allocLabel();
        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, name, 3, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, name, 3);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try beamEmitter.writeAllocate(self.out, 3, 3);
        try beamEmitter.writeInitYregs(self.out, 3);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(0)); // y0 = receiver
        try beamEmitter.writeMoveOp(self.out, Op.xr(1), Dst.yr(1)); // y1 = start
        try beamEmitter.writeMoveOp(self.out, Op.xr(2), Dst.yr(2)); // y2 = end (or `infinity`)

        // `is_eq` jumps when the two are NOT equal, so falling through is the
        // open-ended `xs[Start..]`.
        try beamEmitter.writeTest(self.out, .is_eq, bounded, &.{ Op.yr(2), Op.atom("infinity") });
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(self.out, .is_binary, open_list, &.{Op.xr(0)});
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(1));
        try beamEmitter.writeCall(self.out, .last, 2, .{ .ext = .{ .module = "string", .function = "slice" } }, 3);
        try beamEmitter.writeLabel(self.out, open_list);
        // `lists:sublist(Recv, Start + 1, length(Recv))` — a length larger than
        // what is left is exactly "the rest". The length is parked in `y2`,
        // whose `infinity` is dead on this edge, so the `gc_bif` that computes
        // `Start + 1` needs no live x-registers.
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "length" } }, 0);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(2));
        try beamEmitter.writeGcBif(self.out, .add, 0, &.{ Op.yr(1), Op.int(1) }, Dst.xr(1));
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.yr(2), Dst.xr(2));
        try beamEmitter.writeCall(self.out, .last, 3, .{ .ext = .{ .module = "lists", .function = "sublist" } }, 3);

        try beamEmitter.writeLabel(self.out, bounded);
        // `Len = End - Start`, parked in y2 over the receiver's type test.
        try beamEmitter.writeGcBif(self.out, .sub, 0, &.{ Op.yr(2), Op.yr(1) }, Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(2));
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(self.out, .is_binary, bounded_list, &.{Op.xr(0)});
        try beamEmitter.writeMoveOp(self.out, Op.yr(1), Dst.xr(1));
        try beamEmitter.writeMoveOp(self.out, Op.yr(2), Dst.xr(2));
        try beamEmitter.writeCall(self.out, .last, 3, .{ .ext = .{ .module = "string", .function = "slice" } }, 3);
        try beamEmitter.writeLabel(self.out, bounded_list);
        try beamEmitter.writeGcBif(self.out, .add, 0, &.{ Op.yr(1), Op.int(1) }, Dst.xr(1));
        try beamEmitter.writeMoveOp(self.out, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeMoveOp(self.out, Op.yr(2), Dst.xr(2));
        try beamEmitter.writeCall(self.out, .last, 3, .{ .ext = .{ .module = "lists", .function = "sublist" } }, 3);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.slice_helper_name = name;
        return name;
    }

    /// `@print(a, b, …)` → `'__bp_print'([A, B, …])` (semantics decision 1): the
    /// helper prints every value on one line, space-separated — a binary as its
    /// text (`~ts`), anything else through `~p` — the verb picked at runtime,
    /// byte-identical to the erlang backend's `'__bp_print'/1`.
    fn lowerPrint(self: *Emitter, args: anytype, mode: CallMode) anyerror!void {
        if (args.len == 1) {
            try self.lowerExprIntoX0(args[0].value.*);
            try beamEmitter.writeTestHeap(self.out, 2, 1);
            try beamEmitter.writePutList(self.out, Op.xr(0), Op.nil, Dst.xr(0));
        } else {
            const elems = try self.alloc.alloc(ast.Expr, args.len);
            defer self.alloc.free(elems);
            for (args, 0..) |arg, i| elems[i] = arg.value.*;
            try self.lowerListOf(elems, null);
        }
        const helper = try self.ensurePrintHelper();
        const labels = try self.fnLabelsFor(helper, 1);
        switch (mode) {
            .non_tail => try beamEmitter.writeCall(self.out, .normal, 1, .{ .local = labels.entry }, 0),
            .tail => try beamEmitter.writeCall(self.out, .last, 1, .{ .local = labels.entry }, self.num_y),
        }
    }

    /// A string `+` chain → one binary: its segments (left to right, empty
    /// literals dropped) become a list, each rendered by `'-bp_stringify-'/1`
    /// (a binary is itself, an integer `integer_to_binary`, anything else its
    /// `~p` text — the erlang backend's per-segment `'__bp_text'/1` rule, so a
    /// non-string operand concatenates as text instead of raising `badarith`),
    /// then flattened with `iolist_to_binary/1`.
    fn lowerStringConcat(self: *Emitter, e: ast.Expr) anyerror!void {
        var segs: std.ArrayListUnmanaged(ast.Expr) = .empty;
        defer segs.deinit(self.alloc);
        try self.collectStringSegments(e, &segs);
        try self.lowerStringSegments(segs.items);
    }

    fn collectStringSegments(self: *Emitter, e: ast.Expr, out: *std.ArrayListUnmanaged(ast.Expr)) !void {
        if (e == .binaryOp and e.binaryOp.op == .add and self.isStringExpr(&self.string_locals, e)) {
            try self.collectStringSegments(e.binaryOp.lhs.*, out);
            try self.collectStringSegments(e.binaryOp.rhs.*, out);
            return;
        }
        try out.append(self.alloc, e);
    }

    fn lowerStringSegments(self: *Emitter, segs: []const ast.Expr) anyerror!void {
        try self.lowerListOf(segs, null);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
        const helper = try self.ensureStringifyHelper();
        const helper_labels = try self.fnLabelsFor(helper, 1);
        try self.emitMakeFun(helper_labels.entry, 2, &.{});
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = "map" } }, 0);
        try beamEmitter.writeCall(self.out, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "iolist_to_binary" } }, 0);
    }

    /// Emit (once per module) the four functions decision 8 §7's formatter is
    /// on BEAM: `'__bp_print'/1`, the value renderer `'__bp_show'/2` and the two
    /// one-argument wrappers `lists:map` needs (`'-bp_show_top-'`,
    /// `'-bp_show_elem-'`, which are `'__bp_show'(V, true)` and
    /// `'__bp_show'(V, false)`).
    ///
    /// It replaces the per-value format-verb machinery (`'__bp_print_fmt'/1` +
    /// `'__bp_print_sep'/1`, which chose `~ts` for a binary and `~p` for
    /// everything else). That printed every compound value as an **Erlang
    /// term** — decision 1a never reached this backend — so a nested string
    /// came out `<<"a">>` and a tuple `{1,<<"a">>}`, and §7's separator space
    /// was missing everywhere.
    ///
    /// `'__bp_show'(V, Top)`, the beam twin of the erlang backend's function of
    /// the same name:
    ///
    /// | `V` | text |
    /// |---|---|
    /// | a binary, `Top` | itself — a top-level string prints bare |
    /// | a binary, nested | `io_lib:write_string(unicode:characters_to_list(V))` — `"a\"b"`, source escapes and all, in one call instead of a per-character walk |
    /// | a list | `[$[, lists:join(<<", ">>, …), $]]` over the elements |
    /// | a tuple whose first element is an atom other than `true`/`false`/`undefined` | `~p` — a variant or a `@Result`; §7's `Shape.Square(side: 4)` is `13-module-identity`'s F3 |
    /// | any other tuple | `[$#, $(, lists:join(<<", ">>, …), $)]` |
    /// | anything else | `~p` — an integer, a float (which keeps its `.0`, §7 F5), an atom, a record's map (§7 F2, also 13's) |
    fn ensurePrintHelper(self: *Emitter) anyerror![]const u8 {
        if (self.print_helper_name) |n| return n;
        const name = try self.alloc.dupe(u8, "'__bp_print'");
        const show_name = "'__bp_show'";
        const top_name = "'-bp_show_top-'";
        const elem_name = "'-bp_show_elem-'";
        const tagged_name = "'__bp_tagged'";
        const render_name = "'__bp_render'";
        const pair_name = "'-bp_render_pair-'";
        try self.reserveFn(name, 1);
        try self.reserveFn(show_name, 2);
        try self.reserveFn(top_name, 1);
        try self.reserveFn(elem_name, 1);
        try self.reserveFn(tagged_name, 2);
        try self.reserveFn(render_name, 1);
        try self.reserveFn(pair_name, 1);
        const main_l = try self.fnLabelsFor(name, 1);
        const show_l = try self.fnLabelsFor(show_name, 2);
        const top_l = try self.fnLabelsFor(top_name, 1);
        const elem_l = try self.fnLabelsFor(elem_name, 1);
        const tagged_l = try self.fnLabelsFor(tagged_name, 2);
        const render_l = try self.fnLabelsFor(render_name, 1);
        const pair_l = try self.fnLabelsFor(pair_name, 1);

        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &buf.writer;
        const w = self.out;

        // '__bp_print'(Values) ->
        //     io:format("~ts~n", [lists:join(<<" ">>, lists:map(fun top/1, Values))]).
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, name, 1, main_l.entry);
        try beamEmitter.writeLabel(w, main_l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, name, 1);
        try beamEmitter.writeLabel(w, main_l.entry);
        try beamEmitter.writeAllocate(w, 1, 1);
        try beamEmitter.writeInitYregs(w, 1);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(0));
        try beamEmitter.writeTestHeapAlloc(w, 0, 1, 0);
        try beamEmitter.writeMakeFun3(w, top_l.entry, &.{});
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "map" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.str(" "), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "join" } }, 0);
        try beamEmitter.writeTestHeap(w, 2, 1);
        try beamEmitter.writePutList(w, Op.xr(0), Op.nil, Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.str("~ts~n"), Dst.xr(0));
        try beamEmitter.writeCall(w, .last, 2, .{ .ext = .{ .module = "io", .function = "format" } }, 1);

        // '-bp_show_top-'(V) -> '__bp_show'(V, true).
        // '-bp_show_elem-'(V) -> '__bp_show'(V, false).
        for ([_]struct { n: []const u8, l: FnLabels, flag: []const u8 }{
            .{ .n = top_name, .l = top_l, .flag = "true" },
            .{ .n = elem_name, .l = elem_l, .flag = "false" },
        }) |wrapper| {
            try beamEmitter.writeBlankLine(w);
            try beamEmitter.writeFunctionHeader(w, wrapper.n, 1, wrapper.l.entry);
            try beamEmitter.writeLabel(w, wrapper.l.func_info);
            try beamEmitter.writeLine(w, self.module_name, self.cur_line);
            try beamEmitter.writeFuncInfo(w, self.module_name, wrapper.n, 1);
            try beamEmitter.writeLabel(w, wrapper.l.entry);
            try beamEmitter.writeMoveOp(w, Op.atom(wrapper.flag), Dst.xr(1));
            try beamEmitter.writeCall(w, .only, 2, .{ .local = show_l.entry }, 0);
        }

        // '__bp_show'(V, Top).
        const nested = self.allocLabel();
        const not_bin = self.allocLabel();
        const not_list = self.allocLabel();
        const plain_tuple = self.allocLabel();
        const not_tuple = self.allocLabel();
        const tagged = self.allocLabel();
        const generic = self.allocLabel();
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, show_name, 2, show_l.entry);
        try beamEmitter.writeLabel(w, show_l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, show_name, 2);
        try beamEmitter.writeLabel(w, show_l.entry);
        try beamEmitter.writeAllocate(w, 2, 2);
        try beamEmitter.writeInitYregs(w, 2);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(0)); // y0 = V
        try beamEmitter.writeMoveOp(w, Op.xr(1), Dst.yr(1)); // y1 = Top, then scratch

        // A binary: itself at the top level, quoted and escaped inside.
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(w, .is_binary, not_bin, &.{Op.xr(0)});
        try beamEmitter.writeTest(w, .is_eq, nested, &.{ Op.yr(1), Op.atom("true") });
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);
        try beamEmitter.writeLabel(w, nested);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "unicode", .function = "characters_to_list" } }, 0);
        try beamEmitter.writeCall(w, .last, 1, .{ .ext = .{ .module = "io_lib", .function = "write_string" } }, 2);

        // A list: `[` … `]`, elements separated by `", "`.
        try beamEmitter.writeLabel(w, not_bin);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(w, .is_list, not_list, &.{Op.xr(0)});
        try self.emitShowJoin(w, elem_l.entry, Op.yr(0));
        try beamEmitter.writeTestHeap(w, 6, 1);
        try beamEmitter.writePutList(w, Op.int(']'), Op.nil, Dst.xr(1));
        try beamEmitter.writePutList(w, Op.xr(0), Op.xr(1), Dst.xr(0));
        try beamEmitter.writePutList(w, Op.int('['), Op.xr(0), Dst.xr(0));
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);

        // A tuple: `#(` … `)`, unless its first element is an atom other than
        // `true`/`false`/`undefined` — then it is a variant or a `@Result`, and
        // `~p` stands in until 13 gives a value its own type identity.
        try beamEmitter.writeLabel(w, not_list);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(w, .is_tuple, not_tuple, &.{Op.xr(0)});
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "tuple_size" } }, 0);
        try beamEmitter.writeTest(w, .is_lt, plain_tuple, &.{ Op.int(0), Op.xr(0) });
        try beamEmitter.writeMoveOp(w, Op.int(1), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
        try beamEmitter.writeTest(w, .is_atom, plain_tuple, &.{Op.xr(0)});
        // `is_ne_exact` branches when the two ARE equal, so each of these three
        // sends a bool or an absent `@Option` to the `#(…)` shape.
        try beamEmitter.writeTest(w, .is_ne_exact, plain_tuple, &.{ Op.xr(0), Op.atom("true") });
        try beamEmitter.writeTest(w, .is_ne_exact, plain_tuple, &.{ Op.xr(0), Op.atom("false") });
        try beamEmitter.writeTest(w, .is_ne_exact, plain_tuple, &.{ Op.xr(0), Op.atom("undefined") });
        // A value that names its own declaration (decision 21): `{x, 0}` holds
        // the tag, `{y, 0}` the value.
        try beamEmitter.writeJump(w, tagged);

        try beamEmitter.writeLabel(w, plain_tuple);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "tuple_to_list" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(1));
        try self.emitShowJoin(w, elem_l.entry, Op.yr(1));
        try beamEmitter.writeTestHeap(w, 8, 1);
        try beamEmitter.writePutList(w, Op.int(')'), Op.nil, Dst.xr(1));
        try beamEmitter.writePutList(w, Op.xr(0), Op.xr(1), Dst.xr(0));
        try beamEmitter.writePutList(w, Op.int('('), Op.xr(0), Dst.xr(0));
        try beamEmitter.writePutList(w, Op.int('#'), Op.xr(0), Dst.xr(0));
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);

        // Not a tuple: a bare atom is a unit variant's tag (options § 4, "qualify
        // the tag"), so the same dispatch reads it. `true`, `false` and
        // `undefined` are not values a declaration builds.
        try beamEmitter.writeLabel(w, not_tuple);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTest(w, .is_atom, generic, &.{Op.xr(0)});
        try beamEmitter.writeTest(w, .is_ne_exact, generic, &.{ Op.xr(0), Op.atom("true") });
        try beamEmitter.writeTest(w, .is_ne_exact, generic, &.{ Op.xr(0), Op.atom("false") });
        try beamEmitter.writeTest(w, .is_ne_exact, generic, &.{ Op.xr(0), Op.atom("undefined") });

        try beamEmitter.writeLabel(w, tagged);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .last, 2, .{ .local = tagged_l.entry }, 2);

        try beamEmitter.writeLabel(w, generic);
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(0));
        try beamEmitter.writeTestHeap(w, 2, 1);
        try beamEmitter.writePutList(w, Op.xr(0), Op.nil, Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.str("~p"), Dst.xr(0));
        try beamEmitter.writeCall(w, .last, 2, .{ .ext = .{ .module = "io_lib", .function = "format" } }, 2);

        try self.emitTaggedHelpers(w, tagged_name, tagged_l, render_name, render_l, pair_name, pair_l, show_l);

        self.out = saved_out;
        try self.deferred_lambdas.append(self.alloc, try buf.toOwnedSlice());
        buf.deinit();
        self.print_helper_name = name;
        return name;
    }

    /// Decision 8 §7's dispatch, the BEAM twin of the erlang backend's
    /// `'__bp_tagged'/2` + `'__bp_render'/1`.
    ///
    /// `'__bp_tagged'(A, V)` — `A` is the value's tag, so the module that
    /// formats it is the tag with any `__v__` segment cut off. It is loaded and
    /// asked for `'__bp_format'/1`; anything that does not answer keeps `~p`.
    ///
    /// `'__bp_render'(D)` turns the description into text: `{text, T}` is a
    /// `Display` implementation's own string, `{variant, N, []}` is written
    /// bare, and everything else is `N(label: value, …)` with the values
    /// through `'__bp_show'/2`.
    fn emitTaggedHelpers(
        self: *Emitter,
        w: *std.Io.Writer,
        tagged_name: []const u8,
        tagged_l: FnLabels,
        render_name: []const u8,
        render_l: FnLabels,
        pair_name: []const u8,
        pair_l: FnLabels,
        show_l: FnLabels,
    ) anyerror!void {
        const format_atom = "'__bp_format'";

        // '__bp_tagged'(A, V).
        const use_a = self.allocLabel();
        const fallback = self.allocLabel();
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, tagged_name, 2, tagged_l.entry);
        try beamEmitter.writeLabel(w, tagged_l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, tagged_name, 2);
        try beamEmitter.writeLabel(w, tagged_l.entry);
        try beamEmitter.writeAllocate(w, 3, 2);
        try beamEmitter.writeInitYregs(w, 3);
        try beamEmitter.writeMoveOp(w, Op.xr(1), Dst.yr(0)); // y0 = V
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(1)); // y1 = M, starting at A
        try beamEmitter.writeMoveOp(w, Op.yr(1), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "atom_to_list" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.str("__v__"), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "string", .function = "split" } }, 0);
        try beamEmitter.writeTest(w, .is_nonempty_list, use_a, &.{Op.xr(0)});
        try beamEmitter.writeGetList(w, Op.xr(0), Dst.xr(1), Dst.xr(2));
        try beamEmitter.writeMoveOp(w, Op.xr(1), Dst.yr(2));
        try beamEmitter.writeTest(w, .is_nonempty_list, use_a, &.{Op.xr(2)});
        try beamEmitter.writeMoveOp(w, Op.yr(2), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "erlang", .function = "list_to_atom" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(1));
        try beamEmitter.writeLabel(w, use_a);
        try beamEmitter.writeMoveOp(w, Op.yr(1), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 1, .{ .ext = .{ .module = "code", .function = "ensure_loaded" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.yr(1), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.atom(format_atom), Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.int(1), Dst.xr(2));
        try beamEmitter.writeCall(w, .normal, 3, .{ .ext = .{ .module = "erlang", .function = "function_exported" } }, 0);
        try beamEmitter.writeTest(w, .is_eq_exact, fallback, &.{ Op.xr(0), Op.atom("true") });
        try beamEmitter.writeTestHeap(w, 2, 1);
        try beamEmitter.writePutList(w, Op.yr(0), Op.nil, Dst.xr(2));
        try beamEmitter.writeMoveOp(w, Op.yr(1), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.atom(format_atom), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 3, .{ .ext = .{ .module = "erlang", .function = "apply" } }, 0);
        try beamEmitter.writeCall(w, .last, 1, .{ .local = render_l.entry }, 3);
        try beamEmitter.writeLabel(w, fallback);
        try beamEmitter.writeTestHeap(w, 2, 1);
        try beamEmitter.writePutList(w, Op.yr(0), Op.nil, Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.str("~p"), Dst.xr(0));
        try beamEmitter.writeCall(w, .last, 2, .{ .ext = .{ .module = "io_lib", .function = "format" } }, 3);

        // '__bp_render'(D).
        const not_text = self.allocLabel();
        const has_fields = self.allocLabel();
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, render_name, 1, render_l.entry);
        try beamEmitter.writeLabel(w, render_l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, render_name, 1);
        try beamEmitter.writeLabel(w, render_l.entry);
        try beamEmitter.writeAllocate(w, 2, 1);
        try beamEmitter.writeInitYregs(w, 2);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(0));
        try beamEmitter.writeMoveOp(w, Op.int(1), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
        try beamEmitter.writeTest(w, .is_eq_exact, not_text, &.{ Op.xr(0), Op.atom("text") });
        try beamEmitter.writeMoveOp(w, Op.int(2), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .last, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 2);
        try beamEmitter.writeLabel(w, not_text);
        try beamEmitter.writeMoveOp(w, Op.int(3), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(1));
        try beamEmitter.writeTest(w, .is_eq_exact, has_fields, &.{ Op.xr(0), Op.nil });
        try beamEmitter.writeMoveOp(w, Op.int(2), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .last, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 2);
        try beamEmitter.writeLabel(w, has_fields);
        try beamEmitter.writeTestHeapAlloc(w, 0, 1, 0);
        try beamEmitter.writeMakeFun3(w, pair_l.entry, &.{});
        try beamEmitter.writeMoveOp(w, Op.yr(1), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "map" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.str(", "), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "join" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(1));
        try beamEmitter.writeMoveOp(w, Op.int(2), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
        try beamEmitter.writeTestHeap(w, 8, 1);
        try beamEmitter.writePutList(w, Op.int(')'), Op.nil, Dst.xr(1));
        try beamEmitter.writePutList(w, Op.yr(1), Op.xr(1), Dst.xr(1));
        try beamEmitter.writePutList(w, Op.int('('), Op.xr(1), Dst.xr(1));
        try beamEmitter.writePutList(w, Op.xr(0), Op.xr(1), Dst.xr(0));
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);

        // '-bp_render_pair-'({K, Val}) -> [K, ": ", '__bp_show'(Val, false)].
        try beamEmitter.writeBlankLine(w);
        try beamEmitter.writeFunctionHeader(w, pair_name, 1, pair_l.entry);
        try beamEmitter.writeLabel(w, pair_l.func_info);
        try beamEmitter.writeLine(w, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(w, self.module_name, pair_name, 1);
        try beamEmitter.writeLabel(w, pair_l.entry);
        try beamEmitter.writeAllocate(w, 2, 1);
        try beamEmitter.writeInitYregs(w, 2);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(0));
        try beamEmitter.writeMoveOp(w, Op.int(2), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.atom("false"), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .local = show_l.entry }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.yr(1));
        try beamEmitter.writeMoveOp(w, Op.int(1), Dst.xr(0));
        try beamEmitter.writeMoveOp(w, Op.yr(0), Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "erlang", .function = "element" } }, 0);
        try beamEmitter.writeTestHeap(w, 6, 1);
        try beamEmitter.writePutList(w, Op.yr(1), Op.nil, Dst.xr(1));
        try beamEmitter.writePutList(w, Op.str(": "), Op.xr(1), Dst.xr(1));
        try beamEmitter.writePutList(w, Op.xr(0), Op.xr(1), Dst.xr(0));
        try beamEmitter.writeDeallocate(w, 2);
        try beamEmitter.writeReturn(w);
    }

    /// `lists:join(<<", ">>, lists:map(fun '-bp_show_elem-'/1, Items))` — the
    /// separated element text both compound arms of `'__bp_show'/2` build. The
    /// items come from `src` (a stack slot, since `lists:map` frees the
    /// x-registers); the result lands in `{x, 0}`.
    fn emitShowJoin(self: *Emitter, w: *std.Io.Writer, elem_entry: u32, src: Op) anyerror!void {
        _ = self;
        try beamEmitter.writeTestHeapAlloc(w, 0, 1, 0);
        try beamEmitter.writeMakeFun3(w, elem_entry, &.{});
        try beamEmitter.writeMoveOp(w, src, Dst.xr(1));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "map" } }, 0);
        try beamEmitter.writeMoveOp(w, Op.xr(0), Dst.xr(1));
        try beamEmitter.writeMoveOp(w, Op.str(", "), Dst.xr(0));
        try beamEmitter.writeCall(w, .normal, 2, .{ .ext = .{ .module = "lists", .function = "join" } }, 0);
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

    // ── operand staging ──────────────────────────────────────────────────────
    //
    // A `call` / `call_ext` / `call_fun` frees every x-register, so an operand
    // staged in `{x, k}` dies as soon as a LATER operand's lowering calls
    // anything (`#(f(a), p._1)`, `g(h(1), h(2))`). `stageOperands` evaluates a
    // list of operands left to right and hands back where each value can be
    // read: a simple term in place (a literal or a stack slot), otherwise an
    // x-register — or, when some later operand may call, a stack slot. The
    // last non-simple operand stays in `{x, 0}` (nothing is lowered after it).
    // `countStaging` reserves the stack slots ahead of emission with the same
    // `exprMayCall` predicate.

    const max_staged = 24;

    /// Where the staged operands of one construction or call can be read.
    const Staged = struct {
        ops: [max_staged]Op = undefined,
        len: usize = 0,
        /// One past the highest x-register holding a staged value.
        x_top: u32 = 0,

        fn slice(s: *const Staged) []const Op {
            return s.ops[0..s.len];
        }
    };

    /// True when evaluating `e` may emit a call (freeing the x-file). Purely
    /// syntactic plus the module tables, so `countLocalsInExpr` and the
    /// emission agree; `strings` is the string-local set of the pass asking.
    fn exprMayCall(self: *const Emitter, strings: *const std.StringHashMap(void), e: ast.Expr) bool {
        return switch (e) {
            .literal => false,
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.top_vals.contains(n) or self.crossOwnerOf(n, .val) != null,
                .dotIdent => false,
                .identAccess => |ia| blk: {
                    if (self.exprMayCall(strings, ia.receiver.*)) break :blk true;
                    if (tupleIndexMember(ia.member) != null) break :blk true;
                    if (self.instanceLowering(id.loc, ia.receiver.*)) |il| {
                        if (il == .prim and il.prim == .string) break :blk true;
                    }
                    break :blk false;
                },
            },
            .binaryOp => |bin| (bin.op == .add and (self.isStringExpr(strings, e) or self.addIsDynamic(strings, e))) or
                self.exprMayCall(strings, bin.lhs.*) or self.exprMayCall(strings, bin.rhs.*),
            .unaryOp => |un| self.exprMayCall(strings, un.expr.*),
            .function => false,
            .collection => |col| switch (col.kind) {
                .arrayLit => |al| blk: {
                    for (al.elems) |el| if (self.exprMayCall(strings, el)) break :blk true;
                    if (al.spreadExpr) |se| break :blk self.exprMayCall(strings, se.*);
                    break :blk false;
                },
                .tupleLit => |tl| blk: {
                    for (tl.elems) |el| if (self.exprMayCall(strings, el)) break :blk true;
                    break :blk false;
                },
                .behaviorLit => |il| blk: {
                    for (il.fields) |f| if (self.exprMayCall(strings, f.value.*)) break :blk true;
                    break :blk false;
                },
                .grouped => |g| self.exprMayCall(strings, g.*),
                .case, .range => true,
            },
            else => true,
        };
    }

    /// Stack slots `stageOperands` may take for `exprs`: all of them when an
    /// operand after the first may call. An over-count only widens the frame.
    fn stagingSlots(self: *const Emitter, strings: *const std.StringHashMap(void), exprs: []const ast.Expr) u32 {
        if (exprs.len < 2) return 0;
        for (exprs[1..]) |e| {
            if (self.exprMayCall(strings, e)) return @intCast(exprs.len);
        }
        return 0;
    }

    /// Evaluate `exprs` (then the `lambdas`, which never call) left to right.
    /// The staged values are read back through the returned operands.
    fn stageOperands(self: *Emitter, exprs: []const ast.Expr, lambdas: anytype) anyerror!Staged {
        var st: Staged = .{};
        if (exprs.len + lambdas.len > max_staged) return error.TooManyOperands;
        // A value that is neither simple nor last must survive the operands
        // after it: on the stack when one of them may call.
        var last_complex: ?usize = null;
        for (exprs, 0..) |e, i| {
            if (self.simpleTerm(e) == null) last_complex = i;
        }
        var on_stack = false;
        for (exprs, 0..) |e, i| {
            if (self.simpleTerm(e) != null) continue;
            if (last_complex == i and lambdas.len == 0) continue;
            for (exprs[i + 1 ..]) |later| {
                if (self.exprMayCall(&self.string_locals, later)) on_stack = true;
            }
        }
        const saved_live = self.min_live;
        defer self.min_live = saved_live;
        var next_x = self.scratchBase();
        for (exprs, 0..) |e, i| {
            if (self.simpleTerm(e)) |t| {
                st.ops[i] = t;
                continue;
            }
            try self.lowerExprIntoX0(e);
            if (last_complex == i and lambdas.len == 0) {
                st.ops[i] = Op.xr(0);
                st.x_top = @max(st.x_top, 1);
            } else if (on_stack) {
                const y = self.next_y;
                self.next_y += 1;
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y));
                st.ops[i] = Op.yr(y);
            } else {
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(next_x));
                st.ops[i] = Op.xr(next_x);
                next_x += 1;
                st.x_top = next_x;
                _ = self.raiseLive(next_x);
            }
        }
        for (lambdas, 0..) |lam, j| {
            try self.lowerLambda(lam, self.min_live);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(next_x));
            st.ops[exprs.len + j] = Op.xr(next_x);
            next_x += 1;
            st.x_top = next_x;
            _ = self.raiseLive(next_x);
        }
        st.len = exprs.len + lambdas.len;
        return st;
    }

    /// Move `srcs[i]` into `{x, dsts[i]}` for every `i` as one parallel move:
    /// a move is emitted only once no pending move still reads its target, and
    /// a cycle is broken through a register above every source and target.
    fn emitParallelMove(self: *Emitter, srcs: []const Op, dsts: []const u32) anyerror!void {
        var pending_src: [max_staged]Op = undefined;
        var pending_dst: [max_staged]u32 = undefined;
        var n: usize = 0;
        var spare: u32 = 0;
        for (srcs, dsts) |s, d| {
            spare = @max(spare, d + 1);
            if (s == .x) spare = @max(spare, s.x + 1);
            if (s == .x and s.x == d) continue;
            pending_src[n] = s;
            pending_dst[n] = d;
            n += 1;
        }
        while (n > 0) {
            var progressed = false;
            var i: usize = 0;
            while (i < n) {
                const d = pending_dst[i];
                var blocked = false;
                for (pending_src[0..n], 0..) |s, k| {
                    if (k != i and s == .x and s.x == d) blocked = true;
                }
                if (blocked) {
                    i += 1;
                    continue;
                }
                try beamEmitter.writeMoveOp(self.out, pending_src[i], Dst.xr(d));
                pending_src[i] = pending_src[n - 1];
                pending_dst[i] = pending_dst[n - 1];
                n -= 1;
                progressed = true;
            }
            if (!progressed) {
                // Every remaining move is part of a cycle: park one source.
                try beamEmitter.writeMoveOp(self.out, pending_src[0], Dst.xr(spare));
                pending_src[0] = Op.xr(spare);
                spare += 1;
            }
        }
    }

    /// Stage `[recv] ++ args ++ trailing` of a call, returning the operands.
    fn stageCall(self: *Emitter, recv: ?*const ast.Expr, args: anytype, trailing: anytype) anyerror!Staged {
        var exprs: [max_staged]ast.Expr = undefined;
        var n: usize = 0;
        if (recv) |r| {
            exprs[n] = r.*;
            n += 1;
        }
        if (n + args.len > max_staged) return error.TooManyOperands;
        for (args) |arg| {
            exprs[n] = arg.value.*;
            n += 1;
        }
        return self.stageOperands(exprs[0..n], trailing);
    }

    /// Place staged operands into `{x, 0}..{x, len-1}`.
    fn placeStaged(self: *Emitter, st: *const Staged) anyerror!void {
        var dsts: [max_staged]u32 = undefined;
        for (0..st.len) |i| dsts[i] = @intCast(i);
        try self.emitParallelMove(st.slice(), dsts[0..st.len]);
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
        const st = try self.stageCall(null, args, trailing);
        try self.placeStaged(&st);
    }

    /// Build an Erlang list from an array literal. Elements are consed
    /// right-to-left via `{put_list, Elem, Tail, {x, 0}}`.
    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        try self.lowerListOf(al.elems, if (al.spreadExpr) |se| se.* else null);
    }

    /// Build the list `[elems… | tail]` (`tail` defaults to `[]`) into `{x, 0}`.
    /// Takes one stack slot when `elems` is non-empty (`countLocalsInExpr`).
    fn lowerListOf(self: *Emitter, elems: []const ast.Expr, tail: ?ast.Expr) anyerror!void {
        const al = .{ .elems = elems };
        if (tail) |t| {
            try self.lowerExprIntoX0(t);
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
            // The tail accumulator is parked on the *stack*, not in an
            // x-register: an element that calls a function
            // (`[node(), node()]`) frees the whole x-file, and the half-built
            // list would be gone by the time `put_list` runs. `countLocalsInExpr`
            // reserves this slot.
            const acc_y = self.next_y;
            self.next_y += 1;
            var i: usize = al.elems.len;
            while (i > 0) {
                i -= 1;
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(acc_y));
                try self.lowerExprIntoX0(al.elems[i]);
                // `{x, 0}` holds the element and `{x, scratch}` the reloaded
                // tail — both must survive the cons allocation.
                try beamEmitter.writeMoveOp(self.out, Op.yr(acc_y), Dst.xr(scratch));
                try beamEmitter.writeTestHeap(self.out, 2, scratch + 1);
                try beamEmitter.writePutList(self.out, Op.xr(0), Op.xr(scratch), Dst.xr(0));
            }
        }
    }

    /// Build an Erlang tuple from a tuple literal via `{put_tuple2, ...}`.
    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        const n = tl.elems.len;
        const st = try self.stageOperands(tl.elems, &[_]ast.TrailingLambda{});
        try beamEmitter.writeTestHeap(self.out, n + 1, @max(self.min_live, st.x_top));
        try beamEmitter.writePutTuple2(self.out, Dst.xr(0), st.slice());
    }

    /// Bookkeeping for a guarded case arm: the label that restores the subject
    /// and falls through to the next arm, plus the scratch x-register holding
    /// the saved subject.
    const GuardCtx = struct { restore: u32, subj: Op };

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
        const restore = self.allocLabel();
        // A guard that calls frees the x-file, so the subject waits on the stack.
        if (self.exprMayCall(&self.string_locals, g)) {
            const y = self.next_y;
            self.next_y += 1;
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y));
            if (!try self.lowerComparisonAsTest(g, restore)) {
                try self.lowerExprIntoX0(g);
                try beamEmitter.writeTest(self.out, .is_eq, restore, &.{ Op.xr(0), Op.atom("true") });
            }
            return GuardCtx{ .restore = restore, .subj = Op.yr(y) };
        }
        const subj = self.scratchBase();
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(subj));
        const saved_live = self.raiseLive(subj + 1);
        const lowered = try self.lowerComparisonAsTest(g, restore);
        if (!lowered) {
            try self.lowerExprIntoX0(g);
            try beamEmitter.writeTest(self.out, .is_eq, restore, &.{ Op.xr(0), Op.atom("true") });
        }
        self.min_live = saved_live;
        return GuardCtx{ .restore = restore, .subj = Op.xr(subj) };
    }

    /// Counterpart to `emitGuardPre`: emit the restore block. It must be placed
    /// after the arm body's `{jump, end}` and immediately before this arm's
    /// fail label, so the failing-guard path restores the subject and flows
    /// into the next arm's pattern test.
    fn emitGuardPost(self: *Emitter, ctx: ?GuardCtx) !void {
        const c = ctx orelse return;
        try beamEmitter.writeLabel(self.out, c.restore);
        try beamEmitter.writeMoveOp(self.out, c.subj, Dst.xr(0));
    }

    /// The statements of a `case` arm written as a block. Decision 8 §5 spells
    /// an arm `Pattern { body }`, and the parser reads that block as a lambda
    /// (`ast.Expr.function`, `.lambda` syntax, at most one parameter), so
    /// lowering it as an expression built a closure with `make_fun3` and threw
    /// it away — every statement in the arm was dead and the arm's value was a
    /// `#Fun<…>` (01's defect 2, measured 2026-09-18: a `case` printing from its
    /// arms printed nothing, and `break r * r` reached `integer_to_binary/1` as
    /// a fun). Null for an arrow-form arm, whose body is a plain expression.
    fn armBlock(body: ast.Expr) ?struct { params: []const []const u8, stmts: []const ast.Stmt } {
        const f = switch (body) {
            .function => |fx| fx,
            else => return null,
        };
        if (f.kind.syntax != .lambda) return null;
        if (f.kind.params.len > 1) return null;
        return .{ .params = f.kind.params, .stmts = f.kind.body };
    }

    /// The value of a `case` arm. A block arm runs in this frame (see
    /// `armBlock`): its value is the last statement, unless a `break` carries
    /// one, which wins. Returns true when the body already left the function
    /// (an explicit `return`/`throw`), so the caller skips the dead
    /// `{jump, end}`.
    fn lowerArmBody(self: *Emitter, body: ast.Expr) anyerror!bool {
        const blk = armBlock(body) orelse {
            try self.lowerExprIntoX0(body);
            return false;
        };
        const stmts = blk.stmts;
        for (stmts, 0..) |stmt, i| {
            if (stmt.expr == .jump and stmt.expr.jump.kind == .@"break") {
                if (stmt.expr.jump.kind.@"break".value) |v| {
                    try self.lowerExprIntoX0(v.*);
                } else {
                    try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
                }
                return false;
            }
            if (i + 1 == stmts.len and armValueTail(stmt.expr)) {
                try self.lowerExprIntoX0(stmt.expr);
                return false;
            }
            try self.emitStmt(stmt);
        }
        if (bodyExits(stmts)) return true;
        try beamEmitter.writeMoveOp(self.out, Op.atom("ok"), Dst.xr(0));
        return false;
    }

    /// Bind a one-parameter block arm's name to the subject (01's defect 3).
    /// `subj_y` is the slot `lowerCase` parked the subject in; the name is an
    /// alias for it, so no move is emitted and every arm that asks shares it.
    fn bindArmParam(self: *Emitter, arm: anytype, subj_y: ?u32) !void {
        const blk = armBlock(arm.body) orelse return;
        if (blk.params.len != 1) return;
        const y = subj_y orelse return;
        try self.reg_map.put(blk.params[0], .{ .y = y });
    }

    /// One arm's tail: bind its parameter, check its guard, lower its value and
    /// jump to the end of the `case`.
    fn emitArmTail(self: *Emitter, arm: anytype, subj_y: ?u32, end_label: u32) anyerror!void {
        try self.bindArmParam(arm, subj_y);
        const guard_ctx = try self.emitGuardPre(arm.guard);
        const exited = try self.lowerArmBody(arm.body);
        if (!exited) try beamEmitter.writeJump(self.out, end_label);
        try self.emitGuardPost(guard_ctx);
    }

    /// Lower a `case expr { pat -> body; ... }` into a chain of BEAM test
    /// instructions with fall-through labels. Optional `pat if guard -> body`
    /// guards are honoured via `emitGuardPre`/`emitGuardPost`.
    fn lowerCase(self: *Emitter, subjects: anytype, arms: anytype) anyerror!void {
        if (subjects.len == 0) {
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
            return;
        }
        // The subject's enum steers an unqualified arm (`.Color`), which enum
        // SECTIONS make an ordinary collision (`Token.Color` and
        // `Token.Border.Color` in one file). Parity with `erlang.zig`.
        const saved_hint = self.enum_hint;
        defer self.enum_hint = saved_hint;
        if (subjects.len == 1) {
            if (self.enumOfSubject(subjects[0])) |en| self.enum_hint = en;
        }
        try self.lowerExprIntoX0(subjects[0]);

        // One stack slot holds the subject for every `{ n -> … }` arm that
        // binds it; allocated only when some arm asks, so a `case` without a
        // binder arm keeps the assembly it had.
        var subj_y: ?u32 = null;
        for (arms) |arm| {
            const blk = armBlock(arm.body) orelse continue;
            if (blk.params.len != 1) continue;
            subj_y = self.next_y;
            self.next_y += 1;
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(subj_y.?));
            break;
        }

        const end_label = self.allocLabel();
        for (arms) |arm| {
            switch (arm.pattern) {
                .numberLit => |n| {
                    const next = self.allocLabel();
                    try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(0), Op.num(n) });
                    try self.emitArmTail(arm, subj_y, end_label);
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
                    try self.emitArmTail(arm, subj_y, end_label);
                    try beamEmitter.writeLabel(self.out, next);
                    try beamEmitter.writeMoveOp(self.out, Op.xr(subj), Dst.xr(0));
                },
                .ident => |written| {
                    const name = bareVariantName(written);
                    // §5.1 P8 — a written path (`Maybe.None`, `.None`) is a
                    // variant even when this module never declared the enum.
                    if (isVariantPath(written) or self.enum_variants.contains(name)) {
                        // A nullary enum variant (`Lt ->`) is an atom to test
                        // against, not a name to bind. Without the test the
                        // first arm swallowed every subject
                        // (`HttpMethod_name('Post')` returned `<<"GET">>`).
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(self.variantTag(written), &vbuf);
                        const next = self.allocLabel();
                        try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(0), Op.atom(vatom) });
                        try self.emitArmTail(arm, subj_y, end_label);
                        try beamEmitter.writeLabel(self.out, next);
                    } else if (self.record_fields.contains(name) or self.enum_variant_names.contains(name)) {
                        // Decision 8 §3.3 — an arm naming a `type` is chosen by
                        // the VALUE's own type, which half 3 put in the value.
                        // Emitted as the bare binder it was, the first arm of a
                        // `case` over `Person | Vec` swallowed every subject.
                        const next = self.allocLabel();
                        const testable = try self.emitTypeTestBranch(.{ .named = name }, next);
                        if (!testable) try beamEmitter.writeJump(self.out, next);
                        try self.emitArmTail(arm, subj_y, end_label);
                        try beamEmitter.writeLabel(self.out, next);
                    } else if (std.mem.eql(u8, name, "_")) {
                        try self.emitArmTail(arm, subj_y, end_label);
                    } else {
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(name, .{ .y = y_idx });
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                        try self.emitArmTail(arm, subj_y, end_label);
                    }
                },
                .wildcard => {
                    try self.emitArmTail(arm, subj_y, end_label);
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
                    try self.emitArmTail(arm, subj_y, end_label);
                    try beamEmitter.writeLabel(self.out, next);
                },
                .variant => |v| switch (v.payload) {
                    .fields => |fields| {
                        const next = self.allocLabel();
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(self.variantTag(v.name), &vbuf);
                        try beamEmitter.writeTest(self.out, .is_tagged_tuple, next, &.{ Op.xr(0), .{ .untagged = @intCast(fields.len + 1) }, Op.atom(vatom) });
                        for (fields, 0..) |bname, i| {
                            try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), i + 1, Dst.xr(1));
                            const y_idx = self.next_y;
                            self.next_y += 1;
                            try self.reg_map.put(bname, .{ .y = y_idx });
                            try beamEmitter.writeMoveOp(self.out, Op.xr(1), Dst.yr(y_idx));
                        }
                        try self.emitArmTail(arm, subj_y, end_label);
                        try beamEmitter.writeLabel(self.out, next);
                    },
                    .binding => |binding| {
                        const next = self.allocLabel();
                        var vbuf: [256]u8 = undefined;
                        const vatom = try atomName(self.variantTag(v.name), &vbuf);
                        try beamEmitter.writeTest(self.out, .is_tuple, next, &.{Op.xr(0)});
                        try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 0, Dst.xr(1));
                        try beamEmitter.writeTest(self.out, .is_eq, next, &.{ Op.xr(1), Op.atom(vatom) });
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(binding, .{ .y = y_idx });
                        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
                        try self.emitArmTail(arm, subj_y, end_label);
                        try beamEmitter.writeLabel(self.out, next);
                    },
                    .literals => {
                        // Literal-argument variants are not lowered specially yet.
                        try self.emitArmTail(arm, subj_y, end_label);
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
                    try self.emitArmTail(arm, subj_y, end_label);
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
                    try self.emitArmTail(arm, subj_y, end_label);
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
    fn emitMakeFun(self: *Emitter, entry_label: u32, live: u32, env: []const Op) !void {
        try beamEmitter.writeTestHeapAlloc(self.out, env.len, 1, @max(live, self.min_live));
        try beamEmitter.writeMakeFun3(self.out, entry_label, env);
    }

    /// The closure environment of a lambda/loop body: every name it reads that
    /// the enclosing frame binds (and its own `params` do not shadow), in first-
    /// use order. `names` receives the names, `ops` the enclosing frame's
    /// operand for each — the `make_fun3` free-variable list. The fun's function
    /// takes them after its own parameters, so the body binds them like params.
    fn closureEnv(
        self: *Emitter,
        body: []const ast.Stmt,
        params: []const []const u8,
        names: *std.ArrayListUnmanaged([]const u8),
        ops: *std.ArrayListUnmanaged(Op),
    ) !void {
        var seen: NameCollector = .{ .alloc = self.alloc };
        defer seen.set.deinit(self.alloc);
        try collectNamesInStmts(&seen, body);
        for (seen.set.keys()) |n| {
            var shadowed = false;
            for (params) |p| {
                if (std.mem.eql(u8, p, n)) shadowed = true;
            }
            if (shadowed) continue;
            const reg = self.reg_map.get(n) orelse continue;
            try names.append(self.alloc, n);
            try ops.append(self.alloc, reg.operand());
        }
    }

    /// Lower a lambda `{ params -> body }` into a deferred BEAM function and
    /// emit the closure value at the call site (`emitMakeFun`). Result in
    /// `{x, 0}`. `live` is the number of x-registers the caller needs preserved
    /// across the closure's `test_heap` (args already materialised + params).
    fn lowerLambda(self: *Emitter, lam: anytype, live: u32) anyerror!void {
        const idx = self.lambda_count;
        self.lambda_count += 1;

        // Free variables of the body travel in the fun's environment and arrive
        // as extra parameters after the lambda's own.
        var env_names: std.ArrayListUnmanaged([]const u8) = .empty;
        defer env_names.deinit(self.alloc);
        var env_ops: std.ArrayListUnmanaged(Op) = .empty;
        defer env_ops.deinit(self.alloc);
        try self.closureEnv(lam.body, lam.params, &env_names, &env_ops);
        var all_params: std.ArrayListUnmanaged([]const u8) = .empty;
        defer all_params.deinit(self.alloc);
        try all_params.appendSlice(self.alloc, lam.params);
        try all_params.appendSlice(self.alloc, env_names.items);
        const arity: u32 = @intCast(all_params.items.len);

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
        const saved_group = self.fold_group;
        self.fold_group = null;
        defer self.fold_group = saved_group;

        self.next_y = 0;
        self.cur_arity = arity;
        self.num_y = arity + self.precountLocals(lam.body);
        try self.bindParams(all_params.items);

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

        try self.emitMakeFun(labels.entry, live, env_ops.items);
    }

    /// Lower `try expr catch handler` → BEAM try/catch block.
    /// `try expr catch handler` → match the Result tuple `{ok, V}` / `{error, E}`
    /// with `is_tagged_tuple` (never BEAM try/catch). Ok unwraps element 1; Error
    /// runs the handler.
    fn lowerTryCatch(self: *Emitter, tc: anytype) anyerror!void {
        // The subject runs inside a real catch section: a raise from it
        // (`@todo()` in a `#[@result]` fn) reaches the handler too, like an
        // `{error, E}` result does.
        const tag = self.next_y;
        self.next_y += 1;
        const catch_label = self.allocLabel();
        const err_label = self.allocLabel();
        const end_label = self.allocLabel();

        try beamEmitter.writeTry(self.out, tag, catch_label);
        try self.lowerExprIntoX0(tc.expr.*);
        try beamEmitter.writeTryEnd(self.out, tag);

        // {ok, V}: fall through and unwrap; otherwise jump to the Error branch.
        try beamEmitter.writeTest(self.out, .is_tagged_tuple, err_label, &.{ Op.xr(0), .{ .untagged = 2 }, Op.atom("ok") });
        try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), 1, Dst.xr(0));
        try beamEmitter.writeJump(self.out, end_label);

        try beamEmitter.writeLabel(self.out, catch_label);
        try beamEmitter.writeTryCase(self.out, tag);
        try beamEmitter.writeLabel(self.out, err_label);
        try self.lowerExprIntoX0(tc.handler.*);
        try beamEmitter.writeLabel(self.out, end_label);
    }

    /// Lower `start..end` → `lists:seq(Start, End)`. An open-ended range
    /// (`start..`) mirrors the Erlang backend and passes the atom `infinity`
    /// as the upper bound. Result list lands in `{x, 0}`.
    fn lowerRange(self: *Emitter, r: anytype) anyerror!void {
        if (r.end) |end| {
            // `a..b` is half-open `[a, b)` (parity with wasm/erlang/`Array.range`),
            // but `lists:seq/2` is inclusive — so the upper bound is `b - 1`.
            const st = try self.stageOperands(&.{ r.start.*, end.* }, &[_]ast.TrailingLambda{});
            const live = @max(self.min_live, st.x_top);
            const spare = @max(live, 1);
            try beamEmitter.writeGcBif(self.out, .sub, live, &.{ st.ops[1], Op.int(1) }, Dst.xr(spare));
            try self.emitParallelMove(&.{ st.ops[0], Op.xr(spare) }, &.{ 0, 1 });
        } else {
            try self.lowerExprIntoX0(r.start.*);
            try beamEmitter.writeMoveOp(self.out, Op.atom("infinity"), Dst.xr(1));
        }
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = "seq" } }, 0);
    }

    /// Lower `lhs |> rhs`: evaluate lhs, then call rhs as function with result.
    fn lowerPipeline(self: *Emitter, pl: anytype) anyerror!void {
        const rhs_is_call = pl.rhs.* == .call and pl.rhs.*.call.kind == .call;
        if (!rhs_is_call) try self.lowerExprIntoX0(pl.lhs.*);
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
                    // `lhs |> f(a, b)` → `f(lhs, a, b)`: the piped value is the
                    // first staged operand.
                    const st = try self.stageCall(pl.lhs, cc.args, &[_]ast.TrailingLambda{});
                    try self.placeStaged(&st);
                    const total = cc.args.len + 1;
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

    /// The loop-comprehension shape `loop (xs) { x -> if (c) { …; break v; }; }`
    /// — a single else-less `if` whose branch ends in `break <value>` — which
    /// keeps only the elements the branch fires for (`lists:filtermap/2`).
    /// Returns the `if`, or null.
    fn filterMapIf(lp: anytype) ?@TypeOf(lp.body[0].expr.branch.kind.if_) {
        if (lp.body.len != 1 or lp.body[0].expr != .branch) return null;
        const br = lp.body[0].expr.branch;
        if (br.kind != .if_) return null;
        const iff = br.kind.if_;
        if (iff.else_ != null or iff.then_.len == 0) return null;
        const last = iff.then_[iff.then_.len - 1].expr;
        if (last != .jump or last.jump.kind != .@"break") return null;
        if (last.jump.kind.@"break".value == null) return null;
        return iff;
    }

    /// The `lists:filtermap/2` fun body: `{true, Value}` when the branch fires,
    /// `false` otherwise.
    fn emitFilterMapBody(self: *Emitter, iff: anytype) anyerror!void {
        const else_l = self.allocLabel();
        try self.emitIfTest(iff, else_l);
        for (iff.then_[0 .. iff.then_.len - 1]) |stmt| try self.emitStmt(stmt);
        try self.lowerExprIntoX0(iff.then_[iff.then_.len - 1].expr.jump.kind.@"break".value.?.*);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
        try beamEmitter.writeTestHeap(self.out, 3, 2);
        try beamEmitter.writePutTuple2(self.out, Dst.xr(0), &.{ Op.atom("true"), Op.xr(1) });
        try self.emitReturn();
        try beamEmitter.writeLabel(self.out, else_l);
        try beamEmitter.writeMoveOp(self.out, Op.atom("false"), Dst.xr(0));
        try self.emitReturn();
    }

    // ── mutation threading ───────────────────────────────────────────────────
    //
    // A local lives in a stack slot of its function's frame, so an `if` arm or
    // a plain statement reassigns it in place. A `loop`/`forEach` body is a fun
    // with its own frame: a reassignment there wrote the fun's copy and was
    // lost. Such a statement lowers to `lists:foldl/3` whose accumulator is the
    // reassigned names (one value, or a tuple of them), unpacked back into the
    // caller's slots afterwards.

    /// The local slot `out.push(x)` rebinds — a local of this frame whose
    /// receiver lowering is an Array — or null.
    fn receiverMutation(self: *const Emitter, e: ast.Expr) ?Reg {
        if (e != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        if (cc.is_builtin or !std.mem.eql(u8, cc.callee, "push")) return null;
        if (cc.args.len + cc.trailing.len != 1) return null;
        const recv = cc.receiver orelse return null;
        const name = switch (recv.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| n,
                else => return null,
            },
            else => return null,
        };
        const reg = self.reg_map.get(name) orelse return null;
        const il = self.instanceLowering(e.call.loc, recv.*) orelse return null;
        return if (il == .prim and il.prim == .array) reg else null;
    }

    const ForEachLambda = struct { recv: *const ast.Expr, param: []const u8, body: []const ast.Stmt };

    /// `xs.forEach({ x -> … })` / `xs.forEach { x -> … }` on an Array, or null.
    fn forEachLambda(self: *const Emitter, e: ast.Expr) ?ForEachLambda {
        if (e != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        if (cc.is_builtin or !std.mem.eql(u8, cc.callee, "forEach")) return null;
        const recv = cc.receiver orelse return null;
        const il = self.instanceLowering(e.call.loc, recv.*) orelse return null;
        if (il != .prim or il.prim != .array) return null;
        if (cc.args.len == 1 and cc.trailing.len == 0) {
            const f = switch (cc.args[0].value.*) {
                .function => |f| f,
                else => return null,
            };
            if (f.kind.params.len != 1) return null;
            return .{ .recv = recv, .param = f.kind.params[0], .body = f.kind.body };
        }
        if (cc.args.len == 0 and cc.trailing.len == 1 and cc.trailing[0].params.len == 1) {
            return .{ .recv = recv, .param = cc.trailing[0].params[0], .body = cc.trailing[0].body };
        }
        return null;
    }

    /// Append (once each) the names of this frame that `stmts` reassigns —
    /// through `=`/`+=`, `push`, or a nested `if`/`loop`/`forEach` body.
    fn collectMutations(self: *const Emitter, stmts: []const ast.Stmt, shadowed: []const []const u8, out: *std.ArrayListUnmanaged([]const u8)) anyerror!void {
        for (stmts) |s| switch (s.expr) {
            .binding => |b| switch (b.kind) {
                .assign => |a| switch (a.target) {
                    .name => |n| try self.addMutation(n, shadowed, out),
                    else => {},
                },
                else => {},
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    try self.collectMutations(i.then_, shadowed, out);
                    if (i.else_) |els| try self.collectMutations(els, shadowed, out);
                },
                else => {},
            },
            .loop => |lp| try self.collectMutations(lp.body, lp.params, out),
            .call => {
                if (self.closureMutation(s.expr)) |cm| {
                    for (cm.names) |n| try self.addMutation(n, shadowed, out);
                } else if (self.receiverMutation(s.expr) != null) {
                    const name = s.expr.call.kind.call.receiver.?.*.identifier.kind.ident;
                    try self.addMutation(name, shadowed, out);
                } else if (self.forEachLambda(s.expr)) |each| {
                    try self.collectMutations(each.body, &.{each.param}, out);
                }
            },
            else => {},
        };
    }

    fn addMutation(self: *const Emitter, name: []const u8, shadowed: []const []const u8, out: *std.ArrayListUnmanaged([]const u8)) !void {
        if (!self.reg_map.contains(name)) return;
        for (shadowed) |sh| if (std.mem.eql(u8, sh, name)) return;
        for (out.items) |o| if (std.mem.eql(u8, o, name)) return;
        try out.append(self.alloc, name);
    }

    /// The group of threaded names as one value in `{x, dest}`: the value
    /// itself, or a tuple of them (`live` x-registers survive its `test_heap`).
    fn emitGroupInto(self: *Emitter, names: []const []const u8, dest: u32, live: u32) anyerror!void {
        if (names.len == 1) {
            try beamEmitter.writeMoveOp(self.out, self.reg_map.get(names[0]).?.operand(), Dst.xr(dest));
            return;
        }
        var elems: [max_staged]Op = undefined;
        for (names, 0..) |n, i| elems[i] = self.reg_map.get(n).?.operand();
        try beamEmitter.writeTestHeap(self.out, names.len + 1, live);
        try beamEmitter.writePutTuple2(self.out, Dst.xr(dest), elems[0..names.len]);
    }

    fn emitGroupIntoX0(self: *Emitter, names: []const []const u8) anyerror!void {
        try self.emitGroupInto(names, 0, 0);
    }

    /// Store the group a threading fun answered (in `{x, 0}`) back into the
    /// slots of `names` in this frame.
    fn unpackGroupFromX0(self: *Emitter, names: []const []const u8) anyerror!void {
        if (names.len == 1) {
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), self.reg_map.get(names[0]).?.dest());
            return;
        }
        for (names, 0..) |n, i| {
            try beamEmitter.writeBif(self.out, "element", 0, &.{ Op.int(i + 1), Op.xr(0) }, Dst.xr(1));
            try beamEmitter.writeMoveOp(self.out, Op.xr(1), self.reg_map.get(n).?.dest());
        }
    }

    /// How a threading fun receives its own arguments: plain parameters, or
    /// the one `{Index, Item}` pair of a `lists:enumerate/2` element, bound to
    /// the two loop names.
    const GroupFunHead = union(enum) {
        params: []const []const u8,
        pair: struct { item: []const u8, index: []const u8 },

        fn names(h: GroupFunHead, buf: *[2][]const u8) []const []const u8 {
            return switch (h) {
                .params => |p| p,
                .pair => |p| blk: {
                    buf.* = .{ p.item, p.index };
                    break :blk buf[0..2];
                },
            };
        }
    };

    /// Emit, into `deferred_lambdas`, the fun `(Head…, Group, Env…)` whose body
    /// runs with `names` bound from `Group` and answers the group — so do its
    /// `break`/`continue`. `env_ops` receives the enclosing frame's operand for
    /// each captured name (the `make_fun3` free-variable list). Returns the
    /// fun's entry label.
    fn emitGroupFun(
        self: *Emitter,
        head: GroupFunHead,
        names: []const []const u8,
        body: []const ast.Stmt,
        loop_body: bool,
        env_ops: *std.ArrayListUnmanaged(Op),
    ) anyerror!u32 {
        const idx = self.lambda_count;
        self.lambda_count += 1;

        var head_buf: [2][]const u8 = undefined;
        const head_names = head.names(&head_buf);
        var shadow: std.ArrayListUnmanaged([]const u8) = .empty;
        defer shadow.deinit(self.alloc);
        try shadow.appendSlice(self.alloc, head_names);
        try shadow.appendSlice(self.alloc, names);
        var env_names: std.ArrayListUnmanaged([]const u8) = .empty;
        defer env_names.deinit(self.alloc);
        try self.closureEnv(body, shadow.items, &env_names, env_ops);

        var all_params: std.ArrayListUnmanaged([]const u8) = .empty;
        defer all_params.deinit(self.alloc);
        switch (head) {
            .params => |p| try all_params.appendSlice(self.alloc, p),
            .pair => try all_params.append(self.alloc, ""),
        }
        const group_y: u32 = @intCast(all_params.items.len);
        try all_params.append(self.alloc, "");
        try all_params.appendSlice(self.alloc, env_names.items);
        const arity: u32 = @intCast(all_params.items.len);

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
        const saved_group = self.fold_group;
        defer {
            self.reg_map.deinit();
            self.reg_map = saved_reg_map;
            self.next_y = saved_y;
            self.num_y = saved_num_y;
            self.cur_arity = saved_arity;
            self.in_loop_lambda = saved_loop_flag;
            self.min_live = saved_min_live;
            self.fold_group = saved_group;
            self.out = saved_out;
        }
        self.min_live = 0;
        self.next_y = 0;
        self.cur_arity = arity;
        const unpack: u32 = if (names.len > 1) @intCast(names.len) else 0;
        const pair_slots: u32 = if (head == .pair) 2 else 0;
        self.num_y = arity + unpack + pair_slots + self.precountLocals(body);
        self.in_loop_lambda = loop_body;
        self.fold_group = names;
        try self.bindParams(all_params.items);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, fun_name, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, fun_name, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(arity);
        try self.emitParamSpill(arity);
        // `y0` holds the `{Index, Item}` pair: `element/2` is a guard BIF, so
        // reading it frees no register.
        if (head == .pair) {
            for ([_]struct { name: []const u8, pos: i64 }{ .{ .name = head.pair.index, .pos = 1 }, .{ .name = head.pair.item, .pos = 2 } }) |b| {
                try beamEmitter.writeBif(self.out, "element", 0, &.{ Op.int(b.pos), Op.yr(0) }, Dst.xr(0));
                const y = self.next_y;
                self.next_y += 1;
                try self.reg_map.put(b.name, .{ .y = y });
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y));
            }
        }
        if (names.len == 1) {
            try self.reg_map.put(names[0], .{ .y = group_y });
        } else {
            for (names, 0..) |n, i| {
                try beamEmitter.writeBif(self.out, "element", 0, &.{ Op.int(i + 1), Op.yr(group_y) }, Dst.xr(0));
                const y = self.next_y;
                self.next_y += 1;
                try self.reg_map.put(n, .{ .y = y });
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y));
            }
        }
        for (body) |stmt| try self.emitStmt(stmt);
        if (!bodyExits(body)) {
            try self.emitGroupIntoX0(names);
            try self.emitReturn();
        }
        try self.deferred_lambdas.append(self.alloc, try lam_buf.toOwnedSlice());
        lam_buf.deinit();
        return labels.entry;
    }

    /// `Group = lists:foldl(fun(Param, Group) -> Body, Group end, Group, Iter)`
    /// for a statement loop over `iter` whose `body` reassigns outer names.
    /// A `.pair` head walks `lists:enumerate(Start, Iter)` (`index_range` gives
    /// the start, 0 without one). Returns false (nothing emitted) when the body
    /// reassigns none.
    fn lowerMutatingFold(self: *Emitter, head: GroupFunHead, body: []const ast.Stmt, iter: ast.Expr, index_range: ?*const ast.Expr) anyerror!bool {
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        defer names.deinit(self.alloc);
        var head_buf: [2][]const u8 = undefined;
        try self.collectMutations(body, head.names(&head_buf), &names);
        if (names.items.len == 0 or names.items.len > max_staged) return false;

        var env_ops: std.ArrayListUnmanaged(Op) = .empty;
        defer env_ops.deinit(self.alloc);
        const entry = try self.emitGroupFun(head, names.items, body, true, &env_ops);

        // lists:foldl(Fun, Group, List)
        if (head == .pair) {
            try self.lowerEnumerateIntoX0(iter, index_range);
        } else {
            try self.lowerExprIntoX0(iter);
        }
        try self.emitGroupInto(names.items, 1, 1);
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(2));
        try self.emitMakeFun(entry, 3, env_ops.items);
        try beamEmitter.writeCall(self.out, .normal, 3, .{ .ext = .{ .module = "lists", .function = "foldl" } }, 0);
        try self.unpackGroupFromX0(names.items);
        return true;
    }

    /// `lists:enumerate(Start, Iter)` into `{x, 0}`: the `{Index, Item}` pairs
    /// of a two-parameter loop. `index_range` is the written `Start..` (null
    /// for `loop (xs) { x, i -> … }`, which counts from 0).
    fn lowerEnumerateIntoX0(self: *Emitter, iter: ast.Expr, index_range: ?*const ast.Expr) anyerror!void {
        const start_expr: ?ast.Expr = if (index_range) |ir|
            (if (ir.* == .collection and ir.collection.kind == .range) ir.collection.kind.range.start.* else null)
        else
            null;
        const simple_start: ?Op = if (start_expr) |se| self.simpleTerm(se) else Op.int(0);
        if (simple_start) |start| {
            try self.lowerExprIntoX0(iter);
            try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
            try beamEmitter.writeMoveOp(self.out, start, Dst.xr(0));
        } else {
            const st = try self.stageOperands(&.{ start_expr.?, iter }, &[_]ast.TrailingLambda{});
            try self.emitParallelMove(st.slice(), &.{ 0, 1 });
        }
        try beamEmitter.writeCall(self.out, .normal, 2, .{ .ext = .{ .module = "lists", .function = "enumerate" } }, 0);
    }

    /// A statement-position call of a local closure recorded in
    /// `mutating_closures`: the call and the names it threads, or null.
    const ClosureMutation = struct { cc: @FieldType(@FieldType(ast.CallExprOf(.untyped), "kind"), "call"), names: []const []const u8 };

    fn closureMutation(self: *const Emitter, e: ast.Expr) ?ClosureMutation {
        if (e != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        if (cc.is_builtin or cc.receiver != null or !self.reg_map.contains(cc.callee)) return null;
        const names = self.mutating_closures.get(cc.callee) orelse return null;
        return .{ .cc = cc, .names = names };
    }

    /// `val name = { params -> body }` whose body reassigns names of this frame:
    /// the fun takes those names as one extra argument after its own and
    /// answers their new values (a fun cannot write its caller's stack slots).
    /// Binds `name` like any local. Returns false (nothing emitted) when the
    /// body reassigns none.
    fn lowerMutatingClosure(self: *Emitter, name: []const u8, params: []const []const u8, body: []const ast.Stmt) anyerror!bool {
        if (self.reg_map.contains(name)) return false;
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        defer names.deinit(self.alloc);
        try self.collectMutations(body, params, &names);
        if (names.items.len == 0 or names.items.len > max_staged or params.len + 1 >= max_staged) return false;

        var env_ops: std.ArrayListUnmanaged(Op) = .empty;
        defer env_ops.deinit(self.alloc);
        const entry = try self.emitGroupFun(.{ .params = params }, names.items, body, false, &env_ops);
        try self.emitMakeFun(entry, 0, env_ops.items);

        const y_idx = self.next_y;
        self.next_y += 1;
        try self.reg_map.put(name, .{ .y = y_idx });
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
        try self.mutating_closures.put(name, try self.prelude_arena.allocator().dupe([]const u8, names.items));
        return true;
    }

    /// `emit(a…)` on a closure `lowerMutatingClosure` lowered: pass the group
    /// after the arguments, apply the fun, store what it answers back.
    fn lowerClosureMutationCall(self: *Emitter, cm: ClosureMutation) anyerror!void {
        const arity: u32 = @intCast(cm.cc.args.len + cm.cc.trailing.len);
        try self.materializeCallArgs(cm.cc.args, cm.cc.trailing);
        try self.emitGroupInto(cm.names, arity, arity);
        try beamEmitter.writeMoveOp(self.out, self.reg_map.get(cm.cc.callee).?.operand(), Dst.xr(arity + 1));
        try beamEmitter.writeCallFun(self.out, arity + 1);
        try self.unpackGroupFromX0(cm.names);
    }

    /// The condition loop whose body is being emitted into the current frame.
    fn inCondLoop(self: *const Emitter) ?CondLoop {
        const cl = self.cond_loop orelse return null;
        return if (cl.out == self.out) cl else null;
    }

    /// `loop (condition) { … }` / `loop { … }` (decision 8 §10) in this frame:
    ///
    ///     {label, Top}  <test Cond, else jump Exit>  Body  {jump, {f, Top}}  {label, Exit}
    ///
    /// Reassigned variables live in this frame's registers, so they need no
    /// threading; `break` jumps to `Exit`, `continue` to `Top`.
    ///
    /// When the body carries a `break <value>` (decision 8 §10) the loop is an
    /// expression, and the condition's failure path needs a register of its own
    /// so it cannot be the `break`'s:
    ///
    ///     {label, Top}  <test Cond, else jump Fail>  Body  {jump, {f, Top}}
    ///     {label, Fail} {move, {atom, undefined}, {x,0}}  {label, Exit}
    ///
    /// so `{x, 0}` at `Exit` is the break's value on the `break` path and
    /// `undefined` when the condition ran out — the same pair of answers the
    /// erlang backend's `{Group, Value}` tuple carries (`{FinalGroup,
    /// undefined}` against `{GroupAtTheJump, Value}`).
    fn lowerConditionLoop(self: *Emitter, lp: anytype) anyerror!void {
        const valued = condLoopBreaksWithValue(lp.body);
        const top = self.allocLabel();
        const exit = self.allocLabel();
        const fail = if (valued) self.allocLabel() else exit;
        try beamEmitter.writeLabel(self.out, top);
        if (!try self.lowerComparisonAsTest(lp.iter.*, fail)) {
            try self.lowerExprIntoX0(lp.iter.*);
            try beamEmitter.writeTest(self.out, .is_eq_exact, fail, &.{ Op.xr(0), Op.atom("true") });
        }
        const saved = self.cond_loop;
        self.cond_loop = .{ .top = top, .exit = exit, .out = self.out, .valued = valued };
        defer self.cond_loop = saved;
        for (lp.body) |stmt| try self.emitStmt(stmt);
        if (!(lp.body.len > 0 and stmtIsLoopJump(lp.body[lp.body.len - 1]))) {
            try beamEmitter.writeJump(self.out, top);
        }
        if (valued) {
            try beamEmitter.writeLabel(self.out, fail);
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(0));
        }
        try beamEmitter.writeLabel(self.out, exit);
    }

    fn lowerLoop(self: *Emitter, lp: anytype) anyerror!void {
        const has_map = hasYieldOrBreakValue(lp.body);
        const filter_map = filterMapIf(lp);
        // `loop (xs, 0..) { item, i -> … }` iterates `lists:enumerate(Start, Xs)`:
        // the fun takes one `{Index, Item}` pair and binds both names from it.
        // Without a written range (`loop (xs) { item, i -> … }`) it counts from 0.
        const indexed = lp.params.len == 2;

        const idx = self.lambda_count;
        self.lambda_count += 1;

        var env_names: std.ArrayListUnmanaged([]const u8) = .empty;
        defer env_names.deinit(self.alloc);
        var env_ops: std.ArrayListUnmanaged(Op) = .empty;
        defer env_ops.deinit(self.alloc);
        try self.closureEnv(lp.body, lp.params, &env_names, &env_ops);
        var all_params: std.ArrayListUnmanaged([]const u8) = .empty;
        defer all_params.deinit(self.alloc);
        if (indexed) {
            try all_params.append(self.alloc, "");
        } else {
            try all_params.appendSlice(self.alloc, lp.params);
        }
        try all_params.appendSlice(self.alloc, env_names.items);
        const arity: u32 = @intCast(all_params.items.len);

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
        const saved_group = self.fold_group;
        self.fold_group = null;
        defer self.fold_group = saved_group;

        self.next_y = 0;
        self.cur_arity = arity;
        self.num_y = arity + self.precountLocals(lp.body) + @as(u32, if (indexed) 2 else 0);
        self.in_loop_lambda = true;
        try self.bindParams(all_params.items);

        try beamEmitter.writeBlankLine(self.out);
        try beamEmitter.writeFunctionHeader(self.out, fun_name, arity, labels.entry);
        try beamEmitter.writeLabel(self.out, labels.func_info);
        try beamEmitter.writeLine(self.out, self.module_name, self.cur_line);
        try beamEmitter.writeFuncInfo(self.out, self.module_name, fun_name, arity);
        try beamEmitter.writeLabel(self.out, labels.entry);
        try self.emitFrame(arity);
        try self.emitParamSpill(arity);
        if (indexed) {
            // y0 holds `{Index, Item}`: `element/2` is a guard BIF, so reading
            // it frees no register.
            for ([_]struct { name: []const u8, pos: i64 }{ .{ .name = lp.params[1], .pos = 1 }, .{ .name = lp.params[0], .pos = 2 } }) |b| {
                try beamEmitter.writeBif(self.out, "element", 0, &.{ Op.int(b.pos), Op.yr(0) }, Dst.xr(0));
                const y_idx = self.next_y;
                self.next_y += 1;
                try self.reg_map.put(b.name, .{ .y = y_idx });
                try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.yr(y_idx));
            }
        }

        if (filter_map) |iff| {
            try self.emitFilterMapBody(iff);
        } else {
            try self.emitBody(lp.body);
        }

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
        if (indexed) {
            try self.lowerEnumerateIntoX0(lp.iter.*, lp.indexRange);
        } else {
            try self.lowerExprIntoX0(lp.iter.*);
        }
        try beamEmitter.writeMoveOp(self.out, Op.xr(0), Dst.xr(1));
        try self.emitMakeFun(labels.entry, 2, env_ops.items);

        const func = if (filter_map != null) "filtermap" else if (has_map) "map" else "foreach";
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
                const tag = self.qualifiedVariantTagOf(rn, ia.member) orelse ia.member;
                try beamEmitter.writeMove(self.out, Term.atomOf(tag), dest);
                return;
            }
        }
        // `xs.len` / `s.length` on a primitive: inference records the receiver's
        // primitive kind at this loc, and the member is the host length op, not
        // a map key. Without this the `get_map_elements` path below fails its
        // `is_map` test and falls through leaving the *receiver* in `dest`
        // (`pts.len` printed the whole list).
        if (self.instanceLowering(loc, ia.receiver.*)) |il| switch (il) {
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
            .type_, .field_of => {},
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
            const rec = self.recordTypeOfReceiver(loc, ia.receiver.*, ia.member);
            try beamEmitter.writeTest(self.out, .is_eq, present_l, &.{ Op.xr(0), Op.atom("undefined") });
            // Receiver IS `undefined` (test fell through) → result is `undefined`.
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(dest));
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, present_l);
            if (rec) |type_name| {
                // Decision 21: a record is a tagged tuple, so a present
                // receiver reads its position; a value of any other shape
                // fails the tag test and answers `undefined`, exactly as the
                // map test used to.
                const declared = self.record_fields.get(type_name).?;
                const at = fieldIndexOf(declared, ia.member).?;
                const tag = try self.recordTagAtom(type_name);
                var tag_buf: [512]u8 = undefined;
                try beamEmitter.writeTest(self.out, .is_tagged_tuple, undef_l, &.{
                    Op.xr(0),
                    .{ .untagged = @as(i64, @intCast(declared.len + 1)) },
                    Op.atom(try atomName(tag, &tag_buf)),
                });
                try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), at + 1, Dst.xr(dest));
            } else {
                try beamEmitter.writeTest(self.out, .is_map, undef_l, &.{Op.xr(0)});
                try beamEmitter.writeGetMapElements(self.out, undef_l, Op.xr(0), member, Dst.xr(dest));
            }
            try beamEmitter.writeJump(self.out, end_l);
            try beamEmitter.writeLabel(self.out, undef_l);
            try beamEmitter.writeMoveOp(self.out, Op.atom("undefined"), Dst.xr(dest));
            try beamEmitter.writeLabel(self.out, end_l);
            return;
        }

        // Decision 21 (T2): a record is `{TypeAtom, F1, …}`, so a field read is
        // `erlang:element(N + 1, V)` whenever this emit can place the
        // receiver's type. `element/2` is runtime-checked, which is what the
        // tuple-index read above already needs for a receiver typed `any`.
        if (self.recordTypeOfReceiver(loc, ia.receiver.*, ia.member)) |type_name| {
            const declared = self.record_fields.get(type_name).?;
            const at = fieldIndexOf(declared, ia.member).?;
            // `is_tagged_tuple` + `get_tuple_element`, never `erlang:element/2`:
            // a `call_ext` frees every x-register, and `self.side * self.side`
            // holds the first read in `{x, 1}` across the second
            // (`{{x,1},not_live}` out of the loader's consistency check).
            const fail_label = self.allocLabel();
            const tag = try self.recordTagAtom(type_name);
            var tag_buf: [512]u8 = undefined;
            try beamEmitter.writeTest(self.out, .is_tagged_tuple, fail_label, &.{
                Op.xr(0),
                .{ .untagged = @as(i64, @intCast(declared.len + 1)) },
                Op.atom(try atomName(tag, &tag_buf)),
            });
            try beamEmitter.writeGetTupleElement(self.out, Op.xr(0), at + 1, Dst.xr(dest));
            try beamEmitter.writeLabel(self.out, fail_label);
            return;
        }
        const fail_label = self.allocLabel();
        // A receiver whose type this emit cannot place keeps the map read: an
        // anonymous record and a `@Behavior(…)` literal are maps and stay maps.
        try beamEmitter.writeTest(self.out, .is_map, fail_label, &.{Op.xr(0)});
        try beamEmitter.writeGetMapElements(self.out, fail_label, Op.xr(0), member, Dst.xr(dest));
        try beamEmitter.writeLabel(self.out, fail_label);
    }

    /// The position of `member` in the receiver's record, or null when this
    /// emit cannot place the receiver's type: what inference recorded
    /// (`InstanceLowering.field_of`), the type whose module is being emitted
    /// for a `self` receiver, or the one record declaring the name.
    fn recordTypeOfReceiver(self: *const Emitter, loc: ast.Loc, receiver: ast.Expr, member: []const u8) ?[]const u8 {
        return blk: {
            if (self.instance_lowerings.get(loc)) |il| switch (il) {
                .field_of => |t| if (self.record_fields.contains(t)) break :blk t,
                else => {},
            };
            if (receiver == .identifier and receiver.identifier.kind == .ident and
                std.mem.eql(u8, receiver.identifier.kind.ident, "self"))
            {
                if (self.cur_type) |ct| if (self.record_fields.contains(ct)) break :blk ct;
            }
            var found: ?[]const u8 = null;
            var it = self.record_fields.iterator();
            while (it.next()) |e| {
                if (fieldIndexOf(e.value_ptr.*, member) == null) continue;
                if (found != null) return null;
                found = e.key_ptr.*;
            }
            break :blk found orelse return null;
        };
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

/// The name a written type reference spells, when it is a plain one.
fn writtenTypeName(ref: ast.TypeRef) ?[]const u8 {
    return switch (ref) {
        .named => |n| n,
        .optional => |inner| writtenTypeName(inner.*),
        else => null,
    };
}

/// The OUTER enum of a synthesised inner enum's F1 mangling:
/// `__Token__Color` → `Token`. The beam twin of `erlang.zig`'s.
fn sectionOuterEnum(name: []const u8) ?[]const u8 {
    if (name.len < 3 or name[0] != '_' or name[1] != '_' or !std.ascii.isUpper(name[2])) return null;
    const rest = name[2..];
    const sep = std.mem.indexOf(u8, rest, "__") orelse return null;
    if (sep == 0) return null;
    return rest[0..sep];
}

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
