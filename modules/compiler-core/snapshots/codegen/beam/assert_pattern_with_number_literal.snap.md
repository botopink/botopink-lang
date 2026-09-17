----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert 42 = answer catch throw Error("not 42");
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
    %% unresolved identifier: answer
    {move, {literal, {unresolved_identifier, answer}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 42}]}.
    %% unresolved identifier: answer
    {move, {literal, {unresolved_identifier, answer}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {literal, <<"not 42">>}, {x, 0}}.
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
