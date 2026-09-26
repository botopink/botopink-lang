----- SOURCE CODE -- main.bp
```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'VERSION', 0}, {'HOST', 0}]}.
{attributes, []}.
{labels, 6}.

{function, 'VERSION', 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'VERSION'}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'HOST', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'HOST'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"localhost">>}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
