----- SOURCE CODE -- main.bp
```botopink
fn greeting() -> string {
    return "Hello, " + "World";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, greeting, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, greeting}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"Hello, ">>}, {x, 0}}.
    {move, {literal, <<"World">>}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
