{module, bp_load_cases_comptime_type_param_of_method@main@@Registry}.
{exports, [{times, 2}, {count__Users, 1}, {count__Orders, 1}, {weighted__Users, 2}, {weighted__Orders, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 36}.

{function, times, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, times}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 12}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 2, {extfunc, bp_load_cases_comptime_type_param_of_method@main, scaled, 2}, 2}.

{function, count__Users, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, count__Users}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 21}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, count__Orders, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, count__Orders}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 30}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 30}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, weighted__Users, 2, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, weighted__Users}, 2}.
  {label, 9}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 2, {extfunc, bp_load_cases_comptime_type_param_of_method@main, scaled, 2}, 4}.

{function, weighted__Orders, 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 6}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, weighted__Orders}, 2}.
  {label, 11}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 2, {extfunc, bp_load_cases_comptime_type_param_of_method@main, scaled, 2}, 4}.

{function, '__bp_get', 2, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, '__bp_get'}, 2}.
  {label, 32}.
    {test, is_eq_exact, {f, 33}, [{x, 1}, {atom, entries}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 33}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, '__bp_format'}, 1}.
  {label, 35}.
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

{function, '-scaled/1-fun-0-', 2, 14}.
  {label, 13}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, '-scaled/1-fun-0-'}, 2}.
  {label, 14}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_param_of_method@main@@Users}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {atom, false}, {x, 0}}.
  {label, 17}.
    {test, is_eq, {f, 15}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 18}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 18}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:24:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 19}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 20}}.
  {label, 15}.
  {label, 20}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-scaled/1-fun-1-', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_comptime_type_param_of_method@main@@Registry.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_type_param_of_method@main@@Registry}, {atom, '-scaled/1-fun-1-'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 25}, [{x, 0}, 2, {atom, bp_load_cases_comptime_type_param_of_method@main@@Orders}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {atom, false}, {x, 0}}.
  {label, 26}.
    {test, is_eq, {f, 24}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 27}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 27}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:24:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 28}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 29}}.
  {label, 24}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
