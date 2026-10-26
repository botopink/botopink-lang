{module, bp_load_cases_method_tail_value@main@@Box}.
{exports, [{get, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, get, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_method_tail_value@main@@Box.erl", 4}]}.
    {func_info, {atom, bp_load_cases_method_tail_value@main@@Box}, {atom, get}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, bp_load_cases_method_tail_value@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 6}.
  {label, 5}.
    {line, [{location, "bp_load_cases_method_tail_value@main@@Box.erl", 5}]}.
    {func_info, {atom, bp_load_cases_method_tail_value@main@@Box}, {atom, '__bp_get'}, 2}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, value}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_method_tail_value@main@@Box.erl", 5}]}.
    {func_info, {atom, bp_load_cases_method_tail_value@main@@Box}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"value">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Box">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
