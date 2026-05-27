----- SOURCE CODE -- main.bp
```botopink
fn getFirst(t: #(i32, string)) -> i32 {
    return t._0;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, getFirst, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, getFirst}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, _0}, {x, 0}]}}.
  {label, 4}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
