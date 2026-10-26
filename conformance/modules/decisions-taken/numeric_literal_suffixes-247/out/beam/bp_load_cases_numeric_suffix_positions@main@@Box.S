{module, bp_load_cases_numeric_suffix_positions@main@@Box}.
{exports, [{grow, 2}, {make, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 15}.

{function, grow, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Box.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Box}, {atom, grow}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 3, {atom, bp_load_cases_numeric_suffix_positions@main@@Box}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 6}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 7}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 7}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 8}}.
  {label, 7}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:33:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 8}.
    {deallocate, 2}.
    return.

{function, make, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Box.erl", 6}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Box}, {atom, make}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 10}.
  {label, 9}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Box.erl", 7}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Box}, {atom, '__bp_get'}, 2}.
  {label, 10}.
    {test, is_eq_exact, {f, 11}, [{x, 1}, {atom, label}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 11}.
    {test, is_eq_exact, {f, 12}, [{x, 1}, {atom, size}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 12}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 14}.
  {label, 13}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Box.erl", 7}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Box}, {atom, '__bp_format'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"size">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"label">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Box">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
