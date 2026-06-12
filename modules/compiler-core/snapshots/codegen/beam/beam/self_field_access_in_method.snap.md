----- SOURCE CODE -- main.bp
```botopink
val Point = struct {
    x: i32,
    y: i32,
    fn sum() -> i32 {
        return self.x + self.y;
    }
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, 'Point_sum', 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Point_sum'}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, self}, {x, 0}}.
    {test, is_map, {f, 4}, [{x, 0}]}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 4}.
    {move, {atom, self}, {x, 0}}.
    {test, is_map, {f, 5}, [{x, 0}]}.
    {get_map_elements, {f, 5}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 5}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
