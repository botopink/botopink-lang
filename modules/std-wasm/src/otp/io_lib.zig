//! `io_lib:format/2` (`~p`, `~w`, `~s`, `~n`, `~~`; `~p` without OTP's
//! 80-column line breaking), `io:format/1,2` into a buffer of the module
//! (`rt_printed`), and `rt_describe` — an exception as `Class:Reason`.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const math = @import("math.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;
const Fun = term.Fun;

// ── io_lib:format ~p / ~w / ~s ──────────────────────────────────────────────

fn needsQuote(name: []const u8) bool {
    if (name.len == 0) return true;
    if (!(name[0] >= 'a' and name[0] <= 'z')) return true;
    for (name[1..]) |c| if (!(std.ascii.isAlphanumeric(c) or c == '_' or c == '@')) return true;
    // One string, not a table of slices (pointers in the module's data).
    return term.wordIndex(" after and andalso band begin bnot bor bsl bsr bxor case catch cond div end fun if let maybe not of or orelse receive rem try when xor else ", name) != null;
}

fn writeAtomText(bb: T, name: []const u8) void {
    if (!needsQuote(name)) return term.bbPush(bb, name);
    term.bbPush(bb, "'");
    for (name) |c| {
        if (c == '\'' or c == '\\') term.bbPush(bb, "\\");
        term.bbPush(bb, &.{c});
    }
    term.bbPush(bb, "'");
}

fn printableLatin1(c: i64) bool {
    return (c >= 32 and c <= 126) or (c >= 160 and c <= 255) or c == '\n' or c == '\r' or c == '\t' or c == 11 or c == 8 or c == 12 or c == 27 or c == 7;
}

fn printableUnicode(c: i64) bool {
    return printableLatin1(c) or (c > 255 and c <= 0x10FFFF and !(c >= 0xD800 and c <= 0xDFFF) and c != 0xFFFE and c != 0xFFFF);
}

/// The letter `~p` escapes control character `c` with (`\n` → `n`), or 0.
/// A byte, never a string: a switch over strings compiles to a table of
/// pointers in the module's data, which `std_wasm_link.zig` refuses.
fn escapeLetter(c: i64) u8 {
    return switch (c) {
        '\n' => 'n',
        '\r' => 'r',
        '\t' => 't',
        11 => 'v',
        8 => 'b',
        12 => 'f',
        27 => 'e',
        7 => 'd',
        '\\' => '\\',
        else => 0,
    };
}

fn writeEscapedChar(bb: T, c: i64, quote: u8) void {
    switch (escapeLetter(c)) {
        0 => {
            if (c == quote) {
                term.bbPush(bb, "\\");
                term.bbPush(bb, &.{quote});
            } else {
                var buf: [4]u8 = undefined;
                const n = std.unicode.utf8Encode(@intCast(c), &buf) catch 0;
                term.bbPush(bb, buf[0..n]);
            }
        },
        else => |letter| term.bbPush(bb, &.{ '\\', letter }),
    }
}

/// A printable char list (the `~p` "string" test, unicode range).
fn isPrintableList(t: T) bool {
    if (term.tagOf(t) != .cons) return false;
    var it = t;
    while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
        const h = term.as(term.Cons, it).head;
        if (term.tagOf(h) != .int or !printableUnicode(term.as(term.Int, h).value)) return false;
    }
    return term.tagOf(it) == .nil;
}

/// Write `t` as `~p` / `~w` do, without the line breaking `~p` applies past
/// 80 columns.
fn writeTerm(bb: T, t: T, pretty: bool) void {
    switch (term.tagOf(t)) {
        .int => {
            var buf: [24]u8 = undefined;
            term.bbPush(bb, erlang.intText(term.as(term.Int, t).value, &buf));
        },
        .float => {
            var buf: [64]u8 = undefined;
            term.bbPush(bb, term.shortFloat(term.as(term.Float, t).value, &buf));
        },
        .atom => writeAtomText(bb, term.atomBytes(t)),
        .binary => {
            const s = term.binBytes(t);
            var ascii = true;
            for (s) |c| if (!printableLatin1(c) or c >= 128) {
                ascii = false;
                break;
            };
            if (pretty and ascii) {
                term.bbPush(bb, "<<\"");
                for (s) |c| writeEscapedChar(bb, c, '"');
                term.bbPush(bb, "\">>");
                return;
            }
            if (pretty and std.unicode.utf8ValidateSlice(s)) {
                var ok = true;
                var view = std.unicode.Utf8View.initUnchecked(s).iterator();
                while (view.nextCodepoint()) |cp| if (!printableUnicode(cp)) {
                    ok = false;
                    break;
                };
                if (ok and s.len > 0) {
                    term.bbPush(bb, "<<\"");
                    view = std.unicode.Utf8View.initUnchecked(s).iterator();
                    while (view.nextCodepoint()) |cp| writeEscapedChar(bb, cp, '"');
                    term.bbPush(bb, "\"/utf8>>");
                    return;
                }
            }
            term.bbPush(bb, "<<");
            for (s, 0..) |c, i| {
                if (i > 0) term.bbPush(bb, ",");
                var buf: [4]u8 = undefined;
                term.bbPush(bb, erlang.intText(c, &buf));
            }
            term.bbPush(bb, ">>");
        },
        .nil => term.bbPush(bb, "[]"),
        .cons => {
            if (pretty and isPrintableList(t)) {
                term.bbPush(bb, "\"");
                var it = t;
                while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) writeEscapedChar(bb, term.as(term.Int, term.as(term.Cons, it).head).value, '"');
                term.bbPush(bb, "\"");
                return;
            }
            term.bbPush(bb, "[");
            var it = t;
            var first = true;
            while (term.tagOf(it) == .cons) : (it = term.as(term.Cons, it).tail) {
                if (!first) term.bbPush(bb, ",");
                first = false;
                writeTerm(bb, term.as(term.Cons, it).head, pretty);
            }
            if (term.tagOf(it) != .nil) {
                term.bbPush(bb, "|");
                writeTerm(bb, it, pretty);
            }
            term.bbPush(bb, "]");
        },
        .tuple => {
            const tp = term.as(term.Tuple, t);
            term.bbPush(bb, "{");
            for (0..tp.arity) |i| {
                if (i > 0) term.bbPush(bb, ",");
                writeTerm(bb, tp.items[i], pretty);
            }
            term.bbPush(bb, "}");
        },
        .map => {
            const m = term.as(term.Map, t);
            const order_idx = term.sortedKeys(m);
            term.bbPush(bb, "#{");
            for (order_idx, 0..) |k, i| {
                if (i > 0) term.bbPush(bb, ",");
                writeTerm(bb, m.keys[k], pretty);
                term.bbPush(bb, " => ");
                writeTerm(bb, m.vals[k], pretty);
            }
            term.bbPush(bb, "}");
        },
        .fun => term.bbPush(bb, "#Fun<bp_wat>"),
        .builder => term.bbPush(bb, "<<>>"),
    }
}

/// `io_lib:format(Format, Args)` for the directives the comptime bodies use:
/// `~p`, `~w`, `~s`, `~ts`, `~n`, `~~`. Answers a code-point list, as OTP does.
pub fn rt_io_lib_format(fmt: T, args: T) callconv(.c) term.T {
    const f = string.chardata(fmt) orelse return term.badarg();
    const items = term.listArg(args) orelse return &term.nil_cell;
    const bb = term.rt_bb_new();
    var ai: usize = 0;
    var i: usize = 0;
    while (i < f.len) : (i += 1) {
        const c = f[i];
        if (c != '~') {
            term.bbPush(bb, &.{c});
            continue;
        }
        i += 1;
        if (i >= f.len) return term.badarg();
        var d = f[i];
        if (d == 't' and i + 1 < f.len) {
            i += 1;
            d = f[i];
        }
        switch (d) {
            'n' => term.bbPush(bb, "\n"),
            '~' => term.bbPush(bb, "~"),
            'p', 'w' => {
                if (ai >= items.len) return term.badarg();
                writeTerm(bb, items[ai], d == 'p');
                ai += 1;
            },
            's' => {
                if (ai >= items.len) return term.badarg();
                const a = items[ai];
                ai += 1;
                if (term.tagOf(a) == .atom) term.bbPush(bb, term.atomBytes(a)) else {
                    const s = string.chardata(a) orelse return term.badarg();
                    term.bbPush(bb, s);
                }
            },
            else => {
                term.raiseWat("io_lib:format directive other than ~p ~w ~s ~n ~~");
                return &term.nil_cell;
            },
        }
    }
    if (ai != items.len) return term.badarg();
    return erlang.utf8Chars(term.binBytes(term.rt_bb_end(bb)));
}

/// What a body printed (`io:format`), kept in the module's memory — never on
/// the compiler's stdout; they are captured and dropped with the instance.
pub var printed: ?term.T = null;

fn printBuffer() term.T {
    if (printed) |b| return b;
    const b = term.rt_bb_new();
    printed = b;
    return b;
}

/// `io:format(Format, Args)`.
pub fn rt_io_format(fmt: T, args: T) callconv(.c) term.T {
    const chars = rt_io_lib_format(fmt, args);
    if (term.pending) return &term.nil_cell;
    const bytes = string.chardata(chars) orelse return term.badarg();
    term.bbPush(printBuffer(), bytes);
    return term.a_ok;
}

/// `io:format(Format)`.
pub fn rt_io_format1(fmt: T) callconv(.c) term.T {
    return rt_io_format(fmt, &term.nil_cell);
}

/// The captured prints (the host may read them for a diagnostic).
pub fn rt_printed() callconv(.c) term.T {
    return term.rt_bb_end(printBuffer());
}

/// `Class:Reason`, each as `~p` writes it — the runtime error an exception out
/// of `main` is reported as.
pub fn rt_describe(class: T, reason: T) callconv(.c) term.T {
    const bb = term.rt_bb_new();
    writeTerm(bb, class, true);
    term.bbPush(bb, ":");
    writeTerm(bb, reason, true);
    return term.rt_bb_end(bb);
}
