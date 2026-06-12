----- SOURCE CODE -- main.bp
```botopink
#[@generator]
fn range(a: i32, b: i32) -> @Generator<i32> {
    yield a;
    yield b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

%% *fn (async/generator) — eager lowering
{function, range, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, range}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {deallocate, 0}.
    return.
    {move, {x, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
