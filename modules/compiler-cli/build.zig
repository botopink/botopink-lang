const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── Dependencies ──────────────────────────────────────────────────────────

    const botopink_dep = b.dependency("botopink", .{
        .target = target,
        .optimize = optimize,
    });
    const botopink_mod = botopink_dep.module("botopink");

    // ── CLI executable ────────────────────────────────────────────────────────

    const exe = b.addExecutable(.{
        .name = "botopink",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "botopink", .module = botopink_mod },
            },
        }),
    });

    b.installArtifact(exe);

    // ── Run step ──────────────────────────────────────────────────────────────

    const run_step = b.step("run", "Run the botopink CLI");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
}
