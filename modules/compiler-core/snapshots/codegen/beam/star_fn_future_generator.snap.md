----- SOURCE CODE -- main.bp
```botopink
#[@futureGenerator]
fn stream() -> @FutureGenerator<i32, string> {
    yield 1;
    yield 2;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

%% #[@future] / #[@futureGenerator] — eager lowering
{function, stream, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, stream}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
