/// Template evaluation in the persistent erl runtime.
///
/// When the V1 classifier in `infer.zig` cannot reduce a template body by
/// inspection, the body runs here:
///
///   template `FnDecl` ─ codegen/erlang.zig `emitComptimeModule` ─┐
///   captures + plain args ─ `Term` ─ codegen/beam/erl_emitter ─ `main/0` ──┴→ .erl
///     → comptime/runtime/persistent_erl `evalDetailed`
///     → JSON reply → `Outcome`
///
/// Reply format (`main/0`):
///   {"kind":"code","source":"…"}                  ← `q.build(src)` / `@code(src)`
///   {"kind":"value","value":<json>}               ← `@expr(v)`
///   {"kind":"capture","param":"q"}                ← `return q`
///   {"kind":"custom","source":"…","ast":<tree>}   ← `q.custom(tree, code)`
///   {"kind":"fail","message","param","span"}      ← `q.fail` / `q.failAt` / `@compilerError`
///   {"kind":"error","message"}                    ← anything else raised
///
/// A capture reaches the body as a map; its methods (`q.text()`, `q.parts()`,
/// `q.lookup(name)`, …) lower to the host functions appended to the module.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const persistent_erl = @import("./runtime/persistent_erl.zig");
const trace = @import("./trace.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

// ── results ───────────────────────────────────────────────────────────────────

/// A value lifted by `@expr(…)`.
pub const TypedValue = union(enum) {
    integer: i64,
    float: f64,
    string: []const u8,
    bool: bool,
    null: void,
    array: []const TypedValue,
    object: []const KeyValuePair,

    pub const KeyValuePair = struct {
        key: []const u8,
        value: TypedValue,
    };
};

/// A `CustomNode` tree returned through `q.custom(tree, code)`.
pub const CustomNodeTree = struct {
    kind: []const u8,
    span: ?template.Span = null,
    label: ?[]const u8 = null,
    ref: ?template.NodeBinding = null,
    children: []const CustomNodeTree = &.{},
};

pub const Outcome = union(enum) {
    code: []const u8,
    value: TypedValue,
    capture: []const u8,
    custom: struct { code: []const u8, ast: CustomNodeTree },
    fail: struct {
        message: []const u8,
        param: ?[]const u8,
        span: ?template.Span,
    },
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

/// Longest compiler/runtime diagnostic carried into `Outcome.err`.
const max_error_detail = 4096;

// ── evaluate ──────────────────────────────────────────────────────────────────

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    /// Receives what was sent to and returned by the runtime (snapshots); null skips it.
    traces: ?*std.ArrayListUnmanaged(trace.Entry),
) EvalError!Outcome {
    _ = build_root;
    var unsupported: erlang.UnsupportedMethod = .{};
    const source = buildModule(arena, tfn, captures, plainArgs, &unsupported) catch |err| switch (err) {
        error.UnsupportedMethod => return .{ .err = try unsupportedText(arena, "template", tfn.name, unsupported) },
        else => |e| return e,
    };

    const path = try writeModule(arena, io, ".botopinkbuild/tmp/template", source.module, source.code);

    const response = persistent_erl.evalDetailed(arena, io, path) catch return error.EvalFailed;
    if (traces) |list| try list.append(arena, .{
        .kind = .template,
        .name = tfn.name,
        .erl = source.listing,
        .reply = switch (response) {
            .ok => |stdout| stdout,
            .compile_error => |detail| try std.fmt.allocPrint(arena, "compile error: {s}", .{detail}),
            .runtime_error => |detail| try std.fmt.allocPrint(arena, "runtime error: {s}", .{detail}),
        },
    });
    return switch (response) {
        .ok => |stdout| parseOutcome(arena, stdout),
        .compile_error => |detail| .{ .err = try errorText(arena, "the template module did not compile", detail) },
        .runtime_error => |detail| .{ .err = try errorText(arena, "the template body raised", detail) },
    };
}

/// Write `<dir>/<module>.erl` and return its path. The module is written to a
/// uniquely named sibling first and renamed into place, so a reader never sees
/// a partial file: two evaluations of the same body — concurrent tests, or two
/// compiler processes sharing a working directory — derive the same
/// content-hashed name, and a plain truncate-and-write let one `compile:file`
/// read the file mid-rewrite and fail with no usable diagnostic.
pub fn writeModule(arena: std.mem.Allocator, io: std.Io, dir: []const u8, module: []const u8, code: []const u8) EvalError![]const u8 {
    const cwd = std.Io.Dir.cwd();
    cwd.createDirPath(io, dir) catch return error.EvalFailed;
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, module });
    var nonce: [8]u8 = undefined;
    io.random(&nonce);
    const staging = try std.fmt.allocPrint(arena, "{s}.{x}.tmp", .{ path, std.mem.readInt(u64, &nonce, .little) });
    cwd.writeFile(io, .{ .sub_path = staging, .data = code }) catch return error.EvalFailed;
    cwd.rename(staging, cwd, path, io) catch {
        cwd.deleteFile(io, staging) catch {};
        return error.EvalFailed;
    };
    return path;
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
    /// Erlang module atom derived from the code's hash.
    module: []const u8,
    code: []const u8,
    /// The lowered body and `main/0` only (`trace.Entry.erl`).
    listing: []const u8,
};

const placeholder_module = "template_module";

/// Records of the `std.syntax` template model a body may construct.
const host_records = [_]erlang.HostRecord{
    .{ .name = "Span", .fields = &.{ "start", "end", "line" } },
    .{ .name = "CustomNode", .fields = &.{ "kind", "span", "label", "ref", "children" } },
    .{ .name = "Binding", .fields = &.{ "name", "kind" } },
    .{ .name = "Source", .fields = &.{ "file", "line", "col" } },
    .{ .name = "Context", .fields = &.{ "source", "text", "multiline" } },
};

/// Host functions for the capture API, the reply encoder and `main/0`. A capture
/// is a map tagged with `'__bp_capture'` (its parameter name); `build`/`custom`/
/// `expr`/`code` wrap the body's result in a tagged tuple `'__bp_reply'`
/// dispatches on.
fn hostForms(
    b: Ast.Builder,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A("__bp_template_fail");
    const code_tag = A("__bp_code");

    const args = try b.arena.alloc(Ast.Expr, tfn.params.len);
    for (tfn.params, 0..) |p, i| args[i] = try paramExpr(b.arena, p.name, i, captures, plainArgs);
    const invoke: Ast.Expr = .{ .call = .{ .name = tfn.name, .args = args } };

    const throw = struct {
        fn call(bb: Ast.Builder, items: []const Ast.Expr) Ast.Builder.Error!Ast.Expr {
            return bb.remote("erlang", "throw", &.{try bb.tuple(items)});
        }
    }.call;
    const json = struct {
        fn encode(bb: Ast.Builder, fields: []const Ast.MapField) Ast.Builder.Error!Ast.Expr {
            return bb.remote("json", "encode", &.{try bb.map(fields)});
        }
    }.encode;

    // Capture accessors: `text(#{text := Text}) -> Text.` …
    const accessors = [_][2][]const u8{
        .{ "text", "Text" },       .{ "parts", "Parts" },       .{ "source", "Source" },
        .{ "context", "Context" }, .{ "bindings", "Bindings" },
    };
    var forms: std.ArrayListUnmanaged(Ast.Form) = .empty;
    for (accessors) |acc| {
        try forms.append(b.arena, try b.function(acc[0], &.{try b.map(&.{Ast.exactField(acc[0], V(acc[1]))})}, &.{}, &.{V(acc[1])}));
    }

    const capture_param = try b.map(&.{.{ .key = A("__bp_capture"), .value = V("Param"), .exact = true }});
    try forms.appendSlice(b.arena, &.{
        // lookup(#{bindings := Bindings}, Name) ->
        //     case [B || B = #{name := N} <- Bindings, N =:= Name] of [Hit | _] -> Hit; [] -> undefined end.
        try b.function("lookup", &.{ try b.map(&.{Ast.exactField("bindings", V("Bindings"))}), V("Name") }, &.{}, &.{
            try b.caseOf(.{ .list_comp = .{
                .element = try b.ptr(V("B")),
                .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                    .{ .generator = .{
                        .pattern = try b.match(V("B"), try b.map(&.{Ast.exactField("name", V("N"))})),
                        .list = V("Bindings"),
                    } },
                    .{ .filter = .{ .binop = .{ .op = "=:=", .lhs = try b.ptr(V("N")), .rhs = try b.ptr(V("Name")), .parens = false } } },
                }),
            } }, &.{
                try b.clause(&.{try b.cons(&.{V("Hit")}, V("_"))}, &.{}, &.{V("Hit")}),
                try b.clause(&.{try b.list(&.{})}, &.{}, &.{A("undefined")}),
            }),
        }),
        // ref(#{name := Name}) -> {'__bp_code', __bp_text(Name)}.
        // `Binding.ref()` splices the caller-scope binding back into the
        // expansion as a bare reference, so `return b.ref();` for a hit on
        // `greeting` expands to the identifier `greeting`, not to its value.
        try b.function("ref", &.{try b.map(&.{Ast.exactField("name", V("Name"))})}, &.{}, &.{
            try b.tuple(&.{ code_tag, try b.call("__bp_text", &.{V("Name")}) }),
        }),
        try b.function("build", &.{ V("_Capture"), V("Source") }, &.{}, &.{
            try b.tuple(&.{ code_tag, try b.call("__bp_text", &.{V("Source")}) }),
        }),
        try b.function("custom", &.{ V("_Capture"), V("Tree"), try b.tuple(&.{ code_tag, V("Source") }) }, &.{}, &.{
            try b.tuple(&.{ A("__bp_custom"), V("Tree"), V("Source") }),
        }),
        try b.function("fail", &.{ capture_param, V("Message") }, &.{}, &.{
            try throw(b, &.{ fail_tag, V("Message"), V("Param"), A("null") }),
        }),
        try b.function("failAt", &.{ capture_param, V("Span"), V("Message") }, &.{}, &.{
            try throw(b, &.{ fail_tag, V("Message"), V("Param"), V("Span") }),
        }),
        try b.function("compilerError", &.{V("Message")}, &.{}, &.{
            try throw(b, &.{ fail_tag, V("Message"), A("null"), A("null") }),
        }),
        try b.function("expr", &.{V("Value")}, &.{}, &.{try b.tuple(&.{ A("__bp_value"), V("Value") })}),
        try b.function("code", &.{V("Source")}, &.{}, &.{
            try b.tuple(&.{ code_tag, try b.call("__bp_text", &.{V("Source")}) }),
        }),
        try b.functionClauses("__bp_reply", &.{
            try b.clause(&.{try b.tuple(&.{ code_tag, V("Source") })}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("code")), Ast.field("source", V("Source")) }),
            }),
            try b.clause(&.{try b.tuple(&.{ A("__bp_value"), V("Value") })}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("value")), Ast.field("value", try b.call("__bp_json", &.{V("Value")})) }),
            }),
            try b.clause(&.{try b.tuple(&.{ A("__bp_custom"), V("Tree"), V("Source") })}, &.{}, &.{
                try b.map(&.{
                    Ast.field("kind", Ast.str("custom")),
                    Ast.field("source", V("Source")),
                    Ast.field("ast", try b.call("__bp_json", &.{V("Tree")})),
                }),
            }),
            try b.clause(&.{capture_param}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("capture")), Ast.field("param", V("Param")) }),
            }),
            try b.clause(&.{V("Other")}, &.{}, &.{
                try b.map(&.{
                    Ast.field("kind", Ast.str("error")),
                    Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ A("unsupported_template_result"), V("Other") })})),
                }),
            }),
        }),
    });

    const main_body = try b.body(&.{.{ .try_catch = .{
        .body = try b.body(&.{try b.remote("json", "encode", &.{try b.call("__bp_reply", &.{invoke})})}),
        .catches = try b.arena.dupe(Ast.Clause, &.{
            .{
                .patterns = try b.exprs(&.{try b.exception(A("throw"), try b.tuple(&.{ fail_tag, V("Message"), V("Param"), V("Span") }))}),
                .body = try b.body(&.{try json(b, &.{
                    Ast.field("kind", Ast.str("fail")),
                    Ast.field("message", try b.call("__bp_text", &.{V("Message")})),
                    Ast.field("param", V("Param")),
                    Ast.field("span", try b.call("__bp_json", &.{V("Span")})),
                })}),
            },
            .{
                .patterns = try b.exprs(&.{try b.exception(V("Class"), V("Reason"))}),
                .body = try b.body(&.{try json(b, &.{
                    Ast.field("kind", Ast.str("error")),
                    Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ V("Class"), V("Reason") })})),
                })}),
            },
        }),
    } }});
    try forms.append(b.arena, .{ .function = .{
        .name = "main",
        .clauses = try b.arena.dupe(Ast.Clause, &.{.{ .patterns = &.{}, .body = main_body }}),
    } });
    return forms.items;
}

fn buildModule(
    arena: std.mem.Allocator,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    unsupported: *erlang.UnsupportedMethod,
) (EvalError || error{UnsupportedMethod})!Module {
    const forms = try hostForms(.{ .arena = arena }, tfn, captures, plainArgs);

    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = tfn };
    var config: erlang.ComptimeModule = .{
        .host_enums = &.{ "BindingKind", "DeclKind" },
        .host_records = &host_records,
        .exports = &.{.{ .name = "main", .arity = 0 }},
        .forms = forms,
        .unsupported_method = unsupported,
    };
    const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch |err|
        return if (err == error.UnsupportedComptimeMethod) error.UnsupportedMethod else error.EvalFailed;
    // What snapshots show: the lowered body and `main/0` (the last host form).
    config.forms = forms[forms.len - 1 ..];
    config.listing = true;
    const listing = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch return error.EvalFailed;

    const module = try std.fmt.allocPrint(arena, "template_{x:0>16}", .{std.hash.Wyhash.hash(0, code)});
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });
    return .{ .module = module, .code = renamed, .listing = listing };
}

/// The argument for parameter `index`: its capture map, its literal plain
/// argument, or `undefined`.
fn paramExpr(
    arena: std.mem.Allocator,
    name: []const u8,
    index: usize,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Ast.Expr {
    for (captures) |*cap| {
        if (cap.paramIndex == index) return Ast.Expr.t(try captureToTerm(arena, cap));
    }
    for (plainArgs) |pa| {
        if (std.mem.eql(u8, pa.paramName, name)) return pa.toExpr();
    }
    return Ast.Expr.a("undefined");
}

// ── capture ───────────────────────────────────────────────────────────────────

/// A capture as the map its host functions read:
/// `#{'__bp_capture' => Param, text, parts, source, context, bindings}`.
/// Text is the literal's raw text (escapes unprocessed); in a template with
/// `${…}` holes each hole appears as its `__bp_hole_<param>_<i>` placeholder,
/// which `infer.zig` substitutes back when the built code is spliced.
pub fn captureToTerm(arena: std.mem.Allocator, cap: *const template.CapturedExpr) std.mem.Allocator.Error!Term {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    var parts: std.ArrayListUnmanaged(Term) = .empty;

    switch (cap.node.*) {
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |st| {
                var hole: usize = 0;
                for (st.parts) |part| switch (part) {
                    .text => |t| {
                        const start = text.items.len;
                        try text.appendSlice(arena, t);
                        try parts.append(arena, try partTerm(arena, "Text", "text", t, text.items, start));
                    },
                    .expr => {
                        const placeholder = try std.fmt.allocPrint(arena, "__bp_hole_{s}_{d}", .{ cap.paramName, hole });
                        hole += 1;
                        const start = text.items.len;
                        try text.appendSlice(arena, placeholder);
                        try parts.append(arena, try partTerm(arena, "Interp", "code", placeholder, text.items, start));
                    },
                };
            },
            else => {
                const t = cap.text orelse "";
                try text.appendSlice(arena, t);
                if (t.len > 0) try parts.append(arena, try partTerm(arena, "Text", "text", t, text.items, 0));
            },
        },
        else => {
            const t = cap.text orelse "";
            try text.appendSlice(arena, t);
            if (t.len > 0) try parts.append(arena, try partTerm(arena, "Text", "text", t, text.items, 0));
        },
    }

    const source_entries = try arena.alloc(Term.MapEntry, 3);
    source_entries[0] = Term.field("file", Term.str(cap.modulePath));
    source_entries[1] = Term.field("line", Term.int(@intCast(cap.loc.line)));
    source_entries[2] = Term.field("col", Term.int(@intCast(cap.loc.col)));
    const source = Term.mapOf(source_entries);

    const context_entries = try arena.alloc(Term.MapEntry, 3);
    context_entries[0] = Term.field("source", source);
    context_entries[1] = Term.field("text", Term.str(text.items));
    context_entries[2] = Term.field("multiline", .{ .boolean = cap.multiline });

    var bindings: std.ArrayListUnmanaged(Term) = .empty;
    if (cap.scope) |scope| {
        var it = scope.entries.iterator();
        while (it.next()) |e| {
            const be = try arena.alloc(Term.MapEntry, 2);
            be[0] = Term.field("name", Term.str(e.value_ptr.name));
            be[1] = Term.field("kind", Term.atomOf(e.value_ptr.kind.variantName()));
            try bindings.append(arena, Term.mapOf(be));
        }
    }

    const entries = try arena.alloc(Term.MapEntry, 6);
    entries[0] = .{ .key = Term.atomOf("__bp_capture"), .value = Term.str(cap.paramName) };
    entries[1] = Term.field("text", Term.str(text.items));
    entries[2] = Term.field("parts", Term.listOf(parts.items));
    entries[3] = Term.field("source", source);
    entries[4] = Term.field("context", Term.mapOf(context_entries));
    entries[5] = Term.field("bindings", Term.listOf(bindings.items));
    return Term.mapOf(entries);
}

/// `#{kind => Kind, <field> => Value, span => #{start, end, line}}` for the part
/// occupying `text[start..]`.
fn partTerm(arena: std.mem.Allocator, kind: []const u8, field: []const u8, value: []const u8, text: []const u8, start: usize) !Term {
    const line = 1 + std.mem.count(u8, text[0..start], "\n");
    const span = try arena.alloc(Term.MapEntry, 3);
    span[0] = Term.field("start", Term.int(@intCast(start)));
    span[1] = Term.field("end", Term.int(@intCast(text.len)));
    span[2] = Term.field("line", Term.int(@intCast(line)));
    const entries = try arena.alloc(Term.MapEntry, 3);
    entries[0] = Term.field("kind", Term.str(kind));
    entries[1] = Term.field(field, Term.str(value));
    entries[2] = Term.field("span", Term.mapOf(span));
    return Term.mapOf(entries);
}

// ── outcome ───────────────────────────────────────────────────────────────────

/// The JSON object `main/0` returns.
const Reply = struct {
    kind: []const u8,
    source: []const u8 = "",
    param: ?[]const u8 = null,
    message: []const u8 = "",
    span: ?template.Span = null,
    value: std.json.Value = .null,
    ast: std.json.Value = .null,
};

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) EvalError!Outcome {
    const reply = std.json.parseFromSliceLeaky(Reply, arena, stdout, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    }) catch return .{ .err = try errorText(arena, "the template evaluator returned an unreadable result", stdout) };

    const kind = reply.kind;
    if (std.mem.eql(u8, kind, "code")) return .{ .code = reply.source };
    if (std.mem.eql(u8, kind, "value")) return .{ .value = try typedValue(arena, reply.value) };
    if (std.mem.eql(u8, kind, "capture")) return .{ .capture = reply.param orelse "" };
    if (std.mem.eql(u8, kind, "custom")) {
        const tree = (try customTree(arena, reply.ast)) orelse
            return .{ .err = "`q.custom` received a tree that is not a CustomNode" };
        return .{ .custom = .{ .code = reply.source, .ast = tree } };
    }
    if (std.mem.eql(u8, kind, "fail")) return .{ .fail = .{
        .message = if (reply.message.len > 0) reply.message else "template rejected the input",
        .param = reply.param,
        .span = reply.span,
    } };
    return .{ .err = if (reply.message.len > 0) reply.message else "template evaluation failed" };
}

fn typedValue(arena: std.mem.Allocator, v: std.json.Value) std.mem.Allocator.Error!TypedValue {
    return switch (v) {
        .null => .null,
        .bool => |b| .{ .bool = b },
        .integer => |n| .{ .integer = n },
        .float => |f| .{ .float = f },
        .number_string, .string => |s| .{ .string = s },
        .array => |items| blk: {
            const out = try arena.alloc(TypedValue, items.items.len);
            for (items.items, 0..) |item, i| out[i] = try typedValue(arena, item);
            break :blk .{ .array = out };
        },
        .object => |obj| blk: {
            const out = try arena.alloc(TypedValue.KeyValuePair, obj.count());
            var it = obj.iterator();
            var i: usize = 0;
            while (it.next()) |e| : (i += 1) {
                out[i] = .{ .key = e.key_ptr.*, .value = try typedValue(arena, e.value_ptr.*) };
            }
            break :blk .{ .object = out };
        },
    };
}

fn customTree(arena: std.mem.Allocator, v: std.json.Value) std.mem.Allocator.Error!?CustomNodeTree {
    const obj = switch (v) {
        .object => |o| o,
        else => return null,
    };
    const kind = jsonString(obj.get("kind")) orelse return null;

    const span: ?template.Span = if (obj.get("span")) |sv| switch (sv) {
        .object => |so| .{
            .start = jsonUsize(so.get("start")) orelse 0,
            .end = jsonUsize(so.get("end")) orelse 0,
            .line = jsonUsize(so.get("line")) orelse 1,
        },
        else => null,
    } else null;

    const ref: ?template.NodeBinding = if (obj.get("ref")) |rv| switch (rv) {
        .object => |ro| if (jsonString(ro.get("name"))) |name| .{
            .name = name,
            .kind = jsonString(ro.get("kind")) orelse "",
        } else null,
        else => null,
    } else null;

    var children: []const CustomNodeTree = &.{};
    if (obj.get("children")) |cv| switch (cv) {
        .array => |items| {
            const out = try arena.alloc(CustomNodeTree, items.items.len);
            var n: usize = 0;
            for (items.items) |item| {
                if (try customTree(arena, item)) |child| {
                    out[n] = child;
                    n += 1;
                }
            }
            children = out[0..n];
        },
        else => {},
    };

    return .{ .kind = kind, .span = span, .label = jsonString(obj.get("label")), .ref = ref, .children = children };
}

fn jsonString(v: ?std.json.Value) ?[]const u8 {
    return switch (v orelse return null) {
        .string => |s| s,
        else => null,
    };
}

fn jsonUsize(v: ?std.json.Value) ?usize {
    return switch (v orelse return null) {
        .integer => |n| if (n >= 0) @intCast(n) else null,
        else => null,
    };
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "template outcome: every reply kind" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const code = try parseOutcome(arena, "{\"kind\":\"code\",\"source\":\"\\\"hey!\\\"\"}");
    try std.testing.expectEqualStrings("\"hey!\"", code.code);

    const value = try parseOutcome(arena, "{\"kind\":\"value\",\"value\":[6,\"x\",null,{\"a\":true}]}");
    try std.testing.expectEqual(@as(i64, 6), value.value.array[0].integer);
    try std.testing.expect(value.value.array[2] == .null);
    try std.testing.expect(value.value.array[3].object[0].value.bool);

    const capture = try parseOutcome(arena, "{\"kind\":\"capture\",\"param\":\"q\"}");
    try std.testing.expectEqualStrings("q", capture.capture);

    const custom = try parseOutcome(arena,
        \\{"kind":"custom","source":"41","ast":{"kind":"root","span":{"start":0,"end":6,"line":1},"label":"keyword","ref":null,
        \\ "children":[{"kind":"leaf","span":{"start":5,"end":9,"line":1},"label":"property","ref":{"name":"Item","kind":"Record_"},"children":[]}]}}
    );
    try std.testing.expectEqualStrings("41", custom.custom.code);
    try std.testing.expect(custom.custom.ast.ref == null);
    try std.testing.expectEqualStrings("Record_", custom.custom.ast.children[0].ref.?.kind);

    const fail = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"no\",\"param\":\"q\",\"span\":null}");
    try std.testing.expectEqualStrings("no", fail.fail.message);
    try std.testing.expectEqualStrings("q", fail.fail.param.?);

    try std.testing.expect((try parseOutcome(arena, "{\"kind\":\"error\",\"message\":\"x\"}")) == .err);
    try std.testing.expect((try parseOutcome(arena, "garbage")) == .err);
}
