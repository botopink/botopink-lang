----- SOURCE CODE -- main.bp
```botopink
fn pick(xs: Array<string>) -> string {
    var first = "";
    var last = "";
    loop (xs) { x, i ->
        if (i == 0) { first = x; };
        last = x;
    };
    return first + "-" + last;
}
fn weigh(xs: Array<i32>) -> i32 {
    var total = 0;
    loop (xs, 1..) { x, i ->
        total = total + x * i;
    };
    return total;
}
fn main() {
    @print(pick(["a", "b", "c"]));
    @print(weigh([10, 20, 30]));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 18}.

{function, pick, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, pick}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 1}, {x, 1}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {y, 2}], {x, 0}}.
    {deallocate, 3}.
    return.

{function, weigh, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, weigh}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 30}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 20}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
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

{function, '-pick/1-fun-0-', 2, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-pick/1-fun-0-'}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq, {f, 14}, [{y, 1}, {integer, 0}]}.
    %% assign to unknown variable: first
    {jump, {f, 15}}.
  {label, 14}.
  {label, 15}.
    %% assign to unknown variable: last
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-weigh/1-fun-1-', 2, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-weigh/1-fun-1-'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    %% assign to unknown variable: total
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
