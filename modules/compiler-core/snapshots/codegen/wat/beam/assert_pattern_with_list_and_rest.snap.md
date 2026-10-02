----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, f, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, f}, 0}.
  {label, 3}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_nonempty_list, {f, 5}, [{x, 1}]}.
    {get_list, {x, 1}, {x, 2}, {x, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_nonempty_list, {f, 5}, [{x, 1}]}.
    {get_list, {x, 1}, {x, 2}, {x, 1}}.
    {move, {x, 2}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, nil, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {x, 0}, {x, 1}}.
    {test, is_nonempty_list, {f, 6}, [{x, 1}]}.
    {get_list, {x, 1}, {x, 2}, {x, 1}}.
    {move, {x, 2}, {y, 5}}.
    {test, is_nonempty_list, {f, 6}, [{x, 1}]}.
    {get_list, {x, 1}, {x, 2}, {x, 1}}.
    {move, {x, 2}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {jump, {f, 7}}.
  {label, 6}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, badmatch}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 7}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.
```

----- RUN LOG -----
```logs
```
