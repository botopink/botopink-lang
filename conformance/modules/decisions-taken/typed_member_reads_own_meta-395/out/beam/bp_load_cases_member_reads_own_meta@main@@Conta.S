{module, bp_load_cases_member_reads_own_meta@main@@Conta}.
{exports, [{validate, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 19}.

{function, validate, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_member_reads_own_meta@main@@Conta.erl", 3}]}.
    {func_info, {atom, bp_load_cases_member_reads_own_meta@main@@Conta}, {atom, validate}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"the handle is taken">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, fun bp_load_cases_member_reads_own_meta@main:handleFree/1}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_member_reads_own_meta@main@@Check}, {x, 1}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"the passwords differ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, fun bp_load_cases_member_reads_own_meta@main:passwordsMatch/1}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_member_reads_own_meta@main@@Check}, {x, 1}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 5}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_member_reads_own_meta@main@@Conta.erl", 4}]}.
    {func_info, {atom, bp_load_cases_member_reads_own_meta@main@@Conta}, {atom, '__bp_get'}, 2}.
  {label, 13}.
    {test, is_eq_exact, {f, 14}, [{x, 1}, {atom, handle}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 14}.
    {test, is_eq_exact, {f, 15}, [{x, 1}, {atom, password}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 15}.
    {test, is_eq_exact, {f, 16}, [{x, 1}, {atom, confirm}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 16}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 18}.
  {label, 17}.
    {line, [{location, "bp_load_cases_member_reads_own_meta@main@@Conta.erl", 4}]}.
    {func_info, {atom, bp_load_cases_member_reads_own_meta@main@@Conta}, {atom, '__bp_format'}, 1}.
  {label, 18}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"confirm">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"password">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"handle">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Conta">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-handleFree/1-fun-0-', 3, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_member_reads_own_meta@main@@Conta.erl", 4}]}.
    {func_info, {atom, bp_load_cases_member_reads_own_meta@main@@Conta}, {atom, '-handleFree/1-fun-0-'}, 3}.
  {label, 5}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, bp_load_cases_member_reads_own_meta@main@@Check}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 7}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 1}.
    {test, is_eq, {f, 8}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {atom, true}, {x, 0}}.
  {label, 9}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"conta">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 3, {atom, bp_load_cases_member_reads_own_meta@main@@Check}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 10}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_member_reads_own_meta@main@@Violation}, {x, 1}, {x, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 11}}.
  {label, 6}.
  {label, 11}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
