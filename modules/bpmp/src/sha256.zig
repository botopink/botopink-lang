/// SHA-256 helpers for bpmp's download + sidecar verification path.
///
/// We compute hashes over **file bytes only** — no path prefix, no headers.
/// The sidecar format matches `sha256sum`'s `<64hex>  <path>` shape and the
/// release-pack.sh single-line `<64hex>\n` shape; this module accepts either.
const std = @import("std");

pub const Sha256 = std.crypto.hash.sha2.Sha256;
pub const HEX_LEN = 64;

pub const Error = error{
    HashLengthInvalid,
    HashCharacterInvalid,
    HashMismatch,
} || std.mem.Allocator.Error;

/// Hex-encode `digest` (32 bytes) into a 64-character lowercase string.
pub fn hex(digest: *const [Sha256.digest_length]u8) [HEX_LEN]u8 {
    var out: [HEX_LEN]u8 = undefined;
    const chars = "0123456789abcdef";
    for (digest, 0..) |b, i| {
        out[i * 2] = chars[b >> 4];
        out[i * 2 + 1] = chars[b & 0x0f];
    }
    return out;
}

/// Hash an in-memory buffer.
pub fn hashBytes(data: []const u8) [HEX_LEN]u8 {
    var h = Sha256.init(.{});
    h.update(data);
    var digest: [Sha256.digest_length]u8 = undefined;
    h.final(&digest);
    return hex(&digest);
}

/// Hash the file at `path` by reading it via `io`.
pub fn hashFile(io: std.Io, gpa: std.mem.Allocator, path: []const u8) ![HEX_LEN]u8 {
    const data = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .unlimited);
    defer gpa.free(data);
    return hashBytes(data);
}

/// Extract the leading 64-hex-char digest from a sidecar string. Accepts:
///   - bare `<64hex>` (release-pack.sh)
///   - `<64hex>  <path>` (sha256sum -b / shasum -a 256 output)
/// Trims trailing whitespace / newlines.
pub fn parseSidecar(s: []const u8) Error![HEX_LEN]u8 {
    var trimmed = std.mem.trim(u8, s, " \t\r\n");
    // Drop the trailing `  <path>` form, if present.
    if (std.mem.indexOfScalar(u8, trimmed, ' ')) |sp| trimmed = trimmed[0..sp];
    if (trimmed.len != HEX_LEN) return error.HashLengthInvalid;
    var out: [HEX_LEN]u8 = undefined;
    for (trimmed, 0..) |c, i| {
        switch (c) {
            '0'...'9', 'a'...'f' => out[i] = c,
            'A'...'F' => out[i] = c + 32, // lowercase
            else => return error.HashCharacterInvalid,
        }
    }
    return out;
}

/// Verify `data`'s sha256 against the expected hex digest. Returns the
/// computed digest on success; on mismatch, the caller renders both.
pub fn verify(data: []const u8, expected_hex: []const u8) ![HEX_LEN]u8 {
    const want = try parseSidecar(expected_hex);
    const got = hashBytes(data);
    for (got, 0..) |b, i| if (b != want[i]) return error.HashMismatch;
    return got;
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "hashBytes: known vector for empty input" {
    // sha256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    const got = hashBytes("");
    try testing.expectEqualStrings(
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        &got,
    );
}

test "hashBytes: known vector for \"abc\"" {
    const got = hashBytes("abc");
    try testing.expectEqualStrings(
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        &got,
    );
}

test "parseSidecar: bare 64-hex line" {
    const got = try parseSidecar("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad\n");
    try testing.expectEqualStrings(
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        &got,
    );
}

test "parseSidecar: sha256sum two-column form" {
    const got = try parseSidecar("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  ./file.tar.gz\n");
    try testing.expectEqualStrings(
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        &got,
    );
}

test "parseSidecar: uppercase hex normalised to lowercase" {
    const got = try parseSidecar("BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD");
    try testing.expectEqualStrings(
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        &got,
    );
}

test "parseSidecar: wrong length rejected" {
    try testing.expectError(error.HashLengthInvalid, parseSidecar("abc"));
}

test "parseSidecar: non-hex rejected" {
    try testing.expectError(error.HashCharacterInvalid, parseSidecar(
        "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
    ));
}

test "verify: hit returns the digest" {
    const expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
    const got = try verify("abc", expected);
    try testing.expectEqualStrings(expected, &got);
}

test "verify: mismatch errors" {
    const wrong = "deadbeef00000000000000000000000000000000000000000000000000000000";
    try testing.expectError(error.HashMismatch, verify("abc", wrong));
}
