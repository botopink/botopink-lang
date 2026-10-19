----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> Async<i32> {
    return x;
}
fn loadTwice(x: i32) -> Async<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__fetch', 1}, {'__bp_priv__loadTwice', 1}]}.
{attributes, []}.
{labels, 13}.

%% @Async — eager lowering
{function, fetch, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, fetch}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, loadTwice, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, loadTwice}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 7}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__fetch', 1, 10}.
  {label, 9}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__fetch'}, 1}.
  {label, 10}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__loadTwice', 1, 12}.
  {label, 11}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__loadTwice'}, 1}.
  {label, 12}.
    {call_only, 1, {f, 5}}.

{function, '__bp_add', 2, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_add'}, 2}.
  {label, 7}.
    {test, is_binary, {f, 8}, [{x, 0}]}.
    {test, is_binary, {f, 8}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 8}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
```
