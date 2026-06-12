----- SOURCE CODE -- main.bp
```botopink
fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(10);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, apply, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, apply}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 10}, {x, 0}}.
    {call_fun, 1}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
