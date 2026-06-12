----- SOURCE CODE -- main.bp
```botopink
val Vec2 = record {
    x: f64,
    y: f64,
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 11}.

{function, 'Vec2_lengthSq', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Vec2_lengthSq'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 7}, [{x, 0}]}.
    {get_map_elements, {f, 7}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 7}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 8}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 9}, [{x, 0}]}.
    {get_map_elements, {f, 9}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 9}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Vec2_scale', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Vec2_scale'}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {test, is_map, {f, 10}, [{x, 0}]}.
    {get_map_elements, {f, 10}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 10}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 1}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
