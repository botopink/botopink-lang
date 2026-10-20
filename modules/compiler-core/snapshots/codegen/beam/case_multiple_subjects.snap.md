----- SOURCE CODE -- main.bp
```botopink
fn process(a: i32, b: i32) -> void {
    case a, b {
        0, 0 -> null;
        _, _ -> null;
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__process', 2}]}.
{attributes, []}.
{labels, 9}.

{function, process, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, process}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {test, is_tuple, {f, 5}, [{x, 0}]}.
    {test, test_arity, {f, 5}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_eq, {f, 5}, [{x, 1}, {integer, 0}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {test, is_eq, {f, 5}, [{x, 1}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tuple, {f, 6}, [{x, 0}]}.
    {test, test_arity, {f, 6}, [{x, 0}, 2]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {case_end, {x, 0}}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__process', 2, 8}.
  {label, 7}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__process'}, 2}.
  {label, 8}.
    {call_only, 2, {f, 3}}.
```

----- RUN LOG -----
```logs
```
