----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val numbers = [1, 2, 3];
    val assert [1, 2, 3] = numbers catch throw "not matching";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__f', 0}]}.
{attributes, []}.
{labels, 8}.

{function, f, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, f}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
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
    {test, is_eq, {f, 5}, [{x, 2}, {integer, 1}]}.
    {test, is_nonempty_list, {f, 5}, [{x, 1}]}.
    {get_list, {x, 1}, {x, 2}, {x, 1}}.
    {test, is_eq, {f, 5}, [{x, 2}, {integer, 2}]}.
    {test, is_nonempty_list, {f, 5}, [{x, 1}]}.
    {get_list, {x, 1}, {x, 2}, {x, 1}}.
    {test, is_eq, {f, 5}, [{x, 2}, {integer, 3}]}.
    {test, is_nil, {f, 5}, [{x, 1}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {literal, <<"not matching">>}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__f', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__f'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 3}}.
```

----- RUN LOG -----
```logs
```
