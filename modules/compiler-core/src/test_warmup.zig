//! First-thing-to-run pre-warm: trigger the lazy `stdlib_template` init.
//!
//! The template parses + infers `primitives.d.bp` + `builtins.d.bp` +
//! `builtins_fns.d.bp` once per process (~80ms) and is cloned in µs by
//! every `freshEnv`. Without this warmup, the FIRST test to call
//! `freshEnv` pays the whole init cost — visibly distorting `--time-report`
//! (the test that happens to be first sits at ~80ms while everyone else
//! sits at ~200µs).
//!
//! Running this BEFORE the per-area test files moves the cost out of any
//! single test's row. The same getStdlibTemplate call would happen the
//! first time `freshEnv` runs anyway — we just pre-pay it here.

const std = @import("std");
const comptimeMod = @import("./comptime.zig");

test "_warmup: lazy-init the stdlib template once" {
    _ = try comptimeMod.getStdlibTemplate(std.testing.allocator);
}
