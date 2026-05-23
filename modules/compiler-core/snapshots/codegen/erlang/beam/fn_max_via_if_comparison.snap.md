----- SOURCE CODE -- main.bp
```botopink
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{max, 2}]}.
{attributes, []}.
{labels, 5}.

{function, max, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, max}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 4}, [{x, 0}, {x, 1}]}.
    {move, {x, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 4}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
