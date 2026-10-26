//! Decision 518 — the host features a wasm program needs, as the program
//! carries them: the custom section `botopink.needs`, the needs' names
//! (`ast.WasmNeed`: `exceptions`, `http`, `gc`) one per line, which `wat.zig` writes
//! from the `needs:` of the bindings the program reaches and links. The
//! runners read it back — `needsOf` from the binary (`codegen/runtime.zig`'s
//! RUN LOG), `needsOfText` from a `wasi` build's component text
//! (`botopink run` / `test`) — and hand the host only the
//! matching flags (`wasmtimeArgs`). A program needing none carries no
//! section and runs with no flag; node runs exceptions by default.

const std = @import("std");
const ast = @import("../../ast.zig");

const Need = ast.WasmNeed;
const Needs = ast.WasmNeeds;

/// The most flags `wasmtimeArgs` answers: two per need.
pub const max_args = 2 * std.enums.values(Need).len;

/// `wasmtime run`'s flags for `needs`, in a fixed order: `-W exceptions=y`
/// for `exceptions`, `-S http` for `http`, `-W gc=y` for `gc` (WasmGC, front
/// 164 s2 — every program that emits GC types).
pub fn wasmtimeArgs(needs: Needs, buf: *[max_args][]const u8) []const []const u8 {
    var n: usize = 0;
    if (needs.contains(.exceptions)) {
        buf[n] = "-W";
        buf[n + 1] = "exceptions=y";
        n += 2;
    }
    if (needs.contains(.http)) {
        buf[n] = "-S";
        buf[n + 1] = "http";
        n += 2;
    }
    if (needs.contains(.gc)) {
        buf[n] = "-W";
        buf[n + 1] = "gc=y";
        n += 2;
    }
    return buf[0..n];
}

/// Decision 518 — the custom section a wasm program names the host features
/// it needs in: their names (`Need`, `exceptions` / `http`), one per
/// line. `needsOf` reads it back from the binary, `needsOfText` from the
/// text a `wasi` build writes.
pub const section = "botopink.needs";

/// The needs a `.wasm` binary's `botopink.needs` section names; empty when it
/// has none (or the bytes are no module).
pub fn needsOf(bytes: []const u8) Needs {
    var set = Needs.initEmpty();
    if (bytes.len < 8 or !std.mem.eql(u8, bytes[0..4], "\x00asm")) return set;
    var i: usize = 8;
    while (i < bytes.len) {
        const id = bytes[i];
        i += 1;
        const size = readUleb(bytes, &i) orelse return set;
        if (i + size > bytes.len) return set;
        const body = bytes[i .. i + size];
        i += size;
        if (id != 0) continue;
        var j: usize = 0;
        const n = readUleb(body, &j) orelse continue;
        if (j + n > body.len) continue;
        if (!std.mem.eql(u8, body[j .. j + n], section)) continue;
        addNeeds(&set, body[j + n ..]);
    }
    return set;
}

/// The needs a wasm text names in its `(@custom "botopink.needs" "…")`
/// annotation (a `wasi` build's component text); empty when it has none.
pub fn needsOfText(text: []const u8) Needs {
    var set = Needs.initEmpty();
    const head = "(@custom \"" ++ section ++ "\" \"";
    const at = std.mem.indexOf(u8, text, head) orelse return set;
    const rest = text[at + head.len ..];
    const end = std.mem.indexOfScalar(u8, rest, '"') orelse return set;
    // The text escapes each newline as `\0a`.
    var buf: [256]u8 = undefined;
    var n: usize = 0;
    var k: usize = 0;
    const raw = rest[0..end];
    while (k < raw.len and n < buf.len) : (n += 1) {
        if (raw[k] == '\\' and k + 2 < raw.len) {
            buf[n] = std.fmt.parseInt(u8, raw[k + 1 .. k + 3], 16) catch return set;
            k += 3;
        } else {
            buf[n] = raw[k];
            k += 1;
        }
    }
    addNeeds(&set, buf[0..n]);
    return set;
}

fn addNeeds(set: *Needs, payload: []const u8) void {
    var lines = std.mem.tokenizeScalar(u8, payload, '\n');
    while (lines.next()) |l| {
        if (std.meta.stringToEnum(Need, l)) |need| set.insert(need);
    }
}

fn readUleb(bytes: []const u8, i: *usize) ?usize {
    var result: usize = 0;
    var shift: u6 = 0;
    while (i.* < bytes.len) {
        const b = bytes[i.*];
        i.* += 1;
        result |= @as(usize, b & 0x7f) << shift;
        if (b & 0x80 == 0) return result;
        if (shift >= 56) return null;
        shift += 7;
    }
    return null;
}

test "needs: the section read back from the binary and from the text" {
    const bin = [_]u8{ 0x00, 'a', 's', 'm', 0x01, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x0e } ++ "botopink.needs".* ++ "exceptions\n".*;
    try std.testing.expect(needsOf(&bin).contains(.exceptions));
    try std.testing.expect(!needsOf(&bin).contains(.http));
    const text = "  (@custom \"botopink.needs\" \"exceptions\\0ahttp\\0a\")\n";
    const got = needsOfText(text);
    try std.testing.expect(got.contains(.exceptions) and got.contains(.http));
    try std.testing.expectEqual(@as(usize, 0), needsOfText("(module)").count());
    var buf: [max_args][]const u8 = undefined;
    try std.testing.expectEqual(@as(usize, 4), wasmtimeArgs(got, &buf).len);
    var all = Needs.initFull();
    const flags = wasmtimeArgs(all, &buf);
    try std.testing.expectEqual(@as(usize, 6), flags.len);
    try std.testing.expectEqualStrings("gc=y", flags[5]);
    all.remove(.gc);
    try std.testing.expectEqual(@as(usize, 4), wasmtimeArgs(all, &buf).len);
    try std.testing.expectEqual(@as(usize, 0), wasmtimeArgs(Needs.initEmpty(), &buf).len);
}
