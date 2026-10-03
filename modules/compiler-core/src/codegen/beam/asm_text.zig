//! `beam_file.zig`'s instruction model rendered as BEAM assembly text — the
//! `.S` form `erlc -S` writes and `erlc +from_asm` reads back.
//!
//! The comptime BEAM lowering (`comptime/runtime/beam/lower.zig`) builds one
//! `beam_file.Module` and makes two things of it: the `.beam` bytes the
//! resident node loads (`beam_file.assemble`) and this text, which is what a
//! `COMPTIME BEAM ASSEMBLY` snapshot section shows. One model, two renderers,
//! so the listing cannot describe a program other than the one that ran —
//! and `scripts/beam_export_audit.sh` can hand the listing to `erlc +from_asm`,
//! whose `beam_validator` checks what the loader does not.
//!
//! Each opcode is written in the generic shape `beam_disasm`/`erlc -S` use
//! (`{test, is_eq_exact, {f, L}, [A, B]}`, `{bif, Name, {f, L}, Args, Dst}`,
//! `{gc_bif, Name, {f, L}, Live, Args, Dst}`, `{make_fun3, {f, L}, Index,
//! OldUniq, Dst, {list, Env}}`); an opcode this renderer has no shape for is
//! `error.UnrenderedOpcode`, never guessed.
const std = @import("std");
const bf = @import("beam_file.zig");
const erlEmitter = @import("erl_emitter.zig");
const Term = @import("term.zig").Term;

const Writer = std.Io.Writer;

pub const Error = erlEmitter.Error || error{UnrenderedOpcode};

/// The whole module: header, exports, `{labels, N}`, then every function.
pub fn writeModule(w: *Writer, m: bf.Module) Error!void {
    try w.writeAll("{module, ");
    try erlEmitter.writeAtom(w, m.name);
    try w.writeAll("}.\n{exports, [");
    var first = true;
    for (m.functions) |f| {
        if (!f.exported) continue;
        if (!first) try w.writeAll(", ");
        first = false;
        try w.writeByte('{');
        try erlEmitter.writeAtom(w, f.name);
        try w.print(", {d}}}", .{f.arity});
    }
    try w.writeAll("]}.\n{attributes, []}.\n");
    try w.print("{{labels, {d}}}.\n", .{labelCount(m)});
    var lambda_index: std.AutoArrayHashMapUnmanaged(u32, void) = .empty;
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    for (m.functions) |f| {
        try w.writeAll("\n{function, ");
        try erlEmitter.writeAtom(w, f.name);
        try w.print(", {d}, {d}}}.\n", .{ f.arity, f.entry });
        for (f.code) |ins| {
            if (ins.op == .label) {
                try w.print("  {{label, {d}}}.\n", .{ins.args[0].u});
                continue;
            }
            try w.writeAll("    ");
            // `make_fun3` names its `FunT` row, which the assembler numbers
            // by first use of the entry label; the text says the same.
            const index: ?usize = if (ins.op == .make_fun3) blk: {
                const gop = lambda_index.getOrPut(fba.allocator(), ins.args[0].f) catch return error.UnrenderedOpcode;
                break :blk gop.index;
            } else null;
            try writeInstr(w, ins, index);
            try w.writeAll(".\n");
        }
    }
}

fn labelCount(m: bf.Module) u32 {
    var max: u32 = 0;
    for (m.functions) |f| for (f.code) |ins| {
        if (ins.op == .label) max = @max(max, @as(u32, @intCast(ins.args[0].u)));
    };
    return max + 1;
}

fn writeInstr(w: *Writer, ins: bf.Instr, fun_index: ?usize) Error!void {
    const a = ins.args;
    switch (ins.op) {
        .@"return", .if_end, .raw_raise, .build_stacktrace, .send, .remove_message, .timeout => try w.writeAll(@tagName(ins.op)),
        .func_info, .call, .call_last, .call_ext, .call_ext_last, .call_ext_only, .call_only, .allocate, .deallocate, .test_heap, .move, .jump, .get_list, .get_tuple_element, .put_list, .badmatch, .case_end, .call_fun, .try_end, .try_case, .try_case_end, .init_yregs, .put_tuple2, .loop_rec, .loop_rec_end, .wait, .wait_timeout, .catch_end => {
            try w.writeByte('{');
            try w.writeAll(@tagName(ins.op));
            for (a) |arg| {
                try w.writeAll(", ");
                try writeArg(w, arg);
            }
            try w.writeByte('}');
        },
        .@"catch" => {
            try w.writeAll("{'catch', ");
            try writeArg(w, a[0]);
            try w.writeAll(", ");
            try writeArg(w, a[1]);
            try w.writeByte('}');
        },
        .@"try" => {
            try w.writeAll("{'try', ");
            try writeArg(w, a[0]);
            try w.writeAll(", ");
            try writeArg(w, a[1]);
            try w.writeByte('}');
        },
        .get_map_elements, .has_map_fields => {
            try w.print("{{{s}, ", .{@tagName(ins.op)});
            try writeArgs(w, a);
            try w.writeByte('}');
        },
        .put_map_assoc, .put_map_exact => {
            try w.print("{{{s}, ", .{@tagName(ins.op)});
            try writeArgs(w, a);
            try w.writeByte('}');
        },
        .make_fun3 => {
            try w.writeAll("{make_fun3, ");
            try writeArg(w, a[0]);
            try w.print(", {d}, 0, ", .{fun_index orelse 0});
            try writeArg(w, a[1]);
            try w.writeAll(", ");
            try writeArg(w, a[2]);
            try w.writeByte('}');
        },
        .bif0 => {
            try w.writeAll("{bif, ");
            try erlEmitter.writeAtom(w, a[0].ext.function);
            try w.writeAll(", nofail, [], ");
            try writeArg(w, a[1]);
            try w.writeByte('}');
        },
        .bif1, .bif2 => {
            try w.writeAll("{bif, ");
            try erlEmitter.writeAtom(w, a[1].ext.function);
            try w.writeAll(", ");
            try writeArg(w, a[0]);
            try w.writeAll(", [");
            try writeArgs(w, a[2 .. a.len - 1]);
            try w.writeAll("], ");
            try writeArg(w, a[a.len - 1]);
            try w.writeByte('}');
        },
        .gc_bif1, .gc_bif2, .gc_bif3 => {
            try w.writeAll("{gc_bif, ");
            try erlEmitter.writeAtom(w, a[2].ext.function);
            try w.writeAll(", ");
            try writeArg(w, a[0]);
            try w.writeAll(", ");
            try writeArg(w, a[1]);
            try w.writeAll(", [");
            try writeArgs(w, a[3 .. a.len - 1]);
            try w.writeAll("], ");
            try writeArg(w, a[a.len - 1]);
            try w.writeByte('}');
        },
        .is_lt, .is_ge, .is_eq, .is_ne, .is_eq_exact, .is_ne_exact, .is_integer, .is_float, .is_number, .is_atom, .is_pid, .is_reference, .is_port, .is_nil, .is_binary, .is_list, .is_nonempty_list, .is_tuple, .test_arity, .is_function, .is_boolean, .is_function2, .is_bitstr, .is_map, .is_tagged_tuple => {
            try w.writeAll("{test, ");
            try w.writeAll(if (ins.op == .is_bitstr) "is_bitstr" else @tagName(ins.op));
            try w.writeAll(", ");
            try writeArg(w, a[0]);
            try w.writeAll(", [");
            try writeArgs(w, a[1..]);
            try w.writeAll("]}");
        },
        else => return error.UnrenderedOpcode,
    }
}

fn writeArgs(w: *Writer, args: []const bf.Arg) Error!void {
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try writeArg(w, arg);
    }
}

fn writeArg(w: *Writer, arg: bf.Arg) Error!void {
    switch (arg) {
        .u => |n| try w.print("{d}", .{n}),
        .i => |n| try w.print("{{integer, {d}}}", .{n}),
        .atom => |name| {
            try w.writeAll("{atom, ");
            try erlEmitter.writeAtom(w, name);
            try w.writeByte('}');
        },
        .nil => try w.writeAll("nil"),
        .x => |n| try w.print("{{x, {d}}}", .{n}),
        .y => |n| try w.print("{{y, {d}}}", .{n}),
        .f => |n| try w.print("{{f, {d}}}", .{n}),
        .literal => |t| try writeLiteral(w, t),
        .ext => |e| {
            try w.writeAll("{extfunc, ");
            try erlEmitter.writeAtom(w, e.module);
            try w.writeAll(", ");
            try erlEmitter.writeAtom(w, e.function);
            try w.print(", {d}}}", .{e.arity});
        },
        .list => |items| {
            try w.writeAll("{list, [");
            try writeArgs(w, items);
            try w.writeAll("]}");
        },
        .alloc => |al| try w.print("{{alloc, [{{words, {d}}}, {{floats, {d}}}, {{funs, {d}}}]}}", .{ al.words, al.floats, al.funs }),
        .line => |n| try w.print("[{{location, \"module\", {d}}}]", .{n}),
    }
}

/// `{literal, T}` with the folding the assembler applies: an atom, an integer
/// and `[]` are immediate operands; a float is `{float, F}`.
fn writeLiteral(w: *Writer, t: Term) Error!void {
    switch (t) {
        .atom => |name| {
            try w.writeAll("{atom, ");
            try erlEmitter.writeAtom(w, name);
            try w.writeByte('}');
        },
        .boolean => |b| try w.writeAll(if (b) "{atom, true}" else "{atom, false}"),
        .integer => |n| try w.print("{{integer, {d}}}", .{n}),
        .nil => try w.writeAll("nil"),
        .list => |items| if (items.len == 0) try w.writeAll("nil") else {
            try w.writeAll("{literal, ");
            try erlEmitter.writeTerm(w, t);
            try w.writeByte('}');
        },
        .float => |f| {
            try w.writeAll("{float, ");
            try erlEmitter.writeFloat(w, f);
            try w.writeByte('}');
        },
        .binary, .tuple, .map => {
            try w.writeAll("{literal, ");
            try erlEmitter.writeTerm(w, t);
            try w.writeByte('}');
        },
    }
}

test "asm_text: a function renders in erlc's .S shapes" {
    const code = [_]bf.Instr{
        bf.Instr.of(.label, &.{bf.Arg.uint(1)}),
        bf.Instr.of(.func_info, &.{ bf.Arg.atomOf("m"), bf.Arg.atomOf("f"), bf.Arg.uint(1) }),
        bf.Instr.of(.label, &.{bf.Arg.uint(2)}),
        bf.Instr.of(.is_eq_exact, &.{ bf.Arg.lbl(1), bf.Arg.xr(0), bf.Arg.lit(Term.str("a")) }),
        bf.Instr.of(.gc_bif1, &.{ bf.Arg.lbl(0), bf.Arg.uint(1), bf.Arg.extFn("erlang", "byte_size", 1), bf.Arg.xr(0), bf.Arg.xr(0) }),
        bf.Instr.of(.@"return", &.{}),
    };
    const functions = [_]bf.Function{.{ .name = "f", .arity = 1, .entry = 2, .code = &code }};
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeModule(&aw.writer, .{ .name = "m", .functions = &functions });
    try std.testing.expectEqualStrings(
        \\{module, m}.
        \\{exports, [{f, 1}]}.
        \\{attributes, []}.
        \\{labels, 3}.
        \\
        \\{function, f, 1, 2}.
        \\  {label, 1}.
        \\    {func_info, {atom, m}, {atom, f}, 1}.
        \\  {label, 2}.
        \\    {test, is_eq_exact, {f, 1}, [{x, 0}, {literal, <<"a">>}]}.
        \\    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
        \\    return.
        \\
    , aw.written());
}
