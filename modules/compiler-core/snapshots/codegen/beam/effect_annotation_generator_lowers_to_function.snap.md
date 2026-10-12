----- SOURCE CODE -- main.bp
```botopink
fn range(a: i32, b: i32) -> @Iterator<i32> {
    yield a;
    yield b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__range', 2}]}.
{attributes, []}.
{labels, 7}.

%% @Iterator — eager lowering
{function, range, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, range}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 2}, {y, 2}}.
  {label, 4}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__range', 2, 6}.
  {label, 5}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__range'}, 2}.
  {label, 6}.
    {call_only, 2, {f, 3}}.
```

----- RUN LOG -----
```logs
```
