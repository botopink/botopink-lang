//! beam-to-wasm — `.beam` bytecode translated to wasm (decision 434 (3)).
//!
//! Reads a `.beam` file (the chunks, `chunks.zig`; the instruction stream,
//! `code.zig`) and lowers its functions (`lower.zig`) to wasm functions over
//! the comptime runtime's term ABI (`ir.zig`), its BIF calls bound to the
//! runtime's exports — std-wasm's answers (`modules/std-wasm`). Code that
//! exists only as BEAM — an `@External.Erlang` / `@External.Beam` cell, an
//! `.erl` sidecar — so runs at comptime on the one comptime runtime, wasm.
//!
//! It converts a named subset (decision 435): the opcodes and BIFs 144
//! B-00b's measurement lists (`AGENTS.md` § Measured), growing by a measured
//! need, never by OTP's size. Anything else — an opcode, a call to a function
//! the runtime has no BIF for, an operand or a literal of another kind — is a
//! `refused` answer naming what is missing, which the compiler reports at the
//! call site of the function the code serves.
const std = @import("std");

pub const chunks = @import("chunks.zig");
pub const code = @import("code.zig");
pub const ir = @import("ir.zig");
pub const lower = @import("lower.zig");

pub const Bif = lower.Bif;
pub const runtime = lower.runtime;

pub const Result = union(enum) {
    ok: ir.Module,
    /// What is not converted: an opcode (`opcode 4 (call)`), a call
    /// (`` `re:run/3` ``), a malformed file.
    refused: []const u8,
};

/// Translate the `.beam` file `bytes`, BIF calls resolved by `bifs`.
/// Everything answered lives in `arena`.
pub fn translate(arena: std.mem.Allocator, bytes: []const u8, bifs: []const Bif) error{OutOfMemory}!Result {
    const beam = chunks.read(arena, bytes) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.BadBeam => return .{ .refused = "a file that does not read as BEAM" },
    };
    // A call outside the runtime's BIFs is named before anything else: what
    // the code calls is what a reader can act on.
    for (beam.imports) |imp| {
        for (bifs) |b| {
            if (b.arity == imp.arity and std.mem.eql(u8, b.module, imp.module) and std.mem.eql(u8, b.name, imp.function)) break;
        } else return .{ .refused = try std.fmt.allocPrint(arena, "`{s}:{s}/{d}`", .{ imp.module, imp.function, imp.arity }) };
    }
    const decoded = code.decode(arena, beam.code) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.BadBeam => return .{ .refused = "a Code chunk that does not decode" },
    };
    if (decoded.unknown) |op| return .{ .refused = try std.fmt.allocPrint(arena, "opcode {d}{s}", .{ op, opcodeName(op) }) };
    var l: lower.Lowerer = .{ .ar = arena, .beam = beam, .bifs = bifs };
    const functions = l.lowerAll(decoded.instrs) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Refused => return .{ .refused = l.refusal },
    };
    return .{ .ok = .{ .name = beam.moduleName(), .functions = functions } };
}

/// ` (<name>)` for an opcode a refusal names, when it is one BEAM code
/// commonly holds; empty otherwise.
fn opcodeName(op: u8) []const u8 {
    return switch (op) {
        4 => " (call)",
        5 => " (call_last)",
        6 => " (call_only)",
        8 => " (call_ext_last)",
        9 => " (bif0)",
        10 => " (bif1)",
        11 => " (bif2)",
        39 => " (is_lt)",
        43 => " (is_eq_exact)",
        52 => " (is_nil)",
        57 => " (is_tuple)",
        59 => " (select_val)",
        65 => " (get_list)",
        66 => " (get_tuple_element)",
        78 => " (call_ext_only)",
        103 => " (make_fun2)",
        104 => " (try)",
        125 => " (gc_bif2)",
        153 => " (line)",
        164 => " (put_tuple2)",
        171 => " (make_fun3)",
        177 => " (bs_create_bin)",
        else => "",
    };
}

const test_bifs = [_]Bif{
    .{ .module = "erlang", .name = "iolist_to_binary", .arity = 1, .rt = "rt_erlang_iolist_to_binary" },
    .{ .module = "erlang", .name = "error", .arity = 1, .rt = "rt_error" },
};

test {
    _ = chunks;
    _ = code;
}

test "translate: a cell the compiler assembled, one function over the measured subset" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const r = try translate(arena_state.allocator(), @embedFile("testdata/bp_cell_bang.beam"), &test_bifs);
    const m = r.ok;
    try std.testing.expectEqualStrings("bp_cell_bang", m.name);
    try std.testing.expectEqual(@as(usize, 1), m.functions.len);
    const f = m.functions[0];
    try std.testing.expectEqualStrings("t/1", f.name);
    try std.testing.expectEqual(@as(u32, 1), f.arity);
    try std.testing.expectEqual(@as(u32, 2), f.y_regs);
    // pc = entry label 2, then the raise block, then the raised answer.
    try std.testing.expectEqual(ir.Instr{ .i32_const = 2 }, f.body[0]);
    try std.testing.expectEqualStrings("raise", f.body[2].block.label);
    try std.testing.expect(f.body[2].block.body[0].block.loop);
}

/// Every runtime call a translated body makes, in order.
fn rtCalls(ar: std.mem.Allocator, body: []const ir.Instr, out: *std.ArrayListUnmanaged([]const u8)) !void {
    for (body) |i| switch (i) {
        .rt => |n| try out.append(ar, n),
        .block => |b| try rtCalls(ar, b.body, out),
        else => {},
    };
}

test "translate: call_ext binds the BIF, put_list conses, is_binary tests, literals materialise" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const r = try translate(ar, @embedFile("testdata/bp_cell_wrap.beam"), &test_bifs);
    var calls: std.ArrayListUnmanaged([]const u8) = .empty;
    try rtCalls(ar, r.ok.functions[0].body, &calls);
    const want = [_][]const u8{
        "rt_function_clause", // label 1: func_info
        "rt_is", // label 2: is_binary
        "rt_bin", "rt_cons", // put_list <<">">>, nil
        "rt_cons", // put_list y0
        "rt_bin", "rt_cons", // put_list <<"<">>
        "rt_erlang_iolist_to_binary", "rt_pending", // call_ext + raise test
        "rt_atom", "rt_error", "rt_pending", // label 5: error(badarg)
    };
    // `nil` in `put_list` is the runtime's `rt_nil`.
    var filtered: std.ArrayListUnmanaged([]const u8) = .empty;
    for (calls.items) |c| if (!std.mem.eql(u8, c, "rt_nil")) try filtered.append(ar, c);
    try std.testing.expectEqual(want.len, filtered.items.len);
    for (want, filtered.items) |w, g| try std.testing.expectEqualStrings(w, g);
}

test "translate: a call the runtime has no BIF for is refused, named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const only_error = [_]Bif{test_bifs[1]};
    const r = try translate(arena_state.allocator(), @embedFile("testdata/bp_cell_bang.beam"), &only_error);
    try std.testing.expectEqualStrings("`erlang:iolist_to_binary/1`", r.refused);
}

test "translate: an opcode outside the subset is refused, named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    // The bang cell with its first `allocate` (12) patched to `call` (4).
    const original = @embedFile("testdata/bp_cell_bang.beam");
    const bytes = try ar.dupe(u8, original);
    const beam = try chunks.read(ar, original);
    const code_at = @intFromPtr(beam.code.ptr) - @intFromPtr(original.ptr);
    const at = std.mem.indexOfScalarPos(u8, bytes, code_at, 12).?;
    bytes[at] = 4;
    const r = try translate(ar, bytes, &test_bifs);
    try std.testing.expectEqualStrings("opcode 4 (call)", r.refused);
}

test "translate: not a BEAM file" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const r = try translate(arena_state.allocator(), "not beam", &test_bifs);
    try std.testing.expectEqualStrings("a file that does not read as BEAM", r.refused);
}
