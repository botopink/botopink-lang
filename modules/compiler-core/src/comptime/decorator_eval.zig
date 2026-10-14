/// Decorator invocation on the comptime runtime (`runtime/runtime.zig`; wasm for
/// every target, decision 434).
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core reflects that
/// declaration into a `DeclHandle` and runs the decorator body over it:
///
///   decorator `FnDecl` ─ codegen/erlang.zig `emitComptimeModule` ─ `main/1` → Erlang text
///   handle + args ─ `Term` ─ comptime/runtime/etf ─ external term ─┐
///     → comptime/runtime/runtime `evalWithArg`: the text lowered   │
///       to wasm once per module, run with the handle's term ←──────┘
///     → JSON `{kind, contributions | message | span}` → `Outcome`
///
/// The body is lowered by the regular Erlang backend (untyped mode), so every
/// construct that backend supports works in a decorator. The host functions the
/// body calls (`decl.fail`, `decl.failAt`, `@compilerError`, `@emit`,
/// `decl.addMember`, `decl.setMeta`, `decl.addType` — decision 216) are plain
/// Erlang functions resident in `bp_comptime_decorator`, parsed once per
/// process (`runtime/prelude.zig`) and reached by the `-import`
/// `emitComptimeModule` writes; only `main/1` is generated, and it carries nothing
/// from the declaration it runs over — so one module serves every declaration a
/// decorator annotates with the same annotation arguments.
const std = @import("std");
const memberFnMod = @import("member_fn.zig");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const crossModule = @import("../codegen/crossModule.zig");
const templateEval = @import("./template_eval.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
pub const Term = @import("../codegen/beam/term.zig").Term;
const hostRuntime = @import("./runtime/runtime.zig");
const preludeMod = @import("./runtime/prelude.zig");
const etf = @import("./runtime/etf.zig");
const stages = @import("./runtime/stages.zig");
const trace = @import("./trace.zig");
const typedMeta = @import("./typed_meta.zig");
const hostCells = @import("./host_cells.zig");
const blockEval = @import("./block_eval.zig");
const diagnostics = @import("./diagnostics.zig");
const validation = @import("./error.zig");

/// Reflection of the annotated declaration (`@Decl` in `builtins.d.bp`).
pub const DeclHandle = struct {
    kind: []const u8,
    name: []const u8,
    fields: []const FieldHandle,
    /// The variant names of an enum-shaped `type` (top-level variants, then
    /// section names); empty for every other declaration. With `DeclKind.Type`
    /// covering both shapes, this is how a decorator tells a record from an
    /// enum (`decl.kind == DeclKind.Type && decl.variants.length == 0`).
    variants: []const []const u8 = &.{},
    methods: []const ast.BehaviorMethod,
    returnType: []const u8,
    annotations: []const ast.Annotation,
    /// Decision 277 — `decl.hooks`, the `HookNode` maps the checker built
    /// (`hooks.zig` `nodesToTerm`); empty but for a function one of whose
    /// decorators reads it.
    hooks: []const Term = &.{},
    /// `DeclAnnotation.decorator` — the identity of the decorator each
    /// annotation name of the handle names (`infer.zig`
    /// `annotationDecoratorId`).
    decoratorIds: []const DecoratorId = &.{},
    /// `decl.params` — a function's or a method's own parameters, as written
    /// (decision 280, closed by `01-checker` step 29: a method's `@Decl`
    /// carries its parameter list); empty for every other declaration.
    params: []const ParamHandle = &.{},
    /// Question s29-b — the typed meta each method recorded (its decorators
    /// run before the owner's), read on a `decl.methods` entry as
    /// `m.meta(T)` / `m.metaAll(T)`.
    methodMeta: []const MethodMeta = &.{},
    /// Decision 302 — a tag's handle (`kind` `Element` or `Component`): its
    /// static attributes as written, the component's own handle, and the
    /// typed meta the tag's annotations recorded so far (`d.meta(T)` in the
    /// template's body). The keys are written for a tag only, `component`
    /// for every handle.
    attrs: []const [2][]const u8 = &.{},
    component: ?*const DeclHandle = null,
    tagMeta: []const TagMeta = &.{},
    /// Decision 415 (2) — `decl.module`, the path of the module that
    /// declares it.
    module: []const u8 = "",
    /// Decision 526 — `decl.owner`: the `Declared<unknown>` term of the type
    /// or behavior that holds an annotated method or field (`hooks.zig`
    /// `declaredTerm`, built by the checker, `infer.zig` `runDeclDecorators`);
    /// null — `undefined` in the term — for every other handle.
    owner: ?Term = null,
    /// Decision 415 (2) — a declaration `q.lookup` answered: the typed meta
    /// its decorators recorded (`d.meta(T)` in the template's body, the
    /// `meta` key a tag's handle carries too), its identity and the name the
    /// call site spells it by (what `lookup/2` matches, and what a
    /// `CustomNode`'s `ref` hands the language server). Null for every other
    /// handle.
    lookup: ?Lookup = null,

    pub fn isTag(self: DeclHandle) bool {
        return std.mem.eql(u8, self.kind, "Element") or std.mem.eql(u8, self.kind, "Component");
    }
};

/// What a `q.lookup` handle carries beside a declaration's (decision 415 (2)).
/// `pending` (372's pattern): a declaration of the module whose `.hooks`
/// reader has not run yet — its meta is refused where it is read.
pub const Lookup = struct { identity: []const u8, local: []const u8, meta: []const TagMeta, pending: bool = false };

/// Decision 302 — one typed meta value a tag's annotation recorded: the
/// record type's declared name, whether it was added (`addMeta`), and the
/// value as the map a record is in a body (`metaValueTerm`).
pub const TagMeta = struct { typeName: []const u8, repeat: bool, value: Term };

/// One typed meta value of a method: the record type's declared name and the
/// value as the map a record is in the body (`metaValueTerm`).
pub const MethodMeta = struct { method: []const u8, typeName: []const u8, value: Term };

/// One parameter of a reflected function or method (`Param` in
/// `builtins.d.bp`): its name and its type as the source spells it.
pub const ParamHandle = struct { name: []const u8, typeName: []const u8 };

/// An annotation name and the identity of the decorator it names.
pub const DecoratorId = struct { name: []const u8, id: []const u8 };

pub const FieldHandle = struct {
    name: []const u8,
    typeName: []const u8,
    annotations: []const ast.Annotation,
};

/// One output of a decorator body, in call order (decision 216): a loose
/// `@emit` declaration, or a member `decl.addMember(source)` gives the
/// annotated type.
pub const Contribution = struct {
    kind: Kind,
    /// The botopink source the body wrote (`emit`, `member`).
    source: []const u8 = "",
    /// `decl.setMeta(key, value)` — a comptime fact about the declaration.
    key: []const u8 = "",
    value: []const u8 = "",
    /// `decl.addType(name, source)` — the associated type's name (its shape
    /// is `source`); `decl.addMember(name, fn…)` — the member's name.
    name: []const u8 = "",
    /// Decision 370 (2) — `decl.addMember(name, fn…)`: which of the body's
    /// member functions (`member_fn.collect`'s order) the call handed.
    /// Decision 298 — `decl.setMeta(v)` / `decl.addMeta(v)`: which of the
    /// body's typed meta calls (`typed_meta.collect`'s order) it was.
    index: usize = 0,
    /// Decision 298 — the record the typed meta call built, as JSON (an
    /// untagged map: its type is the call's, `typed_meta.render`).
    data: ?std.json.Value = null,

    /// `wrap` — decision 316, `decl.wrapWith(f)`: `index` is the wrapper's
    /// (`member_fn.collectWrappers`'s order).
    pub const Kind = enum { emit, member, memberFn, meta, assoc, typedMeta, wrap };
};

pub const Outcome = union(enum) {
    /// Accepted; the body's outputs in call order.
    ok: []const Contribution,
    /// Rejected by the body (`decl.fail` / `decl.failAt` / `@compilerError`,
    /// or `x.fail` on a parameter — decision 364 (3): `arg` is its index
    /// after the `@Decl` one).
    fail: struct { message: []const u8, span: ?template.Span, arg: ?usize = null },
    /// The evaluator itself failed (module did not compile, body raised, …).
    err: []const u8,
    /// The body raised, and the raise left a call of one of the `located`
    /// functions (decision 451 (3), `erlang.ComptimeModule.located`): the
    /// text, and where that call starts — the innermost such call.
    raised: struct { message: []const u8, at: ast.Loc },
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

/// Longest compiler/runtime diagnostic carried into `Outcome.err`.
const max_error_detail = 4096;

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    /// The module path `dfn` was declared in (`templateEval.ownerId`).
    owner: []const u8,
    /// The display path of `owner`'s file (`src/deco.bp`, `@src().file`):
    /// a diagnostic located in the body names it.
    owner_file: []const u8,
    dfn: ast.FnDecl,
    /// The functions of `dfn`'s module its body reaches
    /// (`infer.decoratorSupport`), compiled into the module beside it.
    support: []const ast.FnDecl,
    /// Decision 451 (3) — `dfn` and the `support` functions whose calls are
    /// located (the module being compiled's own), by name: a raise that
    /// leaves one of their calls is `Outcome.raised` at it.
    located: []const []const u8,
    /// The record and enum types `dfn` and `support` name, with the methods
    /// they call (`block_eval.typesReached`): a package record an imported
    /// helper constructs travels into the module beside the helper.
    types: []const ast.DeclKind,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
    /// Decision 311 — a template annotation `#[f "…"]`: `dfn` is the template
    /// function, its first parameter the literal (this capture) and its second
    /// the handle. Null for a decorator.
    capture: ?*const template.CapturedExpr,
    /// Receives what was sent to and returned by the runtime (snapshots); null skips it.
    traces: ?*std.ArrayListUnmanaged(trace.Entry),
) EvalError!Outcome {
    _ = build_root;
    var unsupported: erlang.UnsupportedMethod = .{};
    var refused: []const u8 = "";
    const t_module = stages.start();
    const source = buildModule(arena, owner, dfn, support, located, types, handle, plainArgs, capture, &unsupported, &refused) catch |err| switch (err) {
        error.UnsupportedMethod => return .{ .err = try unsupportedText(arena, "decorator", dfn.name, owner_file, unsupported) },
        error.HostCell => return .{ .err = refused },
        else => |e| return e,
    };
    stages.stop(.module, t_module);

    // The comptime runtime is wasm for every target (decision 434,
    // `runtime/runtime.zig`).
    const t_encode = stages.start();
    const arg = try etf.encode(arena, source.argument);
    stages.stop(.encode, t_encode);
    const response = try hostRuntime.evalWithArg(arena, io, "decorator", source.module, source.code, arg);
    if (traces) |list| {
        const t_listing = stages.start();
        defer stages.stop(.listing, t_listing);
        const listing = try hostRuntime.listingOf(arena, "decorator", source.module, source.code, try templateEval.argumentListing(arena, source.argument));
        try list.append(arena, .{
            .kind = .decorator,
            .name = dfn.name,
            .listing = listing,
            .reply = switch (response) {
                .ok => |stdout| stdout,
                .compile_error => |detail| try std.fmt.allocPrint(arena, "compile error: {s}", .{detail}),
                .runtime_error => |detail| try std.fmt.allocPrint(arena, "runtime error: {s}", .{detail}),
            },
        });
    }
    const t_outcome = stages.start();
    defer stages.stop(.outcome, t_outcome);
    return switch (response) {
        .ok => |stdout| parseOutcome(arena, stdout),
        .compile_error => |detail| .{ .err = try errorText(arena, "the decorator module did not compile", detail) },
        .runtime_error => |detail| .{ .err = try errorText(arena, "the decorator body raised", detail) },
    };
}

fn errorText(arena: std.mem.Allocator, what: []const u8, detail: []const u8) ![]const u8 {
    const shown = detail[0..@min(detail.len, max_error_detail)];
    const ellipsis = if (detail.len > max_error_detail) " …" else "";
    return std.fmt.allocPrint(arena, "{s}: {s}{s}", .{ what, shown, ellipsis });
}

/// The diagnostic for a body method call nothing answers (`erlang.UnsupportedMethod`).
fn unsupportedText(arena: std.mem.Allocator, host: []const u8, name: []const u8, file: []const u8, m: erlang.UnsupportedMethod) ![]const u8 {
    return std.fmt.allocPrint(
        arena,
        "the {s} `{s}` calls `.{s}(…)` with {d} argument(s) at {s}:{d}:{d}, which no primitive type (string, array, int, float, bool) and no {s} host function provides",
        .{ host, name, m.callee, m.argc, file, m.loc.line, m.loc.col, host },
    );
}

// ── module ────────────────────────────────────────────────────────────────────

const Module = struct {
    /// Erlang module atom, derived from the code's hash. The code carries no
    /// handle, so every declaration a decorator annotates with the same
    /// annotation arguments derives the same atom.
    module: []const u8,
    code: []const u8,
    /// `main/1`'s argument: the handle, then the annotation arguments.
    argument: Term,
};

const placeholder_module = "decorator_module";

/// `main/1` — the evaluator entry: it destructures the argument tuple, calls the
/// decorator with it and replies with JSON. `fail`/`failAt`/`compilerError`
/// (which throw the tagged rejection caught here) and `emit`/`'__bp_emitted'`
/// are resident (`runtime/prelude.zig`), reached by the `-import`
/// `emitComptimeModule` writes. Nothing here depends on the declaration it runs
/// over any more — that is what makes the module's hash a hash of the decorator.
fn mainForms(b: Ast.Builder, dfn: ast.FnDecl, plans: []const templateEval.ArgPlan, annotation: bool) Ast.Builder.Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A(preludeMod.decorator_fail_tag);
    const template_fail_tag = A(preludeMod.template_fail_tag);
    const emitted_key = A(preludeMod.emitted_key);

    // <decorator>(Handle, Arg1, …): parameters after the `@Decl` one bind the
    // annotation's arguments in order; a missing argument is `undefined`.
    const args = try b.arena.alloc(Ast.Expr, plans.len);
    for (plans, 0..) |plan, i| args[i] = plan.expr;
    const invoke: Ast.Expr = .{ .call = .{ .name = dfn.name, .args = args } };

    const emitted = try b.call("__bp_emitted", &.{});
    const encode = struct {
        fn json(bb: Ast.Builder, fields: []const Ast.MapField) Ast.Builder.Error!Ast.Expr {
            return bb.remote("json", "encode", &.{try bb.map(fields)});
        }
    }.json;

    const all_catches = [_]Ast.Clause{
        .{
            .patterns = try b.exprs(&.{try b.exception(A("throw"), try b.tuple(&.{ fail_tag, V("Message"), V("Span") }))}),
            .body = try b.body(&.{try encode(b, &.{
                Ast.field("kind", Ast.str("fail")),
                Ast.field("message", try b.call("__bp_text", &.{V("Message")})),
                Ast.field("span", V("Span")),
            })}),
        },
        // Decision 311 — a template annotation's capture API (`lookup/2`)
        // fails with the template's tag; it is reported at the annotation,
        // as the handle's own `fail` is.
        .{
            .patterns = try b.exprs(&.{try b.exception(A("throw"), try b.tuple(&.{ template_fail_tag, V("Message"), V("_Param"), V("_Span") }))}),
            .body = try b.body(&.{try encode(b, &.{
                Ast.field("kind", Ast.str("fail")),
                Ast.field("message", try b.call("__bp_text", &.{V("Message")})),
                Ast.field("span", A("null")),
            })}),
        },
        .{
            .patterns = try b.exprs(&.{try b.exception(V("Class"), V("Reason"))}),
            .body = try b.body(&.{try encode(b, &.{
                Ast.field("kind", Ast.str("error")),
                Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ V("Class"), V("Reason") })})),
                Ast.field("at", try b.call("__bp_raised_at", &.{})),
            })}),
        },
    };
    const catches: []const Ast.Clause = if (annotation)
        try b.arena.dupe(Ast.Clause, &all_catches)
    else
        try b.arena.dupe(Ast.Clause, &.{ all_catches[0], all_catches[2] });

    const main_body = try b.body(&.{
        try b.remote("erlang", "erase", &.{emitted_key}),
        .{ .try_catch = .{
            .body = try b.body(&.{
                invoke,
                try encode(b, &.{
                    Ast.field("kind", Ast.str("ok")),
                    Ast.field("contributions", try b.remote("lists", "reverse", &.{emitted})),
                }),
            }),
            .catches = catches,
        } },
    });

    const forms = [_]Ast.Form{
        .{ .function = .{ .name = "main", .clauses = try b.arena.dupe(Ast.Clause, &.{.{
            .patterns = try b.exprs(&.{try templateEval.mainPattern(b, plans)}),
            .body = main_body,
        }}) } },
    };
    return b.arena.dupe(Ast.Form, &forms);
}

fn buildModule(
    arena: std.mem.Allocator,
    owner: []const u8,
    dfn: ast.FnDecl,
    support: []const ast.FnDecl,
    located: []const []const u8,
    types: []const ast.DeclKind,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
    capture: ?*const template.CapturedExpr,
    unsupported: *erlang.UnsupportedMethod,
    /// Why a host function cannot run on this runtime (`error.HostCell`).
    refused: *[]const u8,
) (EvalError || error{ UnsupportedMethod, HostCell })!Module {
    const b: Ast.Builder = .{ .arena = arena };
    const plans = if (capture) |cap| try annotationPlans(arena, dfn, handle, cap) else try argPlans(arena, dfn, handle, plainArgs);
    // Decision 311 — a template annotation's body reads its literal through
    // the capture API (`q.text()`, `q.parts()`, `q.build(…)`), rendered into
    // the module beside `main/1`; the handle's API is the resident prelude's.
    const forms = if (capture != null)
        try std.mem.concat(arena, Ast.Form, &.{ try mainForms(b, dfn, plans, true), try preludeMod.captureForms(b) })
    else
        try mainForms(b, dfn, plans, false);
    const resident = try preludeMod.decoratorForms(b);

    const all = try arena.alloc(ast.DeclKind, 1 + support.len + types.len);
    all[0] = .{ .@"fn" = dfn };
    for (support, 1..) |f, i| all[i] = .{ .@"fn" = f };
    @memcpy(all[1 + support.len ..], types);
    // Decision 341 — each host function as this runtime runs it.
    const decls = switch (try hostCells.forRuntime(arena, all)) {
        .ok => |d| d,
        .refused => |msg| {
            refused.* = msg;
            return error.HostCell;
        },
    };
    const config: erlang.ComptimeModule = .{
        .host_enums = &.{ "DeclKind", "Stage" },
        // `decl.failAt(Span(start, end, line), msg)` builds the span map.
        // Decision 280 — a field key `.name` reaches the body as the
        // `Type.Field<T>` record a `decl.fields` entry is (`infer.zig`
        // `fieldKeySource`).
        .host_records = &.{
            .{ .name = "Span", .fields = &.{ "start", "end", "line" } },
            .{ .name = "__bp_FieldKey", .fields = &.{ "name", "typeName", "annotations" } },
            .{ .name = "__bp_DeclAnnotation", .fields = &.{ "name", "args", "decorator" } },
            // Decision 370 (1) — a parameter handed to a typed meta value's
            // `@Expr<T>` field (`expr_param.eraseFn`).
            .{ .name = typedMeta.expr_ref_record, .fields = &.{typedMeta.expr_ref_field} },
        },
        .exports = &.{.{ .name = "main", .arity = 1 }},
        .forms = forms,
        .resident = .{
            .module = preludeMod.decorator_module,
            .forms = resident,
            .refs = try preludeMod.exportRefs(arena, resident),
        },
        .unsupported_method = unsupported,
        .located = located,
    };
    const argument = try templateEval.argumentTerm(arena, plans);
    // Emitted once per decorator and plan, not once per annotated declaration
    // (`template_eval` § one emit per declaration).
    // The located functions change the code, so they are part of the key —
    // their names, and where their calls are written (`'__bp_at'(Line, Col,
    // Call)`, `templateEval.appendLocs`).
    var kind: std.ArrayListUnmanaged(u8) = .empty;
    try kind.appendSlice(arena, if (capture != null) "ann" else "dec");
    for (located) |n| {
        try kind.append(arena, 1);
        try kind.appendSlice(arena, n);
    }
    for (decls) |d| switch (d) {
        .@"fn" => |f| for (located) |n| {
            if (std.mem.eql(u8, f.name, n)) {
                try kind.append(arena, 2);
                try kind.appendSlice(arena, n);
                try templateEval.appendLocs(arena, &kind, f);
                break;
            }
        },
        else => {},
    };
    const key = try templateEval.emitKey(arena, kind.items, owner, decls, plans);
    const emitted: templateEval.Emitted = (if (key) |k| templateEval.cachedEmit(k) else null) orelse blk: {
        const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch |err|
            return if (err == error.UnsupportedComptimeMethod) error.UnsupportedMethod else error.EvalFailed;
        // A2: `bp@comptime@<owner path>__dec__<decorator>__<16 hex>`; the Wyhash is
        // unchanged, so content-addressing survives (see `template_eval.buildModule`).
        const module = crossModule.erlDeclAtom(arena, try templateEval.ownerId(arena, owner), .dec, dfn.name, std.hash.Wyhash.hash(0, code)) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => return error.EvalFailed,
        };
        const header = "-module(" ++ placeholder_module ++ ").";
        if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
        const fresh: templateEval.Emitted = .{ .module = module, .code = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] }) };
        break :blk if (key) |k| try templateEval.rememberEmit(k, fresh) else fresh;
    };
    const module = emitted.module;
    const renamed = emitted.code;

    return .{ .module = module, .code = renamed, .argument = argument };
}

/// How each parameter of `dfn` reaches the body: the `@Decl` handle first, then
/// the annotation arguments in order. A plain argument whose lexeme has no exact
/// term (`templateEval.plainArgTerm`) stays a literal in the module; a parameter
/// the annotation gave nothing is `undefined`.
fn argPlans(
    arena: std.mem.Allocator,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError![]const templateEval.ArgPlan {
    const plans = try arena.alloc(templateEval.ArgPlan, @max(dfn.params.len, 1));
    plans[0] = .{
        .term = try handleToTerm(arena, handle),
        .expr = Ast.Expr.v("Arg0"),
        .bound = true,
    };
    for (plans[1..], 0..) |*plan, i| {
        if (i >= plainArgs.len) {
            plan.* = .{ .term = Term.undefined_atom, .expr = Ast.Expr.a("undefined"), .bound = false };
            continue;
        }
        // Decision 364 — an argument not known at build the body never reads.
        if (plainArgs[i].absent) {
            plan.* = .{ .term = Term.undefined_atom, .expr = Ast.Expr.a("undefined"), .bound = false };
            continue;
        }
        if (plainArgs[i].call) |builder| {
            plan.* = .{ .term = Term.undefined_atom, .expr = .{ .call = .{ .name = builder, .args = &.{} } }, .bound = false };
            continue;
        }
        const name = try std.fmt.allocPrint(arena, "Arg{d}", .{i + 1});
        plan.* = if (try templateEval.plainArgTerm(arena, plainArgs[i])) |t|
            .{ .term = t, .expr = Ast.Expr.v(name), .bound = true }
        else
            .{ .term = Term.undefined_atom, .expr = plainArgs[i].toExpr(), .bound = false };
    }
    return plans;
}

/// Decision 311 — how a template annotation's parameters reach the body: the
/// literal's capture first (`q`, as `template_eval.captureToTerm` builds it at
/// a call site), the `@Decl` handle second; any further parameter the
/// annotation gives nothing is `undefined`.
fn annotationPlans(
    arena: std.mem.Allocator,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    capture: *const template.CapturedExpr,
) EvalError![]const templateEval.ArgPlan {
    const plans = try arena.alloc(templateEval.ArgPlan, @max(dfn.params.len, 2));
    plans[0] = .{ .term = try templateEval.captureToTerm(arena, capture), .expr = Ast.Expr.v("Arg0"), .bound = true };
    plans[1] = .{ .term = try handleToTerm(arena, handle), .expr = Ast.Expr.v("Arg1"), .bound = true };
    for (plans[2..]) |*plan| plan.* = .{ .term = Term.undefined_atom, .expr = Ast.Expr.a("undefined"), .bound = false };
    return plans;
}

// ── handle ────────────────────────────────────────────────────────────────────

/// The `@Decl` handle as a BEAM term — the map the decorator body reads
/// (`decl.kind`, `decl.fields`, …). `kind` is an atom so it matches the lowering
/// of `DeclKind.Type` (`'Type'`); names and type names are binaries.
pub fn handleToTerm(arena: std.mem.Allocator, handle: DeclHandle) std.mem.Allocator.Error!Term {
    const fields = try arena.alloc(Term, handle.fields.len);
    for (handle.fields, 0..) |f, i| {
        const entries = try arena.alloc(Term.MapEntry, 3);
        entries[0] = Term.field("name", Term.str(f.name));
        entries[1] = Term.field("typeName", Term.str(f.typeName));
        entries[2] = Term.field("annotations", try annotationsToTerm(arena, f.annotations, handle.decoratorIds));
        fields[i] = Term.mapOf(entries);
    }

    const methods = try arena.alloc(Term, handle.methods.len);
    for (handle.methods, 0..) |m, i| {
        const params = try arena.alloc(Term, m.params.len);
        for (m.params, 0..) |p, j| {
            const pe = try arena.alloc(Term.MapEntry, 2);
            pe[0] = Term.field("name", Term.str(p.name));
            pe[1] = Term.field("typeName", Term.str(try typeName(arena, p.typeRef)));
            params[j] = Term.mapOf(pe);
        }
        // Question s29-b — `meta`: `[#{type => <<"Query">>, value => V}]`,
        // what `'__bp_methodMeta'/2` reads.
        var metas: std.ArrayListUnmanaged(Term) = .empty;
        for (handle.methodMeta) |mm| {
            if (!std.mem.eql(u8, mm.method, m.name)) continue;
            const me = try arena.alloc(Term.MapEntry, 2);
            me[0] = Term.field("type", Term.str(mm.typeName));
            me[1] = Term.field("value", mm.value);
            try metas.append(arena, Term.mapOf(me));
        }
        const entries = try arena.alloc(Term.MapEntry, 5);
        entries[0] = Term.field("name", Term.str(m.name));
        entries[1] = Term.field("params", Term.listOf(params));
        entries[2] = Term.field("returnType", Term.str(if (m.returnType) |rt| try typeName(arena, rt) else ""));
        entries[3] = Term.field("annotations", try annotationsToTerm(arena, m.annotations, handle.decoratorIds));
        entries[4] = Term.field("meta", Term.listOf(metas.items));
        methods[i] = Term.mapOf(entries);
    }

    const variants = try arena.alloc(Term, handle.variants.len);
    for (handle.variants, 0..) |v, i| variants[i] = Term.str(v);

    const params = try arena.alloc(Term, handle.params.len);
    for (handle.params, 0..) |p, i| {
        const pe = try arena.alloc(Term.MapEntry, 2);
        pe[0] = Term.field("name", Term.str(p.name));
        pe[1] = Term.field("typeName", Term.str(p.typeName));
        params[i] = Term.mapOf(pe);
    }

    const tag = handle.isTag();
    const extra: usize = if (tag) 2 else if (handle.lookup != null) 3 else 0;
    const entries = try arena.alloc(Term.MapEntry, 12 + extra);
    entries[0] = Term.field("kind", Term.atomOf(handle.kind));
    entries[1] = Term.field("name", Term.str(handle.name));
    entries[2] = Term.field("fields", Term.listOf(fields));
    entries[3] = Term.field("variants", Term.listOf(variants));
    entries[4] = Term.field("methods", Term.listOf(methods));
    entries[5] = Term.field("returnType", Term.str(handle.returnType));
    entries[6] = Term.field("annotations", try annotationsToTerm(arena, handle.annotations, handle.decoratorIds));
    entries[7] = Term.field("hooks", Term.listOf(handle.hooks));
    entries[8] = Term.field("params", Term.listOf(params));
    entries[9] = Term.field("component", if (handle.component) |c| try handleToTerm(arena, c.*) else Term.undefined_atom);
    entries[10] = Term.field("module", Term.str(handle.module));
    entries[11] = Term.field("owner", handle.owner orelse Term.undefined_atom);
    if (handle.lookup) |l| if (!tag) {
        entries[12] = Term.field("meta", if (l.pending)
            Term.tupleOf(try arena.dupe(Term, &.{ Term.atomOf(preludeMod.meta_pending_tag), Term.str(handle.name) }))
        else
            try metaListTerm(arena, l.meta));
        entries[13] = Term.field("identity", Term.str(l.identity));
        entries[14] = Term.field("local", Term.str(l.local));
    };
    if (tag) {
        // `attrs` — `[{<<"id">>, <<"x">>}]`, what `attr/2` reads; `meta` —
        // `[#{type => <<"ClassName">>, value => V}]`, what
        // `'__bp_methodMeta'/2` reads (a method entry's shape).
        const attrs = try arena.alloc(Term, handle.attrs.len);
        for (handle.attrs, 0..) |a, i| attrs[i] = Term.tupleOf(try arena.dupe(Term, &.{ Term.str(a[0]), Term.str(a[1]) }));
        entries[12] = Term.field("attrs", Term.listOf(attrs));
        entries[13] = Term.field("meta", try metaListTerm(arena, handle.tagMeta));
    }
    return Term.mapOf(entries);
}

/// `[#{type => <<"ClassName">>, value => V}]`, what `'__bp_methodMeta'/2`
/// reads (a method entry's shape).
fn metaListTerm(arena: std.mem.Allocator, metas: []const TagMeta) std.mem.Allocator.Error!Term {
    const out = try arena.alloc(Term, metas.len);
    for (metas, 0..) |m, i| {
        const me = try arena.alloc(Term.MapEntry, 2);
        me[0] = Term.field("type", Term.str(m.typeName));
        me[1] = Term.field("value", m.value);
        out[i] = Term.mapOf(me);
    }
    return Term.listOf(out);
}

/// Question s29-b — a typed meta value (the JSON `'__bp_typedMeta'/2`
/// replied, an untagged map) as the build-time term a decorator body reads:
/// the record's map, each field by its shape — a string a binary, a number,
/// a `bool`, a variant its atom, an array a list, `null` `undefined`. An
/// `@Expr<T>` field (370 (1)) has no value at build and reads `undefined`.
pub fn metaValueTerm(arena: std.mem.Allocator, fields: []const typedMeta.FieldShape, data: std.json.Value) std.mem.Allocator.Error!Term {
    if (data != .object) return Term.undefined_atom;
    const entries = try arena.alloc(Term.MapEntry, fields.len);
    for (fields, 0..) |f, i| {
        const v = data.object.get(f.name) orelse std.json.Value{ .null = {} };
        entries[i] = Term.field(f.name, if (f.shape == .expr) Term.undefined_atom else try shapeTerm(arena, f.shape, v));
    }
    return Term.mapOf(entries);
}

fn shapeTerm(arena: std.mem.Allocator, written: typedMeta.Shape, v: std.json.Value) std.mem.Allocator.Error!Term {
    const shape: typedMeta.Shape = switch (written) {
        .optional => |p| p.*,
        else => written,
    };
    return switch (v) {
        .null => Term.undefined_atom,
        .bool => |b| .{ .boolean = b },
        .integer => |n| Term.int(n),
        .float => |x| .{ .float = x },
        .number_string => |t| Term.str(t),
        .string => |t| if (shape == .variant) Term.atomOf(t) else Term.str(t),
        .array => |arr| blk: {
            const inner: typedMeta.Shape = switch (shape) {
                .array => |p| p.*,
                else => shape,
            };
            const items = try arena.alloc(Term, arr.items.len);
            for (arr.items, 0..) |item, i| items[i] = try shapeTerm(arena, inner, item);
            break :blk Term.listOf(items);
        },
        .object => |o| blk: {
            // A tuple (`{"tuple": [...]}`) its items by their shapes; a
            // `Type.Field<T>` its record, every member as data.
            if (shape == .tuple) {
                const arr = o.get("tuple") orelse break :blk Term.undefined_atom;
                if (arr != .array or arr.array.items.len != shape.tuple.len) break :blk Term.undefined_atom;
                const items = try arena.alloc(Term, arr.array.items.len);
                for (arr.array.items, shape.tuple, 0..) |item, s, i| items[i] = try shapeTerm(arena, s, item);
                break :blk Term.tupleOf(items);
            }
            if (shape == .field_key) {
                const entries = try arena.alloc(Term.MapEntry, o.count());
                var it = o.iterator();
                var i: usize = 0;
                while (it.next()) |e| : (i += 1) entries[i] = Term.field(e.key_ptr.*, try shapeTerm(arena, .string, e.value_ptr.*));
                break :blk Term.mapOf(entries);
            }
            break :blk Term.undefined_atom;
        },
    };
}

/// Decision 415 (3) — a typed meta value recorded on a declaration, as the
/// build-time term a template body reads on a `q.lookup` handle
/// (`d.meta(T)`): the record's map, each of `fields` from the constructor's
/// arguments as `typed_meta.render` wrote them (`(name: "users", size: 3)`),
/// else from the field's default as written (`defaults`, by field), else
/// `undefined`. A string is a binary, a number a number, a `bool` an atom, a
/// variant (`.Big`) its atom, an array a list, `null` `undefined`; anything
/// else (an `@Expr` field's argument) reads `undefined`.
pub fn metaArgsTerm(arena: std.mem.Allocator, fields: []const []const u8, defaults: []const ?[]const u8, args: []const u8) std.mem.Allocator.Error!Term {
    const entries = try arena.alloc(Term.MapEntry, fields.len);
    for (fields, 0..) |f, i| {
        const written = argText(args, f) orelse (if (i < defaults.len) defaults[i] else null);
        entries[i] = Term.field(f, if (written) |w| try literalTerm(arena, std.mem.trim(u8, w, " \t\r\n")) else Term.undefined_atom);
    }
    return Term.mapOf(entries);
}

/// The text of the argument labelled `name` in `(a: …, b: …)`, or null.
fn argText(args: []const u8, name: []const u8) ?[]const u8 {
    if (args.len < 2 or args[0] != '(') return null;
    var i: usize = 1;
    while (i < args.len) {
        while (i < args.len and (args[i] == ' ' or args[i] == ',')) i += 1;
        const label_start = i;
        while (i < args.len and args[i] != ':' and args[i] != ')') i += 1;
        if (i >= args.len or args[i] != ':') return null;
        const label = std.mem.trim(u8, args[label_start..i], " ");
        i += 1;
        const value_start = i;
        const end = valueEnd(args, i);
        if (std.mem.eql(u8, label, name)) return args[value_start..end];
        i = end;
        if (i < args.len and args[i] == ')') return null;
    }
    return null;
}

/// Where the value starting at `start` ends: the `,` or `)` at its depth.
fn valueEnd(s: []const u8, start: usize) usize {
    var depth: usize = 0;
    var i = start;
    while (i < s.len) : (i += 1) {
        switch (s[i]) {
            '"' => {
                i += 1;
                while (i < s.len and s[i] != '"') : (i += 1) {
                    if (s[i] == '\\') i += 1;
                }
            },
            '(', '[', '{' => depth += 1,
            ')', ']', '}' => {
                if (depth == 0) return i;
                depth -= 1;
            },
            ',' => if (depth == 0) return i,
            else => {},
        }
    }
    return s.len;
}

/// A literal as `typed_meta.render` writes one (or a default as written), as
/// a term; `undefined` for anything else.
fn literalTerm(arena: std.mem.Allocator, text: []const u8) std.mem.Allocator.Error!Term {
    if (text.len == 0) return Term.undefined_atom;
    if (std.mem.eql(u8, text, "true")) return .{ .boolean = true };
    if (std.mem.eql(u8, text, "false")) return .{ .boolean = false };
    if (std.mem.eql(u8, text, "null")) return Term.undefined_atom;
    if (text[0] == '"' and text.len >= 2 and text[text.len - 1] == '"') return Term.str(try unescape(arena, text[1 .. text.len - 1]));
    if (text[0] == '.' and text.len > 1 and std.ascii.isUpper(text[1])) return Term.atomOf(text[1..]);
    if (text[0] == '[' and text[text.len - 1] == ']') {
        var items: std.ArrayListUnmanaged(Term) = .empty;
        const inner = text[1 .. text.len - 1];
        var i: usize = 0;
        while (i < inner.len) {
            const end = valueEnd(inner, i);
            const item = std.mem.trim(u8, inner[i..end], " \t\r\n");
            if (item.len > 0) try items.append(arena, try literalTerm(arena, item));
            i = end + 1;
        }
        return Term.listOf(items.items);
    }
    const num = if (text[text.len - 1] == 'f' or text[text.len - 1] == 'd') text[0 .. text.len - 1] else text;
    if (std.fmt.parseInt(i64, num, 10)) |n| return Term.int(n) else |_| {}
    if (std.fmt.parseFloat(f64, num)) |x| return .{ .float = x } else |_| {}
    return Term.undefined_atom;
}

/// A string literal's content with its escapes resolved.
fn unescape(arena: std.mem.Allocator, s: []const u8) std.mem.Allocator.Error![]const u8 {
    if (std.mem.indexOfScalar(u8, s, '\\') == null) return s;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] != '\\' or i + 1 >= s.len) {
            try out.append(arena, s[i]);
            continue;
        }
        i += 1;
        switch (s[i]) {
            'n' => try out.append(arena, '\n'),
            'r' => try out.append(arena, '\r'),
            't' => try out.append(arena, '\t'),
            'u' => if (i + 1 < s.len and s[i + 1] == '{') {
                const close = std.mem.indexOfScalarPos(u8, s, i, '}') orelse s.len;
                const cp = std.fmt.parseInt(u21, s[i + 2 .. close], 16) catch 0xFFFD;
                var buf: [4]u8 = undefined;
                const n = std.unicode.utf8Encode(cp, &buf) catch 0;
                try out.appendSlice(arena, buf[0..n]);
                i = close;
            } else try out.append(arena, 'u'),
            else => |c| try out.append(arena, c),
        }
    }
    return out.items;
}

/// A type reference as the source spells it (`TypeRef.format`) — the same
/// rendering as a field's `typeName` (`infer.zig` `declTypeName`).
fn typeName(arena: std.mem.Allocator, tr: ast.TypeRef) std.mem.Allocator.Error![]const u8 {
    return switch (tr) {
        .named => |n| n,
        else => std.fmt.allocPrint(arena, "{f}", .{tr}),
    };
}

/// `[#{name => <<"getMapping">>, args => [<<"\"/users\"">>], decorator => <<"web@@getMapping">>}]`
/// — args keep their raw source lexemes (`DeclAnnotation.args` in
/// `builtins.d.bp`); `decorator` is the identity of the decorator the name
/// names (`ids`, decision 277).
fn annotationsToTerm(arena: std.mem.Allocator, anns: []const ast.Annotation, ids: []const DecoratorId) std.mem.Allocator.Error!Term {
    const items = try arena.alloc(Term, anns.len);
    for (anns, 0..) |a, i| {
        // Decision 311 — a template annotation's one argument is its
        // literal, as written.
        const written: []const []const u8 = if (a.template) |t| &.{t} else a.args;
        const args = try arena.alloc(Term, written.len);
        for (written, 0..) |arg, j| args[j] = Term.str(arg);
        const id = for (ids) |d| {
            if (std.mem.eql(u8, d.name, a.name)) break d.id;
        } else a.name;
        const entries = try arena.alloc(Term.MapEntry, 3);
        entries[0] = Term.field("name", Term.str(a.name));
        entries[1] = Term.field("args", Term.listOf(args));
        entries[2] = Term.field("decorator", Term.str(id));
        items[i] = Term.mapOf(entries);
    }
    return Term.listOf(items);
}

// ── outcome ───────────────────────────────────────────────────────────────────

/// One tagged map of the prelude's `'__bp_contribute'/1` list, as JSON.
const ReplyItem = struct {
    kind: []const u8,
    source: []const u8 = "",
    key: []const u8 = "",
    value: []const u8 = "",
    name: []const u8 = "",
    index: usize = 0,
    data: ?std.json.Value = null,
};

/// The JSON object `main/0` returns.
const Reply = struct {
    kind: []const u8,
    contributions: []const ReplyItem = &.{},
    message: []const u8 = "",
    span: ?ReplySpan = null,
    /// `[Line, Col]` of the innermost located call an error left, `[]` when none.
    at: ?std.json.Value = null,
};

/// A `fail`'s span: `decl.failAt`'s `Span(start, end, line)`, or `x.fail`'s
/// argument (decision 364 (3) — `'__bp_failArg'/2` throws `#{arg => J}`).
const ReplySpan = struct {
    start: usize = 0,
    end: usize = 0,
    line: usize = 0,
    arg: ?usize = null,
};

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) EvalError!Outcome {
    const reply = std.json.parseFromSliceLeaky(Reply, arena, stdout, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    }) catch return .{ .err = try errorText(arena, "the decorator evaluator returned an unreadable result", stdout) };

    if (std.mem.eql(u8, reply.kind, "ok")) {
        const out = try arena.alloc(Contribution, reply.contributions.len);
        for (reply.contributions, 0..) |item, i| {
            const kind = std.meta.stringToEnum(Contribution.Kind, item.kind) orelse
                return .{ .err = try errorText(arena, "the decorator evaluator returned an unknown output kind", item.kind) };
            out[i] = .{ .kind = kind, .source = item.source, .key = item.key, .value = item.value, .name = item.name, .index = item.index, .data = item.data };
        }
        return .{ .ok = out };
    }
    if (std.mem.eql(u8, reply.kind, "fail")) return .{ .fail = .{
        .message = if (reply.message.len > 0) reply.message else "decorator rejected the declaration",
        .span = if (reply.span) |sp| (if (sp.arg == null) template.Span{ .start = sp.start, .end = sp.end, .line = sp.line } else null) else null,
        .arg = if (reply.span) |sp| sp.arg else null,
    } };
    const message = if (blockEval.unseededDraw(reply.message)) |plain| plain else if (reply.message.len > 0) reply.message else "decorator evaluation failed";
    if (blockEval.raisedAt(reply.at)) |at| return .{ .raised = .{ .message = message, .at = at } };
    return .{ .err = message };
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "decorator module: lowered body, handle term and host glue" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const lexerMod = @import("../lexer.zig");
    const parserMod = @import("../parser.zig");
    var lx = lexerMod.Lexer.init(
        \\fn getMapping(comptime decl: @Decl, comptime path: @Expr<string>, comptime verb: @Expr<string>) {
        \\    if (decl.kind != DeclKind.Method) { decl.fail("#[getMapping] must annotate a method"); }
        \\}
    );
    var p = parserMod.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const dfn = program.decls[0].@"fn";

    const handle: DeclHandle = .{
        .kind = "Type",
        .name = "Nope",
        .fields = &.{},
        .methods = &.{},
        .returnType = "",
        .annotations = &.{},
    };
    const args = [_]template.PlainArg{.{ .paramName = "path", .source = "\"/x\"" }};
    var unsupported: erlang.UnsupportedMethod = .{};
    var refused: []const u8 = "";
    const m = try buildModule(arena, "", dfn, &.{}, &.{}, &.{}, handle, &args, null, &unsupported, &refused);

    // A2: the atom names the declaration, not just a hash of the body, and it
    // decodes back to `{gen, package "bp", "comptime", "dec", "route", <16 hex>}`.
    try std.testing.expect(std.mem.startsWith(u8, m.module, "bp@comptime__dec__"));
    try std.testing.expect(std.mem.startsWith(u8, m.code, "-module(bp@comptime__dec__"));
    const decoded = try crossModule.decodeAtom(arena, m.module);
    try std.testing.expectEqualStrings("bp", decoded.package);
    try std.testing.expectEqualStrings("comptime", decoded.path);
    try std.testing.expectEqualStrings("dec", decoded.kind);
    // A2 lowercases the declaration segment, so `getMapping` is `getmapping`.
    var lowered: [64]u8 = undefined;
    try std.testing.expectEqualStrings(std.ascii.lowerString(&lowered, dfn.name), decoded.decl);
    try std.testing.expectEqual(@as(usize, 16), decoded.hash.len);
    // Nothing about the declaration is in the module: `main/1` takes the handle
    // and the annotation arguments, the body is called with the bound names, and
    // the host glue is imported rather than defined.
    const expected = [_][]const u8{
        "-export([main/1]).",
        "-import(bp_comptime_decorator, [fail/2, failAt/3, compilerError/1, emit/1, addMember/2,",
        "(maps:get(kind, Decl) =/= 'Method')",
        "fail(Decl, <<\"#[getMapping] must annotate a method\">>)",
        "main({Arg0, Arg1, _}) ->",
        "getMapping(Arg0, Arg1, undefined),",
        "throw:{'__bp_decorator_fail', Message, Span} ->",
    };
    for (expected) |needle| {
        if (std.mem.indexOf(u8, m.code, needle) == null) {
            std.debug.print("\nmissing:\n{s}\nin:\n{s}\n", .{ needle, m.code });
            return error.TestExpectedContains;
        }
    }
    // The handle travels as the first element of `main/1`'s argument and the
    // annotation's `"/x"` as the second; the third parameter got no argument.
    const argument = m.argument.tuple;
    try std.testing.expectEqual(@as(usize, 3), argument.len);
    try std.testing.expectEqualStrings("kind", argument[0].map[0].key.atom);
    try std.testing.expectEqualStrings("Type", argument[0].map[0].value.atom);
    try std.testing.expectEqualStrings("Nope", argument[0].map[1].value.binary);
    try std.testing.expectEqualStrings("/x", argument[1].binary);
    try std.testing.expectEqualStrings("undefined", argument[2].atom);

    // And the listing still shows it — the snapshots assert the input half of
    // the evaluation, which is no longer inside the module.
    const shown = try templateEval.argumentListing(arena, m.argument);
    try std.testing.expect(std.mem.indexOf(u8, shown, "%% main/1 argument") != null);
    // This handle is short enough to stay on one line; a real one wraps.
    try std.testing.expect(std.mem.indexOf(u8, shown, "name => <<\"Nope\">>,") != null);
    try std.testing.expect(std.mem.indexOf(u8, shown, "%% Arg1 = <<\"/x\">>") != null);
    try std.testing.expect(std.mem.indexOf(u8, shown, "%% Arg2 = undefined") != null);
}

test "decorator module: one module per decorator, whatever it annotates" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const lexerMod = @import("../lexer.zig");
    const parserMod = @import("../parser.zig");
    var lx = lexerMod.Lexer.init(
        \\fn audit(comptime decl: @Decl) {
        \\    @emit("pub val seen = 1;");
        \\}
    );
    var p = parserMod.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const dfn = program.decls[0].@"fn";

    var unsupported: erlang.UnsupportedMethod = .{};
    var refused: []const u8 = "";
    const first = try buildModule(arena, "", dfn, &.{}, &.{}, &.{}, .{
        .kind = "Type",
        .name = "Alpha",
        .fields = &.{},
        .methods = &.{},
        .returnType = "",
        .annotations = &.{},
    }, &.{}, null, &unsupported, &refused);
    const second = try buildModule(arena, "", dfn, &.{}, &.{}, &.{}, .{
        .kind = "Type",
        .name = "Omega",
        .fields = &.{.{ .name = "x", .typeName = "i32", .annotations = &.{} }},
        .methods = &.{},
        .returnType = "",
        .annotations = &.{},
    }, &.{}, null, &unsupported, &refused);

    try std.testing.expectEqualStrings(first.module, second.module);
    try std.testing.expectEqualStrings(first.code, second.code);
    // Same module, different argument — which is the whole of step 2.
    try std.testing.expectEqualStrings("Alpha", first.argument.tuple[0].map[1].value.binary);
    try std.testing.expectEqualStrings("Omega", second.argument.tuple[0].map[1].value.binary);
}

test "decorator outcome: ok / fail / error replies" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const ok = try parseOutcome(arena, "{\"kind\":\"ok\",\"contributions\":[{\"kind\":\"emit\",\"source\":\"pub val x = 1;\"},{\"kind\":\"member\",\"source\":\"pub fn f() {}\"}]}");
    try std.testing.expectEqualStrings("pub val x = 1;", ok.ok[0].source);
    try std.testing.expectEqual(Contribution.Kind.emit, ok.ok[0].kind);
    try std.testing.expectEqual(Contribution.Kind.member, ok.ok[1].kind);

    const fail = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"no\",\"span\":null}");
    try std.testing.expectEqualStrings("no", fail.fail.message);
    try std.testing.expect(fail.fail.span == null);

    const at = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"bad\",\"span\":{\"start\":1,\"end\":4,\"line\":2}}");
    try std.testing.expectEqual(@as(usize, 4), at.fail.span.?.end);

    const arg = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"low\",\"span\":{\"arg\":1}}");
    try std.testing.expectEqual(@as(?usize, 1), arg.fail.arg);
    try std.testing.expect(arg.fail.span == null);

    const meta = try parseOutcome(arena, "{\"kind\":\"ok\",\"contributions\":[{\"kind\":\"typedMeta\",\"index\":1,\"data\":{\"table\":\"cities\"}}]}");
    try std.testing.expectEqual(Contribution.Kind.typedMeta, meta.ok[0].kind);
    try std.testing.expectEqual(@as(usize, 1), meta.ok[0].index);
    try std.testing.expectEqualStrings("cities", meta.ok[0].data.?.object.get("table").?.string);

    const err = try parseOutcome(arena, "{\"kind\":\"error\",\"message\":\"{error,badarg}\"}");
    try std.testing.expectEqualStrings("{error,badarg}", err.err);

    const garbage = try parseOutcome(arena, "not json");
    try std.testing.expect(garbage == .err);
}

// ── independent invocations (decision 343) ──────────────────────────────────

/// A write of a module-level `var` by a decorator body.
pub const VarWrite = struct { name: []const u8, loc: ast.Loc };

/// Decision 343 — the first module-level `var` (of `decls`) the decorator
/// `dfn` writes — in its body, or in a function of this module the body calls
/// — when no local or parameter of that function names it. Each invocation is
/// independent: a decorator's answer depends on its declaration alone, so a
/// write that would carry state from one declaration to the next is refused
/// at the write, before the body runs (it used to read `unbound variable` at
/// the `var`'s first read).
pub fn moduleVarWrite(arena: std.mem.Allocator, decls: []const ast.DeclKind, dfn: ast.FnDecl) std.mem.Allocator.Error!?VarWrite {
    var vars: std.StringHashMapUnmanaged(void) = .empty;
    var fns: std.StringHashMapUnmanaged(ast.FnDecl) = .empty;
    for (decls) |d| switch (d) {
        .val => |v| if (v.mutable) try vars.put(arena, v.name, {}),
        .@"fn" => |f| try fns.put(arena, f.name, f),
        else => {},
    };
    if (vars.count() == 0) return null;
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    var queue: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    try queue.append(arena, dfn);
    try seen.put(arena, dfn.name, {});
    var i: usize = 0;
    while (i < queue.items.len) : (i += 1) {
        const f = queue.items[i];
        const declared = try blockEval.declaredNames(arena, f.body);
        // The program's code a decorator hands on — a member function
        // (370 (2)), a wrapper (316) — runs at run time, not in the body.
        var w = WriteWalk{ .arena = arena, .vars = &vars, .declName = if (i == 0) memberFnMod.declParamName(f) else null };
        for (f.body) |*st| try w.walk(ast.Expr, &st.expr);
        for (w.writes.items) |wr| {
            if (declared.contains(wr.name)) continue;
            for (f.params) |p| {
                if (std.mem.eql(u8, p.name, wr.name)) break;
            } else return wr;
        }
        for (w.calls.items) |callee| {
            if (seen.contains(callee)) continue;
            const g = fns.get(callee) orelse continue;
            if (g.body.len == 0) continue;
            try seen.put(arena, callee, {});
            try queue.append(arena, g);
        }
    }
    return null;
}

const WriteWalk = struct {
    arena: std.mem.Allocator,
    vars: *const std.StringHashMapUnmanaged(void),
    writes: std.ArrayListUnmanaged(VarWrite) = .empty,
    calls: std.ArrayListUnmanaged([]const u8) = .empty,
    declName: ?[]const u8 = null,

    fn walk(self: *WriteWalk, comptime U: type, ptr: *const U) std.mem.Allocator.Error!void {
        if (U == ast.Expr) if (self.declName) |dn| {
            if (memberFnMod.asWrapCall(ptr.*, dn) != null or memberFnMod.asCall(ptr.*, dn) != null) return;
        };
        if (U == ast.Expr) switch (ptr.*) {
            .binding => |b| switch (b.kind) {
                .assign => |a| switch (a.target) {
                    .name => |n| if (self.vars.contains(n)) try self.writes.append(self.arena, .{ .name = n, .loc = b.loc }),
                    else => {},
                },
                else => {},
            },
            .call => |c| if (c.kind == .call and !c.kind.call.is_builtin and c.kind.call.receiver == null) {
                try self.calls.append(self.arena, c.kind.call.callee);
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

/// Decision 343 — the first decorator of `decls` writing a module-level
/// `var` (`moduleVarWrite`), refused at the write.
pub fn checkIndependent(arena: std.mem.Allocator, decls: []const ast.DeclKind, isDecorator: anytype) std.mem.Allocator.Error!?validation.TypeError {
    for (decls) |d| {
        if (d != .@"fn") continue;
        const dfn = d.@"fn";
        if (dfn.body.len == 0 or !isDecorator(dfn.params)) continue;
        const w = try moduleVarWrite(arena, decls, dfn) orelse continue;
        const msg = try std.fmt.allocPrint(arena, "{s}: the decorator `{s}` writes the module-level `var` `{s}` — each decorator invocation is independent: its answer depends on the declaration it annotates alone (decision 343)", .{ diagnostics.decorator_writes_module_var, dfn.name, w.name });
        return validation.TypeError.custom(msg, "Read a catalogue at the entry point with `@TypeInfo.all(with: …)` — a duplicate across declarations is refused there, naming both — instead of collecting it in a module-level `var`.").withLoc(w.loc);
    }
    return null;
}
