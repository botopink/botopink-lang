//! Template markers of `#[@External.<Target>("…")]` annotations — decision 5
//! (specs/1.0.4-beta/08-review-backlog/semantics-decisions.md): a template
//! names the declaration's parameters **by position**, `$0`, `$1`, … over the
//! declared parameters, `self` included; `$self` is not a marker of the
//! language.
//!
//! The backends' renderers keep one internal receiver convention (`comptime/
//! primOpTemplate.zig`): the receiver is a separate internal marker
//! (`receiver_marker`, not writable in source) and `$N` counts the
//! call's arguments after it. This pass, run once over a parsed program,
//! translates the source form into that convention so every renderer — and
//! the code it emits — stays as it was:
//!
//! | Declaration                                   | Target          | `$0`        | `$N` (N ≥ 1) |
//! |-----------------------------------------------|-----------------|-------------|--------------|
//! | a method whose first parameter is `self`      | every target    | receiver    | `$(N-1)`     |
//! | a top-level `fn` whose first parameter is `self` | Erlang, Beam | receiver    | `$(N-1)`     |
//! | anything else                                  | —               | unchanged   | unchanged    |
//!
//! (commonJS already numbers a top-level `fn`'s parameters from `$0`.) A `$args`
//! on a method means every declared parameter, the receiver first.
//!
//! Refused with a location: `$self` anywhere, and `$N` with N ≥ the number of
//! declared parameters.

const std = @import("std");
const ast = @import("../ast.zig");
const token = @import("../lexer/token.zig");
const receiver_marker = @import("../comptime/primOpTemplate.zig").receiver_marker;

const Token = token.Token;

pub const Failure = struct {
    kind: enum { selfMarker, indexOutOfRange },
    /// The token that carries the offending annotation argument.
    tok: Token,
};

/// Rewrites the template markers of every annotated declaration in `program`
/// in place. On a refused marker returns the failure (the program is left as
/// is; the caller owns it).
pub fn normalizeProgram(alloc: std.mem.Allocator, tokens: []const Token, program: *ast.Program) !?Failure {
    for (program.decls) |*d| {
        switch (d.*) {
            .type_ => |*t| for (t.methods) |*m| {
                if (try normalizeDecl(alloc, tokens, m.annotations, m.params, .method)) |f| return f;
            },
            .behavior => |*b| for (b.methods) |*m| {
                if (try normalizeDecl(alloc, tokens, m.annotations, m.params, .method)) |f| return f;
            },
            .@"fn" => |*f| {
                if (try normalizeDecl(alloc, tokens, f.annotations, f.params, .top_level)) |fail| return fail;
            },
            else => {},
        }
    }
    return null;
}

const Site = enum { method, top_level };

const Target = enum { node, erlang, beam, other };

fn targetOf(name: []const u8) ?Target {
    const n = if (std.mem.startsWith(u8, name, "@")) name[1..] else name;
    if (!std.mem.startsWith(u8, n, "External.")) return null;
    const t = n["External.".len..];
    if (std.mem.eql(u8, t, "Node")) return .node;
    if (std.mem.eql(u8, t, "Erlang")) return .erlang;
    if (std.mem.eql(u8, t, "Beam")) return .beam;
    return .other;
}

fn normalizeDecl(
    alloc: std.mem.Allocator,
    tokens: []const Token,
    annotations: []ast.Annotation,
    params: []ast.Param,
    site: Site,
) !?Failure {
    const has_self = params.len > 0 and std.mem.eql(u8, params[0].name, "self");
    for (annotations) |*a| {
        const target = targetOf(a.name) orelse continue;
        const shift = has_self and (site == .method or target == .erlang or target == .beam);
        var new_args: ?[][]const u8 = null;
        errdefer if (new_args) |na| {
            for (na) |x| alloc.free(x);
            alloc.free(na);
        };
        for (a.args, 0..) |arg, i| {
            if (std.mem.indexOfScalar(u8, arg, '$') == null) continue;
            switch (try rewrite(alloc, arg, params.len, shift, has_self and site == .method)) {
                .unchanged => {},
                .rewritten => |text| {
                    if (new_args == null) {
                        const copy = try alloc.alloc([]const u8, a.args.len);
                        for (a.args, 0..) |orig, k| copy[k] = try alloc.dupe(u8, orig);
                        new_args = copy;
                    }
                    alloc.free(new_args.?[i]);
                    new_args.?[i] = text;
                },
                .self_marker => return .{ .kind = .selfMarker, .tok = tokenOf(tokens, arg) },
                .out_of_range => return .{ .kind = .indexOutOfRange, .tok = tokenOf(tokens, arg) },
            }
        }
        if (new_args) |args| {
            // The source spelling stays for the formatter and the AST dump.
            a.source_args = a.args;
            a.args = args;
            new_args = null;
        }
    }
    return null;
}

const Rewrite = union(enum) {
    unchanged,
    rewritten: []u8,
    self_marker,
    out_of_range,
};

/// `shift`: `$0` becomes the receiver marker and `$N` becomes `$(N-1)`.
/// `args_with_receiver`: `$args` on a method lists the receiver first.
fn rewrite(alloc: std.mem.Allocator, arg: []const u8, param_count: usize, shift: bool, args_with_receiver: bool) !Rewrite {
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
fn tokenOf(tokens: []const Token, arg: []const u8) Token {
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

test "$N past the declared parameters is refused" {
    try std.testing.expect(try rewrite(std.testing.allocator, "\"f($2)\"", 2, false, false) == .out_of_range);
}

test "a top-level fn keeps its numbering when not shifted" {
    try std.testing.expect(try rewrite(std.testing.allocator, "\"base64:encode($0)\"", 1, false, false) == .unchanged);
}
