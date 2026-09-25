----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 10}.

{function, recordEq, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, recordEq}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Point}, {integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Point}, {integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 6}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {atom, false}, {x, 0}}.
  {label, 7}.
    {deallocate, 2}.
    return.

{function, arrayEq, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, arrayEq}, 0}.
  {label, 5}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
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
    {move, {x, 0}, {y, 3}}.
    {test, is_eq_exact, {f, 8}, [{y, 1}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {atom, false}, {x, 0}}.
  {label, 9}.
    {deallocate, 4}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@Point.S
```erlang
{module, test@main@@Point}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Point.erl", 1}]}.
    {func_info, {atom, test@main@@Point}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, x}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, y}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main@@Point.erl", 1}]}.
    {func_info, {atom, test@main@@Point}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"y">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"x">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Point">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
