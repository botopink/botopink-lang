/// Decorator invocation in the persistent erl runtime.
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core reflects that
/// declaration into a `DeclHandle` and runs the decorator body over it:
///
///   decorator `FnDecl` ─ codegen/erlang.zig `emitComptimeModule` ─ `main/1` → .erl
///   handle + args ─ `Term` ─ comptime/runtime/etf ─ external term ─┐
///     → comptime/runtime/persistent_erl `evalWithArg`              │
///       (compile+load once, then call `<module>:main(<term>)`) ←───┘
///     → JSON `{kind, contributions | message | span}` → `Outcome`
///
/// The body is lowered by the regular Erlang backend (untyped mode), so every
/// construct that backend supports works in a decorator. The host functions the
/// body calls (`decl.fail`, `decl.failAt`, `@compilerError`, `@emit`) are plain
/// Erlang functions resident in `bp_comptime_decorator`, built once at server
/// warmup (`runtime/prelude.zig`) and reached by the `-import`
/// `emitComptimeModule` writes; only `main/1` is generated, and it carries nothing
/// from the declaration it runs over — so one `.erl` serves every declaration a
/// decorator annotates with the same annotation arguments.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const crossModule = @import("../codegen/crossModule.zig");
const templateEval = @import("./template_eval.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const hostRuntime = @import("./runtime/runtime.zig");
const preludeMod = @import("./runtime/prelude.zig");
const etf = @import("./runtime/etf.zig");
const trace = @import("./trace.zig");

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
};

pub const FieldHandle = struct {
    name: []const u8,
    typeName: []const u8,
    annotations: []const ast.Annotation,
};

pub const Outcome = union(enum) {
    /// Accepted; `@emit(...)` sources in call order.
    ok: []const []const u8,
    /// Rejected by the body (`decl.fail` / `decl.failAt` / `@compilerError`).
    fail: struct { message: []const u8, span: ?template.Span },
    /// The evaluator itself failed (module did not compile, body raised, …).
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

/// Longest compiler/runtime diagnostic carried into `Outcome.err`.
const max_error_detail = 4096;

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
    /// Receives what was sent to and returned by the runtime (snapshots); null skips it.
    traces: ?*std.ArrayListUnmanaged(trace.Entry),
) EvalError!Outcome {
    _ = build_root;
    var unsupported: erlang.UnsupportedMethod = .{};
    const source = buildModule(arena, dfn, handle, plainArgs, &unsupported) catch |err| switch (err) {
        error.UnsupportedMethod => return .{ .err = try unsupportedText(arena, "decorator", dfn.name, unsupported) },
        else => |e| return e,
    };

    // The runtime is the target's (decision 84, `runtime/runtime.zig`); the
    // dispatcher stages the module for the BEAM runtime or lowers it for wat.
    const result = try hostRuntime.evalWithArg(
        arena,
        io,
        "decorator",
        ".botopinkbuild/tmp/decorator",
        source.module,
        source.code,
        try etf.encode(arena, source.argument),
    );
    const response = switch (result) {
        .response => |r| r,
        .unavailable => |why| return .{ .err = why },
    };
    if (traces) |list| try list.append(arena, .{
        .kind = .decorator,
        .name = dfn.name,
        .listing = try hostRuntime.listingOf(arena, source.module, source.code, source.listing),
        .lang = if (hostRuntime.current() == .wat) .wat else .erlang,
        .reply = switch (response) {
            .ok => |stdout| stdout,
            .compile_error => |detail| try std.fmt.allocPrint(arena, "compile error: {s}", .{detail}),
            .runtime_error => |detail| try std.fmt.allocPrint(arena, "runtime error: {s}", .{detail}),
        },
    });
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
fn unsupportedText(arena: std.mem.Allocator, host: []const u8, name: []const u8, m: erlang.UnsupportedMethod) ![]const u8 {
    return std.fmt.allocPrint(
        arena,
        "the {s} `{s}` calls `.{s}(…)` with {d} argument(s) at {d}:{d}, which no primitive type (string, array, int, float, bool) and no {s} host function provides",
        .{ host, name, m.callee, m.argc, m.loc.line, m.loc.col, host },
    );
}

// ── module ────────────────────────────────────────────────────────────────────

const Module = struct {
    /// Erlang module atom, derived from the code's hash. The code carries no
    /// handle, so every declaration a decorator annotates with the same
    /// annotation arguments derives the same atom.
    module: []const u8,
    code: []const u8,
    /// The lowered body and `main/1`, with the argument as a comment
    /// (`trace.Entry.listing` on the BEAM runtime).
    listing: []const u8,
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
fn mainForms(b: Ast.Builder, dfn: ast.FnDecl, plans: []const templateEval.ArgPlan) Ast.Builder.Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A(preludeMod.decorator_fail_tag);
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
            .catches = try b.arena.dupe(Ast.Clause, &.{
                .{
                    .patterns = try b.exprs(&.{try b.exception(A("throw"), try b.tuple(&.{ fail_tag, V("Message"), V("Span") }))}),
                    .body = try b.body(&.{try encode(b, &.{
                        Ast.field("kind", Ast.str("fail")),
                        Ast.field("message", try b.call("__bp_text", &.{V("Message")})),
                        Ast.field("span", V("Span")),
                    })}),
                },
                .{
                    .patterns = try b.exprs(&.{try b.exception(V("Class"), V("Reason"))}),
                    .body = try b.body(&.{try encode(b, &.{
                        Ast.field("kind", Ast.str("error")),
                        Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ V("Class"), V("Reason") })})),
                    })}),
                },
            }),
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
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
    unsupported: *erlang.UnsupportedMethod,
) (EvalError || error{UnsupportedMethod})!Module {
    const b: Ast.Builder = .{ .arena = arena };
    const plans = try argPlans(arena, dfn, handle, plainArgs);
    const forms = try mainForms(b, dfn, plans);
    const resident = try preludeMod.decoratorForms(b);

    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = dfn };
    var config: erlang.ComptimeModule = .{
        .host_enums = &.{"DeclKind"},
        // `decl.failAt(Span(start, end, line), msg)` builds the span map.
        .host_records = &.{.{ .name = "Span", .fields = &.{ "start", "end", "line" } }},
        .exports = &.{.{ .name = "main", .arity = 1 }},
        .forms = forms,
        .resident = .{
            .module = preludeMod.decorator_module,
            .forms = resident,
            .refs = try preludeMod.exportRefs(arena, resident),
        },
        .unsupported_method = unsupported,
    };
    const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch |err|
        return if (err == error.UnsupportedComptimeMethod) error.UnsupportedMethod else error.EvalFailed;
    const argument = try templateEval.argumentTerm(arena, plans);
    // A2: `bp@comptime__dec__<decorator>__<16 hex>`; the Wyhash is unchanged, so
    // content-addressing survives (see `template_eval.buildModule`).
    const module = crossModule.erlDeclAtom(arena, templateEval.comptime_owner, .dec, dfn.name, std.hash.Wyhash.hash(0, code)) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.EvalFailed,
    };
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });

    // What snapshots show: the lowered body, `main/1` and the argument as a
    // comment. `resident` stays set: it decides where a method call lowers, so
    // dropping it would make the listing diverge from the module that ran.
    // Rendered once per module, not once per annotated declaration.
    const listing = templateEval.cachedListing(module) orelse blk: {
        config.listing = true;
        const fresh = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch return error.EvalFailed;
        break :blk try templateEval.rememberListing(module, fresh);
    };
    return .{
        .module = module,
        .code = renamed,
        .listing = try templateEval.listingWithArgument(arena, listing, argument),
        .argument = argument,
    };
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
        const name = try std.fmt.allocPrint(arena, "Arg{d}", .{i + 1});
        plan.* = if (try templateEval.plainArgTerm(arena, plainArgs[i])) |t|
            .{ .term = t, .expr = Ast.Expr.v(name), .bound = true }
        else
            .{ .term = Term.undefined_atom, .expr = plainArgs[i].toExpr(), .bound = false };
    }
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
        entries[2] = Term.field("annotations", try annotationsToTerm(arena, f.annotations));
        fields[i] = Term.mapOf(entries);
    }

    const methods = try arena.alloc(Term, handle.methods.len);
    for (handle.methods, 0..) |m, i| {
        const params = try arena.alloc(Term, m.params.len);
        for (m.params, 0..) |p, j| {
            const pe = try arena.alloc(Term.MapEntry, 2);
            pe[0] = Term.field("name", Term.str(p.name));
            pe[1] = Term.field("typeName", Term.str(typeName(p.typeRef, p.typeName)));
            params[j] = Term.mapOf(pe);
        }
        const entries = try arena.alloc(Term.MapEntry, 4);
        entries[0] = Term.field("name", Term.str(m.name));
        entries[1] = Term.field("params", Term.listOf(params));
        entries[2] = Term.field("returnType", Term.str(if (m.returnType) |rt| typeName(rt, "") else ""));
        entries[3] = Term.field("annotations", try annotationsToTerm(arena, m.annotations));
        methods[i] = Term.mapOf(entries);
    }

    const variants = try arena.alloc(Term, handle.variants.len);
    for (handle.variants, 0..) |v, i| variants[i] = Term.str(v);

    const entries = try arena.alloc(Term.MapEntry, 7);
    entries[0] = Term.field("kind", Term.atomOf(handle.kind));
    entries[1] = Term.field("name", Term.str(handle.name));
    entries[2] = Term.field("fields", Term.listOf(fields));
    entries[3] = Term.field("variants", Term.listOf(variants));
    entries[4] = Term.field("methods", Term.listOf(methods));
    entries[5] = Term.field("returnType", Term.str(handle.returnType));
    entries[6] = Term.field("annotations", try annotationsToTerm(arena, handle.annotations));
    return Term.mapOf(entries);
}

/// Display name of a type reference; `fallback` when the reference has none.
fn typeName(tr: ast.TypeRef, fallback: []const u8) []const u8 {
    return switch (tr) {
        .named => |n| n,
        .generic => |g| g.name,
        else => fallback,
    };
}

/// `[#{name => <<"getMapping">>, args => [<<"\"/users\"">>]}]` — args keep their
/// raw source lexemes (`DeclAnnotation.args` in `builtins.d.bp`).
fn annotationsToTerm(arena: std.mem.Allocator, anns: []const ast.Annotation) std.mem.Allocator.Error!Term {
    const items = try arena.alloc(Term, anns.len);
    for (anns, 0..) |a, i| {
        const args = try arena.alloc(Term, a.args.len);
        for (a.args, 0..) |arg, j| args[j] = Term.str(arg);
        const entries = try arena.alloc(Term.MapEntry, 2);
        entries[0] = Term.field("name", Term.str(a.name));
        entries[1] = Term.field("args", Term.listOf(args));
        items[i] = Term.mapOf(entries);
    }
    return Term.listOf(items);
}

// ── outcome ───────────────────────────────────────────────────────────────────

/// The JSON object `main/0` returns.
const Reply = struct {
    kind: []const u8,
    contributions: []const []const u8 = &.{},
    message: []const u8 = "",
    span: ?template.Span = null,
};

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) EvalError!Outcome {
    const reply = std.json.parseFromSliceLeaky(Reply, arena, stdout, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    }) catch return .{ .err = try errorText(arena, "the decorator evaluator returned an unreadable result", stdout) };

    if (std.mem.eql(u8, reply.kind, "ok")) return .{ .ok = reply.contributions };
    if (std.mem.eql(u8, reply.kind, "fail")) return .{ .fail = .{
        .message = if (reply.message.len > 0) reply.message else "decorator rejected the declaration",
        .span = reply.span,
    } };
    return .{ .err = if (reply.message.len > 0) reply.message else "decorator evaluation failed" };
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "decorator module: lowered body, handle term and host glue" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const lexerMod = @import("../lexer.zig");
    const parserMod = @import("../parser.zig");
    var lx = lexerMod.Lexer.init(
        \\fn getMapping(comptime decl: @Decl, path: string, verb: string) {
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
    const m = try buildModule(arena, dfn, handle, &args, &unsupported);

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
        "-import(bp_comptime_decorator, [fail/2, failAt/3, compilerError/1, emit/1, '__bp_emitted'/0,",
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
    try std.testing.expect(std.mem.indexOf(u8, m.listing, "%% main/1 argument") != null);
    // This handle is short enough to stay on one line; a real one wraps.
    try std.testing.expect(std.mem.indexOf(u8, m.listing, "name => <<\"Nope\">>,") != null);
    try std.testing.expect(std.mem.indexOf(u8, m.listing, "%% Arg1 = <<\"/x\">>") != null);
    try std.testing.expect(std.mem.indexOf(u8, m.listing, "%% Arg2 = undefined") != null);
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
    const first = try buildModule(arena, dfn, .{
        .kind = "Type",
        .name = "Alpha",
        .fields = &.{},
        .methods = &.{},
        .returnType = "",
        .annotations = &.{},
    }, &.{}, &unsupported);
    const second = try buildModule(arena, dfn, .{
        .kind = "Type",
        .name = "Omega",
        .fields = &.{.{ .name = "x", .typeName = "i32", .annotations = &.{} }},
        .methods = &.{},
        .returnType = "",
        .annotations = &.{},
    }, &.{}, &unsupported);

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

    const ok = try parseOutcome(arena, "{\"kind\":\"ok\",\"contributions\":[\"pub val x = 1;\"]}");
    try std.testing.expectEqualStrings("pub val x = 1;", ok.ok[0]);

    const fail = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"no\",\"span\":null}");
    try std.testing.expectEqualStrings("no", fail.fail.message);
    try std.testing.expect(fail.fail.span == null);

    const at = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"bad\",\"span\":{\"start\":1,\"end\":4,\"line\":2}}");
    try std.testing.expectEqual(@as(usize, 4), at.fail.span.?.end);

    const err = try parseOutcome(arena, "{\"kind\":\"error\",\"message\":\"{error,badarg}\"}");
    try std.testing.expectEqualStrings("{error,badarg}", err.err);

    const garbage = try parseOutcome(arena, "not json");
    try std.testing.expect(garbage == .err);
}
