const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const botopink_dep = b.dependency("botopink", .{
        .target = target,
        .optimize = optimize,
    });
    const botopink_mod = botopink_dep.module("botopink");

    const lsp_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "botopink", .module = botopink_mod },
        },
    });

    const lsp_exe = b.addExecutable(.{
        .name = "botopink-lsp",
        .root_module = lsp_mod,
    });

    b.installArtifact(lsp_exe);

    const run_cmd = b.addRunArtifact(lsp_exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Roda o botopink LSP");
    run_step.dependOn(&run_cmd.step);

    // ── Tests ─────────────────────────────────────────────────────────────────

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/test_root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "botopink", .module = botopink_mod },
        },
    });

    const lsp_tests = b.addTest(.{ .root_module = test_mod });
    const run_tests = b.addRunArtifact(lsp_tests);
    run_tests.setCwd(b.path("."));

    const test_step = b.step("test", "Roda os testes do language-server");
    test_step.dependOn(&run_tests.step);
}
