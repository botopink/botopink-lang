/// rustc-style parse error renderer.
///
/// Example output:
///
///   error: syntax error
///    --> <test>:1:8
///     |
///   1 | wibble = 4
///     |        ^ There must be a 'val' or 'var' to bind a variable to a value
///     |
///     = hint: Use `val <n> = <value>` for bindings.
///
const std = @import("std");

const parser_mod = @import("./parser.zig");
pub const ParseErrorInfo = parser_mod.ParseErrorInfo;
pub const ParseErrorType = parser_mod.ParseErrorType;

// ── Canonical messages ────────────────────────────────────────────────────────

pub const ErrorMessages = struct {
    message: []const u8,
    hint: []const u8,
};

/// Returns the (message, hint) pair for a given parse error.
pub fn errorMessages(info: ParseErrorInfo) ErrorMessages {
    return switch (info.kind) {
        .NoValBinding => .{
            .message = "There must be a 'val' or 'var' to bind a variable to a value",
            .hint = "Use `val <n> = <value>` for bindings.",
        },
        .ReservedWord => .{
            .message = "This is a reserved word and cannot be used as a name",
            .hint = "Choose a different identifier.",
        },
        .UnexpectedToken => .{
            .message = "Unexpected token",
            .hint = "Check the syntax around this position.",
        },
        .OpNakedRight => .{
            .message = "This operator has no value on its right-hand side",
            .hint = "Remove the operator or place a value after it.",
        },
        .ListSpreadWithoutTail => .{
            .message = "A spread here requires a tail list",
            .hint = "Provide a tail, e.g. [1, 2, ..rest]",
        },
        .ListSpreadNotLast => .{
            .message = "Elements cannot appear after a spread",
            .hint = "Lists are singly-linked. Prepend items and reverse when done.",
        },
        .UselessSpread => .{
            .message = "This spread does nothing",
            .hint = "Try prepending elements: [1, 2, ..list]",
        },
    };
}

// ── Main renderer ─────────────────────────────────────────────────────────────

/// Renders a parse error to any `writer` (stderr, ArrayList(u8), etc).
///
/// `source`    — original source text (used to extract the context line).
/// `file_path` — path shown in the header (e.g. "src/main.botopink" or "<test>").
///
/// Output format (gutter = line-number width + 1 space):
///
///   error: <message>
///    --> <file>:<line>:<col>
///   <gutter> |
///   <line>   | <source line>
///   <gutter> | <spaces><carets> <detail>
///   <gutter> |
///   <gutter> = hint: <hint>
///
pub fn render(
    writer: anytype,
    info: ParseErrorInfo,
    source: []const u8,
    file_path: []const u8,
) !void {
    const msgs = errorMessages(info);
    const loc = findLocation(source, info.start);

    // width of the line number, e.g. line 1 -> 1, line 42 -> 2
    const line_w = digitWidth(loc.line);
    // gutter: spaces needed to align "|" with the line number column
    // e.g. "1 | ..." -> gutter=2, so blank gutter lines get 2 spaces before "|"
    const gutter = line_w + 1;

    // "error: syntax error"
    try writer.print("error: syntax error\n", .{});

    // " --> <file>:<line>:<col>"  (gutter-1 spaces before "-->")
    try writePad(writer, gutter - 1);
    try writer.print("--> {s}:{d}:{d}\n", .{ file_path, loc.line, loc.col });

    // "<gutter>|"  — blank line above source
    try writePad(writer, gutter);
    try writer.print("|\n", .{});

    // "<line> | <text>"
    try writer.print("{d} | {s}\n", .{ loc.line, loc.line_text });

    // "<gutter>| <spaces><carets> <message>"
    try writePad(writer, gutter);
    try writer.print("| ", .{});
    const span_len = if (info.end > info.start) info.end - info.start else 1;
    try writePadN(writer, loc.col - 1, ' ');
    try writePadN(writer, span_len, '^');
    try writer.print(" {s}\n", .{msgs.message});

    // "<gutter>|"  — blank line below carets
    try writePad(writer, gutter);
    try writer.print("|\n", .{});

    // "<gutter>= hint: <hint>"
    try writePad(writer, gutter);
    try writer.print("= hint: {s}\n", .{msgs.hint});

    // trailing blank line
    try writer.print("\n", .{});
}

/// Allocating version — renders to a new string. Convenient for snapshot tests.
pub fn renderAlloc(
    allocator: std.mem.Allocator,
    info: ParseErrorInfo,
    source: []const u8,
    file_path: []const u8,
) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(allocator);
    try render(buf.writer(allocator), info, source, file_path);
    return buf.toOwnedSlice(allocator);
}

// ── Internal types and helpers ────────────────────────────────────────────────

const Location = struct {
    line_text: []const u8,
    line: usize, // 1-based
    col: usize, // 1-based
};

fn findLocation(source: []const u8, byte_offset: usize) Location {
    var line: usize = 1;
    var line_start: usize = 0;
    const safe_offset = @min(byte_offset, source.len);

    var i: usize = 0;
    while (i < safe_offset) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }

    var line_end = line_start;
    while (line_end < source.len and source[line_end] != '\n') : (line_end += 1) {}

    const col = safe_offset - line_start + 1;
    return .{
        .line_text = source[line_start..line_end],
        .line = line,
        .col = col,
    };
}

fn digitWidth(n: usize) usize {
    if (n == 0) return 1;
    var w: usize = 0;
    var v = n;
    while (v > 0) : (v /= 10) w += 1;
    return w;
}

fn writePad(writer: anytype, n: usize) !void {
    for (0..n) |_| try writer.writeByte(' ');
}

fn writePadN(writer: anytype, n: usize, ch: u8) !void {
    for (0..n) |_| try writer.writeByte(ch);
}
