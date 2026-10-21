----- SOURCE CODE -- main.bp
```botopink
type NetError(code: i32)
fn fetch() -> Result<i32, NetError> {
    throw NetError(code: 500);
}
fn safe() -> i32 {
    val r = try fetch() catch return -1;
    return r;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__fetch', 0}, {'__bp_priv__safe', 0}]}.
{attributes, []}.
{labels, 12}.

{function, fetch, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, fetch}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@NetError}, {integer, 500}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, safe, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, safe}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call, 0, {f, 3}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 7}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__fetch', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__fetch'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__safe', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__safe'}, 0}.
  {label, 11}.
    {call_only, 0, {f, 5}}.
```

----- BEAM ASSEMBLY -- test@main@@NetError.S
```erlang
{module, test@main@@NetError}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@NetError.erl", 1}]}.
    {func_info, {atom, test@main@@NetError}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, code}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 6}.
  {label, 5}.
    {line, [{location, "test@main@@NetError.erl", 1}]}.
    {func_info, {atom, test@main@@NetError}, {atom, '__bp_format'}, 1}.
  {label, 6}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"code">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"NetError">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
