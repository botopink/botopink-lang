----- SOURCE CODE -- main.bp
```botopink
val Vec2 = type(
    x: f64,
    y: f64) {
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
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__vec2.S
```erlang
{module, main__t__vec2}.
{exports, [{lengthSq, 1}, {scale, 2}]}.
{attributes, []}.
{labels, 11}.

{function, lengthSq, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__vec2.erl", 1}]}.
    {func_info, {atom, main__t__vec2}, {atom, lengthSq}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 7}, [{x, 0}]}.
    {get_map_elements, {f, 7}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 7}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 8}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 9}, [{x, 0}]}.
    {get_map_elements, {f, 9}, {x, 0}, {list, [{atom, y}, {x, 0}]}}.
  {label, 9}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, scale, 2, 5}.
  {label, 4}.
    {line, [{location, "main__t__vec2.erl", 2}]}.
    {func_info, {atom, main__t__vec2}, {atom, scale}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 10}, [{x, 0}]}.
    {get_map_elements, {f, 10}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.
  {label, 10}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
