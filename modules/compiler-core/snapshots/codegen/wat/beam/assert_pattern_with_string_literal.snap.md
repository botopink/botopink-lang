----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, f, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, f}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 1}, {x, 0}]}.
    {move, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {x, 1}, {x, 0}}.
    {move, {literal, <<"not hello">>}, {x, 0}}.
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
