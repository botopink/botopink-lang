----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
fn fetch() -> #(i32, i32) {
    return #(1, 2);
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, fetch, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetch}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 0}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, f, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, f}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {try, {y, 0}, {f, 6}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {try_case, {y, 0}}.
    {move, {literal, <<"failed">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: Error/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 7}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
