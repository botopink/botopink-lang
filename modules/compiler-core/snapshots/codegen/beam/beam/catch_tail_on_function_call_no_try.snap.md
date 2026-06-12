----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
*fn risky() -> @Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, risky, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, risky}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, level}, {x, 1}]}}.
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
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {integer, -1}, {x, 0}}.
  {label, 7}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
