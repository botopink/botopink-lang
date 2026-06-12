----- SOURCE CODE -- main.bp
```botopink
val t = #("56454", "85484");
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, t, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, t}, 0}.
  {label, 3}.
    {move, {literal, <<"56454">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"85484">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 0}, {x, 1}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
