----- SOURCE CODE -- main.bp
```botopink
*fn fetch(x: i32) -> @Future<i32> {
    return x;
}
*fn loadTwice(x: i32) -> @Future<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

%% *fn (async/generator) — eager lowering
{function, fetch, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

%% *fn (async/generator) — eager lowering
{function, loadTwice, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, loadTwice}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    %% unsupported expr in tail position: jump
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {y, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
