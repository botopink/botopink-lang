----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = Pair.of(1, "one");
    @print(Pair.first(p));
    @print(Function.identity(42));
    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
    @print(inc(10));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 38}.

{function, 'Function_identity', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Function_identity'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

{function, 'Function_compose', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Function_compose'}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, 'Function_flip', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'Function_flip'}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, 'Function_constant', 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, 'Function_constant'}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, 'Pair_of', 2, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, 'Pair_of'}, 2}.
  {label, 11}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, 3, 4}.
    {put_tuple2, {x, 0}, {list, [{x, 2}, {x, 3}]}}.
    {deallocate, 0}.
    return.

{function, 'Pair_first', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, 'Pair_first'}, 1}.
  {label, 13}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 0}.
    return.

{function, 'Pair_second', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 7}]}.
    {func_info, {atom, main}, {atom, 'Pair_second'}, 1}.
  {label, 15}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 0}.
    return.

{function, 'Pair_swap', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 8}]}.
    {func_info, {atom, main}, {atom, 'Pair_swap'}, 1}.
  {label, 17}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, 3, 3}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 2}]}}.
    {deallocate, 0}.
    return.

{function, 'Pair_mapFirst', 2, 19}.
  {label, 18}.
    {line, [{location, "main.erl", 9}]}.
    {func_info, {atom, main}, {atom, 'Pair_mapFirst'}, 2}.
  {label, 19}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, 3, 4}.
    {put_tuple2, {x, 0}, {list, [{x, 2}, {x, 3}]}}.
    {deallocate, 0}.
    return.

{function, 'Pair_mapSecond', 2, 21}.
  {label, 20}.
    {line, [{location, "main.erl", 10}]}.
    {func_info, {atom, main}, {atom, 'Pair_mapSecond'}, 2}.
  {label, 21}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, 3, 4}.
    {put_tuple2, {x, 0}, {list, [{x, 2}, {x, 3}]}}.
    {deallocate, 0}.
    return.

{function, main, 0, 23}.
  {label, 22}.
    {line, [{location, "main.erl", 11}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 23}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {literal, <<"one">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {call, 2, {f, 11}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {integer, 42}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 10}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 25}.
  {label, 24}.
    {line, [{location, "main.erl", 12}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 25}.
    {call_only, 0, {f, 23}}.

{function, main, 1, 27}.
  {label, 26}.
    {line, [{location, "main.erl", 13}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 27}.
    {call_only, 0, {f, 25}}.

{function, '-/2-fun-0-', 1, 29}.
  {label, 28}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-/2-fun-0-'}, 1}.
  {label, 29}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: f/1
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved local call: g/1
    {deallocate, 0}.
    return.

{function, '-/1-fun-1-', 2, 31}.
  {label, 30}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-/1-fun-1-'}, 2}.
  {label, 31}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    %% unresolved local call: f/2
    {deallocate, 0}.
    return.

{function, '-/1-fun-2-', 1, 33}.
  {label, 32}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, '-/1-fun-2-'}, 1}.
  {label, 33}.
    {allocate, 0, 1}.
    {move, {atom, x}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-3-', 1, 35}.
  {label, 34}.
    {line, [{location, "main.erl", 12}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-3-'}, 1}.
  {label, 35}.
    {allocate, 0, 1}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-4-', 1, 37}.
  {label, 36}.
    {line, [{location, "main.erl", 12}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-4-'}, 1}.
  {label, 37}.
    {allocate, 0, 1}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
<<"one">>
42
10
```
