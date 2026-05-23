----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, sign, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, sign}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {test, is_gt, {f, 4}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"positive">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 4}.
    {move, {atom, undefined}, {x, 0}}.
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
