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
const erlEmitter = @import("../codegen/beam/erl_emitter.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const persistent_erl = @import("./runtime/persistent_erl.zig");

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
) EvalError!Outcome {
    _ = build_root;
    const source = try buildModule(arena, tfn, captures, plainArgs);

    const dir = ".botopinkbuild/tmp/template";
    std.Io.Dir.cwd().createDirPath(io, dir) catch return error.EvalFailed;
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, source.module });
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = source.code }) catch return error.EvalFailed;

    const response = persistent_erl.evalDetailed(arena, io, path) catch return error.EvalFailed;
    return switch (response) {
        .ok => |stdout| parseOutcome(arena, stdout),
        .compile_error => |detail| .{ .err = try errorText(arena, "the template module did not compile", detail) },
        .load_error => |detail| .{ .err = try errorText(arena, "the template module did not load", detail) },
        .runtime_error => |detail| .{ .err = try errorText(arena, "the template body raised", detail) },
    };
}

fn errorText(arena: std.mem.Allocator, what: []const u8, detail: []const u8) ![]const u8 {
    const shown = detail[0..@min(detail.len, max_error_detail)];
    const ellipsis = if (detail.len > max_error_detail) " …" else "";
    return std.fmt.allocPrint(arena, "{s}: {s}{s}", .{ what, shown, ellipsis });
}

// ── module ────────────────────────────────────────────────────────────────────

const Module = struct {
    /// Erlang module atom derived from the code's hash.
    module: []const u8,
    code: []const u8,
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

/// Host functions for the capture API plus the reply encoder. A capture is a
/// map tagged with `'__bp_capture'` (its parameter name); `build`/`custom`/
/// `expr`/`code` wrap the body's result in a tagged tuple `main/0` dispatches on.
const host_fns =
    \\text(#{text := Text}) -> Text.
    \\parts(#{parts := Parts}) -> Parts.
    \\source(#{source := Source}) -> Source.
    \\context(#{context := Context}) -> Context.
    \\bindings(#{bindings := Bindings}) -> Bindings.
    \\lookup(#{bindings := Bindings}, Name) ->
    \\    case [B || B = #{name := N} <- Bindings, N =:= Name] of [Hit | _] -> Hit; [] -> undefined end.
    \\build(_Capture, Source) -> {'__bp_code', '__bp_text'(Source)}.
    \\custom(_Capture, Tree, {'__bp_code', Source}) -> {'__bp_custom', Tree, Source}.
    \\fail(#{'__bp_capture' := Param}, Message) -> erlang:throw({'__bp_template_fail', Message, Param, null}).
    \\failAt(#{'__bp_capture' := Param}, Span, Message) -> erlang:throw({'__bp_template_fail', Message, Param, Span}).
    \\compilerError(Message) -> erlang:throw({'__bp_template_fail', Message, null, null}).
    \\expr(Value) -> {'__bp_value', Value}.
    \\code(Source) -> {'__bp_code', '__bp_text'(Source)}.
    \\
    \\'__bp_text'(Value) when is_binary(Value) -> Value;
    \\'__bp_text'(Value) -> iolist_to_binary(io_lib:format("~p", [Value])).
    \\
    \\%% JSON view of a term: `undefined` is botopink's null.
    \\'__bp_json'(undefined) -> null;
    \\'__bp_json'(Map) when is_map(Map) -> maps:map(fun(_, V) -> '__bp_json'(V) end, Map);
    \\'__bp_json'(List) when is_list(List) -> [ '__bp_json'(V) || V <- List ];
    \\'__bp_json'(Value) -> Value.
    \\
    \\'__bp_reply'({'__bp_code', Source}) -> #{kind => <<"code">>, source => Source};
    \\'__bp_reply'({'__bp_value', Value}) -> #{kind => <<"value">>, value => '__bp_json'(Value)};
    \\'__bp_reply'({'__bp_custom', Tree, Source}) -> #{kind => <<"custom">>, source => Source, ast => '__bp_json'(Tree)};
    \\'__bp_reply'(#{'__bp_capture' := Param}) -> #{kind => <<"capture">>, param => Param};
    \\'__bp_reply'(Other) -> #{kind => <<"error">>, message => '__bp_text'({unsupported_template_result, Other})}.
    \\
    \\
;

fn buildModule(
    arena: std.mem.Allocator,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Module {
    var tail: std.Io.Writer.Allocating = .init(arena);
    const w = &tail.writer;
    try w.writeAll(host_fns);
    try w.writeAll(
        \\main() ->
        \\    try
        \\
    );
    try w.print("        json:encode('__bp_reply'({f}(", .{erlEmitter.atom(tfn.name)});
    for (tfn.params, 0..) |p, i| {
        if (i > 0) try w.writeAll(", ");
        try writeParam(arena, w, p.name, i, captures, plainArgs);
    }
    try w.writeAll(
        \\)))
        \\    catch
        \\        throw:{'__bp_template_fail', Message, Param, Span} ->
        \\            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        \\        Class:Reason ->
        \\            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
        \\    end.
        \\
    );

    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = tfn };
    const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, .{
        .host_enums = &.{ "BindingKind", "DeclKind" },
        .host_records = &host_records,
        .exports = &.{"main/0"},
        .tail = tail.written(),
    }) catch return error.EvalFailed;

    const module = try std.fmt.allocPrint(arena, "template_{x:0>16}", .{std.hash.Wyhash.hash(0, code)});
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });
    return .{ .module = module, .code = renamed };
}

/// The argument for parameter `index`: its capture map, its literal plain
/// argument, or `undefined`.
fn writeParam(
    arena: std.mem.Allocator,
    w: *std.Io.Writer,
    name: []const u8,
    index: usize,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!void {
    for (captures) |*cap| {
        if (cap.paramIndex != index) continue;
        return erlEmitter.writeTerm(w, try captureToTerm(arena, cap)) catch return error.EvalFailed;
    }
    for (plainArgs) |pa| {
        if (std.mem.eql(u8, pa.paramName, name)) return pa.writeErl(w);
    }
    try w.writeAll("undefined");
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
