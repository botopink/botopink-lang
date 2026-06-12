----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    @print(x, y);
    return x;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, describe, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, describe}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {get_map_elements, {f, 4}, {x, 1}, {list, [{atom, x}, {x, 0}]}}.
  {label, 4}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {get_map_elements, {f, 5}, {x, 1}, {list, [{atom, y}, {x, 0}]}}.
  {label, 5}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
