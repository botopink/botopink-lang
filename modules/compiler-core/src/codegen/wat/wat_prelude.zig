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
//! What is here is decision 442 (1)'s list and nothing else: what defines a
//! value's representation (the heap, boxes, the array and string cells the
//! codegen lays out), the arithmetic operators' checks, the output (the
//! I/O — a number's text is std-wasm's) and the language runtime (the `@Async`
//! scheduler, `unknown`, `assert_fail`). Everything that only computes over
//! values — text, number-to-text, arrays, `bigint` — is std-wasm's Zig,
//! transpiled into the module (`std_wasm_link.zig`, decisions 440, 442 (2));
//! `codegen/wat/AGENTS.md` § What stays in `wat_prelude` holds the rule.
//!
//! The scratch layout the print helpers assume, below the data section (which
//! starts at 256): `0..8` the WASI iovec, `8` the newline byte — and `9` the
//! space of §7's `, ` separator, written beside it in one call —, `16..32` the
//! bool text, `64..128` the i32 digits. An `i64`'s and a `u64`'s text is
//! std-wasm's `number.i64Text` / `u64Text` (written in std-wasm's one
//! workspace, so a print allocates nothing), a float's its
//! `number.floatToString` (decision 441).

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
        .print_arr_i32 => &.{ .{ .func = print_arr_i32_raw }, .{ .func = print_arr_i32 } },
        .print_arr_f64 => &.{ .{ .func = print_arr_f64_raw }, .{ .func = print_arr_f64 } },
        .assert_fail => &.{ .{ .func = write_err }, .{ .func = assert_fail } },
        .panic_fail => &.{.{ .func = panic_fail }},
        .main_fail => &.{.{ .func = main_fail }},
        .print_shaped => &.{ .{ .func = print_quoted_raw }, .{ .func = print_tagged_raw }, .{ .func = print_tagged }, .{ .func = print_shaped_raw } },
        .print_opt_f64 => &.{ .{ .func = print_opt_f64_raw }, .{ .func = print_opt_f64 } },
        .print_i64 => &.{ .{ .func = print_i64_raw }, .{ .func = print_i64 } },
        .int_chk => &int_chk_items,
        .print_u64 => &.{ .{ .func = print_u64_raw }, .{ .func = print_u64 } },
        .u64_chk => &u64_chk_items,
        .nz_chk => &nz_chk_items,
        .chk_fail => &.{.{ .func = chk_fail_write }},
        .print_opt_i64 => &.{ .{ .func = print_opt_i64_raw }, .{ .func = print_opt_i64 } },
        .print_opt_u64 => &.{ .{ .func = print_opt_u64_raw }, .{ .func = print_opt_u64 } },
        .print_opt_tagged => &.{ .{ .func = print_opt_tagged_raw }, .{ .func = print_opt_tagged } },
        .unknown => &.{ .{ .func = unknown_kind }, .{ .func = unknown_int_in }, .{ .func = unknown_as_i32 }, .{ .func = unknown_as_f64 }, .{ .func = unknown_eq } },
        .print_unknown => &.{ .{ .func = print_unknown_raw }, .{ .func = print_unknown } },
        .task => &.{
            .{ .global = task_head_global }, .{ .global = task_tail_global }, .{ .global = task_suspended_global },
            .{ .func = task_new },           .{ .func = task_start },         .{ .func = task_pending },
            .{ .func = task_listen },        .{ .func = task_wait },          .{ .func = task_settle_i32 },
            .{ .func = task_settle_i64 },    .{ .func = task_settle_f64 },    .{ .func = task_wake },
            .{ .func = task_enqueue },       .{ .func = task_drain },         .{ .func = task_block_on },
            .{ .func = task_finish },
        },
        .task_poll => &.{.{ .func = task_host_poll }},
        .task_host => &.{ .{ .global = task_hosts_global }, .{ .func = task_host_add }, .{ .func = task_host_settle } },
        .task_gate => &.{ .{ .func = task_host_cancel }, .{ .func = task_gate_new }, .{ .func = task_gate_open }, .{ .func = task_gate_await } },
        .memo_cell => &.{ .{ .func = memo_cell_new }, .{ .func = memo_cell_filled }, .{ .func = memo_cell_get }, .{ .func = memo_cell_set } },
        // Decision 442 (2): `bigint`'s arithmetic is std-wasm's; the group
        // only marks a module that prints one in a container (`stdCalls`).
        .bigint => &.{},
        // Decision 150: a marker, as `bigint` is (`print_shaped_items_unknown`).
        .print_shaped_unknown => &.{},
        .text_capture => &.{ .{ .global = cap_global }, .{ .func = cap_begin }, .{ .func = cap_end } },
        .random_state => &.{.{ .global = random_state_global }},
        // Decision 992: the group is its imports (`fs_imports`), which `wat.zig` places
        // ahead of the memory; no function.
        .fs_host => &.{},
        .std_marshal => &.{ .{ .func = gc_to_lin_str }, .{ .func = lin_to_gc_str } },
        // Decision 1021 (10): string ordering has a GC form only.
        .str_cmp => &.{.{ .func = gc_str_cmp }},
        .print_opt => &.{
            .{ .func = print_null },         .{ .func = print_opt_i32_raw }, .{ .func = print_opt_i32 },
            .{ .func = print_opt_bool_raw }, .{ .func = print_opt_bool },    .{ .func = print_opt_str_raw },
            .{ .func = print_opt_str },
        },
        inline else => |t| &.{.{ .func = @field(@This(), @tagName(t)) }},
    };
}

/// The order groups are appended to a module. `print` first: the others call
/// into it. The groups added after `str_eq` follow in declaration order, so
/// a module that uses none of them renders exactly as before they existed.
pub const order = blk: {
    const all = std.enums.values(ast.HelperGroup);
    var out: [all.len]ast.HelperGroup = undefined;
    for (all, 0..) |g, i| out[i] = g;
    break :blk out;
};

/// Writes the two bytes `a` then `b` through the scratch cells at 8 and 9, in
/// one `fd_write` — the separator idiom `putSep` uses, for any pair.
fn putPair(comptime a: comptime_int, comptime b: comptime_int) [8]Instr {
    return .{ c32(8), c32(a), store8(0), c32(8), c32(b), store8(1), c32(8), c32(2) };
}

/// Decision 8 §7 on wasm (decision 22, `13-module-identity` half 3): the text
/// of a value that carries its own declaration. The value's header word — the
/// i32 four bytes BEHIND the pointer — is the address of the type descriptor
/// the emitter interned, so the text is read from the VALUE and not from the
/// print site, which is what makes a union print correctly.
///
/// The descriptor is length-prefixed, because a wasm loop reads a byte and
/// advances:
///
///     'R' <n> name       <k> [ <n> field <shape…> ] * k    a record
///     'V' <n> Enum.Var   <k> [ <n> field <shape…> ] * k    one variant
///
/// A field's shape is the same self-delimiting code `$__print_shaped_raw`
/// walks, and that function answers the address just past it, so the
/// descriptor needs no length for it. A record's fields start at the pointer;
/// a variant's start one slot in, because slot 0 holds the variant ordinal the
/// `case` arms test.
const print_tagged_raw = func("__print_tagged_raw", &.{"v"}, null, i32s(&.{ "d", "p", "k", "i", "n", "b", "s", "q" }), &.{
    // Decision 8 §7's `Display` half: a type whose `display(self) -> string`
    // the module declares answers its own text. `$__display_of` is written by
    // `wat.zig` per module (a descriptor compare per such type, `0` for none).
    get("v"),                                                                               call("__display_of"),                                     set("s"),              get("s"),
    when(&.{ get("s"), c32(4), op("add"), get("s"), load(0), call("__write_bytes"), ret }), get("v"),                                                 c32(4),                op("sub"),
    load(0),                                                                                set("d"),                                                 get("d"),              c32(1),
    op("add"),                                                                              set("p"),
    // 'V' (86) puts the fields one slot in; 'R' leaves them at the pointer.
                                                    get("v"),              set("b"),
    get("d"),                                                                               load8(0),                                                 c32('V'),              op("eq"),
    when(&.{ get("v"), c32(4), op("add"), set("b") }),
    // The declaration's name.
                                         get("p"),                                                 load8(0),              set("n"),
    get("p"),                                                                               c32(1),                                                   op("add"),             set("p"),
    get("p"),                                                                               get("n"),                                                 call("__write_bytes"), get("p"),
    get("n"),                                                                               op("add"),                                                set("p"),
    // The field count, then one `label: value` per field.
                 get("p"),
    load8(0),                                                                               set("k"),                                                 get("p"),              c32(1),
    op("add"),                                                                              set("p"),                                                 get("k"),              when(&(putByte('(') ++ [_]Instr{call("__write_bytes")})),
    loop(&([_]Instr{
        get("i"), get("k"),                                             op("ge_u"), brk,
        get("i"), when(&(putSep() ++ [_]Instr{call("__write_bytes")})), get("p"),   load8(0),
        set("n"), get("p"),                                             c32(1),     op("add"),
        set("p"), get("p"),                                             get("n"),   call("__write_bytes"),
        get("p"), get("n"),                                             op("add"),  set("p"),
    } ++ putPair(':', ' ') ++ [_]Instr{
        call("__write_bytes"),
    } ++ slot("b", "i") ++ [_]Instr{
        c32(4),   op("sub"), load(0),
        set("s"),
        // `G` — a field written as the declaration's type parameter, or an
        // array or tuple of one. Its construction site stored, after the
        // fields, the address of its arguments' shapes, one after another:
        // `q` walks them, read at the first `G`.
        get("p"),  load8(0),
        c32('G'), op("eq"),
        whenElse(&.{
            get("q"),                                                                        op("eqz"),
            when(&.{ get("b"), get("k"), c32(4), op("mul"), op("add"), load(0), set("q") }), get("s"),
            get("q"),                                                                        c32(1),
            call("__print_shaped_raw"),                                                      set("q"),
            get("p"),                                                                        c32(1),
            op("add"),                                                                       set("p"),
        }, &.{
            get("s"), get("p"), c32(1), call("__print_shaped_raw"), set("p"),
        }),
        get("i"), c32(1),    op("add"),
        set("i"), again,
    })),
    get("k"),                                                                               when(&(putByte(')') ++ [_]Instr{call("__write_bytes")})),
});

const print_tagged = func("__print_tagged", &.{"v"}, null, &.{}, &.{ get("v"), call("__print_tagged_raw"), call("__print_nl") });

// ── decision 238's WASI adapters (`host_binding.zig` `adapters`) ─────────────

/// `random_get(buf, len)` — WASI preview1's one source of random bytes.
pub const random_get_import = ast.Import{
    .module = "wasi_snapshot_preview1",
    .name = "random_get",
    .func = "random_get",
    .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 },
};

/// The seeded stream's word (front 164 s3 P2-e, decision 585 (i)): Mulberry32's
/// state in the low 32 bits of an `i64`, `-1` before any `seed` — the one
/// state `random.wat`'s leaves name as `$__random_state`.
pub const random_state_global = ast.Global{ .name = "__random_state", .ty = .i64, .mutable = true, .init = "-1" };

/// `wasi:random_f64` — 8 bytes of `random_get` into scratch `208..216`, the
/// top 53 bits of them as an integer, scaled by 2^-53: a uniform `f64` in
/// `[0.0, 1.0)`, the range `Math.random` and `rand:uniform/0` answer. An
/// errno from the host is a trap — a value WASI did not give is never made up.
const wasi_random_f64 = typedFunc("__wasi_random_f64", &.{}, .f64, &.{}, &.{
    c32(208),                                                           c32(8),                                    call("random_get"),
    when(&.{.@"unreachable"}),                                          c32(208),                                  .{ .load = .{ .ty = .i64 } },
    c64(11),                                                            op64("shr_u"),                             .{ .convert = "f64.convert_i64_u" },
    .{ .@"const" = .{ .ty = .f64, .text = "1.1102230246251565e-16" } }, .{ .op = .{ .ty = .f64, .name = "mul" } },
});

// ── decision 8 §11's box: a value in an `unknown` or union slot ──────────────
//
// A value entering such a slot carries a header behind its pointer, as a value
// a declaration built does (decision 22): a record or a variant already has one
// and goes in as it is; a primitive is boxed — `[descriptor][payload]`, the
// value being the payload's address — with the descriptor `'P' <n> name`
// (`i32`, `f64`, `bool`, `string`, `array`, `tuple`). The readers below ask the
// header, never the slot's static type, which is what `unknown` does not have.

/// What an `unknown` value holds: `0` for absence, the descriptor's tag for a
/// value that carries its own declaration (`R` / `V`), or the first letter of a
/// boxed primitive's name (`i`, `f`, `b`, `s`, `a`, `t`).
const unknown_kind = func("__unknown_kind", &.{"v"}, .i32, i32s(&.{"d"}), &.{
    get("v"), c32(256),                            op("lt_u"), when(&.{ c32(0), ret }),
    get("v"), c32(4),                              op("sub"),  load(0),
    set("d"), get("d"),                            load8(0),   c32('P'),
    op("ne"), when(&.{ get("d"), load8(0), ret }), get("d"),   load8(2),
});

/// `v is <an integer type>` by value (decision 8 §4.1): a boxed `i32` inside
/// `lo..=hi`, or a boxed `f64` that is a whole number inside it.
const unknown_int_in = typedFunc("__unknown_int_in", &.{ .{ .name = "v", .ty = .i32 }, .{ .name = "lo", .ty = .i32 }, .{ .name = "hi", .ty = .i32 } }, .i32, &.{
    .{ .name = "k", .ty = .i32 }, .{ .name = "x", .ty = .f64 },
}, &.{
    get("v"),                                                                                                       call("__unknown_kind"),              set("k"),
    get("k"),                                                                                                       c32('i'),                            op("eq"),
    when(&.{ get("v"), load(0), get("lo"), op("ge_s"), get("v"), load(0), get("hi"), op("le_s"), op("and"), ret }), get("k"),                            c32('f'),
    op("ne"),                                                                                                       when(&.{ c32(0), ret }),             get("v"),
    .{ .load = .{ .ty = .f64 } },                                                                                   set("x"),                            getF("x"),
    opF("floor"),                                                                                                   getF("x"),                           opF("ne"),
    when(&.{ c32(0), ret }),                                                                                        getF("x"),                           get("lo"),
    .{ .convert = "f64.convert_i32_s" },                                                                            opF("ge"),                           getF("x"),
    get("hi"),                                                                                                      .{ .convert = "f64.convert_i32_s" }, opF("le"),
    op("and"),
});

/// Decision 758 — `v is t` over a run-time type token, `v` an `unknown` value
/// and `t` the blob `wat.zig` `typeTokenAddr` lays out: `[0][n][d0]…` a
/// record's or an enum's descriptors (the value's header is one of them),
/// `[1][lo][hi]` an integer type, `[2]` a float type, `[3]` `bool`, `[4]`
/// `string`, `[5]` `unknown` — each the test `x is T` writes for that type.
const is_type_token = func("__is_type_token", &.{ "v", "t" }, .i32, i32s(&.{ "k", "h", "n", "i" }), &.{
    get("t"),                                                              load(0),                                                                                   set("k"),
    get("k"),                                                              c32(5),                                                                                    op("eq"),
    when(&.{ c32(1), ret }),                                               get("k"),                                                                                  c32(1),
    op("eq"),                                                              when(&.{ get("v"), get("t"), load(4), get("t"), load(8), call("__unknown_int_in"), ret }), get("k"),
    c32(2),                                                                op("eq"),                                                                                  when(&.{ get("v"), call("__unknown_kind"), set("h"), get("h"), c32('i'), op("eq"), get("h"), c32('f'), op("eq"), op("or"), ret }),
    get("k"),                                                              c32(3),                                                                                    op("eq"),
    when(&.{ get("v"), call("__unknown_kind"), c32('b'), op("eq"), ret }), get("k"),                                                                                  c32(4),
    op("eq"),                                                              when(&.{ get("v"), call("__unknown_kind"), c32('s'), op("eq"), ret }),                     get("v"),
    c32(256),                                                              op("lt_u"),                                                                                when(&.{ c32(0), ret }),
    get("v"),                                                              c32(4),                                                                                    op("sub"),
    load(0),                                                               set("h"),                                                                                  get("t"),
    load(4),                                                               set("n"),                                                                                  c32(0),
    set("i"),
    loop(&.{
        get("i"), get("n"),  op("ge_u"),              brk,
        get("t"), c32(8),    op("add"),               get("i"),
        c32(4),   op("mul"), op("add"),               load(0),
        get("h"), op("eq"),  when(&.{ c32(1), ret }), get("i"),
        c32(1),   op("add"), set("i"),                again,
    }),
    c32(0),
});

/// The payload of a boxed number read as an `i32` (a whole `f64` converted).
const unknown_as_i32 = func("__unknown_as_i32", &.{"v"}, .i32, &.{}, &.{
    get("v"),                                                                                   call("__unknown_kind"), c32('f'), op("eq"),
    when(&.{ get("v"), .{ .load = .{ .ty = .f64 } }, .{ .convert = "i32.trunc_f64_s" }, ret }), get("v"),               load(0),
});

/// The payload of a boxed number read as an `f64`.
const unknown_as_f64 = typedFunc("__unknown_as_f64", &.{.{ .name = "v", .ty = .i32 }}, .f64, &.{}, &.{
    get("v"),                                                                call("__unknown_kind"), c32('i'),                     op("eq"),
    when(&.{ get("v"), load(0), .{ .convert = "f64.convert_i32_s" }, ret }), get("v"),               .{ .load = .{ .ty = .f64 } },
});

/// `a == b` with an `unknown` operand (decision 8 §2.3): two numbers compare by
/// value (`2.0 == 2`), two strings by content, two bools by value, anything
/// else by identity.
const unknown_eq = func("__unknown_eq", &.{ "a", "b" }, .i32, i32s(&.{ "ka", "kb" }), &.{
    get("a"),                                                                                           call("__unknown_kind"),                                          set("ka"),
    get("b"),                                                                                           call("__unknown_kind"),                                          set("kb"),
    get("ka"),                                                                                          c32('i'),                                                        op("eq"),
    get("ka"),                                                                                          c32('f'),                                                        op("eq"),
    op("or"),                                                                                           get("kb"),                                                       c32('i'),
    op("eq"),                                                                                           get("kb"),                                                       c32('f'),
    op("eq"),                                                                                           op("or"),                                                        op("and"),
    when(&.{ get("a"), call("__unknown_as_f64"), get("b"), call("__unknown_as_f64"), opF("eq"), ret }), get("ka"),                                                       c32('s'),
    op("eq"),                                                                                           get("kb"),                                                       c32('s'),
    op("eq"),                                                                                           op("and"),                                                       when(&.{ get("a"), load(0), get("b"), load(0), call("__str_eq"), ret }),
    get("ka"),                                                                                          c32('b'),                                                        op("eq"),
    get("kb"),                                                                                          c32('b'),                                                        op("eq"),
    op("and"),                                                                                          when(&.{ get("a"), load(0), get("b"), load(0), op("eq"), ret }), get("a"),
    get("b"),                                                                                           op("eq"),
});

/// An `unknown` value printed by what it holds (decision 8 §7). A boxed array
/// or tuple has no printed form here — its element shapes are not in the box —
/// and traps rather than printing an address.
const print_unknown_raw = func("__print_unknown_raw", &.{"v"}, null, i32s(&.{"k"}), &.{
    get("v"),                                                    op("eqz"),                                                                        when(&.{ call("__print_null"), ret }),
    get("v"),                                                    call("__unknown_kind"),                                                           set("k"),
    get("k"),                                                    c32('i'),                                                                         op("eq"),
    when(&.{ get("v"), load(0), call("__print_i32_raw"), ret }), get("k"),                                                                         c32('f'),
    op("eq"),                                                    when(&.{ get("v"), .{ .load = .{ .ty = .f64 } }, call("__print_f64_raw"), ret }), get("k"),
    c32('b'),                                                    op("eq"),                                                                         when(&.{ get("v"), load(0), call("__print_bool_raw"), ret }),
    get("k"),                                                    c32('s'),                                                                         op("eq"),
    when(&.{ get("v"), load(0), call("__print_str_raw"), ret }), get("k"),                                                                         c32('R'),
    op("eq"),                                                    get("k"),                                                                         c32('V'),
    op("eq"),                                                    op("or"),                                                                         when(&.{ get("v"), call("__print_tagged_raw"), ret }),
    .@"unreachable",
});

const print_unknown = func("__print_unknown", &.{"v"}, null, &.{}, &.{ get("v"), call("__print_unknown_raw"), call("__print_nl") });

/// The `Display` hook's default: no value answers its own text. `wat.zig`
/// replaces it with the module's dispatch when some type declares `display`.
const display_of = func("__display_of", &.{"v"}, .i32, &.{}, &.{c32(0)});

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

/// `$__write_bytes` of a module with `text_capture`: while `$__cap` holds a
/// string, the bytes are appended to a copy of it (the heap is a bump, and a
/// float's text allocates between two writes, so the string cannot grow in
/// place); otherwise they go to stdout as `write_bytes` sends them.
const write_bytes_capture = func("__write_bytes", &.{ "p", "n" }, null, i32s(&.{ "c", "l", "q" }), &.{
    .{ .global_get = "__cap" }, set("c"),
    get("c"),
    when(&.{
        get("c"),  load(0),   set("l"),
        get("l"),  get("n"),  op("add"),
        c32(4),    op("add"), call("__alloc"),
        set("q"),  get("q"),  get("l"),
        get("n"),  op("add"), store(0),
        get("q"),  c32(4),    op("add"),
        get("c"),  c32(4),    op("add"),
        get("l"),  copy,      get("q"),
        c32(4),    op("add"), get("l"),
        op("add"), get("p"),  get("n"),
        copy,      get("q"),  .{ .global_set = "__cap" },
        ret,
    }),
    c32(0),                     get("p"),
    store(0),                   c32(4),
    get("n"),                   store(0),
    c32(1),                     c32(0),
    c32(1),                     c32(8),
    call("fd_write"),           .drop,
});

/// The string `$__write_bytes` appends to while a capture is open, `0` when
/// none is.
const cap_global = ast.Global{ .name = "__cap", .ty = .i32, .mutable = true, .init = "0" };

/// Opens a capture: `$__cap` becomes an empty string; answers the capture it
/// replaces, which `$__cap_end` restores (a `Display` body's hole nests one).
const cap_begin = func("__cap_begin", &.{}, .i32, i32s(&.{ "o", "s" }), &.{
    .{ .global_get = "__cap" }, set("o"),
    c32(4),                     call("__alloc"),
    set("s"),                   get("s"),
    c32(0),                     store(0),
    get("s"),                   .{ .global_set = "__cap" },
    get("o"),
});

/// Closes a capture: answers the string written since `$__cap_begin` and
/// restores the capture `o` it replaced.
const cap_end = func("__cap_end", &.{"o"}, .i32, i32s(&.{"s"}), &.{
    .{ .global_get = "__cap" }, set("s"),
    get("o"),                   .{ .global_set = "__cap" },
    get("s"),
});

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

/// Decision 67 — the most restrictive behaviour, and no flag that turns it off.
/// A string here is a length-prefixed blob in a data segment or on the heap,
/// and both start at the data floor (256); everything below it is the scratch
/// area — `0..8` is the WASI iovec itself. So a pointer below the floor is not
/// a string, it is an absent `?string` whose shape nothing registered, and the
/// honest answer is to stop. Before this guard, `@print` of such a value loaded
/// a length from address 0 and wrote whatever bytes were there at exit 0 with
/// no diagnostic. Measured both ways by disabling the `s.at(i)` arm of
/// `optInfoOf` and rebuilding: `@print(s.at(3))` on `"abc"` wrote six spaces at
/// the tip the row was first written against and a bare newline at `2e6bb4ac`
/// — whatever the iovec happens to hold — and traps here.
const print_str_raw = ast.Func{
    .name = "__print_str_raw",
    .params = &.{.{ .name = "s", .ty = .i32 }},
    .body = .{ .stack = .none, .lines = &.{
        .{ .indent = 4, .instr = .{ .local_get = "s" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "256" } } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "lt_u" } } },
        .{ .indent = 4, .instr = .{ .@"if" = .{
            .then = .{ .seq = .{ .stack = .none, .lines = &.{
                .{ .indent = 8, .instr = .{ .comment = "a pointer below the data floor is not a string" } },
                .{ .indent = 8, .instr = .@"unreachable" },
            } } },
        } } },
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

/// A float as a wasm program writes it: std-wasm's text (decisions 441,
/// 442 (1): the text is std-wasm's `number.floatToString`, the I/O is here)
/// — `5.0`, `0.30000000000000004`, `1.0e21`.
const print_f64_raw = typedFunc("__print_f64_raw", &.{.{ .name = "x", .ty = .f64 }}, null, i32s(&.{"s"}), &.{
    getF("x"), call(stdSymbol("number.floatToString")), set("s"),
    get("s"),  c32(4),                                  op("add"),
    get("s"),  load(0),                                 call("__write_bytes"),
});

const arr_at = ast.Func{
    .name = "__arr_at",
    .params = &.{ .{ .name = "xs", .ty = .i32 }, .{ .name = "i", .ty = .i32 } },
    .result = .i32,
    .body = .{
        .stack = .{ .value = .i32 },
        .lines = &.{
            // A negative index counts from the end (decision 139): i += len.
            .{ .indent = 4, .instr = .{ .local_get = "i" } },
            .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
            .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "lt_s" } } },
            .{ .indent = 4, .instr = .{ .@"if" = .{
                .then = .{ .seq = .{ .stack = .none, .lines = &.{
                    .{ .indent = 8, .instr = .{ .local_get = "i" } },
                    .{ .indent = 8, .instr = .{ .local_get = "xs" } },
                    .{ .indent = 8, .instr = .{ .load = .{ .ty = .i32 } } },
                    .{ .indent = 8, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
                    .{ .indent = 8, .instr = .{ .local_set = "i" } },
                } } },
            } } },
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
        },
    },
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
        .{ .indent = 4, .instr = .{ .comment = "allocate 4 (length prefix) + alen + blen" } },
        .{ .indent = 4, .instr = .{ .@"const" = .{ .ty = .i32, .text = "4" } } },
        .{ .indent = 4, .instr = .{ .local_get = "alen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .local_get = "blen" } },
        .{ .indent = 4, .instr = .{ .op = .{ .ty = .i32, .name = "add" } } },
        .{ .indent = 4, .instr = .{ .call = "__alloc" } },
        .{ .indent = 4, .instr = .{ .local_set = "base" } },
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

// ── groups ───────────────────────────────────────────────────────────────────

const print_items = [_]ast.Item{
    .{ .comment = "Scratch layout below the data section (which starts at 256):" },
    .{ .comment = "  0..8  WASI iovec   8  newline byte" },
    .{ .comment = " 16..32 bool text   64..128 i32 digits" },
    .{ .func = write_bytes },
    .{ .func = print_nl },
    .{ .comment = "separator between the arguments of a multi-argument `@print`" },
    .{ .func = print_sp },
    .{ .func = print_i32 },
    .{ .func = print_i32_raw },
    .{ .func = memmove },
};
/// `print_items` with the capturing `$__write_bytes` — a module that writes a
/// value's text into a string (`text_capture`).
pub const print_items_capture = blk: {
    var out = print_items;
    for (&out) |*it| if (it.* == .func and std.mem.eql(u8, it.func.name, "__write_bytes")) {
        it.* = .{ .func = write_bytes_capture };
    };
    break :blk out;
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

// ── helpers built with it ────────────────────────────────────────────────────

/// Bump-allocate `n` bytes, keeping the heap pointer on a 4-byte boundary —
/// the one bump of the heap every allocation goes through (decision 261).
/// When the new pointer `e` passes the memory's end (`memory.size` pages of
/// 64 KiB), `memory.grow` adds the pages it needs; a grow the host refuses
/// (`-1`) traps, and so does a pointer that wrapped past 2^32 (`e < p`), as an
/// allocation the other targets' hosts cannot make fails there.
const alloc = func("__alloc", &.{"n"}, .i32, i32s(&.{ "p", "e" }), &.{
    .{ .global_get = heap }, set("p"),
    get("p"),                get("n"),
    op("add"),               c32(3),
    op("add"),               c32(-4),
    op("and"),               set("e"),
    get("e"),                get("p"),
    op("lt_u"),              when(&.{.@"unreachable"}),
    get("e"),                .memory_size,
    c32(16),                 op("shl"),
    op("gt_u"),
    when(&.{
        get("e"),    c32(65535),   op("add"),                 c32(16),
        op("shr_u"), .memory_size, op("sub"),                 .memory_grow,
        c32(-1),     op("eq"),     when(&.{.@"unreachable"}),
    }),
    get("e"),                .{ .global_set = heap },
    get("p"),
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

/// A fresh array blob of `n` elements (`[n][e0]…`), elements unset.
const arr_new = func("__arr_new", &.{"n"}, .i32, i32s(&.{"p"}), &.{
    get("n"), c32(1),   op("add"), c32(4),   op("mul"), call("__alloc"), set("p"),
    get("p"), get("n"), store(0),  get("p"),
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

// ── 1.0.11 `01-compiler/05-wasm` step 1: the primitive methods that trapped ──

/// Writes one byte through the newline scratch cell at 8.
fn putByte(comptime ch: comptime_int) [5]Instr {
    return .{ c32(8), c32(ch), store8(0), c32(8), c32(1) };
}

/// `text` byte by byte through the newline scratch cell, one `$__write_bytes` per
/// byte — the words a `@Result` is written with (`Ok(`, `Error(`).
fn putText(comptime text: []const u8) [text.len * 6]Instr {
    var out: [text.len * 6]Instr = undefined;
    for (text, 0..) |ch, k| {
        const one = putByte(ch) ++ [_]Instr{call("__write_bytes")};
        for (one, 0..) |ins, j| out[k * 6 + j] = ins;
    }
    return out;
}

/// `, ` — decision 8 §7's separator inside an array or a tuple. Both bytes go
/// through the scratch cells at 8 and 9 in one `fd_write`, so the separator
/// costs the same one call the bare comma did. The whole of §7 F1 is this
/// function replacing `putByte(',')` at the four sites that write a separator:
/// the two flat-array printers and `$__print_shaped_raw`'s array and tuple arms.
fn putSep() [8]Instr {
    return .{ c32(8), c32(','), store8(0), c32(8), c32(' '), store8(1), c32(8), c32(2) };
}

/// `[1, 2, 3]` — the elements of an i32 array, comma-separated with the space
/// decision 8 §7 wants (commonJS and beam already write it; erlang owes the
/// same row as `02-erlang` step 1 F1).
const print_arr_i32_raw = func("__print_arr_i32_raw", &.{"xs"}, null, i32s(&.{ "n", "i" }), &(putByte('[') ++ [_]Instr{call("__write_bytes")} ++ [_]Instr{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("i"), when(&(putSep() ++ [_]Instr{call("__write_bytes")})) } ++ slot("xs", "i") ++ [_]Instr{
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

/// The program function a std-wasm function is emitted as
/// (`std_wasm_link.entryName`, at comptime): `number.floatToString` →
/// `__std_number_floatToString`. A prelude helper that writes a number calls
/// std-wasm for its text (decision 442 (1)); the group names the function in
/// `HelperGroup.stdCalls`, so a module holding it links it.
pub fn stdSymbol(comptime name: []const u8) []const u8 {
    comptime {
        var out: [name.len]u8 = name[0..name.len].*;
        std.mem.replaceScalar(u8, &out, '.', '_');
        const final = out;
        return "__std_" ++ &final;
    }
}

fn cF(comptime text: []const u8) Instr {
    return .{ .@"const" = .{ .ty = .f64, .text = text } };
}
fn cv(comptime opcode: []const u8) Instr {
    return .{ .convert = opcode };
}
fn l32(comptime n: []const u8) ast.Local {
    return .{ .name = n, .ty = .i32 };
}
fn l64(comptime n: []const u8) ast.Local {
    return .{ .name = n, .ty = .i64 };
}
fn p64(comptime n: []const u8) P {
    return .{ .name = n, .ty = .i64 };
}
fn p32(comptime n: []const u8) P {
    return .{ .name = n, .ty = .i32 };
}
/// `loop` with its own labels, for a loop inside another.
fn loopAs(comptime out: []const u8, comptime cont: []const u8, comptime body: []const Instr) Instr {
    const inner: Instr = .{ .block = .{ .kind = .loop, .label = cont, .body = seqOf(body, .none) } };
    return .{ .block = .{ .kind = .block, .label = out, .body = seqOf(&.{inner}, .none) } };
}

// ── integer arithmetic that refuses to wrap ──────────────────────────────────
//
// commonJS and erlang never wrap an integer: `2147483647 + 1` is `2147483648`
// on both. wasm's `i32.add` wrapped it to `-2147483648` at exit 0. An `i32`
// `+`, `-`, `*` is computed in `i64` and checked back into the `i32` range;
// an `i64` one is checked by the signs (`+`, `-`) or by dividing back (`*`).
// A result the type cannot hold traps — the value the program asked for does
// not exist in its declared type.

/// The check's abort: `$__chk_fail(site)` (decision 527 (3)) — `site` the
/// message the call names, a length-prefixed string (an `i32` in linear
/// memory, a `$str` in a `.gc` module).
fn failChk() Instr {
    return when(&.{ get("site"), call("__chk_fail"), .@"unreachable" });
}

fn chk32(comptime name: []const u8, comptime opname: []const u8, comptime site: P) ast.Func {
    return typedFunc(name, &.{ p32("a"), p32("b"), site }, .i32, &.{l64("r")}, &.{
        get("a"), cv("i64.extend_i32_s"), get("b"),               cv("i64.extend_i32_s"), op64(opname), set("r"),
        get("r"), cv("i32.wrap_i64"),     cv("i64.extend_i32_s"), get("r"),               op64("ne"),   failChk(),
        get("r"), cv("i32.wrap_i64"),
    });
}

fn i64Chk(comptime site: P) [3]ast.Func {
    return .{
        typedFunc("__i64_add_chk", &.{ p64("a"), p64("b"), site }, .i64, &.{l64("r")}, &.{
            get("a"),     get("b"),    op64("add"), set("r"),
            // overflow iff both operands differ in sign from the result
            get("a"),     get("r"),    op64("xor"), get("b"),
            get("r"),     op64("xor"), op64("and"), c64(0),
            op64("lt_s"), failChk(),   get("r"),
        }),
        typedFunc("__i64_sub_chk", &.{ p64("a"), p64("b"), site }, .i64, &.{l64("r")}, &.{
            get("a"),     get("b"),    op64("sub"), set("r"),
            // overflow iff the operands differ in sign and the result's sign is `b`'s
            get("a"),     get("b"),    op64("xor"), get("a"),
            get("r"),     op64("xor"), op64("and"), c64(0),
            op64("lt_s"), failChk(),   get("r"),
        }),
        typedFunc("__i64_mul_chk", &.{ p64("a"), p64("b"), site }, .i64, &.{l64("r")}, &.{
            get("a"),  c64(-1),                                                                        op64("eq"), get("b"),    c64(-9223372036854775808), op64("eq"), op("and"),
            failChk(), get("a"),                                                                       get("b"),   op64("mul"), set("r"),                  get("a"),   op64("eqz"),
            op("eqz"), when(&.{ get("r"), get("a"), op64("div_s"), get("b"), op64("ne"), failChk() }), get("r"),
        }),
    };
}

// A type narrower than its carrier (`i8`, `u8`, `i16`, `u16` in an `i32`;
// `u32`, `u64` in an `i64`) checks the carrier's result against its own
// range (decision 264): `v` answered inside `lo..=hi`, an abort outside it.
fn i32RangeChk(comptime site: P) ast.Func {
    return typedFunc("__i32_range_chk", &.{ p32("v"), p32("lo"), p32("hi"), site }, .i32, &.{}, &.{
        get("v"), get("lo"), op("lt_s"), get("v"), get("hi"), op("gt_s"),
        op("or"), failChk(), get("v"),
    });
}
fn i64RangeChk(comptime site: P) ast.Func {
    return typedFunc("__i64_range_chk", &.{ p64("v"), p64("lo"), p64("hi"), site }, .i64, &.{}, &.{
        get("v"), get("lo"), op64("lt_s"), get("v"), get("hi"), op64("gt_s"),
        op("or"), failChk(), get("v"),
    });
}

/// `$__i32_nz(b, site)` / `$__i64_nz` — a divisor answered back when it is
/// not zero, else the abort (decision 527 (3)); the dividend waits beneath it
/// on the stack and the division follows.
fn nzItems(comptime site: P) [4]ast.Item {
    const osite = P{ .name = "osite", .ty = site.ty };
    const ovf = when(&.{ get("osite"), call("__chk_fail"), .@"unreachable" });
    return .{
        // The signed `div_s`: the zero divisor, then `MIN / -1` — the one quotient
        // wasm traps on bare — checked, else the quotient (decision 527 (3)).
        .{ .func = typedFunc("__i32_divs", &.{ p32("a"), p32("b"), site, osite }, .i32, &.{}, &.{
            get("b"), op("eqz"), failChk(), get("a"), c32(-2147483648), op("eq"), get("b"), c32(-1), op("eq"), op("and"), ovf, get("a"), get("b"), op("div_s"),
        }) },
        .{ .func = typedFunc("__i64_divs", &.{ p64("a"), p64("b"), site, osite }, .i64, &.{}, &.{
            get("b"), op64("eqz"), failChk(), get("a"), c64(-9223372036854775808), op64("eq"), get("b"), c64(-1), op64("eq"), op("and"), ovf, get("a"), get("b"), op64("div_s"),
        }) },
        .{ .func = typedFunc("__i32_nz", &.{ p32("b"), site }, .i32, &.{}, &.{ get("b"), op("eqz"), failChk(), get("b") }) },
        .{ .func = typedFunc("__i64_nz", &.{ p64("b"), site }, .i64, &.{}, &.{ get("b"), op64("eqz"), failChk(), get("b") }) },
    };
}

/// `$__u64_{add,sub,mul}_chk` — see the `u64` section below.
fn u64Chk(comptime site: P) [3]ast.Item {
    return .{
        .{ .func = typedFunc("__u64_add_chk", &.{ p64("a"), p64("b"), site }, .i64, &.{l64("r")}, &.{
            get("a"), get("b"), op64("add"), tee("r"), get("a"), op64("lt_u"), failChk(), get("r"),
        }) },
        .{ .func = typedFunc("__u64_sub_chk", &.{ p64("a"), p64("b"), site }, .i64, &.{}, &.{
            get("a"), get("b"), op64("lt_u"), failChk(), get("a"), get("b"), op64("sub"),
        }) },
        .{ .func = typedFunc("__u64_mul_chk", &.{ p64("a"), p64("b"), site }, .i64, &.{l64("r")}, &.{
            get("a"), get("b"),    op64("mul"), set("r"),
            get("a"), op64("eqz"), op("eqz"),   when(&.{ get("r"), get("a"), op64("div_u"), get("b"), op64("ne"), failChk() }),
            get("r"),
        }) },
    };
}

const linear_site = p32("site");

fn intChkItems(comptime site: P) [6]ast.Item {
    const w = i64Chk(site);
    return .{
        .{ .func = chk32("__i32_add_chk", "add", site) }, .{ .func = chk32("__i32_sub_chk", "sub", site) }, .{ .func = chk32("__i32_mul_chk", "mul", site) },
        .{ .func = w[0] },                                .{ .func = w[1] },                                .{ .func = w[2] },
    };
}
const int_chk_items = intChkItems(linear_site);
const i32_range_chk = i32RangeChk(linear_site);
const i64_range_chk = i64RangeChk(linear_site);
const nz_chk_items = nzItems(linear_site);
const u64_chk_items = u64Chk(linear_site);

/// `$__chk_fail(site)` — the abort of a checked operation: raised as the
/// exception `attempt` catches when the program reaches it (`exceptions`),
/// else `panic: <message>` on stderr and a trap.
pub fn chkFail(exceptions: bool) ast.Func {
    return if (exceptions) chk_fail_raise else chk_fail_write;
}
const chk_fail_raise = typedFunc("__chk_fail", &.{linear_site}, null, &.{}, &.{ get("site"), c32(1), call("__panic_raise"), .@"unreachable" });
const chk_fail_write = typedFunc("__chk_fail", &.{linear_site}, null, &.{}, &.{ get("site"), call("__panic_fail"), .@"unreachable" });
/// The `.gc` form of `chkFail`: the message is a `$str` (a raise has no GC form yet).
pub const gc_chk_fail = typedFunc("__chk_fail", &.{pref("site")}, null, &.{}, &.{ get("site"), call("__panic_fail"), .@"unreachable" });

/// An `i64` printed in all its digits. It was lowered as an `i32`:
/// `val a: i64 = 4294967295` printed `-1`. The digits are std-wasm's
/// (`number.i64Text`, written in its one workspace, so printing allocates
/// nothing); the I/O is here (decision 442 (1)).
const print_i64_raw = typedFunc("__print_i64_raw", &.{p64("v")}, null, i32s(&.{"t"}), &.{
    get("v"), call(stdSymbol("number.i64Text")), set("t"),
    get("t"), c32(4),                            op("add"),
    get("t"), load(0),                           call("__write_bytes"),
});
const print_i64 = typedFunc("__print_i64", &.{p64("v")}, null, &.{}, &.{ get("v"), call("__print_i64_raw"), call("__print_nl") });

// ── `u64` / `usize`: the carrier's 64 bits, unsigned (decision 319) ──────────
//
// A `u64` lives in an `i64`, and every value past `2^63 − 1` has the sign bit
// set: read as signed it printed `-8446744073709551616` for `10^19` at exit 0,
// and `10^19 - 3·10^18` trapped in `$__i64_sub_chk`. Its digits, its checked
// `+ - *` and (in `wat.zig`) its `/ % < > <= >=` read the bits unsigned.

/// A `u64`'s carrier bits as unsigned digits — std-wasm's `number.u64Text`.
const print_u64_raw = typedFunc("__print_u64_raw", &.{p64("v")}, null, i32s(&.{"t"}), &.{
    get("v"), call(stdSymbol("number.u64Text")), set("t"),
    get("t"), c32(4),                            op("add"),
    get("t"), load(0),                           call("__write_bytes"),
});
const print_u64 = typedFunc("__print_u64", &.{p64("v")}, null, &.{}, &.{ get("v"), call("__print_u64_raw"), call("__print_nl") });

/// An `i64` in a 4-byte word slot — a record field, a `?i64` — is the address
/// of an 8-byte cell, as a float is (`$__box_f64`). Wrapped to an `i32` in the
/// slot itself, `4294967295` read back as `-1`.
const box_i64 = typedFunc("__box_i64", &.{p64("v")}, .i32, i32s(&.{"p"}), &.{
    c32(8), call("__alloc"), tee("p"), get("v"), .{ .store = .{ .ty = .i64 } }, get("p"),
});

/// A `?i64`: the address of its cell (`$__box_i64`), or `0` — `null`.
const print_opt_i64_raw = func("__print_opt_i64_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                                                  op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("p"), .{ .load = .{ .ty = .i64 } }, call("__print_i64_raw") }),
});
const print_opt_i64 = func("__print_opt_i64", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_i64_raw"), call("__print_nl") });

/// A `?u64`: the address of its cell, or `0` — `null`. The cell's bits are
/// unsigned (`$__print_u64_raw`); through `$__print_opt_i64_raw`,
/// `18446744073709551615` printed `-1`.
const print_opt_u64_raw = func("__print_opt_u64_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                                                  op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("p"), .{ .load = .{ .ty = .i64 } }, call("__print_u64_raw") }),
});
const print_opt_u64 = func("__print_opt_u64", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_u64_raw"), call("__print_nl") });

/// `[115, 287.5, 460]` — the elements of a float array, each slot the address
/// of its `f64` cell (`$__box_f64`), printed like `$__print_f64`.
const print_arr_f64_raw = func("__print_arr_f64_raw", &.{"xs"}, null, i32s(&.{ "n", "i" }), &(putByte('[') ++ .{call("__write_bytes")} ++ [_]Instr{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("i"), when(&(putSep() ++ [_]Instr{call("__write_bytes")})) } ++ slot("xs", "i") ++ [_]Instr{
        load(0),  .{ .load = .{ .ty = .f64 } }, call("__print_f64_raw"),
        get("i"), c32(1),                       op("add"),
        set("i"), again,
    })),
} ++ putByte(']') ++ .{call("__write_bytes")}));

const print_arr_f64 = func("__print_arr_f64", &.{"xs"}, null, &.{}, &.{ get("xs"), call("__print_arr_f64_raw"), call("__print_nl") });

/// A float in a 4-byte word slot — an array or tuple element, a variant's
/// payload, a `?f64`, a closure's capture — is the address of an 8-byte `f64`
/// cell, as a record's float field is. Narrowed to an `f32` in the slot itself,
/// `1.1` read back as `1.100000023841858`. A cell is never written again once
/// made: a slot that takes another float takes another cell.
const box_f64 = typedFunc("__box_f64", &.{.{ .name = "x", .ty = .f64 }}, .i32, i32s(&.{"p"}), &.{
    c32(8),                        call("__alloc"), tee("p"), getF("x"),
    .{ .store = .{ .ty = .f64 } }, get("p"),
});

/// Writes the byte in local `name` through the newline scratch cell at 8.
fn putLocalByte(comptime name: []const u8) [6]Instr {
    return .{ c32(8), get(name), store8(0), c32(8), c32(1), call("__write_bytes") };
}

/// `"text"` — a string nested in an array or a tuple, quoted with the source
/// escapes `\"`, `\\`, `\n`, `\r`, `\t` (semantics decision 1a).
const print_quoted_raw = func("__print_quoted_raw", &.{"s"}, null, i32s(&.{ "n", "i", "ch", "e" }), &(putByte('"') ++ [_]Instr{call("__write_bytes")} ++ [_]Instr{
    get("s"), load(0), set("n"),
    loop(&([_]Instr{
        get("i"),                        get("n"),  op("ge_u"),                                                                                              brk,
        get("s"),                        c32(4),    op("add"),                                                                                               get("i"),
        op("add"),                       load8(0),  set("ch"),                                                                                               c32(0),
        set("e"),                        get("ch"), c32('"'),                                                                                                op("eq"),
        get("ch"),                       c32('\\'), op("eq"),                                                                                                op("or"),
        when(&.{ get("ch"), set("e") }), get("ch"), c32('\n'),                                                                                               op("eq"),
        when(&.{ c32('n'), set("e") }),  get("ch"), c32('\r'),                                                                                               op("eq"),
        when(&.{ c32('r'), set("e") }),  get("ch"), c32('\t'),                                                                                               op("eq"),
        when(&.{ c32('t'), set("e") }),  get("e"),  whenElse(&(putByte('\\') ++ [_]Instr{call("__write_bytes")} ++ putLocalByte("e")), &putLocalByte("ch")), get("i"),
        c32(1),                          op("add"), set("i"),                                                                                                again,
    })),
} ++ putByte('"') ++ [_]Instr{call("__write_bytes")}));

/// The text of `v` by the shape at `sh`, answering the address just past that
/// shape (semantics decision 1a). Shape codes: `F <n>` a function value of arity `n` — `fn/<n>` —, `i` an i32, `b` a bool, `f` an
/// `f64` cell, `l` / `u` an `i64` / `u64` cell, `s` a string (quoted), `[X` an array of `X` — `[e1, e2]` —,
/// `?X` / `!X` a `?T` (`null`, or `X` over the slot / over its box's word),
/// `(XY…)` a tuple — `#(e1, e2)` —, `R<ok><err>` a `@Result` — `Ok(x)` / `Error(y)` —, `n` a `bigint` (in a module that links
/// the `bigint` group, `print_shaped_raw_bigint`), and `E k [ <n> Enum.Variant ] * k` a value
/// of an all-unit enum, whose ordinal picks one of the `k` names. With `go` =
/// 0 nothing is written and nothing is read through `v`: the call only
/// measures a shape, which is how an array finds the end of its element shape
/// when it has no element.
const print_shaped_raw_body = [_]Instr{
    get("sh"),                                                                                                  load8(0),                                                                                                   set("c"),
    get("c"),                                                                                                   c32('i'),                                                                                                   op("eq"),
    when(&.{ get("go"), when(&.{ get("v"), call("__print_i32_raw") }), get("sh"), c32(1), op("add"), ret }),    get("c"),                                                                                                   c32('b'),
    op("eq"),                                                                                                   when(&.{ get("go"), when(&.{ get("v"), call("__print_bool_raw") }), get("sh"), c32(1), op("add"), ret }),   get("c"),
    c32('f'),                                                                                                   op("eq"),
    when(&.{
        get("go"),
        when(&.{ get("v"), .{ .load = .{ .ty = .f64 } }, call("__print_f64_raw") }),
        get("sh"),
        c32(1),
        op("add"),
        ret,
    }),
    // `l`: an `i64` (or `u32`) in a record field or a tuple slot, the
    // address of its cell (`$__box_i64`).
    get("c"),                                                                                                   c32('l'),                                                                                                   op("eq"),
    when(&.{
        get("go"),
        when(&.{ get("v"), .{ .load = .{ .ty = .i64 } }, call("__print_i64_raw") }),
        get("sh"),
        c32(1),
        op("add"),
        ret,
    }),
    // `u`: a `u64` in a record field or a tuple slot, the address of its
    // cell, whose bits are unsigned (decision 319) — through `l` the field
    // printed `-1` for `18446744073709551615`.
    get("c"),                                                                                                   c32('u'),                                                                                                   op("eq"),
    when(&.{
        get("go"),
        when(&.{ get("v"), .{ .load = .{ .ty = .i64 } }, call("__print_u64_raw") }),
        get("sh"),
        c32(1),
        op("add"),
        ret,
    }),
    get("c"),                                                                                                   c32('s'),                                                                                                   op("eq"),
    when(&.{ get("go"), when(&.{ get("v"), call("__print_quoted_raw") }), get("sh"), c32(1), op("add"), ret }), get("c"),                                                                                                   c32('T'),
    op("eq"),
    // `T` — a value that carries its own declaration: its text is read from
    // the header, so a container of records names each element's type.
                                                                                                      when(&.{ get("go"), when(&.{ get("v"), call("__print_tagged_raw") }), get("sh"), c32(1), op("add"), ret }), get("c"),
    c32('['),                                                                                                   op("eq"),
    when(&([_]Instr{
        get("go"),                               when(&(putByte('[') ++ [_]Instr{call("__write_bytes")})),
        get("sh"),                               c32(1),
        op("add"),                               set("e"),
        c32(0),                                  get("e"),
        c32(0),                                  call("__print_shaped_raw"),
        set("p"),                                get("go"),
        when(&.{ get("v"), load(0), set("n") }),
        loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("i"), when(&(putSep() ++ [_]Instr{call("__write_bytes")})) } ++ slot("v", "i") ++ [_]Instr{
            load(0),  get("e"), c32(1),    call("__print_shaped_raw"), .drop,
            get("i"), c32(1),   op("add"), set("i"),                   again,
        })),
        get("go"),                               when(&(putByte(']') ++ [_]Instr{call("__write_bytes")})),
        get("p"),                                ret,
    })),
    // `F <n>` — a function value (decision 1051): `fn/<n>`, the arity the
    // shape carries; the closure cell is not read.
    get("c"),                                                                                                   c32('F'),                                                                                                   op("eq"),
    when(&([_]Instr{get("go")} ++ [_]Instr{when(&(putText("fn/") ++ [_]Instr{ get("sh"), c32(1), op("add"), load8(0), call("__print_i32_raw") }))} ++ [_]Instr{
        get("sh"), c32(2), op("add"), ret,
    })),
    // `E k [ <n> Enum.Variant ] * k` — an all-unit enum's value is its
    // ordinal, with no header to read, so the shape carries the names and
    // the ordinal picks one.
    get("c"),                                                                                                   c32('E'),                                                                                                   op("eq"),
    when(&[_]Instr{
        get("sh"), c32(1), op("add"), load8(0), set("n"),
        get("sh"), c32(2), op("add"), set("p"),
        loop(&[_]Instr{
            get("i"),  get("n"),                                                                                                                     op("ge_u"), brk,
            get("go"), when(&.{ get("i"), get("v"), op("eq"), when(&.{ get("p"), c32(1), op("add"), get("p"), load8(0), call("__write_bytes") }) }), get("p"),   get("p"),
            load8(0),  op("add"),                                                                                                                    c32(1),     op("add"),
            set("p"),  get("i"),                                                                                                                     c32(1),     op("add"),
            set("i"),  again,
        }),
        get("p"),  ret,
    }),
    // `?X` — a `?T` whose slot is the payload's own pointer or 8-byte cell;
    // `!X` — one whose payload is a scalar in a `$__box_i32` cell. `0` is
    // absence in both, written `null`; measuring (`go` = 0) reads nothing.
    get("c"),                                                                                                   c32('?'),                                                                                                   op("eq"),
    get("c"),                                                                                                   c32('!'),                                                                                                   op("eq"),
    op("or"),
    when(&[_]Instr{
        get("sh"), c32(1),                                  op("add"), set("e"),
        get("go"), get("v"),                                op("eqz"), op("and"),
        when(&[_]Instr{
            c32(176),                   c32(1819047278), .{ .store = .{ .ty = .i32 } },
            c32(176),                   c32(4),          call("__write_bytes"),
            c32(0),                     get("e"),        c32(0),
            call("__print_shaped_raw"), ret,
        }),
        get("go"), get("c"),                                c32('!'),  op("eq"),
        op("and"), when(&.{ get("v"), load(0), set("v") }), get("v"),  get("e"),
        get("go"), call("__print_shaped_raw"),              ret,
    }),
    // `R <ok> <err>` — a `@Result`: the address of its `{ tag, payload }` pair
    // (tag 0 = Ok, the payload a word at +4). It is written `Ok(81)` /
    // `Error("bad")`, the payload by the shape of its side (144 B-53); with
    // `go` = 0 the call only measures the two shapes.
    get("c"),                                                                                                   c32('R'),                                                                                                   op("eq"),
    when(&([_]Instr{
        get("sh"),                  c32(1),   op("add"), set("e"),
        c32(0),                     get("e"), c32(0),    call("__print_shaped_raw"),
        set("p"),                   c32(0),   get("p"),  c32(0),
        call("__print_shaped_raw"), set("n"), get("go"),
        when(&([_]Instr{
            get("v"), load(0),
            whenElse(
                &(putText("Error(") ++ [_]Instr{ get("v"), load(4), get("p"), c32(1), call("__print_shaped_raw"), .drop }),
                &(putText("Ok(") ++ [_]Instr{ get("v"), load(4), get("e"), c32(1), call("__print_shaped_raw"), .drop }),
            ),
        } ++ putText(")"))),
        get("n"),                   ret,
    })),
    get("c"),                                                                                                   c32('('),                                                                                                   op("eq"),
    when(&([_]Instr{
        get("go"), when(&(putByte('#') ++ [_]Instr{call("__write_bytes")} ++ putByte('(') ++ [_]Instr{call("__write_bytes")})),
        get("sh"), c32(1),
        op("add"), set("p"),
        loop(&[_]Instr{
            get("p"),                   load8(0),                                                                   c32(')'), op("eq"), brk,
            get("go"),                  when(&.{ get("i"), when(&(putSep() ++ [_]Instr{call("__write_bytes")})) }), get("v"), get("i"), c32(4),
            op("mul"),                  op("add"),                                                                  load(0),  get("p"), get("go"),
            call("__print_shaped_raw"), set("p"),                                                                   get("i"), c32(1),   op("add"),
            set("i"),                   again,
        }),
        get("go"), when(&(putByte(')') ++ [_]Instr{call("__write_bytes")})),
        get("p"),  c32(1),
        op("add"), ret,
    })),
    get("sh"),                                                                                                  c32(1),                                                                                                     op("add"),
};

const print_shaped_raw = func("__print_shaped_raw", &.{ "v", "sh", "go" }, .i32, i32s(&.{ "c", "n", "i", "p", "e" }), &print_shaped_raw_body);

/// Decision 332 — `$__print_shaped_raw` with the `n` code: a `bigint` slot,
/// the address of its block, written as its digits (std-wasm's
/// `bigint.toString`). The module substitutes this form when it holds the
/// `bigint` group, so a module without one renders as before.
const bigint_arm = [_]Instr{
    get("sh"), load8(0), c32('n'), op("eq"),
    when(&.{
        get("go"),
        when(&.{ get("v"), call(stdSymbol("bigint.toString")), set("e"), get("e"), c32(4), op("add"), get("e"), load(0), call("__write_bytes") }),
        get("sh"),
        c32(1),
        op("add"),
        ret,
    }),
};

/// Decision 150 — the `U` code: a slot holding a union's (or `unknown`'s)
/// box, printed by what it holds — a string quoted, as in any container,
/// `0` as `null`. The module substitutes this form when it holds the
/// `print_shaped_unknown` group.
const unknown_arm = [_]Instr{
    get("sh"), load8(0), c32('U'), op("eq"),
    when(&.{
        get("go"),
        when(&.{
            get("v"), op("eqz"),
            whenElse(&.{call("__print_null")}, &.{
                get("v"),                                                                                                   call("__unknown_kind"), c32('s'), op("eq"),
                whenElse(&.{ get("v"), load(0), call("__print_quoted_raw") }, &.{ get("v"), call("__print_unknown_raw") }),
            }),
        }),
        get("sh"),
        c32(1),
        op("add"),
        ret,
    }),
};

const print_shaped_raw_bigint = func("__print_shaped_raw", &.{ "v", "sh", "go" }, .i32, i32s(&.{ "c", "n", "i", "p", "e" }), &(bigint_arm ++ print_shaped_raw_body));
const print_shaped_raw_unknown = func("__print_shaped_raw", &.{ "v", "sh", "go" }, .i32, i32s(&.{ "c", "n", "i", "p", "e" }), &(unknown_arm ++ print_shaped_raw_body));
const print_shaped_raw_bigint_unknown = func("__print_shaped_raw", &.{ "v", "sh", "go" }, .i32, i32s(&.{ "c", "n", "i", "p", "e" }), &(bigint_arm ++ unknown_arm ++ print_shaped_raw_body));

/// `print_shaped`'s forms with `print_shaped_raw_bigint` in its place.
pub const print_shaped_items_bigint = [_]ast.Item{ .{ .func = print_quoted_raw }, .{ .func = print_tagged_raw }, .{ .func = print_tagged }, .{ .func = print_shaped_raw_bigint } };
/// With `print_shaped_raw_unknown` in its place.
pub const print_shaped_items_unknown = [_]ast.Item{ .{ .func = print_quoted_raw }, .{ .func = print_tagged_raw }, .{ .func = print_tagged }, .{ .func = print_shaped_raw_unknown } };
/// With both arms.
pub const print_shaped_items_bigint_unknown = [_]ast.Item{ .{ .func = print_quoted_raw }, .{ .func = print_tagged_raw }, .{ .func = print_tagged }, .{ .func = print_shaped_raw_bigint_unknown } };

/// A `?T` box: a fresh 4-byte cell holding `v`.
const box_i32 = func("__box_i32", &.{"v"}, .i32, i32s(&.{"p"}), &.{
    c32(4),   call("__alloc"), set("p"),
    get("p"), get("v"),        store(0),
    get("p"),
});

/// `xs.at(i)` as a `?T`: a box holding the element, or 0 out of range; a
/// negative `i` counts from the end (`i + len`, decision 139).
const arr_at_box = func("__arr_at_box", &.{ "xs", "i" }, .i32, &.{}, &([_]Instr{
    get("i"),                c32(0),  op("lt_s"), when(&.{ get("i"), get("xs"), load(0), op("add"), set("i") }),
    get("i"),                c32(0),  op("lt_s"), get("i"),
    get("xs"),               load(0), op("ge_s"), op("or"),
    when(&.{ c32(0), ret }),
} ++ slot("xs", "i") ++ [_]Instr{ load(0), call("__box_i32") }));

/// `null` — decision 47's one spelling of absent (1.0.5-beta), what an empty
/// `?T` prints as on every target. Written through scratch `176..180`.
const print_null = func("__print_null", &.{}, null, &.{}, &.{
    c32(176), c32(1819047278), .{ .store = .{ .ty = .i32 } },
    c32(176), c32(4),          call("__write_bytes"),
});

const print_opt_i32_raw = func("__print_opt_i32_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                             op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("p"), load(0), call("__print_i32_raw") }),
});
const print_opt_i32 = func("__print_opt_i32", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_i32_raw"), call("__print_nl") });

const print_opt_bool_raw = func("__print_opt_bool_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                              op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("p"), load(0), call("__print_bool_raw") }),
});
const print_opt_bool = func("__print_opt_bool", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_bool_raw"), call("__print_nl") });

const print_opt_str_raw = func("__print_opt_str_raw", &.{"s"}, null, &.{}, &.{
    get("s"),                                                                    op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("s"), call("__print_str_raw") }),
});
const print_opt_str = func("__print_opt_str", &.{"s"}, null, &.{}, &.{ get("s"), call("__print_opt_str_raw"), call("__print_nl") });

/// A `?f64`: the address of an `f64` cell (`$__box_f64`) — `fs.at(0)` on a
/// float array is the element's own cell — or `0`. Reading it with
/// `$__print_opt_i32` printed the float's **bits** (`1069547520` for `1.5`)
/// with exit 0.
const print_opt_f64_raw = func("__print_opt_f64_raw", &.{"p"}, null, &.{}, &.{
    get("p"),                                                                                                  op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("p"), .{ .load = .{ .ty = .f64 } }, call("__print_f64_raw") }),
});
const print_opt_f64 = func("__print_opt_f64", &.{"p"}, null, &.{}, &.{ get("p"), call("__print_opt_f64_raw"), call("__print_nl") });

/// A `?T` whose `T` is a record: the value IS the record's pointer, so `0` is
/// absence and anything else carries the header the tagged printer reads four
/// bytes behind it. Without the guard the tagged printer read that header out
/// of the scratch area below address 0.
const print_opt_tagged_raw = func("__print_opt_tagged_raw", &.{"v"}, null, &.{}, &.{
    get("v"),                                                                       op("eqz"),
    whenElse(&.{call("__print_null")}, &.{ get("v"), call("__print_tagged_raw") }),
});
const print_opt_tagged = func("__print_opt_tagged", &.{"v"}, null, &.{}, &.{ get("v"), call("__print_opt_tagged_raw"), call("__print_nl") });

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

/// `@panic(msg)`: `panic: ` and the message, unchanged, and a newline on stderr
/// (decisions 430, 535) — the text the program raised, as on every other target. `msg` is a
/// length-prefixed string.
const panic_fail = func("__panic_fail", &.{"msg"}, null, &.{}, &.{
    // "panic: " — the abort's kind (decision 535), 7 bytes as one i64 word
    c32(188),   .{ .@"const" = .{ .ty = .i64, .text = "9071397899755888" } }, .{ .store = .{ .ty = .i64 } }, c32(188),   c32(7),  call("__write_err"),
    get("msg"), c32(4),                                                       op("add"),                     get("msg"), load(0), call("__write_err"),
    c32(188),   c32(10),                                                      store8(0),                     c32(188),   c32(1),  call("__write_err"),
});

/// Decision 999 — `$__main_fail(msg)`: `failed: ` and the text of the entry
/// `main`'s `Error`, unchanged, and a newline on stderr. `msg` is a
/// length-prefixed string.
const main_fail = func("__main_fail", &.{"msg"}, null, &.{}, &.{
    // "failed: " — 8 bytes as one i64 word
    c32(188),   .{ .@"const" = .{ .ty = .i64, .text = "2322278944636232038" } }, .{ .store = .{ .ty = .i64 } }, c32(188),   c32(8),  call("__write_err"),
    get("msg"), c32(4),                                                          op("add"),                     get("msg"), load(0), call("__write_err"),
    c32(188),   c32(10),                                                         store8(0),                     c32(188),   c32(1),  call("__write_err"),
});

// ── decision 518: aborts as wasm exceptions, and `attempt` ──────────────────
//
// A program reaching a binding that `needs: [.Exceptions]` (std's
// `failure.attempt` / `attemptTask`) raises its aborts as the tag
// `$__bp_panic`, whose one value is a cell `[msg, print]`: `msg` the
// message (a length-prefixed string) and `print` whether the abort writes it
// on stderr when nothing catches it (`@panic` with a message does, as it does
// without exceptions). `_botopink_main` catches what escapes, writes it and
// traps, so an uncaught abort answers what it answered before.

/// The program's exception tag (decision 518).
pub const panic_tag = ast.Tag{ .name = "__bp_panic", .params = &.{.i32} };

/// `$__panic_raise(msg, print)` — the abort's cell, thrown.
const panic_raise = func("__panic_raise", &.{ "msg", "print" }, null, i32s(&.{"c"}), &.{
    c32(8),   call("__alloc"),            set("c"),
    get("c"), get("msg"),                 store(0),
    get("c"), get("print"),               store(4),
    get("c"), .{ .throw = "__bp_panic" },
});

/// `wasi:attempt` — `$__wasi_attempt(f)`: the thunk `f` (a closure cell, its
/// table index at `+0`) called inside a `try_table` catching `$__bp_panic`;
/// a `@Result` pair `[tag, payload]` — `Ok` (0) of the thunk's word, or
/// `Error` (1) of the abort's message.
const wasi_attempt = func("__wasi_attempt", &.{"f"}, .i32, i32s(&.{ "v", "r" }), &.{
    .{ .block = .{ .kind = .block, .label = "caught", .result = .i32, .body = seqOf(&.{
        .{ .block = .{ .kind = .try_table, .result = .i32, .catches = &.{.{ .tag = "__bp_panic", .label = "caught" }}, .body = seqOf(&.{
            get("f"), get("f"), load(0), .{ .call_indirect = .{ .params = &.{.i32}, .result = .i32 } },
        }, .{ .value = .i32 }) } },
        set("v"),
        c32(8),
        call("__alloc"),
        set("r"),
        get("r"),
        c32(0),
        store(0),
        get("r"),
        get("v"),
        store(4),
        get("r"),
        ret,
    }, .terminated) } },
    load(0),
    set("v"),
    c32(8),
    call("__alloc"),
    set("r"),
    get("r"),
    c32(1),
    store(0),
    get("r"),
    get("v"),
    store(4),
    get("r"),
});

// ── decision 392's scheduler (`@Async<T>`, front `01-compiler/140` step 4) ──────
//
// A task is a 40-byte record: `+0` its state (0 pending, 1 settled), `+4` the
// head of what waits on it, `+8` its value (8 bytes: an `i32` word, an `i64`
// or an `f64`), `+16` the frame of the asynchronous function it runs, `+20` the
// function's `kind` (`$__task_resume` dispatches on it; `-1` for a host task or
// a combinator), `+24` its link in the ready queue, `+28` / `+32` a
// combinator's own words (`spawn_all`: the answers' array, the count left).
// What waits on a task is a 16-byte node: `+0` the next node, `+4` its kind
// (0 a suspended task to resume, 1 a `race` to settle, 2 a slot of a
// `spawn_all`), `+8` the task it serves, `+12` the slot.

const task_head_global = ast.Global{ .name = "__task_head", .ty = .i32, .mutable = true, .init = "0" };
const task_tail_global = ast.Global{ .name = "__task_tail", .ty = .i32, .mutable = true, .init = "0" };
/// Set by a state machine's body when it suspended at an `await` instead of
/// answering: its step reads it and leaves the task pending.
const task_suspended_global = ast.Global{ .name = "__task_suspended", .ty = .i32, .mutable = true, .init = "0" };
const task_hosts_global = ast.Global{ .name = "__task_hosts", .ty = .i32, .mutable = true, .init = "0" };

fn gget(comptime n: []const u8) Instr {
    return .{ .global_get = n };
}
fn gset(comptime n: []const u8) Instr {
    return .{ .global_set = n };
}
const load64: Instr = .{ .load = .{ .ty = .i64, .offset = 8 } };
const store64: Instr = .{ .store = .{ .ty = .i64, .offset = 8 } };

/// A pending task of `kind` over `frame`.
const task_new = func("__task_new", &.{ "kind", "frame" }, .i32, i32s(&.{"t"}), &.{
    c32(40),  call("__alloc"), set("t"),
    get("t"), get("kind"),     store(20),
    get("t"), get("frame"),    store(16),
    get("t"),
});

/// A task made and run to its first `await` — a task starts when it is made
/// (decision 392 (1)).
const task_start = func("__task_start", &.{ "kind", "frame" }, .i32, i32s(&.{"t"}), &.{
    get("kind"), get("frame"), call("__task_new"), tee("t"), call("__task_resume"), get("t"),
});

const task_pending = func("__task_pending", &.{"t"}, .i32, &.{}, &.{ get("t"), load(0), op("eqz") });

/// `target` waits on `t` as a node of `kind` (slot `index`).
const task_listen = func("__task_listen", &.{ "t", "kind", "target", "index" }, null, i32s(&.{"n"}), &.{
    c32(16),   call("__alloc"), set("n"),
    get("n"),  get("t"),        load(4),
    store(0),  get("n"),        get("kind"),
    store(4),  get("n"),        get("target"),
    store(8),  get("n"),        get("index"),
    store(12), get("t"),        get("n"),
    store(4),
});

/// The suspended task `w` resumes when `t` settles.
const task_wait = func("__task_wait", &.{ "t", "w" }, null, &.{}, &.{
    get("t"), c32(0), get("w"), c32(0), call("__task_listen"),
});

const task_settle_i32 = func("__task_settle_i32", &.{ "t", "v" }, null, &.{}, &.{
    get("t"), get("v"), store(8), get("t"), call("__task_wake"),
});
const task_settle_i64 = typedFunc("__task_settle_i64", &.{ p32("t"), p64("v") }, null, &.{}, &.{
    get("t"), get("v"), store64, get("t"), call("__task_wake"),
});
const task_settle_f64 = typedFunc("__task_settle_f64", &.{ p32("t"), .{ .name = "v", .ty = .f64 } }, null, &.{}, &.{
    get("t"), get("v"), .{ .store = .{ .ty = .f64, .offset = 8 } }, get("t"), call("__task_wake"),
});

/// `t` settles — once: a settled task is never settled again (the losers of
/// a `race`). What waits on it, in the order it began waiting: a suspended
/// task joins the ready queue, a `race` settles with this value, a
/// `spawn_all` slot takes it and the combinator settles with the array when
/// its last slot is filled.
const task_wake = func("__task_wake", &.{"t"}, null, i32s(&.{ "n", "m", "r", "k", "w" }), &.{
    get("t"), load(0), when(&.{ret}),
    get("t"), c32(1),  store(0),
    get("t"), load(4), set("n"),
    get("t"), c32(0),  store(4),
    loop(&.{
        get("n"), op("eqz"), brk,
        get("n"), load(0),   set("m"),
        get("n"), get("r"),  store(0),
        get("n"), set("r"),  get("m"),
        set("n"), again,
    }),
    loop(&.{
        get("r"), op("eqz"), brk,
        get("r"), load(4),   set("k"),
        get("r"), load(8),   set("w"),
        get("k"), op("eqz"), when(&.{ get("w"), call("__task_enqueue") }),
        get("k"), c32(1),    op("eq"),
        when(&.{
            get("w"),                                                                       load(0), op("eqz"),
            when(&.{ get("w"), get("t"), load64, store64, get("w"), call("__task_wake") }),
        }),
        get("k"), c32(2),    op("eq"),
        when(&.{
            get("w"), load(28), c32(4),    op("add"),                                                                         get("r"), load(12), c32(4), op("mul"), op("add"),
            get("t"), load(8),  store(0),  get("w"),                                                                          get("w"), load(32), c32(1), op("sub"), store(32),
            get("w"), load(32), op("eqz"), when(&.{ get("w"), get("w"), load(28), store(8), get("w"), call("__task_wake") }),
        }),
        get("r"), load(0),   set("r"),
        again,
    }),
});

const task_enqueue = func("__task_enqueue", &.{"t"}, null, &.{}, &.{
    get("t"),            c32(0),                                                                                        store(24),
    gget("__task_tail"), whenElse(&.{ gget("__task_tail"), get("t"), store(24) }, &.{ get("t"), gset("__task_head") }), get("t"),
    gset("__task_tail"),
});

/// Resume the ready tasks until none is left.
const task_drain = func("__task_drain", &.{}, null, i32s(&.{"t"}), &.{
    loop(&.{
        gget("__task_head"), tee("t"),                                op("eqz"),           brk,
        get("t"),            load(24),                                gset("__task_head"), gget("__task_head"),
        op("eqz"),           when(&.{ c32(0), gset("__task_tail") }), get("t"),            call("__task_resume"),
        again,
    }),
});

/// `await t` where no state machine can suspend (a `@Component` body runs in
/// place): the ready tasks run until `t` settles. A task still waiting on the
/// host then traps — on both hosts alike: the `browser` host cannot wait in
/// place, so neither does `wasi` (decision 394's parity) — rather than answer
/// a value it does not have.
const task_block_on = func("__task_block_on", &.{"t"}, .i32, i32s(&.{"r"}), &.{
    loop(&.{
        get("t"),                                load(0),             brk,
        gget("__task_head"),                     tee("r"),            op("eqz"),
        when(&.{.@"unreachable"}),               get("r"),            load(24),
        gset("__task_head"),                     gget("__task_head"), op("eqz"),
        when(&.{ c32(0), gset("__task_tail") }), get("r"),            call("__task_resume"),
        again,
    }),
    get("t"),
});

/// What `_start` runs after `main`: the ready tasks, and the host's answers as
/// they come, until nothing is left to run or to wait on here.
const task_finish = func("__task_finish", &.{}, null, &.{}, &.{
    loop(&.{ call("__task_drain"), call("__task_host_poll"), op("eqz"), brk, again }),
});

/// The prelude's dispatch: no state machine — `wat.zig` substitutes the
/// module's (`Emitter.taskResumeFunc`).
const task_resume = func("__task_resume", &.{"t"}, null, &.{}, &.{.@"unreachable"});

/// The prelude's host poll: nothing to wait on here. The `browser` host waits
/// in its loader, which calls `__bp_ready` as the event loop answers.
const task_host_poll = func("__task_host_poll", &.{}, .i32, &.{}, &.{c32(0)});

/// A host task's pollable joins the pending list.
const task_host_add = func("__task_host_add", &.{ "h", "t" }, null, i32s(&.{"n"}), &.{
    c32(12),  call("__alloc"),      set("n"),
    get("n"), gget("__task_hosts"), store(0),
    get("n"), get("h"),             store(4),
    get("n"), get("t"),             store(8),
    get("n"), gset("__task_hosts"),
});

/// The host answered pollable `h`: its task leaves the pending list and
/// settles. `1` when `h` was pending.
const task_host_settle = func("__task_host_settle", &.{"h"}, .i32, i32s(&.{ "p", "n" }), &.{
    gget("__task_hosts"), set("n"),
    loop(&.{
        get("n"), op("eqz"), brk,
        get("n"), load(4),   get("h"),
        op("eq"),
        when(&.{
            get("p"),
            whenElse(&.{ get("p"), get("n"), load(0), store(0) }, &.{ get("n"), load(0), gset("__task_hosts") }),
            get("n"),
            load(8),
            call("__task_wake"),
            c32(1),
            ret,
        }),
        get("n"), set("p"),  get("n"),
        load(0),  set("n"),  again,
    }),
    c32(0),
});

/// The `wasi` host's poll (`wasi:io/poll`'s `poll` through the component's
/// adapter, `bp_host.wait`): every pending pollable in one list, the ready
/// ones settled and dropped. `0` when nothing is pending.
pub const task_host_poll_wasi = func("__task_host_poll", &.{}, .i32, i32s(&.{ "n", "buf", "out", "k", "i", "node", "h" }), &.{
    gget("__task_hosts"),                                                                                                     set("node"),
    loop(&.{ get("node"), op("eqz"), brk, get("n"), c32(1), op("add"), set("n"), get("node"), load(0), set("node"), again }), get("n"),
    op("eqz"),                                                                                                                when(&.{ c32(0), ret }),
    get("n"),                                                                                                                 c32(4),
    op("mul"),                                                                                                                call("__alloc"),
    set("buf"),                                                                                                               get("n"),
    c32(4),                                                                                                                   op("mul"),
    call("__alloc"),                                                                                                          set("out"),
    gget("__task_hosts"),                                                                                                     set("node"),
    loop(&.{
        get("node"), op("eqz"), brk,
        get("buf"),  get("i"),  c32(4),
        op("mul"),   op("add"), get("node"),
        load(4),     store(0),  get("i"),
        c32(1),      op("add"), set("i"),
        get("node"), load(0),   set("node"),
        again,
    }),
    get("buf"),                                                                                                               get("n"),
    get("out"),                                                                                                               call("bp_host_wait"),
    set("k"),                                                                                                                 c32(0),
    set("i"),
    loop(&.{
        get("i"),             get("k"),                   op("ge_u"), brk,
        get("buf"),           get("out"),                 get("i"),   c32(4),
        op("mul"),            op("add"),                  load(0),    c32(4),
        op("mul"),            op("add"),                  load(0),    set("h"),
        get("h"),             call("__task_host_settle"), .drop,      get("h"),
        call("bp_host_drop"), get("i"),                   c32(1),     op("add"),
        set("i"),             again,
    }),
    c32(1),
});

/// `wasi:delay` — a task holding `v`, settled when the host's pollable for
/// `ms` milliseconds is ready (`bp_host.delay`: `wasi:clocks/monotonic-clock`'s
/// `subscribe-duration` on `wasi`, `setTimeout` on `browser`). A negative
/// duration is `0`.
const task_delay = func("__task_delay", &.{ "ms", "v" }, .i32, i32s(&.{"t"}), &.{
    get("ms"),             c32(0),   op("lt_s"),              when(&.{ c32(0), set("ms") }),
    c32(-1),               c32(0),   call("__task_new"),      set("t"),
    get("t"),              get("v"), store(8),                get("ms"),
    call("bp_host_delay"), get("t"), call("__task_host_add"), get("t"),
});

/// `wasi:race` — the first of `xs` to settle: one settled already, the first
/// in input order; else the task waits on all of them. An empty list traps.
const task_race = func("__task_race", &.{"xs"}, .i32, i32s(&.{ "n", "i", "t", "r" }), &([_]Instr{
    get("xs"), load(0),   set("n"),
    get("n"),  op("eqz"), when(&.{.@"unreachable"}),
    c32(-1),   c32(0),    call("__task_new"),
    set("r"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("xs", "i") ++ [_]Instr{
        load(0),                                                                                       set("t"),
        get("t"),                                                                                      load(0),
        when(&.{ get("r"), get("t"), load64, store64, get("r"), call("__task_wake"), get("r"), ret }), get("i"),
        c32(1),                                                                                        op("add"),
        set("i"),                                                                                      again,
    })),
    c32(0),    set("i"),
} ++ [_]Instr{
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("xs", "i") ++ [_]Instr{
        load(0),  c32(1), get("r"),  c32(0),   call("__task_listen"),
        get("i"), c32(1), op("add"), set("i"), again,
    })),
    get("r"),
}));

/// `wasi:race_of` — every thunk of `fs` called in order (each task starts and
/// runs to its first `await`), then raced.
const task_race_of = func("__task_race_of", &.{"fs"}, .i32, i32s(&.{ "n", "i", "xs", "f" }), &([_]Instr{
    get("fs"), load(0),             set("n"),
    get("n"),  call("__arr_new"),   set("xs"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("fs", "i") ++ [_]Instr{ load(0), set("f") } ++ slot("xs", "i") ++ [_]Instr{
        get("f"),                                                      get("f"),  load(0),
        .{ .call_indirect = .{ .params = &.{.i32}, .result = .i32 } }, store(0),  get("i"),
        c32(1),                                                        op("add"), set("i"),
        again,
    })),
    get("xs"), call("__task_race"),
}));

/// `wasi:spawn_all` — every thunk of `fs` called in order; the task settles
/// with their answers in input order once the last of them has settled.
const task_spawn_all = func("__task_spawn_all", &.{"fs"}, .i32, i32s(&.{ "n", "i", "out", "f", "t", "r" }), &([_]Instr{
    get("fs"), load(0),           set("n"),
    get("n"),  call("__arr_new"), set("out"),
    c32(-1),   c32(0),            call("__task_new"),
    set("r"),  get("r"),          get("out"),
    store(28), get("r"),          get("n"),
    store(32),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("fs", "i") ++ [_]Instr{
        load(0),   set("f"),
        get("f"),  get("f"),
        load(0),   .{ .call_indirect = .{ .params = &.{.i32}, .result = .i32 } },
        set("t"),  get("t"),
        load(0),
        whenElse(&([_]Instr{} ++ slot("out", "i") ++ [_]Instr{
            get("t"), load(8),   store(0),
            get("r"), get("r"),  load(32),
            c32(1),   op("sub"), store(32),
        }), &.{ get("t"), c32(2), get("r"), get("i"), call("__task_listen") }),
        get("i"),  c32(1),
        op("add"), set("i"),
        again,
    })),
} ++ [_]Instr{
    get("r"),                                                                  load(32), op("eqz"),
    when(&.{ get("r"), get("out"), store(8), get("r"), call("__task_wake") }), get("r"),
}));

/// `wasi:gate_new` — a closed gate (decision 334, std's `async` gates): a
/// pending task no host answers and no state machine runs; `gate_open`
/// settles it with `1`.
const task_gate_new = func("__task_gate_new", &.{}, .i32, &.{}, &.{ c32(-1), c32(0), call("__task_new") });

/// `wasi:gate_open` — gate `g` opens: before it settles, the timer of each
/// wait still pending on it (`gate_await`'s task, its `+28` word) is dropped,
/// so an open gate leaves no timer behind; then every wait answers `1`.
/// Opening an open gate changes nothing.
const task_gate_open = func("__task_gate_open", &.{"g"}, null, i32s(&.{ "n", "r" }), &.{
    get("g"), load(0), when(&.{ret}),
    get("g"), load(4), set("n"),
    loop(&.{
        get("n"), op("eqz"), brk,
        get("n"), load(8),   set("r"),
        get("n"), load(4),   c32(1),
        op("eq"),
        when(&.{
            get("r"),                                                                                   load(0), op("eqz"),
            when(&.{ get("r"), load(28), when(&.{ get("r"), load(28), call("__task_host_cancel") }) }),
        }),
        get("n"), load(0),   set("n"),
        again,
    }),
    get("g"), c32(1),  call("__task_settle_i32"),
});

/// `wasi:cell_new` — a `use memo` slot (decision 771, std's `hooks`): a heap
/// cell `[filled, value]`, empty. A GC module has its own form (`gc_memo_cell_*`).
const memo_cell_new = func("__memo_cell_new", &.{}, .i32, i32s(&.{"p"}), &.{
    c32(8),   call("__alloc"), set("p"),
    get("p"), c32(0),          store(0),
    get("p"), c32(0),          store(4),
    get("p"),
});

/// `wasi:cell_filled` — whether cell `c` holds a value.
const memo_cell_filled = func("__memo_cell_filled", &.{"c"}, .i32, &.{}, &.{ get("c"), load(0) });

/// `wasi:cell_get` — the word cell `c` holds.
const memo_cell_get = func("__memo_cell_get", &.{"c"}, .i32, &.{}, &.{ get("c"), load(4) });

/// `wasi:cell_set` — cell `c` holds `v`.
const memo_cell_set = func("__memo_cell_set", &.{ "c", "v" }, null, &.{}, &.{
    get("c"), get("v"), store(4),
    get("c"), c32(1),   store(0),
});

/// `wasi:gate_await` — a task answering `1` when gate `g` opens (at once
/// when it is open), `0` when `ms` milliseconds pass first: it races the gate
/// and a `delay` of `0`, and keeps that delay in its `+28` word for
/// `gate_open` to drop.
const task_gate_await = func("__task_gate_await", &.{ "g", "ms" }, .i32, i32s(&.{ "r", "d" }), &.{
    c32(-1),  c32(0),               call("__task_new"),                                                     set("r"),
    get("g"), load(0),              when(&.{ get("r"), c32(1), call("__task_settle_i32"), get("r"), ret }), get("ms"),
    c32(0),   call("__task_delay"), set("d"),                                                               get("r"),
    get("d"), store(28),            get("g"),                                                               c32(1),
    get("r"), c32(0),               call("__task_listen"),                                                  get("d"),
    c32(1),   get("r"),             c32(0),                                                                 call("__task_listen"),
    get("r"),
});

/// Host task `t`'s pollable leaves the pending list and is dropped
/// (`bp_host.drop`: the pollable's drop on `wasi`, `clearTimeout` on
/// `browser`); `t` stays pending, and nothing waits on it but a settled race.
const task_host_cancel = func("__task_host_cancel", &.{"t"}, null, i32s(&.{ "p", "n" }), &.{
    gget("__task_hosts"), set("n"),
    loop(&.{
        get("n"), op("eqz"), brk,
        get("n"), load(8),   get("t"),
        op("eq"),
        when(&.{
            get("p"),
            whenElse(&.{ get("p"), get("n"), load(0), store(0) }, &.{ get("n"), load(0), gset("__task_hosts") }),
            get("n"),
            load(4),
            call("bp_host_drop"),
            ret,
        }),
        get("n"), set("p"),  get("n"),
        load(0),  set("n"),  again,
    }),
});

/// The host functions decision 393's adapters reach (`wat_emitter`'s
/// component adapter on `wasi`, the loader's JavaScript on `browser`).
pub const bp_host_delay_import = ast.Import{ .module = "bp_host", .name = "delay", .func = "bp_host_delay", .type = .{ .params = &.{.i32}, .result = .i32 } };
pub const bp_host_wait_import = ast.Import{ .module = "bp_host", .name = "wait", .func = "bp_host_wait", .type = .{ .params = &.{ .i32, .i32, .i32 }, .result = .i32 } };
pub const bp_host_drop_import = ast.Import{ .module = "bp_host", .name = "drop", .func = "bp_host_drop", .type = .{ .params = &.{.i32} } };

/// Decision 992 — the file system's host functions, the module `bp_fs` the `wasi` component
/// answers over `wasi:filesystem` (`wat_emitter.zig`, § the file system's adapter). Every path is
/// `(pointer, length)` in the program's memory, relative to the root the host preopens, no leading
/// `/`; every answer is an `i32`, a count or a handle when it is not negative and `-(1 + code)`
/// of `wasi:filesystem`'s `error-code` (its ordinal) when it is; `-100` is the end of a directory
/// and an absent variable or working directory. `read` / `write` take the file offset; `stat`'s `out` is
/// `[type: i32][pad: i32][size: i64][mtime in seconds: i64]`; a directory entry is
/// `[type: i32][name]` at `ptr`, its length the answer.
pub const fs_imports = [_]ast.Import{
    .{ .module = "bp_fs", .name = "open", .func = "__fs_open", .type = .{ .params = &.{ .i32, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "close", .func = "__fs_close", .type = .{ .params = &.{.i32} } },
    .{ .module = "bp_fs", .name = "read", .func = "__fs_read", .type = .{ .params = &.{ .i32, .i64, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "write", .func = "__fs_write", .type = .{ .params = &.{ .i32, .i64, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "stat", .func = "__fs_stat", .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "stat_at", .func = "__fs_stat_at", .type = .{ .params = &.{ .i32, .i32, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "readdir_open", .func = "__fs_readdir_open", .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "readdir_next", .func = "__fs_readdir_next", .type = .{ .params = &.{ .i32, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "readdir_close", .func = "__fs_readdir_close", .type = .{ .params = &.{.i32} } },
    .{ .module = "bp_fs", .name = "mkdir", .func = "__fs_mkdir", .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "rmdir", .func = "__fs_rmdir", .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "unlink", .func = "__fs_unlink", .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "symlink", .func = "__fs_symlink", .type = .{ .params = &.{ .i32, .i32, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "getenv", .func = "__fs_getenv", .type = .{ .params = &.{ .i32, .i32, .i32, .i32 }, .result = .i32 } },
    .{ .module = "bp_fs", .name = "cwd", .func = "__fs_cwd", .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 } },
};

/// The `browser` host's loader calls this export when the event loop answers
/// host task `h` (decision 394): the task settles and the ready tasks run.
pub const bp_ready = ast.Func{
    .name = "__bp_ready",
    .exports = &.{"__bp_ready"},
    .params = &.{.{ .name = "h", .ty = .i32 }},
    .body = indented(seqOf(&.{ get("h"), call("__task_host_settle"), .drop, call("__task_drain") }, .none), 4),
};

// ── WasmGC forms (front 164 s2, decision 544) ────────────────────────────────
//
// A module lowered in `.gc` (`../wat.zig`, `wat/repr.zig`) holds its strings as
// GC arrays of bytes — `$str`, `(array (mut i8))`, always the first type of its
// `(rec …)` group — and its output stays the linear-memory I/O above: a string
// is copied into the marshal arena (`$__alloc`'s memory, the pointer put back
// after the write) and written from there. A group whose functions take or
// answer a string has a GC form here (`gcItems`); a group that only moves
// numbers is the same in both modes; a group with neither has no GC form yet,
// and a module needing it is lowered in linear memory.

/// The index of `$str` in a GC module's type group.
pub const gc_str_index: u16 = 0;
/// `(type $str (array (mut i8)))`.
pub const gc_str_def = ast.TypeDef{ .name = "str", .kind = .{ .array = .{ .ty = .i8, .mutable = true } } };
/// `(ref null $str)`.
pub const gc_str_ref = ast.ValType.def(gc_str_index);

fn sref(comptime n: []const u8) ast.Local {
    return .{ .name = n, .ty = gc_str_ref };
}
fn pref(comptime n: []const u8) P {
    return .{ .name = n, .ty = gc_str_ref };
}
const str_len: Instr = .array_len;
const str_get: Instr = .{ .array_get = .{ .ty = gc_str_index, .ext = .u } };
const str_set: Instr = .{ .array_set = gc_str_index };
const str_new: Instr = .{ .array_new_default = gc_str_index };
const str_copy: Instr = .{ .array_copy = .{ .dst = gc_str_index, .src = gc_str_index } };

/// Writes the GC string `s`: its bytes copied into the marshal arena, written,
/// the arena put back. A null `s` traps at `array.len`, as a pointer that is
/// no string traps in linear memory.
const gc_print_str_raw = typedFunc("__print_str_raw", &.{pref("s")}, null, i32s(&.{ "n", "p", "i", "top" }), &.{
    get("s"),                str_len,                 set("n"),
    .{ .global_get = heap }, set("top"),              get("n"),
    call("__alloc"),         set("p"),
    loop(&.{
        get("i"), get("n"),  op("ge_u"), brk,
        get("p"), get("i"),  op("add"),  get("s"),
        get("i"), str_get,   store8(0),  get("i"),
        c32(1),   op("add"), set("i"),   again,
    }),
    get("p"),                get("n"),                call("__write_bytes"),
    get("top"),              .{ .global_set = heap },
});

const gc_print_str = typedFunc("__print_str", &.{pref("s")}, null, &.{}, &.{ get("s"), call("__print_str_raw"), call("__print_nl") });

/// A float's text (std-wasm's `number.floatToString`, into the marshal
/// arena), written, the arena put back.
const gc_print_f64_raw = typedFunc("__print_f64_raw", &.{.{ .name = "x", .ty = .f64 }}, null, i32s(&.{ "s", "top" }), &.{
    .{ .global_get = heap }, set("top"),
    getF("x"),               call(stdSymbol("number.floatToString")),
    set("s"),                get("s"),
    c32(4),                  op("add"),
    get("s"),                load(0),
    call("__write_bytes"),   get("top"),
    .{ .global_set = heap },
});

/// The GC forms of `$__print_i64_raw` / `$__print_u64_raw` (front 164 s3 P2-a):
/// the digits are the `.wat` leaf's `$str` (`number.i64ToString` /
/// `number.u64ToString`), written through `$__print_str_raw`.
const gc_print_i64_raw = typedFunc("__print_i64_raw", &.{p64("v")}, null, &.{}, &.{
    get("v"), call(stdSymbol("number.i64ToString")), call("__print_str_raw"),
});
const gc_print_u64_raw = typedFunc("__print_u64_raw", &.{p64("v")}, null, &.{}, &.{
    get("v"), call(stdSymbol("number.u64ToString")), call("__print_str_raw"),
});

/// `a + b` over GC strings: a fresh array holding both.
const gc_str_concat = typedFunc("__str_concat", &.{ pref("a"), pref("b") }, gc_str_ref, &.{ sref("r"), l32("alen"), l32("blen") }, &.{
    get("a"),    str_len,     set("alen"), get("b"),    str_len,
    set("blen"), get("alen"), get("blen"), op("add"),   str_new,
    set("r"),    get("r"),    c32(0),      get("a"),    c32(0),
    get("alen"), str_copy,    get("r"),    get("alen"), get("b"),
    c32(0),      get("blen"), str_copy,    get("r"),
});

/// `a == b` over GC strings, byte by byte.
const gc_str_eq = typedFunc("__str_eq", &.{ pref("a"), pref("b") }, .i32, i32s(&.{ "i", "n", "an", "bn" }), &.{
    // An absent string (an optional field, `null`) equals only another one.
    get("a"),  .ref_is_null, set("an"), get("b"),                                         .ref_is_null, set("bn"),
    get("an"), get("bn"),    op("or"),  when(&.{ get("an"), get("bn"), op("and"), ret }), get("a"),     str_len,
    set("n"),  get("n"),     get("b"),  str_len,                                          op("ne"),     when(&.{ c32(0), ret }),
    loop(&.{
        get("i"), get("n"), op("ge_u"), brk,
        get("a"), get("i"), str_get,    get("b"),
        get("i"), str_get,  op("ne"),   when(&.{ c32(0), ret }),
        get("i"), c32(1),   op("add"),  set("i"),
        again,
    }),
    c32(1),
});

/// Decision 1021 (10) — `$__str_cmp(a, b)`: the order of two GC strings by
/// their bytes, unsigned, a prefix first: `-1`, `0` or `1`.
const gc_str_cmp = typedFunc("__str_cmp", &.{ pref("a"), pref("b") }, .i32, i32s(&.{ "i", "n", "an", "bn", "x", "y" }), &.{
    get("a"),  str_len,   set("an"), get("b"),  str_len,    set("bn"),
    get("an"), set("n"),  get("bn"), get("an"), op("lt_u"), when(&.{ get("bn"), set("n") }),
    loop(&.{
        get("i"), get("n"), op("ge_u"), brk,
        get("a"), get("i"), str_get,    set("x"),
        get("b"), get("i"), str_get,    set("y"),
        get("x"), get("y"), op("ne"),   when(&.{ c32(1), c32(-1), get("x"), get("y"), op("gt_u"), .select, ret }),
        get("i"), c32(1),   op("add"),  set("i"),
        again,
    }),
    c32(1),    c32(-1),   get("an"), get("bn"), op("gt_u"), .select,
    c32(0),    get("an"), get("bn"), op("ne"),  .select,
});

/// `$__write_bytes` of a GC module with `text_capture`: while `$__cap` holds a
/// string, the bytes `[p, p + n)` are appended to a copy of it; otherwise they
/// go to stdout.
const gc_write_bytes_capture = typedFunc("__write_bytes", &.{ p32("p"), p32("n") }, null, &.{ sref("c"), sref("q"), l32("l"), l32("i") }, &.{
    .{ .global_get = "__cap" }, set("c"),
    get("c"),                   .ref_is_null,
    op("eqz"),
    when(&.{
        get("c"), str_len,                    set("l"), get("l"),
        get("n"), op("add"),                  str_new,  set("q"),
        get("q"), c32(0),                     get("c"), c32(0),
        get("l"), str_copy,
        loop(&.{
            get("i"), get("n"), op("ge_u"), brk,
            get("q"), get("l"), get("i"),   op("add"),
            get("p"), get("i"), op("add"),  load8(0),
            str_set,  get("i"), c32(1),     op("add"),
            set("i"), again,
        }),
        get("q"), .{ .global_set = "__cap" }, ret,
    }),
    c32(0),                     get("p"),
    store(0),                   c32(4),
    get("n"),                   store(0),
    c32(1),                     c32(0),
    c32(1),                     c32(8),
    call("fd_write"),           .drop,
});

/// The GC string `$__write_bytes` appends to while a capture is open, null
/// when none is.
const gc_cap_global = ast.Global{ .name = "__cap", .ty = gc_str_ref, .mutable = true, .init = "" };

const gc_cap_begin = typedFunc("__cap_begin", &.{}, gc_str_ref, &.{sref("o")}, &.{
    .{ .global_get = "__cap" }, set("o"),
    c32(0),                     str_new,
    .{ .global_set = "__cap" }, get("o"),
});

const gc_cap_end = typedFunc("__cap_end", &.{pref("o")}, gc_str_ref, &.{sref("s")}, &.{
    .{ .global_get = "__cap" }, set("s"),
    get("o"),                   .{ .global_set = "__cap" },
    get("s"),
});

/// A GC string as std-wasm reads one: `[len][bytes…]` in the marshal arena.
const gc_to_lin_str = typedFunc("__gc_to_lin_str", &.{pref("s")}, .i32, i32s(&.{ "n", "p", "i" }), &.{
    get("s"),        str_len,  set("n"),
    get("n"),        c32(4),   op("add"),
    call("__alloc"), set("p"), get("p"),
    get("n"),        store(0),
    loop(&.{
        get("i"), get("n"),  op("ge_u"), brk,
        get("p"), get("i"),  op("add"),  get("s"),
        get("i"), str_get,   store8(4),  get("i"),
        c32(1),   op("add"), set("i"),   again,
    }),
    get("p"),
});

/// The string std-wasm answered at `p` (`[len][bytes…]`), as a GC string.
const lin_to_gc_str = typedFunc("__lin_to_gc_str", &.{p32("p")}, gc_str_ref, &.{ sref("r"), l32("n"), l32("i") }, &.{
    get("p"), load(0), set("n"),
    get("n"), str_new, set("r"),
    loop(&.{
        get("i"),  get("n"),  op("ge_u"), brk,
        get("r"),  get("i"),  get("p"),   get("i"),
        op("add"), load8(4),  str_set,    get("i"),
        c32(1),    op("add"), set("i"),   again,
    }),
    get("r"),
});

/// `"text"` — a GC string nested in a container, quoted with the source
/// escapes `\"`, `\\`, `\n`, `\r`, `\t`, as `$__print_quoted_raw` does.
const gc_print_quoted_raw = typedFunc("__print_quoted_raw", &.{pref("s")}, null, &.{ l32("n"), l32("i"), l32("ch"), l32("e") }, &(putByte('"') ++ [_]Instr{call("__write_bytes")} ++ [_]Instr{
    get("s"), str_len, set("n"),
    loop(&([_]Instr{
        get("i"), get("n"),                        op("ge_u"), brk,
        get("s"), get("i"),                        str_get,    set("ch"),
        c32(0),   set("e"),                        get("ch"),  c32('"'),
        op("eq"), get("ch"),                       c32('\\'),  op("eq"),
        op("or"), when(&.{ get("ch"), set("e") }), get("ch"),  c32('\n'),
        op("eq"), when(&.{ c32('n'), set("e") }),  get("ch"),  c32('\r'),
        op("eq"), when(&.{ c32('r'), set("e") }),  get("ch"),  c32('\t'),
        op("eq"), when(&.{ c32('t'), set("e") }),  get("e"),   whenElse(&(putByte('\\') ++ [_]Instr{call("__write_bytes")} ++ putLocalByte("e")), &putLocalByte("ch")),
        get("i"), c32(1),                          op("add"),  set("i"),
        again,
    })),
} ++ putByte('"') ++ [_]Instr{call("__write_bytes")}));

/// `@panic(msg)` over a GC string: `panic: `, the message and a newline on stderr.
const gc_panic_fail = typedFunc("__panic_fail", &.{pref("msg")}, null, i32s(&.{ "n", "p", "i", "top" }), &.{
    // "panic: " — the abort's kind (decision 535), 7 bytes as one i64 word
    c32(188),        .{ .@"const" = .{ .ty = .i64, .text = "9071397899755888" } }, .{ .store = .{ .ty = .i64 } }, c32(188),                c32(7),                  call("__write_err"),
    get("msg"),      str_len,                                                      set("n"),                      .{ .global_get = heap }, set("top"),              get("n"),
    call("__alloc"), set("p"),
    loop(&.{
        get("i"), get("n"),  op("ge_u"), brk,
        get("p"), get("i"),  op("add"),  get("msg"),
        get("i"), str_get,   store8(0),  get("i"),
        c32(1),   op("add"), set("i"),   again,
    }),
    get("p"),        get("n"),                                                     call("__write_err"),           c32(188),                c32(10),                 store8(0),
    c32(188),        c32(1),                                                       call("__write_err"),           get("top"),              .{ .global_set = heap },
});

/// Decision 999 — `$__main_fail(msg)` over a GC string.
const gc_main_fail = typedFunc("__main_fail", &.{pref("msg")}, null, i32s(&.{ "n", "p", "i", "top" }), &.{
    // "failed: " — 8 bytes as one i64 word
    c32(188),        .{ .@"const" = .{ .ty = .i64, .text = "2322278944636232038" } }, .{ .store = .{ .ty = .i64 } }, c32(188),                c32(8),                  call("__write_err"),
    get("msg"),      str_len,                                                         set("n"),                      .{ .global_get = heap }, set("top"),              get("n"),
    call("__alloc"), set("p"),
    loop(&.{
        get("i"), get("n"),  op("ge_u"), brk,
        get("p"), get("i"),  op("add"),  get("msg"),
        get("i"), str_get,   store8(0),  get("i"),
        c32(1),   op("add"), set("i"),   again,
    }),
    get("p"),        get("n"),                                                        call("__write_err"),           c32(188),                c32(10),                 store8(0),
    c32(188),        c32(1),                                                          call("__write_err"),           get("top"),              .{ .global_set = heap },
});

// ── decision 392's scheduler in a GC module (front 164 s2 P4) ────────────────
//
// The same scheduler as the linear one above, over GC structs. Its types are
// the module's own and their indices are known only once the module is
// lowered, so these forms name them by a slot (`GcSlot`): an index at
// `gc_slot_base` + the slot, which `wat.zig` replaces by the module's index of
// the type (`gcRemapFunc`) when it writes the group into the module.
//
//   $task   (struct (mut i32) state  — 0 pending, 1 settled
//                   (mut (ref null $waiter)) waiters
//                   (mut anyref) value  — a scalar in its box, a reference as it is
//                   (mut structref) frame  — the state machine's `$frame<n>`
//                   i32 kind  — `$__task_resume` dispatches on it; -1 for a host
//                             task or a combinator
//                   (mut (ref null $task)) next  — its link in the ready queue
//                   (mut anyref) aux  — `spawn_all`'s answers, `gate_await`'s delay
//                   (mut i32) left)  — `spawn_all`'s count left
//   $waiter (struct (mut (ref null $waiter)) next, i32 kind  — 0 a suspended
//                   task to resume, 1 a `race` to settle, 2 a `spawn_all` slot,
//                   (ref null $task) target, i32 slot)
//   $hostn  (struct (mut (ref null $hostn)) next, i32 pollable, (ref null $task) task)
//   $exn    (struct (ref null $str) msg, i32 print)  — an abort's payload (518)
//
// A task settles once: its value is shared, never copied (a reference, or a
// box nothing writes). A settled task drops what it held — its waiters and
// its frame — so it is no cycle the host's collector must follow (decision
// 544, question 544-a): a task waiting on another holds it from its frame,
// the other holds it back as a waiter until it settles.

/// The types the GC forms name by slot.
pub const GcSlot = enum(u16) { task, waiter, hostn, closure, arr_any, box_i32, result, exn, cell, sig0 };
/// The first slot index: far above any index a module's group reaches.
pub const gc_slot_base: u16 = 0xF000;

fn gs(comptime s: GcSlot) u16 {
    return gc_slot_base + @intFromEnum(s);
}
fn gref(comptime s: GcSlot) ast.ValType {
    return ast.ValType.def(gs(s));
}
fn sget(comptime s: GcSlot, comptime f: u32) Instr {
    return .{ .struct_get = .{ .ty = gs(s), .field = f } };
}
fn sset(comptime s: GcSlot, comptime f: u32) Instr {
    return .{ .struct_set = .{ .ty = gs(s), .field = f } };
}
fn snew(comptime s: GcSlot) Instr {
    return .{ .struct_new = gs(s) };
}
fn rnull(comptime s: GcSlot) Instr {
    return .{ .ref_null = gref(s) };
}
fn rcast(comptime s: GcSlot) Instr {
    return .{ .ref_cast = gref(s) };
}
fn lref(comptime n: []const u8, comptime s: GcSlot) ast.Local {
    return .{ .name = n, .ty = gref(s) };
}
fn pslot(comptime n: []const u8, comptime s: GcSlot) P {
    return .{ .name = n, .ty = gref(s) };
}
const null_any: Instr = .{ .ref_null = .anyref };
const null_struct: Instr = .{ .ref_null = .structref };
const is_null: Instr = .ref_is_null;
/// `br_if $brk` when the reference on the stack is null.
const brk_null = [_]Instr{ is_null, brk };
/// `(struct.new $box_i32 (i32.const n))`.
fn boxed(comptime n: comptime_int) [2]Instr {
    return .{ c32(n), snew(.box_i32) };
}

/// The fields of `$task`.
const tk = struct {
    const state = 0;
    const waiters = 1;
    const value = 2;
    const frame = 3;
    const kind = 4;
    const next = 5;
    const aux = 6;
    const left = 7;
};
/// The fields of `$waiter`.
const wt = struct {
    const next = 0;
    const kind = 1;
    const target = 2;
    const slot = 3;
};
/// The fields of `$hostn`.
const hn = struct {
    const next = 0;
    const h = 1;
    const t = 2;
};

/// The ready queue and the host tasks pending, as references.
pub const gc_task_head_global = ast.Global{ .name = "__task_head", .ty = gref(.task), .mutable = true, .init = "" };
pub const gc_task_tail_global = ast.Global{ .name = "__task_tail", .ty = gref(.task), .mutable = true, .init = "" };
pub const gc_task_hosts_global = ast.Global{ .name = "__task_hosts", .ty = gref(.hostn), .mutable = true, .init = "" };

/// A pending task of `kind` over `frame`.
const gc_task_new = typedFunc("__task_new", &.{ p32("kind"), .{ .name = "frame", .ty = .structref } }, gref(.task), &.{}, &.{
    c32(0),      rnull(.waiter), null_any, get("frame"), get("kind"), rnull(.task), null_any, c32(0),
    snew(.task),
});

/// A task made and run to its first `await` (decision 392 (1)).
const gc_task_start = typedFunc("__task_start", &.{ p32("kind"), .{ .name = "frame", .ty = .structref } }, gref(.task), &.{lref("t", .task)}, &.{
    get("kind"), get("frame"), call("__task_new"), tee("t"), call("__task_resume"), get("t"),
});

const gc_task_pending = typedFunc("__task_pending", &.{pslot("t", .task)}, .i32, &.{}, &.{ get("t"), sget(.task, tk.state), op("eqz") });

/// `target` waits on `t` as a waiter of `kind` (slot `index`).
const gc_task_listen = typedFunc("__task_listen", &.{ pslot("t", .task), p32("kind"), pslot("target", .task), p32("index") }, null, &.{lref("n", .waiter)}, &.{
    get("t"), sget(.task, tk.waiters), get("kind"),             get("target"), get("index"), snew(.waiter), set("n"),
    get("t"), get("n"),                sset(.task, tk.waiters),
});

/// The suspended task `w` resumes when `t` settles.
const gc_task_wait = typedFunc("__task_wait", &.{ pslot("t", .task), pslot("w", .task) }, null, &.{}, &.{
    get("t"), c32(0), get("w"), c32(0), call("__task_listen"),
});

/// `t` settles with `v`.
const gc_task_settle = typedFunc("__task_settle", &.{ pslot("t", .task), .{ .name = "v", .ty = .anyref } }, null, &.{}, &.{
    get("t"), get("v"), sset(.task, tk.value), get("t"), call("__task_wake"),
});

/// `t` settles — once. It drops its waiters and its frame (cycle hygiene),
/// then what waited on it, in the order it began waiting: a suspended task
/// joins the ready queue, a `race` settles with this value, a `spawn_all`
/// slot takes it and the combinator settles with its answers when the last
/// slot is filled.
const gc_task_wake = typedFunc("__task_wake", &.{pslot("t", .task)}, null, &.{ lref("n", .waiter), lref("m", .waiter), lref("r", .waiter), l32("k"), lref("w", .task) }, &.{
    get("t"), sget(.task, tk.state),   when(&.{ret}),
    get("t"), c32(1),                  sset(.task, tk.state),
    get("t"), sget(.task, tk.waiters), set("n"),
    get("t"), rnull(.waiter),          sset(.task, tk.waiters),
    get("t"), null_struct,             sset(.task, tk.frame),
    loop(&.{
        get("n"), is_null,                brk,
        get("n"), sget(.waiter, wt.next), set("m"),
        get("n"), get("r"),               sset(.waiter, wt.next),
        get("n"), set("r"),               get("m"),
        set("n"), again,
    }),
    loop(&.{
        get("r"), is_null,                  brk,
        get("r"), sget(.waiter, wt.kind),   set("k"),
        get("r"), sget(.waiter, wt.target), set("w"),
        get("k"), op("eqz"),                when(&.{ get("w"), call("__task_enqueue") }),
        get("k"), c32(1),                   op("eq"),
        when(&.{
            get("w"),                                                                                                    sget(.task, tk.state), op("eqz"),
            when(&.{ get("w"), get("t"), sget(.task, tk.value), sset(.task, tk.value), get("w"), call("__task_wake") }),
        }),
        get("k"), c32(2),                   op("eq"),
        when(&.{
            get("w"),             sget(.task, tk.aux),   rcast(.arr_any),                                                                                                                                    get("r"),             sget(.waiter, wt.slot),
            get("t"),             sget(.task, tk.value), .{ .array_set = gs(.arr_any) },                                                                                                                     get("w"),             get("w"),
            sget(.task, tk.left), c32(1),                op("sub"),                                                                                                                                          sset(.task, tk.left), get("w"),
            sget(.task, tk.left), op("eqz"),             when(&.{ get("w"), get("w"), sget(.task, tk.aux), sset(.task, tk.value), get("w"), null_any, sset(.task, tk.aux), get("w"), call("__task_wake") }),
        }),
        get("r"), sget(.waiter, wt.next),   set("r"),
        again,
    }),
});

const gc_task_enqueue = typedFunc("__task_enqueue", &.{pslot("t", .task)}, null, &.{}, &.{
    get("t"),            rnull(.task),        sset(.task, tk.next),
    gget("__task_tail"), is_null,             whenElse(&.{ get("t"), gset("__task_head") }, &.{ gget("__task_tail"), get("t"), sset(.task, tk.next) }),
    get("t"),            gset("__task_tail"),
});

/// Resume the ready tasks until none is left.
const gc_task_drain = typedFunc("__task_drain", &.{}, null, &.{lref("t", .task)}, &.{
    loop(&.{
        gget("__task_head"), tee("t"),                                      is_null,             brk,
        get("t"),            sget(.task, tk.next),                          gset("__task_head"), gget("__task_head"),
        is_null,             when(&.{ rnull(.task), gset("__task_tail") }), get("t"),            call("__task_resume"),
        again,
    }),
});

/// `await t` where no state machine can suspend: the ready tasks run until
/// `t` settles; a task still waiting on the host traps (decision 394's parity).
const gc_task_block_on = typedFunc("__task_block_on", &.{pslot("t", .task)}, gref(.task), &.{lref("r", .task)}, &.{
    loop(&.{
        get("t"),                                      sget(.task, tk.state), brk,
        gget("__task_head"),                           tee("r"),              is_null,
        when(&.{.@"unreachable"}),                     get("r"),              sget(.task, tk.next),
        gset("__task_head"),                           gget("__task_head"),   is_null,
        when(&.{ rnull(.task), gset("__task_tail") }), get("r"),              call("__task_resume"),
        again,
    }),
    get("t"),
});

/// A host task's pollable joins the pending list.
const gc_task_host_add = typedFunc("__task_host_add", &.{ p32("h"), pslot("t", .task) }, null, &.{}, &.{
    gget("__task_hosts"), get("h"), get("t"), snew(.hostn), gset("__task_hosts"),
});

/// The host answered pollable `h`: its task leaves the pending list and
/// settles. `1` when `h` was pending.
const gc_task_host_settle = typedFunc("__task_host_settle", &.{p32("h")}, .i32, &.{ lref("p", .hostn), lref("n", .hostn) }, &.{
    gget("__task_hosts"), set("n"),
    loop(&.{
        get("n"),              is_null,            brk,
        get("n"),              sget(.hostn, hn.h), get("h"),
        op("eq"),
        when(&.{
            get("p"),                                                                                                                                      is_null,
            whenElse(&.{ get("n"), sget(.hostn, hn.next), gset("__task_hosts") }, &.{ get("p"), get("n"), sget(.hostn, hn.next), sset(.hostn, hn.next) }), get("n"),
            sget(.hostn, hn.t),                                                                                                                            call("__task_wake"),
            c32(1),                                                                                                                                        ret,
        }),
        get("n"),              set("p"),           get("n"),
        sget(.hostn, hn.next), set("n"),           again,
    }),
    c32(0),
});

/// Host task `t`'s pollable leaves the pending list and is dropped; `t`
/// stays pending.
const gc_task_host_cancel = typedFunc("__task_host_cancel", &.{pslot("t", .task)}, null, &.{ lref("p", .hostn), lref("n", .hostn) }, &.{
    gget("__task_hosts"), set("n"),
    loop(&.{
        get("n"),              is_null,            brk,
        get("n"),              sget(.hostn, hn.t), get("t"),
        .ref_eq,
        when(&.{
            get("p"),                                                                                                                                      is_null,
            whenElse(&.{ get("n"), sget(.hostn, hn.next), gset("__task_hosts") }, &.{ get("p"), get("n"), sget(.hostn, hn.next), sset(.hostn, hn.next) }), get("n"),
            sget(.hostn, hn.h),                                                                                                                            call("bp_host_drop"),
            ret,
        }),
        get("n"),              set("p"),           get("n"),
        sget(.hostn, hn.next), set("n"),           again,
    }),
});

/// The `wasi` host's poll over the GC list: the pollables copied into a
/// scratch list in linear memory (what `bp_host.wait` reads), the ready ones
/// settled and dropped, the scratch given back. `0` when nothing is pending.
pub const gc_task_host_poll_wasi = typedFunc("__task_host_poll", &.{}, .i32, &.{ l32("n"), l32("buf"), l32("out"), l32("k"), l32("i"), l32("h"), l32("top"), lref("node", .hostn) }, &.{
    gget("__task_hosts"),                                                                                                                 set("node"),
    loop(&.{ get("node"), is_null, brk, get("n"), c32(1), op("add"), set("n"), get("node"), sget(.hostn, hn.next), set("node"), again }), get("n"),
    op("eqz"),                                                                                                                            when(&.{ c32(0), ret }),
    gget(heap),                                                                                                                           set("top"),
    get("n"),                                                                                                                             c32(4),
    op("mul"),                                                                                                                            call("__alloc"),
    set("buf"),                                                                                                                           get("n"),
    c32(4),                                                                                                                               op("mul"),
    call("__alloc"),                                                                                                                      set("out"),
    gget("__task_hosts"),                                                                                                                 set("node"),
    loop(&.{
        get("node"),        is_null,               brk,
        get("buf"),         get("i"),              c32(4),
        op("mul"),          op("add"),             get("node"),
        sget(.hostn, hn.h), store(0),              get("i"),
        c32(1),             op("add"),             set("i"),
        get("node"),        sget(.hostn, hn.next), set("node"),
        again,
    }),
    get("buf"),                                                                                                                           get("n"),
    get("out"),                                                                                                                           call("bp_host_wait"),
    set("k"),                                                                                                                             c32(0),
    set("i"),
    loop(&.{
        get("i"),             get("k"),                   op("ge_u"), brk,
        get("buf"),           get("out"),                 get("i"),   c32(4),
        op("mul"),            op("add"),                  load(0),    c32(4),
        op("mul"),            op("add"),                  load(0),    set("h"),
        get("h"),             call("__task_host_settle"), .drop,      get("h"),
        call("bp_host_drop"), get("i"),                   c32(1),     op("add"),
        set("i"),             again,
    }),
    get("top"),                                                                                                                           gset(heap),
    c32(1),
});

/// `wasi:delay` — a task holding `v`, settled when the host's pollable for
/// `ms` milliseconds is ready. A negative duration is `0`.
const gc_task_delay = typedFunc("__task_delay", &.{ p32("ms"), .{ .name = "v", .ty = .anyref } }, gref(.task), &.{lref("t", .task)}, &.{
    get("ms"),             c32(0),      op("lt_s"),              when(&.{ c32(0), set("ms") }),
    c32(-1),               null_struct, call("__task_new"),      set("t"),
    get("t"),              get("v"),    sset(.task, tk.value),   get("ms"),
    call("bp_host_delay"), get("t"),    call("__task_host_add"), get("t"),
});

/// `wasi:race` — the first of `xs` to settle: one settled already, the first
/// in input order; else the task waits on all of them. An empty list traps.
const gc_task_race = typedFunc("__task_race", &.{pslot("xs", .arr_any)}, gref(.task), &.{ l32("n"), l32("i"), lref("t", .task), lref("r", .task) }, &.{
    get("xs"), .array_len,  set("n"),
    get("n"),  op("eqz"),   when(&.{.@"unreachable"}),
    c32(-1),   null_struct, call("__task_new"),
    set("r"),
    loop(&.{
        get("i"),  get("n"), op("ge_u"),                                brk,
        get("xs"), get("i"), .{ .array_get = .{ .ty = gs(.arr_any) } }, rcast(.task),
        set("t"),  get("t"), sget(.task, tk.state),                     when(&.{ get("r"), get("t"), sget(.task, tk.value), sset(.task, tk.value), get("r"), call("__task_wake"), get("r"), ret }),
        get("i"),  c32(1),   op("add"),                                 set("i"),
        again,
    }),
    c32(0),    set("i"),
    loop(&.{
        get("i"),  get("n"), op("ge_u"),                                brk,
        get("xs"), get("i"), .{ .array_get = .{ .ty = gs(.arr_any) } }, rcast(.task),
        c32(1),    get("r"), c32(0),                                    call("__task_listen"),
        get("i"),  c32(1),   op("add"),                                 set("i"),
        again,
    }),
    get("r"),
});

/// Thunk `f` called: the task it answers (decision 392: started, run to its
/// first `await`). A function value is a `$closure`, called through the table
/// with no argument (`gcClosureSig(0)`).
fn callThunk(comptime f: []const u8) [6]Instr {
    return .{ get(f), get(f), sget(.closure, 0), rcast(.sig0), .{ .call_ref = gs(.sig0) }, rcast(.task) };
}

/// `wasi:race_of` — every thunk of `fs` called in order, then raced.
const gc_task_race_of = typedFunc("__task_race_of", &.{pslot("fs", .arr_any)}, gref(.task), &.{ l32("n"), l32("i"), lref("xs", .arr_any), lref("f", .closure) }, &([_]Instr{
    get("fs"), .array_len,                             set("n"),
    get("n"),  .{ .array_new_default = gs(.arr_any) }, set("xs"),
    loop(&([_]Instr{
        get("i"),  get("n"),  op("ge_u"),                                brk,
        get("fs"), get("i"),  .{ .array_get = .{ .ty = gs(.arr_any) } }, rcast(.closure),
        set("f"),  get("xs"), get("i"),
    } ++ callThunk("f") ++ [_]Instr{
        .{ .array_set = gs(.arr_any) },
        get("i"),
        c32(1),
        op("add"),
        set("i"),
        again,
    })),
    get("xs"), call("__task_race"),
}));

/// `wasi:spawn_all` — every thunk of `fs` called in order; the task settles
/// with their answers in input order once the last of them has settled.
const gc_task_spawn_all = typedFunc("__task_spawn_all", &.{pslot("fs", .arr_any)}, gref(.task), &.{ l32("n"), l32("i"), lref("out", .arr_any), lref("f", .closure), lref("t", .task), lref("r", .task) }, &([_]Instr{
    get("fs"),                                                                                                                       .array_len,                             set("n"),
    get("n"),                                                                                                                        .{ .array_new_default = gs(.arr_any) }, set("out"),
    c32(-1),                                                                                                                         null_struct,                            call("__task_new"),
    set("r"),                                                                                                                        get("r"),                               get("out"),
    sset(.task, tk.aux),                                                                                                             get("r"),                               get("n"),
    sset(.task, tk.left),
    loop(&([_]Instr{
        get("i"),  get("n"), op("ge_u"),                                brk,
        get("fs"), get("i"), .{ .array_get = .{ .ty = gs(.arr_any) } }, rcast(.closure),
        set("f"),
    } ++ callThunk("f") ++ [_]Instr{
        set("t"),
        get("t"),
        sget(.task, tk.state),
        whenElse(&.{
            get("out"),           get("i"), get("t"),             sget(.task, tk.value), .{ .array_set = gs(.arr_any) },
            get("r"),             get("r"), sget(.task, tk.left), c32(1),                op("sub"),
            sset(.task, tk.left),
        }, &.{ get("t"), c32(2), get("r"), get("i"), call("__task_listen") }),
        get("i"),
        c32(1),
        op("add"),
        set("i"),
        again,
    })),
    get("r"),                                                                                                                        sget(.task, tk.left),                   op("eqz"),
    when(&.{ get("r"), get("out"), sset(.task, tk.value), get("r"), null_any, sset(.task, tk.aux), get("r"), call("__task_wake") }), get("r"),
}));

/// `wasi:gate_new` — a closed gate: a pending task no host answers.
const gc_task_gate_new = typedFunc("__task_gate_new", &.{}, gref(.task), &.{}, &.{ c32(-1), null_struct, call("__task_new") });

/// `wasi:gate_open` — gate `g` opens: the timer of each wait still pending on
/// it is dropped, then every wait answers `1`. Opening an open gate changes
/// nothing.
const gc_task_gate_open = typedFunc("__task_gate_open", &.{.{ .name = "g", .ty = .anyref }}, null, &.{ lref("t", .task), lref("n", .waiter), lref("r", .task) }, &([_]Instr{
    get("g"), rcast(.task),            set("t"),
    get("t"), sget(.task, tk.state),   when(&.{ret}),
    get("t"), sget(.task, tk.waiters), set("n"),
    loop(&.{
        get("n"), is_null,                  brk,
        get("n"), sget(.waiter, wt.target), set("r"),
        get("n"), sget(.waiter, wt.kind),   c32(1),
        op("eq"),
        when(&.{
            get("r"),                                                                                                                                           sget(.task, tk.state), op("eqz"),
            when(&.{ get("r"), sget(.task, tk.aux), is_null, op("eqz"), when(&.{ get("r"), sget(.task, tk.aux), rcast(.task), call("__task_host_cancel") }) }),
        }),
        get("n"), sget(.waiter, wt.next),   set("n"),
        again,
    }),
    get("t"),
} ++ boxed(1) ++ [_]Instr{call("__task_settle")}));

/// `wasi:gate_await` — a task answering `1` when gate `g` opens (at once when
/// it is open), `0` when `ms` milliseconds pass first.
const gc_task_gate_await = typedFunc("__task_gate_await", &.{ .{ .name = "g", .ty = .anyref }, p32("ms") }, gref(.task), &.{ lref("t", .task), lref("r", .task), lref("d", .task) }, &([_]Instr{
    get("g"),                                                                                    rcast(.task), set("t"),
    c32(-1),                                                                                     null_struct,  call("__task_new"),
    set("r"),                                                                                    get("t"),     sget(.task, tk.state),
    when(&([_]Instr{get("r")} ++ boxed(1) ++ [_]Instr{ call("__task_settle"), get("r"), ret })), get("ms"),
} ++ boxed(0) ++ [_]Instr{
    call("__task_delay"),  set("d"),
    get("r"),              get("d"),
    sset(.task, tk.aux),   get("t"),
    c32(1),                get("r"),
    c32(0),                call("__task_listen"),
    get("d"),              c32(1),
    get("r"),              c32(0),
    call("__task_listen"), get("r"),
}));

/// `wasi:cell_new` in a GC module — a `use memo` slot: a `$cell`
/// `{filled, value}`, empty.
const gc_memo_cell_new = typedFunc("__memo_cell_new", &.{}, gref(.cell), &.{}, &.{ c32(0), null_any, snew(.cell) });

/// `wasi:cell_filled` — whether cell `c` holds a value.
const gc_memo_cell_filled = typedFunc("__memo_cell_filled", &.{.{ .name = "c", .ty = .anyref }}, .i32, &.{}, &.{ get("c"), rcast(.cell), sget(.cell, 0) });

/// `wasi:cell_get` — the value cell `c` holds.
const gc_memo_cell_get = typedFunc("__memo_cell_get", &.{.{ .name = "c", .ty = .anyref }}, .anyref, &.{}, &.{ get("c"), rcast(.cell), sget(.cell, 1) });

/// `wasi:cell_set` — cell `c` holds `v`.
const gc_memo_cell_set = typedFunc("__memo_cell_set", &.{ .{ .name = "c", .ty = .anyref }, .{ .name = "v", .ty = .anyref } }, null, &.{}, &.{
    get("c"), rcast(.cell), get("v"), sset(.cell, 1),
    get("c"), rcast(.cell), c32(1),   sset(.cell, 0),
});

/// The program's exception tag in a GC module (decision 518): its one value
/// an `$exn`, as an `anyref`.
pub const gc_panic_tag = ast.Tag{ .name = "__bp_panic", .params = &.{.anyref} };

/// `$__panic_raise(msg, print)` — the abort's `$exn`, thrown.
const gc_panic_raise = typedFunc("__panic_raise", &.{ pref("msg"), p32("print") }, null, &.{}, &.{
    get("msg"), get("print"), snew(.exn), .{ .throw = "__bp_panic" },
});

/// `wasi:attempt` — `$__wasi_attempt(f)`: the thunk `f` called inside a
/// `try_table` catching `$__bp_panic`; a `$result` — `Ok` (0) of the thunk's
/// answer, or `Error` (1) of the abort's message.
const gc_wasi_attempt = typedFunc("__wasi_attempt", &.{pslot("f", .closure)}, gref(.result), &.{ .{ .name = "v", .ty = .anyref }, sref("m") }, &.{
    .{ .block = .{ .kind = .block, .label = "caught", .result = .anyref, .body = seqOf(&.{
        .{ .block = .{ .kind = .try_table, .result = .anyref, .catches = &.{.{ .tag = "__bp_panic", .label = "caught" }}, .body = seqOf(&.{
            get("f"), get("f"), sget(.closure, 0), rcast(.sig0), .{ .call_ref = gs(.sig0) },
        }, .{ .value = .anyref }) } },
        .{ .local_set = "v" },
        c32(0),
        get("v"),
        snew(.result),
        ret,
    }, .terminated) } },
    rcast(.exn),
    sget(.exn, 0),
    .{ .local_set = "m" },
    c32(1),
    get("m"),
    snew(.result),
});

/// `$__chk_fail(site)` of a GC module with exceptions: the abort raised.
pub const gc_chk_fail_raise = typedFunc("__chk_fail", &.{pref("site")}, null, &.{}, &.{ get("site"), c32(1), call("__panic_raise"), .@"unreachable" });

/// The GC forms of the scheduler's groups (`gcItems`).
const gc_task_items = [_]ast.Item{
    .{ .global = gc_task_head_global }, .{ .global = gc_task_tail_global }, .{ .global = task_suspended_global },
    .{ .func = gc_task_new },           .{ .func = gc_task_start },         .{ .func = gc_task_pending },
    .{ .func = gc_task_listen },        .{ .func = gc_task_wait },          .{ .func = gc_task_settle },
    .{ .func = gc_task_wake },          .{ .func = gc_task_enqueue },       .{ .func = gc_task_drain },
    .{ .func = gc_task_block_on },      .{ .func = task_finish },
};

/// The GC form of group `g` (front 164 s2): its own items when it moves no
/// string, its GC functions when it does, null when it has none yet — a
/// module that needs such a group is lowered in linear memory. `capture`: the
/// module holds `text_capture`, whose `$__write_bytes` appends to `$__cap`.
pub fn gcItems(g: ast.HelperGroup, capture: bool) ?[]const ast.Item {
    return switch (g) {
        .print => if (capture) &gc_print_items_capture else &print_items,
        .print_str => &.{ .{ .func = gc_print_str_raw }, .{ .func = gc_print_str } },
        .print_f64 => &.{ .{ .func = print_f64 }, .{ .func = gc_print_f64_raw } },
        .str_concat => &.{.{ .func = gc_str_concat }},
        .str_eq => &.{.{ .func = gc_str_eq }},
        .text_capture => &.{ .{ .global = gc_cap_global }, .{ .func = gc_cap_begin }, .{ .func = gc_cap_end } },
        .std_marshal => items(.std_marshal),
        .str_cmp => items(.str_cmp),
        // The host's entropy and the seeded stream's word (front 164 s3 P2-e):
        // the `.wat` leaves of `random.wat` name both.
        // Decision 1021 (10): `bigint`'s marker has no function in a GC
        // module either (its values are byte arrays, `wat.zig`'s marshal).
        .wasi_random_f64, .random_state, .fs_host, .bigint => items(g),
        // The shape walker and the tagged printer are generated per module
        // (`wat.zig`'s `gcPrinter`); the quoted string is the one shared piece.
        .print_shaped => &.{.{ .func = gc_print_quoted_raw }},
        .panic_fail => &.{.{ .func = gc_panic_fail }},
        .main_fail => &.{.{ .func = gc_main_fail }},
        .assert_fail => items(g),
        // `$__print_tagged_raw` is generated, and asks no module's `display`
        // hook: a record's own `display` is called by its printer.
        .display_of => &.{},
        .print_bool, .alloc, .i32_abs, .i32_min, .i32_max => items(g),
        .print_i64 => &.{ .{ .func = gc_print_i64_raw }, .{ .func = print_i64 } },
        .print_u64 => &.{ .{ .func = gc_print_u64_raw }, .{ .func = print_u64 } },
        .int_chk => &gc_int_chk_items,
        .i32_range_chk => &.{.{ .func = gc_i32_range_chk }},
        .i64_range_chk => &.{.{ .func = gc_i64_range_chk }},
        .u64_chk => &gc_u64_chk_items,
        .nz_chk => &gc_nz_chk_items,
        .chk_fail => &.{.{ .func = gc_chk_fail }},
        // Front 164 s2 P4 — the scheduler over GC structs; its types named
        // by slot (`GcSlot`), which `wat.zig` resolves for the module. The
        // dispatch (`task_resume`), the `wasi` poll and the `browser` entry
        // are the module's (`wat.zig`), as in linear memory.
        .task => &gc_task_items,
        .task_poll => items(g),
        .task_host => &.{ .{ .global = gc_task_hosts_global }, .{ .func = gc_task_host_add }, .{ .func = gc_task_host_settle } },
        .task_delay => &.{.{ .func = gc_task_delay }},
        .task_race => &.{.{ .func = gc_task_race }},
        .task_race_of => &.{.{ .func = gc_task_race_of }},
        .task_spawn_all => &.{.{ .func = gc_task_spawn_all }},
        .task_gate => &.{ .{ .func = gc_task_host_cancel }, .{ .func = gc_task_gate_new }, .{ .func = gc_task_gate_open }, .{ .func = gc_task_gate_await } },
        .memo_cell => &.{ .{ .func = gc_memo_cell_new }, .{ .func = gc_memo_cell_filled }, .{ .func = gc_memo_cell_get }, .{ .func = gc_memo_cell_set } },
        .panic_raise => &.{.{ .func = gc_panic_raise }},
        .wasi_attempt => &.{.{ .func = gc_wasi_attempt }},
        else => null,
    };
}

/// The groups whose GC form names a type by slot (`GcSlot`): `wat.zig`
/// resolves each of their items for the module (`gcRemapItem`).
pub fn gcSlotted(g: ast.HelperGroup) bool {
    return switch (g) {
        .task, .task_host, .task_delay, .task_race, .task_race_of, .task_spawn_all, .task_gate, .memo_cell, .panic_raise, .wasi_attempt => true,
        else => false,
    };
}

/// The groups a GC form calls into beyond `HelperGroup.deps`: the marshal
/// arena.
pub fn gcDeps(g: ast.HelperGroup) []const ast.HelperGroup {
    return switch (g) {
        .print_str, .print_f64, .text_capture, .panic_fail, .main_fail => &.{.alloc},
        .print_i64, .print_u64 => &.{ .print_str, .alloc },
        else => &.{},
    };
}

const gc_i32_range_chk = i32RangeChk(pref("site"));
const gc_i64_range_chk = i64RangeChk(pref("site"));
const gc_int_chk_items = intChkItems(pref("site"));
const gc_u64_chk_items = u64Chk(pref("site"));
const gc_nz_chk_items = nzItems(pref("site"));

const gc_print_items_capture = blk: {
    var out = print_items;
    for (&out) |*it| if (it.* == .func and std.mem.eql(u8, it.func.name, "__write_bytes")) {
        it.* = .{ .func = gc_write_bytes_capture };
    };
    break :blk out;
};

/// Decision 1021 (9) (i) — the prelude group: the GC lowering's shared
/// vocabulary, emitted whole in every module that declares a GC type, at
/// these indices, so every unit agrees on each of them (a std unit holding
/// `.wat` leaves declares it alone, decision 1026).
///
/// Decision 1055 (1): `$__decl`, the open struct every record and variant
/// subtypes, its first field the type's `$__tinfo` (its name
/// `<pkg>@<path>.<Type>`, its `print` / `eq` / `display` funcrefs, its
/// `kind`); `$__print_sig` and `$__eq_sig`, what the core casts those
/// funcrefs to. The group holds no closure signature (decision 1076 (2)):
/// each `$sig_<n>` is a singleton group after it (`gcSigDef`).
pub const GcPrelude = enum(u16) { str, arr_i32, arr_f64, arr_any, tuple, box_i32, box_i64, box_f64, box_bool, box_big, closure, result, exn, task, waiter, hostn, gen, cell, decl, tinfo, print_sig, eq_sig };

/// Decision 1076 (2) — `$sig_<n>`, the function type of a lambda's entry of
/// `n` parameters (`$closure` and `n` `anyref`s to an `anyref`): a unit
/// declares one per arity it uses, each a rec group of its own right after
/// the prelude's, so it is one type in every unit by structure (a `$sig_n`
/// inside another group would be another type); no arity is capped.
pub fn gcSigDef(ar: std.mem.Allocator, n: usize) !ast.TypeDef {
    const ps = try ar.alloc(ast.ValType, n + 1);
    ps[0] = gcPreludeRef(.closure);
    for (ps[1..]) |*p| p.* = .anyref;
    return .{ .name = try std.fmt.allocPrint(ar, "sig_{d}", .{n}), .kind = .{ .func = .{ .params = ps, .result = .anyref } } };
}

pub fn gcPreludeRef(p: GcPrelude) ast.ValType {
    return ast.ValType.def(@intFromEnum(p));
}

pub const gc_prelude_defs = [_]ast.TypeDef{
    gc_str_def,
    .{ .name = "arr_i32", .kind = .{ .array = .{ .ty = .i32, .mutable = true } } },
    .{ .name = "arr_f64", .kind = .{ .array = .{ .ty = .f64, .mutable = true } } },
    // Open: `$tuple` is its subtype.
    .{ .name = "arr_any", .kind = .{ .array = .{ .ty = .anyref, .mutable = true } }, .final = false },
    .{ .name = "tuple", .kind = .{ .array = .{ .ty = .anyref, .mutable = true } }, .super = @intFromEnum(GcPrelude.arr_any) },
    // Open: `$box_bool` and an enum's box are its subtypes.
    .{ .name = "box_i32", .kind = .{ .@"struct" = &.{.{ .name = "v", .ty = .i32 }} }, .final = false },
    .{ .name = "box_i64", .kind = .{ .@"struct" = &.{.{ .name = "v", .ty = .i64 }} } },
    .{ .name = "box_f64", .kind = .{ .@"struct" = &.{.{ .name = "v", .ty = .f64 }} } },
    .{ .name = "box_bool", .kind = .{ .@"struct" = &.{.{ .name = "v", .ty = .i32 }} }, .super = @intFromEnum(GcPrelude.box_i32) },
    // Decision 1031 (2) — a `bigint` in an `anyref` slot (a union's member, a type
    // parameter's slot): its block's bytes in a box of its own, so it is told from a
    // string (`ref.test`), printed by its digits and compared by value. A leaf: final.
    .{ .name = "box_big", .kind = .{ .@"struct" = &.{.{ .name = "v", .ty = gc_str_ref }} } },
    // Decision 1055 (4): the lambda's entry (`ref.func`, cast to the
    // prelude's `$sig_<arity>` and `call_ref`ed), its declared arity (what
    // `fn/N` prints, 1051), the component mark (decision 504).
    .{ .name = "closure", .kind = .{ .@"struct" = &.{ .{ .name = "fn", .ty = .funcref }, .{ .name = "arity", .ty = .i32 }, .{ .name = "mark", .ty = .i32 } } }, .final = false },
    .{ .name = "result", .kind = .{ .@"struct" = &.{ .{ .name = "tag", .ty = .i32, .mutable = true }, .{ .name = "payload", .ty = .anyref, .mutable = true } } } },
    .{ .name = "exn", .kind = .{ .@"struct" = &.{ .{ .name = "msg", .ty = gc_str_ref }, .{ .name = "print", .ty = .i32 } } } },
    .{ .name = "task", .kind = .{ .@"struct" = &.{
        .{ .name = "state", .ty = .i32, .mutable = true },
        .{ .name = "waiters", .ty = gcPreludeRef(.waiter), .mutable = true },
        .{ .name = "value", .ty = .anyref, .mutable = true },
        .{ .name = "frame", .ty = .structref, .mutable = true },
        .{ .name = "kind", .ty = .i32 },
        .{ .name = "next", .ty = gcPreludeRef(.task), .mutable = true },
        .{ .name = "aux", .ty = .anyref, .mutable = true },
        .{ .name = "left", .ty = .i32, .mutable = true },
    } } },
    .{ .name = "waiter", .kind = .{ .@"struct" = &.{
        .{ .name = "next", .ty = gcPreludeRef(.waiter), .mutable = true },
        .{ .name = "kind", .ty = .i32 },
        .{ .name = "target", .ty = gcPreludeRef(.task) },
        .{ .name = "slot", .ty = .i32 },
    } } },
    .{ .name = "hostn", .kind = .{ .@"struct" = &.{
        .{ .name = "next", .ty = gcPreludeRef(.hostn), .mutable = true },
        .{ .name = "h", .ty = .i32 },
        .{ .name = "t", .ty = gcPreludeRef(.task) },
    } } },
    .{ .name = "gen", .kind = .{ .@"struct" = &.{
        .{ .name = "state", .ty = .i32, .mutable = true },
        .{ .name = "kind", .ty = .i32 },
        .{ .name = "frame", .ty = .structref, .mutable = true },
        .{ .name = "value", .ty = .anyref, .mutable = true },
        .{ .name = "src", .ty = gcPreludeRef(.gen), .mutable = true },
        .{ .name = "aux", .ty = .anyref, .mutable = true },
        .{ .name = "left", .ty = .i32, .mutable = true },
    } } },
    .{ .name = "cell", .kind = .{ .@"struct" = &.{
        .{ .name = "filled", .ty = .i32, .mutable = true },
        .{ .name = "value", .ty = .anyref, .mutable = true },
    } } },
    .{ .name = "__decl", .kind = .{ .@"struct" = &.{.{ .name = "ti", .ty = gcPreludeRef(.tinfo) }} }, .final = false },
    .{ .name = "__tinfo", .kind = .{ .@"struct" = &.{
        .{ .name = "name", .ty = gc_str_ref },
        .{ .name = "print", .ty = .funcref },
        .{ .name = "eq", .ty = .funcref },
        .{ .name = "display", .ty = .funcref },
        .{ .name = "kind", .ty = .i32 },
    } } },
    .{ .name = "__print_sig", .kind = .{ .func = .{ .params = &.{.anyref} } } },
    .{ .name = "__eq_sig", .kind = .{ .func = .{ .params = &.{ .anyref, .anyref }, .result = .i32 } } },
};

// ── the core's capture, type registry and dispatch (decision 1055 (2), (3), (5)) ──

fn pi(comptime p: GcPrelude) u16 {
    return @intFromEnum(p);
}
fn pget(comptime p: GcPrelude, comptime f: u32) Instr {
    return .{ .struct_get = .{ .ty = pi(p), .field = f } };
}
fn pcast(comptime p: GcPrelude) Instr {
    return .{ .ref_cast = gcPreludeRef(p) };
}

/// The core's capture (decisions 1028 (2), 1055 (5), 1063 (3), 1071 (2)): the
/// string `$__write_bytes` appends to while it is open, null when none is; an
/// `arrayref` so no unit's import names a concrete type (1037).
pub const core_cap_global = ast.Global{ .name = "__cap", .exports = &.{"__cap"}, .ty = .arrayref, .mutable = true, .init = "" };
/// How deep a unit's own capture (a `Display` hole, a `run()`'s) nests inside
/// the core's: the core's capture mirrors a write to `fd_write` only at 0.
pub const core_cap_depth_global = ast.Global{ .name = "__cap_depth", .exports = &.{"__cap_depth"}, .ty = .i32, .mutable = true, .init = "0" };
/// Every unit's `$__tinfo`, in the order the units registered them (1055 (2)):
/// `typeinfo`'s and debugging's, never print's.
const core_types_global = ast.Global{ .name = "__types", .ty = gcPreludeRef(.arr_any), .mutable = true, .init = "" };
const core_types_n_global = ast.Global{ .name = "__types_n", .ty = .i32, .mutable = true, .init = "0" };

/// `$__write_bytes(p, n)` of the core: the bytes `[p, p + n)` appended to the
/// open capture, and also written to `fd_write` when the core's own capture
/// holds them (depth 0, under comptime the host's copy); with none open, to
/// `fd_write` alone.
const core_write_bytes = typedFunc("__write_bytes", &.{ p32("p"), p32("n") }, null, &.{ sref("c"), sref("q"), l32("l"), l32("i") }, &.{
    .{ .global_get = "__cap" }, rcastStr,
    set("c"),                   get("c"),
    .ref_is_null,               op("eqz"),
    when(&.{
        get("c"),  str_len,                    set("l"),                         get("l"),
        get("n"),  op("add"),                  str_new,                          set("q"),
        get("q"),  c32(0),                     get("c"),                         c32(0),
        get("l"),  str_copy,
        loop(&.{
            get("i"), get("n"), op("ge_u"), brk,
            get("q"), get("l"), get("i"),   op("add"),
            get("p"), get("i"), op("add"),  load8(0),
            str_set,  get("i"), c32(1),     op("add"),
            set("i"), again,
        }),
        get("q"),  .{ .global_set = "__cap" }, .{ .global_get = "__cap_depth" }, op("eqz"),
        op("eqz"), when(&.{ret}),
    }),
    c32(0),                     get("p"),
    store(0),                   c32(4),
    get("n"),                   store(0),
    c32(1),                     c32(0),
    c32(1),                     c32(8),
    call("fd_write"),           .drop,
});
const rcastStr: Instr = .{ .ref_cast = gc_str_ref };

/// `__cap_begin()` — the core's capture opened, empty (comptime's evaluated
/// unit's `__bp_init`, 1063 (3)).
const core_cap_begin = typedFunc("__cap_begin", &.{}, null, &.{}, &.{
    c32(0), str_new,                          .{ .global_set = "__cap" },
    c32(0), .{ .global_set = "__cap_depth" },
});

/// `__cap_end()` — closes the core's capture: its text, the capture null
/// again; later writes go to `fd_write` alone (1071 (2)).
const core_cap_end = typedFunc("__cap_end", &.{}, .arrayref, &.{.{ .name = "s", .ty = .arrayref }}, &.{
    .{ .global_get = "__cap" }, set("s"),
    .{ .ref_null = .arrayref }, .{ .global_set = "__cap" },
    get("s"),
});

/// `__ti_register(t)` — a unit's `$__tinfo` appended to the core's list.
const core_ti_register = typedFunc("__ti_register", &.{.{ .name = "t", .ty = .structref }}, null, &.{ l32("n"), .{ .name = "a", .ty = gcPreludeRef(.arr_any) } }, &.{
    .{ .global_get = "__types_n" },                                                                                                                 set("n"),
    get("n"),                                                                                                                                       c32(1),
    op("add"),                                                                                                                                      .{ .array_new_default = pi(.arr_any) },
    set("a"),                                                                                                                                       .{ .global_get = "__types" },
    .ref_is_null,                                                                                                                                   op("eqz"),
    when(&.{ get("a"), c32(0), .{ .global_get = "__types" }, c32(0), get("n"), .{ .array_copy = .{ .dst = pi(.arr_any), .src = pi(.arr_any) } } }), get("a"),
    get("n"),                                                                                                                                       get("t"),
    .{ .array_set = pi(.arr_any) },                                                                                                                 get("a"),
    .{ .global_set = "__types" },                                                                                                                   get("n"),
    c32(1),                                                                                                                                         op("add"),
    .{ .global_set = "__types_n" },
});

/// `__type_infos()` — the core's list of `$__tinfo`s.
const core_type_infos = typedFunc("__type_infos", &.{}, .arrayref, &.{}, &.{.{ .global_get = "__types" }});

/// `__print_decl(v)` — a declared type's value printed by its own `$__tinfo`'s
/// `print` (1055 (3)): whatever unit declared it, no table, no key. Each of
/// the three reads `info` through `ref.as_non_null` (decision 1076 (1)): a
/// null one is a compiler defect, trapping there by name.
const core_print_decl = typedFunc("__print_decl", &.{.{ .name = "v", .ty = .anyref }}, null, &.{}, &.{
    get("v"), get("v"), pcast(.decl), pget(.decl, 0), .ref_as_non_null, pget(.tinfo, 1), pcast(.print_sig), .{ .call_ref = pi(.print_sig) },
});

/// `__eq_decl(a, b)` — `a == b` by `a`'s `$__tinfo`'s `eq` (`0` for a `b` of
/// another type).
const core_eq_decl = typedFunc("__eq_decl", &.{ .{ .name = "a", .ty = .anyref }, .{ .name = "b", .ty = .anyref } }, .i32, &.{}, &.{
    get("a"), get("b"), get("a"), pcast(.decl), pget(.decl, 0), .ref_as_non_null, pget(.tinfo, 2), pcast(.eq_sig), .{ .call_ref = pi(.eq_sig) },
});

/// `__display_decl(v)` — `1` after writing `v`'s `Display` text through its
/// `$__tinfo`'s `display`, `0` (nothing written) for a type with none.
const core_display_decl = typedFunc("__display_decl", &.{.{ .name = "v", .ty = .anyref }}, .i32, &.{.{ .name = "f", .ty = .funcref }}, &.{
    get("v"),                        pcast(.decl), pget(.decl, 0),          .ref_as_non_null, pget(.tinfo, 3), set("f"),
    get("f"),                        .ref_is_null, when(&.{ c32(0), ret }), get("v"),         get("f"),        pcast(.print_sig),
    .{ .call_ref = pi(.print_sig) }, c32(1),
});

/// The core's GC items (decision 1055 (2), (3), (5)), each function exported
/// under its name.
pub const core_gc_items = blk: {
    const fs = [_]ast.Func{ core_write_bytes, core_cap_begin, core_cap_end, core_ti_register, core_type_infos, core_print_decl, core_eq_decl, core_display_decl };
    var out: [4 + fs.len]ast.Item = undefined;
    out[0] = .{ .global = core_cap_global };
    out[1] = .{ .global = core_cap_depth_global };
    out[2] = .{ .global = core_types_global };
    out[3] = .{ .global = core_types_n_global };
    for (fs, 0..) |f, k| {
        var e = f;
        e.exports = &.{f.name};
        out[4 + k] = .{ .func = e };
    }
    break :blk out;
};

/// The names the core's GC functions are exported under, with each one's
/// boundary signature (abstract types only, 1037).
pub const core_gc_exports = [_]struct { name: []const u8, type: ast.FuncType }{
    .{ .name = "__write_bytes", .type = .{ .params = &.{ .i32, .i32 } } },
    .{ .name = "__cap_begin", .type = .{} },
    .{ .name = "__cap_end", .type = .{ .result = .arrayref } },
    .{ .name = "__ti_register", .type = .{ .params = &.{.structref} } },
    .{ .name = "__type_infos", .type = .{ .result = .arrayref } },
    .{ .name = "__print_decl", .type = .{ .params = &.{.anyref} } },
    .{ .name = "__eq_decl", .type = .{ .params = &.{ .anyref, .anyref }, .result = .i32 } },
    .{ .name = "__display_decl", .type = .{ .params = &.{.anyref}, .result = .i32 } },
};

/// A unit's own capture over the core's (a `Display` hole, a `run()`'s):
/// `__cap_begin` answers the capture it replaces and nests one deeper, so the
/// core mirrors none of it; `__cap_end(o)` answers what was written and
/// restores `o` (1071 (2): it stays inside the unit).
const unit_cap_begin = typedFunc("__cap_begin", &.{}, gc_str_ref, &.{sref("o")}, &.{
    .{ .global_get = "__cap" },       rcastStr, set("o"),
    c32(0),                           str_new,  .{ .global_set = "__cap" },
    .{ .global_get = "__cap_depth" }, c32(1),   op("add"),
    .{ .global_set = "__cap_depth" }, get("o"),
});
const unit_cap_end = typedFunc("__cap_end", &.{pref("o")}, gc_str_ref, &.{sref("s")}, &.{
    .{ .global_get = "__cap" }, rcastStr,                   set("s"),
    get("o"),                   .{ .global_set = "__cap" }, .{ .global_get = "__cap_depth" },
    c32(1),                     op("sub"),                  .{ .global_set = "__cap_depth" },
    get("s"),
});
pub const unit_cap_items = [_]ast.Item{ .{ .func = unit_cap_begin }, .{ .func = unit_cap_end } };
