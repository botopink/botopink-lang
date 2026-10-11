//! An `@External.Erlang` template as Erlang source and as BEAM instructions:
//! the one reading of a template, shared by the beam target (BR5: each
//! template compiled at build time into a helper of the module,
//! `../beam_asm.zig` `evalTemplate`; the comptime runtime reads no host
//! function's Erlang cell since decision 452). It reads with
//! `comptime/runtime/wat/erl_parse.zig` and lowers with `erl_lower.zig`, so
//! there is one Erlang front end.
const std = @import("std");
const primOpTemplate = @import("../../comptime/primOpTemplate.zig");
const erlParse = @import("../../comptime/runtime/wat/erl_parse.zig");
const erlLower = @import("erl_lower.zig");

/// The Erlang body of template `template_raw` called with `argc` arguments
/// besides its receiver: the receiver marker → `__BpSelf`, `$N` → `__BpAN`,
/// a `\"` kept from a `"…"` annotation unescaped, and a trailing `.`. Owned
/// by `alloc`.
pub fn templateBody(alloc: std.mem.Allocator, template_raw: []const u8, argc: usize) anyerror![]u8 {
    var src: std.ArrayListUnmanaged(u8) = .empty;
    errdefer src.deinit(alloc);
    var template: std.ArrayListUnmanaged(u8) = .empty;
    defer template.deinit(alloc);
    var ti: usize = 0;
    while (ti < template_raw.len) : (ti += 1) {
        if (template_raw[ti] == '\\' and ti + 1 < template_raw.len and template_raw[ti + 1] == '"') continue;
        try template.append(alloc, template_raw[ti]);
    }
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
    try primOpTemplate.render(template.items, &ctx);
    try src.append(alloc, '.');
    return src.toOwnedSlice(alloc);
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
