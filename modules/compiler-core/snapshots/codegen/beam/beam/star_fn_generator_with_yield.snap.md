----- SOURCE CODE -- main.bp
```botopink
*fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

%% *fn (async/generator) — eager lowering
{function, counter, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, counter}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.
    {move, {integer, 3}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
