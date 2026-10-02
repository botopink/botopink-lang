/// The OTP check of every erlang and beam run (decision 228 of 1.0.11-beta).
///
/// The compiler emits Erlang for one release, `manifest.OTP_RELEASE`; the
/// `erl` / `erlc` on `PATH` decide which release the emitted code is checked
/// and run against. A machine on another release than CI once kept the gate
/// green on a module the CI release refuses (`erlang:element(2, C)(9)`, accepted
/// by OTP 29, a syntax error for 28). So before `botopink build | run | test
/// --target erlang | beam` loads a source, it asks compiler-core's one check
/// (`bp.otp`, probed once per process and shared with the comptime node and
/// the RUN LOG executors) and refuses another release — before any `.erl` is
/// written. No flag, variable or manifest value turns the refusal into a
/// warning (decision 67); a manifest's `"otp"` can only name the same release
/// (`manifest.closureOtp`).
const std = @import("std");
const bp = @import("botopink");

/// The release the compiler emits for — the one constant, owned by `manifest`.
pub const RELEASE = bp.otp.RELEASE;

/// Ask the `erl` on `PATH` for its release and compare it with `RELEASE`.
/// False, with the refusal printed, when it differs or cannot be read.
pub fn check(arena: std.mem.Allocator, io: std.Io) !bool {
    _ = arena;
    bp.otp.check(io) catch return false;
    return true;
}
