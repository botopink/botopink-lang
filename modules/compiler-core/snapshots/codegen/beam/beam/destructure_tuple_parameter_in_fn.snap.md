----- SOURCE CODE -- main.bp
```botopink
fn process(#(x, y): #(i32, i32)) -> i32 {
    return x;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, process, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, process}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {atom, x}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
