//! Shared test harness for the format stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");

pub fn assertFormat(allocator: Allocator, src: []const u8) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const actual = try formatMod.format(allocator, program);
    defer allocator.free(actual);

    const want = std.mem.trim(u8, src, "\n\r");
    const got = std.mem.trim(u8, actual, "\n\r");

    if (std.mem.eql(u8, want, got)) return;

    // Line-by-line diff
    var expLines: std.ArrayList([]const u8) = .empty;
    defer expLines.deinit(allocator);
    var actLines: std.ArrayList([]const u8) = .empty;
    defer actLines.deinit(allocator);

    var it = std.mem.splitScalar(u8, want, '\n');
    while (it.next()) |ln| try expLines.append(allocator, ln);
    it = std.mem.splitScalar(u8, got, '\n');
    while (it.next()) |ln| try actLines.append(allocator, ln);

    const maxLen = @max(expLines.items.len, actLines.items.len);
    std.debug.print("\n-- format output mismatch ------------------------------\n", .{});
    std.debug.print("{s:>4}  {s:<50}  {s}\n", .{ "line", "expected", "actual" });
    for (0..maxLen) |i| {
        const e = if (i < expLines.items.len) expLines.items[i] else "<missing>";
        const a = if (i < actLines.items.len) actLines.items[i] else "<missing>";
        const marker: u8 = if (std.mem.eql(u8, e, a)) ' ' else '!';
        std.debug.print("{d:>4}{c} -{s}\n     +{s}\n", .{ i + 1, marker, e, a });
    }
    std.debug.print("--------------------------------------------------------\n\n", .{});
    return error.TestOutputMismatch;
}

/// `format(parse(src))` equals `expected` — for sources that are not in
/// canonical form (a trailing comma to add, a list to open).
pub fn assertFormatAs(allocator: Allocator, src: []const u8, expected: []const u8) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);
    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);
    const actual = try formatMod.format(allocator, program);
    defer allocator.free(actual);
    try std.testing.expectEqualStrings(std.mem.trim(u8, expected, "\n\r"), std.mem.trim(u8, actual, "\n\r"));
}

/// `format` twice gives the same text — **and** the first pass lost no token.
///
/// The two are asserted together on purpose. Idempotence alone is satisfied by a
/// formatter that deletes every comment in the file: the deletion happens once
/// and pass 2 agrees with pass 1. Pairing them here makes that impossible to
/// pass again, for every case in this directory that uses the round trip.
pub fn assertIdempotent(allocator: Allocator, src: []const u8) !void {
    try assertLossless(allocator, src);
    const pass1 = blk: {
        var l = lexerMod.Lexer.init(src);
        const tokens = try l.scanAll(allocator);
        defer l.deinit(allocator);
        var p = parserMod.Parser.init(tokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(pass1);

    const pass2 = blk: {
        var l = lexerMod.Lexer.init(pass1);
        const tokens = try l.scanAll(allocator);
        defer l.deinit(allocator);
        var p = parserMod.Parser.init(tokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(pass2);

    if (!std.mem.eql(u8, pass1, pass2)) {
        std.debug.print(
            "\n-- formatter is not idempotent --\n-- pass 1 --\n{s}\n-- pass 2 --\n{s}\n",
            .{ pass1, pass2 },
        );
        return error.NotIdempotent;
    }
}

// ── losslessness ─────────────────────────────────────────────────────────────

/// Token kinds the canonical form is allowed to **add or drop**, and which
/// therefore take no part in `assertLossless`. The list is written out rather
/// than derived so that the exemption is reviewable: every one of them is a
/// separator, none of them carries a name, and a formatter that dropped
/// anything else would be losing program text.
///
/// | kind | why the canonical form may move it |
/// |---|---|
/// | `;` | a single-statement `if` branch prints bare, a block-shaped statement's terminator is the brace |
/// | `,` | a trailing comma is added to an open list and removed from a compact one |
/// | `{` `}` | a single-statement `if`/`else` branch loses its braces; an empty body gains `{}` |
const droppable_separators = [_]lexerMod.TokenKind{ .semicolon, .comma, .leftBrace, .rightBrace };

fn isDroppableSeparator(kind: lexerMod.TokenKind) bool {
    for (droppable_separators) |k| if (k == kind) return true;
    return false;
}

fn isComment(kind: lexerMod.TokenKind) bool {
    return kind == .commentNormal or kind == .commentDoc or kind == .commentModule;
}

fn isString(kind: lexerMod.TokenKind) bool {
    return kind == .stringLiteral or kind == .multilineStringLiteral;
}

/// The part of a token's text that carries meaning, for the comparison below.
///
/// Two spellings are normalised away, because the canonical form chooses
/// between them and neither choice loses anything:
///
/// - a comment's marker and its surrounding blanks (`//warm` and `// warm` are
///   the same comment; re-spacing one is not a deletion);
/// - a string's delimiters (`"a"` and `"""a"""` are the same string — the
///   formatter picks the triple form when the content spans lines or holds a
///   `"`).
fn tokenText(t: lexerMod.Token) []const u8 {
    if (isComment(t.kind)) {
        return std.mem.trim(u8, std.mem.trimStart(u8, t.lexeme, "/"), " \t\r\n");
    }
    if (isString(t.kind)) {
        var s = t.lexeme;
        if (std.mem.startsWith(u8, s, "\"\"\"") and s.len >= 6) {
            s = s[3 .. s.len - 3];
        } else if (std.mem.startsWith(u8, s, "\"") and s.len >= 2) {
            s = s[1 .. s.len - 1];
        }
        return std.mem.trim(u8, s, " \t\r\n");
    }
    return t.lexeme;
}

/// The pre-1.0.3 **binding** form of a declaration —
/// `val Name = behavior { … };` / `val Name = type { … };` — prints as the 1.0.3
/// declaration `behavior Name { … }`, which has no `val` and no `=`. Those two
/// tokens are syntax of the form being translated, not text of the program, so
/// they are exempt — but only in that exact shape: a `val` anywhere else is a
/// binding whose loss would be a real one, and the check must still say so.
///
/// Returns the indices of the `val` and the `=` when `tokens[i]` opens the form.
fn oldSurfaceBindingAt(tokens: []const lexerMod.Token, i: usize) ?[2]usize {
    if (tokens[i].kind != .val) return null;
    if (i + 3 >= tokens.len) return null;
    if (tokens[i + 1].kind != .identifier) return null;
    if (tokens[i + 2].kind != .equal) return null;
    return switch (tokens[i + 3].kind) {
        .behavior, .type, .interface, .record, .@"enum" => .{ i, i + 2 },
        else => null,
    };
}

/// The indices of every token the source may spend without the output paying for
/// it: the `val` and `=` of each pre-1.0.3 binding form. Caller owns the result.
fn oldSurfaceExemptions(allocator: Allocator, tokens: []const lexerMod.Token) !std.DynamicBitSetUnmanaged {
    var set = try std.DynamicBitSetUnmanaged.initEmpty(allocator, tokens.len);
    for (0..tokens.len) |i| {
        if (oldSurfaceBindingAt(tokens, i)) |pair| {
            set.set(pair[0]);
            set.set(pair[1]);
        }
    }
    return set;
}

fn lexAll(allocator: Allocator, src: []const u8, out: *lexerMod.Lexer) ![]const lexerMod.Token {
    out.* = lexerMod.Lexer.init(src);
    return out.scanAll(allocator);
}

/// The comparison key for one token: the class it belongs to, then its
/// meaningful text. Two tokens share a key exactly when the canonical form is
/// allowed to print either one for the other.
fn tokenKey(allocator: Allocator, t: lexerMod.Token) ![]u8 {
    const class: u8 = if (isComment(t.kind)) 'c' else if (isString(t.kind)) 's' else 'k';
    const tag = if (class == 'k') @tagName(t.kind) else "";
    return std.fmt.allocPrint(allocator, "{c}\x00{s}\x00{s}", .{ class, tag, tokenText(t) });
}

/// **Nothing the source says is missing from the output.**
///
/// The formatter's other two properties do not imply this one, which is how a
/// deletion survived 239 tests:
///
/// - `assertFormat` compares the output against a text a human wrote, so it only
///   ever sees the cases somebody thought to write down;
/// - `assertIdempotent` compares pass 2 against pass 1, and **a deletion is
///   idempotent** — format a file that has lost a comment and it stays lost, so
///   `format --check` reports it clean.
///
/// Stated as *containment*, over the whole token stream: every token of the
/// source occurs in the output at least as many times, modulo
/// `droppable_separators`. Additions are allowed on purpose — the canonical form
/// splits `#[a, b]` into two annotations and adds a trailing comma — because
/// what makes a formatter unsafe is losing text, not producing it.
///
/// **Order is deliberately not asserted**, and the reason was measured rather
/// than assumed: the formatter translates the pre-1.0.3 spellings, and each
/// translation *moves* a token rather than dropping one —
/// `val D = behavior { … };` → `behavior D { … }` carries the name past the
/// keyword, and `fn f(s comptime: string)` → `fn f(comptime s: string)` carries
/// the marker past the name. An ordered subsequence check fails on all five such
/// cases in `idempotent.zig` while nothing at all has been lost. A *move* is a
/// layout question and `assertFormat`'s expected text already pins it; a
/// *deletion* is a soundness question, and that is this property.
///
/// Defined over the **whole** token stream rather than over comments alone: the
/// deletion that motivated it was the `default` keyword of `pub default mod`,
/// which a comment-only property would have missed.
pub fn assertLossless(allocator: Allocator, src: []const u8) !void {
    var srcLexer: lexerMod.Lexer = undefined;
    const srcTokens = try lexAll(allocator, src, &srcLexer);
    defer srcLexer.deinit(allocator);

    const formatted = blk: {
        var p = parserMod.Parser.init(srcTokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(formatted);

    var outLexer: lexerMod.Lexer = undefined;
    const outTokens = try lexAll(allocator, formatted, &outLexer);
    defer outLexer.deinit(allocator);

    // Tally the output, then draw the source's tokens from it; a token the tally
    // cannot pay for is one the formatter did not print.
    var have: std.StringHashMapUnmanaged(usize) = .empty;
    defer {
        var it = have.keyIterator();
        while (it.next()) |k| allocator.free(k.*);
        have.deinit(allocator);
    }
    for (outTokens) |t| {
        if (t.kind == .endOfFile or isDroppableSeparator(t.kind)) continue;
        const key = try tokenKey(allocator, t);
        const gop = try have.getOrPut(allocator, key);
        if (gop.found_existing) {
            allocator.free(key);
            gop.value_ptr.* += 1;
        } else gop.value_ptr.* = 1;
    }

    var exempt = try oldSurfaceExemptions(allocator, srcTokens);
    defer exempt.deinit(allocator);

    for (srcTokens, 0..) |want, i| {
        if (want.kind == .endOfFile or isDroppableSeparator(want.kind)) continue;
        if (exempt.isSet(i)) continue;
        const key = try tokenKey(allocator, want);
        defer allocator.free(key);
        const slot = have.getPtr(key);
        if (slot != null and slot.?.* > 0) {
            slot.?.* -= 1;
            continue;
        }
        std.debug.print(
            \\
            \\-- the formatter lost a token ---------------------------------
            \\missing: {s} [{s}]  (source line {d}, column {d})
            \\-- source --
            \\{s}
            \\-- output --
            \\{s}
            \\---------------------------------------------------------------
            \\
        , .{ @tagName(want.kind), want.lexeme, want.line, want.col, src, formatted });
        return error.FormatterLostAToken;
    }
}

/// `assertFormat` **and** `assertLossless` — the round trip a case in canonical
/// form should satisfy. Prefer it to `assertFormat` alone for anything carrying
/// a comment or a keyword that only one declaration form uses.
pub fn assertFormatLossless(allocator: Allocator, src: []const u8) !void {
    try assertFormat(allocator, src);
    try assertLossless(allocator, src);
}
