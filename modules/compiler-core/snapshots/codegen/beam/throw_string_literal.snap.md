----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    throw "something went wrong";
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, fail, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fail}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"something went wrong">>}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
```

----- RUN LOG -----
```logs
```
