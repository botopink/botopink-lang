----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert "hello" = greeting catch throw Error("not hello");
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
    {allocate, 0, 0}.
    %% unresolved identifier: greeting
    {move, {literal, {unresolved_identifier, greeting}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 1}, {x, 0}]}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved identifier: greeting
    {move, {literal, {unresolved_identifier, greeting}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {x, 1}, {x, 0}}.
    {move, {literal, <<"not hello">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
