//! The WAT runtime helpers, as built nodes.
//!
//! wasm has no opcode for printing, string concatenation, string equality or a
//! bounds-checked array read, so the backend synthesises a small set of
//! functions into every module that needs one. They used to be the most-copied
//! text in `wat.zig` — eight multi-line string literals, several hundred lines
//! of hand-written WAT, with the same five defect classes one edit away.
//!
//! Here they are `wat_ast.Func` values like any other function the backend
//! emits: their locals sit in the function node, their `if` arms declare what
//! they leave on the stack, and their calls to each other are checked by
//! `wat_ast.validateModule` along with everything else.
//!
//! Helpers come in **groups** (`wat_ast.HelperGroup`): a group is emitted whole
//! or not at all, because its members call each other. A caller never names a
//! helper directly — `wat_ast.Builder.helper` hands out the symbol *and* marks
//! its group, so a module cannot call a helper it does not define.
//!
//! The scratch layout the print helpers assume, below the data section (which
//! starts at 256): `0..8` the WASI iovec, `8` the newline byte, `16..32` the
//! bool text, `32..64` the float fraction, `64..128` the i32 digits.

const std = @import("std");
const ast = @import("wat_ast.zig");

/// The forms of one helper group, in emission order: the functions plus the
/// comment lines that sit between them.
pub fn items(g: ast.HelperGroup) []const ast.Item {
    return switch (g) {
        .print => &print_items,
        .print_str => &print_str_items,
        .print_bool => &print_bool_items,
        .print_f64 => &print_f64_items,
        .arr_at => &arr_at_items,
        .str_concat => &str_concat_items,
        .str_eq => &str_eq_items,
        .str_slice => &str_slice_items,
        .print_arr_i32 => &.{ .{ .func = print_arr_i32_raw }, .{ .func = print_arr_i32 } },
        .print_arr_f32 => &.{ .{ .func = print_arr_f32_raw }, .{ .func = print_arr_f32 } },
        .assert_fail => &.{ .{ .func = write_err }, .{ .func = assert_fail } },
        .print_opt => &.{
            .{ .func = print_undefined },    .{ .func = print_opt_i32_raw }, .{ .func = print_opt_i32 },
            .{ .func = print_opt_bool_raw }, .{ .func = print_opt_bool },    .{ .func = print_opt_str_raw },
            .{ .func = print_opt_str },
        },
        inline else => |t| &.{.{ .func = @field(@This(), @tagName(t)) }},
    };
}

/// The order groups are appended to a module. `print` first: the others call
/// into it. The groups added after `str_slice` follow in declaration order, so
/// a module that uses none of them renders exactly as before they existed.
pub const order = blk: {
    const all = std.enums.values(ast.HelperGroup);
    var out: [all.len]ast.HelperGroup = undefined;
    for (all, 0..) |g, i| out[i] = g;
    break :blk out;
};

/// `fd_write`, the one host function the print helpers need.
pub const fd_write_import = ast.Import{
    .module = "wasi_snapshot_preview1",
    .name = "fd_write",
    .func = "fd_write",
    .type = .{ .params = &.{ .i32, .i32, .i32, .i32 }, .result = .i32 },
};

// ── the helpers ──────────────────────────────────────────────────────────────

const write_bytes = ast.Func{
    .name = "__write_bytes",
    .params = &.{ .{ .name = "p", .ty = .i32 }, .{ .name = "n", .ty = .i32 } },
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .local_get = "p" } },
        .{ .indent = 4, .instr = .{ .store = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .local_get = "n" } },
        .{ .indent = 4, .instr = .{ .store = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "8" } } },
        .{ .indent = 4, .instr = .{ .call = "fd_write" } },
        .{ .indent = 4, .instr = .drop },
    } },
};

const print_nl = ast.Func{
    .name = "__print_nl",
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "8" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "10" } } },
        .{ .indent = 4, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "8" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
        .{ .indent = 4, .instr = .{ .call = "__write_bytes" } },
    } },
};

const print_sp = ast.Func{
    .name = "__print_sp",
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "8" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "32" } } },
        .{ .indent = 4, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "8" } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
        .{ .indent = 4, .instr = .{ .call = "__write_bytes" } },
    } },
};

const print_i32 = ast.Func{
    .name = "__print_i32",
    .params = &.{.{ .name = "n", .ty = .i32 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "n" } },
        .{ .indent = 4, .instr = .{ .call = "__print_i32_raw" } },
        .{ .indent = 4, .instr = .{ .call = "__print_nl" } },
    } },
};

const print_i32_raw = ast.Func{
    .name = "__print_i32_raw",
    .params = &.{.{ .name = "n", .ty = .i32 }},
    .locals = &.{ &.{ .{ .name = "buf", .ty = .i32 }, .{ .name = "len", .ty = .i32 }, .{ .name = "neg", .ty = .i32 }, .{ .name = "d", .ty = .i32 } }, &.{ .{ .name = "i", .ty = .i32 }, .{ .name = "j", .ty = .i32 }, .{ .name = "tmp", .ty = .i32 } } },
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "64" } } },
        .{ .indent = 4, .instr = .{ .local_set = "buf" } },
        .{ .indent = 4, .instr = .{ .local_get = "n" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "lt_s" } } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .indent = 8, .instr = .{ .local_set = "neg" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
                .{ .indent = 8, .instr = .{ .local_get = "n" } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "sub" } } },
                .{ .indent = 8, .instr = .{ .local_set = "n" } },
            } } },
        } } },
        .{ .indent = 4, .instr = .{ .block = .{
            .kind = .block,
            .label = "done",
            .body = .{ .stack = .none, .lines = &.{
                .{ .indent = 6, .instr = .{ .block = .{
                    .kind = .loop,
                    .label = "digits",
                    .body = .{ .stack = .none, .lines = &.{
                        .{ .indent = 8, .instr = .{ .local_get = "n" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "10" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "rem_u" } } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "48" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "d" } },
                        .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                        .{ .indent = 8, .instr = .{ .local_get = "len" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_get = "d" } },
                        .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .local_get = "len" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "len" } },
                        .{ .indent = 8, .instr = .{ .local_get = "n" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "10" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "div_u" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "n" } },
                        .{ .indent = 8, .instr = .{ .local_get = "n" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "gt_u" } } },
                        .{ .indent = 8, .instr = .{ .br_if = "digits" } },
                    } },
                } } },
            } },
        } } },
        .{ .indent = 4, .instr = .{ .comment = "reverse" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .local_set = "i" } },
        .{ .indent = 4, .instr = .{ .local_get = "len" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "sub" } } },
        .{ .indent = 4, .instr = .{ .local_set = "j" } },
        .{ .indent = 4, .instr = .{ .block = .{
            .kind = .block,
            .label = "rdone",
            .body = .{ .stack = .none, .lines = &.{
                .{ .indent = 6, .instr = .{ .block = .{
                    .kind = .loop,
                    .label = "rev",
                    .body = .{ .stack = .terminated, .lines = &.{
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .local_get = "j" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "ge_u" } } },
                        .{ .indent = 8, .instr = .{ .br_if = "rdone" } },
                        .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .local_set = "tmp" } },
                        .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                        .{ .indent = 8, .instr = .{ .local_get = "j" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                        .{ .indent = 8, .instr = .{ .local_get = "j" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_get = "tmp" } },
                        .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "i" } },
                        .{ .indent = 8, .instr = .{ .local_get = "j" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "sub" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "j" } },
                        .{ .indent = 8, .instr = .{ .br = "rev" } },
                    } },
                } } },
            } },
        } } },
        .{ .indent = 4, .instr = .{ .comment = "add neg sign + newline" } },
        .{ .indent = 4, .instr = .{ .comment = "shift the digits one byte right to make room for '-'" } },
        .{ .indent = 4, .instr = .{ .comment = "(dst = buf+1, NOT buf+len: the latter moved them `len`" } },
        .{ .indent = 4, .instr = .{ .comment = " bytes and printed -12 as -21)" } },
        .{ .indent = 4, .instr = .{ .local_get = "neg" } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                .{ .indent = 8, .instr = .{ .local_get = "len" } },
                .{ .indent = 8, .instr = .{ .call = "__memmove" } },
                .{ .indent = 8, .instr = .{ .local_get = "buf" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "45" } } },
                .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                .{ .indent = 8, .instr = .{ .local_get = "len" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                .{ .indent = 8, .instr = .{ .local_set = "len" } },
            } } },
        } } },
        .{ .indent = 4, .instr = .{ .local_get = "buf" } },
        .{ .indent = 4, .instr = .{ .local_get = "len" } },
        .{ .indent = 4, .instr = .{ .call = "__write_bytes" } },
    } },
};

const memmove = ast.Func{
    .name = "__memmove",
    .params = &.{ .{ .name = "dst", .ty = .i32 }, .{ .name = "src", .ty = .i32 }, .{ .name = "len", .ty = .i32 } },
    .locals = &.{&.{.{ .name = "i", .ty = .i32 }}},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "len" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "sub" } } },
        .{ .indent = 4, .instr = .{ .local_set = "i" } },
        .{ .indent = 4, .instr = .{ .block = .{
            .kind = .block,
            .label = "done",
            .body = .{ .stack = .none, .lines = &.{
                .{ .indent = 6, .instr = .{ .block = .{
                    .kind = .loop,
                    .label = "loop",
                    .body = .{ .stack = .terminated, .lines = &.{
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "lt_s" } } },
                        .{ .indent = 8, .instr = .{ .br_if = "done" } },
                        .{ .indent = 8, .instr = .{ .local_get = "dst" } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_get = "src" } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "sub" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "i" } },
                        .{ .indent = 8, .instr = .{ .br = "loop" } },
                    } },
                } } },
            } },
        } } },
    } },
};

const print_str_raw = ast.Func{
    .name = "__print_str_raw",
    .params = &.{.{ .name = "s", .ty = .i32 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "s" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "s" } },
        .{ .indent = 4, .instr = .{ .load = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .call = "__write_bytes" } },
    } },
};

const print_str = ast.Func{
    .name = "__print_str",
    .params = &.{.{ .name = "s", .ty = .i32 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "s" } },
        .{ .indent = 4, .instr = .{ .call = "__print_str_raw" } },
        .{ .indent = 4, .instr = .{ .call = "__print_nl" } },
    } },
};

const print_bool = ast.Func{
    .name = "__print_bool",
    .params = &.{.{ .name = "b", .ty = .i32 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "b" } },
        .{ .indent = 4, .instr = .{ .call = "__print_bool_raw" } },
        .{ .indent = 4, .instr = .{ .call = "__print_nl" } },
    } },
};

const print_bool_raw = ast.Func{
    .name = "__print_bool_raw",
    .params = &.{.{ .name = "b", .ty = .i32 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "b" } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .comment = "\"true\" as a little-endian i32" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "16" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1702195828" } } },
                .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32 } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "16" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
                .{ .indent = 8, .instr = .{ .call = "__write_bytes" } },
            } } },
            .@"else" = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .comment = "\"fals\" + 'e'" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "16" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1936482662" } } },
                .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32 } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "16" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "101" } } },
                .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte, .offset = 4 } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "16" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "5" } } },
                .{ .indent = 8, .instr = .{ .call = "__write_bytes" } },
            } } },
        } } },
    } },
};

const print_f64 = ast.Func{
    .name = "__print_f64",
    .params = &.{.{ .name = "x", .ty = .f64 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "x" } },
        .{ .indent = 4, .instr = .{ .call = "__print_f64_raw" } },
        .{ .indent = 4, .instr = .{ .call = "__print_nl" } },
    } },
};

const print_f64_raw = ast.Func{
    .name = "__print_f64_raw",
    .params = &.{.{ .name = "x", .ty = .f64 }},
    .locals = &.{&.{ .{ .name = "i", .ty = .i32 }, .{ .name = "frac", .ty = .f64 }, .{ .name = "d", .ty = .i32 }, .{ .name = "k", .ty = .i32 }, .{ .name = "last", .ty = .i32 } }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "x" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .f64, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .f64, .name = "lt" } } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "32" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "45" } } },
                .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "32" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .indent = 8, .instr = .{ .call = "__write_bytes" } },
                .{ .indent = 8, .instr = .{ .local_get = "x" } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .f64, .name = "neg" } } },
                .{ .indent = 8, .instr = .{ .local_set = "x" } },
            } } },
        } } },
        .{ .indent = 4, .instr = .{ .local_get = "x" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "trunc_f64_s" } } },
        .{ .indent = 4, .instr = .{ .local_set = "i" } },
        .{ .indent = 4, .instr = .{ .local_get = "x" } },
        .{ .indent = 4, .instr = .{ .local_get = "i" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .f64, .name = "convert_i32_s" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .f64, .name = "sub" } } },
        .{ .indent = 4, .instr = .{ .local_set = "frac" } },
        .{ .indent = 4, .instr = .{ .local_get = "i" } },
        .{ .indent = 4, .instr = .{ .call = "__print_i32_raw" } },
        .{ .indent = 4, .instr = .{ .comment = "fractional digits into 34.. ; 33 holds the '.'" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .local_set = "k" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .local_set = "last" } },
        .{ .indent = 4, .instr = .{ .block = .{
            .kind = .block,
            .label = "fdone",
            .body = .{ .stack = .none, .lines = &.{
                .{ .indent = 6, .instr = .{ .block = .{
                    .kind = .loop,
                    .label = "fdigits",
                    .body = .{ .stack = .terminated, .lines = &.{
                        .{ .indent = 8, .instr = .{ .local_get = "k" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "6" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "ge_s" } } },
                        .{ .indent = 8, .instr = .{ .br_if = "fdone" } },
                        .{ .indent = 8, .instr = .{ .local_get = "frac" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .f64, .text = "10" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .f64, .name = "mul" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "frac" } },
                        .{ .indent = 8, .instr = .{ .local_get = "frac" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "trunc_f64_s" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "d" } },
                        .{ .indent = 8, .instr = .{ .local_get = "frac" } },
                        .{ .indent = 8, .instr = .{ .local_get = "d" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .f64, .name = "convert_i32_s" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .f64, .name = "sub" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "frac" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "34" } } },
                        .{ .indent = 8, .instr = .{ .local_get = "k" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_get = "d" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "48" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                        .{ .indent = 8, .instr = .{ .local_get = "k" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "k" } },
                        .{ .indent = 8, .instr = .{ .local_get = "d" } },
                        .{ .indent = 8, .instr = .{ .@"if" = .{
                            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                                .{ .indent = 12, .instr = .{ .local_get = "k" } },
                                .{ .indent = 12, .instr = .{ .local_set = "last" } },
                            } } },
                        } } },
                        .{ .indent = 8, .instr = .{ .br = "fdigits" } },
                    } },
                } } },
            } },
        } } },
        .{ .indent = 4, .instr = .{ .local_get = "last" } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "33" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "46" } } },
                .{ .indent = 8, .instr = .{ .store = .{ .ty = .i32, .width = .byte } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "33" } } },
                .{ .indent = 8, .instr = .{ .local_get = "last" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                .{ .indent = 8, .instr = .{ .call = "__write_bytes" } },
            } } },
        } } },
    } },
};

const arr_at = ast.Func{
    .name = "__arr_at",
    .params = &.{ .{ .name = "xs", .ty = .i32 }, .{ .name = "i", .ty = .i32 } },
    .result = .i32,
    .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "i" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "lt_s" } } },
        .{ .indent = 4, .instr = .{ .local_get = "i" } },
        .{ .indent = 4, .instr = .{ .local_get = "xs" } },
        .{ .indent = 4, .instr = .{ .load = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "ge_s" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "or" } } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .result = .i32,
            .then = .{ .layout = .inline_, .seq = .{ .stack = .{ .value = .i32 }, .lines = &.{.{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } }} } },
            .@"else" = .{ .seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
                .{ .indent = 8, .instr = .{ .local_get = "xs" } },
                .{ .indent = 8, .instr = .{ .local_get = "i" } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "mul" } } },
                .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32 } } },
            } } },
        } } },
    } },
};

const str_concat = ast.Func{
    .name = "__str_concat",
    .params = &.{ .{ .name = "a", .ty = .i32 }, .{ .name = "b", .ty = .i32 } },
    .result = .i32,
    .locals = &.{&.{ .{ .name = "base", .ty = .i32 }, .{ .name = "alen", .ty = .i32 }, .{ .name = "blen", .ty = .i32 } }},
    .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "a" } },
        .{ .indent = 4, .instr = .{ .load = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .local_set = "alen" } },
        .{ .indent = 4, .instr = .{ .local_get = "b" } },
        .{ .indent = 4, .instr = .{ .load = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .local_set = "blen" } },
        .{ .indent = 4, .instr = .{ .global_get = "__heap_ptr" } },
        .{ .indent = 4, .instr = .{ .local_set = "base" } },
        .{ .indent = 4, .instr = .{ .comment = "bump heap by 4 (length prefix) + alen + blen" } },
        .{ .indent = 4, .instr = .{ .global_get = "__heap_ptr" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .local_get = "alen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "blen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .global_set = "__heap_ptr" } },
        .{ .indent = 4, .instr = .{ .comment = "store combined length prefix" } },
        .{ .indent = 4, .instr = .{ .local_get = "base" } },
        .{ .indent = 4, .instr = .{ .local_get = "alen" } },
        .{ .indent = 4, .instr = .{ .local_get = "blen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .store = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .comment = "copy a's bytes: base+4 <- a+4" } },
        .{ .indent = 4, .instr = .{ .local_get = "base" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "a" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "alen" } },
        .{ .indent = 4, .instr = .memory_copy },
        .{ .indent = 4, .instr = .{ .comment = "copy b's bytes: base+4+alen <- b+4" } },
        .{ .indent = 4, .instr = .{ .local_get = "base" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "alen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "b" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "blen" } },
        .{ .indent = 4, .instr = .memory_copy },
        .{ .indent = 4, .instr = .{ .local_get = "base" } },
    } },
};

const str_eq = ast.Func{
    .name = "__str_eq",
    .params = &.{ .{ .name = "a", .ty = .i32 }, .{ .name = "b", .ty = .i32 } },
    .result = .i32,
    .locals = &.{&.{ .{ .name = "i", .ty = .i32 }, .{ .name = "alen", .ty = .i32 } }},
    .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "a" } },
        .{ .indent = 4, .instr = .{ .load = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .local_set = "alen" } },
        .{ .indent = 4, .instr = .{ .local_get = "alen" } },
        .{ .indent = 4, .instr = .{ .local_get = "b" } },
        .{ .indent = 4, .instr = .{ .load = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "ne" } } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .layout = .inline_, .seq = .{ .stack = .terminated, .lines = &.{ .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } }, .{ .instr = .@"return" } } } },
        } } },
        .{ .indent = 4, .instr = .{ .block = .{
            .kind = .block,
            .label = "done",
            .body = .{ .stack = .none, .lines = &.{
                .{ .indent = 6, .instr = .{ .block = .{
                    .kind = .loop,
                    .label = "cmp",
                    .body = .{ .stack = .terminated, .lines = &.{
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .local_get = "alen" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "ge_u" } } },
                        .{ .indent = 8, .instr = .{ .br_if = "done" } },
                        .{ .indent = 8, .instr = .{ .local_get = "a" } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32, .width = .byte, .offset = 4 } } },
                        .{ .indent = 8, .instr = .{ .local_get = "b" } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32, .width = .byte, .offset = 4 } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "ne" } } },
                        .{ .indent = 8, .instr = .{ .@"if" = .{
                            .then = .{ .layout = .inline_, .seq = .{ .stack = .terminated, .lines = &.{ .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } }, .{ .instr = .@"return" } } } },
                        } } },
                        .{ .indent = 8, .instr = .{ .local_get = "i" } },
                        .{ .indent = 8, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
                        .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                        .{ .indent = 8, .instr = .{ .local_set = "i" } },
                        .{ .indent = 8, .instr = .{ .br = "cmp" } },
                    } },
                } } },
            } },
        } } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } },
    } },
};

const str_slice = ast.Func{
    .name = "__str_slice",
    .params = &.{ .{ .name = "src", .ty = .i32 }, .{ .name = "start", .ty = .i32 }, .{ .name = "end", .ty = .i32 } },
    .result = .i32,
    .locals = &.{&.{ .{ .name = "newlen", .ty = .i32 }, .{ .name = "dst", .ty = .i32 } }},
    .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "end" } },
        .{ .indent = 4, .instr = .{ .local_get = "start" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "sub" } } },
        .{ .indent = 4, .instr = .{ .local_set = "newlen" } },
        .{ .indent = 4, .instr = .{ .global_get = "__heap_ptr" } },
        .{ .indent = 4, .instr = .{ .local_set = "dst" } },
        .{ .indent = 4, .instr = .{ .comment = "bump heap by 4 (length prefix) + newlen" } },
        .{ .indent = 4, .instr = .{ .global_get = "__heap_ptr" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .local_get = "newlen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .global_set = "__heap_ptr" } },
        .{ .indent = 4, .instr = .{ .comment = "store length prefix" } },
        .{ .indent = 4, .instr = .{ .local_get = "dst" } },
        .{ .indent = 4, .instr = .{ .local_get = "newlen" } },
        .{ .indent = 4, .instr = .{ .store = .{ .ty = .i32 } } },
        .{ .indent = 4, .instr = .{ .comment = "copy bytes: dst+4 <- src+4+start" } },
        .{ .indent = 4, .instr = .{ .local_get = "dst" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "src" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "start" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "newlen" } },
        .{ .indent = 4, .instr = .memory_copy },
        .{ .indent = 4, .instr = .{ .local_get = "dst" } },
    } },
};

// ── groups ───────────────────────────────────────────────────────────────────

const print_items = [_]ast.Item{
    .{ .comment = "Scratch layout below the data section (which starts at 256):" },
    .{ .comment = "  0..8  WASI iovec   8  newline byte" },
    .{ .comment = " 16..32 bool text   32..64 float fraction   64..128 i32 digits" },
    .{ .func = write_bytes },
    .{ .func = print_nl },
    .{ .comment = "separator between the arguments of a multi-argument `@print`" },
    .{ .func = print_sp },
    .{ .func = print_i32 },
    .{ .func = print_i32_raw },
    .{ .func = memmove },
};
const print_str_items = [_]ast.Item{
    .{ .func = print_str_raw },
    .{ .func = print_str },
};
const print_bool_items = [_]ast.Item{
    .{ .func = print_bool },
    .{ .func = print_bool_raw },
};
const print_f64_items = [_]ast.Item{
    .{ .func = print_f64 },
    .{ .func = print_f64_raw },
};
const arr_at_items = [_]ast.Item{
    .{ .func = arr_at },
};
const str_concat_items = [_]ast.Item{
    .{ .func = str_concat },
};
const str_eq_items = [_]ast.Item{
    .{ .func = str_eq },
};
const str_slice_items = [_]ast.Item{
    .{ .func = str_slice },
};

// ── the builder for the helpers below ────────────────────────────────────────
//
// The helpers above were transcribed line by line when the backend moved to
// the code model. The ones below are built with a few comptime constructors
// instead: a body is a list of `Instr`, and `func` gives every line the column
// its nesting puts it at (the same columns the transcribed helpers use: body 4,
// an `if` arm +4, a `block`/`loop` body +2). Still nodes — the emitter writes
// the text.

const Instr = ast.Instr;

fn c32(comptime n: comptime_int) Instr {
    return .{ .@"const" = .{ .ty = .i32, .text = std.fmt.comptimePrint("{d}", .{n}) } };
}
fn c64(comptime n: comptime_int) Instr {
    return .{ .@"const" = .{ .ty = .i64, .text = std.fmt.comptimePrint("{d}", .{n}) } };
}
fn get(comptime n: []const u8) Instr {
    return .{ .local_get = n };
}
fn set(comptime n: []const u8) Instr {
    return .{ .local_set = n };
}
fn tee(comptime n: []const u8) Instr {
    return .{ .local_tee = n };
}
/// An `i32.<name>` operation.
fn op(comptime name: []const u8) Instr {
    return .{ .op = .{ .ty = .i32, .name = name } };
}
fn op64(comptime name: []const u8) Instr {
    return .{ .op = .{ .ty = .i64, .name = name } };
}
fn load(comptime off: u32) Instr {
    return .{ .load = .{ .offset = off } };
}
fn load8(comptime off: u32) Instr {
    return .{ .load = .{ .width = .byte, .offset = off } };
}
fn store(comptime off: u32) Instr {
    return .{ .store = .{ .offset = off } };
}
fn store8(comptime off: u32) Instr {
    return .{ .store = .{ .width = .byte, .offset = off } };
}
fn call(comptime name: []const u8) Instr {
    return .{ .call = name };
}
const ret: Instr = .@"return";
const copy: Instr = .memory_copy;
const heap = "__heap_ptr";

fn seqOf(comptime body: []const Instr, comptime stack: ast.Stack) ast.Seq {
    @setEvalBranchQuota(100_000);
    var lines: [body.len]ast.Line = undefined;
    for (body, 0..) |i, k| lines[k] = .{ .instr = i };
    const out = lines;
    return .{ .lines = &out, .stack = stack };
}

/// `(if (then …))` — statement form.
fn when(comptime then: []const Instr) Instr {
    return .{ .@"if" = .{ .then = .{ .seq = seqOf(then, .none) } } };
}
/// `(if (then …) (else …))` — statement form.
fn whenElse(comptime then: []const Instr, comptime els: []const Instr) Instr {
    return .{ .@"if" = .{
        .then = .{ .seq = seqOf(then, .none) },
        .@"else" = .{ .seq = seqOf(els, .none) },
    } };
}
/// `(block $brk (loop $cont …))`; `br_if $brk` leaves, `br $cont` repeats.
fn loop(comptime body: []const Instr) Instr {
    const inner: Instr = .{ .block = .{ .kind = .loop, .label = "cont", .body = seqOf(body, .none) } };
    return .{ .block = .{ .kind = .block, .label = "brk", .body = seqOf(&.{inner}, .none) } };
}
const brk: Instr = .{ .br_if = "brk" };
const again: Instr = .{ .br = "cont" };

fn indented(comptime s: ast.Seq, comptime col: u8) ast.Seq {
    @setEvalBranchQuota(100_000);
    var lines: [s.lines.len]ast.Line = undefined;
    for (s.lines, 0..) |l, k| {
        var nl = l;
        nl.indent = col;
        switch (l.instr) {
            .@"if" => |n| {
                var m = n;
                m.then.seq = indented(n.then.seq, col + 4);
                if (n.@"else") |e| {
                    var ee = e;
                    ee.seq = indented(e.seq, col + 4);
                    m.@"else" = ee;
                }
                nl.instr = .{ .@"if" = m };
            },
            .block => |b| {
                var m = b;
                m.body = indented(b.body, col + 2);
                nl.instr = .{ .block = m };
            },
            else => {},
        }
        lines[k] = nl;
    }
    const out = lines;
    return .{ .lines = &out, .stack = s.stack };
}

const P = ast.Param;

fn i32s(comptime names: []const []const u8) []const ast.Local {
    var out: [names.len]ast.Local = undefined;
    for (names, 0..) |n, k| out[k] = .{ .name = n, .ty = .i32 };
    const final = out;
    return &final;
}

fn func(
    comptime name: []const u8,
    comptime params: []const []const u8,
    comptime result: ?ast.ValType,
    comptime locals: []const ast.Local,
    comptime body: []const Instr,
) ast.Func {
    var ps: [params.len]P = undefined;
    for (params, 0..) |n, k| ps[k] = .{ .name = n, .ty = .i32 };
    const params_final = ps;
    return typedFunc(name, &params_final, result, locals, body);
}

/// `func` with typed parameters.
fn typedFunc(
    comptime name: []const u8,
    comptime params: []const P,
    comptime result: ?ast.ValType,
    comptime locals: []const ast.Local,
    comptime body: []const Instr,
) ast.Func {
    const stack: ast.Stack = if (result) |r| .{ .value = r } else .none;
    return .{
        .name = name,
        .params = params,
        .result = result,
        .locals = if (locals.len == 0) &.{} else &.{locals},
        .body = indented(seqOf(body, stack), 4),
    };
}

/// `base + 4 + i * 4` — the address of element `i` of an `[len][e0][e1]…` blob.
fn slot(comptime base: []const u8, comptime i: []const u8) [7]Instr {
    return .{ get(base), c32(4), op("add"), get(i), c32(4), op("mul"), op("add") };
}

/// ch is one of ' ', '\t', '\n', '\r'.
fn isSpace(comptime ch: []const u8) [15]Instr {
    return .{
        get(ch),  c32(32),  op("eq"),
        get(ch),  c32(9),   op("eq"),
        op("or"), get(ch),  c32(10),
        op("eq"), op("or"), get(ch),
        c32(13),  op("eq"), op("or"),
    };
}

// ── helpers built with it ────────────────────────────────────────────────────

/// Bump-allocate `n` bytes, keeping the heap pointer on a 4-byte boundary.
const alloc = func("__alloc", &.{"n"}, .i32, i32s(&.{"p"}), &.{
    .{ .global_get = heap }, set("p"),
    .{ .global_get = heap }, get("n"),
    op("add"),               c32(3),
    op("add"),               c32(-4),
    op("and"),               .{ .global_set = heap },
    get("p"),
});

/// 1 when the `n` bytes at `a` and `b` are equal.
const mem_eq = func("__mem_eq", &.{ "a", "b", "n" }, .i32, i32s(&.{"i"}), &.{
    loop(&.{
        get("i"),  get("n"),                op("ge_u"), brk,
        get("a"),  get("i"),                op("add"),  load8(0),
        get("b"),  get("i"),                op("add"),  load8(0),
        op("ne"),  when(&.{ c32(0), ret }), get("i"),   c32(1),
        op("add"), set("i"),                again,
    }),
    c32(1),
});

const i32_abs = func("__i32_abs", &.{"n"}, .i32, &.{}, &.{
    get("n"),                                     c32(0),   op("lt_s"),
    when(&.{ c32(0), get("n"), op("sub"), ret }), get("n"),
});

const i32_min = func("__i32_min", &.{ "a", "b" }, .i32, &.{}, &.{
    get("a"),                  get("b"), op("lt_s"),
    when(&.{ get("a"), ret }), get("b"),
});

const i32_max = func("__i32_max", &.{ "a", "b" }, .i32, &.{}, &.{
    get("a"),                  get("b"), op("gt_s"),
    when(&.{ get("a"), ret }), get("b"),
});

/// Decimal text of an i32, as a fresh length-prefixed string. The digits are
/// written backwards into scratch `128..160` (below the data section) and then
/// copied out.
const i32_to_str = func("__i32_to_str", &.{"n"}, .i32, &.{
    .{ .name = "u", .ty = .i64 }, .{ .name = "pos", .ty = .i32 }, .{ .name = "len", .ty = .i32 },
    .{ .name = "p", .ty = .i32 }, .{ .name = "neg", .ty = .i32 },
}, &.{
    c32(160),                                            set("pos"),
    get("n"),                                            c32(0),
    op("lt_s"),                                          set("neg"),
    get("n"),                                            .{ .convert = "i64.extend_i32_s" },
    set("u"),                                            get("neg"),
    when(&.{ c64(0), get("u"), op64("sub"), set("u") }),
    loop(&.{
        get("pos"),                     c32(1),      op("sub"),     set("pos"),
        get("pos"),                     get("u"),    c64(10),       op64("rem_u"),
        .{ .convert = "i32.wrap_i64" }, c32(48),     op("add"),     store8(0),
        get("u"),                       c64(10),     op64("div_u"), set("u"),
        get("u"),                       op64("eqz"), brk,           again,
    }),
    get("neg"),                                          when(&.{ get("pos"), c32(1), op("sub"), set("pos"), get("pos"), c32(45), store8(0) }),
    c32(160),                                            get("pos"),
    op("sub"),                                           set("len"),
    get("len"),                                          c32(4),
    op("add"),                                           call("__alloc"),
    set("p"),                                            get("p"),
    get("len"),                                          store(0),
    get("p"),                                            c32(4),
    op("add"),                                           get("pos"),
    get("len"),                                          copy,
    get("p"),
});

/// A copy of `s` with every byte in `[lo, hi]` shifted by `delta` — ASCII
/// upper/lower case.
const str_case = func("__str_case", &.{ "s", "lo", "hi", "delta" }, .i32, i32s(&.{ "n", "p", "i", "ch" }), &.{
    get("s"),        load(0),  set("n"),
    get("n"),        c32(4),   op("add"),
    call("__alloc"), set("p"), get("p"),
    get("n"),        store(0),
    loop(&.{
        get("i"),                                                  get("n"),  op("ge_u"), brk,
        get("s"),                                                  get("i"),  op("add"),  load8(4),
        set("ch"),                                                 get("ch"), get("lo"),  op("ge_u"),
        get("ch"),                                                 get("hi"), op("le_u"), op("and"),
        when(&.{ get("ch"), get("delta"), op("add"), set("ch") }), get("p"),  get("i"),   op("add"),
        get("ch"),                                                 store8(4), get("i"),   c32(1),
        op("add"),                                                 set("i"),  again,
    }),
    get("p"),
});

/// Byte offset of the first `sub` in `s`, `-1` when absent, `0` for an empty `sub`.
const str_index_of = func("__str_index_of", &.{ "s", "sub" }, .i32, i32s(&.{ "n", "m", "i" }), &.{
    get("s"),   load(0), set("n"),
    get("sub"), load(0), set("m"),
    loop(&.{
        get("i"), get("m"),  op("add"), get("n"),         op("gt_u"),                brk,
        get("s"), c32(4),    op("add"), get("i"),         op("add"),                 get("sub"),
        c32(4),   op("add"), get("m"),  call("__mem_eq"), when(&.{ get("i"), ret }), get("i"),
        c32(1),   op("add"), set("i"),  again,
    }),
    c32(-1),
});

const str_starts_with = func("__str_starts_with", &.{ "s", "p" }, .i32, &.{}, &.{
    get("p"),                load(0),   get("s"), load(0),   op("gt_u"),
    when(&.{ c32(0), ret }), get("s"),  c32(4),   op("add"), get("p"),
    c32(4),                  op("add"), get("p"), load(0),   call("__mem_eq"),
});

const str_ends_with = func("__str_ends_with", &.{ "s", "x" }, .i32, i32s(&.{ "n", "m" }), &.{
    get("s"),                load(0),   set("n"),
    get("x"),                load(0),   set("m"),
    get("m"),                get("n"),  op("gt_u"),
    when(&.{ c32(0), ret }), get("s"),  c32(4),
    op("add"),               get("n"),  op("add"),
    get("m"),                op("sub"), get("x"),
    c32(4),                  op("add"), get("m"),
    call("__mem_eq"),
});

/// `mode` bit 1 trims the start, bit 2 the end (whitespace: ' ' \t \n \r).
const str_trim = func("__str_trim", &.{ "s", "mode" }, .i32, i32s(&.{ "a", "b", "ch" }), &.{
    get("s"),            load(0),  set("b"),
    get("mode"),         c32(1),   op("and"),
    when(&.{loop(&([_]Instr{ get("a"), get("b"), op("ge_u"), brk, get("s"), get("a"), op("add"), load8(4), set("ch") } ++
        isSpace("ch") ++ [_]Instr{ op("eqz"), brk, get("a"), c32(1), op("add"), set("a"), again }))}),
    get("mode"),         c32(2),   op("and"),
    when(&.{loop(&([_]Instr{ get("b"), get("a"), op("le_u"), brk, get("s"), get("b"), op("add"), load8(3), set("ch") } ++
        isSpace("ch") ++ [_]Instr{ op("eqz"), brk, get("b"), c32(1), op("sub"), set("b"), again }))}),
    get("s"),            get("a"), get("b"),
    call("__str_slice"),
});

/// `s` cut at every `sep`, as an array of fresh strings. An empty `sep` cuts
/// between every byte.
const str_split = func("__str_split", &.{ "s", "sep" }, .i32, i32s(&.{ "n", "m", "i", "cnt", "arr", "start", "k" }), &([_]Instr{
    get("s"),   load(0),           set("n"),
    get("sep"), load(0),           set("m"),
    get("m"),   op("eqz"),
    when(&([_]Instr{ get("n"), call("__arr_new"), set("arr") } ++ [_]Instr{loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++
        slot("arr", "i") ++ [_]Instr{ get("s"), get("i"), get("i"), c32(1), op("add"), call("__str_slice"), store(0), get("i"), c32(1), op("add"), set("i"), again }))} ++
        .{ get("arr"), ret })),
    c32(1),     set("cnt"),
    loop(&.{
        get("i"), get("m"),  op("add"), get("n"),         op("gt_u"),                                                                                                                                      brk,
        get("s"), c32(4),    op("add"), get("i"),         op("add"),                                                                                                                                       get("sep"),
        c32(4),   op("add"), get("m"),  call("__mem_eq"), whenElse(&.{ get("cnt"), c32(1), op("add"), set("cnt"), get("i"), get("m"), op("add"), set("i") }, &.{ get("i"), c32(1), op("add"), set("i") }), again,
    }),
    get("cnt"), call("__arr_new"), set("arr"),
    c32(0),     set("i"),
    loop(&.{
        get("i"), get("m"),  op("add"), get("n"),         op("gt_u"),                                                                                                                                                                                                                                              brk,
        get("s"), c32(4),    op("add"), get("i"),         op("add"),                                                                                                                                                                                                                                               get("sep"),
        c32(4),   op("add"), get("m"),  call("__mem_eq"), whenElse(&(slot("arr", "k") ++ [_]Instr{ get("s"), get("start"), get("i"), call("__str_slice"), store(0), get("k"), c32(1), op("add"), set("k"), get("i"), get("m"), op("add"), tee("i"), set("start") }), &.{ get("i"), c32(1), op("add"), set("i") }), again,
    }),
} ++ slot("arr", "k") ++ [_]Instr{ get("s"), get("start"), get("n"), call("__str_slice"), store(0), get("arr") }));

const str_repeat = func("__str_repeat", &.{ "s", "times" }, .i32, i32s(&.{ "n", "p", "i" }), &.{
    get("s"),                         load(0),      set("n"),
    get("times"),                     c32(0),       op("lt_s"),
    when(&.{ c32(0), set("times") }), get("n"),     get("times"),
    op("mul"),                        c32(4),       op("add"),
    call("__alloc"),                  set("p"),     get("p"),
    get("n"),                         get("times"), op("mul"),
    store(0),
    loop(&.{
        get("i"), get("times"), op("ge_s"), brk,
        get("p"), c32(4),       op("add"),  get("n"),
        get("i"), op("mul"),    op("add"),  get("s"),
        c32(4),   op("add"),    get("n"),   copy,
        get("i"), c32(1),       op("add"),  set("i"),
        again,
    }),
    get("p"),
});

/// A fresh array blob of `n` elements (`[n][e0]…`), elements unset.
const arr_new = func("__arr_new", &.{"n"}, .i32, i32s(&.{"p"}), &.{
    get("n"), c32(1),   op("add"), c32(4),   op("mul"), call("__alloc"), set("p"),
    get("p"), get("n"), store(0),  get("p"),
});

/// `xs.slice(a, b)` with the host bounds rules: a negative bound counts from
/// the end, bounds clamp to `[0, len]`, and a reversed range is empty.
const arr_slice = func("__arr_slice", &.{ "xs", "a", "b" }, .i32, i32s(&.{ "n", "cnt", "p" }), &.{
    get("xs"),                                                                                                                                                                                 load(0),                                                                                                                                                                                   set("n"),
    get("a"),                                                                                                                                                                                  c32(0),                                                                                                                                                                                    op("lt_s"),
    whenElse(&.{ get("n"), get("a"), op("add"), set("a"), get("a"), c32(0), op("lt_s"), when(&.{ c32(0), set("a") }) }, &.{ get("a"), get("n"), op("gt_s"), when(&.{ get("n"), set("a") }) }), get("b"),                                                                                                                                                                                  c32(0),
    op("lt_s"),                                                                                                                                                                                whenElse(&.{ get("n"), get("b"), op("add"), set("b"), get("b"), c32(0), op("lt_s"), when(&.{ c32(0), set("b") }) }, &.{ get("b"), get("n"), op("gt_s"), when(&.{ get("n"), set("b") }) }), get("b"),
    get("a"),                                                                                                                                                                                  op("sub"),                                                                                                                                                                                 set("cnt"),
    get("cnt"),                                                                                                                                                                                c32(0),                                                                                                                                                                                    op("lt_s"),
    when(&.{ c32(0), set("cnt") }),                                                                                                                                                            get("cnt"),                                                                                                                                                                                call("__arr_new"),
    set("p"),                                                                                                                                                                                  get("p"),                                                                                                                                                                                  c32(4),
    op("add"),                                                                                                                                                                                 get("xs"),                                                                                                                                                                                 c32(4),
    op("add"),                                                                                                                                                                                 get("a"),                                                                                                                                                                                  c32(4),
    op("mul"),                                                                                                                                                                                 op("add"),                                                                                                                                                                                 get("cnt"),
    c32(4),                                                                                                                                                                                    op("mul"),                                                                                                                                                                                 copy,
    get("p"),
});

const arr_reverse = func("__arr_reverse", &.{"xs"}, .i32, i32s(&.{ "n", "i", "p" }), &.{
    get("xs"), load(0),           set("n"),
    get("n"),  call("__arr_new"), set("p"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("p", "i") ++ [_]Instr{
        get("xs"), get("n"), get("i"),  op("sub"), c32(4), op("mul"), op("add"), load(0), store(0),
        get("i"),  c32(1),   op("add"), set("i"),  again,
    })),
    get("p"),
});

const arr_prepend = func("__arr_prepend", &.{ "xs", "x" }, .i32, i32s(&.{ "n", "p" }), &.{
    get("xs"),         load(0),   set("n"),
    get("n"),          c32(1),    op("add"),
    call("__arr_new"), set("p"),  get("p"),
    get("x"),          store(4),  get("p"),
    c32(8),            op("add"), get("xs"),
    c32(4),            op("add"), get("n"),
    c32(4),            op("mul"), copy,
    get("p"),
});

/// A copy of `xs` with `x` appended — `push` rebinds the receiver to it.
const arr_push = func("__arr_push", &.{ "xs", "x" }, .i32, i32s(&.{ "n", "p" }), &([_]Instr{
    get("xs"),         load(0),   set("n"),
    get("n"),          c32(1),    op("add"),
    call("__arr_new"), set("p"),  get("p"),
    c32(4),            op("add"), get("xs"),
    c32(4),            op("add"), get("n"),
    c32(4),            op("mul"), copy,
} ++ slot("p", "n") ++ [_]Instr{ get("x"), store(0), get("p") }));

const arr_concat = func("__arr_concat", &.{ "a", "b" }, .i32, i32s(&.{ "na", "nb", "p" }), &([_]Instr{
    get("a"),          load(0),   set("na"),
    get("b"),          load(0),   set("nb"),
    get("na"),         get("nb"), op("add"),
    call("__arr_new"), set("p"),  get("p"),
    c32(4),            op("add"), get("a"),
    c32(4),            op("add"), get("na"),
    c32(4),            op("mul"), copy,
} ++ slot("p", "na") ++ [_]Instr{ get("b"), c32(4), op("add"), get("nb"), c32(4), op("mul"), copy, get("p") }));

/// Pairs `a[i]` with `b[i]` as 2-slot tuples, truncated to the shorter array.
const arr_zip = func("__arr_zip", &.{ "a", "b" }, .i32, i32s(&.{ "n", "i", "p", "t" }), &.{
    get("a"),          load(0),                                 set("n"),
    get("b"),          load(0),                                 get("n"),
    op("lt_u"),        when(&.{ get("b"), load(0), set("n") }), get("n"),
    call("__arr_new"), set("p"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, c32(8), call("__alloc"), set("t") } ++
        .{get("t")} ++ slot("a", "i") ++ [_]Instr{ load(0), store(0), get("t") } ++ slot("b", "i") ++ [_]Instr{ load(0), store(4) } ++
        slot("p", "i") ++ [_]Instr{ get("t"), store(0), get("i"), c32(1), op("add"), set("i"), again })),
    get("p"),
});

const arr_index_of_i32 = func("__arr_index_of_i32", &.{ "xs", "x" }, .i32, i32s(&.{ "n", "i" }), &.{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("xs", "i") ++ [_]Instr{
        load(0),  get("x"), op("eq"),  when(&.{ get("i"), ret }),
        get("i"), c32(1),   op("add"), set("i"),
        again,
    })),
    c32(-1),
});

const arr_index_of_str = func("__arr_index_of_str", &.{ "xs", "x" }, .i32, i32s(&.{ "n", "i" }), &.{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("xs", "i") ++ [_]Instr{
        load(0),  get("x"), call("__str_eq"), when(&.{ get("i"), ret }),
        get("i"), c32(1),   op("add"),        set("i"),
        again,
    })),
    c32(-1),
});

/// The strings of `xs` joined with `sep`, as one fresh string.
const arr_join_str = func("__arr_join_str", &.{ "xs", "sep" }, .i32, i32s(&.{ "n", "i", "total", "p", "pos", "e" }), &.{
    get("xs"), load(0),                                                                                                        set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("total") } ++ slot("xs", "i") ++ [_]Instr{
        load(0), load(0), op("add"), set("total"), get("i"), c32(1), op("add"), set("i"), again,
    })),
    get("n"),  when(&.{ get("total"), get("sep"), load(0), get("n"), c32(1), op("sub"), op("mul"), op("add"), set("total") }), get("total"),
    c32(4),    op("add"),                                                                                                      call("__alloc"),
    set("p"),  get("p"),                                                                                                       get("total"),
    store(0),  get("p"),                                                                                                       c32(4),
    op("add"), set("pos"),                                                                                                     c32(0),
    set("i"),
    loop(&([_]Instr{
        get("i"), get("n"),                                                                                                                                 op("ge_u"), brk,
        get("i"), when(&.{ get("pos"), get("sep"), c32(4), op("add"), get("sep"), load(0), copy, get("pos"), get("sep"), load(0), op("add"), set("pos") }),
    } ++ slot("xs", "i") ++ [_]Instr{
        load(0),    set("e"),
        get("pos"), get("e"),
        c32(4),     op("add"),
        get("e"),   load(0),
        copy,       get("pos"),
        get("e"),   load(0),
        op("add"),  set("pos"),
        get("i"),   c32(1),
        op("add"),  set("i"),
        again,
    })),
    get("p"),
});

/// The decimal text of every element of `xs`, joined with `sep`.
const arr_join_i32 = func("__arr_join_i32", &.{ "xs", "sep" }, .i32, i32s(&.{ "n", "i", "t" }), &.{
    get("xs"), load(0),           set("n"),
    get("n"),  call("__arr_new"), set("t"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("t", "i") ++ slot("xs", "i") ++ [_]Instr{
        load(0),  call("__i32_to_str"), store(0),
        get("i"), c32(1),               op("add"),
        set("i"), again,
    })),
    get("t"),  get("sep"),        call("__arr_join_str"),
});

/// Writes one byte through the newline scratch cell at 8.
fn putByte(comptime ch: comptime_int) [5]Instr {
    return .{ c32(8), c32(ch), store8(0), c32(8), c32(1) };
}

/// `[1,2,3]` — the elements of an i32 array, comma-separated, no spaces (the
/// erlang/beam spelling of a list; commonJS pads it with spaces).
const print_arr_i32_raw = func("__print_arr_i32_raw", &.{"xs"}, null, i32s(&.{ "n", "i" }), &(putByte('[') ++ [_]Instr{call("__write_bytes")} ++ [_]Instr{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("i"), when(&(putByte(',') ++ [_]Instr{call("__write_bytes")})) } ++ slot("xs", "i") ++ [_]Instr{
        load(0),   call("__print_i32_raw"),
        get("i"),  c32(1),
        op("add"), set("i"),
        again,
    })),
} ++ putByte(']') ++ [_]Instr{call("__write_bytes")}));

const print_arr_i32 = func("__print_arr_i32", &.{"xs"}, null, &.{}, &.{ get("xs"), call("__print_arr_i32_raw"), call("__print_nl") });

fn opF(comptime name: []const u8) Instr {
    return .{ .op = .{ .ty = .f64, .name = name } };
}
fn getF(comptime n: []const u8) Instr {
    return .{ .local_get = n };
}

/// The text `$__print_f64` writes, as a fresh string: an integer part and up to
/// six fraction digits with trailing zeros dropped. The fraction digits go to
/// scratch `168..174` first.
const f64_to_str = typedFunc("__f64_to_str", &.{.{ .name = "x", .ty = .f64 }}, .i32, &.{
    .{ .name = "neg", .ty = .i32 }, .{ .name = "frac", .ty = .f64 }, .{ .name = "d", .ty = .i32 },
    .{ .name = "k", .ty = .i32 },   .{ .name = "last", .ty = .i32 }, .{ .name = "ip", .ty = .i32 },
    .{ .name = "len", .ty = .i32 }, .{ .name = "p", .ty = .i32 },    .{ .name = "pos", .ty = .i32 },
}, &.{
    getF("x"),                                                                             .{ .@"const" = .{ .ty = .f64, .text = "0" } }, opF("lt"),                                                                                              set("neg"),
    get("neg"),                                                                            when(&.{ getF("x"), opF("neg"), set("x") }),   getF("x"),                                                                                              .{ .convert = "i32.trunc_f64_s" },
    call("__i32_to_str"),                                                                  set("ip"),                                     getF("x"),                                                                                              getF("x"),
    opF("floor"),                                                                          opF("sub"),                                    set("frac"),
    loop(&.{
        get("k"),                          c32(6),                                         op("ge_s"), brk,
        getF("frac"),                      .{ .@"const" = .{ .ty = .f64, .text = "10" } }, opF("mul"), set("frac"),
        getF("frac"),                      .{ .convert = "i32.trunc_f64_s" },              set("d"),   getF("frac"),
        get("d"),                          .{ .convert = "f64.convert_i32_s" },            opF("sub"), set("frac"),
        c32(168),                          get("k"),                                       op("add"),  get("d"),
        c32(48),                           op("add"),                                      store8(0),  get("k"),
        c32(1),                            op("add"),                                      set("k"),   get("d"),
        when(&.{ get("k"), set("last") }), again,
    }),
    get("ip"),                                                                             load(0),                                       get("neg"),                                                                                             op("add"),
    set("len"),                                                                            get("last"),                                   when(&.{ get("len"), get("last"), op("add"), c32(1), op("add"), set("len") }),                          get("len"),
    c32(4),                                                                                op("add"),                                     call("__alloc"),                                                                                        set("p"),
    get("p"),                                                                              get("len"),                                    store(0),                                                                                               get("p"),
    c32(4),                                                                                op("add"),                                     set("pos"),                                                                                             get("neg"),
    when(&.{ get("pos"), c32(45), store8(0), get("pos"), c32(1), op("add"), set("pos") }), get("pos"),                                    get("ip"),                                                                                              c32(4),
    op("add"),                                                                             get("ip"),                                     load(0),                                                                                                copy,
    get("pos"),                                                                            get("ip"),                                     load(0),                                                                                                op("add"),
    set("pos"),                                                                            get("last"),                                   when(&.{ get("pos"), c32(46), store8(0), get("pos"), c32(1), op("add"), c32(168), get("last"), copy }), get("p"),
});

/// `[115,287.5,460]` — the elements of an f32 array, printed like `$__print_f64`.
const print_arr_f32_raw = func("__print_arr_f32_raw", &.{"xs"}, null, i32s(&.{ "n", "i" }), &(putByte('[') ++ .{call("__write_bytes")} ++ [_]Instr{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("i"), when(&(putByte(',') ++ .{call("__write_bytes")})) } ++ slot("xs", "i") ++ [_]Instr{
        .{ .load = .{ .ty = .f32 } }, .{ .convert = "f64.promote_f32" }, call("__print_f64_raw"),
        get("i"),                     c32(1),                            op("add"),
        set("i"),                     again,
    })),
} ++ putByte(']') ++ .{call("__write_bytes")}));

const print_arr_f32 = func("__print_arr_f32", &.{"xs"}, null, &.{}, &.{ get("xs"), call("__print_arr_f32_raw"), call("__print_nl") });

/// A `?T` box: a fresh 4-byte cell holding `v`.
const box_i32 = func("__box_i32", &.{"v"}, .i32, i32s(&.{"p"}), &.{
    c32(4),   call("__alloc"), set("p"),
    get("p"), get("v"),        store(0),
    get("p"),
});

/// `xs.at(i)` as a `?T`: a box holding the element, or 0 out of range.
const arr_at_box = func("__arr_at_box", &.{ "xs", "i" }, .i32, &.{}, &([_]Instr{
    get("i"),                c32(0), op("lt_s"), get("i"), get("xs"), load(0), op("ge_s"), op("or"),
    when(&.{ c32(0), ret }),
} ++ slot("xs", "i") ++ [_]Instr{ load(0), call("__box_i32") }));

/// `undefined` — what none prints as on the other targets. Written through
/// scratch `176..185`.
const print_undefined = func("__print_undefined", &.{}, null, &.{}, &.{
    c32(176), .{ .@"const" = .{ .ty = .i64, .text = "7308895133777555061" } }, .{ .store = .{ .ty = .i64 } },
    c32(184), c32(100),                                                        store8(0),
    c32(176), c32(9),                                                          call("__write_bytes"),
});

const print_opt_i32_raw = func("__print_opt_i32_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                                  op("eqz"),
    whenElse(&.{call("__print_undefined")}, &.{ get("p"), load(0), call("__print_i32_raw") }),
});
const print_opt_i32 = func("__print_opt_i32", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_i32_raw"), call("__print_nl") });

const print_opt_bool_raw = func("__print_opt_bool_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                                   op("eqz"),
    whenElse(&.{call("__print_undefined")}, &.{ get("p"), load(0), call("__print_bool_raw") }),
});
const print_opt_bool = func("__print_opt_bool", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_bool_raw"), call("__print_nl") });

const print_opt_str_raw = func("__print_opt_str_raw", &.{"s"}, null, &.{}, &.{
    get("s"),                                                                         op("eqz"),
    whenElse(&.{call("__print_undefined")}, &.{ get("s"), call("__print_str_raw") }),
});
const print_opt_str = func("__print_opt_str", &.{"s"}, null, &.{}, &.{ get("s"), call("__print_opt_str_raw"), call("__print_nl") });

/// `$__write_bytes` to stderr (fd 2), through the same iovec scratch.
const write_err = func("__write_err", &.{ "p", "n" }, null, &.{}, &.{
    c32(0), get("p"),         store(0),
    c32(4), get("n"),         store(0),
    c32(2), c32(0),           c32(1),
    c32(8), call("fd_write"), .drop,
});

/// `<where>: assertion failed[: <msg>]` and a newline on stderr. `where` and
/// `msg` are length-prefixed strings; `msg` 0 when the assert has none. The
/// literal text goes through scratch `188..208`.
const assert_fail = func("__assert_fail", &.{ "where", "msg" }, null, &.{}, &.{
    get("where"), c32(4),                                                          op("add"),                     get("where"), load(0),                                                         call("__write_err"),
    // ": assertion failed" — 18 bytes as two i64 words and a u16
    c32(188),     .{ .@"const" = .{ .ty = .i64, .text = "8390880602276044858" } }, .{ .store = .{ .ty = .i64 } }, c32(196),     .{ .@"const" = .{ .ty = .i64, .text = "7811882119909502825" } }, .{ .store = .{ .ty = .i64 } },
    c32(204),     c32(101),                                                        store8(0),                     c32(205),     c32(100),                                                        store8(0),
    c32(188),     c32(18),                                                         call("__write_err"),           get("msg"),
    when(&.{
        c32(188),   c32(8250), .{ .store = .{} }, c32(188),   c32(2),  call("__write_err"),
        get("msg"), c32(4),    op("add"),         get("msg"), load(0), call("__write_err"),
    }),
    c32(188),     c32(10),                                                         store8(0),                     c32(188),     c32(1),                                                          call("__write_err"),
});
