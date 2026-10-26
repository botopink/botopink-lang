{module, bp_load_cases_optional_unknown_takes_function@main@@Hook}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 5}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main@@Hook.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main@@Hook}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 3, {atom, bp_load_cases_optional_unknown_takes_function@main@@Hook__v__run}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"note">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"body">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Hook.Run">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Hook">>}, nil]}}.
    {deallocate, 2}.
    return.
