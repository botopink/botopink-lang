----- SOURCE CODE -- main.bp
```botopink
val nothing = null;
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__nothing', 0}]}.
{attributes, []}.
{labels, 6}.

{function, nothing, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, nothing}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__nothing', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__nothing'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
