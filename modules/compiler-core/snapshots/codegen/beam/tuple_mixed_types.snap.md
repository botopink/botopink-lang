----- SOURCE CODE -- main.bp
```botopink
val t = #(12, "5452");
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__t', 0}]}.
{attributes, []}.
{labels, 6}.

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

{function, '__bp_priv__t', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__t'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
