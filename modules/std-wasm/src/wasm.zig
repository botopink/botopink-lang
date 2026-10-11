//! std-wasm compiled alone: `zig build std-wasm` → `zig-out/lib/std_wasm.wasm`
//! (wasm32-freestanding, MVP). The C-ABI face of the package over linear
//! memory: a text argument is `(ptr, len)`, a text answer is packed as
//! `ptr << 32 | len` in a `u64` (`0xFFFF_FFFF_FFFF_FFFF` when refused), every
//! answer lives in one bump arena `std_reset` empties. The comptime runtime
//! does not link this file — it compiles the package into its own term
//! library (`root.zig`) — this is the build a `--target wasm` program links
//! (144 B-00e).
const std = @import("std");
const root = @import("root.zig");

const refused: u64 = std.math.maxInt(u64);

var arena_buf: [1 << 16]u8 = undefined;
var arena_used: usize = 0;

/// Room for `len` bytes, or 0 when the arena is full.
export fn std_alloc(len: usize) usize {
    const at = std.mem.alignForward(usize, arena_used, 8);
    if (at + len > arena_buf.len) return 0;
    arena_used = at + len;
    return @intFromPtr(&arena_buf[at]);
}

/// Every answer handed out so far is released.
export fn std_reset() void {
    arena_used = 0;
}

fn pack(s: []const u8) u64 {
    return (@as(u64, @intFromPtr(s.ptr)) << 32) | s.len;
}

fn arg(ptr: [*]const u8, len: usize) []const u8 {
    return ptr[0..len];
}

/// `hash.contentHash`.
export fn std_hash_contentHash(ptr: [*]const u8, len: usize) u64 {
    const at = std_alloc(8);
    if (at == 0) return refused;
    const out: *[8]u8 = @ptrFromInt(at);
    const h = root.hash.contentHash(out, arg(ptr, len)) catch return refused;
    return pack(h);
}

/// `String.toUpper` (`upper` 1) / `toLower` (0) — ASCII; refused otherwise.
export fn std_text_caseMap(ptr: [*]const u8, len: usize, upper: u32) u64 {
    const at = std_alloc(len);
    if (at == 0 and len > 0) return refused;
    const out: [*]u8 = @ptrFromInt(if (len == 0) @intFromPtr(&arena_buf) else at);
    const r = root.text.caseMap(out[0..len], arg(ptr, len), upper != 0) catch return refused;
    return pack(r);
}

/// `String.trim` (`dir` 2), `trimStart` (0), `trimEnd` (1).
export fn std_text_trim(ptr: [*]const u8, len: usize, dir: u32) u64 {
    const d: root.text.TrimDir = switch (dir) {
        0 => .leading,
        1 => .trailing,
        2 => .both,
        else => return refused,
    };
    return pack(root.text.trim(arg(ptr, len), d));
}

/// `Float.toString`.
export fn std_number_floatToString(f: f64) u64 {
    const at = std_alloc(64);
    if (at == 0) return refused;
    const out: *[64]u8 = @ptrFromInt(at);
    return pack(root.number.shortFloat(f, out));
}
