----- SOURCE CODE -- main.bp
```botopink
fn both(a: bool, b: bool) -> bool {
    return a && b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, both, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, both}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.
    {move, {x, 1}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, false}, {x, 0}}.
  {label, 5}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
