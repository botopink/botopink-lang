/// Workspace build — coordena compiler-core, compiler-cli e language-server.
///
///   zig build          → compila botopink + botopink-lsp
///   zig build test     → roda todos os testes do compiler-core
///   zig build run      → compila e roda o botopink CLI
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── stdlib prelude ────────────────────────────────────────────────────────

    const stdlib_prelude = b.addModule("stdlib_prelude", .{
        .root_source_file = b.path("modules/stdlib/src/prelude.zig"),
        .target = target,
    });

    // ── compiler-core (biblioteca) ────────────────────────────────────────────

    const core_mod = b.addModule("botopink", .{
        .root_source_file = b.path("modules/compiler-core/src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "stdlib_prelude", .module = stdlib_prelude },
        },
    });

    // ── Testes do compiler-core ───────────────────────────────────────────────

    const core_test_mod = b.addModule("botopink_tests", .{
        .root_source_file = b.path("modules/compiler-core/src/test_root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "stdlib_prelude", .module = stdlib_prelude },
        },
    });

    const core_tests = b.addTest(.{
        .root_module = core_test_mod,
    });

    const run_core_tests = b.addRunArtifact(core_tests);
    // Garante que os snapshots sejam gravados dentro de modules/compiler-core/,
    // não na raiz do workspace.
    run_core_tests.setCwd(b.path("modules/compiler-core"));

    const test_step = b.step("test", "Roda todos os testes (compiler-core + language-server)");
    test_step.dependOn(&run_core_tests.step);

    // ── Testes do language-server ─────────────────────────────────────────────

    const lsp_test_mod = b.createModule(.{
        .root_source_file = b.path("modules/language-server/src/test_root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "botopink", .module = core_mod },
        },
    });

    const lsp_tests = b.addTest(.{ .root_module = lsp_test_mod });
    const run_lsp_tests = b.addRunArtifact(lsp_tests);
    run_lsp_tests.setCwd(b.path("modules/language-server"));

    test_step.dependOn(&run_lsp_tests.step);

    // ── compiler-cli (executável botopink) ────────────────────────────────────

    const cli_exe = b.addExecutable(.{
        .name = "botopink",
        .root_module = b.createModule(.{
            .root_source_file = b.path("modules/compiler-cli/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "botopink", .module = core_mod },
            },
        }),
    });

    b.installArtifact(cli_exe);

    // ── language-server (executável botopink-lsp) ─────────────────────────────

    const lsp_exe = b.addExecutable(.{
        .name = "botopink-lsp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("modules/language-server/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "botopink", .module = core_mod },
            },
        }),
    });

    b.installArtifact(lsp_exe);

    // ── Run step ──────────────────────────────────────────────────────────────

    const run_cmd = b.addRunArtifact(cli_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Compila e roda o botopink CLI");
    run_step.dependOn(&run_cmd.step);
}
