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
        const file = try comptimeSnapshot.moduleFile(alloc, name);
        defer alloc.free(file);
        const body = try ct_err.renderAlloc(alloc, src, file);
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
            if (result.run_output) |output| try writeRunLog(alloc, &buf, output);
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
            if (result.run_output) |output| try writeRunLog(alloc, &buf, output);
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

            if (result.run_output) |output| try writeRunLog(alloc, &buf, output);
        },
        .wasm => {
            try writeComptimeSections(alloc, &buf, name, result);

            // WebAssembly Text output section
            const watHdr = try std.fmt.allocPrint(alloc, "----- WASM TEXT -- {s}.wat\n```wasm\n", .{name});
            defer alloc.free(watHdr);
            try buf.appendSlice(alloc, watHdr);
            try buf.appendSlice(alloc, result.js);
            try buf.appendSlice(alloc, "```\n");

            if (result.run_output) |output| try writeRunLog(alloc, &buf, output);
        },
    }

    return try buf.toOwnedSlice(alloc);
}

/// Appends the `----- RUN LOG -----` section. The `botopink test` envelope
/// carries ONE nondeterministic line — `  duration <ms>ms`, the runner's wall
/// clock around each test body — and a snapshot that pins its digits fails on
/// any machine slower than the one that wrote it: `src_in_a_test` recorded
/// `duration 0ms` and answered `duration 1ms` under load, the only line that
/// differed. The digits are normalised to `<ms>` here, so the envelope stays
/// visible in the file and the file compares equal on every machine.
/// `tests/helpers.zig`'s `stripDurationLines` is the same rule for the
/// run-log assertion that writes no snapshot.
fn writeRunLog(alloc: std.mem.Allocator, buf: *std.ArrayListUnmanaged(u8), output: []const u8) !void {
    try buf.appendSlice(alloc, "\n----- RUN LOG -----\n```logs\n");
    var it = std.mem.splitScalar(u8, output, '\n');
    var first = true;
    while (it.next()) |line| {
        if (!first) try buf.append(alloc, '\n');
        first = false;
        if (isDurationLine(line)) {
            try buf.appendSlice(alloc, "  duration <ms>ms");
        } else {
            try buf.appendSlice(alloc, line);
        }
    }
    try buf.appendSlice(alloc, "```\n");
}

/// `  duration <digits>ms` — the envelope line, and nothing a program prints
/// by accident: the two-space indent, the word, one or more digits, `ms`.
fn isDurationLine(line: []const u8) bool {
    const prefix = "  duration ";
    if (!std.mem.startsWith(u8, line, prefix) or !std.mem.endsWith(u8, line, "ms")) return false;
    const digits = line[prefix.len .. line.len - 2];
    if (digits.len == 0) return false;
    for (digits) |c| if (!std.ascii.isDigit(c)) return false;
    return true;
}

test "writeRunLog normalises the envelope's duration line and nothing else" {
    const alloc = std.testing.allocator;
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(alloc);
    try writeRunLog(alloc, &buf, "ok src: in a test\n  duration 1ms\n  duration ms\nduration 3ms\n  duration 12ms\n");
    try std.testing.expectEqualStrings(
        "\n----- RUN LOG -----\n```logs\nok src: in a test\n  duration <ms>ms\n  duration ms\nduration 3ms\n  duration <ms>ms\n```\n",
        buf.items,
    );
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

/// The comptime runtime a snapshot is recorded under: the harness names it on
/// every generation it records (`codegen/tests/helpers.zig` `snapshot_configs`);
/// a generation that names none has no place in the tree.
fn runtimeDir(cfg: config.Config) error{SnapshotWithoutComptimeRuntime}![]const u8 {
    const rt = cfg.comptime_runtime orelse return error.SnapshotWithoutComptimeRuntime;
    return @tagName(rt);
}

/// Asserts the codegen output against a snapshot file.
/// The snapshot path is "codegen/{comptime runtime}/{targetSource}/{slug}.snap.md"
/// (front 18 step 4, decision 85).
pub fn assertCodegen(
    alloc: std.mem.Allocator,
    slug: []const u8,
    outputs: []const SnapInput,
    cfg: config.Config,
) !void {
    const snapName = try std.fmt.allocPrint(alloc, "codegen/{s}/{s}/{s}", .{ try runtimeDir(cfg), @tagName(cfg.targetSource), slug });
    defer alloc.free(snapName);

    const text = try buildSnapshotMulti(alloc, outputs, cfg);
    defer alloc.free(text);

    try snapMod.checkText(alloc, snapName, text);
}

/// Asserts a codegen error against a snapshot file.
/// The snapshot path is "codegen/{comptime runtime}/errors/{targetSource}/{slug}.snap.md".
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

    const snapName = try std.fmt.allocPrint(alloc, "codegen/{s}/errors/{s}/{s}", .{ try runtimeDir(cfg), @tagName(cfg.targetSource), slug });
    defer alloc.free(snapName);

    try snapMod.checkText(alloc, snapName, combined);
}
