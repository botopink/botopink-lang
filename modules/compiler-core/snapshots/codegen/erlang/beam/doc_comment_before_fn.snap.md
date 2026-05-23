----- SOURCE CODE -- main.bp
```botopink
/// This function greets the user
fn greet(name: string) -> string {
    return name;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.
%% This function greets the user

{function, greet, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, greet}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
