----- SOURCE CODE -- main.bp
```botopink
fn getName(name: ?string) -> string {
    if (name) { n ->
        return n;
    };
    return "unknown";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__getName', 1}]}.
{attributes, []}.
{labels, 7}.

{function, getName, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, getName}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_ne_exact, {f, 4}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {literal, <<"unknown">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__getName', 1, 6}.
  {label, 5}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__getName'}, 1}.
  {label, 6}.
    {call_only, 1, {f, 3}}.
```

----- RUN LOG -----
```logs
```
