{module, bp_load_cases_is_behavior_identity_run_time@main@@Mark}.
{exports, [{shown, 1}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 10}.

{function, shown, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main@@Mark.erl", 2}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark}, {atom, shown}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"mark">>}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_format', 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main@@Mark.erl", 3}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark}, {atom, '__bp_format'}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__plain}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Mark.Plain">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 2, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__named}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"text">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Mark.Named">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Mark">>}, nil]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main@@Mark.erl", 3}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark}, {atom, '__bp_behaviors'}, 0}.
  {label, 9}.
    {move, {literal, [bp_load_cases_is_behavior_identity_run_time@main@@Shown]}, {x, 0}}.
    return.
