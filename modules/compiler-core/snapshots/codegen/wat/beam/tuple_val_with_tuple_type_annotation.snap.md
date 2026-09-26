----- SOURCE CODE -- main.bp
```botopink
val t: #(string, string) = #("56454", "85484");
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, t, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, t}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"56454">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"85484">>}, {x, 0}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 0}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
