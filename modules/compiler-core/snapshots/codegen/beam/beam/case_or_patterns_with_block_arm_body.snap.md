----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        break value;
    };
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, parity, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, parity}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, {test@main, parity}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, '$bp_unset'}]}.
    {move, {integer, 5}, {x, 0}}.
    {test, is_ne_exact, {f, 6}, [{x, 0}, {integer, 0}]}.
    {test, is_ne_exact, {f, 6}, [{x, 0}, {integer, 2}]}.
    {test, is_ne_exact, {f, 6}, [{x, 0}, {integer, 4}]}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {literal, <<"even">>}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 7}.
    {move, {literal, <<"odd">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 5}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {test@main, parity}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 1}, {x, 0}}.
  {label, 4}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
