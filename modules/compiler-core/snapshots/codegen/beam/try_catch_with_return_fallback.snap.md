----- SOURCE CODE -- main.bp
```botopink
record NetError { code: i32 }
#[@result]
fn fetch() -> @Result<i32, NetError> {
    throw NetError(code: 500);
}
fn safe() -> i32 {
    val r = try fetch() catch return -1;
    return r;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 9}.

{function, fetch, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, code}, {integer, 500}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, safe, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, safe}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {'try', {y, 0}, {f, 6}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 8}}.
  {label, 6}.
    {try_case, {y, 0}}.
  {label, 7}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 8}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
