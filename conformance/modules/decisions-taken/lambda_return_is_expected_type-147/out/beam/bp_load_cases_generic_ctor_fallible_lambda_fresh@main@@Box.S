{module, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}.
{exports, [{optional, 1}, {array, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 17}.

{function, optional, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box.erl", 1}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {atom, optional}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 8}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, array, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box.erl", 2}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {atom, array}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 2, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 9}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box.erl", 3}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {atom, '__bp_get'}, 2}.
  {label, 13}.
    {test, is_eq_exact, {f, 14}, [{x, 1}, {atom, run}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 14}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 16}.
  {label, 15}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box.erl", 3}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {atom, '__bp_format'}, 1}.
  {label, 16}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"run">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Box">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-0-', 2, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box.erl", 2}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {atom, '-/1-fun-0-'}, 2}.
  {label, 8}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_load_cases_generic_ctor_fallible_lambda_fresh@main, optionalOf, 2}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-1-', 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box.erl", 3}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {atom, '-/1-fun-1-'}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_load_cases_generic_ctor_fallible_lambda_fresh@main, arrayOf, 2}}.
    {deallocate, 2}.
    return.
