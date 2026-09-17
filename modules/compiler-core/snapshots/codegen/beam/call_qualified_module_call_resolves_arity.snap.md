----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, 'Pipeline_run', 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Pipeline_run'}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 4}, [{x, 0}]}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, items}, {x, 0}]}}.
  {label, 4}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, list, map, 2}, 2}.
```

----- RUN LOG -----
```logs
```
