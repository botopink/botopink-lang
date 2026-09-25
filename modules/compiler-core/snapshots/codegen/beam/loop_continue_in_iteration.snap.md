----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32[] {
    var out = [];
    for (arr) { x ->
        if (x % 2 != 0) { continue; };
        out.push(x);
    };
    return out;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, sumEvens, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, sumEvens}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 5}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-sumEvens/1-fun-0-', 2, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-sumEvens/1-fun-0-'}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 6}, [{x, 0}, {integer, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
    {jump, {f, 7}}.
  {label, 6}.
  {label, 7}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
