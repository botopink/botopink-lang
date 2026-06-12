//! Shared renderer for `#[@External.<target>( "<template>")]` primitive-op
//! templates (`prim-op-annotation` v0.beta.19).
//!
//! A template body is a string of target-language bytes with substitution
//! markers the codegen backends interpret:
//!
//! | Marker              | Meaning                                       |
//! |---------------------|-----------------------------------------------|
//! | `$self`             | The receiver expression                       |
//! | `$0`..`$N`          | The N-th positional call argument             |
//! | `$args`             | All positional args, comma-separated          |
//! | `$stringify(<inner>)` | Target's string-of-value wrap around `<inner>` |
//! | other               | Passthrough — target syntax (erlang, JS, …)   |
//!
//! `$stringify(<inner>)` produces a target-language expression whose runtime
//! value is the textual rendering of `<inner>` (Node: `JSON.stringify(...)`,
//! Erlang: `iolist_to_binary(io_lib:format("~p", [...]))`, BEAM/WAT: RP3
//! unsupported). `<inner>` is rendered recursively, so it may contain `$self`
//! / `$N` markers or arbitrary target-language tokens (e.g. a lambda's bound
//! variable name like `__E`) — the wrap is purely the open/close bracket pair
//! the backend supplies via `emitStringifyOpen` / `emitStringifyClose`.
//! Arity branching (`when(argc == N): "..."`) and triple-quoted (`"""…"""`)
//! bodies are also live (see `ast.parseArityBranchArg` and
//! `ast.unquoteAnnotationArg`).
//!
//! The renderer is purely structural: it walks the template bytes, emits
//! literal bytes verbatim, and on each marker calls the matching method on
//! the caller-supplied `ctx`. Backends provide a context struct with
//! `writeByte`, `writeAll`, `emitRecv`, `emitArg`, `emitStringifyOpen`,
//! and `emitStringifyClose` — those callbacks invoke the backend's own
//! expression emitter for the receiver / arg, surrounded by the target's
//! string-of-value bracket pair when stringified.

const std = @import("std");

/// True when `template` looks like a `$`-marker template (the new form),
/// false when it's a legacy `module:symbol(args)` fragment. Discriminator:
/// any `$` byte. Legacy annotations never contain `$` (host symbols are
/// plain identifiers); template bodies always do (every method needs at
/// least `$self`).
pub fn looksLikeTemplate(template: []const u8) bool {
    return std.mem.indexOfScalar(u8, template, '$') != null;
}

/// Render a template body into `ctx`. Walks `template`, emits literal bytes
/// verbatim, and dispatches markers to `ctx.emitRecv()` / `ctx.emitArg(i)`
/// (or the stringified variants when wrapped in `$stringify(...)`).
///
/// `ctx` must expose:
///   - `writeByte(c: u8) anyerror!void`
///   - `emitRecv() anyerror!void`
///   - `emitArg(i: usize) anyerror!void`
///   - `emitStringifyOpen() anyerror!void` (optional — backends that
///      don't support `$stringify(...)` can return
///      `error.PrimOpStringifyUnsupported`)
///   - `emitStringifyClose() anyerror!void` (same)
///   - `argc: usize` (the call-site argument count, for `$N` bounds checks)
///
/// Diagnostics:
///   - Out-of-range `$N` is rejected with `error.PrimOpArgIndexOutOfRange`
///     (RP1, reserved in the spec).
///   - `$stringify(...)` on a backend whose ctx returns
///     `error.PrimOpStringifyUnsupported` surfaces RP3.
///   - A malformed `$stringify(...)` (unbalanced `(`/`)`) returns
///     `error.PrimOpStringifyMalformed`.
pub fn render(template: []const u8, ctx: anytype) anyerror!void {
    var i: usize = 0;
    while (i < template.len) {
        const c = template[i];
        if (c != '$') {
            try ctx.writeByte(c);
            i += 1;
            continue;
        }
        // `$stringify(<inner>)` — target-specific string-of-value wrap.
        // Inner content is rendered recursively, so markers like `$self`
        // and `$N` substitute as usual; bare target-language bytes
        // (a lambda's bound var like `__E`) pass through.
        if (std.mem.startsWith(u8, template[i..], "$stringify(")) {
            const open = i + "$stringify(".len;
            // Scan for matching close paren with simple balance counting.
            var depth: usize = 1;
            var j = open;
            while (j < template.len) : (j += 1) {
                if (template[j] == '(') depth += 1 else if (template[j] == ')') {
                    depth -= 1;
                    if (depth == 0) break;
                }
            }
            if (depth != 0) return error.PrimOpStringifyMalformed;
            // `$stringify` is optional per the ctx contract — backends whose
            // Ctx struct doesn't expose the open/close pair surface
            // `error.PrimOpStringifyUnsupported` (RP3). This avoids requiring
            // every Ctx in every backend to carry the pair when only specific
            // templates (e.g., Array.join's lambda-bound-var wrap) use it.
            if (!@hasDecl(@TypeOf(ctx.*), "emitStringifyOpen")) return error.PrimOpStringifyUnsupported;
            try ctx.emitStringifyOpen();
            try render(template[open..j], ctx);
            try ctx.emitStringifyClose();
            i = j + 1;
            continue;
        }
        // `$self`
        if (std.mem.startsWith(u8, template[i..], "$self")) {
            try ctx.emitRecv();
            i += "$self".len;
            continue;
        }
        // `$args` — every positional arg, comma-separated. Used for variadic
        // host calls like `console.log($args)`.
        if (std.mem.startsWith(u8, template[i..], "$args")) {
            var idx: usize = 0;
            while (idx < ctx.argc) : (idx += 1) {
                if (idx > 0) try ctx.writeAll(", ");
                try ctx.emitArg(idx);
            }
            i += "$args".len;
            continue;
        }
        // `$<digits>` — positional argument
        if (i + 1 < template.len and std.ascii.isDigit(template[i + 1])) {
            var j = i + 1;
            var n: usize = 0;
            while (j < template.len and std.ascii.isDigit(template[j])) : (j += 1) {
                n = n * 10 + (template[j] - '0');
            }
            if (n >= ctx.argc) return error.PrimOpArgIndexOutOfRange;
            try ctx.emitArg(n);
            i = j;
            continue;
        }
        // Bare `$` — not a marker; emit literally.
        try ctx.writeByte('$');
        i += 1;
    }
}

// ── tests ────────────────────────────────────────────────────────────────────

const StringCtx = struct {
    buf: *std.ArrayList(u8),
    alloc: std.mem.Allocator,
    argc: usize,

    pub fn writeByte(self: *StringCtx, c: u8) anyerror!void {
        try self.buf.append(self.alloc, c);
    }
    pub fn writeAll(self: *StringCtx, s: []const u8) anyerror!void {
        try self.buf.appendSlice(self.alloc, s);
    }
    pub fn emitRecv(self: *StringCtx) anyerror!void {
        try self.buf.appendSlice(self.alloc, "<RECV>");
    }
    pub fn emitArg(self: *StringCtx, i: usize) anyerror!void {
        var tmp: [16]u8 = undefined;
        const s = try std.fmt.bufPrint(&tmp, "<A{d}>", .{i});
        try self.buf.appendSlice(self.alloc, s);
    }
    pub fn emitStringifyOpen(self: *StringCtx) anyerror!void {
        try self.buf.appendSlice(self.alloc, "<STR(");
    }
    pub fn emitStringifyClose(self: *StringCtx) anyerror!void {
        try self.buf.appendSlice(self.alloc, ")>");
    }
};

fn renderToOwned(alloc: std.mem.Allocator, template: []const u8, argc: usize) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(alloc);
    var ctx = StringCtx{ .buf = &buf, .alloc = alloc, .argc = argc };
    try render(template, &ctx);
    return buf.toOwnedSlice(alloc);
}

test "render: $self → recv" {
    const out = try renderToOwned(std.testing.allocator, "length($self)", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("length(<RECV>)", out);
}

test "render: $0 → first arg" {
    const out = try renderToOwned(std.testing.allocator, "lists:member($0, $self)", 1);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("lists:member(<A0>, <RECV>)", out);
}

test "render: $0 and $1" {
    const out = try renderToOwned(std.testing.allocator, "f($0, $1, $self)", 2);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("f(<A0>, <A1>, <RECV>)", out);
}

test "render: list cons / operator passthrough" {
    const out = try renderToOwned(std.testing.allocator, "[$0 | $self]", 1);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("[<A0> | <RECV>]", out);
}

test "render: empty-list eq operator" {
    const out = try renderToOwned(std.testing.allocator, "($self =:= [])", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("(<RECV> =:= [])", out);
}

test "render: unary not" {
    const out = try renderToOwned(std.testing.allocator, "(not $self)", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("(not <RECV>)", out);
}

test "render: $ followed by non-digit is literal" {
    const out = try renderToOwned(std.testing.allocator, "$x", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("$x", out);
}

test "render: $N out of range reds" {
    const r = renderToOwned(std.testing.allocator, "f($5)", 1);
    try std.testing.expectError(error.PrimOpArgIndexOutOfRange, r);
}

test "render: $stringify($self)" {
    const out = try renderToOwned(std.testing.allocator, "log($stringify($self))", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("log(<STR(<RECV>)>)", out);
}

test "render: $stringify($0) on first arg" {
    const out = try renderToOwned(std.testing.allocator, "label = $stringify($0)", 1);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("label = <STR(<A0>)>", out);
}

test "render: $stringify of arbitrary inner expression" {
    // Inner is a free variable name — passes through as literal bytes.
    const out = try renderToOwned(std.testing.allocator, "$stringify(__E)", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("<STR(__E)>", out);
}

test "render: $stringify with nested parens" {
    const out = try renderToOwned(std.testing.allocator, "$stringify(f($self))", 0);
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("<STR(f(<RECV>))>", out);
}

test "render: $stringify with out-of-range index reds RP1" {
    const r = renderToOwned(std.testing.allocator, "$stringify($5)", 1);
    try std.testing.expectError(error.PrimOpArgIndexOutOfRange, r);
}

test "render: $stringify missing closing paren reds RP3" {
    const r = renderToOwned(std.testing.allocator, "$stringify($self", 0);
    try std.testing.expectError(error.PrimOpStringifyMalformed, r);
}

test "looksLikeTemplate" {
    try std.testing.expect(looksLikeTemplate("($self ++ [$0])"));
    try std.testing.expect(looksLikeTemplate("$self.length"));
    try std.testing.expect(!looksLikeTemplate("module"));
    try std.testing.expect(!looksLikeTemplate("symbol(arg, self)"));
}

// ── BEAM-target ctx convention (v0.beta.22 front 03) ─────────────────────────
// The BEAM consumer in `codegen/beam_asm.zig` pre-loads `recv` into `{x, 0}`
// and each positional arg into `{x, i+1}` before rendering. `$self` and `$N`
// then substitute to those literal register references; the template body
// emits multi-line `.S` syntax around them.

const BeamCtx = struct {
    buf: *std.ArrayList(u8),
    alloc: std.mem.Allocator,
    argc: usize,
    pub fn writeByte(self: *BeamCtx, c: u8) anyerror!void {
        try self.buf.append(self.alloc, c);
    }
    pub fn writeAll(self: *BeamCtx, s: []const u8) anyerror!void {
        try self.buf.appendSlice(self.alloc, s);
    }
    pub fn emitRecv(self: *BeamCtx) anyerror!void {
        try self.buf.appendSlice(self.alloc, "{x, 0}");
    }
    pub fn emitArg(self: *BeamCtx, i: usize) anyerror!void {
        var tmp: [16]u8 = undefined;
        const s = try std.fmt.bufPrint(&tmp, "{{x, {d}}}", .{i + 1});
        try self.buf.appendSlice(self.alloc, s);
    }
};

fn renderBeamToOwned(alloc: std.mem.Allocator, template: []const u8, argc: usize) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(alloc);
    var ctx = BeamCtx{ .buf = &buf, .alloc = alloc, .argc = argc };
    try render(template, &ctx);
    return buf.toOwnedSlice(alloc);
}

test "BEAM ctx: $self → {x, 0}" {
    const out = try renderBeamToOwned(
        std.testing.allocator,
        "    {call_ext, 1, {extfunc, erlang, length, 1}}.\n",
        0,
    );
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(
        "    {call_ext, 1, {extfunc, erlang, length, 1}}.\n",
        out,
    );
}

test "BEAM ctx: $self / $0 substitute to x-registers" {
    const out = try renderBeamToOwned(
        std.testing.allocator,
        "    {move, $self, {x, 1}}.\n    {move, $0, {x, 0}}.\n",
        1,
    );
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(
        "    {move, {x, 0}, {x, 1}}.\n    {move, {x, 1}, {x, 0}}.\n",
        out,
    );
}

test "BEAM ctx: multi-line body with $0 and $1" {
    const out = try renderBeamToOwned(
        std.testing.allocator,
        \\    {test_heap, 2, 2}.
        \\    {put_list, $0, $1, {x, 0}}.
        \\
    ,
        2,
    );
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(
        \\    {test_heap, 2, 2}.
        \\    {put_list, {x, 1}, {x, 2}, {x, 0}}.
        \\
    ,
        out,
    );
}

test "BEAM ctx: $args expands to comma-separated x-registers" {
    const out = try renderBeamToOwned(
        std.testing.allocator,
        "f($self, $args).\n",
        3,
    );
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings(
        "f({x, 0}, {x, 1}, {x, 2}, {x, 3}).\n",
        out,
    );
}

test "BEAM ctx: $N out of range still reds RP1" {
    const r = renderBeamToOwned(std.testing.allocator, "{move, $5, {x, 0}}.\n", 1);
    try std.testing.expectError(error.PrimOpArgIndexOutOfRange, r);
}

// ── arity branch parsing ─────────────────────────────────────────────────────

const ast = @import("../ast.zig");

test "parseArityBranchArg: 1-arg branch" {
    const b = ast.parseArityBranchArg("when(argc == 1): \"lists:nthtail($0, $self)\"") orelse {
        try std.testing.expect(false);
        return;
    };
    try std.testing.expectEqual(@as(usize, 1), b.argc);
    try std.testing.expectEqualStrings("lists:nthtail($0, $self)", b.template);
}

test "parseArityBranchArg: 2-arg branch with internal whitespace" {
    const b = ast.parseArityBranchArg("when( argc  ==  2 ): \"f($0, $1)\"") orelse {
        try std.testing.expect(false);
        return;
    };
    try std.testing.expectEqual(@as(usize, 2), b.argc);
    try std.testing.expectEqualStrings("f($0, $1)", b.template);
}

test "parseArityBranchArg: non-when arg returns null" {
    try std.testing.expect(ast.parseArityBranchArg("\"some template\"") == null);
    try std.testing.expect(ast.parseArityBranchArg("erlang") == null);
}

test "parseArityBranchArg: missing predicate returns null" {
    try std.testing.expect(ast.parseArityBranchArg("when(other == 1): \"foo\"") == null);
}

test "parseArityBranchArg: missing colon returns null" {
    try std.testing.expect(ast.parseArityBranchArg("when(argc == 1) \"foo\"") == null);
}

test "parseArityBranchArg: triple-quoted template strips fences + leading/trailing newline" {
    // The `"""…"""` form on an arity branch — used when the template body
    // carries embedded `"` bytes (charlist literals, JS arrow-fn IIFE, …).
    // `unquoteAnnotationArg` strips the fences AND the conventional single
    // leading + trailing newline ("indent the block").
    const b = ast.parseArityBranchArg(
        "when(argc == 0): \"\"\"erlang:error({todo, \"not implemented\"})\"\"\"",
    ) orelse {
        try std.testing.expect(false);
        return;
    };
    try std.testing.expectEqual(@as(usize, 0), b.argc);
    try std.testing.expectEqualStrings("erlang:error({todo, \"not implemented\"})", b.template);
}
