----- SOURCE CODE -- main.bp
```botopink
fn two() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
fn stepText(s: YieldStep<i32>) -> string {
    val t = case s {
        Yield(v) -> "yield " + v.toString();
        Done -> "done";
    };
    return t;
}
pub fn main() {
    val it = two();
    @print(stepText(it.next()));
    @print(stepText(it.next()));
    @print(stepText(it.next()));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__stepText', 1}, {'__bp_priv__two', 0}]}.
{attributes, []}.
{labels, 245}.

%% @Iterator — lazy lowering
{function, two, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, two}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 72}}.
    {deallocate, 1}.
    return.

{function, stepText, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, stepText}, 1}.
  {label, 5}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 143}, [{x, 0}, 2, {atom, test@main@@YieldStep__v__yield}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"yield ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 173}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 142}}.
  {label, 143}.
    {test, is_eq, {f, 176}, [{x, 0}, {atom, test@main@@YieldStep__v__done}]}.
    {move, {literal, <<"done">>}, {x, 0}}.
    {jump, {f, 142}}.
  {label, 176}.
    {case_end, {x, 0}}.
  {label, 142}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call, 0, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 178}}.
    {call, 1, {f, 236}}.
    {test, is_nonempty_list, {f, 238}, [{y, 0}]}.
    {get_list, {y, 0}, {x, 1}, {y, 0}}.
  {label, 238}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 145}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 178}}.
    {call, 1, {f, 236}}.
    {test, is_nonempty_list, {f, 239}, [{y, 0}]}.
    {get_list, {y, 0}, {x, 1}, {y, 0}}.
  {label, 239}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 145}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 178}}.
    {call, 1, {f, 236}}.
    {test, is_nonempty_list, {f, 240}, [{y, 0}]}.
    {get_list, {y, 0}, {x, 1}, {y, 0}}.
  {label, 240}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 145}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_priv__stepText', 1, 242}.
  {label, 241}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__stepText'}, 1}.
  {label, 242}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__two', 0, 244}.
  {label, 243}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__two'}, 0}.
  {label, 244}.
    {call_only, 0, {f, 3}}.

{function, '__bp_tpl_0--t/1-fun-0--fun-1-', 1, 24}.
  {label, 23}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-0--fun-1-'}, 1}.
  {label, 24}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 26}, [{x, 0}]}.
    {test, test_arity, {f, 26}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 29}}.
  {label, 27}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 29}}.
  {label, 28}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 29}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 26}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 23}}.

{function, '__bp_tpl_0-t/1-fun-0-', 0, 20}.
  {label, 19}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 0}.
  {label, 20}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_0--t/1-fun-2--fun-3-', 1, 41}.
  {label, 40}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-2--fun-3-'}, 1}.
  {label, 41}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 43}, [{x, 0}]}.
    {test, test_arity, {f, 43}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 43}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 40}}.

{function, '__bp_tpl_0-t/1-fun-2-', 1, 33}.
  {label, 32}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-2-'}, 1}.
  {label, 33}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 37}}.
  {label, 37}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 39}}.
  {label, 39}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 44}}.
  {label, 45}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 44}}.
  {label, 44}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 48}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_0-t/1-fun-4-', 3, 53}.
  {label, 52}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-4-'}, 3}.
  {label, 53}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 56}, [{x, 0}]}.
    {test, test_arity, {f, 56}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 57}.
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
    {jump, {f, 59}}.
  {label, 59}.
  {label, 60}.
    {loop_rec, {f, 61}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {x, 1}]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 64}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 65}, [{x, 0}]}.
    {test, test_arity, {f, 65}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {get_tuple_element, {x, 0}, 4, {y, 13}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, '__bp_gen'}]}.
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
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 67}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 68}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 65}.
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
    {loop_rec_end, {f, 60}}.
  {label, 61}.
    {wait, {f, 60}}.

{function, '__bp_tpl_0', 1, 16}.
  {label, 15}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 16}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 31}}.
  {label, 31}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 51}}.
  {label, 51}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 53}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 70}}.
  {label, 70}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-two/0-gen-0-', 0, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-two/0-gen-0-'}, 0}.
  {label, 13}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 16}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 16}}.
  {label, 14}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 80}.
  {label, 79}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 80}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 82}, [{x, 0}]}.
    {test, test_arity, {f, 82}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 85}}.
  {label, 83}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 85}}.
  {label, 84}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 85}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 82}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 79}}.

{function, '__bp_tpl_1-t/1-fun-0-', 0, 76}.
  {label, 75}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 0}.
  {label, 76}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_1--t/1-fun-2--fun-3-', 1, 97}.
  {label, 96}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-2--fun-3-'}, 1}.
  {label, 97}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 99}, [{x, 0}]}.
    {test, test_arity, {f, 99}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 99}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 96}}.

{function, '__bp_tpl_1-t/1-fun-2-', 1, 89}.
  {label, 88}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-2-'}, 1}.
  {label, 89}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 93}}.
  {label, 93}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 95}}.
  {label, 95}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 97}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 100}}.
  {label, 101}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 100}}.
  {label, 100}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 104}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_1--t/1-fun-4--fun-5-', 4, 115}.
  {label, 114}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-4--fun-5-'}, 4}.
  {label, 115}.
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
    {jump, {f, 119}}.
  {label, 119}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 16}}.
  {label, 120}.
    {loop_rec, {f, 121}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 124}, [{x, 0}]}.
    {test, test_arity, {f, 124}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {x, 1}]}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 124}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 125}, [{x, 0}]}.
    {test, test_arity, {f, 125}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {get_tuple_element, {x, 0}, 3, {y, 20}}.
    {get_tuple_element, {x, 0}, 4, {y, 21}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {atom, '__bp_gen'}]}.
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
    {test, is_eq_exact, {f, 127}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 22}}.
    {jump, {f, 126}}.
  {label, 127}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 128}, [{x, 0}, {atom, next}]}.
    {'try', {y, 32}, {f, 129}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {y, 23}}.
    {try_end, {y, 32}}.
    {jump, {f, 130}}.
  {label, 129}.
    {try_case, {y, 32}}.
    {move, {x, 0}, {y, 24}}.
    {move, {x, 1}, {y, 25}}.
    {move, {x, 2}, {y, 26}}.
    {move, {y, 24}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, throw}]}.
    {move, {y, 25}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 23}}.
    {jump, {f, 131}}.
  {label, 132}.
    {move, {y, 24}, {y, 9}}.
    {move, {y, 25}, {y, 10}}.
    {move, {y, 26}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 11}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {test, is_tuple, {f, 135}, [{x, 0}]}.
    {test, test_arity, {f, 135}, [{x, 0}, 2]}.
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
    {jump, {f, 134}}.
  {label, 135}.
    {move, {y, 27}, {x, 0}}.
    {test, is_eq_exact, {f, 136}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 28}}.
    {jump, {f, 134}}.
  {label, 136}.
    {move, {y, 27}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 134}.
    {move, {atom, normal}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, exit, 1}}.
  {label, 131}.
  {label, 130}.
    {move, {y, 23}, {y, 22}}.
    {jump, {f, 126}}.
  {label, 128}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 126}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_tuple, {f, 138}, [{x, 0}]}.
    {test, test_arity, {f, 138}, [{x, 0}, 2]}.
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
  {label, 138}.
    {move, {y, 22}, {x, 0}}.
    {test, is_eq_exact, {f, 139}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 139}.
    {move, {y, 22}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 125}.
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
    {loop_rec_end, {f, 120}}.
  {label, 121}.
    {wait, {f, 120}}.

{function, '__bp_tpl_1-t/1-fun-4-', 3, 109}.
  {label, 108}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-4-'}, 3}.
  {label, 109}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 113}}.
  {label, 113}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 115}, 2, 0, {x, 0}, {list, [{y, 2}, {y, 0}, {y, 3}, {y, 1}]}}.
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

{function, '__bp_tpl_1', 1, 72}.
  {label, 71}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 72}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 87}}.
  {label, 87}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 89}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 107}}.
  {label, 107}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 109}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 141}}.
  {label, 141}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '__bp_print', 1, 145}.
  {label, 144}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 145}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 149}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 149}.
  {label, 148}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 149}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 147}}.

{function, '-bp_show_elem-', 1, 151}.
  {label, 150}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 151}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 147}}.

{function, '__bp_show', 2, 147}.
  {label, 146}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 147}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 159}, [{x, 0}]}.
    {test, is_eq, {f, 158}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 158}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 159}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 160}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 151}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 160}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 162}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 161}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 161}, [{x, 0}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 167}}.
  {label, 166}.
    {test, is_eq_exact, {f, 163}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 167}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 147}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 161}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 151}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 162}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 164}, [{x, 0}]}.
    {test, is_ne_exact, {f, 164}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 164}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 165}, [{x, 0}, {atom, undefined}]}.
  {label, 163}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 153}, 2}.
  {label, 164}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 165}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 153}.
  {label, 152}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 153}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 168}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 168}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 168}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 169}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 155}, 3}.
  {label, 169}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 155}.
  {label, 154}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 155}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 170}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 170}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 171}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 171}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 157}.
  {label, 156}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 157}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 147}}.
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

{function, '-bp_stringify-', 1, 173}.
  {label, 172}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 173}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 174}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 174}.
    {test, is_integer, {f, 175}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 175}.
    {call, 1, {f, 149}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_2--t/1-fun-0--fun-1-', 1, 188}.
  {label, 187}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2--t/1-fun-0--fun-1-'}, 1}.
  {label, 188}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 190}, [{x, 0}]}.
    {test, test_arity, {f, 190}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 193}}.
  {label, 191}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 192}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 193}}.
  {label, 192}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 193}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 190}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 187}}.

{function, '__bp_tpl_2-t/1-fun-0-', 0, 184}.
  {label, 183}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 0}.
  {label, 184}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 188}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_2--t/1-fun-2--fun-3-', 1, 205}.
  {label, 204}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2--t/1-fun-2--fun-3-'}, 1}.
  {label, 205}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 207}, [{x, 0}]}.
    {test, test_arity, {f, 207}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 207}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 204}}.

{function, '__bp_tpl_2-t/1-fun-2-', 1, 197}.
  {label, 196}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2-t/1-fun-2-'}, 1}.
  {label, 197}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 201}}.
  {label, 201}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 203}}.
  {label, 203}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 205}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 209}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 208}}.
  {label, 209}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 208}}.
  {label, 208}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 212}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 212}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_2-t/1-fun-4-', 4, 217}.
  {label, 216}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2-t/1-fun-4-'}, 4}.
  {label, 217}.
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
    {jump, {f, 221}}.
  {label, 221}.
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
  {label, 222}.
    {loop_rec, {f, 223}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 226}, [{x, 0}]}.
    {test, test_arity, {f, 226}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 226}, [{x, 0}, {x, 1}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 226}, [{x, 0}, {atom, item}]}.
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
  {label, 226}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 227}, [{x, 0}]}.
    {test, test_arity, {f, 227}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {x, 1}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {atom, done}]}.
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
  {label, 227}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 228}, [{x, 0}]}.
    {test, test_arity, {f, 228}, [{x, 0}, 6]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {get_tuple_element, {x, 0}, 5, {y, 16}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {x, 1}]}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, raise}]}.
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
  {label, 228}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 229}, [{x, 0}]}.
    {test, test_arity, {f, 229}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {x, 1}]}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, nil, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 229}.
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
    {loop_rec_end, {f, 222}}.
  {label, 223}.
    {wait, {f, 222}}.

{function, '__bp_tpl_2', 1, 178}.
  {label, 177}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2'}, 1}.
  {label, 178}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 182}, [{x, 0}]}.
    {test, test_arity, {f, 182}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 182}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 184}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 195}}.
  {label, 195}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 197}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 215}}.
  {label, 215}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 217}, 4, 0, {x, 0}, {list, [{y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 231}}.
  {label, 231}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, next}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_nonempty_list, {f, 233}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 8}, {y, 9}}.
    {move, {y, 8}, {y, 0}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nil, {f, 233}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 233}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 234}, [{x, 0}, nil]}.
    {move, nil, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 234}.
    {move, {y, 7}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 182}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-bp_yield_step-', 1, 236}.
  {label, 235}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_yield_step-'}, 1}.
  {label, 236}.
    {test, is_nonempty_list, {f, 237}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@YieldStep__v__yield}, {x, 1}]}}.
    return.
  {label, 237}.
    {move, {atom, test@main@@YieldStep__v__done}, {x, 0}}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@YieldStep.S
```erlang
{module, test@main@@YieldStep}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 6}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@YieldStep.erl", 1}]}.
    {func_info, {atom, test@main@@YieldStep}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, test@main@@YieldStep__v__yield}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"value">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"YieldStep.Yield">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, test@main@@YieldStep__v__done}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"YieldStep.Done">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"YieldStep">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
yield 1
yield 2
done
```
