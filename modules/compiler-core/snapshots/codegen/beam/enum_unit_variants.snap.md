----- SOURCE CODE -- main.bp
```botopink
val Direction = type {
    North,
    South,
    East,
    West,
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- test@main@@Direction.S
```erlang
{module, test@main@@Direction}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Direction.erl", 1}]}.
    {func_info, {atom, test@main@@Direction}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, test@main@@Direction__v__north}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Direction.North">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, test@main@@Direction__v__south}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Direction.South">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, test@main@@Direction__v__east}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Direction.East">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, test@main@@Direction__v__west}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Direction.West">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Direction">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
