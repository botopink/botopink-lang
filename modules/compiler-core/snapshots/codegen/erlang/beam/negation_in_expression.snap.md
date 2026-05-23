----- SOURCE CODE -- main.bp
```botopink
fn diff(x: i32, y: i32) -> i32 {
    return x + -y;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, diff, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, diff}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '-', {f, 0}, 2, [{integer, 0}, {x, 1}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
