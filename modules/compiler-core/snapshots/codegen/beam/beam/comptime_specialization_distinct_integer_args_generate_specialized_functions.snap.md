----- SOURCE CODE -- main.bp
```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn calculate() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, calculate, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, calculate}, 0}.
  {label, 3}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {integer, 21}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 21}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 10}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, 'multiply_$0', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'multiply_$0'}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, 'multiply_$1', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'multiply_$1'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
