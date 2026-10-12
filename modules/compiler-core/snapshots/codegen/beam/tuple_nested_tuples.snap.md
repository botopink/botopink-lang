----- SOURCE CODE -- main.bp
```botopink
val nested = #(#(1, 2), #(3, 4));
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__nested', 0}]}.
{attributes, []}.
{labels, 6}.

{function, nested, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, nested}, 0}.
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

{function, '__bp_priv__nested', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__nested'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
