{module, bp_load_cases_compiler_decorator_three_kinds@main@@Account}.
{exports, [{validate, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, validate, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main@@Account.erl", 4}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main@@Account}, {atom, validate}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_compiler_decorator_three_kinds@main, positive, 1}}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"negative balance (positive)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_decorator_three_kinds@main@@Violation}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"negative balance">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_decorator_three_kinds@main@@Violation}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 6}.
  {label, 5}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main@@Account.erl", 5}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main@@Account}, {atom, '__bp_get'}, 2}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, balance}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main@@Account.erl", 5}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main@@Account}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"balance">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Account">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
