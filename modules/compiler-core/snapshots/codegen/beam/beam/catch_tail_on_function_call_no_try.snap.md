----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
fn risky() -> @Result(i32, RiskError) {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, risky, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, risky}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 5}, {x, 0}}.
    %% unresolved local call: RiskError/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, safe, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, safe}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {try, {y, 0}, {f, 6}}.
    {call, 0, {f, 3}}.
    {try_end, {y, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {try_case, {y, 0}}.
    {move, {integer, -1}, {x, 0}}.
  {label, 7}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
