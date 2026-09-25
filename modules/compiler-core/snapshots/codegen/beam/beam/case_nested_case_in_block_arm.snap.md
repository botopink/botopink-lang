----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          _ -> 1;
      };
   };
   _ -> 1;
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 9}.

{function, result, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, result}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {test@main, result}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, '$bp_unset'}]}.
    {move, {integer, 42}, {x, 0}}.
    {test, is_eq, {f, 6}, [{x, 0}, {integer, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {test, is_eq, {f, 8}, [{x, 0}, {integer, 0}]}.
    {move, {integer, 54}, {x, 0}}.
    {jump, {f, 7}}.
  {label, 8}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 7}}.
  {label, 7}.
    {jump, {f, 5}}.
  {label, 6}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 5}}.
  {label, 5}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {test@main, result}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 4}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
