//! Front 230 s1 — wasm bounded memory, an oracle that can fail. Every value
//! of a wasm program is a WasmGC value (decision 544), and the runner's store
//! limiter (`runner.Options.memory_limit`) bounds the GC heap as it bounds a
//! linear memory: a program whose values die runs under a fixed cap however
//! long it runs, and one whose live data outgrows the cap ends with the GC
//! heap's refusal, never damaged data.

const std = @import("std");
const h = @import("helpers.zig");
const runner = @import("../wat/runner.zig");
const engine = @import("../wat/engine.zig");
const ru = @import("../wat/runtime_unit.zig");
const watEmitter = @import("../wat/wat_emitter.zig");

/// Compile `source` as the program `main` for wasm (its units on) and run
/// it through the runner with `opts`. The caller owns the outcome.
fn runProgram(a: std.mem.Allocator, source: []const u8, opts: runner.Options) !runner.Outcome {
    const io = std.testing.io;
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    var outputs = try h.generate(a, &.{.{ .path = "main", .source = source }}, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    const entry = o.result.wasm orelse return error.ModuleDidNotCompile;

    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    const rt = try ru.get();
    const stems = try ru.unitsOf(ar, entry);
    var fw: std.Io.Writer.Allocating = .init(ar);
    try watEmitter.frameOf(ar, &fw.writer, entry, &.{});
    var failure: ?[]u8 = null;
    const comp = (try engine.precompiled(a, io, null, fw.written(), .component, false, &failure)) orelse {
        std.debug.print("\n=== frame refused: {s}\n", .{failure.?});
        a.free(failure.?);
        return error.TestUnexpectedResult;
    };
    defer comp.code.deinit();
    var held: std.ArrayListUnmanaged(engine.Precompiled) = .empty;
    defer {
        for (held.items) |p| p.code.deinit();
        held.deinit(a);
    }
    const units = try ar.alloc(runner.Unit, stems.len);
    for (stems, units, 0..) |s, *u, k| {
        const bytes = if (k == stems.len - 1) entry else if (std.mem.eql(u8, s, ru.name)) rt.core_bytes else if (rt.unit(s)) |su| su.bytes else return error.TestUnexpectedResult;
        const pc = (try engine.precompiled(a, io, null, bytes, .module, false, &failure)) orelse {
            std.debug.print("\n=== unit {s} refused: {s}\n", .{ s, failure.? });
            a.free(failure.?);
            return error.TestUnexpectedResult;
        };
        try held.append(a, pc);
        u.* = .{ .name = try std.fmt.allocPrint(ar, "unit-{d}", .{k}), .module = pc.code.module };
    }
    return runner.run(a, comp.code.component, units, opts);
}

/// A case of decision 544's conformance module, read from the suite (the
/// test binary runs in `modules/compiler-core`): one source for the cell
/// and the oracle.
fn caseSource(a: std.mem.Allocator, case: []const u8) ![]u8 {
    const path = try std.fmt.allocPrint(a, "../../conformance/modules/decisions-taken/wasm_values_are_gc-544/cases/{s}/src/main.bp", .{case});
    defer a.free(path);
    return std.Io.Dir.cwd().readFileAlloc(std.testing.io, path, a, .limited(1 << 20));
}

/// The fixed cap every oracle run takes (front 230 s1): one constant of the
/// test, never a flag or a variable (decision 67).
const cap: u64 = 2 * 1024 * 1024;

/// One case of the oracle. `linear_kib` per `linear_per` iterations is what
/// the case needs in linear memory (decision 544's retired model, a bump heap
/// never freed): measured 2026-11-03 on the compiler at `feat` with the `.gc`
/// lowering bypassed, by the smallest `memory_limit` (16 KiB steps) each
/// case completes under at two iteration counts — the difference, so the
/// fixed part cancels. `iterations` is the case's count, and `written` the
/// literals of its source that make it, so the source and the table cannot
/// drift apart.
const Case = struct {
    name: []const u8,
    out: []const u8,
    iterations: u64,
    written: []const []const u8,
    linear_kib: u64,
    linear_per: u64,
};

const cases = [_]Case{
    // ~39 bytes per iteration: linear memory is exhausted at ~53 000.
    .{ .name = "short_lived_values_loop", .out = "10888890\n7999992\n", .iterations = 1_000_000, .written = &.{"i < 1000000"}, .linear_kib = 768, .linear_per = 20_000 },
    // ~66 bytes per iteration (the linear table's ~68): exhausted at ~32 000.
    .{ .name = "ten_million_allocations", .out = "48888890\n", .iterations = 2_500_000, .written = &.{"i < 2500000"}, .linear_kib = 1280, .linear_per = 20_000 },
    // ~24 bytes per call: exhausted at ~89 000 calls.
    .{ .name = "deep_recursion_rounds", .out = "9778600\n", .iterations = 200 * 5000, .written = &.{ "round < 200", "descend(5000)" }, .linear_kib = 1152, .linear_per = 50_000 },
    // ~295 bytes per request: exhausted at ~7 100 requests.
    .{ .name = "request_loop", .out = "3488890\n", .iterations = 100_000, .written = &.{"i < 100000"}, .linear_kib = 576, .linear_per = 2_000 },
};

test "wat memory: each of decision 544's cases completes under the fixed cap at ten times the iterations that exhaust it in linear memory" {
    const a = std.testing.allocator;
    for (cases) |case| {
        // The case runs at least ten times as long as linear memory lasts
        // under the cap.
        try std.testing.expect(case.iterations * case.linear_kib * 1024 >= 10 * cap * case.linear_per);
        const src = try caseSource(a, case.name);
        defer a.free(src);
        for (case.written) |lit| if (std.mem.indexOf(u8, src, lit) == null) {
            std.debug.print("\n=== {s}: the source no longer writes `{s}`\n", .{ case.name, lit });
            return error.TestUnexpectedResult;
        };
        const o = try runProgram(a, src, .{ .stdout = .capture, .memory_limit = cap });
        defer o.deinit(a);
        if (o.status != 0) std.debug.print("\n=== {s} under {d} bytes: status {d}, {s}\n", .{ case.name, cap, o.status, o.trap orelse "" });
        try std.testing.expectEqual(@as(i32, 0), o.status);
        try std.testing.expectEqualStrings(case.out, o.stdout orelse "");
    }
}

test "wat memory: a value that outgrows the cap ends the run with the GC heap's refusal" {
    // The oracle can fail: a string doubled 26 times is 64 MiB of live data.
    const a = std.testing.allocator;
    const src =
        \\import {io.terminal} from "std";
        \\
        \\pub fn main() -> void {
        \\    var s = "x";
        \\    var i = 0;
        \\    while (i < 26) {
        \\        s = s + s;
        \\        i = i + 1;
        \\    }
        \\    terminal.print(s.length);
        \\}
    ;
    const free = try runProgram(a, src, .{ .stdout = .capture });
    defer free.deinit(a);
    try std.testing.expectEqual(@as(i32, 0), free.status);
    try std.testing.expectEqualStrings("67108864\n", free.stdout orelse "");
    const capped = try runProgram(a, src, .{ .stdout = .capture, .memory_limit = cap });
    defer capped.deinit(a);
    try std.testing.expectEqual(@as(i32, 1), capped.status);
    try std.testing.expectEqualStrings("", capped.stdout orelse "");
    try std.testing.expect(std.mem.startsWith(u8, capped.trap orelse "", "GC heap out of memory"));
}
