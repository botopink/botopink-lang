//! `zig build gen-unicode` (decisions 333 (A), 443): builds `main.zig` for the
//! host and runs it over this directory, rewriting `libs/std/src/unicode_tables.bp`
//! and std-wasm's case tables, `modules/std-wasm/src/case_tables.zig`.
//! Root `build.zig` registers it with one line (`addStep(b)`); nothing else of
//! the build depends on it — the generated file is committed, and `zig build`
//! embeds it like every other std module.

const std = @import("std");

pub fn addStep(b: *std.Build) void {
    const gen = b.addExecutable(.{
        .name = "unicode-gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("libs/std/tools/unicode-gen/main.zig"),
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
        }),
    });
    const run = b.addRunArtifact(gen);
    run.setCwd(b.path("."));
    run.addArgs(&.{ "libs/std/tools/unicode-gen", "libs/std/src/unicode_tables.bp", "modules/std-wasm/src/case_tables.zig" });
    run.has_side_effects = true; // writes into the source tree — never cached
    const step = b.step("gen-unicode", "Regenerate libs/std/src/unicode_tables.bp and modules/std-wasm/src/case_tables.zig from the pinned Unicode data (libs/std/tools/unicode-gen)");
    step.dependOn(&run.step);
}
