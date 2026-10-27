//! An `@External.Erlang` template as Erlang source and as BEAM instructions:
//! the one reading of a template, shared by the beam target (BR5: each
//! template compiled at build time into a helper of the module,
//! `../beam_asm.zig` `evalTemplate`; the comptime runtime reads no host
//! function's Erlang cell since decision 452). It reads with
//! `codegen/beam/erl_parse.zig` and lowers with `erl_lower.zig`, so
//! there is one Erlang front end.
const std = @import("std");
const primOpTemplate = @import("../../comptime/primOpTemplate.zig");
const erlParse = @import("erl_parse.zig");
const erlLower = @import("erl_lower.zig");

/// The Erlang body of template `template_raw` called with `argc` arguments
/// besides its receiver: the receiver marker → `__BpSelf`, `$N` → `__BpAN`,
/// a `\"` kept from a `"…"` annotation unescaped, and a trailing `.`. Owned
/// by `alloc`. The unescape happens here once, for a raw lexeme; a template
/// the caller already unescaped goes to `renderBody`, so an Erlang-escaped
/// quote (`\\"` in the lexeme, `\"` in the Erlang text) loses no second backslash.
pub fn templateBody(alloc: std.mem.Allocator, template_raw: []const u8, argc: usize) anyerror![]u8 {
    var template: std.ArrayListUnmanaged(u8) = .empty;
    defer template.deinit(alloc);
    var ti: usize = 0;
    while (ti < template_raw.len) : (ti += 1) {
        if (template_raw[ti] == '\\' and ti + 1 < template_raw.len and template_raw[ti + 1] == '"') continue;
        try template.append(alloc, template_raw[ti]);
    }
    return renderBody(alloc, template.items, argc);
}

/// `templateBody` over a template whose `\"` the caller already resolved.
fn renderBody(alloc: std.mem.Allocator, template: []const u8, argc: usize) anyerror![]u8 {
    var src: std.ArrayListUnmanaged(u8) = .empty;
    errdefer src.deinit(alloc);
    const Ctx = struct {
        alloc: std.mem.Allocator,
        out: *std.ArrayListUnmanaged(u8),
        argc: usize,
        pub fn writeByte(c: *@This(), ch: u8) anyerror!void {
            try c.out.append(c.alloc, ch);
        }
        pub fn writeAll(c: *@This(), s: []const u8) anyerror!void {
            try c.out.appendSlice(c.alloc, s);
        }
        pub fn emitRecv(c: *@This()) anyerror!void {
            try c.out.appendSlice(c.alloc, "__BpSelf");
        }
        pub fn emitArg(c: *@This(), idx: usize) anyerror!void {
            var name_buf: [16]u8 = undefined;
            try c.out.appendSlice(c.alloc, try std.fmt.bufPrint(&name_buf, "__BpA{d}", .{idx}));
        }
    };
    var ctx = Ctx{ .alloc = alloc, .out = &src, .argc = argc };
    try primOpTemplate.render(template, &ctx);
    try src.append(alloc, '.');
    return src.toOwnedSlice(alloc);
}

/// The atoms a `result: true` binding builds std's `failure.HostError` with
/// (decisions 431, 489): the record's tag and the three `HostErrorName`
/// variants, as `crossModule.typeAtom` / `variantAtom` render them for the
/// build.
pub const HostErrorAtoms = struct {
    record: []const u8,
    err: []const u8,
    throw: []const u8,
    exit: []const u8,
};

/// A `result: true` binding's template (decisions 431, 489, 490): `template`
/// inside a `try … of … catch … end` that answers `@Result<T, HostError>`. An
/// `{ok, V}` or a plain value is `Ok(V)`; a host that answers `{error, R}`, and
/// every raise — `error`, `throw`, `exit` — is `Error(HostError(message,
/// "host", name, detail))`: `message` the reason by `~tp`, `name` the class
/// (`{error, R}` is `Error`), `detail` the stack by `~tp`. The holes (`$N`) are
/// left as they are; the caller renders them. Erlang text the reader
/// (`erl_parse.zig`) and erlc both take. Owned by `alloc`.
pub fn resultWrap(alloc: std.mem.Allocator, template: []const u8, atoms: HostErrorAtoms) std.mem.Allocator.Error![]u8 {
    const tail = try resultWrapTail(alloc, atoms);
    defer alloc.free(tail);
    return std.mem.concat(alloc, u8, &.{ result_wrap_head, template, tail });
}

/// What `resultWrap` writes before the template.
pub const result_wrap_head = "try (";

/// What `resultWrap` writes after the template — for a backend that wraps a
/// rendered node rather than template text (erlang's host methods). Owned by
/// `alloc`.
pub fn resultWrapTail(alloc: std.mem.Allocator, atoms: HostErrorAtoms) std.mem.Allocator.Error![]u8 {
    return std.fmt.allocPrint(alloc, ") of " ++
        "{{ok, __BpV}} -> {{ok, __BpV}}; " ++
        "{{error, __BpR}} -> {{error, {{'{s}', unicode:characters_to_binary(io_lib:format(\"~tp\", [__BpR])), <<\"host\">>, '{s}', undefined}}}}; " ++
        "__BpV -> {{ok, __BpV}} " ++
        "catch __BpC:__BpE:__BpS -> {{error, {{'{s}', unicode:characters_to_binary(io_lib:format(\"~tp\", [__BpE])), <<\"host\">>, " ++
        "case __BpC of error -> '{s}'; throw -> '{s}'; exit -> '{s}' end, " ++
        "unicode:characters_to_binary(io_lib:format(\"~tp\", [__BpS]))}}}} end", .{
        atoms.record, atoms.err, atoms.record, atoms.err, atoms.throw, atoms.exit,
    });
}

/// `resultWrap` with the arguments bound before the `try`, for a backend that
/// renders a template inline at the call site (erlang): `(fun(__BpA0, …) ->
/// <wrapped> end)($0, …)`. A raise while an argument is evaluated is then the
/// caller's, not the host's, as it is on beam (whose helper takes its
/// arguments evaluated) and on commonJS; and the `try`'s variables live in the
/// fun, so two calls in one clause do not share them. `argc` is the call's
/// argument count. Owned by `alloc`.
pub fn resultWrapBound(alloc: std.mem.Allocator, template: []const u8, argc: usize, atoms: HostErrorAtoms) anyerror![]u8 {
    const wrapped = try resultWrap(alloc, template, atoms);
    defer alloc.free(wrapped);
    return boundOver(alloc, wrapped, argc);
}

/// `wrapped`, a template already inside its `try`, as the fun applied to the
/// call's arguments that `resultWrapBound` and `hostMarkBound` write.
fn boundOver(alloc: std.mem.Allocator, wrapped: []const u8, argc: usize) anyerror![]u8 {
    const body = try renderBody(alloc, wrapped, argc);
    defer alloc.free(body);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, "(fun(");
    for (0..argc) |i| {
        if (i > 0) try out.appendSlice(alloc, ", ");
        try out.print(alloc, "__BpA{d}", .{i});
    }
    try out.appendSlice(alloc, ") -> ");
    try out.appendSlice(alloc, body[0 .. body.len - 1]);
    try out.appendSlice(alloc, " end)(");
    for (0..argc) |i| {
        if (i > 0) try out.appendSlice(alloc, ", ");
        try out.print(alloc, "${d}", .{i});
    }
    try out.append(alloc, ')');
    return out.toOwnedSlice(alloc);
}

/// What `hostMark` writes before the template (the same `try (` as `resultWrap`).
pub const host_mark_head = result_wrap_head;

/// Decision 546 (527 (1)) — what `hostMark` writes after the template: a raise
/// of the binding that is not already a botopink abort is re-raised marked
/// `{bp_host, Text}`, `Text` the reason by `~tp` without the stack (527 (4),
/// 489's rule) whatever the class (`error`, `throw`, `exit`). The program's own
/// aborts that cross the binding — a `{panic, _}`, `{todo, _}`,
/// `{integer_overflow, _}` or `{bp_assert, …}` of a callback it runs, an
/// already marked host raise — and the control-flow throws the emitter writes
/// (`'__bp_break'`, `{'__bp_cond_break' | '__bp_cond_continue' | '__bp_try' |
/// '__bp_gen_stop', _}`, `{'__bp_gen_end', _, _, _}`) pass through unchanged.
pub const host_mark_tail =
    ") catch " ++
    "error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); " ++
    "error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); " ++
    "error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); " ++
    "throw:'__bp_break' -> erlang:throw('__bp_break'); " ++
    "throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); " ++
    "throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); " ++
    "__BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format(\"~tp\", [__BpE]))}) end";

/// A binding without `result: true` outside std (decision 546): `template` in
/// `try … catch … end` marking its raise `host`. The holes (`$N`) are left as
/// they are; the caller renders them. Owned by `alloc`.
pub fn hostMark(alloc: std.mem.Allocator, template: []const u8) std.mem.Allocator.Error![]u8 {
    return std.mem.concat(alloc, u8, &.{ host_mark_head, template, host_mark_tail });
}

/// `hostMark` with the arguments bound before the `try`, as `resultWrapBound`
/// does: a raise while an argument is evaluated is the caller's. Owned by `alloc`.
pub fn hostMarkBound(alloc: std.mem.Allocator, template: []const u8, argc: usize) anyerror![]u8 {
    const wrapped = try hostMark(alloc, template);
    defer alloc.free(wrapped);
    return boundOver(alloc, wrapped, argc);
}

/// A `(module, symbol)` binding as the template it calls —
/// `'module':'symbol'($0, …)` over `argc` arguments — so a `result: true`
/// binding of that form is wrapped like a template. Owned by `alloc`.
pub fn remoteCallTemplate(alloc: std.mem.Allocator, module: []const u8, symbol: []const u8, argc: usize) std.mem.Allocator.Error![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try out.print(alloc, "'{s}':'{s}'(", .{ module, symbol });
    for (0..argc) |i| {
        if (i > 0) try out.appendSlice(alloc, ", ");
        try out.print(alloc, "${d}", .{i});
    }
    try out.append(alloc, ')');
    return out.toOwnedSlice(alloc);
}

/// A `(module, symbol)` binding without `result: true` as the template it
/// calls (decision 546), so `hostMark` can wrap it: `module:symbol($0, …)` over
/// `argc` arguments, the receiver first (`primOpTemplate.receiver_marker`) for a
/// method whose host function takes it. An atom that needs no quotes is written
/// without, as the direct call was: the build's sidecar scan reads the `module:`
/// qualifiers of the emitted text and sees only the unquoted ones. Owned by `alloc`.
pub fn hostCallTemplate(alloc: std.mem.Allocator, module: []const u8, symbol: []const u8, argc: usize, has_recv: bool) std.mem.Allocator.Error![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try appendAtom(alloc, &out, module);
    try out.append(alloc, ':');
    try appendAtom(alloc, &out, symbol);
    try out.append(alloc, '(');
    if (has_recv) try out.appendSlice(alloc, primOpTemplate.receiver_marker);
    for (0..argc) |i| {
        if (i > 0 or has_recv) try out.appendSlice(alloc, ", ");
        try out.print(alloc, "${d}", .{i});
    }
    try out.append(alloc, ')');
    return out.toOwnedSlice(alloc);
}

/// `atom` as Erlang source: bare when it is `[a-z][a-zA-Z0-9_@]*`, else quoted.
fn appendAtom(alloc: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), atom: []const u8) std.mem.Allocator.Error!void {
    const plain = atom.len > 0 and std.ascii.isLower(atom[0]) and for (atom) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_' and c != '@') break false;
    } else true;
    if (plain) return out.appendSlice(alloc, atom);
    try out.append(alloc, '\'');
    try out.appendSlice(alloc, atom);
    try out.append(alloc, '\'');
}

/// The one-function module a template helper is read from:
/// `t(__BpSelf, __BpA0, …) -> <body>` over `arity` parameters, the first the
/// receiver when `has_recv`.
pub fn templateModuleText(ar: std.mem.Allocator, body: []const u8, has_recv: bool, arity: usize) std.mem.Allocator.Error![]u8 {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(ar, try std.fmt.allocPrint(ar, "-module(bp_tpl).\n-export([t/{d}]).\nt(", .{arity}));
    const off: usize = @intFromBool(has_recv);
    for (0..arity) |i| {
        if (i > 0) try text.appendSlice(ar, ", ");
        const param = if (has_recv and i == 0) "__BpSelf" else try std.fmt.allocPrint(ar, "__BpA{d}", .{i - off});
        try text.appendSlice(ar, param);
    }
    try text.appendSlice(ar, ") ->\n    ");
    try text.appendSlice(ar, body);
    try text.append(ar, '\n');
    return text.items;
}

/// What `lowerTemplateText` made of a template helper's module.
pub const TemplateLowering = union(enum) {
    ok: erlLower.Output,
    /// The construct the reader or the lowering refused, by name.
    refused: []const u8,
};

/// Read and lower the one-function module a template helper is
/// (`t(__BpSelf, __BpA0, …) -> <template>.`) — the comptime runtime's reader
/// and `erl_lower.zig` (BR5).
pub fn lowerTemplateText(ar: std.mem.Allocator, text: []const u8, module_name: []const u8) std.mem.Allocator.Error!TemplateLowering {
    var pf: erlParse.Failure = .{};
    const parsed = erlParse.parseModule(ar, text, &pf) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Unsupported => return .{ .refused = pf.message },
        error.Syntax => return .{ .refused = try std.fmt.allocPrint(ar, "it does not read as Erlang: {s}", .{pf.message}) },
    };
    var lf: erlLower.Failure = .{};
    const lowered = erlLower.lowerModule(ar, parsed, module_name, &lf) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Unsupported => return .{ .refused = lf.message },
    };
    return .{ .ok = lowered };
}
