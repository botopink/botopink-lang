----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- BEAM ASSEMBLY -- math.S
```erlang
{module, test@math}.
{exports, [{double, 1}]}.
{attributes, []}.
{labels, 6}.

{function, double, 1, 3}.
  {label, 2}.
    {line, [{location, "test@math.erl", 1}]}.
    {func_info, {atom, test@math}, {atom, double}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 4}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 4}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@math.bp:2:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 5}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {math.double};
val result = double(21);
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_init', 0}]}.
{attributes, []}.
{labels, 7}.

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
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, '$bp_unset'}]}.
    {move, {integer, 21}, {x, 0}}.
    {call_ext, 1, {extfunc, test@math, double, 1}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {test@main, result}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 6}.
    {deallocate, 1}.
    return.

{function, '_botopink_init', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_init'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
