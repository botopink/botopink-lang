{module, bp_load_cases_comptime_primitives_at_build@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_fold', 3}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__arrs', 0}, {'__bp_priv__divs', 0}, {'__bp_priv__exact', 0}, {'__bp_priv__floats', 0}, {'__bp_priv__ints', 0}, {'__bp_priv__strs', 0}]}.
{attributes, []}.
{labels, 254}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 30}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 35}}.
  {label, 33}.
  {label, 31}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 36}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 37}}.
  {label, 36}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 35}}.
    {jump, {f, 39}}.
  {label, 38}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 35}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
  {label, 39}.
  {label, 37}.
    {deallocate, 6}.
    return.
%%% Decisions 331, 434 (5) — a primitive computed at build answers what the
%%% program computes when it runs, one answer for every target: integer
%%% conversions (`1000.toI64()` used to raise `integer_overflow` at build,
%%% its bound written `1 bsl 63`, which the comptime runtime's 64-bit
%%% integers cannot hold), string methods, float arithmetic and text, array
%%% methods and integer division. Each family is computed under `comptime`
%%% and again at run time, and the two compared.

{function, ints, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, ints}, 0}.
  {label, 7}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {integer, 1000}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 9007199254740993}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 41}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 41}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 53}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 64}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 64}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i64 at src/main.bp:19:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 65}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 41}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 8}.
    return.

{function, exact, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, exact}, 0}.
  {label, 9}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1000}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 99}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {float, 1000.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, false}, {x, 0}}.
  {label, 114}.
    {deallocate, 1}.
    return.

{function, strs, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, strs}, 0}.
  {label, 11}.
    {allocate, 19, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {literal, <<"  H\x{C3}\x{A9}llo, World  ">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"l">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"L">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 116}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"H">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 117}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 117}.
    {move, {atom, true}, {x, 0}}.
  {label, 118}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"W">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 120}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {integer, 4}, {x, 2}}.
    {call, 3, {f, 134}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 136}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 153}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 155}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {call_ext, 1, {extfunc, string, uppercase, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 19}.
    return.

{function, floats, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, floats}, 0}.
  {label, 13}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {float, 3.5}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {float, 1.0e-7}], {x, 0}}.
    {call, 1, {f, 157}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{float, 0.1}, {float, 0.2}], {x, 0}}.
    {call, 1, {f, 157}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '/', {f, 0}, 0, [{float, 1.0}, {float, 3.0}], {x, 0}}.
    {call, 1, {f, 157}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 2.0}], {x, 0}}.
    {call, 1, {f, 157}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, arrs, 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, arrs}, 0}.
  {label, 15}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 161}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 159}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 166}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 153}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 153}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 170}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 153}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 12}.
    return.

{function, divs, 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, divs}, 0}.
  {label, 17}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 7}], {x, 0}}.
    {test, is_ge, {f, 173}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 173}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 174}}.
  {label, 173}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:85:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 174}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 3}], {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, 'rem', {f, 0}, 0, [{integer, 7}, {integer, 3}], {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 7}], {x, 0}}.
    {test, is_ge, {f, 175}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 175}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 176}}.
  {label, 175}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:81:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 176}.
    {gc_bif, 'div', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 177}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 177}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 178}}.
  {label, 177}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/main.bp:81:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 178}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, 'div', {f, 0}, 0, [{integer, 7}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 179}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 179}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 180}}.
  {label, 179}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/main.bp:79:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 180}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 1}.
    return.

{function, main, 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, main}, 0}.
  {label, 19}.
    {allocate, 15, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {literal, <<"1000 9007199254740993 9007199254740992 1000 9007199254740993 9223372036854775807">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {call, 0, {f, 7}}.
    {test, is_eq_exact, {f, 181}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 182}}.
  {label, 181}.
    {move, {atom, false}, {x, 0}}.
  {label, 182}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {literal, <<"H\x{C3}\x{89}LLO, WORLD|h\x{C3}\x{A9}llo, world|16|H\x{C3}\x{A9}llo+World|\x{C3}\x{A9}ll|9|true|H\x{C3}\x{A9}Llo, World">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {call, 0, {f, 11}}.
    {test, is_eq_exact, {f, 183}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 184}}.
  {label, 183}.
    {move, {atom, false}, {x, 0}}.
  {label, 184}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {literal, <<"1.75 0.3333333333333333 0.30000000000000004 2.0e-7">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {call, 0, {f, 13}}.
    {test, is_eq_exact, {f, 185}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {atom, false}, {x, 0}}.
  {label, 186}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {literal, <<"6,2,4 2,1,3 3 3,2 6 true">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {call, 0, {f, 15}}.
    {test, is_eq_exact, {f, 187}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 188}}.
  {label, 187}.
    {move, {atom, false}, {x, 0}}.
  {label, 188}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {literal, <<"3 -3 1 -1">>}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {call, 0, {f, 17}}.
    {test, is_eq_exact, {f, 189}, [{y, 4}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 190}}.
  {label, 189}.
    {move, {atom, false}, {x, 0}}.
  {label, 190}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 15}.
    return.

{function, '__bp_loaded_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {call, 0, {f, 19}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/comptime_primitives_at_build|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '_botopink_main'}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 19}, 0}.

{function, main, 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, main}, 1}.
  {label, 29}.
    {call_only, 0, {f, 27}}.

{function, 'string_slice', 3, 134}.
  {label, 133}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, 'string_slice'}, 3}.
  {label, 134}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 191}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 193}, 3}.
  {label, 191}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 215}, 3}.

{function, 'array_fold', 3, 159}.
  {label, 158}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, 'array_fold'}, 3}.
  {label, 159}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 232}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_priv__array_fold', 3, 235}.
  {label, 234}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__array_fold'}, 3}.
  {label, 235}.
    {call_only, 3, {f, 159}}.

{function, '__bp_priv__array_range', 2, 237}.
  {label, 236}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 237}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 239}.
  {label, 238}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 239}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 241}.
  {label, 240}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 21}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 241}.
    {call_only, 3, {f, 134}}.

{function, '__bp_priv__arrs', 0, 243}.
  {label, 242}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 22}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__arrs'}, 0}.
  {label, 243}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__divs', 0, 245}.
  {label, 244}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 23}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__divs'}, 0}.
  {label, 245}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__exact', 0, 247}.
  {label, 246}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 24}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__exact'}, 0}.
  {label, 247}.
    {call_only, 0, {f, 9}}.

{function, '__bp_priv__floats', 0, 249}.
  {label, 248}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 25}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__floats'}, 0}.
  {label, 249}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__ints', 0, 251}.
  {label, 250}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 26}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__ints'}, 0}.
  {label, 251}.
    {call_only, 0, {f, 7}}.

{function, '__bp_priv__strs', 0, 253}.
  {label, 252}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 27}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_priv__strs'}, 0}.
  {label, 253}.
    {call_only, 0, {f, 11}}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 45}.
  {label, 44}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 45}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 47}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 47}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 47}, [{x, 0}, {x, 1}]}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 50}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_0', 1, 41}.
  {label, 40}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 57}.
  {label, 56}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 57}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 59}, [{x, 0}, {x, 1}]}.
    {move, {integer, 4294967295}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 59}, [{x, 0}, {x, 1}]}.
    {jump, {f, 60}}.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 62}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit u32">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toU32: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 63}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_1', 1, 53}.
  {label, 52}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 53}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_print'}, 1}.
  {label, 67}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 71}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 69}}.

{function, '-bp_show_elem-', 1, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 73}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 69}}.

{function, '__bp_show', 2, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_show'}, 2}.
  {label, 69}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 81}, [{x, 0}]}.
    {test, is_eq, {f, 80}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 82}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 84}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 83}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 83}, [{x, 0}]}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 89}}.
  {label, 88}.
    {test, is_eq_exact, {f, 85}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 89}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 69}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 83}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 84}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 86}, [{x, 0}]}.
    {test, is_ne_exact, {f, 86}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 86}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 87}, [{x, 0}, {atom, undefined}]}.
  {label, 85}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 75}, 2}.
  {label, 86}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 87}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 75}.
  {label, 74}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tagged'}, 2}.
  {label, 75}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 90}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 90}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 90}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 77}, 3}.
  {label, 91}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_render'}, 1}.
  {label, 77}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 92}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 93}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 79}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 79}.
  {label, 78}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 79}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 69}}.
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

{function, '-bp_stringify-', 1, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 95}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 96}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 96}.
    {test, is_integer, {f, 97}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 97}.
    {call, 1, {f, 71}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 103}.
  {label, 102}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 103}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, float, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 107}}.
  {label, 107}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 109}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 109}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 110}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_binary, {f, 111}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" has no exact f64">>}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toF64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 112}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 4}.
  {label, 110}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 1, 99}.
  {label, 98}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_2'}, 1}.
  {label, 99}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 103}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3', 3, 116}.
  {label, 115}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_3'}, 3}.
  {label, 116}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, string, replace, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 4}.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 124}.
  {label, 123}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 124}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 128}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 128}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 131}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 132}, [{x, 0}]}.
    {test, test_arity, {f, 132}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 6}.
  {label, 132}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_4', 2, 120}.
  {label, 119}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_4'}, 2}.
  {label, 120}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 124}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 140}.
  {label, 139}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 140}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 144}, [{x, 0}]}.
    {jump, {f, 145}}.
  {label, 144}.
    {test, is_tuple, {f, 146}, [{x, 0}]}.
    {test, test_arity, {f, 146}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 145}}.
  {label, 146}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 145}.
    {move, {x, 0}, {y, 4}}.
  {label, 147}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 148}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 150}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 150}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 151}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 147}}.
  {label, 148}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 149}, [{x, 0}]}.
    {jump, {f, 143}}.
  {label, 149}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 143}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 142}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_5', 2, 136}.
  {label, 135}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_5'}, 2}.
  {label, 136}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 140}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_join-', 2, 153}.
  {label, 152}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-bp_join-'}, 2}.
  {label, 153}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_6', 1, 155}.
  {label, 154}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_6'}, 1}.
  {label, 155}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_tpl_7', 1, 157}.
  {label, 156}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_7'}, 1}.
  {label, 157}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [short]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, float_to_binary, 2}, 1}.

{function, '__bp_add', 2, 163}.
  {label, 162}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_add'}, 2}.
  {label, 163}.
    {test, is_binary, {f, 164}, [{x, 0}]}.
    {test, is_binary, {f, 164}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 164}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-arrs/0-fun-0-', 2, 161}.
  {label, 160}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-arrs/0-fun-0-'}, 2}.
  {label, 161}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 163}}.
    {deallocate, 2}.
    return.

{function, '-arrs/0-fun-1-', 1, 166}.
  {label, 165}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-arrs/0-fun-1-'}, 1}.
  {label, 166}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 167}, [{integer, 1}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 168}}.
  {label, 167}.
    {move, {atom, false}, {x, 0}}.
  {label, 168}.
    {deallocate, 1}.
    return.

{function, '-arrs/0-fun-2-', 1, 170}.
  {label, 169}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-arrs/0-fun-2-'}, 1}.
  {label, 170}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 171}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 171}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 172}}.
  {label, 171}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:65:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 172}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_8-t/3-fun-0-', 3, 197}.
  {label, 196}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_8-t/3-fun-0-'}, 3}.
  {label, 197}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 201}}.
  {label, 201}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 203}}.
  {label, 203}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 205}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 204}}.
  {label, 205}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 206}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 204}}.
  {label, 206}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 204}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 208}}.
  {label, 208}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 210}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 209}}.
  {label, 210}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 209}}.
  {label, 211}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 209}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 213}}.
  {label, 213}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_8', 3, 193}.
  {label, 192}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_8'}, 3}.
  {label, 193}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 197}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_9-t/2-fun-0-', 2, 219}.
  {label, 218}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_9-t/2-fun-0-'}, 2}.
  {label, 219}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 223}}.
  {label, 223}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 225}}.
  {label, 225}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 226}}.
  {label, 227}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 226}}.
  {label, 228}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 226}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 230}}.
  {label, 230}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_9', 2, 215}.
  {label, 214}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_tpl_9'}, 2}.
  {label, 215}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 219}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-fold/3-fun-3-', 3, 232}.
  {label, 231}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '-fold/3-fun-3-'}, 3}.
  {label, 232}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_comptime_primitives_at_build@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_comptime_primitives_at_build@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 35}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 233}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 233}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
