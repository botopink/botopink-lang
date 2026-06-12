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
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, getName, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, getName}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.
    {move, {atom, n}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 4}.
    {move, {literal, <<"unknown">>}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
