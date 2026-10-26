{module, bp_load_cases_numeric_suffix_positions@main@@Item}.
{exports, [{tag, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 14}.

{function, tag, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Item.erl", 8}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Item}, {atom, tag}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, bp_load_cases_numeric_suffix_positions@main@@Item}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 5}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 5}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 6}}.
  {label, 5}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:53:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 6}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Item.erl", 9}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Item}, {atom, '__bp_get'}, 2}.
  {label, 8}.
    {test, is_eq_exact, {f, 9}, [{x, 1}, {atom, id}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 9}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Item.erl", 9}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Item}, {atom, '__bp_format'}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"id">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Item">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Item.erl", 9}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Item}, {atom, '__bp_behaviors'}, 0}.
  {label, 13}.
    {move, {literal, [bp_load_cases_numeric_suffix_positions@main@@Tag]}, {x, 0}}.
    return.
