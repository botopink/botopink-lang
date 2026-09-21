----- SOURCE CODE -- main.bp
```botopink
val Status = type {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__status.S
```erlang
{module, main__t__status}.
{exports, [{isDefault, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, isDefault, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__status.erl", 1}]}.
    {func_info, {atom, main__t__status}, {atom, isDefault}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, main__t__status__v__active}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_format', 1, 5}.
  {label, 4}.
    {line, [{location, "main__t__status.erl", 2}]}.
    {func_info, {atom, main__t__status}, {atom, '__bp_format'}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, main__t__status__v__active}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Status.Active">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, main__t__status__v__inactive}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Status.Inactive">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Status">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
