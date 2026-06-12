----- SOURCE CODE -- main.bp
```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'Logger_prefix', 1}]}.
{attributes, []}.
{labels, 10}.

{function, 'Logger_setPrefix', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Logger_setPrefix'}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_exact, {f, 0}, {x, 0}, {x, 0}, 3, {list, [{atom, _prefix}, {x, 2}]}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Logger_log', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Logger_log'}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {move, {atom, console}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, '_prefix'}, {x, 0}]}}.
  {label, 8}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {move, {x, 4}, {x, 2}}.
    %% unresolved method call: log/3
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Logger_prefix', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'Logger_prefix'}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {test, is_map, {f, 9}, [{x, 0}]}.
    {get_map_elements, {f, 9}, {x, 0}, {list, [{atom, '_prefix'}, {x, 0}]}}.
  {label, 9}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
