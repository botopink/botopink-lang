//! The browser build of compiler-core (front 18 step 5): `zig build compiler-web`
//! → `zig-out/web/botopink.wasm`, a `wasm32-wasi` module exporting the
//! compiler's API as bytes in, text out. The JS glue (`../glue.js`) serves WASI
//! and drives these exports; `../index.html` is the demo.
//!
//! Exports:
//!   bp_alloc(len) → ptr · bp_free(ptr, len)       the host's window into linear memory
//!   bp_reset()                                    forget every source added so far
//!   bp_add_source(path, path_len, src, src_len)   one module of the virtual project (0 ok, 1 OOM)
//!   bp_set_package(name, name_len)                the project's package name — what `botopink.json`'s
//!                                                 `name` is to the CLI (decision 109: an erlang/BEAM
//!                                                 module atom starts with it); empty is no manifest,
//!                                                 and an erlang/beam compile is then refused
//!                                                 (0 ok, 1 OOM)
//!   bp_compile(target, target_len) → status       0 compiled · 1 a module failed (its diagnostic is in
//!                                                 the output) · 2 unknown target · 3 internal error
//!   bp_output_ptr() / bp_output_len()             the JSON of the last `bp_compile`
//!
//! The output is one JSON object: `{ "target", "modules": [ { "name", "code",
//! "typedef", "units": [ { "atom", "code" } ], "wasm", "unit", "linked", "comptimeTrace", "diagnostic" } ],
//! "runtime": [ { "name", "wasm" } ] }`, `runtime` being the core and the std units the
//! program reaches, in dependency order (base64; empty off the `wasm` target),
//! where `wasm` is the base64 of the binary module on the `wasm` target (null
//! on the others) — the bytes the page instantiates, rendered from the same
//! model as `code`, the `.wat` text —, `unit` its unit stem `<pkg>@<path>` and
//! `linked` its `botopink.units` (the core, std's units, the program units it
//! imports, itself, in order; decisions 1032, 1073 (2); null / empty off wasm;
//! std `.bp` linked into importers until P4c-std, decision 1072 (2)) —
//! and `diagnostic` is the rendered text the CLI would print for a module
//! that did not lex, parse, type-check or pass comptime validation, and null
//! for one that compiled. The compiler never executes the program (the page
//! runs the `wasm` output itself, `glue.js` `run`): `execute = false`,
//! and `codegen.zig` refuses `execute` on a host that cannot spawn
//! (`comptime/runtime/runtime.zig`).
const std = @import("std");
const bp = @import("botopink");

const gpa = std.heap.wasm_allocator;

// The web comptime host (`codegen/wat/comptime_page.zig`, decision 1038 (2),
// C3b) is compiled into this build before C4's evaluators call it.
comptime {
    _ = &bp.codegen.wasmComptimeHost.evaluate;
}

var sources: std.ArrayListUnmanaged(bp.Module) = .empty;
var output: []u8 = "";
var root_package: []u8 = "";

export fn bp_alloc(len: usize) ?[*]u8 {
    const s = gpa.alloc(u8, len) catch return null;
    return s.ptr;
}

export fn bp_free(ptr: [*]u8, len: usize) void {
    gpa.free(ptr[0..len]);
}

export fn bp_reset() void {
    for (sources.items) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    sources.clearRetainingCapacity();
}

export fn bp_add_source(path: [*]const u8, path_len: usize, src: [*]const u8, src_len: usize) i32 {
    const p = gpa.dupe(u8, path[0..path_len]) catch return 1;
    const s = gpa.dupe(u8, src[0..src_len]) catch {
        gpa.free(p);
        return 1;
    };
    sources.append(gpa, .{ .path = p, .source = s, .srcPath = p }) catch {
        gpa.free(p);
        gpa.free(s);
        return 1;
    };
    return 0;
}

export fn bp_set_package(name: [*]const u8, name_len: usize) i32 {
    const n = gpa.dupe(u8, name[0..name_len]) catch return 1;
    if (root_package.len > 0) gpa.free(root_package);
    root_package = n;
    return 0;
}

export fn bp_compile(target: [*]const u8, target_len: usize) i32 {
    const name = target[0..target_len];
    const target_source: bp.codegen.TargetSource = if (std.mem.eql(u8, name, "commonJS"))
        .commonJS
    else if (std.mem.eql(u8, name, "erlang"))
        .erlang
    else if (std.mem.eql(u8, name, "beam"))
        .beam
    else if (std.mem.eql(u8, name, "wasm"))
        .wasm
    else
        return 2;
    return compile(target_source) catch 3;
}

export fn bp_output_ptr() [*]const u8 {
    return output.ptr;
}

export fn bp_output_len() usize {
    return output.len;
}

fn compile(target_source: bp.codegen.TargetSource) !i32 {
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const io = std.Io.Threaded.global_single_threaded.io();
    // Decisions 1032, 1073 (2) — on wasm each module is a unit `<pkg>@<path>`
    // (the CLI's `build.wasm_units`), the page composing the program from them.
    const units = target_source == .wasm;
    const cfg = bp.codegen.Config{ .targetSource = target_source, .packages = .{ .root = root_package }, .wasm_artifact = units, .wasm_units = units };
    var outputs = try bp.codegen.generateWith(gpa, sources.items, io, cfg, .{ .execute = false });
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    var failed = false;
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    var w: std.json.Stringify = .{ .writer = &aw.writer, .options = .{} };
    try w.beginObject();
    try w.objectField("target");
    try w.write(@tagName(target_source));
    try w.objectField("modules");
    try w.beginArray();
    for (outputs.items) |o| {
        const r = o.result;
        try w.beginObject();
        try w.objectField("name");
        try w.write(o.name);
        try w.objectField("code");
        try w.write(r.js);
        try w.objectField("typedef");
        try w.write(r.typedef);
        try w.objectField("units");
        try w.beginArray();
        for (r.units) |u| {
            try w.beginObject();
            try w.objectField("atom");
            try w.write(u.atom);
            try w.objectField("code");
            try w.write(u.code);
            try w.endObject();
        }
        try w.endArray();
        try w.objectField("wasm");
        if (r.wasm) |bin| {
            const enc = std.base64.standard.Encoder;
            const b64 = try arena.alloc(u8, enc.calcSize(bin.len));
            try w.write(enc.encode(b64, bin));
        } else try w.write(null);
        // Decision 1073 (2): the module's unit stem and its `botopink.units`
        // (the core, std's units, the program units, itself), in order.
        const linked: []const []const u8 = if (r.wasm) |bin| try bp.codegen.wasmRuntimeUnit.unitsOf(arena, bin) else &.{};
        try w.objectField("unit");
        try w.write(if (linked.len > 0) linked[linked.len - 1] else null);
        try w.objectField("linked");
        try w.write(linked);
        try w.objectField("comptimeTrace");
        try w.write(r.comptime_trace);
        try w.objectField("diagnostic");
        const diagnostic = try renderDiagnostic(arena, o);
        if (diagnostic != null) failed = true;
        try w.write(diagnostic);
        try w.endObject();
    }
    try w.endArray();
    try w.objectField("runtime");
    try writeRuntime(arena, &w, outputs.items);
    try w.endObject();

    if (output.len > 0) gpa.free(output);
    output = try aw.toOwnedSlice();
    return if (failed) 1 else 0;
}

/// Decisions 1021 (2), 1026, 1069 (5): the runtime core `std@__rt` and the std
/// units the program's modules reach, in dependency order — what the CLI writes
/// beside a `wasi` program (`writeRuntimeUnits`), and what the page composes
/// before the program's own module (`glue.js` `programUnits`). `[]` when no
/// module imports the runtime (every target but `wasm`).
fn writeRuntime(arena: std.mem.Allocator, w: *std.json.Stringify, outputs: []const bp.codegen.ModuleOutput) !void {
    const ru = bp.codegen.wasmRuntimeUnit;
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    for (outputs) |o| {
        const bin = o.result.wasm orelse continue;
        if (o.result.failed() or !ru.importsRuntime(bin)) continue;
        try roots.appendSlice(arena, (try ru.importsOf(arena, bin)).units);
    }
    try w.beginArray();
    if (roots.items.len > 0) {
        const rt = try ru.get();
        try writeUnit(arena, w, ru.name, rt.core_bytes);
        for (try rt.closure(arena, roots.items)) |u| try writeUnit(arena, w, u.name, u.bytes);
    }
    try w.endArray();
}

fn writeUnit(arena: std.mem.Allocator, w: *std.json.Stringify, name: []const u8, bytes: []const u8) !void {
    const enc = std.base64.standard.Encoder;
    try w.beginObject();
    try w.objectField("name");
    try w.write(name);
    try w.objectField("wasm");
    try w.write(enc.encode(try arena.alloc(u8, enc.calcSize(bytes.len)), bytes));
    try w.endObject();
}

/// The text the CLI prints for a module without an artifact
/// (`compiler-cli/src/cli/diagnostics.zig`), or null for one that compiled.
fn renderDiagnostic(arena: std.mem.Allocator, o: bp.codegen.ModuleOutput) !?[]const u8 {
    const file = try std.fmt.allocPrint(arena, "{s}.bp", .{o.name});
    if (o.result.comptime_err) |ce| return try ce.renderAlloc(arena, o.src, file);
    const d = o.result.diagnostic orelse return null;
    return switch (d) {
        .syntax => |se| switch (se) {
            .lex => |lf| blk: {
                const at = lineColOf(o.src, lf.start);
                break :blk try std.fmt.allocPrint(arena, "error: {s}\n --> {s}:{d}:{d}\n\n", .{ lf.name, file, at.line, at.col });
            },
            .parse => |info| if (info) |i|
                try bp.print_errors.renderAlloc(arena, i, o.src, file)
            else
                try std.fmt.allocPrint(arena, "error: unexpected token\n --> {s}\n\n", .{file}),
        },
        .type => |t| if (t.loc) |l|
            try std.fmt.allocPrint(arena, "error: {s}\n --> {s}:{d}:{d}\n\n", .{ t.message, file, l.line, l.col })
        else
            try std.fmt.allocPrint(arena, "error: {s}\n --> {s}\n\n", .{ t.message, file }),
    };
}

const LineCol = struct { line: usize, col: usize };

fn lineColOf(source: []const u8, offset: usize) LineCol {
    var line: usize = 1;
    var col: usize = 1;
    for (source[0..@min(offset, source.len)]) |c| {
        if (c == '\n') {
            line += 1;
            col = 1;
        } else col += 1;
    }
    return .{ .line = line, .col = col };
}
