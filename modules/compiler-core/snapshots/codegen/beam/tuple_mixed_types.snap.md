----- SOURCE CODE -- main.bp
```botopink
val t = #(12, "5452");
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
    {move, {literal, <<"5452">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 12}, {x, 0}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
