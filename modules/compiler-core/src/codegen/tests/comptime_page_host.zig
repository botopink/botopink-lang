//! Decision 1035 C3b (1038 (2), 1059, 1063, 1069 (3)): the web comptime host
//! answers as the native one, byte for byte — on V8 (node), whose stack-trace
//! API gives the page its frames; another engine gives none (degraded, never
//! refused), so the equivalence is V8's. Each case runs C3a's hand-written core
//! units — `comptime_host_named_traps`' fixtures among them — and C1's real
//! `out/wasm-comptime/` units through the native host (`wat/comptime_host.zig`)
//! and through the page's: `wat/comptime_page.zig` `plan`, then
//! `modules/compiler-web/glue.js` under node over `bp_host.run_units`, then
//! `comptime_page.finish`; and compares the outcome, the reply (the one the
//! host builds included), the fault's class, import and frames, and the
//! printed text.
const std = @import("std");
const test_scratch = @import("test_scratch");
const codegen = @import("../../codegen.zig");
const ModuleOutput = @import("../moduleOutput.zig").ModuleOutput;
const h = @import("helpers.zig");
const ru = @import("../wat/runtime_unit.zig");
const cu = @import("../wat/comptime_units.zig");
const host = @import("../wat/comptime_host.zig");
const page_host = @import("../wat/comptime_page.zig");
const engine = @import("../wat/engine.zig");
const c = engine.c;

const script = "../compiler-web/tests/comptime_host.js";

/// `.wat` text (or binary) as binary.
fn binary(ar: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, bytes, "\x00asm")) return bytes;
    var out: c.wasm_byte_vec_t = undefined;
    if (c.wasmtime_wat2wasm(bytes.ptr, bytes.len, &out) != null) return error.TestUnexpectedResult;
    defer c.wasm_byte_vec_delete(&out);
    return ar.dupe(u8, out.data[0..out.size]);
}

/// The evaluation of `module` through the page's host, `repeat` times in one
/// host (each on fresh instances). Each answer is owned by `alloc`.
fn page(alloc: std.mem.Allocator, io: std.Io, dir: []const u8, units: []const host.Unit, module: []const u8, input: []const u8, repeat: usize) ![]page_host.Answer {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const ar = arena.allocator();
    const bins = try ar.alloc(page_host.Unit, units.len);
    for (units, bins) |u, *b| b.* = .{ .name = u.name, .bytes = try binary(ar, u.bytes) };
    const p = try page_host.plan(ar, bins, module, input);

    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, dir);
    const plan_path = try std.fs.path.join(ar, &.{ dir, "plan.bin" });
    try cwd.writeFile(io, .{ .sub_path = plan_path, .data = p });
    const times = try std.fmt.allocPrint(ar, "{d}", .{repeat});
    const run = try std.process.run(ar, io, .{ .argv = &.{ "node", script, plan_path, times } });
    if (run.term != .exited or run.term.exited != 0) {
        std.debug.print("\nnode {s}: {s}\n", .{ script, run.stderr });
        return error.TestUnexpectedResult;
    }
    const Raw = struct { status: u32, text: []const u8, printed: []const u8 };
    const raws = try std.json.parseFromSliceLeaky([]Raw, ar, run.stdout, .{});
    const out = try alloc.alloc(page_host.Answer, raws.len);
    for (raws, out) |r, *o| o.* = try page_host.finish(alloc, r.status, r.text, r.printed);
    return out;
}

fn freeAll(alloc: std.mem.Allocator, answers: []page_host.Answer) void {
    for (answers) |a| a.deinit(alloc);
    alloc.free(answers);
}

/// One line per part of an answer, the same for both hosts' answers.
fn render(alloc: std.mem.Allocator, a: anytype) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(alloc);
    switch (a.outcome) {
        .reply, .compile_error => |t| try out.print(alloc, "{s}\n{s}\n", .{ @tagName(a.outcome), t }),
        .raised => |r| {
            try out.print(alloc, "raised: {s} {s}\n{s}\n", .{
                if (r.fault.service) |sv| @tagName(sv) else "-",
                if (r.fault.import.len > 0) r.fault.import else "-",
                r.reply,
            });
        },
    }
    try out.print(alloc, "printed: {s}\n", .{a.printed});
    return out.toOwnedSlice(alloc);
}

/// Both hosts over `units`; their renderings must be equal. Returns the
/// page's (owned).
fn both(io: std.Io, comptime case: []const u8, units: []const host.Unit, module: []const u8, input: []const u8) ![]u8 {
    const a = std.testing.allocator;
    const n = try host.evaluate(a, io, units, module, input, .{});
    defer n.deinit(a);
    const p = try page(a, io, test_scratch.path(io, "codegen/comptime_page_host/" ++ case), units, module, input, 1);
    defer freeAll(a, p);
    const nr = try render(a, n);
    defer a.free(nr);
    const pr = try render(a, p[0]);
    errdefer a.free(pr);
    try std.testing.expectEqualStrings(nr, pr);
    return pr;
}

test "page comptime host on V8: units linked, __bp_init in order, the JSON crosses, print captured; fresh per evaluation; chosen by name" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/roundtrip");
    defer test_scratch.remove(io, "codegen/comptime_page_host/roundtrip");
    const two = host.units2("page-roundtrip");
    const p = try page(a, io, test_scratch.path(io, "codegen/comptime_page_host/roundtrip/page"), &two, "app@main", "[1,\"x\"]", 2);
    defer freeAll(a, p);
    for (p) |r| {
        try std.testing.expectEqualStrings("{\"in\":[1,\"x\"],\"order\":2}", r.outcome.reply);
        try std.testing.expectEqualStrings("[1,\"x\"]", r.printed);
    }
    const units = [_]host.Unit{ two[0], two[1], .{ .name = "app@other", .bytes = host.other_wat } };
    a.free(try both(io, "roundtrip/main", &units, "app@main", "[1,\"x\"]"));
    a.free(try both(io, "roundtrip/other", &units, "app@other", "1"));
    a.free(try both(io, "roundtrip/absent", &units, "app@absent", "1"));
}

test "page comptime host on V8: comptime_host_named_traps' fixtures answer as the native host's, frames included" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/services");
    defer test_scratch.remove(io, "codegen/comptime_page_host/services");
    inline for (host.service_cases, 0..) |case_, i| {
        const units = [_]host.Unit{.{ .name = ru.name, .bytes = case_.wat }};
        const r = try both(io, std.fmt.comptimePrint("services/{d}", .{i}), &units, ru.name, "");
        defer a.free(r);
        if (comptime std.mem.eql(u8, case_.label, "frames"))
            try std.testing.expect(std.mem.indexOf(u8, r, "\"frames\":[{\"module\":\"std@io@clock\",\"function\":\"std@io@clock.now\"},{\"module\":\"std@io@clock\",\"function\":\"app@main.body\"}]") != null);
    }
}

test "page comptime host on V8: an import nothing serves is refused, naming it, as natively" {
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/unserved");
    defer test_scratch.remove(io, "codegen/comptime_page_host/unserved");
    const units = [_]host.Unit{.{ .name = ru.name, .bytes = host.serviceWat("\"env\" \"elsewhere\"", "", "(call $h)") }};
    std.testing.allocator.free(try both(io, "unserved", &units, ru.name, ""));
}

test "page comptime host on V8: engine traps read as the native host's" {
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/traps");
    defer test_scratch.remove(io, "codegen/comptime_page_host/traps");
    const yield = "\"wasi_snapshot_preview1\" \"sched_yield\"";
    const traps = [_][]const u8{
        host.serviceWat(yield, "(result i32)", "unreachable"),
        host.serviceWat(yield, "(result i32)", "(drop (i32.div_s (i32.const 1) (i32.const 0)))"),
        host.serviceWat(yield, "(result i32)", "(drop (i32.load (i32.const 1000000)))"),
    };
    inline for (traps, 0..) |t, i| {
        const units = [_]host.Unit{.{ .name = ru.name, .bytes = t }};
        std.testing.allocator.free(try both(io, std.fmt.comptimePrint("traps/{d}", .{i}), &units, ru.name, ""));
    }
    // Past the stack: the page's stack is its engine's, smaller than the
    // native 64 MiB (1059 (7)); the text is the same.
    const deep = [_]host.Unit{
        .{ .name = ru.name, .bytes = host.depth_core },
        .{ .name = "app@too_deep", .bytes = host.depthEntry("100000000") },
    };
    std.testing.allocator.free(try both(io, "traps/deep", &deep, "app@too_deep", ""));
}

/// GC and exceptions in the page's engine: a struct allocated, an exception
/// thrown and caught by a `try_table`.
const gc_exn_wat =
    \\(module
    \\  (type $box (struct (field i32)))
    \\  (tag $boom (param i32))
    \\  (memory (export "memory") 1)
    \\  (func (export "__alloc") (param i32) (result i32) (i32.const 64))
    \\  (func $caught (result i32)
    \\    (block $h (result i32)
    \\      (try_table (catch $boom $h)
    \\        (throw $boom (struct.get $box 0 (struct.new $box (i32.const 7)))))
    \\      (i32.const 0)))
    \\  (func (export "__bp_comptime_eval") (param i32 i32) (result i32 i32)
    \\    (i32.store8 (i32.const 100) (i32.add (i32.const 48) (call $caught)))
    \\    (i32.const 100) (i32.const 1)))
;

test "page comptime host on V8: GC and exceptions run on the page's engine" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/gc");
    defer test_scratch.remove(io, "codegen/comptime_page_host/gc");
    const units = [_]host.Unit{.{ .name = ru.name, .bytes = gc_exn_wat }};
    const r = try both(io, "gc", &units, ru.name, "");
    defer a.free(r);
    try std.testing.expectEqualStrings("reply\n7\nprinted: \n", r);
}

test "page comptime host on V8: a unit the engine refuses is a compile refusal naming it" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/refused");
    defer test_scratch.remove(io, "codegen/comptime_page_host/refused");
    const units = [_]host.Unit{.{ .name = ru.name, .bytes = "\x00asm\x01\x00\x00\x00\x01\xff" }};
    const p = try page(a, io, test_scratch.path(io, "codegen/comptime_page_host/refused"), &units, ru.name, "", 1);
    defer freeAll(a, p);
    try std.testing.expect(std.mem.startsWith(u8, p[0].outcome.compile_error, "unit " ++ ru.name ++ ": "));
}

test "page comptime host on V8: C1's out/wasm-comptime units link, init in order and reach the crossing" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "codegen/comptime_page_host/c1");
    defer test_scratch.remove(io, "codegen/comptime_page_host/c1");
    const modules = [_]codegen.Module{
        .{ .path = "lib", .source =
        \\pub fn twice(n: i32) -> i32 {
        \\    return n * 2;
        \\}
        },
        .{ .path = "main", .source =
        \\import {compiler, io.terminal.print} from "std";
        \\import {twice} from "lib";
        \\
        \\fn label(syntax decl: unknown) -> void {
        \\    compiler.addMember("pub fn label() -> string { return \"the " + compiler.name(decl)! + "\"; }");
        \\}
        \\
        \\#[label]
        \\type City(name: string)
        \\
        \\pub fn main() -> void {
        \\    print(City.label());
        \\    print(twice(21));
        \\    print("a,b".split(","));
        \\}
        },
    };
    var units: std.ArrayListUnmanaged(ModuleOutput) = .empty;
    defer {
        for (units.items) |*o| o.result.deinit(a);
        units.deinit(a);
    }
    var outs = try codegen.generateWith(a, &modules, io, h.configs[1], .{ .execute = false, .comptime_units = &units });
    defer {
        for (outs.items) |*o| o.result.deinit(a);
        outs.deinit(a);
    }
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var program: std.ArrayListUnmanaged(cu.Unit) = .empty;
    for (units.items) |o| {
        const bin = o.result.wasm orelse return error.TestUnexpectedResult;
        const stems = try ru.unitsOf(ar, bin);
        try program.append(ar, .{ .stem = stems[stems.len - 1], .bytes = bin });
    }
    const files = try cu.files(ar, program.items);
    const linked = try ar.alloc(host.Unit, files.len);
    for (files, linked) |f, *u| u.* = .{ .name = f.name[0 .. f.name.len - ".wasm".len], .bytes = f.bytes };

    // Every unit compiled, linked and initialised on both engines; the
    // evaluation export is C2's.
    const r = try both(io, "c1", linked, "test@main", "{}");
    defer a.free(r);
    try std.testing.expectEqualStrings("compile_error\ntest@main exports no function " ++ ru.comptime_eval_export ++ "\nprinted: \n", r);
}
