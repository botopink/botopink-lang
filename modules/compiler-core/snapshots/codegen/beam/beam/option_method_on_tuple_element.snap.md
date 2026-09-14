----- SOURCE CODE -- main.bp
```botopink
fn firstAndRest(xs: Array<i32>) -> #(Array<i32>, ?i32) {
    val head = xs.at(0);
    val rest = xs.slice(1, xs.length);
    return #(rest, head);
}

fn main() {
    val result = firstAndRest([1, 2, 3]);
    val head = result._1;
    @print(head.unwrapOr(-1));
    val empty = firstAndRest([]);
    @print(empty._1 == null);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 26}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {test, is_ge, {f, 14}, [{x, 0}, {x, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
  {label, 15}.
    {deallocate, 1}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {test, is_ge, {f, 16}, [{integer, 0}, {x, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test_heap, 2, 1}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
  {label, 17}.
    {deallocate, 1}.
    return.

{function, firstAndRest, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, firstAndRest}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 19}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test, is_map, {f, 21}, [{x, 0}]}.
    {get_map_elements, {f, 21}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 21}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    %% unresolved method call: slice/3
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, 3, 3}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 2}]}}.
    {deallocate, 2}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 22}, [{x, 0}, {atom, undefined}]}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
  {label, 23}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq, {f, 24}, [{x, 0}, {atom, nil}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, false}, {x, 0}}.
  {label, 25}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '-bp_at-', 2, 19}.
  {label, 18}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-bp_at-'}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {test, is_ge, {f, 20}, [{y, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 20}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 20}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
1
false
```
