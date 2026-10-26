{module, bp_load_cases_is_behavior_identity_run_time@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__kind', 1}, {'__bp_priv__label', 1}, {'__bp_priv__say', 1}]}.
{attributes, []}.
{labels, 108}.
%%% Decision 810 (1) — at run time `is` tests a type's identity alone: a
%%% record's, and a behavior's (a record's or an enum's type implements it) — the value's type implements it — and a
%%% function type by its arity, on every target. A behavior type pattern
%%% (`Shown<unknown> { k -> … }`) is the same test. erlang and beam answered
%%% `false` for every behavior, commonJS named a class no module emits, wasm
%%% refused the test.

{function, kind, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, kind}, 1}.
  {label, 3}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Shown}, {x, 1}}.
    {call, 2, {f, 22}}.
    {test, is_eq, {f, 20}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"shown">>}, {x, 0}}.
    {jump, {f, 56}}.
  {label, 20}.
    {move, {literal, <<"-">>}, {x, 0}}.
  {label, 56}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 58}, [{x, 0}, 2, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Box}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {atom, false}, {x, 0}}.
  {label, 59}.
    {test, is_eq, {f, 57}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"box">>}, {x, 0}}.
    {jump, {f, 60}}.
  {label, 57}.
    {move, {literal, <<"-">>}, {x, 0}}.
  {label, 60}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_function2, {f, 62}, [{x, 0}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, false}, {x, 0}}.
  {label, 63}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"fn">>}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 61}.
    {move, {literal, <<"-">>}, {x, 0}}.
  {label, 64}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 94}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 5}.
    return.

{function, label, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, label}, 1}.
  {label, 5}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Shown}, {x, 1}}.
    {call, 2, {f, 22}}.
    {test, is_eq, {f, 98}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"shown">>}, {x, 0}}.
    {jump, {f, 99}}.
  {label, 98}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_tagged_tuple, {f, 101}, [{x, 0}, 2, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Box}]}.
    {move, {literal, <<"box">>}, {x, 0}}.
    {jump, {f, 100}}.
  {label, 101}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 100}}.
  {label, 100}.
  {label, 99}.
    {jump, {f, 97}}.
  {label, 97}.
    {deallocate, 5}.
    return.

{function, say, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, say}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 1}.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 7, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_is_behavior_identity_run_time@main@@Tag}, {integer, 1}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 66}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_is_behavior_identity_run_time@main@@Box}, {integer, 1}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 66}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 66}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 66}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"n">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__named}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__plain}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 66}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 5}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_is_behavior_identity_run_time@main@@Box}, {x, 0}]}}.
    {call, 1, {f, 5}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"t">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_is_behavior_identity_run_time@main@@Tag}, {x, 0}]}}.
    {call, 1, {f, 5}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 66}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {call, 0, {f, 9}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/is_behavior_identity_run_time|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__kind', 1, 103}.
  {label, 102}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_priv__kind'}, 1}.
  {label, 103}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__label', 1, 105}.
  {label, 104}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_priv__label'}, 1}.
  {label, 105}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__say', 1, 107}.
  {label, 106}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_priv__say'}, 1}.
  {label, 107}.
    {call_only, 1, {f, 7}}.

{function, '__bp_tpl_0', 2, 22}.
  {label, 21}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 22}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_tuple, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 27}}.
  {label, 25}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 27}}.
  {label, 26}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 27}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, true}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 28}}.
  {label, 29}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, false}]}.
    {move, {y, 2}, {y, 5}}.
    {jump, {f, 28}}.
  {label, 30}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 28}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_atom, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, true}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, false}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 8}}.
    {jump, {f, 41}}.
  {label, 39}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 8}}.
    {jump, {f, 41}}.
  {label, 40}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 41}.
    {move, {y, 8}, {y, 6}}.
    {jump, {f, 38}}.
  {label, 36}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 6}}.
    {jump, {f, 38}}.
  {label, 37}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 7}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 38}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 35}}.
  {label, 33}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 35}}.
  {label, 34}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 35}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, [95, 95, 118, 95, 95]}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 45}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 8}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nonempty_list, {f, 45}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 9}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 45}, [{x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 6}}.
    {jump, {f, 44}}.
  {label, 45}.
    {move, {y, 0}, {y, 6}}.
    {jump, {f, 44}}.
  {label, 44}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, module}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_behaviors'}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_behaviors'}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 7}}.
    {jump, {f, 54}}.
  {label, 52}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 7}}.
    {jump, {f, 54}}.
  {label, 53}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 54}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 51}}.
  {label, 49}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 51}}.
  {label, 50}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 43}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 55}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_print', 1, 66}.
  {label, 65}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_print'}, 1}.
  {label, 66}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 70}.
  {label, 69}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 70}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 68}}.

{function, '-bp_show_elem-', 1, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 72}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 68}}.

{function, '__bp_show', 2, 68}.
  {label, 67}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_show'}, 2}.
  {label, 68}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 80}, [{x, 0}]}.
    {test, is_eq, {f, 79}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 79}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 81}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 83}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 82}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 82}, [{x, 0}]}.
    {test, is_ne_exact, {f, 82}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 82}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 82}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 87}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 88}}.
  {label, 87}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 88}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 68}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 83}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 85}, [{x, 0}]}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 86}, [{x, 0}, {atom, undefined}]}.
  {label, 84}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 74}, 2}.
  {label, 85}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 86}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_tagged'}, 2}.
  {label, 74}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 89}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 89}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 89}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 76}, 3}.
  {label, 90}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '__bp_render'}, 1}.
  {label, 76}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 91}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 92}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 78}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 68}}.
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

{function, '-bp_stringify-', 1, 94}.
  {label, 93}.
    {line, [{location, "bp_load_cases_is_behavior_identity_run_time@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_is_behavior_identity_run_time@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 94}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 95}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 95}.
    {test, is_integer, {f, 96}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 96}.
    {call, 1, {f, 70}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
