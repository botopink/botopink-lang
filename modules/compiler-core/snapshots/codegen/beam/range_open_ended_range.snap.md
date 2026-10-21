----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) -> void {
    for (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__countUp', 1}]}.
{attributes, []}.
{labels, 13}.

{function, countUp, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, countUp}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {line, [{location, "test@main.erl", 2}]}.
  {label, 4}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {line, [{location, "test@main.erl", 2}]}.
  {label, 6}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 8}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 8}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at test@main.bp:2:11">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 9}.
    {move, {x, 0}, {y, 1}}.
    {test, is_lt, {f, 10}, [{integer, 100}, {y, 2}]}.
    {jump, {f, 7}}.
  {label, 10}.
    {jump, {f, 6}}.
  {label, 7}.
    {jump, {f, 5}}.
  {label, 5}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__countUp', 1, 12}.
  {label, 11}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__countUp'}, 1}.
  {label, 12}.
    {call_only, 1, {f, 3}}.
```

----- RUN LOG -----
```logs
```
