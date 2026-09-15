----- SOURCE CODE -- main.bp
```botopink
val array: string[] = ["65454"];
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, array, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, array}, 0}.
  {label, 3}.
    {move, nil, {x, 0}}.
    {test_heap, 2, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"65454">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
