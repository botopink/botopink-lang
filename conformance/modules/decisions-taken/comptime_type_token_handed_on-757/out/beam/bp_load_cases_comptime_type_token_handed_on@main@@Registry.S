{module, bp_load_cases_comptime_type_token_handed_on@main@@Registry}.
{exports, [{count__Users, 1}, {count__Orders, 1}, {get__Users, 1}, {get__Orders, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 55}.

{function, count__Users, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, count__Users}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 18}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, count__Orders, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, count__Orders}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 27}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, get__Users, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, get__Users}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 34}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
    {'try', {y, 1}, {f, 35}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 1}}.
    {jump, {f, 38}}.
  {label, 35}.
    {try_case, {y, 1}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 36}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 36}.
    {test, is_tagged_tuple, {f, 37}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 37}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 38}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, get__Orders, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, get__Orders}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 45}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 45}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
    {'try', {y, 1}, {f, 46}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 1}}.
    {jump, {f, 49}}.
  {label, 46}.
    {try_case, {y, 1}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 47}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {test, is_tagged_tuple, {f, 48}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 49}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, '__bp_get'}, 2}.
  {label, 51}.
    {test, is_eq_exact, {f, 52}, [{x, 1}, {atom, entries}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 52}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, '__bp_format'}, 1}.
  {label, 54}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"entries">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Registry">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-0-', 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, '-/1-fun-0-'}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Users}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 14}}.
  {label, 13}.
    {move, {atom, false}, {x, 0}}.
  {label, 14}.
    {test, is_eq, {f, 12}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 15}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 15}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 16}}.
  {label, 15}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:17:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 16}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 17}}.
  {label, 12}.
  {label, 17}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-1-', 2, 20}.
  {label, 19}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, '-/1-fun-1-'}, 2}.
  {label, 20}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Orders}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {atom, false}, {x, 0}}.
  {label, 23}.
    {test, is_eq, {f, 21}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 24}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 24}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:17:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 25}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 26}}.
  {label, 21}.
  {label, 26}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-2-', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, '-/1-fun-2-'}, 1}.
  {label, 30}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Users}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, false}, {x, 0}}.
  {label, 33}.
    {test, is_eq, {f, 31}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_return'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 31}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-/1-fun-3-', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_comptime_type_token_handed_on@main@@Registry.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Registry}, {atom, '-/1-fun-3-'}, 1}.
  {label, 41}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 43}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_token_handed_on@main@@Orders}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 43}.
    {move, {atom, false}, {x, 0}}.
  {label, 44}.
    {test, is_eq, {f, 42}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_return'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 42}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
