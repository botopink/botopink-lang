----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0    -> "zero";
    _ -> 1;
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, result, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, result}, 0}.
  {label, 3}.
    {move, {integer, 42}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
