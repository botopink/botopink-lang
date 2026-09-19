----- SOURCE CODE -- main.bp
```botopink
fn average(xs: Array<f64>) -> f64 {
    var total = 0.0;
    var n = 0.0;
    loop (xs) { x ->
        total = total + x;
        n = n + 1.0;
    };
    return total / n;
}
fn main() {
    val cat = { x, y -> x + y };
    @print(cat("ab", "cd"));
    @print(average([2.0, 4.0, 9.0]));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 30}.

{function, average, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, average}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{y, 1}, {y, 2}]}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 1}, {y, 2}], {x, 0}}.
    {deallocate, 3}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ab">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cd">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 9.0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 4.0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 2.0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
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

{function, '-average/1-fun-0-', 2, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-average/1-fun-0-'}, 2}.
  {label, 11}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {bif, element, {f, 0}, [{integer, 1}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {bif, element, {f, 0}, [{integer, 2}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 3}]}}.
    {deallocate, 4}.
    return.

{function, '__bp_add', 2, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_add'}, 2}.
  {label, 15}.
    {test, is_binary, {f, 16}, [{x, 0}]}.
    {test, is_binary, {f, 16}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 16}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-main/0-fun-1-', 2, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-1-'}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 15}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 18}.
  {label, 17}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 18}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 22}.
  {label, 21}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_show_top-'}, 1}.
  {label, 22}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 20}}.

{function, '-bp_show_elem-', 1, 24}.
  {label, 23}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 24}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 20}}.

{function, '__bp_show', 2, 20}.
  {label, 19}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_show'}, 2}.
  {label, 20}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 26}, [{x, 0}]}.
    {test, is_eq, {f, 25}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 27}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 29}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 28}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 28}, [{x, 0}]}.
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
```

----- RUN LOG -----
```logs
abcd
5.0
```
