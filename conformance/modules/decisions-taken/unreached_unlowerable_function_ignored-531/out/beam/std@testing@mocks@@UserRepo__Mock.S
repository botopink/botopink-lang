{module, std@testing@mocks@@UserRepo__Mock}.
{exports, [{find, 2}, {all, 1}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 96}.

{function, find, 2, 3}.
  {label, 2}.
    {line, [{location, "std@testing@mocks@@UserRepo__Mock.erl", 24}]}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, find}, 2}.
  {label, 3}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 85}, [{x, 0}, 2, {atom, std@testing@mocks@@UserRepo__Mock}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 85}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"find">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 87}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 4, {f, 7}, 7}.

{function, all, 1, 5}.
  {label, 4}.
    {line, [{location, "std@testing@mocks@@UserRepo__Mock.erl", 25}]}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, all}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, std@testing@mocks@@UserRepo__Mock}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 88}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"all">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 1}, {x, 4}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 4}, {x, 0}}.
    {call_last, 4, {f, 7}, 1}.

{function, '__bp_get', 2, 90}.
  {label, 89}.
    {line, [{location, "std@testing@mocks@@UserRepo__Mock.erl", 26}]}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_get'}, 2}.
  {label, 90}.
    {test, is_eq_exact, {f, 91}, [{x, 1}, {atom, '__id'}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 91}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 93}.
  {label, 92}.
    {line, [{location, "std@testing@mocks@@UserRepo__Mock.erl", 26}]}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_format'}, 1}.
  {label, 93}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"__id">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"UserRepo.Mock">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 95}.
  {label, 94}.
    {line, [{location, "std@testing@mocks@@UserRepo__Mock.erl", 26}]}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_behaviors'}, 0}.
  {label, 95}.
    {move, {literal, [std@testing@mocks@@UserRepo]}, {x, 0}}.
    return.

{function, '__bp_tpl_0---t/4-fun-0--fun-1--fun-2-', 1, 36}.
  {label, 35}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_tpl_0---t/4-fun-0--fun-1--fun-2-'}, 1}.
  {label, 36}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 38}, [{x, 0}]}.
    {test, test_arity, {f, 38}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 38}, [{x, 0}]}.
    {test, test_arity, {f, 38}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 5}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"any">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 8}}.
    {jump, {f, 41}}.
  {label, 39}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 8}}.
    {jump, {f, 41}}.
  {label, 40}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 41}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 38}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    {jump, {f, 35}}.

{function, '__bp_tpl_0--t/4-fun-0--fun-1-', 2, 29}.
  {label, 28}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_tpl_0--t/4-fun-0--fun-1-'}, 2}.
  {label, 29}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, zip, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 34}}.
  {label, 32}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 34}}.
  {label, 33}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 34}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_0-t/4-fun-0-', 4, 11}.
  {label, 10}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_tpl_0-t/4-fun-0-'}, 4}.
  {label, 11}.
    {allocate, 20, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 9}}.
    {move, {x, 3}, {y, 10}}.
    {move, {atom, '__bp_mocks_pending'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 15}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 12}}.
    {jump, {f, 14}}.
  {label, 15}.
    {move, {y, 11}, {y, 0}}.
    {move, {y, 0}, {y, 12}}.
    {jump, {f, 14}}.
  {label, 14}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 18}}.
  {label, 18}.
    {move, {atom, '__bp_mocks_pending'}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {y, 12}}.
    {jump, {f, 19}}.
  {label, 20}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, false}]}.
    {move, nil, {y, 13}}.
    {move, {y, 9}, {y, 14}}.
  {label, 23}.
    {move, {y, 14}, {x, 0}}.
    {test, is_nonempty_list, {f, 24}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 14}}.
    {move, {y, 15}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"eq">>}, {y, 0}]}}.
    {move, {x, 0}, {y, 16}}.
    {test_heap, 2, 0}.
    {put_list, {y, 16}, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {jump, {f, 23}}.
  {label, 24}.
    {move, {y, 14}, {x, 0}}.
    {test, is_nil, {f, 25}, [{x, 0}]}.
    {jump, {f, 22}}.
  {label, 25}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 14}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 22}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 12}}.
    {jump, {f, 19}}.
  {label, 21}.
    {move, {y, 11}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 19}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 27}}.
  {label, 27}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 1}}.
    {jump, {f, 43}}.
  {label, 43}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 12}}.
    {jump, {f, 44}}.
  {label, 45}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 2}, {y, 12}}.
    {jump, {f, 44}}.
  {label, 44}.
    {move, {y, 12}, {y, 2}}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {atom, '__bp_mocks_verify'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 7}, {y, 8}, {y, 9}, {y, 0}]}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, nil, {y, 12}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 15}}.
    {jump, {f, 52}}.
  {label, 53}.
    {move, {y, 14}, {y, 3}}.
    {move, {y, 3}, {y, 15}}.
    {jump, {f, 52}}.
  {label, 52}.
    {move, {y, 15}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 13}}.
  {label, 55}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 56}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 13}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {test, test_arity, {f, 55}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 16}}.
    {get_tuple_element, {x, 0}, 1, {y, 17}}.
    {get_tuple_element, {x, 0}, 2, {y, 18}}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 3}}.
    {move, {y, 18}, {y, 5}}.
    {move, {y, 15}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {x, 1}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {x, 1}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {atom, true}]}.
    {jump, {f, 60}}.
  {label, 58}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, false}]}.
    {jump, {f, 55}}.
  {label, 59}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 19}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 55}}.
  {label, 56}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 57}, [{x, 0}]}.
    {jump, {f, 51}}.
  {label, 57}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 3}}.
    {jump, {f, 62}}.
  {label, 62}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, nil]}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 64}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 65}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 65}, [{x, 0}]}.
    {test, test_arity, {f, 65}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, return}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 65}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 66}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 66}, [{x, 0}]}.
    {test, test_arity, {f, 66}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, throw}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 20}.
  {label, 66}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 50}.
    {move, {y, 11}, {y, 3}}.
    {move, nil, {y, 12}}.
    {move, {y, 2}, {y, 13}}.
  {label, 69}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 70}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 14}, {y, 13}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 15}}.
    {get_tuple_element, {x, 0}, 1, {y, 16}}.
    {get_tuple_element, {x, 0}, 2, {y, 17}}.
    {move, {y, 15}, {y, 2}}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {x, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {x, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {atom, true}]}.
    {jump, {f, 74}}.
  {label, 72}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, false}]}.
    {jump, {f, 69}}.
  {label, 73}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 18}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 74}.
    {test_heap, 2, 0}.
    {put_list, {atom, x}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 69}}.
  {label, 70}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 71}, [{x, 0}]}.
    {jump, {f, 68}}.
  {label, 71}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 68}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 76}}.
  {label, 76}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {integer, -1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 12}}.
    {jump, {f, 77}}.
  {label, 78}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 12}}.
    {jump, {f, 77}}.
  {label, 77}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, true}]}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 81}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {integer, -1}]}.
    {move, {literal, <<"at least 1">>}, {y, 13}}.
    {jump, {f, 83}}.
  {label, 84}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 4, 0}.
    {put_list, {y, 14}, nil, {x, 0}}.
    {put_list, {literal, <<"exactly ">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 13}}.
    {jump, {f, 83}}.
  {label, 83}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 12, 0}.
    {put_list, {y, 14}, nil, {x, 0}}.
    {put_list, {literal, <<" matching call(s), got ">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 13}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<" - expected ">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 8}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"mocks.verify: ">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 20}.
  {label, 82}.
    {move, {y, 12}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 4, 7}.
  {label, 6}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_tpl_0'}, 4}.
  {label, 7}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_1', 1, 87}.
  {label, 86}.
    {func_info, {atom, std@testing@mocks@@UserRepo__Mock}, {atom, '__bp_tpl_1'}, 1}.
  {label, 87}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 48, 116, 112]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 2}.
