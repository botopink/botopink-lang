----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    var sum = 0;
    for (0..n) { i ->
        sum = sum + i;
    };
    return sum;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, sumTo, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, sumTo}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 5}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-sumTo/1-fun-0-', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-sumTo/1-fun-0-'}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
