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
pub fn buildSnapshot(alloc: std.mem.Allocator, name: []const u8, src: []const u8, result: GenerateResult, cfg: config.Config) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(alloc);

    // Source code section
    const srcHdr = try std.fmt.allocPrint(alloc, "----- SOURCE CODE -- {s}.bp\n```botopink\n", .{name});
    defer alloc.free(srcHdr);
    try buf.appendSlice(alloc, srcHdr);
    try buf.appendSlice(alloc, src);
    try buf.appendSlice(alloc, "\n```\n\n");

    switch (cfg.targetSource) {
        .commonJS => {
            // Comptime JavaScript section (if any)
            if (result.comptime_script) |ct| {
                const ctHdr = try std.fmt.allocPrint(alloc, "----- COMPTIME JAVASCRIPT -- {s}.js\n```javascript\n", .{name});
                defer alloc.free(ctHdr);
                try buf.appendSlice(alloc, ctHdr);
                try buf.appendSlice(alloc, ct);
                try buf.appendSlice(alloc, "```\n\n");
            }

            // JavaScript output section
            const jsHdr = try std.fmt.allocPrint(alloc, "----- JAVASCRIPT -- {s}.js\n```javascript\n", .{name});
            defer alloc.free(jsHdr);
            try buf.appendSlice(alloc, jsHdr);
            try buf.appendSlice(alloc, result.js);
            try buf.appendSlice(alloc, "```\n");

            // TypeScript typedef section (if any)
            if (result.typedef) |ts| {
                const tsHdr = try std.fmt.allocPrint(alloc, "\n----- TYPESCRIPT TYPEDEF -- {s}.d.ts\n```typescript\n", .{name});
                defer alloc.free(tsHdr);
                try buf.appendSlice(alloc, tsHdr);
                try buf.appendSlice(alloc, ts);
                try buf.appendSlice(alloc, "```\n");
            }
        },
        .erlang => {
            // Comptime Erlang section (if any)
            if (result.comptime_script) |ct| {
                const ctHdr = try std.fmt.allocPrint(alloc, "----- COMPTIME ERLANG -- {s}.erl\n```erlang\n", .{name});
                defer alloc.free(ctHdr);
                try buf.appendSlice(alloc, ctHdr);
                try buf.appendSlice(alloc, ct);
                try buf.appendSlice(alloc, "```\n\n");
            }

            // Erlang output section
            const erlHdr = try std.fmt.allocPrint(alloc, "----- ERLANG -- {s}.erl\n```erlang\n", .{name});
            defer alloc.free(erlHdr);
            try buf.appendSlice(alloc, erlHdr);
            try buf.appendSlice(alloc, result.js);
            try buf.appendSlice(alloc, "```\n");
        },
    }

    return try buf.toOwnedSlice(alloc);
}

/// Builds a multi-section snapshot for multiple codegen module outputs joined together.
pub fn buildSnapshotMulti(alloc: std.mem.Allocator, outputs: []const SnapInput, cfg: config.Config) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(alloc);

    for (outputs, 0..) |out, idx| {
        if (idx > 0) try buf.appendSlice(alloc, "\n");
        const text = try buildSnapshot(alloc, out.name, out.src, out.result, cfg);
        defer alloc.free(text);
        try buf.appendSlice(alloc, text);
    }

    return try buf.toOwnedSlice(alloc);
}

/// Asserts the codegen output against a snapshot file.
/// The snapshot path is "codegen/{comptimeRuntime}/{targetSource}/{slug}.snap.md".
pub fn assertCodegen(
    alloc: std.mem.Allocator,
    slug: []const u8,
    outputs: []const SnapInput,
    cfg: config.Config,
) !void {
    const snapName = try std.fmt.allocPrint(alloc, "codegen/{s}/{s}/{s}", .{ @tagName(cfg.comptimeRuntime), @tagName(cfg.targetSource), slug });
    defer alloc.free(snapName);

    const text = try buildSnapshotMulti(alloc, outputs, cfg);
    defer alloc.free(text);

    try snapMod.checkText(alloc, snapName, text);
}

/// Asserts a codegen error against a snapshot file.
/// The snapshot path is "codegen/errors/{comptimeRuntime}/{targetSource}/{slug}.snap.md".
pub fn assertCodegenError(
    alloc: std.mem.Allocator,
    slug: []const u8,
    src: []const u8,
    errText: []const u8,
    cfg: config.Config,
) !void {
    const combined = try std.fmt.allocPrint(
        alloc,
        "----- SOURCE CODE -- main.bp\n```botopink\n{s}\n```\n\n----- ERROR\n{s}",
        .{ src, errText },
    );
    defer alloc.free(combined);

    const snapName = try std.fmt.allocPrint(alloc, "codegen/errors/{s}/{s}/{s}", .{ @tagName(cfg.comptimeRuntime), @tagName(cfg.targetSource), slug });
    defer alloc.free(snapName);

    try snapMod.checkText(alloc, snapName, combined);
}
