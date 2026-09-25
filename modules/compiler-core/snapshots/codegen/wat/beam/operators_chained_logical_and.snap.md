----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, allThree, 3, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, allThree}, 3}.
  {label, 3}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_eq, {f, 4}, [{y, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, false}, {x, 0}}.
  {label, 5}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 6}, [{x, 1}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {atom, false}, {x, 0}}.
  {label, 7}.
    {deallocate, 3}.
    return.
```

----- RUN LOG -----
```logs
```
