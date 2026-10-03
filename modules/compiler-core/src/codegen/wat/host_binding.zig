//! Decision 238 — what a `#[@External.Wasm("…")]` binding names: a closed
//! vocabulary of three forms, read and checked here before anything is
//! lowered.
//!
//! | Form | Means |
//! |---|---|
//! | `op:<opcode>` | one numeric wasm instruction over the declared parameters (`op:f64.floor`) |
//! | `fn:<name>` | a private botopink `fn` of the same module, with the same signature |
//! | `wasi:<adapter>` | a compiler adapter over WASI preview1 (`wasi_snapshot_preview1`), from `adapters` |
//!
//! The arguments are always the declared parameters, in order — there are no
//! markers, no expression text and no way to name an address: nothing a
//! binding writes exposes raw memory, and no runtime helper's name becomes a
//! library's contract. Anything outside the vocabulary — another prefix, an
//! opcode this table does not know, an opcode whose type disagrees with the
//! signature, an adapter that is not listed — is an error at the annotation,
//! never a guess (decision 67).
//!
//! The module is pure: it reads text and value types and answers a `Binding`
//! or a message. `wat.zig` (`checkHostBindings`) resolves `fn:` against the
//! declaring module and lowers each form; `docs.md` § Host bindings documents
//! the adapters and is kept in step with `adapters` by
//! `codegen/tests/wat.zig`'s drift test.

const std = @import("std");
const wat = @import("wat_ast.zig");

/// A numeric value type a binding's signature may spell, or `bool` — the
/// `i32` a comparison answers, which a signature writes as `bool`.
pub const Slot = enum { i32, i64, f32, f64, bool };

/// One opcode: its full text (`f64.floor`), operand types and result.
pub const Op = struct {
    text: []const u8,
    params: []const wat.ValType,
    result: wat.ValType,
    /// A comparison or `eqz`: the `i32` it answers is a truth value, so the
    /// declared return is `bool`.
    yields_bool: bool = false,
};

/// A WASI preview1 adapter: the compiler-owned bridge from a WASI call to a
/// botopink value. `helper` is the prelude function the binding calls.
pub const Adapter = struct {
    name: []const u8,
    params: []const Slot,
    result: ?Slot,
    /// What the adapter answers, for `docs.md`'s table and the diagnostics.
    what: []const u8,
};

/// The adapters a `wasi:` binding may name — the list `docs.md` § Host
/// bindings documents. Each is a prelude helper (`wat_prelude.zig`, the group
/// of its name) named `__wasi_<name>`. `seed_u32` / `seeded_f64` make no WASI
/// call of their own: they hold the state of `std/io/random`'s seeded stream,
/// which no botopink module can hold on every target, and draw it as the
/// commonJS host's sidecar does (Mulberry32).
pub const adapters = [_]Adapter{
    .{ .name = "random_f64", .params = &.{}, .result = .f64, .what = "a uniform `f64` in `[0.0, 1.0)` from 53 bits of `random_get`" },
    .{ .name = "seed_u32", .params = &.{.i32}, .result = null, .what = "seeds the module's Mulberry32 stream with the word's bits" },
    .{ .name = "seeded_f64", .params = &.{}, .result = .f64, .what = "the next Mulberry32 draw in `[0.0, 1.0)`, or `random_f64`'s before any seed" },
};

pub const Binding = union(enum) {
    op: Op,
    /// The private fn's name, as written.
    fn_: []const u8,
    wasi: Adapter,
};

/// The signature a binding is checked against: the declared parameters'
/// slots (null for a type no numeric slot spells — a string, an array, a
/// record) and the declared return's (null for `void` / no return; `other`
/// set when the return is a non-numeric type).
pub const Signature = struct {
    params: []const ?Slot,
    result: ?Slot,
    result_other: bool = false,
};

/// A refused binding: the message, owned by the caller's allocator.
pub const Refused = struct { message: []u8 };

pub const Result = union(enum) { ok: Binding, refused: Refused };

/// Reads `text` (the annotation's string, unquoted). `fn:` is only split
/// here; its name is resolved by the caller, which knows the module.
pub fn parse(alloc: std.mem.Allocator, text: []const u8, sig: Signature) !Result {
    if (std.mem.startsWith(u8, text, "op:")) {
        const name = text["op:".len..];
        const op = findOp(name) orelse return refused(alloc, "`#[@External.Wasm(\"{s}\")]`: `{s}` is not a wasm numeric instruction this backend binds (an `op:` names one opcode, e.g. `op:f64.floor`)", .{ text, name });
        if (try checkOp(alloc, text, op, sig)) |r| return r;
        return .{ .ok = .{ .op = op } };
    }
    if (std.mem.startsWith(u8, text, "fn:")) {
        const name = text["fn:".len..];
        if (!isIdent(name)) return refused(alloc, "`#[@External.Wasm(\"{s}\")]`: `fn:` names a private fn of this module by its identifier", .{text});
        return .{ .ok = .{ .fn_ = name } };
    }
    if (std.mem.startsWith(u8, text, "wasi:")) {
        const name = text["wasi:".len..];
        const ad = findAdapter(name) orelse return refused(alloc, "`#[@External.Wasm(\"{s}\")]`: `{s}` is not a WASI adapter — the adapters are listed in docs.md § Host bindings ({s})", .{ text, name, adapterNames() });
        if (sig.params.len != ad.params.len or !slotsEql(sig.params, ad.params) or !resultEql(sig, ad.result)) {
            const takes = try slotsText(alloc, ad.params);
            defer alloc.free(takes);
            return refused(alloc, "`#[@External.Wasm(\"{s}\")]`: the adapter `{s}` takes {s} and answers {s}; the declaration's signature differs", .{ text, name, takes, slotText(ad.result) });
        }
        return .{ .ok = .{ .wasi = ad } };
    }
    return refused(alloc, "`#[@External.Wasm(\"{s}\")]` is none of the three forms a wasm binding takes: `op:<opcode>`, `fn:<private fn of this module>`, `wasi:<adapter>`", .{text});
}

fn refused(alloc: std.mem.Allocator, comptime f: []const u8, args: anytype) !Result {
    return .{ .refused = .{ .message = try std.fmt.allocPrint(alloc, f, args) } };
}

fn checkOp(alloc: std.mem.Allocator, text: []const u8, op: Op, sig: Signature) !?Result {
    var ok = sig.params.len == op.params.len and !sig.result_other;
    if (ok) for (sig.params, op.params) |p, want| {
        const got = p orelse {
            ok = false;
            break;
        };
        if (got == .bool or !std.mem.eql(u8, @tagName(got), @tagName(want))) ok = false;
    };
    if (ok) {
        const r = sig.result orelse return try refused(alloc, "`#[@External.Wasm(\"{s}\")]`: `{s}` answers a value; the declaration answers none", .{ text, op.text });
        ok = if (op.yields_bool) r == .bool else (r != .bool and std.mem.eql(u8, @tagName(r), @tagName(op.result)));
    }
    if (ok) return null;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(alloc);
    try buf.append(alloc, '(');
    for (op.params, 0..) |p, i| {
        if (i > 0) try buf.appendSlice(alloc, ", ");
        try buf.appendSlice(alloc, @tagName(p));
    }
    try buf.appendSlice(alloc, ") -> ");
    try buf.appendSlice(alloc, if (op.yields_bool) "bool" else @tagName(op.result));
    return try refused(alloc, "`#[@External.Wasm(\"{s}\")]`: `{s}` is `{s}`, and the declared parameters and return must be exactly those types", .{ text, op.text, buf.items });
}

fn slotsEql(a: []const ?Slot, b: []const Slot) bool {
    for (a, b) |x, y| if (x == null or x.? != y) return false;
    return true;
}

fn resultEql(sig: Signature, want: ?Slot) bool {
    if (sig.result_other) return false;
    if (want == null) return sig.result == null;
    return sig.result != null and sig.result.? == want.?;
}

fn slotText(s: ?Slot) []const u8 {
    return if (s) |x| @tagName(x) else "nothing";
}

/// The adapter's parameter list as text, owned by the caller.
fn slotsText(alloc: std.mem.Allocator, ss: []const Slot) ![]u8 {
    if (ss.len == 0) return alloc.dupe(u8, "no parameter");
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(alloc);
    try buf.append(alloc, '(');
    for (ss, 0..) |s, i| {
        if (i > 0) try buf.appendSlice(alloc, ", ");
        try buf.appendSlice(alloc, @tagName(s));
    }
    try buf.append(alloc, ')');
    return buf.toOwnedSlice(alloc);
}

fn adapterNames() []const u8 {
    comptime var text: []const u8 = "";
    inline for (adapters, 0..) |a, i| text = text ++ (if (i > 0) ", " else "") ++ a.name;
    return text;
}

pub fn findAdapter(name: []const u8) ?Adapter {
    for (adapters) |a| if (std.mem.eql(u8, a.name, name)) return a;
    return null;
}

fn isIdent(s: []const u8) bool {
    if (s.len == 0) return false;
    for (s, 0..) |c, i| {
        const ok = std.ascii.isAlphabetic(c) or c == '_' or (i > 0 and std.ascii.isDigit(c));
        if (!ok) return false;
    }
    return true;
}

// ── the opcode table ─────────────────────────────────────────────────────────
//
// The MVP numeric instructions, by shape. Memory, control, local/global and
// reference instructions are not in it: a binding names a computation over
// its parameters, never a place.

const int_unary = [_][]const u8{ "clz", "ctz", "popcnt" };
const int_binary = [_][]const u8{ "add", "sub", "mul", "div_s", "div_u", "rem_s", "rem_u", "and", "or", "xor", "shl", "shr_s", "shr_u", "rotl", "rotr" };
const int_compare = [_][]const u8{ "eq", "ne", "lt_s", "lt_u", "gt_s", "gt_u", "le_s", "le_u", "ge_s", "ge_u" };
const float_unary = [_][]const u8{ "abs", "neg", "ceil", "floor", "trunc", "nearest", "sqrt" };
const float_binary = [_][]const u8{ "add", "sub", "mul", "div", "min", "max", "copysign" };
const float_compare = [_][]const u8{ "eq", "ne", "lt", "gt", "le", "ge" };

const Conversion = struct { text: []const u8, from: wat.ValType, to: wat.ValType };
const conversions = [_]Conversion{
    .{ .text = "i32.wrap_i64", .from = .i64, .to = .i32 },
    .{ .text = "i64.extend_i32_s", .from = .i32, .to = .i64 },
    .{ .text = "i64.extend_i32_u", .from = .i32, .to = .i64 },
    .{ .text = "i32.trunc_f32_s", .from = .f32, .to = .i32 },
    .{ .text = "i32.trunc_f32_u", .from = .f32, .to = .i32 },
    .{ .text = "i32.trunc_f64_s", .from = .f64, .to = .i32 },
    .{ .text = "i32.trunc_f64_u", .from = .f64, .to = .i32 },
    .{ .text = "i64.trunc_f32_s", .from = .f32, .to = .i64 },
    .{ .text = "i64.trunc_f32_u", .from = .f32, .to = .i64 },
    .{ .text = "i64.trunc_f64_s", .from = .f64, .to = .i64 },
    .{ .text = "i64.trunc_f64_u", .from = .f64, .to = .i64 },
    .{ .text = "f32.convert_i32_s", .from = .i32, .to = .f32 },
    .{ .text = "f32.convert_i32_u", .from = .i32, .to = .f32 },
    .{ .text = "f32.convert_i64_s", .from = .i64, .to = .f32 },
    .{ .text = "f32.convert_i64_u", .from = .i64, .to = .f32 },
    .{ .text = "f64.convert_i32_s", .from = .i32, .to = .f64 },
    .{ .text = "f64.convert_i32_u", .from = .i32, .to = .f64 },
    .{ .text = "f64.convert_i64_s", .from = .i64, .to = .f64 },
    .{ .text = "f64.convert_i64_u", .from = .i64, .to = .f64 },
    .{ .text = "f32.demote_f64", .from = .f64, .to = .f32 },
    .{ .text = "f64.promote_f32", .from = .f32, .to = .f64 },
    .{ .text = "i32.reinterpret_f32", .from = .f32, .to = .i32 },
    .{ .text = "i64.reinterpret_f64", .from = .f64, .to = .i64 },
    .{ .text = "f32.reinterpret_i32", .from = .i32, .to = .f32 },
    .{ .text = "f64.reinterpret_i64", .from = .i64, .to = .f64 },
};

fn tyOf(s: []const u8) ?wat.ValType {
    inline for (.{ wat.ValType.i32, .i64, .f32, .f64 }) |t| if (std.mem.eql(u8, s, @tagName(t))) return t;
    return null;
}

fn listed(list: []const []const u8, s: []const u8) bool {
    for (list) |x| if (std.mem.eql(u8, x, s)) return true;
    return false;
}

/// The opcode `text` spells (`f64.floor`, `i32.add`, `f64.convert_i32_s`),
/// or null for anything the table does not hold.
pub fn findOp(text: []const u8) ?Op {
    for (conversions) |c| if (std.mem.eql(u8, c.text, text))
        return .{ .text = c.text, .params = oneOf(c.from), .result = c.to };
    const dot = std.mem.indexOfScalar(u8, text, '.') orelse return null;
    const ty = tyOf(text[0..dot]) orelse return null;
    const name = text[dot + 1 ..];
    const one = oneOf(ty);
    const two = twoOf(ty);
    switch (ty) {
        .i32, .i64 => {
            if (std.mem.eql(u8, name, "eqz")) return .{ .text = text, .params = one, .result = .i32, .yields_bool = true };
            if (listed(&int_unary, name)) return .{ .text = text, .params = one, .result = ty };
            if (listed(&int_binary, name)) return .{ .text = text, .params = two, .result = ty };
            if (listed(&int_compare, name)) return .{ .text = text, .params = two, .result = .i32, .yields_bool = true };
        },
        .f32, .f64 => {
            if (listed(&float_unary, name)) return .{ .text = text, .params = one, .result = ty };
            if (listed(&float_binary, name)) return .{ .text = text, .params = two, .result = ty };
            if (listed(&float_compare, name)) return .{ .text = text, .params = two, .result = .i32, .yields_bool = true };
        },
    }
    return null;
}

fn oneOf(t: wat.ValType) []const wat.ValType {
    return switch (t) {
        .i32 => &.{.i32},
        .i64 => &.{.i64},
        .f32 => &.{.f32},
        .f64 => &.{.f64},
    };
}

fn twoOf(t: wat.ValType) []const wat.ValType {
    return switch (t) {
        .i32 => &.{ .i32, .i32 },
        .i64 => &.{ .i64, .i64 },
        .f32 => &.{ .f32, .f32 },
        .f64 => &.{ .f64, .f64 },
    };
}

/// The opcode's shape for the instruction model: a conversion is a
/// `.convert`, everything else an `.op` of its type and name.
pub fn instrOf(op: Op) wat.Instr {
    for (conversions) |c| if (std.mem.eql(u8, c.text, op.text)) return .{ .convert = c.text };
    const dot = std.mem.indexOfScalar(u8, op.text, '.').?;
    return .{ .op = .{ .ty = tyOf(op.text[0..dot]).?, .name = op.text[dot + 1 ..] } };
}

test "host binding: the three forms and their refusals" {
    const a = std.testing.allocator;
    const f64x1 = Signature{ .params = &.{.f64}, .result = .f64 };
    {
        const r = try parse(a, "op:f64.floor", f64x1);
        try std.testing.expectEqualStrings("f64.floor", r.ok.op.text);
    }
    {
        const r = try parse(a, "op:f64.flor", f64x1);
        defer a.free(r.refused.message);
        try std.testing.expect(std.mem.indexOf(u8, r.refused.message, "`f64.flor` is not a wasm numeric instruction") != null);
    }
    {
        const r = try parse(a, "op:f64.min", f64x1);
        defer a.free(r.refused.message);
        try std.testing.expect(std.mem.indexOf(u8, r.refused.message, "`(f64, f64) -> f64`") != null);
    }
    {
        const r = try parse(a, "op:f64.lt", .{ .params = &.{ .f64, .f64 }, .result = .f64 });
        defer a.free(r.refused.message);
        try std.testing.expect(std.mem.indexOf(u8, r.refused.message, "-> bool") != null);
    }
    {
        const r = try parse(a, "fn:powBody", f64x1);
        try std.testing.expectEqualStrings("powBody", r.ok.fn_);
    }
    {
        const r = try parse(a, "wasi:random_f64", .{ .params = &.{}, .result = .f64 });
        try std.testing.expectEqualStrings("random_f64", r.ok.wasi.name);
    }
    {
        const r = try parse(a, "wasi:seed_u32", .{ .params = &.{.i32}, .result = null });
        try std.testing.expectEqualStrings("seed_u32", r.ok.wasi.name);
    }
    {
        const r = try parse(a, "wasi:seed_u32", .{ .params = &.{.f64}, .result = null });
        defer a.free(r.refused.message);
        try std.testing.expect(std.mem.indexOf(u8, r.refused.message, "takes (i32) and answers nothing") != null);
    }
    {
        const r = try parse(a, "wasi:clock_time_get", .{ .params = &.{}, .result = .f64 });
        defer a.free(r.refused.message);
        try std.testing.expect(std.mem.indexOf(u8, r.refused.message, "is not a WASI adapter") != null);
    }
    {
        const r = try parse(a, "$0 + 1", f64x1);
        defer a.free(r.refused.message);
        try std.testing.expect(std.mem.indexOf(u8, r.refused.message, "none of the three forms") != null);
    }
}
