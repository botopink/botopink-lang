//! The OTP functions and BIFs std-wasm serves over Erlang terms (decision
//! 450): each `module:name/arity` and the runtime export (`rt_*`) that answers
//! it — the one table the comptime runtime's lowering
//! (`compiler-core/src/comptime/runtime/wat/lower.zig`) and beam-to-wasm
//! (`modules/beam-to-wasm`, decision 438 (2)) bind a call by. The
//! implementations are `otp/*.zig` over `term.zig`; std-wasm's `program`
//! side (decision 454): no `std:` cell names them.
const std = @import("std");
const root = @import("root.zig");

pub const erlang = @import("otp/erlang.zig");
pub const lists = @import("otp/lists.zig");
pub const maps = @import("otp/maps.zig");
pub const string = @import("otp/string.zig");
pub const binary = @import("otp/binary.zig");
pub const unicode = @import("otp/unicode.zig");
pub const math = @import("otp/math.zig");
pub const io_lib = @import("otp/io_lib.zig");
pub const json = @import("otp/json.zig");
pub const etf = @import("otp/etf.zig");

/// `module:name/arity` → the runtime export that answers it.
pub const Bif = struct { module: []const u8, name: []const u8, arity: u32, rt: []const u8 };

pub const table = [_]Bif{
    // erlang
    .{ .module = "erlang", .name = "element", .arity = 2, .rt = "rt_erlang_element" },
    .{ .module = "erlang", .name = "setelement", .arity = 3, .rt = "rt_erlang_setelement" },
    .{ .module = "erlang", .name = "tuple_size", .arity = 1, .rt = "rt_erlang_tuple_size" },
    .{ .module = "erlang", .name = "size", .arity = 1, .rt = "rt_erlang_tuple_size" },
    .{ .module = "erlang", .name = "tuple_to_list", .arity = 1, .rt = "rt_erlang_tuple_to_list" },
    .{ .module = "erlang", .name = "list_to_tuple", .arity = 1, .rt = "rt_erlang_list_to_tuple" },
    .{ .module = "erlang", .name = "length", .arity = 1, .rt = "rt_erlang_length" },
    .{ .module = "erlang", .name = "hd", .arity = 1, .rt = "rt_erlang_hd" },
    .{ .module = "erlang", .name = "tl", .arity = 1, .rt = "rt_erlang_tl" },
    .{ .module = "erlang", .name = "byte_size", .arity = 1, .rt = "rt_erlang_byte_size" },
    .{ .module = "erlang", .name = "map_size", .arity = 1, .rt = "rt_erlang_map_size" },
    .{ .module = "erlang", .name = "abs", .arity = 1, .rt = "rt_erlang_abs" },
    .{ .module = "erlang", .name = "max", .arity = 2, .rt = "rt_erlang_max" },
    .{ .module = "erlang", .name = "min", .arity = 2, .rt = "rt_erlang_min" },
    .{ .module = "erlang", .name = "round", .arity = 1, .rt = "rt_erlang_round" },
    .{ .module = "erlang", .name = "trunc", .arity = 1, .rt = "rt_erlang_trunc" },
    .{ .module = "erlang", .name = "floor", .arity = 1, .rt = "rt_erlang_floor" },
    .{ .module = "erlang", .name = "ceil", .arity = 1, .rt = "rt_erlang_ceil" },
    .{ .module = "erlang", .name = "float", .arity = 1, .rt = "rt_erlang_float" },
    .{ .module = "erlang", .name = "integer_to_binary", .arity = 1, .rt = "rt_erlang_integer_to_binary" },
    .{ .module = "erlang", .name = "integer_to_list", .arity = 1, .rt = "rt_erlang_integer_to_list" },
    .{ .module = "erlang", .name = "binary_to_integer", .arity = 1, .rt = "rt_erlang_binary_to_integer" },
    .{ .module = "erlang", .name = "list_to_integer", .arity = 1, .rt = "rt_erlang_list_to_integer" },
    .{ .module = "erlang", .name = "atom_to_binary", .arity = 1, .rt = "rt_erlang_atom_to_binary" },
    .{ .module = "erlang", .name = "atom_to_binary", .arity = 2, .rt = "rt_erlang_atom_to_binary2" },
    .{ .module = "erlang", .name = "atom_to_list", .arity = 1, .rt = "rt_erlang_atom_to_list" },
    .{ .module = "erlang", .name = "binary_to_atom", .arity = 1, .rt = "rt_erlang_binary_to_atom" },
    .{ .module = "erlang", .name = "binary_to_atom", .arity = 2, .rt = "rt_erlang_binary_to_atom2" },
    .{ .module = "erlang", .name = "binary_to_existing_atom", .arity = 1, .rt = "rt_erlang_binary_to_atom" },
    .{ .module = "erlang", .name = "binary_to_existing_atom", .arity = 2, .rt = "rt_erlang_binary_to_atom2" },
    .{ .module = "erlang", .name = "list_to_atom", .arity = 1, .rt = "rt_erlang_list_to_atom" },
    .{ .module = "erlang", .name = "binary_to_list", .arity = 1, .rt = "rt_erlang_binary_to_list" },
    .{ .module = "erlang", .name = "iolist_to_binary", .arity = 1, .rt = "rt_erlang_iolist_to_binary" },
    .{ .module = "erlang", .name = "list_to_binary", .arity = 1, .rt = "rt_erlang_list_to_binary" },
    .{ .module = "erlang", .name = "iolist_size", .arity = 1, .rt = "rt_erlang_iolist_size" },
    .{ .module = "erlang", .name = "float_to_binary", .arity = 1, .rt = "rt_erlang_float_to_binary" },
    .{ .module = "erlang", .name = "float_to_binary", .arity = 2, .rt = "rt_erlang_float_to_binary2" },
    .{ .module = "erlang", .name = "float_to_list", .arity = 2, .rt = "rt_erlang_float_to_list2" },
    .{ .module = "erlang", .name = "is_atom", .arity = 1, .rt = "rt_erlang_is_atom" },
    .{ .module = "erlang", .name = "is_binary", .arity = 1, .rt = "rt_erlang_is_binary" },
    .{ .module = "erlang", .name = "is_bitstring", .arity = 1, .rt = "rt_erlang_is_binary" },
    .{ .module = "erlang", .name = "is_integer", .arity = 1, .rt = "rt_erlang_is_integer" },
    .{ .module = "erlang", .name = "is_float", .arity = 1, .rt = "rt_erlang_is_float" },
    .{ .module = "erlang", .name = "is_number", .arity = 1, .rt = "rt_erlang_is_number" },
    .{ .module = "erlang", .name = "is_list", .arity = 1, .rt = "rt_erlang_is_list" },
    .{ .module = "erlang", .name = "is_tuple", .arity = 1, .rt = "rt_erlang_is_tuple" },
    .{ .module = "erlang", .name = "is_map", .arity = 1, .rt = "rt_erlang_is_map" },
    .{ .module = "erlang", .name = "is_map_key", .arity = 2, .rt = "rt_maps_is_key" },
    .{ .module = "erlang", .name = "is_function", .arity = 1, .rt = "rt_erlang_is_function" },
    .{ .module = "erlang", .name = "fun_info", .arity = 2, .rt = "rt_erlang_fun_info2" },
    .{ .module = "erlang", .name = "is_boolean", .arity = 1, .rt = "rt_erlang_is_boolean" },
    .{ .module = "erlang", .name = "put", .arity = 2, .rt = "rt_erlang_put" },
    .{ .module = "erlang", .name = "get", .arity = 1, .rt = "rt_erlang_get" },
    .{ .module = "erlang", .name = "erase", .arity = 1, .rt = "rt_erlang_erase" },
    .{ .module = "erlang", .name = "apply", .arity = 2, .rt = "rt_erlang_apply" },
    .{ .module = "erlang", .name = "throw", .arity = 1, .rt = "rt_throw" },
    .{ .module = "erlang", .name = "error", .arity = 1, .rt = "rt_error" },
    .{ .module = "erlang", .name = "exit", .arity = 1, .rt = "rt_exit" },
    .{ .module = "erlang", .name = "not", .arity = 1, .rt = "rt_not" },
    // lists
    .{ .module = "lists", .name = "map", .arity = 2, .rt = "rt_lists_map" },
    .{ .module = "lists", .name = "foreach", .arity = 2, .rt = "rt_lists_foreach" },
    .{ .module = "lists", .name = "filter", .arity = 2, .rt = "rt_lists_filter" },
    .{ .module = "lists", .name = "foldl", .arity = 3, .rt = "rt_lists_foldl" },
    .{ .module = "lists", .name = "foldr", .arity = 3, .rt = "rt_lists_foldr" },
    .{ .module = "lists", .name = "any", .arity = 2, .rt = "rt_lists_any" },
    .{ .module = "lists", .name = "all", .arity = 2, .rt = "rt_lists_all" },
    .{ .module = "lists", .name = "reverse", .arity = 1, .rt = "rt_lists_reverse" },
    .{ .module = "lists", .name = "reverse", .arity = 2, .rt = "rt_lists_reverse2" },
    .{ .module = "lists", .name = "append", .arity = 1, .rt = "rt_lists_append1" },
    .{ .module = "lists", .name = "append", .arity = 2, .rt = "rt_lists_append2" },
    .{ .module = "lists", .name = "join", .arity = 2, .rt = "rt_lists_join" },
    .{ .module = "lists", .name = "member", .arity = 2, .rt = "rt_lists_member" },
    .{ .module = "lists", .name = "nth", .arity = 2, .rt = "rt_lists_nth" },
    .{ .module = "lists", .name = "nthtail", .arity = 2, .rt = "rt_lists_nthtail" },
    .{ .module = "lists", .name = "sublist", .arity = 2, .rt = "rt_lists_sublist2" },
    .{ .module = "lists", .name = "sublist", .arity = 3, .rt = "rt_lists_sublist3" },
    .{ .module = "lists", .name = "duplicate", .arity = 2, .rt = "rt_lists_duplicate" },
    .{ .module = "lists", .name = "seq", .arity = 2, .rt = "rt_lists_seq" },
    .{ .module = "lists", .name = "zipwith", .arity = 3, .rt = "rt_lists_zipwith" },
    .{ .module = "lists", .name = "last", .arity = 1, .rt = "rt_lists_last" },
    .{ .module = "lists", .name = "enumerate", .arity = 1, .rt = "rt_lists_enumerate1" },
    .{ .module = "lists", .name = "enumerate", .arity = 2, .rt = "rt_lists_enumerate2" },
    .{ .module = "lists", .name = "flatten", .arity = 1, .rt = "rt_lists_flatten" },
    .{ .module = "lists", .name = "sort", .arity = 1, .rt = "rt_lists_sort" },
    .{ .module = "lists", .name = "usort", .arity = 1, .rt = "rt_lists_usort" },
    .{ .module = "lists", .name = "keyfind", .arity = 3, .rt = "rt_lists_keyfind" },
    .{ .module = "lists", .name = "concat", .arity = 1, .rt = "rt_lists_concat" },
    // maps
    .{ .module = "maps", .name = "get", .arity = 2, .rt = "rt_maps_get" },
    .{ .module = "maps", .name = "get", .arity = 3, .rt = "rt_maps_get3" },
    .{ .module = "maps", .name = "find", .arity = 2, .rt = "rt_maps_find" },
    .{ .module = "maps", .name = "is_key", .arity = 2, .rt = "rt_maps_is_key" },
    .{ .module = "maps", .name = "put", .arity = 3, .rt = "rt_maps_put" },
    .{ .module = "maps", .name = "remove", .arity = 2, .rt = "rt_maps_remove" },
    .{ .module = "maps", .name = "keys", .arity = 1, .rt = "rt_maps_keys" },
    .{ .module = "maps", .name = "values", .arity = 1, .rt = "rt_maps_values" },
    .{ .module = "maps", .name = "size", .arity = 1, .rt = "rt_maps_size" },
    .{ .module = "maps", .name = "to_list", .arity = 1, .rt = "rt_maps_to_list" },
    .{ .module = "maps", .name = "from_list", .arity = 1, .rt = "rt_maps_from_list" },
    .{ .module = "maps", .name = "merge", .arity = 2, .rt = "rt_maps_merge" },
    .{ .module = "maps", .name = "map", .arity = 2, .rt = "rt_maps_map" },
    .{ .module = "maps", .name = "fold", .arity = 3, .rt = "rt_maps_fold" },
    // string
    .{ .module = "string", .name = "length", .arity = 1, .rt = "rt_string_length" },
    .{ .module = "string", .name = "is_empty", .arity = 1, .rt = "rt_string_is_empty" },
    .{ .module = "string", .name = "uppercase", .arity = 1, .rt = "rt_string_uppercase" },
    .{ .module = "string", .name = "lowercase", .arity = 1, .rt = "rt_string_lowercase" },
    .{ .module = "string", .name = "titlecase", .arity = 1, .rt = "rt_string_titlecase" },
    .{ .module = "string", .name = "trim", .arity = 1, .rt = "rt_string_trim" },
    .{ .module = "string", .name = "trim", .arity = 2, .rt = "rt_string_trim2" },
    .{ .module = "string", .name = "find", .arity = 2, .rt = "rt_string_find" },
    .{ .module = "string", .name = "prefix", .arity = 2, .rt = "rt_string_prefix" },
    .{ .module = "string", .name = "equal", .arity = 2, .rt = "rt_string_equal" },
    .{ .module = "string", .name = "slice", .arity = 2, .rt = "rt_string_slice2" },
    .{ .module = "string", .name = "slice", .arity = 3, .rt = "rt_string_slice3" },
    .{ .module = "string", .name = "split", .arity = 2, .rt = "rt_string_split" },
    .{ .module = "string", .name = "split", .arity = 3, .rt = "rt_string_split3" },
    .{ .module = "string", .name = "replace", .arity = 3, .rt = "rt_string_replace" },
    .{ .module = "string", .name = "reverse", .arity = 1, .rt = "rt_string_reverse" },
    .{ .module = "string", .name = "to_integer", .arity = 1, .rt = "rt_string_to_integer" },
    // binary, unicode, math
    .{ .module = "binary", .name = "part", .arity = 3, .rt = "rt_binary_part" },
    .{ .module = "binary", .name = "first", .arity = 1, .rt = "rt_binary_first" },
    .{ .module = "binary", .name = "last", .arity = 1, .rt = "rt_binary_last" },
    .{ .module = "binary", .name = "at", .arity = 2, .rt = "rt_binary_at" },
    .{ .module = "binary", .name = "copy", .arity = 2, .rt = "rt_binary_copy" },
    .{ .module = "binary", .name = "match", .arity = 2, .rt = "rt_binary_match" },
    .{ .module = "binary", .name = "replace", .arity = 3, .rt = "rt_binary_replace3" },
    .{ .module = "binary", .name = "replace", .arity = 4, .rt = "rt_binary_replace4" },
    .{ .module = "binary", .name = "split", .arity = 2, .rt = "rt_binary_split2" },
    .{ .module = "binary", .name = "split", .arity = 3, .rt = "rt_binary_split3" },
    .{ .module = "unicode", .name = "characters_to_list", .arity = 1, .rt = "rt_unicode_characters_to_list" },
    .{ .module = "unicode", .name = "characters_to_list", .arity = 2, .rt = "rt_unicode_characters_to_list2" },
    .{ .module = "unicode", .name = "characters_to_binary", .arity = 1, .rt = "rt_unicode_characters_to_binary" },
    .{ .module = "unicode", .name = "characters_to_binary", .arity = 2, .rt = "rt_unicode_characters_to_binary2" },
    .{ .module = "math", .name = "floor", .arity = 1, .rt = "rt_math_floor" },
    .{ .module = "math", .name = "ceil", .arity = 1, .rt = "rt_math_ceil" },
    .{ .module = "math", .name = "sqrt", .arity = 1, .rt = "rt_math_sqrt" },
    .{ .module = "math", .name = "pow", .arity = 2, .rt = "rt_math_pow" },
    .{ .module = "io_lib", .name = "format", .arity = 2, .rt = "rt_io_lib_format" },
    .{ .module = "io", .name = "format", .arity = 2, .rt = "rt_io_format" },
    .{ .module = "io", .name = "format", .arity = 1, .rt = "rt_io_format1" },
    .{ .module = "json", .name = "encode", .arity = 1, .rt = "rt_json_encode" },
};

/// Every file whose `rt_*` functions are runtime exports (`wasm.zig`).
pub const files = .{ root.term, root.term_faces, erlang, lists, maps, string, binary, unicode, math, io_lib, json, etf };

/// Whether `symbol` is a runtime export.
pub fn isRuntimeExport(comptime symbol: []const u8) bool {
    inline for (files) |f| if (@hasDecl(f, symbol)) return true;
    return false;
}

comptime {
    // Every entry answers by a function the term library has.
    @setEvalBranchQuota(100_000);
    for (table) |b| if (!isRuntimeExport(b.rt)) @compileError(b.module ++ ":" ++ b.name ++ " names " ++ b.rt ++ ", which no term library file defines");
}

test {
    inline for (files) |f| std.testing.refAllDecls(f);
    _ = erlang;
    _ = lists;
    _ = maps;
    _ = string;
    _ = binary;
    _ = unicode;
    _ = math;
    _ = io_lib;
    _ = json;
    _ = etf;
}

test "table: one entry per module:name/arity" {
    for (table, 0..) |a, i| for (table[i + 1 ..]) |b| {
        const same = a.arity == b.arity and std.mem.eql(u8, a.module, b.module) and std.mem.eql(u8, a.name, b.name);
        try std.testing.expect(!same);
    };
}

// ── the terms and the OTP functions, natively (a fun runs only on wasm) ─────

const term = root.term;
const T = term.T;

/// `t` as `~p` writes it.
fn show(t: T) []const u8 {
    const out = io_lib.rt_io_lib_format(term.binOf("~p"), term.listFrom(&.{t}));
    return term.binBytes(erlang.rt_erlang_iolist_to_binary(out));
}

fn bin(s: []const u8) T {
    return term.binOf(s);
}

fn int(v: i64) T {
    return term.mkInt(v);
}

test "term: atoms are interned, term order and equality are Erlang's" {
    term.rt_reset();
    try std.testing.expect(term.atomOf("ok") == term.atomOf("ok"));
    const nil = term.rt_nil();
    // number < atom < tuple < map < nil < list < binary
    const order = [_]T{ int(1), term.atomOf("a"), term.tuple(&.{int(1)}), term.rt_map_empty(), nil, term.listFrom(&.{int(1)}), bin("a") };
    for (order[0 .. order.len - 1], order[1..]) |a, b| try std.testing.expect(term.rt_cmp(a, b) < 0);
    const one_float = term.rt_float(1.0);
    try std.testing.expectEqual(@as(i32, 1), term.rt_eq(int(1), one_float));
    try std.testing.expectEqual(@as(i32, 0), term.rt_eqx(int(1), one_float));
}

test "term: a raise keeps the innermost located call, a catch keeps it, a new raise forgets it" {
    term.rt_reset();
    try std.testing.expect(term.rt_raised_at_term() == term.rt_nil());
    term.rt_raised_at(3, 4); // nothing pending: nothing recorded
    try std.testing.expect(term.rt_raised_at_term() == term.rt_nil());
    _ = term.rt_add(int(std.math.maxInt(i64)), int(1));
    term.rt_raised_at(5, 9); // the inner call
    term.rt_raised_at(2, 1); // the call that called it
    term.rt_clear();
    try std.testing.expect(term.rt_eq(term.rt_raised_at_term(), term.listFrom(&.{ int(5), int(9) })) == 1);
    _ = term.rt_error(term.atomOf("again"));
    try std.testing.expect(term.rt_raised_at_term() == term.rt_nil());
    term.rt_clear();
}

test "term: an integer beyond 64 bits raises, and the exception reads as the BEAM's" {
    term.rt_reset();
    _ = term.rt_add(int(std.math.maxInt(i64)), int(1));
    try std.testing.expectEqual(@as(i32, 1), term.rt_pending());
    const text = term.binBytes(io_lib.rt_describe(term.rt_class(), term.rt_reason()));
    try std.testing.expectEqualStrings("error:{bp_wat_runtime,<<\"integer beyond 64 bits (a bignum)\">>}", text);
    term.rt_clear();
    try std.testing.expectEqual(@as(i32, 0), term.rt_pending());
    _ = erlang.rt_erlang_element(int(3), term.tuple(&.{int(1)}));
    try std.testing.expectEqualStrings("error:badarg", term.binBytes(io_lib.rt_describe(term.rt_class(), term.rt_reason())));
    term.rt_clear();
}

test "term: ~p of each shape" {
    term.rt_reset();
    var m = term.rt_map_empty();
    m = term.rt_map_put(m, term.atomOf("value"), int(2));
    m = term.rt_map_put(m, term.atomOf("error"), bin("x"));
    try std.testing.expectEqualStrings("#{error => <<\"x\">>,value => 2}", show(m));
    try std.testing.expectEqualStrings("{ok,[1,2.5],'Quoted',<<\"hi\">>}", show(term.tuple(&.{ term.atomOf("ok"), term.listFrom(&.{ int(1), term.rt_float(2.5) }), term.atomOf("Quoted"), bin("hi") })));
    try std.testing.expectEqualStrings("[]", show(term.rt_nil()));
}

test "lists: reverse, seq, sort, usort, flatten past the first growth" {
    term.rt_reset();
    try std.testing.expectEqualStrings("[3,2,1]", show(lists.rt_lists_reverse(lists.rt_lists_seq(int(1), int(3)))));
    try std.testing.expectEqualStrings("[1,2,3]", show(lists.rt_lists_sort(term.listFrom(&.{ int(3), int(1), int(2) }))));
    try std.testing.expectEqualStrings("[1,2]", show(lists.rt_lists_usort(term.listFrom(&.{ int(2), int(1), int(2) }))));
    var nested: [12]T = undefined;
    for (&nested, 0..) |*x, i| x.* = term.listFrom(&.{int(@intCast(i))});
    try std.testing.expectEqualStrings("[0,1,2,3,4,5,6,7,8,9,10,11]", show(lists.rt_lists_flatten(term.listFrom(&nested))));
}

test "maps: get, a missing key raises badkey" {
    term.rt_reset();
    const m = maps.rt_maps_put(term.atomOf("k"), int(1), term.rt_map_empty());
    try std.testing.expectEqualStrings("1", show(maps.rt_maps_get(term.atomOf("k"), m)));
    _ = maps.rt_maps_get(term.atomOf("j"), m);
    try std.testing.expectEqualStrings("error:{badkey,j}", term.binBytes(io_lib.rt_describe(term.rt_class(), term.rt_reason())));
    term.rt_clear();
}

test "string: case over Unicode, split once and all, titlecase, a list stays a list" {
    term.rt_reset();
    try std.testing.expectEqualStrings("<<\"STRASSE\">>", show(string.rt_string_uppercase(bin("straße"))));
    try std.testing.expectEqualStrings("[<<\"a\">>,<<\"b,c\">>]", show(string.rt_string_split(bin("a,b,c"), bin(","))));
    try std.testing.expectEqualStrings("[<<\"a\">>,<<\"b\">>,<<\"c\">>]", show(string.rt_string_split3(bin("a,b,c"), bin(","), term.atomOf("all"))));
    try std.testing.expectEqualStrings("<<\"Abc\">>", show(string.rt_string_titlecase(bin("abc"))));
    try std.testing.expectEqualStrings("\"AB\"", show(string.rt_string_uppercase(term.listFrom(&.{ int('a'), int('b') }))));
}

test "binary: replace the first or every match, split" {
    term.rt_reset();
    try std.testing.expectEqualStrings("<<\"a+b-c\">>", show(binary.rt_binary_replace3(bin("a-b-c"), bin("-"), bin("+"))));
    const global = term.listFrom(&.{term.atomOf("global")});
    try std.testing.expectEqualStrings("<<\"a+b+c\">>", show(binary.rt_binary_replace4(bin("a-b-c"), bin("-"), bin("+"), global)));
    try std.testing.expectEqualStrings("[<<\"a\">>,<<\"b-c\">>]", show(binary.rt_binary_split2(bin("a-b-c"), bin("-"))));
    try std.testing.expectEqualStrings("[<<\"a\">>,<<\"b\">>,<<\"c\">>]", show(binary.rt_binary_split3(bin("a-b-c"), bin("-"), global)));
}

test "json: encode, OTP 27's escapes and short floats" {
    term.rt_reset();
    const m = term.rt_map_put(term.rt_map_empty(), term.atomOf("a"), term.listFrom(&.{ int(1), term.rt_float(2.5), bin("x\"\n") }));
    try std.testing.expectEqualStrings("{\"a\":[1,2.5,\"x\\\"\\n\"]}", term.binBytes(erlang.rt_erlang_iolist_to_binary(json.rt_json_encode(m))));
}

test "etf: the argument decodes ({ok, 7})" {
    term.rt_reset();
    const bytes = [_]u8{ 131, 104, 2, 119, 2, 'o', 'k', 97, 7 };
    try std.testing.expectEqualStrings("{ok,7}", show(etf.rt_etf_decode(&bytes, bytes.len)));
}
