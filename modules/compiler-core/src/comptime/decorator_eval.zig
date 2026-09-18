/// Decorator invocation in the persistent erl runtime.
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core reflects that
/// declaration into a `DeclHandle` and runs the decorator body over it:
///
///   decorator `FnDecl` ─ codegen/erlang.zig `emitComptimeModule` ─┐
///   handle + args ─ `Term` ─ codegen/beam/erl_emitter ─ `main/0` ──┴→ .erl
///     → comptime/runtime/persistent_erl `evalDetailed`
///     → JSON `{kind, contributions | message | span}` → `Outcome`
///
/// The body is lowered by the regular Erlang backend (untyped mode), so every
/// construct that backend supports works in a decorator. The host functions the
/// body calls (`decl.fail`, `decl.failAt`, `@compilerError`, `@emit`) are plain
/// Erlang functions resident in `bp_comptime_decorator`, built once at server
/// warmup (`runtime/prelude.zig`) and reached by the `-import`
/// `emitComptimeModule` writes; only `main/0` is generated per evaluation.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const templateEval = @import("./template_eval.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const persistent_erl = @import("./runtime/persistent_erl.zig");
const preludeMod = @import("./runtime/prelude.zig");
const trace = @import("./trace.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

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

    // Staged and renamed into place (`template_eval.writeModule`).
    const path = try templateEval.writeModule(arena, io, ".botopinkbuild/tmp/decorator", source.module, source.code);

    const response = persistent_erl.evalDetailed(arena, io, path) catch return error.EvalFailed;
    if (traces) |list| try list.append(arena, .{
        .kind = .decorator,
        .name = dfn.name,
        .erl = source.listing,
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
    /// Erlang module atom, derived from the code's hash (unique per distinct
    /// evaluation, stable across runs).
    module: []const u8,
    code: []const u8,
    /// The lowered body and `main/0` only (`trace.Entry.erl`).
    listing: []const u8,
};

const placeholder_module = "decorator_module";

/// `main/0` — the one host form whose text depends on the call site: it calls
/// the decorator with this declaration's handle and the annotation arguments and
/// replies with JSON. `fail`/`failAt`/`compilerError` (which throw the tagged
/// rejection caught here) and `emit`/`'__bp_emitted'` are resident
/// (`runtime/prelude.zig`), reached by the `-import` `emitComptimeModule` writes.
fn mainForms(b: Ast.Builder, dfn: ast.FnDecl, handle: Term, plainArgs: []const template.PlainArg) Ast.Builder.Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A(preludeMod.decorator_fail_tag);
    const emitted_key = A(preludeMod.emitted_key);

    // <decorator>(Handle, Arg1, …): parameters after the `@Decl` one bind the
    // annotation's arguments in order; a missing argument is `undefined`.
    const args = try b.arena.alloc(Ast.Expr, @max(dfn.params.len, 1));
    args[0] = Ast.Expr.t(handle);
    for (args[1..], 0..) |*arg, i| {
        arg.* = if (i < plainArgs.len) plainArgs[i].toExpr() else A("undefined");
    }
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
        .{ .function = .{ .name = "main", .clauses = try b.arena.dupe(Ast.Clause, &.{.{ .patterns = &.{}, .body = main_body }}) } },
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
    const forms = try mainForms(b, dfn, try handleToTerm(arena, handle), plainArgs);
    const resident = try preludeMod.decoratorForms(b);

    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = dfn };
    var config: erlang.ComptimeModule = .{
        .host_enums = &.{"DeclKind"},
        // `decl.failAt(Span(start, end, line), msg)` builds the span map.
        .host_records = &.{.{ .name = "Span", .fields = &.{ "start", "end", "line" } }},
        .exports = &.{.{ .name = "main", .arity = 0 }},
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
    // What snapshots show: the lowered body and `main/0`. `resident` stays set:
    // it decides where a method call lowers, so dropping it would make the
    // listing diverge from the module that actually ran.
    config.listing = true;
    const listing = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch return error.EvalFailed;

    const module = try std.fmt.allocPrint(arena, "decorator_{x:0>16}", .{std.hash.Wyhash.hash(0, code)});
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });
    return .{ .module = module, .code = renamed, .listing = listing };
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

    try std.testing.expect(std.mem.startsWith(u8, m.module, "decorator_"));
    try std.testing.expect(std.mem.startsWith(u8, m.code, "-module(decorator_"));
    const expected = [_][]const u8{
        "-export([main/0]).",
        "(maps:get(kind, Decl) =/= 'Method')",
        "fail(Decl, <<\"#[getMapping] must annotate a method\">>)",
        \\        getMapping(#{
        \\            kind => 'Type',
        \\            name => <<"Nope">>,
        \\            fields => [],
        \\            variants => [],
        \\            methods => [],
        \\            returnType => <<"">>,
        \\            annotations => []
        \\        }, <<"/x">>, undefined),
        ,
        "throw:{'__bp_decorator_fail', Message, Span} ->",
    };
    for (expected) |needle| {
        if (std.mem.indexOf(u8, m.code, needle) == null) {
            std.debug.print("\nmissing:\n{s}\nin:\n{s}\n", .{ needle, m.code });
            return error.TestExpectedContains;
        }
    }
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
