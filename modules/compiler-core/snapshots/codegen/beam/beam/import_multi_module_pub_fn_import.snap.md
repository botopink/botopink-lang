----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- BEAM ASSEMBLY -- math.S
```erlang
{module, math}.
{exports, [{double, 1}]}.
{attributes, []}.
{labels, 4}.

{function, double, 1, 3}.
  {label, 2}.
    {line, [{location, "math.erl", 1}]}.
    {func_info, {atom, math}, {atom, double}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 0}.
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
    {move, {integer, 21}, {x, 0}}.
    %% unresolved local call: double/1
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
