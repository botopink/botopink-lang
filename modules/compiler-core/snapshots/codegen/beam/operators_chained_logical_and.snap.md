----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, allThree, 3, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, allThree}, 3}.
  {label, 3}.
    {allocate, 0, 3}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.
    {move, {x, 1}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, false}, {x, 0}}.
  {label, 5}.
    {move, {x, 0}, {x, 3}}.
    {test, is_eq, {f, 6}, [{x, 3}, {atom, true}]}.
    {move, {x, 2}, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {atom, false}, {x, 0}}.
  {label, 7}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
