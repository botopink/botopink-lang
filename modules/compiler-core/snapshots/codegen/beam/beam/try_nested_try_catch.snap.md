----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
fn inner() -> @Result(i32, DbError) {
    throw DbError(msg: "conn refused");
}
fn outer() -> @Result(i32, DbError) {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 12}.

{function, inner, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, inner}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"conn refused">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: DbError/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, outer, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, outer}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"timeout">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: DbError/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, process, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, process}, 0}.
  {label, 7}.
    {allocate, 2, 0}.
    {try, {y, 0}, {f, 8}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
    {try_case, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
  {label, 9}.
    {move, {x, 0}, {y, 1}}.
    {try, {y, 2}, {f, 10}}.
    {call, 0, {f, 5}}.
    {try_end, {y, 2}}.
    {jump, {f, 11}}.
  {label, 10}.
    {try_case, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
  {label, 11}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 3}], {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
