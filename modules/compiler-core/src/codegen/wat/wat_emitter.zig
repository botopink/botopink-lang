//! WebAssembly-text emitter — the only place that writes `.wat` text.
//!
//! It renders the `wat_ast.zig` model: s-expression layout, indentation,
//! `$`-prefixed identifiers, folded vs flat instruction form, and data-segment
//! escaping. `codegen/wat.zig` builds nodes and never prints, the way
//! `codegen/erlang.zig` builds `erl_ast` nodes for `erl_emitter.zig`.
//!
//! Every module is validated before a byte is written (`wat_ast.validateModule`):
//! a `call` that names nothing the module declares, a body that does not match
//! its `(result …)`, an unnamed parameter — all are refused here rather than
//! surviving into text that `wasmtime` rejects.

const std = @import("std");
const ast = @import("wat_ast.zig");

const Writer = std.Io.Writer;

pub const Error = Writer.Error || ast.Invalid;

// ── entry points ─────────────────────────────────────────────────────────────

/// Render a whole `(module …)` form.
pub fn renderModule(w: *Writer, m: ast.Module) Error!void {
    try ast.validateModule(m);
    try w.writeAll("(module\n");
    for (m.items) |it| try renderItem(w, it);
    try w.writeAll(")\n");
}

/// One top-level form, in the module's two-space item column.
fn renderItem(w: *Writer, it: ast.Item) Error!void {
    switch (it) {
        .import => |im| try import(w, im),
        .memory => |mem| try memory(w, mem),
        .start => |name| try w.print("  (start ${s})\n", .{name}),
        .data => |d| try dataSegment(w, d),
        .global => |g| try global(w, g),
        .func => |f| try func(w, f),
        .comment => |text| try w.print("  ;; {s}\n", .{text}),
    }
}

// ── forms ────────────────────────────────────────────────────────────────────

fn import(w: *Writer, im: ast.Import) Error!void {
    try w.print("  (import \"{s}\" \"{s}\" (func ${s}", .{ im.module, im.name, im.func });
    if (im.type.params.len > 0) {
        try w.writeAll(" (param");
        for (im.type.params) |p| try w.print(" {s}", .{p.text()});
        try w.writeAll(")");
    }
    if (im.type.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("))\n");
}

fn memory(w: *Writer, mem: ast.Memory) Error!void {
    try w.writeAll("  (memory");
    if (mem.@"export") |e| try w.print(" (export \"{s}\")", .{e});
    try w.print(" {d})\n", .{mem.min_pages});
}

fn global(w: *Writer, g: ast.Global) Error!void {
    try w.print("  (global ${s}", .{g.name});
    for (g.exports) |e| try w.print(" (export \"{s}\")", .{e});
    if (g.mutable)
        try w.print(" (mut {s})", .{g.ty.text()})
    else
        try w.print(" {s}", .{g.ty.text()});
    try w.print(" ({s}.const {s}))\n", .{ g.ty.text(), g.init });
}

fn func(w: *Writer, f: ast.Func) Error!void {
    try w.print("  (func ${s}", .{f.name});
    for (f.exports) |e| try w.print(" (export \"{s}\")", .{e});
    for (f.params) |p| try w.print(" (param ${s} {s})", .{ p.name, p.ty.text() });
    if (f.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("\n");
    // `(local …)` lives between the signature and the first instruction — the
    // only place WAT accepts it, and the reason locals are a field of the
    // function node instead of an instruction.
    for (f.locals) |group| {
        try w.writeAll("    ");
        for (group, 0..) |l, i| {
            if (i > 0) try w.writeAll(" ");
            try w.print("(local ${s} {s})", .{ l.name, l.ty.text() });
        }
        try w.writeAll("\n");
    }
    try seq(w, f.body);
    try w.writeAll("  )\n");
}

/// `(data (i32.const off) "…")` — the four-byte little-endian length prefix
/// every string carries, then the bytes.
fn dataSegment(w: *Writer, d: ast.DataSegment) Error!void {
    try w.print("  (data (i32.const {d}) \"", .{d.offset});
    const prefix = [4]u8{
        @truncate(d.len_prefix),
        @truncate(d.len_prefix >> 8),
        @truncate(d.len_prefix >> 16),
        @truncate(d.len_prefix >> 24),
    };
    for (prefix) |c| try w.print("\\{x:0>2}", .{c});
    for (d.bytes) |c| switch (c) {
        '\n' => try w.writeAll("\\n"),
        '"' => try w.writeAll("\\\""),
        '\\' => try w.writeAll("\\\\"),
        '\t' => try w.writeAll("\\t"),
        '\r' => try w.writeAll("\\r"),
        else => if (c < 0x20)
            try w.print("\\{x:0>2}", .{c})
        else
            try w.writeByte(c),
    };
    try w.writeAll("\")\n");
}

// ── instructions ─────────────────────────────────────────────────────────────

fn seq(w: *Writer, s: ast.Seq) Error!void {
    for (s.lines) |l| try line(w, l);
}

fn indent(w: *Writer, n: u8) Error!void {
    for (0..n) |_| try w.writeAll(" ");
}

fn line(w: *Writer, l: ast.Line) Error!void {
    switch (l.instr) {
        .@"if" => |n| return ifForm(w, l.indent, n),
        .block => |b| return blockForm(w, l.indent, b),
        .comment => |text| {
            try indent(w, l.indent);
            return w.print(";; {s}\n", .{text});
        },
        else => {},
    }
    try indent(w, l.indent);
    if (l.folded) try w.writeAll("(");
    try instr(w, l.instr);
    if (l.folded) try w.writeAll(")");
    if (l.comment) |c| try w.print(" ;; {s}", .{c});
    try w.writeAll("\n");
}

fn ifForm(w: *Writer, col: u8, n: ast.If) Error!void {
    try indent(w, col);
    try w.writeAll("(if");
    if (n.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("\n");
    try arm(w, col + 2, "then", n.then);
    if (n.@"else") |e| try arm(w, col + 2, "else", e);
    try indent(w, col);
    try w.writeAll(")\n");
}

fn arm(w: *Writer, col: u8, keyword: []const u8, a: ast.If.Arm) Error!void {
    try indent(w, col);
    try w.print("({s}", .{keyword});
    switch (a.layout) {
        .inline_ => {
            for (a.seq.lines) |l| {
                try w.writeAll(" ");
                try instr(w, l.instr);
            }
            try w.writeAll(")\n");
        },
        .block => {
            try w.writeAll("\n");
            try seq(w, a.seq);
            try indent(w, col);
            try w.writeAll(")\n");
        },
    }
}

fn blockForm(w: *Writer, col: u8, b: ast.Block) Error!void {
    try indent(w, col);
    try w.print("({s}", .{@tagName(b.kind)});
    if (b.label) |l| try w.print(" ${s}", .{l});
    if (b.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("\n");
    try seq(w, b.body);
    try indent(w, col);
    try w.writeAll(")\n");
}

/// The instruction itself, with no indentation, comment or newline — so an
/// inline `if` arm can put several on one line.
fn instr(w: *Writer, i: ast.Instr) Error!void {
    switch (i) {
        .@"const" => |c| try w.print("{s}.const {s}", .{ c.ty.text(), c.text }),
        .local_get => |n| try w.print("local.get ${s}", .{n}),
        .local_set => |n| try w.print("local.set ${s}", .{n}),
        .local_tee => |n| try w.print("local.tee ${s}", .{n}),
        .global_get => |n| try w.print("global.get ${s}", .{n}),
        .global_set => |n| try w.print("global.set ${s}", .{n}),
        .op => |o| try w.print("{s}.{s}", .{ o.ty.text(), o.name }),
        .convert => |o| try w.writeAll(o),
        .load => |m| {
            try w.print("{s}.load", .{m.ty.text()});
            if (m.width == .byte) try w.writeAll("8_u");
            if (m.offset != 0) try w.print(" offset={d}", .{m.offset});
        },
        .store => |m| {
            try w.print("{s}.store", .{m.ty.text()});
            if (m.width == .byte) try w.writeAll("8");
            if (m.offset != 0) try w.print(" offset={d}", .{m.offset});
        },
        .call => |n| try w.print("call ${s}", .{n}),
        .br => |l| try w.print("br ${s}", .{l}),
        .br_if => |l| try w.print("br_if ${s}", .{l}),
        .drop => try w.writeAll("drop"),
        .@"return" => try w.writeAll("return"),
        .@"unreachable" => try w.writeAll("unreachable"),
        .memory_copy => try w.writeAll("memory.copy"),
        .comment => |text| try w.print(";; {s}", .{text}),
        // Structured forms own their own lines; `line`/`arm` never reach here.
        .@"if", .block => unreachable,
    }
}

// ── tests ────────────────────────────────────────────────────────────────────

fn renderToString(alloc: std.mem.Allocator, m: ast.Module) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    errdefer aw.deinit();
    try renderModule(&aw.writer, m);
    return aw.toOwnedSlice();
}

test "a module renders imports, data, globals and functions in item order" {
    const alloc = std.testing.allocator;

    // `(if (result i32) (then i32.const 0) (else …))`: an inline arm and a
    // block arm side by side, plus a `block`/`loop` pair and an indented body.
    const then_arm: ast.If.Arm = .{
        .layout = .inline_,
        .seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        } },
    };
    const else_arm: ast.If.Arm = .{ .seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .indent = 8, .instr = .{ .local_get = "p" } },
        .{ .indent = 8, .instr = .{ .load = .{ .offset = 4 } }, .comment = ".x" },
    } } };

    const loop_body: ast.Seq = .{ .stack = .terminated, .lines = &.{
        .{ .indent = 8, .instr = .{ .local_get = "p" } },
        .{ .indent = 8, .instr = .{ .br_if = "done" } },
        .{ .indent = 8, .instr = .{ .br = "again" } },
    } };

    const body: ast.Seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .instr = .{ .comment = "a note" } },
        .{ .instr = .{ .block = .{ .kind = .block, .label = "done", .body = .{
            .stack = .none,
            .lines = &.{.{ .indent = 6, .instr = .{ .block = .{
                .kind = .loop,
                .label = "again",
                .body = loop_body,
            } } }},
        } } } },
        .{ .instr = .{ .local_get = "p" } },
        .{ .instr = .{ .@"if" = .{ .result = .i32, .then = then_arm, .@"else" = else_arm } } },
    } };

    const m: ast.Module = .{ .items = &.{
        .{ .import = .{
            .module = "wasi_snapshot_preview1",
            .name = "fd_write",
            .func = "fd_write",
            .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 },
        } },
        .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } },
        .{ .start = "__init_globals" },
        .{ .data = .{ .offset = 256, .len_prefix = 3, .bytes = "a\"b" } },
        .{ .global = .{ .name = "__heap_ptr", .ty = .i32, .mutable = true, .init = "264" } },
        .{ .global = .{ .name = "PI", .exports = &.{"PI"}, .ty = .f64, .init = "3.14" } },
        .{ .comment = "a form-level note" },
        .{ .func = .{
            .name = "f",
            .exports = &.{"f"},
            .params = &.{.{ .name = "p", .ty = .i32 }},
            .result = .i32,
            .locals = &.{ &.{.{ .name = "a", .ty = .i32 }}, &.{ .{ .name = "b", .ty = .i32 }, .{ .name = "c", .ty = .f32 } } },
            .body = body,
        } },
    } };

    const out = try renderToString(alloc, m);
    defer alloc.free(out);

    try std.testing.expectEqualStrings(
        \\(module
        \\  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (start $__init_globals)
        \\  (data (i32.const 256) "\03\00\00\00a\"b")
        \\  (global $__heap_ptr (mut i32) (i32.const 264))
        \\  (global $PI (export "PI") f64 (f64.const 3.14))
        \\  ;; a form-level note
        \\  (func $f (export "f") (param $p i32) (result i32)
        \\    (local $a i32)
        \\    (local $b i32) (local $c f32)
        \\    ;; a note
        \\    (block $done
        \\      (loop $again
        \\        local.get $p
        \\        br_if $done
        \\        br $again
        \\      )
        \\    )
        \\    local.get $p
        \\    (if (result i32)
        \\      (then i32.const 0)
        \\      (else
        \\        local.get $p
        \\        i32.load offset=4 ;; .x
        \\      )
        \\    )
        \\  )
        \\)
        \\
    , out);
}

test "a call to a function the module does not declare is refused" {
    const calls_missing: ast.Module = .{ .items = &.{
        .{ .func = .{ .name = "f", .body = .{ .lines = &.{
            .{ .instr = .{ .call = "nope" } },
        } } } },
    } };
    var discard: std.Io.Writer.Discarding = .init(&.{});
    try std.testing.expectError(error.UndefinedCall, renderModule(&discard.writer, calls_missing));

    // The same call is fine once the module defines the symbol.
    const defines_it: ast.Module = .{ .items = &.{
        calls_missing.items[0],
        .{ .func = .{ .name = "nope" } },
    } };
    try renderModule(&discard.writer, defines_it);
}

test "a body's stack has to match the signature" {
    const b: ast.Builder = .{ .arena = std.testing.allocator };

    // A void function may not leave a value behind.
    try std.testing.expectError(error.ResultMismatch, b.func(.{
        .name = "void_leaks",
        .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        } },
    }));

    // …and a function that produces one may not go without a `(result …)`,
    // which is the same check: the specialisation pass used to clear the
    // declared return type and leave the `return <v>` in place.
    try std.testing.expectError(error.ResultMismatch, b.func(.{
        .name = "specialised",
        .result = null,
        .body = .{ .stack = .{ .value = .i32 } },
    }));

    // A terminated body fits either signature.
    const term = try b.func(.{ .name = "t", .result = .f64, .body = .{ .stack = .terminated } });
    try std.testing.expect(term.result.? == .f64);
}

test "an if arm has to fill the result it promises, and an unnamed param is refused" {
    try std.testing.expectError(error.BranchMismatch, ast.validateFunc(.{
        .name = "f",
        .result = .i32,
        .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = .{ .stack = .none } },
                .@"else" = .{ .seq = .{ .stack = .{ .value = .i32 } } },
            } } },
        } },
    }));

    try std.testing.expectError(error.MissingElse, ast.validateFunc(.{
        .name = "f",
        .result = .i32,
        .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = .{ .stack = .{ .value = .i32 } } },
            } } },
        } },
    }));

    try std.testing.expectError(error.UnnamedParam, ast.validateFunc(.{
        .name = "f",
        .params = &.{.{ .name = "", .ty = .i32 }},
    }));
}

test "a helper can only be named by requesting it" {
    var b: ast.Builder = .{ .arena = std.testing.allocator };
    try std.testing.expect(!b.helpers.has(.print));

    const call = b.helper(.print_str);
    try std.testing.expectEqualStrings("__print_str", call.call);
    try std.testing.expect(b.helpers.has(.print_str));
    // `$__print_str` ends in `$__print_nl`, so its group pulls `print` in.
    try std.testing.expect(b.helpers.has(.print));
    try std.testing.expect(!b.helpers.has(.str_eq));
}

test "every runtime helper group renders with its deps, and only with them" {
    const prelude = @import("wat_prelude.zig");
    const alloc = std.testing.allocator;
    for (std.enums.values(ast.HelperGroup)) |g| {
        var set: ast.HelperSet = .{};
        set.require(g);
        var items: std.ArrayListUnmanaged(ast.Item) = .empty;
        defer items.deinit(alloc);
        if (set.has(.print)) try items.append(alloc, .{ .import = prelude.fd_write_import });
        try items.append(alloc, .{ .global = .{ .name = "__heap_ptr", .ty = .i32, .mutable = true, .init = "256" } });
        for (prelude.order) |og| {
            if (set.has(og)) try items.appendSlice(alloc, prelude.items(og));
        }
        var discard: std.Io.Writer.Discarding = .init(&.{});
        renderModule(&discard.writer, .{ .items = items.items }) catch |err| {
            std.debug.print("helper group {s}: {s}\n", .{ @tagName(g), @errorName(err) });
            return err;
        };
    }
}
