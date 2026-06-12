----- SOURCE CODE -- main.bp
```botopink
fn sameWord() -> bool {
    return "foo" == "bar";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, sameWord, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, sameWord}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"foo">>}, {x, 0}}.
    {move, {literal, <<"bar">>}, {x, 0}}.
    {test, is_eq, {f, 4}, [{x, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, false}, {x, 0}}.
  {label, 5}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
