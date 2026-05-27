----- SOURCE CODE -- main.bp
```botopink
record CalcError { msg: string }
fn getA() -> @Result(i32, CalcError) {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = getA() catch 0;
    return r;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, getA, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, getA}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"overflow">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: CalcError/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, compute, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, compute}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {try, {y, 0}, {f, 6}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {try_case, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
  {label, 7}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
