----- SOURCE CODE -- main.bp
```botopink
fn isPositive(n: i32) -> bool {
    return n > 0;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, isPositive, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, isPositive}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_gt, {f, 4}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
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
