----- SOURCE CODE -- main.bp
```botopink
fn negate(v: bool) -> bool {
    return !v;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, negate, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, negate}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, true}, {x, 0}}.
  {label, 5}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
