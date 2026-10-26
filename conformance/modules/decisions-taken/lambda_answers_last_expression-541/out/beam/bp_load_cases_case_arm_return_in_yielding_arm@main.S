{module, bp_load_cases_case_arm_return_in_yielding_arm@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__items', 1}]}.
{attributes, []}.
{labels, 249}.
%%% Decision 541 (2) — a `case` arm that yields is a scope of the enclosing
%%% generator, so a `return` in it ends that generator: nothing after the
%%% `case` is emitted.

%% @Iter — lazy lowering
{function, items, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, items}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 78}}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 149}, 0, 0, {x, 0}, {list, []}}.
    {call, 2, {f, 179}}.
    {move, {literal, <<"--">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 151}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 246}, 0, 0, {x, 0}, {list, []}}.
    {call, 2, {f, 179}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/case_arm_return_in_yielding_arm|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__items', 1, 248}.
  {label, 247}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_priv__items'}, 1}.
  {label, 248}.
    {call_only, 1, {f, 3}}.

{function, '__bp_tpl_0--t/1-fun-0--fun-1-', 1, 28}.
  {label, 27}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_0--t/1-fun-0--fun-1-'}, 1}.
  {label, 28}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 33}}.
  {label, 31}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 33}}.
  {label, 32}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 33}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 30}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 27}}.

{function, '__bp_tpl_0-t/1-fun-0-', 0, 24}.
  {label, 23}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 0}.
  {label, 24}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_0--t/1-fun-2--fun-3-', 1, 45}.
  {label, 44}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_0--t/1-fun-2--fun-3-'}, 1}.
  {label, 45}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 47}, [{x, 0}]}.
    {test, test_arity, {f, 47}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 47}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 44}}.

{function, '__bp_tpl_0-t/1-fun-2-', 1, 37}.
  {label, 36}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_0-t/1-fun-2-'}, 1}.
  {label, 37}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 41}}.
  {label, 41}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 43}}.
  {label, 43}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 48}}.
  {label, 49}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 52}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_0-t/1-fun-4-', 3, 57}.
  {label, 56}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_0-t/1-fun-4-'}, 3}.
  {label, 57}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 60}, [{x, 0}]}.
    {test, test_arity, {f, 60}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {atom, item}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {jump, {f, 63}}.
  {label, 63}.
  {label, 64}.
    {loop_rec, {f, 65}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 68}, [{x, 0}]}.
    {test, test_arity, {f, 68}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {x, 1}]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 68}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {get_tuple_element, {x, 0}, 4, {y, 13}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 10}, {y, 6}}.
    {move, {y, 11}, {y, 5}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    remove_message.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {y, 3}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 71}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 72}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 69}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 13}}.
    {move, nil, {y, 14}}.
    {loop_rec_end, {f, 64}}.
  {label, 65}.
    {wait, {f, 64}}.

{function, '__bp_tpl_0', 1, 20}.
  {label, 19}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 20}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 35}}.
  {label, 35}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 55}}.
  {label, 55}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 74}}.
  {label, 74}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-items/1-gen-0-', 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '-items/1-gen-0-'}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 76}, [{x, 0}, {integer, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 20}}.
    {jump, {f, 18}}.
  {label, 76}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {atom, ok}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 75}.
    {move, {integer, 9}, {x, 0}}.
    {call, 1, {f, 20}}.
  {label, 18}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 86}.
  {label, 85}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 86}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 88}, [{x, 0}]}.
    {test, test_arity, {f, 88}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 91}}.
  {label, 89}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 91}}.
  {label, 90}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 91}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 88}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 85}}.

{function, '__bp_tpl_1-t/1-fun-0-', 0, 82}.
  {label, 81}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 0}.
  {label, 82}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 86}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_1--t/1-fun-2--fun-3-', 1, 103}.
  {label, 102}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1--t/1-fun-2--fun-3-'}, 1}.
  {label, 103}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 105}, [{x, 0}]}.
    {test, test_arity, {f, 105}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 105}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 102}}.

{function, '__bp_tpl_1-t/1-fun-2-', 1, 95}.
  {label, 94}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1-t/1-fun-2-'}, 1}.
  {label, 95}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 99}}.
  {label, 99}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 101}}.
  {label, 101}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 103}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 106}}.
  {label, 107}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 106}}.
  {label, 106}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 110}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 110}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_1--t/1-fun-4--fun-5-', 4, 121}.
  {label, 120}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1--t/1-fun-4--fun-5-'}, 4}.
  {label, 121}.
    {allocate, 33, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {atom, process}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, monitor, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 4}}.
    {jump, {f, 125}}.
  {label, 125}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 16}}.
  {label, 126}.
    {loop_rec, {f, 127}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 130}, [{x, 0}]}.
    {test, test_arity, {f, 130}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 130}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_eq_exact, {f, 130}, [{x, 0}, {x, 1}]}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 130}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 130}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 131}, [{x, 0}]}.
    {test, test_arity, {f, 131}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {get_tuple_element, {x, 0}, 3, {y, 20}}.
    {get_tuple_element, {x, 0}, 4, {y, 21}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 18}, {y, 6}}.
    {move, {y, 19}, {y, 5}}.
    {move, {y, 20}, {y, 7}}.
    {move, {y, 21}, {y, 8}}.
    remove_message.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 22}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {y, 7}]}}.
    {move, {x, 0}, {y, 22}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 22}}.
    {jump, {f, 132}}.
  {label, 133}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{x, 0}, {atom, next}]}.
    {'try', {y, 32}, {f, 135}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {y, 23}}.
    {try_end, {y, 32}}.
    {jump, {f, 136}}.
  {label, 135}.
    {try_case, {y, 32}}.
    {move, {x, 0}, {y, 24}}.
    {move, {x, 1}, {y, 25}}.
    {move, {x, 2}, {y, 26}}.
    {move, {y, 24}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 0}, {atom, throw}]}.
    {move, {y, 25}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 23}}.
    {jump, {f, 137}}.
  {label, 138}.
    {move, {y, 24}, {y, 9}}.
    {move, {y, 25}, {y, 10}}.
    {move, {y, 26}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 11}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {test, is_tuple, {f, 141}, [{x, 0}]}.
    {test, test_arity, {f, 141}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 29}}.
    {get_tuple_element, {x, 0}, 1, {y, 30}}.
    {move, {y, 29}, {y, 12}}.
    {move, {y, 30}, {y, 13}}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 31}}.
    {test_heap, 7, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 13}, {atom, raise}, {y, 9}, {y, 10}, {y, 11}, {y, 31}]}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 31}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 31}, {y, 28}}.
    {jump, {f, 140}}.
  {label, 141}.
    {move, {y, 27}, {x, 0}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 28}}.
    {jump, {f, 140}}.
  {label, 142}.
    {move, {y, 27}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 140}.
    {move, {atom, normal}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, exit, 1}}.
  {label, 137}.
  {label, 136}.
    {move, {y, 23}, {y, 22}}.
    {jump, {f, 132}}.
  {label, 134}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 132}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_tuple, {f, 144}, [{x, 0}]}.
    {test, test_arity, {f, 144}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 23}}.
    {get_tuple_element, {x, 0}, 1, {y, 24}}.
    {move, {y, 23}, {y, 14}}.
    {move, {y, 24}, {y, 15}}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 25}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 15}, {atom, done}, {y, 25}]}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, send, 2}, 33}.
  {label, 144}.
    {move, {y, 22}, {x, 0}}.
    {test, is_eq_exact, {f, 145}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 145}.
    {move, {y, 22}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 131}.
    {move, nil, {y, 16}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 17}}.
    {move, nil, {y, 18}}.
    {move, nil, {y, 19}}.
    {move, nil, {y, 20}}.
    {move, nil, {y, 21}}.
    {move, nil, {y, 22}}.
    {move, nil, {y, 23}}.
    {move, nil, {y, 24}}.
    {move, nil, {y, 25}}.
    {move, nil, {y, 26}}.
    {move, nil, {y, 27}}.
    {move, nil, {y, 28}}.
    {move, nil, {y, 29}}.
    {move, nil, {y, 30}}.
    {move, nil, {y, 31}}.
    {loop_rec_end, {f, 126}}.
  {label, 127}.
    {wait, {f, 126}}.

{function, '__bp_tpl_1-t/1-fun-4-', 3, 115}.
  {label, 114}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1-t/1-fun-4-'}, 3}.
  {label, 115}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 119}}.
  {label, 119}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 121}, 2, 0, {x, 0}, {list, [{y, 2}, {y, 0}, {y, 3}, {y, 1}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, spawn, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen'}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_1', 1, 78}.
  {label, 77}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 78}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 82}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 93}}.
  {label, 93}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 95}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 113}}.
  {label, 113}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 115}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 147}}.
  {label, 147}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '__bp_print', 1, 151}.
  {label, 150}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_print'}, 1}.
  {label, 151}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 155}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 155}.
  {label, 154}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 155}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 153}}.

{function, '-bp_show_elem-', 1, 157}.
  {label, 156}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 157}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 153}}.

{function, '__bp_show', 2, 153}.
  {label, 152}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_show'}, 2}.
  {label, 153}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 165}, [{x, 0}]}.
    {test, is_eq, {f, 164}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 164}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 165}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 166}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 166}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 168}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 167}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 167}, [{x, 0}]}.
    {test, is_ne_exact, {f, 167}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 167}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 167}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 172}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 173}}.
  {label, 172}.
    {test, is_eq_exact, {f, 169}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 173}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 153}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 167}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 168}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 170}, [{x, 0}]}.
    {test, is_ne_exact, {f, 170}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 170}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 171}, [{x, 0}, {atom, undefined}]}.
  {label, 169}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 159}, 2}.
  {label, 170}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 171}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 159}.
  {label, 158}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tagged'}, 2}.
  {label, 159}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 174}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 174}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 174}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 175}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 161}, 3}.
  {label, 175}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 161}.
  {label, 160}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_render'}, 1}.
  {label, 161}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 176}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 176}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 177}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 177}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 163}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 163}.
  {label, 162}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 163}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 153}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-1-', 1, 149}.
  {label, 148}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '-main/0-fun-1-'}, 1}.
  {label, 149}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 151}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_2--t/2-fun-0--fun-1-', 1, 189}.
  {label, 188}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2--t/2-fun-0--fun-1-'}, 1}.
  {label, 189}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 191}, [{x, 0}]}.
    {test, test_arity, {f, 191}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 192}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 194}}.
  {label, 192}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 193}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 194}}.
  {label, 193}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 194}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 191}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 188}}.

{function, '__bp_tpl_2-t/2-fun-0-', 0, 185}.
  {label, 184}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 0}.
  {label, 185}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 189}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_2--t/2-fun-2--fun-3-', 1, 206}.
  {label, 205}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2--t/2-fun-2--fun-3-'}, 1}.
  {label, 206}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 208}, [{x, 0}]}.
    {test, test_arity, {f, 208}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 208}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 205}}.

{function, '__bp_tpl_2-t/2-fun-2-', 1, 198}.
  {label, 197}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2-t/2-fun-2-'}, 1}.
  {label, 198}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 202}}.
  {label, 202}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 204}}.
  {label, 204}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 206}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 210}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 209}}.
  {label, 210}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 209}}.
  {label, 209}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 213}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 213}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_2-t/2-fun-4-', 4, 218}.
  {label, 217}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2-t/2-fun-4-'}, 4}.
  {label, 218}.
    {allocate, 18, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {atom, process}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, monitor, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {jump, {f, 222}}.
  {label, 222}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen'}, {y, 9}, {y, 10}, {y, 2}, {y, 11}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 10}}.
  {label, 223}.
    {loop_rec, {f, 224}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 227}, [{x, 0}]}.
    {test, test_arity, {f, 227}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {x, 1}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {atom, item}]}.
    {move, {y, 13}, {y, 6}}.
    {move, {y, 14}, {y, 4}}.
    remove_message.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [flush]}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, demonitor, 2}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 227}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 228}, [{x, 0}]}.
    {test, test_arity, {f, 228}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {x, 1}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, done}]}.
    {move, {y, 13}, {y, 4}}.
    remove_message.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [flush]}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, demonitor, 2}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 14}}.
    {move, nil, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 228}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 229}, [{x, 0}]}.
    {test, test_arity, {f, 229}, [{x, 0}, 6]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {get_tuple_element, {x, 0}, 5, {y, 16}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {x, 1}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, raise}]}.
    {move, {y, 13}, {y, 7}}.
    {move, {y, 14}, {y, 3}}.
    {move, {y, 15}, {y, 5}}.
    {move, {y, 16}, {y, 4}}.
    remove_message.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [flush]}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, demonitor, 2}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {call_ext_last, 3, {extfunc, erlang, raise, 3}, 18}.
  {label, 229}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 230}, [{x, 0}]}.
    {test, test_arity, {f, 230}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {x, 1}]}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, nil, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 230}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 13}}.
    {move, nil, {y, 14}}.
    {move, nil, {y, 15}}.
    {move, nil, {y, 16}}.
    {move, nil, {y, 17}}.
    {loop_rec_end, {f, 223}}.
  {label, 224}.
    {wait, {f, 223}}.

{function, '__bp_tpl_2-t/2-fun-5-', 3, 234}.
  {label, 233}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2-t/2-fun-5-'}, 3}.
  {label, 234}.
    {allocate, 8, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 234}, 2, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, next}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 238}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 6}}.
    {move, {y, 5}, {y, 3}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 238}, [{x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_last, 3, {f, 234}, 8}.
  {label, 238}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 239}, [{x, 0}, nil]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 239}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 2, 179}.
  {label, 178}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '__bp_tpl_2'}, 2}.
  {label, 179}.
    {allocate, 15, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 183}, [{x, 0}]}.
    {test, test_arity, {f, 183}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 185}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 196}}.
  {label, 196}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 198}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 2}}.
    {jump, {f, 216}}.
  {label, 216}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 218}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 232}}.
  {label, 232}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 234}, 2, 0, {x, 0}, {list, [{y, 1}, {y, 0}, {y, 5}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 2}}.
    {jump, {f, 241}}.
  {label, 241}.
    {'try', {y, 14}, {f, 242}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 9}}.
    {try_end, {y, 14}}.
    {jump, {f, 243}}.
  {label, 242}.
    {try_case, {y, 14}}.
    {move, {x, 0}, {y, 10}}.
    {move, {x, 1}, {y, 11}}.
    {move, {x, 2}, {y, 12}}.
    {move, {y, 10}, {y, 2}}.
    {move, {y, 11}, {y, 3}}.
    {move, {y, 12}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, close}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, raise, 3}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 9}}.
    {jump, {f, 244}}.
  {label, 244}.
  {label, 243}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 183}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, foreach, 2}, 15}.

{function, '-main/0-fun-2-', 1, 246}.
  {label, 245}.
    {line, [{location, "bp_load_cases_case_arm_return_in_yielding_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_arm_return_in_yielding_arm@main}, {atom, '-main/0-fun-2-'}, 1}.
  {label, 246}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 151}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
