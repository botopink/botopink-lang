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
//! starts at 256): `0..8` the WASI iovec, `8` the newline byte — and `9` the
//! space of §7's `, ` separator, written beside it in one call —, `16..32` the
//! bool text, `64..128` the i32 digits. A float's text is built in the
//! `$__dtoa_ws` workspace, allocated once (§ an f64 as text).

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
        .print_arr_f64 => &.{ .{ .func = print_arr_f64_raw }, .{ .func = print_arr_f64 } },
        .assert_fail => &.{ .{ .func = write_err }, .{ .func = assert_fail } },
        .print_shaped => &.{ .{ .func = print_quoted_raw }, .{ .func = print_tagged_raw }, .{ .func = print_tagged }, .{ .func = print_shaped_raw } },
        .print_opt_f64 => &.{ .{ .func = print_opt_f64_raw }, .{ .func = print_opt_f64 } },
        .print_i64 => &.{ .{ .func = print_i64_raw }, .{ .func = print_i64 } },
        .int_chk => &int_chk_items,
        .print_opt_i64 => &.{ .{ .func = print_opt_i64_raw }, .{ .func = print_opt_i64 } },
        .print_opt_tagged => &.{ .{ .func = print_opt_tagged_raw }, .{ .func = print_opt_tagged } },
        .unknown => &.{ .{ .func = unknown_kind }, .{ .func = unknown_int_in }, .{ .func = unknown_as_i32 }, .{ .func = unknown_as_f64 }, .{ .func = unknown_eq } },
        .print_unknown => &.{ .{ .func = print_unknown_raw }, .{ .func = print_unknown } },
        .wasi_seed_state => &.{ .{ .global = seed_state_global }, .{ .global = seeded_global } },
        .dtoa => &dtoa_items,
        .print_opt => &.{
            .{ .func = print_null },         .{ .func = print_opt_i32_raw }, .{ .func = print_opt_i32 },
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
const print_tagged_raw = func("__print_tagged_raw", &.{"v"}, null, i32s(&.{ "d", "p", "k", "i", "n", "b", "s" }), &.{
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
        c32(4),    op("sub"), load(0),
        get("p"),  c32(1),    call("__print_shaped_raw"),
        set("p"),  get("i"),  c32(1),
        op("add"), set("i"),  again,
    })),
    get("k"),                                                                               when(&(putByte(')') ++ [_]Instr{call("__write_bytes")})),
});

const print_tagged = func("__print_tagged", &.{"v"}, null, &.{}, &.{ get("v"), call("__print_tagged_raw"), call("__print_nl") });

/// `s.charCodeAt(i)`: the code point at code-point index `i`, or `-1`
/// outside `0..count` — the answer the Erlang template gives (and Node's
/// `codePointAt` for every character of the Basic Multilingual Plane). The
/// string is UTF-8, so the walk steps a sequence at a time — its width from
/// the lead byte — and decodes the one it stops on. It answered the BYTE at
/// `i`: `"héllo".charCodeAt(1)` was `195` where the other targets said `233`.
const str_char_code = func("__str_char_code", &.{ "s", "i" }, .i32, i32s(&.{ "n", "p", "b", "w" }), &.{
    get("i"), c32(0),  op("lt_s"), when(&.{ c32(-1), ret }),
    get("s"), load(0), set("n"),
    loop(&.{
        get("p"),  get("n"),   op("ge_u"),                   when(&.{ c32(-1), ret }),
        get("s"),  get("p"),   op("add"),                    load8(4),
        set("b"),  c32(1),     set("w"),                     get("b"),
        c32(0xC0), op("ge_u"), when(&.{ c32(2), set("w") }), get("b"),
        c32(0xE0), op("ge_u"), when(&.{ c32(3), set("w") }), get("b"),
        c32(0xF0), op("ge_u"), when(&.{ c32(4), set("w") }), get("i"),
        op("eqz"),
        when(&.{
            get("w"), c32(1),    op("eq"),   when(&.{ get("b"), ret }),
            get("b"), c32(0x80), get("w"),   op("shr_u"),
            c32(1),   op("sub"), op("and"),  set("b"),
            get("w"), c32(1),    op("gt_u"),
            when(&.{
                get("b"), c32(6),    op("shl"), get("s"),
                get("p"), op("add"), c32(1),    op("add"),
                load8(4), c32(0x3F), op("and"), op("or"),
                set("b"),
            }),
            get("w"), c32(2),    op("gt_u"),
            when(&.{
                get("b"), c32(6),    op("shl"), get("s"),
                get("p"), op("add"), c32(2),    op("add"),
                load8(4), c32(0x3F), op("and"), op("or"),
                set("b"),
            }),
            get("w"), c32(3),    op("gt_u"),
            when(&.{
                get("b"), c32(6),    op("shl"), get("s"),
                get("p"), op("add"), c32(3),    op("add"),
                load8(4), c32(0x3F), op("and"), op("or"),
                set("b"),
            }),
            get("b"), ret,
        }),
        get("i"),  c32(1),     op("sub"),                    set("i"),
        get("p"),  get("w"),   op("add"),                    set("p"),
        again,
    }),
    c32(-1),
});

/// `s.lastIndexOf(sub)`: the last byte offset of `sub`, `-1` when absent, and
/// the length for an empty `sub` (JavaScript's answer).
const str_last_index_of = func("__str_last_index_of", &.{ "s", "sub" }, .i32, i32s(&.{ "n", "m", "i" }), &.{
    get("s"),   load(0),  set("n"),
    get("sub"), load(0),  set("m"),
    get("n"),   get("m"), op("sub"),
    set("i"),
    loop(&.{
        get("i"),  c32(0),           op("lt_s"),                brk,
        get("s"),  c32(4),           op("add"),                 get("i"),
        op("add"), get("sub"),       c32(4),                    op("add"),
        get("m"),  call("__mem_eq"), when(&.{ get("i"), ret }), get("i"),
        c32(1),    op("sub"),        set("i"),                  again,
    }),
    c32(-1),
});

// ── string indices in codepoints (decision 240) ──────────────────────────────
//
// A string is `[byte count][UTF-8 bytes]`, and `length`, `at`, `slice`,
// `indexOf` and `lastIndexOf` count CODEPOINTS on this target, as erlang and
// beam do (decision 169 applied to the fourth target): an index one of them
// answers can be handed to another. A byte is a codepoint's first exactly
// when it is not a `10xxxxxx` continuation byte, so each helper below walks
// the bytes and counts the ones that start a sequence. The byte helpers they
// sit on (`$__str_slice`, `$__str_index_of`, `$__str_last_index_of`) stay the
// byte cutters and searchers the rest of the prelude uses.

/// The bytes of `s` that start a codepoint, counted.
const str_cp_len = func("__str_cp_len", &.{"s"}, .i32, i32s(&.{ "n", "i", "k" }), &.{
    get("s"), load(0), set("n"),
    loop(&.{
        get("i"),                                          get("n"),  op("ge_u"), brk,
        get("s"),                                          get("i"),  op("add"),  load8(4),
        c32(0xC0),                                         op("and"), c32(0x80),  op("ne"),
        when(&.{ get("k"), c32(1), op("add"), set("k") }), get("i"),  c32(1),     op("add"),
        set("i"),                                          again,
    }),
    get("k"),
});

/// The byte offset where codepoint `i` (≥ 0) of `s` starts; the byte count
/// when `s` has `i` codepoints or fewer.
const str_cp_off = func("__str_cp_off", &.{ "s", "i" }, .i32, i32s(&.{ "n", "p", "k" }), &.{
    get("s"), load(0), set("n"),
    loop(&.{
        get("p"),  get("n"),  op("ge_u"), brk,
        get("s"),  get("p"),  op("add"),  load8(4),
        c32(0xC0), op("and"), c32(0x80),  op("ne"),
        when(&.{
            get("k"), get("i"), op("eq"),  when(&.{ get("p"), ret }),
            get("k"), c32(1),   op("add"), set("k"),
        }),
        get("p"),  c32(1),    op("add"),  set("p"),
        again,
    }),
    get("n"),
});

/// The codepoint index of byte offset `off` of `s` — the codepoints that start
/// before it; `-1` stays `-1` (a search that found nothing).
const str_cp_of = func("__str_cp_of", &.{ "s", "off" }, .i32, i32s(&.{ "p", "k" }), &.{
    get("off"), c32(0), op("lt_s"), when(&.{ c32(-1), ret }),
    loop(&.{
        get("p"),                                          get("off"), op("ge_u"), brk,
        get("s"),                                          get("p"),   op("add"),  load8(4),
        c32(0xC0),                                         op("and"),  c32(0x80),  op("ne"),
        when(&.{ get("k"), c32(1), op("add"), set("k") }), get("p"),   c32(1),     op("add"),
        set("p"),                                          again,
    }),
    get("k"),
});

/// `s.slice(a, b)` in codepoints, with `slice`'s bounds: a negative bound
/// counts from the end, each is clamped to `0..length`, and an end before the
/// start is the start. An open end is any bound past the length.
const str_cp_slice = func("__str_cp_slice", &.{ "s", "a", "b" }, .i32, i32s(&.{"n"}), &.{
    get("s"),                                            call("__str_cp_len"),         set("n"),
    get("a"),                                            c32(0),                       op("lt_s"),
    when(&.{ get("a"), get("n"), op("add"), set("a") }), get("a"),                     c32(0),
    op("lt_s"),                                          when(&.{ c32(0), set("a") }), get("a"),
    get("n"),                                            op("gt_s"),                   when(&.{ get("n"), set("a") }),
    get("b"),                                            c32(0),                       op("lt_s"),
    when(&.{ get("b"), get("n"), op("add"), set("b") }), get("b"),                     c32(0),
    op("lt_s"),                                          when(&.{ c32(0), set("b") }), get("b"),
    get("n"),                                            op("gt_s"),                   when(&.{ get("n"), set("b") }),
    get("b"),                                            get("a"),                     op("lt_s"),
    when(&.{ get("a"), set("b") }),                      get("s"),                     get("s"),
    get("a"),                                            call("__str_cp_off"),         get("s"),
    get("b"),                                            call("__str_cp_off"),         call("__str_slice"),
});

/// `s.at(i)` in codepoints, as a `?string`: a negative `i` counted from the
/// end (decision 139), then the one-codepoint string, or `0` — absence —
/// outside `0..length` (`$__str_at`'s unsigned compare, over the count).
const str_cp_at = func("__str_cp_at", &.{ "s", "i" }, .i32, i32s(&.{"n"}), &.{
    get("s"),                                            call("__str_cp_len"),    set("n"),
    get("i"),                                            c32(0),                  op("lt_s"),
    when(&.{ get("i"), get("n"), op("add"), set("i") }), get("i"),                get("n"),
    op("ge_u"),                                          when(&.{ c32(0), ret }), get("s"),
    get("i"),                                            get("i"),                c32(1),
    op("add"),                                           call("__str_cp_slice"),
});

/// `s.indexOf(sub)` in codepoints.
const str_cp_index_of = func("__str_cp_index_of", &.{ "s", "sub" }, .i32, &.{}, &.{
    get("s"), get("s"), get("sub"), call("__str_index_of"), call("__str_cp_of"),
});

/// `s.lastIndexOf(sub)` in codepoints.
const str_cp_last_index_of = func("__str_cp_last_index_of", &.{ "s", "sub" }, .i32, &.{}, &.{
    get("s"), get("s"), get("sub"), call("__str_last_index_of"), call("__str_cp_of"),
});

// ── decision 238's WASI adapters (`host_binding.zig` `adapters`) ─────────────

/// `random_get(buf, len)` — WASI preview1's one source of random bytes.
pub const random_get_import = ast.Import{
    .module = "wasi_snapshot_preview1",
    .name = "random_get",
    .func = "random_get",
    .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 },
};

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

/// `wasi:seed_u32` / `wasi:seeded_f64` — `std/io/random`'s seeded stream as
/// the commonJS sidecar draws it (`libs/std/src/sidecars/random.mjs`):
/// Mulberry32 over one word of state, so the same `seed` gives the same draws
/// on both targets. `$__seeded` is 0 until a seed is written, and until then a
/// draw is `$__wasi_random_f64`'s — the sidecar's `Math.random` fallback.
const seed_state_global = ast.Global{ .name = "__seed_state", .ty = .i32, .mutable = true, .init = "0" };
const seeded_global = ast.Global{ .name = "__seeded", .ty = .i32, .mutable = true, .init = "0" };

/// `state = s` — `(Number(s) | 0) >>> 0` is the word's own bits.
const wasi_seed_u32 = func("__wasi_seed_u32", &.{"s"}, null, &.{}, &.{
    get("s"), .{ .global_set = "__seed_state" }, c32(1), .{ .global_set = "__seeded" },
});

/// One Mulberry32 step: `state += 0x6D2B79F5`; `t = imul(t ^ t >>> 15, t | 1)`;
/// `t ^= t + imul(t ^ t >>> 7, t | 61)`; `(t ^ t >>> 14) >>> 0` scaled by 2^-32.
const wasi_seeded_f64 = typedFunc("__wasi_seeded_f64", &.{}, .f64, i32s(&.{"t"}), &.{
    .{ .global_get = "__seeded" },             op("eqz"),                           when(&.{ call("__wasi_random_f64"), ret }),
    .{ .global_get = "__seed_state" },         c32(1831565813),                     op("add"),
    tee("t"),                                  .{ .global_set = "__seed_state" },   get("t"),
    get("t"),                                  c32(15),                             op("shr_u"),
    op("xor"),                                 get("t"),                            c32(1),
    op("or"),                                  op("mul"),                           set("t"),
    get("t"),                                  get("t"),                            get("t"),
    get("t"),                                  c32(7),                              op("shr_u"),
    op("xor"),                                 get("t"),                            c32(61),
    op("or"),                                  op("mul"),                           op("add"),
    op("xor"),                                 set("t"),                            get("t"),
    get("t"),                                  c32(14),                             op("shr_u"),
    op("xor"),                                 .{ .convert = "f64.convert_i32_u" }, .{ .@"const" = .{ .ty = .f64, .text = "2.3283064365386963e-10" } },
    .{ .op = .{ .ty = .f64, .name = "mul" } },
});

/// `s.padStart(width, pad)` (`start = 1`) / `padEnd` (`start = 0`): `s` when it
/// is already `width` long or the pad is empty, else a fresh string of `width`
/// bytes with the pad repeated into the gap (JavaScript's cycling).
const str_pad = func("__str_pad", &.{ "s", "width", "pad", "start" }, .i32, i32s(&.{ "n", "pl", "k", "p", "i", "at" }), &.{
    get("s"),                  load(0),         set("n"),
    get("pad"),                load(0),         set("pl"),
    get("width"),              get("n"),        op("le_s"),
    get("pl"),                 op("eqz"),       op("or"),
    when(&.{ get("s"), ret }), get("width"),    c32(4),
    op("add"),                 call("__alloc"), set("p"),
    get("p"),                  get("width"),    store(0),
    get("width"),              get("n"),        op("sub"),
    set("k"),
    // the text lands after the gap on `padStart`, at the front on `padEnd`
                     get("p"),        c32(4),
    op("add"),                 get("start"),    get("k"),
    op("mul"),                 op("add"),       get("s"),
    c32(4),                    op("add"),       get("n"),
    copy,
    // the gap starts at 0 on `padStart`, after the text on `padEnd`
                         get("start"),    op("eqz"),
    get("n"),                  op("mul"),       set("at"),
    loop(&.{
        get("i"),    get("k"),   op("ge_u"), brk,
        get("p"),    get("at"),  op("add"),  get("i"),
        op("add"),   get("pad"), get("i"),   get("pl"),
        op("rem_u"), op("add"),  load8(4),   store8(4),
        get("i"),    c32(1),     op("add"),  set("i"),
        again,
    }),
    get("p"),
});

/// `s.replace(pat, with)` (`all = 0`: the first occurrence) / `replaceAll`
/// (`all = 1`). An empty `pat` matches before every byte and at the end, as
/// JavaScript's does: `replace` puts `with` in front, `replaceAll` around
/// every byte.
const str_replace = func("__str_replace", &.{ "s", "pat", "with", "all" }, .i32, i32s(&.{ "m", "n", "out", "rest", "idx", "i" }), &.{
    get("pat"), load(0),         set("m"),
    get("s"),   load(0),         set("n"),
    get("m"),   op("eqz"),
    when(&.{
        get("with"),                                                        set("out"),
        get("all"),
        when(&.{loop(&.{
            get("i"),   get("n"),   op("ge_u"),          brk,
            get("out"), get("s"),   get("i"),            get("i"),
            c32(1),     op("add"),  call("__str_slice"), call("__str_concat"),
            set("out"), get("out"), get("with"),         call("__str_concat"),
            set("out"), get("i"),   c32(1),              op("add"),
            set("i"),   again,
        })}),
        get("all"),                                                         op("eqz"),
        when(&.{ get("out"), get("s"), call("__str_concat"), set("out") }), get("out"),
        ret,
    }),
    c32(4),     call("__alloc"), set("out"),
    get("out"), c32(0),          store(0),
    get("s"),   set("rest"),
    loop(&.{
        get("rest"),         get("pat"),           call("__str_index_of"), set("idx"),
        get("idx"),          c32(-1),              op("eq"),               brk,
        get("out"),          get("rest"),          c32(0),                 get("idx"),
        call("__str_slice"), call("__str_concat"), set("out"),             get("out"),
        get("with"),         call("__str_concat"), set("out"),             get("rest"),
        get("idx"),          get("m"),             op("add"),              get("rest"),
        load(0),             call("__str_slice"),  set("rest"),            get("all"),
        op("eqz"),           brk,                  again,
    }),
    get("out"), get("rest"),     call("__str_concat"),
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

/// A float as commonJS prints it: `Number.isInteger(x) ? x.toFixed(1) :
/// String(x)` (`$__f64_fmt` mode 1) — `5.0`, `0.30000000000000004`,
/// `1e+21`, `NaN`. It wrote an integer part and six fraction digits, so
/// `0.26642920868471265` printed `0.266429` and a float past `2^31` trapped.
const print_f64_raw = typedFunc("__print_f64_raw", &.{.{ .name = "x", .ty = .f64 }}, null, i32s(&.{"n"}), &.{
    getF("x"),             c32(1),         call("__f64_fmt"), set("n"),
    call("__dtoa_ws"),     c32(dtoa_text), op("add"),         get("n"),
    call("__write_bytes"),
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
    .{ .comment = " 16..32 bool text   64..128 i32 digits" },
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

/// `s.at(i)` as a `?string`: a fresh one-byte string, or `0` — absence — when
/// `i` is outside `0..len` once a negative `i` has been counted from the end
/// (`i + len`, decision 139). A `?string` needs no box on this backend: a string
/// IS its own pointer and `$__print_opt_str_raw` reads absence as `i32.eqz`,
/// which is why this answers a pointer and not the `$__box_i32` cell
/// `$__arr_at_box` builds for a scalar element. The bounds test is `$__arr_at`'s
/// against the length prefix instead of the element count, folded into one
/// **unsigned** compare: a negative `i` wraps past any length, so `i32.ge_u`
/// rejects both ends where `$__arr_at` needs `lt_s` and `ge_s` together.
const str_at = func("__str_at", &.{ "s", "i" }, .i32, &.{}, &.{
    get("i"),                                                     c32(0),     op("lt_s"),
    when(&.{ get("i"), get("s"), load(0), op("add"), set("i") }), get("i"),   get("s"),
    load(0),                                                      op("ge_u"), when(&.{ c32(0), ret }),
    get("s"),                                                     get("i"),   get("i"),
    c32(1),                                                       op("add"),  call("__str_slice"),
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

/// Whether byte `i` of string `s` starts a UTF-8 codepoint (it is not a
/// `10xxxxxx` continuation byte).
fn leadByte(comptime i: []const u8) [7]Instr {
    return .{ get("s"), get(i), op("add"), load8(4), c32(192), op("and"), c32(128) };
}

/// `s` cut at every `sep`, as an array of fresh strings. An empty `sep` cuts
/// before every UTF-8 codepoint (`"%0Aéz"` → 5 pieces, as on the other
/// targets); `""` answers no piece.
const str_split = func("__str_split", &.{ "s", "sep" }, .i32, i32s(&.{ "n", "m", "i", "cnt", "arr", "start", "k" }), &([_]Instr{
    get("s"),   load(0),           set("n"),
    get("sep"), load(0),           set("m"),
    get("m"),   op("eqz"),
    when(&([_]Instr{loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ leadByte("i") ++ [_]Instr{
        op("ne"), when(&.{ get("cnt"), c32(1), op("add"), set("cnt") }), get("i"), c32(1), op("add"), set("i"), again,
    }))} ++ [_]Instr{ get("cnt"), call("__arr_new"), set("arr"), c32(1), set("i") } ++ [_]Instr{loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ leadByte("i") ++ [_]Instr{
        op("ne"), when(&(slot("arr", "k") ++ [_]Instr{ get("s"), get("start"), get("i"), call("__str_slice"), store(0), get("k"), c32(1), op("add"), set("k"), get("i"), set("start") })), get("i"), c32(1), op("add"), set("i"), again,
    }))} ++ [_]Instr{ get("n"), when(&(slot("arr", "k") ++ [_]Instr{ get("s"), get("start"), get("n"), call("__str_slice"), store(0) })), get("arr"), ret })),
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

/// `xs.lastIndexOf(x)`: `indexOf` walked from the last slot down.
const arr_last_index_of_i32 = func("__arr_last_index_of_i32", &.{ "xs", "x" }, .i32, i32s(&.{"i"}), &.{
    get("xs"), load(0), set("i"),
    loop(&([_]Instr{ get("i"), op("eqz"), brk, get("i"), c32(1), op("sub"), set("i") } ++ slot("xs", "i") ++ [_]Instr{
        load(0), get("x"), op("eq"), when(&.{ get("i"), ret }),
        again,
    })),
    c32(-1),
});

const arr_last_index_of_str = func("__arr_last_index_of_str", &.{ "xs", "x" }, .i32, i32s(&.{"i"}), &.{
    get("xs"), load(0), set("i"),
    loop(&([_]Instr{ get("i"), op("eqz"), brk, get("i"), c32(1), op("sub"), set("i") } ++ slot("xs", "i") ++ [_]Instr{
        load(0), get("x"), call("__str_eq"), when(&.{ get("i"), ret }),
        again,
    })),
    c32(-1),
});

// ── 1.0.11 `01-compiler/05-wasm` step 1: the primitive methods that trapped ──

/// Byte `i` of string `s`.
fn byteAt(comptime i: []const u8) [5]Instr {
    return .{ get("s"), get(i), op("add"), load8(4), set("ch") };
}

/// `s.lines()`: `s` cut at every `\n`, a `\r` right before it dropped with
/// it — the `/\r?\n/` split node answers and the `[<<"\r\n">>, <<"\n">>]`
/// one erlang answers. The last piece keeps a trailing `\r` (nothing follows
/// it), and `""` is one empty line.
const str_lines = func("__str_lines", &.{"s"}, .i32, i32s(&.{ "n", "i", "cnt", "arr", "start", "k", "e", "ch" }), &([_]Instr{
    get("s"),   load(0),           set("n"),   c32(1), set("cnt"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ byteAt("i") ++ [_]Instr{
        get("ch"), c32(10), op("eq"),  when(&.{ get("cnt"), c32(1), op("add"), set("cnt") }),
        get("i"),  c32(1),  op("add"), set("i"),
        again,
    })),
    get("cnt"), call("__arr_new"), set("arr"), c32(0), set("i"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ byteAt("i") ++ [_]Instr{
        get("ch"), c32(10), op("eq"),
        when(&([_]Instr{
            get("i"),   set("e"),
            get("e"),   get("start"),
            op("gt_u"), when(&.{ get("s"), get("e"), op("add"), load8(3), c32(13), op("eq"), when(&.{ get("e"), c32(1), op("sub"), set("e") }) }),
        } ++ slot("arr", "k") ++ [_]Instr{
            get("s"), get("start"), get("e"),     call("__str_slice"), store(0),
            get("k"), c32(1),       op("add"),    set("k"),            get("i"),
            c32(1),   op("add"),    set("start"),
        })),
        get("i"),  c32(1),  op("add"),
        set("i"),  again,
    })),
} ++ slot("arr", "k") ++ [_]Instr{ get("s"), get("start"), get("n"), call("__str_slice"), store(0), get("arr") }));

/// `s.words()`: the maximal runs of bytes that are not ` `, `\t`, `\n` or
/// `\r`, as fresh strings — `""` and an all-blank string answer none.
const str_words = func("__str_words", &.{"s"}, .i32, i32s(&.{ "n", "i", "cnt", "arr", "start", "k", "inw", "ch" }), &([_]Instr{
    get("s"),   load(0),                                                                                                  set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ byteAt("i") ++ isSpace("ch") ++ [_]Instr{
        whenElse(&.{ c32(0), set("inw") }, &.{ get("inw"), op("eqz"), when(&.{ get("cnt"), c32(1), op("add"), set("cnt"), c32(1), set("inw") }) }),
        get("i"),
        c32(1),
        op("add"),
        set("i"),
        again,
    })),
    get("cnt"), call("__arr_new"),                                                                                        set("arr"),
    c32(0),     set("i"),                                                                                                 c32(0),
    set("inw"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ byteAt("i") ++ isSpace("ch") ++ [_]Instr{
        whenElse(&.{ get("inw"), when(&(slot("arr", "k") ++ [_]Instr{
            get("s"),   get("start"), get("i"),  call("__str_slice"), store(0),
            get("k"),   c32(1),       op("add"), set("k"),            c32(0),
            set("inw"),
        })) }, &.{ get("inw"), op("eqz"), when(&.{ get("i"), set("start"), c32(1), set("inw") }) }),
        get("i"),
        c32(1),
        op("add"),
        set("i"),
        again,
    })),
    get("inw"), when(&(slot("arr", "k") ++ [_]Instr{ get("s"), get("start"), get("n"), call("__str_slice"), store(0) })), get("arr"),
}));

/// The `f64` a float slot's cell holds, as its bits (`i64.load`): decision
/// 214's `==` over floats is a total order (`Object.is` on commonJS), which
/// is the bits' equality.
const load_cell_bits: [2]Instr = .{ load(0), .{ .load = .{ .ty = .i64 } } };

/// `xs.unique()` — consecutive duplicates dropped, as `primitives.bp`'s body
/// does: element `i` is kept when it differs from element `i - 1`. `mode`
/// names the equality: `0` the slot's word (an integer, a bool, an all-unit
/// enum's ordinal), `1` the `f64` the slot's cell holds (`$__box_f64`), by
/// its bits, `2` a string's content.
const arr_unique = func("__arr_unique", &.{ "xs", "mode" }, .i32, i32s(&.{ "n", "i", "k", "out", "keep", "b" }), &([_]Instr{
    get("xs"),  load(0),  set("n"), get("n"),   call("__arr_new"), set("out"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, c32(1), set("keep"), get("i") } ++ [_]Instr{
        when(&([_]Instr{ get("i"), c32(1), op("sub"), set("b"), get("mode"), c32(1), op("eq") } ++ [_]Instr{
            whenElse(
                &(slot("xs", "i") ++ load_cell_bits ++ slot("xs", "b") ++ load_cell_bits ++ [_]Instr{ op64("ne"), set("keep") }),
                &([_]Instr{ get("mode"), c32(2), op("eq") } ++ [_]Instr{whenElse(
                    &(slot("xs", "i") ++ [_]Instr{load(0)} ++ slot("xs", "b") ++ [_]Instr{ load(0), call("__str_eq"), op("eqz"), set("keep") }),
                    &(slot("xs", "i") ++ [_]Instr{load(0)} ++ slot("xs", "b") ++ [_]Instr{ load(0), op("ne"), set("keep") }),
                )}),
            ),
        })),
        get("keep"),
        when(&(slot("out", "k") ++ slot("xs", "i") ++ [_]Instr{ load(0), store(0), get("k"), c32(1), op("add"), set("k") })),
        get("i"),
        c32(1),
        op("add"),
        set("i"),
        again,
    })),
    get("out"), get("k"), store(0), get("out"),
}));

/// `xs.flatten()` / `xs.flat()` over an array of arrays: every inner array's
/// slots, in order, in one fresh array.
const arr_flatten = func("__arr_flatten", &.{"xs"}, .i32, i32s(&.{ "n", "i", "total", "out", "pos", "e" }), &([_]Instr{
    get("xs"),    load(0),           set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk, get("total") } ++ slot("xs", "i") ++ [_]Instr{
        load(0), load(0), op("add"), set("total"), get("i"), c32(1), op("add"), set("i"), again,
    })),
    get("total"), call("__arr_new"), set("out"),
    get("out"),   c32(4),            op("add"),
    set("pos"),   c32(0),            set("i"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("xs", "i") ++ [_]Instr{
        load(0),    set("e"),
        get("pos"), get("e"),
        c32(4),     op("add"),
        get("e"),   load(0),
        c32(4),     op("mul"),
        copy,       get("pos"),
        get("e"),   load(0),
        c32(4),     op("mul"),
        op("add"),  set("pos"),
        get("i"),   c32(1),
        op("add"),  set("i"),
        again,
    })),
    get("out"),
}));

/// `xs.chunked(m)`: consecutive slices of `m` elements, the last one shorter
/// when `m` does not divide the length; `m <= 0` answers no chunk.
const arr_chunked = func("__arr_chunked", &.{ "xs", "m" }, .i32, i32s(&.{ "n", "cnt", "out", "k" }), &([_]Instr{
    get("m"),          c32(0),      op("le_s"),                                            when(&.{ c32(0), call("__arr_new"), ret }),
    get("xs"),         load(0),     set("n"),                                              get("n"),
    get("m"),          op("div_u"), set("cnt"),                                            get("n"),
    get("m"),          op("rem_u"), when(&.{ get("cnt"), c32(1), op("add"), set("cnt") }), get("cnt"),
    call("__arr_new"), set("out"),
    loop(&([_]Instr{ get("k"), get("cnt"), op("ge_u"), brk } ++ slot("out", "k") ++ [_]Instr{
        get("xs"), get("k"), get("m"),  op("mul"), get("k"), get("m"), op("mul"), get("m"), op("add"), call("__arr_slice"), store(0),
        get("k"),  c32(1),   op("add"), set("k"),  again,
    })),
    get("out"),
}));

/// `xs.sliding(m)`: one slice of `m` elements per start offset
/// (`len - m + 1` of them); `m <= 0` or `m > len` answers none.
const arr_sliding = func("__arr_sliding", &.{ "xs", "m" }, .i32, i32s(&.{ "cnt", "out", "k" }), &([_]Instr{
    get("m"),          c32(0),     op("le_s"),                                 when(&.{ c32(0), call("__arr_new"), ret }),
    get("xs"),         load(0),    get("m"),                                   op("sub"),
    c32(1),            op("add"),  set("cnt"),                                 get("cnt"),
    c32(0),            op("le_s"), when(&.{ c32(0), call("__arr_new"), ret }), get("cnt"),
    call("__arr_new"), set("out"),
    loop(&([_]Instr{ get("k"), get("cnt"), op("ge_u"), brk } ++ slot("out", "k") ++ [_]Instr{
        get("xs"), get("k"), get("k"),  get("m"), op("add"), call("__arr_slice"), store(0),
        get("k"),  c32(1),   op("add"), set("k"), again,
    })),
    get("out"),
}));

/// `xs.fill(v)` — `Array.repeat(v, xs.length)`: `n` slots each holding the
/// word `v` (a float arrives as its `f32` bits).
const arr_fill = func("__arr_fill", &.{ "n", "v" }, .i32, i32s(&.{ "out", "i" }), &([_]Instr{
    get("n"),   call("__arr_new"), set("out"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_s"), brk } ++ slot("out", "i") ++ [_]Instr{
        get("v"), store(0), get("i"), c32(1), op("add"), set("i"), again,
    })),
    get("out"),
}));

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

/// The text a float **concatenated into a string** takes (`"x" + 0.1`,
/// `x.toString()`), as a fresh string: JavaScript's `Number#toString` — the
/// shortest decimal that reads back as the same `f64` (`0.30000000000000004`,
/// `1e+21`, `5e-324`, `5` for `5.0`), what commonJS answers for the same value.
/// It wrote an integer part and six fraction digits, and trapped on a float
/// past `2^31`.
const f64_to_str = typedFunc("__f64_to_str", &.{.{ .name = "x", .ty = .f64 }}, .i32, i32s(&.{ "n", "p" }), &.{
    getF("x"),      c32(0),    call("__f64_fmt"), set("n"),
    get("n"),       c32(4),    op("add"),         call("__alloc"),
    set("p"),       get("p"),  get("n"),          store(0),
    get("p"),       c32(4),    op("add"),         call("__dtoa_ws"),
    c32(dtoa_text), op("add"), get("n"),          copy,
    get("p"),
});

// ── an f64 as text: V8's `BignumDtoa`, shortest mode ─────────────────────────
//
// commonJS prints a float as `Number.isInteger(v) ? v.toFixed(1) : String(v)`
// and concatenates it as `String(v)`. `String(v)` is the shortest digit string
// that reads back as `v`, the closest such when several are as short, a tie
// going to the even digit — what V8's `bignum-dtoa.cc` computes, transcribed
// here step for step over 40-limb (1280-bit) unsigned integers, enough for the
// widest scaled value (`5e-324`'s denominator is `2^1076`). The workspace is
// allocated once (`$__dtoa_ws`), so printing a float allocates nothing:
//
//     0 numerator · 160 denominator · 320 delta− · 480 delta+ · 640 a temporary
//     800 the decimal point (i32) · 804 the digits · 832 the text · 896..920 an
//     integer's digits, written backwards

const big_bytes = 160;
const dtoa_point = 800;
const dtoa_digits = 804;
const dtoa_text = 832;
const dtoa_ws_bytes = 920;

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
/// `a *= m` — a bignum by a word.
fn bigMul(comptime a: []const u8, comptime m: comptime_int) [3]Instr {
    return .{ get(a), c64(m), call("__big_mul") };
}
/// The text cursor `q` writes `ch` and steps.
fn putc(comptime ch: comptime_int) [7]Instr {
    return .{ get("q"), c32(ch), store8(0), get("q"), c32(1), op("add"), set("q") };
}

const dtoa_ws_global = ast.Global{ .name = "__dtoa_ws", .ty = .i32, .mutable = true, .init = "0" };

const dtoa_ws = func("__dtoa_ws", &.{}, .i32, &.{}, &.{
    .{ .global_get = "__dtoa_ws" },                                                  op("eqz"),
    when(&.{ c32(dtoa_ws_bytes), call("__alloc"), .{ .global_set = "__dtoa_ws" } }), .{ .global_get = "__dtoa_ws" },
});

/// `a = v`.
const big_set = typedFunc("__big_set", &.{ p32("a"), p64("v") }, null, &.{l32("i")}, &.{
    loop(&.{ get("i"), c32(big_bytes), op("ge_u"), brk, get("a"), get("i"), op("add"), c32(0), store(0), get("i"), c32(4), op("add"), set("i"), again }),
    get("a"),
    get("v"),
    cv("i32.wrap_i64"),
    store(0),
    get("a"),
    get("v"),
    c64(32),
    op64("shr_u"),
    cv("i32.wrap_i64"),
    store(4),
});

/// `a *= m`, `m < 2^32`.
const big_mul = typedFunc("__big_mul", &.{ p32("a"), p64("m") }, null, &.{ l32("i"), l64("t"), l64("c") }, &.{
    loop(&.{
        get("i"),               c32(big_bytes), op("ge_u"),         brk,
        get("a"),               get("i"),       op("add"),          load(0),
        cv("i64.extend_i32_u"), get("m"),       op64("mul"),        get("c"),
        op64("add"),            set("t"),       get("a"),           get("i"),
        op("add"),              get("t"),       cv("i32.wrap_i64"), store(0),
        get("t"),               c64(32),        op64("shr_u"),      set("c"),
        get("i"),               c32(4),         op("add"),          set("i"),
        again,
    }),
});

/// `a += b`.
const big_add = func("__big_add", &.{ "a", "b" }, null, &.{ l32("i"), l64("t"), l64("c") }, &.{
    loop(&.{
        get("i"),               c32(big_bytes),         op("ge_u"),         brk,
        get("a"),               get("i"),               op("add"),          load(0),
        cv("i64.extend_i32_u"), get("b"),               get("i"),           op("add"),
        load(0),                cv("i64.extend_i32_u"), op64("add"),        get("c"),
        op64("add"),            set("t"),               get("a"),           get("i"),
        op("add"),              get("t"),               cv("i32.wrap_i64"), store(0),
        get("t"),               c64(32),                op64("shr_u"),      set("c"),
        get("i"),               c32(4),                 op("add"),          set("i"),
        again,
    }),
});

/// `a -= b`, `a >= b`. A negative difference borrows: its sign bit is the borrow.
const big_sub = func("__big_sub", &.{ "a", "b" }, null, &.{ l32("i"), l64("t"), l64("c") }, &.{
    loop(&.{
        get("i"),               c32(big_bytes),         op("ge_u"),         brk,
        get("a"),               get("i"),               op("add"),          load(0),
        cv("i64.extend_i32_u"), get("b"),               get("i"),           op("add"),
        load(0),                cv("i64.extend_i32_u"), op64("sub"),        get("c"),
        op64("sub"),            set("t"),               get("a"),           get("i"),
        op("add"),              get("t"),               cv("i32.wrap_i64"), store(0),
        get("t"),               c64(63),                op64("shr_u"),      set("c"),
        get("i"),               c32(4),                 op("add"),          set("i"),
        again,
    }),
});

/// `-1` / `0` / `1` as `a` is below, equal to or above `b`.
const big_cmp = func("__big_cmp", &.{ "a", "b" }, .i32, i32s(&.{ "i", "x", "y" }), &.{
    c32(big_bytes), set("i"),
    loop(&.{
        get("i"),                op("eqz"),  brk,
        get("i"),                c32(4),     op("sub"),
        set("i"),                get("a"),   get("i"),
        op("add"),               load(0),    set("x"),
        get("b"),                get("i"),   op("add"),
        load(0),                 set("y"),   get("x"),
        get("y"),                op("lt_u"), when(&.{ c32(-1), ret }),
        get("x"),                get("y"),   op("gt_u"),
        when(&.{ c32(1), ret }), again,
    }),
    c32(0),
});

/// `cmp(a + b, c)`, the sum built in `t`.
const big_pcmp = func("__big_pcmp", &.{ "a", "b", "c", "t" }, .i32, &.{}, &.{
    get("t"), get("a"),          c32(big_bytes),    copy,
    get("t"), get("b"),          call("__big_add"), get("t"),
    get("c"), call("__big_cmp"),
});

/// `a <<= n`.
const big_shl = func("__big_shl", &.{ "a", "n" }, null, &.{}, &.{
    loop(&.{ get("n"), c32(31), op("lt_s"), brk, get("a"), c64(2147483648), call("__big_mul"), get("n"), c32(31), op("sub"), set("n"), again }),
    get("a"),
    c64(1),
    get("n"),
    cv("i64.extend_i32_u"),
    op64("shl"),
    call("__big_mul"),
});

/// `a *= 10^n`.
const big_pow10 = func("__big_pow10", &.{ "a", "n" }, null, &.{}, &.{
    loop(&.{ get("n"), c32(9), op("lt_s"), brk, get("a"), c64(1000000000), call("__big_mul"), get("n"), c32(9), op("sub"), set("n"), again }),
    loop(&.{ get("n"), op("eqz"), brk, get("a"), c64(10), call("__big_mul"), get("n"), c32(1), op("sub"), set("n"), again }),
});

/// The shortest digits of a finite `v > 0` (V8's `BignumDtoa`, shortest mode):
/// the digits at `dtoa_digits`, their count answered, the decimal point at
/// `dtoa_point` — `v = 0.d1d2… × 10^point`.
const dtoa = typedFunc("__dtoa", &.{.{ .name = "v", .ty = .f64 }}, .i32, &.{
    l32("w"),    l32("n"),    l32("d"),  l32("m"),   l32("p"),   l32("t"),  l32("bexp"), l32("e"),  l32("ne"),
    l32("near"), l32("even"), l32("k"),  l32("len"), l32("dig"), l32("lo"), l32("hi"),   l32("cc"), l64("bits"),
    l64("mant"), l64("f"),    l64("nf"),
}, &.{
    call("__dtoa_ws"),       tee("w"),                                                                                                                  set("n"),
    get("w"),                c32(big_bytes),                                                                                                            op("add"),
    set("d"),                get("w"),                                                                                                                  c32(2 * big_bytes),
    op("add"),               set("m"),                                                                                                                  get("w"),
    c32(3 * big_bytes),      op("add"),                                                                                                                 set("p"),
    get("w"),                c32(4 * big_bytes),                                                                                                        op("add"),
    set("t"),                getF("v"),                                                                                                                 cv("i64.reinterpret_f64"),
    set("bits"),             get("bits"),                                                                                                               c64(52),
    op64("shr_u"),           cv("i32.wrap_i64"),                                                                                                        c32(2047),
    op("and"),               set("bexp"),                                                                                                               get("bits"),
    c64(0xFFFFFFFFFFFFF),    op64("and"),                                                                                                               set("mant"),
    get("bexp"),             op("eqz"),
    whenElse(
        &.{ get("mant"), set("f"), c32(-1074), set("e") },
        &.{ get("mant"), c64(1 << 52), op64("or"), set("f"), get("bexp"), c32(1075), op("sub"), set("e") },
    ),
    // The lower boundary is half as far when `f` is a bare power of two above
    // the smallest normal; a tie reads back as `v` when `f` is even.
    get("mant"),             op64("eqz"),                                                                                                               get("bexp"),
    c32(1),                  op("gt_s"),                                                                                                                op("and"),
    set("near"),             get("f"),                                                                                                                  c64(1),
    op64("and"),             op64("eqz"),                                                                                                               set("even"),
    // `EstimatePower` over the normalised exponent: the decimal point, or one less.
    get("f"),                set("nf"),                                                                                                                 get("e"),
    set("ne"),
    loop(&.{
        get("nf"), c64(1 << 52), op64("and"), op64("eqz"), op("eqz"), brk,
        get("nf"), c64(1),       op64("shl"), set("nf"),   get("ne"), c32(1),
        op("sub"), set("ne"),    again,
    }),
    get("ne"),               c32(52),                                                                                                                   op("add"),
    cv("f64.convert_i32_s"), cF("0.30102999566398114"),                                                                                                 opF("mul"),
    cF("1e-10"),             opF("sub"),                                                                                                                opF("ceil"),
    cv("i32.trunc_f64_s"),   set("k"),
    // `InitialScaledStartValues`: numerator / denominator = v / 10^k, the
    // deltas the distance to each boundary, all doubled.
                                                                                                                     get("e"),
    c32(0),                  op("ge_s"),
    whenElse(&.{
        get("n"),          get("f"),          call("__big_set"), get("n"),          get("e"),          c32(1),              op("add"),         call("__big_shl"),
        get("d"),          c64(1),            call("__big_set"), get("d"),          get("k"),          call("__big_pow10"), get("d"),          c32(1),
        call("__big_shl"), get("p"),          c64(1),            call("__big_set"), get("p"),          get("e"),            call("__big_shl"), get("m"),
        c64(1),            call("__big_set"), get("m"),          get("e"),          call("__big_shl"),
    }, &.{
        get("k"), c32(0), op("ge_s"),
        whenElse(&.{
            get("n"), get("f"),          call("__big_set"), get("n"),  c32(1),            call("__big_shl"),
            get("d"), c64(1),            call("__big_set"), get("d"),  get("k"),          call("__big_pow10"),
            get("d"), c32(1),            get("e"),          op("sub"), call("__big_shl"), get("p"),
            c64(1),   call("__big_set"), get("m"),          c64(1),    call("__big_set"),
        }, &.{
            get("p"), c64(1),            call("__big_set"), get("p"),            c32(0),   get("k"),  op("sub"),         call("__big_pow10"),
            get("m"), get("p"),          c32(big_bytes),    copy,                get("n"), get("f"),  call("__big_set"), get("n"),
            c32(0),   get("k"),          op("sub"),         call("__big_pow10"), get("n"), c32(1),    call("__big_shl"), get("d"),
            c64(1),   call("__big_set"), get("d"),          c32(1),              get("e"), op("sub"), call("__big_shl"),
        }),
    }),
    get("near"),             when(&.{ get("n"), c32(1), call("__big_shl"), get("d"), c32(1), call("__big_shl"), get("p"), c32(1), call("__big_shl") }),
    // `FixupMultiply10`: the estimate was one short when numerator + delta+
    // already reaches the denominator.
    get("n"),
    get("p"),                get("d"),                                                                                                                  get("t"),
    call("__big_pcmp"),      get("even"),                                                                                                               op("add"),
    c32(0),                  op("gt_s"),                                                                                                                whenElse(&.{ get("k"), c32(1), op("add"), set("k") }, &(bigMul("n", 10) ++ bigMul("m", 10) ++ bigMul("p", 10))),
    // `GenerateShortestDigits`.
    loopAs("gbrk", "gcont", &([_]Instr{
        c32(0),                                                                                                                                                              set("dig"),
        loop(&.{ get("n"), get("d"), call("__big_cmp"), c32(0), op("lt_s"), brk, get("n"), get("d"), call("__big_sub"), get("dig"), c32(1), op("add"), set("dig"), again }), get("w"),
        c32(dtoa_digits),                                                                                                                                                    op("add"),
        get("len"),                                                                                                                                                          op("add"),
        get("dig"),                                                                                                                                                          c32('0'),
        op("add"),                                                                                                                                                           store8(0),
        get("len"),                                                                                                                                                          c32(1),
        op("add"),                                                                                                                                                           set("len"),
        get("n"),                                                                                                                                                            get("m"),
        call("__big_cmp"),                                                                                                                                                   get("even"),
        op("lt_s"),                                                                                                                                                          set("lo"),
        get("n"),                                                                                                                                                            get("p"),
        get("d"),                                                                                                                                                            get("t"),
        call("__big_pcmp"),                                                                                                                                                  get("even"),
        op("add"),                                                                                                                                                           c32(0),
        op("gt_s"),                                                                                                                                                          set("hi"),
        get("lo"),                                                                                                                                                           get("hi"),
        op("or"),                                                                                                                                                            .{ .br_if = "gbrk" },
    } ++ bigMul("n", 10) ++ bigMul("m", 10) ++ bigMul("p", 10) ++ [_]Instr{.{ .br = "gcont" }})),
    // Both boundaries in reach: round by the remainder, a tie to the even digit.
    get("lo"),               get("hi"),                                                                                                                 op("and"),
    when(&.{
        get("n"),  get("n"),  get("d"),   get("t"),  call("__big_pcmp"), set("cc"),
        get("cc"), c32(0),    op("gt_s"), get("cc"), op("eqz"),          get("dig"),
        c32(1),    op("and"), op("and"),  op("or"),  set("hi"),
    }),
    get("hi"),
    when(&.{
        get("w"), c32(dtoa_digits - 1), op("add"), get("len"), op("add"), tee("t"),
        get("t"), load8(0),             c32(1),    op("add"),  store8(0),
    }),
    get("w"),                get("k"),                                                                                                                  store(dtoa_point),
    get("len"),
});

/// The decimal digits of the unsigned `v` at `q`, zero-padded to `width`;
/// answers the address past them.
const fmt_u64 = typedFunc("__fmt_u64", &.{ p32("q"), p64("v"), p32("width") }, .i32, i32s(&.{ "t", "cnt" }), &.{
    call("__dtoa_ws"), c32(dtoa_ws_bytes), op("add"),  set("t"),
    loop(&.{
        get("t"),           c32(1),      op("sub"),     set("t"),
        get("t"),           get("v"),    c64(10),       op64("rem_u"),
        cv("i32.wrap_i64"), c32('0'),    op("add"),     store8(0),
        get("v"),           c64(10),     op64("div_u"), set("v"),
        get("cnt"),         c32(1),      op("add"),     set("cnt"),
        get("v"),           op64("eqz"), get("cnt"),    get("width"),
        op("ge_s"),         op("and"),   brk,           again,
    }),
    get("q"),          get("t"),           get("cnt"), copy,
    get("q"),          get("cnt"),         op("add"),
});

/// `x` as text at `dtoa_text`, its length answered. `mode` 0 is
/// `String(x)`; `mode` 1 is what `@print` writes on commonJS,
/// `Number.isInteger(x) ? x.toFixed(1) : String(x)` — a whole number below
/// `1e21` in all its digits and `.0` (`-0` is `0.0`), exact past `2^53`.
const f64_fmt = typedFunc("__f64_fmt", &.{ .{ .name = "x", .ty = .f64 }, p32("mode") }, .i32, &.{
    l32("w"), l32("q"), l32("len"), l32("pt"), l32("dig"), l32("i"), l32("e"), l64("bits"), l64("f"), l64("a"), l64("c"),
}, &.{
    call("__dtoa_ws"), tee("w"),     c32(dtoa_text),                                                    op("add"),                                                                                                                 set("q"),
    getF("x"),         getF("x"),    opF("ne"),                                                         when(&(putc('N') ++ putc('a') ++ putc('N') ++ [_]Instr{ get("q"), get("w"), c32(dtoa_text), op("add"), op("sub"), ret })), get("mode"),
    getF("x"),         opF("floor"), getF("x"),                                                         opF("eq"),                                                                                                                 op("and"),
    getF("x"),         opF("abs"),   cF("1e21"),                                                        opF("lt"),                                                                                                                 op("and"),
    when(&([_]Instr{
        getF("x"), cF("0"),                   opF("lt"), when(&(putc('-') ++ [_]Instr{ getF("x"), opF("neg"), set("x") })),
        getF("x"), cF("9223372036854775808"), opF("lt"),
        whenElse(&.{ get("q"), getF("x"), cv("i64.trunc_f64_s"), c32(1), call("__fmt_u64"), set("q") }, &.{
            // `f * 2^e` with `e <= 17`: split `f` at `10^10` so each half's
            // product stays below `2^64`.
            getF("x"),              cv("i64.reinterpret_f64"), set("bits"),
            get("bits"),            c64(0xFFFFFFFFFFFFF),      op64("and"),
            c64(1 << 52),           op64("or"),                set("f"),
            get("bits"),            c64(52),                   op64("shr_u"),
            cv("i32.wrap_i64"),     c32(1075),                 op("sub"),
            set("e"),               get("f"),                  c64(10000000000),
            op64("div_u"),          get("e"),                  cv("i64.extend_i32_u"),
            op64("shl"),            set("a"),                  get("f"),
            c64(10000000000),       op64("rem_u"),             get("e"),
            cv("i64.extend_i32_u"), op64("shl"),               set("c"),
            get("q"),               get("a"),                  get("c"),
            c64(10000000000),       op64("div_u"),             op64("add"),
            c32(1),                 call("__fmt_u64"),         set("q"),
            get("q"),               get("c"),                  c64(10000000000),
            op64("rem_u"),          c32(10),                   call("__fmt_u64"),
            set("q"),
        }),
    } ++ putc('.') ++ putc('0') ++ [_]Instr{ get("q"), get("w"), c32(dtoa_text), op("add"), op("sub"), ret })),
    getF("x"),         cF("0"),      opF("eq"),                                                         when(&(putc('0') ++ [_]Instr{ c32(1), ret })),                                                                             getF("x"),
    cF("0"),           opF("lt"),    when(&(putc('-') ++ [_]Instr{ getF("x"), opF("neg"), set("x") })), getF("x"),                                                                                                                 cF("inf"),
    opF("eq"),
    whenElse(&(putc('I') ++ putc('n') ++ putc('f') ++ putc('i') ++ putc('n') ++ putc('i') ++ putc('t') ++ putc('y')), &.{
        getF("x"),  call("__dtoa"),   set("len"),
        get("w"),   load(dtoa_point), set("pt"),
        get("w"),   c32(dtoa_digits), op("add"),
        set("dig"), get("len"),       get("pt"),
        op("le_s"), get("pt"),        c32(21),
        op("le_s"), op("and"),
        whenElse(&.{
            // `123000`
            get("q"),   get("dig"), get("len"),                                                                                                                         copy, get("q"), get("len"), op("add"), set("q"),
            get("len"), set("i"),   loop(&([_]Instr{ get("i"), get("pt"), op("ge_s"), brk } ++ putc('0') ++ [_]Instr{ get("i"), c32(1), op("add"), set("i"), again })),
        }, &.{
            get("pt"), c32(0), op("gt_s"), get("pt"), c32(21), op("le_s"), op("and"),
            whenElse(&([_]Instr{
                // `12.5`
                get("q"), get("dig"), get("pt"), copy, get("q"), get("pt"), op("add"), set("q"),
            } ++ putc('.') ++ [_]Instr{
                get("q"), get("dig"), get("pt"), op("add"), get("len"), get("pt"), op("sub"), copy,
                get("q"), get("len"), get("pt"), op("sub"), op("add"),  set("q"),
            }), &.{
                get("pt"), c32(-6), op("gt_s"), get("pt"), c32(0), op("le_s"), op("and"),
                whenElse(&(putc('0') ++ putc('.') ++ [_]Instr{
                    // `0.000125`
                    get("pt"),                                                                                                                       set("i"),
                    loop(&([_]Instr{ get("i"), c32(0), op("ge_s"), brk } ++ putc('0') ++ [_]Instr{ get("i"), c32(1), op("add"), set("i"), again })), get("q"),
                    get("dig"),                                                                                                                      get("len"),
                    copy,                                                                                                                            get("q"),
                    get("len"),                                                                                                                      op("add"),
                    set("q"),
                }), &([_]Instr{
                    // `1.25e+21`, `5e-324`
                    get("q"),   get("dig"), c32(1),     copy, get("q"), c32(1), op("add"), set("q"),
                    get("len"), c32(1),     op("gt_s"),
                    when(&(putc('.') ++ [_]Instr{
                        get("q"), get("dig"), c32(1), op("add"), get("len"), c32(1),   op("sub"), copy,
                        get("q"), get("len"), c32(1), op("sub"), op("add"),  set("q"),
                    })),
                } ++ putc('e') ++ [_]Instr{
                    get("pt"),         c32(1),   op("sub"),              set("i"),
                    get("i"),          c32(0),   op("lt_s"),             whenElse(&(putc('-') ++ [_]Instr{ c32(0), get("i"), op("sub"), set("i") }), &putc('+')),
                    get("q"),          get("i"), cv("i64.extend_i32_u"), c32(1),
                    call("__fmt_u64"), set("q"),
                })),
            }),
        }),
    }),
    get("q"),          get("w"),     c32(dtoa_text),                                                    op("add"),                                                                                                                 op("sub"),
});

/// The `i64` `v` as decimal text at `dtoa_text`, its length answered — a
/// `-` and the magnitude, which `$__fmt_u64` writes unsigned, so `-2^63`
/// (its own negation) prints whole.
const i64_fmt = typedFunc("__i64_fmt", &.{p64("v")}, .i32, i32s(&.{ "w", "q" }), &.{
    call("__dtoa_ws"), tee("w"),  c32(dtoa_text),    op("add"),                                                                 set("q"),
    get("v"),          c64(0),    op64("lt_s"),      when(&(putc('-') ++ [_]Instr{ c64(0), get("v"), op64("sub"), set("v") })), get("q"),
    get("v"),          c32(1),    call("__fmt_u64"), get("w"),                                                                  c32(dtoa_text),
    op("add"),         op("sub"),
});

const dtoa_items = [_]ast.Item{
    .{ .global = dtoa_ws_global }, .{ .func = dtoa_ws },   .{ .func = big_set }, .{ .func = big_mul },
    .{ .func = big_add },          .{ .func = big_sub },   .{ .func = big_cmp }, .{ .func = big_pcmp },
    .{ .func = big_shl },          .{ .func = big_pow10 }, .{ .func = dtoa },    .{ .func = fmt_u64 },
    .{ .func = f64_fmt },          .{ .func = i64_fmt },
};

// ── integer arithmetic that refuses to wrap ──────────────────────────────────
//
// commonJS and erlang never wrap an integer: `2147483647 + 1` is `2147483648`
// on both. wasm's `i32.add` wrapped it to `-2147483648` at exit 0. An `i32`
// `+`, `-`, `*` is computed in `i64` and checked back into the `i32` range;
// an `i64` one is checked by the signs (`+`, `-`) or by dividing back (`*`).
// A result the type cannot hold traps — the value the program asked for does
// not exist in its declared type.

fn chk32(comptime name: []const u8, comptime opname: []const u8) ast.Func {
    return func(name, &.{ "a", "b" }, .i32, &.{l64("r")}, &.{
        get("a"), cv("i64.extend_i32_s"), get("b"),               cv("i64.extend_i32_s"), op64(opname), set("r"),
        get("r"), cv("i32.wrap_i64"),     cv("i64.extend_i32_s"), get("r"),               op64("ne"),   when(&.{.@"unreachable"}),
        get("r"), cv("i32.wrap_i64"),
    });
}
const i32_add_chk = chk32("__i32_add_chk", "add");
const i32_sub_chk = chk32("__i32_sub_chk", "sub");
const i32_mul_chk = chk32("__i32_mul_chk", "mul");

const i64_add_chk = typedFunc("__i64_add_chk", &.{ p64("a"), p64("b") }, .i64, &.{l64("r")}, &.{
    get("a"),     get("b"),                  op64("add"), set("r"),
    // overflow iff both operands differ in sign from the result
    get("a"),     get("r"),                  op64("xor"), get("b"),
    get("r"),     op64("xor"),               op64("and"), c64(0),
    op64("lt_s"), when(&.{.@"unreachable"}), get("r"),
});
const i64_sub_chk = typedFunc("__i64_sub_chk", &.{ p64("a"), p64("b") }, .i64, &.{l64("r")}, &.{
    get("a"),     get("b"),                  op64("sub"), set("r"),
    // overflow iff the operands differ in sign and the result's sign is `b`'s
    get("a"),     get("b"),                  op64("xor"), get("a"),
    get("r"),     op64("xor"),               op64("and"), c64(0),
    op64("lt_s"), when(&.{.@"unreachable"}), get("r"),
});
const i64_mul_chk = typedFunc("__i64_mul_chk", &.{ p64("a"), p64("b") }, .i64, &.{l64("r")}, &.{
    get("a"),                  c64(-1),                                                                                        op64("eq"), get("b"),    c64(-9223372036854775808), op64("eq"), op("and"),
    when(&.{.@"unreachable"}), get("a"),                                                                                       get("b"),   op64("mul"), set("r"),                  get("a"),   op64("eqz"),
    op("eqz"),                 when(&.{ get("r"), get("a"), op64("div_s"), get("b"), op64("ne"), when(&.{.@"unreachable"}) }), get("r"),
});

const int_chk_items = [_]ast.Item{
    .{ .func = i32_add_chk }, .{ .func = i32_sub_chk }, .{ .func = i32_mul_chk },
    .{ .func = i64_add_chk }, .{ .func = i64_sub_chk }, .{ .func = i64_mul_chk },
};

/// An `i64` printed in all its digits. It was lowered as an `i32`:
/// `val a: i64 = 4294967295` printed `-1`.
const print_i64_raw = typedFunc("__print_i64_raw", &.{p64("v")}, null, i32s(&.{"n"}), &.{
    get("v"),       call("__i64_fmt"), set("n"), call("__dtoa_ws"),
    c32(dtoa_text), op("add"),         get("n"), call("__write_bytes"),
});
const print_i64 = typedFunc("__print_i64", &.{p64("v")}, null, &.{}, &.{ get("v"), call("__print_i64_raw"), call("__print_nl") });

/// An `i64` as a fresh string — `"n" + v`, `v.toString()`.
const i64_to_str = typedFunc("__i64_to_str", &.{p64("v")}, .i32, i32s(&.{ "n", "p" }), &.{
    get("v"),        call("__i64_fmt"), set("n"),
    get("n"),        c32(4),            op("add"),
    call("__alloc"), set("p"),          get("p"),
    get("n"),        store(0),          get("p"),
    c32(4),          op("add"),         call("__dtoa_ws"),
    c32(dtoa_text),  op("add"),         get("n"),
    copy,            get("p"),
});

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

/// `xs.indexOf(x)` / `xs.lastIndexOf(x)` over a float array: native
/// `Array#indexOf`'s strict equality (`f64.eq` — `NaN` is never found, `-0`
/// finds `0`), what commonJS answers.
const arr_index_of_f64 = typedFunc("__arr_index_of_f64", &.{ p32("xs"), .{ .name = "x", .ty = .f64 } }, .i32, i32s(&.{ "n", "i" }), &.{
    get("xs"), load(0), set("n"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("xs", "i") ++ [_]Instr{
        load(0),  .{ .load = .{ .ty = .f64 } }, getF("x"), opF("eq"), when(&.{ get("i"), ret }),
        get("i"), c32(1),                       op("add"), set("i"),  again,
    })),
    c32(-1),
});
const arr_last_index_of_f64 = typedFunc("__arr_last_index_of_f64", &.{ p32("xs"), .{ .name = "x", .ty = .f64 } }, .i32, i32s(&.{"i"}), &.{
    get("xs"), load(0), set("i"),
    loop(&([_]Instr{ get("i"), op("eqz"), brk, get("i"), c32(1), op("sub"), set("i") } ++ slot("xs", "i") ++ [_]Instr{
        load(0), .{ .load = .{ .ty = .f64 } }, getF("x"), opF("eq"), when(&.{ get("i"), ret }),
        again,
    })),
    c32(-1),
});

/// `xs.join(sep)` over a float array: each element as `String(x)` — the text
/// `$__f64_to_str` writes, as `Array#join` does on commonJS.
const arr_join_f64 = func("__arr_join_f64", &.{ "xs", "sep" }, .i32, i32s(&.{ "n", "i", "t" }), &.{
    get("xs"), load(0),           set("n"),
    get("n"),  call("__arr_new"), set("t"),
    loop(&([_]Instr{ get("i"), get("n"), op("ge_u"), brk } ++ slot("t", "i") ++ slot("xs", "i") ++ [_]Instr{
        load(0),  .{ .load = .{ .ty = .f64 } }, call("__f64_to_str"), store(0),
        get("i"), c32(1),                       op("add"),            set("i"),
        again,
    })),
    get("t"),  get("sep"),        call("__arr_join_str"),
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
/// shape (semantics decision 1a). Shape codes: `i` an i32, `b` a bool, `f` an
/// f32 slot, `s` a string (quoted), `[X` an array of `X` — `[e1, e2]` —,
/// `(XY…)` a tuple — `#(e1, e2)` —, and `E k [ <n> Enum.Variant ] * k` a value
/// of an all-unit enum, whose ordinal picks one of the `k` names. With `go` =
/// 0 nothing is written and nothing is read through `v`: the call only
/// measures a shape, which is how an array finds the end of its element shape
/// when it has no element.
const print_shaped_raw = func("__print_shaped_raw", &.{ "v", "sh", "go" }, .i32, i32s(&.{ "c", "n", "i", "p", "e" }), &.{
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
    // `l`: a record's `i64` field, the address of its cell (`$__box_i64`).
    get("c"),                                                                                                   c32('l'),                                                                                                   op("eq"),
    when(&.{
        get("go"),
        when(&.{ get("v"), .{ .load = .{ .ty = .i64 } }, call("__print_i64_raw") }),
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
});

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
