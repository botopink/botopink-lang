const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── Executable ──────────────────────────────────────────────────────────────
    // Fully self-contained — it shells out to the installed `botopink` binary and
    // touches no compiler internals, so it carries no `compiler-core` dependency.

    const exe = b.addExecutable(.{
        .name = "botopink-lib-test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    // ── Run step ────────────────────────────────────────────────────────────────

    const run_step = b.step("run", "Run the lib test runner");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    // ── Test step ───────────────────────────────────────────────────────────────

    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run the lib-test-runner unit tests");
    test_step.dependOn(&run_exe_tests.step);
}
