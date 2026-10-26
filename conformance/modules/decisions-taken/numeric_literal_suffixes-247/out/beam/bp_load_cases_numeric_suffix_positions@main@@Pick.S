{module, bp_load_cases_numeric_suffix_positions@main@@Pick}.
{exports, [{'band', 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 12}.

{function, 'band', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Pick.erl", 9}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Pick}, {atom, 'band'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, bp_load_cases_numeric_suffix_positions@main@@Pick}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 6}, [{integer, 5}, {y, 1}]}.
    {move, {literal, <<"high">>}, {x, 0}}.
    {deallocate, 2}.
    return.
    {jump, {f, 5}}.
  {label, 6}.
    {move, {x, 1}, {x, 0}}.
    {move, {literal, <<"low">>}, {x, 0}}.
    {deallocate, 2}.
    return.
    {jump, {f, 5}}.
  {label, 5}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Pick.erl", 10}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Pick}, {atom, '__bp_get'}, 2}.
  {label, 8}.
    {test, is_eq_exact, {f, 9}, [{x, 1}, {atom, n}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 9}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Pick.erl", 10}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Pick}, {atom, '__bp_format'}, 1}.
  {label, 11}.
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
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Pick">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
