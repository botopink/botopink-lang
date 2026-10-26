{module, bp_load_cases_decorator_expr_message_runtime@main@@Signup}.
{exports, [{validate, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 11}.

{function, validate, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_decorator_expr_message_runtime@main@@Signup.erl", 3}]}.
    {func_info, {atom, bp_load_cases_decorator_expr_message_runtime@main@@Signup}, {atom, validate}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_decorator_expr_message_runtime@main, passwordsMatch, 1}}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 4}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"confirm">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"signup.mismatch">>}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_decorator_expr_message_runtime@main, t, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_expr_message_runtime@main@@Violation}, {y, 2}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_get', 2, 6}.
  {label, 5}.
    {line, [{location, "bp_load_cases_decorator_expr_message_runtime@main@@Signup.erl", 4}]}.
    {func_info, {atom, bp_load_cases_decorator_expr_message_runtime@main@@Signup}, {atom, '__bp_get'}, 2}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, password}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {test, is_eq_exact, {f, 8}, [{x, 1}, {atom, confirm}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 8}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 10}.
  {label, 9}.
    {line, [{location, "bp_load_cases_decorator_expr_message_runtime@main@@Signup.erl", 4}]}.
    {func_info, {atom, bp_load_cases_decorator_expr_message_runtime@main@@Signup}, {atom, '__bp_format'}, 1}.
  {label, 10}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"confirm">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"password">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Signup">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
