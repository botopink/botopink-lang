----- SOURCE CODE -- main.bp
```botopink
val Temperature = struct {
    _celsius: f64 = 0.0,
    set celsius(self: Self, value: f64) {
        self._celsius = value;
    }
    get celsius(self: Self) -> f64 {
        return self._celsius;
    }
    get fahrenheit(self: Self) -> f64 {
        return self._celsius * 1.8 + 32.0;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'Temperature_celsius', 2}, {'Temperature_celsius', 1}, {'Temperature_fahrenheit', 1}]}.
{attributes, []}.
{labels, 10}.

{function, 'Temperature_celsius', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Temperature_celsius'}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_exact, {f, 0}, {x, 0}, {x, 0}, 3, {list, [{atom, _celsius}, {x, 2}]}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Temperature_celsius', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Temperature_celsius'}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, '_celsius'}, {x, 0}]}}.
  {label, 8}.
    {deallocate, 0}.
    return.

{function, 'Temperature_fahrenheit', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'Temperature_fahrenheit'}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {test, is_map, {f, 9}, [{x, 0}]}.
    {get_map_elements, {f, 9}, {x, 0}, {list, [{atom, '_celsius'}, {x, 0}]}}.
  {label, 9}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {float, 1.8}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {float, 32.0}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
