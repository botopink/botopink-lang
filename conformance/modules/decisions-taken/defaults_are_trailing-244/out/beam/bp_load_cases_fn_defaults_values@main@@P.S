{module, bp_load_cases_fn_defaults_values@main@@P}.
{exports, [{bump, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 13}.

{function, bump, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_fn_defaults_values@main@@P.erl", 2}]}.
    {func_info, {atom, bp_load_cases_fn_defaults_values@main@@P}, {atom, bump}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 3, {atom, bp_load_cases_fn_defaults_values@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 5}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 5}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 6}}.
  {label, 5}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:19:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 6}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_fn_defaults_values@main@@P.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_defaults_values@main@@P}, {atom, '__bp_get'}, 2}.
  {label, 8}.
    {test, is_eq_exact, {f, 9}, [{x, 1}, {atom, y}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 9}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {atom, x}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 10}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 12}.
  {label, 11}.
    {line, [{location, "bp_load_cases_fn_defaults_values@main@@P.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_defaults_values@main@@P}, {atom, '__bp_format'}, 1}.
  {label, 12}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"x">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"y">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"P">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
