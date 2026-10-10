//! `zig build gen-unicode` (decision 333 (A)): builds `main.zig` for the host
//! and runs it over this directory, rewriting `libs/std/src/unicode_tables.bp`.
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
    run.addArgs(&.{ "libs/std/tools/unicode-gen", "libs/std/src/unicode_tables.bp" });
    run.has_side_effects = true; // writes into the source tree — never cached
    const step = b.step("gen-unicode", "Regenerate libs/std/src/unicode_tables.bp from the pinned Unicode data (libs/std/tools/unicode-gen)");
    step.dependOn(&run.step);
}
