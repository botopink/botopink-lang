----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Ok(value) = result catch throw Error("not ok");
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, f, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, f}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    %% unresolved identifier: result
    {move, {literal, {unresolved_identifier, result}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 0}}.
    %% unresolved identifier: result
    {move, {literal, {unresolved_identifier, result}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {literal, <<"not ok">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
