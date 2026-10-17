----- SOURCE CODE -- main.bp
```botopink
fn range(a: i32, b: i32) -> @Iterator<i32> {
    yield a;
    yield b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__range', 2}]}.
{attributes, []}.
{labels, 110}.

%% @Iterator — lazy lowering
{function, range, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, range}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 5}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {call, 1, {f, 53}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__range', 2, 109}.
  {label, 108}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__range'}, 2}.
  {label, 109}.
    {call_only, 2, {f, 3}}.

{function, '__bp_tpl_0--t/1-fun-0--fun-1-', 1, 16}.
  {label, 15}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-0--fun-1-'}, 1}.
  {label, 16}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 18}, [{x, 0}]}.
    {test, test_arity, {f, 18}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 18}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    {jump, {f, 15}}.

{function, '__bp_tpl_0-t/1-fun-0-', 0, 12}.
  {label, 11}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 0}.
  {label, 12}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 16}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_0--t/1-fun-2--fun-3-', 1, 28}.
  {label, 27}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-2--fun-3-'}, 1}.
  {label, 28}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 30}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 27}}.

{function, '__bp_tpl_0-t/1-fun-2-', 1, 22}.
  {label, 21}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-2-'}, 1}.
  {label, 22}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 26}}.
  {label, 26}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 32}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 3}.

{function, '__bp_tpl_0-t/1-fun-4-', 3, 37}.
  {label, 36}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-4-'}, 3}.
  {label, 37}.
    {allocate, 14, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 40}, [{x, 0}]}.
    {test, test_arity, {f, 40}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {y, 2}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {y, 7}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {atom, item}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 7}}.
  {label, 42}.
    {loop_rec, {f, 43}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 46}, [{x, 0}]}.
    {test, test_arity, {f, 46}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {get_tuple_element, {x, 0}, 2, {y, 10}}.
    {get_tuple_element, {x, 0}, 3, {y, 11}}.
    {get_tuple_element, {x, 0}, 4, {y, 12}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 9}, {y, 5}}.
    {move, {y, 10}, {y, 4}}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    remove_message.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 2}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 48}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 14}.
  {label, 49}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 46}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 13}}.
    {loop_rec_end, {f, 42}}.
  {label, 43}.
    {wait, {f, 42}}.

{function, '__bp_tpl_0', 1, 8}.
  {label, 7}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 8}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 20}}.
  {label, 20}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 35}}.
  {label, 35}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 51}}.
  {label, 51}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-range/2-gen-0-', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-range/2-gen-0-'}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 8}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 8}}.
  {label, 6}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 61}.
  {label, 60}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 61}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 63}, [{x, 0}]}.
    {test, test_arity, {f, 63}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 63}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    {jump, {f, 60}}.

{function, '__bp_tpl_1-t/1-fun-0-', 0, 57}.
  {label, 56}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 0}.
  {label, 57}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_1--t/1-fun-2--fun-3-', 1, 73}.
  {label, 72}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-2--fun-3-'}, 1}.
  {label, 73}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 75}, [{x, 0}]}.
    {test, test_arity, {f, 75}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 75}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 72}}.

{function, '__bp_tpl_1-t/1-fun-2-', 1, 67}.
  {label, 66}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-2-'}, 1}.
  {label, 67}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 71}}.
  {label, 71}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 77}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 3}.

{function, '__bp_tpl_1--t/1-fun-4--fun-5-', 3, 86}.
  {label, 85}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-4--fun-5-'}, 3}.
  {label, 86}.
    {allocate, 29, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
  {label, 89}.
    {loop_rec, {f, 90}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tuple, {f, 93}, [{x, 0}]}.
    {test, test_arity, {f, 93}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 15}}.
    {get_tuple_element, {x, 0}, 1, {y, 16}}.
    {get_tuple_element, {x, 0}, 2, {y, 17}}.
    {get_tuple_element, {x, 0}, 3, {y, 18}}.
    {get_tuple_element, {x, 0}, 4, {y, 19}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 3}}.
    {move, {y, 18}, {y, 5}}.
    {move, {y, 19}, {y, 6}}.
    remove_message.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 20}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {y, 5}]}}.
    {move, {x, 0}, {y, 20}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 95}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 20}}.
    {jump, {f, 94}}.
  {label, 95}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 96}, [{x, 0}, {atom, next}]}.
    {'try', {y, 28}, {f, 97}}.
    {move, {y, 1}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {y, 21}}.
    {try_end, {y, 28}}.
    {jump, {f, 98}}.
  {label, 97}.
    {try_case, {y, 28}}.
    {move, {x, 0}, {y, 22}}.
    {move, {x, 1}, {y, 23}}.
    {move, {x, 2}, {y, 24}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, throw}]}.
    {move, {y, 23}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 21}}.
    {jump, {f, 99}}.
  {label, 100}.
    {move, {y, 22}, {y, 7}}.
    {move, {y, 23}, {y, 8}}.
    {move, {y, 24}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {test, is_tuple, {f, 102}, [{x, 0}]}.
    {test, test_arity, {f, 102}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 26}}.
    {get_tuple_element, {x, 0}, 1, {y, 27}}.
    {move, {y, 26}, {y, 10}}.
    {move, {y, 27}, {y, 11}}.
    {jump, {f, 103}}.
  {label, 102}.
    {move, {y, 25}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 103}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 25}}.
    {test_heap, 7, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 11}, {atom, raise}, {y, 7}, {y, 8}, {y, 9}, {y, 25}]}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 25}}.
    {move, {atom, normal}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, exit, 1}}.
  {label, 99}.
  {label, 98}.
    {move, {y, 21}, {y, 20}}.
    {jump, {f, 94}}.
  {label, 96}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 94}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 20}, {x, 0}}.
    {test, is_tuple, {f, 104}, [{x, 0}]}.
    {test, test_arity, {f, 104}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 21}}.
    {get_tuple_element, {x, 0}, 1, {y, 22}}.
    {move, {y, 21}, {y, 12}}.
    {move, {y, 22}, {y, 13}}.
    {jump, {f, 105}}.
  {label, 104}.
    {move, {y, 20}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 105}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 20}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 13}, {atom, done}, {y, 20}]}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, send, 2}, 29}.
  {label, 93}.
    {move, nil, {y, 14}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 15}}.
    {move, nil, {y, 16}}.
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
    {loop_rec_end, {f, 89}}.
  {label, 90}.
    {wait, {f, 89}}.

{function, '__bp_tpl_1-t/1-fun-4-', 3, 82}.
  {label, 81}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-4-'}, 3}.
  {label, 82}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 86}, 2, 0, {x, 0}, {list, [{y, 0}, {y, 2}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, spawn, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen'}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1', 1, 53}.
  {label, 52}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 53}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 65}}.
  {label, 65}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 80}}.
  {label, 80}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 82}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 107}}.
  {label, 107}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.
```

----- RUN LOG -----
```logs
```
