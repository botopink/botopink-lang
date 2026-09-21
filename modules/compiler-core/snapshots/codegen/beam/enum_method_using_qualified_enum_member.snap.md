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
{exports, [{isDefault, 1}]}.
{attributes, []}.
{labels, 4}.

{function, isDefault, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__status.erl", 1}]}.
    {func_info, {atom, main__t__status}, {atom, isDefault}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, 'Active'}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
