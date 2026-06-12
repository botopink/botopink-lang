----- SOURCE CODE -- main.bp
```botopink
record Vec2 {
    x: f64,
    y: f64,
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, 'Vec2_dot', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Vec2_dot'}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {test, is_map, {f, 4}, [{x, 0}]}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 4}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {test, is_map, {f, 5}, [{x, 0}]}.
    {get_map_elements, {f, 5}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 5}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {test, is_map, {f, 7}, [{x, 0}]}.
    {get_map_elements, {f, 7}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 7}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
