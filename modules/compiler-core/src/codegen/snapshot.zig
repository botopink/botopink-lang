/// Snapshot generation for codegen tests.
///
/// Builds multi-section snapshot content:
///   ----- SOURCE CODE -- name.bp
///   ----- COMPTIME VALUES -- name  (optional: `ct_N = literal` per comptime val)
///   ----- JAVASCRIPT -- name.js
///   ----- TYPESCRIPT TYPEDEF -- name.d.ts  (optional)
///   ----- RUN LOG -----  (optional)
///
/// A module that never reached the backend (parse / type error) or that comptime
/// validation rejected gets, in place of the code section:
///   ----- COMPILE DIAGNOSTIC -- name
/// so a program that does not compile can no longer be recorded as an empty
/// snapshot that compares equal to itself (spec 06 defect H3).
///
/// And for error tests:
///   ----- SOURCE CODE -- main.bp
///   ----- ERROR
const std = @import("std");
const snapMod = @import("../utils/snap.zig");
const codegen = @import("../codegen.zig");
const config = @import("./config.zig");
const moduleOutput = @import("./moduleOutput.zig");
const comptimeSnapshot = @import("../comptime/snapshot.zig");
const Module = codegen.Module;
const GenerateResult = moduleOutput.GenerateResult;

/// Input data for snapshot generation.
///
/// `result` is null for a module that never reached codegen (parse / type
/// error): the backends drop it from their output list. `diagnostic` then
/// carries the rendered reason, which `buildSnapshot` records as a
/// `COMPILE DIAGNOSTIC` section — spec 06 defect H3, where such a module used
/// to contribute nothing at all and the snapshot compared empty with empty.
pub const SnapInput = struct {
    name: []const u8,
    src: []const u8,
    result: ?GenerateResult = null,
    diagnostic: ?[]const u8 = null,
};

/// The comptime evidence, shared by every backend: the decorator/template
/// runtime exchanges (`COMPTIME ERLANG` / `COMPTIME REPLY`), then the folded
/// `val`s (`COMPTIME VALUES`).
fn writeComptimeSections(alloc: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), name: []const u8, result: GenerateResult) !void {
    if (result.comptime_trace) |tr| try buf.appendSlice(alloc, tr);
    if (result.comptime_script) |ct| {
        try buf.print(alloc, "----- COMPTIME VALUES -- {s}\n```text\n", .{name});
        try buf.appendSlice(alloc, ct);
        try buf.appendSlice(alloc, "```\n\n");
    }
}

/// Builds the full snapshot text for a single codegen module output.
/// One section per extra module the file produced (`GenerateResult.units`,
/// policy 3's per-`type` modules): `----- <kind> -- <atom><ext>` in the same
/// fence as the file's own module, so the snapshot shows every module the
/// program loads and `beam_export_audit.sh` assembles each of them.
fn writeUnitSections(alloc: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), kind: []const u8, ext: []const u8, result: GenerateResult) !void {
    for (result.units) |u| {
        try buf.print(alloc, "\n----- {s} -- {s}{s}\n```erlang\n", .{ kind, u.atom, ext });
        try buf.appendSlice(alloc, u.code);
        try buf.appendSlice(alloc, "```\n");
    }
}

pub fn buildSnapshot(
    alloc: std.mem.Allocator,
    name: []const u8,
    src: []const u8,
    result_opt: ?GenerateResult,
    diagnostic: ?[]const u8,
    cfg: config.Config,
) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(alloc);

    // Source code section
    const srcHdr = try std.fmt.allocPrint(alloc, "----- SOURCE CODE -- {s}.bp\n```botopink\n", .{name});
    defer alloc.free(srcHdr);
    try buf.appendSlice(alloc, srcHdr);
    try buf.appendSlice(alloc, src);
    try buf.appendSlice(alloc, "\n```\n\n");

    const result = result_opt orelse {
        // The module never reached the backend — record why.
        try comptimeSnapshot.appendDiagnosticSection(
            alloc,
            &buf,
            name,
            diagnostic orelse "error: the module did not compile (no diagnostic available)\n",
        );
        return try buf.toOwnedSlice(alloc);
    };

    // Comptime validation rejected the module: the backends emit an empty
    // program, so show the diagnostic in place of the (empty) code section.
    if (result.comptime_err) |ct_err| {
        const body = try ct_err.renderAlloc(alloc, src);
        defer alloc.free(body);
        try comptimeSnapshot.appendDiagnosticSection(alloc, &buf, name, body);
        return try buf.toOwnedSlice(alloc);
    }

    switch (cfg.targetSource) {
        .commonJS => {
            try writeComptimeSections(alloc, &buf, name, result);

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

            // RUN LOG section (if any)
            if (result.run_output) |output| {
                const runLogHdr = try std.fmt.allocPrint(alloc, "\n----- RUN LOG -----\n```logs\n", .{});
                defer alloc.free(runLogHdr);
                try buf.appendSlice(alloc, runLogHdr);
                try buf.appendSlice(alloc, output);
                try buf.appendSlice(alloc, "```\n");
            }
        },
        .erlang => {
            try writeComptimeSections(alloc, &buf, name, result);

            // Erlang output section
            const erlHdr = try std.fmt.allocPrint(alloc, "----- ERLANG -- {s}.erl\n```erlang\n", .{name});
            defer alloc.free(erlHdr);
            try buf.appendSlice(alloc, erlHdr);
            try buf.appendSlice(alloc, result.js);
            try buf.appendSlice(alloc, "```\n");
            try writeUnitSections(alloc, &buf, "ERLANG", ".erl", result);

            // RUN LOG section (if any)
            if (result.run_output) |output| {
                const runLogHdr = try std.fmt.allocPrint(alloc, "\n----- RUN LOG -----\n```logs\n", .{});
                defer alloc.free(runLogHdr);
                try buf.appendSlice(alloc, runLogHdr);
                try buf.appendSlice(alloc, output);
                try buf.appendSlice(alloc, "```\n");
            }
        },
        .beam => {
            try writeComptimeSections(alloc, &buf, name, result);

            // BEAM Assembly output section
            const asmHdr = try std.fmt.allocPrint(alloc, "----- BEAM ASSEMBLY -- {s}.S\n```erlang\n", .{name});
            defer alloc.free(asmHdr);
            try buf.appendSlice(alloc, asmHdr);
            try buf.appendSlice(alloc, result.js);
            try buf.appendSlice(alloc, "```\n");
            try writeUnitSections(alloc, &buf, "BEAM ASSEMBLY", ".S", result);

            if (result.run_output) |output| {
                const runLogHdr = try std.fmt.allocPrint(alloc, "\n----- RUN LOG -----\n```logs\n", .{});
                defer alloc.free(runLogHdr);
                try buf.appendSlice(alloc, runLogHdr);
                try buf.appendSlice(alloc, output);
                try buf.appendSlice(alloc, "```\n");
            }
        },
        .wasm => {
            try writeComptimeSections(alloc, &buf, name, result);

            // WebAssembly Text output section
            const watHdr = try std.fmt.allocPrint(alloc, "----- WASM TEXT -- {s}.wat\n```wasm\n", .{name});
            defer alloc.free(watHdr);
            try buf.appendSlice(alloc, watHdr);
            try buf.appendSlice(alloc, result.js);
            try buf.appendSlice(alloc, "```\n");

            if (result.run_output) |output| {
                const runLogHdr = try std.fmt.allocPrint(alloc, "\n----- RUN LOG -----\n```logs\n", .{});
                defer alloc.free(runLogHdr);
                try buf.appendSlice(alloc, runLogHdr);
                try buf.appendSlice(alloc, output);
                try buf.appendSlice(alloc, "```\n");
            }
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
        const text = try buildSnapshot(alloc, out.name, out.src, out.result, out.diagnostic, cfg);
        defer alloc.free(text);
        try buf.appendSlice(alloc, text);
    }

    return try buf.toOwnedSlice(alloc);
}

/// Asserts the codegen output against a snapshot file.
/// The snapshot path is "codegen/{targetSource}/{slug}.snap.md".
pub fn assertCodegen(
    alloc: std.mem.Allocator,
    slug: []const u8,
    outputs: []const SnapInput,
    cfg: config.Config,
) !void {
    const snapName = try std.fmt.allocPrint(alloc, "codegen/{s}/{s}", .{ @tagName(cfg.targetSource), slug });
    defer alloc.free(snapName);

    const text = try buildSnapshotMulti(alloc, outputs, cfg);
    defer alloc.free(text);

    try snapMod.checkText(alloc, snapName, text);
}

/// Asserts a codegen error against a snapshot file.
/// The snapshot path is "codegen/errors/{targetSource}/{slug}.snap.md".
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

    const snapName = try std.fmt.allocPrint(alloc, "codegen/errors/{s}/{s}", .{ @tagName(cfg.targetSource), slug });
    defer alloc.free(snapName);

    try snapMod.checkText(alloc, snapName, combined);
}
