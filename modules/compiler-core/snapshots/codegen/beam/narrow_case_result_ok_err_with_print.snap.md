----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch(ok: bool) -> @Result<string, string> {
    if (ok) { return "data"; };
    throw "fail";
}
fn main() {
    val r1 = fetch(true);
    val msg1 = case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg1);
    val r2 = fetch(false);
    val msg2 = case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg2);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 30}.

{function, fetch, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 10}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"data">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 10}.
    {move, {literal, <<"fail">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"OK:">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 11}}.
  {label, 12}.
    {test, is_tagged_tuple, {f, 17}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"ERR:">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 11}}.
  {label, 17}.
  {label, 11}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"OK:">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 27}}.
  {label, 28}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"ERR:">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 27}}.
  {label, 29}.
  {label, 27}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '-bp_stringify-', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_stringify-'}, 1}.
  {label, 14}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 15}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 15}.
    {test, is_integer, {f, 16}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 16}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.

{function, '__bp_print', 1, 19}.
  {label, 18}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 21}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 21}.
  {label, 20}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 21}.
    {test, is_nonempty_list, {f, 24}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 23}}.
    {test, is_binary, {f, 25}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 25}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 24}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 23}.
  {label, 22}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 23}.
    {test, is_nonempty_list, {f, 26}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 21}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 26}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
OK:data
ERR:fail
```
