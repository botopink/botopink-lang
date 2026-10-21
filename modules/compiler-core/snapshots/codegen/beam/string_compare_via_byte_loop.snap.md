----- SOURCE CODE -- main.bp
```botopink
fn sameWord() -> bool {
    return "foo" == "bar";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__sameWord', 0}]}.
{attributes, []}.
{labels, 8}.

{function, sameWord, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, sameWord}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"foo">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bar">>}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {atom, false}, {x, 0}}.
  {label, 5}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__sameWord', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__sameWord'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
