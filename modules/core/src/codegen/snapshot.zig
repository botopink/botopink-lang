/// Snapshot generation for codegen tests.
///
/// Builds multi-section snapshot content:
///   ----- SOURCE CODE -- name.bp
///   ----- COMPTIME JAVASCRIPT -- name.js  (optional)
///   ----- JAVASCRIPT -- name.js
///   ----- TYPESCRIPT TYPEDEF -- name.d.ts  (optional)
///
/// And for error tests:
///   ----- SOURCE CODE -- main.bp
///   ----- ERROR
const std = @import("std");
const snapMod = @import("../utils/snap.zig");
const codegen = @import("../codegen.zig");
const config = @import("./config.zig");
const moduleOutput = @import("./moduleOutput.zig");
const Module = codegen.Module;
const GenerateResult = moduleOutput.GenerateResult;

/// Input data for snapshot generation.
pub const SnapInput = struct {
    name: []const u8,
    src: []const u8,
    result: GenerateResult,
};

/// Builds the full snapshot text for a single codegen module output.
pub fn buildSnapshot(allocator: std.mem.Allocator, name: []const u8, src: []const u8, result: GenerateResult, cfg: config.Config) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);

    // Source code section
    const srcHdr = try std.fmt.allocPrint(allocator, "----- SOURCE CODE -- {s}.bp\n```botopink\n", .{name});
    defer allocator.free(srcHdr);
    try buf.appendSlice(allocator, srcHdr);
    try buf.appendSlice(allocator, src);
    try buf.appendSlice(allocator, "\n```\n\n");

    switch (cfg.targetSource) {
        .commonJS => {
            // Comptime JavaScript section (if any)
            if (result.comptime_script) |ct| {
                const ctHdr = try std.fmt.allocPrint(allocator, "----- COMPTIME JAVASCRIPT -- {s}.js\n```javascript\n", .{name});
                defer allocator.free(ctHdr);
                try buf.appendSlice(allocator, ctHdr);
                try buf.appendSlice(allocator, ct);
                try buf.appendSlice(allocator, "```\n\n");
            }

            // JavaScript output section
            const jsHdr = try std.fmt.allocPrint(allocator, "----- JAVASCRIPT -- {s}.js\n```javascript\n", .{name});
            defer allocator.free(jsHdr);
            try buf.appendSlice(allocator, jsHdr);
            try buf.appendSlice(allocator, result.js);
            try buf.appendSlice(allocator, "```\n");

            // TypeScript typedef section (if any)
            if (result.typedef) |ts| {
                const tsHdr = try std.fmt.allocPrint(allocator, "\n----- TYPESCRIPT TYPEDEF -- {s}.d.ts\n```typescript\n", .{name});
                defer allocator.free(tsHdr);
                try buf.appendSlice(allocator, tsHdr);
                try buf.appendSlice(allocator, ts);
                try buf.appendSlice(allocator, "```\n");
            }
        },
        .erlang => {
            // Comptime Erlang section (if any)
            if (result.comptime_script) |ct| {
                const ctHdr = try std.fmt.allocPrint(allocator, "----- COMPTIME ERLANG -- {s}.erl\n```erlang\n", .{name});
                defer allocator.free(ctHdr);
                try buf.appendSlice(allocator, ctHdr);
                try buf.appendSlice(allocator, ct);
                try buf.appendSlice(allocator, "```\n\n");
            }

            // Erlang output section
            const erlHdr = try std.fmt.allocPrint(allocator, "----- ERLANG -- {s}.erl\n```erlang\n", .{name});
            defer allocator.free(erlHdr);
            try buf.appendSlice(allocator, erlHdr);
            try buf.appendSlice(allocator, result.js);
            try buf.appendSlice(allocator, "```\n");
        },
    }

    return try buf.toOwnedSlice(allocator);
}

/// Builds a multi-section snapshot for multiple codegen module outputs joined together.
pub fn buildSnapshotMulti(allocator: std.mem.Allocator, outputs: []const SnapInput, cfg: config.Config) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);

    for (outputs, 0..) |out, idx| {
        if (idx > 0) try buf.appendSlice(allocator, "\n");
        const text = try buildSnapshot(allocator, out.name, out.src, out.result, cfg);
        defer allocator.free(text);
        try buf.appendSlice(allocator, text);
    }

    return try buf.toOwnedSlice(allocator);
}

/// Asserts the codegen output against a snapshot file.
/// The snapshot path is "codegen/{comptimeRuntime}/{targetSource}/{slug}.snap.md".
pub fn assertCodegen(
    allocator: std.mem.Allocator,
    slug: []const u8,
    outputs: []const SnapInput,
    cfg: config.Config,
) !void {
    const snapName = try std.fmt.allocPrint(allocator, "codegen/{s}/{s}/{s}", .{ @tagName(cfg.comptimeRuntime), @tagName(cfg.targetSource), slug });
    defer allocator.free(snapName);

    const text = try buildSnapshotMulti(allocator, outputs, cfg);
    defer allocator.free(text);

    try snapMod.checkText(allocator, snapName, text);
}

/// Asserts a codegen error against a snapshot file.
/// The snapshot path is "codegen/errors/{comptimeRuntime}/{targetSource}/{slug}.snap.md".
pub fn assertCodegenError(
    allocator: std.mem.Allocator,
    slug: []const u8,
    src: []const u8,
    errText: []const u8,
    cfg: config.Config,
) !void {
    const combined = try std.fmt.allocPrint(
        allocator,
        "----- SOURCE CODE -- main.bp\n```botopink\n{s}\n```\n\n----- ERROR\n{s}",
        .{ src, errText },
    );
    defer allocator.free(combined);

    const snapName = try std.fmt.allocPrint(allocator, "codegen/errors/{s}/{s}/{s}", .{ @tagName(cfg.comptimeRuntime), @tagName(cfg.targetSource), slug });
    defer allocator.free(snapName);

    try snapMod.checkText(allocator, snapName, combined);
}
