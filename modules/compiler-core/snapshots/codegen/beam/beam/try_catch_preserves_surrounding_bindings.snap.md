----- SOURCE CODE -- main.bp
```botopink
record LoadError { msg: string }
*fn load() -> @Result<i32, LoadError> {
    throw LoadError(msg: "not found");
}
fn process() -> i32 {
    val prefix = 10;
    val data = try load() catch 0;
    val suffix = 20;
    @print(prefix, data, suffix);
    return prefix + data + suffix;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, load, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, load}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"not found">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, msg}, {x, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, process, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, process}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 3}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {integer, 0}, {x, 0}}.
  {label, 7}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 20}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {deallocate, 3}.
    return.
```

----- RUN LOG -----
```logs
```
