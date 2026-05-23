----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    return loop (0..n) { i ->
        yield i;
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, sumTo, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, sumTo}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {make_fun2, {f, 5}, 0, 0, 0}.
    {move, {x, 0}, {x, 1}}.
    %% unsupported: range (Fase 7)
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {deallocate, 0}.
    return.

{function, '-sumTo/1-fun-0-', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-sumTo/1-fun-0-'}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
