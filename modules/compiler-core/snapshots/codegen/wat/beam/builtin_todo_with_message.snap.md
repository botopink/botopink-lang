----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, notImplemented, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, notImplemented}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"implement this function">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, todo}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
