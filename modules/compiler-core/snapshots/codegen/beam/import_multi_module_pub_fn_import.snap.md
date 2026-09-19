----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- BEAM ASSEMBLY -- math.S
```erlang
{module, bp@math}.
{exports, [{double, 1}]}.
{attributes, []}.
{labels, 4}.

{function, double, 1, 3}.
  {label, 2}.
    {line, [{location, "bp@math.erl", 1}]}.
    {func_info, {atom, bp@math}, {atom, double}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {double} from "math";
val result = double(21);
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, result, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, result}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 21}, {x, 0}}.
    {call_ext, 1, {extfunc, bp@math, double, 1}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
