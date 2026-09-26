----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert true;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, f, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, f}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, true}]}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {literal, <<"assertion failed">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"test@main.bp:2">>}, {x, 2}}.
    {test_heap, 4, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {x, 1}, {x, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 5}.
    {move, {atom, ok}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
