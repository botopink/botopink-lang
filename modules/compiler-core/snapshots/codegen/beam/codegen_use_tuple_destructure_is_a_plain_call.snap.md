----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
#[@context]
fn LikeWidget() -> Element {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 13}.

{function, optimistic, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, optimistic}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 2}]}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, 'LikeWidget', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'LikeWidget'}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 12}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, main__t__element}]}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-optimistic/2-fun-0-', 3, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-optimistic/2-fun-0-'}, 3}.
  {label, 7}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_add', 2, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_add'}, 2}.
  {label, 11}.
    {test, is_binary, {f, 12}, [{x, 0}]}.
    {test, is_binary, {f, 12}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 12}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-LikeWidget/0-fun-1-', 2, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-LikeWidget/0-fun-1-'}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 11}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__element.S
```erlang
{module, main__t__element}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 4}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__element.erl", 1}]}.
    {func_info, {atom, main__t__element}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Element">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
