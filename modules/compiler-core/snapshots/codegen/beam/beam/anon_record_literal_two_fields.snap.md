----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val r = record { a: 7, b: 11 };
    return r;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, make, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, make}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    %% unsupported: record literal
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
