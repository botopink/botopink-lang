{module, bp_load_cases_integer_conversions_exact@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__grow', 2}]}.
{attributes, []}.
{labels, 123}.
%%% 02-std-and-packaging/97-std-dedupe step 13, decision 319 — the explicit integer conversions
%%% `toI32()`, `toI64()`, `toU32()`, `toU64()` and `toF64()` are std's `Integer` methods, and a
%%% value that fits converts exactly on every target: the type's own bounds, a value past 2^53
%%% (a `BigInt` on commonJS) and an `f64` that holds the integer exactly. The parent declared none
%%% (`toI32` was no method of `i64`). A value that does not fit aborts:
%%% `run/integer_conversion_to_i32_aborts`, `run/integer_conversion_to_f64_inexact_aborts`.

{function, grow, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, grow}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 16}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 16}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:11:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 17}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 9, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {integer, 2147483647}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 19}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}], {x, 0}}.
    {test, is_ge, {f, 58}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 58}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i64 at src/main.bp:17:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 59}.
    {move, {integer, -1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {call, 1, {f, 19}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 4294967295}, {x, 0}}.
    {call, 1, {f, 61}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 61}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 9007199254740991}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 73}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 85}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {call, 1, {f, 85}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 18446744073709551615}, {x, 0}}.
    {call, 1, {f, 73}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {call, 1, {f, 97}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {float, 9007199254740994.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, false}, {x, 0}}.
  {label, 112}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {call, 1, {f, 85}}.
    {call, 1, {f, 73}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, -9007199254740991}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 3}}.
    {call, 1, {f, 97}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {float, -9007199254740991.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, false}, {x, 0}}.
  {label, 114}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 85}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 9007199254740991}], {x, 0}}.
    {test, is_ge, {f, 115}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 115}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 116}}.
  {label, 115}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:28:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 116}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 97}}.
    {gc_bif, '/', {f, 0}, 1, [{x, 0}, {float, 2.0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 4000000000}, {x, 0}}.
    {call, 1, {f, 85}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 5}, {x, 0}}.
    {call, 1, {f, 85}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}], {x, 0}}.
    {test, is_ge, {f, 117}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 117}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 118}}.
  {label, 117}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:31:11">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 118}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 1234567}, {x, 0}}.
    {call, 1, {f, 73}}.
    {call, 1, {f, 19}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 4611686018427387904}, {x, 0}}.
    {call, 1, {f, 97}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {float, 4611686018427387904.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 120}}.
  {label, 119}.
    {move, {atom, false}, {x, 0}}.
  {label, 120}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/integer_conversions_exact|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__grow', 2, 122}.
  {label, 121}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_priv__grow'}, 2}.
  {label, 122}.
    {call_only, 2, {f, 3}}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 23}.
  {label, 22}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, -2147483648}, {x, 1}}.
    {test, is_ge, {f, 25}, [{x, 0}, {x, 1}]}.
    {move, {integer, 2147483647}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 25}, [{x, 0}, {x, 1}]}.
    {jump, {f, 26}}.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 28}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i32">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI32: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 29}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_0', 1, 19}.
  {label, 18}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_print'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 35}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '-bp_show_elem-', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 37}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '__bp_show', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_show'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 45}, [{x, 0}]}.
    {test, is_eq, {f, 44}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 46}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 48}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 47}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 53}}.
  {label, 52}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 53}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 50}, [{x, 0}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
  {label, 49}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 39}, 2}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 51}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tagged'}, 2}.
  {label, 39}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 54}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 41}, 3}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_render'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 56}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 57}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_integer_conversions_exact@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 65}.
  {label, 64}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 65}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 67}, [{x, 0}, {x, 1}]}.
    {move, {integer, 4294967295}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 67}, [{x, 0}, {x, 1}]}.
    {jump, {f, 68}}.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 70}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit u32">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toU32: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 71}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_1', 1, 61}.
  {label, 60}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 61}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 77}.
  {label, 76}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 77}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 79}, [{x, 0}, {x, 1}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {gc_bif, 'bsl', {f, 79}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_lt, {f, 79}, [{x, 0}, {x, 1}]}.
    {jump, {f, 80}}.
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 79}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 82}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit u64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toU64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 83}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_2', 1, 73}.
  {label, 72}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_2'}, 1}.
  {label, 73}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 77}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 89}.
  {label, 88}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 89}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 91}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 91}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 91}, [{x, 0}, {x, 1}]}.
    {jump, {f, 92}}.
  {label, 92}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 91}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 94}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 95}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_3', 1, 85}.
  {label, 84}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_3'}, 1}.
  {label, 85}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 89}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4-t/1-fun-0-', 1, 101}.
  {label, 100}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 1}.
  {label, 101}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, float, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 105}}.
  {label, 105}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 107}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 108}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_binary, {f, 109}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" has no exact f64">>}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toF64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 110}}.
  {label, 109}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 110}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 4}.
  {label, 108}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_4', 1, 97}.
  {label, 96}.
    {func_info, {atom, bp_load_cases_integer_conversions_exact@main}, {atom, '__bp_tpl_4'}, 1}.
  {label, 97}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 101}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
