//! std-wasm's program face: `zig build std-wasm` → `zig-out/lib/std_wasm.wasm`,
//! a position-independent side module (wasm32-freestanding, MVP + bulk
//! memory, `dylink.0`) whose functions the wasm codegen decodes into a
//! `--target wasm` program (`compiler-core/src/codegen/wat/std_wasm_link.zig`,
//! decision 440 (2)). The comptime runtime does not link this file — it
//! compiles the package into its own term library (`root.zig`).
//!
//! Each entry of `root.exports` is exported under its cell's text,
//! `std:<module>.<function>` (`std:hash.contentHash`) — never the bare
//! `hash.contentHash`, which is the name Zig gives `hash.zig`'s own
//! `contentHash`: an export of that name resolves to itself, and the
//! optimizer, seeing the recursion, compiles the export to `unreachable`. Its
//! values are the program's own: a `string` is the
//! address of its `u32` length with the bytes behind it — the layout every
//! string of a wasm program has — and an answer is a fresh string allocated
//! through the program's bump allocator, imported as `env.bp_alloc` (the
//! decoder binds it to `$__alloc`). The module's data, its function table and
//! its stack are placed by the program (`__memory_base`, `__table_base`,
//! `__stack_pointer`).
const std = @import("std");
const root = @import("root.zig");

/// The program's allocator: `n` fresh bytes, 4-aligned; it grows the memory
/// or traps.
extern "env" fn bp_alloc(n: u32) u32;

/// The bytes of the program string at `s`.
fn arg(s: u32) []const u8 {
    const len = @as(*const u32, @ptrFromInt(s)).*;
    return @as([*]const u8, @ptrFromInt(s + 4))[0..len];
}

/// `bytes` as a fresh program string.
fn fresh(bytes: []const u8) u32 {
    const p = bp_alloc(@intCast(bytes.len + 4));
    @as(*u32, @ptrFromInt(p)).* = @intCast(bytes.len);
    @memcpy(@as([*]u8, @ptrFromInt(p + 4))[0..bytes.len], bytes);
    return p;
}

/// A fresh program string of `n` bytes, its bytes for the caller to write.
fn blank(n: usize) struct { ptr: u32, bytes: []u8 } {
    const p = bp_alloc(@intCast(n + 4));
    @as(*u32, @ptrFromInt(p)).* = @intCast(n);
    return .{ .ptr = p, .bytes = @as([*]u8, @ptrFromInt(p + 4))[0..n] };
}

/// The slots of the program array at `a` (`[n][e0][e1]…`, one word each).
fn slots(a: u32) []u32 {
    const n = @as(*const u32, @ptrFromInt(a)).*;
    return @as([*]u32, @ptrFromInt(a + 4))[0..n];
}

/// A fresh program array of `n` slots, its slots for the caller to write —
/// the layout `$__arr_new` makes.
fn newArray(n: usize) struct { ptr: u32, slots: []u32 } {
    const p = bp_alloc(@intCast((n + 1) * 4));
    @as(*u32, @ptrFromInt(p)).* = @intCast(n);
    return .{ .ptr = p, .slots = @as([*]u32, @ptrFromInt(p + 4))[0..n] };
}

/// The program string of each piece `it` yields, as a fresh array: counted
/// first, then cut.
fn piecesArray(it0: anytype) u32 {
    var it = it0;
    var n: usize = 0;
    while (it.next()) |_| n += 1;
    const out = newArray(n);
    it = it0;
    for (out.slots) |*slot| slot.* = fresh(it.next().?);
    return out.ptr;
}

/// `hash.contentHash`. A program string is valid UTF-8, so the refusal is
/// unreachable from a program; it traps rather than answer.
fn contentHash(s: u32) callconv(.c) u32 {
    var buf: [8]u8 = undefined;
    const h = root.hash.contentHash(&buf, arg(s)) catch @trap();
    return fresh(h);
}

fn trimmed(s: u32, dir: root.text.TrimDir) u32 {
    const a = arg(s);
    const t = root.text.trim(a, dir);
    // Nothing trimmed: the string itself (strings are immutable).
    if (t.len == a.len) return s;
    return fresh(t);
}

/// `String.trim`.
fn trim(s: u32) callconv(.c) u32 {
    return trimmed(s, .both);
}

/// `String.trimStart`.
fn trimStart(s: u32) callconv(.c) u32 {
    return trimmed(s, .leading);
}

/// `String.trimEnd`.
fn trimEnd(s: u32) callconv(.c) u32 {
    return trimmed(s, .trailing);
}

/// `Float.toString`, and the text a wasm program writes for a float
/// anywhere (decision 441).
fn floatToString(f: f64) callconv(.c) u32 {
    var buf: [64]u8 = undefined;
    return fresh(root.number.shortFloat(f, &buf));
}

// ── `String`'s methods (decision 442 (2)) ─────────────────────────────────

/// `String.length` — code points (decision 240).
fn length(s: u32) callconv(.c) i32 {
    return @intCast(root.text.cpLength(arg(s)));
}

/// `String.split`.
fn split(s: u32, sep: u32) callconv(.c) u32 {
    return piecesArray(root.text.Split.init(arg(s), arg(sep)));
}

/// `String.chars` — one string per code point.
fn chars(s: u32) callconv(.c) u32 {
    return piecesArray(root.text.Split.init(arg(s), ""));
}

/// `String.lines`.
fn lines(s: u32) callconv(.c) u32 {
    return piecesArray(root.text.Lines{ .s = arg(s) });
}

/// `String.words`.
fn words(s: u32) callconv(.c) u32 {
    return piecesArray(root.text.Words{ .s = arg(s) });
}

/// `String.contains`.
fn contains(s: u32, sub: u32) callconv(.c) i32 {
    return @intFromBool(root.text.find(arg(s), arg(sub)) != null);
}

/// `String.startsWith`.
fn startsWith(s: u32, x: u32) callconv(.c) i32 {
    return @intFromBool(root.text.startsWith(arg(s), arg(x)));
}

/// `String.endsWith`.
fn endsWith(s: u32, x: u32) callconv(.c) i32 {
    return @intFromBool(root.text.endsWith(arg(s), arg(x)));
}

/// `String.indexOf` — a code point index.
fn indexOf(s: u32, sub: u32) callconv(.c) i32 {
    return root.text.indexOf(arg(s), arg(sub));
}

/// `String.lastIndexOf` — a code point index.
fn lastIndexOf(s: u32, sub: u32) callconv(.c) i32 {
    return root.text.lastIndexOf(arg(s), arg(sub));
}

/// `String.at` — a `?string`: the code point as a fresh string, or `0`.
fn at(s: u32, i: i32) callconv(.c) u32 {
    return if (root.text.cpAt(arg(s), i)) |c| fresh(c) else 0;
}

/// `String.charCodeAt`.
fn charCodeAt(s: u32, i: i32) callconv(.c) i32 {
    return root.text.charCodeAt(arg(s), i);
}

fn padded(s: u32, width: i32, pad: u32, start: bool) u32 {
    const a = arg(s);
    const n = root.text.padLength(a, width, arg(pad));
    // No gap: the string itself (strings are immutable).
    if (n == a.len) return s;
    const out = blank(n);
    root.text.padInto(out.bytes, a, arg(pad), start);
    return out.ptr;
}

/// `String.padStart`.
fn padStart(s: u32, width: i32, pad: u32) callconv(.c) u32 {
    return padded(s, width, pad, true);
}

/// `String.padEnd`.
fn padEnd(s: u32, width: i32, pad: u32) callconv(.c) u32 {
    return padded(s, width, pad, false);
}

/// `String.repeat`.
fn repeat(s: u32, times: i32) callconv(.c) u32 {
    const a = arg(s);
    const out = blank(root.text.repeatLength(a, times));
    root.text.repeatInto(out.bytes, a);
    return out.ptr;
}

fn replaced(s: u32, pat: u32, with: u32, all: bool) u32 {
    const a = arg(s);
    const out = blank(root.text.replacedLength(a, arg(pat), arg(with), all));
    root.text.replaceInto(out.bytes, a, arg(pat), arg(with), all);
    return out.ptr;
}

/// `String.replace` — the first occurrence.
fn replace(s: u32, pat: u32, with: u32) callconv(.c) u32 {
    return replaced(s, pat, with, false);
}

/// `String.replaceAll`.
fn replaceAll(s: u32, pat: u32, with: u32) callconv(.c) u32 {
    return replaced(s, pat, with, true);
}

/// `String.fromCodepoint` — a value that is no Unicode scalar value traps,
/// as erlang's `<<Cp/utf8>>` raises and the Node cell throws (decision 262).
fn fromCodepoint(cp: i32) callconv(.c) u32 {
    var buf: [4]u8 = undefined;
    return fresh(root.text.encodeCodepoint(&buf, cp) orelse @trap());
}

/// `s.slice(a, b)` in code points with `slice`'s bounds — the codegen's
/// string slice and index (`s[a..b]`).
fn textSlice(s: u32, a: i32, b: i32) callconv(.c) u32 {
    return fresh(root.text.cpSlice(arg(s), a, b));
}

// ── integers as text (decision 442 (2)) ─────────────────────────────────────

fn intString(v: i64, unsigned: bool) u32 {
    var buf: [24]u8 = undefined;
    const n = if (unsigned) root.number.unsignedText(&buf, @bitCast(v)) else root.number.signedText(&buf, v);
    return fresh(buf[0..n]);
}

/// An `i32`'s decimal text as a fresh string.
fn i32ToString(v: i32) callconv(.c) u32 {
    return intString(v, false);
}

/// An `i64`'s decimal text as a fresh string.
fn i64ToString(v: i64) callconv(.c) u32 {
    return intString(v, false);
}

/// A `u64`'s — the carrier's 64 bits read unsigned (decision 319).
fn u64ToString(v: i64) callconv(.c) u32 {
    return intString(v, true);
}

/// The one workspace a printed integer's text is written in: `[len][digits]`,
/// overwritten by the next — what lets `@print` of an `i64` allocate nothing.
var int_ws: [4 + 24]u8 align(4) = undefined;

fn intText(v: i64, unsigned: bool) u32 {
    const n = if (unsigned) root.number.unsignedText(int_ws[4..], @bitCast(v)) else root.number.signedText(int_ws[4..], v);
    @as(*u32, @ptrCast(&int_ws)).* = @intCast(n);
    return @intFromPtr(&int_ws);
}

/// An `i64`'s text in the workspace — what `$__print_i64_raw` writes.
fn i64Text(v: i64) callconv(.c) u32 {
    return intText(v, false);
}

/// A `u64`'s text in the workspace — what `$__print_u64_raw` writes.
fn u64Text(v: i64) callconv(.c) u32 {
    return intText(v, true);
}

// ── `Array`'s methods, over slot words (decision 442 (2)) ─────────────────

/// A fresh array holding `parts`' slots one after the other.
fn joined(parts: []const []const u32) u32 {
    var n: usize = 0;
    for (parts) |p| n += p.len;
    const out = newArray(n);
    var o: usize = 0;
    for (parts) |p| {
        @memcpy(out.slots[o..][0..p.len], p);
        o += p.len;
    }
    return out.ptr;
}

/// `xs.reverse()`.
fn reverse(xs: u32) callconv(.c) u32 {
    const a = slots(xs);
    const out = newArray(a.len);
    for (out.slots, 0..) |*slot, i| slot.* = a[a.len - 1 - i];
    return out.ptr;
}

fn sliced(xs: u32, a: i32, b: i32) u32 {
    const all = slots(xs);
    const r = root.array.sliceRange(all.len, a, b);
    return joined(&.{all[r.from..][0..r.len]});
}

/// `xs.slice(a, b)` (`rest`, `take`, `drop`, a list pattern's rest).
fn arraySlice(xs: u32, a: i32, b: i32) callconv(.c) u32 {
    return sliced(xs, a, b);
}

/// `xs.prepend(x)` — `x` the element's slot word.
fn prepend(xs: u32, x: u32) callconv(.c) u32 {
    return joined(&.{ &.{x}, slots(xs) });
}

/// `a.append(b)`, `[...a, ...b]`.
fn concat(a: u32, b: u32) callconv(.c) u32 {
    return joined(&.{ slots(a), slots(b) });
}

/// `a.zip(b)` — 2-slot tuples, as long as the shorter array.
fn zip(a: u32, b: u32) callconv(.c) u32 {
    const xs = slots(a);
    const ys = slots(b);
    const out = newArray(@min(xs.len, ys.len));
    for (out.slots, 0..) |*slot, i| {
        const t = bp_alloc(8);
        @as(*[2]u32, @ptrFromInt(t)).* = .{ xs[i], ys[i] };
        slot.* = t;
    }
    return out.ptr;
}

/// `xs.fill(v)` — `n` slots holding the word `v` (`Array.repeat(v, n)`).
fn fill(n: i32, v: u32) callconv(.c) u32 {
    const out = newArray(@intCast(@max(n, 0)));
    @memset(out.slots, v);
    return out.ptr;
}

/// The strings of `xs` joined with `sep`, as one fresh string.
fn joinStrings(xs: u32, sep: u32) callconv(.c) u32 {
    const items = slots(xs);
    const s = arg(sep);
    var n: usize = 0;
    for (items) |e| n += arg(e).len;
    if (items.len > 0) n += s.len * (items.len - 1);
    const out = blank(n);
    var o: usize = 0;
    for (items, 0..) |e, i| {
        if (i > 0) {
            @memcpy(out.bytes[o..][0..s.len], s);
            o += s.len;
        }
        const t = arg(e);
        @memcpy(out.bytes[o..][0..t.len], t);
        o += t.len;
    }
    return out.ptr;
}

/// `xs.join(sep)` over integers: each slot's decimal text.
fn joinInts(xs: u32, sep: u32) callconv(.c) u32 {
    const items = slots(xs);
    const texts = newArray(items.len);
    for (texts.slots, items) |*t, e| t.* = intString(@as(i32, @bitCast(e)), false);
    return joinStrings(texts.ptr, sep);
}

/// `xs.join(sep)` over floats: each cell as `Float.toString` writes it.
fn joinFloats(xs: u32, sep: u32) callconv(.c) u32 {
    const items = slots(xs);
    const texts = newArray(items.len);
    for (texts.slots, items) |*t, e| t.* = floatToString(@as(*const f64, @ptrFromInt(e)).*);
    return joinStrings(texts.ptr, sep);
}

fn sameWord(x: u32, e: u32) bool {
    return e == x;
}

fn sameString(x: u32, e: u32) bool {
    return std.mem.eql(u8, arg(e), arg(x));
}

/// A float slot's cell compared by `f64.eq` (`NaN` never found, `-0` finds
/// `0`) — native `Array#indexOf`'s strict equality.
fn sameFloat(x: f64, e: u32) bool {
    return @as(*const f64, @ptrFromInt(e)).* == x;
}

/// `xs.indexOf(x)` over integers, bools, enum ordinals, records by address.
fn indexOfWord(xs: u32, x: u32) callconv(.c) i32 {
    return root.array.search(slots(xs), false, x, sameWord);
}

/// `xs.indexOf(x)` over strings, by content.
fn indexOfString(xs: u32, x: u32) callconv(.c) i32 {
    return root.array.search(slots(xs), false, x, sameString);
}

/// `xs.indexOf(x)` over floats.
fn indexOfFloat(xs: u32, x: f64) callconv(.c) i32 {
    return root.array.search(slots(xs), false, x, sameFloat);
}

fn lastIndexOfWord(xs: u32, x: u32) callconv(.c) i32 {
    return root.array.search(slots(xs), true, x, sameWord);
}

fn lastIndexOfString(xs: u32, x: u32) callconv(.c) i32 {
    return root.array.search(slots(xs), true, x, sameString);
}

fn lastIndexOfFloat(xs: u32, x: f64) callconv(.c) i32 {
    return root.array.search(slots(xs), true, x, sameFloat);
}

fn eqWords(_: void, a: u32, b: u32) bool {
    return a == b;
}

fn eqStrings(_: void, a: u32, b: u32) bool {
    return std.mem.eql(u8, arg(a), arg(b));
}

/// Two float cells by their bits — decision 214's `==` over floats.
fn eqFloatBits(_: void, a: u32, b: u32) bool {
    return @as(*const u64, @ptrFromInt(a)).* == @as(*const u64, @ptrFromInt(b)).*;
}

/// `xs.unique()` — `mode` names the equality: `0` the slot's word, `1` the
/// `f64` its cell holds (by bits), `2` a string's content.
fn unique(xs: u32, mode: i32) callconv(.c) u32 {
    const items = slots(xs);
    const out = newArray(items.len);
    const k = switch (mode) {
        1 => root.array.uniqueInto(out.slots, items, {}, eqFloatBits),
        2 => root.array.uniqueInto(out.slots, items, {}, eqStrings),
        else => root.array.uniqueInto(out.slots, items, {}, eqWords),
    };
    @as(*u32, @ptrFromInt(out.ptr)).* = @intCast(k);
    return out.ptr;
}

/// `xs.flatten()` over an array of arrays: every inner array's slots, in order.
fn flatten(xs: u32) callconv(.c) u32 {
    const outer = slots(xs);
    var n: usize = 0;
    for (outer) |inner| n += slots(inner).len;
    const out = newArray(n);
    var o: usize = 0;
    for (outer) |inner| {
        const s = slots(inner);
        @memcpy(out.slots[o..][0..s.len], s);
        o += s.len;
    }
    return out.ptr;
}

/// `xs.chunked(m)`: consecutive slices of `m`, the last shorter.
fn chunked(xs: u32, m: i32) callconv(.c) u32 {
    const out = newArray(root.array.chunkCount(slots(xs).len, m));
    for (out.slots, 0..) |*slot, k| {
        const from: i32 = @intCast(k * @as(usize, @intCast(m)));
        slot.* = sliced(xs, from, from + m);
    }
    return out.ptr;
}

/// `xs.sliding(m)`: one slice of `m` per start offset.
fn sliding(xs: u32, m: i32) callconv(.c) u32 {
    const out = newArray(root.array.slidingCount(slots(xs).len, m));
    for (out.slots, 0..) |*slot, k| {
        const from: i32 = @intCast(k);
        slot.* = sliced(xs, from, from + m);
    }
    return out.ptr;
}

// ── `bigint` (decisions 332, 442 (2)) ──────────────────────────────────────
//
// A program's `bigint` is the address of a `[L][limb0][limb1]…` block, `L`
// the limbs' byte count negated for a negative value (`0` is zero) — a
// positive literal is a data segment of the string layout. The codegen
// passes and receives those addresses; the limbs are `bigint.zig`'s.

fn readBig(p: u32) root.bigint.Big {
    const l = @as(*const i32, @ptrFromInt(p)).*;
    const n: usize = @intCast(@abs(l) / 4);
    return .{ .neg = l < 0, .limbs = @as([*]const u32, @ptrFromInt(p + 4))[0..n] };
}

/// A fresh block with room for `cap` limbs, its `L` written by `finish`.
fn bigBlock(cap: usize) struct { ptr: u32, limbs: []u32 } {
    const p = bp_alloc(@intCast((cap + 1) * 4));
    return .{ .ptr = p, .limbs = @as([*]u32, @ptrFromInt(p + 4))[0..cap] };
}

/// The block at `p` holding `len` limbs: its `L`, negated when `neg` and
/// nonzero.
fn finish(p: u32, neg: bool, len: usize) u32 {
    const l: i32 = @intCast(len * 4);
    @as(*i32, @ptrFromInt(p)).* = if (neg) -l else l;
    return p;
}

/// `x + y`, or `x - y` when `flip`.
fn bigAdd(x: u32, y: u32, flip: i32) callconv(.c) u32 {
    const a = readBig(x);
    var b = readBig(y);
    b.neg = b.neg != (flip != 0);
    const out = bigBlock(@max(a.limbs.len, b.limbs.len) + 1);
    if (a.neg == b.neg) return finish(out.ptr, a.neg, root.bigint.addMag(out.limbs, a.limbs, b.limbs).len);
    if (root.bigint.cmpMag(a.limbs, b.limbs) >= 0) return finish(out.ptr, a.neg, root.bigint.subMag(out.limbs, a.limbs, b.limbs).len);
    return finish(out.ptr, b.neg, root.bigint.subMag(out.limbs, b.limbs, a.limbs).len);
}

/// `-x`.
fn bigNegate(x: u32) callconv(.c) u32 {
    const a = readBig(x);
    const out = bigBlock(a.limbs.len);
    @memcpy(out.limbs, a.limbs);
    return finish(out.ptr, !a.neg, a.limbs.len);
}

/// `x * y`.
fn bigMultiply(x: u32, y: u32) callconv(.c) u32 {
    const a = readBig(x);
    const b = readBig(y);
    const out = bigBlock(a.limbs.len + b.limbs.len);
    return finish(out.ptr, a.neg != b.neg, root.bigint.mulMag(out.limbs, a.limbs, b.limbs).len);
}

/// `x / y` truncated toward zero, or — when `rem` — `x % y` with `x`'s sign.
/// A zero `y` traps (an integer `/` or `%` by zero aborts, decision 264).
fn bigDivmod(x: u32, y: u32, rem: i32) callconv(.c) u32 {
    const a = readBig(x);
    const b = readBig(y);
    if (b.isZero()) @trap();
    const q = bigBlock(a.limbs.len);
    const r = bigBlock(b.limbs.len + 1);
    const d = root.bigint.divMag(q.limbs, r.limbs, a.limbs, b.limbs);
    if (rem != 0) return finish(r.ptr, a.neg, d.r.len);
    return finish(q.ptr, a.neg != b.neg, d.q.len);
}

/// `-1` / `0` / `1` as `x` is below, equal to or above `y`.
fn bigCompare(x: u32, y: u32) callconv(.c) i32 {
    return root.bigint.cmp(readBig(x), readBig(y));
}

/// `x == y` over two `?bigint`s (the block's address or `0`): both absent,
/// or both present and equal.
fn bigEqualOptional(x: u32, y: u32) callconv(.c) i32 {
    if (x == 0 or y == 0) return @intFromBool(x == y);
    return @intFromBool(root.bigint.cmp(readBig(x), readBig(y)) == 0);
}

/// `BigInt.of(v)`.
fn bigOfI64(v: i64) callconv(.c) u32 {
    const out = bigBlock(2);
    const b = root.bigint.ofI64(out.limbs, v);
    return finish(out.ptr, b.neg, b.limbs.len);
}

/// `x.toI64()` — a value past the `i64` range traps.
fn bigToI64(x: u32) callconv(.c) i64 {
    return root.bigint.toI64(readBig(x)) orelse @trap();
}

/// `x.toF64()` — a value no `f64` holds exactly traps.
fn bigToF64(x: u32) callconv(.c) f64 {
    return root.bigint.toF64(readBig(x)) orelse @trap();
}

/// `x.toString()` — and the text `@print` writes for a `bigint`.
fn bigToString(x: u32) callconv(.c) u32 {
    const a = readBig(x);
    const scratch = bigBlock(a.limbs.len);
    const cap = root.bigint.decimalCapacity(a.limbs);
    const out = blank(cap);
    const text = root.bigint.toDecimal(out.bytes, scratch.limbs, a);
    @as(*u32, @ptrFromInt(out.ptr)).* = @intCast(text.len);
    return out.ptr;
}

/// `BigInt.parse(text)`'s numeral: the value, or `0` (no pointer) for text
/// that spells none.
fn bigParse(s: u32) callconv(.c) u32 {
    const text = arg(s);
    const out = bigBlock(root.bigint.decimalLimbs(text));
    const b = root.bigint.fromDecimal(out.limbs, text) orelse return 0;
    return finish(out.ptr, b.neg, b.limbs.len);
}

/// Each export by its `std:` name — the table the check below reads, and the
/// `@export`s it makes: `root.exports` (bound by `std:` cells) and
/// `root.program` (the wasm codegen's own calls).
const faces = .{
    .{ "hash.contentHash", contentHash },
    .{ "text.trim", trim },
    .{ "text.trimStart", trimStart },
    .{ "text.trimEnd", trimEnd },
    .{ "number.floatToString", floatToString },
    .{ "text.length", length },
    .{ "text.split", split },
    .{ "text.chars", chars },
    .{ "text.lines", lines },
    .{ "text.words", words },
    .{ "text.contains", contains },
    .{ "text.startsWith", startsWith },
    .{ "text.endsWith", endsWith },
    .{ "text.indexOf", indexOf },
    .{ "text.lastIndexOf", lastIndexOf },
    .{ "text.at", at },
    .{ "text.charCodeAt", charCodeAt },
    .{ "text.padStart", padStart },
    .{ "text.padEnd", padEnd },
    .{ "text.repeat", repeat },
    .{ "text.replace", replace },
    .{ "text.replaceAll", replaceAll },
    .{ "text.fromCodepoint", fromCodepoint },
};

const program_faces = .{
    .{ "text.slice", textSlice },
    .{ "number.i32ToString", i32ToString },
    .{ "number.i64ToString", i64ToString },
    .{ "number.u64ToString", u64ToString },
    .{ "number.i64Text", i64Text },
    .{ "number.u64Text", u64Text },
    .{ "array.reverse", reverse },
    .{ "array.slice", arraySlice },
    .{ "array.prepend", prepend },
    .{ "array.concat", concat },
    .{ "array.zip", zip },
    .{ "array.fill", fill },
    .{ "array.joinStrings", joinStrings },
    .{ "array.joinInts", joinInts },
    .{ "array.joinFloats", joinFloats },
    .{ "array.indexOfWord", indexOfWord },
    .{ "array.indexOfString", indexOfString },
    .{ "array.indexOfFloat", indexOfFloat },
    .{ "array.lastIndexOfWord", lastIndexOfWord },
    .{ "array.lastIndexOfString", lastIndexOfString },
    .{ "array.lastIndexOfFloat", lastIndexOfFloat },
    .{ "array.unique", unique },
    .{ "array.flatten", flatten },
    .{ "array.chunked", chunked },
    .{ "array.sliding", sliding },
    .{ "bigint.add", bigAdd },
    .{ "bigint.negate", bigNegate },
    .{ "bigint.multiply", bigMultiply },
    .{ "bigint.divmod", bigDivmod },
    .{ "bigint.compare", bigCompare },
    .{ "bigint.equalOptional", bigEqualOptional },
    .{ "bigint.ofI64", bigOfI64 },
    .{ "bigint.toI64", bigToI64 },
    .{ "bigint.toF64", bigToF64 },
    .{ "bigint.toString", bigToString },
    .{ "bigint.parse", bigParse },
};

/// The wasm type a `root.Type` crosses as.
fn wasmType(t: root.Type) type {
    return switch (t) {
        .string, .string_array, .opt_string => u32,
        .f64 => f64,
        .i32, .bool => i32,
        .i64 => i64,
        .void => void,
    };
}

/// Whether Zig type `z` crosses as the wasm value type `v`.
fn crossesAs(z: type, v: root.Val) bool {
    return switch (v) {
        .i32 => z == u32 or z == i32,
        .i64 => z == i64,
        .f64 => z == f64,
    };
}

comptime {
    // Every entry of `root.exports` and `root.program` is here, under its
    // name, with the signature its types cross as — and nothing else is.
    @setEvalBranchQuota(100_000);
    if (faces.len != root.exports.len) @compileError("wasm.zig exports a different set than root.exports");
    if (program_faces.len != root.program.len) @compileError("wasm.zig exports a different set than root.program");
    for (root.exports) |e| {
        var found = false;
        for (faces) |face| if (std.mem.eql(u8, face[0], e.name)) {
            found = true;
            const info = @typeInfo(@TypeOf(face[1])).@"fn";
            if (info.params.len != e.params.len) @compileError(e.name ++ ": wrong arity");
            for (info.params, e.params) |p, t| if (p.type.? != wasmType(t)) @compileError(e.name ++ ": wrong parameter type");
            if (info.return_type.? != wasmType(e.result)) @compileError(e.name ++ ": wrong result type");
        };
        if (!found) @compileError("std-wasm implements " ++ e.name ++ " but wasm.zig does not export it");
    }
    for (root.program) |e| {
        var found = false;
        for (program_faces) |face| if (std.mem.eql(u8, face[0], e.name)) {
            found = true;
            const info = @typeInfo(@TypeOf(face[1])).@"fn";
            if (info.params.len != e.params.len) @compileError(e.name ++ ": wrong arity");
            for (info.params, e.params) |p, t| if (!crossesAs(p.type.?, t)) @compileError(e.name ++ ": wrong parameter type");
            const r = info.return_type.?;
            if (e.result) |t| {
                if (!crossesAs(r, t)) @compileError(e.name ++ ": wrong result type");
            } else if (r != void) @compileError(e.name ++ ": wrong result type");
        };
        if (!found) @compileError("std-wasm's program face lists " ++ e.name ++ " but wasm.zig does not export it");
    }
    for (faces ++ program_faces) |face| {
        const f = face[1];
        @export(&f, .{ .name = "std:" ++ face[0] });
    }
}
