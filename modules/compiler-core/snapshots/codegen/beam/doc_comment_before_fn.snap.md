----- SOURCE CODE -- main.bp
```botopink
/// This function greets the user
fn greet(name: string) -> string {
    return name;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__greet', 1}]}.
{attributes, []}.
{labels, 6}.
%% This function greets the user

{function, greet, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, greet}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__greet', 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__greet'}, 1}.
  {label, 5}.
    {call_only, 1, {f, 3}}.
```

----- RUN LOG -----
```logs
```
