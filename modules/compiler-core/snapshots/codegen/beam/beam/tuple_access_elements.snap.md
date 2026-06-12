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
{labels, 4}.

{function, getFirst, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, getFirst}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
