----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, abs, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, abs}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {test, is_lt, {f, 4}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 0}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 4}.
    {deallocate, 1}.
    return.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
