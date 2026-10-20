----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    assert false, "error message";
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
    {allocate, 0, 0}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, true}]}.
    {jump, {f, 5}}.
  {label, 4}.
    {move, {literal, <<"error message">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"test@main.bp:2">>}, {x, 2}}.
    {test_heap, 9, 3}.
    {put_list, {x, 1}, {literal, [<<" at test@main.bp:2:5">>]}, {x, 3}}.
    {put_list, {literal, <<"assertion failed: false: ">>}, {x, 3}, {x, 3}}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {x, 1}, {x, 2}, {x, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 5}.
    {move, {atom, ok}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
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
