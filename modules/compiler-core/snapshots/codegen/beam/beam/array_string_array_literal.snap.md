----- SOURCE CODE -- main.bp
```botopink
val xs = ["hello", "world"];
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, xs, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, xs}, 0}.
  {label, 3}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"world">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
