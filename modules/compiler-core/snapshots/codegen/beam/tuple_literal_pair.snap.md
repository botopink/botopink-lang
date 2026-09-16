----- SOURCE CODE -- main.bp
```botopink
val pair = #(1, "hello");
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, pair, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, pair}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, 3, 3}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 2}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
