----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn first(p: Point) -> i32 {
    return p.x;
}
fn second(p: Point) -> i32 {
    return p.y;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, first, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, first}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 3, {atom, main__t__point}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {deallocate, 1}.
    return.

{function, second, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, second}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, main__t__point}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 7}.
    {deallocate, 1}.
    return.
```

----- BEAM ASSEMBLY -- main__t__point.S
```erlang
{module, main__t__point}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "main__t__point.erl", 1}]}.
    {func_info, {atom, main__t__point}, {atom, '__bp_get'}, 2}.
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
    {line, [{location, "main__t__point.erl", 1}]}.
    {func_info, {atom, main__t__point}, {atom, '__bp_format'}, 1}.
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
