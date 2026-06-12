//! Shared test harness for the codegen stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");

pub const configs = [_]config.Config{
    .{
        .comptimeRuntime = .node,
        .targetSource = .commonJS,
        .typeDefLanguage = .typescript,
    },
    .{
        .comptimeRuntime = .erlang,
        .targetSource = .erlang,
        .typeDefLanguage = null,
    },
    .{
        .comptimeRuntime = .beam,
        .targetSource = .beam,
        .typeDefLanguage = null,
    },
    .{
        .comptimeRuntime = .wasm,
        .targetSource = .wasm,
        .typeDefLanguage = null,
    },
};

pub fn slugify(comptime s: []const u8) []const u8 {
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true;
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1;
                sep = true;
            }
        }
        if (sep and count > 0) count -= 1;
        break :blk count;
    };
    const S = struct {
        const data: [n]u8 = blk: {
            var buf: [n]u8 = undefined;
            var i: usize = 0;
            var sep = true;
            for (s) |c| {
                if (std.ascii.isAlphanumeric(c)) {
                    if (i < n) {
                        buf[i] = std.ascii.toLower(c);
                        i += 1;
                    }
                    sep = false;
                } else if (!sep) {
                    if (i < n) {
                        buf[i] = '_';
                        i += 1;
                    }
                    sep = true;
                }
            }
            break :blk buf;
        };
    };
    return &S.data;
}

pub fn slugFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const desc = comptime blk: {
        const fnName = loc.fn_name;
        const afterTest = if (std.mem.startsWith(u8, fnName, "test."))
            fnName["test.".len..]
        else
            fnName;
        break :blk if (std.mem.indexOf(u8, afterTest, ": ")) |i|
            afterTest[i + 2 ..]
        else
            afterTest;
    };
    return slugify(desc);
}

pub fn buildRootPathFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const slug = comptime slugFromSrc(loc);
    return comptime std.fmt.comptimePrint(".botopinkbuild/codegen/{s}", .{slug});
}

pub fn freshEnv(arena_alloc: std.mem.Allocator, gpa: Allocator) !comptimeMod.Env_ {
    var env = comptimeMod.Env_.init(arena_alloc);
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, gpa);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));
    return env;
}

pub fn assertJs(
    allocator: Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    const io = std.testing.io;
    const build_root_path = comptime buildRootPathFromSrc(loc);

    for (configs) |c| {
        var cfg = c;
        cfg.build_root = build_root_path;
        var outputs = try codegen.generate(
            allocator,
            modules,
            io,
            cfg,
        );

        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }

        // Build snapshot data for each module
        var snapOutputs = std.ArrayList(snap.SnapInput).empty;
        defer snapOutputs.deinit(allocator);

        for (outputs.items) |o| {
            try snapOutputs.append(allocator, .{
                .name = o.name,
                .src = o.src,
                .result = o.result,
            });
        }

        const slug = comptime slugFromSrc(loc);
        try snap.assertCodegen(allocator, slug, snapOutputs.items, c);
    }
}

pub fn assertJsError(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;

    for (configs) |c| {
        var outputs = try codegen.generate(
            allocator,
            &.{.{ .path = "", .source = src }},
            io,
            c,
        ); // var: deinit needs *Self
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }
        var ct_err_opt: ?comptimeMod.ComptimeError = null;
        for (outputs.items) |o| {
            if (o.result.comptime_err) |ct_err| {
                ct_err_opt = ct_err;
                break;
            }
        }

        if (ct_err_opt == null) {
            ct_err_opt = try extractComptimeValidationError(allocator, src);
        }
        const ct_err = ct_err_opt orelse return error.ExpectedComptimeError;

        const errText = try ct_err.renderAlloc(allocator, src);
        defer allocator.free(errText);

        const slug = comptime slugFromSrc(loc);
        try snap.assertCodegenError(allocator, slug, src, errText, c);
    }
}

pub fn extractComptimeValidationError(allocator: Allocator, src: []const u8) !?comptimeMod.ComptimeError {
    switch (try probeComptimeValidationError(allocator, src)) {
        .err => |err| return err,
        .noError => return null,
        .parseError => {},
    }

    var end = src.len;
    while (end > 0) {
        const maybe_nl = std.mem.lastIndexOfScalar(u8, src[0..end], '\n');
        if (maybe_nl == null) break;
        end = maybe_nl.?;
        var prefix_end = end;
        while (prefix_end > 0) {
            const c = src[prefix_end - 1];
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
                prefix_end -= 1;
            } else break;
        }
        const prefix = src[0..prefix_end];
        if (prefix.len == 0) continue;
        switch (try probeComptimeValidationError(allocator, prefix)) {
            .err => |err| return err,
            .noError => return null,
            .parseError => continue,
        }
    }

    return null;
}

pub const ValidationProbe = union(enum) {
    parseError,
    noError,
    err: comptimeMod.ComptimeError,
};

pub fn probeComptimeValidationError(allocator: Allocator, src: []const u8) !ValidationProbe {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = p.parse(alloc) catch return .parseError;
    if (validation.validateComptime(program)) |err| {
        return .{ .err = err };
    }
    return .noError;
}

pub fn assertJsSingle(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    return assertJs(allocator, loc, &.{.{ .path = "", .source = src }});
}

/// Generate CommonJS for a single-module program and return the JS as an owned
/// slice (caller frees). Used to assert two source forms lower identically.
pub fn generateJs(allocator: Allocator, src: []const u8) ![]u8 {
    const io = std.testing.io;
    var outputs = try codegen.generate(allocator, &.{.{ .path = "", .source = src }}, io, configs[0]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    return allocator.dupe(u8, outputs.items[0].result.js);
}

/// Snapshot a single module compiled in **test mode** (commonJS + erlang):
/// `test { … }` blocks emit as test functions plus a registry + runner
/// entry, and `assert` lowers to a recoverable per-test failure.
pub fn assertJsTestMode(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root_path = comptime buildRootPathFromSrc(loc);

    for (configs[0..2]) |c| { // commonJS/node + erlang
        var cfg = c;
        cfg.build_root = build_root_path;
        cfg.test_mode = true;

        var outputs = try codegen.generate(allocator, &.{.{ .path = "", .source = src }}, io, cfg);
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }

        var snapOutputs = std.ArrayList(snap.SnapInput).empty;
        defer snapOutputs.deinit(allocator);
        for (outputs.items) |o| {
            try snapOutputs.append(allocator, .{
                .name = o.name,
                .src = o.src,
                .result = o.result,
            });
        }

        const slug = comptime slugFromSrc(loc);
        try snap.assertCodegen(allocator, slug, snapOutputs.items, cfg);
    }
}

pub fn assertJsContains(allocator: Allocator, src: []const u8, needles: []const []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[0], // commonJS / node
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const js = outputs.items[outputs.items.len - 1].result.js;
    for (needles) |needle| {
        if (std.mem.indexOf(u8, js, needle) == null) {
            std.debug.print(
                "\n=== generated JS ===\n{s}\n=== missing needle: {s} ===\n",
                .{ js, needle },
            );
            return error.NeedleNotFound;
        }
    }
}

/// Asserts that none of `needles` appear in the generated commonJS output.
pub fn assertJsNotContains(allocator: Allocator, src: []const u8, needles: []const []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[0], // commonJS / node
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const js = outputs.items[outputs.items.len - 1].result.js;
    for (needles) |needle| {
        if (std.mem.indexOf(u8, js, needle) != null) {
            std.debug.print(
                "\n=== generated JS ===\n{s}\n=== unexpected needle: {s} ===\n",
                .{ js, needle },
            );
            return error.UnexpectedNeedle;
        }
    }
}

/// Multi-module variant of `assertJsContains`/`assertJsNotContains`: generates
/// every module (last one is the consumer `main`) and asserts the consumer's JS
/// both contains every `present` needle and contains none of the `absent` ones.
pub fn assertConsumerJs(
    allocator: Allocator,
    modules: []const Module,
    present: []const []const u8,
    absent: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(allocator, modules, io, configs[0]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const js = outputs.items[outputs.items.len - 1].result.js;
    for (present) |needle| {
        if (std.mem.indexOf(u8, js, needle) == null) {
            std.debug.print("\n=== consumer JS ===\n{s}\n=== missing: {s} ===\n", .{ js, needle });
            return error.NeedleNotFound;
        }
    }
    for (absent) |needle| {
        if (std.mem.indexOf(u8, js, needle) != null) {
            std.debug.print("\n=== consumer JS ===\n{s}\n=== unexpected: {s} ===\n", .{ js, needle });
            return error.UnexpectedNeedle;
        }
    }
}
