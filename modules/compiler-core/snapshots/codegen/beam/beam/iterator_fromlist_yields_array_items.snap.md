----- SOURCE CODE -- main.bp
```botopink
*fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

*fn doRange(cur: i32, stop: i32) -> @Iterator<i32> {
    if (cur < stop) {
        yield cur;
        return doRange(cur + 1, stop);
    };
}

fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

fn main() {
    @print(toList(fromList([1, 2, 3])).join(","));
    @print(toList(doRange(0, 3)).join(","));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 19}.

%% *fn (async/generator) — eager lowering
{function, fromList, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fromList}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

%% *fn (async/generator) — eager lowering
{function, doRange, 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, doRange}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 16}, [{x, 0}, {x, 1}]}.
    {deallocate, 0}.
    return.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 5}, 0}.
  {label, 16}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, toList, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, toList}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
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
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: join/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: join/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
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

{function, '-fromList/1-fun-0-', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-fromList/1-fun-0-'}, 1}.
  {label, 15}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

{function, '-toList/1-fun-1-', 1, 18}.
  {label, 17}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-toList/1-fun-1-'}, 1}.
  {label, 18}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
<<",">>
<<",">>
```
