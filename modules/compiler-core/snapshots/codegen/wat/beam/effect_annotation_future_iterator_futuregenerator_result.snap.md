----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@resultGenerator]
fn counter() -> @ResultGenerator<i32> {
    yield 1;
    yield 2;
}
#[@futureGenerator]
fn stream() -> @FutureGenerator<i32, string> {
    yield 1;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 13}.

%% #[@future] / #[@futureGenerator] — eager lowering
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

%% #[@future] / #[@futureGenerator] — eager lowering
{function, counter, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, counter}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
  {label, 10}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {deallocate, 1}.
    return.

%% #[@future] / #[@futureGenerator] — eager lowering
{function, stream, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, stream}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
  {label, 11}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {deallocate, 1}.
    return.

{function, parse, 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, parse}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 12}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 12}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
