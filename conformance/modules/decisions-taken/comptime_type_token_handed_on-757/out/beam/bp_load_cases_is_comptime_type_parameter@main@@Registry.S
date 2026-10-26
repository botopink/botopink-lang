{module, bp_load_cases_is_comptime_type_parameter@main@@Registry}.
{exports, [{count__Users, 1}, {count__Orders, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 29}.

{function, count__Users, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_is_comptime_type_parameter@main@@Registry.erl", 1}]}.
    {func_info, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}, {atom, count__Users}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 2, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 14}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, count__Orders, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_is_comptime_type_parameter@main@@Registry.erl", 2}]}.
    {func_info, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}, {atom, count__Orders}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 2, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 23}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 16}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_is_comptime_type_parameter@main@@Registry.erl", 3}]}.
    {func_info, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}, {atom, '__bp_get'}, 2}.
  {label, 25}.
    {test, is_eq_exact, {f, 26}, [{x, 1}, {atom, entries}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_is_comptime_type_parameter@main@@Registry.erl", 3}]}.
    {func_info, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}, {atom, '__bp_format'}, 1}.
  {label, 28}.
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

{function, '-/1-fun-0-', 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_is_comptime_type_parameter@main@@Registry.erl", 2}]}.
    {func_info, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}, {atom, '-/1-fun-0-'}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 2, {atom, bp_load_cases_is_comptime_type_parameter@main@@Users}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 9}.
    {move, {atom, false}, {x, 0}}.
  {label, 10}.
    {test, is_eq, {f, 8}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 11}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 11}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 12}}.
  {label, 11}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:17:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 12}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 13}}.
  {label, 8}.
  {label, 13}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-1-', 2, 16}.
  {label, 15}.
    {line, [{location, "bp_load_cases_is_comptime_type_parameter@main@@Registry.erl", 3}]}.
    {func_info, {atom, bp_load_cases_is_comptime_type_parameter@main@@Registry}, {atom, '-/1-fun-1-'}, 2}.
  {label, 16}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 2, {atom, bp_load_cases_is_comptime_type_parameter@main@@Orders}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {atom, false}, {x, 0}}.
  {label, 19}.
    {test, is_eq, {f, 17}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 20}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 20}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:17:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 21}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 22}}.
  {label, 17}.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
