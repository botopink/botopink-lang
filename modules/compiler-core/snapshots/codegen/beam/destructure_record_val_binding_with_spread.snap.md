----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32, z: i32)
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, describe, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, describe}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 4}, [{x, 1}]}.
    {get_map_elements, {f, 6}, {x, 1}, {list, [{atom, x}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, undefined}, {y, 1}}.
  {label, 5}.
    {move, {x, 1}, {x, 0}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
