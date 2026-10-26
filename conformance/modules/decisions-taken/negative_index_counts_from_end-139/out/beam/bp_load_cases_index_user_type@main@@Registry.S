{module, bp_load_cases_index_user_type@main@@Registry}.
{exports, [{at, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 17}.

{function, at, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Registry.erl", 5}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Registry}, {atom, at}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, bp_load_cases_index_user_type@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 6}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 9}, [{y, 2}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 9}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Registry.erl", 6}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Registry}, {atom, '__bp_get'}, 2}.
  {label, 11}.
    {test, is_eq_exact, {f, 12}, [{x, 1}, {atom, names}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 12}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 14}.
  {label, 13}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Registry.erl", 6}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Registry}, {atom, '__bp_format'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"names">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Registry">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 16}.
  {label, 15}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Registry.erl", 6}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Registry}, {atom, '__bp_behaviors'}, 0}.
  {label, 16}.
    {move, {literal, [std@primitives@@Index]}, {x, 0}}.
    return.

{function, '-bp_indexOf-', 3, 6}.
  {label, 5}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Registry.erl", 6}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Registry}, {atom, '-bp_indexOf-'}, 3}.
  {label, 6}.
    {test, is_nonempty_list, {f, 7}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 8}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 8}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 6}}.
  {label, 7}.
    {move, {integer, -1}, {x, 0}}.
    return.
