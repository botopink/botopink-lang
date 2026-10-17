----- SOURCE CODE -- main.bp
```botopink
val array: string[] = ["65454"];
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__array', 0}]}.
{attributes, []}.
{labels, 6}.

{function, array, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, array}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"65454">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__array', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__array'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
