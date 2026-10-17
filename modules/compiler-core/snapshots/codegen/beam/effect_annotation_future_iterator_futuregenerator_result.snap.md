----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> @Task<i32> {
    return x;
}
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
fn stream() -> @Stream<@Result<i32, string>> {
    yield 1;
}
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__counter', 0}, {'__bp_priv__fetch', 1}, {'__bp_priv__parse', 1}, {'__bp_priv__stream', 0}]}.
{attributes, []}.
{labels, 126}.

%% @Task — eager lowering
{function, fetch, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, fetch}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

%% @Iterator — lazy lowering
{function, counter, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, counter}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 59}}.
    {deallocate, 1}.
    return.

%% @Stream — lazy lowering
{function, stream, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, stream}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 115}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 59}}.
    {deallocate, 1}.
    return.

{function, parse, 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, parse}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 117}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 117}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__counter', 0, 119}.
  {label, 118}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__counter'}, 0}.
  {label, 119}.
    {call_only, 0, {f, 5}}.

{function, '__bp_priv__fetch', 1, 121}.
  {label, 120}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__fetch'}, 1}.
  {label, 121}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__parse', 1, 123}.
  {label, 122}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__parse'}, 1}.
  {label, 123}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__stream', 0, 125}.
  {label, 124}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__stream'}, 0}.
  {label, 125}.
    {call_only, 0, {f, 7}}.

{function, '__bp_tpl_0--t/1-fun-0--fun-1-', 1, 22}.
  {label, 21}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-0--fun-1-'}, 1}.
  {label, 22}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 24}, [{x, 0}]}.
    {test, test_arity, {f, 24}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 24}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    {jump, {f, 21}}.

{function, '__bp_tpl_0-t/1-fun-0-', 0, 18}.
  {label, 17}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 0}.
  {label, 18}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_0--t/1-fun-2--fun-3-', 1, 34}.
  {label, 33}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/1-fun-2--fun-3-'}, 1}.
  {label, 34}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {test, test_arity, {f, 36}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 36}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 33}}.

{function, '__bp_tpl_0-t/1-fun-2-', 1, 28}.
  {label, 27}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-2-'}, 1}.
  {label, 28}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 32}}.
  {label, 32}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 38}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 3}.

{function, '__bp_tpl_0-t/1-fun-4-', 3, 43}.
  {label, 42}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/1-fun-4-'}, 3}.
  {label, 43}.
    {allocate, 14, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 46}, [{x, 0}]}.
    {test, test_arity, {f, 46}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {y, 2}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 47}}.
  {label, 46}.
    {move, {y, 7}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 47}.
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
  {label, 48}.
    {loop_rec, {f, 49}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 52}, [{x, 0}]}.
    {test, test_arity, {f, 52}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {get_tuple_element, {x, 0}, 2, {y, 10}}.
    {get_tuple_element, {x, 0}, 3, {y, 11}}.
    {get_tuple_element, {x, 0}, 4, {y, 12}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, '__bp_gen'}]}.
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
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 54}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 14}.
  {label, 55}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 52}.
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
    {loop_rec_end, {f, 48}}.
  {label, 49}.
    {wait, {f, 48}}.

{function, '__bp_tpl_0', 1, 14}.
  {label, 13}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 14}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 26}}.
  {label, 26}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 41}}.
  {label, 41}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 57}}.
  {label, 57}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-counter/0-gen-0-', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-counter/0-gen-0-'}, 0}.
  {label, 11}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 14}}.
  {label, 12}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 67}.
  {label, 66}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 67}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 69}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    {jump, {f, 66}}.

{function, '__bp_tpl_1-t/1-fun-0-', 0, 63}.
  {label, 62}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 0}.
  {label, 63}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_1--t/1-fun-2--fun-3-', 1, 79}.
  {label, 78}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-2--fun-3-'}, 1}.
  {label, 79}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 81}, [{x, 0}]}.
    {test, test_arity, {f, 81}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 81}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 78}}.

{function, '__bp_tpl_1-t/1-fun-2-', 1, 73}.
  {label, 72}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-2-'}, 1}.
  {label, 73}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 77}}.
  {label, 77}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 79}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 83}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 3}.

{function, '__bp_tpl_1--t/1-fun-4--fun-5-', 3, 92}.
  {label, 91}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1--t/1-fun-4--fun-5-'}, 3}.
  {label, 92}.
    {allocate, 29, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
  {label, 95}.
    {loop_rec, {f, 96}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tuple, {f, 99}, [{x, 0}]}.
    {test, test_arity, {f, 99}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 15}}.
    {get_tuple_element, {x, 0}, 1, {y, 16}}.
    {get_tuple_element, {x, 0}, 2, {y, 17}}.
    {get_tuple_element, {x, 0}, 3, {y, 18}}.
    {get_tuple_element, {x, 0}, 4, {y, 19}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, '__bp_gen'}]}.
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
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 20}}.
    {jump, {f, 100}}.
  {label, 101}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, {atom, next}]}.
    {'try', {y, 28}, {f, 103}}.
    {move, {y, 1}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {y, 21}}.
    {try_end, {y, 28}}.
    {jump, {f, 104}}.
  {label, 103}.
    {try_case, {y, 28}}.
    {move, {x, 0}, {y, 22}}.
    {move, {x, 1}, {y, 23}}.
    {move, {x, 2}, {y, 24}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_eq_exact, {f, 106}, [{x, 0}, {atom, throw}]}.
    {move, {y, 23}, {x, 0}}.
    {test, is_eq_exact, {f, 106}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 21}}.
    {jump, {f, 105}}.
  {label, 106}.
    {move, {y, 22}, {y, 7}}.
    {move, {y, 23}, {y, 8}}.
    {move, {y, 24}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {test, is_tuple, {f, 108}, [{x, 0}]}.
    {test, test_arity, {f, 108}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 26}}.
    {get_tuple_element, {x, 0}, 1, {y, 27}}.
    {move, {y, 26}, {y, 10}}.
    {move, {y, 27}, {y, 11}}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {y, 25}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 109}.
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
  {label, 105}.
  {label, 104}.
    {move, {y, 21}, {y, 20}}.
    {jump, {f, 100}}.
  {label, 102}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 100}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 20}, {x, 0}}.
    {test, is_tuple, {f, 110}, [{x, 0}]}.
    {test, test_arity, {f, 110}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 21}}.
    {get_tuple_element, {x, 0}, 1, {y, 22}}.
    {move, {y, 21}, {y, 12}}.
    {move, {y, 22}, {y, 13}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {y, 20}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 111}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 20}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 13}, {atom, done}, {y, 20}]}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, send, 2}, 29}.
  {label, 99}.
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
    {loop_rec_end, {f, 95}}.
  {label, 96}.
    {wait, {f, 95}}.

{function, '__bp_tpl_1-t/1-fun-4-', 3, 88}.
  {label, 87}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1-t/1-fun-4-'}, 3}.
  {label, 88}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 92}, 2, 0, {x, 0}, {list, [{y, 0}, {y, 2}, {y, 1}]}}.
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

{function, '__bp_tpl_1', 1, 59}.
  {label, 58}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 59}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 71}}.
  {label, 71}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 86}}.
  {label, 86}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 113}}.
  {label, 113}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-stream/0-gen-1-', 0, 115}.
  {label, 114}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-stream/0-gen-1-'}, 0}.
  {label, 115}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {call, 1, {f, 14}}.
  {label, 116}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
