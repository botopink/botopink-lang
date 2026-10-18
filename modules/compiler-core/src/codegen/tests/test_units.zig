//! Decision 513 (144 B-64): a module's tests are a unit of their own. The
//! production unit is the same bytes under `build` and `test` on every
//! target; the test unit exists under `botopink test` of the package that
//! declares the module only, never for a dependency's module.

const std = @import("std");
const test_scratch = @import("test_scratch");
const codegen = @import("../../codegen.zig");
const h = @import("helpers.zig");

const main_src =
    \\fn helper(x: i32) -> i32 {
    \\    return x * 2;
    \\}
    \\
    \\val secret = 21;
    \\
    \\pub fn twice(x: i32) -> i32 {
    \\    return helper(x);
    \\}
    \\
    \\fn main() {
    \\    print(twice(secret));
    \\}
    \\
    \\test "reads a private fn and a private val" {
    \\    assert helper(secret) == 42;
    \\}
    \\import {io.terminal.print} from "std";
;

const dep_src =
    \\pub fn one() -> i32 {
    \\    return 1;
    \\}
    \\
    \\test "a dependency's own test" {
    \\    assert one() == 1;
    \\}
;

fn emit(alloc: std.mem.Allocator, cfg: codegen.Config) !std.ArrayListUnmanaged(codegen.ModuleOutput) {
    const modules = [_]codegen.Module{
        .{ .path = "dep/util", .source = dep_src, .package = "dep" },
        .{ .path = "main", .source = main_src },
    };
    return codegen.generateWith(alloc, &modules, std.testing.io, cfg, .{ .execute = false });
}

test "every target: a module's production bytes are equal under build and test; only the package under test has a test unit" {
    const alloc = std.testing.allocator;
    for (h.configs) |base| {
        var cfg = base;
        cfg.packages = .{ .root = "test", .deps = &.{"dep"} };
        cfg.build_root = test_scratch.path(std.testing.io, "codegen/test_units");
        var built = try emit(alloc, cfg);
        defer {
            for (built.items) |*o| o.result.deinit(alloc);
            built.deinit(alloc);
        }
        cfg.test_mode = true;
        var tested = try emit(alloc, cfg);
        defer {
            for (tested.items) |*o| o.result.deinit(alloc);
            tested.deinit(alloc);
        }
        try std.testing.expectEqual(built.items.len, tested.items.len);
        var saw_main = false;
        for (built.items, tested.items) |b, t| {
            try std.testing.expectEqualStrings(b.name, t.name);
            if (b.result.failed() or t.result.failed()) {
                std.debug.print("\n{s} [{s}]: the module did not compile\n", .{ b.name, @tagName(cfg.targetSource) });
                return error.ModuleDidNotCompile;
            }
            std.testing.expectEqualStrings(b.result.js, t.result.js) catch |err| {
                std.debug.print("\n{s} [{s}]: the production unit differs between build and test\n", .{ b.name, @tagName(cfg.targetSource) });
                return err;
            };
            try std.testing.expect(b.result.test_unit == null);
            if (std.mem.eql(u8, t.name, "main")) {
                saw_main = true;
                const unit = t.result.test_unit orelse return error.NoTestUnit;
                try std.testing.expect(std.mem.startsWith(u8, unit.atom, "__test__"));
            } else {
                // A dependency's tests are never emitted for a consumer.
                try std.testing.expect(t.result.test_unit == null);
            }
        }
        try std.testing.expect(saw_main);
    }
}

// A pipe stage naming the file's function (`3 |> double`) in a test body is a
// reach from the test unit into the production module, as a written
// `double(3)` is: a remote call to its reserved export. erlang called it bare
// (`function double/1 undefined`) and beam skipped the stage, so the
// assertion saw `3` (`conformance/test/expr_sugar.bp`).
test "erlang, beam: a pipe stage in a test body reaches the file's function through the production module" {
    const alloc = std.testing.allocator;
    const src =
        \\fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        \\
        \\fn add(x: i32, y: i32) -> i32 {
        \\    return x + y;
        \\}
        \\
        \\test "piped" {
        \\    assert (3 |> add(4) |> double) == 14;
        \\}
    ;
    for (h.configs[1..3]) |base| {
        var cfg = base;
        cfg.test_mode = true;
        cfg.build_root = test_scratch.path(std.testing.io, "codegen/test_units_pipe");
        const modules = [_]codegen.Module{.{ .path = "main", .source = src }};
        var out = try codegen.generateWith(alloc, &modules, std.testing.io, cfg, .{ .execute = false });
        defer {
            for (out.items) |*o| o.result.deinit(alloc);
            out.deinit(alloc);
        }
        for (out.items) |o| {
            if (!std.mem.eql(u8, o.name, "main")) continue;
            if (o.result.failed()) return error.ModuleDidNotCompile;
            const unit = o.result.test_unit orelse return error.NoTestUnit;
            for ([_][]const u8{ "__bp_priv__double", "__bp_priv__add" }) |needle| {
                if (std.mem.indexOf(u8, unit.code, needle) == null) {
                    std.debug.print("\n=== {s} test unit ===\n{s}\n=== missing: {s} ===\n", .{ @tagName(cfg.targetSource), unit.code, needle });
                    return error.NeedleNotFound;
                }
            }
            if (std.mem.indexOf(u8, unit.code, "unresolved pipeline fn") != null) return error.UnresolvedStage;
        }
    }
}
