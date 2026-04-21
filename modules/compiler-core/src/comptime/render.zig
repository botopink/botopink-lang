/// Diagnostic and source-text rendering utilities.
/// Used by error reporting — not tied to any specific runtime backend.
const std = @import("std");

/// Return the text of line `lineNum` (1-based) from `src`.
pub fn extractLine(src: []const u8, lineNum: usize) []const u8 {
    var line: usize = 1;
    var start: usize = 0;
    for (src, 0..) |c, i| {
        if (c == '\n') {
            if (line == lineNum) return src[start..i];
            line += 1;
            start = i + 1;
        }
    }
    return if (line == lineNum) src[start..] else "";
}

/// Write `n` space characters to `writer`.
pub fn padSpaces(writer: anytype, n: usize) !void {
    for (0..n) |_| try writer.writeByte(' ');
}

/// Return the number of decimal digits in `n` (minimum 1).
pub fn digitWidth(n: usize) usize {
    if (n == 0) return 1;
    var w: usize = 0;
    var v = n;
    while (v > 0) : (v /= 10) w += 1;
    return w;
}
