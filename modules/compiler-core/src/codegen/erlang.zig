/// Erlang codegen backend.
///
/// Translates the botopink typed AST to Erlang source.
///
/// Conventions used:
///   - Variables → CamelCase (first letter uppercased)
///   - String literals → <<"...">> binaries
///   - Function bodies → comma-separated expressions; last is return value
///   - OR patterns  → expanded to multiple Erlang case clauses
///   - `return expr` → bare `expr` (Erlang last-expr return)
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const envMod = @import("../comptime/env.zig");
const crossModule = @import("./crossModule.zig");
const patternFacts = @import("./patterns.zig");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const prelude = @import("std_prelude");
const primOpTemplate = @import("../comptime/primOpTemplate.zig");
const erlEmitter = @import("./beam/erl_emitter.zig");
const Ast = @import("./beam/erl_ast.zig");
const Term = @import("./beam/term.zig").Term;

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;
const CrossModule = crossModule.CrossModule;

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

/// True when a record/struct/enum method is an associated fn — no `self`
/// receiver, so it's callable as `Type.method(...)` (and across modules as a
/// remote call). Its Erlang arity is just `params.len` (no `self` to drop).
fn isAssocMethod(m: ast.BehaviorMethod) bool {
    return m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self");
}

/// How the body of a `forEach` accumulator lambda computes the next value of
/// the captured `acc`, recognized by `classifyFoldStmt`. Each variant carries
/// the AST piece a `lists:foldl/3` fun body is built from (the accumulator is
/// the fun's second parameter, named after `acc`).
const FoldBodyKind = union(enum) {
    /// `acc = expr;` → fun body is `expr`.
    assign: *const ast.Expr,
    /// `acc += expr;` → fun body is `(Acc + expr)`.
    plus_assign: *const ast.Expr,
    /// `acc.push(x);` (mutate-in-place on JS) → fun body is `(Acc ++ [x])`.
    push: *const ast.Expr,
    /// `if (c) { acc = t; } [else { acc = e; }]` → `case c of true -> t; _ -> e|Acc end`.
    if_assign: struct { cond: *const ast.Expr, then_val: *const ast.Expr, else_val: ?*const ast.Expr },
};

/// A `var acc = init;` binding immediately followed by `recv.forEach({ p -> … })`
/// whose lambda body only mutates `acc`. Erlang closures can't rebind a captured
/// variable, so the pair is fused into a single
/// `Acc = lists:foldl(fun(P, Acc) -> <body> end, Init, Recv)` — see
/// `detectFoldFusion`/`emitFoldFusion`.
const FoldFusion = struct {
    acc_name: []const u8,
    init: *const ast.Expr,
    recv: *const ast.Expr,
    param: []const u8,
    body_kind: FoldBodyKind,
};

/// Recognize the single statement of a `forEach` accumulator lambda. Returns
/// `null` for any shape that doesn't reduce to "compute the next `acc`".
fn classifyFoldStmt(stmt: ast.Stmt, acc_name: []const u8) ?FoldBodyKind {
    switch (stmt.expr) {
        .binding => |b| switch (b.kind) {
            .assign => |a| {
                const tgt = switch (a.target) {
                    .name => |n| n,
                    else => return null,
                };
                if (!std.mem.eql(u8, tgt, acc_name)) return null;
                return switch (a.op) {
                    .assign => .{ .assign = a.value },
                    .plusAssign => .{ .plus_assign = a.value },
                };
            },
            else => return null,
        },
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (!std.mem.eql(u8, cc.callee, "push")) return null;
                if (cc.args.len != 1) return null;
                const recv = cc.receiver orelse return null;
                const rn = identName(recv.*) orelse return null;
                if (!std.mem.eql(u8, rn, acc_name)) return null;
                return .{ .push = cc.args[0].value };
            },
            else => return null,
        },
        .branch => |br| switch (br.kind) {
            .if_ => |if_node| {
                if (if_node.binding != null) return null;
                const then_val = singleAssignValue(if_node.then_, acc_name) orelse return null;
                var else_val: ?*const ast.Expr = null;
                if (if_node.else_) |else_body| {
                    else_val = singleAssignValue(else_body, acc_name) orelse return null;
                }
                return .{ .if_assign = .{ .cond = if_node.cond, .then_val = then_val, .else_val = else_val } };
            },
            else => return null,
        },
        else => return null,
    }
}

/// The RHS of a single `acc = expr;` statement body, or `null`.
fn singleAssignValue(body: []const ast.Stmt, acc_name: []const u8) ?*const ast.Expr {
    if (body.len != 1) return null;
    return switch (classifyFoldStmt(body[0], acc_name) orelse return null) {
        .assign => |e| e,
        else => null,
    };
}

/// The bare identifier name of `expr`, or `null` if it isn't a plain identifier.
fn identName(expr: ast.Expr) ?[]const u8 {
    return switch (expr) {
        .identifier => |id| switch (id.kind) {
            .ident => |n| n,
            else => null,
        },
        else => null,
    };
}

/// Marker kinds emitted by `transform.zig::tryLowerFutureJump`.
const FutureWrapKindErl = enum { resolved, rejected };

/// Recognise the `__bp_future_resolved(<t>)` / `__bp_future_rejected(<e>)`
/// builtin marker calls so the erlang return-statement emitter can strip
/// them back to the eager-lowering shape (`<t>` for resolved, `throw(<e>)`
/// for rejected). The promise wrap is implicit in erlang's sync rendering.
fn futureWrapCallNameErl(e: ast.Expr) ?FutureWrapKindErl {
    if (e != .call) return null;
    if (e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (!c.is_builtin or c.args.len != 1) return null;
    if (std.mem.eql(u8, c.callee, "__bp_future_resolved")) return .resolved;
    if (std.mem.eql(u8, c.callee, "__bp_future_rejected")) return .rejected;
    return null;
}

fn isZeroArgMainCallExpr(expr: ast.Expr) bool {
    return switch (expr) {
        .call => |c| switch (c.kind) {
            .call => |cc| !cc.is_builtin and
                cc.receiver == null and
                cc.args.len == 0 and
                cc.trailing.len == 0 and
                std.mem.eql(u8, cc.callee, "main"),
            else => false,
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |rp| isZeroArgMainCallExpr(rp.*) else false,
            .try_ => |t| if (t) |tp| isZeroArgMainCallExpr(tp.*) else false,
            else => false,
        },
        .collection => |col| switch (col.kind) {
            .grouped => |inner| isZeroArgMainCallExpr(inner.*),
            else => false,
        },
        else => false,
    };
}

fn isSyntheticMainEntrypointCall(v: ast.ValDecl) bool {
    if (std.mem.startsWith(u8, v.name, "_main")) return true;
    return std.mem.startsWith(u8, v.name, "_") and isZeroArgMainCallExpr(v.value.*);
}

// Auto-imported Erlang BIF table — driven by `@External.Erlang("erlang", "<symbol>")`
// annotations in the std `erlang` module (`libs/std/src/erlang.bp`,
// surfaced through `prelude.pkg_modules`).
//
// `loadAutoImportedBifsFromPrelude` walks the `std/erlang` module's
// decls, picks every one whose annotation list contains
// `@External.Erlang("erlang", "<symbol>")`, and returns a (name, arity)
// list — `name` from the annotation's second arg (the actual erlang
// symbol; preserves snake_case), `arity` from the decl's param count.
// The generated module prelude emits
// `-compile({no_auto_import,[fn/arity, …]}).` for any user fn that
// shadows one of these — without the directive, OTP 27+ erlc upgrades
// the `ambiguous call of overridden pre Erlang/OTP R14 auto-imported
// BIF` diagnostic from warning to compile error.
//
// Decoupling the catalog from `builtins.d.bp` keeps the global env
// clean: these wrappers ship as a `std/erlang` module consumers
// `import { … } from "std/erlang"` only when they actually need the
// raw BIF surface. The codegen's shadow-detection job is independent
// of whether they get imported.
//
// To add / remove / update a BIF: edit `libs/std/src/erlang.bp`. No
// `.zig` recompile of the table itself is needed.
const AutoImportedBif = struct { name: []const u8, arity: u8 };

fn loadAutoImportedBifsFromPrelude(
    alloc: std.mem.Allocator,
) anyerror!std.ArrayListUnmanaged(AutoImportedBif) {
    var out: std.ArrayListUnmanaged(AutoImportedBif) = .empty;
    errdefer out.deinit(alloc);

    // Locate the `std/erlang` module in the embedded pkg registry.
    var source: ?[]const u8 = null;
    for (prelude.pkg_modules) |entry| {
        if (std.mem.eql(u8, entry.path, "std/erlang")) {
            source = entry.source;
            break;
        }
    }
    if (source == null) return out;

    // Parse inside an arena so the lexer + AST scratch storage is freed
    // wholesale at function exit; only the `.name` dupes that land in
    // `out` are owned by `alloc` (caller frees via `freeAutoImportedBifs`).
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var lx = lexerMod.Lexer.init(source.?);
    const tokens = lx.scanAll(a) catch return out;
    var p = parserMod.Parser.init(tokens);
    var program = p.parse(a) catch return out;
    defer program.deinit(a);

    for (program.decls) |decl| {
        if (decl != .@"fn") continue;
        const f = decl.@"fn";
        // Pick decls carrying `@External.Erlang("erlang", "<symbol>")`.
        // The shadow lookup needs the *erlang symbol* (not the botopink
        // fn name) — botopink fns are camelCase, erlang BIFs are
        // snake_case; only the symbol arg matches what the user's
        // codegen-lowered fn ends up named in erlang output.
        const ref = f.externalFor("erlang") orelse continue;
        const sym = ref.symbol;
        if (f.params.len > std.math.maxInt(u8)) continue;
        try out.append(alloc, .{
            .name = try alloc.dupe(u8, sym),
            .arity = @intCast(f.params.len),
        });
    }
    return out;
}

fn freeAutoImportedBifs(alloc: std.mem.Allocator, list: *std.ArrayListUnmanaged(AutoImportedBif)) void {
    for (list.items) |b| alloc.free(b.name);
    list.deinit(alloc);
}

/// `name/arity` of every user function whose name + arity shadows an Erlang
/// auto-imported BIF, deduplicated in declaration order. Walks every surface
/// emitted as a bare erlang fn: top-level fns plus methods of records, enums,
/// `extend` and `implement` (sharing the global atom namespace). Interface
/// assoc fns are mangled (`'Interface_name'`) and cannot collide with a
/// lowercase BIF, so they are excluded.
fn noAutoImportRefs(b: Ast.Builder, decls: []ast.DeclKind, bif_table: []const AutoImportedBif) ![]const Ast.FnRef {
    var refs: std.ArrayListUnmanaged(Ast.FnRef) = .empty;
    const Collect = struct {
        fn run(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(Ast.FnRef), table: []const AutoImportedBif, name: []const u8, arity: usize) !void {
            for (table) |bif| {
                if (bif.arity != arity or !std.mem.eql(u8, bif.name, name)) continue;
                for (out.items) |seen| {
                    if (seen.arity == arity and std.mem.eql(u8, seen.name, name)) return;
                }
                return out.append(arena, .{ .name = try arena.dupe(u8, name), .arity = arity });
            }
        }
    };
    for (decls) |decl| switch (decl) {
        .@"fn" => |f| try Collect.run(b.arena, &refs, bif_table, f.name, f.params.len),
        // Record / enum methods keep `params.len` as the erlang arity (instance
        // methods include the receiver); `is_declare` methods emit no body.
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => for (tdecl.methods) |m| {
                if (!m.is_declare) try Collect.run(b.arena, &refs, bif_table, m.name, m.params.len);
            },
            .enum_ => for (tdecl.methods) |m| {
                if (!m.is_declare) try Collect.run(b.arena, &refs, bif_table, m.name, m.params.len);
            },
        },
        // Extension methods always keep the receiver as the first param.
        .extend => |ex| for (ex.methods) |m| try Collect.run(b.arena, &refs, bif_table, m.name, m.params.len),
        .implement => |im| for (im.methods) |m| try Collect.run(b.arena, &refs, bif_table, m.name, m.params.len),
        else => {},
    };
    return refs.items;
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Cross-module link index — lets a consumer resolve an imported record's
    // associated fn to a remote call into the owning module (`http:ok(...)`)
    // and an owner export only the assoc fns another module consumes.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    // Every module's `pub enum`s with their variants, so a consumer can quote
    // an imported variant in a case pattern (`collectImportedTypes`). The
    // cross-module index carries an enum's name only.
    var enum_exports: std.ArrayListUnmanaged(EnumExport) = .empty;
    defer enum_exports.deinit(alloc);
    for (outputs) |*ct| {
        const ok = switch (ct.outcome) {
            .ok => |*o| o,
            else => continue,
        };
        for (ok.transformed.decls) |decl| switch (decl) {
            .type_ => |e| if (!e.isRecord() and e.isPub) try enum_exports.append(alloc, .{ .module = ct.name, .name = e.name, .variants = e.variants() }),
            else => {},
        };
    }

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
                // `"std"` package copies are dependencies — never emit their
                // test blocks (mirrors the commonJS rule).
                const module_test_mode = config.test_mode and !std.mem.startsWith(u8, ct.name, "std/");
                // 06 C13 — a host-backed fn with no `erlang` target used to
                // abort the whole build with the bare error name. It reaches
                // the driver as a located diagnostic naming the function now,
                // like a type error: only this module fails.
                var missing: ?moduleOutput.MissingExternal = null;
                const code = emitErlang(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, module_test_mode, &cross, enum_exports.items, &missing) catch |err| {
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

/// Shape of a standalone module evaluated at compile time (decorator / template
/// bodies run in the persistent `erl`). The body decls are lowered by the same
/// emitter as regular modules — only the host glue differs.
pub const ComptimeModule = struct {
    /// Enum types the host injects without a declaration (`DeclKind`), so a
    /// qualified member (`DeclKind.Type`) lowers to its variant atom.
    host_enums: []const []const u8 = &.{},
    /// Record types the host injects without a declaration (`Span`,
    /// `CustomNode`), so a constructor call (`Span(5, 9, 1)`,
    /// `CustomNode(kind: …)`) lowers to the same `#{field => …}` map a declared
    /// record would.
    host_records: []const HostRecord = &.{},
    /// Extra exports (the evaluator entry, `main/0`).
    exports: []const Ast.FnRef = &.{},
    /// Host forms appended after the lowered decls and the standard helpers
    /// (host functions, the evaluator entry).
    forms: []const Ast.Form = &.{},
    /// Host forms that live in a **resident** module instead of being rendered
    /// into this one: `-import`ed, so the lowered body's own text is unchanged,
    /// and `comptime_helper_forms` is not appended (the prelude carries it).
    /// They still answer `isHostFunction`, so the located unsupported-method
    /// diagnostic sees the same set of host functions either way.
    /// Built by `comptime/runtime/prelude.zig`.
    resident: ?Resident = null,
    /// Render only the lowered decls and `forms` — no module header, exports or
    /// helper forms. Not a compilable module: the listing snapshots show.
    listing: bool = false,
    /// When set, a method call that no primitive type answers and no host form
    /// defines is rejected at emit time: the call is recorded here and the emit
    /// fails with `error.UnsupportedComptimeMethod`, so the evaluator reports a
    /// located diagnostic instead of `erl_lint`'s `{undefined_function,…}`.
    /// Only honoured on the compilable (non-`listing`) emit, where `forms`
    /// carries every host function.
    unsupported_method: ?*UnsupportedMethod = null,

    /// A module the generated one imports its host glue from, with the forms
    /// that module defines. `refs` is derived from `forms`, so nothing can be
    /// imported that the prelude does not export.
    pub const Resident = struct {
        module: []const u8,
        forms: []const Ast.Form,
        refs: []const Ast.FnRef,
    };
};

/// The first method call of a comptime body nothing can answer (see
/// `ComptimeModule.unsupported_method`). `callee` borrows from the body's AST.
pub const UnsupportedMethod = struct {
    callee: []const u8 = "",
    /// Positional arguments plus trailing lambdas — the receiver excluded.
    argc: usize = 0,
    loc: ast.Loc = .{ .line = 0, .col = 0 },
};

/// A number's representation: an erlang integer, a float, or a number whose
/// precision is unknown (the result of `*` on operands of unknown type).
const NumKind = enum { int, float, number };

/// The runtime-dispatch shim a comptime-body method call lowers to:
/// `'__bp_prim_<method>'(Recv, Args…)` (see `Emitter.primShimForms`).
const prim_shim_prefix = "__bp_prim_";

/// The atom a bare `break` throws and its loop's `try` catches.
const break_signal = "__bp_break";
/// The named-fun variable an unbounded `loop (x..)` recurses through.
const loop_fun_var = "__Loop";
/// The throws a condition loop (decision 8 §10) catches: `{Signal, Group}`,
/// the reassigned variables at the jump.
const cond_break_signal = "__bp_cond_break";
const cond_continue_signal = "__bp_cond_continue";

/// A `pub enum` of some module in the build, with its variants.
const EnumExport = struct {
    /// The declaring module's path (`std/order`).
    module: []const u8,
    name: []const u8,
    variants: []const ast.EnumVariant,
};

pub const HostRecord = struct {
    name: []const u8,
    /// Field names in declaration order (positional constructor arguments).
    fields: []const []const u8,
};

/// `'__bp_add'/2`: `+` on operands of unknown type — two binaries concatenate,
/// anything else is arithmetic. Every comptime module carries it; a typed module
/// emits it when neither operand of a `+` is provably a number or a string.
const add_helper_form: Ast.Form = .{ .function = .{ .name = "__bp_add", .clauses = &.{
    .{
        .patterns = &.{ Ast.Expr.v("A"), Ast.Expr.v("B") },
        .guards = &.{ isA("binary", "A"), isA("binary", "B") },
        .body = Ast.Body.of(&.{.{ .expr = .{ .bin = &.{
            .{ .value = Ast.Expr.v("A"), .type = "binary" },
            .{ .value = Ast.Expr.v("B"), .type = "binary" },
        } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("A"), Ast.Expr.v("B") },
        .body = Ast.Body.of(&.{.{ .expr = .{ .binop = .{ .op = "+", .lhs = &Ast.Expr.v("A"), .rhs = &Ast.Expr.v("B"), .parens = false } } }}),
        .layout = .inline_,
    },
} } };

/// `'__bp_len'/2`: `.len`/`.length`/`.size` on a receiver of unknown type — a
/// list's length, a binary's length, else the map field. Every comptime module
/// carries it; a typed module emits it when inference recorded no lowering for
/// such a field read.
const len_helper_form: Ast.Form = .{ .function = .{ .name = "__bp_len", .clauses = &.{
    .{
        .patterns = &.{ Ast.Expr.v("X"), Ast.Expr.v("_") },
        .guards = &.{isA("list", "X")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .name = "length", .args = &.{Ast.Expr.v("X")} } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("X"), Ast.Expr.v("_") },
        .guards = &.{isA("binary", "X")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "string", .name = "length", .args = &.{Ast.Expr.v("X")} } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("X"), Ast.Expr.v("Field") },
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "maps", .name = "get", .args = &.{ Ast.Expr.v("Field"), Ast.Expr.v("X") } } } }}),
        .layout = .inline_,
    },
} } };

/// `'__bp_text'/1`: any term as a binary — a binary is itself, anything else
/// its `~p` rendering. Every comptime module carries it; a typed module emits it
/// when a string `+` has an operand that is not provably a string
/// (`concatSegments`).
const text_helper_form: Ast.Form = .{ .function = .{ .name = "__bp_text", .clauses = &.{
    .{
        .patterns = &.{Ast.Expr.v("Value")},
        .guards = &.{isA("binary", "Value")},
        .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.v("Value") }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{Ast.Expr.v("Value")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .name = "iolist_to_binary", .args = &.{.{ .call = .{
            .module = "io_lib",
            .name = "format",
            .args = &.{ Ast.Expr.t(Term.str("~p")), .{ .list = &.{Ast.Expr.v("Value")} } },
        } }} } } }}),
        .layout = .inline_,
    },
} } };

/// `'__bp_print'/1`: the `@print`/`@println`/`@debug` lowering (cross-backend
/// semantics decisions 1 and 1a). It takes the argument LIST and prints the
/// values on one line separated by a space, each as `'__bp_show'/2` renders
/// it. The rendering dispatches at runtime, so the typed and the untyped
/// (comptime) path print the same bytes.
const print_helper_form: Ast.Form = .{ .function = .{ .name = "__bp_print", .clauses = &.{.{
    .patterns = &.{Ast.Expr.v("Values")},
    .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "io", .name = "format", .args = &.{
        .{ .string = "~ts~n" },
        .{ .list = &.{.{ .call = .{ .module = "lists", .name = "join", .args = &.{
            .{ .string = " " },
            .{ .list_comp = .{
                .element = &Ast.Expr{ .call = .{ .name = "__bp_show", .args = &.{ Ast.Expr.v("V"), Ast.Expr.a("true") } } },
                .qualifiers = &.{.{ .generator = .{ .pattern = Ast.Expr.v("V"), .list = Ast.Expr.v("Values") } }},
            } },
        } } }} },
    } } } }}),
}} } };

/// `V` bound to the first element of a tuple, for the tagged-tuple guard.
const show_first: Ast.Expr = .{ .call = .{ .name = "element", .args = &.{ .{ .number = "1" }, Ast.Expr.v("V") } } };

/// `element(1, V) =/= Atom`.
fn firstIsNot(comptime atom: []const u8) Ast.Expr {
    return .{ .binop = .{ .op = "=/=", .lhs = &show_first, .rhs = &Ast.Expr.a(atom), .parens = false } };
}

/// `'__bp_show'(Elem, false)` over `Elems`, joined by `,`.
fn showJoined(comptime elems: Ast.Expr) Ast.Expr {
    return .{ .call = .{ .module = "lists", .name = "join", .args = &.{
        .{ .string = "," },
        .{ .list_comp = .{
            .element = &Ast.Expr{ .call = .{ .name = "__bp_show", .args = &.{ Ast.Expr.v("E"), Ast.Expr.a("false") } } },
            .qualifiers = &.{.{ .generator = .{ .pattern = Ast.Expr.v("E"), .list = elems } }},
        } },
    } } };
}

/// `$C -> "Escaped"` — one clause of the nested-string escape `case`.
fn escapeClause(comptime char: []const u8, comptime escaped: []const u8) Ast.Clause {
    return .{ .patterns = &.{.{ .number = char }}, .body = Ast.Body.of(&.{.{ .expr = .{ .string = escaped } }}), .layout = .inline_ };
}

/// `'__bp_show'/2`: the text of one printed value as chardata (semantics
/// decision 1a). `Top` is `true` for an argument of `@print` itself.
///   - a binary at top level is its text; nested, it is quoted with the source
///     escapes (`\"`, `\\`, `\n`, `\r`, `\t`);
///   - a list is `[E1,E2]`, a tuple `#(E1,E2)` — no spaces;
///   - a tuple tagged by an atom (an enum variant `{'Circle', R}`, a Result
///     `{ok, V}`) and every other term (numbers, atoms, maps) keep `~p`: the
///     text of records, enums and maps is not decided by 1a. `true`, `false`
///     and `undefined` are values, not tags, so a tuple they open is a tuple.
const show_helper_form: Ast.Form = .{ .function = .{ .name = "__bp_show", .clauses = &.{
    .{
        .patterns = &.{ Ast.Expr.v("V"), Ast.Expr.a("true") },
        .guards = &.{isA("binary", "V")},
        .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.v("V") }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("V"), Ast.Expr.v("_") },
        .guards = &.{isA("binary", "V")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .list = &.{
            .{ .number = "$\"" },
            .{ .list_comp = .{
                .element = &Ast.Expr{ .case_ = .{
                    .subject = &Ast.Expr.v("C"),
                    .clauses = &.{
                        escapeClause("$\"", "\\\""),
                        escapeClause("$\\\\", "\\\\"),
                        escapeClause("$\\n", "\\n"),
                        escapeClause("$\\r", "\\r"),
                        escapeClause("$\\t", "\\t"),
                        .{ .patterns = &.{Ast.Expr.v("_")}, .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.v("C") }}), .layout = .inline_ },
                    },
                    .layout = .inline_,
                } },
                .qualifiers = &.{.{ .generator = .{
                    .pattern = Ast.Expr.v("C"),
                    .list = .{ .call = .{ .module = "unicode", .name = "characters_to_list", .args = &.{Ast.Expr.v("V")} } },
                } }},
            } },
            .{ .number = "$\"" },
        } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("V"), Ast.Expr.v("_") },
        .guards = &.{isA("list", "V")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .list = &.{ .{ .number = "$[" }, showJoined(Ast.Expr.v("V")), .{ .number = "$]" } } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("V"), Ast.Expr.v("_") },
        .guards = &.{
            isA("tuple", "V"),
            .{ .binop = .{ .op = ">", .lhs = &Ast.Expr{ .call = .{ .name = "tuple_size", .args = &.{Ast.Expr.v("V")} } }, .rhs = &Ast.Expr{ .number = "0" }, .parens = false } },
            .{ .call = .{ .name = "is_atom", .args = &.{show_first} } },
            firstIsNot("true"),
            firstIsNot("false"),
            firstIsNot("undefined"),
        },
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "io_lib", .name = "format", .args = &.{ .{ .string = "~p" }, .{ .list = &.{Ast.Expr.v("V")} } } } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("V"), Ast.Expr.v("_") },
        .guards = &.{isA("tuple", "V")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .list = &.{
            .{ .string = "#(" },
            showJoined(.{ .call = .{ .name = "tuple_to_list", .args = &.{Ast.Expr.v("V")} } }),
            .{ .number = "$)" },
        } } }}),
        .layout = .inline_,
    },
    .{
        .patterns = &.{ Ast.Expr.v("V"), Ast.Expr.v("_") },
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "io_lib", .name = "format", .args = &.{ .{ .string = "~p" }, .{ .list = &.{Ast.Expr.v("V")} } } } } }}),
        .layout = .inline_,
    },
} } };

/// Helpers every comptime module carries. Bodies are untyped (no inference ran
/// over them), so type-directed lowerings dispatch at runtime — `+` →
/// `'__bp_add'/2` (binary concat for strings, arithmetic otherwise),
/// `.len`/`.length` → `'__bp_len'/2` (list/string length, else the map field) —
/// and host glue reports through `'__bp_text'/1` (any term as a binary) and
/// `'__bp_json'/1` (a term with `undefined` as JSON `null`).
pub const comptime_helper_forms = [_]Ast.Form{
    add_helper_form,
    len_helper_form,
    text_helper_form,
    .{
        .function = .{
            .name = "__bp_json",
            .clauses = &.{
                .{
                    .patterns = &.{Ast.Expr.a("undefined")},
                    .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.a("null") }}),
                    .layout = .inline_,
                },
                .{
                    .patterns = &.{Ast.Expr.v("Map")},
                    .guards = &.{isA("map", "Map")},
                    .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "maps", .name = "map", .args = &.{
                        .{ .fun = .{
                            .params = &.{ Ast.Expr.v("_"), Ast.Expr.v("V") },
                            .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .name = "__bp_json", .args = &.{Ast.Expr.v("V")} } } }}),
                        } },
                        Ast.Expr.v("Map"),
                    } } } }}),
                    .layout = .inline_,
                },
                .{
                    .patterns = &.{Ast.Expr.v("List")},
                    .guards = &.{isA("list", "List")},
                    .body = Ast.Body.of(&.{.{ .expr = .{ .list_comp = .{
                        .element = &Ast.Expr{ .call = .{ .name = "__bp_json", .args = &.{Ast.Expr.v("V")} } },
                        .qualifiers = &.{.{ .generator = .{ .pattern = Ast.Expr.v("V"), .list = Ast.Expr.v("List") } }},
                    } } }}),
                    .layout = .inline_,
                },
                .{
                    // A tuple has no JSON form: `{"$tuple": [...]}`, read back by
                    // template_eval's `typedValue`.
                    .patterns = &.{Ast.Expr.v("Tuple")},
                    .guards = &.{isA("tuple", "Tuple")},
                    .body = Ast.Body.of(&.{.{ .expr = .{ .map = &.{.{
                        .key = .{ .lexeme_binary = "$tuple" },
                        .value = .{ .list_comp = .{
                            .element = &Ast.Expr{ .call = .{ .name = "__bp_json", .args = &.{Ast.Expr.v("V")} } },
                            .qualifiers = &.{.{ .generator = .{ .pattern = Ast.Expr.v("V"), .list = .{ .call = .{ .module = "erlang", .name = "tuple_to_list", .args = &.{Ast.Expr.v("Tuple")} } } } }},
                        } },
                    }} } }}),
                    .layout = .inline_,
                },
                .{
                    .patterns = &.{Ast.Expr.v("Value")},
                    .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.v("Value") }}),
                    .layout = .inline_,
                },
            },
        },
    },
};

/// `is_<kind>(Var)` guard test.
fn isA(comptime kind: []const u8, comptime variable: []const u8) Ast.Expr {
    return .{ .call = .{ .name = "is_" ++ kind, .args = &.{Ast.Expr.v(variable)} } };
}

/// Emit `program` as a comptime-evaluated Erlang module: the lowered decls, the
/// `comptime_helper_forms` (unless `module.resident` carries them) and then the
/// host forms of `module`.
pub fn emitComptimeModule(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    module: ComptimeModule,
) ![]u8 {
    var comptime_vals = std.StringHashMap([]const u8).init(alloc);
    defer comptime_vals.deinit();
    var rewrites = std.AutoHashMap(ast.Loc, []const u8).init(alloc);
    defer rewrites.deinit();
    var instance_lowerings = std.AutoHashMap(ast.Loc, envMod.InstanceLowering).init(alloc);
    defer instance_lowerings.deinit();
    return emitErlangModule(alloc, module_name, program, comptime_vals, rewrites, instance_lowerings, false, null, &.{}, module, null);
}

/// How many `<Iface>.<method>` entries the primitive dispatch table holds for a
/// module that declares nothing — i.e. what the embedded `primitives.bp`
/// contributes. `collectPrimErlangDispatch` swallows a prelude parse failure,
/// which would silently empty the table for every module; tests pin this.
pub fn primErlangDispatchCount(alloc: std.mem.Allocator) !usize {
    var comptime_vals = std.StringHashMap([]const u8).init(alloc);
    defer comptime_vals.deinit();
    var rewrites = std.AutoHashMap(ast.Loc, []const u8).init(alloc);
    defer rewrites.deinit();
    var em = Emitter.init(alloc, comptime_vals, rewrites);
    var no_decls = [_]ast.DeclKind{};
    try em.collectPrimErlangDispatch(.{ .decls = &no_decls });
    defer {
        var pit = em.prim_iface_chain.iterator();
        while (pit.next()) |entry| {
            alloc.free(entry.key_ptr.*);
            alloc.free(entry.value_ptr.*);
        }
        em.prim_iface_chain.deinit();
        var dit = em.prim_erlang_dispatch.iterator();
        while (dit.next()) |entry| {
            alloc.free(entry.key_ptr.*);
            alloc.free(entry.value_ptr.module);
            alloc.free(entry.value_ptr.symbol);
            if (entry.value_ptr.args) |args| {
                for (args) |a| alloc.free(a);
                alloc.free(args);
            }
            for (entry.value_ptr.arity_branches) |br| alloc.free(br.template);
            if (entry.value_ptr.arity_branches.len > 0) alloc.free(entry.value_ptr.arity_branches);
        }
        em.prim_erlang_dispatch.deinit();
    }
    return em.prim_erlang_dispatch.count();
}

// ── top-level emitter ─────────────────────────────────────────────────────────

fn emitErlang(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    test_mode: bool,
    cross: ?*const CrossModule,
    enum_exports: []const EnumExport,
    /// 06 C13 — set when the emit fails with `error.MissingExternalTarget`, so
    /// the caller reports the function and the call site, not the error name.
    missing: ?*?moduleOutput.MissingExternal,
) ![]u8 {
    return emitErlangModule(alloc, module_name, program, comptime_vals, rewrites, instance_lowerings, test_mode, cross, enum_exports, null, missing);
}

fn emitErlangModule(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    test_mode: bool,
    cross: ?*const CrossModule,
    enum_exports: []const EnumExport,
    comptime_module: ?ComptimeModule,
    missing: ?*?moduleOutput.MissingExternal,
) ![]u8 {
    var em = Emitter.init(alloc, comptime_vals, rewrites);
    errdefer if (missing) |slot| {
        slot.* = em.missing_external;
    };
    em.enum_exports = enum_exports;
    em.instance_lowerings = instance_lowerings;
    em.untyped = comptime_module != null;
    if (comptime_module) |cm| {
        em.host_forms = cm.forms;
        if (cm.resident) |r| em.resident_forms = r.forms;
        if (!cm.listing) em.unsupported_method = cm.unsupported_method;
    }
    defer {
        for (em.prim_shims.keys()) |k| alloc.free(k);
        em.prim_shims.deinit(alloc);
    }
    em.test_mode = test_mode;
    em.module_name = module_name;
    em.cross = cross;

    // Test registry entries collected while emitting decls (test mode only).
    const TestEntry = struct { name: ?[]const u8, line: usize, idx: usize };
    var test_entries: std.ArrayListUnmanaged(TestEntry) = .empty;
    defer test_entries.deinit(alloc);
    var test_count: usize = 0;
    if (test_mode) {
        for (program.decls) |decl| {
            if (decl == .@"test") test_count += 1;
        }
    }
    // Names of `implement`/`extend` blocks — a PascalCase call receiver that
    // matches one is a qualified extension call (`PatoNada.swim(d)`), lowered
    // to the bare local function `swim(d)` rather than a remote module call.
    try em.collectExtensionNames(program);
    defer em.ext_names.deinit();
    try em.collectExternals(program);
    defer em.externals.deinit();
    defer em.externals_missing.deinit();
    try em.collectStdImports(program);
    defer em.std_imports.deinit();
    defer em.locals.deinit();
    defer em.mutable_locals.deinit(alloc);
    defer em.mutating_closures.deinit(alloc);
    defer {
        var kit = em.local_fn_arities.keyIterator();
        while (kit.next()) |k| alloc.free(k.*);
        em.local_fn_arities.deinit(alloc);
    }
    defer em.var_current.deinit();
    defer em.var_next.deinit();
    defer em.top_vals.deinit();
    try em.collectInterfaces(program);
    defer {
        var iface_it = em.interface_assoc.keyIterator();
        while (iface_it.next()) |k| em.alloc.free(k.*);
        em.interface_assoc.deinit();
        var inst_it = em.iface_instance_defaults.keyIterator();
        while (inst_it.next()) |k| em.alloc.free(k.*);
        em.iface_instance_defaults.deinit();
        // Keys are borrowed from `iface_instance_defaults` — freed above.
        em.needed_instance_defaults.deinit(em.alloc);
        var self_it = em.iface_self_returns.keyIterator();
        while (self_it.next()) |k| em.alloc.free(k.*);
        em.iface_self_returns.deinit();
        // Keys and values borrow the program AST — nothing to free.
        em.local_behaviors.deinit();
    }
    defer em.nullable_locals.deinit();
    defer em.string_locals.deinit();
    defer em.string_names.deinit();
    defer em.num_locals.deinit(alloc);
    defer em.num_names.deinit(alloc);
    try em.collectPrimErlangDispatch(program);
    // A comptime body is one decl: the primitive interfaces' bodied instance
    // `default fn`s (`String.slice`, `Array.first`) are not in it, so they are
    // indexed from the embedded prelude. The parse lives until the module is
    // rendered — the reached bodies are lowered from it and borrow its strings.
    var prelude_arena = std.heap.ArenaAllocator.init(alloc);
    defer prelude_arena.deinit();
    if (comptime_module != null) try em.collectPreludeInstanceDefaults(prelude_arena.allocator());
    try em.collectRecordMethodCollisions(program);
    defer {
        var rit = em.record_method_collisions.iterator();
        while (rit.next()) |entry| em.alloc.free(entry.key_ptr.*);
        em.record_method_collisions.deinit();
    }
    defer {
        var pit = em.prim_iface_chain.iterator();
        while (pit.next()) |entry| {
            em.alloc.free(entry.key_ptr.*);
            em.alloc.free(entry.value_ptr.*);
        }
        em.prim_iface_chain.deinit();
    }
    defer {
        var dit = em.prim_erlang_dispatch.iterator();
        while (dit.next()) |entry| {
            em.alloc.free(entry.key_ptr.*);
            em.alloc.free(entry.value_ptr.module);
            em.alloc.free(entry.value_ptr.symbol);
            if (entry.value_ptr.args) |args| {
                for (args) |a| em.alloc.free(a);
                em.alloc.free(args);
            }
            for (entry.value_ptr.arity_branches) |br| em.alloc.free(br.template);
            if (entry.value_ptr.arity_branches.len > 0) em.alloc.free(entry.value_ptr.arity_branches);
        }
        em.prim_erlang_dispatch.deinit();
    }
    try em.collectBuiltinErlangDispatch();
    defer {
        var bit = em.builtin_erlang_dispatch.iterator();
        while (bit.next()) |entry| {
            em.alloc.free(entry.key_ptr.*);
            if (entry.value_ptr.symbol.len > 0) em.alloc.free(entry.value_ptr.symbol);
            for (entry.value_ptr.arity_branches) |br| em.alloc.free(br.template);
            if (entry.value_ptr.arity_branches.len > 0) em.alloc.free(entry.value_ptr.arity_branches);
        }
        em.builtin_erlang_dispatch.deinit();
        var uit = em.user_erlang_templates.iterator();
        while (uit.next()) |entry| {
            em.alloc.free(entry.key_ptr.*);
            if (entry.value_ptr.symbol.len > 0) em.alloc.free(entry.value_ptr.symbol);
            for (entry.value_ptr.arity_branches) |br| em.alloc.free(br.template);
            if (entry.value_ptr.arity_branches.len > 0) em.alloc.free(entry.value_ptr.arity_branches);
        }
        em.user_erlang_templates.deinit();
    }
    try em.collectTypeShapes(program);
    try em.collectImportedTypes(program);
    try em.collectStringNames(program);
    try em.collectLocalFnArities(program);
    // After `collectLocalFnArities`: an adopted `default fn` is emitted only
    // when its `<name>/<arity>` is still free in the module.
    try em.collectAdoptedIfaceDefaults(program);
    defer {
        var ad_it = em.adopted_defaults.keyIterator();
        while (ad_it.next()) |k| em.alloc.free(k.*);
        em.adopted_defaults.deinit();
    }
    if (comptime_module) |cm| {
        for (cm.host_enums) |name| try em.enum_names.put(name, {});
        for (cm.host_records) |r| try em.record_fields.put(r.name, try alloc.dupe([]const u8, r.fields));
    }
    defer {
        var rf_it = em.record_fields.valueIterator();
        while (rf_it.next()) |names| alloc.free(names.*);
        em.record_fields.deinit();
        em.enum_names.deinit();
        em.enum_variants.deinit();
        em.imported_types.deinit();
        em.imported_fns.deinit();
        var ftf_it = em.fn_typed_fields.keyIterator();
        while (ftf_it.next()) |k| alloc.free(k.*);
        em.fn_typed_fields.deinit();
        em.fn_typed_field_names.deinit();
    }
    var top_runtime_vals: std.ArrayListUnmanaged(ast.ValDecl) = .empty;
    defer top_runtime_vals.deinit(alloc);
    var has_main_0 = false;
    for (program.decls) |decl| {
        switch (decl) {
            .val => |v| {
                if (!v.value.isComptimeExpr() and !isSyntheticMainEntrypointCall(v)) try top_runtime_vals.append(alloc, v);
            },
            .@"fn" => |f| {
                if (std.mem.eql(u8, f.name, "main") and fnArityNoSelf(f) == 0) has_main_0 = true;
            },
            else => {},
        }
    }
    // Test mode never auto-runs `main/0` — the escript entry is the test runner.
    const emit_entrypoint_wrapper = has_main_0 and !test_mode;

    // A *named* runtime module-level `val` is always emitted as a 0-arity function
    // (`topValForms`), so a bare reference to it lowers to the call `name()`.
    // Erlang has no module-level storage: binding them as locals of the generated
    // `'_botopink_main'/0` (what the entrypoint wrapper used to do) left every read
    // from `main/0` — or from any other function — as an unbound variable.
    // The trade-off is that the initialiser runs once per read instead of once at
    // startup; `_`-named synthetic statements (top-level expression statements)
    // keep their single, ordered evaluation inside the wrapper.
    for (program.decls) |decl| {
        const v = switch (decl) {
            .val => |x| x,
            else => continue,
        };
        if (!v.value.isComptimeExpr() or isSyntheticMainEntrypointCall(v)) continue;
        if (std.mem.startsWith(u8, v.name, "_")) continue;
        em.top_vals.put(v.name, {}) catch {};
    }
    for (top_runtime_vals.items) |v| {
        if (std.mem.startsWith(u8, v.name, "_")) continue;
        em.top_vals.put(v.name, {}) catch {};
    }

    // The module is built as `erl_ast` forms in one arena, then rendered.
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const b: Ast.Builder = .{ .arena = arena_state.allocator() };
    var forms: Forms = .empty;

    // Module header. "std" package modules are named `std/<mod>` for output
    // layout; the Erlang module atom is the basename (`-module(option).`).
    const erl_module_name = if (std.mem.lastIndexOfScalar(u8, module_name, '/')) |i|
        module_name[i + 1 ..]
    else
        module_name;
    try forms.append(b.arena, .{ .module = erl_module_name });

    // `-compile({no_auto_import,[fn/arity, ...]}).` for any user function whose
    // name + arity shadows an Erlang auto-imported BIF: OTP 27+ erlc makes the
    // `ambiguous call of overridden pre Erlang/OTP R14 auto-imported BIF`
    // diagnostic an error, and the directive keeps the generated code
    // OTP-version-independent. The (name, arity) catalog comes from
    // `prelude.erlang_bifs` (`libs/std/src/erlang_bifs.d.bp`).
    var bif_table = try loadAutoImportedBifsFromPrelude(alloc);
    defer freeAutoImportedBifs(alloc, &bif_table);
    const shadows = try noAutoImportRefs(b, program.decls, bif_table.items);
    if (shadows.len > 0) try forms.append(b.arena, .{ .no_auto_import = shadows });

    // Collect public function names for export.
    var pub_fns: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    defer pub_fns.deinit(alloc);
    for (program.decls) |decl| {
        switch (decl) {
            // External fns emit no local definition — nothing to export.
            .@"fn" => |f| if (f.isPub and !f.isExternal()) try pub_fns.append(alloc, f),
            else => {},
        }
    }
    // The generated entrypoint wrapper when main/0 exists; `main/1` is the
    // escript entry point (escript calls it with the argv list).
    if (emit_entrypoint_wrapper) {
        try forms.append(b.arena, .{ .exports = &.{ .{ .name = "_botopink_main", .arity = 0 }, .{ .name = "main", .arity = 1 } } });
    }
    // Test runner escript entry point.
    if (test_mode and test_count > 0) {
        try forms.append(b.arena, .{ .exports = &.{.{ .name = "main", .arity = 1 }} });
    }

    // A record/enum whose name another module imports exports its associated
    // fns: the consumer reaches them via a remote call (`http:ok(...)`). Records
    // emit assoc fns as bare local functions (see `recordForms`), so the owner
    // exports `<fn>/<arity>` for every no-`self` method. Scoped to consumed
    // types → single-module programs are unchanged.
    var exports: std.ArrayListUnmanaged(Ast.FnRef) = .empty;
    if (comptime_module) |cm| try exports.appendSlice(b.arena, cm.exports);
    for (pub_fns.items) |f| try exports.append(b.arena, .{ .name = f.name, .arity = fnArityNoSelf(f) });
    // A host-backed `declare fn` another module imports is answered by the
    // wrapper the decl loop emits, so it is exported like any other pub fn.
    // `externalWrapperEmits` is the same predicate the decl loop applies, so the
    // export list never names a wrapper that was skipped (erlc rejects an
    // exported undefined function).
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (externalWrapperNeeded(f, cross) and em.externalWrapperEmits(f)) {
            // A top-level `declare fn` takes no `self`, so the declared
            // parameter count is the wrapper's arity.
            try exports.append(b.arena, .{ .name = f.name, .arity = f.params.len });
        },
        else => {},
    };
    if (cross) |xc| {
        for (program.decls) |decl| {
            // A `pub` type's methods are reachable from another module even when
            // that module never names the type itself (a method called on a
            // value some imported fn answered), so the owner exports them in any
            // multi-module build.
            const tdecl = switch (decl) {
                .type_ => |t| if (t.isPub or xc.imported.contains(t.name)) t else continue,
                else => continue,
            };
            for (tdecl.methods) |m| {
                if (m.is_declare) continue;
                // Both shapes are bare local functions here: an assoc fn takes
                // only its declared parameters, an instance method takes the
                // receiver as `params[0]`. A method name two types share is
                // emitted under its mangled name (`grouping_toArray`), so the
                // export must name what the module actually defines.
                var mn_buf: [256]u8 = undefined;
                const mn: []const u8 = if (em.isRecordMethodCollision(tdecl.name, m.name))
                    try b.arena.dupe(u8, try Emitter.recordMethodAtom(&mn_buf, tdecl.name, m.name))
                else
                    m.name;
                try exports.append(b.arena, .{ .name = mn, .arity = m.params.len });
            }
        }
        // A `pub implement` / `pub extend` another module activates
        // (`import {PatoNada*} from "pond"`) is reached as a remote call, so the
        // owner exports each method. Extension methods keep the receiver as
        // their first parameter, so the arity is the full parameter count.
        for (program.decls) |decl| {
            const ext: struct { name: []const u8, is_pub: bool, methods: []const ast.ImplementMethod } = switch (decl) {
                .implement => |im| .{ .name = im.name, .is_pub = im.isPub, .methods = im.methods },
                .extend => |ex| .{ .name = ex.name, .is_pub = ex.isPub, .methods = ex.methods },
                else => continue,
            };
            if (!ext.is_pub or !xc.imported.contains(ext.name)) continue;
            for (ext.methods) |m| try exports.append(b.arena, .{ .name = m.name, .arity = m.params.len });
        }
    }
    if (exports.items.len > 0) try forms.append(b.arena, .{ .exports = exports.items });

    // A comptime module reaches its host glue in the resident prelude by its
    // bare name, so the lowered body reads the same whether the glue is
    // rendered here or compiled once at server warmup. A listing is not a
    // compilable module and carries no directive.
    if (comptime_module) |cm| {
        if (cm.resident) |r| {
            if (!cm.listing) try forms.append(b.arena, .{ .import = .{ .module = r.module, .funs = r.refs } });
        }
    }

    // Declarations, each after an empty line.
    const decls_start = forms.items.len;
    for (program.decls) |decl| {
        try forms.append(b.arena, .blank);
        switch (decl) {
            // Only the `_`-named synthetic statements move into the entrypoint
            // wrapper; every named `val` keeps its 0-arity form (see `top_vals`).
            .val => |v| if (!emit_entrypoint_wrapper or v.value.isComptimeExpr() or
                !std.mem.startsWith(u8, v.name, "_")) try em.topValForms(b, &forms, v),
            .@"fn" => |f| {
                if (!f.isExternal()) {
                    try em.fnForms(b, &forms, f);
                    continue;
                }
                // FFI declaration — calls lower to the remote target directly.
                const text = if (em.externals.get(f.name)) |ref|
                    try std.fmt.allocPrint(b.arena, "external fn {s} -> {s}:{s}", .{ f.name, ref.module, ref.symbol })
                else if (em.user_erlang_templates.contains(f.name))
                    try std.fmt.allocPrint(b.arena, "external fn {s} -> erlang template", .{f.name})
                else
                    try std.fmt.allocPrint(b.arena, "external fn {s} (no erlang target)", .{f.name});
                try forms.append(b.arena, .{ .comment = Ast.Comment.doc(text) });
                // …and, when another module imports it, the wrapper that module
                // calls (`hostlib:hostKey(V)`).
                if (externalWrapperNeeded(f, cross)) {
                    if (try em.externalWrapperForm(b, f)) |form| try forms.append(b.arena, form);
                }
            },
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => try em.recordForms(b, &forms, tdecl),
                .enum_ => try em.enumForms(b, &forms, tdecl),
            },
            .behavior => |i| try em.interfaceForms(b, &forms, i),
            .implement => |im| try em.implementForms(b, &forms, im),
            .extend => |ex| try em.extendForms(b, &forms, ex),
            .use => |u| try forms.append(b.arena, .{ .comment = Ast.Comment.doc(try useComment(b, u)) }),
            // `mod` is module-tree metadata; the submodule emits as its own atom.
            .mod => {},
            .delegate => |d| try forms.append(b.arena, .{ .comment = Ast.Comment.doc(try std.fmt.allocPrint(b.arena, "delegate {s}", .{d.name})) }),
            // Test blocks are only compiled under `botopink test`; in normal
            // builds they are skipped entirely.
            .@"test" => |t| {
                if (!test_mode) continue;
                const idx = test_entries.items.len;
                try test_entries.append(alloc, .{ .name = t.name, .line = t.loc.line, .idx = idx });
                try forms.append(b.arena, try em.testFunction(b, t, idx));
            },
            .comment => |c| try forms.append(b.arena, .{ .comment = .{
                .level = if (c.is_doc) .doc else if (c.is_module) .module else .line,
                .text = c.text,
            } }),
        }
    }

    // Interface instance `default fn`s reached by some call site above.
    try em.instanceDefaultForms(b, &forms);

    // Runtime helpers a lowering reached. A comptime module always carries
    // `'__bp_text'/1` (`comptime_helper_forms`); a listing renders no helper.
    const listing_only = if (comptime_module) |cm| cm.listing else false;
    if (comptime_module == null) {
        // Runtime-dispatch shims a typed call site reached (no recorded
        // lowering); their fallback clause for `toString` formats through
        // `'__bp_text'/1`.
        if (em.prim_shims.count() > 0) {
            try em.primShimForms(b, &forms);
            if (em.prim_shims.contains("toString/0")) em.needs_text_helper = true;
        }
    }
    if (!listing_only) {
        if (em.needs_add_helper and comptime_module == null) try forms.appendSlice(b.arena, &.{ .blank, add_helper_form });
        if (em.needs_len_helper and comptime_module == null) try forms.appendSlice(b.arena, &.{ .blank, len_helper_form });
        if (em.needs_text_helper and comptime_module == null) try forms.appendSlice(b.arena, &.{ .blank, text_helper_form });
        if (em.needs_print_helper) try forms.appendSlice(b.arena, &.{ .blank, print_helper_form, .blank, show_helper_form });
    }

    if (comptime_module) |cm| {
        if (!cm.listing) {
            try em.primShimForms(b, &forms);
            // The prelude carries them when there is one; a shim's `toString`
            // fallback reaches `'__bp_text'/1` through the same `-import`.
            if (cm.resident == null) {
                for (&comptime_helper_forms) |form| try forms.appendSlice(b.arena, &.{ .blank, form });
            }
        }
        for (cm.forms) |form| try forms.appendSlice(b.arena, &.{ .blank, form });
    }

    if (emit_entrypoint_wrapper) {
        // `'_botopink_main'() -> Stmt1, …, main().` runs the top-level
        // expression statements in order, then `main/0`. Named vals are 0-arity
        // functions instead, so they stay reachable from every function.
        const saved_indent = em.indent;
        em.indent = 1;
        var stmts: std.ArrayListUnmanaged(Ast.Expr) = .empty;
        for (top_runtime_vals.items) |v| {
            if (!std.mem.startsWith(u8, v.name, "_")) continue;
            try stmts.append(b.arena, try em.topValEntryExpr(b, v));
        }
        try stmts.append(b.arena, try b.call("main", &.{}));
        em.indent = saved_indent;
        try forms.appendSlice(b.arena, &.{
            .blank,
            try blockFunction(b, "_botopink_main", &.{}, try b.body(stmts.items)),
            .blank,
            try blockFunction(b, "main", &.{Ast.Expr.v("_Args")}, try b.body(&.{try b.call("_botopink_main", &.{})})),
        });
    }

    // Test mode: the registry, the runner and the escript entry.
    if (test_mode and test_entries.items.len > 0) {
        const tests = try b.arena.alloc(Ast.Expr, test_entries.items.len);
        for (test_entries.items, 0..) |t, i| {
            const name = t.name orelse try std.fmt.allocPrint(b.arena, "test_{d}", .{t.idx});
            tests[i] = try b.tuple(&.{
                .{ .lexeme_binary = name },
                .{ .fun_ref = .{ .name = try std.fmt.allocPrint(b.arena, "__bp_test_{d}", .{t.idx}), .arity = 0 } },
                .{ .lexeme_binary = try std.fmt.allocPrint(b.arena, "{s}.bp:{d}", .{ module_name, t.line }) },
            });
        }
        // Only a module that calls into another needs the sibling loader: a
        // single-module project's runner stays exactly as it was.
        try testRunnerForms(b, &forms, tests, em.imported_fns.count() > 0 or em.imported_types.count() > 0);
    }

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    const listing = if (comptime_module) |cm| cm.listing else false;
    // A listing starts at the first decl, past its leading blank line.
    const written = if (listing) forms.items[@min(decls_start + 1, forms.items.len)..] else forms.items;
    try erlEmitter.writeForms(&aw.writer, written);
    return aw.toOwnedSlice();
}

const Forms = std.ArrayListUnmanaged(Ast.Form);

/// True when this module must answer `f` — a `pub` host-backed `declare fn` —
/// with a callable wrapper: some other module imports the name, and erlang
/// resolves a bare call in the CALLING module. Single-module builds and
/// declarations nobody imports emit the comment alone, as before.
fn externalWrapperNeeded(f: ast.FnDecl, cross: ?*const crossModule.CrossModule) bool {
    if (!f.isPub or !f.isExternal()) return false;
    const xc = cross orelse return false;
    return xc.imported.contains(f.name);
}

/// `name(Patterns) ->` + block body.
fn blockFunction(b: Ast.Builder, name: []const u8, patterns: []const Ast.Expr, body: Ast.Body) !Ast.Form {
    return .{ .function = .{
        .name = try b.arena.dupe(u8, name),
        .clauses = try b.arena.dupe(Ast.Clause, &.{.{ .patterns = try b.exprs(patterns), .body = body }}),
    } };
}

/// `import a, b` / `activate a, b` (a comment's text).
fn useComment(b: Ast.Builder, u: ast.ImportDecl) ![]const u8 {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(b.arena, if (u.activationOnly) "activate " else "import ");
    for (u.imports, 0..) |imp, i| {
        if (i > 0) try text.appendSlice(b.arena, ", ");
        try text.appendSlice(b.arena, imp.name());
    }
    return text.items;
}

/// `io:format("Format", [Args])`.
fn ioFormat(b: Ast.Builder, format: []const u8, args: []const Ast.Expr) !Ast.Expr {
    return b.remote("io", "format", &.{ .{ .string = format }, try b.list(args) });
}

fn comments(b: Ast.Builder, lines: []const []const u8) ![]const Ast.Stmt {
    const out = try b.arena.alloc(Ast.Stmt, lines.len);
    for (lines, 0..) |line, i| out[i] = .{ .comment = Ast.Comment.doc(line) };
    return out;
}

/// The test-mode runner: `'__bp_run_one'/1` runs one `{Name, Fun, Loc}` inside
/// the `----- RUN LOG -----` envelope, `'__bp_run_tests'/1` runs the registry
/// (`tests`, filtered by name) and halts non-zero on failure, and `main/1` is the
/// escript entry.
fn testRunnerForms(b: Ast.Builder, forms: *Forms, tests: []const Ast.Expr, load_siblings: bool) !void {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const monotonic = try b.remote("erlang", "monotonic_time", &.{A("millisecond")});
    const outcome = try b.match(V("Outcome"), .{ .try_catch = .{
        .body = try b.body(&.{ .{ .apply = .{ .fun = try b.ptr(V("Fun")) } }, A("ok") }),
        .catches = try b.arena.dupe(Ast.Clause, &.{
            .{
                .patterns = try b.exprs(&.{try b.exception(A("error"), try b.tuple(&.{ A("bp_assert"), V("Msg"), V("ALoc") }))}),
                .body = try b.body(&.{try b.tuple(&.{ A("fail"), V("Msg"), V("ALoc") })}),
            },
            .{
                .patterns = try b.exprs(&.{try b.exception(V("Class"), V("Reason"))}),
                .body = try b.body(&.{try b.tuple(&.{ A("fail"), try b.tuple(&.{ V("Class"), V("Reason") }), V("Loc") })}),
            },
        }),
    } });
    const fail_pattern = try b.tuple(&.{ A("fail"), V("FMsg"), V("FLoc") });
    const report = try b.caseOf(V("Outcome"), &.{
        .{ .patterns = try b.exprs(&.{A("ok")}), .body = try b.body(&.{ try ioFormat(b, "  ok   ~s~n", &.{V("Name")}), A("ok") }) },
        .{
            .patterns = try b.exprs(&.{fail_pattern}),
            .guards = try b.exprs(&.{try b.call("is_binary", &.{V("FMsg")})}),
            .body = try b.body(&.{ try ioFormat(b, "  FAIL ~s  (~s)  at ~s~n", &.{ V("Name"), V("FMsg"), V("FLoc") }), A("fail") }),
        },
        .{ .patterns = try b.exprs(&.{fail_pattern}), .body = try b.body(&.{ try ioFormat(b, "  FAIL ~s  (~p)  at ~s~n", &.{ V("Name"), V("FMsg"), V("FLoc") }), A("fail") }) },
    });

    var run_one: std.ArrayListUnmanaged(Ast.Stmt) = .empty;
    try run_one.appendSlice(b.arena, try comments(b, &.{
        "§T `----- RUN LOG -----` envelope (v0.beta.20 frente-b spec):",
        "emit TEST header + fenced ```logs``` block; the test body's",
        "io:format/io:put_chars calls land inside the fence",
        "sequentially via the group leader (no explicit capture",
        "needed for the sync erlang shape).",
    }));
    try run_one.appendSlice(b.arena, &.{
        .{ .expr = try ioFormat(b, "TEST ~s ~s~n", &.{ V("Loc"), V("Name") }) },
        .{ .expr = try ioFormat(b, "----- RUN LOG -----~n```logs~n", &.{}) },
    });
    try run_one.appendSlice(b.arena, try comments(b, &.{
        "§T duration: monotonic millisecond clock around Fun(); the",
        "delta lands on its own `  duration <ms>ms` line between the",
        "fence close and the ok/FAIL line. Older parsers that don't",
        "recognise the duration line skip it (forward-compatible).",
    }));
    try run_one.appendSlice(b.arena, &.{
        .{ .expr = try b.match(V("T0"), monotonic) },
        .{ .expr = outcome },
        .{ .expr = try b.match(V("T1"), monotonic) },
        .{ .expr = try b.match(V("DurMs"), try b.remote("erlang", "max", &.{
            Ast.Expr.t(Term.int(0)),
            .{ .binop = .{ .op = "-", .lhs = try b.ptr(V("T1")), .rhs = try b.ptr(V("T0")), .parens = false } },
        })) },
        .{ .expr = try ioFormat(b, "```~n", &.{}) },
        .{ .expr = try ioFormat(b, "  duration ~pms~n", &.{V("DurMs")}) },
        .{ .expr = report },
    });

    const selected = try b.caseOf(V("Filter"), &.{
        try b.clause(&.{A("none")}, &.{}, &.{V("Tests")}),
        try b.clause(&.{V("_")}, &.{}, &.{.{ .list_comp = .{
            .element = try b.ptr(V("T")),
            .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                .{ .generator = .{ .pattern = try b.match(try b.tuple(&.{ V("N"), V("_"), V("_") }), V("T")), .list = V("Tests") } },
                .{ .filter = .{ .binop = .{ .op = "=/=", .lhs = try b.ptr(try b.remote("binary", "match", &.{ V("N"), V("Filter") })), .rhs = try b.ptr(A("nomatch")), .parens = false } } },
            }),
        } }}),
    });
    const results: Ast.Expr = .{ .list_comp = .{
        .element = try b.ptr(try b.call("__bp_run_one", &.{V("T")})),
        .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{.{ .generator = .{ .pattern = V("T"), .list = V("Selected") } }}),
    } };
    const failures: Ast.Expr = .{ .list_comp = .{
        .element = try b.ptr(V("R")),
        .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
            .{ .generator = .{ .pattern = V("R"), .list = V("Results") } },
            .{ .filter = .{ .binop = .{ .op = "=:=", .lhs = try b.ptr(V("R")), .rhs = try b.ptr(A("fail")), .parens = false } } },
        }),
    } };
    const run_tests = try b.body(&.{
        try b.match(V("Tests"), .{ .list_block = tests }),
        try b.match(V("Selected"), selected),
        try b.match(V("Results"), results),
        try b.match(V("Failed"), try b.call("length", &.{failures})),
        try b.match(V("Passed"), .{ .binop = .{ .op = "-", .lhs = try b.ptr(try b.call("length", &.{V("Results")})), .rhs = try b.ptr(V("Failed")), .parens = false } }),
        try ioFormat(b, "~p passed, ~p failed~n", &.{ V("Passed"), V("Failed") }),
        try b.caseInline(.{ .binop = .{ .op = ">", .lhs = try b.ptr(V("Failed")), .rhs = try b.ptr(Ast.Expr.t(Term.int(0))), .parens = false } }, &.{
            try b.clause(&.{A("true")}, &.{}, &.{try b.call("halt", &.{Ast.Expr.t(Term.int(1))})}),
            try b.clause(&.{A("false")}, &.{}, &.{A("ok")}),
        }),
    });

    const filter = try b.caseOf(V("Args"), &.{
        try b.clause(&.{try b.cons(&.{V("F")}, V("_"))}, &.{}, &.{try b.call("list_to_binary", &.{V("F")})}),
        try b.clause(&.{V("_")}, &.{}, &.{A("none")}),
    });

    try forms.appendSlice(b.arena, &.{
        .blank,
        try blockFunction(b, "__bp_run_one", &.{try b.tuple(&.{ V("Name"), V("Fun"), V("Loc") })}, .{ .stmts = run_one.items }),
        .blank,
        try blockFunction(b, "__bp_run_tests", &.{V("Filter")}, run_tests),
    });

    // `escript <module>.erl` compiles and loads THAT module only, so a call
    // into a sibling or a dependency (`a:twice(X)`) is `undef` at run time.
    // Compile and load every other module the runner wrote beside this one,
    // once, before the tests run. A module that does not compile is skipped:
    // its own cell reports the error.
    const main_body = if (load_siblings) blk: {
        const loader: Ast.Expr = .{ .raw =
            \\(fun() ->
            \\        Dir = filename:dirname(escript:script_name()),
            \\        Self = atom_to_list(?MODULE) ++ ".erl",
            \\        lists:foreach(fun(Src) ->
            \\            case filename:basename(Src) =:= Self of
            \\                true -> ok;
            \\                false ->
            \\                    case compile:file(Src, [binary, return_errors, {i, Dir}]) of
            \\                        {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
            \\                        _ -> ok
            \\                    end
            \\            end
            \\        end, filelib:wildcard(filename:join([Dir, "**", "*.erl"])))
            \\    end)()
        };
        try forms.appendSlice(b.arena, &.{
            .blank,
            try blockFunction(b, "__bp_load_siblings", &.{}, try b.body(&.{loader})),
        });
        break :blk try b.body(&.{
            try b.call("__bp_load_siblings", &.{}),
            try b.match(V("Filter"), filter),
            try b.call("__bp_run_tests", &.{V("Filter")}),
        });
    } else try b.body(&.{ try b.match(V("Filter"), filter), try b.call("__bp_run_tests", &.{V("Filter")}) });

    try forms.appendSlice(b.arena, &.{
        .blank,
        try blockFunction(b, "main", &.{V("Args")}, main_body),
    });
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// True when `name` looks like a module/type reference (PascalCase) rather than
/// a local variable. A qualified call whose receiver is such a name maps to an
/// Erlang remote call `module:fun(...)`; a lowercase receiver is a value the
/// method is invoked on and is left as-is.
fn isModuleRef(name: []const u8) bool {
    if (name.len == 0) return false;
    if (std.ascii.isUpper(name[0])) return true;
    // §enum-sections F4 — synthesised inner enums carry the F1 mangling
    // `__<EnumName>__<SectionPath>` (double underscore + uppercase enum
    // letter). Recognise them as module refs so the codegen's enum_names
    // lookup matches and the qualified-ctor lowering fires.
    return name.len >= 3 and name[0] == '_' and name[1] == '_' and std.ascii.isUpper(name[2]);
}

/// Module atom for a type-like name (`List` → `list`), allocated by the caller's
/// allocator.
const erlangModule = erlEmitter.moduleName;

/// Mangled atom for an interface associated `default fn` (`Array`.`range` →
/// `array_range`). The interface's first char is lowercased so the result is a
/// valid UNQUOTED erlang atom (a PascalCase `Array_range` would need quoting),
/// and the `Interface_` prefix avoids colliding with a consumer's own top-level
/// fn of the same name (a consumer may define its own `range`/`repeat`).
fn interfaceAssocAtom(buf: []u8, iface: []const u8, method: []const u8) ![]const u8 {
    if (iface.len == 0) return std.fmt.bufPrint(buf, "{s}", .{method});
    return std.fmt.bufPrint(buf, "{c}{s}_{s}", .{ std.ascii.toLower(iface[0]), iface[1..], method });
}

/// True when a parameter can hold `undefined` at runtime: it is declared `?T`,
/// or it defaults to `null` (`end: i32 = null`, the optional-argument form the
/// arity-dispatch default fns use). `if (p)` on such a parameter is a null test,
/// not a boolean test.
fn isNullableParam(p: ast.Param) bool {
    if (p.typeRef == .optional) return true;
    const d = p.default orelse return false;
    return d == .literal and d.literal.kind == .null_;
}

/// An interface instance `default fn` — a `default fn` whose first parameter is
/// `self` and which carries a body. Unlike an associated default (`Array.range`)
/// it is reached through a value receiver (`xs.all(pred)`), so the emitted form
/// keeps `self` as its first parameter.
const IfaceDefault = struct { iface: []const u8, method: ast.BehaviorMethod };

/// One `'__bp_prim_<callee>'/<argc + 1>` runtime-dispatch shim a comptime body
/// reached. `callee` borrows from the body's AST.
const PrimShim = struct { callee: []const u8, argc: usize };

/// The primitive kinds a shim dispatches on, in clause order, with the guard
/// BIF that recognises each one's runtime representation.
const prim_shim_kinds = [_]struct { kind: envMod.PrimKind, guard: Ast.Expr }{
    .{ .kind = .array, .guard = isA("list", "Recv") },
    .{ .kind = .string, .guard = isA("binary", "Recv") },
    .{ .kind = .bool, .guard = isA("boolean", "Recv") },
    .{ .kind = .int, .guard = isA("integer", "Recv") },
    .{ .kind = .float, .guard = isA("float", "Recv") },
};

/// Tuple positional member (`_0`, `_1`, …) → the digits, else null.
/// Distinguishes tuple index access from `_`-prefixed record fields.
fn tupleIndexMember(member: []const u8) ?[]const u8 {
    // `t._N` and the bare `t.N` both read element N.
    const digits = if (member.len > 0 and member[0] == '_') member[1..] else member;
    if (digits.len == 0) return null;
    for (digits) |ch| {
        if (!std.ascii.isDigit(ch)) return null;
    }
    return digits;
}

/// §A5 annotation-driven prim-method dispatch entry: the host module + symbol +
/// optional ordered arg names parsed from `@external(erlang, "mod", "sym(args)")`.
/// `args == null` means "bare symbol" — emit in declaration order.
///
/// `prim-op-annotation` arity branches (`when($argc == N): "..."`) live in
/// `arity_branches`. When non-empty, this entry is arity-branched: the emitter
/// looks up the matching branch by call-site argc and renders its template
/// (ignoring `module`/`symbol`/`args`). RP2 (`prim-op-no-arity-match`) is
/// raised when no branch matches.
const PrimErlangCall = struct {
    module: []const u8,
    symbol: []const u8,
    args: ?[]const []const u8,
    arity_branches: []const ast.ArityBranch = &.{},
};

/// Map a primitive `PrimKind` to its controller interface name in
/// `primitives.d.bp`. Mirrors `comptime/infer.zig`'s `primitiveInterfaceName`.
/// `.int` maps to `Signed` (its chain reaches `Integer` and `Number`) and
/// `.float` to `Float` — the concrete `I32`/`I64`/`U32`/`U64`/`F32`/`F64`
/// interfaces are empty markers that extend their parent, so a method
/// declared on `Integer` (e.g. `toString → erlang:integer_to_binary`)
/// reaches any concrete-width receiver through `walkPrimIfaceChain`.
fn primIfaceForKind(k: envMod.PrimKind) ?[]const u8 {
    return switch (k) {
        .array => "Array",
        .string => "String",
        .bool => "Bool",
        // `Signed` extends `Integer`, so a walk from it reaches both: `abs`,
        // declared on `Signed`, was never found from `Integer` and fell through
        // to the auto-imported `abs/1`. The checker already rejected `abs` on an
        // unsigned receiver, so starting from the signed interface is safe.
        .int => "Signed",
        .float => "Float",
    };
}

/// Walk the `extends` chain of `iface` (depth-bounded) and yield each
/// successive parent name, starting with `iface` itself. Mirrors the
/// `primMethodReturnTypeFromIface` chain walk on the infer side — used
/// by `primAnnotationNode` so a method declared on a parent
/// (`Integer.toString` for an `I32` receiver) lights up via dispatch
/// without flattening the map at collection time.
const PrimIfaceWalker = struct {
    current: ?[]const u8,
    guard: usize = 0,
    em: *const Emitter,
    /// Optional cache of (iface → parent) edges parsed from
    /// `primitives.d.bp`. When null the walker stops after the head.
    chain: ?*const std.StringHashMap([]const u8),

    fn init(em: *const Emitter, head: []const u8, chain: ?*const std.StringHashMap([]const u8)) PrimIfaceWalker {
        return .{ .current = head, .em = em, .chain = chain };
    }
    fn next(this: *PrimIfaceWalker) ?[]const u8 {
        if (this.guard >= 16) return null;
        const out = this.current orelse return null;
        this.guard += 1;
        this.current = if (this.chain) |c| c.get(out) else null;
        return out;
    }
};

/// `@print` / `@println` / `@debug` — the builtins lowered to `'__bp_print'/1`.
fn isPrintBuiltin(callee: []const u8) bool {
    return std.mem.eql(u8, callee, "print") or std.mem.eql(u8, callee, "println") or std.mem.eql(u8, callee, "debug");
}

/// True when any `External.<target>(..., "true")` annotation carries the
/// inline flag (last arg is the literal `"true"`).
fn hasExternalInline(annotations: []const ast.Annotation, target: []const u8) bool {
    for (annotations) |a| {
        if (!std.mem.startsWith(u8, a.name, "External.")) continue;
        if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
        if (a.args.len == 0) continue;
        if (std.mem.eql(u8, a.args[a.args.len - 1], "true")) return true;
    }
    return false;
}

// ── Emitter ───────────────────────────────────────────────────────────────────

const Emitter = struct {
    cv: std.StringHashMap([]const u8),
    indent: usize = 0,
    try_seq: usize = 0,
    /// 06 C13 — the host-backed fn whose `#[@External.Erlang(…)]` is missing,
    /// filled at the throw site so `codegenEmit` can turn
    /// `error.MissingExternalTarget` into a located diagnostic naming it.
    missing_external: ?moduleOutput.MissingExternal = null,
    /// While set, `patternBindVar` renders every binder as `_`: the pattern is
    /// being lowered as a pure test (`assertPatternStmts`'s `case` arm) and
    /// nothing reads its names.
    pattern_discard: bool = false,
    /// Comptime modules (see `emitComptimeModule`) carry no inferred types, so
    /// type-directed lowerings dispatch at runtime instead: `+` → `'__bp_add'/2`
    /// (binary concat or arithmetic), `.len`/`.length` → `'__bp_len'/2`.
    untyped: bool = false,
    alloc: std.mem.Allocator,
    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    /// At these sites `recv.m(args)` lowers to the bare local function `m(Recv, args)`.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Set of `implement`/`extend` block names (for qualified-call dispatch).
    ext_names: std.StringHashMap(void),
    /// `@[external(erlang, "module", "symbol")]` fns: name → remote target.
    /// Calls lower to `module:symbol(Args)`; the decl itself emits nothing.
    externals: std.StringHashMap(ast.ExternalRef),
    /// `@[external(…)]` fns with no `erlang` target — calling one is an error.
    externals_missing: std.StringHashMap(void),
    /// §A2 user-fn per-callee template dispatch (erlang twin of the
    /// commonJS `user_node_templates`): a `declare fn` whose
    /// `@external(erlang, …)` symbol is a template (contains `$0`/`$1`/…)
    /// or whose annotation list carries `when(argc == N): "..."` branches.
    /// The decl emits no `module:symbol` reference at the top level — the
    /// template renders inline at every call site, matching how the
    /// existing interface-method `primAnnotationNode` path already
    /// handles per-callee templates on primitives.d.bp methods.
    user_erlang_templates: std.StringHashMap(PrimErlangCall),
    /// Module names imported via `import {…} from "std"` — a lowercase
    /// receiver naming one lowers to a remote call (`option:map(Args)`).
    std_imports: std.StringHashMap(void),
    /// When true, `fnForms` keeps the `self` parameter (extension methods take
    /// the receiver as an explicit first argument; ordinary fns drop `self`).
    keep_self: bool = false,
    /// `botopink test` compilation: `assert` lowers to a `bp_assert` error the
    /// test runner catches per test instead of a hard `true = (...)` badmatch.
    test_mode: bool = false,
    /// Module name, used for `<module>.bp:<line>` source locations in
    /// test-mode assert failures.
    module_name: []const u8 = "main",
    /// Record/struct constructors: name → ordered field names. A constructor
    /// call (`AppError(code: 1, msg: "x")`) lowers to a map literal
    /// `#{code => 1, msg => <<"x">>}` (mirrors the beam backend's
    /// `put_map_assoc` shape); field access lowers to `maps:get/2`.
    record_fields: std.StringHashMap([]const []const u8),
    /// Enum names → so `EnumName.Variant` access lowers to the variant atom.
    enum_names: std.StringHashMap(void),
    /// Enum variant names (across every enum) → so a bare `.ident` case pattern
    /// (`case o { Lt -> … }`) lowers to the atom `'Lt'`, not an erlang variable
    /// that would shadow-match anything.
    enum_variants: std.StringHashMap(void),
    /// Cross-module link index (null in the standalone path).
    cross: ?*const CrossModule = null,
    /// Every module's `pub enum`s (empty in the standalone path).
    enum_exports: []const EnumExport = &.{},
    /// Imported record/struct name → owning module atom. A qualified call whose
    /// receiver names one (`Response.ok(...)` for an imported `Response`) lowers
    /// to a remote call into the owner (`http:ok(...)`), not a bare local fn.
    imported_types: std.StringHashMap([]const u8),
    /// Imported function name → owning module atom: a `pub fn` this module
    /// imports (`import {twice};`) and the methods of an imported record/enum.
    /// Erlang has no ambient scope, so a call to one of these is a remote call
    /// (`a:twice(X)`); emitted bare it was `function twice/1 undefined`. A local
    /// definition of the same name/arity wins (an `@emit`ed mock body defines
    /// `find/2` next to the imported `find`).
    imported_fns: std.StringHashMap([]const u8),
    /// `"<Record>.<field>"` of every field declared with a function type, and
    /// the bare field names — inference records no instance lowering for a call
    /// on a field, so the untyped fallback matches on the name alone.
    fn_typed_fields: std.StringHashMap(void),
    fn_typed_field_names: std.StringHashMap(void),
    /// Value-receiver instance call lowerings (call loc → record/primitive). A
    /// record method lowers to `method(Recv, args)` (or `owner:method(...)` for
    /// an imported type); a primitive method lowers to the erlang host op.
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering) = undefined,
    /// Function-scoped local bindings (params, `val`/`var`, lambda params) of the
    /// function currently being emitted. Erlang variables are function-scoped, so
    /// a flat per-function set is exact. A no-receiver call whose callee is a
    /// local lowers to a fun application (`F(args)`), not a bare function call.
    locals: std.StringHashMap(void),
    /// The subset of `locals` declared with `var` in the current function —
    /// the only receivers a mutating method call (`receiverMutation`) rebinds.
    /// Reset per function alongside `locals`.
    mutable_locals: std.StringHashMapUnmanaged(void) = .empty,
    /// Local closures (`val emit = { x -> tokens = tokens.append([x]); }`) whose
    /// body reassigns variables of the enclosing function, keyed by the closure
    /// name, valued by those variables. Such a closure takes the variables as an
    /// extra last argument and answers their new values (`mutatingClosureExpr`);
    /// a statement-position call rebinds them. Reset with `locals`.
    mutating_closures: std.StringHashMapUnmanaged([]const []const u8) = .empty,
    /// Single-assignment versioning. Erlang variables bind once, so a botopink
    /// name rebound in the same function (`count += 1`, `msg = msg + x`) gets a
    /// fresh variable per binding: `Count`, `Count@1`, `Count@2`. `var_current`
    /// is the version reads resolve to; `var_next` the last version handed out
    /// (never reused, so a version bound in one `case` arm can't collide with a
    /// later one). Both reset per function. `@` keeps versions disjoint from
    /// botopink identifiers.
    var_current: std.StringHashMap(u32),
    var_next: std.StringHashMap(u32),
    /// Module-level `val` names emitted as 0-arity functions (library / test
    /// mode, no entrypoint wrapper). A bare reference to one is NOT a variable —
    /// it lowers to the call `name()`. Empty when an entrypoint wrapper binds the
    /// vals as local variables instead.
    top_vals: std.StringHashMap(void),
    /// Interface associated `default fn` qualified names (`"Array.range"`,
    /// `"Pair.of"`). These pure-botopink fns are emitted as bare local functions
    /// (the interface decl is inlined into each consuming module), so an
    /// `Interface.method(...)` call resolves to the local fn, not a remote
    /// `array:range`. Populated by `collectInterfaces`.
    interface_assoc: std.StringHashMap(void),
    /// Interface INSTANCE `default fn`s (a `self` receiver plus a body), keyed
    /// `<Iface>.<method>` — `"Bool.nor"`, `"String.slice"`, `"Number.clamp"`.
    /// Populated by `collectInterfaces` alongside `interface_assoc`.
    iface_instance_defaults: std.StringHashMap(IfaceDefault),
    /// Every `behavior` this module declares, by name — the erlang twin of
    /// commonJS's `local_interfaces`. `recordForms` walks it to emit the bodied
    /// instance `default fn`s a record adopts with `implement`. Keys and values
    /// borrow the program AST.
    local_behaviors: std.StringHashMap(ast.BehaviorDecl),
    /// `<Record>.<method>` for each adopted instance `default fn` this module
    /// emits as one of the record's own functions. Populated by
    /// `collectAdoptedIfaceDefaults`; owns its keys.
    adopted_defaults: std.StringHashMap(void),
    /// The record `self` names while an adopted interface `default fn` body is
    /// being emitted, else null. Inference records no lowering inside such a
    /// body (the method belongs to the behavior, not to the record), so
    /// `self.size()` would otherwise be a bare `size/1` that a record-method
    /// collision has mangled away.
    self_record_type: ?[]const u8 = null,
    /// The subset of `iface_instance_defaults` a call site actually reached (see
    /// `ifaceDefaultNode`). Only these are emitted, as `<iface>_<method>(Self,
    /// …)` forms at the end of the module — emitting every default of every
    /// inlined primitive interface would bury each module in dead code. Insertion
    /// ordered so the emitted forms are deterministic; the map grows while it is
    /// drained (a default body may call another default), so `instanceDefaultForms`
    /// walks it to a fixpoint.
    needed_instance_defaults: std.StringArrayHashMapUnmanaged(IfaceDefault) = .empty,
    /// `<Iface>.<method>` for every interface method declared to return `Self`.
    /// Inside an instance `default fn` body it is what makes a chained receiver
    /// (`self.filter(pred).length`) keep the interface's primitive kind.
    iface_self_returns: std.StringHashMap(void),
    /// The primitive kind `self` carries while an interface instance
    /// `default fn` body is being emitted, else null. Inference records no
    /// lowering for a `Self`-typed receiver (it is generic over every
    /// implementor), so the emitter re-derives it from the owning interface.
    self_prim_kind: ?envMod.PrimKind = null,
    /// True while emitting an inlined interface `default fn` body. Such a body
    /// may call a std prelude helper (`stringSlice1`) the consuming module never
    /// declares, so bare callees also resolve against the prelude template index.
    in_iface_default: bool = false,
    /// The variables the innermost condition loop (decision 8 §10) threads,
    /// while its body is emitted; null outside one and behind a fun boundary
    /// (a collection loop, a lambda). A `break` / `continue` there throws them.
    cond_loop: ?[]const []const u8 = null,
    /// Numbers the named funs of condition loops so a nested one does not
    /// shadow its parent's name.
    cond_loop_seq: u32 = 0,
    /// Numbers the variables a condition loop's `catch` binds, so two loops in
    /// one function body never reuse a name Erlang considers unsafe after `try`.
    cond_loop_vars: u32 = 0,
    /// Comptime modules only: the `(method, argc)` runtime-dispatch shims the
    /// body's method calls reached (see `untypedPrimCallNode`), keyed
    /// `"<method>/<argc>"` (owned) and insertion ordered so the emitted forms
    /// are deterministic. Drained by `primShimForms`.
    prim_shims: std.StringArrayHashMapUnmanaged(PrimShim) = .empty,
    /// Comptime modules only: the host forms appended after the body
    /// (`ComptimeModule.forms`). A method call whose `(name, argc + 1)` one of
    /// them defines stays the bare local call (`q.text()` → `text(Q)`).
    host_forms: []const Ast.Form = &.{},
    /// Comptime modules only: the host forms a resident prelude defines
    /// (`ComptimeModule.Resident.forms`). Not rendered into this module — the
    /// `-import` above resolves the bare call — but they answer
    /// `isHostFunction` exactly as `host_forms` does, so where a method call
    /// lowers does not depend on which side of the `-import` its host lives.
    resident_forms: []const Ast.Form = &.{},
    /// Comptime modules only: `ComptimeModule.unsupported_method`.
    unsupported_method: ?*UnsupportedMethod = null,
    /// Locals that may hold `undefined` (null): a parameter declared `?T` or
    /// defaulted to `null`. `if (x)` on one is a null test, not a boolean test.
    /// Reset per function alongside `locals`.
    nullable_locals: std.StringHashMap(void),
    /// Locals statically known to hold a `string`: a parameter declared `string`
    /// or a `val`/`var` bound to a string expression. Feeds `isStringExpr`, which
    /// decides whether `+` is binary concatenation or arithmetic. Reset per
    /// function alongside `locals`.
    string_locals: std.StringHashMap(void),
    /// Module-level names that evaluate to a `string`: a `fn` declared
    /// `-> string` and a top-level `val` bound to a string expression (both are
    /// reached as 0-arity/`n`-arity local calls). Module-wide, never reset.
    string_names: std.StringHashMap(void),
    /// Locals statically known to hold a number, with its kind: a parameter
    /// declared with a numeric type, or a `val`/`var` bound to a numeric
    /// expression (`numKind`). Decides `+` (arithmetic vs `'__bp_add'/2`) and
    /// `/` (`div` vs `/`). Reset per function alongside `locals`.
    num_locals: std.StringHashMapUnmanaged(NumKind) = .empty,
    /// Module-level names answering a number: a `fn` declared with a numeric
    /// return type, a top-level `val` bound to a numeric expression.
    num_names: std.StringHashMapUnmanaged(NumKind) = .empty,
    /// Set when a typed `+` fell back to `'__bp_add'/2`.
    needs_add_helper: bool = false,
    /// §A5 annotation-driven prim-method dispatch: `<Iface>.<method>` →
    /// `(host module, host symbol, ordered arg names)` parsed from
    /// `@external(erlang, "mod", "sym(args)")` on a primitive interface method.
    /// Populated by `collectPrimErlangDispatch`. `primMethodNode` consults this
    /// map FIRST and emits `mod:sym(...)` with the args rendered in the template
    /// order (`self` resolves to the receiver expression); the inline allow-list
    /// catches irreducible cases (list ops, custom comparisons, BIF aliases).
    prim_erlang_dispatch: std.StringHashMap(PrimErlangCall),
    /// `prim-op-annotation` builtin dispatch: top-level `fn` callees from
    /// `builtins.d.bp` carrying `@external(erlang, …)` annotations, keyed by
    /// callee name (`todo`, `panic`, …). `builtinAnnotationNode` consults
    /// this map before the hardcoded `@todo`/`@panic`/`@block`/`@print`
    /// switches in `if (cc.is_builtin)`.
    builtin_erlang_dispatch: std.StringHashMap(PrimErlangCall),
    /// Parent-interface edges parsed from `primitives.d.bp`:
    /// `prim_iface_chain.get("I32")` → `"Signed"`, etc. Used by
    /// `primAnnotationNode`'s `PrimIfaceWalker` so a method declared on
    /// `Integer` lights up via an `I32` receiver. Populated by
    /// `collectPrimErlangDispatch` alongside the dispatch map.
    prim_iface_chain: std.StringHashMap([]const u8),
    /// Set of `<RecordType>.<method>` keys whose method name collides with
    /// at least one other record's method of the same arity. Emitted as
    /// the mangled top-level fn `<recordtype>_<method>(Self, args)`; the
    /// call site (when the receiver's `.record` lowering names `<tn>` and
    /// `(<tn>, callee)` is in this set) routes to the mangled name. Empty
    /// means no collision detected — every record method stays bare.
    /// Populated by `collectRecordMethodCollisions` before any emit.
    record_method_collisions: std.StringHashMap(void),
    /// Set when a lowering called `'__bp_text'/1` (a string `+` operand that
    /// is not provably a string). A typed module then emits `text_helper_form`;
    /// a comptime module always carries it.
    needs_text_helper: bool = false,
    /// Set when `@print`/`@println`/`@debug` lowered to `'__bp_print'/1`; the
    /// module then emits `print_helper_form`.
    needs_print_helper: bool = false,
    /// Set when a typed-module field read fell back to `'__bp_len'/2`.
    needs_len_helper: bool = false,
    /// `name/arity` of every function this module defines by name — top-level
    /// fns, record/enum methods, extension methods. A value-receiver call with
    /// no recorded lowering stays the bare local call when one of these answers
    /// it, and dispatches on the receiver at runtime otherwise.
    local_fn_arities: std.StringHashMapUnmanaged(void) = .empty,

    fn init(alloc: std.mem.Allocator, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        return .{
            .cv = cv,
            .alloc = alloc,
            .rewrites = rewrites,
            .ext_names = std.StringHashMap(void).init(alloc),
            .externals = std.StringHashMap(ast.ExternalRef).init(alloc),
            .externals_missing = std.StringHashMap(void).init(alloc),
            .std_imports = std.StringHashMap(void).init(alloc),
            .record_fields = std.StringHashMap([]const []const u8).init(alloc),
            .enum_names = std.StringHashMap(void).init(alloc),
            .enum_variants = std.StringHashMap(void).init(alloc),
            .imported_types = std.StringHashMap([]const u8).init(alloc),
            .imported_fns = std.StringHashMap([]const u8).init(alloc),
            .fn_typed_fields = std.StringHashMap(void).init(alloc),
            .fn_typed_field_names = std.StringHashMap(void).init(alloc),
            .locals = std.StringHashMap(void).init(alloc),
            .var_current = std.StringHashMap(u32).init(alloc),
            .var_next = std.StringHashMap(u32).init(alloc),
            .top_vals = std.StringHashMap(void).init(alloc),
            .interface_assoc = std.StringHashMap(void).init(alloc),
            .iface_instance_defaults = std.StringHashMap(IfaceDefault).init(alloc),
            .local_behaviors = std.StringHashMap(ast.BehaviorDecl).init(alloc),
            .adopted_defaults = std.StringHashMap(void).init(alloc),
            .iface_self_returns = std.StringHashMap(void).init(alloc),
            .nullable_locals = std.StringHashMap(void).init(alloc),
            .string_locals = std.StringHashMap(void).init(alloc),
            .string_names = std.StringHashMap(void).init(alloc),
            .prim_erlang_dispatch = std.StringHashMap(PrimErlangCall).init(alloc),
            .builtin_erlang_dispatch = std.StringHashMap(PrimErlangCall).init(alloc),
            .user_erlang_templates = std.StringHashMap(PrimErlangCall).init(alloc),
            .prim_iface_chain = std.StringHashMap([]const u8).init(alloc),
            .record_method_collisions = std.StringHashMap(void).init(alloc),
        };
    }

    /// Pre-pass: detect record/struct method names that appear on more than
    /// one nominal type with the same arity. Those collisions get mangled
    /// at emit time (`Query.count` → `query_count`) and at the call site
    /// (`.type_ => |"Query"|` of `count` routes to `query_count`),
    /// because erlang's top-level fn namespace has no record-scoped
    /// disambiguation.
    fn collectRecordMethodCollisions(this: *Emitter, program: ast.Program) !void {
        var arena = std.heap.ArenaAllocator.init(this.alloc);
        defer arena.deinit();
        const aa = arena.allocator();
        // First pass: map (method, arity) → first type that declares it.
        // A second occurrence triggers collision recording for BOTH the
        // existing entry's type and the new type.
        const FirstOf = struct { type_name: []const u8 };
        var seen = std.StringHashMap(FirstOf).init(aa);
        for (program.decls) |decl| {
            const type_name: []const u8 = switch (decl) {
                .type_ => |r| if (r.isRecord()) r.name else continue,
                else => continue,
            };
            const methods: []const ast.BehaviorMethod = switch (decl) {
                .type_ => |r| if (r.isRecord()) r.methods else continue,
                else => continue,
            };
            for (methods) |m| {
                if (m.is_declare) continue;
                if (m.params.len == 0) continue;
                if (!std.mem.eql(u8, m.params[0].name, "self")) continue;
                const key = try std.fmt.allocPrint(aa, "{s}/{d}", .{ m.name, m.params.len });
                if (seen.get(key)) |first| {
                    try this.recordCollision(first.type_name, m.name);
                    try this.recordCollision(type_name, m.name);
                } else {
                    try seen.put(key, .{ .type_name = type_name });
                }
            }
        }
    }

    fn recordCollision(this: *Emitter, type_name: []const u8, method: []const u8) !void {
        const key = try std.fmt.allocPrint(this.alloc, "{s}.{s}", .{ type_name, method });
        const gop = try this.record_method_collisions.getOrPut(key);
        if (gop.found_existing) this.alloc.free(key);
    }

    /// Mangle a record method as `<lowercased-typename>_<method>`. Mirrors
    /// `interfaceAssocAtom`'s shape so the resulting atom is unquoted-safe
    /// when the type name's first char is alphabetic.
    fn recordMethodAtom(buf: []u8, type_name: []const u8, method: []const u8) ![]const u8 {
        if (type_name.len == 0) return std.fmt.bufPrint(buf, "{s}", .{method});
        return std.fmt.bufPrint(buf, "{c}{s}_{s}", .{ std.ascii.toLower(type_name[0]), type_name[1..], method });
    }

    /// True when `(type_name, method)` lives in the collision set (the
    /// mangled name is required both at emit and at call site).
    fn isRecordMethodCollision(this: *const Emitter, type_name: []const u8, method: []const u8) bool {
        var b: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ type_name, method }) catch return false;
        return this.record_method_collisions.contains(key);
    }

    /// `prim-op-annotation`: index top-level `fn` decls in `builtins.d.bp`
    /// carrying `@external(erlang, …)` — the dispatch map is keyed by the bare
    /// callee name (`todo`, `panic`, …). `builtinAnnotationNode` consults
    /// this in the `if (cc.is_builtin)` branch before the hardcoded switches.
    ///
    /// `libs/std/src/builtins.d.bp` is the *documented* surface and is not
    /// strictly parseable, so we seed the dispatch with `panic` / `todo`
    /// inline (matching the documented `@external(erlang, when(argc == N))`
    /// template) and then attempt the file parse best-effort to pick up any
    /// other entries that happen to parse.
    fn collectBuiltinErlangDispatch(this: *Emitter) !void {
        try this.registerInlineBuiltinErlangDispatch();
        // Scan `builtins_fns.d.bp` for top-level `declare fn` with
        // `#[@External.Erlang]` / `#[@External.Node]` annotations.
        try this.scanDeclareFnExternal("erlang", prelude.builtins);
        // Also scan `primitives.bp` so helpers like `stringSlice0`/`stringSlice1`
        // are discovered — the `default fn slice(...)` wrapper calls them.
        try this.scanDeclareFnExternal("erlang", prelude.primitives);
    }

    /// Scan `src` (embedded .bp source) for top-level `declare fn` carrying
    /// `#[@External.<Target>]` annotations. Registers single-template entries
    /// (no arity branches) in `builtin_erlang_dispatch`. Arity-branched entries
    /// are NOT handled here — those go through `registerInlineBuiltinErlangDispatch`.
    fn scanDeclareFnExternal(this: *Emitter, target: []const u8, src: []const u8) !void {
        var arena = std.heap.ArenaAllocator.init(this.alloc);
        defer arena.deinit();
        const alloc_arena = arena.allocator();
        var lx = lexerMod.Lexer.init(src);
        const tokens = lx.scanAll(alloc_arena) catch return;
        var p = parserMod.Parser.init(tokens);
        var program = p.parse(alloc_arena) catch return;
        defer program.deinit(alloc_arena);
        for (program.decls) |decl| {
            if (decl != .@"fn") continue;
            const f = decl.@"fn";
            if (this.builtin_erlang_dispatch.contains(f.name)) continue;
            const ref = f.externalFor(target) orelse continue;
            if (primOpTemplate.looksLikeTemplate(ref.symbol)) {
                try this.builtin_erlang_dispatch.put(try this.alloc.dupe(u8, f.name), .{
                    .module = "",
                    .symbol = try this.alloc.dupe(u8, ref.symbol),
                    .args = null,
                    .arity_branches = &.{},
                });
            }
        }
    }

    /// Seeds `builtin_erlang_dispatch` with the `panic` / `todo` entries from
    /// the documented `builtins.d.bp` surface (which itself is not strictly
    /// parseable). Templates mirror the file's `@external(erlang, when(argc
    /// == N))` clauses byte-for-byte.
    fn registerInlineBuiltinErlangDispatch(this: *Emitter) !void {
        try this.putInlineErlangBuiltin("todo", &.{
            .{ .argc = 0, .template = "erlang:error({todo, \"not implemented\"})" },
            .{ .argc = 1, .template = "erlang:error({todo, $0})" },
        });
        try this.putInlineErlangBuiltin("panic", &.{
            .{ .argc = 0, .template = "erlang:error({panic, \"panic\"})" },
            .{ .argc = 1, .template = "erlang:error({panic, $0})" },
        });
        // `print`/`println`/`debug` are not templates: they lower to the
        // `'__bp_print'/1` helper (`builtinCallNode`), whatever the prelude's
        // `builtins.d.bp` annotation still spells.
    }

    fn putInlineErlangBuiltin(this: *Emitter, name: []const u8, branches: []const ast.ArityBranch) !void {
        if (this.builtin_erlang_dispatch.contains(name)) return;
        const owned = try this.alloc.alloc(ast.ArityBranch, branches.len);
        for (branches, 0..) |b, i| {
            owned[i] = .{
                .argc = b.argc,
                .template = try this.alloc.dupe(u8, b.template),
            };
        }
        try this.builtin_erlang_dispatch.put(try this.alloc.dupe(u8, name), .{
            .module = "",
            .symbol = "",
            .args = null,
            .arity_branches = owned,
        });
    }

    /// A `@builtin(...)` call rendered from its `@external(erlang, …)` template,
    /// or null when no template is registered (the caller falls through to
    /// `@block`, the `__bp_*` ops and the plain call).
    fn builtinAnnotationNode(this: *Emitter, b: Ast.Builder, callee: []const u8, cc: anytype) anyerror!?Ast.Expr {
        const call = this.builtin_erlang_dispatch.get(callee) orelse return null;
        const template = templateFor(call, cc) orelse return null;
        return try this.templateNode(b, template, null, cc, error.PrimOpRecvInBuiltinTemplate);
    }

    /// A bare call to a std prelude `declare fn` whose `@External.Erlang` symbol
    /// is a template (`stringSlice1(self, start, end)` →
    /// `string:slice(Self, Start, (End - Start))`). The declaration's first
    /// parameter is named `self`, so the template's receiver marker (the source's `$0`) is the call's
    /// FIRST positional argument and `$N` the (N+1)-th — unlike a method call,
    /// where the receiver marker is the receiver. Null when the callee has no template.
    fn preludeHelperNode(this: *Emitter, b: Ast.Builder, callee: []const u8, cc: anytype) anyerror!?Ast.Expr {
        const call = this.builtin_erlang_dispatch.get(callee) orelse return null;
        if (cc.args.len == 0) return null;
        const shifted = .{ .args = cc.args[1..], .trailing = cc.trailing };
        const template = templateFor(call, shifted) orelse return null;
        return try this.templateNode(b, template, cc.args[0].value, shifted, error.PrimOpRecvInBuiltinTemplate);
    }

    /// The template an annotation renders for this call site: the arity branch
    /// matching its argument count, or the single `$`-bearing symbol.
    fn templateFor(call: PrimErlangCall, cc: anytype) ?[]const u8 {
        if (call.arity_branches.len > 0) {
            const argc = cc.args.len + cc.trailing.len;
            for (call.arity_branches) |branch| {
                if (branch.argc == argc) return branch.template;
            }
            return null;
        }
        return if (primOpTemplate.looksLikeTemplate(call.symbol)) call.symbol else null;
    }

    /// A host template (`comptime/primOpTemplate.zig`) as a `seq` node: the
    /// template text is kept verbatim around the receiver and argument
    /// (`$N`, `$args`) nodes. `no_recv` is raised when the template names
    /// the receiver but the call has no receiver.
    fn templateNode(this: *Emitter, b: Ast.Builder, template: []const u8, recv: ?*const ast.Expr, cc: anytype, no_recv: anyerror) anyerror!Ast.Expr {
        const Ctx = struct {
            self: *Emitter,
            b: Ast.Builder,
            recv: ?*const ast.Expr,
            cc_ref: @TypeOf(cc),
            argc: usize,
            no_recv: anyerror,
            parts: std.ArrayListUnmanaged(Ast.Expr) = .empty,
            text: std.ArrayListUnmanaged(u8) = .empty,
            /// `parts` lengths at each open `$stringify(`.
            stringify_marks: std.ArrayListUnmanaged(usize) = .empty,

            fn flush(c: *@This()) anyerror!void {
                if (c.text.items.len == 0) return;
                try c.parts.append(c.b.arena, Ast.Expr.r(try c.text.toOwnedSlice(c.b.arena)));
            }
            pub fn writeByte(c: *@This(), ch: u8) anyerror!void {
                try c.text.append(c.b.arena, ch);
            }
            pub fn writeAll(c: *@This(), s: []const u8) anyerror!void {
                try c.text.appendSlice(c.b.arena, s);
            }
            pub fn emitRecv(c: *@This()) anyerror!void {
                const r = c.recv orelse return c.no_recv;
                try c.flush();
                try c.parts.append(c.b.arena, try c.self.exprNode(c.b, r.*));
            }
            pub fn emitArg(c: *@This(), i: usize) anyerror!void {
                try c.flush();
                try c.parts.append(c.b.arena, try c.self.argNode(c.b, c.cc_ref, i));
            }
            /// `$stringify(<inner>)`: the parts `<inner>` renders become the
            /// argument of the compiler's own any-value-as-text call node,
            /// `iolist_to_binary(io_lib:format("~p", [Inner]))` — not template
            /// text, which stays the author's only.
            pub fn emitStringifyOpen(c: *@This()) anyerror!void {
                try c.flush();
                try c.stringify_marks.append(c.b.arena, c.parts.items.len);
            }
            pub fn emitStringifyClose(c: *@This()) anyerror!void {
                try c.flush();
                const mark = c.stringify_marks.pop() orelse return error.PrimOpStringifyMalformed;
                const inner_parts = try c.b.arena.dupe(Ast.Expr, c.parts.items[mark..]);
                c.parts.shrinkRetainingCapacity(mark);
                const inner: Ast.Expr = if (inner_parts.len == 1) inner_parts[0] else .{ .seq = inner_parts };
                const format = try c.b.remote("io_lib", "format", &.{ .{ .string = "~p" }, try c.b.list(&.{inner}) });
                try c.parts.append(c.b.arena, try c.b.call("iolist_to_binary", &.{format}));
            }
        };
        var ctx = Ctx{ .self = this, .b = b, .recv = recv, .cc_ref = cc, .argc = cc.args.len + cc.trailing.len, .no_recv = no_recv };
        try primOpTemplate.render(template, &ctx);
        try ctx.flush();
        return .{ .seq = ctx.parts.items };
    }

    /// §A5: index interface methods carrying `@external(erlang, "mod", "sym[(args)]")`
    /// — the lookup key is `<Iface>.<method>` so the prim-method dispatch can find
    /// it without re-scanning. The symbol/args are owned by the emitter's
    /// allocator so they outlive the parser arena (the original annotation lexemes
    /// would survive, but the parsed arg list lives on a scratch buffer).
    fn collectPrimErlangDispatch(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| {
            if (decl != .behavior) continue;
            try this.collectIfaceErlangDispatch(decl.behavior);
            try this.collectIfaceExtendsChain(decl.behavior);
        }
        // Reparse `primitives.d.bp` from the embedded prelude so the dispatch
        // map sees `String`/`Bool`/numeric interfaces even when the module
        // didn't get them stubbed into `program.decls` (they're only stubbed
        // for `default fn` stdlib lib dispatch — host-backed instance methods
        // like `s.toUpper()` don't trip that path). The parse is per-emit and
        // throwaway; we keep only the (iface, method, external-ref) triples we
        // need by deep-copying into the emitter's allocator.
        var arena = std.heap.ArenaAllocator.init(this.alloc);
        defer arena.deinit();
        const alloc_arena = arena.allocator();
        var lx = lexerMod.Lexer.init(prelude.primitives);
        const tokens = lx.scanAll(alloc_arena) catch return;
        var p = parserMod.Parser.init(tokens);
        var prim_program = p.parse(alloc_arena) catch return;
        defer prim_program.deinit(alloc_arena);
        for (prim_program.decls) |decl| {
            if (decl != .behavior) continue;
            try this.collectIfaceErlangDispatch(decl.behavior);
            try this.collectIfaceExtendsChain(decl.behavior);
        }
    }

    /// Record `iface.extends[0]` as the parent for `iface` in
    /// `prim_iface_chain` so `primAnnotationNode`'s walker can climb
    /// `I32 → Signed → Integer → Number`. First-write-wins (the parse of
    /// `program.decls` lands before the embedded `primitives.d.bp`
    /// re-parse). We only record the first parent — multi-inheritance is
    /// not used by `primitives.d.bp` at v1.
    fn collectIfaceExtendsChain(this: *Emitter, iface: ast.BehaviorDecl) !void {
        if (iface.extends.len == 0) return;
        if (this.prim_iface_chain.contains(iface.name)) return;
        const child = try this.alloc.dupe(u8, iface.name);
        const parent = try this.alloc.dupe(u8, iface.extends[0]);
        try this.prim_iface_chain.put(child, parent);
    }

    /// Collect the `@external(erlang, …)` annotations on one interface's
    /// methods. Caller is the dispatch builder; this both handles the
    /// `program.decls` interfaces and the reparsed `primitives.d.bp` ones with
    /// the same shape. A key already present wins on first-write (the in-program
    /// decl overrides the embedded primitive — useful for tests that shadow a
    /// stdlib interface to inject a custom dispatch).
    fn collectIfaceErlangDispatch(this: *Emitter, iface: ast.BehaviorDecl) !void {
        var slots: [16][]const u8 = undefined;
        for (iface.methods) |m| {
            // `prim-op-annotation` arity-branch form takes precedence: when the
            // method's `@external(erlang, …)` carries one or more
            // `when($argc == N): "..."` clauses, store every branch and skip
            // the ref read (arity-branch annotations may carry 3+ args).
            if (ast.externalHasArityBranches(m.annotations, "erlang")) {
                if (hasExternalInline(m.annotations, "erlang")) continue;
                const key = try std.fmt.allocPrint(this.alloc, "{s}.{s}", .{ iface.name, m.name });
                if (this.prim_erlang_dispatch.contains(key)) {
                    this.alloc.free(key);
                    continue;
                }
                var branches: std.ArrayList(ast.ArityBranch) = .empty;
                errdefer branches.deinit(this.alloc);
                for (m.annotations) |a| {
                    if (!std.mem.startsWith(u8, a.name, "External.") or !std.ascii.eqlIgnoreCase(a.name["External.".len..], "erlang")) continue;
                    for (a.args) |raw| {
                        const b = ast.parseArityBranchArg(raw) orelse continue;
                        try branches.append(this.alloc, .{
                            .argc = b.argc,
                            .template = try this.alloc.dupe(u8, b.template),
                        });
                    }
                }
                try this.prim_erlang_dispatch.put(key, .{
                    .module = "",
                    .symbol = "",
                    .args = null,
                    .arity_branches = try branches.toOwnedSlice(this.alloc),
                });
                continue;
            }
            const ref = m.externalFor("erlang") orelse continue;
            if (hasExternalInline(m.annotations, "erlang")) continue;
            const key = try std.fmt.allocPrint(this.alloc, "{s}.{s}", .{ iface.name, m.name });
            if (this.prim_erlang_dispatch.contains(key)) {
                this.alloc.free(key);
                continue;
            }
            // `prim-op-annotation` template form: a `$`-bearing symbol is a raw
            // template body — store it verbatim and skip `parseExternalCallTemplate`
            // (which would interpret `($0 ++ $1)` as a `f(arg)` shape with an
            // empty head and one bogus arg). `primAnnotationNode` runs the same
            // `looksLikeTemplate` discriminator and renders via
            // `comptime/primOpTemplate.zig`.
            if (primOpTemplate.looksLikeTemplate(ref.symbol)) {
                try this.prim_erlang_dispatch.put(key, .{
                    .module = "",
                    .symbol = try this.alloc.dupe(u8, ref.symbol),
                    .args = null,
                });
                continue;
            }
            const tmpl = ast.parseExternalCallTemplate(ref.symbol, &slots);
            const owned_args: ?[][]const u8 = if (tmpl.args) |args| blk: {
                const out = try this.alloc.alloc([]const u8, args.len);
                for (args, 0..) |a, i| out[i] = try this.alloc.dupe(u8, a);
                break :blk out;
            } else null;
            try this.prim_erlang_dispatch.put(key, .{
                .module = try this.alloc.dupe(u8, ref.module),
                .symbol = try this.alloc.dupe(u8, tmpl.symbol),
                .args = owned_args,
            });
        }
    }

    /// A primitive method call rendered from its `@external(erlang, …)`
    /// annotation, or null when none is registered for `<iface>.<method>`
    /// (callers fall through to the inline lowerings for irreducible cases).
    /// `primIfaceForKind` maps a `PrimKind` to its interface (`.array` →
    /// `"Array"`), and the `extends` chain is walked so a method declared on a
    /// parent interface (`Integer.toString` from an `I32` receiver) resolves.
    fn primAnnotationNode(this: *Emitter, b: Ast.Builder, k: envMod.PrimKind, callee: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!?Ast.Expr {
        const head_iface = primIfaceForKind(k) orelse return null;
        var iface_walk = PrimIfaceWalker.init(this, head_iface, &this.prim_iface_chain);
        const call = while (iface_walk.next()) |iface_name| {
            var key_buf: [128]u8 = undefined;
            const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ iface_name, callee }) catch return null;
            if (this.prim_erlang_dispatch.get(key)) |hit| break hit;
        } else return null;
        // Arity-branched (`when($argc == N): "…"`) or single-string template:
        // The receiver marker ⇒ the receiver, `$N` ⇒ the N-th argument (the
        // parser translated the source's positional markers, decision 5). An arity-branched
        // annotation with no branch for this argument count falls through.
        if (call.arity_branches.len > 0 or primOpTemplate.looksLikeTemplate(call.symbol)) {
            const template = templateFor(call, cc) orelse return null;
            return try this.templateNode(b, template, recv, cc, error.PrimOpRecvMissing);
        }
        var args: std.ArrayListUnmanaged(Ast.Expr) = .empty;
        if (call.args) |names| {
            // Template order: `self` ⇒ the receiver; any other slot ⇒ the next
            // positional argument (the parser drops `@external(…)` arg labels,
            // so the binding is positional, in source order).
            var next_arg: usize = 0;
            for (names) |name| {
                if (std.mem.eql(u8, name, "self")) {
                    try args.append(b.arena, try this.exprNode(b, recv.*));
                } else {
                    try args.append(b.arena, try this.argNode(b, cc, next_arg));
                    next_arg += 1;
                }
            }
        } else {
            // Bare symbol — declaration order: `self`, then the positional args.
            try args.append(b.arena, try this.exprNode(b, recv.*));
            for (cc.args) |arg| try args.append(b.arena, try this.exprNode(b, arg.value.*));
        }
        return try b.remote(call.module, call.symbol, args.items);
    }

    /// §A2 erlang twin: a top-level user `declare fn` whose `@external(erlang, …)`
    /// annotation is a template (`$0`/`$N`) or arity-branched, rendered at the
    /// call site instead of `module:symbol(args)` (which does not fit
    /// chained-host-call shapes). Null when no template matches.
    fn userTemplateNode(this: *Emitter, b: Ast.Builder, callee: []const u8, cc: anytype) anyerror!?Ast.Expr {
        const call = this.user_erlang_templates.get(callee) orelse return null;
        // A marker-less host expression (module-less 1-arg annotation) is its
        // own template text.
        const template = templateFor(call, cc) orelse
            (if (call.arity_branches.len == 0 and call.symbol.len > 0) call.symbol else return null);
        return try this.templateNode(b, template, null, cc, error.PrimOpRecvInUserTemplate);
    }

    /// Index an interface's bodied `default fn`s by qualified name. Associated
    /// ones (no `self`) land in `interface_assoc` so `Interface.method(...)`
    /// resolves to the bare local fn `interfaceForms` emits; instance ones
    /// (a `self` receiver) land in `iface_instance_defaults` so a value-receiver
    /// call (`xs.all(pred)`) resolves to the `<iface>_<method>(Recv, …)` form
    /// `instanceDefaultForms` emits on demand.
    fn collectInterfaces(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .behavior => |i| {
                try this.local_behaviors.put(i.name, i);
                for (i.methods) |m| {
                    if (m.returnType) |rt| {
                        if (rt == .named and std.mem.eql(u8, rt.named, "Self")) {
                            const sq = try std.fmt.allocPrint(this.alloc, "{s}.{s}", .{ i.name, m.name });
                            try this.iface_self_returns.put(sq, {});
                        }
                    }
                    if (!m.is_default or m.body == null) continue;
                    const has_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
                    const qn = try std.fmt.allocPrint(this.alloc, "{s}.{s}", .{ i.name, m.name });
                    if (has_self) {
                        try this.iface_instance_defaults.put(qn, .{ .iface = i.name, .method = m });
                    } else {
                        try this.interface_assoc.put(qn, {});
                    }
                }
            },
            else => {},
        };
    }

    /// Comptime modules: index the embedded prelude's primitive interfaces the
    /// way `collectInterfaces` indexes a program's — the bodied instance
    /// `default fn`s and the `-> Self` methods — so a shim clause reaches
    /// `String.slice` / `Array.first`. `arena` owns the parsed prelude and must
    /// outlive the emit. A name the program already declares keeps its entry.
    fn collectPreludeInstanceDefaults(this: *Emitter, arena: std.mem.Allocator) !void {
        var lx = lexerMod.Lexer.init(prelude.primitives);
        const tokens = try lx.scanAll(arena);
        var p = parserMod.Parser.init(tokens);
        const prim_program = try p.parse(arena);
        for (prim_program.decls) |decl| {
            if (decl != .behavior) continue;
            const i = decl.behavior;
            for (i.methods) |m| {
                var key_buf: [256]u8 = undefined;
                const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ i.name, m.name }) catch continue;
                if (m.returnType) |rt| {
                    if (rt == .named and std.mem.eql(u8, rt.named, "Self") and !this.iface_self_returns.contains(key)) {
                        try this.iface_self_returns.put(try this.alloc.dupe(u8, key), {});
                    }
                }
                if (!m.is_default or m.body == null) continue;
                if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
                if (this.iface_instance_defaults.contains(key)) continue;
                try this.iface_instance_defaults.put(try this.alloc.dupe(u8, key), .{ .iface = i.name, .method = m });
            }
        }
    }

    /// True for the bare identifier `self`.
    fn isSelfIdent(e: ast.Expr) bool {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| std.mem.eql(u8, n, "self"),
                else => false,
            },
            else => false,
        };
    }

    /// A method call whose receiver is known to be record/enum `tn`: a function
    /// taking the receiver first — local `m(Recv, args)`, or `owner:m(Recv,
    /// args)` for an imported type. A method name shared by two records is
    /// mangled to `<recordtype>_<method>` so the flat fn namespace stays
    /// unambiguous.
    fn typedMethodNode(this: *Emitter, b: Ast.Builder, tn: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!Ast.Expr {
        // A FIELD of function type, called like a method (`c.set(9)` on
        // `type State<T>(value: T, set: fn(next: T))`): the record has no
        // `set/2` function — apply what the field holds.
        if (this.fnTypedField(tn, cc.callee)) {
            return .{ .apply = .{
                .fun = try b.ptr(try b.paren(try b.remote("maps", "get", &.{ Ast.Expr.a(cc.callee), try this.exprNode(b, recv.*) }))),
                .args = try this.callArgs(b, null, cc),
            } };
        }
        var mn_buf: [256]u8 = undefined;
        const mn: []const u8 = if (this.isRecordMethodCollision(tn, cc.callee))
            try b.arena.dupe(u8, try recordMethodAtom(&mn_buf, tn, cc.callee))
        else
            cc.callee;
        const args = try this.callArgs(b, try this.exprNode(b, recv.*), cc);
        return if (this.imported_types.get(tn)) |owner| b.remote(owner, mn, args) else b.call(mn, args);
    }

    /// The name a `implement` clause refers to (`implement Sized`,
    /// `implement Container<T>`); null for a shape that names no behavior.
    fn implementedName(ref: ast.TypeRef) ?[]const u8 {
        return switch (ref) {
            .named => |n| n,
            .generic => |g| g.name,
            else => null,
        };
    }

    /// The bodied instance `default fn`s a record adopts through its inline
    /// `implement` clauses and does not declare itself — the erlang twin of
    /// commonJS's `appendInterfaceDefaults`. Without them the record emitted no
    /// function at all for `bag.isEmpty()`, and the call fell through to the
    /// untyped primitive shim, which aborted at run time with
    /// `{bp_unsupported_method, <<"isEmpty">>, 0, #{items => []}}` while commonJS
    /// answered from the class. Follows `extends`, depth-capped like commonJS's
    /// walker; a method already collected (two behaviors declaring the same
    /// default) is kept once, the first one found.
    fn adoptedIfaceDefaults(
        this: *const Emitter,
        alloc: std.mem.Allocator,
        r: ast.TypeDecl,
        out: *std.ArrayListUnmanaged(ast.BehaviorMethod),
    ) anyerror!void {
        for (r.implement) |ref| {
            const iface_name = implementedName(ref) orelse continue;
            try this.appendIfaceDefaults(alloc, iface_name, r, out, 0);
        }
    }

    fn appendIfaceDefaults(
        this: *const Emitter,
        alloc: std.mem.Allocator,
        iface_name: []const u8,
        r: ast.TypeDecl,
        out: *std.ArrayListUnmanaged(ast.BehaviorMethod),
        depth: usize,
    ) anyerror!void {
        if (depth > 16) return;
        const iface = this.local_behaviors.get(iface_name) orelse return;
        for (iface.methods) |m| {
            if (!m.is_default or m.body == null) continue;
            // An associated `default fn` (no `self`) is already emitted by
            // `interfaceForms` as `<iface>_<method>`; only instance ones become
            // methods of the record.
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            var taken = false;
            for (r.methods) |own| {
                if (std.mem.eql(u8, own.name, m.name)) taken = true;
            }
            for (out.items) |seen| {
                if (std.mem.eql(u8, seen.name, m.name)) taken = true;
            }
            if (taken) continue;
            try out.append(alloc, m);
        }
        for (iface.extends) |parent| try this.appendIfaceDefaults(alloc, parent, r, out, depth + 1);
    }

    fn isInterfaceAssoc(this: *Emitter, iface: []const u8, method: []const u8) bool {
        var b: [256]u8 = undefined;
        const qn = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface, method }) catch return false;
        return this.interface_assoc.contains(qn);
    }

    /// Inverse of `primIfaceForKind`: the primitive kind whose controller
    /// interface reaches `iface` through its `extends` chain. A method declared
    /// on a shared parent (`Number.clamp`) answers `.int` — the chain walk from
    /// either numeric kind passes through `Number`, so the dispatch is the same.
    fn primKindForIface(this: *const Emitter, iface: []const u8) ?envMod.PrimKind {
        for ([_]envMod.PrimKind{ .array, .string, .bool, .int, .float }) |k| {
            const head = primIfaceForKind(k) orelse continue;
            var iface_walk = PrimIfaceWalker.init(this, head, &this.prim_iface_chain);
            while (iface_walk.next()) |name| {
                if (std.mem.eql(u8, name, iface)) return k;
            }
        }
        return null;
    }

    /// The primitive kind of a `Self`-typed expression inside an interface
    /// instance `default fn` body — the `self` parameter, or a call on a
    /// `Self`-typed receiver whose interface method is declared `-> Self`
    /// (`self.filter(pred)` on `Array`). Null everywhere else, including in
    /// every ordinary function, where inference records the lowering instead.
    fn selfPrimKind(this: *const Emitter, e: ast.Expr) ?envMod.PrimKind {
        const k = this.self_prim_kind orelse return null;
        switch (e) {
            .identifier => |id| {
                const name = switch (id.kind) {
                    .ident => |n| n,
                    else => return null,
                };
                return if (std.mem.eql(u8, name, "self")) k else null;
            },
            .call => |c| {
                const cc = switch (c.kind) {
                    .call => |x| x,
                    else => return null,
                };
                if (cc.is_builtin) return null;
                const recv = cc.receiver orelse return null;
                if (this.selfPrimKind(recv.*) == null) return null;
                const head_iface = primIfaceForKind(k) orelse return null;
                var iface_walk = PrimIfaceWalker.init(this, head_iface, &this.prim_iface_chain);
                while (iface_walk.next()) |iface_name| {
                    var key_buf: [256]u8 = undefined;
                    const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ iface_name, cc.callee }) catch return null;
                    if (this.iface_self_returns.contains(key)) return k;
                }
                return null;
            },
            else => return null,
        }
    }

    /// Mark `name` as a function-scoped local (param / `val` / lambda param).
    fn addLocal(this: *Emitter, name: []const u8) void {
        this.locals.put(name, {}) catch {};
        // A fresh binding (param, lambda param, first `val`) shadows any
        // rebound version of the same name.
        _ = this.var_current.remove(name);
    }

    fn resetLocals(this: *Emitter) void {
        this.locals.clearRetainingCapacity();
        this.mutable_locals.clearRetainingCapacity();
        this.mutating_closures.clearRetainingCapacity();
        this.var_current.clearRetainingCapacity();
        this.var_next.clearRetainingCapacity();
        this.nullable_locals.clearRetainingCapacity();
        this.string_locals.clearRetainingCapacity();
        this.num_locals.clearRetainingCapacity();
    }

    /// True when `t` is the `string` primitive.
    fn isStringType(t: ?ast.TypeRef) bool {
        const ty = t orelse return false;
        return ty == .named and std.mem.eql(u8, ty.named, "string");
    }

    /// Index the module-level names that evaluate to a `string`: every `fn`
    /// declared `-> string` and every top-level `val` bound to a string
    /// expression. `isStringExpr` reads it to decide whether `+` is binary
    /// concatenation (`<<A/binary, B/binary>>`) or integer arithmetic.
    fn collectStringNames(this: *Emitter, program: ast.Program) !void {
        // Two passes: a `val` may be initialised by a `fn` declared later.
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (isStringType(f.returnType)) try this.string_names.put(f.name, {});
                if (numTypeKind(f.returnType)) |k| try this.num_names.put(this.alloc, f.name, k);
            },
            else => {},
        };
        for (program.decls) |decl| switch (decl) {
            .val => |v| {
                if (this.isStringExpr(v.value.*)) try this.string_names.put(v.name, {});
                if (this.numKind(v.value.*)) |k| try this.num_names.put(this.alloc, v.name, k);
            },
            else => {},
        };
    }

    /// The start of an open-ended range (`x..`), or null for anything else.
    fn unboundedRangeStart(e: ast.Expr) ?*const ast.Expr {
        if (e != .collection or e.collection.kind != .range) return null;
        const r = e.collection.kind.range;
        if (r.end != null) return null;
        return r.start;
    }

    /// Wraps a loop whose body can `break` in the `try … catch` that catches the
    /// break throw, so the loop ends instead of the exception escaping the
    /// enclosing function. Loops that never break are returned untouched.
    fn loopBreakCatch(this: *Emitter, b: Ast.Builder, loop: Ast.Expr, body: []const ast.Stmt) anyerror!Ast.Expr {
        _ = this;
        if (!hasBareBreak(body)) return loop;
        return .{ .try_catch = .{
            .body = try b.body(&.{loop}),
            .catches = try b.arena.dupe(Ast.Clause, &.{
                try b.clause(
                    &.{.{ .exception = .{ .class = try b.ptr(Ast.Expr.a("throw")), .reason = try b.ptr(Ast.Expr.a(break_signal)) } }},
                    &.{},
                    &.{Ast.Expr.a("ok")},
                ),
            }),
        } };
    }

    /// True when the statements contain a value-less `break` — the form that
    /// leaves the loop rather than producing an element. Walks the `if`/`case`
    /// arms a break is normally guarded by.
    fn hasBareBreak(body: []const ast.Stmt) bool {
        for (body) |stmt| switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"break" => |brk| if (brk.value == null) return true,
                else => {},
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    if (hasBareBreak(i.then_)) return true;
                    if (i.else_) |els| if (hasBareBreak(els)) return true;
                },
                else => {},
            },
            else => {},
        };
        return false;
    }

    /// The `lists:filtermap/2` fun body for a loop whose whole body is one
    /// unconditional `if` (no `else`, no binding form) ending in `break <expr>`:
    /// `case Cond of true -> …, {true, Value}; _ -> false end`. Null for every
    /// other loop, which keeps its `map`/`foreach` lowering.
    fn filterMapFunBody(this: *Emitter, b: Ast.Builder, lp: anytype) anyerror!?Ast.Body {
        if (lp.body.len != 1 or lp.body[0].expr != .branch) return null;
        const br = lp.body[0].expr.branch;
        if (br.kind != .if_) return null;
        const iff = br.kind.if_;
        if (iff.else_ != null or iff.binding != null or iff.then_.len == 0) return null;
        const last = iff.then_[iff.then_.len - 1].expr;
        if (last != .jump or last.jump.kind != .@"break") return null;
        const value = last.jump.kind.@"break".value orelse return null;

        const saved = this.indent;
        this.indent += 2;
        defer this.indent = saved;
        const cond = try this.condNode(b, iff.cond.*);
        var body: std.ArrayListUnmanaged(Ast.Expr) = .empty;
        for (iff.then_[0 .. iff.then_.len - 1]) |stmt| {
            try body.append(b.arena, try this.exprNode(b, stmt.expr));
        }
        try body.append(b.arena, try b.tuple(&.{ Ast.Expr.a("true"), try this.exprNode(b, value.*) }));
        const case = try b.caseOf(cond, &.{
            .{ .patterns = try b.exprs(&.{Ast.Expr.a("true")}), .body = try b.body(body.items) },
            try b.clause(&.{Ast.Expr.v("_")}, &.{}, &.{Ast.Expr.a("false")}),
        });
        this.indent = saved;
        return try b.body(&.{case});
    }

    /// The first index a `loop (xs, <range>)` counts from — `0` for the usual
    /// `0..`, the range's lower bound otherwise.
    fn indexRangeStart(this: *Emitter, b: Ast.Builder, e: ast.Expr) anyerror!Ast.Expr {
        if (e == .collection and e.collection.kind == .range) {
            return this.exprNode(b, e.collection.kind.range.start.*);
        }
        return Ast.Expr.t(Term.int(0));
    }

    /// A bare botopink name as a read: the local variable at its current
    /// version, or the call `name()` when it is a module-level `val`.
    fn nameRefNode(this: *Emitter, b: Ast.Builder, name: []const u8) anyerror!Ast.Expr {
        if (!this.locals.contains(name) and this.top_vals.contains(name)) return b.call(name, &.{});
        return Ast.Expr.v(try this.varRef(b, name));
    }

    /// A string `+` chain as one flat binary construction:
    /// `a + b + c` → `<<"a", (b())/binary, C/binary>>`. Flattening keeps the
    /// nesting out of the emitted module; the segments are collected left to
    /// right so the concatenation order is preserved.
    fn stringConcatNode(this: *Emitter, b: Ast.Builder, e: ast.Expr) anyerror!Ast.Expr {
        var segs: std.ArrayListUnmanaged(Ast.BinSegment) = .empty;
        try this.concatSegments(b, &segs, e);
        return .{ .bin = segs.items };
    }

    fn concatSegments(this: *Emitter, b: Ast.Builder, out: *std.ArrayListUnmanaged(Ast.BinSegment), e: ast.Expr) anyerror!void {
        if (e == .binaryOp and e.binaryOp.op == .add and this.isStringExpr(e)) {
            try this.concatSegments(b, out, e.binaryOp.lhs.*);
            try this.concatSegments(b, out, e.binaryOp.rhs.*);
            return;
        }
        var node = try this.exprNode(b, e);
        // An empty literal contributes nothing (the comptime template builder
        // starts its concat chain from `""`), so it is dropped rather than
        // written as a `""` segment.
        if (node == .lexeme_binary and node.lexeme_binary.len == 0) return;
        // A `/binary` segment takes a binary only: `"value: " + v` with `v: i32`
        // raised `badarg`. An operand not provably a string goes through
        // `'__bp_text'/1` — itself when it is a binary at runtime, its `~p`
        // rendering otherwise — so an unproven string still concatenates as text.
        if (!this.isStringExpr(e)) {
            this.needs_text_helper = true;
            node = try b.call("__bp_text", &.{node});
        }
        // A binary segment only takes a "simple" expression bare; anything else
        // — a call, a `case`, an arithmetic term — has to be parenthesised.
        const value: Ast.Expr = switch (node) {
            .variable, .lexeme_binary, .paren => node,
            .term => |t| if (t == .binary) node else .{ .paren = try b.ptr(node) },
            else => .{ .paren = try b.ptr(node) },
        };
        try out.append(b.arena, .{ .value = value, .type = "binary" });
    }

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

    /// The numeric kind `e` statically has, or null when it cannot be proven
    /// (`.number` when it is a number of unknown precision):
    /// a number literal (a float when it has a `.` or an exponent), a numeric
    /// local/parameter/module name, a length read, and arithmetic over them (a
    /// float operand makes a float; `%` is an integer).
    fn numKind(this: *const Emitter, e: ast.Expr) ?NumKind {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (std.mem.startsWith(u8, n, "0x") or std.mem.startsWith(u8, n, "0b") or std.mem.startsWith(u8, n, "0o"))
                    .int
                else if (std.mem.indexOfAny(u8, n, ".eE") != null) .float else .int,
                else => null,
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| this.num_locals.get(n) orelse
                    (if (!this.locals.contains(n)) this.num_names.get(n) else null),
                .identAccess => if (this.instance_lowerings.get(id.loc)) |il| switch (il) {
                    .prim => .int,
                    .type_ => null,
                } else null,
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| this.numKind(inner.*),
                else => null,
            },
            .unaryOp => |un| if (un.op == .neg) this.numKind(un.expr.*) else null,
            .binaryOp => |bin| switch (bin.op) {
                .add => if (this.isStringExpr(e)) null else combineNum(this.numKind(bin.lhs.*), this.numKind(bin.rhs.*)),
                // `-`, `*` and `/` only ever answer a number in erlang.
                .sub, .mul, .div => combineNum(this.numKind(bin.lhs.*), this.numKind(bin.rhs.*)) orelse .number,
                .mod => .int,
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| if (cc.receiver == null and !cc.is_builtin and !this.locals.contains(cc.callee)) this.num_names.get(cc.callee) else null,
                else => null,
            },
            else => null,
        };
    }

    fn combineNum(a: ?NumKind, b: ?NumKind) ?NumKind {
        if (a == .float or b == .float) return .float;
        if (a == .int and b == .int) return .int;
        if (a != null or b != null) return .number;
        return null;
    }

    /// True when `e` is statically a botopink `string`, so a `+` over it is
    /// binary concatenation and not arithmetic. Conservative: anything it cannot
    /// prove stays arithmetic, which is the pre-existing behaviour.
    fn isStringExpr(this: *const Emitter, e: ast.Expr) bool {
        return switch (e) {
            .literal => |lit| lit.kind == .stringLit or lit.kind == .stringTemplate,
            .binaryOp => |bin| bin.op == .add and
                (this.isStringExpr(bin.lhs.*) or this.isStringExpr(bin.rhs.*)),
            .identifier => |id| switch (id.kind) {
                .ident => |n| this.string_locals.contains(n) or
                    (!this.locals.contains(n) and this.string_names.contains(n)),
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| cc.receiver == null and this.string_names.contains(cc.callee),
                else => false,
            },
            else => false,
        };
    }

    /// The Erlang variable for a read of `name` at its current version
    /// (`Count` or `Count@2`), spelled once in the builder's arena.
    fn varRef(this: *Emitter, b: Ast.Builder, name: []const u8) ![]const u8 {
        return this.versionedVar(b, name, this.var_current.get(name) orelse 0);
    }

    /// `Name` for version 0, `Name@N` otherwise, in the builder's arena.
    fn versionedVar(this: *Emitter, b: Ast.Builder, name: []const u8, version: u32) ![]const u8 {
        _ = this;
        const base = try erlEmitter.varName(b.arena, name);
        if (version == 0) return base;
        return std.fmt.allocPrint(b.arena, "{s}@{d}", .{ base, version });
    }

    const BindOp = enum { bind, assign, plus_assign };

    /// `Name = Value` for `val`/`var` declarations and `=`/`+=` assignments.
    /// The first binding of a name in the function keeps the bare variable; any
    /// later binding — assignment or a shadowing `val i = i - 1` — binds the next
    /// version, with `value` (and the `+=` left operand) reading the previous one.
    fn bindExpr(this: *Emitter, b: Ast.Builder, name: []const u8, op: BindOp, value: ast.Expr) anyerror!Ast.Expr {
        // Remember string-valued bindings so a later `+` on them concatenates.
        if (op != .plus_assign and this.isStringExpr(value)) try this.string_locals.put(name, {});
        if (op != .plus_assign) {
            if (this.numKind(value)) |k| try this.num_locals.put(this.alloc, name, k);
        }
        if (!this.locals.contains(name)) {
            const vname = Ast.Expr.v(try this.arenaVar(b, name));
            this.addLocal(name);
            return b.match(vname, try this.exprNode(b, value));
        }
        const version = (this.var_next.get(name) orelse 0) + 1;
        const target = Ast.Expr.v(try this.versionedVar(b, name, version));
        const rhs: Ast.Expr = if (op == .plus_assign) blk: {
            const old_var = Ast.Expr.v(try this.varRef(b, name));
            // `s += x` on a string concatenates; on a number it adds; on a
            // name of unknown type it dispatches at runtime.
            if (!this.untyped and (this.string_locals.contains(name) or this.isStringExpr(value))) {
                var segs: std.ArrayListUnmanaged(Ast.BinSegment) = .empty;
                try segs.append(b.arena, .{ .value = old_var, .type = "binary" });
                try this.concatSegments(b, &segs, value);
                break :blk .{ .bin = segs.items };
            }
            const addend = try this.exprNode(b, value);
            if (this.untyped or (!this.num_locals.contains(name) and this.numKind(value) == null)) {
                if (!this.untyped) this.needs_add_helper = true;
                break :blk try b.call("__bp_add", &.{ old_var, addend });
            }
            break :blk .{ .binop = .{ .op = "+", .lhs = try b.ptr(old_var), .rhs = try b.ptr(addend), .parens = false } };
        } else try this.exprNode(b, value);
        try this.var_next.put(name, version);
        try this.var_current.put(name, version);
        return b.match(target, rhs);
    }

    /// Indexes record/struct field orders + enum names for constructor-call,
    /// field-access, and enum-member lowering.
    fn collectTypeShapes(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => {
                    var names = try self.alloc.alloc([]const u8, tdecl.recordFields().len);
                    for (tdecl.recordFields(), 0..) |f, i| names[i] = f.name;
                    try self.record_fields.put(tdecl.name, names);
                    // A field of function type is CALLED like a method
                    // (`c.set(9)`), and the record emits no `set/2`: remember
                    // the pair so the call applies the field's value.
                    for (tdecl.recordFields()) |f| {
                        if (f.typeRef != .function) continue;
                        var key_buf: [256]u8 = undefined;
                        const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ tdecl.name, f.name }) catch continue;
                        try self.fn_typed_fields.put(try self.alloc.dupe(u8, key), {});
                        try self.fn_typed_field_names.put(f.name, {});
                    }
                },
                .enum_ => {
                    try self.enum_names.put(tdecl.name, {});
                    for (tdecl.variants()) |v| try self.enum_variants.put(v.name, {});
                },
            },
            else => {},
        };
    }

    /// Registers types this module imports `from "<pkg>"` (resolved via the
    /// cross-module index). An imported record/struct joins `record_fields` so a
    /// construction (`App(8080, "/")`) inlines the same `#{…}` map the owner
    /// would build, and `imported_types` so an associated-fn call
    /// (`Response.ok(...)`) lowers to a remote call into the owner module.
    /// Imported enums join `enum_names` (their tagged-tuple / atom shape is
    /// module-independent). No-op without a cross index (standalone path).
    fn collectImportedTypes(self: *Emitter, program: ast.Program) !void {
        // An imported enum's variants join `enum_variants`, so a case pattern
        // naming one is the atom (`'Gt'`), not a fresh variable that matches
        // anything. The enum arrives by name (`import {Order}`) or with its
        // module (`import {order} from "std"` brings `std/order`'s enums).
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const name = imp.segments[imp.segments.len - 1];
                for (self.enum_exports) |ee| {
                    if (std.mem.eql(u8, ee.module, self.module_name)) continue;
                    if (!std.mem.eql(u8, ee.name, name) and !std.mem.eql(u8, crossModule.moduleBasename(ee.module), name)) continue;
                    for (ee.variants) |v| try self.enum_variants.put(v.name, {});
                }
            },
            else => {},
        };
        const xc = self.cross orelse return;
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const name = imp.name();
                const info = xc.exports.get(name) orelse {
                    // Not a `pub` symbol: the import names a MODULE
                    // (`import {dict} from "std"`, a sibling `import {geometry}`).
                    try self.collectNamespaceModuleTypes(xc, name);
                    continue;
                };
                switch (info.kind) {
                    .record => {
                        // Records are maps at runtime, so the consumer inlines
                        // the same `#{field => V}` literal the owner would build
                        // — there is no constructor function to call remotely.
                        if (!self.record_fields.contains(name)) {
                            try self.record_fields.put(name, try self.alloc.dupe([]const u8, info.fields));
                        }
                        try self.imported_types.put(name, crossModule.moduleBasename(info.module));
                    },
                    .@"enum" => try self.enum_names.put(name, {}),
                    .@"fn", .val => {},
                }
                // Names this module calls but never defines: an imported
                // `pub fn` (`twice(X)`) and the methods of an imported
                // record/enum (`stub.thenReturn(v)`, emitted by the owner as a
                // bare function taking the receiver first). Erlang resolves a
                // bare call in the calling module, so the call site needs the
                // owner atom; a local definition of the same name wins.
                if (std.mem.eql(u8, info.module, self.module_name)) continue;
                const owner = crossModule.moduleBasename(info.module);
                switch (info.kind) {
                    // An FFI declaration with an `erlang` target is answered in
                    // its owner by the wrapper `externalWrapperForm` emits, so
                    // it is reached like any other imported fn. Without a target
                    // the owner has nothing to wrap: the call stays bare, and an
                    // unresolved one is a loud erlc error naming the function
                    // (see AGENTS.md).
                    .@"fn" => if (!info.is_external or info.erlang_backed) try self.imported_fns.put(name, owner),
                    .record, .@"enum" => for (info.methods) |m| {
                        const gop = try self.imported_fns.getOrPut(m);
                        if (!gop.found_existing) gop.value_ptr.* = owner;
                    },
                    .val => {},
                }
                // A method may belong to a type the consumer never names
                // (`when(...)` answers onze's `OnzeStub`, whose `thenReturn` is
                // called on the result): register the methods of every pub type
                // of a module this one already imports from.
                var ex_it = xc.exports.iterator();
                while (ex_it.next()) |e| {
                    const other = e.value_ptr.*;
                    if (!std.mem.eql(u8, other.module, info.module)) continue;
                    if (other.kind != .record and other.kind != .@"enum") continue;
                    for (other.methods) |m| {
                        const gop = try self.imported_fns.getOrPut(m);
                        if (!gop.found_existing) gop.value_ptr.* = owner;
                    }
                }
            },
            else => {},
        };
    }

    /// A `use` name that is not a `pub` symbol but the basename of a module some
    /// export comes from: `import {dict} from "std"` binds the MODULE `std/dict`,
    /// not a declaration. The consumer then reaches the module's types only
    /// through its functions (`dict.empty()` answers a `Dict`) and never names
    /// `Dict` itself, so the `.record`/`.@"enum"` branches above never ran and a
    /// method call on the answered value fell through to a bare local call
    /// (`insert(D, K, V)` → `function insert/3 undefined`). Register the module's
    /// pub types the same way an explicitly imported one is registered: the type
    /// name for an associated call and a typed method call, every method name for
    /// a call site inference left untyped. `record_fields` is deliberately left
    /// alone — a consumer that constructs the record has to import it by name,
    /// which is the branch above.
    fn collectNamespaceModuleTypes(self: *Emitter, xc: *const CrossModule, ns: []const u8) !void {
        var it = xc.exports.iterator();
        while (it.next()) |e| {
            const info = e.value_ptr.*;
            if (info.kind != .record and info.kind != .@"enum") continue;
            if (!std.mem.eql(u8, crossModule.moduleBasename(info.module), ns)) continue;
            if (std.mem.eql(u8, info.module, self.module_name)) continue;
            const owner = crossModule.moduleBasename(info.module);
            if (info.kind == .record) try self.imported_types.put(e.key_ptr.*, owner);
            for (info.methods) |m| {
                const gop = try self.imported_fns.getOrPut(m);
                if (!gop.found_existing) gop.value_ptr.* = owner;
            }
        }
    }

    /// Owning module atom of an imported function called with `arity`
    /// arguments, or null when this module defines one of that name and arity
    /// itself (a local definition shadows the import, as it does in botopink).
    fn importedFnOwner(self: *const Emitter, name: []const u8, arity: usize) ?[]const u8 {
        const owner = self.imported_fns.get(name) orelse return null;
        var key_buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&key_buf, "{s}/{d}", .{ name, arity }) catch return owner;
        return if (self.local_fn_arities.contains(key)) null else owner;
    }

    /// True when record `type_name` declares a field `name` of function type —
    /// `c.set(9)` applies the field, it does not call a `set/2` the record never
    /// emits.
    fn fnTypedField(this: *const Emitter, type_name: []const u8, name: []const u8) bool {
        var key_buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ type_name, name }) catch return false;
        return this.fn_typed_fields.contains(key);
    }

    /// True when some record of the module declares a field named `name`.
    fn isRecordField(self: *const Emitter, name: []const u8) bool {
        var it = self.record_fields.valueIterator();
        while (it.next()) |fields| for (fields.*) |f| if (std.mem.eql(u8, f, name)) return true;
        return false;
    }

    /// Index `local_fn_arities`: every function the module emits under its own
    /// name, with its Erlang arity.
    fn collectLocalFnArities(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| try self.putLocalFn(f.name, fnArityNoSelf(f)),
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => for (tdecl.methods) |m| try self.putLocalFn(m.name, m.params.len),
                .enum_ => for (tdecl.methods) |m| try self.putLocalFn(m.name, m.params.len),
            },
            .implement => |im| for (im.methods) |m| try self.putLocalFn(m.name, m.params.len),
            .extend => |ex| for (ex.methods) |m| try self.putLocalFn(m.name, m.params.len),
            else => {},
        };
    }

    /// Decide which adopted instance `default fn`s each record emits, and index
    /// them as local functions. Runs after `collectLocalFnArities`, so
    /// `local_fn_arities` already names every top-level fn and every record /
    /// enum method: an adopted default whose `<name>/<arity>` is taken there is
    /// skipped, because erlang's flat namespace would double-define it and the
    /// call site has no lowering to disambiguate with (the receiver's type is
    /// exactly what inference does not record for an adopted default). Skipping
    /// leaves that call on the untyped primitive shim, i.e. unchanged.
    ///
    /// Two records adopting the SAME default are skipped together, not resolved
    /// first-wins: with one `isEmpty/1` emitted, every untyped call site would
    /// reach that one record's body and read fields the other receiver does not
    /// have. A module with several implementors of one behavior therefore keeps
    /// today's run-time abort until inference types such a receiver (06 N15).
    fn collectAdoptedIfaceDefaults(self: *Emitter, program: ast.Program) !void {
        var arena = std.heap.ArenaAllocator.init(self.alloc);
        defer arena.deinit();
        const aa = arena.allocator();
        // Pass 1: how many records would claim each `<name>/<arity>`.
        var claims = std.StringHashMap(usize).init(aa);
        for (program.decls) |decl| switch (decl) {
            .type_ => |r| {
                if (!r.isRecord()) continue;
                var adopted: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
                try self.adoptedIfaceDefaults(aa, r, &adopted);
                for (adopted.items) |m| {
                    const key = try std.fmt.allocPrint(aa, "{s}/{d}", .{ m.name, m.params.len });
                    const gop = try claims.getOrPut(key);
                    gop.value_ptr.* = if (gop.found_existing) gop.value_ptr.* + 1 else 1;
                }
            },
            else => {},
        };
        // Pass 2: emit the unambiguous ones.
        for (program.decls) |decl| switch (decl) {
            .type_ => |r| {
                if (!r.isRecord()) continue;
                var adopted: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
                try self.adoptedIfaceDefaults(aa, r, &adopted);
                for (adopted.items) |m| {
                    var key_buf: [256]u8 = undefined;
                    const arity_key = std.fmt.bufPrint(&key_buf, "{s}/{d}", .{ m.name, m.params.len }) catch continue;
                    if (self.local_fn_arities.contains(arity_key)) continue;
                    if ((claims.get(arity_key) orelse 0) != 1) continue;
                    try self.putLocalFn(m.name, m.params.len);
                    const key = try std.fmt.allocPrint(self.alloc, "{s}.{s}", .{ r.name, m.name });
                    const gop = try self.adopted_defaults.getOrPut(key);
                    if (gop.found_existing) self.alloc.free(key);
                }
            },
            else => {},
        };
    }

    /// True when `recordForms` emits `method` for `type_name` as an adopted
    /// interface `default fn` (see `collectAdoptedIfaceDefaults`).
    fn emitsAdoptedDefault(this: *const Emitter, type_name: []const u8, method: []const u8) bool {
        var b: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&b, "{s}.{s}", .{ type_name, method }) catch return false;
        return this.adopted_defaults.contains(key);
    }

    fn putLocalFn(self: *Emitter, name: []const u8, arity: usize) !void {
        const key = try std.fmt.allocPrint(self.alloc, "{s}/{d}", .{ name, arity });
        const gop = try self.local_fn_arities.getOrPut(self.alloc, key);
        if (gop.found_existing) self.alloc.free(key);
    }

    /// Records every module name imported from the "std" package.
    fn collectStdImports(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .use => |u| {
                const from_std = switch (u.source) {
                    .module => |m| std.mem.eql(u8, m, "std"),
                    .root => false,
                };
                if (!from_std) continue;
                for (u.imports) |imp| {
                    try this.std_imports.put(imp.segments[imp.segments.len - 1], {});
                }
            },
            else => {},
        };
    }

    fn collectExtensionNames(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .implement => |im| try this.ext_names.put(im.name, {}),
            .extend => |ex| try this.ext_names.put(ex.name, {}),
            else => {},
        };
    }

    /// Indexes every `@[external(…)]` fn by name: with an `erlang` target it
    /// goes to `externals`; without one it goes to `externals_missing` (so a
    /// call can fail with a clear error instead of an undefined function).
    /// An `@External.Erlang("…")` template, owned by the emitter. The annotation
    /// argument is the string literal's raw LEXEME, so a quote inside the Erlang
    /// text is still written botopink-escaped (`io_lib:format(\"~p\", …)`) — it
    /// is emitted verbatim into the `.erl`, where the backslash would start an
    /// unterminated string. Resolve `\"` to `"`; every other escape belongs to
    /// the Erlang source the template carries and passes through untouched.
    fn dupeTemplate(this: *Emitter, s: []const u8) ![]const u8 {
        if (std.mem.indexOf(u8, s, "\\\"") == null) return this.alloc.dupe(u8, s);
        var out: std.ArrayListUnmanaged(u8) = .empty;
        errdefer out.deinit(this.alloc);
        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            if (s[i] == '\\' and i + 1 < s.len and s[i + 1] == '"') continue;
            try out.append(this.alloc, s[i]);
        }
        return out.toOwnedSlice(this.alloc);
    }

    fn collectExternals(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (!f.isExternal()) continue;
                // §A2 arity-branched template (`when(argc == N): "<tmpl>"`)
                // on a top-level declare fn — the existing
                // interface-method `primAnnotationNode` path already
                // handles primitives.d.bp; this map covers
                // top-level user `declare fn`s so chained-host-call
                // shapes (`file:get_cwd()`, `os:getpid()`, etc.) can
                // lower without aliasing.
                if (ast.externalHasArityBranches(f.annotations, "erlang")) {
                    var branches: std.ArrayList(ast.ArityBranch) = .empty;
                    errdefer branches.deinit(this.alloc);
                    for (f.annotations) |a| {
                        if (!std.mem.startsWith(u8, a.name, "External.") or !std.ascii.eqlIgnoreCase(a.name["External.".len..], "erlang")) continue;
                        for (a.args) |raw| {
                            const b = ast.parseArityBranchArg(raw) orelse continue;
                            try branches.append(this.alloc, .{
                                .argc = b.argc,
                                .template = try this.dupeTemplate(b.template),
                            });
                        }
                    }
                    try this.user_erlang_templates.put(try this.alloc.dupe(u8, f.name), .{
                        .module = "",
                        .symbol = "",
                        .args = null,
                        .arity_branches = try branches.toOwnedSlice(this.alloc),
                    });
                    continue;
                }
                if (f.externalFor("erlang")) |ref| {
                    // §A2 single-template form (`"$0.method(...)"`,
                    // `"erlang:something($0, $1)"` with `$` markers) — the
                    // symbol carries `$` → render at the call site, never
                    // emit `module:symbol`. A 1-arg form without markers
                    // (`"list_to_integer(os:getpid())"`) names no module: it is
                    // a bare host expression and renders verbatim too — as a
                    // `module:symbol` call it came out `:expr()()`.
                    if (primOpTemplate.looksLikeTemplate(ref.symbol) or ref.module.len == 0) {
                        try this.user_erlang_templates.put(try this.alloc.dupe(u8, f.name), .{
                            .module = "",
                            .symbol = try this.dupeTemplate(ref.symbol),
                            .args = null,
                        });
                        continue;
                    }
                    try this.externals.put(f.name, ref);
                } else {
                    try this.externals_missing.put(f.name, {});
                }
            },
            else => {},
        };
    }

    // ── top-level val ─────────────────────────────────────────────────────────

    /// A module-level `val` is a 0-arity function. A comptime one keeps its
    /// `%% comptime val x` header and carries the FOLDED value as its body —
    /// the comment alone left every reader of the name unbound.
    fn topValForms(this: *Emitter, b: Ast.Builder, out: *Forms, v: ast.ValDecl) !void {
        if (v.value.isComptimeExpr()) {
            try out.append(b.arena, .{ .comment = Ast.Comment.doc(try std.fmt.allocPrint(b.arena, "comptime val {s}", .{v.name})) });
        }
        const saved = this.indent;
        this.indent = 1;
        defer this.indent = saved;
        // A 0-arity function is its own variable scope.
        this.resetLocals();
        // A comptime block is the function body itself: its statements, then
        // its `break` value.
        if (v.value.* == .comptime_ and v.value.comptime_.kind == .comptimeBlock) {
            const body = try this.comptimeBlockBody(b, v.value.comptime_.kind.comptimeBlock.body, 1);
            return out.append(b.arena, try blockFunction(b, v.name, &.{}, body));
        }
        try out.append(b.arena, try blockFunction(b, v.name, &.{}, try b.body(&.{try this.exprNode(b, v.value.*)})));
    }

    /// A runtime module-level `val` inside `'_botopink_main'/0`: `Name = Value`,
    /// or the bare value for a synthetic `_`-named statement.
    fn topValEntryExpr(this: *Emitter, b: Ast.Builder, v: ast.ValDecl) !Ast.Expr {
        if (std.mem.startsWith(u8, v.name, "_")) return this.exprNode(b, v.value.*);
        const name = Ast.Expr.v(try this.arenaVar(b, v.name));
        return b.match(name, try this.exprNode(b, v.value.*));
    }

    // ── fn ────────────────────────────────────────────────────────────────────

    /// True when the body is a flat sequence of `yield` statements (a simple
    /// finite generator that lowers to an eager Erlang list).
    fn isPlainYieldGenerator(f: ast.FnDecl) bool {
        if (f.effect == null or f.body.len == 0) return false;
        for (f.body) |stmt| {
            if (!(stmt.expr == .jump and stmt.expr.jump.kind == .yield)) return false;
        }
        return true;
    }

    fn fnForms(this: *Emitter, b: Ast.Builder, out: *Forms, f: ast.FnDecl) !void {
        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. Erlang is eager: a `@Future<T>`
        // resolves to `T` (so `await` is identity) and a finite `@Iterator<T>`
        // is a list.
        if (f.effect != null and f.effect.? != .result) {
            try out.append(b.arena, .{ .comment = Ast.Comment.doc("#[@future] / #[@asyncGenerator] — eager lowering") });
        }
        // Fresh local scope for this function (erlang vars are function-scoped).
        this.resetLocals();
        var params: std.ArrayListUnmanaged(Ast.Expr) = .empty;
        for (f.params) |p| {
            if (p.destruct) |d| switch (d) {
                // `destructPatternExpr` binds each name as a local.
                .names, .tuple_ => try params.append(b.arena, try this.destructPatternExpr(b, d)),
                // List / constructor parameter patterns are not lowered yet.
                .list, .ctor => {},
            } else if (this.keep_self or !std.mem.eql(u8, p.name, "self")) {
                try params.append(b.arena, Ast.Expr.v(try this.arenaVar(b, p.name)));
                this.addLocal(p.name);
                if (isNullableParam(p)) try this.nullable_locals.put(p.name, {});
                if (isStringType(p.typeRef)) try this.string_locals.put(p.name, {});
                if (numTypeKind(p.typeRef)) |k| try this.num_locals.put(this.alloc, p.name, k);
            }
        }
        const saved = this.indent;
        this.indent = 1;
        defer this.indent = saved;
        this.try_seq = 0;
        const body: Ast.Body = if (isPlainYieldGenerator(f)) blk: {
            // Finite generator → eager list of yielded items: `[V1, V2, ...]`.
            const items = try b.arena.alloc(Ast.Expr, f.body.len);
            for (f.body, 0..) |stmt, i| {
                // A bare `yield;` yields no value: `undefined`, botopink's null.
                items[i] = if (stmt.expr.jump.kind.yield.value) |val| try this.exprNode(b, val.*) else Ast.Expr.a("undefined");
            }
            break :blk try b.body(&.{.{ .list = items }});
        } else try this.bodyNode(b, f.body, 0, 1);
        try out.append(b.arena, try blockFunction(b, f.name, params.items, body));
    }

    /// A `test { … }` body as `'__bp_test_<idx>'() -> Body.`, registered with
    /// the runner.
    fn testFunction(this: *Emitter, b: Ast.Builder, t: ast.TestDecl, idx: usize) !Ast.Form {
        this.resetLocals();
        const saved = this.indent;
        this.indent = 1;
        defer this.indent = saved;
        this.try_seq = 0;
        const name = try std.fmt.allocPrint(b.arena, "__bp_test_{d}", .{idx});
        return blockFunction(b, name, &.{}, try this.bodyNode(b, t.body, 0, 1));
    }

    /// `try expr` (no catch) at body position → propagate `{error, E}` by nesting
    /// the rest of the body inside the `{ok, V}` arm. Returns the inner expr.
    fn propagateTryInner(e: ast.Expr) ?ast.Expr {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .try_ => |t| if (t) |i| i.* else null,
                else => null,
            },
            else => null,
        };
    }

    /// The statements `body[start..]` as an `erl_ast` body rendered at `indent`.
    ///
    /// A `try` without `catch` short-circuits: it lowers to
    /// `case Inner of {ok, V} -> <rest>; {error, E} -> {error, E} end`, nesting
    /// every following statement inside the Ok arm (Erlang has no early return),
    /// so the Error variant propagates up as the function's value. An `if` whose
    /// then-branch ends in `return` nests the rest in its false arm the same way.
    fn bodyNode(this: *Emitter, b: Ast.Builder, body: []const ast.Stmt, start: usize, indent: usize) anyerror!Ast.Body {
        const saved_indent = this.indent;
        this.indent = indent;
        defer this.indent = saved_indent;

        var stmts: std.ArrayListUnmanaged(Ast.Stmt) = .empty;
        // The body's tail (last value) keys off the last *real* statement, so
        // trailing comments never become the tail.
        const last_real = lastRealStmt(body);
        var i = start;
        while (i < body.len) : (i += 1) {
            const stmt = body[i];
            const is_last = if (last_real) |lr| (i == lr) else (i == body.len - 1);

            // `[val name =] try inner` (no catch) at this position.
            const prop: ?struct { inner: ast.Expr, head: TryHead } = switch (stmt.expr) {
                .binding => |bind| switch (bind.kind) {
                    .localBind => |lb| if (propagateTryInner(lb.value.*)) |inner|
                        .{ .inner = inner, .head = .{ .name = lb.name } }
                    else
                        null,
                    .localBindDestruct => |lb| if (propagateTryInner(lb.value.*)) |inner|
                        .{ .inner = inner, .head = .{ .destruct = lb.pattern } }
                    else
                        null,
                    else => null,
                },
                .jump => |j| switch (j.kind) {
                    .try_ => |t| if (t) |inner|
                        .{ .inner = inner.*, .head = .none }
                    else
                        null,
                    .@"return" => |r| if (r) |rv| if (propagateTryInner(rv.*)) |inner|
                        .{ .inner = inner, .head = .none }
                    else
                        null else null,
                    else => null,
                },
                else => null,
            };
            if (prop) |p| {
                try stmts.append(b.arena, .{ .expr = try this.propagateTryExpr(b, body, i, p.inner, p.head) });
                break; // remaining statements are nested inside the Ok arm
            }

            if (!is_last and stmt.expr == .branch and stmt.expr.branch.kind == .if_) {
                const if_node = stmt.expr.branch.kind.if_;
                if (if_node.else_ == null and bodyEndsWithReturn(if_node.then_)) {
                    try stmts.append(b.arena, .{ .expr = try this.earlyReturnIfExpr(b, body, i, if_node) });
                    break; // remaining statements are nested inside the false arm
                }
            }

            // `var acc = init;` + `recv.forEach({ p -> <mutate acc> })`: fuse
            // into a single `lists:foldl` (Erlang closures can't rebind a
            // captured var). Consumes both statements.
            if (!is_last) {
                if (this.detectFoldFusion(body, i)) |ff| {
                    try stmts.append(b.arena, .{ .expr = try this.foldFusionExpr(b, ff) });
                    i += 1; // also consume the forEach statement
                    continue;
                }
            }

            // `val assert P = e [catch h];` — its bindings are read by the
            // statements after it, so the pattern is matched in the enclosing
            // clause, not inside the `case` (a name bound by a single `case`
            // clause is "unsafe" after it).
            if (this.assertPatternBindingStmt(stmt)) |ap| {
                try stmts.appendSlice(b.arena, try this.assertPatternStmts(b, ap, stmt.expr.comptime_.loc));
                continue;
            }

            if (sourceComment(stmt)) |c| {
                try stmts.append(b.arena, .{ .comment = c });
            } else if (try this.mutatingExpr(b, stmt)) |mutation| {
                try stmts.append(b.arena, .{ .expr = mutation });
            } else {
                try stmts.append(b.arena, .{ .expr = try this.stmtExpr(b, stmt) });
            }
        }
        return .{ .stmts = stmts.items };
    }

    /// The `val assert` at `stmt` whose pattern binds at least one name, or
    /// null. A pattern that binds nothing (`val assert 42 = answer catch 0;`)
    /// is a pure check and keeps the single-expression lowering.
    fn assertPatternBindingStmt(this: *const Emitter, stmt: ast.Stmt) ?@FieldType(@FieldType(ast.ComptimeExpr, "kind"), "assertPattern") {
        if (stmt.expr != .comptime_) return null;
        if (stmt.expr.comptime_.kind != .assertPattern) return null;
        const ap = stmt.expr.comptime_.kind.assertPattern;
        const isVariant = struct {
            fn f(e: *const Emitter, name: []const u8) bool {
                return e.enum_variants.contains(name);
            }
        }.f;
        if (!patternFacts.bindsNames(ap.pattern, this, isVariant)) return null;
        return ap;
    }

    /// `val assert P = e [catch h];` at statement position, when `P` binds at
    /// least one name:
    ///
    /// ```erlang
    /// BpAssert0 = Subject,
    /// P = case BpAssert0 of P' -> BpAssert0; _ -> Handler end
    /// ```
    ///
    /// The `case` only decides *which* value the statement yields — the
    /// subject when it matched, the handler's value otherwise (for the
    /// handler-less form the handler is the `@panic(…)` the parser desugars
    /// to, so a mismatch is fatal). The outer match is what binds, in the
    /// enclosing clause where the following statements can read it: a name
    /// bound by a single `case` clause is "unsafe" in erlang after the case.
    /// `P'` is the same pattern lowered first, so `patternBindVar` gives it the
    /// earlier version of each name and the outer `P` the current one.
    ///
    /// The subject is staged in `BpAssert<n>` because the arm used to re-emit
    /// it — `case parse(X) of {ok, N} -> parse(X); …` called `parse/1` twice.
    fn assertPatternStmts(this: *Emitter, b: Ast.Builder, ap: anytype, loc: ast.Loc) anyerror![]const Ast.Stmt {
        const tmp = try std.fmt.allocPrint(b.arena, "BpAssert{d}_{d}", .{ loc.line, loc.col });
        const subject = try this.exprNode(b, ap.expr.*);
        this.pattern_discard = true;
        const check = try this.patternNode(b, ap.pattern);
        this.pattern_discard = false;
        const handler = try this.exprNode(b, ap.handler.*);
        const decided = try b.caseInline(Ast.Expr.v(tmp), &.{
            try b.clause(&.{check}, &.{}, &.{Ast.Expr.v(tmp)}),
            try b.clause(&.{Ast.Expr.v("_")}, &.{}, &.{handler}),
        });
        const bind = try this.patternNode(b, ap.pattern);
        const stmts = try b.arena.alloc(Ast.Stmt, 2);
        stmts[0] = .{ .expr = try b.match(Ast.Expr.v(tmp), subject) };
        stmts[1] = .{ .expr = try b.match(bind, decided) };
        return stmts;
    }

    /// Match `var acc = init;` at `body[i]` immediately followed by
    /// `recv.forEach({ p -> … })` at `body[i+1]` whose lambda body only mutates
    /// `acc`. Returns the fusion plan, or `null` if the shape doesn't match.
    fn detectFoldFusion(this: *Emitter, body: []const ast.Stmt, i: usize) ?FoldFusion {
        _ = this;
        if (i + 1 >= body.len) return null;

        const bind = switch (body[i].expr) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| lb,
                else => return null,
            },
            else => return null,
        };
        if (!bind.mutable) return null;

        const cc = switch (body[i + 1].expr) {
            .call => |c| switch (c.kind) {
                .call => |call| call,
                else => return null,
            },
            else => return null,
        };
        if (cc.receiver == null) return null;
        if (!std.mem.eql(u8, cc.callee, "forEach")) return null;

        // The action lambda may arrive as a parenthesized arg (`forEach({…})`)
        // or as a trailing block (`forEach { … }`).
        var lam_params: []const []const u8 = undefined;
        var lam_body: []const ast.Stmt = undefined;
        if (cc.args.len == 1 and cc.trailing.len == 0) {
            switch (cc.args[0].value.*) {
                .function => |fe| {
                    lam_params = fe.kind.params;
                    lam_body = fe.kind.body;
                },
                else => return null,
            }
        } else if (cc.args.len == 0 and cc.trailing.len == 1) {
            lam_params = cc.trailing[0].params;
            lam_body = cc.trailing[0].body;
        } else return null;
        if (lam_params.len != 1) return null;
        if (lam_body.len != 1) return null;

        const bk = classifyFoldStmt(lam_body[0], bind.name) orelse return null;
        return .{
            .acc_name = bind.name,
            .init = bind.value,
            .recv = cc.receiver.?,
            .param = lam_params[0],
            .body_kind = bk,
        };
    }

    /// `Acc = lists:foldl(fun(P, Acc) -> <body> end, Init, Recv)`. The
    /// accumulator reuses its source name as the fun's second parameter so the
    /// body's reads of `acc` resolve to the per-iteration value.
    fn foldFusionExpr(this: *Emitter, b: Ast.Builder, ff: FoldFusion) anyerror!Ast.Expr {
        const acc_var = Ast.Expr.v(try this.arenaVar(b, ff.acc_name));
        const p_var = Ast.Expr.v(try this.arenaVar(b, ff.param));
        this.addLocal(ff.acc_name);
        try this.mutable_locals.put(this.alloc, ff.acc_name, {});
        this.addLocal(ff.param);
        const saved = this.indent;
        this.indent = saved + 1;
        const fold_body = try this.foldBodyExpr(b, ff.body_kind, acc_var);
        this.indent = saved;
        const fold = try b.remote("lists", "foldl", &.{
            .{ .fun = .{ .params = try b.exprs(&.{ p_var, acc_var }), .body = try b.body(&.{fold_body}) } },
            try this.exprNode(b, ff.init.*),
            try this.exprNode(b, ff.recv.*),
        });
        return b.match(acc_var, fold);
    }

    fn foldBodyExpr(this: *Emitter, b: Ast.Builder, bk: FoldBodyKind, acc_var: Ast.Expr) anyerror!Ast.Expr {
        return switch (bk) {
            .assign => |e| this.exprNode(b, e.*),
            .plus_assign => |e| b.binop("+", acc_var, try this.exprNode(b, e.*)),
            .push => |e| b.binop("++", acc_var, try b.list(&.{try this.exprNode(b, e.*)})),
            .if_assign => |ia| blk: {
                const cond = try this.exprNode(b, ia.cond.*);
                this.indent += 1;
                defer this.indent -= 1;
                const then_val = try this.exprNode(b, ia.then_val.*);
                const else_val = if (ia.else_val) |ev| try this.exprNode(b, ev.*) else acc_var;
                break :blk b.caseOf(cond, &.{
                    try b.clause(&.{Ast.Expr.a("true")}, &.{}, &.{then_val}),
                    try b.clause(&.{Ast.Expr.v("_")}, &.{}, &.{else_val}),
                });
            },
        };
    }

    // ── mutation through branches and loops ──────────────────────────────────
    //
    // Erlang variables are immutable and a binding made inside a `case` arm or a
    // `fun` is not visible after it, so a statement-level `if` / `loop` /
    // `forEach` that reassigns variables bound before it is lowered to an
    // expression that *returns* the new values:
    //
    //   if (c) { acc = acc + 1; }          Acc@1 = case C of true -> Acc@2 = …, Acc@2; _ -> Acc end
    //   loop (xs) { x -> acc = acc + x; }  Acc@3 = lists:foldl(fun(X, Acc@1) -> Acc@2 = …, Acc@2 end, Acc, Xs)
    //
    // Several reassigned variables travel as a tuple. The names are the ones
    // already bound in the function (`locals`) that the statement assigns,
    // looking through nested `if`/`loop`/`forEach` bodies.

    /// `stmt` through the mutation-returning shapes above when it reassigns
    /// outer variables, or null.
    fn mutatingExpr(this: *Emitter, b: Ast.Builder, stmt: ast.Stmt) anyerror!?Ast.Expr {
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        switch (stmt.expr) {
            .branch => |br| switch (br.kind) {
                .if_ => |if_node| {
                    if (bodyEndsWithReturn(if_node.then_)) return null;
                    if (if_node.else_) |els| if (bodyEndsWithReturn(els)) return null;
                    try this.collectMutations(b.arena, if_node.then_, &.{}, &names);
                    if (if_node.else_) |els| try this.collectMutations(b.arena, els, &.{}, &names);
                    if (if_node.binding) |bn| removeName(&names, bn);
                    if (names.items.len == 0) return null;
                    return try this.mutatingIfExpr(b, if_node, names.items);
                },
                else => return null,
            },
            .loop => |lp| {
                if (lp.condition) {
                    try this.collectMutations(b.arena, lp.body, &.{}, &names);
                    if (names.items.len == 0) return null;
                    return try this.conditionLoopNode(b, lp, names.items);
                }
                // One loop parameter, or two — `loop (xs) { x, i -> … }` /
                // `loop (xs, 0..) { … }` — whose second one is the index.
                if (lp.params.len == 0 or lp.params.len > 2 or lp.awaitLoop) return null;
                if (lp.indexRange != null and lp.params.len != 2) return null;
                for (lp.body) |s| if (s.expr == .jump and s.expr.jump.kind == .yield) return null;
                try this.collectMutations(b.arena, lp.body, lp.params, &names);
                if (names.items.len == 0) return null;
                const index: ?FoldIndex = if (lp.params.len == 2) .{ .name = lp.params[1], .range = lp.indexRange } else null;
                return try this.mutatingFoldExpr(b, lp.params[0], index, lp.body, lp.iter.*, names.items);
            },
            .binding => |bind| switch (bind.kind) {
                .localBind => |lb| {
                    if (lb.value.* != .function or this.locals.contains(lb.name)) return null;
                    const fe = lb.value.function;
                    try this.collectMutations(b.arena, fe.kind.body, fe.kind.params, &names);
                    if (names.items.len == 0) return null;
                    if (lb.mutable) try this.mutable_locals.put(this.alloc, lb.name, {});
                    return try this.mutatingClosureExpr(b, lb.name, fe.kind.params, fe.kind.body, names.items);
                },
                else => return null,
            },
            .call => {
                // `emit(x)` on a closure that reassigns outer variables rebinds
                // them from what it answers: `Tokens@2 = Emit(X, Tokens@1)`.
                if (this.closureMutation(stmt.expr)) |cm| {
                    var args: std.ArrayListUnmanaged(Ast.Expr) = .empty;
                    try args.appendSlice(b.arena, try this.callArgs(b, null, cm.cc));
                    try args.append(b.arena, try this.varGroupExpr(b, cm.names));
                    const call: Ast.Expr = .{ .apply = .{
                        .fun = try b.ptr(try this.nameRefNode(b, cm.cc.callee)),
                        .args = args.items,
                    } };
                    return try b.match(try this.bindVarGroupExpr(b, cm.names), call);
                }
                // `out.push(x)` rebinds `out`: `Out@1 = (Out ++ [X])`, so a
                // group-out expression after it reads the grown list.
                if (this.receiverMutation(stmt.expr)) |name| {
                    return try this.bindExpr(b, name, .assign, stmt.expr);
                }
                const each = forEachLambda(stmt.expr) orelse return null;
                try this.collectMutations(b.arena, each.body, each.params, &names);
                if (names.items.len == 0) return null;
                return try this.mutatingFoldExpr(b, each.params[0], null, each.body, each.recv.*, names.items);
            },
            else => return null,
        }
    }

    /// The local a statement-position call mutates through its receiver —
    /// `out.push(x)` on a `var out` — or null. The receiver must be an Array
    /// (the inferred `.prim = .array` lowering; in a comptime body any receiver,
    /// whose shim answers `push` for lists only), so the call's value is the
    /// grown list. A parameter or a field access (`self.items.push(x)`) keeps
    /// the plain lowering: rebinding it could not reach the caller anyway.
    fn receiverMutation(this: *const Emitter, e: ast.Expr) ?[]const u8 {
        if (e != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        if (cc.is_builtin or !std.mem.eql(u8, cc.callee, "push")) return null;
        if (cc.args.len + cc.trailing.len != 1) return null;
        const name = identName((cc.receiver orelse return null).*) orelse return null;
        if (!this.locals.contains(name) or !this.mutable_locals.contains(name)) return null;
        if (this.untyped) return name;
        const il = this.instance_lowerings.get(e.call.loc) orelse return null;
        return switch (il) {
            .prim => |k| if (k == .array) name else null,
            .type_ => null,
        };
    }

    /// A condition loop (decision 8 §10) as a named fun that tests, runs the
    /// body and recurses:
    ///
    ///     Group' = (fun __Loop(GroupIn) -> case Cond of true -> Body, __Loop(GroupOut);
    ///                                                   _ -> GroupIn end end)(Group)
    ///
    /// The variables the body reassigns (`names`) travel as the fun's parameter
    /// and come back as its value; with none the fun takes nothing and answers
    /// `ok`. A `break` throws `{__bp_cond_break, Group}` at its versions, caught
    /// around the call; a `continue` throws `{__bp_cond_continue, Group}`, caught
    /// around the body so the recursion carries on.
    fn conditionLoopNode(this: *Emitter, b: Ast.Builder, lp: anytype, names: []const []const u8) anyerror!Ast.Expr {
        const fun_name = if (this.cond_loop_seq == 0) loop_fun_var else try std.fmt.allocPrint(b.arena, "{s}{d}", .{ loop_fun_var, this.cond_loop_seq });
        this.cond_loop_seq += 1;
        defer this.cond_loop_seq -= 1;
        const saved_ctx = this.cond_loop;
        this.cond_loop = names;
        defer this.cond_loop = saved_ctx;

        this.cond_loop_vars += 1;
        const caught_var = try std.fmt.allocPrint(b.arena, "__BpGroup{d}", .{this.cond_loop_vars});
        var snapshot = try this.var_current.clone();
        defer snapshot.deinit();
        const group_in: ?Ast.Expr = if (names.len > 0) try this.bindVarGroupExpr(b, names) else null;
        var in_versions = try this.var_current.clone();
        defer in_versions.deinit();
        const arm_indent = this.indent + 3;
        const saved = this.indent;
        this.indent = arm_indent;
        const cond = try this.condNode(b, lp.iter.*);
        this.indent = saved;

        const body_stmts = (try this.bodyNode(b, lp.body, 0, arm_indent)).stmts;
        const group_out = if (group_in != null) try this.varGroupExpr(b, names) else Ast.Expr.a("ok");
        var arm: std.ArrayListUnmanaged(Ast.Stmt) = .empty;
        const next: Ast.Expr = if (hasJump(lp.body, .@"continue")) blk: {
            var tried: std.ArrayListUnmanaged(Ast.Stmt) = .empty;
            try tried.appendSlice(b.arena, body_stmts);
            try tried.append(b.arena, .{ .expr = group_out });
            break :blk .{ .try_catch = .{
                .body = .{ .stmts = tried.items },
                .catches = try b.arena.dupe(Ast.Clause, &.{try b.clause(
                    &.{try b.exception(Ast.Expr.a("throw"), try b.tuple(&.{ Ast.Expr.a(cond_continue_signal), Ast.Expr.v(caught_var) }))},
                    &.{},
                    &.{Ast.Expr.v(caught_var)},
                )}),
            } };
        } else blk: {
            try arm.appendSlice(b.arena, body_stmts);
            break :blk group_out;
        };
        try arm.append(b.arena, .{ .expr = .{ .apply = .{
            .fun = try b.ptr(Ast.Expr.v(fun_name)),
            .args = if (group_in != null) try b.exprs(&.{next}) else &.{},
        } } });
        if (group_in == null and next == .try_catch) {
            // No group to carry: run the guarded body for its effects, then recurse.
            arm.items[arm.items.len - 1] = .{ .expr = .{ .apply = .{ .fun = try b.ptr(Ast.Expr.v(fun_name)), .args = &.{} } } };
            try arm.insert(b.arena, arm.items.len - 1, .{ .expr = next });
        }
        try this.restoreVersions(&in_versions);
        const done = if (group_in) |_| try this.varGroupExpr(b, names) else Ast.Expr.a("ok");
        try this.restoreVersions(&snapshot);
        const case = try b.caseOf(cond, &.{
            .{ .patterns = try b.exprs(&.{Ast.Expr.a("true")}), .body = .{ .stmts = arm.items } },
            try b.clause(&.{Ast.Expr.v("_")}, &.{}, &.{done}),
        });
        const fun: Ast.Expr = .{ .fun = .{
            .name = fun_name,
            .params = if (group_in) |g| try b.exprs(&.{g}) else &.{},
            .body = try b.body(&.{case}),
        } };
        const plain_call: Ast.Expr = .{ .apply = .{
            .fun = try b.ptr(try b.paren(fun)),
            .args = if (group_in != null) try b.exprs(&.{try this.varGroupExpr(b, names)}) else &.{},
        } };
        var call = plain_call;
        if (hasJump(lp.body, .@"break")) {
            const guarded = try b.body(&.{plain_call});
            call = .{ .try_catch = .{
                .body = guarded,
                .catches = try b.arena.dupe(Ast.Clause, &.{try b.clause(
                    &.{try b.exception(Ast.Expr.a("throw"), try b.tuple(&.{ Ast.Expr.a(cond_break_signal), Ast.Expr.v(caught_var) }))},
                    &.{},
                    &.{Ast.Expr.v(caught_var)},
                )}),
            } };
        }
        if (group_in == null) return call;
        return b.match(try this.bindVarGroupExpr(b, names), call);
    }

    /// True when `body` jumps with `kind` for the loop it belongs to — directly
    /// or under an `if`, not inside a nested loop or a lambda.
    fn hasJump(body: []const ast.Stmt, kind: std.meta.Tag(ast.JumpExprOf(.untyped))) bool {
        for (body) |stmt| switch (stmt.expr) {
            .jump => |j| if (j.kind == kind) return true,
            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    if (hasJump(i.then_, kind)) return true;
                    if (i.else_) |els| if (hasJump(els, kind)) return true;
                },
                else => {},
            },
            else => {},
        };
        return false;
    }

    /// A condition loop used as a value, or one whose body yields or breaks
    /// with a value: the value form has no erlang lowering yet.
    fn conditionLoopHasValue(body: []const ast.Stmt) bool {
        for (body) |stmt| switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .yield => |y| if (y.value != null) return true,
                .@"break" => |brk| if (brk.value != null) return true,
                else => {},
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    if (conditionLoopHasValue(i.then_)) return true;
                    if (i.else_) |els| if (conditionLoopHasValue(els)) return true;
                },
                else => {},
            },
            else => {},
        };
        return false;
    }

    const ClosureMutation = struct {
        cc: @FieldType(@FieldType(ast.CallExprOf(.untyped), "kind"), "call"),
        names: []const []const u8,
    };

    /// A statement-position call of a local closure recorded in
    /// `mutating_closures`, or null.
    fn closureMutation(this: *const Emitter, e: ast.Expr) ?ClosureMutation {
        if (e != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        if (cc.is_builtin or cc.receiver != null or !this.locals.contains(cc.callee)) return null;
        const names = this.mutating_closures.get(cc.callee) orelse return null;
        return .{ .cc = cc, .names = names };
    }

    /// `Name = fun(Params…, GroupIn) -> Body, GroupOut end` for a closure whose
    /// body reassigns `names` of the enclosing function. An erlang fun cannot
    /// rebind what it captured, so the variables travel in as the last argument
    /// and out as the value; every statement-position call rebinds them.
    fn mutatingClosureExpr(this: *Emitter, b: Ast.Builder, name: []const u8, params: []const []const u8, body: []const ast.Stmt, names: []const []const u8) anyerror!Ast.Expr {
        const saved_cond_loop = this.cond_loop;
        this.cond_loop = null;
        defer this.cond_loop = saved_cond_loop;
        var snapshot = try this.var_current.clone();
        defer snapshot.deinit();
        const fun_params = try b.arena.alloc(Ast.Expr, params.len + 1);
        for (params, 0..) |p, i| {
            fun_params[i] = Ast.Expr.v(try this.arenaVar(b, p));
            this.addLocal(p);
        }
        fun_params[params.len] = try this.bindVarGroupExpr(b, names);
        const fun_body = try this.armWithGroup(b, body, names, this.indent + 1);
        try this.restoreVersions(&snapshot);
        try this.mutating_closures.put(this.alloc, name, try b.arena.dupe([]const u8, names));
        const target = Ast.Expr.v(try this.arenaVar(b, name));
        this.addLocal(name);
        return b.match(target, .{ .fun = .{ .params = fun_params, .body = fun_body } });
    }

    const ForEachLambda = struct {
        recv: *const ast.Expr,
        params: []const []const u8,
        body: []const ast.Stmt,
    };

    /// `recv.forEach({ p -> body })` / `recv.forEach { p -> body }` with a
    /// single-parameter lambda, or null.
    fn forEachLambda(e: ast.Expr) ?ForEachLambda {
        if (e != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        const recv = cc.receiver orelse return null;
        if (!std.mem.eql(u8, cc.callee, "forEach")) return null;
        if (cc.args.len == 1 and cc.trailing.len == 0) {
            const fe = switch (cc.args[0].value.*) {
                .function => |f| f,
                else => return null,
            };
            if (fe.kind.params.len != 1) return null;
            return .{ .recv = recv, .params = fe.kind.params, .body = fe.kind.body };
        }
        if (cc.args.len == 0 and cc.trailing.len == 1 and cc.trailing[0].params.len == 1) {
            return .{ .recv = recv, .params = cc.trailing[0].params, .body = cc.trailing[0].body };
        }
        return null;
    }

    /// Append (once each) the outer variables that `stmts` reassigns. `shadowed`
    /// names are bound by the construct itself (loop/lambda params) and skipped.
    fn collectMutations(this: *Emitter, gpa: std.mem.Allocator, stmts: []const ast.Stmt, shadowed: []const []const u8, out: *std.ArrayListUnmanaged([]const u8)) anyerror!void {
        for (stmts) |s| switch (s.expr) {
            .binding => |b| switch (b.kind) {
                .assign => |a| switch (a.target) {
                    .name => |n| {
                        if (!this.locals.contains(n)) continue;
                        if (containsName(shadowed, n) or containsName(out.items, n)) continue;
                        try out.append(gpa, n);
                    },
                    else => {},
                },
                else => {},
            },
            .branch => |br| switch (br.kind) {
                .if_ => |if_node| {
                    try this.collectMutations(gpa, if_node.then_, shadowed, out);
                    if (if_node.else_) |els| try this.collectMutations(gpa, els, shadowed, out);
                },
                else => {},
            },
            .loop => |lp| try this.collectMutations(gpa, lp.body, lp.params, out),
            .call => if (this.closureMutation(s.expr)) |cm| {
                for (cm.names) |n| {
                    if (!this.locals.contains(n) or containsName(shadowed, n) or containsName(out.items, n)) continue;
                    try out.append(gpa, n);
                }
            } else if (this.receiverMutation(s.expr)) |n| {
                if (containsName(shadowed, n) or containsName(out.items, n)) continue;
                try out.append(gpa, n);
            } else if (forEachLambda(s.expr)) |each| try this.collectMutations(gpa, each.body, each.params, out),
            else => {},
        };
    }

    fn containsName(names: []const []const u8, name: []const u8) bool {
        for (names) |n| if (std.mem.eql(u8, n, name)) return true;
        return false;
    }

    fn removeName(names: *std.ArrayListUnmanaged([]const u8), name: []const u8) void {
        var i: usize = 0;
        while (i < names.items.len) {
            if (std.mem.eql(u8, names.items[i], name)) _ = names.orderedRemove(i) else i += 1;
        }
    }

    /// `Name` / `Name@v` for each of `names` at their current versions, as one
    /// variable or a `{A, B}` tuple.
    fn varGroupExpr(this: *Emitter, b: Ast.Builder, names: []const []const u8) anyerror!Ast.Expr {
        const vars = try b.arena.alloc(Ast.Expr, names.len);
        for (names, 0..) |n, i| vars[i] = Ast.Expr.v(try this.varRef(b, n));
        return if (vars.len == 1) vars[0] else .{ .tuple = vars };
    }

    /// Give every name in `names` a fresh version and return the group.
    fn bindVarGroupExpr(this: *Emitter, b: Ast.Builder, names: []const []const u8) anyerror!Ast.Expr {
        for (names) |n| {
            const version = (this.var_next.get(n) orelse 0) + 1;
            try this.var_next.put(n, version);
            try this.var_current.put(n, version);
        }
        return this.varGroupExpr(b, names);
    }

    const VersionSnapshot = std.StringHashMap(u32);

    fn restoreVersions(this: *Emitter, snapshot: *const VersionSnapshot) !void {
        this.var_current.clearRetainingCapacity();
        var it = snapshot.iterator();
        while (it.next()) |e| try this.var_current.put(e.key_ptr.*, e.value_ptr.*);
    }

    /// The bare Erlang variable for `name`, spelled in the builder's arena.
    fn arenaVar(this: *Emitter, b: Ast.Builder, name: []const u8) anyerror![]const u8 {
        return this.versionedVar(b, name, 0);
    }

    /// A variable BOUND by a pattern. Erlang patterns do not shadow: a name that
    /// is already bound in the enclosing clause matches against its value instead
    /// of binding it (`case Sh of {'Square', S} ->` with `S` the function
    /// parameter never matches), and a name bound by a single `case` clause is
    /// "unsafe" in every later `case`. So each pattern binding takes the next
    /// version of the name (`S`, `S@2`, …) and that version becomes the current
    /// one, which is what the arm body then reads.
    fn patternBindVar(this: *Emitter, b: Ast.Builder, name: []const u8) anyerror![]const u8 {
        if (name.len == 0 or std.mem.eql(u8, name, "_")) return "_";
        // `assertPatternStmts` lowers its pattern twice: once as the `case`
        // test, whose binders nothing reads (and which erlang would warn
        // about), and once as the enclosing match, which is the one that binds.
        if (this.pattern_discard) return "_";
        if (!this.locals.contains(name)) {
            this.addLocal(name);
            return this.arenaVar(b, name);
        }
        const version = (this.var_next.get(name) orelse 0) + 1;
        try this.var_next.put(name, version);
        try this.var_current.put(name, version);
        return this.versionedVar(b, name, version);
    }

    /// An arm body at `indent`: its statements (when it has a real one), then
    /// the group at its post-arm versions.
    fn armWithGroup(this: *Emitter, b: Ast.Builder, body: []const ast.Stmt, names: []const []const u8, indent: usize) anyerror!Ast.Body {
        var stmts: std.ArrayListUnmanaged(Ast.Stmt) = .empty;
        if (lastRealStmt(body) != null) {
            try stmts.appendSlice(b.arena, (try this.bodyNode(b, body, 0, indent)).stmts);
        }
        try stmts.append(b.arena, .{ .expr = try this.varGroupExpr(b, names) });
        return .{ .stmts = stmts.items };
    }

    /// `Group = case Cond of true -> Then, Group'; _ -> Else, Group'' end`
    /// (the binding form `if (x) { b -> … }` matches `undefined` first).
    fn mutatingIfExpr(this: *Emitter, b: Ast.Builder, if_node: anytype, names: []const []const u8) anyerror!Ast.Expr {
        var snapshot = try this.var_current.clone();
        defer snapshot.deinit();

        var clauses: std.ArrayListUnmanaged(Ast.Clause) = .empty;
        const arm_indent = this.indent + 2;

        if (if_node.binding) |name| {
            // The binding form: `undefined` runs the else arm, any other value
            // binds the name and runs the then arm — no catch-all after them.
            const subject = try this.exprNode(b, if_node.cond.*);
            if (if_node.else_) |els| {
                try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{Ast.Expr.a("undefined")}), .body = try this.armWithGroup(b, els, names, arm_indent) });
                try this.restoreVersions(&snapshot);
            } else {
                try clauses.append(b.arena, try b.clause(&.{Ast.Expr.a("undefined")}, &.{}, &.{try this.varGroupExpr(b, names)}));
            }
            const bound = Ast.Expr.v(try this.patternBindVar(b, name));
            try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{bound}), .body = try this.armWithGroup(b, if_node.then_, names, arm_indent) });
            try this.restoreVersions(&snapshot);
            const target = try this.bindVarGroupExpr(b, names);
            return b.match(target, try b.caseOf(subject, clauses.items));
        }
        const subject = try this.condNode(b, if_node.cond.*);
        const then_pattern = Ast.Expr.a("true");
        try clauses.append(b.arena, .{
            .patterns = try b.exprs(&.{then_pattern}),
            .body = try this.armWithGroup(b, if_node.then_, names, arm_indent),
        });
        try this.restoreVersions(&snapshot);

        const else_body: Ast.Body = if (if_node.else_) |els| blk: {
            const body = try this.armWithGroup(b, els, names, arm_indent);
            try this.restoreVersions(&snapshot);
            break :blk body;
        } else try b.body(&.{try this.varGroupExpr(b, names)});
        try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{Ast.Expr.v("_")}), .body = else_body });

        // The group's fresh versions are only known once both arms were built.
        const target = try this.bindVarGroupExpr(b, names);
        return b.match(target, try b.caseOf(subject, clauses.items));
    }

    /// The index parameter of a two-parameter loop and the range it counts
    /// (`loop (xs, 1..) { x, i -> }`); `range` is null for `loop (xs) { x, i -> }`,
    /// which counts from 0.
    const FoldIndex = struct { name: []const u8, range: ?*const ast.Expr };

    /// `Group = lists:foldl(fun(Param, GroupIn) -> Body, GroupOut end, Group, Iter)`.
    /// With an index the fold walks `lists:enumerate(Start, Iter)` and the item
    /// parameter is the `{Index, Item}` pair — `lists:foldl` passes one element,
    /// so two fun parameters would never match.
    fn mutatingFoldExpr(this: *Emitter, b: Ast.Builder, param: []const u8, index: ?FoldIndex, body: []const ast.Stmt, iter: ast.Expr, names: []const []const u8) anyerror!Ast.Expr {
        const saved_cond_loop = this.cond_loop;
        this.cond_loop = null;
        defer this.cond_loop = saved_cond_loop;
        var snapshot = try this.var_current.clone();
        defer snapshot.deinit();

        // Fun heads shadow: the parameters take the bare names.
        const item = Ast.Expr.v(try this.arenaVar(b, param));
        this.addLocal(param);
        const pname = if (index) |ix| blk: {
            const idx = Ast.Expr.v(try this.arenaVar(b, ix.name));
            this.addLocal(ix.name);
            break :blk try b.tuple(&.{ idx, item });
        } else item;
        // The accumulator parameter is a fresh version: fun heads always bind.
        const group_in = try this.bindVarGroupExpr(b, names);
        const fun_body = try this.armWithGroup(b, body, names, this.indent + 1);
        try this.restoreVersions(&snapshot);
        const group_init = try this.varGroupExpr(b, names);
        const iter_expr = if (index) |ix| try b.remote("lists", "enumerate", &.{
            if (ix.range) |r| try this.indexRangeStart(b, r.*) else Ast.Expr.t(Term.int(0)),
            try this.exprNode(b, iter),
        }) else try this.exprNode(b, iter);

        const fold = try b.remote("lists", "foldl", &.{
            .{ .fun = .{ .params = try b.exprs(&.{ pname, group_in }), .body = fun_body } },
            group_init,
            iter_expr,
        });
        const target = try this.bindVarGroupExpr(b, names);
        return b.match(target, fold);
    }

    /// True when the last statement of a branch body is a valued `return`.
    /// A statement that is only a source comment (`.literal.comment`). Comments
    /// are not Erlang expressions: they never take a `,` separator and must not
    /// be treated as the body's tail value.
    fn sourceComment(stmt: ast.Stmt) ?Ast.Comment {
        if (stmt.expr != .literal or stmt.expr.literal.kind != .comment) return null;
        return commentNode(stmt.expr.literal.kind.comment);
    }

    /// A source comment as an Erlang comment: `//` → `%`, `///` → `%%`, `////` → `%%%`.
    fn commentNode(c: anytype) Ast.Comment {
        return .{
            .level = switch (c.kind) {
                .normal => .line,
                .doc => .doc,
                .module => .module,
            },
            .text = c.text,
        };
    }

    fn isCommentStmt(stmt: ast.Stmt) bool {
        return switch (stmt.expr) {
            .literal => |lit| switch (lit.kind) {
                .comment => true,
                else => false,
            },
            else => false,
        };
    }

    /// Index of the last non-comment statement in `body`, or `null` when every
    /// statement is a comment. The comma-joining of a body keys off this: a real
    /// statement gets a trailing `,` only when another real statement follows, so
    /// trailing comments never strand a dangling comma before `end`/`.`.
    fn lastRealStmt(body: []const ast.Stmt) ?usize {
        var i = body.len;
        while (i > 0) {
            i -= 1;
            if (!isCommentStmt(body[i])) return i;
        }
        return null;
    }

    fn bodyEndsWithReturn(body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        return switch (body[body.len - 1].expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| r != null,
                else => false,
            },
            else => false,
        };
    }

    /// `case Cond of true -> <then-body>; _ -> <body[i+1..]> end` for an `if`
    /// that early-returns, nesting the remaining statements in the false arm.
    /// The binding form `if (x) { s -> return …; }` matches the value itself:
    /// `case X of undefined -> <body[i+1..]>; S -> <then-body> end`. Lowered as
    /// a statement instead, its `case` value was discarded and the function
    /// answered the fall-through value unconditionally.
    fn earlyReturnIfExpr(this: *Emitter, b: Ast.Builder, body: []const ast.Stmt, i: usize, if_node: anytype) anyerror!Ast.Expr {
        const arm_indent = this.indent + 2;
        if (if_node.binding) |name| {
            const subject = try this.exprNode(b, if_node.cond.*);
            var snapshot = try this.var_current.clone();
            defer snapshot.deinit();
            const rest = try this.bodyNode(b, body, i + 1, arm_indent);
            try this.restoreVersions(&snapshot);
            const bound = Ast.Expr.v(try this.patternBindVar(b, name));
            return b.caseOf(subject, &.{
                .{ .patterns = try b.exprs(&.{Ast.Expr.a("undefined")}), .body = rest },
                .{ .patterns = try b.exprs(&.{bound}), .body = try this.bodyNode(b, if_node.then_, 0, arm_indent) },
            });
        }
        const cond = try this.condNode(b, if_node.cond.*);
        return b.caseOf(cond, &.{
            .{ .patterns = try b.exprs(&.{Ast.Expr.a("true")}), .body = try this.bodyNode(b, if_node.then_, 0, arm_indent) },
            .{ .patterns = try b.exprs(&.{Ast.Expr.v("_")}), .body = try this.bodyNode(b, body, i + 1, arm_indent) },
        });
    }

    const TryHead = union(enum) {
        name: []const u8,
        destruct: ast.ParamDestruct,
        none,
    };

    /// The propagating `case` for a `try` at `body[i]`, nesting `body[i+1..]`
    /// inside the `{ok, _}` arm.
    fn propagateTryExpr(this: *Emitter, b: Ast.Builder, body: []const ast.Stmt, i: usize, inner: ast.Expr, head: TryHead) anyerror!Ast.Expr {
        const n = this.try_seq;
        this.try_seq += 1;

        const subject = try this.exprNode(b, inner);
        const bound: Ast.Expr = switch (head) {
            .name => |nm| Ast.Expr.v(try this.arenaVar(b, nm)),
            .destruct => |pat| try this.destructPatternExpr(b, pat),
            .none => Ast.Expr.v(try std.fmt.allocPrint(b.arena, "_TryV{d}", .{n})),
        };
        const arm_indent = this.indent + 2;
        const ok_body: Ast.Body = if (i + 1 < body.len)
            try this.bodyNode(b, body, i + 1, arm_indent)
        else switch (head) {
            // No continuation: the Ok value is the function's result.
            .name => try b.body(&.{bound}),
            else => try b.body(&.{Ast.Expr.v(try std.fmt.allocPrint(b.arena, "_TryV{d}", .{n}))}),
        };
        const err_var = Ast.Expr.v(try std.fmt.allocPrint(b.arena, "_TryE{d}", .{n}));
        const err = try b.tuple(&.{ Ast.Expr.a("error"), err_var });
        return b.caseOf(subject, &.{
            .{ .patterns = try b.exprs(&.{try b.tuple(&.{ Ast.Expr.a("ok"), bound })}), .body = ok_body },
            try b.clause(&.{err}, &.{}, &.{err}),
        });
    }

    /// A destructuring pattern as an Erlang pattern. A record is a map at
    /// runtime, so `{ x, y }` is the exact map pattern `#{x := X, y := Y}` — the
    /// tuple `{X, Y}` it used to be never matched a map (`badmatch` on a `val`,
    /// `function_clause` on a parameter). A map pattern ignores the keys it does
    /// not name, so `..` needs no element of its own. `#(a, b)` stays a tuple.
    /// Each name binds through `patternBindVar`, so a destructured name already
    /// bound in the function takes a fresh version instead of matching.
    fn destructPatternExpr(this: *Emitter, b: Ast.Builder, pattern: ast.ParamDestruct) anyerror!Ast.Expr {
        switch (pattern) {
            .names => |n| {
                const fields = try b.arena.alloc(Ast.MapField, n.fields.len);
                for (n.fields, 0..) |fld, i| {
                    fields[i] = Ast.exactField(fld.field_name, Ast.Expr.v(try this.patternBindVar(b, fld.bind_name)));
                }
                return .{ .map = fields };
            },
            .tuple_ => |t| {
                const items = try b.arena.alloc(Ast.Expr, t.len);
                for (t, 0..) |nm, i| items[i] = Ast.Expr.v(try this.patternBindVar(b, nm));
                return .{ .tuple = items };
            },
            .list, .ctor => return Ast.Expr.v("_"),
        }
    }

    /// A statement inside a function body. `return expr` is the bare expression
    /// (in Erlang the last expression is the value).
    fn stmtExpr(this: *Emitter, b: Ast.Builder, stmt: ast.Stmt) anyerror!Ast.Expr {
        const e = stmt.expr;
        switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    const val = r orelse return Ast.Expr.a("undefined");
                    // `#[@future]` eager lowering: strip the
                    // `__bp_future_resolved(<t>)` marker back to `<t>`, and map
                    // `__bp_future_rejected(<e>)` to a plain `throw(<e>)` — the
                    // promise wrap is implicit in erlang's sync rendering.
                    if (futureWrapCallNameErl(val.*)) |kind| {
                        const inner = try this.exprNode(b, val.*.call.kind.call.args[0].value.*);
                        return switch (kind) {
                            .resolved => inner,
                            .rejected => b.call("throw", &.{inner}),
                        };
                    }
                    return this.exprNode(b, val.*);
                },
                else => return this.exprNode(b, e),
            },
            .binding => |bind| switch (bind.kind) {
                .localBind => |lb| {
                    if (lb.mutable) try this.mutable_locals.put(this.alloc, lb.name, {});
                    return this.bindExpr(b, lb.name, .bind, lb.value.*);
                },
                .assign => |a| switch (a.target) {
                    .name => |name| return this.bindExpr(b, name, switch (a.op) {
                        .assign => .assign,
                        .plusAssign => .plus_assign,
                    }, a.value.*),
                    .fieldAccess => return .{ .comment = Ast.Comment.doc("field assignment is not directly supported in Erlang") },
                },
                .localBindDestruct => |lb| {
                    const value = try this.exprNode(b, lb.value.*);
                    return switch (lb.pattern) {
                        .names, .tuple_ => b.match(try this.destructPatternExpr(b, lb.pattern), value),
                        .list, .ctor => value,
                    };
                },
            },
            else => return this.exprNode(b, e),
        }
    }

    // ── expressions ──────────────────────────────────────────────────────────

    /// The inline Erlang form of a lowered `@Result`/`@Option` method op.
    /// `args[0]` is the receiver; `args[1]` (when present) the fn/default value.
    /// A fun binds the receiver once (so chains don't re-evaluate it). Result
    /// values use the OTP `{ok, V} | {error, E}` shape; absent options are
    /// `undefined`.
    fn resultOptionNode(this: *Emitter, b: Ast.Builder, callee: []const u8, args: []const ast.CallArg) anyerror!Ast.Expr {
        const eq = std.mem.eql;
        const V = Ast.Expr.v;
        const A = Ast.Expr.a;
        const recv = args[0].value;
        // Result constructors: `return v` / `throw e` in a `-> @Result<…>` fn.
        if (eq(u8, callee, "__bp_ok")) return b.tuple(&.{ A("ok"), try this.exprNode(b, recv.*) });
        if (eq(u8, callee, "__bp_error")) return b.tuple(&.{ A("error"), try this.exprNode(b, recv.*) });

        const ok_v = try b.tuple(&.{ A("ok"), V("V") });
        var subject = V("R");
        var clauses: [2]Ast.Clause = undefined;
        if (eq(u8, callee, "__bp_result_map")) {
            clauses = .{
                try b.clause(&.{ok_v}, &.{}, &.{try b.tuple(&.{ A("ok"), try b.applyParen(try this.opArg(b, args), &.{V("V")}) })}),
                try b.clause(&.{V("_")}, &.{}, &.{subject}),
            };
        } else if (eq(u8, callee, "__bp_result_flatMap")) {
            clauses = .{
                try b.clause(&.{ok_v}, &.{}, &.{try b.applyParen(try this.opArg(b, args), &.{V("V")})}),
                try b.clause(&.{V("_")}, &.{}, &.{subject}),
            };
        } else if (eq(u8, callee, "__bp_result_unwrapOr")) {
            clauses = .{
                try b.clause(&.{ok_v}, &.{}, &.{V("V")}),
                try b.clause(&.{V("_")}, &.{}, &.{try b.paren(try this.opArg(b, args))}),
            };
        } else if (eq(u8, callee, "__bp_result_isOk") or eq(u8, callee, "__bp_result_isError")) {
            const tag = if (eq(u8, callee, "__bp_result_isOk")) "ok" else "error";
            clauses = .{
                try b.clause(&.{try b.tuple(&.{ A(tag), V("_") })}, &.{}, &.{A("true")}),
                try b.clause(&.{V("_")}, &.{}, &.{A("false")}),
            };
        } else if (eq(u8, callee, "__bp_option_map") or eq(u8, callee, "__bp_option_flatMap")) {
            subject = V("O");
            clauses = .{
                try b.clause(&.{A("undefined")}, &.{}, &.{A("undefined")}),
                try b.clause(&.{V("V")}, &.{}, &.{try b.applyParen(try this.opArg(b, args), &.{V("V")})}),
            };
        } else if (eq(u8, callee, "__bp_option_unwrapOr")) {
            subject = V("O");
            clauses = .{
                try b.clause(&.{A("undefined")}, &.{}, &.{try b.paren(try this.opArg(b, args))}),
                try b.clause(&.{V("V")}, &.{}, &.{V("V")}),
            };
        } else {
            return error.UnknownResultOptionOp;
        }
        const fun: Ast.Expr = .{ .fun_clauses = try b.arena.dupe(Ast.Clause, &.{
            try b.clause(&.{subject}, &.{}, &.{try b.caseInline(subject, &clauses)}),
        }) };
        return b.applyParen(fun, &.{try this.exprNode(b, recv.*)});
    }

    /// The fn/default argument of a `@Result`/`@Option` op (empty when absent).
    fn opArg(this: *Emitter, b: Ast.Builder, args: []const ast.CallArg) anyerror!Ast.Expr {
        if (args.len < 2) return error.MissingResultOptionArgument;
        return this.exprNode(b, args[1].value.*);
    }

    /// `e` as an `erl_ast` expression rendered at the current indentation.
    fn exprNode(this: *Emitter, b: Ast.Builder, e: ast.Expr) anyerror!Ast.Expr {
        const V = Ast.Expr.v;
        const A = Ast.Expr.a;
        switch (e) {
            .literal => |lit| return switch (lit.kind) {
                .numberLit => |n| .{ .number = n },
                .comment => |c| .{ .comment = commentNode(c) },
                .stringLit => |str| .{ .lexeme_binary = str },
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .null_ => A("undefined"),
            },

            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    // Boolean literals are env-bound identifiers in botopink —
                    // they must stay lowercase atoms, never `True`/`False` vars.
                    if (std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false")) return A(n);
                    // A module-level `val` emitted as a 0-arity function: a bare
                    // reference is the call `name()`. A local of the same name
                    // shadows it.
                    if (!this.locals.contains(n) and this.top_vals.contains(n)) return b.call(n, &.{});
                    return V(try this.varRef(b, n));
                },
                .identAccess => |ia| {
                    // Qualified enum member: `Order.Lt` → the variant atom.
                    if (ia.receiver.* == .identifier and ia.receiver.*.identifier.kind == .ident and
                        this.enum_names.contains(ia.receiver.*.identifier.kind.ident))
                    {
                        return A(ia.member);
                    }
                    // Tuple index access: `t._N` → `element(N+1, T)` (1-based).
                    if (tupleIndexMember(ia.member)) |digits| {
                        const idx = std.fmt.parseInt(usize, digits, 10) catch 0;
                        const position = Ast.Expr.t(Term.int(@intCast(idx + 1)));
                        if (ia.optional) {
                            const n = this.try_seq;
                            this.try_seq += 1;
                            const opt = V(try std.fmt.allocPrint(b.arena, "_Opt{d}", .{n}));
                            return this.optionalAccess(b, opt, try b.call("element", &.{ position, opt }), ia.receiver.*);
                        }
                        return b.call("element", &.{ position, try this.exprNode(b, ia.receiver.*) });
                    }
                    // `arr.length` / `s.length` / `arr.len` recorded by inference as a
                    // primitive field access → the host length op, not a map read.
                    if (this.instance_lowerings.get(id.loc)) |il| switch (il) {
                        .prim => |k| {
                            const recv = try this.exprNode(b, ia.receiver.*);
                            return switch (k) {
                                .string => b.remote("string", "length", &.{recv}),
                                else => b.call("length", &.{recv}),
                            };
                        },
                        .type_ => {},
                    };
                    // Same field access on a `Self`-typed receiver inside an
                    // interface instance `default fn` (`self.length`), which
                    // inference leaves unlowered.
                    if (!ia.optional and (std.mem.eql(u8, ia.member, "len") or
                        std.mem.eql(u8, ia.member, "length") or std.mem.eql(u8, ia.member, "size")))
                    {
                        if (this.selfPrimKind(ia.receiver.*)) |k| {
                            const recv = try this.exprNode(b, ia.receiver.*);
                            return switch (k) {
                                .string => b.remote("string", "length", &.{recv}),
                                else => b.call("length", &.{recv}),
                            };
                        }
                    }
                    // A comptime body has no types; a typed module whose inference
                    // recorded nothing here (a chained or generic receiver:
                    // `Array.range(0, 5)`'s result) does not know either, unless
                    // some record of the module declares the field. Both
                    // dispatch at runtime: a list's or binary's length, else the
                    // map field.
                    if (!ia.optional and
                        (std.mem.eql(u8, ia.member, "len") or std.mem.eql(u8, ia.member, "length") or
                            std.mem.eql(u8, ia.member, "size")) and
                        (this.untyped or (this.instance_lowerings.get(id.loc) == null and !this.isRecordField(ia.member))))
                    {
                        if (!this.untyped) this.needs_len_helper = true;
                        return b.call("__bp_len", &.{ try this.exprNode(b, ia.receiver.*), A(ia.member) });
                    }
                    // Record/struct field access — records are maps at runtime.
                    // Optional chaining (`a?.b`) guards on `undefined`.
                    if (ia.optional) {
                        const n = this.try_seq;
                        this.try_seq += 1;
                        const opt = V(try std.fmt.allocPrint(b.arena, "_Opt{d}", .{n}));
                        return this.optionalAccess(b, opt, try b.remote("maps", "get", &.{ A(ia.member), opt }), ia.receiver.*);
                    }
                    return b.remote("maps", "get", &.{ A(ia.member), try this.exprNode(b, ia.receiver.*) });
                },
                // Leading-dot shorthand for an enum member (`.Black`): the same
                // variant atom the qualified form lowers to. Rendered raw it was
                // the bare name — an unbound erlang VARIABLE for the usual
                // PascalCase variant.
                .dotIdent => |n| return A(n),
            },

            .binaryOp => |bin| {
                const op: []const u8 = switch (bin.op) {
                    .add => if (this.untyped)
                        return b.call("__bp_add", &.{ try this.exprNode(b, bin.lhs.*), try this.exprNode(b, bin.rhs.*) })
                    else if (this.isStringExpr(e))
                        // String `+` is concatenation: erlang binaries have no
                        // arithmetic, so `"a" + b` used to raise `badarith`.
                        return this.stringConcatNode(b, e)
                    else if (this.numKind(bin.lhs.*) != null or this.numKind(bin.rhs.*) != null)
                        "+"
                    else {
                        // Neither operand is provably a number or a string (a
                        // generic lambda's `{ acc, s -> acc + s }`): two binaries
                        // concatenate at runtime, anything else adds.
                        this.needs_add_helper = true;
                        return b.call("__bp_add", &.{ try this.exprNode(b, bin.lhs.*), try this.exprNode(b, bin.rhs.*) });
                    },
                    .sub => "-",
                    .mul => "*",
                    // `div` is integer division and raises `badarith` on a float;
                    // an operand known to be a float takes `/`.
                    .div => if (this.numKind(bin.lhs.*) == .float or this.numKind(bin.rhs.*) == .float) "/" else "div",
                    .mod => "rem",
                    .lt => "<",
                    .gt => ">",
                    .lte => "=<",
                    .gte => ">=",
                    .eq => "=:=",
                    .ne => "=/=",
                    // Short-circuiting, as botopink's `&&`/`||` are: erlang's
                    // `and`/`or` evaluate BOTH operands, so a right operand
                    // guarded by the left (`xs.length > 0 && xs.at(0) > 1`)
                    // used to raise instead of yielding `false`.
                    .@"and" => "andalso",
                    .@"or" => "orelse",
                };
                return b.binop(op, try this.exprNode(b, bin.lhs.*), try this.exprNode(b, bin.rhs.*));
            },

            .unaryOp => |un| return .{ .unop = .{
                .op = switch (un.op) {
                    .not => "not ",
                    .neg => "-",
                },
                .operand = try b.ptr(try this.exprNode(b, un.expr.*)),
            } },

            .function => |func| {
                const saved_cond_loop = this.cond_loop;
                this.cond_loop = null;
                defer this.cond_loop = saved_cond_loop;
                const params = try b.arena.alloc(Ast.Expr, func.kind.params.len);
                for (func.kind.params, 0..) |p, i| {
                    params[i] = V(try this.arenaVar(b, p));
                    this.addLocal(p);
                }
                return .{ .fun = .{ .params = params, .body = try this.bodyNode(b, func.kind.body, 0, this.indent + 1) } };
            },

            .collection => |col| switch (col.kind) {
                .grouped => |inner| return b.paren(try this.exprNode(b, inner.*)),
                .arrayLit => |al| {
                    var items: std.ArrayListUnmanaged(Ast.Expr) = .empty;
                    for (al.elems) |elem| try items.append(b.arena, try this.exprNode(b, elem));
                    // A spread expression concatenates: `[A, B] ++ Rest`.
                    if (al.spreadExpr) |se| {
                        return .{ .binop = .{
                            .op = "++",
                            .lhs = try b.ptr(.{ .list = items.items }),
                            .rhs = try b.ptr(try this.exprNode(b, se.*)),
                            .parens = false,
                        } };
                    }
                    // `[a, b, ...rest]` parsed as a trailing spread NAME: it is
                    // a concatenation too, not a fourth element (which is what
                    // the raw name used to render — and in botopink spelling,
                    // so the emitted module did not even compile).
                    if (al.spread) |name| {
                        if (name.len > 0) return .{ .binop = .{
                            .op = "++",
                            .lhs = try b.ptr(.{ .list = items.items }),
                            .rhs = try b.ptr(try this.nameRefNode(b, name)),
                            .parens = false,
                        } };
                    }
                    return .{ .list = items.items };
                },
                .tupleLit => |tl| {
                    const items = try b.arena.alloc(Ast.Expr, tl.elems.len);
                    for (tl.elems, 0..) |elem, i| items[i] = try this.exprNode(b, elem);
                    return .{ .tuple = items };
                },
                .case => |c| return this.caseNode(b, c.subjects, c.arms),
                // `a..b` is half-open `[a, b)` (parity with wasm + `Array.range`),
                // but erlang's `lists:seq/2` is inclusive — so the upper bound is
                // `b - 1`; an open range `a..` iterates to `infinity`.
                .range => |r| return b.remote("lists", "seq", &.{
                    try this.exprNode(b, r.start.*),
                    if (r.end) |end| .{ .binop = .{
                        .op = "-",
                        .lhs = try b.ptr(try b.paren(try this.exprNode(b, end.*))),
                        .rhs = try b.ptr(Ast.Expr.t(Term.int(1))),
                        .parens = false,
                    } } else A("infinity"),
                }),
                // Anonymous record / interface literal — an Erlang map (the same
                // shape named records lower to). Keys are the field names as written.
                .behaviorLit => |il| return this.fieldMap(b, il.fields),
            },

            .jump => |j| return switch (j.kind) {
                // A value-less jump has no value to stand for: `return;` and a
                // bare `try` are `undefined` (null), as `stmtExpr`'s `return`
                // already was, and a bare `throw;` throws `undefined` rather
                // than rendering as nothing — a hole `erlc` rejected, or worse,
                // accepted as the next expression.
                .@"return" => |r| if (r) |val| this.exprNode(b, val.*) else A("undefined"),
                .throw_ => |r| b.remote("erlang", "throw", &.{if (r) |val| try this.exprNode(b, val.*) else A("undefined")}),
                .try_ => |t| if (t) |val| this.exprNode(b, val.*) else A("undefined"),
                .await_ => |av| this.exprNode(b, av.*),
                // A bare `break` leaves the enclosing loop. Erlang's list
                // functions cannot be stopped from inside the fun, so the exit
                // is a throw the loop's `try` catches (`loopBreakCatch`). It
                // used to render as nothing at all, which left a `;` where the
                // clause body belonged and broke the whole module.
                .@"break" => |brk| if (this.cond_loop) |names|
                    b.remote("erlang", "throw", &.{try b.tuple(&.{ A(cond_break_signal), if (names.len > 0) try this.varGroupExpr(b, names) else A("ok") })})
                else if (brk.value) |bp| this.exprNode(b, bp.*) else b.remote("erlang", "throw", &.{Ast.Expr.a(break_signal)}),
                .yield => |y| if (y.value) |val| this.exprNode(b, val.*) else A("undefined"),
                .@"continue" => if (this.cond_loop) |names|
                    b.remote("erlang", "throw", &.{try b.tuple(&.{ A(cond_continue_signal), if (names.len > 0) try this.varGroupExpr(b, names) else A("ok") })})
                else
                    .{ .comment = Ast.Comment.doc("continue") },
            },

            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    // The binding form (`if (mb) { b -> … }`) matches on the
                    // value itself (`undefined -> …; B -> …`), so it keeps the
                    // raw subject; only the boolean form needs the null test.
                    const cond = if (i.binding == null) try this.condNode(b, i.cond.*) else try this.exprNode(b, i.cond.*);
                    const arm_indent = this.indent + 2;
                    var clauses: std.ArrayListUnmanaged(Ast.Clause) = .empty;
                    if (i.binding) |name| {
                        // `if (mb) { b -> body } [else { … }]`: `undefined` takes
                        // the else body (it used to sit behind an unreachable
                        // `false` clause), any other value binds `b`. The two
                        // patterns cover every value, so no catch-all follows.
                        const undefined_body = if (i.else_) |els| try this.bodyNode(b, els, 0, arm_indent) else try b.body(&.{A("undefined")});
                        try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{A("undefined")}), .body = undefined_body, .layout = if (i.else_ == null) .inline_ else .block });
                        const bound = V(try this.patternBindVar(b, name));
                        try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{bound}), .body = try this.bodyNode(b, i.then_, 0, arm_indent) });
                        return b.caseOf(cond, clauses.items);
                    }
                    try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{A("true")}), .body = try this.bodyNode(b, i.then_, 0, arm_indent) });
                    if (i.else_) |els| {
                        try clauses.append(b.arena, .{ .patterns = try b.exprs(&.{A("false")}), .body = try this.bodyNode(b, els, 0, arm_indent) });
                    } else {
                        // No else branch — a catch-all so the case doesn't crash
                        // when the condition is false.
                        try clauses.append(b.arena, try b.clause(&.{V("_")}, &.{}, &.{A("ok")}));
                    }
                    return b.caseOf(cond, clauses.items);
                },
                .tryCatch => |tc| {
                    // `try expr catch handler` → pattern match on the Result tag:
                    //   case Expr of {ok, V} -> V; {error, E} -> Handler end
                    const n = this.try_seq;
                    this.try_seq += 1;
                    // The subject runs inside a real `try`: `@todo()`/`@panic`
                    // in a `#[@result]` callee RAISE instead of answering
                    // `{error, E}`, and a `case` cannot catch a raise. The
                    // reason becomes the `{error, Reason}` the handler receives.
                    // Only the subject is wrapped — a raise in the handler or
                    // in the value arm still propagates.
                    const reason = V(try std.fmt.allocPrint(b.arena, "_TryR{d}", .{n}));
                    const subject: Ast.Expr = .{ .try_catch = .{
                        .body = try b.body(&.{try this.exprNode(b, tc.expr.*)}),
                        .catches = try b.arena.dupe(Ast.Clause, &.{
                            try b.clause(&.{try b.exception(A("error"), reason)}, &.{}, &.{try b.tuple(&.{ A("error"), reason })}),
                        }),
                    } };
                    const ok_var = V(try std.fmt.allocPrint(b.arena, "TryV{d}", .{n}));
                    const err_var = V(try std.fmt.allocPrint(b.arena, "_TryE{d}", .{n}));

                    const saved = this.indent;
                    this.indent = saved + 2;
                    const handler_expr = try this.exprNode(b, tc.handler.*);
                    this.indent = saved;
                    // A function handler receives the error.
                    const handler: Ast.Expr = if (tc.handler.* == .function)
                        .{ .apply = .{ .fun = try b.ptr(handler_expr), .args = try b.exprs(&.{err_var}) } }
                    else
                        handler_expr;

                    return b.caseOf(subject, &.{
                        try b.clause(&.{try b.tuple(&.{ A("ok"), ok_var })}, &.{}, &.{ok_var}),
                        .{ .patterns = try b.exprs(&.{try b.tuple(&.{ A("error"), err_var })}), .body = try b.body(&.{handler}) },
                    });
                },
            },

            .loop => |lp| {
                if (lp.condition) {
                    if (conditionLoopHasValue(lp.body)) return error.ConditionLoopValueUnsupported;
                    return this.conditionLoopNode(b, lp, &.{});
                }
                // A collection loop's body is a fun: its jumps are its own.
                const saved_cond_loop = this.cond_loop;
                this.cond_loop = null;
                defer this.cond_loop = saved_cond_loop;
                // A loop is a `lists:map` when its body produces a value per
                // item: a `yield`, or a `break <expr>` (the mapped element —
                // bare `break` carries no value and keeps the loop a foreach).
                const yields = for (lp.body) |stmt| {
                    if (stmt.expr != .jump) continue;
                    switch (stmt.expr.jump.kind) {
                        .yield => break true,
                        .@"break" => |brk| if (brk.value != null) break true,
                        else => {},
                    }
                } else false;
                const op = if (yields) "map" else "foreach";
                // `loop (xs, 0..) { item, i -> … }`: `lists:map/foreach` pass ONE
                // element to the fun, so the two loop parameters cannot be two fun
                // parameters (that raised `function_clause` at every call). The
                // index range walks alongside the collection, which is exactly
                // `lists:enumerate/2` — a list of `{Index, Item}` pairs matched by
                // a single tuple parameter.
                // `loop (xs) { item, i -> … }` (no written range) counts from 0.
                if (lp.params.len == 2) {
                    const idx = V(try this.arenaVar(b, lp.params[1]));
                    this.addLocal(lp.params[1]);
                    const item = V(try this.arenaVar(b, lp.params[0]));
                    this.addLocal(lp.params[0]);
                    const pair = try b.tuple(&.{ idx, item });
                    const fun: Ast.Expr = .{ .fun = .{
                        .params = try b.exprs(&.{pair}),
                        .body = try this.bodyNode(b, lp.body, 0, this.indent + 1),
                    } };
                    const enumerated = try b.remote("lists", "enumerate", &.{
                        if (lp.indexRange) |r| try this.indexRangeStart(b, r.*) else Ast.Expr.t(Term.int(0)),
                        try this.exprNode(b, lp.iter.*),
                    });
                    return b.remote("lists", op, &.{ fun, enumerated });
                }
                const params = try b.arena.alloc(Ast.Expr, lp.params.len);
                for (lp.params, 0..) |p, i| {
                    params[i] = V(try this.arenaVar(b, p));
                    this.addLocal(p);
                }
                // An open-ended range (`loop (x..) { i -> … }`) has no list to
                // walk — `lists:seq/2` cannot take `infinity` — so it becomes a
                // named fun that counts up and calls itself. The bare `break`
                // such a loop needs to terminate is the throw below.
                if (unboundedRangeStart(lp.iter.*)) |start| {
                    if (lp.params.len == 1) {
                        var body: std.ArrayListUnmanaged(Ast.Expr) = .empty;
                        const inner = try this.bodyNode(b, lp.body, 0, this.indent + 1);
                        for (inner.stmts) |s| try body.append(b.arena, s.expr);
                        const next: Ast.Expr = .{ .binop = .{
                            .op = "+",
                            .lhs = try b.ptr(params[0]),
                            .rhs = try b.ptr(Ast.Expr.t(Term.int(1))),
                            .parens = false,
                        } };
                        try body.append(b.arena, .{ .apply = .{
                            .fun = try b.ptr(V(loop_fun_var)),
                            .args = try b.exprs(&.{next}),
                        } });
                        const fun: Ast.Expr = .{ .fun = .{
                            .name = loop_fun_var,
                            .params = params,
                            .body = try b.body(body.items),
                        } };
                        const call: Ast.Expr = .{ .apply = .{
                            .fun = try b.ptr(try b.paren(fun)),
                            .args = try b.exprs(&.{try this.exprNode(b, start.*)}),
                        } };
                        return this.loopBreakCatch(b, call, lp.body);
                    }
                }
                // `loop (xs) { x -> if (cond) { break x; }; }` keeps only the
                // items the guard admits — `lists:filtermap/2` exactly, with the
                // fun answering `{true, Value}` or `false`. Lowered as a plain
                // `foreach` this dropped every value the loop produced.
                if (try this.filterMapFunBody(b, lp)) |body| {
                    return b.remote("lists", "filtermap", &.{
                        .{ .fun = .{ .params = params, .body = body } },
                        try this.exprNode(b, lp.iter.*),
                    });
                }
                const fun: Ast.Expr = .{ .fun = .{ .params = params, .body = try this.bodyNode(b, lp.body, 0, this.indent + 1) } };
                return this.loopBreakCatch(b, try b.remote("lists", op, &.{ fun, try this.exprNode(b, lp.iter.*) }), lp.body);
            },

            .call => |c| return this.callNode(b, c),
            .binding => |bind| return this.bindingNode(b, bind),
            // `use` is a transparent prefix: lower the wrapped call (any binding
            // belongs to the enclosing `val`).
            .useHook => |uh| return this.exprNode(b, uh.kind.inner.*),
            .comptime_ => |ct| return this.comptimeNode(b, ct),
        }
    }

    /// `(fun(undefined) -> undefined; (Opt) -> Access end)(Receiver)`.
    /// An `if`/`else if` condition. The `case Cond of true -> …; false -> …`
    /// shape needs a real boolean, so a bare reference to a nullable local
    /// (`if (end)` where `end: i32 = null`) becomes the null test the botopink
    /// truthiness rule means: `(End =/= undefined)`. Every other condition
    /// already evaluates to a boolean and is emitted unchanged.
    fn condNode(this: *Emitter, b: Ast.Builder, cond: ast.Expr) anyerror!Ast.Expr {
        const node = try this.exprNode(b, cond);
        if (cond != .identifier or cond.identifier.kind != .ident) return node;
        if (!this.nullable_locals.contains(cond.identifier.kind.ident)) return node;
        return b.binop("=/=", node, Ast.Expr.a("undefined"));
    }

    fn optionalAccess(this: *Emitter, b: Ast.Builder, opt: Ast.Expr, access: Ast.Expr, receiver: ast.Expr) anyerror!Ast.Expr {
        const fun: Ast.Expr = .{ .fun_clauses = try b.arena.dupe(Ast.Clause, &.{
            try b.clause(&.{Ast.Expr.a("undefined")}, &.{}, &.{Ast.Expr.a("undefined")}),
            try b.clause(&.{opt}, &.{}, &.{access}),
        }) };
        return .{ .apply = .{ .fun = try b.ptr(try b.paren(fun)), .args = try b.exprs(&.{try this.exprNode(b, receiver)}) } };
    }

    /// `#{field => Value, …}`, the field names as atoms (quoted when PascalCase
    /// or reserved, e.g. `'Kind'`, `'end'`).
    fn fieldMap(this: *Emitter, b: Ast.Builder, fields: anytype) anyerror!Ast.Expr {
        const out = try b.arena.alloc(Ast.MapField, fields.len);
        for (fields, 0..) |f, i| out[i] = Ast.field(f.name, try this.exprNode(b, f.value.*));
        return .{ .map = out };
    }

    // ── calls ─────────────────────────────────────────────────────────────────

    fn callNode(this: *Emitter, b: Ast.Builder, c: anytype) anyerror!Ast.Expr {
        return switch (c.kind) {
            .pipeline => |p| this.pipelineNode(b, p),
            .call => |cc| if (cc.is_builtin) this.builtinCallNode(b, cc) else this.plainCallNode(b, c.loc, cc),
        };
    }

    /// `a |> f |> g` → `g(f(A))`: the chain flattened and applied inside out.
    /// Stages are built from the last one down, as they have always been emitted.
    fn pipelineNode(this: *Emitter, b: Ast.Builder, p: anytype) anyerror!Ast.Expr {
        var items: std.ArrayListUnmanaged(ast.Expr) = .empty;
        try items.append(b.arena, p.lhs.*);
        var current = p.rhs.*;
        while (current == .call and current.call.kind == .pipeline) {
            try items.append(b.arena, current.call.kind.pipeline.lhs.*);
            current = current.call.kind.pipeline.rhs.*;
        }
        try items.append(b.arena, current);

        // A stage that is a bare identifier naming a top-level function is
        // CALLED (`inc(Acc)`); only a fn-typed local is APPLIED as a fun
        // variable (`Inc(Acc)`). Erlang has no value for a plain fn name, so
        // lowering a bare `|> inc` as a variable leaves `Inc` unbound.
        var node = try this.exprNode(b, items.items[0]);
        for (items.items[1..]) |stage_expr| {
            if (identName(stage_expr)) |name| {
                if (!this.locals.contains(name)) {
                    node = try b.call(name, &.{node});
                    continue;
                }
            }
            const stage = try this.exprNode(b, stage_expr);
            node = .{ .apply = .{ .fun = try b.ptr(stage), .args = try b.exprs(&.{node}) } };
        }
        return node;
    }

    /// `@name(...)`: the builtin's `@external(erlang, …)` template when it has
    /// one (`todo`/`panic`/`print`/`println`/`debug`), `@block`, the lowered
    /// `__bp_*` result/option ops, else a local call.
    fn builtinCallNode(this: *Emitter, b: Ast.Builder, cc: anytype) anyerror!Ast.Expr {
        // `@print(a, b)` → `'__bp_print'([A, B])`: the helper picks `~ts` for a
        // binary and `~p` for anything else at runtime (semantics decision 1),
        // so a string prints as its text on the typed and the comptime path.
        if (isPrintBuiltin(cc.callee)) {
            this.needs_print_helper = true;
            return b.call("__bp_print", &.{try b.list(try this.callArgs(b, null, cc))});
        }
        if (try this.builtinAnnotationNode(b, cc.callee, cc)) |node| return node;
        if (std.mem.eql(u8, cc.callee, "block")) {
            // `@block { … }` (or `@block(fn)`) is an immediately-applied fun, so
            // the body runs and its value is the call's value.
            const body: Ast.Body = if (cc.args.len == 1) blk: {
                const arg = cc.args[0].value;
                if (arg.* != .function) return error.InvalidArgs;
                this.indent += 1;
                defer this.indent -= 1;
                break :blk try b.body(&.{try this.exprNode(b, arg.*)});
            } else if (cc.trailing.len == 1 and cc.trailing[0].params.len == 0)
                try this.bodyNode(b, cc.trailing[0].body, 0, this.indent + 1)
            else
                return error.InvalidArgs;
            return b.applyParen(.{ .fun = .{ .params = &.{}, .body = body } }, &.{});
        }
        if (std.mem.startsWith(u8, cc.callee, "__bp_")) return this.resultOptionNode(b, cc.callee, cc.args);
        return b.call(cc.callee, try this.callArgs(b, null, cc));
    }

    /// A user-level call: receiver dispatch (std module, extension, enum
    /// constructor, associated fn, primitive/record instance method), host
    /// templates and externals, record constructors, fun-typed locals, or a
    /// plain local call. Reserved-word callees (`of`, `div`) are quoted atoms.
    fn plainCallNode(this: *Emitter, b: Ast.Builder, loc: anytype, cc: anytype) anyerror!Ast.Expr {
        const recv = cc.receiver orelse {
            if (this.user_erlang_templates.contains(cc.callee)) {
                // §A2 per-callee template / arity-branched annotation. With no
                // matching branch, the bare local call surfaces the gap as an
                // erlang "undefined function" instead of emitting nothing.
                if (try this.userTemplateNode(b, cc.callee, cc)) |node| return node;
                return b.call(cc.callee, try this.callArgs(b, null, cc));
            }
            // A bare callee inside an inlined interface `default fn` body is a
            // std prelude helper the consuming module never declares
            // (`String.slice`'s body calls `stringSlice0`/`stringSlice1`), so it
            // renders from the `primitives.bp` template index instead.
            if (this.in_iface_default) {
                if (try this.preludeHelperNode(b, cc.callee, cc)) |node| return node;
            }
            // `#[@external(erlang, "module", "symbol")]` fn → `module:symbol(…)`.
            if (this.externals.get(cc.callee)) |ref| {
                return b.remote(ref.module, ref.symbol, try this.callArgs(b, null, cc));
            }
            // External fn with no `erlang` target — no symbol to call here.
            if (this.externals_missing.contains(cc.callee)) {
                this.missing_external = .{ .name = cc.callee, .target = "erlang", .loc = loc };
                return error.MissingExternalTarget;
            }
            // Record/struct constructor → `#{field => V, …}` (the runtime shape of
            // the beam backend's `put_map_assoc` maps). Labeled args use their
            // label; positional args follow the declared field order.
            if (this.record_fields.get(cc.callee)) |fields| {
                const out = try b.arena.alloc(Ast.MapField, cc.args.len);
                for (cc.args, 0..) |arg, ai| {
                    const fname: []const u8 = if (arg.label) |lbl| lbl else if (ai < fields.len) fields[ai] else "_arg";
                    out[ai] = Ast.field(fname, try this.exprNode(b, arg.value.*));
                }
                return .{ .map = out };
            }
            // `Ok(v)` / `Err(e)` / `new Error(msg)` build the runtime `@Result`
            // tuple the `#[@result]` transform and the `Ok`/`Err` case arms both
            // use. Rendered as a call they became `'Ok'(V)` — applying an atom,
            // which is not a function. A user type of the same name wins (it was
            // matched above).
            if (!this.enum_variants.contains(cc.callee) and cc.args.len == 1) {
                if (resultTag(cc.callee)) |tag| {
                    return b.tuple(&.{ Ast.Expr.a(tag), try this.exprNode(b, cc.args[0].value.*) });
                }
            }
            // A fn-typed local (parameter, `val`, lambda binding) is applied as a
            // fun variable (`Pred(X)`), not called as a module function.
            if (this.locals.contains(cc.callee)) {
                return .{ .apply = .{
                    .fun = try b.ptr(Ast.Expr.v(try this.arenaVar(b, cc.callee))),
                    .args = try this.callArgs(b, null, cc),
                } };
            }
            // A module-level `val` holding a lambda (`val add = { x, y -> … }`)
            // is a 0-arity function RETURNING the fun, so the call applies what
            // it answers: `(add())(10, 20)` — `add(10, 20)` would look for an
            // `add/2` the module never defines.
            if (this.top_vals.contains(cc.callee)) {
                return .{ .apply = .{
                    .fun = try b.ptr(try b.paren(try b.call(cc.callee, &.{}))),
                    .args = try this.callArgs(b, null, cc),
                } };
            }
            // An imported `pub fn` (`import {twice};`): this module never emits
            // `twice/1`, so the bare call was `function twice/1 undefined` —
            // reach the owner (`a:twice(X)`). A local definition of the same
            // name and arity wins (an `@emit`ed body next to the import).
            if (this.importedFnOwner(cc.callee, cc.args.len + cc.trailing.len)) |owner| {
                return b.remote(owner, cc.callee, try this.callArgs(b, null, cc));
            }
            return b.call(cc.callee, try this.callArgs(b, null, cc));
        };

        // 06 N24 — a tuple element of function type applied by its position
        // (`c._1(9)`, what a labelled `c.set(9)` becomes): a tuple is an erlang
        // tuple, so the fun is `element(N+1, C)` applied to the arguments —
        // never a module function named `'_1'`.
        if (tupleIndexMember(cc.callee)) |digits| {
            const idx = std.fmt.parseInt(usize, digits, 10) catch 0;
            const position = Ast.Expr.t(Term.int(@intCast(idx + 1)));
            const elem = try b.call("element", &.{ position, try this.exprNode(b, recv.*) });
            return .{ .apply = .{
                .fun = try b.ptr(elem),
                .args = try this.callArgs(b, null, cc),
            } };
        }

        const mod_name: ?[]const u8 = if (recv.* == .identifier and recv.identifier.kind == .ident and isModuleRef(recv.identifier.kind.ident))
            recv.identifier.kind.ident
        else
            null;
        // `"std"` package call: a lowercase receiver naming an imported std
        // module lowers to the remote `option:map(Args)`.
        if (recv.* == .identifier and recv.identifier.kind == .ident and this.std_imports.contains(recv.identifier.kind.ident)) {
            return b.remote(recv.identifier.kind.ident, cc.callee, try this.callArgs(b, null, cc));
        }
        // Activated extension dispatch: `recv.m(args)` → the local `m(Recv, args)`
        // emitted by `extensionForms`.
        if (this.rewrites.get(loc)) |sym| {
            // The activated block may belong to another module
            // (`import {PatoNada*} from "pond"`), where the method is emitted as
            // a bare exported function: reach it remotely.
            if (!this.ext_names.contains(sym)) {
                if (this.cross) |xc| if (xc.ownerModuleAtom(sym)) |owner| {
                    return b.remote(owner, cc.callee, try this.callArgs(b, try this.exprNode(b, recv.*), cc));
                };
            }
            return b.call(cc.callee, try this.callArgs(b, try this.exprNode(b, recv.*), cc));
        }
        if (mod_name) |name| {
            // Qualified extension call `Sym.m(obj)`: the receiver names the
            // extension block, not a module — the local `m(obj)`.
            if (this.ext_names.contains(name)) return b.call(cc.callee, try this.callArgs(b, null, cc));
            // Qualified enum payload constructor `Color.Rgb(r, g, b)` → the tagged
            // tuple `{'Rgb', R, G, B}` (the case-arm constructor pattern shape).
            if (this.enum_names.contains(name)) {
                const items = try b.arena.alloc(Ast.Expr, cc.args.len + 1);
                items[0] = Ast.Expr.a(cc.callee);
                for (cc.args, 1..) |arg, i| items[i] = try this.exprNode(b, arg.value.*);
                return .{ .tuple = items };
            }
            // Associated fn of an IMPORTED record (`Response.ok(...)` from
            // `"web"`): a remote call into the owning module (`http:ok(...)`).
            if (this.imported_types.get(name)) |owner| {
                return b.remote(owner, cc.callee, try this.callArgs(b, null, cc));
            }
            // Associated fn of a LOCAL record: a local function of this module.
            if (this.record_fields.contains(name)) return b.call(cc.callee, try this.callArgs(b, null, cc));
            // Associated `default fn` of an interface (`Array.range`): the mangled
            // local `'<Interface>_<method>'` that `interfaceForms` emits.
            if (this.isInterfaceAssoc(name, cc.callee)) {
                var mraw: [256]u8 = undefined;
                const mname = try interfaceAssocAtom(&mraw, name, cc.callee);
                return b.call(try b.arena.dupe(u8, mname), try this.callArgs(b, null, cc));
            }
            // Any other PascalCase receiver is a module: `List.map(xs, f)` →
            // `list:map(Xs, F)`.
            const mod = try erlangModule(b.arena, name);
            return b.remote(mod, cc.callee, try this.callArgs(b, null, cc));
        }
        if (this.instance_lowerings.get(loc)) |il| switch (il) {
            // Builtin-primitive method (`xs.map(f)`, `s.split(sep)`): the host op.
            .prim => |k| return this.primMethodNode(b, k, cc.callee, recv, cc),
            // Record/struct/enum instance method: a function taking the receiver
            // first — local `m(Recv, args)`, or `owner:m(Recv, args)` for an
            // imported type. A method name shared by two records is mangled to
            // `<recordtype>_<method>` so the flat fn namespace stays unambiguous.
            .type_ => |tn| return this.typedMethodNode(b, tn, recv, cc),
        };
        // Inside an ADOPTED interface `default fn` body (`implement Sized`'s
        // `isEmpty`, emitted as one of the record's functions) inference records
        // no lowering — the method is declared on the behavior, not on the
        // record — but `self` is known to be that record.
        if (this.self_record_type) |tn| {
            if (isSelfIdent(recv.*)) return this.typedMethodNode(b, tn, recv, cc);
        }
        // Inside an interface instance `default fn` the receiver's type is
        // `Self`, which inference leaves unlowered (it is generic over every
        // implementor): dispatch on the owning interface's primitive kind.
        if (this.selfPrimKind(recv.*)) |k| return this.primMethodNode(b, k, cc.callee, recv, cc);
        // A value receiver with no recorded lowering (inference bailed out, e.g.
        // on a chained call): try the Array primitive defaults and the universal
        // `toString` before the bare `m(Recv, args)` call.
        if (try this.arrayPrimFallbackNode(b, cc.callee, recv, cc)) |node| return node;
        // A comptime body has no types at all: dispatch on the receiver at runtime.
        // A comptime body has no types at all, and a typed module whose inference
        // recorded no lowering here (a method on `Array.range(0, 5)`'s result, a
        // local inside an inlined interface default) does not know the receiver
        // either: dispatch on it at runtime — unless the module defines a
        // function of that name taking the receiver first.
        if (this.untyped or !this.local_fn_arities.contains(try std.fmt.allocPrint(b.arena, "{s}/{d}", .{ cc.callee, cc.args.len + cc.trailing.len + 1 }))) {
            if (try this.untypedPrimCallNode(b, loc, recv, cc)) |node| return node;
        }
        if (std.mem.eql(u8, cc.callee, "toString") and cc.args.len == 0) return this.formatNode(b, recv);
        // A field of function type called like a method on a receiver inference
        // left untyped (`c.set(9)` where some record declares `set: fn(…)`):
        // apply what the field holds. A function of that name taking the
        // receiver first wins — that is a real method.
        if (this.fn_typed_field_names.contains(cc.callee) and
            this.importedFnOwner(cc.callee, cc.args.len + cc.trailing.len + 1) == null and
            !this.local_fn_arities.contains(try std.fmt.allocPrint(b.arena, "{s}/{d}", .{ cc.callee, cc.args.len + cc.trailing.len + 1 })))
        {
            return .{ .apply = .{
                .fun = try b.ptr(try b.paren(try b.remote("maps", "get", &.{ Ast.Expr.a(cc.callee), try this.exprNode(b, recv.*) }))),
                .args = try this.callArgs(b, null, cc),
            } };
        }
        // A method of an IMPORTED record whose receiver inference left untyped
        // (`when(...).thenReturn(v)` — a method on a call's result): the owner
        // emits it as a bare function taking the receiver first, so reach it
        // there instead of calling a local this module never defines.
        if (this.importedFnOwner(cc.callee, cc.args.len + cc.trailing.len + 1)) |owner| {
            return b.remote(owner, cc.callee, try this.callArgs(b, try this.exprNode(b, recv.*), cc));
        }
        return b.call(cc.callee, try this.callArgs(b, try this.exprNode(b, recv.*), cc));
    }

    /// Call arguments: `first` (a receiver passed positionally), the positional
    /// arguments, then trailing lambdas as funs.
    fn callArgs(this: *Emitter, b: Ast.Builder, first: ?Ast.Expr, cc: anytype) anyerror![]const Ast.Expr {
        var out: std.ArrayListUnmanaged(Ast.Expr) = .empty;
        if (first) |f| try out.append(b.arena, f);
        for (cc.args) |arg| try out.append(b.arena, try this.exprNode(b, arg.value.*));
        for (cc.trailing) |tl| try out.append(b.arena, try this.trailingFunNode(b, tl));
        return out.items;
    }

    /// `iolist_to_binary(io_lib:format("~p", [Value]))` — any value as text.
    fn formatNode(this: *Emitter, b: Ast.Builder, value: *const ast.Expr) anyerror!Ast.Expr {
        const format = try b.remote("io_lib", "format", &.{ .{ .string = "~p" }, try b.list(&.{try this.exprNode(b, value.*)}) });
        return b.call("iolist_to_binary", &.{format});
    }

    fn bindingNode(this: *Emitter, b: Ast.Builder, bind: anytype) anyerror!Ast.Expr {
        switch (bind.kind) {
            .localBind => |lb| {
                if (lb.mutable) try this.mutable_locals.put(this.alloc, lb.name, {});
                return this.bindExpr(b, lb.name, .bind, lb.value.*);
            },
            .assign => |a| switch (a.target) {
                .name => |name| return this.bindExpr(b, name, switch (a.op) {
                    .assign => .assign,
                    .plusAssign => .plus_assign,
                }, a.value.*),
                // Maps are immutable; a field assignment has no Erlang form.
                .fieldAccess => |fa| return .{ .comment = Ast.Comment.doc(try std.fmt.allocPrint(b.arena, "self.{s} = ...", .{fa.field})) },
            },
            .localBindDestruct => |lb| switch (lb.pattern) {
                .names, .tuple_ => {
                    // The value reads the names BEFORE the pattern rebinds them.
                    const value = try this.exprNode(b, lb.value.*);
                    return b.match(try this.destructPatternExpr(b, lb.pattern), value);
                },
                // List / constructor patterns are not lowered yet: the value alone.
                .list, .ctor => return this.exprNode(b, lb.value.*),
            },
        }
    }

    /// A comptime block's statements up to its first `break`, then the value
    /// that `break` carries (semantics decision 2: a block's value comes from
    /// `break`). It used to lower to the `break` expression alone, dropping
    /// the `val`s it reads — `result() -> (X * 2).` did not compile. A block
    /// with no `break`, or a bare one, is valueless: `ok`.
    fn comptimeBlockBody(this: *Emitter, b: Ast.Builder, body: []const ast.Stmt, indent: usize) anyerror!Ast.Body {
        var end = body.len;
        var value: ?*const ast.Expr = null;
        for (body, 0..) |stmt, i| {
            if (stmt.expr == .jump and stmt.expr.jump.kind == .@"break") {
                end = i;
                value = stmt.expr.jump.kind.@"break".value;
                break;
            }
        }
        var stmts: std.ArrayListUnmanaged(Ast.Stmt) = .empty;
        try stmts.appendSlice(b.arena, (try this.bodyNode(b, body[0..end], 0, indent)).stmts);
        const saved = this.indent;
        this.indent = indent;
        defer this.indent = saved;
        try stmts.append(b.arena, .{ .expr = if (value) |v| try this.exprNode(b, v.*) else Ast.Expr.a("ok") });
        return .{ .stmts = stmts.items };
    }

    fn comptimeNode(this: *Emitter, b: Ast.Builder, ct: anytype) anyerror!Ast.Expr {
        const V = Ast.Expr.v;
        const A = Ast.Expr.a;
        switch (ct.kind) {
            .comptimeExpr => |inner| return this.exprNode(b, inner.*),
            // A comptime block in expression position is an applied fun over
            // its statements, so the `val`s before its `break` stay bound.
            .comptimeBlock => |cb| return b.applyParen(.{ .fun = .{
                .params = &.{},
                .body = try this.comptimeBlockBody(b, cb.body, this.indent + 1),
            } }, &.{}),
            .assert => |a| {
                const cond = try b.paren(try this.exprNode(b, a.condition.*));
                // Always fatal, with the message and the `file:line` (semantics
                // decision 4): a failed assert raises `{bp_assert, Msg, Where}`.
                // The test runner catches it per test and continues; outside
                // test mode nothing does. `true = (Cond)` dropped both.
                const message = if (a.message) |msg| try this.exprNode(b, msg.*) else Ast.str("assertion failed");
                const where: Ast.Expr = .{ .lexeme_binary = try std.fmt.allocPrint(b.arena, "{s}.bp:{d}", .{ this.module_name, ct.loc.line }) };
                const raise = try b.remote("erlang", "error", &.{try b.tuple(&.{ A("bp_assert"), message, where })});
                return b.caseInline(cond, &.{
                    try b.clause(&.{A("true")}, &.{}, &.{A("ok")}),
                    try b.clause(&.{V("_")}, &.{}, &.{raise}),
                });
            },
            // `case E of Pat -> E; _ -> Handler end`.
            .assertPattern => |ap| {
                const subject = try this.exprNode(b, ap.expr.*);
                const pattern = try this.patternNode(b, ap.pattern);
                const matched = try this.exprNode(b, ap.expr.*);
                const handler = try this.exprNode(b, ap.handler.*);
                return b.caseInline(subject, &.{
                    try b.clause(&.{pattern}, &.{}, &.{matched}),
                    try b.clause(&.{V("_")}, &.{}, &.{handler}),
                });
            },
        }
    }

    // ── case expression ───────────────────────────────────────────────────────

    /// `case Subject of Pat -> Body; … end`. A multi-subject case matches a tuple
    /// of the subjects; an OR pattern expands to one clause per alternative with
    /// the same body.
    fn caseNode(this: *Emitter, b: Ast.Builder, subjects: []ast.Expr, arms: []ast.CaseArm) anyerror!Ast.Expr {
        const subject: Ast.Expr = if (subjects.len == 1)
            try this.exprNode(b, subjects[0])
        else blk: {
            const items = try b.arena.alloc(Ast.Expr, subjects.len);
            for (subjects, 0..) |subj, i| items[i] = try this.exprNode(b, subj);
            break :blk .{ .tuple = items };
        };
        const body_indent = this.indent + 2;
        var clauses: std.ArrayListUnmanaged(Ast.Clause) = .empty;
        for (arms) |arm| {
            // The pattern is lowered FIRST: it binds the names the guard and the
            // body then read at their arm-local versions (`patternBindVar`).
            // `pattern if <guard> -> body` becomes an erlang clause guard — the
            // arm only matches when the pattern matches AND the guard holds; a
            // dropped guard makes the first arm swallow every subject.
            switch (arm.pattern) {
                .@"or" => |pats| for (pats) |pat| {
                    const pattern = try this.patternNode(b, pat);
                    try clauses.append(b.arena, .{
                        .patterns = try b.exprs(&.{pattern}),
                        .guards = try this.armGuards(b, arm.guard),
                        .body = try this.caseBodyNode(b, arm.body, body_indent),
                    });
                },
                else => {
                    const pattern = try this.patternNode(b, arm.pattern);
                    try clauses.append(b.arena, .{
                        .patterns = try b.exprs(&.{pattern}),
                        .guards = try this.armGuards(b, arm.guard),
                        .body = try this.caseBodyNode(b, arm.body, body_indent),
                    });
                },
            }
        }
        return b.caseOf(subject, clauses.items);
    }

    /// The guard sequence of a case arm, rendered after its pattern so the guard
    /// reads the names the pattern just bound.
    fn armGuards(this: *Emitter, b: Ast.Builder, guard: ?ast.Expr) anyerror![]const Ast.Expr {
        const g = guard orelse return &.{};
        return b.exprs(&.{try this.exprNode(b, g)});
    }

    /// A case arm body at `indent`: a lambda block's statements, or the single
    /// expression.
    fn caseBodyNode(this: *Emitter, b: Ast.Builder, body: ast.Expr, indent: usize) anyerror!Ast.Body {
        if (body == .function and body.function.kind.syntax == .lambda) {
            return this.bodyNode(b, body.function.kind.body, 0, indent);
        }
        const saved = this.indent;
        this.indent = indent;
        defer this.indent = saved;
        return b.body(&.{try this.exprNode(b, body)});
    }

    fn patternNode(this: *Emitter, b: Ast.Builder, pat: ast.Pattern) anyerror!Ast.Expr {
        switch (pat) {
            .wildcard => return Ast.Expr.v("_"),
            // A bare ident pattern is either a nullary enum variant (→ the atom
            // `'Lt'`) or a binding (→ an erlang variable `X`).
            .ident => |n| return if (this.enum_variants.contains(n)) Ast.Expr.a(n) else Ast.Expr.v(try this.patternBindVar(b, n)),
            .numberLit => |n| return .{ .number = n },
            .stringLit => |str| return .{ .lexeme_binary = str },
            // Variant patterns mirror what the constructor builds: the tagged
            // tuple `{'Rgb', R, G, B}` for a payload, the bare atom `'Lt'`
            // without one. (The old `{tag, Name, …}` shape both bound `Name` as
            // a fresh variable and added an element no constructor ever
            // materialised, so every arm failed with `case_clause`.)
            .variant => |v| {
                var items: std.ArrayListUnmanaged(Ast.Expr) = .empty;
                try items.append(b.arena, Ast.Expr.a(this.variantTag(v.name)));
                switch (v.payload) {
                    .binding => |binding| try items.append(b.arena, Ast.Expr.v(try this.patternBindVar(b, binding))),
                    .fields => |fields| for (fields) |f| try items.append(b.arena, Ast.Expr.v(try this.patternBindVar(b, f))),
                    .literals => |args| for (args) |arg| try items.append(b.arena, try this.patternNode(b, arg)),
                }
                if (items.items.len == 1) return Ast.Expr.a(this.variantTag(v.name));
                return .{ .tuple = items.items };
            },
            .list => |lp| {
                const elems = try b.arena.alloc(Ast.Expr, lp.elems.len);
                for (lp.elems, 0..) |elem, i| elems[i] = try this.listPatElemNode(b, elem);
                const sp = lp.spread orelse return .{ .list = elems };
                if (lp.elems.len == 0 and sp.len == 0) return Ast.Expr.v("_");
                const tail = if (sp.len > 0) Ast.Expr.v(try this.patternBindVar(b, sp)) else Ast.Expr.v("_");
                // `[Rest]` when only a named spread is present (as the backend has always written it).
                if (lp.elems.len == 0) return b.list(&.{tail});
                return b.cons(elems, tail);
            },
            // Expanded by `caseNode`; elsewhere the first alternative stands in.
            .@"or" => |pats| return if (pats.len > 0) this.patternNode(b, pats[0]) else error.EmptyOrPattern,
            .multi => |pats| {
                const items = try b.arena.alloc(Ast.Expr, pats.len);
                for (pats, 0..) |p, i| items[i] = try this.patternNode(b, p);
                return .{ .tuple = items };
            },
        }
    }

    /// The runtime tag atom of a variant pattern. `@Result` is materialised as
    /// `{ok, V}` / `{error, E}` by the `#[@result]` transform, so its `Ok`/`Err`
    /// arms match those lowercase tags. A user enum variant of the same name
    /// (recorded in `enum_variants`) keeps its own name.
    fn variantTag(this: *const Emitter, name: []const u8) []const u8 {
        if (this.enum_variants.contains(name)) return name;
        return resultTag(name) orelse name;
    }

    /// The `@Result` runtime tag a constructor name builds, or null when the
    /// name is not one of `Ok` / `Err` / `Error`.
    fn resultTag(name: []const u8) ?[]const u8 {
        if (std.mem.eql(u8, name, "Ok")) return "ok";
        if (std.mem.eql(u8, name, "Err") or std.mem.eql(u8, name, "Error")) return "error";
        return null;
    }

    fn listPatElemNode(this: *Emitter, b: Ast.Builder, elem: ast.ListPatternElem) anyerror!Ast.Expr {
        return switch (elem) {
            .wildcard => Ast.Expr.v("_"),
            .bind => |name| Ast.Expr.v(try this.patternBindVar(b, name)),
            .numberLit => |n| .{ .number = n },
        };
    }

    // ── builtin-primitive method lowering ─────────────────────────────────────

    /// The `i`-th argument of a call: a positional argument, then trailing
    /// lambdas as funs; `undefined` when not supplied (an optional-arg method
    /// form). Receiver and arguments are reordered to fit host signatures.
    fn argNode(this: *Emitter, b: Ast.Builder, cc: anytype, i: usize) anyerror!Ast.Expr {
        if (i < cc.args.len) return this.exprNode(b, cc.args[i].value.*);
        if (i - cc.args.len >= cc.trailing.len) return Ast.Expr.a("undefined");
        return this.trailingFunNode(b, cc.trailing[i - cc.args.len]);
    }

    /// A trailing lambda `{ a, b -> … }` as `fun(A, B) -> … end`.
    fn trailingFunNode(this: *Emitter, b: Ast.Builder, tl: anytype) anyerror!Ast.Expr {
        const params = try b.arena.alloc(Ast.Expr, tl.params.len);
        for (tl.params, 0..) |p, i| {
            params[i] = Ast.Expr.v(try this.arenaVar(b, p));
            this.addLocal(p);
        }
        return .{ .fun = .{ .params = params, .body = try this.bodyNode(b, tl.body, 0, this.indent + 1) } };
    }

    /// A builtin-primitive instance method lowered to its erlang host operation
    /// (arrays are lists, strings binaries, numbers/bools native). Most methods
    /// are annotation-driven (`primitives.d.bp` `@external(erlang, …)`
    /// templates); the inline cases below don't reduce to a template. An
    /// unmapped method is a bare local `m(Recv, args)` call (a clear runtime
    /// error if truly unsupported) rather than invalid `Recv:m(args)` syntax.
    fn primMethodNode(this: *Emitter, b: Ast.Builder, k: envMod.PrimKind, callee: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!Ast.Expr {
        if (try this.primHostMethodNode(b, k, callee, recv, cc)) |node| return node;
        // Pure-botopink instance `default fn` (`xs.all(pred)`, `n.clamp(lo, hi)`):
        // the local form emitted on demand at the end of the module.
        if (try this.ifaceDefaultNode(b, k, callee, recv, cc)) |node| return node;
        var args: std.ArrayListUnmanaged(Ast.Expr) = .empty;
        try args.append(b.arena, try this.exprNode(b, recv.*));
        for (cc.args) |arg| try args.append(b.arena, try this.exprNode(b, arg.value.*));
        return b.call(callee, args.items);
    }

    /// The host-op half of `primMethodNode`: the `@external(erlang, …)`
    /// annotation, the inline cases and the Array fallbacks — null when none
    /// answers (an instance `default fn` or nothing).
    fn primHostMethodNode(this: *Emitter, b: Ast.Builder, k: envMod.PrimKind, callee: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!?Ast.Expr {
        const eq = std.mem.eql;
        if (try this.primAnnotationNode(b, k, callee, recv, cc)) |node| return node;
        switch (k) {
            .array => if (eq(u8, callee, "len") or eq(u8, callee, "length") or eq(u8, callee, "size")) {
                return try b.call("length", &.{try this.exprNode(b, recv.*)});
            },
            // `toString` is declared on `Integer`/`Float` with host annotations;
            // this covers a numeric receiver the interface chain doesn't know.
            .int => if (eq(u8, callee, "toString")) return try b.call("integer_to_binary", &.{try this.exprNode(b, recv.*)}),
            .float => if (eq(u8, callee, "toString")) return try b.call("float_to_binary", &.{try this.exprNode(b, recv.*)}),
            .string, .bool => {},
        }
        // Array default fns without an `@external` annotation (or a chained call
        // the inferer didn't tag) use the canonical host op directly.
        if (k == .array) {
            if (try this.arrayPrimFallbackNode(b, callee, recv, cc)) |node| return node;
        }
        return null;
    }

    // ── comptime-body primitive dispatch ──────────────────────────────────────
    //
    // A comptime body (`emitComptimeModule`) has no inferred types, so a method
    // call's receiver kind is unknown when it is lowered. `recv.m(args)` becomes
    // `'__bp_prim_m'(Recv, Args…)`, and one shim per reached `(m, argc)` carries
    // a clause per primitive kind that answers `m` — the clause body is
    // `primMethodNode`'s own lowering of that kind, guarded by the kind's runtime
    // test (`is_list`, `is_binary`, …) — then a clause that raises. The typed
    // tables (`prim_erlang_dispatch`, the prelude's instance defaults) stay the
    // single source of truth.

    /// The call a shim clause lowers: the receiver `recv` and the positional
    /// arguments `arg0…` (→ `Recv`, `Arg0…`).
    const ShimCall = struct {
        recv: *ast.Expr,
        args: []const ast.CallArg,
        trailing: []const ast.TrailingLambda = &.{},
    };

    fn shimIdent(b: Ast.Builder, name: []const u8) !*ast.Expr {
        const e = try b.arena.create(ast.Expr);
        e.* = .{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .ident = name } } };
        return e;
    }

    /// True when `externalWrapperForm` will emit a body for `f` — the export
    /// pass reads it so `-export` never names a function the decl loop skips.
    /// Mirrors `userTemplateNode`: a `module:symbol` external always renders; a
    /// template renders when its text is non-empty, an arity-branched one when a
    /// branch matches the declared parameter count.
    fn externalWrapperEmits(this: *const Emitter, f: ast.FnDecl) bool {
        if (this.externals.contains(f.name)) return true;
        const call = this.user_erlang_templates.get(f.name) orelse return false;
        if (call.arity_branches.len == 0) return call.symbol.len > 0;
        for (call.arity_branches) |branch| if (branch.argc == f.params.len) return true;
        return false;
    }

    /// A host-backed `declare fn` emits no function of its own — its annotation
    /// renders at each call site — so another module had nothing to call
    /// (`function hostKey/1 undefined`). The owner answers it with a wrapper
    /// whose body is that same rendering over the wrapper's own parameters: the
    /// erlang twin of the commonJS `exports.name = name` re-export. Emitted only
    /// for a `pub` external some module imports, so single-module programs and
    /// unconsumed declarations are unchanged. Null exactly when
    /// `externalWrapperEmits` is false — there is nothing to render, and the
    /// consumer keeps its bare call so erlc names the gap.
    fn externalWrapperForm(this: *Emitter, b: Ast.Builder, f: ast.FnDecl) !?Ast.Form {
        const arity = f.params.len;
        // A fresh local scope, as `fnForms` opens for a bodied function.
        this.resetLocals();
        const args = try b.arena.alloc(ast.CallArg, arity);
        const patterns = try b.arena.alloc(Ast.Expr, arity);
        for (f.params, 0..) |p, i| {
            // The declared parameter name reads better than a synthetic one
            // (`hostKey(V)`, not `hostKey(A0)`); `_`-prefixed and duplicate
            // names are the author's problem, as in any other emitted function.
            args[i] = .{ .label = null, .value = try shimIdent(b, p.name) };
            patterns[i] = Ast.Expr.v(try this.arenaVar(b, p.name));
            this.addLocal(p.name);
            if (isNullableParam(p)) try this.nullable_locals.put(p.name, {});
            if (isStringType(p.typeRef)) try this.string_locals.put(p.name, {});
            if (numTypeKind(p.typeRef)) |k| try this.num_locals.put(this.alloc, p.name, k);
        }
        const cc = .{
            .callee = f.name,
            .receiver = @as(?*const ast.Expr, null),
            .args = args,
            .trailing = @as([]const ast.TrailingLambda, &.{}),
        };
        const saved = this.indent;
        this.indent = 1;
        defer this.indent = saved;
        const body: Ast.Expr = if (this.user_erlang_templates.contains(f.name))
            (try this.userTemplateNode(b, f.name, cc)) orelse return null
        else if (this.externals.get(f.name)) |ref|
            try b.remote(ref.module, ref.symbol, try this.callArgs(b, null, cc))
        else
            return null;
        return try blockFunction(b, f.name, patterns, try b.body(&.{body}));
    }

    fn shimCall(b: Ast.Builder, argc: usize) !ShimCall {
        const args = try b.arena.alloc(ast.CallArg, argc);
        for (args, 0..) |*arg, i| arg.* = .{
            .label = null,
            .value = try shimIdent(b, try std.fmt.allocPrint(b.arena, "arg{d}", .{i})),
        };
        return .{ .recv = try shimIdent(b, "recv"), .args = args };
    }

    /// The instance `default fn` kind `k` answers `callee` with, when it accepts
    /// `argc` arguments (the ones past `argc` all carry a default).
    fn primDefaultFor(this: *const Emitter, k: envMod.PrimKind, callee: []const u8, argc: usize) ?IfaceDefault {
        const head_iface = primIfaceForKind(k) orelse return null;
        var iface_walk = PrimIfaceWalker.init(this, head_iface, &this.prim_iface_chain);
        while (iface_walk.next()) |iface_name| {
            var key_buf: [256]u8 = undefined;
            const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ iface_name, callee }) catch return null;
            const d = this.iface_instance_defaults.get(key) orelse continue;
            const params = d.method.params[1..];
            if (argc > params.len) return null;
            for (params[argc..]) |p| if (p.default == null) return null;
            return d;
        }
        return null;
    }

    /// True when some primitive kind lowers `callee` called with `argc`
    /// arguments. Builds (and drops) the lowering, so it agrees with the shim.
    fn primMethodAnswered(this: *Emitter, b: Ast.Builder, callee: []const u8, argc: usize) anyerror!bool {
        const call = try shimCall(b, argc);
        for (prim_shim_kinds) |pk| {
            if (try this.primHostMethodNode(b, pk.kind, callee, call.recv, call) != null) return true;
            if (this.primDefaultFor(pk.kind, callee, argc) != null) return true;
        }
        return false;
    }

    /// True when a host form defines `name/arity` — in this module or in the
    /// resident prelude it imports.
    fn isHostFunction(this: *const Emitter, name: []const u8, arity: usize) bool {
        for ([_][]const Ast.Form{ this.host_forms, this.resident_forms }) |forms| {
            for (forms) |form| switch (form) {
                .function => |f| {
                    if (!std.mem.eql(u8, f.name, name)) continue;
                    for (f.clauses) |c| if (c.patterns.len == arity) return true;
                },
                else => {},
            };
        }
        return false;
    }

    /// A comptime body's value-receiver method call: the shim call when some
    /// primitive kind answers it; null when a host form defines it (`q.text()`,
    /// `decl.fail(msg)`) or nothing does. In the latter case, when the module
    /// asked for it (`ComptimeModule.unsupported_method`), the call is recorded
    /// and the emit fails instead.
    fn untypedPrimCallNode(this: *Emitter, b: Ast.Builder, loc: ast.Loc, recv: *const ast.Expr, cc: anytype) anyerror!?Ast.Expr {
        const argc = cc.args.len + cc.trailing.len;
        if (this.isHostFunction(cc.callee, argc + 1)) return null;
        if (!try this.primMethodAnswered(b, cc.callee, argc)) {
            if (this.unsupported_method) |slot| {
                slot.* = .{ .callee = cc.callee, .argc = argc, .loc = loc };
                return error.UnsupportedComptimeMethod;
            }
            return null;
        }
        const key = try std.fmt.allocPrint(this.alloc, "{s}/{d}", .{ cc.callee, argc });
        const entry = try this.prim_shims.getOrPut(this.alloc, key);
        if (entry.found_existing) {
            this.alloc.free(key);
        } else {
            entry.value_ptr.* = .{ .callee = cc.callee, .argc = argc };
        }
        const name = try std.fmt.allocPrint(b.arena, prim_shim_prefix ++ "{s}", .{cc.callee});
        return try b.call(name, try this.callArgs(b, try this.exprNode(b, recv.*), cc));
    }

    /// Emit every shim the body reached, and the instance `default fn`s their
    /// clauses reach. A default body may itself reach a new shim
    /// (`out.append(x)` on a local), so both lists are drained to a fixpoint.
    fn primShimForms(this: *Emitter, b: Ast.Builder, out: *Forms) !void {
        var next_shim: usize = 0;
        // Defaults a call site reached were already emitted above the host block.
        var next_default = this.needed_instance_defaults.count();
        while (true) {
            if (next_shim < this.prim_shims.count()) {
                const shim = this.prim_shims.values()[next_shim];
                next_shim += 1;
                try out.appendSlice(b.arena, &.{ .blank, try this.primShimForm(b, shim) });
            } else if (next_default < this.needed_instance_defaults.count()) {
                const d = this.needed_instance_defaults.values()[next_default];
                next_default += 1;
                try this.instanceDefaultForm(b, out, d);
            } else break;
        }
    }

    /// `'__bp_prim_<callee>'(Recv, Arg0, …)`: one guarded clause per primitive
    /// kind that answers the call, then a clause that raises
    /// `{bp_unsupported_method, <<"callee">>, Argc, Recv}` — or, for `toString/0`,
    /// formats any other term the way `'__bp_text'/1` does.
    fn primShimForm(this: *Emitter, b: Ast.Builder, shim: PrimShim) !Ast.Form {
        this.resetLocals();
        const call = try shimCall(b, shim.argc);
        const patterns = try b.arena.alloc(Ast.Expr, shim.argc + 1);
        patterns[0] = Ast.Expr.v("Recv");
        this.addLocal("recv");
        for (call.args, 1..) |arg, i| {
            const name = arg.value.identifier.kind.ident;
            patterns[i] = Ast.Expr.v(try this.arenaVar(b, name));
            this.addLocal(name);
        }
        const saved_indent = this.indent;
        this.indent = 1;
        defer this.indent = saved_indent;

        var clauses: std.ArrayListUnmanaged(Ast.Clause) = .empty;
        for (prim_shim_kinds) |pk| {
            const node = (try this.primHostMethodNode(b, pk.kind, shim.callee, call.recv, call)) orelse
                (try this.primDefaultShimNode(b, pk.kind, shim, call)) orelse continue;
            try clauses.append(b.arena, .{
                .patterns = patterns,
                .guards = try b.exprs(&.{pk.guard}),
                .body = try b.body(&.{node}),
            });
        }

        const fallback_patterns = try b.arena.alloc(Ast.Expr, shim.argc + 1);
        fallback_patterns[0] = Ast.Expr.v("Recv");
        for (fallback_patterns[1..]) |*p| p.* = Ast.Expr.v("_");
        const fallback = if (std.mem.eql(u8, shim.callee, "toString") and shim.argc == 0)
            try b.call("__bp_text", &.{Ast.Expr.v("Recv")})
        else
            try b.remote("erlang", "error", &.{try b.tuple(&.{
                Ast.Expr.a("bp_unsupported_method"),
                Ast.str(shim.callee),
                Ast.Expr.t(Term.int(@intCast(shim.argc))),
                Ast.Expr.v("Recv"),
            })});
        try clauses.append(b.arena, .{ .patterns = fallback_patterns, .body = try b.body(&.{fallback}) });

        const name = try std.fmt.allocPrint(b.arena, prim_shim_prefix ++ "{s}", .{shim.callee});
        return b.functionClauses(name, clauses.items);
    }

    /// A shim clause reaching an instance `default fn`: `<Iface>_<method>(Recv,
    /// Arg0, …)` with every omitted trailing parameter filled from its declared
    /// default (`s.slice(1)` → `'String_slice'(Recv, Arg0, undefined)`).
    fn primDefaultShimNode(this: *Emitter, b: Ast.Builder, k: envMod.PrimKind, shim: PrimShim, call: ShimCall) anyerror!?Ast.Expr {
        const d = this.primDefaultFor(k, shim.callee, shim.argc) orelse return null;
        const params = d.method.params[1..];
        const args = try b.arena.alloc(ast.CallArg, params.len);
        for (args, 0..) |*arg, i| {
            if (i < shim.argc) {
                arg.* = call.args[i];
                continue;
            }
            const value = try b.arena.create(ast.Expr);
            value.* = params[i].default.?;
            arg.* = .{ .label = null, .value = value };
        }
        const padded: ShimCall = .{ .recv = call.recv, .args = args };
        return this.ifaceDefaultNode(b, k, shim.callee, padded.recv, padded);
    }

    /// A value-receiver call that resolves to an interface instance `default fn`
    /// → the local `<iface>_<method>(Recv, args)` form, and a note that the form
    /// is needed. Walks the receiver's `extends` chain, so `n.clamp(0, 5)` on an
    /// `i32` finds `Number.clamp`. Null when no interface in the chain declares
    /// `callee` as a bodied instance default — the caller then falls back to the
    /// bare `callee(Recv, args)` call.
    fn ifaceDefaultNode(this: *Emitter, b: Ast.Builder, k: envMod.PrimKind, callee: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!?Ast.Expr {
        const head_iface = primIfaceForKind(k) orelse return null;
        var iface_walk = PrimIfaceWalker.init(this, head_iface, &this.prim_iface_chain);
        while (iface_walk.next()) |iface_name| {
            var key_buf: [256]u8 = undefined;
            const key = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ iface_name, callee }) catch return null;
            const hit = this.iface_instance_defaults.getEntry(key) orelse continue;
            // The key is owned by `iface_instance_defaults`, which outlives the
            // needed-set, so the borrow is safe.
            try this.needed_instance_defaults.put(this.alloc, hit.key_ptr.*, hit.value_ptr.*);
            var mbuf: [256]u8 = undefined;
            const mangled = interfaceAssocAtom(&mbuf, iface_name, callee) catch return null;
            const head = try b.arena.dupe(u8, mangled);
            return try b.call(head, try this.callArgs(b, try this.exprNode(b, recv.*), cc));
        }
        return null;
    }

    /// Emit the interface instance `default fn`s some call site reached, as
    /// `<iface>_<method>(Self, …)` forms. Draining is a fixpoint walk: a default
    /// body may itself call another default (`String.slice` → nothing, but
    /// `Array.append` → `Array.slice`), which appends to the same list.
    fn instanceDefaultForms(this: *Emitter, b: Ast.Builder, out: *Forms) !void {
        var i: usize = 0;
        while (i < this.needed_instance_defaults.count()) : (i += 1) {
            try this.instanceDefaultForm(b, out, this.needed_instance_defaults.values()[i]);
        }
    }

    /// One reached instance `default fn` as its `<iface>_<method>(Self, …)`
    /// form, lowered with `self` known to be the interface's primitive kind.
    fn instanceDefaultForm(this: *Emitter, b: Ast.Builder, out: *Forms, d: IfaceDefault) !void {
        const saved_kind = this.self_prim_kind;
        const saved_in = this.in_iface_default;
        defer {
            this.self_prim_kind = saved_kind;
            this.in_iface_default = saved_in;
        }
        this.in_iface_default = true;
        var mbuf: [256]u8 = undefined;
        const mangled = interfaceAssocAtom(&mbuf, d.iface, d.method.name) catch return;
        this.self_prim_kind = this.primKindForIface(d.iface);
        try this.methodForms(b, out, try b.arena.dupe(u8, mangled), d.method);
    }

    /// The std Array default fns as erlang BIFs (`forEach`/`fold`/`drop`/
    /// `take`/`toList`), or null for any other method.
    fn arrayPrimFallbackNode(this: *Emitter, b: Ast.Builder, callee: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!?Ast.Expr {
        const eq = std.mem.eql;
        const arity = cc.args.len + cc.trailing.len;
        // `xs.forEach(action)` → `lists:foreach(Action, Xs)`.
        if (eq(u8, callee, "forEach") and arity == 1) {
            const action = try this.argNode(b, cc, 0);
            return try b.remote("lists", "foreach", &.{ action, try this.exprNode(b, recv.*) });
        }
        // `xs.fold(init, f)` → `lists:foldl(fun(__X, __A) -> (F)(__A, __X) end, Init, Xs)`:
        // botopink's `f(acc, x)` order is swapped inside the wrapper.
        if (eq(u8, callee, "fold") and arity == 2) {
            const f = try this.argNode(b, cc, 1);
            const step: Ast.Expr = .{ .fun_clauses = try b.arena.dupe(Ast.Clause, &.{
                try b.clause(&.{ Ast.Expr.v("__X"), Ast.Expr.v("__A") }, &.{}, &.{try b.applyParen(f, &.{ Ast.Expr.v("__A"), Ast.Expr.v("__X") })}),
            }) };
            const initial = try this.argNode(b, cc, 0);
            return try b.remote("lists", "foldl", &.{ step, initial, try this.exprNode(b, recv.*) });
        }
        // `xs.drop(n)` → `lists:nthtail(N, Xs)` (panics out of bounds, matching
        // the default fn's in-bounds contract).
        if (eq(u8, callee, "drop") and cc.args.len == 1) {
            const n = try this.exprNode(b, cc.args[0].value.*);
            return try b.remote("lists", "nthtail", &.{ n, try this.exprNode(b, recv.*) });
        }
        // `xs.take(n)` → `lists:sublist(Xs, N)`.
        if (eq(u8, callee, "take") and cc.args.len == 1) {
            const xs = try this.exprNode(b, recv.*);
            return try b.remote("lists", "sublist", &.{ xs, try this.exprNode(b, cc.args[0].value.*) });
        }
        // `xs.toList()` — an `Array<T>` is already a list.
        if (eq(u8, callee, "toList") and cc.args.len == 0) return try this.exprNode(b, recv.*);
        return null;
    }

    // ── record / enum / interface / extensions ────────────────────────────────

    /// A method as a function form: `keep_self` keeps the receiver as the first
    /// parameter (`Self`) for instance methods; associated fns have none.
    fn methodForms(this: *Emitter, b: Ast.Builder, out: *Forms, name: []const u8, m: anytype) !void {
        const saved_keep_self = this.keep_self;
        this.keep_self = !isAssocMethod(m);
        defer this.keep_self = saved_keep_self;
        try out.append(b.arena, .blank);
        try this.fnForms(b, out, .{
            .isPub = false,
            .name = name,
            .annotations = &.{},
            .genericParams = &.{},
            .params = m.params,
            .returnType = m.returnType,
            .body = m.body orelse &.{},
        });
    }

    fn recordForms(this: *Emitter, b: Ast.Builder, out: *Forms, r: ast.TypeDecl) !void {
        // Records are maps at runtime (`#{field => V}`) — no decl needed.
        // (`-record(PascalCase, …)` is invalid Erlang: a capitalised bare atom.)
        var text: std.ArrayListUnmanaged(u8) = .empty;
        try text.appendSlice(b.arena, try std.fmt.allocPrint(b.arena, "type {s}: ", .{r.name}));
        for (r.recordFields(), 0..) |f, i| {
            if (i > 0) try text.appendSlice(b.arena, ", ");
            try text.appendSlice(b.arena, f.name);
        }
        try out.append(b.arena, .{ .comment = Ast.Comment.doc(text.items) });
        // Instance methods take the receiver positionally (`recv.m(args)` →
        // `m(Recv, args)`). A method whose name collides with another record's
        // method is mangled to `<recordtype>_<method>` so erlang's flat
        // top-level fn namespace doesn't double-define it.
        for (r.methods) |m| {
            if (m.is_declare) continue;
            var mname_buf: [256]u8 = undefined;
            const mname: []const u8 = if (this.isRecordMethodCollision(r.name, m.name))
                try recordMethodAtom(&mname_buf, r.name, m.name)
            else
                m.name;
            try this.methodForms(b, out, mname, m);
        }
        // The bodied instance `default fn`s the record adopts with `implement`
        // and does not declare itself: the behavior contract is part of the
        // record's surface, exactly as commonJS puts them on the class.
        // `self` is the record inside those bodies, so `self.size()` reaches the
        // record's own (possibly mangled) method rather than a bare `size/1`.
        var adopted: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        try this.adoptedIfaceDefaults(b.arena, r, &adopted);
        const saved_self_record = this.self_record_type;
        defer this.self_record_type = saved_self_record;
        this.self_record_type = r.name;
        for (adopted.items) |m| {
            if (!this.emitsAdoptedDefault(r.name, m.name)) continue;
            try this.methodForms(b, out, m.name, m);
        }
    }

    fn enumForms(this: *Emitter, b: Ast.Builder, out: *Forms, e: ast.TypeDecl) !void {
        try out.append(b.arena, .{ .comment = Ast.Comment.doc(try std.fmt.allocPrint(b.arena, "type {s}", .{e.name})) });
        for (e.variants()) |v| {
            var text: std.ArrayListUnmanaged(u8) = .empty;
            try text.appendSlice(b.arena, try std.fmt.allocPrint(b.arena, "  {s}", .{v.name}));
            if (v.fields.len > 0) {
                try text.append(b.arena, '(');
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try text.appendSlice(b.arena, ", ");
                    try text.appendSlice(b.arena, f.name);
                }
                try text.append(b.arena, ')');
            }
            try out.append(b.arena, .{ .comment = Ast.Comment.doc(text.items) });
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try this.methodForms(b, out, m.name, m);
        }
    }

    fn interfaceForms(this: *Emitter, b: Ast.Builder, out: *Forms, i: ast.BehaviorDecl) !void {
        try out.append(b.arena, .{ .comment = Ast.Comment.doc(try std.fmt.allocPrint(b.arena, "behavior {s}", .{i.name})) });
        // Associated `default fn`s (no `self`) are pure botopink — local
        // functions so `Interface.method(...)` resolves locally (the interface
        // decl is inlined into each consuming module). The name is mangled
        // `Interface_method` (→ quoted `'Array_range'`) so it never collides with
        // a consumer's own top-level fn of the same name. Instance default fns
        // (with `self`) are not emitted here.
        for (i.methods) |m| {
            if (!m.is_default or m.body == null) continue;
            const has_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
            if (has_self) continue;
            var mbuf: [256]u8 = undefined;
            const mangled = interfaceAssocAtom(&mbuf, i.name, m.name) catch continue;
            try out.append(b.arena, .blank);
            try this.fnForms(b, out, .{
                .isPub = false,
                .name = mangled,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = null,
                .body = m.body.?,
            });
        }
    }

    fn implementForms(this: *Emitter, b: Ast.Builder, out: *Forms, im: ast.ImplementDecl) !void {
        var text: std.ArrayListUnmanaged(u8) = .empty;
        try text.appendSlice(b.arena, "implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try text.appendSlice(b.arena, ", ");
            try text.appendSlice(b.arena, switch (iface) {
                .named => |n| n,
                .generic => |g| g.name,
                else => "?",
            });
        }
        try text.appendSlice(b.arena, try std.fmt.allocPrint(b.arena, " for {s}", .{im.target}));
        try out.append(b.arena, .{ .comment = Ast.Comment.doc(text.items) });
        try this.extensionForms(b, out, im.methods);
    }

    fn extendForms(this: *Emitter, b: Ast.Builder, out: *Forms, ex: ast.ExtendDecl) !void {
        try out.append(b.arena, .{ .comment = Ast.Comment.doc(try std.fmt.allocPrint(b.arena, "extend {s}", .{ex.target})) });
        try this.extensionForms(b, out, ex.methods);
    }

    /// Extension methods (from `implement`/`extend`) are bare top-level
    /// functions taking the receiver first, so an activated `recv.m(args)`
    /// dispatch calls `m(Recv, args)` directly.
    fn extensionForms(this: *Emitter, b: Ast.Builder, out: *Forms, methods: []const ast.ImplementMethod) !void {
        const saved_keep_self = this.keep_self;
        this.keep_self = true;
        defer this.keep_self = saved_keep_self;
        for (methods) |m| {
            try out.append(b.arena, .blank);
            try this.fnForms(b, out, .{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = null,
                .body = m.body,
            });
        }
    }
};
