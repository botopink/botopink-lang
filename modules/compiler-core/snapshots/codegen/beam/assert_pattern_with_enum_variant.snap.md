----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse() -> @Result<i32, string> {
    return 42;
}
fn f() {
    val result = parse();
    val assert Ok(value) = result catch throw "not ok";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, parse, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, parse}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 42}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, f, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, f}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {call, 0, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 7}.
    {move, {literal, <<"not ok">>}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 6}}.
  {label, 6}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
