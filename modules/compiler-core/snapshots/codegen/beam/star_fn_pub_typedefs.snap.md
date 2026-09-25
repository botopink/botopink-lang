----- SOURCE CODE -- main.bp
```botopink
#[@future]
pub fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
#[@resultGenerator]
pub fn count() -> @ResultGenerator<i32> {
    yield 1;
}
#[@futureGenerator]
pub fn pulses() -> @FutureGenerator<i32, string> {
    yield 1;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{loadOne, 1}, {count, 0}, {pulses, 0}]}.
{attributes, []}.
{labels, 10}.

%% #[@future] / #[@futureGenerator] — eager lowering
{function, loadOne, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, loadOne}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

%% #[@future] / #[@futureGenerator] — eager lowering
{function, count, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, count}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
  {label, 8}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {deallocate, 1}.
    return.

%% #[@future] / #[@futureGenerator] — eager lowering
{function, pulses, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, pulses}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, {y, 0}, {y, 0}}.
  {label, 9}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
