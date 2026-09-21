----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val rows = [[1, 2], [3, 4]];
    @print(rows);
    @print(rows[1]);
    @print(rows[1][0]);
    @print(rows[0].length);
    val xs = [10, 20, 30];
    @print(xs[0..2].length);
    val sl = xs[0..2];
    @print(sl.length);
    val ps = [#(1, "a"), #(2, "b")];
    @print(ps[1]);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 40}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 12}, [{y, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 13}.
    {deallocate, 4}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 14}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 15}.
    {deallocate, 4}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 11, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 30}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 30}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 30}}.
    {test, is_map, {f, 34}, [{x, 0}]}.
    {get_map_elements, {f, 34}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 34}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 30}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 20}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 2}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 2}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 2}, {x, 0}]}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {x, 0}]}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 30}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_print', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 21}.
  {label, 20}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-bp_show_top-'}, 1}.
  {label, 21}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 19}}.

{function, '-bp_show_elem-', 1, 23}.
  {label, 22}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 23}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 19}}.

{function, '__bp_show', 2, 19}.
  {label, 18}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_show'}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 25}, [{x, 0}]}.
    {test, is_eq, {f, 24}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 26}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 28}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 27}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 27}, [{x, 0}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.

{function, '-bp_at-', 2, 30}.
  {label, 29}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-bp_at-'}, 2}.
  {label, 30}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {test, is_ge, {f, 31}, [{y, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 31}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 31}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_erl_eval', 2, 37}.
  {label, 36}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '__bp_erl_eval'}, 2}.
  {label, 37}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {call_ext, 1, {extfunc, erl_scan, string, 1}}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call_ext, 1, {extfunc, erl_parse, parse_exprs, 1}}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erl_eval, exprs, 2}}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 3, {atom, value}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 38}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 1}.

{function, '__bp_prim_at', 2, 33}.
  {label, 32}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '__bp_prim_at'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 35}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 30}, 2}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 39}, [{x, 0}]}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 1}, 0, {list, [{atom, '__BpSelf'}, {y, 0}, {atom, '__BpA0'}, {y, 1}]}}.
    {move, {literal, <<"(fun(__S, __I) -> case (__I >= 0) andalso (__I < string:length(__S)) of true -> string:slice(__S, __I, 1); false -> undefined end end)(__BpSelf, __BpA0).">>}, {x, 0}}.
    {call_last, 2, {f, 37}, 2}.
  {label, 39}.
    %% unresolved_method: at/2
    {move, {literal, {unresolved_method, at, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
[[1, 2], [3, 4]]
[3, 4]
3
[1, 2]
2
2
#(2, "b")
```
