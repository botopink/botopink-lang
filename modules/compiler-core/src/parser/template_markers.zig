//! Template markers of an `Implementation`'s template (`#[external(.Erlang("…"))]`,
//! `parser/implementations.zig`) — decision 5
//! (specs/1.0.4-beta/08-review-backlog/semantics-decisions.md): a template
//! names the declaration's parameters **by position**, `$0`, `$1`, … over the
//! declared parameters, `self` included; `$self` is not a marker of the
//! language.
//!
//! The backends' renderers keep one internal receiver convention (`comptime/
//! primOpTemplate.zig`): the receiver is a separate internal marker
//! (`receiver_marker`, not writable in source) and `$N` counts the
//! call's arguments after it. `rewrite`, run on each template as the parser
//! reads it (`implementations.read`), translates the source form into that
//! convention so every renderer — and the code it emits — stays as it was:
//!
//! | Declaration                                   | Target          | `$0`        | `$N` (N ≥ 1) |
//! |-----------------------------------------------|-----------------|-------------|--------------|
//! | a method whose first parameter is `self`      | every target    | receiver    | `$(N-1)`     |
//! | anything else                                  | —               | unchanged   | unchanged    |
//!
//! A top-level `fn` has no receiver: the parser refuses a free function's
//! `self` parameter (`self-param-outside-type`), so its `$N` is its N-th
//! parameter on every target. A `$args` on a method means every declared
//! parameter, the receiver first.
//!
//! Refused with a location: `$self` anywhere, `$stringify(…)` anywhere
//! (decisions 164, 239 — a template writes the host's own string conversion),
//! and `$N` with N ≥ the number of declared parameters.

const std = @import("std");
const ast = @import("../ast.zig");
const token = @import("../lexer/token.zig");
const receiver_marker = @import("../comptime/primOpTemplate.zig").receiver_marker;

const Token = token.Token;

pub const Failure = struct {
    kind: enum { selfMarker, stringifyMarker, indexOutOfRange },
    /// The token that carries the offending annotation argument.
    tok: Token,
};

pub const Rewrite = union(enum) {
    unchanged,
    rewritten: []u8,
    self_marker,
    stringify_marker,
    out_of_range,
};

/// `shift`: `$0` becomes the receiver marker and `$N` becomes `$(N-1)`.
/// `args_with_receiver`: `$args` on a method lists the receiver first.
pub fn rewrite(alloc: std.mem.Allocator, arg: []const u8, param_count: usize, shift: bool, args_with_receiver: bool) !Rewrite {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(alloc);
    var changed = false;
    var i: usize = 0;
    while (i < arg.len) {
        const c = arg[i];
        if (c != '$') {
            try out.append(alloc, c);
            i += 1;
            continue;
        }
        const rest = arg[i..];
        if (std.mem.startsWith(u8, rest, "$self")) {
            out.deinit(alloc);
            return .self_marker;
        }
        if (std.mem.startsWith(u8, rest, "$stringify")) {
            out.deinit(alloc);
            return .stringify_marker;
        }
        if (std.mem.startsWith(u8, rest, "$args")) {
            if (args_with_receiver) {
                try out.appendSlice(alloc, receiver_marker);
                if (param_count > 1) try out.appendSlice(alloc, ", $args");
                changed = true;
            } else {
                try out.appendSlice(alloc, "$args");
            }
            i += "$args".len;
            continue;
        }
        if (i + 1 < arg.len and std.ascii.isDigit(arg[i + 1])) {
            var j = i + 1;
            var n: usize = 0;
            while (j < arg.len and std.ascii.isDigit(arg[j])) : (j += 1) n = n * 10 + (arg[j] - '0');
            if (n >= param_count) {
                out.deinit(alloc);
                return .out_of_range;
            }
            if (shift) {
                if (n == 0) {
                    try out.appendSlice(alloc, receiver_marker);
                } else {
                    try out.print(alloc, "${d}", .{n - 1});
                }
                changed = true;
            } else {
                try out.appendSlice(alloc, arg[i..j]);
            }
            i = j;
            continue;
        }
        try out.append(alloc, c);
        i += 1;
    }
    if (!changed) {
        out.deinit(alloc);
        return .unchanged;
    }
    return .{ .rewritten = try out.toOwnedSlice(alloc) };
}

/// The token whose lexeme starts the annotation argument `arg` (arguments are
/// slices of token lexemes); the first token when none matches.
pub fn tokenOf(tokens: []const Token, arg: []const u8) Token {
    for (tokens) |t| {
        if (t.lexeme.len > 0 and t.lexeme.ptr == arg.ptr) return t;
    }
    for (tokens) |t| {
        if (t.lexeme.len > 0 and @intFromPtr(t.lexeme.ptr) <= @intFromPtr(arg.ptr) and
            @intFromPtr(arg.ptr) < @intFromPtr(t.lexeme.ptr) + t.lexeme.len) return t;
    }
    return tokens[0];
}

test "a method's $0 is the receiver and $N shifts" {
    const r = try rewrite(std.testing.allocator, "\"lists:member($1, $0)\"", 2, true, true);
    defer if (r == .rewritten) std.testing.allocator.free(r.rewritten);
    try std.testing.expectEqualStrings("\"lists:member($0, " ++ receiver_marker ++ ")\"", r.rewritten);
}

test "$self is refused" {
    try std.testing.expect(try rewrite(std.testing.allocator, "\"f($self)\"", 1, true, true) == .self_marker);
}

test "$stringify is refused (decision 239)" {
    try std.testing.expect(try rewrite(std.testing.allocator, "\"io_lib:format($stringify($0))\"", 1, false, false) == .stringify_marker);
    try std.testing.expect(try rewrite(std.testing.allocator, "\"f($stringify($1))\"", 2, true, true) == .stringify_marker);
}

test "$N past the declared parameters is refused" {
    try std.testing.expect(try rewrite(std.testing.allocator, "\"f($2)\"", 2, false, false) == .out_of_range);
}

test "a top-level fn keeps its numbering when not shifted" {
    try std.testing.expect(try rewrite(std.testing.allocator, "\"base64:encode($0)\"", 1, false, false) == .unchanged);
}
