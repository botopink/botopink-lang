----- SOURCE CODE -- main.bp
```botopink
fn process(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(5);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__process', 1}]}.
{attributes, []}.
{labels, 6}.

{function, process, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, process}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__process', 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__process'}, 1}.
  {label, 5}.
    {call_only, 1, {f, 3}}.
```

----- RUN LOG -----
```logs
```
