----- SOURCE CODE -- main.bp
```botopink
//// This module provides utility functions
//// for string manipulation

fn capitalize(s: string) -> string {
    return s;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__capitalize', 1}]}.
{attributes, []}.
{labels, 6}.
%%% This module provides utility functions
%%% for string manipulation

{function, capitalize, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, capitalize}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__capitalize', 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__capitalize'}, 1}.
  {label, 5}.
    {call_only, 1, {f, 3}}.
```

----- RUN LOG -----
```logs
```
