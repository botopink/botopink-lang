----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, validate, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, validate}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 4}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@AppError}, {integer, 400}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 5}}.
  {label, 4}.
  {label, 5}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@AppError.S
```erlang
{module, test@main@@AppError}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@AppError.erl", 1}]}.
    {func_info, {atom, test@main@@AppError}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, code}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, msg}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main@@AppError.erl", 1}]}.
    {func_info, {atom, test@main@@AppError}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"msg">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"code">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"AppError">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
