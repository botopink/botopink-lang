----- SOURCE CODE -- main.bp
```botopink
val nested = #(#(1, 2), #(3, 4));
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, nested, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, nested}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{integer, 3}, {integer, 4}]}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 0}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
