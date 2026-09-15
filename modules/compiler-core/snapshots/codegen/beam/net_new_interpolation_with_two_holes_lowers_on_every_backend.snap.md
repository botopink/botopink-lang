----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, label, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, label}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 1}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
