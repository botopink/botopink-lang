//! Erlang (the generated comptime module and its resident prelude, as
//! `erl_parse.zig` reads them) → a `codegen/wat/wat_ast.zig` module whose
//! every value is a term of `rt.zig`.
//!
//! The output is a self-describing wasm module: it imports the runtime
//! functions it calls from module `"rt"` (`(import "rt" "rt_add" …)`), declares
//! a function table for its closures, three globals the linker defines
//! (`__lit` — where its literal data lands, `__lit_end`, `__tbase` — its first
//! table slot) and its literal bytes as data at offsets relative to `__lit`.
//! `link.zig` splices it into the runtime's bytes; `wat_emitter` renders it as
//! the `COMPTIME WAT` listing. Exports: `bp_init()` (the arena begins past the
//! literals) and `bp_main(arg_ptr, arg_len) → reply` (ETF in, the binary `main`
//! answered out, 0 when `main` raised — the exception stays pending).
//!
//! Semantics are Erlang's, by construction of the same program:
//!   * every value is an `i32` term; a variable is a local;
//!   * after each call that can raise, `rt_pending` is tested and control
//!     leaves by `br` to the innermost handler — a `try`'s catch block, a
//!     guard's failure, or the function's exit (which returns 0);
//!   * clauses are tried in order; a pattern test that fails branches to the
//!     next clause; no clause matching raises `function_clause`,
//!     `{case_clause, V}`, `if_clause` or `{badmatch, V}` as the BEAM does;
//!   * a `fun` is lifted to a function `(Self, A1…An)` in the table, its
//!     captured variables in an environment tuple;
//!   * a list comprehension is a loop that conses in reverse, then reverses.
//!
//! What it cannot lower it **refuses** (`error.Unsupported`, with `failure`
//! naming the construct and the Erlang function) — before anything runs, so a
//! refusal is a compile error of the comptime module, never a zero value.
const std = @import("std");
const ep = @import("erl_parse.zig");
const wat = @import("../../../codegen/wat/wat_ast.zig");

pub const Error = error{ OutOfMemory, Unsupported };

pub const Failure = struct {
    message: []const u8 = "",
};

const Instr = wat.Instr;
const Line = wat.Line;
const Seq = wat.Seq;

/// The runtime functions the lowering calls, with their wasm signatures. A
/// name absent here cannot be emitted (`rtCall` asserts it).
const RtSig = struct { params: []const wat.ValType, result: ?wat.ValType = .i32 };

fn i32s(comptime n: usize) []const wat.ValType {
    return &([_]wat.ValType{.i32} ** n);
}

const rt_sigs = std.StaticStringMap(RtSig).initComptime(.{
    .{ "rt_init", RtSig{ .params = i32s(1), .result = null } },
    .{ "rt_clear", RtSig{ .params = i32s(0), .result = null } },
    .{ "rt_pending", RtSig{ .params = i32s(0) } },
    .{ "rt_class", RtSig{ .params = i32s(0) } },
    .{ "rt_reason", RtSig{ .params = i32s(0) } },
    .{ "rt_nil", RtSig{ .params = i32s(0) } },
    .{ "rt_atom", RtSig{ .params = i32s(2) } },
    .{ "rt_bin", RtSig{ .params = i32s(2) } },
    .{ "rt_int", RtSig{ .params = &.{.i64} } },
    .{ "rt_float", RtSig{ .params = &.{.f64} } },
    .{ "rt_cons", RtSig{ .params = i32s(2) } },
    .{ "rt_hd", RtSig{ .params = i32s(1) } },
    .{ "rt_tl", RtSig{ .params = i32s(1) } },
    .{ "rt_tuple", RtSig{ .params = i32s(1) } },
    .{ "rt_tset", RtSig{ .params = i32s(3) } },
    .{ "rt_elem", RtSig{ .params = i32s(2) } },
    .{ "rt_tuple_arity", RtSig{ .params = i32s(1) } },
    .{ "rt_make_fun", RtSig{ .params = i32s(3) } },
    .{ "rt_fun_env", RtSig{ .params = i32s(1) } },
    .{ "rt_fun_index", RtSig{ .params = i32s(3) } },
    .{ "rt_map_empty", RtSig{ .params = i32s(0) } },
    .{ "rt_map_put", RtSig{ .params = i32s(3) } },
    .{ "rt_map_update", RtSig{ .params = i32s(3) } },
    .{ "rt_map_find", RtSig{ .params = i32s(2) } },
    .{ "rt_bb_new", RtSig{ .params = i32s(0) } },
    .{ "rt_bb_bin", RtSig{ .params = i32s(2) } },
    .{ "rt_bb_int", RtSig{ .params = i32s(3) } },
    .{ "rt_bb_utf8", RtSig{ .params = i32s(2) } },
    .{ "rt_bb_end", RtSig{ .params = i32s(1) } },
    .{ "rt_bin_is", RtSig{ .params = i32s(3) } },
    .{ "rt_bin_rest", RtSig{ .params = i32s(3) } },
    .{ "rt_is", RtSig{ .params = i32s(2) } },
    .{ "rt_is_fun_arity", RtSig{ .params = i32s(2) } },
    .{ "rt_truth", RtSig{ .params = i32s(1) } },
    .{ "rt_bool", RtSig{ .params = i32s(1) } },
    .{ "rt_eq", RtSig{ .params = i32s(2) } },
    .{ "rt_eqx", RtSig{ .params = i32s(2) } },
    .{ "rt_cmp", RtSig{ .params = i32s(2) } },
    .{ "rt_etf_decode", RtSig{ .params = i32s(2) } },
    .{ "rt_raise", RtSig{ .params = i32s(2) } },
    .{ "rt_throw", RtSig{ .params = i32s(1) } },
    .{ "rt_error", RtSig{ .params = i32s(1) } },
    .{ "rt_exit", RtSig{ .params = i32s(1) } },
    .{ "rt_badmatch", RtSig{ .params = i32s(1) } },
    .{ "rt_case_clause", RtSig{ .params = i32s(1) } },
    .{ "rt_try_clause", RtSig{ .params = i32s(1) } },
    .{ "rt_if_clause", RtSig{ .params = i32s(0) } },
    .{ "rt_function_clause", RtSig{ .params = i32s(0) } },
    .{ "rt_badarg_of", RtSig{ .params = i32s(1) } },
    .{ "rt_add", RtSig{ .params = i32s(2) } },
    .{ "rt_sub", RtSig{ .params = i32s(2) } },
    .{ "rt_mul", RtSig{ .params = i32s(2) } },
    .{ "rt_fdiv", RtSig{ .params = i32s(2) } },
    .{ "rt_idiv", RtSig{ .params = i32s(2) } },
    .{ "rt_rem", RtSig{ .params = i32s(2) } },
    .{ "rt_band", RtSig{ .params = i32s(2) } },
    .{ "rt_bor", RtSig{ .params = i32s(2) } },
    .{ "rt_bxor", RtSig{ .params = i32s(2) } },
    .{ "rt_bsl", RtSig{ .params = i32s(2) } },
    .{ "rt_bsr", RtSig{ .params = i32s(2) } },
    .{ "rt_neg", RtSig{ .params = i32s(1) } },
    .{ "rt_bnot", RtSig{ .params = i32s(1) } },
    .{ "rt_not", RtSig{ .params = i32s(1) } },
    .{ "rt_and", RtSig{ .params = i32s(2) } },
    .{ "rt_or", RtSig{ .params = i32s(2) } },
    .{ "rt_xor", RtSig{ .params = i32s(2) } },
    .{ "rt_append", RtSig{ .params = i32s(2) } },
    .{ "rt_subtract", RtSig{ .params = i32s(2) } },
    .{ "rt_lists_reverse", RtSig{ .params = i32s(1) } },
    .{ "rt_erlang_iolist_to_binary", RtSig{ .params = i32s(1) } },
});

/// A BIF the runtime answers: `module:name/arity` → the export that does it.
const Bif = struct { module: []const u8, name: []const u8, arity: usize, rt: []const u8 };

const bifs = [_]Bif{
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
    .{ .module = "erlang", .name = "is_function", .arity = 1, .rt = "rt_erlang_is_function" },
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

fn findBif(module: []const u8, name: []const u8, arity: usize) ?Bif {
    for (bifs) |b| {
        if (b.arity == arity and std.mem.eql(u8, b.module, module) and std.mem.eql(u8, b.name, name)) return b;
    }
    return null;
}

/// The BIFs an unqualified call reaches (erlang's auto-imports).
fn isAutoImported(name: []const u8, arity: usize) bool {
    const b = findBif("erlang", name, arity) orelse return false;
    _ = b;
    return !std.mem.eql(u8, name, "not");
}

// ── the program ──────────────────────────────────────────────────────────────

/// One Erlang function reachable from `main`, by module and name/arity.
const FnKey = struct { module: usize, name: []const u8, arity: usize };

pub const Program = struct {
    /// The generated module first, then the preludes it imports.
    modules: []const ep.Module,
};

pub const Output = struct {
    module: wat.Module,
    /// Literal bytes, laid out from offset 0 (`__lit`).
    data: []const u8,
};

const Lowerer = struct {
    ar: std.mem.Allocator,
    prog: Program,
    failure: *Failure,
    items: std.ArrayListUnmanaged(wat.Item) = .empty,
    funcs: std.ArrayListUnmanaged(wat.Item) = .empty,
    rt_used: std.StringArrayHashMapUnmanaged(void) = .empty,
    /// Functions of the program, lowered on demand (only what `main` reaches).
    queued: std.StringArrayHashMapUnmanaged(FnKey) = .empty,
    table: std.ArrayListUnmanaged([]const u8) = .empty,
    data: std.ArrayListUnmanaged(u8) = .empty,
    literals: std.StringHashMapUnmanaged(u32) = .empty,
    lifted: usize = 0,
    /// The Erlang function being lowered, for refusals.
    where: []const u8 = "",

    fn refuse(l: *Lowerer, comptime fmt: []const u8, args: anytype) Error {
        const what = std.fmt.allocPrint(l.ar, fmt, args) catch return error.OutOfMemory;
        l.failure.message = std.fmt.allocPrint(l.ar, "{s} (in {s})", .{ what, l.where }) catch return error.OutOfMemory;
        return error.Unsupported;
    }

    fn useRt(l: *Lowerer, name: []const u8) Error!void {
        std.debug.assert(rt_sigs.has(name) or isBifRt(name));
        try l.rt_used.put(l.ar, name, {});
    }

    /// Offset of `bytes` in the literal data (deduplicated).
    fn literal(l: *Lowerer, bytes: []const u8) Error!u32 {
        if (l.literals.get(bytes)) |off| return off;
        const off: u32 = @intCast(l.data.items.len);
        try l.data.appendSlice(l.ar, bytes);
        // keep every literal 8-aligned so nothing straddles oddly
        while (l.data.items.len % 8 != 0) try l.data.append(l.ar, 0);
        try l.literals.put(l.ar, try l.ar.dupe(u8, bytes), off);
        return off;
    }

    fn fnSymbol(l: *Lowerer, k: FnKey) Error![]const u8 {
        const prefix = if (k.module == 0) "" else l.prog.modules[k.module].name;
        return sanitize(l.ar, try std.fmt.allocPrint(l.ar, "{s}{s}{s}/{d}", .{ prefix, if (k.module == 0) "" else ":", k.name, k.arity }));
    }

    fn findFunction(l: *Lowerer, module: usize, name: []const u8, arity: usize) ?ep.Function {
        for (l.prog.modules[module].functions) |f| {
            if (f.arity == arity and std.mem.eql(u8, f.name, name)) return f;
        }
        return null;
    }

    fn moduleIndex(l: *Lowerer, name: []const u8) ?usize {
        for (l.prog.modules, 0..) |m, i| if (std.mem.eql(u8, m.name, name)) return i;
        return null;
    }

    /// The symbol a call to `name/arity` from `module` reaches, queueing the
    /// function for lowering; null when it is not a program function.
    fn resolveLocal(l: *Lowerer, module: usize, name: []const u8, arity: usize) Error!?[]const u8 {
        if (l.findFunction(module, name, arity) != null) return try l.queue(.{ .module = module, .name = name, .arity = arity });
        for (l.prog.modules[module].imports) |im| {
            if (im.arity == arity and std.mem.eql(u8, im.name, name)) {
                const mi = l.moduleIndex(im.module) orelse return null;
                if (l.findFunction(mi, name, arity) == null) return null;
                return try l.queue(.{ .module = mi, .name = name, .arity = arity });
            }
        }
        return null;
    }

    fn queue(l: *Lowerer, k: FnKey) Error![]const u8 {
        const sym = try l.fnSymbol(k);
        if (!l.queued.contains(sym)) try l.queued.put(l.ar, sym, k);
        return sym;
    }
};

fn isBifRt(name: []const u8) bool {
    for (bifs) |b| if (std.mem.eql(u8, b.rt, name)) return true;
    return false;
}

fn sigOf(name: []const u8) RtSig {
    if (rt_sigs.get(name)) |s| return s;
    for (bifs) |b| if (std.mem.eql(u8, b.rt, name)) return .{ .params = i32s(4)[0..b.arity] };
    unreachable;
}

/// A WAT identifier: every byte outside `idchar` becomes `_`.
fn sanitize(ar: std.mem.Allocator, s: []const u8) Error![]const u8 {
    const out = try ar.dupe(u8, s);
    for (out) |*c| {
        const ok = std.ascii.isAlphanumeric(c.*) or std.mem.indexOfScalar(u8, "!#$%&'*+-./:<=>?@\\^_`|~", c.*) != null;
        if (!ok) c.* = '_';
    }
    return out;
}

// ── a function under construction ────────────────────────────────────────────

const Code = std.ArrayListUnmanaged(Line);

/// Where a raise inside the current code goes: the label to `br` to. The
/// function's own exit returns 0; a `try` catches; a guard clears and fails.
const Fn = struct {
    l: *Lowerer,
    module: usize,
    locals: std.ArrayListUnmanaged(wat.Local) = .empty,
    local_set: std.StringHashMapUnmanaged(void) = .empty,
    labels: usize = 0,
    temps: usize = 0,
    /// Erlang variable → local symbol, for the variables bound so far.
    vars: std.StringHashMapUnmanaged([]const u8) = .empty,
    raise: []const u8 = "raise",
    /// Variables whose next binding takes a fresh local: a generator or a
    /// fun head shadows an outer binding of the same name.
    renames: std.StringHashMapUnmanaged([]const u8) = .empty,

    fn label(f: *Fn) Error![]const u8 {
        f.labels += 1;
        return std.fmt.allocPrint(f.l.ar, "L{d}", .{f.labels});
    }

    fn local(f: *Fn, name: []const u8) Error![]const u8 {
        if (!f.local_set.contains(name)) {
            try f.local_set.put(f.l.ar, name, {});
            try f.locals.append(f.l.ar, .{ .name = name, .ty = .i32 });
        }
        return name;
    }

    fn temp(f: *Fn) Error![]const u8 {
        f.temps += 1;
        return f.local(try std.fmt.allocPrint(f.l.ar, "t{d}", .{f.temps}));
    }

    /// The local an Erlang variable is kept in.
    fn varLocal(f: *Fn, name: []const u8) Error![]const u8 {
        if (f.vars.get(name)) |sym| return sym;
        if (f.renames.get(name)) |sym| return sym;
        const sym = try f.local(try sanitize(f.l.ar, try std.fmt.allocPrint(f.l.ar, "V_{s}", .{name})));
        return sym;
    }

    fn isBound(f: *Fn, name: []const u8) bool {
        return f.vars.contains(name);
    }

    fn bind(f: *Fn, name: []const u8) Error![]const u8 {
        const sym = try f.varLocal(name);
        try f.vars.put(f.l.ar, name, sym);
        return sym;
    }

    fn snapshot(f: *Fn) Error!std.StringHashMapUnmanaged([]const u8) {
        return f.vars.clone(f.l.ar);
    }
};

fn emit(c: *Code, ar: std.mem.Allocator, i: Instr) Error!void {
    try c.append(ar, .{ .instr = i });
}

fn endsTerminated(c: Code) bool {
    if (c.items.len == 0) return false;
    return switch (c.items[c.items.len - 1].instr) {
        .br, .@"return", .@"unreachable" => true,
        else => false,
    };
}

fn block(c: *Code, ar: std.mem.Allocator, kind: wat.Block.Kind, lbl: ?[]const u8, result: ?wat.ValType, body: Code) Error!void {
    const stack: wat.Stack = if (endsTerminated(body)) .terminated else if (result) |r| .{ .value = r } else .none;
    try emit(c, ar, .{ .block = .{ .kind = kind, .label = lbl, .result = result, .body = .{ .lines = body.items, .stack = stack } } });
}

fn ifThen(c: *Code, ar: std.mem.Allocator, result: ?wat.ValType, then: Code, els: ?Code) Error!void {
    const st = struct {
        fn of(code: Code, r: ?wat.ValType) wat.Stack {
            return if (endsTerminated(code)) .terminated else if (r) |t| .{ .value = t } else .none;
        }
    };
    try emit(c, ar, .{ .@"if" = .{
        .result = result,
        .then = .{ .seq = .{ .lines = then.items, .stack = st.of(then, result) } },
        .@"else" = if (els) |e| .{ .seq = .{ .lines = e.items, .stack = st.of(e, result) } } else null,
    } });
}

// ── lowering ─────────────────────────────────────────────────────────────────

const Ctx = struct {
    f: *Fn,
    c: *Code,

    fn ar(x: Ctx) std.mem.Allocator {
        return x.f.l.ar;
    }

    fn e(x: Ctx, i: Instr) Error!void {
        return emit(x.c, x.ar(), i);
    }

    fn cnst(x: Ctx, v: i64) Error!void {
        return x.e(.{ .@"const" = .{ .ty = .i32, .text = try std.fmt.allocPrint(x.ar(), "{d}", .{v}) } });
    }

    /// `call $rt_<name>`, and the raise check when it can raise.
    fn rt(x: Ctx, name: []const u8) Error!void {
        try x.f.l.useRt(name);
        try x.e(.{ .call = name });
    }

    fn rtChecked(x: Ctx, name: []const u8) Error!void {
        try x.rt(name);
        try x.check();
    }

    /// Leave for the current handler when an exception is pending.
    fn check(x: Ctx) Error!void {
        try x.rt("rt_pending");
        try x.e(.{ .br_if = x.f.raise });
    }

    /// Raise already recorded by the runtime: leave.
    fn leave(x: Ctx) Error!void {
        try x.e(.{ .br = x.f.raise });
    }

    fn get(x: Ctx, sym: []const u8) Error!void {
        return x.e(.{ .local_get = sym });
    }

    fn set(x: Ctx, sym: []const u8) Error!void {
        return x.e(.{ .local_set = sym });
    }

    fn sub(x: Ctx, c: *Code) Ctx {
        return .{ .f = x.f, .c = c };
    }

    /// Push the address of literal `bytes` and its length.
    fn litBytes(x: Ctx, bytes: []const u8) Error!void {
        const off = try x.f.l.literal(bytes);
        try x.e(.{ .global_get = "__lit" });
        try x.cnst(off);
        try x.e(.{ .op = .{ .ty = .i32, .name = "add" } });
        try x.cnst(@intCast(bytes.len));
    }

    fn atom(x: Ctx, name: []const u8) Error!void {
        try x.litBytes(name);
        try x.rt("rt_atom");
    }
};

/// Lower `e`; leaves one term on the stack.
fn lowerExpr(x: Ctx, e: ep.Expr) Error!void {
    const ar = x.ar();
    switch (e) {
        .variable => |v| {
            if (std.mem.eql(u8, v, "_")) return x.f.l.refuse("`_` used as a value", .{});
            if (!x.f.isBound(v)) return x.f.l.refuse("variable `{s}` used before it is bound", .{v});
            try x.get(x.f.vars.get(v).?);
        },
        .atom => |a| try x.atom(a),
        .int => |n| {
            try x.e(.{ .@"const" = .{ .ty = .i64, .text = try std.fmt.allocPrint(ar, "{d}", .{n}) } });
            try x.rt("rt_int");
        },
        .float => |fl| {
            try x.e(.{ .@"const" = .{ .ty = .f64, .text = try floatText(ar, fl) } });
            try x.rt("rt_float");
        },
        .string => |cps| try lowerCharList(x, cps),
        .binary => |segs| try lowerBinary(x, segs),
        .tuple => |items| {
            const t = try x.f.temp();
            try x.cnst(@intCast(items.len));
            try x.rt("rt_tuple");
            try x.set(t);
            for (items, 0..) |it, i| {
                try x.get(t);
                try x.cnst(@intCast(i));
                try lowerExpr(x, it);
                try x.rt("rt_tset");
                try x.e(.drop);
            }
            try x.get(t);
        },
        .list => |lst| {
            // Evaluate left to right into temps, then cons from the end.
            var temps: std.ArrayListUnmanaged([]const u8) = .empty;
            for (lst.items) |it| {
                const t = try x.f.temp();
                try lowerExpr(x, it);
                try x.set(t);
                try temps.append(ar, t);
            }
            if (lst.tail) |tl| try lowerExpr(x, tl.*) else try x.rt("rt_nil");
            var i = temps.items.len;
            while (i > 0) {
                i -= 1;
                const acc = try x.f.temp();
                try x.set(acc);
                try x.get(temps.items[i]);
                try x.get(acc);
                try x.rt("rt_cons");
            }
        },
        .map => |m| {
            if (m.base) |base| try lowerExpr(x, base.*) else try x.rt("rt_map_empty");
            for (m.fields) |fl| {
                const acc = try x.f.temp();
                try x.set(acc);
                try x.get(acc);
                try lowerExpr(x, fl.key);
                try lowerExpr(x, fl.value);
                if (fl.exact) {
                    if (m.base == null) return x.f.l.refuse("`:=` in a map construction", .{});
                    try x.rtChecked("rt_map_update");
                } else if (m.base != null) {
                    try x.rtChecked("rt_map_put");
                } else try x.rt("rt_map_put");
            }
        },
        .call => |c| try lowerCall(x, c),
        .fun_ref => |r| try lowerFunRef(x, r),
        .fun => |fun| try lowerFun(x, fun),
        .binop => |b| try lowerBinop(x, b),
        .unop => |u| {
            try lowerExpr(x, u.operand.*);
            const name: []const u8 = if (std.mem.eql(u8, u.op, "-")) "rt_neg" else if (std.mem.eql(u8, u.op, "not")) "rt_not" else if (std.mem.eql(u8, u.op, "bnot")) "rt_bnot" else return x.f.l.refuse("unary `{s}`", .{u.op});
            try x.rtChecked(name);
        },
        .match => |m| {
            try lowerExpr(x, m.value.*);
            const t = try x.f.temp();
            try x.set(t);
            const fail = try x.f.label();
            const done = try x.f.label();
            var inner: Code = .empty;
            const xi = x.sub(&inner);
            try lowerPattern(xi, m.pattern.*, t, fail);
            try xi.e(.{ .br = done });
            var outer: Code = .empty;
            try block(&outer, ar, .block, fail, null, inner);
            // the pattern failed
            const xo = x.sub(&outer);
            try xo.get(t);
            try xo.rt("rt_badmatch");
            try xo.e(.drop);
            try xo.leave();
            try block(x.c, ar, .block, done, null, outer);
            try x.get(t);
        },
        .case_ => |cs| {
            try lowerExpr(x, cs.subject.*);
            const t = try x.f.temp();
            try x.set(t);
            try lowerClauses(x, cs.clauses, &.{t}, .{ .case_clause = t });
        },
        .if_ => |clauses| try lowerClauses(x, clauses, &.{}, .if_clause),
        .try_ => |t| try lowerTry(x, t),
        .block => |body| try lowerBody(x, body),
        .list_comp => |lc| try lowerListComp(x, lc),
    }
}

fn floatText(ar: std.mem.Allocator, f: f64) Error![]const u8 {
    if (std.math.isNan(f)) return "nan";
    if (std.math.isInf(f)) return if (f > 0) "inf" else "-inf";
    return std.fmt.allocPrint(ar, "{e}", .{f});
}

/// A sequence: every value but the last is dropped.
fn lowerBody(x: Ctx, body: []const ep.Expr) Error!void {
    for (body, 0..) |e, i| {
        try lowerExpr(x, e);
        if (i + 1 < body.len) try x.e(.drop);
    }
}

fn lowerCharList(x: Ctx, cps: []const u21) Error!void {
    try x.rt("rt_nil");
    var i = cps.len;
    while (i > 0) {
        i -= 1;
        const acc = try x.f.temp();
        try x.set(acc);
        try x.e(.{ .@"const" = .{ .ty = .i64, .text = try std.fmt.allocPrint(x.ar(), "{d}", .{cps[i]}) } });
        try x.rt("rt_int");
        try x.get(acc);
        try x.rt("rt_cons");
    }
}

/// The bytes of a binary whose every segment is a literal (string, integer or
/// char with the default type or `/binary` of a string), or null.
fn literalBinary(ar: std.mem.Allocator, segs: []const ep.Segment) Error!?[]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (segs) |s| {
        if (s.size != null) return null;
        const ty: []const u8 = if (s.types.len == 0) "" else if (s.types.len == 1) s.types[0] else return null;
        switch (s.value) {
            .string => |cps| {
                if (std.mem.eql(u8, ty, "utf8")) {
                    for (cps) |cp| {
                        var buf: [4]u8 = undefined;
                        const n = std.unicode.utf8Encode(cp, &buf) catch return null;
                        try out.appendSlice(ar, buf[0..n]);
                    }
                } else if (ty.len == 0 or std.mem.eql(u8, ty, "binary")) {
                    for (cps) |cp| try out.append(ar, @truncate(cp));
                } else return null;
            },
            .int => |n| {
                if (std.mem.eql(u8, ty, "utf8")) {
                    var buf: [4]u8 = undefined;
                    const k = std.unicode.utf8Encode(@intCast(n), &buf) catch return null;
                    try out.appendSlice(ar, buf[0..k]);
                } else if (ty.len == 0 or std.mem.eql(u8, ty, "integer")) {
                    try out.append(ar, @truncate(@as(u64, @bitCast(n))));
                } else return null;
            },
            else => return null,
        }
    }
    return out.items;
}

fn lowerBinary(x: Ctx, segs: []const ep.Segment) Error!void {
    if (try literalBinary(x.ar(), segs)) |bytes| {
        try x.litBytes(bytes);
        try x.rt("rt_bin");
        return;
    }
    const bb = try x.f.temp();
    try x.rt("rt_bb_new");
    try x.set(bb);
    for (segs) |s| {
        if (try literalBinary(x.ar(), &.{s})) |bytes| {
            try x.get(bb);
            try x.litBytes(bytes);
            try x.rt("rt_bin");
            try x.rtChecked("rt_bb_bin");
            try x.e(.drop);
            continue;
        }
        const ty: []const u8 = if (s.types.len == 0) "integer" else s.types[0];
        try x.get(bb);
        try lowerExpr(x, s.value);
        if (std.mem.eql(u8, ty, "binary") or std.mem.eql(u8, ty, "bytes") or std.mem.eql(u8, ty, "bitstring")) {
            if (s.size != null) return x.f.l.refuse("a sized /binary segment", .{});
            try x.rtChecked("rt_bb_bin");
        } else if (std.mem.eql(u8, ty, "utf8")) {
            try x.rtChecked("rt_bb_utf8");
        } else if (std.mem.eql(u8, ty, "integer")) {
            const bits: i64 = if (s.size) |sz| switch (sz) {
                .int => |n| n,
                else => return x.f.l.refuse("a binary segment with a computed size", .{}),
            } else 8;
            try x.cnst(bits);
            try x.rtChecked("rt_bb_int");
        } else return x.f.l.refuse("binary segment type `{s}`", .{ty});
        try x.e(.drop);
    }
    try x.get(bb);
    try x.rt("rt_bb_end");
}

// ── calls ────────────────────────────────────────────────────────────────────

fn lowerArgs(x: Ctx, args: []const ep.Expr) Error!void {
    for (args) |a| try lowerExpr(x, a);
}

fn lowerCall(x: Ctx, c: ep.Expr.Call) Error!void {
    const l = x.f.l;
    if (c.module) |m| {
        const mod = switch (m.*) {
            .atom => |a| a,
            else => return l.refuse("a call through a computed module", .{}),
        };
        const name = switch (c.fun.*) {
            .atom => |a| a,
            else => return l.refuse("a call to a computed function name", .{}),
        };
        return lowerNamedCall(x, mod, name, c.args, true);
    }
    switch (c.fun.*) {
        .atom => |name| return lowerNamedCall(x, null, name, c.args, false),
        else => {},
    }
    // Applying a fun value.
    try lowerExpr(x, c.fun.*);
    const f = try x.f.temp();
    try x.set(f);
    var arg_temps: std.ArrayListUnmanaged([]const u8) = .empty;
    for (c.args) |a| {
        const t = try x.f.temp();
        try lowerExpr(x, a);
        try x.set(t);
        try arg_temps.append(x.ar(), t);
    }
    try x.get(f);
    try x.cnst(@intCast(c.args.len));
    try x.rt("rt_nil");
    try x.rtChecked("rt_fun_index");
    const idx = try x.f.temp();
    try x.set(idx);
    try x.get(f);
    for (arg_temps.items) |t| try x.get(t);
    try x.get(idx);
    try x.e(.{ .call_indirect = .{ .params = try closureParams(x.ar(), c.args.len), .result = .i32 } });
    try x.check();
}

fn closureParams(ar: std.mem.Allocator, arity: usize) Error![]const wat.ValType {
    const p = try ar.alloc(wat.ValType, arity + 1);
    @memset(p, .i32);
    return p;
}

fn lowerNamedCall(x: Ctx, module_name: ?[]const u8, name: []const u8, args: []const ep.Expr, qualified: bool) Error!void {
    const l = x.f.l;
    const here = x.f.module;
    // A program function (local, imported, or `mod:name` of a program module).
    if (module_name) |m| {
        if (l.moduleIndex(m)) |mi| {
            if (l.findFunction(mi, name, args.len) != null) {
                const sym = try l.queue(.{ .module = mi, .name = name, .arity = args.len });
                try lowerArgs(x, args);
                try x.e(.{ .call = sym });
                try x.check();
                return;
            }
        }
    } else if (try l.resolveLocal(here, name, args.len)) |sym| {
        try lowerArgs(x, args);
        try x.e(.{ .call = sym });
        try x.check();
        return;
    }
    const mod = module_name orelse "erlang";
    if (!qualified and !isAutoImported(name, args.len)) {
        return l.refuse("call to undefined function {s}/{d}", .{ name, args.len });
    }
    // `apply(M, F, Args)` with everything literal is a direct call.
    if (std.mem.eql(u8, mod, "erlang") and std.mem.eql(u8, name, "apply") and args.len == 3) {
        return l.refuse("erlang:apply/3", .{});
    }
    if (std.mem.eql(u8, mod, "erlang") and std.mem.eql(u8, name, "error") and args.len == 2) {
        try lowerExpr(x, args[0]);
        try x.rt("rt_error");
        try x.e(.drop);
        try x.leave();
        try x.rt("rt_nil"); // unreachable value, keeps the stack shape readable
        return;
    }
    if (std.mem.eql(u8, mod, "erlang") and std.mem.eql(u8, name, "raise") and args.len == 3) {
        try lowerExpr(x, args[0]);
        try lowerExpr(x, args[1]);
        try x.rt("rt_raise");
        try x.e(.drop);
        try x.leave();
        try x.rt("rt_nil");
        return;
    }
    const bif = findBif(mod, name, args.len) orelse return l.refuse("{s}:{s}/{d} is not in the wat runtime", .{ mod, name, args.len });
    try lowerArgs(x, args);
    try x.rtChecked(bif.rt);
}

fn lowerFunRef(x: Ctx, r: ep.Expr.FunRef) Error!void {
    const l = x.f.l;
    // A wrapper `(Self, A1…An) -> target(A1…An)`, lifted once per target.
    var target: []const u8 = undefined;
    var is_bif = false;
    if (r.module) |m| {
        if (l.moduleIndex(m)) |mi| {
            if (l.findFunction(mi, r.name, r.arity) == null) return l.refuse("fun {s}:{s}/{d}: no such function", .{ m, r.name, r.arity });
            target = try l.queue(.{ .module = mi, .name = r.name, .arity = r.arity });
        } else {
            const bif = findBif(m, r.name, r.arity) orelse return l.refuse("fun {s}:{s}/{d} is not in the wat runtime", .{ m, r.name, r.arity });
            target = bif.rt;
            is_bif = true;
            try l.useRt(bif.rt);
        }
    } else {
        target = (try l.resolveLocal(x.f.module, r.name, r.arity)) orelse return l.refuse("fun {s}/{d}: no such function", .{ r.name, r.arity });
    }
    const sym = try sanitize(l.ar, try std.fmt.allocPrint(l.ar, "ref:{s}", .{target}));
    const slot = try tableSlot(l, sym);
    if (slot.new) {
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        try params.append(l.ar, .{ .name = "self", .ty = .i32 });
        var body: Code = .empty;
        for (0..r.arity) |i| {
            const p = try std.fmt.allocPrint(l.ar, "a{d}", .{i});
            try params.append(l.ar, .{ .name = p, .ty = .i32 });
            try emit(&body, l.ar, .{ .local_get = p });
        }
        try emit(&body, l.ar, .{ .call = target });
        try l.funcs.append(l.ar, .{ .func = .{
            .name = sym,
            .params = params.items,
            .result = .i32,
            .body = .{ .lines = body.items, .stack = .{ .value = .i32 } },
        } });
    }
    try pushTableIndex(x, slot.index);
    try x.cnst(@intCast(r.arity));
    try x.rt("rt_nil");
    try x.rt("rt_make_fun");
}

const Slot = struct { index: usize, new: bool };

fn tableSlot(l: *Lowerer, sym: []const u8) Error!Slot {
    for (l.table.items, 0..) |s, i| if (std.mem.eql(u8, s, sym)) return .{ .index = i, .new = false };
    try l.table.append(l.ar, sym);
    return .{ .index = l.table.items.len - 1, .new = true };
}

fn pushTableIndex(x: Ctx, index: usize) Error!void {
    try x.e(.{ .global_get = "__tbase" });
    try x.cnst(@intCast(index));
    try x.e(.{ .op = .{ .ty = .i32, .name = "add" } });
}

// ── funs ─────────────────────────────────────────────────────────────────────

/// Variables a fun reads that are bound where it is defined (its captures),
/// in first-use order.
fn freeVars(f: *Fn, fun: ep.Expr.Fun, out: *std.ArrayListUnmanaged([]const u8)) Error!void {
    var shadow: std.StringHashMapUnmanaged(void) = .empty;
    if (fun.name) |n| try shadow.put(f.l.ar, n, {});
    for (fun.clauses) |cl| {
        var local_shadow = try shadow.clone(f.l.ar);
        for (cl.patterns) |p| try collectPatternVars(f.l.ar, p, &local_shadow);
        for (cl.guards) |alt| for (alt) |g| try collectUses(f, g, &local_shadow, out);
        for (cl.body) |b| try collectUses(f, b, &local_shadow, out);
    }
}

fn collectPatternVars(ar: std.mem.Allocator, p: ep.Expr, into: *std.StringHashMapUnmanaged(void)) Error!void {
    switch (p) {
        .variable => |v| if (!std.mem.eql(u8, v, "_")) try into.put(ar, v, {}),
        .tuple => |items| for (items) |it| try collectPatternVars(ar, it, into),
        .list => |l| {
            for (l.items) |it| try collectPatternVars(ar, it, into);
            if (l.tail) |t| try collectPatternVars(ar, t.*, into);
        },
        .map => |m| for (m.fields) |fl| try collectPatternVars(ar, fl.value, into),
        .match => |m| {
            try collectPatternVars(ar, m.pattern.*, into);
            try collectPatternVars(ar, m.value.*, into);
        },
        .binary => |segs| for (segs) |s| try collectPatternVars(ar, s.value, into),
        .binop => |b| if (std.mem.eql(u8, b.op, ":")) {
            try collectPatternVars(ar, b.lhs.*, into);
            try collectPatternVars(ar, b.rhs.*, into);
        },
        else => {},
    }
}

/// Every variable `e` reads that is bound in `f` and not shadowed — a
/// conservative walk (a variable bound inside `e` before its use is still
/// collected when an outer binding of the name exists, which only costs an
/// extra environment slot).
fn collectUses(f: *Fn, e: ep.Expr, shadow: *std.StringHashMapUnmanaged(void), out: *std.ArrayListUnmanaged([]const u8)) Error!void {
    const ar = f.l.ar;
    switch (e) {
        .variable => |v| {
            if (shadow.contains(v) or !f.isBound(v)) return;
            for (out.items) |o| if (std.mem.eql(u8, o, v)) return;
            try out.append(ar, v);
        },
        .atom, .int, .float, .string, .fun_ref => {},
        .binary => |segs| for (segs) |s| {
            try collectUses(f, s.value, shadow, out);
            if (s.size) |sz| try collectUses(f, sz, shadow, out);
        },
        .tuple => |items| for (items) |it| try collectUses(f, it, shadow, out),
        .list => |l| {
            for (l.items) |it| try collectUses(f, it, shadow, out);
            if (l.tail) |t| try collectUses(f, t.*, shadow, out);
        },
        .map => |m| {
            if (m.base) |b| try collectUses(f, b.*, shadow, out);
            for (m.fields) |fl| {
                try collectUses(f, fl.key, shadow, out);
                try collectUses(f, fl.value, shadow, out);
            }
        },
        .call => |c| {
            if (c.module) |m| try collectUses(f, m.*, shadow, out);
            try collectUses(f, c.fun.*, shadow, out);
            for (c.args) |a| try collectUses(f, a, shadow, out);
        },
        .fun => |fun| {
            var inner = try shadow.clone(ar);
            if (fun.name) |n| try inner.put(ar, n, {});
            for (fun.clauses) |cl| {
                var cs = try inner.clone(ar);
                for (cl.patterns) |p| try collectPatternVars(ar, p, &cs);
                for (cl.guards) |alt| for (alt) |g| try collectUses(f, g, &cs, out);
                for (cl.body) |b| try collectUses(f, b, &cs, out);
            }
        },
        .binop => |b| {
            try collectUses(f, b.lhs.*, shadow, out);
            try collectUses(f, b.rhs.*, shadow, out);
        },
        .unop => |u| try collectUses(f, u.operand.*, shadow, out),
        .match => |m| {
            try collectUses(f, m.pattern.*, shadow, out);
            try collectUses(f, m.value.*, shadow, out);
        },
        .case_ => |c| {
            try collectUses(f, c.subject.*, shadow, out);
            for (c.clauses) |cl| try collectClauseUses(f, cl, shadow, out);
        },
        .if_ => |cls| for (cls) |cl| try collectClauseUses(f, cl, shadow, out),
        .try_ => |t| {
            for (t.body) |b| try collectUses(f, b, shadow, out);
            for (t.of) |cl| try collectClauseUses(f, cl, shadow, out);
            for (t.catches) |cl| try collectClauseUses(f, cl, shadow, out);
            for (t.after) |b| try collectUses(f, b, shadow, out);
        },
        .block => |b| for (b) |it| try collectUses(f, it, shadow, out),
        .list_comp => |lc| {
            var inner = try shadow.clone(ar);
            for (lc.qualifiers) |q| switch (q) {
                .generator => |g| {
                    try collectUses(f, g.list, &inner, out);
                    try collectPatternVars(ar, g.pattern, &inner);
                },
                .bin_generator => |g| {
                    try collectUses(f, g.bin, &inner, out);
                    try collectPatternVars(ar, g.pattern, &inner);
                },
                .filter => |fl| try collectUses(f, fl, &inner, out),
            };
            try collectUses(f, lc.element.*, &inner, out);
        },
    }
}

fn collectClauseUses(f: *Fn, cl: ep.Clause, shadow: *std.StringHashMapUnmanaged(void), out: *std.ArrayListUnmanaged([]const u8)) Error!void {
    for (cl.patterns) |p| try collectUses(f, p, shadow, out);
    for (cl.guards) |alt| for (alt) |g| try collectUses(f, g, shadow, out);
    for (cl.body) |b| try collectUses(f, b, shadow, out);
}

fn lowerFun(x: Ctx, fun: ep.Expr.Fun) Error!void {
    const l = x.f.l;
    const arity = fun.clauses[0].patterns.len;
    var captured: std.ArrayListUnmanaged([]const u8) = .empty;
    try freeVars(x.f, fun, &captured);

    l.lifted += 1;
    const sym = try sanitize(l.ar, try std.fmt.allocPrint(l.ar, "fun{d}:{s}", .{ l.lifted, l.where }));
    const slot = try tableSlot(l, sym);

    // The lifted function.
    var g: Fn = .{ .l = l, .module = x.f.module };
    var params: std.ArrayListUnmanaged(wat.Param) = .empty;
    try params.append(l.ar, .{ .name = "self", .ty = .i32 });
    var arg_syms: std.ArrayListUnmanaged([]const u8) = .empty;
    for (0..arity) |i| {
        const p = try std.fmt.allocPrint(l.ar, "a{d}", .{i});
        try params.append(l.ar, .{ .name = p, .ty = .i32 });
        try arg_syms.append(l.ar, p);
    }
    var body: Code = .empty;
    const gx: Ctx = .{ .f = &g, .c = &body };
    // Captured variables: loaded from the environment tuple.
    for (captured.items, 0..) |v, i| {
        const loc = try g.bind(v);
        try gx.get("self");
        try gx.rt("rt_fun_env");
        try gx.cnst(@intCast(i));
        try gx.rt("rt_elem");
        try gx.set(loc);
    }
    if (fun.name) |n| {
        const loc = try g.bind(n);
        try gx.get("self");
        try gx.set(loc);
    }
    try lowerClausesHeads(gx, fun.clauses, arg_syms.items, .function_clause, true);
    try finishFunction(l, &g, sym, &.{}, params.items, body);

    // The closure value here.
    if (captured.items.len == 0) {
        try x.rt("rt_nil");
    } else {
        try lowerExpr(x, .{ .tuple = try varExprs(l.ar, captured.items) });
    }
    const env = try x.f.temp();
    try x.set(env);
    try pushTableIndex(x, slot.index);
    try x.cnst(@intCast(arity));
    try x.get(env);
    try x.rt("rt_make_fun");
}

fn varExprs(ar: std.mem.Allocator, names: []const []const u8) Error![]const ep.Expr {
    const out = try ar.alloc(ep.Expr, names.len);
    for (names, 0..) |n, i| out[i] = .{ .variable = n };
    return out;
}

// ── operators ────────────────────────────────────────────────────────────────

fn lowerBinop(x: Ctx, b: ep.Expr.BinOp) Error!void {
    const op = b.op;
    if (std.mem.eql(u8, op, "andalso") or std.mem.eql(u8, op, "orelse")) {
        const is_and = std.mem.eql(u8, op, "andalso");
        try lowerExpr(x, b.lhs.*);
        const t = try x.f.temp();
        try x.set(t);
        const k = try x.f.temp();
        try x.get(t);
        try x.rt("rt_truth");
        try x.set(k);
        // k == 2 → {badarg, T}
        var bad: Code = .empty;
        const xb = x.sub(&bad);
        try xb.get(t);
        try xb.rt("rt_badarg_of");
        try xb.e(.drop);
        try xb.leave();
        try x.get(k);
        try x.cnst(2);
        try x.e(.{ .op = .{ .ty = .i32, .name = "eq" } });
        try ifThen(x.c, x.ar(), null, bad, null);
        // andalso: k == 1 → rhs, else false. orelse: k == 0 → rhs, else true.
        var rhs: Code = .empty;
        try lowerExpr(x.sub(&rhs), b.rhs.*);
        var short: Code = .empty;
        try x.sub(&short).atom(if (is_and) "false" else "true");
        try x.get(k);
        if (!is_and) try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
        try ifThen(x.c, x.ar(), .i32, rhs, short);
        return;
    }
    try lowerExpr(x, b.lhs.*);
    try lowerExpr(x, b.rhs.*);
    const Cmp = struct { op: []const u8, rt: []const u8, test_: []const u8, neg: bool };
    const cmps = [_]Cmp{
        .{ .op = "==", .rt = "rt_eq", .test_ = "", .neg = false },
        .{ .op = "/=", .rt = "rt_eq", .test_ = "", .neg = true },
        .{ .op = "=:=", .rt = "rt_eqx", .test_ = "", .neg = false },
        .{ .op = "=/=", .rt = "rt_eqx", .test_ = "", .neg = true },
        .{ .op = "<", .rt = "rt_cmp", .test_ = "lt_s", .neg = false },
        .{ .op = ">", .rt = "rt_cmp", .test_ = "gt_s", .neg = false },
        .{ .op = "=<", .rt = "rt_cmp", .test_ = "le_s", .neg = false },
        .{ .op = ">=", .rt = "rt_cmp", .test_ = "ge_s", .neg = false },
    };
    for (cmps) |c| {
        if (!std.mem.eql(u8, c.op, op)) continue;
        try x.rt(c.rt);
        if (c.test_.len > 0) {
            try x.cnst(0);
            try x.e(.{ .op = .{ .ty = .i32, .name = c.test_ } });
        }
        if (c.neg) try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
        try x.rt("rt_bool");
        return;
    }
    const arith = [_][2][]const u8{
        .{ "+", "rt_add" },     .{ "-", "rt_sub" },   .{ "*", "rt_mul" },     .{ "/", "rt_fdiv" },
        .{ "div", "rt_idiv" },  .{ "rem", "rt_rem" }, .{ "band", "rt_band" }, .{ "bor", "rt_bor" },
        .{ "bxor", "rt_bxor" }, .{ "bsl", "rt_bsl" }, .{ "bsr", "rt_bsr" },   .{ "and", "rt_and" },
        .{ "or", "rt_or" },     .{ "xor", "rt_xor" }, .{ "++", "rt_append" }, .{ "--", "rt_subtract" },
    };
    for (arith) |a| {
        if (std.mem.eql(u8, a[0], op)) return x.rtChecked(a[1]);
    }
    return x.f.l.refuse("operator `{s}`", .{op});
}

// ── patterns ─────────────────────────────────────────────────────────────────

/// Match the term in local `v` against `p`, binding its unbound variables;
/// `br $fail` when it does not match.
fn lowerPattern(x: Ctx, p: ep.Expr, v: []const u8, fail: []const u8) Error!void {
    const l = x.f.l;
    switch (p) {
        .variable => |name| {
            if (std.mem.eql(u8, name, "_")) return;
            if (x.f.isBound(name)) {
                try x.get(v);
                try x.get(x.f.vars.get(name).?);
                try x.rt("rt_eqx");
                try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                try x.e(.{ .br_if = fail });
            } else {
                const sym = try x.f.bind(name);
                try x.get(v);
                try x.set(sym);
            }
        },
        .atom, .int, .float, .string => {
            try x.get(v);
            try lowerExpr(x, p);
            try x.rt("rt_eqx");
            try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
            try x.e(.{ .br_if = fail });
        },
        .binary => |segs| {
            if (try literalBinary(l.ar, segs)) |bytes| {
                try x.get(v);
                try x.litBytes(bytes);
                try x.rt("rt_bin_is");
                try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                try x.e(.{ .br_if = fail });
                return;
            }
            // `<<Lit…, Rest/binary>>`
            if (segs.len >= 1) {
                const last = segs[segs.len - 1];
                const rest_ok = last.types.len == 1 and std.mem.eql(u8, last.types[0], "binary") and last.size == null and last.value == .variable;
                if (rest_ok) {
                    if (try literalBinary(l.ar, segs[0 .. segs.len - 1])) |prefix| {
                        const t = try x.f.temp();
                        try x.get(v);
                        try x.litBytes(prefix);
                        try x.rt("rt_bin_rest");
                        try x.set(t);
                        try x.get(t);
                        try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                        try x.e(.{ .br_if = fail });
                        return lowerPattern(x, last.value, t, fail);
                    }
                }
            }
            return l.refuse("a binary pattern other than literal bytes and a `/binary` tail", .{});
        },
        .tuple => |items| {
            try x.get(v);
            try x.rt("rt_tuple_arity");
            try x.cnst(@intCast(items.len));
            try x.e(.{ .op = .{ .ty = .i32, .name = "ne" } });
            try x.e(.{ .br_if = fail });
            for (items, 0..) |it, i| {
                if (it == .variable and std.mem.eql(u8, it.variable, "_")) continue;
                const t = try x.f.temp();
                try x.get(v);
                try x.cnst(@intCast(i));
                try x.rt("rt_elem");
                try x.set(t);
                try lowerPattern(x, it, t, fail);
            }
        },
        .list => |lst| {
            var cur = v;
            for (lst.items) |it| {
                try x.get(cur);
                try x.cnst(@intFromEnum(Kind.cons));
                try x.rt("rt_is");
                try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                try x.e(.{ .br_if = fail });
                const h = try x.f.temp();
                try x.get(cur);
                try x.rt("rt_hd");
                try x.set(h);
                const t = try x.f.temp();
                try x.get(cur);
                try x.rt("rt_tl");
                try x.set(t);
                try lowerPattern(x, it, h, fail);
                cur = t;
            }
            if (lst.tail) |tl| {
                try lowerPattern(x, tl.*, cur, fail);
            } else {
                try x.get(cur);
                try x.cnst(@intFromEnum(Kind.nil));
                try x.rt("rt_is");
                try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                try x.e(.{ .br_if = fail });
            }
        },
        .map => |m| {
            if (m.base != null) return l.refuse("a map update in a pattern", .{});
            try x.get(v);
            try x.cnst(@intFromEnum(Kind.map));
            try x.rt("rt_is");
            try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
            try x.e(.{ .br_if = fail });
            for (m.fields) |fl| {
                const t = try x.f.temp();
                try x.get(v);
                try lowerExpr(x, fl.key);
                try x.rt("rt_map_find");
                try x.set(t);
                try x.get(t);
                try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                try x.e(.{ .br_if = fail });
                try lowerPattern(x, fl.value, t, fail);
            }
        },
        .match => |m| {
            try lowerPattern(x, m.pattern.*, v, fail);
            try lowerPattern(x, m.value.*, v, fail);
        },
        .binop => |b| {
            if (std.mem.eql(u8, b.op, "++")) {
                // `"prefix" ++ Rest`
                const prefix = switch (b.lhs.*) {
                    .string => |cps| cps,
                    else => return l.refuse("`++` in a pattern with a non-literal prefix", .{}),
                };
                var cur = v;
                for (prefix) |cp| {
                    try x.get(cur);
                    try x.cnst(@intFromEnum(Kind.cons));
                    try x.rt("rt_is");
                    try x.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
                    try x.e(.{ .br_if = fail });
                    const h = try x.f.temp();
                    try x.get(cur);
                    try x.rt("rt_hd");
                    try x.set(h);
                    try lowerPattern(x, .{ .int = cp }, h, fail);
                    const t = try x.f.temp();
                    try x.get(cur);
                    try x.rt("rt_tl");
                    try x.set(t);
                    cur = t;
                }
                return lowerPattern(x, b.rhs.*, cur, fail);
            }
            return l.refuse("operator `{s}` in a pattern", .{b.op});
        },
        else => return l.refuse("this pattern shape ({s})", .{@tagName(p)}),
    }
}

const Kind = enum(u32) { atom = 0, binary = 1, integer = 2, float = 3, number = 4, list = 5, tuple = 6, map = 7, function = 8, boolean = 9, bitstring = 10, nil = 11, cons = 12 };

// ── clauses and guards ───────────────────────────────────────────────────────

const NoMatch = union(enum) {
    function_clause,
    if_clause,
    case_clause: []const u8,
    try_clause: []const u8,
    /// `catch` clauses: none matched — re-raise the exception held in the two
    /// locals.
    reraise: [2][]const u8,
};

/// Clauses tried in order against the terms in `subjects` (one per pattern);
/// leaves the chosen body's value. Variables bound by a clause survive it
/// when every clause binds them (Erlang's exported variables).
fn lowerClauses(x: Ctx, clauses: []const ep.Clause, subjects: []const []const u8, no_match: NoMatch) Error!void {
    return lowerClausesHeads(x, clauses, subjects, no_match, false);
}

/// `fresh_heads`: the patterns introduce new variables even where a name is
/// bound (a `fun` head), instead of testing against the binding.
fn lowerClausesHeads(x: Ctx, clauses: []const ep.Clause, subjects: []const []const u8, no_match: NoMatch, fresh_heads: bool) Error!void {
    const ar = x.ar();
    const done = try x.f.label();
    var outer: Code = .empty;
    const before = try x.f.snapshot();
    var common: ?std.StringHashMapUnmanaged([]const u8) = null;
    for (clauses) |cl| {
        if (cl.patterns.len != subjects.len) return x.f.l.refuse("a clause of {d} patterns for {d} values", .{ cl.patterns.len, subjects.len });
        x.f.vars = try before.clone(ar);
        if (fresh_heads) for (cl.patterns) |p| try shadowPatternVars(x.f, p);
        const next = try x.f.label();
        var inner: Code = .empty;
        const xi = x.sub(&inner);
        for (cl.patterns, subjects) |p, s| try lowerPattern(xi, p, s, next);
        try lowerGuards(xi, cl.guards, next);
        try lowerBody(xi, cl.body);
        try xi.e(.{ .br = done });
        try block(&outer, ar, .block, next, null, inner);
        // the variables every clause so far binds
        if (common) |*cm| {
            var it = cm.iterator();
            var drop: std.ArrayListUnmanaged([]const u8) = .empty;
            while (it.next()) |kv| if (!x.f.vars.contains(kv.key_ptr.*)) try drop.append(ar, kv.key_ptr.*);
            for (drop.items) |d| _ = cm.remove(d);
        } else common = try x.f.vars.clone(ar);
    }
    // No clause matched.
    const xo = x.sub(&outer);
    switch (no_match) {
        .function_clause => try xo.rt("rt_function_clause"),
        .if_clause => try xo.rt("rt_if_clause"),
        .case_clause => |t| {
            try xo.get(t);
            try xo.rt("rt_case_clause");
        },
        .try_clause => |t| {
            try xo.get(t);
            try xo.rt("rt_try_clause");
        },
        .reraise => |cr| {
            try xo.get(cr[0]);
            try xo.get(cr[1]);
            try xo.rt("rt_raise");
        },
    }
    try xo.e(.drop);
    try xo.leave();
    try block(x.c, ar, .block, done, .i32, outer);
    x.f.vars = common orelse before;
}

/// A guard sequence: the clause proceeds when one alternative's tests are all
/// `true`; an exception in a guard is a failed guard, not an error.
fn lowerGuards(x: Ctx, alts: []const []const ep.Expr, fail: []const u8) Error!void {
    if (alts.len == 0) return;
    const ar = x.ar();
    const ok = try x.f.label();
    var outer: Code = .empty;
    const saved_raise = x.f.raise;
    for (alts) |tests| {
        const alt_fail = try x.f.label();
        const alt_raise = try x.f.label();
        var raise_code: Code = .empty;
        var body: Code = .empty;
        x.f.raise = alt_raise;
        const xb = x.sub(&body);
        for (tests) |t| {
            try lowerExpr(xb, t);
            try xb.rt("rt_truth");
            try xb.cnst(1);
            try xb.e(.{ .op = .{ .ty = .i32, .name = "ne" } });
            try xb.e(.{ .br_if = alt_fail });
        }
        try xb.e(.{ .br = ok });
        x.f.raise = saved_raise;
        try block(&raise_code, ar, .block, alt_raise, null, body);
        // an exception inside the guard: forget it, the alternative failed
        try emit(&raise_code, ar, .{ .call = "rt_clear" });
        try x.f.l.useRt("rt_clear");
        try block(&outer, ar, .block, alt_fail, null, raise_code);
    }
    try emit(&outer, ar, .{ .br = fail });
    try block(x.c, ar, .block, ok, null, outer);
}

// ── try ──────────────────────────────────────────────────────────────────────

fn lowerTry(x: Ctx, t: ep.Expr.Try) Error!void {
    const ar = x.ar();
    if (t.after.len > 0) return x.f.l.refuse("`try … after`", .{});
    const done = try x.f.label();
    const caught = try x.f.label();
    var outer: Code = .empty;
    var inner: Code = .empty;
    const saved = x.f.raise;
    x.f.raise = caught;
    const xi = x.sub(&inner);
    try lowerBody(xi, t.body);
    x.f.raise = saved;
    if (t.of.len > 0) {
        const v = try x.f.temp();
        try xi.set(v);
        try lowerClauses(xi, t.of, &.{v}, .{ .try_clause = v });
    }
    try xi.e(.{ .br = done });
    try block(&outer, ar, .block, caught, null, inner);
    // The handler: take the exception, match the catch clauses.
    const xo = x.sub(&outer);
    const class = try x.f.temp();
    const reason = try x.f.temp();
    try xo.rt("rt_class");
    try xo.set(class);
    try xo.rt("rt_reason");
    try xo.set(reason);
    try xo.rt("rt_clear");
    if (t.catches.len == 0) {
        try xo.get(class);
        try xo.get(reason);
        try xo.rt("rt_raise");
        try xo.e(.drop);
        try xo.leave();
    } else {
        // `Class:Reason[:Stack]` patterns become two subjects.
        var clauses: std.ArrayListUnmanaged(ep.Clause) = .empty;
        for (t.catches) |cl| {
            const pat = cl.patterns[0];
            var cls: ep.Expr = .{ .atom = "throw" };
            var rsn: ep.Expr = pat;
            if (pat == .binop and std.mem.eql(u8, pat.binop.op, ":")) {
                var lhs = pat.binop.lhs.*;
                rsn = pat.binop.rhs.*;
                // `Class:Reason:Stack` is `(Class:Reason):Stack`
                if (lhs == .binop and std.mem.eql(u8, lhs.binop.op, ":")) {
                    const stack_pat = rsn;
                    rsn = lhs.binop.rhs.*;
                    lhs = lhs.binop.lhs.*;
                    if (stack_pat != .variable) return x.f.l.refuse("a stack pattern other than a variable", .{});
                    if (!std.mem.eql(u8, stack_pat.variable, "_")) {
                        // bind the stack to []
                        const sym = try x.f.bind(stack_pat.variable);
                        try xo.rt("rt_nil");
                        try xo.set(sym);
                    }
                }
                cls = lhs;
            }
            try clauses.append(ar, .{ .patterns = try ar.dupe(ep.Expr, &.{ cls, rsn }), .guards = cl.guards, .body = cl.body });
        }
        try lowerClauses(xo, clauses.items, &.{ class, reason }, .{ .reraise = .{ class, reason } });
        try xo.e(.{ .br = done });
    }
    try block(x.c, ar, .block, done, .i32, outer);
}

// ── list comprehensions ──────────────────────────────────────────────────────

fn lowerListComp(x: Ctx, lc: ep.Expr.ListComp) Error!void {
    const acc = try x.f.temp();
    try x.rt("rt_nil");
    try x.set(acc);
    const before = try x.f.snapshot();
    try lowerQualifiers(x, lc, 0, acc);
    x.f.vars = before;
    try x.get(acc);
    try x.rt("rt_lists_reverse");
}

/// The qualifiers from `i` on, then the element consed onto `acc`.
fn lowerQualifiers(x: Ctx, lc: ep.Expr.ListComp, i: usize, acc: []const u8) Error!void {
    const ar = x.ar();
    if (i == lc.qualifiers.len) {
        try lowerExpr(x, lc.element.*);
        try x.get(acc);
        try x.rt("rt_cons");
        try x.set(acc);
        return;
    }
    switch (lc.qualifiers[i]) {
        .filter => |f| {
            // A filter that is not `true` skips; a non-boolean is an error in
            // Erlang only for guards — as a filter it must be a boolean.
            const skip = try x.f.label();
            var body: Code = .empty;
            const xb = x.sub(&body);
            try lowerExpr(xb, f);
            try xb.rt("rt_truth");
            try xb.cnst(1);
            try xb.e(.{ .op = .{ .ty = .i32, .name = "ne" } });
            try xb.e(.{ .br_if = skip });
            try lowerQualifiers(xb, lc, i + 1, acc);
            try block(x.c, ar, .block, skip, null, body);
        },
        .generator => |g| {
            // for each element of the list: match the pattern (a mismatch
            // skips the element), then the rest.
            try lowerExpr(x, g.list);
            const cur = try x.f.temp();
            try x.set(cur);
            const brk = try x.f.label();
            const again = try x.f.label();
            var loop_body: Code = .empty;
            const xl = x.sub(&loop_body);
            try xl.get(cur);
            try xl.cnst(@intFromEnum(Kind.cons));
            try xl.rt("rt_is");
            try xl.e(.{ .op = .{ .ty = .i32, .name = "eqz" } });
            try xl.e(.{ .br_if = brk });
            const h = try x.f.temp();
            try xl.get(cur);
            try xl.rt("rt_hd");
            try xl.set(h);
            try xl.get(cur);
            try xl.rt("rt_tl");
            try xl.set(cur);
            // generator variables are fresh (they shadow outer bindings)
            const saved = try x.f.snapshot();
            const saved_renames = try x.f.renames.clone(ar);
            try shadowPatternVars(x.f, g.pattern);
            const next = try x.f.label();
            var item: Code = .empty;
            const xi = x.sub(&item);
            try lowerPattern(xi, g.pattern, h, next);
            try lowerQualifiers(xi, lc, i + 1, acc);
            try block(&loop_body, ar, .block, next, null, item);
            x.f.vars = saved;
            x.f.renames = saved_renames;
            try xl.e(.{ .br = again });
            var loop: Code = .empty;
            try block(&loop, ar, .loop, again, null, loop_body);
            try block(x.c, ar, .block, brk, null, loop);
        },
        .bin_generator => |g| {
            // `<<V/utf8>> <= Bin` or `<<V>> <= Bin`: one code point / byte at
            // a time, via the char list.
            const segs = switch (g.pattern) {
                .binary => |s| s,
                else => return x.f.l.refuse("a binary generator whose pattern is not a binary", .{}),
            };
            if (segs.len != 1 or segs[0].size != null) return x.f.l.refuse("a binary generator pattern of more than one segment", .{});
            const ty: []const u8 = if (segs[0].types.len == 0) "integer" else segs[0].types[0];
            try lowerExpr(x, g.bin);
            if (std.mem.eql(u8, ty, "utf8")) {
                try x.rtChecked("rt_unicode_characters_to_list");
            } else if (std.mem.eql(u8, ty, "integer")) {
                try x.rtChecked("rt_erlang_binary_to_list");
            } else return x.f.l.refuse("a binary generator of `/{s}` segments", .{ty});
            const tmp = try x.f.temp();
            try x.set(tmp);
            const vname = try std.fmt.allocPrint(ar, "__bingen{d}", .{x.f.temps});
            const sym = try x.f.bind(vname);
            try x.get(tmp);
            try x.set(sym);
            var quals = try ar.dupe(ep.Expr.Qualifier, lc.qualifiers);
            quals[i] = .{ .generator = .{ .pattern = segs[0].value, .list = .{ .variable = vname } } };
            try lowerQualifiers(x, .{ .element = lc.element, .qualifiers = quals }, i, acc);
        },
    }
}

/// The variables of pattern `p` that are bound now become unbound, and their
/// next binding takes a fresh local — a generator or a fun head introduces new
/// variables even where the name is already bound.
fn shadowPatternVars(f: *Fn, p: ep.Expr) Error!void {
    var names: std.StringHashMapUnmanaged(void) = .empty;
    try collectPatternVars(f.l.ar, p, &names);
    var it = names.keyIterator();
    while (it.next()) |n| {
        if (!f.vars.contains(n.*)) continue;
        _ = f.vars.remove(n.*);
        f.temps += 1;
        const sym = try f.local(try sanitize(f.l.ar, try std.fmt.allocPrint(f.l.ar, "V_{s}#{d}", .{ n.*, f.temps })));
        try f.renames.put(f.l.ar, n.*, sym);
    }
}

// ── functions ────────────────────────────────────────────────────────────────

/// Add a lowered function: `body` leaves the value; a raise lands after the
/// body's block and answers 0.
fn finishFunction(l: *Lowerer, f: *Fn, sym: []const u8, exports: []const []const u8, params: []const wat.Param, body: Code) Error!void {
    var wrapped: Code = .empty;
    var inner = body;
    try emit(&inner, l.ar, .@"return");
    try block(&wrapped, l.ar, .block, "raise", null, inner);
    try emit(&wrapped, l.ar, .{ .@"const" = .{ .ty = .i32, .text = "0" } });
    try l.funcs.append(l.ar, .{ .func = .{
        .name = sym,
        .exports = exports,
        .params = params,
        .result = .i32,
        .locals = if (f.locals.items.len == 0) &.{} else try l.ar.dupe([]const wat.Local, &.{f.locals.items}),
        .body = .{ .lines = wrapped.items, .stack = .{ .value = .i32 } },
    } });
}

fn lowerFunction(l: *Lowerer, sym: []const u8, k: FnKey) Error!void {
    const func = l.findFunction(k.module, k.name, k.arity).?;
    l.where = try std.fmt.allocPrint(l.ar, "{s}:{s}/{d}", .{ l.prog.modules[k.module].name, k.name, k.arity });
    var f: Fn = .{ .l = l, .module = k.module };
    var params: std.ArrayListUnmanaged(wat.Param) = .empty;
    var subjects: std.ArrayListUnmanaged([]const u8) = .empty;
    for (0..k.arity) |i| {
        const p = try std.fmt.allocPrint(l.ar, "a{d}", .{i});
        try params.append(l.ar, .{ .name = p, .ty = .i32 });
        try subjects.append(l.ar, p);
    }
    var body: Code = .empty;
    try lowerClauses(.{ .f = &f, .c = &body }, func.clauses, subjects.items, .function_clause);
    try finishFunction(l, &f, sym, &.{}, params.items, body);
}

/// Lower `prog` (the generated module first) into a wat module that imports
/// the runtime and exports `bp_init` and `bp_main`.
pub fn lowerProgram(ar: std.mem.Allocator, prog: Program, failure: *Failure) Error!Output {
    var l: Lowerer = .{ .ar = ar, .prog = prog, .failure = failure };
    const gen = prog.modules[0];
    if (l.findFunction(0, "main", 1) == null) {
        failure.message = try std.fmt.allocPrint(ar, "module {s} defines no main/1", .{gen.name});
        return error.Unsupported;
    }
    const main_sym = try l.queue(.{ .module = 0, .name = "main", .arity = 1 });
    var i: usize = 0;
    while (i < l.queued.count()) : (i += 1) {
        const sym = l.queued.keys()[i];
        const k = l.queued.values()[i];
        try lowerFunction(&l, sym, k);
    }

    // bp_init(): the arena starts past the literals.
    {
        var body: Code = .empty;
        try emit(&body, ar, .{ .global_get = "__lit_end" });
        try emit(&body, ar, .{ .call = "rt_init" });
        try l.useRt("rt_init");
        try emit(&body, ar, .{ .@"const" = .{ .ty = .i32, .text = "0" } });
        try l.funcs.append(ar, .{ .func = .{ .name = "bp_init", .exports = &.{"bp_init"}, .result = .i32, .body = .{ .lines = body.items, .stack = .{ .value = .i32 } } } });
    }
    // bp_main(ptr, len): decode, run main/1, answer a binary (0 when it raised).
    {
        var body: Code = .empty;
        try emit(&body, ar, .{ .local_get = "ptr" });
        try emit(&body, ar, .{ .local_get = "len" });
        try emit(&body, ar, .{ .call = "rt_etf_decode" });
        try l.useRt("rt_etf_decode");
        try emit(&body, ar, .{ .call = main_sym });
        try emit(&body, ar, .{ .local_set = "r" });
        try emit(&body, ar, .{ .call = "rt_pending" });
        try l.useRt("rt_pending");
        var raised: Code = .empty;
        try emit(&raised, ar, .{ .@"const" = .{ .ty = .i32, .text = "0" } });
        try emit(&raised, ar, .@"return");
        try ifThen(&body, ar, null, raised, null);
        try emit(&body, ar, .{ .local_get = "r" });
        try emit(&body, ar, .{ .call = "rt_erlang_iolist_to_binary" });
        try l.useRt("rt_erlang_iolist_to_binary");
        try l.funcs.append(ar, .{ .func = .{
            .name = "bp_main",
            .exports = &.{"bp_main"},
            .params = try ar.dupe(wat.Param, &.{ .{ .name = "ptr", .ty = .i32 }, .{ .name = "len", .ty = .i32 } }),
            .result = .i32,
            .locals = try ar.dupe([]const wat.Local, &.{try ar.dupe(wat.Local, &.{.{ .name = "r", .ty = .i32 }})}),
            .body = .{ .lines = body.items, .stack = .{ .value = .i32 } },
        } });
    }

    // The module: rt imports, the three linker globals, table, data, funcs.
    var items: std.ArrayListUnmanaged(wat.Item) = .empty;
    for (l.rt_used.keys()) |name| {
        const sig = sigOf(name);
        try items.append(ar, .{ .import = .{ .module = "rt", .name = name, .func = name, .type = .{ .params = sig.params, .result = sig.result } } });
    }
    try items.append(ar, .{ .global = .{ .name = "__lit", .ty = .i32, .init = "0" } });
    try items.append(ar, .{ .global = .{ .name = "__lit_end", .ty = .i32, .init = try std.fmt.allocPrint(ar, "{d}", .{l.data.items.len}) } });
    try items.append(ar, .{ .global = .{ .name = "__tbase", .ty = .i32, .init = "0" } });
    if (l.table.items.len > 0) try items.append(ar, .{ .table = l.table.items });
    try items.appendSlice(ar, l.funcs.items);
    return .{ .module = .{ .items = items.items }, .data = l.data.items };
}
