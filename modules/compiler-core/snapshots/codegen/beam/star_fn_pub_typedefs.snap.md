----- SOURCE CODE -- main.bp
```botopink
pub fn loadOne(x: i32) -> @Task<i32> {
    return x;
}
pub fn count() -> @Iterator<i32> {
    yield 1;
}
pub fn pulses() -> @Stream<@Result<i32, string>> {
    yield 1;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{loadOne, 1}, {count, 0}, {pulses, 0}]}.
{attributes, []}.
{labels, 139}.

%% @Task — eager lowering
{function, loadOne, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, loadOne}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

%% @Iterator — lazy lowering
{function, count, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, count}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 68}}.
    {deallocate, 1}.
    return.

%% @Stream — lazy lowering
{function, pulses, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, pulses}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 137}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 68}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_0--t/1-fun-0--fun-1-', 1, 20}.
  {label, 19}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-0--fun-1-'}, 1}.
  {label, 20}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 22}, [{x, 0}]}.
    {test, test_arity, {f, 22}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 25}}.
  {label, 23}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 25}}.
  {label, 24}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 25}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 19}}.

{function, '__bp_tpl_0-t/1-fun-0-', 0, 16}.
  {label, 15}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 0}.
  {label, 16}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_0--t/1-fun-2--fun-3-', 1, 37}.
  {label, 36}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-2--fun-3-'}, 1}.
  {label, 37}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 39}, [{x, 0}]}.
    {test, test_arity, {f, 39}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 39}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 36}}.

{function, '__bp_tpl_0-t/1-fun-2-', 1, 29}.
  {label, 28}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-2-'}, 1}.
  {label, 29}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 33}}.
  {label, 33}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 35}}.
  {label, 35}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 40}}.
  {label, 41}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 40}}.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 44}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_0-t/1-fun-4-', 3, 49}.
  {label, 48}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-4-'}, 3}.
  {label, 49}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 52}, [{x, 0}]}.
    {test, test_arity, {f, 52}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 53}.
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
    {jump, {f, 55}}.
  {label, 55}.
  {label, 56}.
    {loop_rec, {f, 57}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 60}, [{x, 0}]}.
    {test, test_arity, {f, 60}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {x, 1}]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 60}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 61}, [{x, 0}]}.
    {test, test_arity, {f, 61}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {get_tuple_element, {x, 0}, 4, {y, 13}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, '__bp_gen'}]}.
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
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 63}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 64}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 61}.
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
    {loop_rec_end, {f, 56}}.
  {label, 57}.
    {wait, {f, 56}}.

{function, '__bp_tpl_0', 1, 12}.
  {label, 11}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 12}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 16}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 27}}.
  {label, 27}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 47}}.
  {label, 47}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 66}}.
  {label, 66}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-count/0-gen-0-', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-count/0-gen-0-'}, 0}.
  {label, 9}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 12}}.
  {label, 10}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 76}.
  {label, 75}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 76}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 78}, [{x, 0}]}.
    {test, test_arity, {f, 78}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 81}}.
  {label, 79}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 81}}.
  {label, 80}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 81}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 78}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 75}}.

{function, '__bp_tpl_1-t/1-fun-0-', 0, 72}.
  {label, 71}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 0}.
  {label, 72}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_1--t/1-fun-2--fun-3-', 1, 93}.
  {label, 92}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-2--fun-3-'}, 1}.
  {label, 93}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 95}, [{x, 0}]}.
    {test, test_arity, {f, 95}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 95}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 92}}.

{function, '__bp_tpl_1-t/1-fun-2-', 1, 85}.
  {label, 84}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-2-'}, 1}.
  {label, 85}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 89}}.
  {label, 89}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 91}}.
  {label, 91}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 93}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 96}}.
  {label, 97}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 96}}.
  {label, 96}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 100}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_1--t/1-fun-4--fun-5-', 4, 111}.
  {label, 110}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-4--fun-5-'}, 4}.
  {label, 111}.
    {allocate, 31, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {atom, process}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, monitor, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 4}}.
    {jump, {f, 115}}.
  {label, 115}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 16}}.
  {label, 116}.
    {loop_rec, {f, 117}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 120}, [{x, 0}]}.
    {test, test_arity, {f, 120}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {x, 1}]}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 31}.
    return.
  {label, 120}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 121}, [{x, 0}]}.
    {test, test_arity, {f, 121}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {get_tuple_element, {x, 0}, 3, {y, 20}}.
    {get_tuple_element, {x, 0}, 4, {y, 21}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 121}, [{x, 0}, {atom, '__bp_gen'}]}.
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
    {test, is_eq_exact, {f, 123}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 22}}.
    {jump, {f, 122}}.
  {label, 123}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, next}]}.
    {'try', {y, 30}, {f, 125}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {y, 23}}.
    {try_end, {y, 30}}.
    {jump, {f, 126}}.
  {label, 125}.
    {try_case, {y, 30}}.
    {move, {x, 0}, {y, 24}}.
    {move, {x, 1}, {y, 25}}.
    {move, {x, 2}, {y, 26}}.
    {move, {y, 24}, {x, 0}}.
    {test, is_eq_exact, {f, 128}, [{x, 0}, {atom, throw}]}.
    {move, {y, 25}, {x, 0}}.
    {test, is_eq_exact, {f, 128}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 23}}.
    {jump, {f, 127}}.
  {label, 128}.
    {move, {y, 24}, {y, 9}}.
    {move, {y, 25}, {y, 10}}.
    {move, {y, 26}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 11}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {test, is_tuple, {f, 130}, [{x, 0}]}.
    {test, test_arity, {f, 130}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 28}}.
    {get_tuple_element, {x, 0}, 1, {y, 29}}.
    {move, {y, 28}, {y, 12}}.
    {move, {y, 29}, {y, 13}}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {y, 27}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 131}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 27}}.
    {test_heap, 7, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 13}, {atom, raise}, {y, 9}, {y, 10}, {y, 11}, {y, 27}]}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 27}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 27}}.
    {move, {atom, normal}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, exit, 1}}.
  {label, 127}.
  {label, 126}.
    {move, {y, 23}, {y, 22}}.
    {jump, {f, 122}}.
  {label, 124}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 122}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_tuple, {f, 132}, [{x, 0}]}.
    {test, test_arity, {f, 132}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 23}}.
    {get_tuple_element, {x, 0}, 1, {y, 24}}.
    {move, {y, 23}, {y, 14}}.
    {move, {y, 24}, {y, 15}}.
    {jump, {f, 133}}.
  {label, 132}.
    {move, {y, 22}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 133}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 22}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 15}, {atom, done}, {y, 22}]}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, send, 2}, 31}.
  {label, 121}.
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
    {loop_rec_end, {f, 116}}.
  {label, 117}.
    {wait, {f, 116}}.

{function, '__bp_tpl_1-t/1-fun-4-', 3, 105}.
  {label, 104}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-4-'}, 3}.
  {label, 105}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 109}}.
  {label, 109}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 111}, 2, 0, {x, 0}, {list, [{y, 2}, {y, 0}, {y, 3}, {y, 1}]}}.
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

{function, '__bp_tpl_1', 1, 68}.
  {label, 67}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 68}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 83}}.
  {label, 83}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 85}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 103}}.
  {label, 103}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 105}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 135}}.
  {label, 135}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-pulses/0-gen-1-', 0, 137}.
  {label, 136}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-pulses/0-gen-1-'}, 0}.
  {label, 137}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {call, 1, {f, 12}}.
  {label, 138}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
