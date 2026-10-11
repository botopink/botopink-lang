//! std `hash`'s host function `contentHash`, in Zig (decision 434 (2)).
const std = @import("std");

pub const Error = error{InvalidUtf8};

/// `hash.contentHash(s)`: djb2 over the code points of UTF-8 `s`, kept to
/// 32 bits (`h = (h * 33 + cp) mod 2^32`, from 5381), written in lowercase
/// hexadecimal without leading zeros — the answer std's `@External.Erlang`
/// template and its `fn:contentHashBody` botopink body both give. Invalid
/// UTF-8 is `error.InvalidUtf8` (OTP's `unicode:characters_to_list/1` raises
/// on it). The text is written into `out` and returned.
pub fn contentHash(out: *[8]u8, s: []const u8) Error![]const u8 {
    var h: u32 = 5381;
    var it = (std.unicode.Utf8View.init(s) catch return error.InvalidUtf8).iterator();
    while (it.nextCodepoint()) |cp| h = h *% 33 +% cp;
    var tmp: [8]u8 = undefined;
    var n: usize = 0;
    var v = h;
    while (true) {
        tmp[n] = "0123456789abcdef"[v & 15];
        n += 1;
        v >>= 4;
        if (v == 0) break;
    }
    for (0..n) |i| out[i] = tmp[n - 1 - i];
    return out[0..n];
}

test "contentHash: the vectors std's two cells answer" {
    const cases = [_]struct { []const u8, []const u8 }{
        .{ "Point", "de553cf" },
        .{ "héllo €", "70c9d2a9" },
        .{ "run", "b88a75a" },
        .{ "build", "f2e56d5" },
        .{ "", "1505" },
    };
    for (cases) |c| {
        var buf: [8]u8 = undefined;
        try std.testing.expectEqualStrings(c[1], try contentHash(&buf, c[0]));
    }
}

test "contentHash: invalid UTF-8 is refused" {
    var buf: [8]u8 = undefined;
    try std.testing.expectError(error.InvalidUtf8, contentHash(&buf, "\xff"));
}
