----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) "positive" else "non-positive";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, describe, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, describe}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_gt, {f, 4}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"positive">>}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 4}.
    {move, {literal, <<"non-positive">>}, {x, 0}}.
    {deallocate, 0}.
    return.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
