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
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
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
    {test, is_map, {f, 7}, [{x, 0}]}.
    {get_map_elements, {f, 7}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 7}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
