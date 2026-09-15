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
/// construct that backend supports works in a decorator. Host functions the
/// body calls (`decl.fail`, `decl.failAt`, `@compilerError`, `@emit`) are plain
/// Erlang functions appended to the module.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const persistent_erl = @import("./runtime/persistent_erl.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

/// Reflection of the annotated declaration (`@Decl` in `builtins.d.bp`).
pub const DeclHandle = struct {
    kind: []const u8,
    name: []const u8,
    fields: []const FieldHandle,
    methods: []const ast.InterfaceMethod,
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
) EvalError!Outcome {
    _ = build_root;
    const source = try buildModule(arena, dfn, handle, plainArgs);

    const dir = ".botopinkbuild/tmp/decorator";
    std.Io.Dir.cwd().createDirPath(io, dir) catch return error.EvalFailed;
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, source.module });
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = source.code }) catch return error.EvalFailed;

    const response = persistent_erl.evalDetailed(arena, io, path) catch return error.EvalFailed;
    return switch (response) {
        .ok => |stdout| parseOutcome(arena, stdout),
        .compile_error => |detail| .{ .err = try errorText(arena, "the decorator module did not compile", detail) },
        .load_error => |detail| .{ .err = try errorText(arena, "the decorator module did not load", detail) },
        .runtime_error => |detail| .{ .err = try errorText(arena, "the decorator body raised", detail) },
    };
}

fn errorText(arena: std.mem.Allocator, what: []const u8, detail: []const u8) ![]const u8 {
    const shown = detail[0..@min(detail.len, max_error_detail)];
    const ellipsis = if (detail.len > max_error_detail) " …" else "";
    return std.fmt.allocPrint(arena, "{s}: {s}{s}", .{ what, shown, ellipsis });
}

// ── module ────────────────────────────────────────────────────────────────────

const Module = struct {
    /// Erlang module atom, derived from the code's hash (unique per distinct
    /// evaluation, stable across runs).
    module: []const u8,
    code: []const u8,
};

const placeholder_module = "decorator_module";

/// Host functions the lowered body calls plus the `main/0` entry.
/// `fail`/`failAt`/`compilerError` throw a tagged rejection caught by `main/0`;
/// `emit` accumulates sources in the process dictionary. `main/0` calls the
/// decorator with the handle and the annotation arguments and replies with JSON.
fn hostForms(b: Ast.Builder, dfn: ast.FnDecl, handle: Term, plainArgs: []const template.PlainArg) Ast.Builder.Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A("__bp_decorator_fail");
    const emitted_key = A("__bp_emitted");

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
        try b.function("fail", &.{ V("_Decl"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), A("null") })}),
        }),
        try b.function("failAt", &.{ V("_Decl"), V("Span"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), V("Span") })}),
        }),
        try b.function("compilerError", &.{V("Message")}, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), A("null") })}),
        }),
        try b.function("emit", &.{V("Source")}, &.{}, &.{
            try b.remote("erlang", "put", &.{ emitted_key, try b.cons(&.{V("Source")}, emitted) }),
            A("ok"),
        }),
        try b.function("__bp_emitted", &.{}, &.{}, &.{
            try b.caseOf(try b.remote("erlang", "get", &.{emitted_key}), &.{
                try b.clause(&.{A("undefined")}, &.{}, &.{try b.list(&.{})}),
                try b.clause(&.{V("Sources")}, &.{}, &.{V("Sources")}),
            }),
        }),
        .{ .function = .{ .name = "main", .clauses = try b.arena.dupe(Ast.Clause, &.{.{ .patterns = &.{}, .body = main_body }}) } },
    };
    return b.arena.dupe(Ast.Form, &forms);
}

fn buildModule(
    arena: std.mem.Allocator,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError!Module {
    const b: Ast.Builder = .{ .arena = arena };
    const forms = try hostForms(b, dfn, try handleToTerm(arena, handle), plainArgs);

    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = dfn };
    const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, .{
        .host_enums = &.{"DeclKind"},
        .exports = &.{.{ .name = "main", .arity = 0 }},
        .forms = forms,
    }) catch return error.EvalFailed;

    const module = try std.fmt.allocPrint(arena, "decorator_{x:0>16}", .{std.hash.Wyhash.hash(0, code)});
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });
    return .{ .module = module, .code = renamed };
}

// ── handle ────────────────────────────────────────────────────────────────────

/// The `@Decl` handle as a BEAM term — the map the decorator body reads
/// (`decl.kind`, `decl.fields`, …). `kind` is an atom so it matches the lowering
/// of `DeclKind.Record` (`'Record'`); names and type names are binaries.
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

    const entries = try arena.alloc(Term.MapEntry, 6);
    entries[0] = Term.field("kind", Term.atomOf(handle.kind));
    entries[1] = Term.field("name", Term.str(handle.name));
    entries[2] = Term.field("fields", Term.listOf(fields));
    entries[3] = Term.field("methods", Term.listOf(methods));
    entries[4] = Term.field("returnType", Term.str(handle.returnType));
    entries[5] = Term.field("annotations", try annotationsToTerm(arena, handle.annotations));
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
        .kind = "Record",
        .name = "Nope",
        .fields = &.{},
        .methods = &.{},
        .returnType = "",
        .annotations = &.{},
    };
    const args = [_]template.PlainArg{.{ .paramName = "path", .source = "\"/x\"" }};
    const m = try buildModule(arena, dfn, handle, &args);

    try std.testing.expect(std.mem.startsWith(u8, m.module, "decorator_"));
    try std.testing.expect(std.mem.startsWith(u8, m.code, "-module(decorator_"));
    const expected = [_][]const u8{
        "-export([main/0]).",
        "(maps:get(kind, Decl) =/= 'Method')",
        "fail(Decl, <<\"#[getMapping] must annotate a method\">>)",
        "getMapping(#{kind => 'Record', name => <<\"Nope\">>, fields => [], methods => [], returnType => <<\"\">>, annotations => []}, <<\"/x\">>, undefined),",
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
