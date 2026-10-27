//! Decision 1035 C3a over C1's real units: the native comptime host
//! (`wat/comptime_host.zig`) links the files the `.comptime` stage writes to
//! `out/wasm-comptime/` — the runtime core, std's units, the program's
//! comptime units — and runs their `__bp_init`s. C1's units carry no
//! evaluation export yet (C2 adds it), so the evaluation stops at the
//! crossing, naming the export it looked for.
const std = @import("std");
const codegen = @import("../../codegen.zig");
const ModuleOutput = @import("../moduleOutput.zig").ModuleOutput;
const h = @import("helpers.zig");
const ru = @import("../wat/runtime_unit.zig");
const cu = @import("../wat/comptime_units.zig");
const host = @import("../wat/comptime_host.zig");

test "comptime host: C1's out/wasm-comptime units link, init in order and reach the crossing" {
    const a = std.testing.allocator;
    const io = std.testing.io;
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
    // The folder's files in dependency order, each under its import name.
    const files = try cu.files(ar, program.items);
    const linked = try ar.alloc(host.Unit, files.len);
    for (files, linked) |f, *u| u.* = .{ .name = f.name[0 .. f.name.len - ".wasm".len], .bytes = f.bytes };
    try std.testing.expectEqualStrings(ru.name, linked[0].name);
    try std.testing.expectEqualStrings("test@main", linked[linked.len - 1].name);

    const answer = try host.evaluate(a, io, linked, "test@main", "{}", .{});
    defer answer.deinit(a);
    // Every unit compiled, linked and initialised; the core's memory and
    // `__alloc` were found; the evaluation export is C2's.
    if (answer.outcome != .compile_error) std.debug.print("\n{s}\n", .{@tagName(answer.outcome)});
    try std.testing.expectEqualStrings("test@main exports no function __bp_comptime_eval", answer.outcome.compile_error);
    try std.testing.expectEqualStrings("", answer.printed);
}
