{module, std@testing@mocks@@Greeter__Mock}.
{exports, [{greet, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 93}.

{function, greet, 2, 3}.
  {label, 2}.
    {line, [{location, "std@testing@mocks@@Greeter__Mock.erl", 26}]}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, greet}, 2}.
  {label, 3}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 83}, [{x, 0}, 2, {atom, std@testing@mocks@@Greeter__Mock}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 83}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"greet">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 85}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 4, {f, 5}, 7}.

{function, '__bp_get', 2, 87}.
  {label, 86}.
    {line, [{location, "std@testing@mocks@@Greeter__Mock.erl", 27}]}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_get'}, 2}.
  {label, 87}.
    {test, is_eq_exact, {f, 88}, [{x, 1}, {atom, '__id'}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 88}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 90}.
  {label, 89}.
    {line, [{location, "std@testing@mocks@@Greeter__Mock.erl", 27}]}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_format'}, 1}.
  {label, 90}.
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
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Greeter.Mock">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 92}.
  {label, 91}.
    {line, [{location, "std@testing@mocks@@Greeter__Mock.erl", 27}]}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_behaviors'}, 0}.
  {label, 92}.
    {move, {literal, [std@testing@mocks@@Greeter]}, {x, 0}}.
    return.

{function, '__bp_tpl_0---t/4-fun-0--fun-1--fun-2-', 1, 34}.
  {label, 33}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_tpl_0---t/4-fun-0--fun-1--fun-2-'}, 1}.
  {label, 34}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {test, test_arity, {f, 36}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {test, test_arity, {f, 36}, [{x, 0}, 2]}.
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
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 8}}.
    {jump, {f, 39}}.
  {label, 37}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 8}}.
    {jump, {f, 39}}.
  {label, 38}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 39}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 36}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    {jump, {f, 33}}.

{function, '__bp_tpl_0--t/4-fun-0--fun-1-', 2, 27}.
  {label, 26}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_tpl_0--t/4-fun-0--fun-1-'}, 2}.
  {label, 27}.
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
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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
    {jump, {f, 32}}.
  {label, 30}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 32}}.
  {label, 31}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 32}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_0-t/4-fun-0-', 4, 9}.
  {label, 8}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_tpl_0-t/4-fun-0-'}, 4}.
  {label, 9}.
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
    {test, is_eq_exact, {f, 13}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 12}}.
    {jump, {f, 12}}.
  {label, 13}.
    {move, {y, 11}, {y, 0}}.
    {move, {y, 0}, {y, 12}}.
    {jump, {f, 12}}.
  {label, 12}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 16}}.
  {label, 16}.
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
    {test, is_eq_exact, {f, 18}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {y, 12}}.
    {jump, {f, 17}}.
  {label, 18}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 19}, [{x, 0}, {atom, false}]}.
    {move, nil, {y, 13}}.
    {move, {y, 9}, {y, 14}}.
  {label, 21}.
    {move, {y, 14}, {x, 0}}.
    {test, is_nonempty_list, {f, 22}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 14}}.
    {move, {y, 15}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"eq">>}, {y, 0}]}}.
    {move, {x, 0}, {y, 16}}.
    {test_heap, 2, 0}.
    {put_list, {y, 16}, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {jump, {f, 21}}.
  {label, 22}.
    {move, {y, 14}, {x, 0}}.
    {test, is_nil, {f, 23}, [{x, 0}]}.
    {jump, {f, 20}}.
  {label, 23}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 14}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 20}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 12}}.
    {jump, {f, 17}}.
  {label, 19}.
    {move, {y, 11}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 17}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 25}}.
  {label, 25}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 1}}.
    {jump, {f, 41}}.
  {label, 41}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 12}}.
    {jump, {f, 42}}.
  {label, 43}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 2}, {y, 12}}.
    {jump, {f, 42}}.
  {label, 42}.
    {move, {y, 12}, {y, 2}}.
    {jump, {f, 46}}.
  {label, 46}.
    {move, {atom, '__bp_mocks_verify'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
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
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 15}}.
    {jump, {f, 50}}.
  {label, 51}.
    {move, {y, 14}, {y, 3}}.
    {move, {y, 3}, {y, 15}}.
    {jump, {f, 50}}.
  {label, 50}.
    {move, {y, 15}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 13}}.
  {label, 53}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 54}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 13}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_tuple, {f, 53}, [{x, 0}]}.
    {test, test_arity, {f, 53}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 16}}.
    {get_tuple_element, {x, 0}, 1, {y, 17}}.
    {get_tuple_element, {x, 0}, 2, {y, 18}}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 3}}.
    {move, {y, 18}, {y, 5}}.
    {move, {y, 15}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {x, 1}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {x, 1}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, true}]}.
    {jump, {f, 58}}.
  {label, 56}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, false}]}.
    {jump, {f, 53}}.
  {label, 57}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 19}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 58}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 53}}.
  {label, 54}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 55}, [{x, 0}]}.
    {jump, {f, 49}}.
  {label, 55}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 49}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 3}}.
    {jump, {f, 60}}.
  {label, 60}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, nil]}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 62}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 63}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 63}, [{x, 0}]}.
    {test, test_arity, {f, 63}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, return}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 63}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 64}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, throw}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 20}.
  {label, 64}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 48}.
    {move, {y, 11}, {y, 3}}.
    {move, nil, {y, 12}}.
    {move, {y, 2}, {y, 13}}.
  {label, 67}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 68}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 14}, {y, 13}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tuple, {f, 67}, [{x, 0}]}.
    {test, test_arity, {f, 67}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 15}}.
    {get_tuple_element, {x, 0}, 1, {y, 16}}.
    {get_tuple_element, {x, 0}, 2, {y, 17}}.
    {move, {y, 15}, {y, 2}}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {x, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {x, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, true}]}.
    {jump, {f, 72}}.
  {label, 70}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, false}]}.
    {jump, {f, 67}}.
  {label, 71}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 18}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 72}.
    {test_heap, 2, 0}.
    {put_list, {atom, x}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 67}}.
  {label, 68}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 69}, [{x, 0}]}.
    {jump, {f, 66}}.
  {label, 69}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 66}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 74}}.
  {label, 74}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {integer, -1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 12}}.
    {jump, {f, 75}}.
  {label, 76}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 12}}.
    {jump, {f, 75}}.
  {label, 75}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, true}]}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 79}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, {integer, -1}]}.
    {move, {literal, <<"at least 1">>}, {y, 13}}.
    {jump, {f, 81}}.
  {label, 82}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 4, 0}.
    {put_list, {y, 14}, nil, {x, 0}}.
    {put_list, {literal, <<"exactly ">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 13}}.
    {jump, {f, 81}}.
  {label, 81}.
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
  {label, 80}.
    {move, {y, 12}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 4, 5}.
  {label, 4}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_tpl_0'}, 4}.
  {label, 5}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_1', 1, 85}.
  {label, 84}.
    {func_info, {atom, std@testing@mocks@@Greeter__Mock}, {atom, '__bp_tpl_1'}, 1}.
  {label, 85}.
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
