//! Which comptime runtime this build of the compiler carries — decided by the
//! host it is built for, at compile time (front 18 step 5, the browser build).
//!
//! The BEAM runtime (`persistent_erl.zig`) needs a process the compiler can
//! spawn; a wasm-hosted compiler has none. Every reference to that file in the
//! evaluators sits behind `active == .beam`, which is comptime-false on
//! `wasm32`, so the file is never analysed there and `std.process` never has
//! to resolve. The wat runtime (`persistent_wat.zig`, step 2) is what a browser
//! will run comptime bodies on; until it lands, a build that carries no runtime
//! REFUSES the evaluation with `no_runtime_message` — decision 67: a missing
//! runtime is a located diagnostic, never a silent empty reply.
//!
//! Step 3 (decision 84) turns `active` into a per-target choice between `.beam`
//! and `.wat`; the enum is that step's, declared here so the two evaluators and
//! the executor gate already read one place.
const builtin = @import("builtin");

pub const ComptimeRuntime = enum { beam, wat };

/// Whether this build can spawn a child process: the BEAM runtime's
/// precondition, and the RUN LOG executors' (`codegen/runtime.zig`).
pub const can_spawn: bool = !builtin.cpu.arch.isWasm();

/// The runtime an evaluation runs on in this build; null when the build
/// carries none (a wasm host before step 2).
pub const active: ?ComptimeRuntime = if (can_spawn) .beam else null;

/// What an evaluator answers where `active` is null — the sentence after
/// "the <template|decorator> evaluator has ".
pub const no_runtime_message =
    "no comptime runtime in this build of the compiler: the BEAM runtime needs a process it can spawn, " ++
    "and the wat runtime (front 18 step 2) is not built yet";

test "a native build carries the BEAM runtime" {
    const std = @import("std");
    try std.testing.expect(can_spawn);
    try std.testing.expectEqual(ComptimeRuntime.beam, active.?);
}
