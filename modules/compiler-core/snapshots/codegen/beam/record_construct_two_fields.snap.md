----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn make() -> Point {
    return Point(x: 3, y: 4);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, make, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, make}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, x}, {integer, 3}, {atom, y}, {integer, 4}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
