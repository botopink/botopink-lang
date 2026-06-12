----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
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
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 10}.

{function, recordEq, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, recordEq}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 3, {list, [{atom, x}, {x, 1}, {atom, y}, {x, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 3, {list, [{atom, x}, {x, 1}, {atom, y}, {x, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq, {f, 6}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {atom, false}, {x, 0}}.
  {label, 7}.
    {deallocate, 2}.
    return.

{function, arrayEq, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, arrayEq}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq, {f, 8}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {atom, false}, {x, 0}}.
  {label, 9}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
