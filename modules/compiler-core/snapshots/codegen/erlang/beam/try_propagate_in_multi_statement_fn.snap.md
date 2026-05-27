----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
fn step1() -> @Result(i32, IoError) {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> @Result(i32, IoError) {
    throw IoError(path: "/out");
}
fn pipeline() -> @Result(i32, IoError) {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, step1, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, step1}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"/data">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: IoError/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, step2, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, step2}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {move, {literal, <<"/out">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved local call: IoError/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, pipeline, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, pipeline}, 0}.
  {label, 7}.
    {allocate, 2, 0}.
    {call, 0, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
