//! std-wasm — std's host functions in Zig, compiled to wasm (decision 434 (2)).
//!
//! What a std function reached at comptime answers, whatever the build's
//! target (434 (5)): the comptime runtime (wasm3 in-process,
//! `compiler-core/src/comptime/runtime/wat/`) is compiled with this package —
//! `rt.zig`, the term library a lowered comptime module links against,
//! imports it, so the runtime's `.wasm` (`bp_wat_rt.wasm`) carries it — and
//! serves:
//!
//! - **the std functions in `functions`** whole: a host function std
//!   declares (`hash.contentHash`) is called as the runtime export
//!   `rt_std_<module>__<name>` instead of either of its cells, so it needs no
//!   per-binding `@External.Wasm` cell at comptime;
//! - **the text and number algorithms** behind the OTP calls the comptime
//!   module's primitive methods make (`string:uppercase/1`, `string:trim/1,2`,
//!   `string:split/2,3`, `binary:replace/3,4`, `float_to_binary/2` …): the
//!   runtime's BIF answers through `text` and `number`.
//!
//! Everything here is pure — no term layout, no allocation of its own — so
//! the same code is linked into a `--target wasm` program (144 B-00e). Each
//! function has a Zig unit test; `zig build std-wasm` compiles the package
//! alone to `zig-out/lib/std_wasm.wasm` (`wasm.zig`'s exports).
const std = @import("std");

pub const hash = @import("hash.zig");
pub const text = @import("text.zig");
pub const number = @import("number.zig");

/// A std function std-wasm serves whole at comptime.
pub const Function = struct {
    /// The std module (`hash`, `io/fs`) and the function's name and arity.
    module: []const u8,
    name: []const u8,
    arity: u8,
    /// The symbol a comptime module calls it by, in the Erlang module
    /// `erlang_module`: the module path with `/` → `_`, two underscores, the
    /// name (`hash__contentHash`). The comptime runtime's export that answers
    /// it is `"rt_std_" ++ symbol`.
    symbol: []const u8,
};

/// The Erlang module name a comptime module's call to a std-wasm function is
/// written under (`bp_std_wasm:hash__contentHash(S)`); the comptime runtime's
/// lowering maps each to `Function.runtimeExport`.
pub const erlang_module = "bp_std_wasm";

/// Every std function served whole — the measured list (144 B-00a,
/// `AGENTS.md` § Measured): the bodyless std host functions a comptime
/// evaluation reaches today.
pub const functions = [_]Function{
    .{ .module = "hash", .name = "contentHash", .arity = 1, .symbol = "hash__contentHash" },
};

/// The function std module `module` declares as `name/arity`, when std-wasm
/// serves it.
pub fn find(module: []const u8, name: []const u8, arity: usize) ?Function {
    for (functions) |f| {
        if (f.arity == arity and std.mem.eql(u8, f.module, module) and std.mem.eql(u8, f.name, name)) return f;
    }
    return null;
}

test {
    _ = hash;
    _ = text;
    _ = number;
}

test "find: the served functions by module, name and arity" {
    const f = find("hash", "contentHash", 1) orelse return error.TestExpectedFunction;
    try std.testing.expectEqualStrings("hash", f.module);
    try std.testing.expect(find("hash", "contentHash", 2) == null);
    try std.testing.expect(find("hash", "sha256", 1) == null);
}

test "every symbol is its module path, two underscores, its name" {
    for (functions) |f| {
        var buf: [128]u8 = undefined;
        const want = try std.fmt.bufPrint(&buf, "{s}__{s}", .{ f.module, f.name });
        std.mem.replaceScalar(u8, want, '/', '_');
        try std.testing.expectEqualStrings(want, f.symbol);
    }
}
