{module, bp_load_cases_behavior_static_written_fn@main@@Dot}.
{exports, [{make, 0}, {area, 1}, {describe, 1}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 15}.

{function, make, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Dot.erl", 8}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {atom, make}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {integer, 0}]}}.
    {deallocate, 0}.
    return.

{function, area, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Dot.erl", 9}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {atom, area}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, describe, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Dot.erl", 10}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {atom, describe}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a dot">>}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Dot.erl", 11}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {atom, '__bp_get'}, 2}.
  {label, 9}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {atom, n}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 10}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 12}.
  {label, 11}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Dot.erl", 11}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {atom, '__bp_format'}, 1}.
  {label, 12}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"n">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Dot">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 14}.
  {label, 13}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Dot.erl", 11}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Dot}, {atom, '__bp_behaviors'}, 0}.
  {label, 14}.
    {move, {literal, [bp_load_cases_behavior_static_written_fn@main@@Shape]}, {x, 0}}.
    return.
